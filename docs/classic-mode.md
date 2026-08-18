# Classic mode (non-Composer)

Most extensions on the TER are installed in **classic mode** (non-Composer),
where TYPO3 resolves classes from the `autoload` key in `ext_emconf.php`
instead of Composer's PSR-4 autoloader. Bugs that only surface there - a
missing or drifted `ext_emconf.php` autoload key, an extension key mismatch,
or a runtime dependency that only exists because Composer happened to pull it
in - stay invisible in the default Composer-mode instances.

Append `--classic` to [`ddev install`](installation.md#--classic) to (re)build
that version as a Composer-free instance:

```shell
ddev install 13 --classic
```

This **replaces the version 13 slot in place**: TYPO3 sources are downloaded
from `get.typo3.org` (no `composer install`), your extension is symlinked
into `typo3conf/ext/<extension_key>` and activated the classic way - exactly
like on the TER. On TYPO3 v12/v13, class loading is driven by the `autoload`
key in `ext_emconf.php`; on TYPO3 v14, classic mode requires a `composer.json`
in the extension instead. The instance keeps the same hostname:

```text
https://13.<extension-name>.ddev.site
```

The regular commands detect the mode automatically:

```shell
ddev 13 typo3 cache:flush
ddev launch 13
```

To switch back to a Composer instance, re-run the install without the flag:

```shell
ddev install 13
```

## Non-core Composer dependencies

If your extension requires a package TYPO3 core doesn't already ship (e.g.
`symfony/var-dumper`), classic mode has no `vendor/` to resolve it from - the
class simply won't be found at runtime. Bundle such dependencies into your
extension with
[`eliashaeussler/typo3-vendor-bundler`](https://github.com/eliashaeussler/typo3-vendor-bundler)
before testing classic mode; the
[reusable release workflow](https://github.com/konradmichalik/reusable-github-actions)
mirrors the same bundling step for TER releases.

## Fixture packages without `ext_emconf.php`

TYPO3's classic-mode package discovery only recognizes directories containing
an `ext_emconf.php`. The default `sitepackage` fixture (and any project
fixture under `Tests/Acceptance/Fixtures/packages/`) ships only a
`composer.json`, so this add-on generates a minimal `ext_emconf.php` for it
automatically in classic mode - the fixture's own source files are never
modified.

## Notes

- A version slot is either Composer or classic at a time, not both - rebuild
  to switch. Different versions can still run in different modes side by side
  (e.g. Composer 13 and classic 14).
- Classic mode is **per version** and is not part of `ddev install all`.
- Only TYPO3 v12+ is supported in classic mode.
- On TYPO3 v14, classic mode only recognises extensions that ship a
  `composer.json` - make sure your extension provides one before testing v14
  in classic mode.
- `composer` commands (`ddev 13 composer ...`) are unavailable while a slot is
  in classic mode.
