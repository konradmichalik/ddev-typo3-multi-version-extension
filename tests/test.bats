#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# To exclude the heavy end-to-end install test:
#   bats ./tests/test.bats --filter-tags '!install'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=konradmichalik/ddev-typo3-multi-version-extension

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"

  # A valid composer.json is a documented prerequisite (README) and, since
  # the "Check for a valid composer.json" pre-install action, an enforced
  # one - every test project needs at least this minimal one before
  # `ddev add-on get` runs. Tests that need a richer composer.json
  # (require/extension-key) overwrite this via scaffold_with_existing_tests_dir.
  cat > composer.json <<JSON
{
    "name": "test/${PROJNAME}",
    "type": "typo3-cms-extension"
}
JSON

  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site --webserver-type=apache-fpm
  assert_success
  run ddev start -y
  assert_success
}

health_checks() {
  # Do something useful here that verifies the add-on

  # You can check for specific information in headers:
  # run curl -sfI https://${PROJNAME}.ddev.site
  # assert_output --partial "HTTP/2 200"
  # assert_output --partial "test_header"

  # Or check if some command gives expected output:
  DDEV_DEBUG=true run ddev launch
  assert_success
  assert_output --partial "FULLURL https://${PROJNAME}.ddev.site"
}

# Version hosts route to .Build/<version>/public, also after a restart
# (DDEV regenerates its own webserver config on start).
version_routing_checks() {
  mkdir -p "${TESTDIR}/.Build/12/public/typo3"
  echo "T12" > "${TESTDIR}/.Build/12/public/marker.txt"
  echo '<?php echo "BE12";' > "${TESTDIR}/.Build/12/public/typo3/index.php"
  run ddev restart -y
  assert_success

  run curl -sfk "https://12.${PROJNAME}.ddev.site/marker.txt"
  assert_success
  assert_output "T12"
  # TYPO3 12 still serves its backend from public/typo3/index.php
  run curl -sfk "https://12.${PROJNAME}.ddev.site/typo3/"
  assert_success
  assert_output "BE12"
  # Bare host still serves the intro page
  run curl -sfk "https://${PROJNAME}.ddev.site/"
  assert_success
  refute_output "T12"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  # Persist TESTDIR if running inside GitHub Actions. Useful for uploading test result artifacts
  # See example at https://github.com/ddev/github-action-add-on-test#preserving-artifacts
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

# Scaffold a consumer extension that already has a Tests/Acceptance/ directory
scaffold_with_existing_tests_dir() {
  # Minimal consumer extension so the add-on's composer steps have a project to act on.
  cat > composer.json <<JSON
{
    "name": "test/${PROJNAME}",
    "type": "typo3-cms-extension",
    "require": {
        "typo3/cms-core": "^13.4"
    },
    "extra": {
        "typo3/cms": {
            "extension-key": "$(echo "${PROJNAME}" | tr '-' '_')"
        }
    }
}
JSON

  # Recreate Tests/Acceptance/ dir that might exists before install.
  mkdir -p Tests/Acceptance/Fixtures
  touch Tests/Acceptance/Fixtures/.gitkeep

  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
  version_routing_checks
}

@test "install from directory on nginx-fpm" {
  set -eu -o pipefail
  run ddev config --webserver-type=nginx-fpm
  assert_success
  run ddev restart -y
  assert_success

  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
  # 13+ serve the backend from the main index.php, even if typo3/index.php exists
  mkdir -p "${TESTDIR}/.Build/13/public/typo3"
  echo '<?php echo "FE13";' > "${TESTDIR}/.Build/13/public/index.php"
  echo '<?php echo "BE13";' > "${TESTDIR}/.Build/13/public/typo3/index.php"
  version_routing_checks

  # Backend routes reach typo3/index.php (Apache gets this from TYPO3's .htaccess)
  run curl -sfk "https://12.${PROJNAME}.ddev.site/typo3/main"
  assert_success
  assert_output "BE12"
  run curl -sfk "https://13.${PROJNAME}.ddev.site/typo3/login"
  assert_success
  assert_output "FE13"
}

@test "warns about an unmarked nginx-site.conf with the old version routing" {
  set -eu -o pipefail
  mkdir -p .ddev/nginx_full
  printf 'server {\n    server_name ~^(?<t3version>1[1-4])\\..*$;\n}\n' > .ddev/nginx_full/nginx-site.conf

  run ddev add-on get "${DIR}"
  assert_success
  assert_output --partial "nginx_full/nginx-site.conf overrides"
  assert_file_exist .ddev/nginx_full/nginx-site.conf
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

# When the consuming extension already has a Tests/Acceptance/ directory before `ddev add-on get`, the bundled
# fixtures must land at Tests/Acceptance/Fixtures/... and NOT nested under # Tests/Acceptance/Acceptance/..
@test "merges bundled fixtures when Tests/Acceptance already exists" {
  set -eu -o pipefail
  scaffold_with_existing_tests_dir

  assert_file_exist "${TESTDIR}/Tests/Acceptance/Fixtures/packages/sitepackage/composer.json"
  assert_file_not_exist "${TESTDIR}/Tests/Acceptance/Acceptance/Fixtures/packages/sitepackage/composer.json"
}

# End-to-end confirmation that the install completes with a pre-existing Tests/Acceptance/.
# bats test_tags=install
@test "ddev install succeeds with a pre-existing Tests/Acceptance" {
  set -eu -o pipefail
  if [ "${RUN_DDEV_INSTALL:-false}" != "true" ]; then
    skip "set RUN_DDEV_INSTALL=true to run the networked 'ddev install' assertion"
  fi

  scaffold_with_existing_tests_dir

    # Authenticate composer to avoid codeload rate-limit (HTTP 400) on TYPO3 subtree-split
    # packages. Scope to THIS temp project (no `global`) so the token lives only in
    # ${TESTDIR}/.ddev and is removed by teardown — never persisted to the user's global config.
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      run ddev config --web-environment-add="COMPOSER_AUTH={\"github-oauth\":{\"github.com\":\"${GITHUB_TOKEN}\"}}"
      assert_success
      run ddev restart -y
      assert_success
    fi

  run ddev install 13
  assert_success
}

# End-to-end confirmation that a classic (non-Composer) install rebuilds the
# version slot in place: the mode marker flips to "classic", the extension is
# symlinked TER-style into typo3conf/ext/<key>, and the frontend is reachable
# under the unchanged hostname.
# bats test_tags=install
@test "ddev install 13 --classic builds a classic instance" {
  set -eu -o pipefail
  if [ "${RUN_DDEV_INSTALL:-false}" != "true" ]; then
    skip "set RUN_DDEV_INSTALL=true to run the networked 'ddev install' assertion"
  fi

  scaffold_with_existing_tests_dir

    # Authenticate composer to avoid codeload rate-limit (HTTP 400) on TYPO3 subtree-split
    # packages. Scope to THIS temp project (no `global`) so the token lives only in
    # ${TESTDIR}/.ddev and is removed by teardown — never persisted to the user's global config.
    if [ -n "${GITHUB_TOKEN:-}" ]; then
      run ddev config --web-environment-add="COMPOSER_AUTH={\"github-oauth\":{\"github.com\":\"${GITHUB_TOKEN}\"}}"
      assert_success
      run ddev restart -y
      assert_success
    fi

  run ddev install 13 --classic
  assert_success

  local ext_key
  ext_key=$(echo "${PROJNAME}" | tr '-' '_')

  # Mode marker flipped to classic.
  run cat "${TESTDIR}/.Build/13/.install-mode"
  assert_success
  assert_output "classic"

  # Extension linked TER-style into typo3conf/ext/<key>: the target is a
  # directory whose entries are symlinks back to the extension sources (here the
  # scaffolded composer.json), and there is no per-extension Composer autoloader.
  assert_dir_exist "${TESTDIR}/.Build/13/public/typo3conf/ext/${ext_key}"
  run test -L "${TESTDIR}/.Build/13/public/typo3conf/ext/${ext_key}/composer.json"
  assert_success
  assert_file_not_exist "${TESTDIR}/.Build/13/public/typo3conf/ext/${ext_key}/vendor/autoload.php"

  # Frontend reachable under the unchanged per-version hostname.
  run curl -sfI "https://13.${PROJNAME}.ddev.site"
  assert_success
}