#!/usr/bin/env bash
# Tests scripts/selfhost/pre-push-laws.sh against a fixture laws dir with stub check commands (the real laws are never run):
# BAYAN_LAW_TIER=full reaches the check, a failing check fails the gate and names the id, proposed and retired laws are not run,
# an enacted law with no check: line fails the gate and is named.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/pre-push-laws-test"; rm -rf "$t"; mkdir -p "$t/laws"
law() { printf -- '---\nid: %s\nstatus: %s\n%stimeout: 60\n---\nbody\n' "$1" "$2" "${3:+check: $3
}" > "$t/laws/$4.md"; }
gate() { rc=0; out="$(bash "$root/scripts/selfhost/pre-push-laws.sh" "$t/laws" 2>&1)" || rc=$?; }

law L901 enacted "echo tier=\$BAYAN_LAW_TIER > '$t/tier'" 0901
law L902 proposed "touch '$t/ran-proposed'" 0902
law L903 retired "touch '$t/ran-retired'" 0903
gate
[ $rc = 0 ] || fail "passing laws exited $rc: $out"
[ "$(cat "$t/tier")" = tier=full ] || fail "BAYAN_LAW_TIER=full did not reach the check"
[ ! -e "$t/ran-proposed" ] && [ ! -e "$t/ran-retired" ] || fail "a proposed or retired law was run"
echo "$out" | grep -qx '== L901 (full tier)' || fail "no == L901 line"
echo "$out" | grep -q 'All enacted laws hold' || fail "no pass line"

law L904 enacted "exit 3" 0904
gate
[ $rc = 1 ] || fail "a failing check exited $rc"
echo "$out" | grep -q 'LAWS FAILED (full tier): L904$' || fail "the failing id is not named: $out"

law L904 enacted "" 0904
gate
[ $rc = 1 ] || fail "a missing check line exited $rc"
echo "$out" | grep -q 'L904: no check: line' || fail "the missing check is not named: $out"
echo "$out" | grep -q 'LAWS FAILED (full tier): L904$' || fail "the missing check did not fail the gate"
echo "pre-push-laws.test: ok"
