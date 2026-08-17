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

![Screencast](./images/screencast.gif)

For a detailed console output, use the following command:

```shell
ddev install 12 -v
````

## ⚙ Configuration

By default, a blank TYPO3 instance will be installed for each version. They are only two extensions installed:

- your **main extension** from the project root (symlinked)
- a demo **sitepackage extension** in from the `Tests/Acceptance/Fixtures/packages` directory

Use this sitepackage to test the features of your main extension. You can adjust it to your needs in `Tests/Acceptance/Fixtures/packages/sitepackage/`.

If you need more extensions for your setup, you can place them in the `Tests/Acceptance/Fixtures/packages` directory or adjust the `ddev install` command. Within the e.g. the [.install-12](commands/web/.install-12) file, you can adjust the `composer require` command to fit your needs.

> [!NOTE]
> You may not need all TYPO3 versions? You can remove the unwanted versions from the `TYPO3_VERSIONS` variable in [.ddev/docker-compose.typo3-setup.yaml](docker-compose.typo3-setup.yaml).

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

### Fixtures

During installation, fixture data from `Tests/Acceptance/Fixtures/` is automatically imported. The following types are supported:

| Type | Location | Description |
|------|----------|-------------|
| XML | `Tests/Acceptance/Fixtures/*.xml` | TYPO3 export files, imported via `impexp:import` |
| SQL | `Tests/Acceptance/Fixtures/*.sql` | Raw SQL files, imported directly into the database |
| Site config | `Tests/Acceptance/Fixtures/sites/<site-name>/` | Site configuration directories copied to `config/sites/`. Use `VERSION_PLACEHOLDER` in `config.yaml` to insert the TYPO3 version automatically. |
| Shell scripts | `Tests/Acceptance/Fixtures/*.sh` | Executed during setup (failures are logged but don't abort the installation) |

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
