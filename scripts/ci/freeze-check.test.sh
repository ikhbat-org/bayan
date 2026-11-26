#!/usr/bin/env bash
# Tests scripts/ci/freeze-check.sh in a scratch repo under tmp/: a manifest from --write passes and is sorted bytewise and
# idempotent; a committed edit, an uncommitted edit, a removed file, a file with no row, a digest-only manifest edit, a cases
# count off by one, a duplicate row, an EXPORT.tsv count or missing class, a pending DIVERGENCES row and a run-c.sha256 edit are
# refused; an edit with its --write row passes; a path with spaces and a CRLF file under eol=lf work; the frozen set is the
# golden-commit-check.sh is_expected set plus run-c.sha256; the tag row is compared only when the tag resolves.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/freeze-check-test"; rm -rf "$t"; mkdir -p "$t"; cd "$t"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com
export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0=/dev/null GIT_CONFIG_KEY_1=core.safecrlf GIT_CONFIG_VALUE_1=false
fc="$root/scripts/ci/freeze-check.sh"
tab="$(printf '\t')"
run() { rc=0; out="$(bash "$fc" "$@" 2>&1)" || rc=$?; }
expect() { # name exit [text]: checks HEAD, the worktree untouched
  run HEAD
  [ "$rc" = "$2" ] || fail "$1: exit $rc, wanted $2: $out"
  [ -z "${3:-}" ] || grep -q -F -e "$3" <<<"$out" || fail "$1: no '$3' in: $out"
}
git init -q -b main .
printf '* text=auto eol=lf\n' > .gitattributes
mkdir -p "tests/cases/cli/CliTests/Shows-1" "tests/cases/cli/CliTests/Shows 2" tests/cases/sem/SemTests/a tests/cases/lex \
  tests/cases/emit tests/cases/out src
echo out > "tests/cases/cli/CliTests/Shows-1/expected.stdout"; echo args > "tests/cases/cli/CliTests/Shows-1/args"
echo spaced > "tests/cases/cli/CliTests/Shows 2/expected.stdout"; echo 1 > "tests/cases/cli/CliTests/Shows 2/expected.exitcode"
echo sem > tests/cases/sem/SemTests/a/expected.golden
for n in B a ab a-b; do echo "$n" > "tests/cases/lex/$n.tokens"; done; echo src > tests/cases/lex/a.byn
echo 'a b c' > "tests/cases/lex/a b.tokens"
echo hash > tests/cases/emit/run-c.sha256; echo '{}' > tests/cases/out/results-fail.json; echo t > tests/cases/out/x.tree
printf 'class\tkind\ttests\tcases\treason\nCliTests\tcli\t2\t2\t\nSemTests\tsem\t1\t1\t\n' > tests/cases/EXPORT.tsv
printf 'case\tquestion\tright\treason\nCacheTests.X\tQ1\tdriver\tnot a path\ncli/CliTests/Shows-1\tQ2\tcsharp\tr\n' > tests/cases/DIVERGENCES.tsv
echo a > src/a.txt
git add -A; git commit -qm base
tagsha="$(git rev-parse HEAD)"
printf 'tag\tv0\t%s\nexport\tchore/export\t%s\n' "$tagsha" "$tagsha" > tests/cases/FREEZE.tsv

