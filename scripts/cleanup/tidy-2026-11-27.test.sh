#!/usr/bin/env bash
# tidy-2026-11-27 on a fixture repo: a worktree whose branch another branch holds, or whose commits dev has under another
# id, goes only with -e --delete-worktree-scratch; one with commits nobody holds or with untracked files stays; an old big
# tmp/ entry goes only with -e --delete-tmp-scratch, while a recent, small, kept or tracked one stays; the dry run changes nothing.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
script="$root/scripts/cleanup/tidy-2026-11-27.sh"
r="$root/tmp/cleanup-tidy-1127-test"
rm -rf "$r" && mkdir -p "$r" && cd "$r"
export GIT_ALLOW_PROTECTED=1  # fixture repo: its dev branch is the subject under test
g() { git -c user.email=t@t -c user.name=t "$@"; }
git init -q -b dev && git config core.hooksPath /dev/null
printf 'tmp/*\n!tmp/tracked\n' > .gitignore && mkdir tmp && echo t > tmp/tracked && git add .gitignore tmp/tracked && g commit -q -m base
g switch -q -c inner && echo a > a && g add a && g commit -q -m inner
g switch -q -c outer && echo b > b && g add b && g commit -q -m outer
g switch -q -c picked dev && echo c > c && g add c && g commit -q -m picked
g switch -q -c lone dev && echo d > d && g add d && g commit -q -m lone
g switch -q -c dirty dev && echo e > e && g add e && g commit -q -m dirty
g switch -q dev && g cherry-pick picked >/dev/null
for b in inner picked lone dirty; do g worktree add -q ".worktrees/$b" "$b"; done
echo x > .worktrees/dirty/new.txt
mkdir tmp/oldbig tmp/newbig tmp/oldsmall tmp/zig-global
for d in oldbig newbig zig-global; do dd if=/dev/zero of="tmp/$d/f" bs=1024 count=2048 2>/dev/null; done
echo s > tmp/oldsmall/f
touch -t 202001010000 tmp/oldbig tmp/oldsmall tmp/zig-global tmp/tracked
export CONTAINED="inner outer
lone outer
dirty dirty" CHERRY_BRANCHES="picked lone" KEEP_TMP="zig-global" TMP_MIN_MB=1
fail() { echo "FAIL: $1"; echo "$out"; cd "$root"; exit 1; }

out="$(bash "$script")"
echo "$out" | grep -q "^would: git worktree remove .worktrees/inner (in outer)$" || fail "contained not listed"
echo "$out" | grep -q "^would: git worktree remove .worktrees/picked (every commit in dev)$" || fail "cherry-picked not listed"
echo "$out" | grep -q "^keep:  lone (not in outer)$" || fail "uncontained not kept"
echo "$out" | grep -q "^keep:  lone (commits dev lacks)$" || fail "unpicked not kept"
echo "$out" | grep -q "^keep:  .worktrees/dirty (modified or untracked files)$" || fail "dirty not kept"
echo "$out" | grep -q "^would: rm -rf tmp/oldbig (2 MB)$" || fail "old big tmp not listed"
echo "$out" | grep -q "^keep:  tmp/zig-global (KEEP_TMP)$" || fail "kept tmp not kept"
echo "$out" | grep -q "^refuse: tmp/tracked is tracked by git" || fail "tracked tmp not refused"
echo "$out" | grep -qE "newbig|oldsmall" && fail "recent or small tmp listed"
[ "$(git worktree list | wc -l | tr -d ' ')" = 5 ] && [ -d tmp/oldbig ] || fail "dry run changed something"

out="$(bash "$script" -e || true)"
[ -d .worktrees/inner ] && [ -d tmp/oldbig ] || fail "-e alone removed scratch"

out="$(bash "$script" -e --delete-worktree-scratch --delete-tmp-scratch || true)"
[ ! -d .worktrees/inner ] && [ ! -d .worktrees/picked ] || fail "held worktrees not removed"
[ -d .worktrees/lone ] && [ -d .worktrees/dirty ] || fail "kept worktrees removed"
[ ! -d tmp/oldbig ] && [ -d tmp/newbig ] && [ -d tmp/oldsmall ] && [ -d tmp/zig-global ] && [ -f tmp/tracked ] || fail "tmp removal wrong"
git rev-parse -q --verify refs/heads/inner >/dev/null || fail "a branch was deleted"

out="$(bash "$script" -e --delete-worktree-scratch --delete-tmp-scratch || true)"
echo "$out" | grep -q "^skip:  inner has no worktree$" || fail "second run not a no-op"

cd "$root" && rm -rf "$r"
echo "tidy-2026-11-27: PASS"
