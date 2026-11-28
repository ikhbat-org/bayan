#!/usr/bin/env bash
# Written 2026-11-28 by the 0.4.2 release-check session. Run after v0.4.2 is tagged and pushed.
# Merged worktrees and branches (release-042, fix-wp1-timeout, dev-land's fix branches) go to
# scripts/cleanup/merged-worktree-backlog.sh, which computes its targets at run time; this script runs it (same flags),
# then removes the session's scratch tmp/rel042 (watchdog, CI-watch and timing scripts, run logs).
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0; pass=()
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1; pass+=("$a") ;;
    --delete-worktree-scratch) pass+=("$a") ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from a checkout on dev (here: %s).\n' "$(git branch --show-current)"; exit 1
fi
repo=$(cd "$(git rev-parse --git-common-dir)/.." && pwd)

bash "$(dirname "${BASH_SOURCE[0]}")/merged-worktree-backlog.sh" ${pass[@]+"${pass[@]}"}

p="$repo/tmp/rel042"
if [ -e "$p" ]; then
  if [ $execute = 1 ]; then rm -rf "$p"; printf 'removed %s\n' "$p"; else printf 'would remove %s (%s)\n' "$p" "$(du -sh "$p" | cut -f1)"; fi
fi
