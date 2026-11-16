#!/usr/bin/env bash
# Second history rewrite (user decision 2026-11-14): CI `authors` fails on dev because 18 commits made on
# 2026-11-03, after the first rewrite, have author/committer `Claude <noreply@anthropic.com>` and 3 of them a
# Co-Authored-By trailer naming Claude. They are reachable from dev, main, tag v0.2.0 and three merged remote
# branches. This maps that identity to the user's (author and committer) and drops every message line that
# check-authors.sh's msg_re matches. File contents are not changed, so every tree SHA stays the same.
#
#   2026-11-14-history-rewrite.sh [--backup <dir>]                                 rehearse (dry run)
#   GIT_ALLOW_PROTECTED=1 2026-11-14-history-rewrite.sh [--backup <dir>] --execute --rewrite-history
#
# Both modes work under tmp/history-rewrite-1114/: mirror the repository to trial.git, rewrite the mirror,
# verify it (check-authors clean on every branch and tag, same commit count, same trees for dev, main and
# every tag), clone it non-bare to clone/ and there rewrite old SHAs cited in dev's tracked .md files as one
# commit on chore/history-sha-refs-1114 merged --no-ff into dev. The dry run changes nothing outside tmp/.
# The real run (both flags) first mirrors the repository to --backup (default
# ~/Developer/backups/bayan-pre-rewrite-2026-11-14.git; refuses if it exists), then fetches the rewritten
# objects and moves, by compare-and-swap (a ref moved since the mirror is skipped), each rewritten branch not
# checked out in any worktree and every tag, maps refs/review/reviewed and review.reviewedthrough, and prints
# a guarded reset --keep per checked-out branch, the push commands (--force-with-lease) and the undo, which covers
# every ref it moved or printed. Branches that exist only on origin are not created. It pushes nothing.
# Exit 0 done, 1 refused or a check failed (nothing changed in the repository), 2 usage, 3 failed after the
# repository's refs began to change (run the printed undo).
set -u
HERE=$(cd "$(dirname "$0")" && pwd -P)
REPO=$(cd "$HERE/../.." && pwd -P)
BACKUP=$HOME/Developer/backups/bayan-pre-rewrite-2026-11-14.git EXEC=0 REWRITE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --backup) BACKUP=${2:-}; shift 2 ;;
    --execute) EXEC=1; shift ;;
    --rewrite-history) REWRITE=1; shift ;;
    *) echo "usage: $0 [--backup <dir>] [--execute --rewrite-history]" >&2; exit 2 ;;
  esac
done
[ -n "$BACKUP" ] || { echo "usage: --backup needs a directory" >&2; exit 2; }
if [ "$EXEC" -ne "$REWRITE" ]; then echo "refuse: the real run needs both --execute and --rewrite-history" >&2; exit 2; fi
WORK=$REPO/tmp/history-rewrite-1114
TRIAL=$WORK/trial.git
CLONE=$WORK/clone
MAILMAP=$WORK/mailmap
CHECK=$REPO/scripts/ci/check-authors.sh
SHAB=chore/history-sha-refs-1114
bad=0
say() { printf '%s\n' "$*"; }
refuse() { say "refuse: $*"; bad=1; }

# ---- preflight (both modes) -----------------------------------------------------------------
git filter-repo --version >/dev/null 2>&1 || refuse "git filter-repo not found (brew install git-filter-repo)"
[ -f "$CHECK" ] || refuse "missing $CHECK"
cd "$REPO" || exit 1
git rev-parse -q --verify refs/heads/dev >/dev/null || refuse "no dev branch"
git rev-parse -q --verify "refs/heads/$SHAB" >/dev/null && refuse "branch $SHAB exists"
if [ "$EXEC" -eq 1 ] && [ -e "$BACKUP" ]; then refuse "backup $BACKUP exists"; fi
if [ "$EXEC" -eq 1 ] && [ "${GIT_ALLOW_PROTECTED:-}" != 1 ]; then refuse "the protected-branch hooks refuse rewriting dev/main: run with GIT_ALLOW_PROTECTED=1"; fi
ORIGIN=$(git remote get-url origin 2>/dev/null || echo '<origin>')
[ "$bad" -eq 0 ] || { say "preflight failed: nothing changed"; exit 1; }

