<div align="center">

ddev-typo3-multi-version-extension
===============================

[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/konradmichalik/ddev-typo3-multi-version-extension/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/konradmichalik/ddev-typo3-multi-version-extension/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/konradmichalik/ddev-typo3-multi-version-extension)](https://github.com/konradmichalik/ddev-typo3-multi-version-extension/commits)
[![release](https://img.shields.io/github/v/release/konradmichalik/ddev-typo3-multi-version-extension)](https://github.com/konradmichalik/ddev-typo3-multi-version-extension/releases/latest)
</div>

## What is `ddev-typo3-multi-version-extension`?

ddev-typo3-multi-version-extension is a DDEV add-on that provides a multi-version TYPO3 environment. With this feature, it is possible to develop and test your extension with different TYPO3 versions at the same time.

## Support

- TYPO3 11.5
- TYPO3 12.4
- TYPO3 13.4
- TYPO3 14.3

## Requirements

- Extension key as DDEV project name, e.g. `custom-extension`
- `apache-fpm` as webserver type
- a valid `composer.json` file in the project root directory

You may use the following command to create a new DDEV project with the required settings:

```shell
ddev config --project-type=php --docroot=public --webserver-type=apache-fpm --project-name=custom-extension
```

## 🔥 Installation

Install the add-on with the following command:

```shell
ddev add-on get konradmichalik/ddev-typo3-multi-version-extension && ddev restart
```

After the installation, you can use the following command to open the intro page:

```shell
ddev launch
```

To install TYPO3 instances, use the following command:

```shell
ddev install all
# or for a specific version
ddev install 12
```

You can also rebuild a single version as a Composer-free (TER-style) instance with
`ddev install 13 --classic` — see [🧩 Classic mode](#-classic-mode-non-composer).

![Screencast](./images/screencast.gif)

For a detailed console output, use the following command:

```shell
ddev install 12 -v
````

### Updating

Run `ddev add-on get konradmichalik/ddev-typo3-multi-version-extension && ddev restart` again to pick up add-on updates in an existing project.

Files that ship with a `#ddev-generated` marker (e.g. `.ddev/.setup/scripts/utils.sh`, `.ddev/.setup/templates/index.php`, the `commands/web/*` wrappers) are overwritten on every update. If you need to customize one of them, remove that marker line from your project's copy — DDEV will then leave the file alone on future updates.

## ⚙ Configuration

By default, a blank TYPO3 instance will be installed for each version. They are only two extensions installed:

- your **main extension** from the project root (symlinked)
- a demo **sitepackage extension** in from the `Tests/Acceptance/Fixtures/packages` directory

Use this sitepackage to test the features of your main extension. You can adjust it to your needs in `Tests/Acceptance/Fixtures/packages/sitepackage/`.

If you need more extensions for your setup, you can place them in the `Tests/Acceptance/Fixtures/packages` directory or adjust the `ddev install` command. Within the e.g. the [.install-12](commands/web/.install-12) file, you can adjust the `composer require` command to fit your needs.

> [!NOTE]
> You may not need all TYPO3 versions? You can remove the unwanted versions from the `TYPO3_VERSIONS` variable in [.ddev/docker-compose.typo3-setup.yaml](docker-compose.typo3-setup.yaml).

Items from your main extension's root directory are symlinked into the TYPO3 instance, except the ones listed in the `SYMLINK_EXCLUSIONS` variable in [.ddev/docker-compose.typo3-setup.yaml](docker-compose.typo3-setup.yaml). It defaults to `Documentation Documentation-GENERATED-temp var vendor public`, so a local `vendor/` or `public/` directory in your extension repository is not linked into the instance's own composer/web-root structure.

### Demo content

Pass `--demo` to `ddev install` to populate the instance with a demo site instead of a single blank page. The demo step always drops and rebuilds the instance rather than layering onto an existing one, so re-running it is deterministic.

```shell
ddev install 13 --demo
ddev install 13 --demo=bootstrap
ddev install all --demo
```

Profiles:

| Profile | Result |
|---|---|
| `introduction` (default) | Installs [`typo3/cms-introduction`](https://extensions.typo3.org/extension/introduction) and removes the generated `main` site, since the Introduction Package brings its own. **Not available on TYPO3 14** - no released version supports it yet, so `--demo`/`--demo=introduction` automatically falls back to the `bootstrap` profile on 14 with a message. |
| `bootstrap` | Installs [`bk2k/bootstrap-package`](https://packagist.org/packages/bk2k/bootstrap-package) only - a themed but otherwise empty site. Works on every supported version. |
| `custom` | Installs no demo package; relies entirely on your own `Tests/Acceptance/Fixtures/` fixtures (see below). |

### Project-specific customizations

Copy [.ddev/.setup/project.sh.example](.setup/project.sh.example) to `.ddev/.setup/project.sh` to customize the install without touching `utils.sh` - `project.sh` isn't managed by the add-on, so it survives `ddev add-on get` upgrades. Supported variables:

| Variable | Effect |
|---|---|
| `ADDITIONAL_PACKAGES` | Extra composer packages installed alongside the base install |
| `SITEPACKAGE_PACKAGES` | Replaces the default `test/sitepackage` when set |
| `COMPOSER_CONFIG` | Extra `composer config` entries |
| `TYPO3_SETTINGS` | Extra `typo3 configuration:set` calls |
| `FIXTURE_EXTENSION_DIRS` | Extra directories (besides `Tests/Acceptance/Fixtures/packages`) whose subdirectories get symlinked in as additional extensions |

`$VERSION` in a package constraint expands per version at install time - write it single-quoted (e.g. `'typo3/cms-reports:^$VERSION'`) so it isn't expanded early.

### Install hooks

For install steps that don't fit a variable in `project.sh`, add a script at `.ddev/.setup/hooks/<name>.sh` - it's sourced automatically if present, so it has access to `$VERSION`, `$BASE_PATH`, `$TYPO3_BIN`, `$DATABASE`, `$EXTENSION_KEY` and the `message`/`_progress`/`_done` helpers. Unlike the best-effort `Tests/Acceptance/Fixtures/*.sh` scripts, a failing command in a hook aborts the install with its output shown, not silently swallowed.

| Hook | Runs |
|---|---|
| `pre-install` | Before the environment is set up (`$TYPO3_BIN`/`$DATABASE` are not yet available at this point) |
| `post-composer` | After the base composer packages are installed |
| `post-typo3-setup` | After TYPO3 itself is set up, before fixture import |
| `post-install` | Last, after fixtures, site configs and the schema update |

### Avoiding CS-fixer churn on `.ddev/`

If your project runs `php-cs-fixer` (or a similar tool) on the whole repository, it will also reformat the files this add-on manages under `.ddev/` to match *your* project's rules - which may differ from the rules this add-on's own files were written with. That produces a spurious diff on every `ddev add-on get` update, and every `composer cgl`/fixer run dirties files that aren't supposed to be edited locally anyway. Exclude `.ddev/` from your fixer's paths to avoid this:

```php
$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__)
    ->exclude('.ddev');
```

### Fixtures

During installation, fixture data from `Tests/Acceptance/Fixtures/` is automatically imported. The following types are supported:

| Type | Location | Description |
|------|----------|-------------|
| XML | `Tests/Acceptance/Fixtures/*.xml` | TYPO3 export files, imported via `impexp:import` |
| SQL | `Tests/Acceptance/Fixtures/*.sql` | Raw SQL files, imported directly into the database |
| Site config | `Tests/Acceptance/Fixtures/sites/<site-name>/` | Site configuration directories copied to `config/sites/`. In `config.yaml`, `__VERSION__` is replaced with the TYPO3 version and `__SITENAME__` with the project's `DDEV_SITENAME`. Use a relative `base: /` - an absolute hostname in `base` breaks as soon as the project's hostname changes (e.g. in a `git worktree` checkout). The older `VERSION_PLACEHOLDER` placeholder still works but is deprecated in favor of `__VERSION__`. |
| Shell scripts | `Tests/Acceptance/Fixtures/*.sh` | Executed during setup (failures are logged but don't abort the installation) |

## 🧩 Classic mode (non-Composer)

Most extensions on the TER are installed in **classic mode** (non-Composer), where TYPO3
resolves classes from the `autoload` key in `ext_emconf.php` instead of Composer's PSR-4
autoloader. Bugs that only surface there — a missing or drifted `ext_emconf.php` autoload
key, an extension key mismatch, or a runtime dependency that only exists because Composer
happened to pull it in — stay invisible in the default Composer-mode instances.

Append `--classic` to an install to (re)build that version as a Composer-free instance:

    ddev install 13 --classic

This **replaces the version 13 slot in place**: TYPO3 sources are downloaded from
`get.typo3.org` (no `composer install`), your extension is symlinked into
`typo3conf/ext/<extension_key>` and activated the classic way — exactly like on the TER.
On TYPO3 v12/v13, class loading is driven by the `autoload` key in `ext_emconf.php`;
on TYPO3 v14, classic mode requires a `composer.json` in the extension instead. The
instance keeps the same hostname:

    https://13.<extension-name>.ddev.site

The regular commands detect the mode automatically:

    ddev 13 typo3 cache:flush
    ddev launch 13

To switch back to a Composer instance, re-run the install without the flag:

    ddev install 13

**Notes**

- A version slot is either Composer or classic at a time, not both — rebuild to switch.
  Different versions can still run in different modes side by side (e.g. Composer 13 and
  classic 14).
- Classic mode is **per version** and is not part of `ddev install all`.
- Only TYPO3 v12+ is supported in classic mode.
- On TYPO3 v14, classic mode only recognises extensions that ship a `composer.json` —
  make sure your extension provides one before testing v14 in classic mode.
- `composer` commands (`ddev 13 composer ...`) are unavailable while a slot is in classic mode.

## 📊 Usage

You can launch a TYPO3 instance in your browser with the following command:

```shell
ddev launch 11
ddev launch 12
ddev launch 13
ddev launch 14
```

If you want to open the TYPO3 backend directly, use the following command:

```shell
ddev launch 13 /typo3
```

If you want to execute a console command in a specific TYPO3 instance, use the following command:

```shell
ddev 11 composer update
ddev 12 typo3 cache:flush
ddev 13 ls -la
```

You can also run a command in all TYPO3 instances at once:

```shell
ddev all typo3 cache:flush
```

## 🌳 Git Worktree Support

Since `.ddev/` is committed to your repository, a plain `git worktree add` checkout would normally share the same DDEV project name (and therefore the same hostnames) as your primary checkout - only one of them could run at a time. This add-on avoids baking the project name into any of its own files, but DDEV's own `.ddev/config.yaml` still needs one adjustment, and each worktree needs its own hostnames.

Requires DDEV `>= v1.24.10` (the version constraint declared by this add-on).

### One-time setup

Tell DDEV to derive the project name from the directory instead of a fixed `name:` in `.ddev/config.yaml` - either per project by removing the `name:` line from `.ddev/config.yaml`, or globally for all future projects:

```shell
ddev config global --omit-project-name-by-default=true
```

### Per-worktree setup

Create the worktree as a **sibling** of your primary checkout (never nested inside it), using a directory name that's safe as a DNS label (lowercase letters, digits, hyphens):

```shell
git worktree add ../my-feature-branch feature/my-feature
cd ../my-feature-branch
ddev worktree-init
ddev restart
ddev install all
```

`ddev worktree-init` regenerates this checkout's router hostnames so they don't collide with the primary checkout's; `.Build/` is gitignored, so every worktree needs its own `ddev install`.

### Resource expectations

Each worktree runs its own `web` and `db` container, plus roughly one full TYPO3 distribution per configured version under `.Build/`. Running several worktrees at once multiplies both. `ddev poweroff` stops *all* DDEV projects, not just the current one - worth knowing if several worktrees (or agents) are meant to keep running in parallel.

### Upgrading an existing project

If you installed this add-on before worktree support was added, re-run the installation command to pick up the fixes:

```shell
ddev add-on get konradmichalik/ddev-typo3-multi-version-extension && ddev restart
```

See [Updating](#updating) above for which files get overwritten.

## Background

The TYPO3 instances are located in the `.Build/` directory. The main extension is symlinked from the root directory to the `.Build/` directory. 

```text
.
└── .Build/
    ├── 11/
    │   ├── config/
    │   ├── packages/
    │   │   ├── sitepackage/
    │   │   └── your-ext/
    │   ├── public/
    │   ├── var/
    │   ├── vendor/
    │   ├── composer.json
    │   └── composer.lock
    └── ...
```

**Contributed and maintained by `@konradmichalik`**
