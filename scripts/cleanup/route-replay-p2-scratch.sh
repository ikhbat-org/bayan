#!/usr/bin/env bash
# Written 2026-11-11 for the spec 003 P2 routing pilot (~/.claude tools/route-replay.js) and the 2026-11-11 review session.
# Removes the replay scratch repos under tmp/route-replay/ (each a throwaway clone with its own worker worktrees).
# The labels and history the pilot produced live in ~/.claude/tmp/route/ and are not touched.
# The session's merged worktrees (worker-rv-e764-signaled, fix-review-2026-11-11-3, worker-q1190,
# fix-q1190-number-agreement, worker-p007-a1, worker-p007-a2) are left to the recurring merged-worktree-backlog.sh,
# which decides merged-ness and cleanliness at run time; section 3 only prints its dry run.
# Dry run by default. --execute / -e acts; deleting the scratch also needs --delete-replay-scratch.
set -euo pipefail

execute=0; scratch=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-replay-scratch) scratch=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
repo="$(git rev-parse --show-toplevel)"
cd "$repo"
failed=0

# 1. Gate: no replay may be running, or its worktrees would be deleted under it.
if pgrep -f 'route-replay\.js run' >/dev/null 2>&1; then
  printf 'refuse: a route-replay run is in progress (pgrep -f "route-replay.js run"). Wait for it to finish.\n'; exit 1
fi

# 2. Replay scratch repos, in the main checkout (the replay tool writes there, not in a linked worktree).
main="$(git rev-parse --path-format=absolute --git-common-dir)"; main="${main%/.git}"
cd "$main"
rel="tmp/route-replay"
if [ ! -e "$rel" ]; then
  printf 'skip:  %s no longer exists\n' "$rel"
elif git ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
  printf 'refuse: %s is tracked by git. Propose it as a commit instead. Left alone.\n' "$rel"; failed=1
elif ! git check-ignore -q -- "$rel"; then
  printf 'refuse: %s is not ignored by git, so it is not known scratch. Left alone.\n' "$rel"; failed=1
else
  printf 'would remove %s (%s)\n' "$rel" "$(du -sh "$rel" | cut -f1)"
  if [ "$execute" = 1 ] && [ "$scratch" = 1 ]; then
    rm -rf "./$rel" && printf 'removed %s\n' "$rel"
  elif [ "$execute" = 1 ]; then
    printf '  held: deleting it also needs --delete-replay-scratch\n'
  fi
fi

cd "$repo"
# 3. The session's merged worktrees: the recurring script's dry run.
printf -- '--- merged-worktree-backlog.sh (dry run; run it yourself with -e) ---\n'
if [ "$(git branch --show-current)" = "dev" ]; then
  bash scripts/cleanup/merged-worktree-backlog.sh | grep -E 'worker-rv-e764-signaled|fix-review-2026-11-11-3|worker-q1190|fix-q1190-number-agreement|worker-p007-a[12]' || printf 'none of this session'"'"'s worktrees listed\n'
else
  printf 'skip:  merged-worktree-backlog.sh needs a dev checkout (on %s)\n' "$(git branch --show-current)"
fi

# 4. Remaining state.
printf -- '--- remaining ---\n'
[ -e "$main/$rel" ] && printf '%s present\n' "$rel" || printf '%s gone\n' "$rel"
git worktree list | grep -cE 'worker-rv-e764-signaled|fix-review-2026-11-11-3|worker-q1190|fix-q1190-number-agreement|worker-p007-a[12]' | sed 's/^/session worktrees left: /' || true

if [ "$execute" = 1 ] && [ "$failed" = 1 ]; then exit 1; fi
exit 0
