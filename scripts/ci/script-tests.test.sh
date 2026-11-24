#!/usr/bin/env bash
# Tests scripts/ci/script-tests.sh: every file it lists exists, ci.yml reaches it only through scripts/test.sh and runs no test of
# its own, an unknown group exits 2, and a failing test makes it exit 1 after running the rest.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
s="$root/scripts/ci/script-tests.sh"
fail() { echo "FAIL $1"; exit 1; }
while IFS= read -r f; do [ -f "$root/$f" ] || fail "script-tests.sh lists a missing file: $f"; done < <(bash "$s" list)
ci="$root/.github/workflows/ci.yml"
grep -qx '        run: bash scripts/test.sh \$TEST_ARGS' "$ci" || fail "ci.yml's Test step does not run scripts/test.sh"
grep -q "TEST_ARGS: \${{ matrix.part == 'other' && '--skip golden' || " "$ci" || fail "ci.yml's other-parts job does not run the parts but golden"
! grep -n 'script-tests.sh' "$ci" || fail "ci.yml runs script-tests.sh beside scripts/test.sh, so the script tests run twice"
grep -q 'scripts/ci/script-tests.sh \$groups' "$root/scripts/test.sh" || fail "scripts/test.sh does not run script-tests.sh"
grep -qx 'groups="unix"; \[ \$os = linux \] && groups="unix docs"' "$root/scripts/test.sh" || fail "scripts/test.sh does not run the docs group on Linux"
grep -qx '\[ -z "\${SCRIPT_TESTS_GROUPS:-}" \] || groups=\$SCRIPT_TESTS_GROUPS' "$root/scripts/test.sh" || fail "scripts/test.sh ignores SCRIPT_TESTS_GROUPS"
grep -qx "          SCRIPT_TESTS_GROUPS: \${{ matrix.part == 'slow' && 'slow' || matrix.os == 'ubuntu-latest' && 'fast docs' || 'fast' }}" "$ci" || fail "ci.yml does not split the script tests into fast (other parts) and slow"
grep -q "matrix.part == 'slow' && '--only scripts' || " "$ci" || fail "ci.yml's slow job does not run the scripts part alone"
grep -qx '        part: \[other, slow, .*' "$ci" || fail "ci.yml has no slow part"
! grep -nE '^\s+(bash scripts/.*\.test\.sh|for f in scripts/docs)' "$ci" || fail "ci.yml runs a script test outside script-tests.sh"
rc=0; bash "$s" nope > /dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "an unknown group exited $rc, not 2"

t="$root/tmp/script-tests-test"; rm -rf "$t"; mkdir -p "$t/scripts/ci"
cp "$s" "$t/scripts/ci/"
printf 'exit 1\n' > "$t/bad.sh"; printf 'echo ran >> "%s/ran"\n' "$t" > "$t/good.sh"; printf 'echo slow >> "%s/slowran"\n' "$t" > "$t/slowx.sh"
sed -i.bak -e 's#^slow=(.*#slow=(slowx.sh)#' -e 's#^unix=(.*#unix=(bad.sh good.sh)#' -e '/^  scripts\//d' "$t/scripts/ci/script-tests.sh"
rc=0; out="$("$BASH" "$t/scripts/ci/script-tests.sh" unix 2>&1)" || rc=$?  # "$BASH": the bash under test (macOS /bin/bash 3.2), not the first on PATH
[ $rc = 1 ] || fail "a failing test exited $rc, not 1: $out"
grep -q 'FAILED bad.sh' <<<"$out" || fail "the failure is not named: $out"
[ -f "$t/ran" ] || fail "the test after a failing one did not run"
[ -f "$t/slowran" ] || fail "the unix group did not run the slow tests"
rm -f "$t/ran" "$t/slowran"
"$BASH" "$t/scripts/ci/script-tests.sh" fast > /dev/null 2>&1 || true
[ -f "$t/ran" ] && [ ! -f "$t/slowran" ] || fail "the fast group did not run the unix tests alone"
rm -f "$t/ran"
out="$("$BASH" "$t/scripts/ci/script-tests.sh" slow 2>&1)" || fail "the slow group failed: $out"
[ -f "$t/slowran" ] && [ ! -f "$t/ran" ] || fail "the slow group did not run the slow tests alone"
! bash "$s" list-quick | grep -q "^scripts/evals/" || fail "the quick group (pre-push) runs the slow eval tests"
bash "$s" list | grep -qx scripts/evals/llm-eval.test.sh || fail "the full list lost llm-eval.test.sh"
! bash "$s" list-quick | grep -qx scripts/sabk/sabk.test.sh || fail "the quick group (pre-push) runs sabk.test.sh"
bash "$s" list | grep -qx scripts/sabk/sabk.test.sh || fail "the full list lost sabk.test.sh"
[ "$(grep -o "script-tests.sh quick\"" "$root/scripts/ci/pre-push.sh" | wc -l | tr -d " ")" = 2 ] || fail "pre-push.sh does not run the quick group"
echo "script-tests.test: all passed"
