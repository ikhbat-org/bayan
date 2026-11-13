#!/usr/bin/env bash
# Written 2026-11-13 by the session that landed plans 009 and 011, closed plan 010 and ran the session review
# (fix/review-2026-11-13-1). Removes that session's worker worktrees and branches, its scratch files under tmp/,
# its named shard directories in VM bayan-test01 (user bt). Ghosthive bundles and /home/bt/f2* are only listed.
# feat/009-prebuilt-runtime-object is checked out in .worktrees/dev-merge, so section 1 skips it until that checkout moves.
# Every target is checked at run time: a tracked path is refused, a missing one is a skip, an unmerged branch is
# left to `git branch -d` to refuse.
# Dry run by default. --execute / -e acts. --remove-remote also removes the named VM directories
# (/home/bt/o0: plan 010's -O0 runs, /home/bt/o0/r<n>-<v>, this session; the shard dirs below). Bundles are never removed.
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
  if [ ! -d "$d" ]; then printf 'skip:  worktree %s directory gone (pruned below)\n' "$wt"; continue; fi
  if [ -n "$(git -C "$d" status --porcelain)" ]; then printf 'refuse: %s has uncommitted changes. Left alone.\n' "$wt"; failed=1; continue; fi
  run git worktree remove "$d"
done
run git worktree prune
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
  "$main/.worktrees/dev-merge|tmp/p009-gate2.out" "$main/.worktrees/dev-merge|tmp/p009-review-criteria.md"
  "$main/.worktrees/dev-merge|tmp/p009-review.out" "$main/.worktrees/dev-merge|tmp/p009-vm2-classes.txt"
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

# 3. VM bayan-test01 (user bt) and ghosthive: only this session's named items, removed only with --execute --remove-remote.
#    Shard run dirs are /home/bt/shard/<sha8>-<slot> (scripts/selfhost/shard-test.sh); other sessions' runs are not touched.
#    The VM is stopped again only if it was stopped when the script started.
# Only runs this session logged (tmp/p009-shard.log, p009-vm2.log, rv1113-shard.log, rv1113-vm2.log).
shas="b53bbbbf 70d11eaa 7f80f611 51057d4c"
# Listed, never removed: no log ties /root/dev-91966244.bundle to this session.
bundles="/root/dev-91966244.bundle"
printf -- '-- ghosthive bundles (listed only, check by hand):\n'
for f in $bundles; do ssh ghosthive "ls -la $f 2>/dev/null || echo '  gone: $f'" || failed=1; done
if [ $execute = 1 ] && [ $remote = 1 ]; then
  ssh ghosthive "
    was=\$(incus list bayan-test01 -c s -f csv)
    [ \"\$was\" = RUNNING ] || incus start bayan-test01
    rc=0; up=0
    for i in \$(seq 1 30); do timeout 10 incus exec bayan-test01 -- true 2>/dev/null && { up=1; break; }; sleep 2; done
    [ \$up = 1 ] || { echo '  VM agent not ready after 60 s'; rc=1; }
    timeout 120 incus exec bayan-test01 -- sh -c 'cd /home/bt || exit 0
      for d in o0; do [ -e \"\$d\" ] && { echo rm -rf /home/bt/\$d; rm -rf \"\$d\"; }; done
      for s in $shas; do for d in shard/\$s-*; do [ -e \"\$d\" ] && { echo rm -rf /home/bt/\$d; rm -rf \"\$d\"; }; done; done
      ls -d f2* 2>/dev/null | sed \"s|^|  left (check by hand): /home/bt/|\"
      for d in o0 \$(for s in $shas; do echo shard/\$s-*; done); do [ -e \"\$d\" ] && { echo \"  still there: /home/bt/\$d\"; exit 1; }; done; exit 0' || { echo '  VM step failed'; rc=1; }
    [ \"\$was\" = RUNNING ] || incus stop bayan-test01 || rc=1
    exit \$rc" || failed=1
else
  printf 'would: in bayan-test01 remove /home/bt/o0 and /home/bt/shard/{%s}-*; list /home/bt/f2* (needs --execute --remove-remote)\n' "${shas// /,}"
fi

printf -- '-- remaining worktrees:\n'; git worktree list | grep -E 'worker-p009|worker-p011|worker-rv1113|feat-011-os-random' || echo '  none'
if [ $execute = 1 ] && [ $failed = 1 ]; then exit 1; fi
