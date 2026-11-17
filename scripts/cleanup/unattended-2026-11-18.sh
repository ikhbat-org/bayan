#!/usr/bin/env bash
# Written 2026-11-18 by the unattended session on specs 019 (dotnet exit) and 025 (LLM eval set).
# Worktrees and branches merged into dev go to scripts/cleanup/merged-worktree-backlog.sh, which computes its targets
# at run time; this script runs it (same flags), then removes the session's scratch:
#   repo tmp/: worker build output moved aside before land, the T24, T24b and T40 export and staging dirs,
#     the release-workflow test scratch (tmp/rwt.*),
#   025 T32 staging (tmp/025-t32) and the per-task export dirs (tmp/export-t1*, tmp/export-t2*)
#   ~/.cache/zig (broken 2026-11-18: libcompiler_rt.a FileNotFound), with --clear-zig-cache
#   on wp1: C:\tmp\t24* and C:\tmp\t40*, with --remove-remote
# Kept on purpose: tmp/export-parse and tmp/export-lex (T17 lands them). The per-task export dirs are count checks;
# T17 reruns the export, so run this script after T17 lands.
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0; remote=0; zig=0; pass=()
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1; pass+=("$a") ;;
    --delete-worktree-scratch) pass+=("$a") ;;
    --remove-remote) remote=1 ;;
    --clear-zig-cache) zig=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from a checkout on dev (here: %s).\n' "$(git branch --show-current)"; exit 1
fi
repo=$(git rev-parse --show-toplevel)
failed=0

# 1. merged worktrees and branches
bash "$(dirname "${BASH_SOURCE[0]}")/merged-worktree-backlog.sh" ${pass[@]+"${pass[@]}"} || failed=1

# 2. repo tmp/ scratch (globs expand at run time; tracked paths are refused)
shopt -s nullglob
for p in "$repo"/tmp/*-build-out* "$repo"/tmp/t24-win "$repo"/tmp/t24b-win "$repo"/tmp/export-t24b* \
         "$repo"/tmp/t12 "$repo"/tmp/t13 "$repo"/tmp/gate-export-* "$repo"/tmp/std-path-export \
         "$repo"/tmp/l005-run-batch-export "$repo"/tmp/zig-global \
         "$repo"/tmp/t40-linux "$repo"/tmp/t40-win "$repo"/tmp/rwt.* "$repo"/tmp/025-t32 "$repo"/tmp/export-t1* "$repo"/tmp/export-t2*; do
  rel=${p#"$repo"/}
  if git -C "$repo" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
    printf 'refuse: %s is tracked by git. Propose it as a commit instead. Left alone.\n' "$rel"; failed=1; continue
  fi
  [ -e "$p" ] || { printf 'skip:  %s gone\n' "$rel"; continue; }
  if [ $execute = 1 ]; then rm -rf "$p"; printf 'removed %s\n' "$rel"; else printf 'would remove %s (%s)\n' "$rel" "$(du -sh "$p" | cut -f1)"; fi
done

# 3. the broken zig global cache
z="$HOME/.cache/zig"
if [ ! -e "$z" ]; then printf 'skip:  %s gone\n' "$z"
elif [ $execute = 1 ] && [ $zig = 1 ]; then rm -rf "$z"; printf 'removed %s\n' "$z"
else printf 'would remove %s (%s; needs --execute --clear-zig-cache)\n' "$z" "$(du -sh "$z" | cut -f1)"; fi

# 4. Windows staging on wp1
if [ $execute = 1 ] && [ $remote = 1 ]; then
  # wp1's ssh shell expands $_ inside -Command text; -EncodedCommand (UTF-16LE base64) passes it through untouched
  ps='Get-ChildItem C:\tmp\* -Include t24*,t40* -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item -Recurse -Force $_.FullName; "removed " + $_.FullName }'
  ssh wp1 "powershell -NoProfile -EncodedCommand $(printf '%s' "$ps" | iconv -f UTF-8 -t UTF-16LE | base64)" || failed=1
else
  printf 'would: on wp1 remove C:\\tmp\\t24* and C:\\tmp\\t40* (needs --execute --remove-remote)\n'
fi

printf 'left in tmp/: %s\n' "$(ls "$repo/tmp" | wc -l | tr -d ' ') entries"
if [ $failed = 1 ]; then exit 1; fi
exit 0
