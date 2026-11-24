#!/usr/bin/env bash
# Written 2026-11-17 by the session that restored and shortened the hoopoe hero, merged the 019/023/025 OQ answers and
# ran review 5810cf25b398..1d26738b (fix/review-2026-11-17-6).
# Worktrees and branches merged into dev are left to scripts/cleanup/merged-worktree-backlog.sh, which computes its targets
# at run time; this script runs it (same flags), then removes, in the main checkout, the reviewers' leftover pinned-build
# directories (.cache/bayan/.build-<sha>-<pid>) and this session's tmp/ scratch. Every target is refused if git tracks it.
# Not touched: ~/.local/opt/bayan-0.3.1-macos-arm64 (the previous install; ~/.local/bin/bayan now points at 0.3.3-dev).
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
repo="$(cd "$(git rev-parse --path-format=absolute --git-common-dir)/.." && pwd)"
failed=0

# 1. merged worktrees and branches
bash "$(dirname "${BASH_SOURCE[0]}")/merged-worktree-backlog.sh" ${pass[@]+"${pass[@]}"} || failed=1

# 2. pinned-build leftovers and session scratch (main checkout)
targets=()
for p in "$repo"/.cache/bayan/.build-*-[0-9]*; do [ -e "$p" ] && targets+=("${p#"$repo"/}"); done
for rel in tmp/review-2026-11-17.diff tmp/review-2026-11-17-loop2.diff tmp/review-2026-11-17-criteria.md \
           tmp/review-2026-11-17-criteria-b.md tmp/review-loop2.out tmp/gate-review-fix.log tmp/laws-fix.out \
           tmp/hoopoe-shots tmp/local-bin; do
  [ -e "$repo/$rel" ] && targets+=("$rel")
done
for p in "$repo"/tmp/refute-*.out; do [ -e "$p" ] && targets+=("${p#"$repo"/}"); done

for rel in ${targets[@]+"${targets[@]}"}; do
  if git -C "$repo" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    printf 'refuse: %s is tracked by git. Propose it as a commit instead. Left alone.\n' "$rel"
    failed=1
    continue
  fi
  if [ $execute = 1 ]; then
    rm -rf -- "${repo:?}/$rel"
    if [ -e "$repo/$rel" ]; then printf '  still there: %s\n' "$rel"; failed=1; else printf 'removed: %s\n' "$rel"; fi
  else
    printf 'would remove: %s\n' "$rel"
  fi
done

# 3. remaining state
printf 'left in .cache/bayan: %s entries\n' "$(ls -A "$repo/.cache/bayan" 2>/dev/null | wc -l | tr -d ' ')"
if [ $failed = 1 ]; then exit 1; fi
exit 0
