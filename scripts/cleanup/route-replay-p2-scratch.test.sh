#!/usr/bin/env bash
# route-replay-p2-scratch on a fixture repo: the dry run changes nothing and exits 0; a process working inside the scratch
# or matching the replay pattern refuses the run (exit 0 dry, 1 with -e); a failed rm and a failed backlog run exit 1
# with -e; a missing lsof refuses; only exact session worktree names are listed; deletion needs both flags; a second run after success skips.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
r="$root/tmp/cleanup-rrp2-test"
[ -d "$r" ] && chmod -R u+w "$r"
rm -rf "$r" && mkdir -p "$r" && cd "$r"
export GIT_ALLOW_PROTECTED=1  # fixture repo: its dev branch is the subject under test
export CLEANUP_REPLAY_PATTERN='no-such-process-cleanup-rrp2-xyz'
sp=''
trap '[ -n "$sp" ] && kill "$sp" 2>/dev/null; true' EXIT
git init -q -b dev && git config core.hooksPath /dev/null
mkdir -p scripts/cleanup && cp "$root/scripts/cleanup/route-replay-p2-scratch.sh" scripts/cleanup/
cat > scripts/cleanup/merged-worktree-backlog.sh <<'EOF'
#!/usr/bin/env bash
[ -n "${STUB_BACKLOG_FAIL:-}" ] && { echo "stub: git broke"; exit 3; }
printf 'keep:  .worktrees/worker-q1190-b (x)\nwould: git worktree remove .worktrees/worker-q1190\nwould: git branch -d chore/worker-q1190\n'
EOF
printf 'tmp/\n' > .gitignore && git add . && git -c user.email=t@t -c user.name=t commit -q -m base
mkdir -p tmp/route-replay/p2/a && echo x > tmp/route-replay/p2/a/f
s="scripts/cleanup/route-replay-p2-scratch.sh"
fail() { echo "FAIL: $1"; echo "$out"; cd "$root"; exit 1; }
run() { set +e; out="$(bash "$s" "$@" 2>&1)"; rc=$?; set -e; }

run
[ "$rc" = 0 ] || fail "dry run exit $rc"
echo "$out" | grep -q '^would remove tmp/route-replay' || fail "scratch not listed"
[ -e tmp/route-replay/p2/a/f ] || fail "dry run deleted the scratch"
echo "$out" | grep -q '^would: git worktree remove .worktrees/worker-q1190$' || fail "session worktree not listed"
echo "$out" | grep -q 'worker-q1190-b' && fail "a longer worktree name matched"

(cd tmp/route-replay/p2/a && exec sleep 60) & sp=$!
sleep 1
run; [ "$rc" = 0 ] && echo "$out" | grep -q "^refuse: processes are using the replay scratch (pids .*$sp" || { kill "$sp"; fail "cwd gate (dry)"; }
run -e --delete-replay-scratch; [ "$rc" = 1 ] && [ -e tmp/route-replay/p2/a/f ] || { kill "$sp"; fail "cwd gate (-e)"; }
kill "$sp"; wait "$sp" 2>/dev/null || true; sp=''

(exec -a cleanup-rrp2-fake-replay sleep 60) & sp=$!
sleep 1
CLEANUP_REPLAY_PATTERN='cleanup-rrp2-fake-replay' run -e --delete-replay-scratch
kill "$sp"; wait "$sp" 2>/dev/null || true; sp=''
[ "$rc" = 1 ] && [ -e tmp/route-replay/p2/a/f ] || fail "replay-process gate"

PATH=/nonexistent:$(dirname "$(command -v git)"):/bin run -e --delete-replay-scratch
[ "$rc" = 1 ] && echo "$out" | grep -q '^refuse: lsof is not on PATH' && [ -e tmp/route-replay/p2/a/f ] || fail "lsof missing not refused"

STUB_BACKLOG_FAIL=1 run -e
[ "$rc" = 1 ] && echo "$out" | grep -q '^failed: merged-worktree-backlog.sh' || fail "backlog failure not reported"
echo "$out" | grep -q "none of this session" && fail "backlog failure read as nothing to clean"

run -e
[ "$rc" = 0 ] && echo "$out" | grep -q 'held: deleting it also needs --delete-replay-scratch' && [ -e tmp/route-replay/p2/a/f ] || fail "-e alone deleted or failed"

chmod 555 tmp/route-replay/p2/a
run -e --delete-replay-scratch
chmod 755 tmp/route-replay/p2/a
[ "$rc" = 1 ] && echo "$out" | grep -q '^failed: rm -rf tmp/route-replay' || fail "a failed rm exited $rc"

run -e --delete-replay-scratch
[ "$rc" = 0 ] && [ ! -e tmp/route-replay ] && echo "$out" | grep -q '^tmp/route-replay gone$' || fail "delete"
run -e --delete-replay-scratch
[ "$rc" = 0 ] && echo "$out" | grep -q '^skip:  tmp/route-replay no longer exists' || fail "second run after success"

git switch -q -c other
run -e; [ "$rc" = 1 ] && echo "$out" | grep -q '^refuse: check out dev' || fail "branch gate"

cd "$root" && rm -rf "$r"
echo PASS
