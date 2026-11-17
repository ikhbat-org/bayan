#!/usr/bin/env bash
# record-encodings.sh: two runs give the same TSV, the committed TSV equals a fresh run, one row per '// form:' line,
# and an invalid instruction fails the script. Off arm64 macOS, or without otool and zig, it says why and skips (exit 0).
set -euo pipefail
skip() { echo "record-encodings.test: skipped: $1"; exit 0; }
[ "$(uname -s)" = Darwin ] || skip "not macOS ($(uname -s))"
[ "$(uname -m)" = arm64 ] || skip "not arm64 ($(uname -m))"
command -v otool >/dev/null 2>&1 || skip "otool not on PATH"
command -v zig >/dev/null 2>&1 || [ -x "$HOME/.local/bin/zig" ] || skip "zig not on PATH or in ~/.local/bin"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
t="$root/tmp/sabk-record-test"
rm -rf "$t" && mkdir -p "$t"
trap 'rm -rf "$t"' EXIT
s="$root/scripts/sabk/record-encodings.sh"
src="$root/src/sabk/testdata/encodings.s"
tsv="$root/src/sabk/testdata/encodings.tsv"
fail() { echo "FAIL: $1" >&2; exit 1; }

bash "$s" "$src" "$t/a.tsv" || fail "first run fails"
bash "$s" "$src" "$t/b.tsv" || fail "second run fails"
cmp -s "$t/a.tsv" "$t/b.tsv" || fail "two runs differ"
cmp -s "$t/a.tsv" "$tsv" || fail "committed encodings.tsv differs from a fresh run"
forms="$(grep -c '^[[:space:]]*// form:' "$src")"
rows="$(grep -vc '^#' "$tsv")"
[ "$forms" = "$rows" ] || fail "$forms forms but $rows rows"

printf '// form: bad\n    notaninstruction x0, x1\n' > "$t/bad.s"
if bash "$s" "$t/bad.s" "$t/bad.tsv" >/dev/null 2>&1; then fail "invalid instruction passed"; fi
[ ! -e "$t/bad.tsv" ] || fail "invalid instruction wrote output"
echo "record-encodings.test: all passed"
