#!/usr/bin/env bash
# Coverage ratchet (spec 019 R16, T29): `$BAYAN_EXE test --coverage --package src src/<m>` for each src/<m> with a test
# block, the packages' reports merged and compared with each file's T22 figure in tests/quality-baseline.json.
# usage: BAYAN_EXE=<driver> coverage.sh [--out FILE] [--root DIR]
# --out: the merged report (bayan-quality.json, kind "coverage", paths relative to the root; default
#   tmp/quality/bayan-quality.json). --root: the tree whose src/ packages run and whose tests/quality-baseline.json is
#   read (default: this checkout; tests use a fixture tree).
# Merge: a line or branch counts as covered when any package's run covers it (a file is in the report of every package
# that compiles it). Gate: a file with a figure (coverage or branches not null) that the report lacks, or whose
# round(covered / total, 4) is below its figure, is printed, one line each. Exit 1 on such a file or a failing test run
# (the report is still written), 2 on a usage error or no report. The driver writes each report to src/out/test/, which
# is moved out and removed after each package. bash 3.2.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
out=""
while [ $# -gt 0 ]; do
  case "$1" in
    --out) [ $# -ge 2 ] || { echo "coverage.sh: --out expects a file" >&2; exit 2; }; out="$2"; shift 2 ;;
    --root) [ $# -ge 2 ] && [ -d "$2" ] || { echo "coverage.sh: --root expects a directory" >&2; exit 2; }; root="$(cd "$2" && pwd)"; shift 2 ;;
    *) echo "coverage.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$out" ] || out="$root/tmp/quality/bayan-quality.json"
[ -n "${BAYAN_EXE:-}" ] && [ -x "$BAYAN_EXE" ] || { echo "coverage.sh: BAYAN_EXE is not an executable: '${BAYAN_EXE:-}'" >&2; exit 2; }
reports="$root/tmp/quality/coverage-reports"
rm -rf "$reports"
mkdir -p "$reports" "$(dirname "$out")" || exit 2

start=$SECONDS
tx=0
cd "$root" || exit 2
for d in src/*/; do
  d=${d%/}
  grep -lq '^test "' "$d"/*.byn 2>/dev/null || continue
  echo "== $d"
  "$BAYAN_EXE" test --coverage --package src "$d" || tx=1
  if [ -f src/out/test/bayan-quality.json ]; then
    mv src/out/test/bayan-quality.json "$reports/${d#src/}.json"
  else
    echo "coverage.sh: $d wrote no src/out/test/bayan-quality.json" >&2; tx=1
  fi
  rm -rf src/out/test; rmdir src/out 2>/dev/null
done

python3 -I - "$root" "$out" "$root/tests/quality-baseline.json" "$reports"/*.json <<'PY'
import json, os, sys
from collections import Counter
root, out, baseline, reports = sys.argv[1], sys.argv[2], sys.argv[3], [p for p in sys.argv[4:] if os.path.isfile(p)]
if not reports:
    print("coverage.sh: no package wrote a report", file=sys.stderr); sys.exit(2)
merged = {}
for p in reports:
    for f in json.load(open(p))["files"]:
        path = os.path.relpath(f["path"], root) if os.path.isabs(f["path"]) else f["path"]
        if not (path.startswith("src/") and path.endswith(".byn") and os.path.isfile(os.path.join(root, path))):
            continue
        lines = f["lines"]
        br = f.get("branches") or {"total": 0, "missed": [], "unknown": []}
        # uncovered lines and branches, missed or unknown, as counts (two branches can share a line, column and outcome);
        # the merge keeps those no package covered
        ul = Counter(lines.get("missed", []) + lines.get("unknown", []))
        ub = Counter((b["line"], b["column"], b["outcome"]) for b in br.get("missed", []) + br.get("unknown", []))
        m = merged.get(path)
        if m is None:
            merged[path] = {"lines": lines["total"], "ul": ul, "branches": br["total"], "ub": ub}
        elif m["lines"] != lines["total"] or m["branches"] != br["total"]:
            print(f"coverage.sh: {path}: two packages count {m['lines']}/{lines['total']} lines, {m['branches']}/{br['total']} branches", file=sys.stderr)
            sys.exit(2)
        else:
            m["ul"] &= ul; m["ub"] &= ub
files = []
for path in sorted(merged):
    m = merged[path]
    files.append({"path": path,
                  "lines": {"covered": m["lines"] - sum(m["ul"].values()), "total": m["lines"],
                            "missed": sorted(m["ul"].elements())},
                  "branches": {"covered": m["branches"] - sum(m["ub"].values()), "total": m["branches"],
                               "missed": [{"line": l, "column": c, "outcome": o} for l, c, o in sorted(m["ub"].elements())]}})
json.dump({"version": 1, "kind": "coverage", "tool": "bayan test --coverage", "files": files}, open(out, "w"), indent=2)
print(f"wrote {out}")
by = {f["path"]: f for f in files}
low = 0
for path, fig in sorted(json.load(open(baseline))["files"].items()):
    if fig.get("coverage") is None and fig.get("branches") is None:
        continue
    f = by.get(path)
    if f is None:
        print(f"coverage: {path}: in the baseline, not in the report"); low += 1; continue
    below = []
    for name, key in (("lines", "lines"), ("branches", "branches")):
        want = fig.get("coverage" if key == "lines" else "branches")
        if want is None:
            continue
        t = f[key]
        got = round(t["covered"] / t["total"], 4) if t["total"] else None
        if got is None or got < want:
            below.append(f"{name} {got} < {want}")
    if below:
        print(f"coverage: {path}: " + ", ".join(below)); low += 1
print(f"coverage: {len(files)} files measured, {low} below their figure")
sys.exit(1 if low else 0)
PY
gx=$?
echo "coverage.sh: $((SECONDS - start))s" >&2
[ $tx = 0 ] || echo "coverage.sh: a test run failed; the report above still counts it" >&2
[ $gx = 2 ] && exit 2
[ $tx = 0 ] && [ $gx = 0 ]
