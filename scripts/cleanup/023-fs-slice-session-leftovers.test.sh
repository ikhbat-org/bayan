#!/usr/bin/env bash
# 023-fs-slice-session-leftovers on a fixture repo: a merged worktree goes with its branch, an unmerged and a dirty one
# stay, one holding ignored scratch waits for --delete-scratch, the worktree it runs from and one holding a nested
# worktree stay, a detached check-out in dev goes, a tracked scratch path is refused (exit 1), an untracked one goes only
# with --delete-scratch, tmp/sanitizer-debug is never a target; a worker key's worktree is removed before the key is
# retired, held for scratch, kept when off its branch; a key outside dev is kept; the dry run changes nothing.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
script="$root/scripts/cleanup/023-fs-slice-session-leftovers.sh"
r="$root/tmp/cleanup-023-test"
rm -rf "$r" && mkdir -p "$r/repo" && cd "$r/repo"
export GIT_ALLOW_PROTECTED=1  # fixture repo: its dev branch is the subject under test
g() { git -c user.email=t@t -c user.name=t "$@"; }
git init -q -b main && git config core.hooksPath /dev/null
printf 'tmp/\n.worktrees/\n' > .gitignore && mkdir -p tmp/sanitizer-debug && echo x > tmp/sanitizer-debug/a
git add .gitignore && g commit -q -m base && g branch dev
for b in fix/zig-pin-message fix/review-2026-11-08-4 fix/review-2026-11-08-3 docs/w0-d6-plan chore/017-t20-into-dev \
         chore/worker-q1100 chore/worker-json-i64 chore/worker-015-t7 chore/worker-w0-d6-plan chore/worker-q1100-x \
         chore/worker-review-tts-fix; do g branch "$b" dev; done
g switch -q fix/zig-pin-message && g commit -q --allow-empty -m z && g switch -q dev && g merge -q --no-ff fix/zig-pin-message -m mz
g switch -q fix/review-2026-11-08-4 && g commit -q --allow-empty -m u && g switch -q main
g switch -q chore/worker-015-t7 && g commit -q --allow-empty -m w && g switch -q main
g worktree add -q .worktrees/fix-zig-pin-message fix/zig-pin-message
g worktree add -q .worktrees/fix-review-2026-11-08-4 fix/review-2026-11-08-4
g worktree add -q .worktrees/fix-review-2026-11-08-3 fix/review-2026-11-08-3
g worktree add -q .worktrees/docs-w0-d6-plan docs/w0-d6-plan
g worktree add -q .worktrees/dev-merge dev
g worktree add -q .worktrees/017-into-dev chore/017-t20-into-dev
g worktree add -q --detach .worktrees/017-into-dev/.worktrees/nested dev
g worktree add -q --detach tmp/wt-acba dev
g worktree add -q .worktrees/worker-q1100 chore/worker-q1100
mkdir -p .worktrees/worker-q1100/tmp && echo x > .worktrees/worker-q1100/tmp/log
g worktree add -q --detach .worktrees/worker-json-i64 dev
g worktree add -q .worktrees/worker-w0-d6-plan chore/worker-w0-d6-plan
g worktree add -q .worktrees/worker-w0-d6-plan/.worktrees/x chore/worker-q1100-x
g worktree add -q .worktrees/worker-review-tts-fix chore/worker-review-tts-fix
mkdir -p "$r/logs"; sleep 600 >/dev/null 2>&1 </dev/null & live=$!; echo "$live" > "$r/logs/review-tts-fix.lock"
trap 'kill "$live" 2>/dev/null || true' EXIT
mkdir -p "$r/tmpdir/tmp.qhKsq0vwnC" && echo x > "$r/tmpdir/tmp.qhKsq0vwnC/f"
mkdir -p .worktrees/fix-review-2026-11-08-3/tmp && echo x > .worktrees/fix-review-2026-11-08-3/tmp/run.log
echo x > .worktrees/docs-w0-d6-plan/new.txt
mkdir -p tmp/zig-dl && echo x > tmp/zig-dl/z && git add -f tmp/zig-dl/z && g commit -q -m tracked-scratch
printf 'console.log("retired " + Deno.args.slice(1).join(" "));\n' > "$r/worker.js"
export CLEANUP_WORKER_JS="$r/worker.js" TMPDIR="$r/tmpdir" CLEANUP_WORKER_LOGS="$r/logs"
fail() { echo "FAIL: $1"; echo "$out"; cd "$root"; exit 1; }
has() { printf '%s\n' "$out" | grep -qF -- "$1" || fail "missing: $1"; }

