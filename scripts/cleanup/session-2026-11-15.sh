#!/usr/bin/env bash
# Written 2026-11-15 by the unattended session that watched ci after the v0.3.0 tag, fixed the macOS timer-parity flake
# (fix/ci-timer-frame-count), opened 0.3.1-dev (chore/next-dev-0-3-1) and built plan 016 (feat/016-versioned-docs, writers
# 016-w1..w3), all merged into dev.
# Removes that session's worktrees (the three writer worktrees and .worktrees/main-release), its merged branches, and its
# scratch in VM bayan-test01 (user bt): ~/016-docs, ~/016-docs.tgz, ~/pk.log and the shard dirs of 0bc1b102.
# Every target is checked at run time: a dirty worktree is refused, a missing one is a skip, an unmerged branch is left to
# `git branch -d` to refuse.
# Dry run by default. --execute / -e acts. --remove-remote also removes the VM files.
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

# 1. worktrees (writer worktrees hold only ignored build output besides their committed branch)
wts="worker-016-w1 worker-016-w2 worker-016-w3 main-release"
for wt in $wts; do
  d="$main/.worktrees/$wt"
  if ! git worktree list --porcelain | grep -qxF "worktree $d"; then printf 'skip:  worktree %s not registered\n' "$wt"; continue; fi
  if [ ! -d "$d" ]; then printf 'skip:  worktree %s directory gone (pruned below)\n' "$wt"; continue; fi
  if [ -n "$(git -C "$d" status --porcelain)" ]; then printf 'refuse: %s has uncommitted changes. Left alone.\n' "$wt"; failed=1; continue; fi
  run git worktree remove "$d"
done
run git worktree prune

# 2. branches merged into dev (a dry run skips the writer branches as checked out; --execute removes their worktrees first)
for b in chore/worker-016-w1 chore/worker-016-w2 chore/worker-016-w3 feat/016-versioned-docs fix/ci-timer-frame-count chore/next-dev-0-3-1; do
  if ! git rev-parse --verify --quiet "refs/heads/$b" >/dev/null; then printf 'skip:  branch %s no longer exists\n' "$b"; continue; fi
  if git worktree list --porcelain | grep -qxF "branch refs/heads/$b"; then printf 'skip:  branch %s is checked out\n' "$b"; continue; fi
  run git branch -d "$b"
done

# 3. VM bayan-test01 (user bt)
shas="0bc1b102"
if [ $execute = 1 ] && [ $remote = 1 ]; then
  ssh ghosthive "
    was=\$(incus list bayan-test01 -c s -f csv)
    [ \"\$was\" = RUNNING ] || incus start bayan-test01
    rc=0; up=0
    for i in \$(seq 1 30); do timeout 10 incus exec bayan-test01 -- true 2>/dev/null && { up=1; break; }; sleep 2; done
    [ \$up = 1 ] || { echo '  VM agent not ready after 60 s'; rc=1; }
    timeout 120 incus exec bayan-test01 -- sh -c 'cd /home/bt || exit 0
      for d in 016-docs 016-docs.tgz pk.log; do [ -e \"\$d\" ] && { echo rm -rf /home/bt/\$d; rm -rf \"\$d\"; }; done
      for s in $shas; do for d in shard/\$s-*; do [ -e \"\$d\" ] && { echo rm -rf /home/bt/\$d; rm -rf \"\$d\"; }; done; done
      for d in 016-docs 016-docs.tgz pk.log; do [ -e \"\$d\" ] && { echo \"  still there: /home/bt/\$d\"; exit 1; }; done
      for s in $shas; do for d in shard/\$s-*; do [ -e \"\$d\" ] && { echo \"  still there: /home/bt/\$d\"; exit 1; }; done; done; exit 0' || { echo '  VM step failed'; rc=1; }
    [ \"\$was\" = RUNNING ] || incus stop bayan-test01 || rc=1
    exit \$rc" || failed=1
else
  printf 'would: in bayan-test01 remove /home/bt/{016-docs,016-docs.tgz,pk.log} and /home/bt/shard/{%s}-* (needs --execute --remove-remote)\n' "${shas// /,}"
fi

printf -- '-- remaining worktrees:\n'
git worktree list | grep -E "worker-016-w[123]|main-release" || echo '  none'
if [ $execute = 1 ] && [ $failed = 1 ]; then exit 1; fi
