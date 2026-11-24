#!/usr/bin/env bash
# Tests scripts/ci/golden-commit-check.sh in a scratch repo under tmp/: a mixed commit is refused, a golden-only commit with
# no cause is refused, with a sha or a task id (T30, T41b, T123) cause it passes and with "Txyz" it is refused, manifest plus golden passes, an unrelated commit passes, merges are skipped,
# a mixed commit in scripts/ci/golden-commit-allow.txt passes and one not in it is refused, a mixed commit reachable from a ref
# given after the range passes.
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
for m in "fix per T41b" "T123 follow" "T30 x"; do
  echo "$m" >> tests/cases/diag/a.diag; git commit -qam "$m"; expect "golden-only, task id cause '$m'" 0
done
echo n >> tests/cases/diag/a.diag; git commit -qam "Txyz goldens"
expect "golden-only, Txyz is no task id" 1
mkdir -p tests/cases/cli/C-1; echo j > tests/cases/cli/C-1/expected.sections; echo j > tests/cases/cli/C-1/expected.golden; git add -A; git commit -qm "exported case for Q1018"
expect "exported case expected files" 0
echo k > tests/cases/cli/C-1/expected.golden; echo k > src/a.txt; git commit -qam "exported case with src for Q1018"
expect "exported case mixed with src" 1
echo g > src/a.txt; git commit -qam "unrelated"
expect "unrelated commit" 0
# a range holding the bad commits reports them all, and a merge is skipped
git checkout -q -b side; echo h > src/b.txt; git add -A; git commit -qm "side work"
git checkout -q main; echo i > src/c.txt; git add -A; git commit -qm "main work"
git merge -q --no-ff side -m "merge side" 2>/dev/null
expect "merge commit" 0
run_check "$(git rev-list --max-parents=0 HEAD)"; [ "$rc" = 1 ] || fail "whole range exit $rc"
[ "$(grep -c 'golden-commit-check: [0-9a-f]\{7\} ' <<<"$out")" = 4 ] || fail "whole range should name 4 commits: $out"
rc=0; bash "$gc" nonsense >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "bad usage exit $rc"
# a mixed commit listed in scripts/ci/golden-commit-allow.txt (as of the range's head) passes; one not listed is refused
start="$(git rev-parse HEAD)"
echo l > tests/cases/diag/a.diag; echo l > src/a.txt; git commit -qam "listed mixed commit"; listed="$(git rev-parse HEAD)"
mkdir -p scripts/ci; printf '# comment\n%s  # listed\n' "$listed" > scripts/ci/golden-commit-allow.txt; git add -A; git commit -qm "allow list"
run_check "$start"; [ "$rc" = 0 ] || fail "a listed mixed commit was refused: $out"
echo m > tests/cases/diag/a.diag; echo m > src/a.txt; git commit -qam "unlisted mixed commit"
run_check "$start"; [ "$rc" = 1 ] || fail "an unlisted mixed commit after a listed one exit $rc"
[ "$(grep -c 'together with a file' <<<"$out")" = 1 ] && grep -q 'unlisted mixed commit' <<<"$out" || fail "only the unlisted commit should be refused: $out"
# commits reachable from a ref given after the range are left out (pre-push passes origin/dev and origin/main)
start="$(git rev-parse HEAD)"
git checkout -q -b pub; echo o > tests/cases/diag/a.diag; echo o > src/a.txt; git commit -qam "published mixed commit"
git checkout -q main; git merge -q --no-ff pub -m "merge pub" 2>/dev/null
run_check "$start"; [ "$rc" = 1 ] || fail "a published mixed commit without the ref exit $rc"
rc=0; out="$(bash "$gc" "$start..HEAD" pub 2>&1)" || rc=$?; [ "$rc" = 0 ] || fail "a mixed commit reachable from the ref was refused: $out"
echo p > tests/cases/diag/a.diag; echo p > src/a.txt; git commit -qam "unpublished mixed commit"
rc=0; out="$(bash "$gc" "$start..HEAD" pub 2>&1)" || rc=$?; [ "$rc" = 1 ] || fail "an unpublished mixed commit with the ref exit $rc"
[ "$(grep -c 'together with a file' <<<"$out")" = 1 ] && grep -q 'unpublished mixed commit' <<<"$out" || fail "only the unpublished commit should be refused: $out"
echo "golden-commit-check.test: ok"
