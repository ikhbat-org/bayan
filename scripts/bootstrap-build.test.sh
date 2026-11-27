#!/usr/bin/env bash
# Tests scripts/bootstrap-build.sh: usage errors exit 2; a CC that fails makes stage 0 fail, named, exit 1; a real run
# (skipped with a reason when there is no C compiler) prints a stage-1 path whose --version is exactly "bayan <VERSION>". bash 3.2.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
s="$root/scripts/bootstrap-build.sh"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/bootstrap-build-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

rc=0; "$BASH" "$s" --bogus >/dev/null 2>&1 || rc=$?
[ $rc = 2 ] || fail "an unknown option exited $rc, not 2"
rc=0; "$BASH" "$s" --out >/dev/null 2>&1 || rc=$?
[ $rc = 2 ] || fail "--out without a value exited $rc, not 2"

printf '#!/bin/sh\necho boom >&2\nexit 1\n' > "$tmp/badcc"; chmod +x "$tmp/badcc"
rc=0; out="$(CC="$tmp/badcc" "$BASH" "$s" --out "$tmp/bad" 2>&1)" || rc=$?
[ $rc = 1 ] || fail "a failing CC exited $rc, not 1: $out"
grep -q 'stage 0' <<<"$out" || fail "stage 0 is not named: $out"

if [ -z "${CC:-}" ] && ! command -v cc >/dev/null 2>&1 && ! command -v zig >/dev/null 2>&1; then
  echo "SKIP real build: no C compiler (set CC, or install cc or zig)"; echo "ok"; exit 0
fi
rc=0; out="$("$BASH" "$s" --out "$tmp/real" 2>&1)" || rc=$?
[ $rc = 0 ] || fail "the real build exited $rc: $out"
s1="$(tail -n 1 <<<"$out")"
[ -x "$s1" ] || fail "stage-1 path '$s1' is not an executable: $out"
v="$("$s1" --version 2>&1)" || fail "stage 1 --version failed: $v"
[ "$v" = "bayan $(cat "$root/VERSION")" ] || fail "stage 1 --version is not 'bayan $(cat "$root/VERSION")': $v"
echo "ok"
