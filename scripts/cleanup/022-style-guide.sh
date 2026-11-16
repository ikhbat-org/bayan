#!/bin/bash
# Cleanup for spec 022 (style guide) and the 2026-11-16 README examples work.
# Written 2026-11-16 by the session that ran 022 T7b-T11. Never run by an agent.
#
#   scripts/cleanup/022-style-guide.sh                          dry run, changes nothing
#   scripts/cleanup/022-style-guide.sh -e                       remove clean worktrees, delete merged branches
#   scripts/cleanup/022-style-guide.sh -e --delete-build-output also delete ignored build output
#                                                               (bin/, obj/, tmp/) inside the worker
#                                                               worktrees first, so `git worktree remove`
#                                                               accepts them
#   scripts/cleanup/022-style-guide.sh -e --delete-scratch      also delete the scratch in /tmp and in tmp/ (steps 4, 5)
#
# Run it from a checkout of this repo that is on `dev`, after 022 is merged into dev:
# `git branch -d` checks merged-ness against the current branch.
set -euo pipefail

execute=0
delete_build=0
delete_scratch=0
for arg in "$@"; do
    case "$arg" in
        -e|--execute) execute=1 ;;
        --delete-build-output) delete_build=1 ;;
        --delete-scratch) delete_scratch=1 ;;
        *) printf 'unknown argument: %s\n' "$arg"; exit 2 ;;
    esac
done

repo=$(git rev-parse --show-toplevel)
common=$(cd "$repo" && cd "$(git rev-parse --git-common-dir)/.." && pwd)
failed=0

run() {
    if [ "$execute" -eq 1 ]; then
        printf 'run:   %s\n' "$*"
        "$@" || { printf '  refused (exit %s). Left alone.\n' "$?"; failed=1; }
    else
        printf 'would: %s\n' "$*"
    fi
}

branch=$(git -C "$repo" branch --show-current)
if [ "$branch" != "dev" ]; then
    printf 'refuse: run this from a checkout on dev (this one is on %s).\n' "${branch:-detached HEAD}"
    [ "$execute" -eq 1 ] && exit 1
    printf '        dry run continues so you can see the list.\n'
fi

worktrees="worker-s022-t7b worker-s022-t8b worker-s022-t9 worker-s022-t10 worker-s022-t11 readme-examples worker-readme-v2 readme-v2 fix-review-2026-11-16-2"
branches="docs/readme-examples docs/readme-v2 chore/worker-readme-v2 fix/review-2026-11-16-1 fix/review-2026-11-16-2"
for t in 1 2 3 4 5 6 6b 6c 7 7b 8 8b 9 10 11; do branches="$branches chore/worker-s022-t$t"; done

echo "== 1. ignored build output inside the worktrees"
for w in $worktrees; do
    dir="$common/.worktrees/$w"
    if [ ! -d "$dir" ]; then printf 'skip:  %s is gone\n' "$w"; continue; fi
    n=$(git -C "$dir" ls-files --others --ignored --exclude-standard --directory | wc -l | tr -d ' ')
    if [ "$n" -eq 0 ]; then printf 'skip:  %s has no ignored files\n' "$w"; continue; fi
    if [ "$delete_build" -eq 1 ]; then
        run git -C "$dir" clean -fdX
    else
        printf 'keep:  %s holds %s ignored paths; pass --delete-build-output to delete them\n' "$w" "$n"
    fi
done

echo "== 2. worktrees (git worktree remove refuses a dirty tree; that refusal is kept)"
for w in $worktrees; do
    dir="$common/.worktrees/$w"
    if [ ! -d "$dir" ]; then printf 'skip:  %s is gone\n' "$w"; continue; fi
    run git -C "$common" worktree remove "$dir"
done
run git -C "$common" worktree prune

echo "== 3. branches (git branch -d refuses an unmerged one)"
for b in $branches; do
    if ! git -C "$repo" rev-parse --verify --quiet "refs/heads/$b" >/dev/null; then
        printf 'skip:  branch %s no longer exists\n' "$b"
        continue
    fi
    run git -C "$repo" branch -d "$b"
done

echo "== 4. stray scratch outside the repo"
scratch() { # path: delete it only with --delete-scratch
    if [ ! -e "$1" ]; then printf "skip:  %s is gone\n" "$1"
    elif [ "$delete_scratch" -eq 1 ]; then run rm -rf "$1"
    else printf "keep:  %s; pass --delete-scratch\n" "$1"; fi
}
for f in /tmp/x /tmp/t8b-gate.log /tmp/gate-sm2; do scratch "$f"; done

echo "== 5. scratch in the repo's tmp/ (ignored files moved out of writer worktrees before land)"
for d in manifesto-site-ignored sabk-verify; do scratch "$common/tmp/$d"; done

echo "== remaining"
git -C "$common" worktree list | grep -E 'worker-s022|readme-examples' || echo "no 022 or README worktrees left"
git -C "$repo" branch --list 'chore/worker-s022-*' docs/readme-examples docs/readme-v2 chore/worker-readme-v2 fix/review-2026-11-16-1

if [ "$execute" -eq 1 ] && [ "$failed" -eq 1 ]; then exit 1; fi
exit 0
