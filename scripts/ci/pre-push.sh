#!/usr/bin/env bash
# Runs the ci script tests on a commit before it is pushed, in a throwaway checkout of that commit.
#   scripts/ci/pre-push.sh <sha>
# The git pre-push hook calls it when a push updates dev or main; a non-zero exit refuses the push (bypass once: git push --no-verify).
# A passing tree is recorded in tmp/pre-push/passed, so the same tree is not tested twice.
# Before the tests it runs scripts/ci/golden-commit-check.sh over the commits not yet on origin/dev or origin/main (skipped with neither).
# PRE_PUSH_TEST_CMD names the test command, run in the checkout (default: /bin/bash scripts/ci/script-tests.sh, or bash if there is no /bin/bash).
set -uo pipefail
root="$(git rev-parse --show-toplevel)" || { echo "pre-push: not in a git repo" >&2; exit 2; }
[ $# = 1 ] || { echo "usage: scripts/ci/pre-push.sh <sha>" >&2; exit 2; }
sha="$(git -C "$root" rev-parse --verify -q "$1^{commit}")" || { echo "pre-push: unknown commit '$1'" >&2; echo "usage: scripts/ci/pre-push.sh <sha>" >&2; exit 2; }
tree="$(git -C "$root" rev-parse "$sha^{tree}")"
# a push from a linked worktree exports GIT_DIR etc. for that worktree; the tests must act on the checkout's own repo
# shellcheck disable=SC2046
unset $(git rev-parse --local-env-vars)
state="$root/tmp/pre-push"
mkdir -p "$state"
# golden-update commits (spec 019 R14): the commits not yet on origin/dev or origin/main, with the script as in the pushed commit
base=""
for r in origin/dev origin/main; do
  b="$(git -C "$root" merge-base "$sha" "$r" 2>/dev/null)" || continue
  if [ -z "$base" ] || [ "$(git -C "$root" rev-list --count "$b..$sha")" -lt "$(git -C "$root" rev-list --count "$base..$sha")" ]; then base="$b"; fi
done
if [ -n "$base" ] && git -C "$root" cat-file -e "$sha:scripts/ci/golden-commit-check.sh" 2>/dev/null; then
  git -C "$root" show "$sha:scripts/ci/golden-commit-check.sh" > "$state/golden-$$.sh"
  rc=0; (cd "$root" && bash "$state/golden-$$.sh" "$base..$sha") || rc=$?
  rm -f "$state/golden-$$.sh"
  [ "$rc" = 0 ] || { echo "pre-push: FAILED golden-commit-check on ${sha:0:10}" >&2; exit "$rc"; }
fi
if grep -qx "$tree" "$state/passed" 2>/dev/null; then
  echo "pre-push: tree ${tree:0:10} of ${sha:0:10} already passed, skipping"; exit 0
fi
cmd="${PRE_PUSH_TEST_CMD:-}"
if [ -z "$cmd" ]; then
  cmd="bash scripts/ci/script-tests.sh"; [ -x /bin/bash ] && cmd="/bin/bash scripts/ci/script-tests.sh"
fi
wt="$state/wt-$$"
out="$state/out-$$"
cleanup() {
  git -C "$root" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"
  git -C "$root" worktree prune
  rm -f "$out"
}
trap cleanup EXIT
trap 'exit 130' INT TERM
echo "pre-push: testing ${sha:0:10} (script tests, about 90 s)"
git -C "$root" worktree add --detach -q "$wt" "$sha" || exit 1
(cd "$wt" && bash -c "$cmd") 2>&1 | tee "$out"
status=${PIPESTATUS[0]}
if [ "$status" = 0 ]; then
  echo "$tree" >> "$state/passed"
  exit 0
fi
echo "pre-push: FAILED on ${sha:0:10}" >&2
grep -E '^(FAIL|script-tests: FAILED)' "$out" >&2 || true
echo "pre-push: to push anyway, once: git push --no-verify" >&2
exit "$status"
