#!/usr/bin/env bash
# Written 2026-11-23 by the session on spec 019 (full-review fixes, Fs.fileSize, presize, golden worker slices).
# Removes:
#   worktree tmp/: tmp/bbfix, tmp/rss1601, tmp/rv* (rv2 debug scratch, rv3 driver builds), tmp/ref019-golden, tmp/t51-dry, tmp/bb
#   with --remove-worktrees: .worktrees/worker-fix019-{bound,cache,lsp,scripts,sem} (merged into feat/019 by hand: worker.js land
#     refused them over ignored csharp bin files)
#   with --delete-branches: the merged branches listed in $branches (each checked merged into feat/019-dotnet-exit first)
#   with --remove-images: the docker images gcc:14 and debian:stable-slim (Linux runtime test runs)
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0; worktrees=0; branchdel=0; images=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --remove-worktrees) worktrees=1 ;;
    --delete-branches) branchdel=1 ;;
    --remove-images) images=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from a checkout on dev (here: %s).\n' "$(git branch --show-current)"; exit 1
fi
repo=$(cd "$(git rev-parse --git-common-dir)/.." && pwd)
wt019="$repo/.worktrees/feat-019-dotnet-exit"
failed=0

remove_scratch() {
  local p rel top
  for p in "$@"; do
    rel=${p#"$repo"/}
    [ -e "$p" ] || { printf 'skip:  %s gone\n' "$rel"; continue; }
    top=$(git -C "$(dirname "$p")" rev-parse --show-toplevel 2>/dev/null) || top=$repo
    if git -C "$top" ls-files --error-unmatch -- "${p#"$top"/}" >/dev/null 2>&1; then
      printf 'refuse: %s is tracked by git. Left alone.\n' "$rel"; failed=1; continue
    fi
    if [ $execute = 1 ]; then rm -rf "$p"; printf 'removed %s\n' "$rel"
    else printf 'would remove %s (%s)\n' "$rel" "$(du -sh "$p" | cut -f1)"; fi
  done
}

shopt -s nullglob
remove_scratch "$wt019"/tmp/bbfix "$wt019"/tmp/rss1601 "$wt019"/tmp/rv* "$wt019"/tmp/ref019-golden "$wt019"/tmp/t51-dry "$wt019"/tmp/bb

for k in bound cache lsp scripts sem; do
  w="$repo/.worktrees/worker-fix019-$k"
  if ! git -C "$repo" worktree list --porcelain | grep -qxF "worktree $w"; then printf 'skip:  %s not a worktree\n' "${w#"$repo"/}"
  elif [ $execute = 1 ] && [ $worktrees = 1 ]; then
    git -C "$repo" worktree remove --force "$w" && printf 'removed worktree %s\n' "${w#"$repo"/}" || failed=1
  else printf 'would remove worktree %s (needs --execute --remove-worktrees)\n' "${w#"$repo"/}"; fi
done

branches="chore/worker-fix019-bound chore/worker-fix019-cache chore/worker-fix019-lsp chore/worker-fix019-scripts chore/worker-fix019-sem
fix/019-io-read-presize fix/019-io-read-presize-regular-file fix/019-libc-uses-presize fix/019-test-sh-zig-manifests
test/019-pin-new-cases docs/019-review-lows docs/019-fix-review-lows fix/llm-eval-prime-mtime-tie chore/cleanup-session-1122"
for b in $branches; do
  if ! git -C "$repo" rev-parse -q --verify "refs/heads/$b" >/dev/null; then printf 'skip:  branch %s gone\n' "$b"; continue; fi
  if ! git -C "$repo" merge-base --is-ancestor "$b" feat/019-dotnet-exit && ! git -C "$repo" merge-base --is-ancestor "$b" dev; then
    printf 'refuse: branch %s is not merged into feat/019-dotnet-exit or dev. Left alone.\n' "$b"; failed=1; continue
  fi
  if [ $execute = 1 ] && [ $branchdel = 1 ]; then git -C "$repo" branch -d "$b" >/dev/null && printf 'deleted branch %s\n' "$b" || failed=1
  else printf 'would delete branch %s (needs --execute --delete-branches)\n' "$b"; fi
done

for img in gcc:14 debian:stable-slim; do
  if ! docker image inspect "$img" >/dev/null 2>&1; then printf 'skip:  image %s not present\n' "$img"
  elif [ $execute = 1 ] && [ $images = 1 ]; then docker image rm "$img" >/dev/null && printf 'removed image %s\n' "$img" || failed=1
  else printf 'would remove image %s (needs --execute --remove-images)\n' "$img"; fi
done

if [ $failed = 1 ]; then exit 1; fi
exit 0
