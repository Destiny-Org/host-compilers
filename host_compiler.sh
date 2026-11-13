#!/usr/bin/env bash
# Installs a host compiler (an upstream D compiler used to build Destiny)
# from the releases of this repository, Destiny-Org/host-compilers.
#
# Usage: host_compiler.sh <spec> [install-root]
#   or:  curl -fsSL https://raw.githubusercontent.com/Destiny-Org/host-compilers/main/host_compiler.sh | bash -s -- <spec>
#
#   spec          dmd, dmd-latest, dmd-<version>,
#                 ldc, ldc-latest, ldmd2, ldc-<version>
#   install-root  defaults to ~/host-compilers
#
# Creates <install-root>/<spec>/activate, which puts the compiler on PATH and
# sets DMD and DC; `deactivate` undoes it. Inside GitHub Actions the compiler
# is also added to GITHUB_PATH / GITHUB_ENV, like a setup action would.
#
# The mirror holds only the versions listed below. To add one, add it here
# and run the "Mirror host compilers" workflow of this repository.

set -euo pipefail

# Mirrored versions. The last entry of each list is what "latest" means.
DMD_VERSIONS="2.079.1 2.095.0 2.097.1 2.111.0 2.112.1 2.113.1"
LDC_VERSIONS="1.41.0"

MIRROR="${HOST_COMPILER_MIRROR:-https://github.com/Destiny-Org/host-compilers/releases/download}"

# Platform name used in asset file names: linux, osx, windows or freebsd.
host_os() {
    case "$(uname -s)" in
        Linux) echo linux ;;
        Darwin) echo osx ;;
        FreeBSD) echo freebsd ;;
        MINGW*|MSYS*|CYGWIN*) echo windows ;;
        *) echo "unsupported OS: $(uname -s)" >&2; return 1 ;;
    esac
}

# Asset file name for a compiler <kind> <version> on <os>.
asset_name() {
    local kind="$1" version="$2" os="$3"
    case "$kind/$os" in
        dmd/linux)    echo "dmd.$version.linux.tar.xz" ;;
        dmd/osx)      echo "dmd.$version.osx.tar.xz" ;;
        dmd/freebsd)  echo "dmd.$version.freebsd-64.tar.xz" ;;
        dmd/windows)  echo "dmd.$version.windows.zip" ;;
        ldc/linux)    echo "ldc2-$version-linux-x86_64.tar.xz" ;;
        ldc/osx)      echo "ldc2-$version-osx-universal.tar.xz" ;;
        ldc/windows)  echo "ldc2-$version-windows-multilib.7z" ;;
        *) echo "no $kind build for $os" >&2; return 1 ;;
    esac
}

last_word() { local w; for w in $1; do :; done; echo "$w"; }

main() {
    local spec="${1:?usage: host_compiler.sh <spec> [install-root]}"
    local root="${2:-$HOME/host-compilers}"
    local kind version driver

    case "$spec" in
        dmd|dmd-latest) kind=dmd; version="$(last_word "$DMD_VERSIONS")"; driver=dmd ;;
        dmd-*)          kind=dmd; version="${spec#dmd-}"; driver=dmd ;;
        ldc|ldc-latest) kind=ldc; version="$(last_word "$LDC_VERSIONS")"; driver=ldmd2 ;;
        ldmd2)          kind=ldc; version="$(last_word "$LDC_VERSIONS")"; driver=ldmd2 ;;
        ldc-*)          kind=ldc; version="${spec#ldc-}"; driver=ldmd2 ;;
        *) echo "unknown compiler: $spec" >&2; exit 1 ;;
    esac

    local known="$DMD_VERSIONS"; [ "$kind" = ldc ] && known="$LDC_VERSIONS"
    case " $known " in
        *" $version "*) ;;
        *) echo "$kind $version is not mirrored (mirrored: $known)" >&2; exit 1 ;;
    esac

    local os asset dir
    os="$(host_os)"
    asset="$(asset_name "$kind" "$version" "$os")"
    dir="$root/$spec"

    if [ ! -e "$dir/activate" ]; then
        echo "Installing $kind $version for $os from $MIRROR" >&2
        mkdir -p "$dir"
        curl -fsSL --retry 5 --retry-delay 5 --connect-timeout 10 \
            "$MIRROR/$kind-$version/$asset" -o "$dir/$asset"
        case "$asset" in
            *.tar.xz) tar -C "$dir" -xJf "$dir/$asset" ;;
            *.zip)    unzip -q "$dir/$asset" -d "$dir" ;;
            *.7z)     7z x -y -o"$dir" "$dir/$asset" > /dev/null ;;
        esac
        rm -f "$dir/$asset"
    fi

    # Find the directory holding the compiler driver.
    local exe="" bindir
    [ "$os" = windows ] && exe=".exe"
    bindir="$(dirname "$(find "$dir" -type f -name "$driver$exe" | sort | tail -n1)")"
    if [ ! -x "$bindir/$driver$exe" ]; then
        echo "could not find $driver in $dir" >&2; exit 1
    fi
    local dc=dmd; [ "$kind" = ldc ] && dc=ldc2

    cat > "$dir/activate" <<EOF
_HOST_COMPILER_OLD_PATH="\$PATH"
export PATH="$bindir:\$PATH"
export DMD="$driver"
export DC="$dc"
deactivate() { export PATH="\$_HOST_COMPILER_OLD_PATH"; unset DMD DC; unset -f deactivate; }
EOF

    if [ -n "${GITHUB_PATH:-}" ]; then
        echo "$bindir" >> "$GITHUB_PATH"
        { echo "DMD=$driver"; echo "DC=$dc"; } >> "$GITHUB_ENV"
    fi
    echo "$dir/activate"
}

# Run unless sourced (mirror.sh sources this file for the version lists).
if [ "${BASH_SOURCE[0]:-$0}" = "$0" ] || [ -z "${BASH_SOURCE[0]:-}" ]; then
    main "$@"
fi
