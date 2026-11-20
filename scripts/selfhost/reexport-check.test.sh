#!/usr/bin/env bash
# Tests scripts/selfhost/reexport-check.sh on a scratch repo with a stub `dotnet` (REEXPORT_DOTNET): its `test` logs the filter
# and copies the classes the filter names from $AUX/export into BAYAN_EXPORT_DIR, less the case in $DROP and plus $AUX/extra
# when $EXTRA is set. The tree passes; a changed expected file, a missing row and an extra file with a FREEZE.tsv row each fail
# naming the path; an extra file with no row is listed and passes; a
# DIVERGENCES.tsv row (case key or Class.Test) lets its case differ; the seed picks the same classes twice; --full has no
# filter; a class whose source names no SelfhostExport type at the head is printed as left out, never compared, and
# refused by --class; the C# CLI replay (a stub CLI) passes, names a changed expected file, a frozen file it did not write and an
# exit-code difference (a file and a flat exit-code line), honours a divergence row, picks one unit per kind weekly and refuses a
# class it does not run under --class; the emit lines (through freeze-csharp.sh) and a golden case (a stub runner, REEXPORT_RUNNER,
# with BAYAN_EXE the C# CLI) pass, and a changed emit line and a failed golden case are named; no dotnet fails without a pass; usage errors exit 2.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/reexport-check-test.XXXXXX")"
aux="$tmp/aux"; mkdir -p "$aux"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; [ -z "${2:-}" ] || echo "$2" >&2; exit 1; }

cat > "$aux/dotnet" <<'STUB'
#!/bin/bash
if [ "$1 $2 $5" = "build csharp/Bayan.Cli -o" ]; then mkdir -p "$6" && cp "$AUX/bayan" "$6/bayan"; echo "build" >> "$AUX/log"; exit 0; fi
[ "$1 $2" = "test csharp/tests/Bayan.Tests" ] || exit 9
f=""; while [ $# -gt 0 ]; do [ "$1" = --filter ] && f=$2; shift; done
echo "filter=$f" >> "$AUX/log"
for d in "$AUX"/export/*/*; do
  c="${d##*/}"; k="${d%/*}"; k="${k##*/}"
  case "|$f|" in (*"|FullyQualifiedName~.$c.|"*|"||") ;; (*) continue ;; esac
  mkdir -p "$BAYAN_EXPORT_DIR/$k"; cp -R "$d" "$BAYAN_EXPORT_DIR/$k/"
