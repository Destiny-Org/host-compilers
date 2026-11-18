#!/usr/bin/env bash
# Installs a host compiler (a released Destiny compiler, used to build the
# next one) from the releases of this repository, Destiny-Org/host-compilers.
#
# Usage: host_compiler.sh <spec> [install-root]
#   or:  curl -fsSL https://raw.githubusercontent.com/Destiny-Org/host-compilers/main/host_compiler.sh | bash -s -- <spec>
#
#   spec          destiny, destiny-latest, destiny-<version>
#   install-root  defaults to ~/host-compilers
#
# Creates <install-root>/<spec>/activate, which puts the compiler on PATH and
# sets DMD and DC (the variable names the build scripts read); `deactivate`
# undoes it. Inside GitHub Actions the compiler is also added to
# GITHUB_PATH / GITHUB_ENV.
#
# Each version is a release of this repository tagged destiny-<version>,
# holding the destiny64 package made by the destiny repository's
# ci/package.sh (destiny64-<version>-linux.tar.xz). Only Linux x86_64 is
# packaged. To add a version, upload its package to a new release and add
# the version below.

set -euo pipefail

# Released host compilers. The last entry is what "latest" means.
DESTINY_VERSIONS="2.115.0-master"

MIRROR="${HOST_COMPILER_MIRROR:-https://github.com/Destiny-Org/host-compilers/releases/download}"

last_word() { local w; for w in $1; do :; done; echo "$w"; }

main() {
    local spec="${1:?usage: host_compiler.sh <spec> [install-root]}"
    local root="${2:-$HOME/host-compilers}"
    local version

    case "$spec" in
        destiny|destiny-latest) version="$(last_word "$DESTINY_VERSIONS")" ;;
        destiny-*)              version="${spec#destiny-}" ;;
        *) echo "unknown host compiler: $spec (use destiny-<version>)" >&2; exit 1 ;;
    esac

    case " $DESTINY_VERSIONS " in
        *" $version "*) ;;
        *) echo "destiny $version is not released here (released: $DESTINY_VERSIONS)" >&2; exit 1 ;;
    esac

    if [ "$(uname -s)" != Linux ] || [ "$(uname -m)" != x86_64 ]; then
        echo "destiny64 host compilers exist for Linux x86_64 only" >&2; exit 1
    fi

    local asset="destiny64-$version-linux.tar.xz"
    local dir="$root/$spec"

    if [ ! -e "$dir/activate" ]; then
        echo "Installing destiny $version from $MIRROR" >&2
        mkdir -p "$dir"
        curl -fsSL --retry 5 --retry-delay 5 --connect-timeout 10 \
            "$MIRROR/destiny-$version/$asset" -o "$dir/$asset"
        tar -C "$dir" -xJf "$dir/$asset"
        rm -f "$dir/$asset"
    fi

    local bindir="$dir/destiny64/bin"
    if [ ! -x "$bindir/destiny" ]; then
        echo "could not find destiny in $dir" >&2; exit 1
    fi

    cat > "$dir/activate" <<EOF
_HOST_COMPILER_OLD_PATH="\$PATH"
export PATH="$bindir:\$PATH"
export DMD="destiny"
export DC="destiny"
deactivate() { export PATH="\$_HOST_COMPILER_OLD_PATH"; unset DMD DC; unset -f deactivate; }
EOF

    if [ -n "${GITHUB_PATH:-}" ]; then
        echo "$bindir" >> "$GITHUB_PATH"
        { echo "DMD=destiny"; echo "DC=destiny"; } >> "$GITHUB_ENV"
    fi
    echo "$dir/activate"
}

main "$@"
