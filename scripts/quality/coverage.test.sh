#!/usr/bin/env bash
# coverage.sh against a fixture tree and a stub BAYAN_EXE that writes each package's report (spec 019 T29): the packages'
# reports are merged; a file below its figure fails and is named; all at or above passes; a file with a figure missing
# from the report fails; a failing test run fails with the report written; a `dotnet` on PATH that exits 97 is never run.
# The corpus part (T29), stubbed, no real corpus run: --corpus-run builds `--coverage` to DIR/bayan-cov and runs `test
# tests/cases` with it as BAYAN_EXE, BAYAN_COVERAGE unset, BAYAN_COVERAGE_CASES=DIR/counters/c (the prefix the runner extends
# per case, src/driver/golden.byn goldenCoveragePrefix and its test block) and the shard; --corpus merges the `--counters`
# report with the packages' ones (a line only the corpus covers counts); a file still below fails; a missing counter
# directory, or one with no c.* file, fails with a message.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
d="$root/tmp/quality/coverage-test"; rm -rf "$d"; mkdir -p "$d/bin" "$d/tree/src/a" "$d/tree/src/b" "$d/tree/src/c" "$d/tree/tests"
fail() { echo "FAIL: $1"; echo "$2"; exit 1; }
t="$d/tree"
printf 'test "x" {}\n' > "$t/src/a/a.byn"; printf 'test "y" {}\n' > "$t/src/b/b.byn"; printf 'fn f() {}\n' > "$t/src/c/c.byn"
cat > "$d/bin/dotnet" <<'SH'
#!/bin/sh
echo "dotnet called: $*" >> "$CALLS"; exit 97
SH
# the stub driver: `test --coverage --package src src/<m>` writes $FIX/<m>.json as src/out/test/bayan-quality.json, exit $EXIT;
# `build --coverage ... -o <exe> src/driver` copies itself to <exe>; `test tests/cases ...` logs its arguments and env to
# $CORPUS_LOG and writes two counter files under $BAYAN_COVERAGE_CASES; `build --coverage --counters <p> --package src
# src/driver` logs <p> and the files <p>.* and writes $FIX/$CORPUS.json (paths relative to src/) as the report
cat > "$d/bin/bayan" <<'SH'
#!/bin/sh
case "$*" in
  "build --coverage --mode safe --package src -o "*" src/driver") cp "$0" "$8"; exit 0 ;;
  "test tests/cases"*) echo "$* | BAYAN_EXE=$BAYAN_EXE CASES=$BAYAN_COVERAGE_CASES SHARD=$BAYAN_TEST_SHARD COV=${BAYAN_COVERAGE-unset}" >> "$CORPUS_LOG"
    echo x > "$BAYAN_COVERAGE_CASES.lex_2fa.11"; echo y > "$BAYAN_COVERAGE_CASES.run_2fb.11"; exit "${EXIT:-0}" ;;
  "build --coverage --counters "*" --package src src/driver") echo "counters $4: $(ls "$4".* | wc -l | tr -d ' ') files" >> "$CORPUS_LOG"
    mkdir -p src/out/test; cp "$FIX/$CORPUS.json" src/out/test/bayan-quality.json; exit 0 ;;
