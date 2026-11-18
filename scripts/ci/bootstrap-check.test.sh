#!/usr/bin/env bash
# Tests scripts/ci/bootstrap-check.sh and land.sh's bootstrap regeneration on scratch repos, with a stub `cc` (the one
# scripts/pinned-bayan.sh calls) whose "bayan" emits `C:<src/driver/main.byn>` and refuses a source holding `cap` unless
# the bootstrap.c it was built from holds `cap` too, and a `dotnet` that logs and exits 97: neither script may reach it.
# Fresh bootstrap: pass; a src/ or runtime/ change without regenerating: fail naming the file; a previous bootstrap that
# cannot build the new src/: fail; land.sh regenerates bootstrap/ from the base's bootstrap with no dotnet call.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
check="$root/scripts/ci/bootstrap-check.sh"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/bootstrap-check-test.XXXXXX")"
aux="$tmp/aux"; mkdir -p "$aux"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; [ -z "${2:-}" ] || echo "$2" >&2; exit 1; }

# the stub compiler; `run` stands in for wave-brief (land.sh runs it through scripts/bayan-tool.sh and $PINNED_BAYAN)
cat > "$aux/bayan.in" <<'STUB'
#!/bin/bash
CAP=no
if [ "$1" = run ]; then d=tmp/010-$(echo "$5" | tr A-Z a-z); mkdir -p "$d"; echo "bash scripts/selfhost/guard.sh --base x --filter F" > "$d/prompt.md"; exit 0; fi
src=$(cat src/driver/main.byn)
case "$src" in *cap*) [ $CAP = yes ] || { echo "error: this compiler cannot parse 'cap'" >&2; exit 1; } ;; esac
[ "$2" = --emit-c ] && { printf '#line 1 "driver/main.byn"\nC:%s\n' "$src"; exit 0; }
while [ $# -gt 0 ]; do [ "$1" = -o ] && out=$2; shift; done
cap=no; case "$src" in *cap*) cap=yes ;; esac
echo build >> "$AUX/builds"; [ -z "${SLOW:-}" ] || sleep "$SLOW"
mkdir -p "$(dirname "$out")"; sed "s/^CAP=.*/CAP=$cap/" "$0" > "$out"; chmod +x "$out"
STUB
cat > "$aux/cc" <<'STUB'
#!/bin/bash
while [ $# -gt 0 ]; do case "$1" in -o) out=$2 ;; */bayan.c) c=$1 ;; esac; shift; done
cap=no; grep -q cap "$c" && cap=yes
mkdir -p "$(dirname "$out")"; sed "s/^CAP=.*/CAP=$cap/" "$AUX/bayan.in" > "$out"; chmod +x "$out"
STUB
cat > "$aux/dotnet" <<'STUB'
#!/bin/bash
echo "dotnet $*" >> "$AUX/dotnet-calls.txt"; exit 97
STUB
chmod +x "$aux/cc" "$aux/dotnet"
export AUX="$aux" PATH="$aux:$PATH"
unset PINNED_BAYAN PINNED_BAYAN_REF CC
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

# regen: what land.sh should leave in bootstrap/ for the current src/ and runtime/
regen() { printf '#line 1 "driver/main.byn"\nC:%s\n' "$(cat src/driver/main.byn)" > bootstrap/bayan.c; cp runtime/bayan-rt.h runtime/bayan-rt.c bootstrap/; }
scaffold() { mkdir -p bootstrap runtime src/driver; printf '/tmp/\n/.cache/\n' > .gitignore
  echo h1 > runtime/bayan-rt.h; echo c1 > runtime/bayan-rt.c; echo v1 > src/driver/main.byn; regen; }
run() { "$check" "$@" > "$tmp/out" 2>&1 && echo pass || echo fail; }

r="$tmp/repo"; mkdir -p "$r"; cd "$r"
git init -q -b dev; git config core.hooksPath /dev/null
scaffold; git add -A; git commit -qm one
[ "$(run)" = pass ] || fail "a root commit with a fresh bootstrap failed" "$(cat "$tmp/out")"
echo v2 > src/driver/main.byn; regen; git commit -qam two
[ "$(run)" = pass ] || fail "a fresh bootstrap failed" "$(cat "$tmp/out")"

# a src/ change without regenerating names bootstrap/bayan.c and the src/ file behind the first difference
git checkout -q -b stale; echo v3 > src/driver/main.byn; git commit -qam three
[ "$(run)" = fail ] || fail "a src/ change without a regenerated bootstrap passed" "$(cat "$tmp/out")"
grep -q 'FAIL bootstrap/bayan.c is not the C' "$tmp/out" && grep -q 'from src/driver/main.byn:1' "$tmp/out" \
  || fail "the stale bayan.c was not named with its src/ file" "$(cat "$tmp/out")"

# a runtime/ change without copying it names the copy
git checkout -q -b rt dev; echo c2 > runtime/bayan-rt.c; git commit -qam rt
[ "$(run)" = fail ] || fail "a runtime/ change without a copied bootstrap passed" "$(cat "$tmp/out")"
grep -q 'FAIL bootstrap/bayan-rt.c differs from runtime/bayan-rt.c' "$tmp/out" || fail "the stale runtime copy was not named" "$(cat "$tmp/out")"

# src/ that the previous bootstrap cannot build fails, though the new bootstrap builds itself
git checkout -q -b chain dev; echo 'v4 cap' > src/driver/main.byn; regen; git commit -qam four
[ "$(run HEAD)" = pass ] || fail "the new bootstrap did not build itself" "$(cat "$tmp/out")"
[ "$(run)" = fail ] || fail "src/ the previous bootstrap cannot build passed" "$(cat "$tmp/out")"
grep -q "FAIL the bootstrap of HEAD^ ($(git rev-parse dev)) does not build src/driver (R36)" "$tmp/out" \
  || fail "no chain failure message" "$(cat "$tmp/out")"

# a merge commit: dev's bootstrap cannot build the merged branch's src/, the branch's own can; the check builds from HEAD^2
git checkout -q -b mfeat dev; echo 'v5 cap' > src/driver/main.byn; regen; git commit -qam feat
git checkout -q dev; echo d > docs.txt; git add docs.txt; git commit -qm dev-moves
git merge -q --no-ff -m merge mfeat
[ "$(run)" = pass ] || fail "a merge commit whose second parent's bootstrap builds src/ failed" "$(cat "$tmp/out")"
grep -q 'the bootstrap of HEAD^2 builds it' "$tmp/out" || fail "the merge check did not name HEAD^2" "$(cat "$tmp/out")"

# a merge commit where neither parent's bootstrap builds the merged src/: fail, after trying both parents
git checkout -q -b mboth dev~1; git checkout -q -b mside; echo e > side.txt; git add side.txt; git commit -qm side
git checkout -q mboth; echo f > main.txt; git add main.txt; git commit -qm main
git merge -q --no-ff --no-commit mside > /dev/null 2>&1; echo 'v6 cap' > src/driver/main.byn; regen; git add -A; git commit -qm merge-new-src
[ "$(run)" = fail ] || fail "a merge commit no parent's bootstrap can build passed" "$(cat "$tmp/out")"
grep -q 'FAIL the bootstrap of HEAD^2 ' "$tmp/out" && grep -q 'FAIL the bootstrap of HEAD^ ' "$tmp/out" && grep -q 'trying the next parent' "$tmp/out" \
  || fail "the merge failure did not name both parents" "$(cat "$tmp/out")"

# reuse (T32b): same inputs reuse the build, a changed tree rebuilds, a failed build leaves no stamp
git checkout -q -b reuse dev; rm -f "$aux/builds"
[ "$(run)" = pass ] || fail "reuse: first run failed" "$(cat "$tmp/out")"
[ "$(wc -l < "$aux/builds")" -eq 1 ] && ! grep -q reused "$tmp/out" || fail "reuse: first run did not build once" "$(cat "$tmp/out")"
[ "$(run)" = pass ] && grep -q 'reused' "$tmp/out" && [ "$(wc -l < "$aux/builds")" -eq 1 ] || fail "reuse: same inputs did not reuse" "$(cat "$tmp/out")"
echo v7 > src/driver/main.byn; regen; git commit -qam v7
[ "$(run)" = pass ] && ! grep -q reused "$tmp/out" && [ "$(wc -l < "$aux/builds")" -eq 2 ] || fail "reuse: a changed tree did not rebuild" "$(cat "$tmp/out")"
echo v7b > src/driver/main.byn; regen; git commit -q --amend -a --no-edit   # same parent, new tree
[ "$(run)" = pass ] && ! grep -q reused "$tmp/out" && [ "$(wc -l < "$aux/builds")" -eq 3 ] || fail "reuse: a changed tree under the same parent did not rebuild" "$(cat "$tmp/out")"
echo 'v8 cap' > src/driver/main.byn; regen; git commit -qam v8
[ "$(run)" = fail ] && [ ! -e tmp/bootstrap-check/stamp ] || fail "reuse: a failed build left a stamp" "$(cat "$tmp/out")"
[ "$(run)" = fail ] && ! grep -q reused "$tmp/out" || fail "reuse: a failed build was reused" "$(cat "$tmp/out")"

# two runs at once: one build, both OK
echo v9 > src/driver/main.byn; regen; git commit -qam v9; rm -f "$aux/builds"
SLOW=2 "$check" > "$tmp/out1" 2>&1 & p1=$!
sleep 1; "$check" > "$tmp/out2" 2>&1 & p2=$!
wait $p1 && wait $p2 || fail "concurrent: a run failed" "$(cat "$tmp/out1" "$tmp/out2")"
grep -q 'OK' "$tmp/out1" && grep -q 'OK' "$tmp/out2" && [ "$(wc -l < "$aux/builds")" -eq 1 ] || fail "concurrent: not one build and two OKs" "$(cat "$tmp/out1" "$tmp/out2"; cat "$aux/builds")"
[ ! -e tmp/bootstrap-check.lock ] || fail "concurrent: the lock was left behind"

# a stale lock whose pid is dead is broken; a live one is waited on
echo v10 > src/driver/main.byn; regen; git commit -qam v10
sh -c 'exit 0' & dead=$!; wait $dead
mkdir tmp/bootstrap-check.lock; echo $dead > tmp/bootstrap-check.lock/pid
[ "$(run)" = pass ] || fail "stale lock with a dead pid was not broken" "$(cat "$tmp/out")"
echo v11 > src/driver/main.byn; regen; git commit -qam v11
mkdir tmp/bootstrap-check.lock; echo $$ > tmp/bootstrap-check.lock/pid
"$check" > "$tmp/out" 2>&1 & p3=$!; sleep 1
kill -0 $p3 2> /dev/null || fail "a live lock was not waited on" "$(cat "$tmp/out")"
rm -rf tmp/bootstrap-check.lock; wait $p3 || fail "the waiting run failed after the lock cleared" "$(cat "$tmp/out")"

# an unknown ref is an error, not a pass
[ "$(run nope)" = fail ] && grep -q "no commit for 'nope'" "$tmp/out" || fail "an unknown ref was not refused" "$(cat "$tmp/out")"
[ ! -e "$aux/dotnet-calls.txt" ] || fail "bootstrap-check.sh called dotnet: $(cat "$aux/dotnet-calls.txt")"

# land.sh: a branch changing src/ lands with bootstrap/ regenerated by the stage-1 route, and no dotnet call
l="$tmp/land"; mkdir -p "$l/scripts/selfhost" "$l/docs/specs/010-self-hosted-semantics"; cd "$l"
git init -q -b base; git config core.hooksPath /dev/null
scaffold; printf 'echo GUARD PASS\n' > scripts/selfhost/guard.sh; printf 'echo ok\n' > scripts/selfhost/preflight.sh
printf -- '- [ ] T99 fixture\n' > docs/specs/010-self-hosted-semantics/010-tasks.md
git add -A; git commit -qm base
git checkout -q -b feat; echo v2 > src/driver/main.byn; echo h2 > runtime/bayan-rt.h; git commit -qam code
rev=docs/specs/010-self-hosted-semantics/reviews/T99.md; mkdir -p "${rev%/*}"
printf '# T99 review\nCommit: %s\nVerdict: PASS\n' "$(git rev-parse HEAD)" > "$rev"; git add "$rev"; git commit -qm "docs(010): T99 review (PASS, round 1)"
git checkout -q base
sed 's/^CAP=.*/CAP=yes/' "$aux/bayan.in" > "$aux/bayan"; chmod +x "$aux/bayan"
landed=$(PINNED_BAYAN="$aux/bayan" /bin/bash "$root/scripts/selfhost/land.sh" T99 feat 2>&1) || fail "land.sh failed" "$landed"
echo "$landed" | grep -q '^LANDED T99$' || fail "land.sh did not land" "$landed"
[ ! -e "$aux/dotnet-calls.txt" ] || fail "land.sh called dotnet: $(cat "$aux/dotnet-calls.txt")"
[ "$(cat bootstrap/bayan.c)" = "$(printf '#line 1 "driver/main.byn"\nC:v2')" ] && [ "$(cat bootstrap/bayan-rt.h)" = h2 ] \
  || fail "land.sh did not regenerate bootstrap/ (bayan.c: $(cat bootstrap/bayan.c); bayan-rt.h: $(cat bootstrap/bayan-rt.h))" "$landed"
[ -z "$(git status --porcelain --untracked-files=no)" ] || fail "land.sh left bootstrap/ uncommitted" "$(git status --porcelain)"
unset PINNED_BAYAN
[ "$(run)" = pass ] || fail "the landed tick commit fails bootstrap-check.sh" "$(cat "$tmp/out")"
echo PASS
