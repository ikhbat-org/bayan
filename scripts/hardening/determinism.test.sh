#!/usr/bin/env bash
# Standalone checks for compare_case in determinism.sh, with fixture files under tmp/hardening/det-test/ (no driver needed).
# Prints `N passed, M failed`; exits 1 on a failure.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$root/scripts/hardening/determinism.sh"
t="$root/tmp/hardening/det-test"
rm -rf "$t"; mkdir -p "$t"
pass=0; fail=0
check() { # <name> <want> <got>
    if [ "$2" = "$3" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $1: want [$2] got [$3]"; fi
}
pa="$t/det-a"; pb="$t/det-b-longer-path"
printf 'int main(void){return 0;}\n' >"$t/c1"; cp "$t/c1" "$t/c2"
printf 'int main(void){return 1;}\n' >"$t/c3"
printf 'ELF\0same bytes\0' >"$t/b1"; cp "$t/b1" "$t/b2"
printf 'ELF\0%s/prog.c\0padding' "$pa" >"$t/b3"
printf 'ELF\0%s/prog.c\0padding' "$pb" >"$t/b4"
printf 'ELF\0other bytes\0' >"$t/b5"

check "equal C and binaries" "" "$(compare_case "$t/c1" "$t/c2" "$t/b1" "$t/b2" 1 "$pa" "$pb")"
check "differing C" "c" "$(compare_case "$t/c1" "$t/c3" "$t/b1" "$t/b2" 1 "$pa" "$pb")"
check "differing binary with embedded path" "bin embedded build path" "$(compare_case "$t/c1" "$t/c2" "$t/b3" "$t/b4" 1 "$pa" "$pb")"
check "differing binary without a path" "bin" "$(compare_case "$t/c1" "$t/c2" "$t/b1" "$t/b5" 1 "$pa" "$pb")"
check "binary check skipped off Linux" "" "$(compare_case "$t/c1" "$t/c2" "$t/b3" "$t/b4" 0 "$pa" "$pb")"
check "differing C and binary" "c bin embedded build path" "$(compare_case "$t/c1" "$t/c3" "$t/b3" "$t/b4" 1 "$pa" "$pb")"

echo "$pass passed, $fail failed"
[ $fail = 0 ]
