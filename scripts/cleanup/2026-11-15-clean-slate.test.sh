#!/usr/bin/env bash
# Tests 2026-11-15-clean-slate.sh in a fixture repo whose main checkout is on dev. Step 1: a detached worktree with a commit not
# on dev is refused, one with ignored scratch (tmp/) is refused unless --delete-worktree-scratch, one with only build output is
# removed. Step 2b: ignored old-layout build output is listed, removed only with --execute --delete-old-build-output; a directory
# with a file git does not ignore, or with ignored scratch, is refused.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
t="$root/tmp/clean-slate-test"; rm -rf "$t"; mkdir -p "$t"; cd "$t"
export GIT_ALLOW_PROTECTED=1  # fixture repo: its dev branch is the subject under test
git init -q -b dev && git config core.hooksPath /dev/null
mkdir -p src/driver src/Bayan.Cli/obj src/Bayan.Testing src/Bayan.Syntax/obj src/Bayan.Syntax/tmp && echo x > src/driver/a.byn
printf 'obj/\ntmp/\n.worktrees/\n' > .gitignore && git add . && git -c user.email=t@t -c user.name=t commit -qm base
echo o > src/Bayan.Cli/obj/a.dll; echo s > src/Bayan.Testing/stray.cs
echo o > src/Bayan.Syntax/obj/a.dll; echo n > src/Bayan.Syntax/tmp/notes.txt
git worktree add -q --detach .worktrees/base-dev
git -C .worktrees/base-dev -c user.email=t@t -c user.name=t commit -q --allow-empty -m 'not on dev'
git worktree add -q --detach .worktrees/fix-m1-relpath; mkdir -p .worktrees/fix-m1-relpath/tmp .worktrees/fix-m1-relpath/x/obj
echo n > .worktrees/fix-m1-relpath/tmp/notes.txt; echo o > .worktrees/fix-m1-relpath/x/obj/a.dll
git worktree add -q --detach .worktrees/cleanup-slate; mkdir -p .worktrees/cleanup-slate/x/obj; echo o > .worktrees/cleanup-slate/x/obj/a.dll
fail() { echo "FAIL $1"; exit 1; }
s="$root/scripts/cleanup/2026-11-15-clean-slate.sh"
out="$(bash "$s" 2>&1 || true)"
grep -q '^stale:  src/Bayan.Cli ' <<<"$out" || fail "dry run lists the ignored build output: $out"
grep -q '^refuse: src/Bayan.Testing holds files git does not ignore' <<<"$out" || fail "dry run refuses an unignored file: $out"
grep -q '^refuse: src/Bayan.Syntax holds ignored files that are not build output' <<<"$out" || fail "ignored scratch next to build output is refused: $out"
grep -q '^refuse: base-dev holds commits not on dev' <<<"$out" || fail "a detached worktree with commits not on dev is refused: $out"
grep -q '^refuse: fix-m1-relpath holds ignored files that are not build output (tmp/' <<<"$out" || fail "a worktree with ignored scratch is refused: $out"
grep -q '^would: git -C .* worktree remove .*/cleanup-slate$' <<<"$out" || fail "a worktree with only build output is removed: $out"
grep -q '^stale:  bayan-test01:/home/bt/ci ' <<<"$out" || fail "without --delete-vm-ci the VM clones are only listed: $out"
out="$(bash "$s" --delete-vm-ci 2>&1 || true)"
grep -q '^would: ssh ghosthive ' <<<"$out" || fail "a dry run with --delete-vm-ci prints the ssh, not runs it: $out"
bash "$s" -e > /dev/null 2>&1 || true
[ -f src/Bayan.Cli/obj/a.dll ] || fail "--execute alone removed build output"
bash "$s" -e --delete-old-build-output > /dev/null 2>&1 || true
[ ! -e src/Bayan.Cli ] || fail "--delete-old-build-output left src/Bayan.Cli"
[ -f src/Bayan.Testing/stray.cs ] || fail "an unignored file was removed"
[ -f src/driver/a.byn ] || fail "a tracked file was removed"
[ -f src/Bayan.Syntax/tmp/notes.txt ] || fail "ignored scratch was removed"
[ -d .worktrees/base-dev ] || fail "a detached worktree with commits not on dev was removed"
[ -f .worktrees/fix-m1-relpath/tmp/notes.txt ] || fail "a worktree with ignored scratch was removed without --delete-worktree-scratch"
[ ! -e .worktrees/cleanup-slate ] || fail "a worktree with only build output was left"
bash "$s" -e --delete-worktree-scratch > /dev/null 2>&1 || true
[ ! -e .worktrees/fix-m1-relpath ] || fail "--delete-worktree-scratch left the worktree"
echo ok
