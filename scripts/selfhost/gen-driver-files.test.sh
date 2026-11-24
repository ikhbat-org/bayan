#!/usr/bin/env bash
# Tests scripts/selfhost/gen-driver-files.sh: the committed src/driver/diagdocs.byn and runtime.byn equal a fresh
# generation, and on a scratch copy a changed input makes --check fail naming the file until --write regenerates it.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
gen="$root/scripts/selfhost/gen-driver-files.sh"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/gen-driver-files-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

bash "$gen" --check || fail "a committed generated file of src/driver differs from a fresh generation"

w="$tmp/w"; mkdir -p "$w/scripts/selfhost" "$w/docs" "$w/src/driver"
cp "$gen" "$w/scripts/selfhost/"; cp -R "$root/docs/diagnostics" "$w/docs/"; cp -R "$root/runtime" "$w/"
cp "$root/src/driver/diagdocs.byn" "$root/src/driver/runtime.byn" "$w/src/driver/"
g="$w/scripts/selfhost/gen-driver-files.sh"
bash "$g" --check || fail "the scratch copy is not fresh"

doc="$w/docs/diagnostics/BYN0001.md"; [ -f "$doc" ] || fail "no docs/diagnostics/BYN0001.md"
printf 'a "quoted" \\ line\twith a tab\001\n' >> "$doc"
if bash "$g" --check 2> "$tmp/err"; then fail "a changed docs/diagnostics file passed --check"; fi
grep -q 'src/driver/diagdocs.byn' "$tmp/err" || fail "--check did not name diagdocs.byn: $(cat "$tmp/err")"
! grep -q 'src/driver/runtime.byn' "$tmp/err" || fail "--check named runtime.byn, which did not change"
bash "$g" --write && bash "$g" --check || fail "--write did not make diagdocs.byn fresh"
grep -qF 'a \"quoted\" \\ line\twith a tab\u{1}\n"' "$w/src/driver/diagdocs.byn" || fail "the escapes are not those of SelfhostDefaultT1Tests.Escape"

printf '/* added */\n' >> "$w/runtime/bayan-rt.c"
if bash "$g" --check 2> "$tmp/err"; then fail "a changed runtime/bayan-rt.c passed --check"; fi
grep -q 'src/driver/runtime.byn' "$tmp/err" || fail "--check did not name runtime.byn: $(cat "$tmp/err")"
bash "$g" --write && bash "$g" --check || fail "--write did not make runtime.byn fresh"

printf '/* """ */\n' >> "$w/runtime/bayan-rt.h"
if bash "$g" runtime > /dev/null 2> "$tmp/err"; then fail "a runtime file holding \"\"\" was generated"; fi
grep -qF 'holds """' "$tmp/err" || fail "the refusal does not name the triple quote: $(cat "$tmp/err")"
echo PASS
