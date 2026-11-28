#!/usr/bin/env bash
# Written 2026-11-28. Remote test clones made by scripts/selfhost/wp1-test.sh on wp1 and wlt1
# (C:/home/code/extrode.com/bayan/tmp/<short sha>, each with a <short sha>.wp1-test marker): wp1 held 393, wlt1 136.
# Only a directory with its .wp1-test marker is a candidate (wp1-test.sh made it); the newest KEEP (default 5) per host
# are kept, and so are the bundles of kept ones; a clone whose folder was last written in the last 24 h is skipped (a run may be in
# flight; the folder time changes only when a top-level entry does). Unmarked directories are never touched. The dry run counts
# the candidates and lists the first 5. A clone whose delete fails keeps its marker (so a rerun retries it) and is listed.
# Unmarked <sha8>-sp checkouts (the old shard runner) are removed by scripts/cleanup/unattended-2026-11-19.sh --execute --remove-remote
# (that script also deletes every <sha8>.bundle, kept clones' included: run it only when no wp1-test.sh run is in flight);
# cache, asan-tests and task-named dirs are left alone.
# Local leftovers, clean at ca937344b, not removed here: .worktrees/worker-tasks027, .worktrees/worker-tasks028
# (remove with: git worktree remove .worktrees/worker-tasks027; same for 028).
# Dry run by default. Removing needs both --execute (-e) and --delete-remote-clones (the clones cannot be restored,
# but each is a fresh clone of a bundle, so a rerun of wp1-test.sh recreates any of them).
set -euo pipefail

execute=0; del=0; failed=0; keep=${KEEP:-5}
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-remote-clones) del=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
case $keep in ''|*[!0-9]*) echo "KEEP must be a number"; exit 2;; esac

for h in wp1 wlt1; do
  ps="\$d = Get-ChildItem C:/home/code/extrode.com/bayan/tmp -Directory | Where-Object { Test-Path ('C:/home/code/extrode.com/bayan/tmp/' + \$_.Name + '.wp1-test') } | Sort-Object LastWriteTime -Descending | Select-Object -Skip $keep | Where-Object { \$_.LastWriteTime -lt (Get-Date).AddHours(-24) };"
  if [ $execute = 1 ] && [ $del = 1 ]; then
    ps="$ps \$n = 0; \$d | ForEach-Object { Remove-Item -Recurse -Force \$_.FullName -ErrorAction SilentlyContinue; if (Test-Path \$_.FullName) { '  kept (delete failed): ' + \$_.Name } else { Remove-Item -Force (\$_.FullName + '.wp1-test'), (\$_.FullName + '.bundle') -ErrorAction SilentlyContinue; \$n++ } }; 'removed ' + \$n + ' of ' + @(\$d).Count"
  else
    ps="$ps 'would remove ' + @(\$d).Count + ' clones (keeping newest $keep)'; \$d | Select-Object -First 5 | ForEach-Object { '  ' + \$_.Name + ' ' + \$_.LastWriteTime }"
  fi
  printf '%s: ' "$h"
  out=$(ssh "$h" "$ps" 2>&1) || { failed=1; echo "(ssh to $h failed)"; }
  printf '%s\n' "$out" | grep -v 'post-quantum\|store now\|pq.html' || true
done
[ $execute = 1 ] && [ $del = 1 ] || echo "dry run; pass --execute --delete-remote-clones to remove"
exit $failed