# 1 --write: sorted bytewise (LC_ALL=C), idempotent, and the tree then passes
run --write; [ "$rc" = 0 ] || fail "--write exit $rc: $out"
git add -A; git commit -qm "freeze for T20"
grep "^file$tab" tests/cases/FREEZE.tsv | cut -f3 > "$t/rows"
LC_ALL=C sort "$t/rows" | cmp -s - "$t/rows" || fail "file rows are not in LC_ALL=C order: $(cat "$t/rows")"
[ "$(grep -n 'lex/B.tokens' "$t/rows" | cut -d: -f1)" -lt "$(grep -n 'lex/a.tokens' "$t/rows" | cut -d: -f1)" ] || fail "B sorts after a"
run --write; grep -q unchanged <<<"$out" || fail "a second --write changed the manifest: $out"
git diff --quiet || fail "a second --write changed the manifest"
[ "$(grep "lex/a.tokens" tests/cases/FREEZE.tsv | cut -f2)" = "$(git rev-parse HEAD:tests/cases/lex/a.tokens)" ] || fail "digest is not the blob id"
grep -qx "cases${tab}lex${tab}5" tests/cases/FREEZE.tsv || fail "lex should have 5 cases (a, a b, a-b, ab, B): $(grep ^cases tests/cases/FREEZE.tsv)"
grep -qx "cases${tab}cli${tab}2" tests/cases/FREEZE.tsv || fail "cli should have 2 cases (two dirs, three files)"
expect "clean" 0 "ok"
run; [ "$rc" = 0 ] || fail "clean worktree exit $rc: $out"
git update-ref refs/tags/v0 "$tagsha"
expect "matching tag" 0
git update-ref -d refs/tags/v0; git update-ref refs/tags/v0 "$(git rev-parse HEAD)"
expect "tag on another commit" 1 "tag v0 is"
git update-ref -d refs/tags/v0
expect "absent tag" 0 "tag v0 does not resolve here"
freeze="$(git rev-parse HEAD)"

# 2 a committed one-byte edit is named
echo outx > "tests/cases/cli/CliTests/Shows-1/expected.stdout"; git commit -qam "edit"
expect "committed edit" 1 "frozen file differs from its digest: tests/cases/cli/CliTests/Shows-1/expected.stdout"
# 4 the same edit with its --write row in one commit passes (the manifest is <rev>'s, not the freeze commit's)
bash "$fc" --write > /dev/null; git commit -qam "golden update for 1a2b3c4d"
expect "edit with its row" 0
run "$freeze"; [ "$rc" = 0 ] || fail "the freeze commit itself exit $rc: $out"

# 3 an uncommitted edit fails in worktree mode only
echo outy > "tests/cases/cli/CliTests/Shows-1/expected.stdout"
run; [ "$rc" = 1 ] && grep -q "differs from its digest (uncommitted): tests/cases/cli/CliTests/Shows-1/expected.stdout" <<<"$out" ||
  fail "uncommitted edit: exit $rc: $out"
expect "rev mode reads no worktree" 0
run --write; run; [ "$rc" = 0 ] || fail "uncommitted edit with --write exit $rc: $out"
git checkout -q -- .

# 5 a removed file
start="$(git rev-parse HEAD)"
git rm -q tests/cases/lex/ab.tokens; git commit -qm rm
expect "removed" 1 "frozen file removed: tests/cases/lex/ab.tokens"
git rm -q -r tests/cases; git checkout -q "$start" -- tests; git commit -qm back

# 6 an expected file with no row
mkdir -p tests/cases/sem/SemTests/b; echo new > tests/cases/sem/SemTests/b/expected.stdout; git add -A; git commit -qm new
expect "no row" 1 "expected file has no manifest row: tests/cases/sem/SemTests/b/expected.stdout"
git rm -q -r tests/cases/sem/SemTests/b; git commit -qm back

# 7 a digest-only manifest edit
sed "s/^file$tab[0-9a-f]*${tab}tests\/cases\/lex\/a.tokens$/file${tab}0123456789012345678901234567890123456789${tab}tests\/cases\/lex\/a.tokens/" \
  tests/cases/FREEZE.tsv > "$t/m"; cat "$t/m" > tests/cases/FREEZE.tsv; git commit -qam "digest"
expect "digest-only edit" 1 "frozen file differs from its digest: tests/cases/lex/a.tokens"
git checkout -q "$start" -- tests; git commit -qm back

