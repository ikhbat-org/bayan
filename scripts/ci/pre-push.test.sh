#!/usr/bin/env bash
# Tests scripts/ci/pre-push.sh in a scratch repo under tmp/, with a stub in place of the real 90 s script-tests run
# (PRE_PUSH_TEST_CMD, which pre-push.sh runs in the checkout; this test never runs script-tests.sh).
# A pass exits 0 and records the tree; the same tree again skips; a failure exits non-zero; the temp checkout is gone after
# either; a bad sha or no argument exits 2.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/pre-push-test"; rm -rf "$t"; mkdir -p "$t/scripts/ci"; cd "$t"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null  # not the machine's commit hooks
git init -q -b scratch .
printf 'tmp/\n' > .gitignore
cp "$root/scripts/ci/pre-push.sh" scripts/ci/
echo one > file; git add -A; git commit -qm "test: one"; one="$(git rev-parse HEAD)"
echo two > file; git commit -qam "test: two"; two="$(git rev-parse HEAD)"
git commit -q --allow-empty -m "test: same tree"; same="$(git rev-parse HEAD)"
pp=scripts/ci/pre-push.sh
# the stub fails when the checked-out file says "two"; it also shows it ran on the commit, not on the working tree
echo dirty > file
export PRE_PUSH_TEST_CMD='echo ran "$(cat file)" >> "'"$t"'/ran"; ! grep -qx two file || { echo "FAIL stub"; exit 1; }'
leftover() { [ -z "$(ls -d tmp/pre-push/wt-* 2>/dev/null)" ] && [ -z "$(git worktree list --porcelain | grep -c 'wt-' | grep -v '^0$')" ]; }

rc=0; bash $pp "$one" >/dev/null 2>&1 || rc=$?; [ $rc = 0 ] || fail "a passing commit exited $rc"
grep -qx "$(git rev-parse "$one^{tree}")" tmp/pre-push/passed || fail "the passed tree was not recorded"
grep -qx 'ran one' ran || fail "the test did not run on the commit's files"
leftover || fail "the checkout is left after a pass"
[ "$(cat file)" = dirty ] || fail "the working tree was touched"

rc=0; out="$(bash $pp "$one" 2>&1)" || rc=$?; [ $rc = 0 ] || fail "a passed tree exited $rc"
[ "$(($(wc -l < ran)))" = 1 ] || fail "a passed tree ran the tests again"
[ "$(($(wc -l <<<"$out")))" = 1 ] || fail "the skip is not one line: $out"

rc=0; out="$(bash $pp "$two" 2>&1)" || rc=$?; [ $rc != 0 ] || fail "a failing stub exited 0"
grep -q -- '--no-verify' <<<"$out" || fail "the failure does not name --no-verify: $out"
leftover || fail "the checkout is left after a failure"
rc=0; bash $pp "$same" >/dev/null 2>&1 || rc=$?; [ $rc != 0 ] || fail "a failed tree was recorded as passed"

rc=0; bash $pp deadbeef >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "a bad sha exited $rc, not 2"
rc=0; bash $pp >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "no argument exited $rc, not 2"
echo "pre-push.test: all passed"
