#!/usr/bin/env bash
# Written 2026-11-25 by the unattended session after the 0.4.0 release: CI fixes, the 0.4.0 audit, the raw-string,
# getter and fail-narrows fixes, and the dev split (dev rebuilt so golden-commit-check passes; old tip dev-before-split).
# Sections:
#   1. worktrees under .worktrees/ this session made; each is removed only when its HEAD is in dev, or (for the
#      branches the split superseded) when the split copy is in dev; audit-040 waits until chunks 17 and 18 have
#      verdicts. A worktree holding ignored files (tmp/ builds) is kept unless --delete-worktree-scratch.
#   2. branches merged into dev: git branch -d.
#   3. branches the split superseded (their commits are in dev only as split copies, so -d refuses them): archived to
#      refs/archive/<name> and deleted at the recorded sha, only with --delete-superseded-branches, and only once
#      origin/dev holds local dev (the owner pushed the split).
# Dry run by default. --execute / -e acts.
set -euo pipefail

execute=0; scratch=0; superseded=0
for a in "$@"; do
  case "$a" in
    --execute|-e) execute=1 ;;
    --delete-worktree-scratch) scratch=1 ;;
    --delete-superseded-branches) superseded=1 ;;
    *) printf 'unknown flag: %s\n' "$a"; exit 2 ;;
  esac
done
if [ "$(git branch --show-current)" != "dev" ]; then
  printf 'refuse: run from a checkout on dev (here: %s).\n' "$(git branch --show-current)"; exit 1
fi
repo=$(cd "$(git rev-parse --git-common-dir)/.." && pwd)
failed=0

# in_dev REF: the commit is reachable from dev.
in_dev() { git merge-base --is-ancestor "$1" dev 2>/dev/null; }

# 1. worktrees: "dir branch-whose-copy-must-be-in-dev"
audit_done=1
for c in 17-docs-vs-impl 18-tests-laws; do
  grep -q '^## Verdicts' "$repo/tmp/audit-0.4.0/$c.verify.md" 2>/dev/null || audit_done=0
done
while read -r dir need; do
  wt="$repo/.worktrees/$dir"
  [ -d "$wt" ] || { printf 'skip:  worktree %s gone\n' "$dir"; continue; }
  if [ "$dir" = audit-040 ] && [ $audit_done = 0 ]; then
    printf 'keep:  worktree audit-040 (audit chunks 17/18 have no verdicts yet)\n'; continue
  fi
  head=$(git -C "$wt" rev-parse HEAD)
  if ! in_dev "$head" && ! in_dev "$need"; then
    printf 'keep:  worktree %s (HEAD %s and %s not in dev)\n' "$dir" "${head:0:9}" "$need"; failed=1; continue
  fi
  if [ -n "$(git -C "$wt" status --porcelain)" ]; then
    printf 'keep:  worktree %s is dirty\n' "$dir"; failed=1; continue
  fi
  ignored=$(git -C "$wt" status --porcelain --ignored | grep -c '^!!' || true)
  if [ "$ignored" -gt 0 ] && [ $scratch = 0 ]; then
    printf 'keep:  worktree %s holds %s ignored path(s) (%s); --delete-worktree-scratch removes them\n' \
      "$dir" "$ignored" "$(du -sh "$wt" | cut -f1)"; continue
  fi
  if [ $execute = 1 ]; then
    if [ "$ignored" -gt 0 ]; then git worktree remove --force "$wt"; else git worktree remove "$wt"; fi
    printf 'removed worktree %s\n' "$dir"
  else
    printf 'would remove worktree %s (%s)\n' "$dir" "$(du -sh "$wt" | cut -f1)"
  fi
done <<'EOF'
llm-base fix/llm-eval-base-fixture
ci-slow fix/ci-slow-script-tests
next-dev-041 chore/next-dev-0.4.1
review5 fix/review-2026-11-24-5
raw-fix fix/raw-string-closing-line-split
getter-fix fix/getter-name-clash-panic-split
fail-narrow fix/fail-narrows-split
audit-report docs/audit-0.4.0-report-split
split-dev dev-split
audit-040 v0.4.0
EOF
[ $execute = 1 ] && git worktree prune

# 2. merged branches
for b in fix/llm-eval-base-fixture fix/ci-slow-script-tests chore/next-dev-0.4.1 fix/review-2026-11-24-5 \
  fix/raw-string-closing-line-split fix/getter-name-clash-panic-split fix/fail-narrows-split \
  docs/audit-0.4.0-report-split docs/audit-snapshot-line dev-split; do
  if ! git rev-parse --verify --quiet "refs/heads/$b" >/dev/null; then printf 'skip:  branch %s gone\n' "$b"; continue; fi
  if [ $execute = 1 ]; then
    git branch -d "$b" || { printf '  refused: %s not merged. Left alone.\n' "$b"; failed=1; }
  else
    printf 'would git branch -d %s\n' "$b"
  fi
done

# 3. superseded by the split: "branch sha-recorded-2026-11-25"
pushed=0
git rev-parse --verify --quiet origin/dev >/dev/null && git merge-base --is-ancestor dev origin/dev && pushed=1
while read -r b sha; do
  cur=$(git rev-parse --verify --quiet "refs/heads/$b" || true)
  [ -n "$cur" ] || { printf 'skip:  branch %s gone\n' "$b"; continue; }
  if [ "$cur" != "$(git rev-parse "$sha")" ]; then printf 'keep:  %s moved since 2026-11-25 (now %s)\n' "$b" "${cur:0:9}"; failed=1; continue; fi
  if [ $superseded = 0 ] || [ $execute = 0 ]; then
    printf 'would archive refs/archive/%s and delete %s at %s (needs -e --delete-superseded-branches)\n' "$b" "$b" "$sha"; continue
  fi
  if [ $pushed = 0 ]; then printf 'refuse: origin/dev does not hold dev yet; push dev first. %s left alone.\n' "$b"; failed=1; continue; fi
  if git rev-parse --verify --quiet "refs/archive/$b" >/dev/null; then
    printf 'keep:  refs/archive/%s already exists; not overwritten. %s left alone.\n' "$b" "$b"; failed=1; continue
  fi
  git update-ref "refs/archive/$b" "$cur" ""
  git update-ref -d "refs/heads/$b" "$cur"
  printf 'archived + deleted %s\n' "$b"
done <<'EOF'
fix/raw-string-closing-line d848812c8
fix/getter-name-clash-panic 71a025f28
fix/fail-narrows 06e39ff01
docs/audit-0.4.0-report 48c73d9d1
docs/audit-0.4.0-report-pipes c0b1ff3c9
dev-before-split 89945f6bb
EOF

echo "remaining:"
git worktree list | grep -E '/\.worktrees/(llm-base|ci-slow|next-dev-041|review5|raw-fix|getter-fix|fail-narrow|audit-report|split-dev|audit-040) ' || echo "  no session worktrees"
if [ $execute = 1 ] && [ $failed = 1 ]; then exit 1; fi
exit 0
