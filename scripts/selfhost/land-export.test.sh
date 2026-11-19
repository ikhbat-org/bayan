#!/usr/bin/env bash
# Tests scripts/selfhost/land-export.sh on a fixture export under tmp/: byte-for-byte copies, input/ as input.tsv with the
# files and trees stored once by content (executable bit kept), the root masked in non-input text files only, cli/SelfhostExport
# dropped, the doctor, cc, version, std-list and T5 commit masks, a binary input naming the machine left out, a removed case, EXPORT.tsv from UNEXPORTED.tsv, the case counts
# and the inventory, a name ending in a dot and a space landed without them, a landed `os` file kept and listed with the reason the old
# EXPORT.tsv gave it, a rerun writing nothing, and the refusals (also a stored file whose bytes lost their CRs, and inputs/files
# without -text in a git worktree).
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
tool="$root/scripts/selfhost/land-export.sh"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/land-export-test"; rm -rf "$t"; mkdir -p "$t/tmp"
export TMPDIR="$t/tmp"
printf 'tests/cases/inputs/files/** -text\n' > "$t/.gitattributes"                  # the fixture is inside this worktree
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
printf 'use "%s/lib"\n' "$R" > "$x/cli/AlphaTests/One-2/input.byn"                  # an input: masked and stored by content
printf 'lex\n' > "$x/cli/AlphaTests/One-2/args"
mkdir -p "$x/cli/AlphaTests/Dot ." "$d/sem/GammaTests/Two"; printf 'lex\n' > "$x/cli/AlphaTests/Dot ./args"   # (3b) lands as Dot
printf 'macos linux\n' > "$d/sem/GammaTests/Two/os"                                                        # (5) kept and listed
printf 'class\tkind\ttests\tcases\treason\nGammaTests\tsem\t2\t2\t1 os: Two (macos: names the export machine)\n' > "$d/EXPORT.tsv"
D=$x/cli/SelfhostDefaultT5Tests; mkdir -p "$D/Plain" "$D/Seeded" "$D/Color" "$x/cli/SelfhostDefaultT12Tests/Cc"
E=$(printf "\033")
printf "◆ bayan       0.3.2\n◆ host        macos-arm64\n◆ C compiler  /Users/q/bin/zig cc (clang 22)\n◆ zig         not found; x\n◆ git         /opt/homebrew/bin/git (git 2)\n◆ cache       %s/tmp/cache (writable)\n✗ zig: <repo>/zig is bad\n%s[31m✗ cache: /c isn't writable: Access to the path '/c/.d-1' is denied.%s[0m\nx (commit 9cf2) y\n" "$R" "$E" "$E" > "$D/Plain/expected.stdout"
printf "NO_COLOR\nLANG=C\n" > "$D/Plain/env"
printf "◆ cache       %s/tmp/p (writable)\n◆ git         /opt/homebrew/bin/git\n" "$R" > "$D/Seeded/expected.stdout"
printf "BAYAN_CACHE=%s/tmp/p\n" "$R" > "$D/Seeded/env"
printf "%s[32m◆%s[0m host        macos-arm64\n* zig         /opt/z\n" "$E" "$E" > "$D/Color/expected.stdout"
printf 'doctor\n' | tee "$D/Plain/args" "$D/Seeded/args" > "$D/Color/args"
mkdir -p "$D/Build" "$x/cli/SelfhostDefaultT9Tests/Arm"                             # doctor by args, not by class
printf 'build\n' > "$D/Build/args"; printf "◆ host        macos-arm64\nbayan 0.3.2 (masked)\n" > "$D/Build/expected.stdout"
std='help: import one of `std.json`\n"help":"import one of `std.json`"\nimport one of `std.json`, `std.fs`\n'
printf "$std" > "$D/Build/expected.stderr"                                          # (2b) std list: the whole `std.json` list only
printf -- '--ascii\ndoctor\n' > "$x/cli/SelfhostDefaultT9Tests/Arm/args"
printf "* host        macos-arm64\n* git         /opt/homebrew/bin/git\n" > "$x/cli/SelfhostDefaultT9Tests/Arm/expected.stdout"
G=$x/sem/GammaTests/Three; mkdir -p "$G/input"                                       # a binary input naming the machine is left out
printf 'k\n' > "$G/input/keep.txt"; printf 'o\000/Users/q/a.c\n' > "$G/input/host.o"
F=$x/cli/SelfhostDefaultT2Tests/FeaturesMatchesTheCSharpCli-14; mkdir -p "$F/input"
printf 'features\n.\n' > "$F/args"; printf 'dll\n' > "$F/input/x.dll"
W=$x/cli/SelfhostDriverT5Tests/CannotWriteTheOutputAsCliApp-5; mkdir -p "$W"; printf 'build\n' > "$W/args"   # (2d) removed
printf "x\nC compiler failed (exit 1):\nIn file /Users/q/zig/a.h:2\n  error\n" > "$x/cli/SelfhostDefaultT12Tests/Cc/expected.stderr"
printf "keep\n" > "$x/cli/SelfhostDefaultT12Tests/Cc/expected.stdout"
printf 'lex\n' > "$x/cli/SelfhostExport/Probe/args"
printf 'AlphaTests\tOne\tbuild %s/tmp/b.byn\nBetaTests\tNoCase\tcache after evicting (not exported: API-level)\nSelfhostExport\tProbe\tx\n' "$R" > "$x/cli/UNEXPORTED.tsv"
printf 'AlphaTests\t2\nSelfhostExport\t1\n' > "$x/cli/counts.tsv"
printf 'x\n' > "$x/sem/GammaTests/Two/input/b.txt"; printf '#!/bin/sh\n' > "$x/sem/GammaTests/Two/input/run.sh"
chmod +x "$x/sem/GammaTests/Two/input/run.sh"
printf 's\nbayan 0.3.2 (masked)\nimport one of `std.json`\n' > "$x/sem/GammaTests/Two/section"
printf 'path\n' > "$x/runtime/macos/path-relative.in"
{ printf 'class\tfile\tfamily\ttests\tdisposition\ttarget\treason\tmemberdata\n'
  printf 'AlphaTests\ta\tcli\t3\tcli\tcli\tr\t\nBetaTests\tb\tcli\t1\tcli\tcli\tr\t\nGammaTests\tg\tsem\t2\tsem\tsem\tr\t\n'; } > "$t/tests/inventory-019.tsv"

