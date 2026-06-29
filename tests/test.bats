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
  mkdir -p ~/tmp
  export TESTDIR=$(mktemp -d ~/tmp/${PROJNAME}.XXXXXX)
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
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

teardown() {
  set -eu -o pipefail
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
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

  # Authenticate composer to avoid codeload rate-limit (HTTP 400) on TYPO3 subtree-split packages.
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    run ddev config global --web-environment-add="COMPOSER_AUTH={\"github-oauth\":{\"github.com\":\"${GITHUB_TOKEN}\"}}"
    assert_success
    run ddev restart -y
    assert_success
  fi

  run ddev install 13
  assert_success
}