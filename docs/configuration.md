# Configuration

By default, a blank TYPO3 instance is installed for each version, with only
two extensions active:

- your **main extension** from the project root (symlinked)
- a demo **sitepackage extension** from `Tests/Acceptance/Fixtures/packages`

Use the sitepackage to exercise your main extension's features. Adjust it to
your needs in `Tests/Acceptance/Fixtures/packages/sitepackage/`.

If you need more extensions, place them in `Tests/Acceptance/Fixtures/packages`
or adjust the `ddev install` command - within e.g. the
[`.install-12`](../commands/web/.install-12) file, you can adjust the
`composer require` command to fit your needs.

## `TYPO3_VERSIONS`

`TYPO3 12`, `13` and `14` are installed by `ddev install all` by default.
TYPO3 11 is still fully supported by the install scripts but is not part of
that default set. Edit the `TYPO3_VERSIONS` variable in
[`.ddev/docker-compose.typo3-setup.yaml`](../docker-compose.typo3-setup.yaml)
to drop versions you don't need, or add `11` back:

```yaml
- TYPO3_VERSIONS=11 12 13 14
```

Run `ddev restart` after changing it.

## `SYMLINK_EXCLUSIONS`

Items from your main extension's root directory are symlinked into each TYPO3
instance, except the ones listed in `SYMLINK_EXCLUSIONS` in
[`docker-compose.typo3-setup.yaml`](../docker-compose.typo3-setup.yaml). It
defaults to `Documentation Documentation-GENERATED-temp var vendor public`, so
a local `vendor/` or `public/` directory in your extension repository is not
linked into the instance's own composer/web-root structure.

## `project.sh`

Copy [`.ddev/.setup/project.sh.example`](../.setup/project.sh.example) to
`.ddev/.setup/project.sh` to customize the install without touching
`utils.sh` - `project.sh` isn't managed by the add-on, so it survives
`ddev add-on get` upgrades.

```bash
ADDITIONAL_PACKAGES=(
    'typo3/cms-reports:^$VERSION'
)
```

| Variable | Effect |
|---|---|
| `ADDITIONAL_PACKAGES` | Extra composer packages installed alongside the base install |
| `SITEPACKAGE_PACKAGES` | Replaces the default `test/sitepackage` when set |
| `COMPOSER_CONFIG` | Extra `composer config` entries |
| `TYPO3_SETTINGS` | Extra `typo3 configuration:set` calls |
| `FIXTURE_EXTENSION_DIRS` | Extra directories (besides `Tests/Acceptance/Fixtures/packages`) whose subdirectories get symlinked into Composer's local package repository |

`$VERSION` in a package constraint expands per version at install time - write
it single-quoted (e.g. `'typo3/cms-reports:^$VERSION'`) so it isn't expanded
early.

Symlinking alone only makes a package *discoverable* - it still needs to be
required by name in `ADDITIONAL_PACKAGES` (or `SITEPACKAGE_PACKAGES`) to
actually get installed and activated, the same way the default
`test/sitepackage` fixture works.

## Install hooks

For install steps that don't fit a `project.sh` variable, add a script at
`.ddev/.setup/hooks/<name>.sh` - it's sourced automatically if present, so it
has access to `$VERSION`, `$BASE_PATH`, `$TYPO3_BIN`, `$DATABASE`,
`$EXTENSION_KEY` and the `message`/`_progress`/`_done` helpers. Unlike the
best-effort `Tests/Acceptance/Fixtures/*.sh` scripts below, a failing command
in a hook aborts the install with its output shown, not silently swallowed.

| Hook | Runs |
|---|---|
| `pre-install` | Before the environment is set up (`$TYPO3_BIN`/`$DATABASE` are not yet available at this point) |
| `post-composer` | After the base composer packages are installed |
| `post-typo3-setup` | After TYPO3 itself is set up, before fixture import |
| `post-install` | Last, after fixtures, site configs and the schema update |

```bash
# .ddev/.setup/hooks/post-install.sh
$TYPO3_BIN extension:setup --extension=my_extension
```

## Fixtures

During installation, fixture data from `Tests/Acceptance/Fixtures/` is
imported automatically:

| Type | Location | Description |
|------|----------|--------------|
| XML | `Tests/Acceptance/Fixtures/*.xml` | TYPO3 export files, imported via `impexp:import` |
| SQL | `Tests/Acceptance/Fixtures/*.sql` | Raw SQL files, imported directly into the database |
| Site config | `Tests/Acceptance/Fixtures/sites/<site-name>/` | Site configuration directories copied to `config/sites/`. In `config.yaml`, `__VERSION__` is replaced with the TYPO3 version and `__SITENAME__` with the project's `DDEV_SITENAME`. Use a relative `base: /` - an absolute hostname in `base` breaks as soon as the project's hostname changes (e.g. in a `git worktree` checkout). The older `VERSION_PLACEHOLDER` placeholder still works but is deprecated in favor of `__VERSION__`. |
| Shell scripts | `Tests/Acceptance/Fixtures/*.sh` | Executed during setup (failures are logged but don't abort the installation) |

## Application context

Every installed instance runs with `TYPO3_CONTEXT=Development`, set via
`docker-compose.typo3-setup.yaml`. `ddev config --web-environment-add=TYPO3_CONTEXT=Production`
does **not** override it - add-on-provided compose files are merged after
DDEV's own config-derived one, so the add-on's value always wins. To override
it, add your own compose file that sorts after `docker-compose.typo3-setup.yaml`
(survives `ddev add-on get` updates, since it isn't a file the add-on manages):

```yaml
# .ddev/docker-compose.zz-context-override.yaml
services:
  web:
    environment:
      - TYPO3_CONTEXT=Production
```

Then run `ddev restart` to apply it.

## Avoiding CS-fixer churn on `.ddev/`

If your project runs `php-cs-fixer` (or a similar tool) on the whole
repository, it will also reformat the files this add-on manages under
`.ddev/` to match *your* project's rules - which may differ from the rules
this add-on's own files were written with. That produces a spurious diff on
every `ddev add-on get` update, and every `composer cgl`/fixer run dirties
files that aren't supposed to be edited locally anyway. Exclude `.ddev/` from
your fixer's paths to avoid this:

```php
$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__)
    ->exclude('.ddev');
```
