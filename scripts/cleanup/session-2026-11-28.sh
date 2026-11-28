#!/usr/bin/env bash
# Written 2026-11-28. Remote test clones made by scripts/selfhost/wp1-test.sh on wp1 and wlt1
# (C:/home/code/extrode.com/bayan/tmp/<short sha>, each with a <short sha>.wp1-test marker): wp1 held 393, wlt1 136.
# Only a directory with its .wp1-test marker is a candidate (wp1-test.sh made it); the newest KEEP (default 5) per host
# are kept, and so are the bundles of kept ones. Everything else is listed.
# Dry run by default. Removing needs both --execute (-e) and --delete-remote-clones (the clones cannot be restored,
# but each is a fresh clone of a bundle, so a rerun of wp1-test.sh recreates any of them).
set -euo pipefail

execute=0; del=0; keep=${KEEP:-5}
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-remote-clones) del=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
case $keep in ''|*[!0-9]*) echo "KEEP must be a number"; exit 2;; esac

for h in wp1 wlt1; do
  ps="\$d = Get-ChildItem C:/home/code/extrode.com/bayan/tmp -Directory | Where-Object { Test-Path ('C:/home/code/extrode.com/bayan/tmp/' + \$_.Name + '.wp1-test') } | Sort-Object LastWriteTime -Descending | Select-Object -Skip $keep;"
  if [ $execute = 1 ] && [ $del = 1 ]; then
    ps="$ps \$d | ForEach-Object { Remove-Item -Recurse -Force \$_.FullName; Remove-Item -Force (\$_.FullName + '.wp1-test'), (\$_.FullName + '.bundle') -ErrorAction SilentlyContinue }; 'removed ' + @(\$d).Count"
  else
    ps="$ps 'would remove ' + @(\$d).Count + ' clones (keeping newest $keep)'; \$d | Select-Object -First 5 | ForEach-Object { '  ' + \$_.Name + ' ' + \$_.LastWriteTime }"
  fi
  printf '%s: ' "$h"
  ssh "$h" "$ps" 2>&1 | grep -v 'post-quantum\|store now\|pq.html' || true
done
[ $execute = 1 ] && [ $del = 1 ] || echo "dry run; pass --execute --delete-remote-clones to remove"
