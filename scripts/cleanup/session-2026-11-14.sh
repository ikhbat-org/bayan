#!/usr/bin/env bash
# Written 2026-11-14 by the session that ran the 0.3.0 release preflight on bayan-test01, wp1 and mb1, fixed the
# goldens (chore/release-0.3.0) and the mutate cache race (fix/mutate-env-race), and merged both into dev.
# Removes that session's worktrees, merged branches, scratch under tmp/ and its shard dirs in VM bayan-test01 (user bt).
# test/release-0.3.0-preflight and test/release-0.3.0-preflight-2 are scratch merges never meant for dev: listed only.
# Every target is checked at run time: a tracked path is refused, a missing one is a skip, an unmerged branch is
# left to `git branch -d` to refuse.
# Dry run by default. --execute / -e acts. --remove-remote also removes the VM shard dirs of e9f5ef68.
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

# 1. scratch under tmp/ (before the worktrees that hold some of it go)
targets=(
  "$main/.worktrees/dev-land-2026-11-13|tmp/mb1-preflight2"
  "$main/.worktrees/dev-land-2026-11-13|tmp/preflight-vm.out"
  "$main/.worktrees/dev-land-2026-11-13|tmp/preflight2-vm.out"
  "$main/.worktrees/dev-land-2026-11-13|tmp/preflight2-wp1.out"
  "$main/.worktrees/dev-land-2026-11-13|tmp/ci-5ac81ec4.out"
  "$main/.worktrees/fix-mutate-env-race|tmp/laws.out"
  "$main/.worktrees/fix-mutate-env-race|tmp/ci85-win.log"
  "$main/.worktrees/fix-mutate-env-race|tmp/ci85-mac.log"
  "$main/.worktrees/fix-review-2026-11-14-2|tmp/laws.out"
  "$main/.worktrees/fix-review-2026-11-14-2|tmp/tut"
  "$main/.worktrees/fix-review-2026-11-14-2|tmp/tut2"
  "$main/.worktrees/fix-peak-sampler-first-sample|tmp/laws.out"
  "$main|tmp/review-1114.diff"
  "$main|tmp/rv1114.out"
)
for t in "${targets[@]}"; do
  repo="${t%%|*}"; rel="${t#*|}"
  if [ ! -e "$repo/$rel" ]; then printf 'skip:  %s/%s gone\n' "$repo" "$rel"; continue; fi
  if git -C "$repo" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    printf 'refuse: %s is tracked by git. Propose it as a commit instead. Left alone.\n' "$rel"; failed=1; continue
  fi
  run rm -rf "$repo/$rel"
done

# 2. worktrees, then their branches
for wt in fix-mutate-env-race chore-release-0.3.0 dev-check-8390c3d6 docs-session-2026-11-14 fix-review-2026-11-14-2 fix-peak-sampler-first-sample; do
  d="$main/.worktrees/$wt"
  if ! git worktree list --porcelain | grep -qxF "worktree $d"; then printf 'skip:  worktree %s not registered\n' "$wt"; continue; fi
  if [ ! -d "$d" ]; then printf 'skip:  worktree %s directory gone (pruned below)\n' "$wt"; continue; fi
  if [ -n "$(git -C "$d" status --porcelain)" ]; then printf 'refuse: %s has uncommitted changes. Left alone.\n' "$wt"; failed=1; continue; fi
  run git worktree remove "$d"
done
run git worktree prune
for b in fix/mutate-env-race chore/release-0.3.0 docs/session-2026-11-14 fix/review-2026-11-14-2 fix/peak-sampler-first-sample; do
  if ! git rev-parse --verify --quiet "refs/heads/$b" >/dev/null; then printf 'skip:  branch %s no longer exists\n' "$b"; continue; fi
  if git worktree list --porcelain | grep -qxF "branch refs/heads/$b"; then printf 'skip:  branch %s is checked out\n' "$b"; continue; fi
  run git branch -d "$b"
done
for b in test/release-0.3.0-preflight test/release-0.3.0-preflight-2; do
  git rev-parse --verify --quiet "refs/heads/$b" >/dev/null && printf 'left (scratch, check by hand): %s\n' "$b" || true
done

# 3. VM bayan-test01 (user bt): the shard dirs of this session's run, /home/bt/shard/<sha8>-<slot>.
shas="e9f5ef68"
if [ $execute = 1 ] && [ $remote = 1 ]; then
  ssh ghosthive "
    was=\$(incus list bayan-test01 -c s -f csv)
    [ \"\$was\" = RUNNING ] || incus start bayan-test01
    rc=0; up=0
    for i in \$(seq 1 30); do timeout 10 incus exec bayan-test01 -- true 2>/dev/null && { up=1; break; }; sleep 2; done
    [ \$up = 1 ] || { echo '  VM agent not ready after 60 s'; rc=1; }
    timeout 120 incus exec bayan-test01 -- sh -c 'cd /home/bt || exit 0
      for s in $shas; do for d in shard/\$s-*; do [ -e \"\$d\" ] && { echo rm -rf /home/bt/\$d; rm -rf \"\$d\"; }; done; done
      for s in $shas; do for d in shard/\$s-*; do [ -e \"\$d\" ] && { echo \"  still there: /home/bt/\$d\"; exit 1; }; done; done; exit 0' || { echo '  VM step failed'; rc=1; }
    [ \"\$was\" = RUNNING ] || incus stop bayan-test01 || rc=1
    exit \$rc" || failed=1
else
  printf 'would: in bayan-test01 remove /home/bt/shard/{%s}-* (needs --execute --remove-remote)\n' "${shas// /,}"
fi

printf -- '-- remaining worktrees:\n'
git worktree list | grep -E "fix-mutate-env-race|chore-release-0.3.0|dev-check-8390c3d6|docs-session-2026-11-14|fix-review-2026-11-14-2|fix-peak-sampler-first-sample" || echo '  none'
if [ $execute = 1 ] && [ $failed = 1 ]; then exit 1; fi
