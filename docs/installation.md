# Console command `ddev install`

```shell
ddev install [<version>|all] [-v|--verbose] [--demo[=<profile>]] [--classic]
```

Installs a fresh TYPO3 instance for the given version, or rebuilds it if one
already exists in that slot. With no version argument, the lowest version in
`TYPO3_VERSIONS` is used (see [Configuration](configuration.md)).

Each Composer-mode install: wipes `.Build/<version>/`, symlinks the main
extension and the fixture packages from `Tests/Acceptance/Fixtures/packages/`
into it, runs `composer req typo3/cms-base-distribution:^<version>` plus the
sitepackage and any `ADDITIONAL_PACKAGES`, sets up TYPO3 non-interactively,
imports fixtures, and runs the schema update. Any repo-owned
[install hook](configuration.md#install-hooks) runs at the matching point in
that sequence.

## `<version>|all`

The TYPO3 major to install: `11`, `12`, `13` or `14`. `all` installs every
version listed in `TYPO3_VERSIONS`.

```shell
ddev install 13
ddev install all
```

Requesting a version that is not in `TYPO3_VERSIONS` fails with
`TYPO3 version '<version>' is not supported.` before anything is touched.

## `-v`, `--verbose`

Streams the full output of every install step instead of showing a spinner.
Useful when an install fails and the default spinner mode's captured log is
not enough context.

```shell
ddev install 12 -v
```

## `--demo[=<profile>]`

Populates the instance with a demo site instead of a single blank page. The
demo step always drops and rebuilds the instance rather than layering onto an
existing one, so re-running it is deterministic.

```shell
ddev install 13 --demo
ddev install 13 --demo=bootstrap
ddev install all --demo
```

| Profile | Result |
|---|---|
| `introduction` (default) | Installs [`typo3/cms-introduction`](https://extensions.typo3.org/extension/introduction) and removes the generated `main` site, since the Introduction Package brings its own. **Not available on TYPO3 14** - no released version supports it yet, so `--demo`/`--demo=introduction` automatically falls back to `bootstrap` on 14 with a warning message. |
| `bootstrap` | Installs [`bk2k/bootstrap-package`](https://packagist.org/packages/bk2k/bootstrap-package) only - a themed but otherwise empty site. Works on every supported version. |
| `custom` | Installs no demo package; relies entirely on your own `Tests/Acceptance/Fixtures/` fixtures. |

## `--classic`

Rebuilds the given version as a Composer-free (TER-style) instance instead of
the default Composer instance. See [Classic mode](classic-mode.md) for what
changes and its limitations.

```shell
ddev install 13 --classic
```

`--classic` cannot be combined with `all` (`Classic mode is per-version only`)
and is rejected for version `11` (`Classic mode requires TYPO3 v12 or higher.`).

To switch a slot back to a Composer instance, re-run the install without the
flag: `ddev install 13`.

## Security note: Composer advisory blocking is disabled

Every Composer install/require for a version slot runs with
`audit.block-insecure` set to `false`. Composer normally refuses to install
any package version flagged by a known security advisory - since instances
intentionally cover TYPO3 majors past their security-support window (to see
what changed across versions), that block would otherwise trigger on
essentially any install. This is about the disposable dev instance, not the
extension being tested: it never affects `composer audit` or advisory
handling in your own project outside `.Build/`.
