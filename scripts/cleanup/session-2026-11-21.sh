#!/usr/bin/env bash
# Written 2026-11-21 by the session on specs 019 (T44a golden memory, cli-place, Windows t29 test) and 025 (T45, Qwen T39).
# Worktrees and branches merged into dev go to scripts/cleanup/merged-worktree-backlog.sh; this script removes the rest:
#   repo tmp/: CI log downloads (tmp/ci-win, tmp/ci-art8, tmp/win-kf), mutation-batch runs (tmp/mb-*), the push-models test
#     (tmp/pm-test*), web research notes (tmp/research), the script-tests log
#   worktree tmp/: the stage-0 build and logs (tmp/gb*), the golden and worker growth probes (tmp/golden-growth,
#     tmp/worker-growth, tmp/golden-jobs-*, tmp/cli), cli-place briefs, dry-run logs (tmp/ci-dr), stdin probes, one-off edit scripts
#   detached worktree tmp/dc-2598 inside the 019 worktree, and .worktrees/worker-golden-mem (landed into feat/019 as
#     ffb5d2577, kept because its tmp/gm/bayan was in use), with --remove-worktrees
#   tmp/w2/t29-*: T29 launcher scripts and baselines, with --remove-t29-scratch (T29 is parked: keep them until it ends)
#   zig caches: tmp/zig-global in each checkout and ~/.cache/zig, with --clear-zig-cache
#   on wp1: the WSL run checkouts ~/bayan-runs/<sha8> (zig and its cache stay), with --remove-remote
# Kept on purpose: the rest of tmp/w2 (launcher scripts and logs the handoff cites), tmp/llm-eval (the T39 records).
# Not here: ~/dot-claude-worktrees/push-models belongs to the ~/.claude repo; its own cleanup covers it.
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0; remote=0; zig=0; worktrees=0; t29=0; pass=()
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1; pass+=("$a") ;;
    --remove-remote) remote=1 ;;
    --clear-zig-cache) zig=1 ;;
    --remove-worktrees) worktrees=1 ;;
    --remove-t29-scratch) t29=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from a checkout on dev (here: %s).\n' "$(git branch --show-current)"; exit 1
fi
repo=$(cd "$(git rev-parse --git-common-dir)/.." && pwd)
wt019="$repo/.worktrees/feat-019-dotnet-exit"
failed=0

# 1. merged worktrees and branches
bash "$(dirname "${BASH_SOURCE[0]}")/merged-worktree-backlog.sh" ${pass[@]+"${pass[@]}"} || failed=1

# remove_scratch PATH...: each path under $repo, refused when git tracks it in the checkout that holds it.
remove_scratch() {
  local p rel top
  for p in "$@"; do
    rel=${p#"$repo"/}
    [ -e "$p" ] || { printf 'skip:  %s gone\n' "$rel"; continue; }
    top=$(git -C "$(dirname "$p")" rev-parse --show-toplevel 2>/dev/null) || top=$repo
    if git -C "$top" ls-files --error-unmatch -- "${p#"$top"/}" >/dev/null 2>&1; then
      printf 'refuse: %s is tracked by git. Propose it as a commit instead. Left alone.\n' "$rel"; failed=1; continue
    fi
    if [ $execute = 1 ]; then rm -rf "$p"; printf 'removed %s\n' "$rel"
    else printf 'would remove %s (%s)\n' "$rel" "$(du -sh "$p" | cut -f1)"; fi
  done
}

# 2. repo and worktree tmp/ scratch (globs expand at run time)
shopt -s nullglob
remove_scratch "$repo"/tmp/ci-win "$repo"/tmp/ci-art8 "$repo"/tmp/win-kf "$repo"/tmp/mb-* "$repo"/tmp/pm-test* \
  "$repo"/tmp/research "$repo"/tmp/script-tests.log \
  "$wt019"/tmp/gb "$wt019"/tmp/gb.sh "$wt019"/tmp/gb-shard.sh "$wt019"/tmp/golden-growth "$wt019"/tmp/worker-growth \
  "$wt019"/tmp/golden-jobs-* "$wt019"/tmp/cli "$wt019"/tmp/cli-place-*.md "$wt019"/tmp/ci-dr "$wt019"/tmp/t29-win*.log \
  "$wt019"/tmp/stdin-check* "$wt019"/tmp/stdin-probe "$wt019"/tmp/printer-edit.py "$wt019"/tmp/regen-boot.sh
if [ $t29 = 1 ]; then
  remove_scratch "$repo"/tmp/w2/t29-* "$repo"/tmp/w2/t29one
else
  printf 'would remove tmp/w2/t29-* and tmp/w2/t29one (needs --remove-t29-scratch; T29 is parked)\n'
fi

# 3. worktrees that are not merged into dev, so the backlog script leaves them
for w in "$wt019/tmp/dc-2598" "$repo/.worktrees/worker-golden-mem"; do
  if ! git -C "$repo" worktree list --porcelain | grep -qxF "worktree $w"; then printf 'skip:  %s not a worktree\n' "${w#"$repo"/}"
  elif [ $execute = 1 ] && [ $worktrees = 1 ]; then
    git -C "$repo" worktree remove --force "$w" && printf 'removed worktree %s\n' "${w#"$repo"/}" || failed=1
  else printf 'would remove worktree %s (needs --execute --remove-worktrees; its branch stays)\n' "${w#"$repo"/}"; fi
done

# 4. zig caches
for z in "$repo/tmp/zig-global" "$wt019/tmp/zig-global" "$HOME/.cache/zig"; do
  if [ ! -e "$z" ]; then printf 'skip:  %s gone\n' "$z"
  elif [ $execute = 1 ] && [ $zig = 1 ]; then rm -rf "$z"; printf 'removed %s\n' "$z"
  else printf 'would remove %s (%s; needs --execute --clear-zig-cache)\n' "$z" "$(du -sh "$z" | cut -f1)"; fi
done

# 5. WSL run checkouts on wp1 (names are <8 hex> only; zig, zig.path and zig-global stay)
if [ $execute = 1 ] && [ $remote = 1 ]; then
  ssh wp1 "wsl -e bash -c 'cd ~/bayan-runs 2>/dev/null || exit 0; for d in *; do case \$d in ([0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) rm -rf -- \"\$d\"; echo removed ~/bayan-runs/\$d ;; esac; done'" || failed=1
else
  printf 'would: on wp1 remove the WSL ~/bayan-runs/<sha8> checkouts (needs --execute --remove-remote)\n'
fi

printf 'left in tmp/: %s entries\n' "$(ls "$repo/tmp" | wc -l | tr -d ' ')"
if [ $failed = 1 ]; then exit 1; fi
exit 0
