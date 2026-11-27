#!/usr/bin/env bash
# Disk cleanup written 2026-11-27 (owner: .worktrees 289 GB, tmp/ 251 GB). Every target is checked at run time.
#   1. merged-worktree-backlog.sh with the same flags: worktrees whose branch dev holds.
#   2. Worktrees whose branch another branch already holds (CONTAINED: branch, container) or whose every commit dev has
#      under another id (`git cherry dev <branch>` lists no `+`; the 2026-11-25 dev split rewrote ids). Branches stay.
#   3. Top-level entries of the main checkout's tmp/ untouched for TMP_DAYS days (default 2), at least TMP_MIN_MB (100)
#      in size, untracked, and not in KEEP_TMP.
# Dry run by default. --execute / -e acts. Section 2 also needs --delete-worktree-scratch (removing a worktree deletes its
# ignored files); section 3 needs --delete-tmp-scratch.
set -euo pipefail

execute=0; scratch=0; tmpdel=0; pass=()
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1; pass+=("$a") ;;
    --delete-worktree-scratch) scratch=1; pass+=("$a") ;;
    --delete-tmp-scratch) tmpdel=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
repo="$(git rev-parse --show-toplevel)"
cd "$repo"
[ "$(git branch --show-current)" = dev ] || { printf 'refuse: check out dev first (on %s).\n' "$(git branch --show-current)"; exit 1; }
main="$(git rev-parse --path-format=absolute --git-common-dir)"; main="${main%/.git}"
here="$(dirname "$0")"
failed=0

CONTAINED="${CONTAINED-
fix/audit-040-highs fix/audit-040-highs-2
chore/worker-h2fix-sem fix/audit-040-highs-2
chore/worker-h2fix-emit fix/audit-040-highs-2
fix/audit-040-lows-2 fix/audit-040-lows-3
chore/worker-hard8b feat/hardening-sanitize
fix/release-0.3.2-l028 main
}"
CHERRY="${CHERRY_BRANCHES-chore/worker-019-t17c docs/go-decision-bench chore/worker-low041-ci chore/worker-low041-drv}"
KEEP_TMP="${KEEP_TMP-zig-global wp1 wlt1 audit-0.4.0 plan040 decision pre-push}"

echo "== 1. worktrees dev holds (merged-worktree-backlog.sh)"
bash "$here/merged-worktree-backlog.sh" ${pass[@]+"${pass[@]}"} || failed=1

# wt_of BRANCH: the worktree path checked out on BRANCH, empty when none.
wt_of() { git worktree list --porcelain | awk -v b="refs/heads/$1" '/^worktree /{w=substr($0,10)} $0=="branch " b {print w}'; }
remove_wt() { # remove_wt BRANCH REASON
  local w; w="$(wt_of "$1")"
  if [ -z "$w" ]; then printf 'skip:  %s has no worktree\n' "$1"; return; fi
  local rel="${w#"$main"/}"
  if [ -n "$(git -C "$w" status --porcelain 2>/dev/null)" ]; then printf 'keep:  %s (modified or untracked files)\n' "$rel"; return; fi
  if [ "$execute" = 0 ] || [ "$scratch" = 0 ]; then printf 'would: git worktree remove %s (%s)\n' "$rel" "$2"; return; fi
  if git worktree remove "$w"; then printf 'removed: %s\n' "$rel"; else printf 'refused: %s. Left alone.\n' "$rel"; failed=1; fi
}

echo "== 2. worktrees another branch or dev already holds"
while read -r b c; do
  [ -n "$b" ] || continue
  git rev-parse --verify -q "refs/heads/$b" >/dev/null || { printf 'skip:  branch %s no longer exists\n' "$b"; continue; }
  if git merge-base --is-ancestor "$b" "$c" 2>/dev/null; then remove_wt "$b" "in $c"
  else printf 'keep:  %s (not in %s)\n' "$b" "$c"; fi
done <<< "$CONTAINED"
for b in $CHERRY; do
  git rev-parse --verify -q "refs/heads/$b" >/dev/null || { printf 'skip:  branch %s no longer exists\n' "$b"; continue; }
  if [ "$(git cherry dev "$b" | grep -c '^+' || true)" = 0 ]; then remove_wt "$b" "every commit in dev"
  else printf 'keep:  %s (commits dev lacks)\n' "$b"; fi
done
[ "$execute" = 1 ] && [ "$scratch" = 1 ] && git worktree prune

echo "== 3. old tmp/ entries"
total=0
if [ -d "$main/tmp" ]; then
  while IFS= read -r p; do
    n="${p##*/}"
    case " $KEEP_TMP " in *" $n "*) printf 'keep:  tmp/%s (KEEP_TMP)\n' "$n"; continue ;; esac
    if git -C "$main" ls-files --error-unmatch -- "tmp/$n" >/dev/null 2>&1; then
      printf 'refuse: tmp/%s is tracked by git. Left alone.\n' "$n"; failed=1; continue
    fi
    kb="$(du -sk "$p" 2>/dev/null | cut -f1)"; kb="${kb:-0}"
    [ "$kb" -ge $(( ${TMP_MIN_MB:-100} * 1024 )) ] || continue
    total=$(( total + kb ))
    if [ "$execute" = 1 ] && [ "$tmpdel" = 1 ]; then rm -rf -- "$p" && printf 'removed: tmp/%s (%d MB)\n' "$n" $(( kb / 1024 ))
    else printf 'would: rm -rf tmp/%s (%d MB)\n' "$n" $(( kb / 1024 )); fi
  done < <(find "$main/tmp" -mindepth 1 -maxdepth 1 -mtime +"${TMP_DAYS:-2}")
fi
printf 'tmp/ old entries: %d GB\n' $(( total / 1048576 ))

echo "== remaining"
printf 'worktrees: %s\n' "$(git worktree list | wc -l | tr -d ' ')"
df -h "$main" | tail -1
if [ "$execute" = 1 ] && [ "$failed" = 1 ]; then exit 1; fi
exit 0
