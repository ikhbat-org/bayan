#!/usr/bin/env bash
# Tests 2026-11-14-history-rewrite.sh on throwaway repos under tmp/: the dry run changes nothing, the real run
# end to end (worktree branch left, its command printed, nothing pushed, the printed undo), and the refusals.
# Prints PASS or the failures.
set -u
HERE=$(cd "$(dirname "$0")" && pwd -P)
ROOT=$(cd "$HERE/../.." && pwd -P)
FX=$ROOT/tmp/history-rewrite-1114-test
export GIT_CEILING_DIRECTORIES=$ROOT/tmp
unset GIT_ALLOW_PROTECTED
fails=0
fail() { echo "FAIL: $*"; fails=$((fails + 1)); }
me() { GIT_AUTHOR_NAME=User GIT_AUTHOR_EMAIL=syed@beparey.com GIT_COMMITTER_NAME=User GIT_COMMITTER_EMAIL=syed@beparey.com "$@"; }
bot() { GIT_AUTHOR_NAME=Claude GIT_AUTHOR_EMAIL=noreply@anthropic.com GIT_COMMITTER_NAME=Claude GIT_COMMITTER_EMAIL=noreply@anthropic.com "$@"; }

# fixture: user commit, a Claude commit with a trailer, a doc citing it, tag v0.2.0, main, a branch in a linked
# worktree, the main checkout on an unchanged branch, a local bare origin with a branch the repository lacks
fresh() {
  rm -rf "$FX"; mkdir -p "$FX/repo/scripts/move" "$FX/repo/scripts/ci" "$FX/hooks"
  R=$FX/repo WT=$FX/wt
  git -C "$R" init -q -b dev; git -C "$R" config core.hooksPath "$FX/hooks"
  cp "$HERE/2026-11-14-history-rewrite.sh" "$R/scripts/move/"; cp "$ROOT/scripts/ci/check-authors.sh" "$R/scripts/ci/"
  printf 'tmp/\n' > "$R/.gitignore"; printf 'a\n' > "$R/a.txt"
  git -C "$R" add -A; me git -C "$R" commit -q -m "feat: first"
  git -C "$R" branch side
  printf 'b\n' > "$R/b.txt"; git -C "$R" add -A
  bot git -C "$R" commit -q -m "fix: by the bot" -m "Co-Authored-By: Claude Opus <noreply@anthropic.com>"
  BAD=$(git -C "$R" rev-parse --short=12 HEAD)
  git -C "$R" branch feat/wt
  mkdir -p "$R/docs"; printf 'See %s.\n' "$BAD" > "$R/docs/x.md"; git -C "$R" add -A; me git -C "$R" commit -q -m "docs: cite"
  git -C "$R" tag v0.2.0; git -C "$R" branch main
  git -C "$R" checkout -q side
  git -C "$R" worktree add -q "$WT" feat/wt
  git clone -q --bare "$R" "$FX/origin.git"; git -C "$FX/origin.git" branch remote-only dev
  git -C "$R" remote add origin "$FX/origin.git"; git -C "$R" fetch -q origin
  ORIGIN0=$(git -C "$FX/origin.git" for-each-ref)
  WTB0=$(git -C "$R" rev-parse feat/wt)
  TREES0=$(for r in dev main v0.2.0; do git -C "$R" rev-parse "$r^{tree}"; done)
}
state() { git -C "$R" for-each-ref; git -C "$R" config --list --local; git -C "$R" status --porcelain; git -C "$WT" status --porcelain; }
run() { OUT=$(cd "$R" && bash scripts/move/2026-11-14-history-rewrite.sh --backup "$FX/backup.git" "$@" 2>&1); RC=$?; }

# A. dry run: exit 0, nothing in the repository changes, no backup
fresh; S0=$(state); run
[ "$RC" -eq 0 ] || fail "dry run: exit $RC: $OUT"
[ "$(state)" = "$S0" ] || fail "dry run: the repository changed"
[ -e "$FX/backup.git" ] && fail "dry run: made a backup"
case "$OUT" in *"dry run: nothing changed"*) ;; *) fail "dry run: $OUT" ;; esac

# B. real run, the printed worktree command, then the printed undo
fresh; git -C "$R" config review.reviewedthrough "$(git -C "$R" rev-parse dev)"; S0=$(state)
GIT_ALLOW_PROTECTED=1 run --execute --rewrite-history
[ "$RC" -eq 0 ] || fail "real run: exit $RC: $OUT"
for r in $(git -C "$R" for-each-ref --format='%(refname)' refs/heads refs/tags); do
  [ "$r" = refs/heads/feat/wt ] && continue
  (cd "$R" && bash scripts/ci/check-authors.sh "$r" >/dev/null 2>&1) || fail "real run: check-authors fails on $r"
