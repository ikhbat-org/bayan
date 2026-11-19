#!/usr/bin/env bash
# Tests scripts/ci/inventory-check.sh on fixture trees under tmp/: a clean pass, then each failure alone (class with no row,
# dropped row with no reason, also with the 8th column memberdata set, case count below the test count (alone, and with an
# EXPORT.tsv reason whose leading count names too few tests), frozen row in csharp-internals,
# a flat-case target naming a missing case or none, a golden folder's exported <Class>/ subfolder counted as
# a case, a nightly row whose script is missing or not in laws-nightly.yml), and the skip without EXPORT.tsv.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/inventory-check-test"; rm -rf "$t"; mkdir -p "$t"
chk="$root/scripts/ci/inventory-check.sh"
run_check() { rc=0; out="$(bash "$chk" "$t" 2>&1)" || rc=$?; }
expect() { # name exit [text the output must hold]
  run_check
  [ "$rc" = "$2" ] || fail "$1: exit $rc, wanted $2: $out"
  [ -z "${3:-}" ] || grep -q -- "$3" <<<"$out" || fail "$1: no '$3' in: $out"
}
good() { # the clean tree and inventory
  rm -rf "$t/csharp" "$t/src" "$t/tests"; mkdir -p "$t/csharp/tests/X" "$t/src/tests" "$t/tests/cases"
  printf 'public sealed class AlphaTests\n{\n    [Fact]\n    public void A() {}\n    [Theory]\n    public void B(int i) {}\n}\n' > "$t/csharp/tests/X/AlphaTests.cs"
  printf 'internal static class Helper { }\npublic class BetaTests\n{\n    [Fact(Skip = "x")]\n    public void A() {}\n}\n' > "$t/src/tests/BetaTests.cs"
  printf 'public class GammaTests { [Fact] public void A() {} }\n' > "$t/src/tests/GammaTests.cs"
  { printf 'class\tfile\tfamily\ttests\tdisposition\ttarget\treason\n'
    printf 'AlphaTests\ta\tcsharp-internals\t3\tsem\tsem\tr\n'
    printf 'BetaTests\tb\tcli\t1\tdropped\t\tgone\n'
    printf 'GammaTests\tg\tcli\t1\tshell\tshell\tr\n'; } > "$t/tests/inventory-019.tsv"
}
good
expect "clean, no export" 0 "skip case counts: no tests/cases/EXPORT.tsv"
grep -q "inventory-check: ok" <<<"$out" || fail "clean: no ok: $out"

printf 'public class DeltaTests { [Theory] public void A() {} }\n' > "$t/src/tests/DeltaTests.cs"
expect "class with no row" 1 "class DeltaTests has no row"
good
printf 'BetaTests\tb\tcli\t1\tdropped\t\t\n' >> "$t/tests/inventory-019.tsv"
sed -i.bak '/^BetaTests.*gone$/d' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
expect "dropped, no reason" 1 "row BetaTests is dropped with no reason"
good
sed -i.bak 's/$/\t/; 1s/\t$/\tmemberdata/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"   # the 8th column
expect "memberdata column" 0 "inventory-check: ok"
sed -i.bak 's/^BetaTests.*/BetaTests\tb\tcli\t1\tdropped\t\t\tno export: typed rows/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
expect "dropped, no reason, memberdata set" 1 "row BetaTests is dropped with no reason"
good
sed -i.bak 's/^GammaTests.*/GammaTests\tg\tcsharp-internals\t1\tfrozen\t\tr/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
expect "frozen csharp-internals" 1 "row GammaTests is csharp-internals and proven only by the frozen compiler"
good
sed -i.bak 's/^GammaTests.*/GammaTests\tg\tcli\t1\tfrozen\t\tr/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
expect "frozen outside csharp-internals" 0

