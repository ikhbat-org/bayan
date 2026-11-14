#!/usr/bin/env bash
# Cleanup for plan 015 (docs/plans/2026-11-14-015-q31-followups.md) and the 2026-11-14 CI work, written 2026-11-14.
#   1. worktrees .worktrees/q31-b, .worktrees/q31-d, .worktrees/ci-fixes, .worktrees/review-1114, .worktrees/review-1114-3 (git worktree remove;
#      refused when it has uncommitted changes; refused when it holds ignored files, e.g. tmp/ evidence such as
#      q31-d/tmp/q31-d/laws-d.out, unless --delete-scratch is given too, because git worktree remove deletes them);
#   2. the merged branches (git branch -d; git refuses an unmerged one). chore/q31-bt-{region,summary,frontend}-off are
#      kept: they are unmerged VM break-test branches the answered questions cite as evidence;
#   3. untracked scratch in the dev worktree: the duplicate plan copy, tmp/q31-015, tmp/cimem, tmp/review-1114 and only
#      this session's shard runs tmp/shard/<sha8> (021f6b6f 37315c1e 45fb6ba2 574db1db), never tmp/shard itself or its
#      class-times.tsv (needs --delete-scratch as well);
#   4. VM scratch on bayan-test01 as user bt: /home/bt/q31c and /home/bt/shard/<sha8>-* for the same shas, never other
#      runs or /home/bt/shard/cc-jobs (needs --delete-vm-scratch as well).
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0; scratch=0; vm=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-scratch) scratch=1 ;;
    --delete-vm-scratch) vm=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
main="$(git rev-parse --path-format=absolute --git-common-dir)"; main="${main%/.git}"
here="$(git rev-parse --show-toplevel)"
shas="021f6b6f 37315c1e 45fb6ba2 574db1db"
failed=0
run() { if [ "$execute" = 1 ]; then printf 'do:   %s\n' "$*"; "$@" || { printf '  failed. Left alone.\n'; failed=1; }; else printf 'would: %s\n' "$*"; fi; }

# 1. Worktrees.
for rel in .worktrees/q31-b .worktrees/q31-d .worktrees/ci-fixes .worktrees/review-1114 .worktrees/review-1114-3; do
  wt="$main/$rel"
  if [ "$here" = "$wt" ]; then printf 'refuse: run this from outside %s.\n' "$rel"; exit 1; fi
  if ! git worktree list --porcelain | grep -qx "worktree $wt"; then printf 'skip:  %s is not a worktree\n' "$rel"; continue; fi
  if [ -n "$(git -C "$wt" status --porcelain)" ]; then printf 'refuse: %s has uncommitted changes. Left alone.\n' "$rel"; failed=1; continue; fi
  ignored="$(git -C "$wt" status --porcelain --ignored | grep '^!!' | head -5 || true)"
  if [ -n "$ignored" ] && [ "$scratch" != 1 ]; then
    printf 'refuse (needs --delete-scratch): %s holds ignored files git worktree remove would delete:\n%s\n' "$rel" "$ignored"
    failed=1; continue
  fi
  run git worktree remove "$wt"
done
run git worktree prune

# 2. Merged branches.
for b in fix/q31-followups-small fix/q31-frontend-before-cc fix/q31-effects-arena fix/q31-l022-pin \
         fix/ci-dispatch-windows-cc-timeout chore/worker-rewrite-1114 fix/review-2026-11-14-2 fix/review-2026-11-14-3; do
  if ! git rev-parse --verify --quiet "refs/heads/$b" >/dev/null; then printf 'skip:  branch %s no longer exists\n' "$b"; continue; fi
  run git branch -d "$b"
done

# 3. Untracked scratch in the dev worktree.
devwt="$(git worktree list --porcelain | awk '/^worktree /{w=$2} /^branch refs\/heads\/dev$/{print w}')"
if [ -z "$devwt" ]; then
  printf 'skip:  no worktree has dev checked out\n'
else
  rels="docs/plans/2026-11-14-016-plan-the-q31-follow-ups-after-plan-014-frontend-freed-before.md tmp/q31-015 tmp/cimem tmp/review-1114"
  for s in $shas; do rels="$rels tmp/shard/$s"; done
  for rel in $rels; do
    if [ ! -e "$devwt/$rel" ]; then printf 'skip:  %s is gone\n' "$rel"; continue; fi
    if git -C "$devwt" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
      printf 'refuse: %s is tracked by git. Propose it as a commit instead. Left alone.\n' "$rel"; failed=1; continue
    fi
    if [ "$scratch" = 1 ]; then run rm -rf -- "$devwt/$rel"; else printf 'would (needs --delete-scratch): rm -rf %s\n' "$devwt/$rel"; fi
  done
fi

# 4. VM scratch (bayan-test01, user bt); skipped when the VM is not running.
vmpaths="/home/bt/q31c"
for s in $shas; do vmpaths="$vmpaths /home/bt/shard/$s-*"; done
if [ "$vm" = 1 ] && [ "$execute" = 1 ]; then
  if ssh ghosthive "incus list bayan-test01 -c s --format csv" 2>/dev/null | grep -qx RUNNING; then
    run ssh ghosthive "incus exec bayan-test01 -- runuser -u bt -- bash -c 'rm -rf -- $vmpaths'"
  else
    printf 'skip:  bayan-test01 is not running\n'
  fi
else
  printf 'would (needs --execute --delete-vm-scratch): on bayan-test01 rm -rf %s\n' "$vmpaths"
fi

printf '\nremaining:\n'
git worktree list | grep -E '/(q31-b|q31-d|ci-fixes|review-1114|review-1114-3) ' || printf '  none of these worktrees\n'
git branch --list 'fix/q31-*' 'chore/q31-bt-*' 'fix/ci-dispatch-windows-cc-timeout' 'chore/worker-rewrite-1114' 'fix/review-2026-11-14-2' 'fix/review-2026-11-14-3' || true
if [ "$execute" = 1 ] && [ "$failed" = 1 ]; then exit 1; fi
exit 0
