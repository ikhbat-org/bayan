#!/usr/bin/env bash
# Coverage ratchet (spec 019 R16, T29): `$BAYAN_EXE test --coverage --package src src/<m>` for each src/<m> with a test
# block, the packages' reports merged and compared with each file's T22 figure in tests/quality-baseline.json.
# usage: BAYAN_EXE=<driver> coverage.sh [--out FILE] [--root DIR] [--corpus DIR] [--add-report FILE]...
#        BAYAN_EXE=<driver> coverage.sh --corpus-run DIR [--shard i/n] [--jobs N] [--root DIR]
# --out: the merged report (bayan-quality.json, kind "coverage", paths relative to the root; default
#   tmp/quality/bayan-quality.json). --root: the tree whose src/ packages run and whose tests/quality-baseline.json is
#   read (default: this checkout; tests use a fixture tree).
# --corpus-run DIR (the golden corpus, T29; no gate): builds the driver with `--coverage` to DIR/bayan-cov and runs
#   `DIR/bayan-cov test tests/cases` with it as BAYAN_EXE, BAYAN_COVERAGE unset and BAYAN_COVERAGE_CASES=DIR/counters/c, so
#   each case's processes write DIR/counters/c.<case>.<pid> (src/driver/golden.byn goldenCoveragePrefix: a prefix per case,
#   so a pid that repeats over the run never overwrites another case's file). --shard is BAYAN_TEST_SHARD (scripts/test.sh
#   --shard), --jobs the runner's. Exit as the corpus run. One DIR per concurrent run; the counter files of all shards and
#   hosts are then copied into one directory, their names being distinct across them.
# --corpus DIR: the gate also counts the corpus: `$BAYAN_EXE build --coverage --counters DIR/c --package src src/driver`
#   adds up every DIR/c.* file into one more report, merged with the packages' ones. A DIR with no c.* file is exit 2.
# --add-report FILE (repeatable, T29c): a `bayan test --coverage` bayan-quality.json from another host (macOS's run of
#   src/driver), merged with the packages' ones. Its paths are full paths of that host's checkout: one outside the root
#   is read from its last `/src/` on.
# Exempt (T29c): before the comparison, a missed line, and a missed branch outcome on a line, that a valid
#   `// coverage-exempt: Qnnn` marker exempts (tools/coverage-gate.byn's rule, `coverage-gate --exempt` printing the
#   exempted `path:line`s of the src/ files holding a marker) leave the file's covered and total; an unknown one never
#   does. An invalid marker is exit 1, named by the tool. The written report keeps the raw counts; a file's gate line ends
#   in `(N exempt)` when N > 0.
# Merge: a line or branch counts as covered when any package's run covers it (a file is in the report of every package
# that compiles it). Gate: a file with a figure (coverage or branches not null) that the report lacks, or whose
# round(covered / total, 4) is below its figure, is printed, one line each. Exit 1 on such a file or a failing test run
# (the report is still written), 2 on a usage error or no report. The driver writes each report to src/out/test/, which
# is moved out and removed after each package. bash 3.2.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
out=""; corpus=""; corpus_run=""; shard=""; jobs=""; adds=()
while [ $# -gt 0 ]; do
  case "$1" in
    --out) [ $# -ge 2 ] || { echo "coverage.sh: --out expects a file" >&2; exit 2; }; out="$2"; shift 2 ;;
    --root) [ $# -ge 2 ] && [ -d "$2" ] || { echo "coverage.sh: --root expects a directory" >&2; exit 2; }; root="$(cd "$2" && pwd)"; shift 2 ;;
    --corpus) [ $# -ge 2 ] || { echo "coverage.sh: --corpus expects a directory of counter files" >&2; exit 2; }; corpus="$2"; shift 2 ;;
    --corpus-run) [ $# -ge 2 ] || { echo "coverage.sh: --corpus-run expects a directory" >&2; exit 2; }; corpus_run="$2"; shift 2 ;;
    --shard) [ $# -ge 2 ] || { echo "coverage.sh: --shard expects i/n" >&2; exit 2; }; shard="$2"; shift 2 ;;
    --jobs) [ $# -ge 2 ] || { echo "coverage.sh: --jobs expects a number" >&2; exit 2; }; jobs="$2"; shift 2 ;;
    --add-report) [ $# -ge 2 ] && [ -f "$2" ] || { echo "coverage.sh: --add-report expects a report file" >&2; exit 2; }; adds+=("$2"); shift 2 ;;
    *) echo "coverage.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$out" ] || out="$root/tmp/quality/bayan-quality.json"
