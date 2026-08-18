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
- [ ] Apache vhost independent of project name (PR #39) on a differently-named project

## Classic mode (`--classic`)

- [x] Classic install, main extension only, TYPO3 13 — `typo3-dump-server`, 2026-08-18
- [x] Classic install, main extension only, TYPO3 14 — `typo3-dump-server`, 2026-08-18
- [x] Classic install with a non-core Composer dependency (vendor-bundled) — `typo3-dump-server`, 2026-08-18
- [x] Classic install activates a composer.json-only fixture package (generated `ext_emconf.php`) — `typo3-dump-server`, 2026-08-18
- [x] `trustedHostsPattern` correctly set in classic mode — `typo3-dump-server`, 2026-08-18
- [x] Classic mode on TYPO3 12 — `typo3-dump-server`, 2026-08-18
- [x] `--classic` rejected for `all` and for TYPO3 11 (documented guards) — `typo3-dump-server`, 2026-08-18
- [x] Switching a version slot from classic back to composer mode (`ddev install <v>` without the flag) — `typo3-dump-server`, 2026-08-18
- [ ] `project.sh`'s `TYPO3_SETTINGS` applied in classic mode (**known gap — not implemented**)

## Demo content (`--demo`)

- [x] `--demo` / `--demo=introduction` on TYPO3 12 — `typo3-dump-server`, 2026-08-18
- [x] `--demo=bootstrap` profile — `typo3-dump-server`, 2026-08-18
- [x] `--demo=custom` profile (no package installed, relies on fixtures) — `typo3-dump-server`, 2026-08-18
- [x] `--demo` on TYPO3 14 (introduction unavailable → automatic bootstrap fallback + message) — `typo3-dump-server`, 2026-08-18
- [x] Unknown `--demo=<profile>` value is rejected with a clear error — `typo3-dump-server`, 2026-08-18

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
- [x] Primary and worktree checkout running simultaneously — `typo3-dump-server`, 2026-08-18
- [x] Install a TYPO3 instance inside a worktree checkout — `typo3-dump-server`, 2026-08-18
- [x] `worktree-remove` tears down containers/images/network — `typo3-dump-server`, 2026-08-18
- [ ] `worktree-remove` actually removes its hostnames from `/etc/hosts` (both attempts hit a local sudo/TTY limitation, never confirmed)
- [x] Three or more worktrees running in parallel (4 total incl. primary, unique hostnames, no collisions) — `typo3-dump-server`, 2026-08-18
- [x] Started 3 new worktree projects while the primary kept running (the exact scenario the router 404 gotcha describes) — no 404 observed this run; timing-dependent, not force-reproduced — `typo3-dump-server`, 2026-08-18

## Intro page

- [x] Git branch/commit shown when `.git-info` present — `typo3-dump-server`, 2026-08-18
- [x] Intro page with no git info available (fresh, non-git project) — verified by code review only (write-git-info.sh's git-availability guard + index.php's empty-string check), not exercised live against a non-git scaffold — 2026-08-18
- [x] DDEV command listing on the intro page reflects actual installed commands — `typo3-dump-server`, 2026-08-18

## Misc / lifecycle

- [x] `ddev add-on get` removal (`removal_actions` — config/hooks/setup directory cleanup) — `typo3-dump-server`, 2026-08-18
- [x] `TYPO3_CONTEXT` override via a project-owned `zz`-sorted compose file — `typo3-dump-server`, 2026-08-18
- [ ] `composer.json` normalization / CGL still passes after add-on-driven edits to a project's own files
