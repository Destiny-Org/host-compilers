#!/usr/bin/env bash
# Copies the host compilers listed in host_compiler.sh from their upstream
# release servers to GitHub releases of this repository, one release
# per compiler version (tags like dmd-2.113.1 and ldc-1.41.0).
#
# This is the only script that downloads from upstream. It runs in the
# "Mirror host compilers" workflow; run that workflow again whenever a version
# is added to host_compiler.sh. Versions
# that are already mirrored are skipped. It needs the GitHub CLI (`gh`) with
# write access to the target repository (GH_TOKEN in GitHub Actions).
#
# The compilers are distributed under the Boost Software License 1.0 (dmd)
# and BSD-style licences (ldc), which allow redistribution.
#
# Usage: mirror.sh [repo]   (default: Destiny-Org/host-compilers)

set -euo pipefail

repo="${1:-Destiny-Org/host-compilers}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=host_compiler.sh
source "$here/host_compiler.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

upstream_url() {
    local kind="$1" version="$2" asset="$3"
    case "$kind" in
        dmd) echo "https://downloads.dlang.org/releases/2.x/$version/$asset" ;;
        ldc) echo "https://github.com/ldc-developers/ldc/releases/download/v$version/$asset" ;;
    esac
}

mirror_one() {
    local kind="$1" version="$2" platforms="$3"
    local tag="$kind-$version" os asset files=()
    if [ "${MIRROR_FORCE:-0}" != 1 ] && gh release view "$tag" --repo "$repo" > /dev/null 2>&1; then
        echo "$tag is already mirrored, skipped (set MIRROR_FORCE=1 to redo it)" >&2
        return
    fi
    for os in $platforms; do
        asset="$(asset_name "$kind" "$version" "$os")" || continue
        if curl -fsSL --retry 3 "$(upstream_url "$kind" "$version" "$asset")" -o "$work/$asset"; then
            files+=("$work/$asset")
        else
            echo "warning: no upstream $asset, skipped" >&2
        fi
    done
    [ "${#files[@]}" -gt 0 ] || { echo "nothing to upload for $tag" >&2; return; }

    (cd "$work" && sha256sum "${files[@]##*/}") > "$work/SHA256SUMS-$tag"
    files+=("$work/SHA256SUMS-$tag")

    if gh release view "$tag" --repo "$repo" > /dev/null 2>&1; then
        gh release upload "$tag" --repo "$repo" --clobber "${files[@]}"
    else
        gh release create "$tag" --repo "$repo" --title "$kind $version" \
            --notes "Mirror of the upstream $kind $version release, used as a host compiler to build Destiny." \
            "${files[@]}"
    fi
    rm -f "${files[@]}"
}

for v in $DMD_VERSIONS; do mirror_one dmd "$v" "linux osx windows freebsd"; done
for v in $LDC_VERSIONS; do mirror_one ldc "$v" "linux osx windows"; done
echo "Done: https://github.com/$repo/releases"
