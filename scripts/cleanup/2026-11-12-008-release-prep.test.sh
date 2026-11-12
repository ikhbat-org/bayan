#!/usr/bin/env bash
# 2026-11-12-008-release-prep on a fixture repo whose main checkout has another branch out (as on 2026-11-13):
# a branch in dev goes, judged in the dev worktree; one not in dev stays; without a dev worktree nothing goes.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
script="$root/scripts/cleanup/2026-11-12-008-release-prep.sh"
r="$root/tmp/cleanup-008-test"
rm -rf "$r" && mkdir -p "$r/repo" && cd "$r/repo"
export GIT_ALLOW_PROTECTED=1  # fixture repo: its dev branch is the subject under test
g() { git -c user.email=t@t -c user.name=t "$@"; }
git init -q -b main && git config core.hooksPath /dev/null
printf '.worktrees/\n' > .gitignore && git add .gitignore && g commit -q -m base && g branch dev
g switch -q -c chore/worker-008-w1 && g commit -q --allow-empty -m w1
g switch -q dev && g merge -q --no-ff chore/worker-008-w1 -m m1
g switch -q -c chore/worker-008-w2 && g commit -q --allow-empty -m w2
g switch -q -c feat/011-other main
fail=0
check() { if eval "$2"; then printf 'ok:   %s\n' "$1"; else printf 'FAIL: %s\n' "$1"; fail=1; fi; }
has() { git show-ref --verify --quiet "refs/heads/$1"; }

out=$(bash "$script" -e 2>&1 || true)
check "no dev worktree: w1 kept" 'has chore/worker-008-w1'
check "no dev worktree: reported" 'grep -q "keep: chore/worker-008-w1 (no worktree has dev checked out)" <<< "$out"'

g worktree add -q .worktrees/dev-merge dev
out=$(bash "$script" 2>&1)
check "dry run changes nothing" 'has chore/worker-008-w1'
out=$(bash "$script" -e 2>&1 || true)
check "w1 (in dev) removed while main has feat/011-other out" '! has chore/worker-008-w1'
check "w2 (not in dev) kept" 'has chore/worker-008-w2'
check "w2 reported" 'grep -q "keep: chore/worker-008-w2 (missing or not in dev)" <<< "$out"'
check "main checkout still on feat/011-other" '[ "$(git branch --show-current)" = feat/011-other ]'
exit $fail
