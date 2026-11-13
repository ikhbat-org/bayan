#!/usr/bin/env bash
# Written 2026-11-14 by the session that landed plans 012 and 013 (Q31 arenas: mutate re-binds, region summaries, cache reads)
# and fix/t10-harness-batches. Removes those branches' worktrees (their gitignored tmp/ scratch goes with them: tmp/asan,
# tmp/q31, shard logs) and this session's directories in VM bayan-test01 (user bt).
# Branches are never deleted here, and neither is probe/mutate-peak-linux (keep it). .worktrees/dev-land-2026-11-13 holds dev
# and is where this script runs, so it stays.
# Every target is checked at run time: a worktree with uncommitted changes is refused, a missing one is a skip.
# Dry run by default. --execute / -e acts. --remove-remote also removes the named VM directories.
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

# 1. worktrees of merged branches (the branch must be merged into dev; the branch itself stays)
for wt in fix-mutate-arena-per-rebind fix-t10-harness-batches fix-q31-region-cache-arenas; do
  d="$main/.worktrees/$wt"
  if ! git worktree list --porcelain | grep -qxF "worktree $d"; then printf 'skip:  worktree %s not registered\n' "$wt"; continue; fi
  if [ ! -d "$d" ]; then printf 'skip:  worktree %s directory gone (pruned below)\n' "$wt"; continue; fi
  if ! st="$(git -C "$d" status --porcelain)" || ! head="$(git -C "$d" rev-parse HEAD)"; then printf 'refuse: git cannot read worktree %s. Left alone.\n' "$wt"; failed=1; continue; fi
  if [ -n "$st" ]; then printf 'refuse: %s has uncommitted changes. Left alone.\n' "$wt"; failed=1; continue; fi
  if ! git merge-base --is-ancestor "$head" dev; then printf 'refuse: %s HEAD %s is not in dev. Left alone.\n' "$wt" "${head:0:8}"; failed=1; continue; fi
  run git worktree remove "$d"   # no --force: ignored files (tmp/ scratch) do not block it; new changes still do
done
run git worktree prune

# 2. VM bayan-test01 (user bt): /home/bt/q31 (plan 013 measurements) and this session's shard runs
#    (/home/bt/shard/<sha8>-<slot>, scripts/selfhost/shard-test.sh; bf340707 is the fix/cc-jobs-limit proof run; /home/bt/shard/cc-jobs stays,
#    later runs share it). Other sessions' runs are not touched.
shas="b5b5705d db4f3ca8 bf340707"
if [ $execute = 1 ] && [ $remote = 1 ]; then
  ssh ghosthive "
    was=\$(incus list bayan-test01 -c s -f csv)
    [ \"\$was\" = RUNNING ] || incus start bayan-test01
    rc=0; up=0
    for i in \$(seq 1 30); do timeout 10 incus exec bayan-test01 -- true 2>/dev/null && { up=1; break; }; sleep 2; done
    if [ \$up = 1 ]; then timeout 120 incus exec bayan-test01 -- sh -c 'cd /home/bt || exit 0
      [ -e q31 ] && { echo rm -rf /home/bt/q31; rm -rf q31; }
      for s in $shas; do for d in shard/\$s-*; do [ -e \"\$d\" ] && { echo rm -rf /home/bt/\$d; rm -rf \"\$d\"; }; done; done
      for d in q31 \$(for s in $shas; do echo shard/\$s-*; done); do [ -e \"\$d\" ] && { echo \"  still there: /home/bt/\$d\"; exit 1; }; done; exit 0' || { echo '  VM step failed'; rc=1; }
    else echo '  VM agent not ready after 60 s'; rc=1; fi
    [ \"\$was\" = RUNNING ] || incus stop bayan-test01 || rc=1
    exit \$rc" || failed=1
else
  printf 'would: in bayan-test01 remove /home/bt/q31 and /home/bt/shard/{%s}* (needs --execute --remove-remote)\n' "${shas// /,}"
fi

printf -- '-- remaining worktrees:\n'; git worktree list | grep -E 'fix-mutate-arena-per-rebind|fix-t10-harness-batches|fix-q31-region-cache-arenas' || echo '  none'
if [ $execute = 1 ] && [ $failed = 1 ]; then exit 1; fi
