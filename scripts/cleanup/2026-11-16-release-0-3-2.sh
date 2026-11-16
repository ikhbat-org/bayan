#!/bin/bash
# Cleanup for the 2026-11-16 session that merged the 0.3.2 work into dev and cut 0.3.2.
# Written 2026-11-16. Never run by an agent.
#
#   scripts/cleanup/2026-11-16-release-0-3-2.sh                         dry run, changes nothing
#   scripts/cleanup/2026-11-16-release-0-3-2.sh -e                      remove clean worktrees, `git branch -d` merged branches
#   ... -e --delete-build-output   first delete ignored files (bin/, obj/, tmp/) inside those worktrees,
#                                  so `git worktree remove` accepts them
#   ... -e --delete-scratch        delete this session's scratch in tmp/ and the stale .cache/bayan/.build-* dirs
#   ... -e --delete-vm-scratch     delete /home/bt/ci-ce337d7b and /opt/dotnet-10.0.302 on the VM bayan-test01
#
# Run it from a checkout on dev, after chore/release-0.3.2 is merged into dev. A worktree still holding uncommitted
# edits, and a branch dev does not contain, are refused and left alone.
# sabk-spec (docs/024-sabk-spec) and site-redesign (feat/site-redesign) are not listed: both hold unmerged work.
set -euo pipefail

execute=0; delete_build=0; delete_scratch=0; delete_vm=0
for arg in "$@"; do
    case "$arg" in
        -e|--execute) execute=1 ;;
        --delete-build-output) delete_build=1 ;;
        --delete-scratch) delete_scratch=1 ;;
        --delete-vm-scratch) delete_vm=1 ;;
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

# worktree directory under .worktrees/ -> its branch
pairs="concepts:docs/additional-concepts ci-pre-push:chore/ci-pre-push ci-readme-dist:fix/ci-readme-dist-version
cleanup-all:chore/cleanup-all decisions-1116:docs/2026-11-16-decisions docs-032:docs/0.3.2-cleanup
feat/site-pages:feat/site-pages format-dev-sources:fix/format-dev-sources next-dev-0.3.2:chore/next-dev-0.3.2
proposal-docs-layout:docs/proposal-docs-layout readme-v3:docs/readme-v3 release-0.3.2:chore/release-0.3.2
release-docs-fix:docs/release-0.3.2-docs-fix review-2026-11-16-3:fix/review-2026-11-16-3
review-2026-11-16-4:fix/review-2026-11-16-4 site-0.3.2:docs/site-0.3.2 spec-catch-up:docs/023-spec-catch-up
worker-ci-pre-push:chore/worker-ci-pre-push worker-ci-readme-dist:chore/worker-ci-readme-dist
worker-readme-v3:chore/worker-readme-v3 worker-review-prepush-gitdir:chore/worker-review-prepush-gitdir
worker-s022-rfix:chore/worker-s022-rfix worker-site-a:chore/worker-site-a worker-site-docs:chore/worker-site-docs
worker-site-mockups:chore/worker-site-mockups dev-merge:"
# branches whose worktree is already gone (writers landed this session)
extra_branches="chore/worker-cleanup-all chore/worker-manifesto-site chore/worker-site-redesign chore/worker-site-docs2
chore/worker-roadmap-check chore/worker-docs-fix-032 chore/worker-spec-catch-up"

echo "== 1. ignored build output inside the worktrees"
for p in $pairs; do
    dir="$common/.worktrees/${p%%:*}"
    if [ ! -d "$dir" ]; then printf 'skip:  %s is gone\n' "${p%%:*}"; continue; fi
    n=$(git -C "$dir" ls-files --others --ignored --exclude-standard --directory | wc -l | tr -d ' ')
    if [ "$n" -eq 0 ]; then printf 'skip:  %s has no ignored files\n' "${p%%:*}"; continue; fi
    if [ "$delete_build" -eq 1 ]; then
        run git -C "$dir" clean -fdX
    else
        printf 'keep:  %s holds %s ignored paths; pass --delete-build-output to delete them\n' "${p%%:*}" "$n"
    fi
done

echo "== 2. worktrees (git worktree remove refuses a dirty tree; that refusal is kept)"
for p in $pairs; do
    dir="$common/.worktrees/${p%%:*}"
    if [ ! -d "$dir" ]; then printf 'skip:  %s is gone\n' "${p%%:*}"; continue; fi
    if [ "$(git -C "$dir" branch --show-current)" = "dev" ]; then
        printf 'keep:  %s has dev checked out; switch it away first (git -C %s switch --detach)\n' "${p%%:*}" "$dir"
        continue
    fi
    run git -C "$common" worktree remove "$dir"
done
run git -C "$common" worktree prune

echo "== 3. branches (git branch -d refuses one dev does not contain)"
for b in $(for p in $pairs; do printf '%s\n' "${p#*:}"; done) $extra_branches; do
    [ -n "$b" ] || continue
    if ! git -C "$repo" rev-parse --verify --quiet "refs/heads/$b" >/dev/null; then
        printf 'skip:  branch %s no longer exists\n' "$b"; continue
    fi
    run git -C "$repo" branch -d "$b"
done

echo "== 4. scratch in tmp/ and stale compiler build dirs"
scratch="tmp/cleanup-all-ignored tmp/cleanup-all-criteria.md tmp/cleanup-all-gate.out tmp/manifesto-site-criteria.md
tmp/manifesto-site-gate2.out tmp/devcheck"
for f in $scratch; do
    path="$common/$f"
    if [ ! -e "$path" ]; then printf 'skip:  %s is gone\n' "$f"; continue; fi
    if [ "$delete_scratch" -eq 1 ]; then run rm -rf "$path"; else printf 'keep:  %s; pass --delete-scratch\n' "$f"; fi
done
# .build-<sha>-<pid>: stale once that pid has exited; a live one belongs to a build running now
for d in "$common"/.cache/bayan/.build-*; do
    [ -e "$d" ] || { echo "skip:  no .cache/bayan/.build-* dirs"; break; }
    pid="${d##*-}"
    case "$pid" in ''|*[!0-9]*) printf 'keep:  %s; no pid in its name\n' "${d#$common/}"; continue ;; esac
    if ps -p "$pid" >/dev/null 2>&1; then printf 'keep:  %s; process %s is running\n' "${d#$common/}" "$pid"; continue; fi
    if [ "$delete_scratch" -eq 1 ]; then run rm -rf "$d"; else printf 'keep:  %s; pass --delete-scratch\n' "${d#$common/}"; fi
done

echo "== 5. VM bayan-test01 (through ghosthive)"
if [ "$delete_vm" -eq 1 ]; then
    run ssh -o ConnectTimeout=15 ghosthive 'incus exec bayan-test01 -- rm -rf /home/bt/ci-ce337d7b /opt/dotnet-10.0.302'
else
    printf 'keep:  /home/bt/ci-ce337d7b and /opt/dotnet-10.0.302 on bayan-test01; pass --delete-vm-scratch\n'
fi

echo "== remaining"
git -C "$common" worktree list | grep -E 'release-0\.3\.2|site-0\.3\.2|dev-merge|cleanup-all' || echo "no 0.3.2 worktrees left"

if [ "$execute" -eq 1 ] && [ "$failed" -eq 1 ]; then exit 1; fi
exit 0
