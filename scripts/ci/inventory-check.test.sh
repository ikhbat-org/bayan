#!/usr/bin/env bash
# Tests scripts/ci/inventory-check.sh on fixture trees under tmp/: a clean pass, then each failure alone (class with no row,
# dropped row with no reason, case count below the test count, frozen row in csharp-internals), and the skip without EXPORT.tsv.
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
sed -i.bak 's/^GammaTests.*/GammaTests\tg\tcsharp-internals\t1\tfrozen\t\tr/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
expect "frozen csharp-internals" 1 "row GammaTests is csharp-internals and proven only by the frozen compiler"
good
sed -i.bak 's/^GammaTests.*/GammaTests\tg\tcli\t1\tfrozen\t\tr/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
expect "frozen outside csharp-internals" 0

good
printf 'class\tkind\ttests\tcases\treason\n' > "$t/tests/cases/EXPORT.tsv"
mkdir -p "$t/tests/cases/sem/AlphaTests/a" "$t/tests/cases/sem/AlphaTests/b"
expect "case count below" 1 "row AlphaTests has 2 cases under tests/cases/sem/AlphaTests, below its 3 tests"
mkdir -p "$t/tests/cases/sem/AlphaTests/c"
touch "$t/tests/cases/sem/AlphaTests/stray-file"
expect "case count met" 0 "inventory-check: ok"
! grep -q "skip case counts" <<<"$out" || fail "skip printed with EXPORT.tsv: $out"
rm -rf "$t/tests/cases/sem"
printf 'AlphaTests\tsem\t3\t0\tno export: typed rows\n' >> "$t/tests/cases/EXPORT.tsv"
expect "class not exported" 0

good
printf 'class\tkind\ttests\tcases\treason\n' > "$t/tests/cases/EXPORT.tsv"
printf 'DeltaTests\td\tcli\t3\tgolden\ttests/cases/fmt\tr\nEpsTests\te\tcli\t2\tgolden\ttests/cases/fmt\tr\n' >> "$t/tests/inventory-019.tsv"
printf 'public class DeltaTests { [Fact] public void A() {} }\npublic class EpsTests { [Fact] public void A() {} }\n' > "$t/src/tests/DeltaTests.cs"
expect "golden folder missing" 1 "row DeltaTests has 0 cases, no tests/cases/fmt folder"
mkdir -p "$t/tests/cases/fmt"; for i in 1 2 3 4; do touch "$t/tests/cases/fmt/c$i.byn" "$t/tests/cases/fmt/c$i.out"; done
mkdir -p "$t/tests/cases/sem/AlphaTests/a" "$t/tests/cases/sem/AlphaTests/b" "$t/tests/cases/sem/AlphaTests/c"
expect "golden below" 1 "row DeltaTests has 4 cases in tests/cases/fmt, below the 5 tests of its golden rows"
touch "$t/tests/cases/fmt/c5.byn"
expect "golden met" 0 "inventory-check: ok"

good
printf 'class\tkind\ttests\tcases\treason\n' > "$t/tests/cases/EXPORT.tsv"
sed -i.bak 's/^AlphaTests.*/AlphaTests\ta\tcsharp-internals\t3\tfrozen\t\t/' "$t/tests/inventory-019.tsv"; rm "$t/tests/inventory-019.tsv.bak"
printf 'public class DeltaTests { [Fact] public void A() {} }\n' > "$t/src/tests/DeltaTests.cs"
expect "several offenders" 1 "AlphaTests is csharp-internals"
grep -q "class DeltaTests has no row" <<<"$out" || fail "several: DeltaTests missing: $out"
rm -rf "$t"
echo "inventory-check.test: ok"
