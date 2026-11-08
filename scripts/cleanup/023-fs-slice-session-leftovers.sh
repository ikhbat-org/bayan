#!/usr/bin/env bash
# Cleanup for the 2026-11-08/09 session (fs slice → dev, 017 T20 → dev, review fixes 2026-11-08-1..4, plan 007 prep),
# written 2026-11-09 by the agent that ran it unattended; never run by that agent.
# 1. worker keys landed by hand (land refused over ignored build output): the worktree is removed here under section 2's
#    rules, then `worker.js retire` drops the key (it would forget a key whose worktree it keeps, and exits 0 either way).
#    The branch stays for 019-merged-branches.sh.
# 2. plain worktrees of this session's branches, and two detached check-outs under tmp/: `git worktree remove`, then
#    `git branch -d`.
# 3. untracked scratch: tmp/zig-dl (the zig 0.17.0 download) and a gate checker's mktemp dir, only when this user owns
#    it. tmp/sanitizer-debug is kept: it holds the fixtures of the open ToolchainSanitizer flake (work/todo.md).
# Every item is checked at run time: a target that is gone prints `skip`; a branch not in dev, a dirty worktree or a
# tracked path is kept. merged-worktree-backlog.sh covers the same worktrees once they are 24 h old; this one does not
# wait.
# Dry run by default. --execute / -e acts. Section 3 and worktrees holding ignored files beyond build output also need
# --delete-scratch.
set -euo pipefail

execute=0; scratch=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-scratch) scratch=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
here="$(git rev-parse --show-toplevel)"
repo="$(git rev-parse --path-format=absolute --git-common-dir)"; repo="${repo%/.git}"  # the main checkout: targets are relative to it
worker="${CLEANUP_WORKER_JS:-$HOME/.claude/tools/worker.js}"
failed=0

if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from a checkout of dev (on %s).\n' "$(git branch --show-current)"; exit 1
fi
cd "$repo"

tracked() { git ls-files --error-unmatch -- "$1" >/dev/null 2>&1; }
in_dev() { git merge-base --is-ancestor "$1" refs/heads/dev 2>/dev/null; }

printf '== 1. worker keys landed by hand\n'
for key in diag-examples 012-anchors review-c1dae2fc-fix review-fix-r2 json-i64 015-t7 test-time-scale q1100 \
           l017-unicode-case w0-d6-plan l017-fatarrow review-tts-fix; do
  br="chore/worker-$key"; wt=".worktrees/worker-$key"
  if ! git show-ref -q --verify "refs/heads/$br" && [ ! -d "$wt" ]; then printf 'skip:  %s (no branch, no worktree)\n' "$key"; continue; fi
  if git show-ref -q --verify "refs/heads/$br" && ! in_dev "refs/heads/$br"; then
    printf 'keep:  %s (%s not in dev)\n' "$key" "$br"; continue
  fi
  if [ -d "$wt" ] && [ -n "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
    printf 'keep:  %s (modified or untracked files in %s)\n' "$key" "$wt"; continue
  fi
  if [ -d "$wt" ]; then
    if [ "$(git -C "$wt" branch --show-current 2>/dev/null)" != "$br" ]; then printf 'keep:  %s (%s not on %s)\n' "$key" "$wt" "$br"; continue; fi
    other="$(git -C "$wt" status --porcelain --ignored | sed -n 's/^!! //p' \
      | grep -Ev '(^|/)(bin|obj|TestResults|__pycache__)/$|(^|/)\.DS_Store$' || true)"
    if [ -n "$other" ] && [ $scratch -eq 0 ]; then
      printf 'hold:  %s (ignored files beyond build output in %s: %s; needs --delete-scratch)\n' \
        "$key" "$wt" "$(printf '%s\n' "$other" | head -3 | tr '\n' ' ')"; continue
    fi
  fi
  if [ $execute -eq 0 ]; then
    [ -d "$wt" ] && printf 'would: git worktree remove %s\n' "$wt"
    printf 'would: worker.js retire %s\n' "$key"; continue
  fi
  if [ -d "$wt" ] && ! git worktree remove "$wt"; then printf '  refused: %s. Key %s kept.\n' "$wt" "$key"; failed=1; continue; fi
  deno run -A "$worker" retire "$key"
  if [ -d "$wt" ]; then printf '  refused: %s is still there.\n' "$wt"; failed=1; fi
done

printf '\n== 2. worktrees of merged branches\n'
while read -r rel br; do
  if [ ! -d "$rel" ]; then printf 'skip:  %s is gone\n' "$rel"; continue; fi
  if [ "$repo/$rel" = "$here" ]; then printf 'keep:  %s (this script runs from it)\n' "$rel"; continue; fi
  if tracked "$rel"; then printf 'refuse: %s is tracked by git. Propose it as a commit instead. Left alone.\n' "$rel"; failed=1; continue; fi
  if [ "$br" = "-" ]; then tip="$(git -C "$rel" rev-parse HEAD 2>/dev/null || true)"; else tip="refs/heads/$br"; fi
  if [ -z "$tip" ] || ! in_dev "$tip"; then printf 'keep:  %s (%s not in dev)\n' "$rel" "$br"; continue; fi
  if [ "$br" != "-" ] && [ "$(git -C "$rel" branch --show-current)" != "$br" ]; then
    printf 'keep:  %s (not on %s any more)\n' "$rel" "$br"; continue
  fi
  if [ -n "$(git -C "$rel" status --porcelain)" ]; then printf 'keep:  %s (modified or untracked files)\n' "$rel"; continue; fi
  if [ -n "$(git worktree list --porcelain | sed -n 's/^worktree //p' | grep -F "$repo/$rel/" || true)" ]; then
    printf 'keep:  %s (holds a nested worktree)\n' "$rel"; continue
  fi
  other="$(git -C "$rel" status --porcelain --ignored | sed -n 's/^!! //p' \
    | grep -Ev '(^|/)(bin|obj|TestResults|__pycache__)/$|(^|/)\.DS_Store$' || true)"
  if [ -n "$other" ] && [ $scratch -eq 0 ]; then
    printf 'hold:  %s (ignored files beyond build output: %s; needs --delete-scratch)\n' \
      "$rel" "$(printf '%s\n' "$other" | head -3 | tr '\n' ' ')"; continue
  fi
  if [ $execute -eq 0 ]; then
    printf 'would: git worktree remove %s\n' "$rel"
    case "$br" in -|dev) ;; *) printf 'would: git branch -d %s\n' "$br" ;; esac
    continue
  fi
  if ! git worktree remove "$rel"; then printf '  refused: %s. Left alone.\n' "$rel"; failed=1; continue; fi
  printf 'removed: %s\n' "$rel"
  # git branch -d checks merged-ness against HEAD, so it runs in the dev checkout, not the main one.
  case "$br" in -|dev) ;; *) git -C "$here" branch -d "$br" || { printf '  refused: branch %s. Left alone.\n' "$br"; failed=1; } ;; esac