out="$(bash "$tool" "$x" "$R/" "$d")" || fail "first run failed: $out"
[ "$(tail -n1 <<<"$out")" = "land-export: 12 cases, 4 new input files, 2 new input trees, 28 files written" ] || fail "first run counts: $out"

# (1) input/ as input.tsv; files and trees once by content
o="$d/cli/AlphaTests/One"
[ ! -e "$o/input" ] || fail "input/ was copied"
hx="$(printf 'x\n' | h)"; hr="$(printf '#!/bin/sh\n' | h)"
sub="$(printf 'b.txt\tfile:%s\nrun.sh\tfile+x:%s\n' "$hx" "$hr")"; hs="$(printf '%s\n' "$sub" | h)"; he="$(printf '' | h)"
[ "$(cat "$o/input.tsv")" = "$(printf 'a.txt\tfile:%s\nempty\ttree:%s\nsub\ttree:%s' "$hx" "$he" "$hs")" ] || fail "input.tsv: $(cat "$o/input.tsv")"
[ "$(cat "$d/inputs/trees/$hs.tsv")" = "$sub" ] || fail "sub tree file"
[ -f "$d/inputs/trees/$he.tsv" ] && [ ! -s "$d/inputs/trees/$he.tsv" ] || fail "empty tree file"
[ "$(cat "$d/sem/GammaTests/Two/input.tsv")" = "$sub" ] || fail "the same tree in another case lists the same lines"
[ "$(ls "$d/inputs/files" | wc -l | tr -d ' ')" = 4 ] || fail "files stored more than once: $(ls "$d/inputs/files")"
cmp -s "$d/inputs/files/$hr" "$c/input/sub/run.sh" || fail "stored file differs"
# byte for byte, and (2) the root masked in non-input text only
cmp -s "$o/expected.exitcode" "$c/expected.exitcode" || fail "expected.exitcode not byte for byte"
cmp -s "$o/expected.bin" "$c/expected.bin" || fail "binary file changed"
[ ! -e "$d/cli/AlphaTests/One-2/input.byn" ] || fail "input.byn was copied"
hb="$(printf "use \"<repo>/lib\"\n" | h)"
[ "$(cat "$d/cli/AlphaTests/One-2/input.byn.ref")" = "file:$hb" ] || fail "input.byn.ref: $(cat "$d/cli/AlphaTests/One-2/input.byn.ref")"
printf "use \"<repo>/lib\"\n" | cmp -s - "$d/inputs/files/$hb" || fail "input.byn not masked before hashing"
D="$d/cli/SelfhostDefaultT5Tests"
printf "◆ bayan       <version>\n◆ host        <host>\n◆ C compiler  <host>\n◆ zig         not found; x\n◆ git         <host>\n◆ cache       <host>\n✗ zig: <repo>/zig is bad\n%s[31m✗ cache: /c isn't writable: <message>%s[0m\nx (commit <c>) y\n" "$E" "$E" | cmp -s - "$D/Plain/expected.stdout" || fail "doctor mask: $(cat "$D/Plain/expected.stdout")"
printf "◆ cache       <repo>/tmp/p (writable)\n◆ git         <host>\n" | cmp -s - "$D/Seeded/expected.stdout" || fail "seeded cache mask: $(cat "$D/Seeded/expected.stdout")"
printf "%s[32m◆%s[0m host        <host>\n* zig         <host>\n" "$(printf "\033")" "$(printf "\033")" | cmp -s - "$D/Color/expected.stdout" || fail "coloured doctor mask"
printf "x\nC compiler failed (exit 1):\n<cc output>\n" | cmp -s - "$d/cli/SelfhostDefaultT12Tests/Cc/expected.stderr" || fail "cc output mask"
printf "keep\n" | cmp -s - "$d/cli/SelfhostDefaultT12Tests/Cc/expected.stdout" || fail "cc mask touched a stdout without the line"
printf "◆ host        macos-arm64\nbayan <version> (masked)\n" | cmp -s - "$D/Build/expected.stdout" || fail "doctor mask on a case that runs no doctor, or no version mask"
printf "* host        <host>\n* git         <host>\n" | cmp -s - "$d/cli/SelfhostDefaultT9Tests/Arm/expected.stdout" || fail "doctor mask in another class"
[ "$(cat "$d/sem/GammaTests/Three/input.tsv")" = "$(printf 'keep.txt\tfile:%s' "$(printf 'k\n' | h)")" ] || fail "binary naming the machine kept: $(cat "$d/sem/GammaTests/Three/input.tsv")"
grep -q "^land-export: sem/GammaTests/Three: left out host.o" <<<"$out" || fail "left-out file not printed: $out"
[ ! -e "$d/cli/SelfhostDefaultT2Tests/FeaturesMatchesTheCSharpCli-14/input.tsv" ] && [ -f "$d/cli/SelfhostDefaultT2Tests/FeaturesMatchesTheCSharpCli-14/args" ] || fail "FeaturesMatchesTheCSharpCli-14 input"
[ ! -e "$d/cli/SelfhostDriverT5Tests" ] || fail "a removed case landed"
grep -q "^land-export: cli/SelfhostDriverT5Tests/CannotWriteTheOutputAsCliApp-5: removed (" <<<"$out" || fail "removed case not printed: $out"
[ "$(cat "$o/args")" = "$(printf 'build\n<repo>/tmp/a.byn')" ] || fail "args not masked: $(cat "$o/args")"
printf 'error at <repo>/src/x.byn and <repo>/y' | cmp -s - "$o/expected.stdout" || fail "stdout not masked or final newline added"
printf 'help: import one of <std modules>\n"help":"import one of <std modules>"\nimport one of `std.json`, `std.fs`\n' | cmp -s - "$D/Build/expected.stderr" || fail "std mask: $(cat "$D/Build/expected.stderr")"
cmp -s "$d/sem/GammaTests/Two/section" "$x/sem/GammaTests/Two/section" || fail "section"
[ "$(ls "$d/cli/AlphaTests" | tr '\n' '|')" = "Dot|One|One-2|" ] && [ -f "$d/cli/AlphaTests/Dot/args" ] || fail "(3b) name: $(ls "$d/cli/AlphaTests")"
printf 'macos linux\n' | cmp -s - "$d/sem/GammaTests/Two/os" || fail "os file not kept"
# (3) SelfhostExport dropped; kind-level files and the runtime fixtures are not cases
[ ! -e "$d/cli/SelfhostExport" ] || fail "cli/SelfhostExport landed"
[ ! -e "$d/cli/UNEXPORTED.tsv" ] && [ ! -e "$d/cli/counts.tsv" ] && [ ! -e "$d/runtime" ] || fail "a non-case file landed"
# (4) EXPORT.tsv
want="$(printf 'class\tkind\ttests\tcases\treason\nAlphaTests\tcli\t3\t3\t1 not exported: One (build <repo>/tmp/b.byn)\nBetaTests\tcli\t1\t0\t1 not exported: NoCase (cache after evicting (not exported: API-level))\nGammaTests\tsem\t2\t2\t1 os: Two (macos linux: names the export machine)\nSelfhostDefaultT12Tests\tcli\t\t1\t\nSelfhostDefaultT2Tests\tcli\t\t1\t\nSelfhostDefaultT5Tests\tcli\t\t4\t\nSelfhostDefaultT9Tests\tcli\t\t1\t\nSelfhostDriverT5Tests\tcli\t\t0\t1 removed: CannotWriteTheOutputAsCliApp-5 (its input out/safe/macos-arm64/read-only named the export machine and was left out)')"
[ "$(cat "$d/EXPORT.tsv")" = "$want" ] || fail "EXPORT.tsv: $(cat "$d/EXPORT.tsv")"