mkdir -p "$WORK"
ME="$(git log -1 --format='%an <%ae>' --author=syed@beparey.com dev)"
[ -n "$ME" ] || { say "refuse: no commit by the user on dev to take the identity from"; exit 1; }
printf '%s Claude <noreply@anthropic.com>\n' "$ME" > "$MAILMAP"
# drops each message line check-authors.sh's msg_re matches, then trailing blank lines
CALLBACK='
import re
pat = re.compile(rb"^.*(?:Co-[Aa]uthored-[Bb]y:.*(?:[Cc]laude|[Aa]nthropic)|Generated (?:with|by) .*Claude|\xf0\x9f\xa4\x96).*(?:\n|$)", re.M)
out = pat.sub(b"", message)
return out.rstrip() + b"\n" if out != message else message
'
FILTER=(--mailmap "$MAILMAP" --message-callback "$CALLBACK")

# trees <gitdir>: "<ref> <tree>" for dev, main and every tag
trees() {
  local g=$1 r
  for r in refs/heads/dev refs/heads/main $(git --git-dir="$g" for-each-ref --format='%(refname)' refs/tags); do
    git --git-dir="$g" rev-parse -q --verify "$r^{tree}" >/dev/null && printf '%s %s\n' "$r" "$(git --git-dir="$g" rev-parse "$r^{tree}")"
  done
}

# verify <gitdir>: check-authors clean on every branch and tag
verify() {
  local g=$1 fails=0 r out
  for r in $(git --git-dir="$g" for-each-ref --format='%(refname)' refs/heads refs/tags); do
    out=$(GIT_DIR=$g bash "$CHECK" "$r" 2>&1) || { say "fail: $r: ${out##*$'\n'}"; fails=1; }
  done
  return $fails
}

# remap <commit-map> <file>...: old SHAs (7-40 hex, with a letter or 10+ long, one unique old commit) -> new, same length
remap() {
  local map=$1; shift
  awk -v MAP="$map" '
    BEGIN {
      while ((getline l < MAP) > 0) { split(l, a, " "); if (a[1] !~ /^[0-9a-f]+$/ || a[1] == a[2]) continue
        n++; old[n] = a[1]; new[a[1]] = a[2]; for (k = 7; k <= 12; k++) { p = substr(a[1], 1, k); cnt[p]++; who[p] = a[1] } }
    }
    function sub1(t,   p, o, i, hit, m) {
      if (length(t) < 7 || length(t) > 40) return t
      if (t !~ /[a-f]/ && length(t) < 10) return t
      if (length(t) <= 12) { if (cnt[t] == 1) { changed++; return substr(new[who[t]], 1, length(t)) } return t }
      p = substr(t, 1, 12); if (!(p in cnt)) return t
      m = 0; for (i = 1; i <= n; i++) if (index(old[i], t) == 1) { m++; hit = old[i] }
      if (m == 1) { changed++; return substr(new[hit], 1, length(t)) }
      return t
    }
    # a file is written (as FILENAME.remap) only when a reference in it changed, so nothing else moves
    function flush(   i, out) {
      if (file == "" || fchanged == changed) return
      out = file ".remap"; for (i = 1; i <= nl; i++) print buf[i] > out; close(out)
    }
    FNR == 1 { flush(); file = FILENAME; fchanged = changed; nl = 0 }
    {
      line = $0; res = ""
      while (match(line, /[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]*/)) {
        tok = substr(line, RSTART, RLENGTH)
        res = res substr(line, 1, RSTART - 1) (tok ~ /[A-F]/ ? tok : sub1(tok))
        line = substr(line, RSTART + RLENGTH)
      }
      buf[++nl] = res line
    }
    END { flush(); print changed + 0 }
  ' "$@"
}

# mapsha <sha>: the rewritten SHA of a commit of the repository (empty if not in the commit-map)
mapsha() { awk -v o="$1" '$1 == o { print $2 }' "$TRIAL/filter-repo/commit-map"; }

# a fetched origin commit the local dev/main lacks is not in the rewrite, and the push would drop it;
# the push leases on the origin values checked here (ORIGIN_dev, ORIGIN_main), not on a later fetch
for b in dev main; do
  ob=$(git rev-parse -q --verify "refs/remotes/origin/$b" 2>/dev/null || true)
  printf -v "ORIGIN_$b" '%s' "$ob"
  lb=$(git rev-parse -q --verify "refs/heads/$b" 2>/dev/null || true)
  if [ -n "$ob" ] && [ -n "$lb" ] && ! git merge-base --is-ancestor "$ob" "$lb"; then
    say "refuse: origin/$b has commits the local $b lacks; merge them into $b, then rerun. Nothing changed."; exit 1
  fi