done <<'EOF'
.worktrees/docs-diagnostics-examples docs/diagnostics-examples
.worktrees/docs-w0-d6-plan docs/w0-d6-plan
.worktrees/fix-l017-for-missing-name fix/l017-for-missing-name
.worktrees/fix-l017-unicode-case fix/l017-unicode-case
.worktrees/fix-review-2026-11-08-1 fix/review-2026-11-08-1
.worktrees/fix-review-2026-11-08-2 fix/review-2026-11-08-2
.worktrees/fix-review-2026-11-08-3 fix/review-2026-11-08-3
.worktrees/fix-review-2026-11-08-4 fix/review-2026-11-08-4
.worktrees/fix-zig-pin-message fix/zig-pin-message
.worktrees/017-into-dev chore/017-t20-into-dev
.worktrees/dev-merge dev
tmp/wt-ab3ec002 -
tmp/wt-acba -
EOF

printf '\n== 3. untracked scratch\n'
gate_tmp="${TMPDIR:-/nonexistent}/tmp.qhKsq0vwnC"; gate_tmp="${gate_tmp//\/\//\/}"
for p in tmp/zig-dl "$gate_tmp"; do
  if [ ! -e "$p" ]; then printf 'skip:  %s is gone\n' "$p"; continue; fi
  if [ ! -O "$p" ]; then printf 'keep:  %s (not owned by %s)\n' "$p" "$(id -un)"; continue; fi
  if tracked "$p"; then printf 'refuse: %s is tracked by git. Propose it as a commit instead. Left alone.\n' "$p"; failed=1; continue; fi
  if [ $scratch -eq 0 ] || [ $execute -eq 0 ]; then printf 'would (with --execute --delete-scratch): rm -rf %s\n' "$p"; continue; fi
  rm -rf -- "$p" && printf 'removed: %s\n' "$p" || { printf '  refused: %s. Left alone.\n' "$p"; failed=1; }
done

if [ $execute -eq 1 ]; then git worktree prune; else printf '\nwould: git worktree prune\n'; fi
printf '\nremaining: %s worktrees, %s chore/worker-* branches\n' \
  "$(git worktree list | wc -l | tr -d ' ')" "$(git branch --list 'chore/worker-*' | wc -l | tr -d ' ')"
if [ $execute -eq 1 ] && [ $failed -eq 1 ]; then exit 1; fi
exit 0