# 8 a path with spaces: passes, then a committed edit names the whole path
grep -q "${tab}tests/cases/cli/CliTests/Shows 2/expected.stdout$" tests/cases/FREEZE.tsv || fail "no row for the spaced path"
expect "spaced path" 0
echo spacedx > "tests/cases/cli/CliTests/Shows 2/expected.stdout"; git commit -qam spaced
expect "spaced edit" 1 "frozen file differs from its digest: tests/cases/cli/CliTests/Shows 2/expected.stdout"
git checkout -q "$start" -- tests; git commit -qm back

# 9 a cases row off by one
sed "s/^cases${tab}lex${tab}5$/cases${tab}lex${tab}6/" tests/cases/FREEZE.tsv > "$t/m"; cat "$t/m" > tests/cases/FREEZE.tsv; git commit -qam count
expect "cases row" 1 "kind lex: 5 cases, manifest 6"
git checkout -q "$start" -- tests; git commit -qm back

# 10 EXPORT.tsv: a count that differs from the dirs, then a class dir with no row
sed "s/^SemTests${tab}sem${tab}1${tab}1/SemTests${tab}sem${tab}1${tab}2/" tests/cases/EXPORT.tsv > "$t/m"; cat "$t/m" > tests/cases/EXPORT.tsv
git commit -qam export
expect "EXPORT count" 1 "EXPORT.tsv row SemTests sem: cases 2, 1 case directories"
git checkout -q "$start" -- tests
mkdir -p tests/cases/sem/OtherTests/c; echo x > tests/cases/sem/OtherTests/c/args; git add -A; git commit -qm export2
expect "EXPORT class" 1 "EXPORT.tsv has no row for class OtherTests"
git rm -q -r tests/cases/sem/OtherTests; git commit -qm back
printf 'StdEnvTests\tshell\t6\t2\truntime/tests\n' >> tests/cases/EXPORT.tsv; git commit -qam shell
expect "EXPORT shell row" 0
sed "s/^StdEnvTests${tab}shell${tab}6${tab}2/StdEnvTests${tab}shell${tab}6${tab}x/" tests/cases/EXPORT.tsv > "$t/m"; cat "$t/m" > tests/cases/EXPORT.tsv
git commit -qam shell2
expect "EXPORT shell count" 1 "EXPORT.tsv row StdEnvTests shell: cases x is not a count"
git checkout -q "$start" -- tests; git commit -qm back

# 11 DIVERGENCES: pending in the question or the right column, and a kind path that names no case
for row in "cli/CliTests/Shows-1${tab}pending${tab}csharp${tab}r" "cli/CliTests/Shows-1${tab}remove${tab}pending${tab}r"; do
  printf '%s\n' "$row" >> tests/cases/DIVERGENCES.tsv; git commit -qam pending
  expect "pending row" 1 "cli/CliTests/Shows-1 is pending"
  git checkout -q "$start" -- tests; git commit -qm back
done
printf 'cli/CliTests/Gone-9\tQ3\tcsharp\tr\nlex/a\tQ4\tcsharp\tr\n' >> tests/cases/DIVERGENCES.tsv; git commit -qam gone
expect "unknown case" 1 "cli/CliTests/Gone-9 is no case of a manifest row"
grep -q 'lex/a is' <<<"$out" && fail "the flat case lex/a was refused: $out"
git checkout -q "$start" -- tests; git commit -qm back
mkdir -p tests/cases/run/pk; echo pk > tests/cases/run/pk/main.stdout; echo pk > tests/cases/run/pk/main.byn
run --write; git add -A; git commit -qm package
printf 'run/pk\tQ5\tdriver\tr\n' >> tests/cases/DIVERGENCES.tsv; git commit -qam pkrow
expect "package case by its directory" 0 "ok"
printf 'run/pq\tQ6\tdriver\tr\n' >> tests/cases/DIVERGENCES.tsv; git commit -qam pqrow
expect "unknown package case" 1 "run/pq is no case of a manifest row"
git rm -rq tests/cases/run; git checkout -q "$start" -- tests; git commit -qm back

