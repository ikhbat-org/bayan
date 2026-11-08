#!/usr/bin/env bash
# 023-fs-slice-session-leftovers on a fixture repo: a merged worktree goes with its branch, an unmerged and a dirty one
# stay, one holding ignored scratch waits for --delete-scratch, the worktree it runs from stays, a tracked scratch path is
# refused, an untracked one goes only with --delete-scratch, a worker key in dev is retired and one outside dev is not,
# and the dry run changes nothing.
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
for b in fix/zig-pin-message fix/review-2026-11-08-4 fix/review-2026-11-08-3 docs/w0-d6-plan chore/worker-q1100 chore/worker-015-t7; do g branch "$b" dev; done
g switch -q fix/zig-pin-message && g commit -q --allow-empty -m z && g switch -q dev && g merge -q --no-ff fix/zig-pin-message -m mz
g switch -q fix/review-2026-11-08-4 && g commit -q --allow-empty -m u && g switch -q main
g switch -q chore/worker-015-t7 && g commit -q --allow-empty -m w && g switch -q main
g worktree add -q .worktrees/fix-zig-pin-message fix/zig-pin-message
g worktree add -q .worktrees/fix-review-2026-11-08-4 fix/review-2026-11-08-4
g worktree add -q .worktrees/fix-review-2026-11-08-3 fix/review-2026-11-08-3
g worktree add -q .worktrees/docs-w0-d6-plan docs/w0-d6-plan
g worktree add -q .worktrees/dev-merge dev
mkdir -p .worktrees/fix-review-2026-11-08-3/tmp && echo x > .worktrees/fix-review-2026-11-08-3/tmp/run.log
echo x > .worktrees/docs-w0-d6-plan/new.txt
mkdir -p tmp/zig-dl && echo x > tmp/zig-dl/z && git add -f tmp/zig-dl/z && g commit -q -m tracked-scratch
printf 'console.log("retired " + Deno.args.slice(1).join(" "));\n' > "$r/worker.js"
export CLEANUP_WORKER_JS="$r/worker.js" TMPDIR="$r/nowhere"
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
has 'skip:  .worktrees/017-into-dev is gone'; has 'refuse: tmp/zig-dl is tracked by git'
has 'would (with --execute --delete-scratch): rm -rf tmp/sanitizer-debug'
has 'would: worker.js retire q1100'; has 'keep:  015-t7 (chore/worker-015-t7 not in dev)'; has 'skip:  diag-examples'
[ "$before" = "$(git -C "$r/repo" worktree list; git -C "$r/repo" branch)" ] || fail 'dry run changed state'

out="$(bash "$script" --execute 2>&1)"
has 'removed: .worktrees/fix-zig-pin-message'; has 'retired q1100'
[ ! -d "$r/repo/.worktrees/fix-zig-pin-message" ] || fail 'merged worktree still there'
git -C "$r/repo" show-ref -q --verify refs/heads/fix/zig-pin-message && fail 'merged branch still there'
[ -d "$r/repo/.worktrees/fix-review-2026-11-08-3" ] || fail 'scratch worktree removed without --delete-scratch'
[ -d "$r/repo/tmp/sanitizer-debug" ] || fail 'scratch removed without --delete-scratch'
out="$(bash "$script" --execute --delete-scratch 2>&1)"
has 'removed: .worktrees/fix-review-2026-11-08-3'; has 'removed: tmp/sanitizer-debug'
[ -f "$r/repo/tmp/zig-dl/z" ] || fail 'tracked scratch deleted'
[ -d "$r/repo/.worktrees/fix-review-2026-11-08-4" ] && [ -d "$r/repo/.worktrees/docs-w0-d6-plan" ] || fail 'kept worktree removed'
cd "$root" && rm -rf "$r" && echo "023 cleanup: all checks pass"
