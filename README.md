# host-compilers

Destiny's compiler is written in D, so building it needs an existing D
compiler: the *host compiler*. This repository keeps copies of the upstream
host compilers that Destiny's CI and `bootstrap.sh` use, as GitHub releases,
so builds do not depend on upstream download servers.

Each release holds one compiler version for Linux, macOS, Windows and
FreeBSD (where available), plus a `SHA256SUMS-<tag>` file:

- `dmd-<version>`, for example `dmd-2.113.1`
- `ldc-<version>`, for example `ldc-1.41.0`

## Which versions

The list lives in one place: `DMD_VERSIONS` and `LDC_VERSIONS` at the top of
[ci/host_compiler.sh](https://github.com/Destiny-Org/destiny/blob/main/ci/host_compiler.sh)
in Destiny-Org/destiny. That script also installs a mirrored compiler:

```
ci/host_compiler.sh dmd-2.113.1
source ~/host-compilers/dmd-2.113.1/activate
```

## Updating the mirror

1. Add the version to `ci/host_compiler.sh` in Destiny-Org/destiny.
2. In this repository, open **Actions → Mirror host compilers → Run workflow**.

Versions already mirrored are skipped. Tick **force** to download and upload
everything again.

## Licences

dmd is distributed under the Boost Software License 1.0 and LDC under
BSD-style licences; both allow redistribution. The archives are unmodified
copies of the upstream releases.
