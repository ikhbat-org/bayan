#!/usr/bin/env bash
# Written 2026-11-22 by the session on spec 019 T29 (T29c exempt markers, bound-peak instrumentation, cov9 gate).
# Removes:
#   repo tmp/remote: the claude bundles for wp1/WSL (claude-bundle, claude-bundle.tgz), writer.bundle, branch.bundle,
#     t29-tools.tgz, t29-lists.tgz; repo tmp/ci-art-44922498549 (macOS golden-bound CI logs)
#   worktree tmp/: tmp/rca-bound and tmp/golden-jobs-* (debug worker scratch), tmp/wp1 (WSL run bundles)
#   .worktrees/worker-019-bound-peak and worker-019-t29c (landed into feat/019 by hand: worker.js land refused them over
#     ignored csharp bin files), with --remove-worktrees; their branches stay
#   in wp1's WSL: ~/claude-bundle, ~/.claude.json.bak-semble, ~/.claude.json.bak-trust, ~/semble-warm.log, with --remove-remote
# Kept on purpose: tmp/w2 (launcher scripts and cov logs the T29 note cites), tmp/llm-eval (T39 records), ~/bayan-runs in WSL
#   (session-2026-11-21.sh --remove-remote covers its checkouts).
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0; remote=0; worktrees=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --remove-remote) remote=1 ;;
    --remove-worktrees) worktrees=1 ;;
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
remove_scratch "$repo"/tmp/remote/claude-bundle "$repo"/tmp/remote/claude-bundle.tgz "$repo"/tmp/remote/writer.bundle \
  "$repo"/tmp/remote/branch.bundle "$repo"/tmp/remote/t29-tools.tgz "$repo"/tmp/remote/t29-lists.tgz \
  "$repo"/tmp/ci-art-44922498549 "$wt019"/tmp/rca-bound "$wt019"/tmp/golden-jobs-* "$wt019"/tmp/wp1

for w in "$repo/.worktrees/worker-019-bound-peak" "$repo/.worktrees/worker-019-t29c"; do
  if ! git -C "$repo" worktree list --porcelain | grep -qxF "worktree $w"; then printf 'skip:  %s not a worktree\n' "${w#"$repo"/}"
  elif [ $execute = 1 ] && [ $worktrees = 1 ]; then
    git -C "$repo" worktree remove --force "$w" && printf 'removed worktree %s\n' "${w#"$repo"/}" || failed=1
  else printf 'would remove worktree %s (needs --execute --remove-worktrees; its branch stays)\n' "${w#"$repo"/}"; fi
done

if [ $execute = 1 ] && [ $remote = 1 ]; then
  ssh wp1 "wsl -e bash -c 'rm -rf -- ~/claude-bundle ~/.claude.json.bak-semble ~/.claude.json.bak-trust ~/semble-warm.log && echo removed WSL scratch'" || failed=1
else
  printf 'would: in wp1 WSL remove ~/claude-bundle ~/.claude.json.bak-semble ~/.claude.json.bak-trust ~/semble-warm.log (needs --execute --remove-remote)\n'
fi

if [ $failed = 1 ]; then exit 1; fi
exit 0
