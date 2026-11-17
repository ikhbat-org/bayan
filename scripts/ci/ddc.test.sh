#!/usr/bin/env bash
# Tests scripts/ci/ddc.sh on a scratch repo with a stub `dotnet` (DDC_DOTNET): its `publish` writes a stub C# compiler whose
# `build -o X` writes a stub stage 1, which emits `line 1` then src/driver/main.byn as C; its `test` logs the filter and
# fails for the id in $FAIL_LAW. Usage: exit 2; a bootstrap/bayan.c that differs: exit 1 naming the line; equal: exit 0;
# the empty laws list passes; a listed law runs in the frozen tree and its failure fails the run.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/ddc-test.XXXXXX")"
aux="$tmp/aux"; mkdir -p "$aux"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; [ -z "${2:-}" ] || echo "$2" >&2; exit 1; }

cat > "$aux/stage1" <<'STUB'
#!/bin/bash
[ "$2" = --emit-c ] || exit 9
echo "line 1"; cat src/driver/main.byn
STUB
cat > "$aux/csharp" <<'STUB'
#!/bin/bash
[ "$1" = build ] || exit 9
while [ $# -gt 0 ]; do [ "$1" = -o ] && out=$2; shift; done
mkdir -p "$(dirname "$out")"; cp "$AUX/stage1" "$out"
STUB
cat > "$aux/dotnet" <<'STUB'
#!/bin/bash
case "$1" in
  publish) while [ $# -gt 0 ]; do [ "$1" = -o ] && out=$2; shift; done; mkdir -p "$out"; cp "$AUX/csharp" "$out/bayan" ;;
  test) echo "$* tier=$BAYAN_LAW_TIER in $(cat VERSION)" >> "$AUX/tests.txt"; [ "$*" != "test -v q --filter Law=${FAIL_LAW:-}" ] ;;
  *) exit 9 ;;
esac
STUB
chmod +x "$aux/stage1" "$aux/csharp" "$aux/dotnet"
export AUX="$aux" DDC_DOTNET="$aux/dotnet" DDC_RID=linux-x64
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

r="$tmp/repo"; mkdir -p "$r/scripts/ci" "$r/src/driver" "$r/bootstrap" "$r/csharp/Bayan.Cli"; cd "$r"
git init -q -b dev; git config core.hooksPath /dev/null
cp "$root/scripts/ci/ddc.sh" "$root/scripts/ci/ddc-laws.txt" scripts/ci/
printf '/tmp/\n' > .gitignore; echo frozen > VERSION; touch csharp/Bayan.Cli/Bayan.Cli.csproj
printf 'a\nb\nc\n' > src/driver/main.byn; printf 'line 1\na\nb\nc\n' > bootstrap/bayan.c
git add -A; git commit -qm good; git tag good
printf 'line 1\na\nB\nc\n' > bootstrap/bayan.c; git commit -qam bad; git tag bad
echo later > VERSION; git commit -qam later
run() { bash scripts/ci/ddc.sh "$@" > "$tmp/out" 2>&1 && echo 0 || echo $?; }

[ "$(run a b)" = 2 ] || fail "two arguments: want exit 2" "$(cat "$tmp/out")"
[ "$(run --help)" = 2 ] || fail "an option: want exit 2" "$(cat "$tmp/out")"
[ "$(run nosuchref)" = 2 ] || fail "an unknown ref: want exit 2" "$(cat "$tmp/out")"
[ "$(run)" = 2 ] && grep -q "csharp-final" "$tmp/out" || fail "no ref: want exit 2 naming csharp-final (untagged here)" "$(cat "$tmp/out")"

[ "$(run bad)" = 1 ] || fail "a differing bootstrap/bayan.c: want exit 1" "$(cat "$tmp/out")"
grep -q "differs from bootstrap/bayan.c at line 3" "$tmp/out" || fail "the mismatch does not name line 3" "$(cat "$tmp/out")"
grep -q "bootstrap/bayan.c: B" "$tmp/out" && grep -q "emitted: *b" "$tmp/out" || fail "the mismatch does not show both lines" "$(cat "$tmp/out")"
[ ! -e "$AUX/tests.txt" ] || fail "laws ran after a mismatch"
kept="$(ls -d tmp/ddc.*)"; [ -n "$kept" ] && grep -qF "tree kept: $r/$kept" "$tmp/out" || fail "a failing run did not keep and name its tree" "$(cat "$tmp/out")"
rm -rf tmp/ddc.*

[ "$(run good)" = 0 ] || fail "an equal bootstrap/bayan.c: want exit 0" "$(cat "$tmp/out")"
grep -q "reproduced byte for byte" "$tmp/out" || fail "no reproduced line" "$(cat "$tmp/out")"
grep -q "no laws listed" "$tmp/out" || fail "the empty laws list does not say so" "$(cat "$tmp/out")"
[ ! -e "$AUX/tests.txt" ] || fail "a law ran from the empty list"
[ -z "$(ls -d tmp/ddc.* 2>/dev/null)" ] || fail "a passing run left its tree"

printf '# amended\nL027\n\nL043  # frozen files\n' > scripts/ci/ddc-laws.txt
[ "$(run good)" = 0 ] || fail "listed laws that hold: want exit 0" "$(cat "$tmp/out")"
[ "$(cat "$AUX/tests.txt")" = "$(printf 'test -v q --filter Law=L027 tier=full in frozen\ntest -v q --filter Law=L043 tier=full in frozen')" ] \
  || fail "laws did not run in the frozen tree, full tier" "$(cat "$AUX/tests.txt")"
[ "$(FAIL_LAW=L043 run good)" = 1 ] && grep -q "laws failed on the frozen compiler: L043" "$tmp/out" \
  || fail "a failing listed law: want exit 1 naming it" "$(cat "$tmp/out")"
echo PASS