done

# ---- rehearsal (both modes) -----------------------------------------------------------------
if [ "$EXEC" -eq 1 ]; then
  say "run: backup mirror -> $BACKUP"
  mkdir -p "$(dirname "$BACKUP")"
  git clone -q --mirror "$REPO" "$BACKUP" || { say "fail: backup clone; nothing changed"; exit 1; }
  git config --get review.reviewedthrough > "$BACKUP/review-reviewedthrough" 2>/dev/null || true
fi
say "rehearse: mirror $REPO -> $TRIAL"
rm -rf "$TRIAL" "$CLONE"
git clone -q --mirror "$REPO" "$TRIAL" || { say "fail: mirror clone"; exit 1; }
# the throwaway mirror only: the global protected-branch hooks refuse its rewritten dev/main
git --git-dir="$TRIAL" config core.hooksPath /dev/null
OLDREFS=$WORK/refs-before
git --git-dir="$TRIAL" for-each-ref --format='%(refname) %(objectname)' refs/heads refs/tags > "$OLDREFS"
trees "$TRIAL" > "$WORK/trees-before"
BEFORE=$(git --git-dir="$TRIAL" rev-list --all | wc -l | tr -d ' ')
if [ "$EXEC" -eq 1 ] && [ "$(git --git-dir="$BACKUP" rev-list --all | wc -l | tr -d ' ')" != "$BEFORE" ]; then
  say "fail: backup and mirror differ (the repository moved?); nothing changed"; exit 1
fi
(cd "$TRIAL" && git filter-repo --force --quiet "${FILTER[@]}") || { say "fail: filter-repo on the mirror"; exit 1; }
AFTER=$(git --git-dir="$TRIAL" rev-list --all | wc -l | tr -d ' ')
CHANGED=$(awk 'NR > 1 && $1 != $2' "$TRIAL/filter-repo/commit-map" | wc -l | tr -d ' ')
say "rehearse: $BEFORE commits before, $AFTER after, $CHANGED with a new SHA"
[ "$BEFORE" = "$AFTER" ] || { say "fail: commit count changed; nothing changed in $REPO"; exit 1; }
trees "$TRIAL" > "$WORK/trees-after"
if ! cmp -s "$WORK/trees-before" "$WORK/trees-after"; then
  say "fail: a tree changed (dev, main or a tag):"; diff "$WORK/trees-before" "$WORK/trees-after" | sed 's/^/  /'
  say "rehearsal failed: nothing changed in $REPO"; exit 1
fi
say "rehearse: $(wc -l < "$WORK/trees-after" | tr -d ' ') tree(s) of dev, main and the tags unchanged"
verify "$TRIAL" || { say "rehearsal failed: nothing changed in $REPO"; exit 1; }

