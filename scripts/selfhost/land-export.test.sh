#!/usr/bin/env bash
# Tests scripts/selfhost/land-export.sh on a fixture export under tmp/: byte-for-byte copies, input/ as input.tsv with the
# files and trees stored once by content (executable bit kept), the root masked in non-input text files only, cli/SelfhostExport
# dropped, EXPORT.tsv from UNEXPORTED.tsv, the case counts and the inventory, a rerun writing nothing, and the refusals.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
tool="$root/scripts/selfhost/land-export.sh"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/land-export-test"; rm -rf "$t"; mkdir -p "$t/tmp"
export TMPDIR="$t/tmp"
if command -v sha256sum > /dev/null 2>&1; then h() { sha256sum | cut -c1-64; }; else h() { shasum -a 256 | cut -c1-64; }; fi
R=/machine/wt/chore-019-export
x="$t/export"; d="$t/tests/cases"
mkdir -p "$x/cli/AlphaTests/One/input/sub" "$x/cli/AlphaTests/One/input/empty" "$x/cli/AlphaTests/One-2" "$x/cli/SelfhostExport/Probe" \
  "$x/sem/GammaTests/Two/input" "$x/runtime/macos" "$d"
c="$x/cli/AlphaTests/One"
printf 'build\n%s/tmp/a.byn\n' "$R" > "$c/args"
printf 'error at %s/src/x.byn and %s/y' "$R" "$R" > "$c/expected.stdout"          # no final newline
printf '0\n' > "$c/expected.exitcode"
printf 'bin\000%s\n' "$R" > "$c/expected.bin"                                       # binary: not masked
printf 'x\n' > "$c/input/a.txt"; printf 'x\n' > "$c/input/sub/b.txt"; printf '#!/bin/sh\n' > "$c/input/sub/run.sh"
chmod +x "$c/input/sub/run.sh"
printf 'use "%s/lib"\n' "$R" > "$x/cli/AlphaTests/One-2/input.byn"                  # an input: not masked
printf 'lex\n' > "$x/cli/AlphaTests/One-2/args"
printf 'lex\n' > "$x/cli/SelfhostExport/Probe/args"
printf 'AlphaTests\tOne\tbuild %s/tmp/b.byn\nBetaTests\tNoCase\tcache after evicting (not exported: API-level)\nSelfhostExport\tProbe\tx\n' "$R" > "$x/cli/UNEXPORTED.tsv"
printf 'AlphaTests\t2\nSelfhostExport\t1\n' > "$x/cli/counts.tsv"
printf 'x\n' > "$x/sem/GammaTests/Two/input/b.txt"; printf '#!/bin/sh\n' > "$x/sem/GammaTests/Two/input/run.sh"
chmod +x "$x/sem/GammaTests/Two/input/run.sh"
printf 's\n' > "$x/sem/GammaTests/Two/section"
printf 'path\n' > "$x/runtime/macos/path-relative.in"
{ printf 'class\tfile\tfamily\ttests\tdisposition\ttarget\treason\tmemberdata\n'
  printf 'AlphaTests\ta\tcli\t3\tcli\tcli\tr\t\nBetaTests\tb\tcli\t1\tcli\tcli\tr\t\nGammaTests\tg\tsem\t1\tsem\tsem\tr\t\n'; } > "$t/tests/inventory-019.tsv"

out="$(bash "$tool" "$x" "$R/" "$d")" || fail "first run failed: $out"
[ "$out" = "land-export: 3 cases, 2 new input files, 2 new input trees, 10 files written" ] || fail "first run counts: $out"

# (1) input/ as input.tsv; files and trees once by content
o="$d/cli/AlphaTests/One"
[ ! -e "$o/input" ] || fail "input/ was copied"
hx="$(printf 'x\n' | h)"; hr="$(printf '#!/bin/sh\n' | h)"
sub="$(printf 'b.txt\tfile:%s\nrun.sh\tfile+x:%s\n' "$hx" "$hr")"; hs="$(printf '%s\n' "$sub" | h)"; he="$(printf '' | h)"
[ "$(cat "$o/input.tsv")" = "$(printf 'a.txt\tfile:%s\nempty\ttree:%s\nsub\ttree:%s' "$hx" "$he" "$hs")" ] || fail "input.tsv: $(cat "$o/input.tsv")"
[ "$(cat "$d/inputs/trees/$hs.tsv")" = "$sub" ] || fail "sub tree file"
[ -f "$d/inputs/trees/$he.tsv" ] && [ ! -s "$d/inputs/trees/$he.tsv" ] || fail "empty tree file"
[ "$(cat "$d/sem/GammaTests/Two/input.tsv")" = "$sub" ] || fail "the same tree in another case lists the same lines"
[ "$(ls "$d/inputs/files" | wc -l | tr -d ' ')" = 2 ] || fail "files stored more than once: $(ls "$d/inputs/files")"
cmp -s "$d/inputs/files/$hr" "$c/input/sub/run.sh" || fail "stored file differs"
# byte for byte, and (2) the root masked in non-input text only
cmp -s "$o/expected.exitcode" "$c/expected.exitcode" || fail "expected.exitcode not byte for byte"
cmp -s "$o/expected.bin" "$c/expected.bin" || fail "binary file changed"
cmp -s "$d/cli/AlphaTests/One-2/input.byn" "$x/cli/AlphaTests/One-2/input.byn" || fail "input.byn masked"
[ "$(cat "$o/args")" = "$(printf 'build\n<repo>/tmp/a.byn')" ] || fail "args not masked: $(cat "$o/args")"
printf 'error at <repo>/src/x.byn and <repo>/y' | cmp -s - "$o/expected.stdout" || fail "stdout not masked or final newline added"
cmp -s "$d/sem/GammaTests/Two/section" "$x/sem/GammaTests/Two/section" || fail "section"
# (3) SelfhostExport dropped; kind-level files and the runtime fixtures are not cases
[ ! -e "$d/cli/SelfhostExport" ] || fail "cli/SelfhostExport landed"
[ ! -e "$d/cli/UNEXPORTED.tsv" ] && [ ! -e "$d/cli/counts.tsv" ] && [ ! -e "$d/runtime" ] || fail "a non-case file landed"
# (4) EXPORT.tsv
want="$(printf 'class\tkind\ttests\tcases\treason\nAlphaTests\tcli\t3\t2\t1 not exported: One (build <repo>/tmp/b.byn)\nBetaTests\tcli\t1\t0\t1 not exported: NoCase (cache after evicting (not exported: API-level))\nGammaTests\tsem\t1\t1\t')"
[ "$(cat "$d/EXPORT.tsv")" = "$want" ] || fail "EXPORT.tsv: $(cat "$d/EXPORT.tsv")"

# a rerun over the same input writes nothing
touch "$t/marker"
out="$(bash "$tool" "$x" "$R" "$d")" || fail "rerun failed: $out"
[ "$out" = "land-export: 3 cases, 0 new input files, 0 new input trees, 0 files written" ] || fail "rerun counts: $out"
[ -z "$(find "$d" -newer "$t/marker")" ] || fail "rerun touched: $(find "$d" -newer "$t/marker")"

# refusals
rc=0; bash "$tool" "$x" "$R" > /dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "two arguments exited $rc, not 2"
ln -s a.txt "$c/input/link"
rc=0; out="$(bash "$tool" "$x" "$R" "$d" 2>&1)" || rc=$?
[ $rc = 1 ] && grep -q "unsupported input entry.*link" <<<"$out" || fail "a symlink in input/ was accepted ($rc): $out"
rm -rf "$t"
echo "land-export.test: ok"
