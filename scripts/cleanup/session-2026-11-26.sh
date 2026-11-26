#!/usr/bin/env bash
# Written 2026-11-26 by the unattended session that landed plan 2026-11-25-019 branches F, D, E, B, C, A and the
# review fix fix/review-2026-11-26-1 (region loop/defer store order).
# Sections:
#   1. worktrees under .worktrees/ this session made; each is removed only when its HEAD is in dev and it is clean.
#      A worktree holding ignored files (tmp/ builds) is kept unless --delete-worktree-scratch, because
#      git worktree remove deletes ignored files without --force.
#   2. branches merged into dev: git branch -d (refuses anything unmerged).
#   3. scratch under the repo's tmp/ and /tmp/gate12-loop2 (a worker gate dir).
#   4. zig caches (~/.cache/zig, tmp/zig-global): only with --clear-zig-cache.
#   5. wp1 run dirs: listed only (names not recorded).
#   Stale branches fix/review-2026-11-10-5, fix/review-2026-11-11-3, fix/review-2026-11-11-4 are listed, never touched.
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0; scratch=0; zig=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-worktree-scratch) scratch=1 ;;
    --clear-zig-cache) zig=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from a checkout on dev (here: %s).\n' "$(git branch --show-current)"; exit 1
fi
repo=$(cd "$(git rev-parse --git-common-dir)/.." && pwd)
failed=0
checked_out() { git worktree list --porcelain | grep -qx "branch refs/heads/$1"; }
in_dev() { git merge-base --is-ancestor "$1" dev 2>/dev/null; }

session_branches="fix/review-2026-11-26-1 chore/worker-a-call chore/worker-a-copies chore/worker-a-defer
chore/worker-a-fixpoint chore/worker-a-loop chore/worker-a-loop2 chore/worker-a-loop3 chore/worker-a-provide
chore/worker-a-store chore/worker-a-this chore/worker-a-transfer fix/audit-040-mediums-1
chore/worker-m-lex chore/worker-m-fold chore/worker-m-emit chore/worker-m-std chore/worker-m-front chore/worker-m-rt
chore/worker-m-types chore/worker-m-drv chore/worker-m-regions chore/worker-m-states chore/worker-m-lsp
chore/worker-m-misc chore/worker-m-cname chore/worker-m-vol"

# 1. worktrees: "dir branch"
while read -r dir b; do
  wt="$repo/.worktrees/$dir"
  [ -d "$wt" ] || { printf 'skip:  worktree %s gone\n' "$dir"; continue; }
  head=$(git -C "$wt" rev-parse HEAD 2>/dev/null) || { printf 'keep:  worktree %s has no readable HEAD\n' "$dir"; failed=1; continue; }
  if ! in_dev "$head"; then printf 'keep:  worktree %s (HEAD %s not in dev)\n' "$dir" "${head:0:9}"; failed=1; continue; fi
  if [ -n "$(git -C "$wt" status --porcelain)" ]; then printf 'keep:  worktree %s is dirty\n' "$dir"; failed=1; continue; fi
  ignored=$(git -C "$wt" status --porcelain --ignored | grep -c '^!!' || true)
  if [ "$ignored" -gt 0 ] && [ $scratch = 0 ]; then
    printf 'keep:  worktree %s holds %s ignored path(s) (%s); --delete-worktree-scratch removes them\n' \
      "$dir" "$ignored" "$(du -sh "$wt" | cut -f1)"; continue
  fi
  if [ $execute = 1 ]; then
    if git worktree remove --force "$wt"; then printf 'removed worktree %s\n' "$dir"
    else printf 'keep:  git worktree remove refused %s\n' "$dir"; failed=1; fi
  else
    printf 'would remove worktree %s (%s)\n' "$dir" "$(du -sh "$wt" | cut -f1)"
  fi
done <<'EOF'
fix-review-2026-11-26-1 fix/review-2026-11-26-1
worker-a-call chore/worker-a-call
worker-a-copies chore/worker-a-copies
worker-a-defer chore/worker-a-defer
worker-a-fixpoint chore/worker-a-fixpoint
worker-a-loop chore/worker-a-loop
worker-a-loop2 chore/worker-a-loop2
worker-a-loop3 chore/worker-a-loop3
worker-a-provide chore/worker-a-provide
worker-a-store chore/worker-a-store
worker-a-this chore/worker-a-this
worker-a-transfer chore/worker-a-transfer
audit-mediums fix/audit-040-mediums-1
worker-m-lex chore/worker-m-lex
worker-m-fold chore/worker-m-fold
worker-m-emit chore/worker-m-emit
worker-m-std chore/worker-m-std
worker-m-front chore/worker-m-front
worker-m-rt chore/worker-m-rt
worker-m-types chore/worker-m-types
worker-m-drv chore/worker-m-drv
worker-m-regions chore/worker-m-regions
worker-m-states chore/worker-m-states
worker-m-lsp chore/worker-m-lsp
worker-m-misc chore/worker-m-misc
worker-m-cname chore/worker-m-cname
worker-m-vol chore/worker-m-vol
EOF
[ $execute = 1 ] && git worktree prune

# 2. merged branches
for b in $session_branches; do
  if ! git rev-parse --verify --quiet "refs/heads/$b" >/dev/null; then printf 'skip:  branch %s gone\n' "$b"; continue; fi
  if checked_out "$b"; then printf 'keep:  branch %s is checked out (worktree kept above)\n' "$b"; failed=1; continue; fi
  if [ $execute = 1 ]; then
    git branch -d "$b" || { printf '  refused: %s not merged. Left alone.\n' "$b"; failed=1; }
  else
    printf 'would git branch -d %s\n' "$b"
  fi
done

# 3. tmp scratch (globs inside the repo tmp/ and the dev worktree tmp/)
dev_wt="$repo/.worktrees/fix-divergences-run-cases"
for p in "$repo"/tmp/rf-* "$repo"/tmp/review-* "$repo"/tmp/a-* "$repo"/tmp/rv-* "$repo"/tmp/mediums "$repo"/tmp/med-* \
  "$dev_wt/tmp/a-stage1" "$dev_wt/tmp/rv-r2" /tmp/gate12-loop2; do
  [ -e "$p" ] || continue
  if [ $execute = 1 ]; then rm -rf -- "$p" && printf 'removed %s\n' "$p"
  else printf 'would remove %s (%s)\n' "$p" "$(du -sh "$p" | cut -f1)"; fi
done

# 4. zig caches
for p in "$HOME/.cache/zig" "$repo/tmp/zig-global"; do
  [ -e "$p" ] || continue
  if [ $zig = 1 ] && [ $execute = 1 ]; then rm -rf -- "$p" && printf 'removed %s\n' "$p"
  else printf 'would remove %s (%s; needs -e --clear-zig-cache)\n' "$p" "$(du -sh "$p" | cut -f1)"; fi
done

# 5. wp1 run dirs: this session's per-sha dirs under C:/home/code/extrode.com/bayan/tmp were not recorded by name,
#    so nothing is deleted there; list them and remove by hand:
echo "wp1: ssh wp1 \"Get-ChildItem C:/home/code/extrode.com/bayan/tmp | Sort-Object LastWriteTime\""
echo "wlt1: ssh wlt1 \"Get-ChildItem C:/home/code/extrode.com/bayan/tmp | Sort-Object LastWriteTime\""

echo "stale, not touched (owner decides): fix/review-2026-11-10-5 fix/review-2026-11-11-3 fix/review-2026-11-11-4"
if [ $execute = 1 ] && [ $failed = 1 ]; then exit 1; fi
exit 0