# SHA references, in a non-bare clone of the rewritten mirror
git clone -q -b dev "$TRIAL" "$CLONE" || { say "fail: clone of the mirror"; exit 1; }
git -C "$CLONE" config core.hooksPath /dev/null
git -C "$CLONE" config user.name "${ME% <*}"; ME_EMAIL=${ME##*<}; git -C "$CLONE" config user.email "${ME_EMAIL%>}"
git -C "$CLONE" fetch -q --update-head-ok origin '+refs/heads/*:refs/heads/*' || { say "fail: branches into the clone"; exit 1; }
git -C "$CLONE" checkout -q -b "$SHAB" dev || { say "fail: $SHAB in the clone"; exit 1; }
FILES=$(git -C "$CLONE" ls-files '*.md')
N=$( (cd "$CLONE" && remap "$TRIAL/filter-repo/commit-map" $FILES) | tail -1)
(cd "$CLONE" && for f in $FILES; do [ -f "$f.remap" ] || continue; if cmp -s "$f" "$f.remap"; then rm -f "$f.remap"; else mv "$f.remap" "$f"; fi; done)
if [ -n "$(git -C "$CLONE" status --porcelain --untracked-files=no)" ]; then
  git -C "$CLONE" commit -qam "docs: point SHA references at the rewritten history ($N references)" || { say "fail: SHA-reference commit in the clone"; exit 1; }
  { git -C "$CLONE" checkout -q dev && git -C "$CLONE" merge -q --no-ff "$SHAB" -m "Merge branch '$SHAB' into dev"; } || { say "fail: merge of $SHAB in the clone"; exit 1; }
  say "rehearse: $N old SHA reference(s) in dev's .md files rewritten, merged into dev (in the clone)"
else
  git -C "$CLONE" checkout -q dev; git -C "$CLONE" branch -q -D "$SHAB"; say "rehearse: no SHA references to rewrite"
fi
verify "$CLONE/.git" || { say "rehearsal failed: nothing changed in $REPO"; exit 1; }

# review state: refs/review/reviewed and review.reviewedthrough through the commit-map
RR0=$(git rev-parse -q --verify refs/review/reviewed 2>/dev/null || true) RR1=""
[ -z "$RR0" ] || { RR1=$(mapsha "$RR0"); say "review: refs/review/reviewed $RR0 -> ${RR1:-(not in the commit-map, left)}"; }
WT0=$(git config --get review.reviewedthrough 2>/dev/null || true) WT1=""
if [ -n "$WT0" ]; then
  full=$(git rev-parse -q --verify "$WT0^{commit}" 2>/dev/null || true)
  [ -z "$full" ] || WT1=$(mapsha "$full")
  [ -z "$WT1" ] || [ "${#WT0}" -ge 40 ] || WT1=$(printf '%s' "$WT1" | cut -c1-${#WT0})
  say "review: review.reviewedthrough $WT0 -> ${WT1:-(not in the commit-map, left)}"
fi
say "ok: rehearsal clean (identities, messages, commit count, trees)"
if [ "$EXEC" -eq 0 ]; then say "dry run: nothing changed in $REPO; run again with --execute --rewrite-history"; exit 0; fi

# ---- real run: bring the rewritten refs back ------------------------------------------------
# branches checked out in a worktree (the main one included)
WTB=$WORK/worktree-branches
git worktree list --porcelain | awk '/^worktree /{ w = substr($0, 10) } /^branch refs\/heads\//{ print substr($0, 19) "\t" w }' > "$WTB"
UNDOF=$BACKUP/undo.sh
printf '#!/usr/bin/env bash\n# undo of 2026-11-14-history-rewrite.sh (before pushing): old values of the refs it changed\nset -e\ncd %q\n' "$REPO" > "$UNDOF"
UNDO="GIT_ALLOW_PROTECTED=1 bash $UNDOF"
changed_fail() { say "fail: $*"; say "the repository is partly changed and nothing is pushed. Undo: $UNDO"; exit 3; }
FETCHED=0 SKIPPED=0 MANUAL=""
# the rewritten objects only (FETCH_HEAD, no ref is written); every ref then moves by compare-and-swap
# (update-ref <ref> <new> <old>), which refuses a ref that moved since the mirror. A branch checked out in a
# worktree gets a printed `reset --keep` guarded on its old tip: dev's tree differs by the SHA-reference merge.
git -C "$CLONE" config uploadpack.allowAnySHA1InWant true
git fetch -q --no-tags --no-write-fetch-head "$CLONE" $(git -C "$CLONE" for-each-ref --format='%(objectname)' refs/heads refs/tags | sort -u) \
  || { say "fail: fetch of the rewritten objects; no ref changed"; exit 1; }
for br in $(git -C "$CLONE" for-each-ref --format='%(refname:short)' refs/heads); do
  new=$(git -C "$CLONE" rev-parse "refs/heads/$br")
  old=$(awk -v r="refs/heads/$br" '$1 == r { print $2 }' "$OLDREFS")
  [ "$new" != "$old" ] || continue
  # filter-repo turns refs/remotes/origin/X into refs/heads/X when the mirror has no branch X: not created here
  if [ -z "$old" ] && [ "$br" != "$SHAB" ]; then say "skip: $br is only on origin; not created"; continue; fi
  wt=$(awk -F'\t' -v b="$br" '$1 == b { print $2; exit }' "$WTB")
  if [ -n "$wt" ]; then
    allow=""; case "$br" in dev|main) allow="GIT_ALLOW_PROTECTED=1 " ;; esac
    MANUAL="$MANUAL  [ \"\$(git -C $wt rev-parse HEAD)\" = $old ] && ${allow}git -C $wt reset -q --keep $new   # $br; keeps uncommitted changes, refuses if $br moved"$'\n'
    printf '[ "$(git -C %q rev-parse HEAD)" = %s ] && %sgit -C %q reset -q --keep %s || echo "left: %s not reset (not at the rewritten tip, or uncommitted changes in the way)"\n' "$wt" "$new" "$allow" "$wt" "$old" "$br" >> "$UNDOF"
    continue
  fi
  if [ -n "$old" ]; then
    git update-ref "refs/heads/$br" "$new" "$old" 2>/dev/null || { say "skip: $br moved since the mirror; left as is"; SKIPPED=$((SKIPPED + 1)); continue; }
    printf 'git update-ref refs/heads/%q %s %s\n' "$br" "$old" "$new" >> "$UNDOF"
  else
    git update-ref "refs/heads/$br" "$new" 0000000000000000000000000000000000000000 || changed_fail "create $br"
    printf 'git update-ref -d refs/heads/%q %s\n' "$br" "$new" >> "$UNDOF"
  fi
  FETCHED=$((FETCHED + 1))
done
for t in $(git -C "$CLONE" for-each-ref --format='%(refname:short)' refs/tags); do
  new=$(git -C "$CLONE" rev-parse "refs/tags/$t")
  old=$(awk -v r="refs/tags/$t" '$1 == r { print $2 }' "$OLDREFS")
  [ -n "$old" ] && [ "$new" != "$old" ] || continue
  git update-ref "refs/tags/$t" "$new" "$old" 2>/dev/null || { say "skip: tag $t moved since the mirror; left as is"; SKIPPED=$((SKIPPED + 1)); continue; }
  printf 'git update-ref refs/tags/%q %s %s\n' "$t" "$old" "$new" >> "$UNDOF"
done
if [ -n "$RR1" ]; then
  git update-ref refs/review/reviewed "$RR1" "$RR0" || changed_fail "refs/review/reviewed"
  printf 'git update-ref refs/review/reviewed %s %s\n' "$RR0" "$RR1" >> "$UNDOF"
  say "run: refs/review/reviewed -> $RR1"
fi
if [ -n "$WT1" ]; then
  git config review.reviewedthrough "$WT1" || changed_fail "review.reviewedthrough"
  printf 'git config review.reviewedthrough %s\n' "$WT0" >> "$UNDOF"
  say "run: review.reviewedthrough -> $WT1"
fi
say "ok: $FETCHED branch(es) and the tags moved to the rewritten history; $SKIPPED skipped; $CHANGED commits have new SHAs. Nothing pushed."
if [ -n "$MANUAL" ]; then say "checked out in a worktree, left as is (yours; undo.sh covers them):"; printf '%s' "$MANUAL"; fi
# each push leases on origin's value checked before the rehearsal, so a push or fetch made since is not overwritten
REFS="" LEASES=""
for b in dev main; do
  git -C "$CLONE" rev-parse -q --verify "refs/heads/$b" >/dev/null || continue
  ob_var="ORIGIN_$b"; ob=${!ob_var}
  REFS="$REFS $b"; LEASES="$LEASES --force-with-lease=refs/heads/$b:$ob"
done
while read -r r s; do
  o=$(awk -v r="$r" '$1 == r { print $2 }' "$OLDREFS")
  [ -n "$o" ] && [ "$s" != "$o" ] || continue
  REFS="$REFS $r"; LEASES="$LEASES --force-with-lease=$r:$o"
done < <(git -C "$CLONE" for-each-ref --format='%(refname) %(objectname)' refs/tags)
say "push (yours, from the rewritten clone):"
say "  GIT_ALLOW_PROTECTED=1 git -C $CLONE push$LEASES $ORIGIN$REFS"
DEV0=$(awk '$1 == "refs/heads/dev" { print $2 }' "$OLDREFS")
# remote branches merged into the old dev whose tip got a new SHA
OLDREM=$(git for-each-ref --format='%(refname:lstrip=3) %(objectname)' refs/remotes/origin | while read -r b s; do
  case "$b" in HEAD|dev|main) continue ;; esac
  n=$(mapsha "$s"); [ -n "$n" ] && [ "$n" != "$s" ] && git merge-base --is-ancestor "$s" "$DEV0" && printf ' %s' "$b"; done)
[ -z "$OLDREM" ] || say "  option: git push origin --delete$OLDREM   # merged remote branches holding only old history"
say "undo (before pushing): $UNDO"
