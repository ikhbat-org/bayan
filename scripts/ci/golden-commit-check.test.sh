#!/usr/bin/env bash
# Tests scripts/ci/golden-commit-check.sh in a scratch repo under tmp/: a mixed commit is refused, a golden-only commit with
# no cause is refused, with a sha cause it passes, manifest plus golden passes, an unrelated commit passes, merges are skipped.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/golden-commit-check-test"; rm -rf "$t"; mkdir -p "$t"; cd "$t"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null
git init -q -b main .
mkdir -p tests/cases/diag src
echo a > src/a.txt; echo x > tests/cases/diag/a.diag; git add -A; git commit -qm "base"
gc="$root/scripts/ci/golden-commit-check.sh"
run_check() { rc=0; out="$(bash "$gc" "$1..HEAD" 2>&1)" || rc=$?; }
expect() { # name exit: checks the newest commit alone
  run_check "$(git rev-parse HEAD~1)"
  [ "$rc" = "$2" ] || fail "$1: exit $rc, wanted $2: $out"
}
echo b > tests/cases/diag/a.diag; echo b > src/a.txt; git commit -qam "update goldens with src"
expect "mixed commit" 1; grep -q 'together with a file' <<<"$out" || fail "mixed reason: $out"
echo c > tests/cases/diag/a.diag; git commit -qam "update goldens"
expect "golden-only, no cause" 1; grep -q 'names no cause' <<<"$out" || fail "no-cause reason: $out"
echo d > tests/cases/diag/a.diag; git commit -qam "update goldens, caused by 1a2b3c4d"
expect "golden-only, sha cause" 0
echo e > tests/cases/diag/a.diag; git commit -qam "regenerate after Q1272"
expect "golden-only, Q cause" 0
echo f > tests/cases/diag/a.diag; printf 'k\t1\n' > tests/cases/FREEZE.tsv; git add -A; git commit -qm "refresh for T21"
expect "manifest and golden" 0
mkdir -p tests/cases/cli/C-1; echo j > tests/cases/cli/C-1/expected.sections; echo j > tests/cases/cli/C-1/expected.golden; git add -A; git commit -qm "exported case for Q1018"
expect "exported case expected files" 0
echo g > src/a.txt; git commit -qam "unrelated"
expect "unrelated commit" 0
# a range holding the bad commits reports them all, and a merge is skipped
git checkout -q -b side; echo h > src/b.txt; git add -A; git commit -qm "side work"
git checkout -q main; echo i > src/c.txt; git add -A; git commit -qm "main work"
git merge -q --no-ff side -m "merge side" 2>/dev/null
expect "merge commit" 0
run_check "$(git rev-list --max-parents=0 HEAD)"; [ "$rc" = 1 ] || fail "whole range exit $rc"
[ "$(grep -c 'golden-commit-check: [0-9a-f]\{7\} ' <<<"$out")" = 2 ] || fail "whole range should name 2 commits: $out"
rc=0; bash "$gc" nonsense >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "bad usage exit $rc"
echo "golden-commit-check.test: ok"
