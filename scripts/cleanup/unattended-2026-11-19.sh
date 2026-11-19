#!/usr/bin/env bash
# Written 2026-11-19 by the unattended session on specs 019 (dotnet exit) and 025 (LLM eval set).
# Worktrees and branches merged into dev go to scripts/cleanup/merged-worktree-backlog.sh, which computes its targets
# at run time; this script runs it (same flags), then removes the session's scratch:
#   repo tmp/: reviewer scratch (tmp/rv-*), export staging (tmp/export-*), worker build output moved aside before a
#     land (tmp/*-build-out*), gate and break-test scratch, the stage-1 build the writers shared (tmp/bb)
#   worktree tmp/: the bundles sent to wp1 and wlt1 (tmp/wp1, tmp/wlt1), script-test leftovers, moved-aside caches
#   /tmp: the files this session's reviewers wrote outside the repo
#   zig caches: tmp/zig-global (28 GB on 2026-11-19) and ~/.cache/zig (6.1 GB), with --clear-zig-cache
#   on wp1 and wlt1: the <sha8>-sp checkouts and <sha8>.bundle files under the repo's tmp\, with --remove-remote
# Kept on purpose: tmp/w2 (launcher scripts, gate and run logs the handoff cites) and tmp/remote-019*.sh.
# Run it after the Windows golden runs have ended: --remove-remote deletes the checkout a running one uses.
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
repo=$(cd "$(git rev-parse --git-common-dir)/.." && pwd)
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
remove_scratch "$repo"/tmp/rv-* "$repo"/tmp/rv3-* "$repo"/tmp/export-* "$repo"/tmp/*-build-out* "$repo"/tmp/t19d-feat \
  "$repo"/tmp/bb "$repo"/tmp/gate-l025* "$repo"/tmp/gate-l023fix "$repo"/tmp/delx "$repo"/tmp/t31ba-ex1 "$repo"/tmp/t30ba-ex1 "$repo"/tmp/t30fa-ex1 \
  "$repo"/tmp/parity-csharp-bayan "$repo"/tmp/parity-csharp-bayan.log "$repo"/tmp/panic-probe \
  "$repo"/.worktrees/*/tmp/wp1 "$repo"/.worktrees/*/tmp/wlt1 "$repo"/.worktrees/*/tmp/bash32-parse-test \
  "$repo"/.worktrees/*/tmp/script-tests-test "$repo"/.worktrees/*/tmp/cache-moved-aside* \
  "$repo"/.worktrees/*/tmp/parity-csharp-bayan "$repo"/.worktrees/*/tmp/parity-csharp-bayan.log \
  "$repo"/.worktrees/*/tmp/t30e-* "$repo"/.worktrees/*/tmp/t30eb "$repo"/.worktrees/*/tmp/bb0 "$repo"/.worktrees/*/tmp/bootstrap

# 3. files this session's reviewers left outside the repo
for p in /tmp/019wg-changed.txt /tmp/t20-golden-commit-check.log /tmp/t20-inventory-check.log /tmp/t20rev.out /tmp/t31bc-gate.* \
  /tmp/x_m /tmp/x_c /tmp/icheck-fixed.sh /tmp/t30d-scratch.* /tmp/t30d-*.log /tmp/t30d-inv.out \
  /tmp/t30fb-cs.* /tmp/t30ea-inv-head.out /tmp/inv-head.txt /tmp/inv-base.txt; do
  [ -e "$p" ] || { printf 'skip:  %s gone\n' "$p"; continue; }
  if [ $execute = 1 ]; then rm -rf "$p"; printf 'removed %s\n' "$p"; else printf 'would remove %s\n' "$p"; fi
done

# 4. zig caches (the default one grew past 500 GB on mb1 before 2026-11-18)
for z in "$repo/tmp/zig-global" "$HOME/.cache/zig"; do
  if [ ! -e "$z" ]; then printf 'skip:  %s gone\n' "$z"
  elif [ $execute = 1 ] && [ $zig = 1 ]; then rm -rf "$z"; printf 'removed %s\n' "$z"
  else printf 'would remove %s (%s; needs --execute --clear-zig-cache)\n' "$z" "$(du -sh "$z" | cut -f1)"; fi
done

# 5. Windows checkouts and bundles on wp1 and wlt1 (names are <8 hex>-sp and <8 hex>.bundle only)
if [ $execute = 1 ] && [ $remote = 1 ]; then
  # the ssh shell on these hosts expands $_ inside -Command text; -EncodedCommand (UTF-16LE base64) passes it through
  ps='foreach ($d in "C:\home\code\extrode.com\bayan\tmp", "C:\home\code\ikhbat.org\bayan\tmp") { if (Test-Path $d) { Get-ChildItem $d | Where-Object { $_.Name -match "^[0-9a-f]{8}(-sp|\.bundle)$" } | ForEach-Object { Remove-Item -Recurse -Force $_.FullName; "removed " + $_.FullName } } }'
  for h in wp1 wlt1; do
    ssh "$h" "powershell -NoProfile -EncodedCommand $(printf '%s' "$ps" | iconv -f UTF-8 -t UTF-16LE | base64)" || failed=1
  done
else
  printf 'would: on wp1 and wlt1 remove <sha8>-sp and <sha8>.bundle under the repo tmp\\ (needs --execute --remove-remote)\n'
fi

printf 'left in tmp/: %s entries\n' "$(ls "$repo/tmp" | wc -l | tr -d ' ')"
if [ $failed = 1 ]; then exit 1; fi
exit 0
