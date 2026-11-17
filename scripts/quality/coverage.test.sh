#!/usr/bin/env bash
# coverage.sh --selfhost with a stub dotnet: a failing test run still writes the report (src/**/*.byn only, a file deleted
# again dropped), prints the test counts and exits non-zero; a passing run exits 0 (spec 019 T22).
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
d="$root/tmp/quality/coverage-test"; rm -rf "$d"; mkdir -p "$d/bin" "$d/tree/src" "$d/tree/lib"
fail() { echo "FAIL: $1"; echo "$2"; exit 1; }
touch "$d/tree/src/a.byn" "$d/tree/lib/b.byn"
# the stub's test run writes a report naming a src file, a lib file and a src file that no longer exists
cat > "$d/bin/dotnet" <<'SH'
#!/bin/sh
[ "$1" = test ] || exit 0
printf '{"version": 1, "kind": "coverage", "files": [{"path": "%s/src/a.byn", "lines": {"covered": 1, "total": 2, "missed": [2]}}, {"path": "%s/lib/b.byn", "lines": {"covered": 1, "total": 1, "missed": []}}, {"path": "%s/src/gone.byn", "lines": {"covered": 1, "total": 1, "missed": []}}]}\n' "$TREE" "$TREE" "$TREE" > "$BAYAN_COVERAGE/bayan-quality.json"
echo "$SUMMARY"
exit "$EXIT"
SH
chmod +x "$d/bin/dotnet"
run() { PATH="$d/bin:$PATH" TREE="$d/tree" SUMMARY="$1" EXIT="$2" bash "$root/scripts/quality/coverage.sh" --selfhost "$d/tree" --out "$d/out.json" 2> "$d/err.txt"; }

out=$(run 'Failed!  - Failed:     2, Passed:     5, Skipped:     0, Total:     7' 1) && fail "a failing test run exited 0" "$out"
echo "$out" | grep -qx 'tests: Failed! - Failed: 2, Passed: 5, Skipped: 0, Total: 7' || fail "no test counts" "$out"
[ "$(python3 -I -c 'import json, sys; print([f["path"] for f in json.load(open(sys.argv[1]))["files"]])' "$d/out.json")" = "['src/a.byn']" ] \
  || fail "the report is not src/a.byn alone" "$(cat "$d/out.json")"
grep -q 'dotnet test failed (exit 1)' "$d/err.txt" || fail "no failure message" "$(cat "$d/err.txt")"

rm -f "$d/out.json"
out=$(run 'Passed!  - Failed:     0, Passed:     7, Skipped:     0, Total:     7' 0) || fail "a passing test run exited non-zero" "$out$(cat "$d/err.txt")"
echo "$out" | grep -qx 'tests: Passed! - Failed: 0, Passed: 7, Skipped: 0, Total: 7' || fail "no test counts" "$out"
[ -f "$d/out.json" ] || fail "a passing run wrote no report" "$out"
echo PASS
