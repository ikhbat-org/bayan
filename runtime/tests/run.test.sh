#!/usr/bin/env bash
# runtime/tests/run.sh against copies of the fixtures: one changed expected line fails, a missing fixture fails.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
mkdir -p "$root/tmp"
t="$(mktemp -d "$root/tmp/run-test.XXXXXX")" || exit 2
trap 'rm -rf "$t"' EXIT
fail=0
check() { if [ "$2" = "$3" ]; then echo "ok: $1"; else echo "FAIL: $1: got '$2', want '$3'"; fail=1; fi; }
case "$(uname -s)" in
    Darwin) os=macos ;;
    Linux) os=linux ;;
    MINGW*|MSYS*|CYGWIN*) os=windows ;;
    *) os=$(uname -s) ;;
esac
run() { BAYAN_RT_CASES="$t/cases" bash "$here/run.sh" >"$t/out" 2>&1; echo $?; }

cp -R "$here/cases" "$t/cases"
check "copied fixtures pass" "$(run)" 0

f="$t/cases/$os/path-relative.expected"
{ echo changed; tail -n +2 "$f"; } >"$t/changed" && mv "$t/changed" "$f"
check "changed expected line fails" "$([ "$(run)" != 0 ] && echo nonzero)" nonzero
check "changed line is named" "$(grep -c '^FAIL path-relative-cases.c' "$t/out")" 1
cp "$here/cases/$os/path-relative.expected" "$f"

f="$t/cases/$os/batch-cmdline.expected"
{ cat "$f"; echo extra; } >"$t/changed" && mv "$t/changed" "$f"
check "extra expected line fails" "$([ "$(run)" != 0 ] && echo nonzero)" nonzero
cp "$here/cases/$os/batch-cmdline.expected" "$f"

rm "$t/cases/$os/batch-cmdline.in"
check "missing fixture fails" "$([ "$(run)" != 0 ] && echo nonzero)" nonzero
check "missing fixture is a failure, not a skip" "$(grep -c '^FAIL batch-cmdline-cases.c: no fixture' "$t/out")" 1

rm -rf "$t/cases/$os"
check "missing OS directory fails" "$([ "$(run)" != 0 ] && echo nonzero)" nonzero
exit $fail
