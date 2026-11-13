# host-compilers

Destiny's compiler is written in D, so building it needs an existing D
compiler: the *host compiler*. This repository keeps copies of the upstream
host compilers that Destiny's CI and `bootstrap.sh` use, as GitHub releases,
so builds do not depend on upstream download servers.

This repository is public on purpose: it only holds unmodified upstream
compilers, and public release files can be downloaded by any CI job without
a token.

Destiny uses a single host compiler, **dmd 2.113.1** (release `dmd-2.113.1`),
for Linux, macOS, Windows and FreeBSD, plus a `SHA256SUMS-dmd-2.113.1` file.
Older releases here are left over from earlier setups and are no longer used.

## Installing a host compiler

[host_compiler.sh](host_compiler.sh) installs a mirrored compiler and writes
an `activate` script:

```
curl -fsSL https://raw.githubusercontent.com/Destiny-Org/host-compilers/main/host_compiler.sh | bash -s -- dmd
source ~/host-compilers/dmd/activate
```

In Destiny-Org/destiny, `ci/host_compiler.sh dmd` does the same.

## Which versions

`DMD_VERSIONS` at the top of [host_compiler.sh](host_compiler.sh), currently
just `2.113.1`. The last entry is what `dmd` and `dmd-latest` mean. The script
still supports LDC (`LDC_VERSIONS`), but none is mirrored.

## Updating the mirror

Change the version lists in `host_compiler.sh` and push to `main`. The
**Mirror host compilers** workflow runs automatically and uploads the new
versions; versions already mirrored are skipped. It can also be started by
hand from the Actions tab, with **force** to upload everything again.

## Licences

dmd is distributed under the Boost Software License 1.0 and LDC under
BSD-style licences; both allow redistribution. The archives are unmodified
copies of the upstream releases.