[ -n "${BAYAN_EXE:-}" ] && [ -x "$BAYAN_EXE" ] || { echo "coverage.sh: BAYAN_EXE is not an executable: '${BAYAN_EXE:-}'" >&2; exit 2; }
if [ -n "$corpus_run" ]; then
  mkdir -p "$corpus_run/counters" || exit 2
  dir="$(cd "$corpus_run" && pwd)"; cov="$dir/bayan-cov"
  case "$(uname -s)" in (MINGW*|MSYS*|CYGWIN*) cov="$cov.exe" ;; esac
  cd "$root" || exit 2
  start=$SECONDS
  "$BAYAN_EXE" build --coverage --mode safe --package src -o "$cov" src/driver > "$dir/build.log" 2>&1 \
    || { echo "coverage.sh: building the coverage driver failed; log: $dir/build.log" >&2; exit 2; }
  set -- test tests/cases; [ -z "$jobs" ] || set -- "$@" --jobs "$jobs"
  (unset BAYAN_COVERAGE; BAYAN_EXE="$cov" BAYAN_COVERAGE_CASES="$dir/counters/c" BAYAN_TEST_SHARD="$shard" "$cov" "$@")
  rx=$?
  n=0; bytes=0
  for f in "$dir/counters"/c.*; do [ -f "$f" ] || continue; n=$((n + 1)); bytes=$((bytes + $(wc -c < "$f"))); done
  echo "coverage.sh: corpus${shard:+ shard $shard}: $n counter files, $bytes bytes in $dir/counters, $((SECONDS - start))s" >&2
  exit $rx
fi
if [ -n "$corpus" ]; then
  [ -d "$corpus" ] || { echo "coverage.sh: --corpus $corpus: no such counter directory" >&2; exit 2; }
  corpus="$(cd "$corpus" && pwd)"
  [ -n "$(find "$corpus" -maxdepth 1 -type f -name 'c.*' -print -quit)" ] || { echo "coverage.sh: --corpus $corpus: no counter file c.*" >&2; exit 2; }
fi
reports="$root/tmp/quality/coverage-reports"
rm -rf "$reports"
mkdir -p "$reports" "$(dirname "$out")" || exit 2
n=0
for a in ${adds[@]+"${adds[@]}"}; do n=$((n + 1)); cp "$a" "$reports/add-report.$n.json" || exit 2; done

start=$SECONDS
tx=0
cd "$root" || exit 2
exempt="$reports/exempt.txt"; : > "$exempt"
marked=$(grep -rl --include='*.byn' -e '// coverage-exempt:' src 2>/dev/null | sort)
if [ -n "$marked" ]; then
  # shellcheck disable=SC2086 # src/ paths hold no space
  bash "$here/../bayan-tool.sh" coverage-gate --exempt $marked > "$exempt" \
    || { echo "coverage.sh: an invalid coverage-exempt marker (above), or the tool failed" >&2; exit 1; }
fi
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
if [ -n "$corpus" ]; then
  echo "== corpus $corpus"
  "$BAYAN_EXE" build --coverage --counters "$corpus/c" --package src src/driver > /dev/null || tx=1
  if [ -f src/out/test/bayan-quality.json ]; then
    mv src/out/test/bayan-quality.json "$reports/corpus.json"
  else
    echo "coverage.sh: the corpus counters wrote no src/out/test/bayan-quality.json" >&2; tx=1
  fi
  rm -rf src/out/test; rmdir src/out 2>/dev/null
