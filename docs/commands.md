# Instance commands

Commands for working with instances once they are installed. For creating or
rebuilding an instance, see [`ddev install`](installation.md).

## `ddev launch [<version>] [<path>]`

Opens a browser at an instance's URL. Starts the project first if it is not
already running.

```shell
ddev launch
ddev launch 13
ddev launch 13 /typo3
```

With no version, opens the project's primary URL (the intro page). With a
version but no path, opens that instance's homepage. `<path>` is appended to
the instance URL, so `ddev launch 13 /typo3` opens the TYPO3 13 backend
directly.

The intro page lists each installed instance's exact core version (e.g.
`13.4.34`), read from `composer.lock` or, in classic mode, from the
downloaded core source - not just the configured major (`13`), since the
Composer constraint always resolves to the newest patch release available at
install time. `ddev all` prints the same detail in its per-instance header.

## `ddev <version> <command>`

Runs `<command>` inside one instance's directory. `typo3 …` is rewritten to
the right binary for that version and mode automatically (`vendor/bin/typo3`
for Composer instances, `vendor/bin/typo3cms` on TYPO3 11, the core CLI binary
for classic instances).

```shell
ddev 11 composer du -o
ddev 12 typo3 cache:flush
ddev 13 ls -la
```

`composer` commands are rejected for a slot currently rebuilt in
[classic mode](classic-mode.md), since a classic instance has no `vendor/`.

## `ddev all <command>`

Runs `<command>` in every installed instance listed in `TYPO3_VERSIONS`, one
after another. Each instance is skipped with a warning if it has not been
installed yet.

```shell
ddev all composer du -o
ddev all typo3 cache:flush
```

## `ddev worktree-init`

Regenerates this checkout's router hostnames so a `git worktree` checkout does
not collide with the primary checkout's. Run once per worktree, right after
`ddev config global --omit-project-name-by-default=true` and before the first
`ddev restart`. See [Git worktrees](git-worktrees.md) for the full setup.

```shell
ddev worktree-init
ddev restart
ddev install all
```

## `ddev worktree-remove`

Unregisters this worktree's DDEV project and drops its database, images and
volumes, then prints the `git worktree remove` / `git branch -D` commands to
run from the **primary** checkout - a worktree cannot remove itself while you
are inside it.

```shell
ddev worktree-remove
```
