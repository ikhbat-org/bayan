#!/usr/bin/env bash
# C# coverage report (spec 013 R15): dotnet test with coverlet, converted to bayan-quality.json (kind "coverage").
# usage: coverage.sh [--out FILE] [-- dotnet test args, e.g. --filter ...]
#        coverage.sh --selfhost DIR [--out FILE] [-- dotnet test args]
# --selfhost DIR: the whole xUnit suite of the source tree DIR under BAYAN_COVERAGE (spec 013 T26) instead of coverlet; the
# report keeps DIR's src/**/*.byn files, their paths relative to DIR (spec 019 R16, T22). The whole-suite baseline at a tag:
#   mkdir -p tmp/v0.3.2 && git archive v0.3.2 | tar -x -C tmp/v0.3.2
#   bash scripts/quality/coverage.sh --selfhost tmp/v0.3.2 --out tmp/quality/selfhost-v0.3.2.json
#   bash scripts/bayan-tool.sh quality-baseline update tests/quality-baseline.json . tmp/quality/selfhost-v0.3.2.json
set -euo pipefail
export MSBUILDDISABLENODEREUSE=1 DOTNET_CLI_USE_MSBUILD_SERVER=0  # no MSBuild worker or build server outlives the run
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
out="$repo/tmp/quality/bayan-quality.json"
selfhost=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out) out="$2"; shift 2 ;;
    --selfhost) selfhost="$(cd "$2" && pwd)"; shift 2 ;;
    --) shift; break ;;
    *) echo "coverage.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done
results="$repo/tmp/quality/coverlet"; [ -z "$selfhost" ] || results="$repo/tmp/quality/selfhost"
rm -rf "$results"
mkdir -p "$results" "$(dirname "$out")"
project="${selfhost:-$repo}/csharp/tests/Bayan.Tests/Bayan.Tests.csproj"

start=$SECONDS
dotnet build "$project" -v q --nologo >&2
built=$SECONDS
if [ -n "$selfhost" ]; then
  # every selfhost build counts all its files; the harness writes the report when the test host exits, merging every
  # build's counters, so vstest is given as long as guard.sh gives it
  # a failing test still leaves a report, written below; the script then exits with dotnet test's status
  tx=0; BAYAN_COVERAGE="$results" VSTEST_TESTHOST_SHUTDOWN_TIMEOUT=600000 \
    dotnet test "$project" --no-build -v q --nologo "$@" 2>&1 | tee "$repo/tmp/quality/selfhost-test.txt" >&2 || tx=$?
  [ -f "$results/bayan-quality.json" ] || { echo "coverage.sh: the harness wrote no bayan-quality.json" >&2; exit 1; }
  python3 -I - "$results/bayan-quality.json" "$selfhost" "$out" <<'PY'
import json, os, sys
report, root, out = sys.argv[1:]
r = json.load(open(report))
r["files"] = [dict(f, path=os.path.relpath(f["path"], root)) for f in r["files"]]
# a file a test wrote under src/ and deleted again (src/t-case.byn) is not part of the tree
r["files"] = [f for f in r["files"] if f["path"].startswith("src/") and f["path"].endswith(".byn") and os.path.isfile(os.path.join(root, f["path"]))]
json.dump(r, open(out, "w"), indent=2)
PY
  echo "selfhost coverage: $((built - start))s build, $((SECONDS - start))s total" >&2
  echo "tests: $(grep -E '^(Passed|Failed)! ' "$repo/tmp/quality/selfhost-test.txt" | tr -s ' ' || echo "no summary line")"
  echo "wrote $out"
  [ $tx = 0 ] || echo "coverage.sh: dotnet test failed (exit $tx); the report above still counts the run" >&2
  exit $tx
fi
dotnet test "$project" --no-build --collect:"XPlat Code Coverage" --results-directory "$results" -v q --nologo "$@" >&2
cobertura="$(find "$results" -name 'coverage.cobertura.xml' | head -n 1)"
if [ -z "$cobertura" ]; then echo "coverage.sh: coverlet wrote no coverage.cobertura.xml" >&2; exit 1; fi
python3 -I "$here/cobertura_to_quality.py" "$cobertura" "$repo" "$out" "$((built - start))" "$((SECONDS - start))"
echo "wrote $out"
