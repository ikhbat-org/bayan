#!/usr/bin/env bash
# Tests scripts/selfhost/reexport-check.sh on a scratch repo with a stub `dotnet` (REEXPORT_DOTNET): its `test` logs the filter
# and copies the classes the filter names from $AUX/export into BAYAN_EXPORT_DIR, less the case in $DROP and plus $AUX/extra
# when $EXTRA is set. The tree passes; a changed expected file, a missing row and an extra file with a FREEZE.tsv row each fail
# naming the path; an extra file with no row is listed and passes; a
# DIVERGENCES.tsv row (case key or Class.Test) lets its case differ; the seed picks the same classes twice; --full has no
# filter; a class whose source names no SelfhostExport type at the head is printed as left out, never compared, and
# refused by --class; no dotnet fails without a pass; usage errors exit 2.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/reexport-check-test.XXXXXX")"
aux="$tmp/aux"; mkdir -p "$aux"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; [ -z "${2:-}" ] || echo "$2" >&2; exit 1; }

cat > "$aux/dotnet" <<'STUB'
#!/bin/bash
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
chmod +x "$aux/dotnet"
export AUX="$aux" REEXPORT_DOTNET="$aux/dotnet"
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
cp "$root/scripts/selfhost/reexport-check.sh" "$root/scripts/selfhost/land-export.sh" scripts/selfhost/
printf '/tmp/\n' > .gitignore; printf '* text=auto eol=lf\ntests/cases/inputs/files/** -text\n' > .gitattributes
# export mode at the head: ACliTests and BSemTests name SelfhostExport, ASemTests names a Selfhost harness, CSemTests neither
mkdir -p src/tests csharp/tests
printf 'class SelfhostExport { }\nclass SelfhostFakeHarness { SelfhostExport e; }\n' > src/tests/SelfhostExport.cs
printf 'class ACliTests { SelfhostExport e; }\n' > src/tests/ACliTests.cs
printf 'class ASemTests { SelfhostFakeHarness h; }\n' > src/tests/ASemTests.cs
printf 'class BSemTests { SelfhostExport e; }\n' > csharp/tests/BSemTests.cs
printf 'class CSemTests { Cli c; }\n' > src/tests/CSemTests.cs
git add -A; git commit -qm export; head="$(git rev-parse HEAD)"
cp -R "$aux/export/." tests/cases/
mk tests/cases sem/CSemTests/Five "five"
printf 'class\tfile\tfamily\ttests\tdisposition\ttarget\treason\tmemberdata\n' > tests/inventory-019.tsv
for c in ACliTests ASemTests BSemTests CSemTests; do printf '%s\tx.cs\tf\t1\tcli\tcli\t\t\n' "$c" >> tests/inventory-019.tsv; done
printf 'class\tkind\ttests\tcases\treason\nACliTests\tcli\t1\t1\t\nASemTests\tsem\t1\t2\t\nBSemTests\tsem\t1\t1\t\nCSemTests\tsem\t1\t1\t\nShellTests\tshell\t1\t3\t\n' \
  > tests/cases/EXPORT.tsv
printf 'case\tquestion\tright\treason\n' > tests/cases/DIVERGENCES.tsv
{ printf 'tag\tv0\t%s\nexport\tchore/export\t%s\n' "$head" "$head"
  find tests/cases -name 'expected.*' | LC_ALL=C sort | while IFS= read -r p; do printf 'file\t%s\t%s\n' "$(git hash-object "$p")" "$p"; done
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
run > /dev/null; grep -q "seed $(date -u +%G%V): 2 classes" "$tmp/out" || fail "no seed: want the ISO week" "$(cat "$tmp/out")"
grep -A1 "left out, not checked .*: 1 classes" "$tmp/out" | grep -q "^  sem/CSemTests$" || fail "the left-out class is not printed" "$(cat "$tmp/out")"
[ "$(run --full)" = 0 ] && [ "$(tail -1 "$aux/log")" = "filter=" ] || fail "--full: want exit 0 and no filter" "$(cat "$tmp/out")"
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

[ "$(REEXPORT_DOTNET=$tmp/no-dotnet run "${all[@]}")" = 1 ] || fail "no dotnet: want exit 1" "$(cat "$tmp/out")"
grep -q "no dotnet on PATH: L043 is not checked" "$tmp/out" && ! grep -q "ok in" "$tmp/out" || fail "no dotnet: want the message and no pass" "$(cat "$tmp/out")"
echo PASS
