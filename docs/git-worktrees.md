# Git worktree support

Since `.ddev/` is committed to your repository, a plain `git worktree add`
checkout would normally share the same DDEV project name (and therefore the
same hostnames) as your primary checkout - only one of them could run at a
time. This add-on avoids baking the project name into any of its own files,
but DDEV's own `.ddev/config.yaml` still needs one adjustment, and each
worktree needs its own hostnames.

Requires DDEV `>= v1.24.10` (the version constraint declared by this add-on).

## One-time setup

Tell DDEV to derive the project name from the directory instead of a fixed
`name:` in `.ddev/config.yaml` - either per project by removing the `name:`
line from `.ddev/config.yaml`, or globally for all future projects:

```shell
ddev config global --omit-project-name-by-default=true
```

## Per-worktree setup

Create the worktree as a **sibling** of your primary checkout (never nested
inside it), using a directory name that's safe as a DNS label (lowercase
letters, digits, hyphens):

```shell
git worktree add ../my-feature-branch feature/my-feature
cd ../my-feature-branch
ddev worktree-init
ddev restart
ddev install all
```

[`ddev worktree-init`](commands.md#ddev-worktree-init) regenerates this
checkout's router hostnames so they don't collide with the primary checkout's;
`.Build/` is gitignored, so every worktree needs its own `ddev install`.

> [!NOTE]
> A bare `404 page not found` right after `ddev restart` is the DDEV
> **router**, not TYPO3 - registering a new project while others are already
> running can leave the router without a route for it until the project is
> restarted once more. Run `ddev restart` again if you see it.

A new worktree checkout initially contains only committed repository content.
If a repo-owned customization file such as `.ddev/.setup/project.sh` or a
script under `.ddev/.setup/hooks/` isn't committed, a new worktree simply
won't have it - no error, the customization just doesn't apply.

## Resource expectations

Each worktree runs its own `web` and `db` container, plus roughly one full
TYPO3 distribution per configured version under `.Build/`. Running several
worktrees at once multiplies both. `ddev poweroff` stops *all* DDEV projects,
not just the current one - worth knowing if several worktrees (or agents) are
meant to keep running in parallel.

## Removing a worktree

From inside the worktree,
[`ddev worktree-remove`](commands.md#ddev-worktree-remove) unregisters its
DDEV project and drops its database, images and volumes, then prints the
`git worktree remove` / `git branch -D` commands to run from your **primary**
checkout (a worktree cannot remove itself while you're inside it).

## Upgrading an existing project

If you installed this add-on before worktree support was added, re-run the
installation command to pick up the fixes:

```shell
ddev add-on get konradmichalik/ddev-typo3-multi-version-extension && ddev restart
```

See [Updating](../README.md#updating) for which files get overwritten.
