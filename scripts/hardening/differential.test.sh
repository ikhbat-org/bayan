#!/usr/bin/env bash
# Tests compare_cells of scripts/hardening/differential.sh on fixture cells (records.tsv and out/<flat>.stderr) under tmp/.
# DIFFERENTIAL overrides the script under test.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=differential.sh
source "${DIFFERENTIAL:-$root/scripts/hardening/differential.sh}"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/differential-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

pass=0; failed=0
check() { if [ "$2" = 0 ]; then pass=$((pass + 1)); else failed=$((failed + 1)); echo "FAIL: $1"; fi; }

# fixture <dir> <case> <exit> <stdout hash> <stderr text>: one record and its stderr file
fixture() {
    mkdir -p "$1/out"
    printf '%s\t%s\t%s\t-\n' "$2" "$3" "$4" >>"$1/records.tsv"
    printf '%s' "$5" >"$1/out/${2//\//_}.stderr"
    : >"$1/out/${2//\//_}.stdout"
}
# compare <name>: compare_cells of $tmp/<name>/base and $tmp/<name>/cell, its summary line
compare() { compare_cells "$tmp/$1/base" "$tmp/$1/cell" "$tmp/report" | head -n 1; }

fixture "$tmp/eq/base" run/a 0 h1 ""; fixture "$tmp/eq/cell" run/a 0 h1 ""
fixture "$tmp/eq/base" run/b 3 h2 "panic: x\n"; fixture "$tmp/eq/cell" run/b 3 h2 "panic: x\n"
[ "$(compare eq)" = "cases 2, divergent 0, debug skipped 0" ]; check "equal records are not divergent" $?

fixture "$tmp/out/base" run/a 0 h1 ""; fixture "$tmp/out/cell" run/a 0 h9 ""
[ "$(compare out)" = "cases 1, divergent 1, debug skipped 0" ]; check "a differing stdout hash is divergent" $?
compare_cells "$tmp/out/base" "$tmp/out/cell" "$tmp/report" | grep -qx '  run/a'; check "a divergent case is named" $?

fixture "$tmp/trap/base" run/a 134 h1 $'noise\npanic: index out of range\n'
fixture "$tmp/trap/cell" run/a 139 h1 $'panic: index out of range\n'
[ "$(compare trap)" = "cases 1, divergent 0, debug skipped 0" ]; check "non-zero exits with the same trap line are not divergent" $?

fixture "$tmp/trap2/base" run/a 134 h1 $'panic: index out of range\n'
fixture "$tmp/trap2/cell" run/a 1 h1 $'panic: overflow\n'
[ "$(compare trap2)" = "cases 1, divergent 1, debug skipped 0" ]; check "non-zero exits with different trap lines are divergent" $?

fixture "$tmp/zero/base" run/a 0 h1 $'panic: x\n'; fixture "$tmp/zero/cell" run/a 1 h1 $'panic: x\n'
[ "$(compare zero)" = "cases 1, divergent 1, debug skipped 0" ]; check "a zero against a non-zero exit is divergent" $?

fixture "$tmp/dbg/base" run/d debug - ""; fixture "$tmp/dbg/cell" run/d debug - ""
fixture "$tmp/dbg/base" run/e 0 h1 ""; fixture "$tmp/dbg/cell" run/e 0 h1 ""
[ "$(compare dbg)" = "cases 1, divergent 0, debug skipped 1" ]; check "debug cases are skipped and counted" $?

for i in $(seq 1 25); do fixture "$tmp/many/base" "run/c$i" 0 h1 ""; fixture "$tmp/many/cell" "run/c$i" 0 h2 ""; done
sort -o "$tmp/many/base/records.tsv" "$tmp/many/base/records.tsv"; sort -o "$tmp/many/cell/records.tsv" "$tmp/many/cell/records.tsv"
out=$(compare_cells "$tmp/many/base" "$tmp/many/cell" "$tmp/report")
[ "$(printf '%s\n' "$out" | grep -c '^  run/')" = 20 ] && printf '%s\n' "$out" | grep -qx '  … and 5 more'
check "at most 20 names, then the rest counted" $?

echo "$pass passed, $failed failed"
[ "$failed" = 0 ]