done
[ "$(for r in main v0.2.0; do git -C "$R" rev-parse "$r^{tree}"; done)" = "$(printf '%s\n' "$TREES0" | tail -2)" ] || fail "real run: a tree of main or v0.2.0 changed"
[ "$(git -C "$R" rev-parse dev^1^{tree})" = "$(printf '%s\n' "$TREES0" | head -1)" ] || fail "real run: dev's tree before the SHA-reference merge changed"
git -C "$R" log dev main v0.2.0 --format=%B | grep -q 'Co-Authored-By' && fail "real run: the trailer is still in a message"
NEWBAD=$(git -C "$R" log --format='%h' --abbrev=12 --grep='^fix: by the bot' main)
git -C "$R" show dev:docs/x.md | grep -q "$BAD" && fail "real run: docs/x.md still cites the old SHA"
git -C "$R" show dev:docs/x.md | grep -q "See $NEWBAD\." || fail "real run: docs/x.md does not cite the new SHA $NEWBAD"
[ "$(git -C "$R" config review.reviewedthrough)" = "$(git -C "$R" rev-parse main)" ] || fail "real run: review.reviewedthrough not mapped"
[ "$(git -C "$R" rev-parse feat/wt)" = "$WTB0" ] || fail "real run: the worktree branch was changed"
git -C "$R" rev-parse -q --verify refs/heads/remote-only >/dev/null && fail "real run: created the origin-only branch"
case "$OUT" in *"[ \"\$(git -C $WT rev-parse HEAD)\" = $WTB0 ] && git -C $WT reset -q --keep "*) ;; *) fail "real run: no worktree command: $OUT" ;; esac
case "$OUT" in *"reset --hard"*) fail "real run: prints a reset --hard" ;; esac
[ "$(git -C "$FX/origin.git" for-each-ref)" = "$ORIGIN0" ] || fail "real run: origin changed"
printf '%s\n' "$OUT" | grep -qE '^  GIT_ALLOW_PROTECTED=1 git -C .* push --force-with-lease=refs/heads/dev:[0-9a-f]{40} --force-with-lease=refs/heads/main:[0-9a-f]{40} --force-with-lease=refs/tags/v0.2.0:[0-9a-f]{40} .* dev main refs/tags/v0.2.0$' || fail "real run: no push line: $OUT"
case "$OUT" in *"option: git push origin --delete feat/wt"*) ;; *) fail "real run: no delete option: $OUT" ;; esac
CMD=$(printf '%s\n' "$OUT" | grep -F "git -C $WT reset" | sed 's/   # .*//')
printf 'dirty\n' >> "$WT/a.txt"
(eval "$CMD") >/dev/null 2>&1 || fail "worktree command: failed"
(cd "$WT" && bash scripts/ci/check-authors.sh HEAD >/dev/null 2>&1) || fail "worktree command: feat/wt not clean"
[ "$(git -C "$WT" status --porcelain)" = " M a.txt" ] || fail "worktree command: uncommitted change lost or index moved: $(git -C "$WT" status --porcelain)"
git -C "$WT" checkout -q -- a.txt
UNDO=$(printf '%s\n' "$OUT" | sed -n 's/^undo (before pushing): //p')
(cd "$R" && eval "$UNDO") >/dev/null 2>&1 || fail "undo: failed"
[ "$(state)" = "$S0" ] || fail "undo: the repository is not back"

# D. a worktree branch that moved after the run: its printed command refuses, the new commit stays
fresh; GIT_ALLOW_PROTECTED=1 run --execute --rewrite-history
CMD=$(printf '%s\n' "$OUT" | grep -F "git -C $WT reset" | sed 's/   # .*//')
printf 'c\n' > "$WT/c.txt"; git -C "$WT" add -A; me git -C "$WT" commit -q -m "feat: after the mirror"
MOVED=$(git -C "$WT" rev-parse HEAD)
[ -n "$CMD" ] || fail "moved worktree branch: no command printed"
(eval "$CMD") >/dev/null 2>&1 && fail "moved worktree branch: the command did not refuse"
[ "$(git -C "$R" rev-parse feat/wt)" = "$MOVED" ] || fail "moved worktree branch: the new commit is gone"

# C. one flag only: exit 2; an existing backup: exit 1
fresh; S0=$(state)
GIT_ALLOW_PROTECTED=1 run --execute; [ "$RC" -eq 2 ] || fail "--execute alone: exit $RC"
GIT_ALLOW_PROTECTED=1 run --rewrite-history; [ "$RC" -eq 2 ] || fail "--rewrite-history alone: exit $RC"
mkdir -p "$FX/backup.git"; GIT_ALLOW_PROTECTED=1 run --execute --rewrite-history
[ "$RC" -eq 1 ] || fail "existing backup: exit $RC"
case "$OUT" in *"backup $FX/backup.git exists"*) ;; *) fail "existing backup: $OUT" ;; esac
[ "$(state)" = "$S0" ] || fail "refusals: the repository changed"

rm -rf "$FX"
[ "$fails" -eq 0 ] && echo PASS || { echo "$fails failure(s)"; exit 1; }
