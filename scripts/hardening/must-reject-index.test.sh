#!/usr/bin/env bash
# Tests must-reject-index.sh on a fixture index and case dir under tmp/. Prints `N passed, M failed`; exit 1 on a failure.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tool="$root/scripts/hardening/must-reject-index.sh"
t="$root/tmp/must-reject-index-test"
rm -rf "$t"; mkdir -p "$t/cases/dircase"
echo 'error BYN1111: a' > "$t/cases/ok.diag"
echo 'error BYN2222: b' > "$t/cases/dircase/main.diag"
passed=0; failed=0
check() { # <name> <expected exit> <expected output substring> <index lines...>
    local name=$1 want=$2 sub=$3; shift 3
    printf '# fixture\n%s\n' "$@" > "$t/index.md"
    local out rc
    out=$(bash "$tool" "$t/index.md" "$t/cases"); rc=$?
    if [ $rc = "$want" ] && printf '%s' "$out" | grep -qF -- "$sub"; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL $name"; fi
}
check present-with-code 0 "cases 1, missing 0, code-mismatch 0" '- diag/ok: BYN1111'
check directory-case 0 "cases 1, missing 0, code-mismatch 0" '- diag/dircase: BYN2222'
check missing-case 1 "cases 1, missing 1, code-mismatch 0" '- diag/nope: BYN1111'
check wrong-code 1 "cases 1, missing 0, code-mismatch 1" '- diag/ok: BYN9999'
check second-code-wrong 1 "code-mismatch 1" '- diag/ok: BYN1111, BYN9999'
check names-reported 1 "missing diag/nope" '- diag/nope: BYN1111'
echo "$passed passed, $failed failed"
[ $failed = 0 ]