# a rerun over the same input writes nothing
touch "$t/marker"
out="$(bash "$tool" "$x" "$R" "$d")" || fail "rerun failed: $out"
[ "$(tail -n1 <<<"$out")" = "land-export: 12 cases, 0 new input files, 0 new input trees, 0 files written" ] || fail "rerun counts: $out"
[ -z "$(find "$d" -newer "$t/marker")" ] || fail "rerun touched: $(find "$d" -newer "$t/marker")"

# refusals
rc=0; bash "$tool" "$x" "$R" > /dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "two arguments exited $rc, not 2"
printf 'see /opt/homebrew/bin\n' > "$x/cli/AlphaTests/One-2/leak.txt"
rc=0; out="$(bash "$tool" "$x" "$R" "$d" 2>&1)" || rc=$?
[ $rc = 1 ] && grep -q "names the export machine" <<<"$out" || fail "a leak was accepted ($rc): $out"
rm "$x/cli/AlphaTests/One-2/leak.txt"
mkdir "$x/cli/AlphaTests/One. "
rc=0; out="$(bash "$tool" "$x" "$R" "$d" 2>&1)" || rc=$?
[ $rc = 1 ] && grep -q "lands as One, the name of another case" <<<"$out" || fail "a name landing on another case's was accepted ($rc): $out"
rmdir "$x/cli/AlphaTests/One. "; mkdir "$x/cli/AlphaTests/A:b"
rc=0; out="$(bash "$tool" "$x" "$R" "$d" 2>&1)" || rc=$?
[ $rc = 1 ] && grep -q "A:b: a name Windows cannot hold" <<<"$out" || fail "a name Windows cannot hold was accepted ($rc): $out"
rmdir "$x/cli/AlphaTests/A:b"; printf 'macos\nlinux\n' > "$d/sem/GammaTests/Two/os"
rc=0; out="$(bash "$tool" "$x" "$R" "$d" 2>&1)" || rc=$?
[ $rc = 1 ] && grep -q "GammaTests/Two/os has more than one line" <<<"$out" || fail "an os file of two lines was accepted ($rc): $out"
printf 'macos\n' > "$d/sem/GammaTests/Two/os"; printf 'class\tkind\ttests\tcases\treason\n' > "$d/EXPORT.tsv"
rc=0; out="$(bash "$tool" "$x" "$R" "$d" 2>&1)" || rc=$?
[ $rc = 1 ] && grep -q "GammaTests/Two/os has no reason in EXPORT.tsv" <<<"$out" || fail "an os file with no reason was accepted ($rc): $out"
ln -s a.txt "$c/input/link"
rc=0; out="$(bash "$tool" "$x" "$R" "$d" 2>&1)" || rc=$?
[ $rc = 1 ] && grep -q "unsupported input entry.*link" <<<"$out" || fail "a symlink in input/ was accepted ($rc): $out"
rm "$c/input/link" "$d/cli/AlphaTests/One-2/leak.txt"
printf 'a\r\nb\r\n' > "$c/input/crlf.txt"; hc="$(printf 'a\r\nb\r\n' | h)"
bash "$tool" "$x" "$R" "$d" > /dev/null || fail "a CRLF input did not land"
cmp -s "$d/inputs/files/$hc" "$c/input/crlf.txt" || fail "a CRLF input was not stored byte for byte"
printf 'a\nb\n' > "$d/inputs/files/$hc"                                              # an earlier land that lost its CRs
rc=0; out="$(bash "$tool" "$x" "$R" "$d" 2>&1)" || rc=$?
[ $rc = 1 ] && grep -q "do not hash to their names" <<<"$out" && grep -qx "$hc" <<<"$out" || fail "a stored file not hashing to its name was accepted ($rc): $out"
rm "$t/.gitattributes"
rc=0; out="$(bash "$tool" "$x" "$R" "$d" 2>&1)" || rc=$?
[ $rc = 1 ] && grep -q "is not -text" <<<"$out" || fail "inputs/files without -text was accepted ($rc): $out"
rm -rf "$t"
echo "land-export.test: ok"