fi

python3 -I - "$root" "$out" "$root/tests/quality-baseline.json" "$exempt" "$reports"/*.json <<'PY'
import json, os, sys
from collections import Counter
root, out, baseline, reports = sys.argv[1], sys.argv[2], sys.argv[3], [p for p in sys.argv[5:] if os.path.isfile(p)]
# the exempted lines, `path:line` per line as tools/coverage-gate.byn `--exempt` prints them
exempt = {}
for l in open(sys.argv[4]).read().split():
    p, _, n = l.rpartition(":")
    exempt.setdefault(p, set()).add(int(n))
if not reports:
    print("coverage.sh: no package wrote a report", file=sys.stderr); sys.exit(2)
merged = {}
for p in reports:
    for f in json.load(open(p))["files"]:
        # `test --coverage` writes full paths, `build --coverage --counters` paths relative to the package root src/
        path = os.path.relpath(f["path"], root) if os.path.isabs(f["path"]) else os.path.join("src", f["path"])
        # another host's report: its own checkout's full paths
        if os.path.basename(p).startswith("add-report.") and not path.startswith("src/") and "/src/" in f["path"]:
            path = f["path"][f["path"].rindex("/src/") + 1:]
        if not (path.startswith("src/") and path.endswith(".byn") and os.path.isfile(os.path.join(root, path))):
            continue
        lines = f["lines"]
        br = f.get("branches") or {"total": 0, "missed": [], "unknown": []}
        # uncovered lines and branches, missed or unknown, as counts (two branches can share a line, column and outcome);
        # the merge keeps those no package covered
        ul = Counter(lines.get("missed", []) + lines.get("unknown", []))
        ub = Counter((b["line"], b["column"], b["outcome"]) for b in br.get("missed", []) + br.get("unknown", []))
        kl = set(lines.get("unknown", []))
        kb = set((b["line"], b["column"], b["outcome"]) for b in br.get("unknown", []))
        m = merged.get(path)
        if m is None:
            merged[path] = {"lines": lines["total"], "ul": ul, "branches": br["total"], "ub": ub, "kl": kl, "kb": kb}
        elif m["lines"] != lines["total"] or m["branches"] != br["total"]:
            print(f"coverage.sh: {path}: two packages count {m['lines']}/{lines['total']} lines, {m['branches']}/{br['total']} branches", file=sys.stderr)
            sys.exit(2)
        else:
            m["ul"] &= ul; m["ub"] &= ub; m["kl"] |= kl; m["kb"] |= kb
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
    ex, m, nex = exempt.get(path, set()), merged[path], 0
    for name, key in (("lines", "lines"), ("branches", "branches")):
        want = fig.get("coverage" if key == "lines" else "branches")
        if want is None:
            continue
        t = f[key]
        if key == "lines":
            n = sum(1 for l in t["missed"] if l in ex and l not in m["kl"])
        else:
            n = sum(1 for b in t["missed"] if b["line"] in ex and (b["line"], b["column"], b["outcome"]) not in m["kb"])
        nex += n
        total = t["total"] - n
        got = round(t["covered"] / total, 4) if total else (1.0 if t["total"] else None)
        if got is None or got < want:
            below.append(f"{name} {got} < {want}")
    if below:
        print(f"coverage: {path}: " + ", ".join(below) + (f" ({nex} exempt)" if nex else "")); low += 1
print(f"coverage: {len(files)} files measured, {low} below their figure")
sys.exit(1 if low else 0)
PY
gx=$?
echo "coverage.sh: $((SECONDS - start))s" >&2
[ $tx = 0 ] || echo "coverage.sh: a test run failed; the report above still counts it" >&2
[ $gx = 2 ] && exit 2
[ $tx = 0 ] && [ $gx = 0 ]
