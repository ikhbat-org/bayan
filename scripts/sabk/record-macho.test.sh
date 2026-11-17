#!/usr/bin/env bash
# record-macho.sh: two runs give the same file, the committed macho-expected.txt equals a fresh run, it records the four load
# commands, and an input the assembler rejects fails the script without writing output.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
t="$root/tmp/sabk-record-macho-test"
rm -rf "$t" && mkdir -p "$t"
trap 'rm -rf "$t"' EXIT
s="$root/scripts/sabk/record-macho.sh"
src="$root/src/sabk/testdata/macho.s"
exp="$root/src/sabk/testdata/macho-expected.txt"
fail() { echo "FAIL: $1" >&2; exit 1; }

bash "$s" "$src" "$t/a.txt" || fail "first run fails"
bash "$s" "$src" "$t/b.txt" || fail "second run fails"
cmp -s "$t/a.txt" "$t/b.txt" || fail "two runs differ"
cmp -s "$t/a.txt" "$exp" || fail "committed macho-expected.txt differs from a fresh run"
[ "$(grep -c '^lc	' "$exp")" = 4 ] || fail "expected four load commands"
grep -q '^build	1	15.0	' "$exp" || fail "LC_BUILD_VERSION is not macOS 15.0"

printf '    notaninstruction x0, x1\n' > "$t/bad.s"
if bash "$s" "$t/bad.s" "$t/bad.txt" >/dev/null 2>&1; then fail "invalid assembly passed"; fi
[ ! -e "$t/bad.txt" ] || fail "invalid assembly wrote output"
echo "record-macho.test: all passed"
