#!/usr/bin/env bash
# Written 2026-11-24 by the session on spec 019b (C# removal, T67–T70) and the 2026-11-23 review LOWs.
# Removes:
#   main checkout tmp/: tmp/csf-* (csharp-final probes and their logs), tmp/v032-blame
#   with --remove-worktrees: .worktrees/worker-rv-lows-1123 (the review-LOWs writer)
#   with --delete-branches: chore/worker-rv-lows-1123 (checked merged into dev first)
#   with --remove-zig-caches: ~/.cache/zig and .worktrees/feat-019b/tmp/zig-global (zig caches grow without bound)
# Prints, never runs: the wp1 command for its tmp/csf-e5780 (the csharp-final ddc build tree there).
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0; worktrees=0; branchdel=0; zig=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --remove-worktrees) worktrees=1 ;;
    --delete-branches) branchdel=1 ;;
    --remove-zig-caches) zig=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from a checkout on dev (here: %s).\n' "$(git branch --show-current)"; exit 1
fi
repo=$(cd "$(git rev-parse --git-common-dir)/.." && pwd)
failed=0

remove_scratch() { # [flag-needed-name flag-value] paths...
  local p rel top
  for p in "$@"; do
    rel=${p#"$repo"/}
    [ -e "$p" ] || { printf 'skip:  %s gone\n' "$rel"; continue; }
    top=$(git -C "$(dirname "$p")" rev-parse --show-toplevel 2>/dev/null) || top=""
    if [ -n "$top" ] && git -C "$top" ls-files --error-unmatch -- "${p#"$top"/}" >/dev/null 2>&1; then
      printf 'refuse: %s is tracked by git. Left alone.\n' "$rel"; failed=1; continue
    fi
    if [ $execute = 1 ]; then rm -rf "$p"; printf 'removed %s\n' "$rel"
    else printf 'would remove %s (%s)\n' "$rel" "$(du -sh "$p" | cut -f1)"; fi
  done
}

shopt -s nullglob
# 1. scratch
remove_scratch "$repo"/tmp/csf-* "$repo"/tmp/v032-blame

# 2. worktree
w="$repo/.worktrees/worker-rv-lows-1123"
if ! git -C "$repo" worktree list --porcelain | grep -qxF "worktree $w"; then printf 'skip:  %s not a worktree\n' "${w#"$repo"/}"
elif [ -n "$(git -C "$w" status --porcelain --untracked-files=no)" ]; then printf 'refuse: %s has uncommitted changes. Left alone.\n' "${w#"$repo"/}"; failed=1
elif [ $execute = 1 ] && [ $worktrees = 1 ]; then
  git -C "$repo" worktree remove --force "$w" && printf 'removed worktree %s\n' "${w#"$repo"/}" || failed=1
else printf 'would remove worktree %s (needs --execute --remove-worktrees)\n' "${w#"$repo"/}"; fi

# 3. branch
b=chore/worker-rv-lows-1123
if ! git -C "$repo" rev-parse -q --verify "refs/heads/$b" >/dev/null; then printf 'skip:  branch %s gone\n' "$b"
elif ! git -C "$repo" merge-base --is-ancestor "$b" dev; then printf 'refuse: branch %s is not merged into dev. Left alone.\n' "$b"; failed=1
elif [ $execute = 1 ] && [ $branchdel = 1 ]; then git -C "$repo" branch -d "$b" >/dev/null && printf 'deleted branch %s\n' "$b" || failed=1
else printf 'would delete branch %s (needs --execute --delete-branches)\n' "$b"; fi

# 4. zig caches (outside any repo, or ignored tmp/)
for z in "$HOME/.cache/zig" "$repo/.worktrees/feat-019b/tmp/zig-global"; do
  if [ ! -e "$z" ]; then printf 'skip:  %s gone\n' "$z"
  elif [ $execute = 1 ] && [ $zig = 1 ]; then rm -rf "$z" && printf 'removed %s\n' "$z" || failed=1
  else printf 'would remove %s (%s; needs --execute --remove-zig-caches)\n' "$z" "$(du -sh "$z" | cut -f1)"; fi
done

# 5. wp1 (not run from here)
printf 'wp1, by hand if wanted: the bayan checkout'\''s tmp/csf-e5780 there (the csharp-final ddc build tree) is scratch too.\n'

if [ $failed = 1 ]; then exit 1; fi
exit 0
