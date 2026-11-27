#!/usr/bin/env bash
# Plan 020 step 3: installs the pinned Fil-C release (versions.env) under tmp/hardening/filc/<version> (or --prefix DIR) and prints
# the path of its clang driver. The tarball is downloaded into tmp/hardening/filc/, checked against the pinned sha256 (a mismatch
# exits 1, keeps the file and extracts nothing), then extracted; a verified install is reused. Linux x86_64/aarch64 only (exit 2
# otherwise). Test overrides: FILC_URL_BASE (default the GitHub release URL), FILC_VERSIONS_ENV, FILC_ARCH, FILC_OS, FILC_DOWNLOAD_DIR.
usage() { echo "usage: $0 [--prefix DIR]" >&2; exit 2; }

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
prefix=""
while [ $# -gt 0 ]; do
    case "$1" in
        --prefix) [ $# -ge 2 ] || usage; prefix=$2; shift ;;
        *) usage ;;
    esac
    shift
done
. "${FILC_VERSIONS_ENV:-$root/scripts/hardening/versions.env}"
[ -n "$prefix" ] || prefix="$root/tmp/hardening/filc/$FILC_VERSION"
dl="${FILC_DOWNLOAD_DIR:-$root/tmp/hardening/filc}"
base="${FILC_URL_BASE:-https://github.com/pizlonator/fil-c/releases/download/v${FILC_VERSION}}"

[ "${FILC_OS:-$(uname -s)}" = Linux ] || { echo "install-filc: Fil-C ships Linux builds only" >&2; exit 2; }
case "${FILC_ARCH:-$(uname -m)}" in
    x86_64) asset=$FILC_LINUX_X86_64_ASSET; want=$FILC_LINUX_X86_64_SHA256 ;;
    aarch64) asset=$FILC_LINUX_AARCH64_ASSET; want=$FILC_LINUX_AARCH64_SHA256 ;;
    *) echo "install-filc: unsupported architecture ${FILC_ARCH:-$(uname -m)} (x86_64 and aarch64 only)" >&2; exit 2 ;;
esac

sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1; }
find_clang() { find "$prefix" -name clang \( -type f -o -type l \) -perm -u+x 2>/dev/null | sort | head -n 1; }
done_clang() {
    local c
    c=$(find_clang)
    [ -n "$c" ] || { echo "install-filc: no executable clang found under $prefix" >&2; exit 1; }
    echo "$c"
    exit 0
}

if [ -f "$prefix/.filc-verified" ] && [ "$(cat "$prefix/.filc-verified")" = "$want" ]; then
    echo "install-filc: reusing $prefix" >&2
    done_clang
fi

mkdir -p "$dl" || exit 1
file="$dl/$asset"
if [ ! -f "$file" ] || [ "$(sha "$file")" != "$want" ]; then
    echo "install-filc: downloading $base/$asset" >&2
    curl -fL -o "$file" "$base/$asset" || { echo "install-filc: download failed" >&2; exit 1; }
fi
got=$(sha "$file")
if [ "$got" != "$want" ]; then
    echo "install-filc: sha256 mismatch for $file (got $got, want $want); not extracting" >&2
    exit 1
fi
rm -rf "$prefix"; mkdir -p "$prefix" || exit 1
tar -xf "$file" -C "$prefix" || { echo "install-filc: extract failed" >&2; exit 1; }
echo "$want" > "$prefix/.filc-verified"
done_clang