done
[ -z "${DROP:-}" ] || rm -rf "$BAYAN_EXPORT_DIR/$DROP"
[ -z "${EXTRA:-}" ] || cp -R "$AUX/extra/." "$BAYAN_EXPORT_DIR/"
STUB
# the stub C# CLI: its argv, the input it was given and a wall time on stdout, its directory on stderr; exit $STUB_EXIT (else 0)
cat > "$aux/bayan" <<'STUB'
#!/bin/bash
last="${@: -1}"; echo "args: $* in 0.42s"; [ ! -f "$last" ] || echo "file: $(< "$last")"
[ ! -f input.byn ] || echo "at $PWD/input.byn"; echo "foo $FOO" >&2
exit "${STUB_EXIT:-0}"
STUB
# the stub golden runner: logs what BAYAN_EXE answers to `version`, then passes each --only case, or fails $GOLDEN_FAIL naming its
# .stdout
cat > "$aux/runner" <<'STUB'
#!/bin/bash
echo "runner: $("$BAYAN_EXE" version)" >> "$AUX/log"
while [ $# -gt 0 ]; do
  if [ "$1" = --only ]; then
    if [ "$2" = "${GOLDEN_FAIL:-}" ]; then printf 'failed %s\n    tests/cases/%s.stdout\n    expected line 1: a\n' "$2" "$2"; else echo "passed $2"; fi
    shift
  fi
  shift
done
STUB
chmod +x "$aux/dotnet" "$aux/bayan" "$aux/runner"
export AUX="$aux" REEXPORT_DOTNET="$aux/dotnet" REEXPORT_RUNNER="$aux/runner"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

# the export: three classes, two kinds; the tree holds what land-export.sh makes of it
mk() { mkdir -p "$1/$2"; printf '%s\n' "$3" > "$1/$2/expected.stdout"; printf 'check\n' > "$1/$2/args"; }
mk "$aux/export" cli/ACliTests/Prints "hello"
mk "$aux/export" sem/ASemTests/One "one"
mk "$aux/export" sem/ASemTests/Two-2 "two"
mk "$aux/export" sem/BSemTests/Three "three"
mk "$aux/extra" sem/ASemTests/Four "four"

r="$tmp/repo"; mkdir -p "$r/scripts/selfhost" "$r/tests/cases"; cd "$r"
git init -q -b dev; git config core.hooksPath /dev/null
cp "$root/scripts/selfhost/reexport-check.sh" "$root/scripts/selfhost/land-export.sh" "$root/scripts/selfhost/replay-csharp.sh" \
  "$root/scripts/selfhost/freeze-csharp.sh" scripts/selfhost/
printf '/tmp/\n' > .gitignore; printf '* text=auto eol=lf\ntests/cases/inputs/files/** -text\n' > .gitattributes
# export mode at the head: ACliTests and BSemTests name SelfhostExport, ASemTests names a Selfhost harness, CSemTests neither
mkdir -p src/tests csharp/tests
printf 'class SelfhostExport { }\nclass SelfhostFakeHarness { SelfhostExport e; }\n' > src/tests/SelfhostExport.cs
printf 'class ACliTests { SelfhostExport e; }\n' > src/tests/ACliTests.cs
printf 'class ASemTests { SelfhostFakeHarness h; }\n' > src/tests/ASemTests.cs
printf 'class BSemTests { SelfhostExport e; }\n' > csharp/tests/BSemTests.cs
printf 'class CSemTests { Cli c; }\n' > src/tests/CSemTests.cs
printf 'class DLexTests { SelfhostExport e; }\nclass ESemTests { SelfhostExport e; }\n' > src/tests/Big.cs
git add -A; git commit -qm export; head="$(git rev-parse HEAD)"
cp -R "$aux/export/." tests/cases/
mk tests/cases sem/CSemTests/Five "five"
printf 'class\tfile\tfamily\ttests\tdisposition\ttarget\treason\tmemberdata\n' > tests/inventory-019.tsv
for c in ACliTests ASemTests BSemTests CSemTests; do printf '%s\tx.cs\tf\t1\tcli\tcli\t\t\n' "$c" >> tests/inventory-019.tsv; done
printf 'class\tkind\ttests\tcases\treason\nACliTests\tcli\t1\t1\t\nASemTests\tsem\t1\t2\t\nBSemTests\tsem\t1\t1\t\nCSemTests\tsem\t1\t1\t\nDLexTests\tlex\t1\t2001\t\nESemTests\tsem\t1\t2500\t\nShellTests\tshell\t1\t3\t\n' \
  > tests/cases/EXPORT.tsv
printf 'case\tquestion\tright\treason\n' > tests/cases/DIVERGENCES.tsv
# the replay (T59 part 2): two left-out classes the C# CLI replays (routes `case` and `scratch`), one it does not, a flat parse input
# with its exit-code line; the expected files are what the stub C# CLI prints, through the replay's path and time masks
rc() { mkdir -p "tests/cases/$1"; printf "$2" > "tests/cases/$1/args"; printf "$3" > "tests/cases/$1/input.byn"
  printf "$4" > "tests/cases/$1/expected.stdout"; printf "$5" > "tests/cases/$1/expected.stderr"; printf '0\n' > "tests/cases/$1/expected.exitcode"; }
rc sem/FunctionTypeTests/A 'types\ninput.byn\n' 'fn a' 'args: types input.byn in 0.42s\nfile: fn a\nat input.byn\n' 'foo \n'
rc sem/FunctionTypeTests/B-2 'types\ninput.byn\n' 'fn b' 'args: types input.byn in 0.42s\nfile: fn b\nat input.byn\n' 'foo \n'
rc cli/DiagnosticRendererTests/C 'check\n<repo>/tmp/x/C/input.byn\n' 'fn c' 'args: check <repo>/tmp/x/C/input.byn in masked\nfile: fn c\n' \
  'foo <repo>/f\n'
printf 'seconds-masked\n' > tests/cases/cli/DiagnosticRendererTests/C/compare
printf 'FOO=<repo>/f\nBAYAN_THEME\n' > tests/cases/cli/DiagnosticRendererTests/C/env
rc cli/MutatorTests/M 'test\n--mutate\n' 'fn m' 'm\n' ''
mkdir -p tests/cases/parse tests/cases/emit/exit; printf 'p' > tests/cases/parse/p.byn
printf 'args: parse --ast p.byn in 0.42s\nfile: p\n' > tests/cases/parse/p.ast; printf '0  parse/p.byn\n' > tests/cases/emit/exit/expected.parse.exitcode
# a run input: its golden .stdout (the stub runner passes it) and its emit lines, each the sha256 of what the stub C# CLI prints
mkdir -p tests/cases/run tests/cases/emit/modes; printf 'r' > tests/cases/run/r.byn; printf 'r\n' > tests/cases/run/r.stdout
if command -v sha256sum > /dev/null 2>&1; then sum="sha256sum"; else sum="shasum -a 256"; fi
for m in debug safe fast; do
  printf '%s  run/r.byn\n' "$(cd tests/cases/run && "$aux/bayan" build --emit-c --mode $m --package . r.byn 2> /dev/null | $sum | cut -c1-64)" \
    > tests/cases/emit/modes/expected.$m.sha256
done
cp tests/cases/emit/modes/expected.safe.sha256 tests/cases/emit/run-c.sha256
printf 'FunctionTypeTests\tsem\t1\t2\t\nDiagnosticRendererTests\tcli\t1\t1\t\nMutatorTests\tcli\t1\t1\t\n' >> tests/cases/EXPORT.tsv
{ printf 'tag\tv0\t%s\nexport\tchore/export\t%s\n' "$head" "$head"
  { find tests/cases -name 'expected.*'; echo tests/cases/parse/p.ast; echo tests/cases/run/r.stdout; echo tests/cases/emit/run-c.sha256; } |
    LC_ALL=C sort |
    while IFS= read -r p; do printf 'file\t%s\t%s\n' "$(git hash-object "$p")" "$p"; done
} > tests/cases/FREEZE.tsv
git add -A; git commit -qm tree
run() { bash scripts/selfhost/reexport-check.sh "$@" > "$tmp/out" 2>&1 && echo 0 || echo $?; }
all=(--class cli/ACliTests --class sem/ASemTests --class sem/BSemTests)

[ "$(run --full --seed 1)" = 2 ] || fail "--full with --seed: want exit 2" "$(cat "$tmp/out")"
[ "$(run --bogus)" = 2 ] || fail "an unknown option: want exit 2" "$(cat "$tmp/out")"
[ "$(run --class sem/NoSuchTests)" = 2 ] || fail "an unknown class: want exit 2" "$(cat "$tmp/out")"
[ "$(run --class sem/CSemTests)" = 2 ] && grep -q "export mode writes no case for sem/CSemTests" "$tmp/out" \
  || fail "a left-out class: want exit 2 and the reason" "$(cat "$tmp/out")"

[ "$(run "${all[@]}")" = 0 ] || fail "the tree: want exit 0" "$(cat "$tmp/out")"
grep -q "4 files compared, 0 on the divergence list, 0 skipped by an os file, 0 failed" "$tmp/out" \
  || fail "the tree: want 4 files compared" "$(cat "$tmp/out")"
[ "$(tail -1 "$aux/log")" = "filter=FullyQualifiedName~.ACliTests.|FullyQualifiedName~.ASemTests.|FullyQualifiedName~.BSemTests." ] \
  || fail "the filter names the classes" "$(tail -1 "$aux/log")"
[ -z "$(ls -d tmp/reexport.* 2> /dev/null)" ] || fail "a passing run left its work dir"

[ "$(run --seed 5)" = 0 ] || fail "a seeded sample: want exit 0" "$(cat "$tmp/out")"
grep -A2 "seed 5: 2 classes" "$tmp/out" | tail -2 > "$tmp/pick1"
grep -q "^  cli/ACliTests$" "$tmp/pick1" && grep -q "^  sem/" "$tmp/pick1" || fail "the sample is one class per kind" "$(cat "$tmp/out")"
run --seed 5 > /dev/null; grep -A2 "seed 5: 2 classes" "$tmp/out" | tail -2 | cmp -s - "$tmp/pick1" || fail "the same seed picks other classes"
for s in 1 2 3 4 5 6 7 8; do
  run --seed $s > /dev/null; ! grep -q "^  sem/ESemTests$" <(grep -A2 "seed $s: 2 classes" "$tmp/out") || fail "seed $s picks a class over 2,000 cases" "$(cat "$tmp/out")"
done
grep -q "^reexport-check: lex has no weekly class" "$tmp/out" && grep -A2 "left to --full (over 2,000 cases): 2 classes" "$tmp/out" |
  tr '\n' ' ' | grep -q "  lex/DLexTests   sem/ESemTests" || fail "the classes over 2,000 cases are not printed" "$(cat "$tmp/out")"
[ "$(run --class lex/DLexTests)" = 0 ] || fail "--class takes a class over 2,000 cases" "$(cat "$tmp/out")"
run > /dev/null; grep -q "seed $(date -u +%G%V): 2 classes" "$tmp/out" || fail "no seed: want the ISO week" "$(cat "$tmp/out")"
grep -q "^  sem/CSemTests: no replay route$" "$tmp/out" || fail "the left-out class is not printed" "$(cat "$tmp/out")"
[ "$(run --full)" = 0 ] && [ "$(grep "^filter=" "$aux/log" | tail -1)" = "filter=" ] || fail "--full: want exit 0 and no filter" "$(cat "$tmp/out")"
grep -q "4 files compared" "$tmp/out" && ! grep -q "^  sem/CSemTests$" <(sed -n '/^== /,/left out/p' "$tmp/out") \
  || fail "--full counts a left-out class" "$(cat "$tmp/out")"

printf 'TWO\n' > tests/cases/sem/ASemTests/Two-2/expected.stdout
[ "$(run "${all[@]}")" = 1 ] || fail "a changed expected file: want exit 1" "$(cat "$tmp/out")"
grep -q "differs from the frozen compiler: tests/cases/sem/ASemTests/Two-2/expected.stdout" "$tmp/out" \
  || fail "the changed file is not named" "$(cat "$tmp/out")"
kept="$(ls -d tmp/reexport.*)"; [ -n "$kept" ] && grep -qF "work dir kept: $r/$kept" "$tmp/out" || fail "a failing run did not keep its work dir" "$(cat "$tmp/out")"
rm -rf tmp/reexport.*
printf 'sem/ASemTests/Two-2\tQ1\tdriver\tx\n' >> tests/cases/DIVERGENCES.tsv
[ "$(run "${all[@]}")" = 0 ] && grep -q "3 files compared, 1 on the divergence list" "$tmp/out" \
  || fail "a case-key divergence row: want exit 0, 1 on the list" "$(cat "$tmp/out")"
printf 'case\tquestion\tright\treason\nASemTests.Two\tQ1\tdriver\tx\n' > tests/cases/DIVERGENCES.tsv
[ "$(run "${all[@]}")" = 0 ] && grep -q "1 on the divergence list" "$tmp/out" \
  || fail "a Class.Test divergence row: want exit 0" "$(cat "$tmp/out")"
git checkout -q -- tests/cases

[ "$(DROP=sem/ASemTests/One run "${all[@]}")" = 1 ] || fail "a missing row: want exit 1" "$(cat "$tmp/out")"
grep -q "missing from the re-export: tests/cases/sem/ASemTests/One/expected.stdout" "$tmp/out" || fail "the missing row is not named" "$(cat "$tmp/out")"
rm -rf tmp/reexport.*
[ "$(EXTRA=1 run "${all[@]}")" = 0 ] || fail "an extra file with no manifest row: want exit 0" "$(cat "$tmp/out")"
grep -A1 "re-exported with no manifest row (no L043 row, not compared): 1 files" "$tmp/out" |
  grep -q "^  tests/cases/sem/ASemTests/Four/expected.stdout$" && grep -q "4 files compared, .* 0 failed" "$tmp/out" \
  || fail "the file with no manifest row is not listed apart" "$(cat "$tmp/out")"
printf 'file\t%s\ttests/cases/sem/ASemTests/Four/expected.stdout\n' "$(printf 'four\n' | git hash-object --stdin)" >> tests/cases/FREEZE.tsv
[ "$(EXTRA=1 run "${all[@]}")" = 1 ] || fail "an extra file with a manifest row: want exit 1" "$(cat "$tmp/out")"
grep -q "extra (re-exported, not in the tree): tests/cases/sem/ASemTests/Four/expected.stdout" "$tmp/out" || fail "the extra file is not named" "$(cat "$tmp/out")"
git checkout -q -- tests/cases
rm -rf tmp/reexport.*

rep=(--class sem/FunctionTypeTests --class cli/DiagnosticRendererTests --class parse)
[ "$(run "${rep[@]}")" = 0 ] || fail "the replay: want exit 0" "$(cat "$tmp/out")"
grep -q "replay: 11 files compared, 0 on the divergence list, 0 failed" "$tmp/out" && [ "$(tail -1 "$aux/log")" = build ] \
  || fail "the replay: want 11 files compared and the CLI built, no export run" "$(cat "$tmp/out"; tail -1 "$aux/log")"
[ -z "$(ls -d tmp/reexport.* 2> /dev/null)" ] || fail "a passing replay left its work dir"
[ "$(run --seed 5)" = 0 ] && sed -n '/replayed through the C# CLI/,/left out/p' "$tmp/out" | tr '\n' ' ' |
  grep -q "  cli/DiagnosticRendererTests   sem/FunctionTypeTests   flat/parse " || fail "the weekly replay: one unit per kind" "$(cat "$tmp/out")"
[ "$(run --class cli/MutatorTests)" = 2 ] && grep -q "MaskMutation" "$tmp/out" \
  || fail "a class the replay does not run: want exit 2 and the reason" "$(cat "$tmp/out")"
printf 'X\n' >> tests/cases/sem/FunctionTypeTests/A/expected.stdout
[ "$(run "${rep[@]}")" = 1 ] && grep -q "differs from the frozen compiler: tests/cases/sem/FunctionTypeTests/A/expected.stdout (first difference" "$tmp/out" \
  || fail "the replay: a changed expected file is not named" "$(cat "$tmp/out")"
git checkout -q -- tests/cases; rm -rf tmp/reexport.*
[ "$(STUB_EXIT=4 run "${rep[@]}")" = 1 ] && grep -q "differs from the frozen compiler: tests/cases/cli/DiagnosticRendererTests/C/expected.exitcode" "$tmp/out" &&
  grep -q "differs from the frozen compiler: tests/cases/emit/exit/expected.parse.exitcode (the line of parse/p.byn: exit 4)" "$tmp/out" \
  || fail "the replay: an exit-code difference is not named" "$(cat "$tmp/out")"
rm -rf tmp/reexport.*
printf 'r\n' > tests/cases/sem/FunctionTypeTests/A/expected.report
printf 'file\t%s\ttests/cases/sem/FunctionTypeTests/A/expected.report\n' "$(git hash-object tests/cases/sem/FunctionTypeTests/A/expected.report)" >> tests/cases/FREEZE.tsv
[ "$(run "${rep[@]}")" = 1 ] && grep -q "missing from the replay: tests/cases/sem/FunctionTypeTests/A/expected.report" "$tmp/out" \
  || fail "the replay: a frozen file it did not write is not named" "$(cat "$tmp/out")"
rm -rf tmp/reexport.* tests/cases/sem/FunctionTypeTests/A/expected.report; git checkout -q -- tests/cases
printf 'B\n' > tests/cases/sem/FunctionTypeTests/B-2/expected.stdout
printf 'FunctionTypeTests.B\tT59\tcsharp\tx\n' >> tests/cases/DIVERGENCES.tsv
[ "$(run "${rep[@]}")" = 0 ] && grep -q "replay: 8 files compared, 3 on the divergence list, 0 failed" "$tmp/out" \
  || fail "the replay: a divergence row: want exit 0, 3 on the list" "$(cat "$tmp/out")"
git checkout -q -- tests/cases
gold=(--class emit --class run)
[ "$(run "${gold[@]}")" = 0 ] && grep -q "replay: 5 files compared, 0 on the divergence list, 0 failed" "$tmp/out" &&
  grep -q "^runner: args: version in 0.42s$" "$aux/log" \
  || fail "the emit and golden replay: want 5 files compared, BAYAN_EXE the C# CLI" "$(cat "$tmp/out" "$aux/log")"
printf '0%s\n' "$(cut -c2- tests/cases/emit/modes/expected.safe.sha256)" > tests/cases/emit/modes/expected.safe.sha256
[ "$(run "${gold[@]}")" = 1 ] && grep -q "differs from the frozen compiler: tests/cases/emit/modes/expected.safe.sha256 (the line of run/r.byn" "$tmp/out" \
  || fail "the emit replay: a changed line is not named" "$(cat "$tmp/out")"
git checkout -q -- tests/cases; rm -rf tmp/reexport.*
[ "$(GOLDEN_FAIL=run/r run "${gold[@]}")" = 1 ] &&
  grep -q "differs from the frozen compiler: tests/cases/run/r.stdout (first difference: expected line 1: a)" "$tmp/out" \
  || fail "the golden replay: a failed case is not named" "$(cat "$tmp/out")"
rm -rf tmp/reexport.*

[ "$(REEXPORT_DOTNET=$tmp/no-dotnet run "${all[@]}")" = 1 ] || fail "no dotnet: want exit 1" "$(cat "$tmp/out")"
grep -q "no dotnet on PATH: L043 is not checked" "$tmp/out" && ! grep -q "ok in" "$tmp/out" || fail "no dotnet: want the message and no pass" "$(cat "$tmp/out")"
echo PASS
