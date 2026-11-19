# host-compilers

Destiny's compiler is written in Destiny, so building it needs an existing
Destiny compiler: the *host compiler*. This repository holds released
Destiny compilers (the `destiny64` packages) as GitHub releases, one per
version, tagged `destiny-<version>`. Destiny's CI installs one and uses it to
build the next compiler, which then rebuilds itself.

No upstream D compiler is used anywhere in Destiny's builds.

This repository is public on purpose, so CI jobs can download the packages
without a token.

Only Linux x86_64 is packaged.

## Installing a host compiler

[host_compiler.sh](host_compiler.sh) installs a released compiler and writes
an `activate` script:

```
curl -fsSL https://raw.githubusercontent.com/Destiny-Org/host-compilers/main/host_compiler.sh | bash -s -- destiny
source ~/host-compilers/destiny/activate
```

In Destiny-Org/destiny, `ci/host_compiler.sh destiny` does the same.

## Which versions

`DESTINY_VERSIONS` at the top of [host_compiler.sh](host_compiler.sh). The
last entry is what `destiny` and `destiny-latest` mean.

## Adding a version

1. Build and package the compiler in Destiny-Org/destiny
   (`ci/run.sh build`, then `ci/package.sh dist`). This produces
   `destiny64-<version>-linux.tar.xz`.
2. Create a release of this repository tagged `destiny-<version>` and upload
   that file to it.
3. Add the version to `DESTINY_VERSIONS` and push to `main`.

## License

The scripts in this repository are under the Mozilla Public License 2.0 ([LICENSE](LICENSE)).
The packages are Destiny releases; each contains its own LICENSE and NOTICE
(Mozilla Public License 2.0, with the original D files under the Boost Software
License 1.0).
