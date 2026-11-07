#!/usr/bin/env bash
# Cleanup for the later unattended session of 2026-11-07 (see unattended-2026-11-07.sh for the earlier one; spec 017 T5-T8 landings, round-4 review fixes,
# security plan revision). Written 2026-11-07, never run by the agent.
# 1. worktrees left by that work (git worktree remove; refuses dirty trees)
# 2. untracked scratch under the repo's tmp/ dirs        (needs --delete-scratch)
# 3. scratch under /tmp from early probes                (needs --delete-scratch)
# Branches are left to merged-worktree-backlog.sh / git branch -d by hand.
# wp1 clones (C:/home/code/extrode.com/bayan/tmp/<sha>) are remote: see 021-ci-q747-scratch.sh.
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0; scratch=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-scratch) scratch=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
main="$(git rev-parse --path-format=absolute --git-common-dir)"; main="${main%/.git}"
cd "$main"
if ! git rev-parse --verify --quiet refs/heads/dev >/dev/null; then printf 'refuse: no dev branch here.\n'; exit 1; fi
failed=0

printf '== 1. worktrees\n'
for w in worker-r4-fix worker-r4-fix2 worker-fix-r4-dev worker-sec-plan-rev1 docs-sec-plan-rev1 \
         fix-review-2026-11-07-6 fix-review-2026-11-07-7 chore-cleanup-unattended-2026-11-07 chore-cleanup-2026-11-07-late; do
  wt=".worktrees/$w"
  if [ ! -d "$wt" ]; then printf 'skip:  %s is gone\n' "$wt"; continue; fi
  br="$(git -C "$wt" branch --show-current 2>/dev/null || true)"
  if [ -n "$br" ] && ! git merge-base --is-ancestor "refs/heads/$br" refs/heads/dev 2>/dev/null; then
    printf 'keep:  %s (%s not in dev)\n' "$wt" "$br"; continue
  fi
  if [ -n "$(git -C "$wt" status --porcelain)" ]; then printf 'keep:  %s (modified or untracked files)\n' "$wt"; continue; fi
  if [ $execute -eq 0 ]; then printf 'would: git worktree remove %s\n' "$wt"; continue; fi
  git worktree remove "$wt" || { printf '  refused: %s. Left alone.\n' "$wt"; failed=1; }
done
[ $execute -eq 1 ] && git worktree prune

printf '== 2. repo tmp/ scratch\n'
rm_untracked() {  # rm_untracked GITDIR REL
  local g="$1" rel="$2"
  if [ ! -e "$g/$rel" ]; then printf 'skip:  %s/%s is gone\n' "$g" "$rel"; return; fi
  if git -C "$g" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    printf 'refuse: %s/%s is tracked by git. Left alone.\n' "$g" "$rel"; failed=1; return
  fi
  if [ $execute -eq 0 ] || [ $scratch -eq 0 ]; then printf 'would: rm -rf %s/%s (needs -e --delete-scratch)\n' "$g" "$rel"; return; fi
  rm -rf -- "${g:?}/$rel"
}
for rel in tmp/review-t6 tmp/review-t9 tmp/probe-r4 tmp/probe-r4m tmp/review-t2 tmp/review-r4-dev tmp/review-t8 tmp/review-t8-test.log; do
  rm_untracked "$main" "$rel"
done
f017="$main/.worktrees/feat-017-selfhost-default"
[ -d "$f017" ] && rm_untracked "$f017" tmp/017-t2/prompt.md.bak
t7="$main/.worktrees/worker-017-t7"
[ -d "$t7" ] && rm_untracked "$t7" tmp/t8

printf '== 3. /tmp scratch\n'
for p in /tmp/rv006 /tmp/t2g /tmp/sdt.bak; do
  if [ ! -e "$p" ]; then printf 'skip:  %s is gone\n' "$p"; continue; fi
  if [ $execute -eq 0 ] || [ $scratch -eq 0 ]; then printf 'would: rm -rf %s (needs -e --delete-scratch)\n' "$p"; continue; fi
  rm -rf -- "$p"
done

printf '== remaining\n'
git worktree list | wc -l | xargs printf '%s worktrees registered\n'
if [ $execute -eq 1 ] && [ $failed -eq 1 ]; then exit 1; fi
exit 0
