#!/usr/bin/env bash
# coverage.sh against a fixture tree and a stub BAYAN_EXE that writes each package's report (spec 019 T29): the packages'
# reports are merged; a file below its figure fails and is named; all at or above passes; a file with a figure missing
# from the report fails; a failing test run fails with the report written; a `dotnet` on PATH that exits 97 is never run.
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
# the stub driver: `test --coverage --package src src/<m>` writes $FIX/<m>.json as src/out/test/bayan-quality.json, exit $EXIT
cat > "$d/bin/bayan" <<'SH'
#!/bin/sh
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
run() { (cd "$t" && PATH="$d/bin:$PATH" CALLS="$d/calls" FIX="$d/fix" BAYAN_EXE="$d/bin/bayan" bash "$root/scripts/quality/coverage.sh" --root "$t" --out "$d/out.json" 2> "$d/err.txt"); }

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

[ ! -e "$d/calls" ] || fail "dotnet was called" "$(cat "$d/calls")"
echo PASS