# 12 run-c.sha256 is frozen
echo hashx > tests/cases/emit/run-c.sha256; git commit -qam runc
expect "run-c.sha256" 1 "frozen file differs from its digest: tests/cases/emit/run-c.sha256"
git checkout -q "$start" -- tests; git commit -qm back

# 13 a file committed with CRLF under eol=lf: the blob is LF, the worktree keeps CRLF, both modes pass
printf 'x\r\ny\r\n' > tests/cases/lex/crlf.tokens; git add -A; git commit -qm crlf
bash "$fc" --write > /dev/null; git commit -qam "freeze crlf for T20"
grep -q "$(printf '\r')" tests/cases/lex/crlf.tokens || fail "the fixture lost its CRLF worktree file"
[ "$(grep 'lex/crlf.tokens' tests/cases/FREEZE.tsv | cut -f2)" = "$(printf 'x\ny\n' | git hash-object --stdin)" ] || fail "CRLF digest is not the LF blob"
expect "crlf" 0
touch tests/cases/lex/crlf.tokens; run; [ "$rc" = 0 ] || fail "crlf worktree exit $rc: $out"
git checkout -q "$start" -- tests; git rm -q tests/cases/lex/crlf.tokens; git commit -qm back

# 14 a duplicate file row
row="$(grep "lex/a.tokens" tests/cases/FREEZE.tsv)"; printf '%s\n' "$row" >> tests/cases/FREEZE.tsv;git commit -qam dup
expect "duplicate row" 1 "duplicate file row: tests/cases/lex/a.tokens"
git checkout -q "$start" -- tests; git commit -qm back

# 15 the frozen set is golden-commit-check.sh is_expected plus run-c.sha256, over every path shape in the fixture
mkdir -p tests/cases/emit-c/E/c tests/cases/diag tests/cases/new/p
for f in tests/cases/emit-c/E/c/expected.c tests/cases/emit-c/E/c/input.byn tests/cases/diag/d.diag tests/cases/diag/d.byn \
  tests/cases/new/p/q.ast tests/cases/new/p/q.types tests/cases/new/p/q.jsonl tests/cases/new/p/q.stderr tests/cases/new/p/q.color \
  tests/cases/new/p/q.plain tests/cases/new/p/q.ascii tests/cases/new/p/q.txt tests/cases/new/p/run-c.sha256 tests/cases/out/other.json; do
  echo x > "$f"; done
printf 'E\temit-c\t1\t1\t\n' >> tests/cases/EXPORT.tsv
git add -A; bash "$fc" --write > /dev/null; git add -A; git commit -qm "more shapes for T20"
expect "more shapes" 0
eval "$(sed -n '/^is_expected() {/,/^}/p' "$root/scripts/ci/golden-commit-check.sh")"
git ls-files tests/cases | while IFS= read -r f; do
  if is_expected "$f" || [ "$f" = tests/cases/emit/run-c.sha256 ]; then printf '%s\n' "$f"; fi
done | LC_ALL=C sort > "$t/want"
grep "^file$tab" tests/cases/FREEZE.tsv | cut -f3 > "$t/have"
cmp -s "$t/want" "$t/have" || fail "the frozen set differs from is_expected: $(diff "$t/want" "$t/have")"

# usage, rev and manifest errors
run a b; [ "$rc" = 2 ] || fail "two arguments exit $rc"
run --nope; [ "$rc" = 2 ] || fail "unknown flag exit $rc"
run no-such-rev; [ "$rc" = 2 ] || fail "unknown rev exit $rc"
run "$tagsha"; [ "$rc" = 1 ] && grep -q "no tests/cases/FREEZE.tsv" <<<"$out" || fail "no manifest: exit $rc: $out"
echo "freeze-check.test: ok"
