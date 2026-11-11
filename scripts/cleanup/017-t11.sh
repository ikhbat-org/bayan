#!/usr/bin/env bash
# Cleanup for spec 017 T11 (`test` in the self-hosted driver), written 2026-11-12 by the T11 worker.
# Removes the untracked scratch the T11 runs left under tmp/: probe projects, break-test copies and the golden work dirs of `test`.
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
repo="$(git rev-parse --show-toplevel)"
cd "$repo"
failed=0

shopt -s nullglob
for rel in tmp/t11c tmp/t11bt tmp/golden/test_*; do
  if [ ! -e "$rel" ]; then printf 'skip:  %s already gone\n' "$rel"; continue; fi
  if git ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    printf 'refuse: %s is tracked by git. Propose it as a commit instead. Left alone.\n' "$rel"; failed=1; continue
  fi
  if [ $execute -eq 1 ]; then rm -rf -- "$rel"; printf 'removed: %s\n' "$rel"
  else printf 'would: rm -rf %s (needs --execute)\n' "$rel"; fi
done

if [ $execute -eq 1 ] && [ $failed -eq 1 ]; then exit 1; fi
