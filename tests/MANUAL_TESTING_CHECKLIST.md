# Manual Testing Checklist

Exploratory coverage against a real extension, complementing `test.bats`. Check items off as they're verified; note the extension/version/date next to each when you do.

## Core install flow

- [x] Fresh `ddev add-on get` install (apache-fpm) — `typo3-dump-server`, 2026-08-18
- [x] Update over an existing pre-marker install (`ddev add-on get` re-run) — `typo3-dump-server`, 2026-08-18
- [x] Install TYPO3 12 (composer mode) — `typo3-dump-server`, 2026-08-18
- [x] Install TYPO3 13 (composer mode) — `typo3-dump-server`, 2026-08-18
- [x] Install TYPO3 14 (composer mode) — `typo3-dump-server`, 2026-08-18
- [x] Install TYPO3 11 (composer mode, `typo3cms` binary path, `install:setup` flow) — `typo3-dump-server`, 2026-08-18
- [x] `ddev install all` — `typo3-dump-server`, 2026-08-18
- [x] `ddev <version> <command>` exec wrapper (`ddev 11 typo3 extension:list`) — `typo3-dump-server`, 2026-08-18
- [x] `ddev all <command>` exec wrapper — `typo3-dump-server`, 2026-08-18

## Webserver types

- [x] apache-fpm project — `typo3-dump-server`, 2026-08-18
- [x] nginx-fpm project (`nginx_full/nginx-site.conf`, pretty-URL routing through `index.php`, no stray `.htaccess`/`web.config`) — `typo3-dump-server`, 2026-08-18
- [x] Apache vhost independent of project name (PR #39): `ServerName ${DDEV_SITENAME}.${DDEV_TLD}` resolves dynamically, not baked in at install time - verified via Host-header test (correct host → 200, unrelated host → 404) — `typo3-dump-server`, 2026-08-18

## Classic mode (`--classic`)

- [x] Classic install, main extension only, TYPO3 13 — `typo3-dump-server`, 2026-08-18
- [x] Classic install, main extension only, TYPO3 14 — `typo3-dump-server`, 2026-08-18
- [x] Classic install with a non-core Composer dependency (vendor-bundled) — `typo3-dump-server`, 2026-08-18
- [x] Classic install activates a composer.json-only fixture package (generated `ext_emconf.php`) — `typo3-dump-server`, 2026-08-18
- [x] `trustedHostsPattern` correctly set in classic mode — `typo3-dump-server`, 2026-08-18
- [x] Classic mode on TYPO3 12 — `typo3-dump-server`, 2026-08-18
- [x] `--classic` rejected for `all` and for TYPO3 11 (documented guards) — `typo3-dump-server`, 2026-08-18
- [x] Switching a version slot from classic back to composer mode (`ddev install <v>` without the flag) — `typo3-dump-server`, 2026-08-18
- [x] `project.sh`'s `TYPO3_SETTINGS` applied in classic mode - implemented (was a real gap) and verified: `$DDEV_SITENAME` expansion and quoted-string values both resolve correctly — `typo3-dump-server`, 2026-08-18
- [ ] `--classic --demo` warns that demo content requires Composer mode, skips the demo install, and still runs the `post-install` hook (issue #63 item 1) - not yet exercised live
- [ ] A failed fixture-package `extension:activate` in classic mode now aborts the install instead of silently continuing into `extension:setup` (issue #63 item 2) - not yet exercised live
- [ ] An explicit `TYPO3_SERVER_TYPE` env var is respected instead of being overwritten by `compute_typo3_server_type` (issue #63 item 3) - not yet exercised live

## Demo content (`--demo`)

- [x] `--demo` / `--demo=introduction` on TYPO3 12 — `typo3-dump-server`, 2026-08-18
- [x] `--demo=bootstrap` profile — `typo3-dump-server`, 2026-08-18
- [x] `--demo=custom` profile (no package installed, relies on fixtures) — `typo3-dump-server`, 2026-08-18
- [x] `--demo` on TYPO3 14 (introduction unavailable → automatic bootstrap fallback + message) — `typo3-dump-server`, 2026-08-18
- [x] Unknown `--demo=<profile>` value is rejected with a clear error — `typo3-dump-server`, 2026-08-18
- [ ] Empty `--demo=` value and an unrecognized flag (e.g. `--verbse`) are both rejected with an error instead of being silently dropped or mistaken for a version argument (issue #63 item 8) - not yet exercised live

## `project.sh` customizations

- [x] `ADDITIONAL_PACKAGES` — `typo3-dump-server`, 2026-08-18
- [x] `TYPO3_SETTINGS` — `typo3-dump-server`, 2026-08-18
- [x] `SITEPACKAGE_PACKAGES` (replaces default `test/sitepackage`) — `typo3-dump-server`, 2026-08-18
- [x] `COMPOSER_CONFIG` (avoid `bin-dir` - conflicts with the hardcoded `vendor/bin/typo3` path) — `typo3-dump-server`, 2026-08-18
- [x] `FIXTURE_EXTENSION_DIRS` (symlinks only; needs pairing with `ADDITIONAL_PACKAGES` to actually activate - README clarified) — `typo3-dump-server`, 2026-08-18
- [x] `$VERSION` expansion inside a package constraint — `typo3-dump-server`, 2026-08-18

## Install hooks (`.ddev/.setup/hooks/<name>.sh`)

- [x] `post-install` hook — `typo3-dump-server`, 2026-08-18
- [x] `pre-install` hook — `typo3-dump-server`, 2026-08-18
- [x] `post-composer` hook — `typo3-dump-server`, 2026-08-18
- [x] `post-typo3-setup` hook — `typo3-dump-server`, 2026-08-18
- [x] A failing hook aborts the install with output shown (not swallowed) — `typo3-dump-server`, 2026-08-18 (verified non-interactive; interactive/spinner-mode replay path not separately exercised)

## `SYMLINK_EXCLUSIONS`

- [x] Default fallback includes `vendor`/`public` — verified by reading fixed default, not exercised live
- [x] Custom `SYMLINK_EXCLUSIONS` value actually excludes the given directories — `typo3-dump-server`, 2026-08-18

## Git worktree support

- [x] `worktree-init` regenerates hostnames without colliding with the primary checkout — `typo3-dump-server`, 2026-08-18
- [ ] `worktree-init` fails explicitly (instead of guessing `12 13 14`) when `TYPO3_VERSIONS` can't be read from `docker-compose.typo3-setup.yaml` (issue #63 item 6) - not yet exercised live
- [x] Primary and worktree checkout running simultaneously — `typo3-dump-server`, 2026-08-18
- [x] Install a TYPO3 instance inside a worktree checkout — `typo3-dump-server`, 2026-08-18
- [x] `worktree-remove` tears down containers/images/network — `typo3-dump-server`, 2026-08-18
- [ ] `worktree-remove` refuses to run from the primary checkout instead of deleting its DDEV project (issue #63 item 7) - not yet exercised live
- [x] `worktree-remove` actually removes its hostnames from `/etc/hosts` - confirmed absent after removal (previous attempts only hit a sudo/TTY limitation running non-interactively, not an add-on bug) — `typo3-dump-server`, 2026-08-18
- [x] Three or more worktrees running in parallel (4 total incl. primary, unique hostnames, no collisions) — `typo3-dump-server`, 2026-08-18
- [x] Started 3 new worktree projects while the primary kept running (the exact scenario the router 404 gotcha describes) — no 404 observed this run; timing-dependent, not force-reproduced — `typo3-dump-server`, 2026-08-18

## Intro page

- [x] Git branch/commit shown when `.git-info` present — `typo3-dump-server`, 2026-08-18
- [ ] Intro page with no git info available (fresh, non-git project) now still shows the hostname (fix for issue #63 item 4 - the hostname was previously nested inside the git-branch/commit condition and got hidden along with it) - not yet exercised live
- [x] DDEV command listing on the intro page reflects actual installed commands — `typo3-dump-server`, 2026-08-18

## Misc / lifecycle

- [ ] `ddev add-on remove` now removes only add-on-managed subpaths under `.ddev/.setup/` and leaves a project's own `.ddev/.setup/project.sh` in place (fix for issue #63 item 5, previously `rm -rf`'d the whole directory) - not yet exercised live
- [x] `TYPO3_CONTEXT` override via a project-owned `zz`-sorted compose file — `typo3-dump-server`, 2026-08-18
- [x] `composer.json` normalization / CGL still passes after add-on-driven edits to a project's own files — N/A by design: verified via code review that no install.yaml action ever writes outside `.ddev/` (the `find ${DDEV_APPROOT}/.ddev` substitutions are scoped there; composer.json is only *read* for its `name`). The one real edit to `typo3-dump-server`'s own composer.json today (vendor-bundler dev-dependency, PR #64) was a deliberate manual step, not an automatic add-on action, and passed the project's own `cgl` CI job — 2026-08-18
