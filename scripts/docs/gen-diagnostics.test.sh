#!/usr/bin/env bash
# gen-diagnostics.sh on a fixture repo (test-fixture.sh): rows per status, counts, escaping, page links, determinism,
# --write, refusals of a bad hand-kept line and of a plan code that has a descriptor.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
t="$root/tmp/docs-gen-diagnostics-test"
rm -rf "$t" && mkdir -p "$t"
trap 'rm -rf "$t"' EXIT
. "$root/scripts/docs/test-fixture.sh"
docs_fixture "$t/repo"
s="$t/repo/scripts/docs/gen-diagnostics.sh"; d="$t/repo/docs/DIAGNOSTICS.md"; h="$t/repo/docs/diagnostics-allocated.txt"
fail() { echo "FAIL: $1" >&2; exit 1; }
has() { grep -qxF "$1" "$d" || fail "DIAGNOSTICS.md lacks: $1"; }

has 'Version: 1.2.3-dev (matches `bayan --version`)'
has 'Revisions applied: 0001–0002'
has '| [BYN0001](diagnostics/BYN0001.md) | Alpha | Error | live | alpha `{0}` |'
has '| BYN2003 | Gamma | Warning | live | a \| b needs "quotes" |'
has '| BYN1002 | RetiredBeta | Error | retired | retired: beta |'
has '| BYN3004 | Delta | Error | reserved | delta |'
has '| BYN3005 | Old | Error | retired | old |'
has '| BYN2233 | UnlikelyOnErrorReturn | Warning: redundant. |'
has '| BYN1070 | NegatedIsInput | `!(x is .s)`. // target: 19xx input form | `DiagnosticCodes.cs` round-4 block |'
has '| BYN8004 | - | a layer-2 sink | `docs/diagnostics-allocated.txt` |'
has '| BYN3005 | Old | retired in its page only | `docs/diagnostics-allocated.txt` |'
for row in '| live | 2 |' '| plan | 1 |' '| reserved | 3 |' '| retired | 2 |' '| total | 8 |'; do has "$row"; done
grep -q 'second form' "$d" && fail "the new(...) second form became a row"
[ "$(bash "$s")" = "$(cat "$d")" ] || fail "stdout differs from the --write output"
[ "$(bash "$s")" = "$(bash "$s")" ] || fail "output not deterministic"

cp "$h" "$t/h"
echo 'planned BYN9999 X note' >> "$h"
out="$(bash "$s" 2>&1)" && fail "bad status accepted"
echo "$out" | grep -q "each line is" || fail "no bad-line message: $out"
cp "$t/h" "$h"; echo 'plan BYN0001 Alpha note' >> "$h"
out="$(bash "$s" 2>&1)" && fail "plan code with a descriptor accepted"
echo "$out" | grep -q "have a descriptor: BYN0001" || fail "no clash message: $out"
cp "$t/h" "$h"; echo 'reserved BYN1070 X note' >> "$h"
out="$(bash "$s" 2>&1)" && fail "code listed twice accepted"
echo "$out" | grep -q "listed twice" || fail "no listed-twice message: $out"
cp "$t/h" "$h"
echo PASS
