# Contributing

## Local setup

This add-on is developed against a real DDEV project, since it has no
meaningful behaviour outside one.

```shell
mkdir my-test-extension && cd my-test-extension
composer init --name=vendor/my-test-extension --type=typo3-cms-extension --no-interaction
ddev config --project-type=php --docroot=public --webserver-type=apache-fpm --project-name=my-test-extension
ddev add-on get /path/to/your/ddev-typo3-multi-version-extension/checkout
ddev restart
ddev install all
```

`ddev add-on get` accepts a local path, so changes in your checkout are picked
up on the next `ddev add-on get` / `ddev restart` without publishing anything.

## Tests

Automated tests use [bats-core](https://bats-core.readthedocs.io/) >= 1.8.0
(required for `--filter-tags`), run locally from the repository root:

```shell
bats ./tests/test.bats
# Exclude release tests:
bats ./tests/test.bats --filter-tags '!release'
# Exclude the heavy end-to-end install test:
bats ./tests/test.bats --filter-tags '!install'
```

CI runs the same suite via `ddev/github-action-add-on-test` on every pull
request that touches something other than Markdown, against both the stable
and `HEAD` DDEV releases - `tests.yml` skips doc-only changes.

`tests/MANUAL_TESTING_CHECKLIST.md` tracks exploratory coverage against a real
extension that the automated suite does not reach - update it alongside a
change when it touches behaviour the checklist exercises.

## Commit messages

Conventional commits: `<type>: <description>` (`feat`, `fix`, `refactor`,
`docs`, `test`, `chore`, `ci`), describing the change rather than the ticket
that triggered it.

## Files with a `#ddev-generated` marker

Anything shipped under `.ddev/` with a `#ddev-generated` marker is overwritten
on every `ddev add-on get` update - see
[Updating](README.md#updating). Keep that in mind when editing
`commands/`, `.setup/scripts/`, `.setup/templates/` or the compose files: a
change there ships to every consumer's project on their next update.

## Pull requests

Open the PR against `main`. CI must pass (`tests.yml`) before merge.
