#!/usr/bin/env bash
# Written 2026-11-11 for the spec 003 P2 routing pilot (~/.claude tools/route-replay.js) and the 2026-11-11 review session.
# Removes the replay scratch repos under tmp/route-replay/ of the main checkout (each a throwaway clone with its own
# worker worktrees). The labels and history the pilot produced live in ~/.claude/tmp/route/ and are not touched.
# The session's merged worktrees (worker-rv-e764-signaled, fix-review-2026-11-11-3, worker-q1190,
# fix-q1190-number-agreement, worker-p007-a1, worker-p007-a2) are left to the recurring merged-worktree-backlog.sh,
# which decides merged-ness and cleanliness at run time; section 3 only prints its dry run.
# Dry run by default. --execute / -e acts; deleting the scratch also needs --delete-replay-scratch.
# Run it from a dev checkout (section 3 needs one); section 2 acts on the main checkout's tmp/ wherever it runs from.
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
main="$(git rev-parse --path-format=absolute --git-common-dir)"; main="${main%/.git}"
rel="tmp/route-replay"
failed=0
SESSION_WT='/(worker-rv-e764-signaled|fix-review-2026-11-11-3|worker-q1190|fix-q1190-number-agreement|worker-p007-a1|worker-p007-a2)( |$)'

# 1. Gates on the current state.
if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: check out dev first (on %s).\n' "$(git branch --show-current)"; [ "$execute" = 1 ] && exit 1 || exit 0
fi
# A replay, or any writer or gate it started, works with its cwd inside the scratch; deleting it then pulls the tree
# out from under a live process. The replay's own process is checked by name as well, in case it is between tasks.
busy="$(pgrep -f "${CLEANUP_REPLAY_PATTERN:-route-replay\.js run}" || true)"
if [ -e "$main/$rel" ]; then
  if ! command -v lsof >/dev/null 2>&1; then
    printf 'refuse: lsof is not on PATH, so processes using the scratch cannot be checked.\n'; [ "$execute" = 1 ] && exit 1 || exit 0
  fi
  busy="$busy $(lsof -a -d cwd -Fpn 2>/dev/null | awk -v d="$main/$rel" '/^p/{p=substr($0,2)} /^n/{n=substr($0,2); if (n==d || index(n, d "/")==1) print p}' || true)"
fi
busy="$(printf '%s' "$busy" | tr -s ' \n' ' ' | sed 's/^ //; s/ $//')"
if [ -n "$busy" ]; then
  printf 'refuse: processes are using the replay scratch (pids %s). Wait for the replay and its workers to finish.\n' "$busy"
  [ "$execute" = 1 ] && exit 1 || exit 0
fi

# 2. Replay scratch repos, in the main checkout (the replay tool writes there, not in a linked worktree).
cd "$main"
if [ ! -e "$rel" ]; then
  printf 'skip:  %s no longer exists\n' "$rel"
elif git ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
  printf 'refuse: %s is tracked by git. Propose it as a commit instead. Left alone.\n' "$rel"; failed=1
elif ! git check-ignore -q -- "$rel"; then
  printf 'refuse: %s is not ignored by git, so it is not known scratch. Left alone.\n' "$rel"; failed=1
else
  printf 'would remove %s (%s)\n' "$rel" "$(du -sh "$rel" 2>/dev/null | cut -f1)"
  if [ "$execute" = 1 ] && [ "$scratch" = 1 ]; then
    if rm -rf "./$rel"; then printf 'removed %s\n' "$rel"
    else printf 'failed: rm -rf %s left part of it behind.\n' "$rel"; failed=1
    fi
  elif [ "$execute" = 1 ]; then
    printf '  held: deleting it also needs --delete-replay-scratch\n'
  fi
fi
cd "$repo"

# 3. The session's merged worktrees: the recurring script's dry run.
printf -- '--- merged-worktree-backlog.sh (dry run; run it yourself with -e) ---\n'
if backlog="$(bash scripts/cleanup/merged-worktree-backlog.sh 2>&1)"; then
  listed="$(printf '%s\n' "$backlog" | grep -E "$SESSION_WT" || true)"
  if [ -n "$listed" ]; then printf '%s\n' "$listed"; else printf "none of this session's worktrees listed\n"; fi
else
  printf 'failed: merged-worktree-backlog.sh exited non-zero; its output:\n%s\n' "$backlog"; failed=1
fi

# 4. Remaining state.
printf -- '--- remaining ---\n'
if [ -e "$main/$rel" ]; then printf '%s present\n' "$rel"; else printf '%s gone\n' "$rel"; fi
printf 'session worktrees left: %s\n' "$(git worktree list | grep -cE "$SESSION_WT" || true)"

if [ "$execute" = 1 ] && [ "$failed" = 1 ]; then exit 1; fi
exit 0
