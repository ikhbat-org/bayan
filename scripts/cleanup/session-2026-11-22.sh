#!/bin/bash
# Cleanup for the 2026-11-22/23 unattended session (019 T59, mutate --files fix, heldout drafts).
# Written 2026-11-23 by the agent, never run by it. Dry run by default; --execute acts.
# Branch deletes need --delete-branches as well (git branch -d only, never -D).
set -euo pipefail

B=/Users/sy/Developer/ikhbat.org/bayan
H=/Users/sy/Developer/ikhbat.org/bayan-heldout
EXECUTE=0; BRANCHES=0
for a in "$@"; do
  case $a in
    --execute|-e) EXECUTE=1 ;;
    --delete-branches) BRANCHES=1 ;;
    *) echo "unknown flag: $a"; exit 64 ;;
  esac
done
failed=0

run() { if [ $EXECUTE = 1 ]; then "$@" || failed=1; else echo "would: $*"; fi; }

# 1. Scratch directories under bayan/tmp (refuse anything git tracks)
for rel in tmp/reexport.iYGZlb tmp/reexport.wLSpsx tmp/t59-six-export; do
  [ -e "$B/$rel" ] || { echo "gone: $rel"; continue; }
  if git -C "$B" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    echo "refuse: $rel is tracked by git. Left alone."; failed=1; continue
  fi
  run rm -rf "$B/$rel"
done

# 2. Merged bayan worktrees (git worktree remove refuses a dirty one; --force not used)
for wt in worker-d1-reexport-pairing fix-mutate-files-filter t59-close 019-mutate-fix mutate-parity handoff-headers; do
  [ -d "$B/.worktrees/$wt" ] || { echo "gone: .worktrees/$wt"; continue; }
  run git -C "$B" worktree remove "$B/.worktrees/$wt"
done

# 3. Heldout worker worktrees (only once their branches are merged by the owner)
for wt in worker-heldout-seeds worker-heldout-effects-fable worker-gdrafts-a worker-gdrafts-b; do
  [ -d "$H/.worktrees/$wt" ] || { echo "gone: heldout .worktrees/$wt"; continue; }
  run git -C "$H" worktree remove "$H/.worktrees/$wt"
done

# 4. Dispatcher scratch in the heldout checkout
rel=recheck.txt
if [ -e "$H/$rel" ]; then
  if git -C "$H" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    echo "refuse: heldout $rel is tracked. Left alone."; failed=1
  else
    run rm -f "$H/$rel"
  fi
fi

# 5. Branches (needs --delete-branches; -d refuses unmerged ones)
if [ $BRANCHES = 1 ]; then
  run git -C "$H" branch -d feat/api-drafts
  for br in fix/mutate-files-filter chore/019-t59-close fix/019-mutate-files fix/mutate-parity-baseline fix/handoff-headers docs/019-progress-1122; do
    run git -C "$B" branch -d "$br"
  done
else
  echo "skip: branch deletes (pass --delete-branches with --execute)"
fi

# 6. Remaining state
git -C "$B" worktree list | wc -l | xargs echo "bayan worktrees:"
git -C "$H" worktree list | wc -l | xargs echo "heldout worktrees:"
[ $failed = 0 ] || { echo "some steps refused or failed"; exit 1; }