out="$(bash "$script" 2>&1 || true)"; has 'refuse: run from a checkout of dev'
cd .worktrees/dev-merge
before="$(git -C "$r/repo" worktree list; git -C "$r/repo" branch)"
out="$(bash "$script" 2>&1)"
has 'would: git worktree remove .worktrees/fix-zig-pin-message'; has 'would: git branch -d fix/zig-pin-message'
has 'keep:  .worktrees/fix-review-2026-11-08-4 (fix/review-2026-11-08-4 not in dev)'
has 'keep:  .worktrees/docs-w0-d6-plan (modified or untracked files)'
has 'hold:  .worktrees/fix-review-2026-11-08-3'; has 'keep:  .worktrees/dev-merge (this script runs from it)'
has 'keep:  .worktrees/017-into-dev (holds a nested worktree)'; has 'refuse: tmp/zig-dl is tracked by git'
has 'would: git worktree remove tmp/wt-acba'
has "would (with --execute --delete-scratch): rm -rf $r/tmpdir/tmp.qhKsq0vwnC"
printf '%s\n' "$out" | grep -q 'sanitizer-debug' && fail 'tmp/sanitizer-debug is a target'
has 'hold:  q1100 (ignored files beyond build output in .worktrees/worker-q1100'
has 'keep:  json-i64 (.worktrees/worker-json-i64 not on chore/worker-json-i64)'
has 'keep:  015-t7 (chore/worker-015-t7 not in dev)'; has 'skip:  diag-examples'
has 'keep:  w0-d6-plan (.worktrees/worker-w0-d6-plan holds a nested worktree)'
has 'keep:  review-tts-fix (a worker holds its lock)'
[ "$before" = "$(git -C "$r/repo" worktree list; git -C "$r/repo" branch)" ] || fail 'dry run changed state'

st=0; out="$(bash "$script" --execute 2>&1)" || st=$?
[ $st -eq 1 ] || fail "--execute with a refused tracked path exited $st, not 1"
has 'removed: .worktrees/fix-zig-pin-message'; has 'removed: tmp/wt-acba'
printf '%s\n' "$out" | grep -q 'retired q1100' && fail 'q1100 retired while its worktree was held'
[ ! -d "$r/repo/.worktrees/fix-zig-pin-message" ] || fail 'merged worktree still there'
git -C "$r/repo" show-ref -q --verify refs/heads/fix/zig-pin-message && fail 'merged branch still there'
[ -d "$r/repo/.worktrees/fix-review-2026-11-08-3" ] || fail 'scratch worktree removed without --delete-scratch'
[ -d "$r/repo/tmp/sanitizer-debug" ] || fail 'scratch removed without --delete-scratch'
st=0; out="$(bash "$script" --execute --delete-scratch 2>&1)" || st=$?
[ $st -eq 1 ] || fail "second --execute exited $st, not 1"
has 'removed: .worktrees/fix-review-2026-11-08-3'; has "removed: $r/tmpdir/tmp.qhKsq0vwnC"; has 'retired q1100'
[ ! -d "$r/repo/.worktrees/worker-q1100" ] || fail 'worker worktree still there after retire'
git -C "$r/repo" show-ref -q --verify refs/heads/chore/worker-q1100 || fail 'worker branch deleted'
git -C "$r/repo" show-ref -q --verify refs/heads/fix/review-2026-11-08-3 && fail 'scratch worktree branch still there'
[ -d "$r/repo/tmp/sanitizer-debug" ] || fail 'tmp/sanitizer-debug deleted'
[ -d "$r/repo/.worktrees/017-into-dev" ] && [ -d "$r/repo/.worktrees/worker-json-i64" ] || fail 'kept worktree removed'
[ -d "$r/repo/.worktrees/worker-w0-d6-plan/.worktrees/x" ] && [ -d "$r/repo/.worktrees/worker-review-tts-fix" ] || fail 'nested or locked worker worktree removed'
[ -f "$r/repo/tmp/zig-dl/z" ] || fail 'tracked scratch deleted'
[ -d "$r/repo/.worktrees/fix-review-2026-11-08-4" ] && [ -d "$r/repo/.worktrees/docs-w0-d6-plan" ] || fail 'kept worktree removed'
cd "$root" && rm -rf "$r" && echo "023 cleanup: all checks pass"
