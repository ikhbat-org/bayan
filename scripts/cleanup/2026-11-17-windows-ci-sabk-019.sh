#!/usr/bin/env bash
# Written 2026-11-17 by the session that fixed the Windows CI red on dev (fix/windows-ci-dev), merged feat/site-redesign
# and started specs 024 (sabk) and 019. Worktrees and branches merged into dev (worker-024-*, worker-019-*, the feature
# worktrees once merged) are left to scripts/cleanup/merged-worktree-backlog.sh, which computes its targets at run time;
# this script runs it (same flags), then removes this session's tmp/ scratch in the main checkout and one probe directory
# written outside the project by mistake (/tmp/claude-cwd-probe). Every repo target is refused if git tracks it.
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

# 2. session scratch (main checkout)
targets=()
for rel in tmp/cwd-probe tmp/t18.cs tmp/selfhost-tests.out tmp/wp1-t18.out tmp/ci-win-dev.log tmp/pre-push-dev.out \
           tmp/sa-fix.out tmp/dev-subjects.txt tmp/dev-subj-only.txt tmp/docs-024.out tmp/wp1-fix.out; do
  [ -e "$repo/$rel" ] && targets+=("$rel")
done
for p in "$repo"/tmp/w-024-*.out "$repo"/tmp/w-019-*.out "$repo"/tmp/g-024-*.out "$repo"/tmp/g-019-*.out; do
  [ -e "$p" ] && targets+=("${p#"$repo"/}")
done

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

# 3. scratch written outside the project (a cwd probe; the 024 T10 gate checker's round-1 copy; the 019 T1 writer's stage-0 build dir in the OS temp dir)
for probe in /tmp/claude-cwd-probe /tmp/t10gate.KNso /var/folders/nn/bj_f92fd4dq9k0dqr82y_hfw0000gn/T/tmp.adUOv5tDUd; do
if [ -e "$probe" ]; then
  if [ $execute = 1 ]; then
    rm -rf -- "$probe"
    if [ -e "$probe" ]; then printf '  still there: %s\n' "$probe"; failed=1; else printf 'removed: %s\n' "$probe"; fi
  else
    printf 'would remove: %s\n' "$probe"
  fi
fi
done

if [ $failed = 1 ]; then exit 1; fi
exit 0
