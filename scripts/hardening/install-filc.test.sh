#!/usr/bin/env bash
# Tests scripts/hardening/install-filc.sh offline: a fixture tarball served through file:// (FILC_URL_BASE) with a fixture versions.env.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
inst="$root/scripts/hardening/install-filc.sh"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/install-filc-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/src/filc/bin" "$tmp/serve"
printf '#!/bin/sh\necho fake\n' > "$tmp/src/filc/bin/clang"; chmod +x "$tmp/src/filc/bin/clang"
tar -cf "$tmp/serve/fake.tar" -C "$tmp/src" filc
good=$( (sha256sum "$tmp/serve/fake.tar" 2>/dev/null || shasum -a 256 "$tmp/serve/fake.tar") | cut -d' ' -f1)
mkenv() { # <sha>
    printf 'FILC_VERSION=9.9\nFILC_LINUX_X86_64_ASSET=fake.tar\nFILC_LINUX_X86_64_SHA256=%s\nFILC_LINUX_AARCH64_ASSET=fake.tar\nFILC_LINUX_AARCH64_SHA256=%s\n' "$1" "$1" > "$tmp/versions.env"
}
export FILC_URL_BASE="file://$tmp/serve" FILC_VERSIONS_ENV="$tmp/versions.env" FILC_OS=Linux FILC_ARCH=x86_64 FILC_DOWNLOAD_DIR="$tmp/dl"

pass=0; failed=0
check() { if [ "$2" = 0 ]; then pass=$((pass + 1)); else failed=$((failed + 1)); echo "FAIL: $1"; fi; }

mkenv 0000000000000000000000000000000000000000000000000000000000000000
out=$(bash "$inst" --prefix "$tmp/bad" 2>&1); rc=$?
[ $rc = 1 ]; check "sha mismatch exits 1" $?
[ ! -e "$tmp/bad" ]; check "sha mismatch extracts nothing" $?
[ -f "$tmp/dl/fake.tar" ]; check "sha mismatch keeps the download" $?

mkenv "$good"
out=$(bash "$inst" --prefix "$tmp/ok" 2>"$tmp/err1"); rc=$?
[ $rc = 0 ]; check "matching sha exits 0" $?
[ "$out" = "$tmp/ok/filc/bin/clang" ]; check "matching sha prints the clang path" $?
[ -x "$tmp/ok/filc/bin/clang" ]; check "matching sha extracts" $?

rm -f "$tmp/serve/fake.tar" "$tmp/dl/fake.tar"
out2=$(bash "$inst" --prefix "$tmp/ok" 2>"$tmp/err2"); rc=$?
[ $rc = 0 ] && [ "$out2" = "$out" ]; check "second run prints the same path without the tarball" $?
grep -q reusing "$tmp/err2"; check "second run reuses" $?

FILC_ARCH=riscv64 bash "$inst" --prefix "$tmp/arch" >/dev/null 2>&1; rc=$?
[ $rc = 2 ]; check "unknown arch exits 2" $?
FILC_OS=Darwin bash "$inst" --prefix "$tmp/os" >/dev/null 2>&1; rc=$?
[ $rc = 2 ]; check "non-Linux exits 2" $?

echo "$pass passed, $failed failed"
[ $failed = 0 ]
