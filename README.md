# host-compilers

Destiny's compiler is written in D, so building it needs an existing D
compiler: the *host compiler*. This repository keeps copies of the upstream
host compilers that Destiny's CI and `bootstrap.sh` use, as GitHub releases,
so builds do not depend on upstream download servers.

This repository is public on purpose: it only holds unmodified upstream
compilers, and public release files can be downloaded by any CI job without
a token.

Each release holds one compiler version for Linux, macOS, Windows (`.zip`, or
`.7z` for recent dmd releases) and
FreeBSD (where available), plus a `SHA256SUMS-<tag>` file:

- `dmd-<version>`, for example `dmd-2.113.1`
- `ldc-<version>`, for example `ldc-1.41.0`

## Installing a host compiler

[host_compiler.sh](host_compiler.sh) installs a mirrored compiler and writes
an `activate` script:

```
curl -fsSL https://raw.githubusercontent.com/Destiny-Org/host-compilers/main/host_compiler.sh | bash -s -- dmd
source ~/host-compilers/dmd/activate
```

In Destiny-Org/destiny, `ci/host_compiler.sh dmd` does the same.

## Which versions

`DMD_VERSIONS` and `LDC_VERSIONS` at the top of
[host_compiler.sh](host_compiler.sh). The last entry of each list is what
`dmd`, `dmd-latest`, `ldc` and `ldc-latest` mean.

## Updating the mirror

Change the version lists in `host_compiler.sh` and push to `main`. The
**Mirror host compilers** workflow runs automatically and uploads the new
versions; versions already mirrored are skipped. It can also be started by
hand from the Actions tab, with **force** to upload everything again.

## Licences

dmd is distributed under the Boost Software License 1.0 and LDC under
BSD-style licences; both allow redistribution. The archives are unmodified
copies of the upstream releases.
