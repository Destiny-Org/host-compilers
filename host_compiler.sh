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
# packaged. Releases are published by the destiny repository's release
# workflow; any released version can be installed, and "latest" is the
# newest release of this repository.

set -euo pipefail

REPO="${HOST_COMPILER_REPO:-Destiny-Org/host-compilers}"

MIRROR="${HOST_COMPILER_MIRROR:-https://github.com/Destiny-Org/host-compilers/releases/download}"

main() {
    local spec="${1:?usage: host_compiler.sh <spec> [install-root]}"
    local root="${2:-$HOME/host-compilers}"
    local version

    case "$spec" in
        destiny|destiny-latest)
            # the newest release's tag, e.g. destiny-2.115.0
            # a token (GITHUB_TOKEN / GH_TOKEN) avoids the API's rate limit
            local auth=()
            local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
            [ -n "$token" ] && auth=(-H "Authorization: Bearer $token")
            version="$(curl -fsSL --retry 5 --connect-timeout 10 "${auth[@]}" \
                "https://api.github.com/repos/$REPO/releases/latest" |
                sed -n 's/.*"tag_name": *"destiny-\([^"]*\)".*/\1/p' | head -n1)"
            [ -n "$version" ] || { echo "no destiny release found in $REPO" >&2; exit 1; } ;;
        destiny-*) version="${spec#destiny-}" ;;
        *) echo "unknown host compiler: $spec (use destiny-<version>)" >&2; exit 1 ;;
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
            "$MIRROR/destiny-$version/$asset" -o "$dir/$asset" ||
            { echo "destiny $version is not released in $REPO (no $asset in release destiny-$version)" >&2; exit 1; }
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