good
printf 'class\tkind\ttests\tcases\treason\n' > "$t/tests/cases/EXPORT.tsv"
mkdir -p "$t/tests/cases/sem/AlphaTests/a" "$t/tests/cases/sem/AlphaTests/b"
expect "case count below" 1 "row AlphaTests has 2 cases under tests/cases/sem/AlphaTests and 0 tests named by reasons, below its 3 tests"
mkdir -p "$t/tests/cases/sem/AlphaTests/c"
touch "$t/tests/cases/sem/AlphaTests/stray-file"
expect "case count met" 0 "inventory-check: ok"
! grep -q "skip case counts" <<<"$out" || fail "skip printed with EXPORT.tsv: $out"
rm -rf "$t/tests/cases/sem/AlphaTests/b" "$t/tests/cases/sem/AlphaTests/c"
printf 'AlphaTests\tsem\t3\t1\t1 not exported: B (covered by c)\n' >> "$t/tests/cases/EXPORT.tsv"
expect "reason for one test, too few cases" 1 "row AlphaTests has 1 cases under tests/cases/sem/AlphaTests and 1 tests named by reasons, below its 3 tests"
mkdir -p "$t/tests/cases/sem/AlphaTests/b"
expect "cases and named tests account for the class" 0 "inventory-check: ok"
rm -rf "$t/tests/cases/sem"
printf 'class\tkind\ttests\tcases\treason\n' > "$t/tests/cases/EXPORT.tsv"
printf 'AlphaTests\tsem\t3\t0\tno export: typed rows\n' >> "$t/tests/cases/EXPORT.tsv"
expect "a reason with no count names no test" 1 "row AlphaTests has 0 cases under tests/cases/sem/AlphaTests and 0 tests named by reasons, below its 3 tests"
printf 'class\tkind\ttests\tcases\treason\nAlphaTests\tsem\t3\t0\t3 not exported: A, B x2 (typed rows)\n' > "$t/tests/cases/EXPORT.tsv"
expect "class not exported, every test named" 0

good
printf 'class\tkind\ttests\tcases\treason\n' > "$t/tests/cases/EXPORT.tsv"
sed -i.bak 's/^AlphaTests.*/AlphaTests\ta\tcsharp-internals\t3\tsem\tsem\/flat-a,flat-b\tr/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
mkdir -p "$t/tests/cases/sem/flat-b"; touch "$t/tests/cases/sem/flat-a.byn" "$t/tests/cases/sem/flat-a.diag"
expect "flat cases named" 0 "inventory-check: ok"
rm "$t/tests/cases/sem/flat-a.byn" "$t/tests/cases/sem/flat-a.diag"
expect "flat case missing" 1 "row AlphaTests names case sem/flat-a, not found under tests/cases/sem"
sed -i.bak 's/^AlphaTests\(.*\)\tsem\/flat-a,flat-b\t/AlphaTests\1\tsem\/\t/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
expect "flat target naming nothing" 1 "row AlphaTests names case sem/, not found"

