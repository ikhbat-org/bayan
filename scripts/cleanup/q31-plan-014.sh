#!/usr/bin/env bash
# Written 2026-11-14 by the session that landed plan 014 (Q31: region analyses in arenas, docs/plans/2026-11-14-014-region-analysis-arenas.md)
# and fix/cc-jobs-limit. Removes those branches' worktrees (their gitignored tmp/ scratch goes with them: tmp/q31 variants and ASan builds,
# tmp/shard), the measurement scratch tmp/q31-build in .worktrees/dev-land-2026-11-13 (that worktree holds dev and stays), and this
# session's directories in VM bayan-test01 (user bt): /home/bt/q31b, /home/bt/q31c and the plan 014 shard run.
# Branches are never deleted here.
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
for wt in fix-q31-build-arenas fix-cc-jobs-limit; do
  d="$main/.worktrees/$wt"
  if ! git worktree list --porcelain | grep -qxF "worktree $d"; then printf 'skip:  worktree %s not registered\n' "$wt"; continue; fi
  if [ ! -d "$d" ]; then printf 'skip:  worktree %s directory gone (pruned below)\n' "$wt"; continue; fi
  if ! st="$(git -C "$d" status --porcelain)" || ! head="$(git -C "$d" rev-parse HEAD)"; then printf 'refuse: git cannot read worktree %s. Left alone.\n' "$wt"; failed=1; continue; fi
  if [ -n "$st" ]; then printf 'refuse: %s has uncommitted changes. Left alone.\n' "$wt"; failed=1; continue; fi
  if ! git merge-base --is-ancestor "$head" dev; then printf 'refuse: %s HEAD %s is not in dev. Left alone.\n' "$wt" "${head:0:8}"; failed=1; continue; fi
  run git worktree remove "$d"   # no --force: ignored files (tmp/ scratch) do not block it; new changes still do
done
run git worktree prune

# 2. measurement scratch in the dev worktree (gitignored)
s="$main/.worktrees/dev-land-2026-11-13/tmp/q31-build"
if [ -d "$s" ]; then run rm -rf "$s"; else printf 'skip:  %s not there\n' "$s"; fi

# 3. VM bayan-test01 (user bt): plan 014 Linux measurements and its shard run (/home/bt/shard/<sha8>-<slot>). Other runs are not touched.
dirs="q31b q31c"
shas="d4e06ce7"
if [ $execute = 1 ] && [ $remote = 1 ]; then
  ssh ghosthive "
    was=\$(incus list bayan-test01 -c s -f csv)
    [ \"\$was\" = RUNNING ] || incus start bayan-test01
    rc=0; up=0
    for i in \$(seq 1 30); do timeout 10 incus exec bayan-test01 -- true 2>/dev/null && { up=1; break; }; sleep 2; done
    if [ \$up = 1 ]; then timeout 120 incus exec bayan-test01 -- sh -c 'cd /home/bt || exit 0
      for d in $dirs; do [ -e \"\$d\" ] && { echo rm -rf /home/bt/\$d; rm -rf \"\$d\"; }; done
      for s in $shas; do for d in shard/\$s-*; do [ -e \"\$d\" ] && { echo rm -rf /home/bt/\$d; rm -rf \"\$d\"; }; done; done
      for d in $dirs \$(for s in $shas; do echo shard/\$s-*; done); do [ -e \"\$d\" ] && { echo \"  still there: /home/bt/\$d\"; exit 1; }; done; exit 0' || { echo '  VM step failed'; rc=1; }
    else echo '  VM agent not ready after 60 s'; rc=1; fi
    [ \"\$was\" = RUNNING ] || incus stop bayan-test01 || rc=1
    exit \$rc" || failed=1
else
  printf 'would: in bayan-test01 remove /home/bt/{%s} and /home/bt/shard/{%s}* (needs --execute --remove-remote)\n' "${dirs// /,}" "${shas// /,}"
fi

printf -- '-- remaining worktrees:\n'; git worktree list | grep -E 'fix-q31-build-arenas|fix-cc-jobs-limit' || echo '  none'
if [ $execute = 1 ] && [ $failed = 1 ]; then exit 1; fi
