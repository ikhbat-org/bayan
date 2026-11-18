#!/usr/bin/env bash
# Tests scripts/test.sh with each part replaced by a stub (TEST_SH_*): all passing exits 0 with one pass line per part;
# one failing exits 1 naming it, after the parts behind it ran; --jobs reaches the golden part; --only runs one part;
# a bad --jobs or --only exits 2. No driver is built: every part is stubbed.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
s="$root/scripts/test.sh"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/test-sh-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

# stub <name> <exit>: records its arguments in $tmp/<name>.args and exits <exit>.
stub() { printf '#!/bin/sh\necho "$@" > "%s/%s.args"\nexit %s\n' "$tmp" "$1" "$2" > "$tmp/$1"; chmod +x "$tmp/$1"; }
for p in golden bayan parity scripts runtime; do stub "$p" 0; done
export TEST_SH_GOLDEN="$tmp/golden" TEST_SH_BAYAN="$tmp/bayan" TEST_SH_PARITY="$tmp/parity" TEST_SH_SCRIPTS="$tmp/scripts" TEST_SH_RUNTIME="$tmp/runtime"
unset BAYAN_EXE

rc=0; out="$("$BASH" "$s" --jobs 3 2>&1)" || rc=$?
[ $rc = 0 ] || fail "all parts passing exited $rc: $out"
for p in golden bayan parity scripts runtime; do
  [ "$(grep -c "^test: $p  *pass " <<<"$out")" = 1 ] || fail "no one pass line for $p: $out"
done
[ "$(cat "$tmp/golden.args")" = "--jobs 3" ] || fail "--jobs 3 did not reach the golden part: $(cat "$tmp/golden.args")"

rm -f "$tmp"/*.args; stub bayan 1
rc=0; out="$("$BASH" "$s" --jobs 2 2>&1)" || rc=$?
logs="$(sed -n 's#.*log: \(.*\)/bayan\.log).*#\1#p' <<<"$out")"; case "$logs" in "$root"/tmp/test.*) rm -rf "$logs" ;; esac
[ $rc = 1 ] || fail "a failing part exited $rc, not 1: $out"
grep -q '^test: bayan  *FAIL ' <<<"$out" || fail "the failing part has no FAIL line: $out"
grep -qx 'test: FAILED bayan' <<<"$out" || fail "the failing part is not named at the end: $out"
[ -f "$tmp/parity.args" ] && [ -f "$tmp/scripts.args" ] && [ -f "$tmp/runtime.args" ] || fail "the parts after a failing one did not run: $out"

rm -f "$tmp"/*.args; stub bayan 0
rc=0; out="$("$BASH" "$s" --only runtime --jobs 5 2>&1)" || rc=$?
[ $rc = 0 ] || fail "--only runtime exited $rc: $out"
[ -f "$tmp/runtime.args" ] && [ ! -f "$tmp/golden.args" ] && [ ! -f "$tmp/bayan.args" ] && [ ! -f "$tmp/parity.args" ] && [ ! -f "$tmp/scripts.args" ] \
  || fail "--only runtime ran another part: $out"

rc=0; "$BASH" "$s" --jobs 0 >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "--jobs 0 exited $rc, not 2"
rc=0; "$BASH" "$s" --only nope >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "--only nope exited $rc, not 2"
echo "test.test: all passed"
