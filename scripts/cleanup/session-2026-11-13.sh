#!/usr/bin/env bash
# Written 2026-11-13 by the session that landed plans 009 and 011, closed plan 010 and ran the session review
# (fix/review-2026-11-13-1). Removes that session's worker worktrees and branches, its scratch files under tmp/,
# its directories in VM bayan-test01 (user bt) and its git bundles on ghosthive.
# Every target is checked at run time: a tracked path is refused, a missing one is a skip, an unmerged branch is
# left to `git branch -d` to refuse.
# Dry run by default. --execute / -e acts. --remove-remote also removes the VM directories and ghosthive bundles.
set -euo pipefail

execute=0; remote=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --remove-remote) remote=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
main="$(git rev-parse --path-format=absolute --git-common-dir)"; main="${main%/.git}"
if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from a checkout on dev (here: %s).\n' "$(git branch --show-current)"; exit 1
fi
failed=0
run() { if [ $execute = 1 ]; then printf 'run:   %s\n' "$*"; "$@" || { printf '  failed\n'; failed=1; }; else printf 'would: %s\n' "$*"; fi; }

# 1. worker and feature worktrees, then their branches
for wt in worker-p009 worker-p009-fix worker-p011 worker-rv1113 feat-011-os-random; do
  d="$main/.worktrees/$wt"
  if ! git worktree list --porcelain | grep -qxF "worktree $d"; then printf 'skip:  worktree %s not registered\n' "$wt"; continue; fi
  if [ -n "$(git -C "$d" status --porcelain)" ]; then printf 'refuse: %s has uncommitted changes. Left alone.\n' "$wt"; failed=1; continue; fi
  run git worktree remove "$d"
done
for b in chore/worker-p009 chore/worker-p009-fix chore/worker-p011 chore/worker-rv1113 feat/011-os-random-builtin \
         feat/009-prebuilt-runtime-object fix/review-2026-11-13-1 docs/session-2026-11-13-close; do
  if ! git rev-parse --verify --quiet "refs/heads/$b" >/dev/null; then printf 'skip:  branch %s no longer exists\n' "$b"; continue; fi
  if git worktree list --porcelain | grep -qxF "branch refs/heads/$b"; then printf 'skip:  branch %s is checked out\n' "$b"; continue; fi
  run git branch -d "$b"
done

# 2. scratch under tmp/ in the checkouts that hold it
targets=(
  "$main/.worktrees/dev-merge|tmp/p009-shard.log" "$main/.worktrees/dev-merge|tmp/p009-vm2.log"
  "$main/.worktrees/dev-merge|tmp/p009-fix.out" "$main/.worktrees/dev-merge|tmp/rv1113-shard.log"
  "$main/.worktrees/dev-merge|tmp/rv1113-vm2.log" "$main/.worktrees/dev-merge|tmp/rv1113-vm2-classes.txt"
  "$main/.worktrees/dev-merge/.worktrees/docs-roadmap-2026-11-13|tmp/review-1113-criteria.md"
  "$main/.worktrees/dev-merge/.worktrees/docs-roadmap-2026-11-13|tmp/rv1113.out"
  "$main/.worktrees/dev-merge/.worktrees/docs-roadmap-2026-11-13|tmp/rv1113-gate.out"
  "$main/.worktrees/dev-merge/.worktrees/docs-roadmap-2026-11-13|tmp/rv1113-rr.out"
  "$main/.worktrees/dev-merge/.worktrees/docs-roadmap-2026-11-13|tmp/rv1113-laws.out"
  "$main/.worktrees/dev-merge/.worktrees/docs-roadmap-2026-11-13|tmp/session-review.out"
  "$main/.worktrees/dev-merge/.worktrees/docs-roadmap-2026-11-13|tmp/session-review-prompt.md"
)
for t in "${targets[@]}"; do
  repo="${t%%|*}"; rel="${t#*|}"
  if [ ! -e "$repo/$rel" ]; then printf 'skip:  %s/%s gone\n' "$repo" "$rel"; continue; fi
  if git -C "$repo" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    printf 'refuse: %s is tracked by git. Propose it as a commit instead. Left alone.\n' "$rel"; failed=1; continue
  fi
  run rm -rf "$repo/$rel"
done

# 3. VM bayan-test01 (user bt) and ghosthive bundles: listed always, removed only with --execute --remove-remote
printf -- '-- VM directories (o0, f2*, shard) and ghosthive /root/*.bundle:\n'
ssh ghosthive 'ls -d /root/*.bundle 2>/dev/null || echo "  no bundles"' || failed=1
if [ $execute = 1 ] && [ $remote = 1 ]; then
  ssh ghosthive 'set -e; incus start bayan-test01 2>/dev/null || true; sleep 5
    timeout 120 incus exec bayan-test01 -- sh -c "cd /home/bt && ls -d o0 f2* shard 2>/dev/null | while read d; do echo rm -rf /home/bt/\$d; rm -rf \"/home/bt/\$d\"; done"
    incus stop bayan-test01
    for f in /root/*.bundle; do [ -e "$f" ] && { echo rm -f "$f"; rm -f "$f"; }; done; true' || failed=1
else
  printf 'would: start bayan-test01, rm -rf /home/bt/{o0,f2*,shard}, stop it, rm /root/*.bundle (needs --execute --remove-remote)\n'
fi

printf -- '-- remaining worktrees:\n'; git worktree list | grep -E 'worker-p009|worker-p011|worker-rv1113|feat-011-os-random' || echo '  none'
if [ $execute = 1 ] && [ $failed = 1 ]; then exit 1; fi