esac
[ "$1 $2 $3 $4" = "test --coverage --package src" ] || { echo "stub bayan: unexpected $*" >&2; exit 64; }
m=${5#src/}; mkdir -p src/out/test; sed "s|@|$PWD|g" "$FIX/$m.json" > src/out/test/bayan-quality.json
echo "ran $5"; exit "${EXIT:-0}"
SH
chmod +x "$d/bin/dotnet" "$d/bin/bayan"
# report <file> <covered> <total> <missed lines> [<missed branches>]: one file entry, two branches each
rep() { printf '{"path": "@/src/%s", "lines": {"covered": %s, "total": %s, "missed": [%s], "unknown": []}, "branches": {"covered": %s, "total": 2, "missed": [%s], "unknown": []}, "errorPaths": []}' \
  "$1" "$2" "$3" "$4" "$5" "$6"; }
fixture() { mkdir -p "$d/fix"; printf '{"version": 1, "kind": "coverage", "files": [%s, %s, %s]}\n' "$1" "$2" "$3" > "$d/fix/$4.json"; }
# a.byn: 2/4 in package a's run, lines 3 and 4 covered by b's run, so 4/4 merged; b.byn 3/4, its two branches missed and
# alike (line, column and outcome), so 0/2; gone.byn is not in the tree
twice='{"line": 5, "column": 1, "outcome": true}, {"line": 5, "column": 1, "outcome": true}'
fixture "$(rep a/a.byn 2 4 '3, 4' 1 '{"line": 1, "column": 1, "outcome": true}')" "$(rep b/b.byn 3 4 2 0 "$twice")" "$(rep a/gone.byn 1 1 '' 2 '')" a
fixture "$(rep a/a.byn 2 4 '1, 2' 1 '{"line": 1, "column": 1, "outcome": false}')" "$(rep b/b.byn 3 4 2 0 "$twice")" "$(rep a/gone.byn 1 1 '' 2 '')" b
base() { printf '{"version": 1, "files": {"src/a/a.byn": {"mutation": null, "coverage": 1.0, "branches": 1.0}, "src/b/b.byn": {"mutation": null, "coverage": %s, "branches": null}, "src/c/c.byn": {"mutation": null, "coverage": null, "branches": null}%s}}\n' "$1" "$2" > "$t/tests/quality-baseline.json"; }
run() { (cd "$t" && PATH="$d/bin:$PATH" CALLS="$d/calls" FIX="$d/fix" CORPUS_LOG="$d/corpus.log" BAYAN_EXE="$d/bin/bayan" bash "$root/scripts/quality/coverage.sh" --root "$t" --out "$d/out.json" "$@" 2> "$d/err.txt"); }
# the corpus reports, paths relative to src/: `lift` covers b.byn's line 2 and one of its two branches, `still` leaves line 2
fixture "$(rep a/a.byn 0 4 '1, 2, 3, 4' 0 "$twice" | sed 's|@/src/||')" "$(rep b/b.byn 4 4 '' 1 '{"line": 5, "column": 1, "outcome": true}' | sed 's|@/src/||')" "$(rep a/gone.byn 1 1 '' 2 '' | sed 's|@/src/||')" lift
fixture "$(rep a/a.byn 0 4 '1, 2, 3, 4' 0 "$twice" | sed 's|@/src/||')" "$(rep b/b.byn 3 4 2 0 "$twice" | sed 's|@/src/||')" "$(rep a/gone.byn 1 1 '' 2 '' | sed 's|@/src/||')" still

base 0.75 ''
out=$(run) || fail "all at or above their figure exited non-zero" "$out$(cat "$d/err.txt")"
echo "$out" | grep -qx 'coverage: 2 files measured, 0 below their figure' || fail "no count line" "$out"
[ "$(python3 -I -c 'import json, sys; print([(f["path"], f["lines"]["covered"], f["branches"]["covered"]) for f in json.load(open(sys.argv[1]))["files"]])' "$d/out.json")" \
  = "[('src/a/a.byn', 4, 2), ('src/b/b.byn', 3, 0)]" ] || fail "the merged report is not a.byn 4/4 2/2 and b.byn 3/4 0/2" "$(cat "$d/out.json")"
[ ! -e "$t/src/out" ] || fail "src/out is left in the tree" "$(ls -R "$t/src/out")"
echo "$out" | grep -q 'ran src/c' && fail "src/c, with no test block, was run" "$out"

base 0.7501 ''
out=$(run) && fail "a file below its figure exited 0" "$out"
echo "$out" | grep -qx 'coverage: src/b/b.byn: lines 0.75 < 0.7501' || fail "the file below is not named" "$out"
[ "$(echo "$out" | grep -c '^coverage: src/')" = 1 ] || fail "more than the one file below is named" "$out"

base 0.75 ', "src/a/new.byn": {"mutation": null, "coverage": 0.5, "branches": null}'
out=$(run) && fail "a file missing from the report exited 0" "$out"
echo "$out" | grep -qx 'coverage: src/a/new.byn: in the baseline, not in the report' || fail "the missing file is not named" "$out"

base 0.75 ''
out=$(EXIT=1 run) && fail "a failing test run exited 0" "$out"
grep -q 'a test run failed' "$d/err.txt" || fail "no failure message" "$(cat "$d/err.txt")"
[ -f "$d/out.json" ] || fail "a failing run wrote no report" "$out"

# the corpus run: the coverage build, then the corpus through it with the per-case prefix and the shard, BAYAN_COVERAGE unset
out=$(BAYAN_COVERAGE=stray run --corpus-run "$d/cr" --shard 2/3 --jobs 4) || fail "the corpus run exited non-zero" "$out$(cat "$d/err.txt")"
[ -x "$d/cr/bayan-cov" ] || fail "no coverage driver at DIR/bayan-cov" "$(ls -la "$d/cr")"
[ "$(cat "$d/corpus.log")" = "test tests/cases --jobs 4 | BAYAN_EXE=$d/cr/bayan-cov CASES=$d/cr/counters/c SHARD=2/3 COV=unset" ] \
  || fail "the corpus did not run through DIR/bayan-cov with BAYAN_COVERAGE_CASES=DIR/counters/c, the shard and BAYAN_COVERAGE unset" "$(cat "$d/corpus.log")"
grep -qx "coverage.sh: corpus shard 2/3: 2 counter files, 4 bytes in $d/cr/counters, [0-9]*s" "$d/err.txt" || fail "no counter count line" "$(cat "$d/err.txt")"
[ -z "$out" ] || fail "the corpus run printed the gate" "$out"
rm -f "$d/corpus.log"
out=$(EXIT=1 run --corpus-run "$d/cr") && fail "a failing corpus run exited 0" "$out"

# the merge: b.byn is 0.75 by the packages alone and 1.0 with the corpus; its branches 0/2 and 1/2
base 1.0 ''
out=$(CORPUS=lift run --corpus "$d/cr/counters") || fail "the corpus did not lift b.byn to its figure" "$out$(cat "$d/err.txt")"
grep -qx "counters $d/cr/counters/c: 2 files" "$d/corpus.log" || fail "the counters were not read from DIR/c.*" "$(cat "$d/corpus.log")"
[ "$(python3 -I -c 'import json, sys; print([(f["path"], f["lines"]["covered"], f["branches"]["covered"]) for f in json.load(open(sys.argv[1]))["files"]])' "$d/out.json")" \
  = "[('src/a/a.byn', 4, 2), ('src/b/b.byn', 4, 1)]" ] || fail "the merged report is not a.byn 4/4 2/2 and b.byn 4/4 1/2" "$(cat "$d/out.json")"
[ ! -e "$t/src/out" ] || fail "src/out is left in the tree after the corpus report" "$(ls -R "$t/src/out")"
out=$(CORPUS=still run --corpus "$d/cr/counters") && fail "a file below its figure with the corpus exited 0" "$out"
echo "$out" | grep -qx 'coverage: src/b/b.byn: lines 0.75 < 1.0' || fail "the file below with the corpus is not named" "$out"

# a missing counter directory, and one with no counter file
out=$(CORPUS=lift run --corpus "$d/none") && fail "a missing counter directory exited 0" "$out"
grep -qx "coverage.sh: --corpus $d/none: no such counter directory" "$d/err.txt" || fail "no message for the missing directory" "$(cat "$d/err.txt")"
mkdir -p "$d/empty"
out=$(CORPUS=lift run --corpus "$d/empty") && fail "a counter directory with no c.* exited 0" "$out"
grep -qx "coverage.sh: --corpus $d/empty: no counter file c.\*" "$d/err.txt" || fail "no message for the empty directory" "$(cat "$d/err.txt")"
# more counter files than one argv holds: the existence check must not expand them into a command line
mkdir -p "$d/many"; long=$(printf 'x%.0s' $(seq 1 200)); (cd "$d/many" && seq 1 12000 | sed "s/^/c.$long./" | xargs touch)
out=$(CORPUS=lift run --corpus "$d/many") || true
grep -q "no counter file" "$d/err.txt" && fail "a directory of 12000 counter files was reported as empty" "$(head -3 "$d/err.txt")"

[ ! -e "$d/calls" ] || fail "dotnet was called" "$(cat "$d/calls")"
echo PASS
