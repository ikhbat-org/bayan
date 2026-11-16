#!/usr/bin/env bash
# Written 2026-11-17 by the unattended session after the v0.3.2 tag (015 T9–T13 ports, L028 skip, Q31 plan-015 LOWs,
# review fixes 1117-1..3, the 020 T1 strace measurements on bayan-test01).
# Worktrees and branches that session merged into dev are left to scripts/cleanup/merged-worktree-backlog.sh, which
# computes its targets at run time; this script runs it (same flags) and then removes the session's VM scratch:
# /home/bt/tmp-020-t1 in bayan-test01 (user bt), the 020 T1 strace sample (~800 MB).
# Not touched: fix/release-0.3.2-l028 (for main, the user's call) and every branch dev does not hold.
# Dry run by default. --execute / -e acts. --remove-remote also removes the VM directory.
set -euo pipefail

execute=0; remote=0; pass=()
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1; pass+=("$a") ;;
    --delete-worktree-scratch) pass+=("$a") ;;
    --remove-remote) remote=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from a checkout on dev (here: %s).\n' "$(git branch --show-current)"; exit 1
fi
failed=0
bash "$(dirname "${BASH_SOURCE[0]}")/merged-worktree-backlog.sh" ${pass[@]+"${pass[@]}"} || failed=1

if [ $execute = 1 ] && [ $remote = 1 ]; then
  ssh ghosthive "
    was=\$(incus list bayan-test01 -c s -f csv)
    [ \"\$was\" = RUNNING ] || incus start bayan-test01
    rc=0; up=0
    for i in \$(seq 1 30); do timeout 10 incus exec bayan-test01 -- true 2>/dev/null && { up=1; break; }; sleep 2; done
    [ \$up = 1 ] || { echo '  VM agent not ready after 60 s'; rc=1; }
    timeout 120 incus exec bayan-test01 -- sh -c 'd=/home/bt/tmp-020-t1
      [ -e \$d ] || { echo \"skip:  \$d gone\"; exit 0; }
      echo rm -rf \$d; rm -rf \$d; [ ! -e \$d ] || { echo \"  still there: \$d\"; exit 1; }' || { echo '  VM step failed'; rc=1; }
    [ \"\$was\" = RUNNING ] || incus stop bayan-test01 || rc=1
    exit \$rc" || failed=1
else
  printf 'would: in bayan-test01 remove /home/bt/tmp-020-t1 (needs --execute --remove-remote)\n'
fi
if [ $execute = 1 ] && [ $failed = 1 ]; then exit 1; fi
exit 0
