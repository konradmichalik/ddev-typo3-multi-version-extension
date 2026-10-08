# AGENTS.md

## Project overview

DDEV add-on that runs TYPO3 12, 13 and 14 (optionally 11) as sibling instances inside one DDEV project. Each instance has its own hostname and database and symlinks the same extension checkout. The add-on is written in Bash and PHP templates and is installed with `ddev add-on get konradmichalik/ddev-typo3-multi-version-extension`.

- Requires DDEV `>= v1.24.10` (see `ddev_version_constraint` in `install.yaml`)
- Requires webserver type `apache-fpm` or `nginx-fpm` and a valid `composer.json` in the project root
- The DDEV project name must equal the extension key

## Structure

- `install.yaml`: add-on manifest with pre-install checks and the `project_files` list that ships to consumers
- `commands/host/`: DDEV host commands (`launch`, `worktree-init`, `worktree-remove`)
- `commands/web/`: DDEV web container commands (`install`, `all`, `11` to `14`, hidden `.install-<version>`)
- `.setup/scripts/`: shared shell helpers (`utils.sh`, `write-git-info.sh`)
- `.setup/templates/`: `index.php` intro page
- `.setup/Tests/Acceptance/Fixtures/`: bundled fixtures
- `apache/`, `nginx_full/`: webserver configuration
- `docker-compose.typo3-setup.yaml`: compose override shipped with the add-on
- `docs/`: user documentation (installation, commands, configuration, classic mode, git worktrees)
- `tests/`: bats suite (`test.bats`) and `MANUAL_TESTING_CHECKLIST.md`

## Development commands

The add-on has no build step. Develop it against a real DDEV project:

```shell
mkdir my-test-extension && cd my-test-extension
composer init --name=vendor/my-test-extension --type=typo3-cms-extension --no-interaction
ddev config --project-type=php --docroot=public --webserver-type=apache-fpm --project-name=my-test-extension
ddev add-on get /path/to/this/checkout
ddev restart
ddev install all
```

`ddev add-on get` accepts a local path, so changes are picked up on the next `ddev add-on get` and `ddev restart`.

## Testing

Tests use [bats-core](https://bats-core.readthedocs.io/), run from the repository root:

```shell
bats ./tests/test.bats
bats ./tests/test.bats --filter-tags '!release'
bats ./tests/test.bats --filter-tags '!install'
```

- `release` tests install from the published release, `install` tests run the heavy end-to-end install
- CI (`.github/workflows/tests.yml`) runs the suite through `ddev/github-action-add-on-test` on pull requests, pushes to `main` and nightly, against DDEV `stable` and `HEAD`. Markdown-only changes skip it
- Update `tests/MANUAL_TESTING_CHECKLIST.md` when a change touches behaviour it exercises

## Code style and linting

No linter is configured. `.editorconfig` applies: UTF-8, LF, 4 spaces (2 spaces for `bats`, `sh`, `yml`, `yaml`), final newline, trailing whitespace trimmed except in Markdown.

Anything shipped under `.ddev/` with a `#ddev-generated` marker is overwritten on every `ddev add-on get`. A change to `commands/`, `.setup/scripts/`, `.setup/templates/` or the compose files ships to every consumer on their next update.

## Git workflow

- Commit format: `<type>: <description>` with `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`
- Describe the change, not the ticket that triggered it
- No co-author trailers
- Open pull requests against `main`. CI must pass before merge