good
printf 'class\tkind\ttests\tcases\treason\n' > "$t/tests/cases/EXPORT.tsv"
printf 'DeltaTests\td\tcli\t3\tgolden\ttests/cases/fmt\tr\nEpsTests\te\tcli\t2\tgolden\ttests/cases/fmt\tr\n' >> "$t/tests/inventory-019.tsv"
printf 'public class DeltaTests { [Fact] public void A() {} }\npublic class EpsTests { [Fact] public void A() {} }\n' > "$t/src/tests/DeltaTests.cs"
expect "golden folder missing" 1 "row DeltaTests has 0 cases, no tests/cases/fmt folder"
printf 'DeltaTests\tfmt\t3\t0\t3 not exported: A x3 (cli/DeltaCli)\n' >> "$t/tests/cases/EXPORT.tsv"
expect "golden folder missing, every test named" 1 "row EpsTests has 0 cases, no tests/cases/fmt folder, and 0 tests named"
! grep -q "row DeltaTests" <<<"$out" || fail "golden folder missing, named: DeltaTests still reported: $out"
printf 'class\tkind\ttests\tcases\treason\n' > "$t/tests/cases/EXPORT.tsv"
mkdir -p "$t/tests/cases/fmt"; for i in 1 2 3 4; do touch "$t/tests/cases/fmt/c$i.byn" "$t/tests/cases/fmt/c$i.out"; done
mkdir -p "$t/tests/cases/sem/AlphaTests/a" "$t/tests/cases/sem/AlphaTests/b" "$t/tests/cases/sem/AlphaTests/c"
expect "golden below" 1 "row DeltaTests has 4 cases in tests/cases/fmt and 0 tests named by reasons, below the 5 tests of its golden rows"
touch "$t/tests/cases/fmt/c5.byn"
expect "golden met" 0 "inventory-check: ok"
rm "$t/tests/cases/fmt/c5.byn"; mkdir -p "$t/tests/cases/fmt/KappaTests/k1"
printf 'KappaTests\tfmt\t1\t1\t\n' >> "$t/tests/cases/EXPORT.tsv"
expect "golden exported class subfolder not a case" 1 "row DeltaTests has 4 cases in tests/cases/fmt and 0 tests named by reasons, below the 5 tests"
mkdir "$t/tests/cases/fmt/c5"
expect "golden case subfolder" 0 "inventory-check: ok"
rm -rf "$t/tests/cases/fmt/KappaTests" "$t/tests/cases/fmt/c5"; touch "$t/tests/cases/fmt/c5.byn"
printf 'ZetaTests\tz\tcli\t12\tgolden\ttests/cases\tr\n' >> "$t/tests/inventory-019.tsv"
printf 'public class ZetaTests { [Fact] public void A() {} }\n' > "$t/src/tests/ZetaTests.cs"
expect "golden tests/cases below" 1 "row ZetaTests has 8 cases across the kind folders of tests/cases and 0 tests named by reasons, below its 12 tests"
mkdir -p "$t/tests/cases/other"; for i in 1 2 3 4 5 6 7; do touch "$t/tests/cases/other/o$i.byn"; done
expect "golden tests/cases met" 0 "inventory-check: ok"
rm -rf "$t/tests/cases/other"
sed -i.bak 's/^ZetaTests\(.*\)\t12\t/ZetaTests\1\t20\t/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
mkdir -p "$t/tests/cases/emit-c/KlassA" "$t/tests/cases/emit-c/KlassB" "$t/tests/cases/multi/m"
touch "$t/tests/cases/multi/m/main.byn"
for i in 1 2 3 4; do mkdir "$t/tests/cases/emit-c/KlassA/t$i"; done; for i in 1 2 3 4 5; do mkdir "$t/tests/cases/emit-c/KlassB/t$i"; done
expect "golden tests/cases per-test layout" 1 "row ZetaTests has 18 cases across"
mkdir "$t/tests/cases/emit-c/KlassB/t6" "$t/tests/cases/emit-c/KlassB/t7"
expect "golden tests/cases per-test layout met" 0 "inventory-check: ok"

good
rm -rf "$t/scripts" "$t/.github"
sed -i.bak 's/^GammaTests.*/GammaTests\tg\tcli\t1\tnightly\tscripts\/ci\/n.sh --mode a\tr/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
expect "nightly script missing" 1 "row GammaTests names nightly script 'scripts/ci/n.sh', not found"
mkdir -p "$t/scripts/ci" "$t/.github/workflows"; touch "$t/scripts/ci/n.sh"
expect "nightly script not in the workflow" 1 "row GammaTests names nightly script scripts/ci/n.sh, not run by .github/workflows/laws-nightly.yml"
printf '      - run: bash scripts/ci/n.sh\n' > "$t/.github/workflows/laws-nightly.yml"
expect "nightly script run by the workflow" 0 "inventory-check: ok"
rm -rf "$t/scripts" "$t/.github"

good
printf 'class\tkind\ttests\tcases\treason\n' > "$t/tests/cases/EXPORT.tsv"
sed -i.bak 's/^AlphaTests.*/AlphaTests\ta\tcsharp-internals\t3\tfrozen\t\t/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
printf 'public class DeltaTests { [Fact] public void A() {} }\n' > "$t/src/tests/DeltaTests.cs"
expect "several offenders" 1 "AlphaTests is csharp-internals"
grep -q "class DeltaTests has no row" <<<"$out" || fail "several: DeltaTests missing: $out"
rm -rf "$t"
echo "inventory-check.test: ok"
