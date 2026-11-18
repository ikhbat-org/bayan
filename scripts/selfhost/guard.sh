#!/bin/bash
# guard.sh — run in a writer worktree before finishing. Prints GUARD PASS or GUARD FAIL + the items to fix.
#   bash guard.sh --base <branch> --allow '<glob>[,<glob>…]' --filter '<word>[ <word>…]' [--task T<n>] [--mutate <file.byn>[,…]] [--spec <nnn>] [--scope-only]
# --filter words are each a scripts/test.sh part (golden|bayan|parity|scripts|runtime), run as `scripts/test.sh --only <part>`, or a
# `<kind>/<Class>/` selector, run as `bayan test tests/cases --only <selector>` (BAYAN_EXE, else the stage-1 binary scripts/bootstrap-build.sh prints).
# --spec picks the row of specs.tsv (default 010): its shared-state files are allowed in scope; --task names the task for the content checks;
# --scope-only stops after check 1 and 2 (land.sh --check-scope).
# Changed lib/std/**/*.byn files are treated like selfhost .byn files wherever the guard selects them (coverage, banned C#-isms);
# with one changed, the coverage run adds the `bayan` part to --filter, whose run of each std module's tests counts them,
# and check 5 runs the pinned `bayan format --check` over lib/std/ (skipped on Windows, as SourcesAreFormatted).
# Checks: 1 scope (changed files match --allow, plus the questions and progress-log docs, todo and tasks), 2 no junk (binary or extensionless files),
# 3 build (the stage-1 bayan), 4 tests pass with 0 skipped, and coverage (spec 013 T26): when the branch changes selfhost .byn files the
# tests run under BAYAN_COVERAGE with those files, and every line and branch of each function the branch touches (its span
# holds a line added or changed against the merge base with --base; a new function counts) must be covered, each missed one
# named (tools/coverage-gate.byn; `// coverage-exempt:` for code dead in the C#, `// coverage-blocked: Qnnn T<k> <fn>` for code
# behind sibling T<k>'s stub while T<k> is open and not --task); each file's other functions get one info line, never a FAIL; a file under another specs.tsv row's bydir (an 011 task editing src/semantics) has only its changed lines gated (Q871), while files outside every bydir (src/parser) keep the touched-function rule; a changed file the report has no entry for is one (Q820) unless its AST (pinned bayan parse --ast) holds no Function, Constructor, Getter, Property, Test or Block line: then an info line. The guard makes no baseline check of
# coverage: it leaves the report at tmp/guard-run/coverage/bayan-quality.json, and land.sh records it (raise-only) in
# tests/quality-baseline.json. 5 banned C#-isms in changed .byn, 6 mutation (spec 013 R14): every
# mutation site of the --mutate files must make the filtered tests fail (`bayan mutate --binary` over a BAYAN_SNAPSHOT
# recording; a survivor = an untested change; `@unobservable because "…"` marks a statement whose mutants no test can see),
# and no file's score may fall below tests/quality-baseline.json (only with --mutate),
# 7 content checks from tools/guard-checks.byn (C# oracle in the tests, no stubs or empty bodies left, ctx.byn only in the
# task's own section, no open gating Question, docs: progress log entry and Question line citations that hold).
# Per-task landing runs no mutation (land.sh drops --mutate, user decision 2026-11-01): it runs in batches and CI; coverage
# runs on every guard (when a selfhost .byn changed), landing included. A python helper that exits non-zero (a malformed report, manifest or baseline) is a
# FAIL item naming its input, never a silent pass.
set -u
BASE=""; ALLOW=""; FILTER=""; TASK=""; MUTATE=""; SPEC=010; SCOPEONLY=0
while [ $# -gt 0 ]; do case "$1" in
  --base) BASE=$2; shift 2;; --allow) ALLOW=$2; shift 2;; --filter) FILTER=$2; shift 2;; --task) TASK=$2; shift 2;;
  --mutate) MUTATE=$2; shift 2;; --spec) SPEC=$2; shift 2;; --scope-only) SCOPEONLY=1; shift;; *) echo "unknown arg $1"; exit 2;; esac; done
[ -n "$BASE" ] && [ -n "$FILTER" ] || { echo "need --base and --filter"; exit 2; }
ROW=$(awk -F'\t' -v s="$SPEC" 'NR>1 && $1==s' "$(dirname "$0")/specs.tsv")
[ -n "$ROW" ] || { echo "no row for spec $SPEC in specs.tsv"; exit 2; }
IFS=$'\t' read -r _ SDIR STASKS _ _ SHARED BYDIR _ <<< "$ROW"
FAIL=(); note() { FAIL+=("$1"); }
mkdir -p "$PWD/tmp/guard-run"; LOG=$PWD/tmp/guard-run

# 1 scope + 2 junk
CHANGED=$( { git diff --name-only "$BASE"...HEAD; git diff --name-only; git ls-files --others --exclude-standard; } | sort -u)
while IFS= read -r f; do
  [ -n "$f" ] || continue
  ok=0; case "$f" in docs/bayan-questions.md|docs/bayan-progress-log.md|work/todo.md|docs/specs/*/*-tasks.md|docs/specs/*/reviews/*.md) ok=1;; esac
  IFS=',' read -ra SH <<< "$SHARED"; for p in "${SH[@]}"; do [ "$f" = "$p" ] && ok=1; done
  IFS=',' read -ra PATS <<< "$ALLOW"; for p in "${PATS[@]}"; do [[ "$f" == $p ]] && ok=1; done
  [ $ok = 1 ] || note "scope: $f is outside --allow ($ALLOW); revert it or record the need as a Question"
  b=$(basename "$f"); [[ "$b" != *.* ]] && note "junk: $f has no extension (stray run-case output?); delete it"
  [ -f "$f" ] && ! grep -Iq . "$f" 2>/dev/null && [ -s "$f" ] && note "junk: $f is binary; delete it"
done <<< "$CHANGED"
if [ $SCOPEONLY = 1 ]; then
  if [ ${#FAIL[@]} = 0 ]; then echo "GUARD PASS"; exit 0; fi
  echo "GUARD FAIL (${#FAIL[@]} items):"; for x in "${FAIL[@]}"; do echo "- $x"; done; exit 1
fi
# the changed selfhost .byn files still present: the files coverage is measured over
COVER=$(while IFS= read -r f; do case "$f" in (src/*.byn|lib/std/*.byn) [ -f "$f" ] && echo "$f";; esac; done <<< "$CHANGED" | tr '\n' ',' | sed 's/,$//')
# a changed lib/std file is covered by its module's own tests (the `bayan` part), whatever --filter selects
TFILTER=$FILTER; case ",$COVER" in *,lib/std/*) case " $FILTER " in *" bayan "*) ;; *) TFILTER="$FILTER bayan";; esac;; esac
rm -f "$LOG/quality-"*.json  # a mutation report left by an earlier run must not reach this run's baseline check
COV="$LOG/coverage"; rm -f "$COV/bayan-quality.json" "$COV/functions.json"; TX=1

# 3 build: the stage-1 bayan, BAYAN_EXE when set
E=0; BEXE=${BAYAN_EXE:-}
if [ -z "$BEXE" ]; then
  BEXE=$(bash "$PWD/scripts/bootstrap-build.sh" 2> "$LOG/build.txt" | tail -1) && [ -x "$BEXE" ] || { E=1; note "build: bootstrap-build.sh failed — $(tail -1 "$LOG/build.txt")"; }
fi

# 4 tests: each --filter word runs on its own; a failing word fails the guard
if [ "$E" = 0 ]; then
  TX=0; CENV=(); [ -z "$COVER" ] || CENV=(BAYAN_COVERAGE="$COV" BAYAN_COVERAGE_FILES="$COVER"); : > "$LOG/test.txt"
  for w in $TFILTER; do
    case $w in golden|bayan|parity|scripts|runtime) cmd=(bash "$PWD/scripts/test.sh" --only "$w");; *) cmd=("$BEXE" test tests/cases --only "$w");; esac
    # the coverage report is written by the run itself (T29)
    env BAYAN_EXE="$BEXE" ${CENV[@]+"${CENV[@]}"} "${cmd[@]}" > "$LOG/test-word.txt" 2>&1; rc=$?
    { echo "== $w (exit $rc)"; cat "$LOG/test-word.txt"; } >> "$LOG/test.txt"
    [ $rc = 0 ] || { TX=1; note "tests: FAIL '$w' (exit $rc) — first failure: $(grep -m1 -iE 'fail|error' "$LOG/test-word.txt" | cut -c1-400)"; }
    grep -qE '^bayan: no (case|test) name contains' "$LOG/test-word.txt" && note "tests: '$w' matched no tests"
    grep -qE '^test: +[a-z]+ +skip ' "$LOG/test-word.txt" && note "tests: skipped tests present ('$w')"
  done
fi

# 4 coverage of the functions the branch touches in the changed selfhost .byn files (a red run's coverage proves nothing):
# 100% of their lines and branches; no baseline check (see the header)
if [ $TX = 0 ] && [ -n "$COVER" ]; then
  if [ ! -f "$COV/bayan-quality.json" ]; then
    note "coverage: the tests wrote no tmp/guard-run/coverage/bayan-quality.json: no test under --filter '$TFILTER' builds a selfhost program with $COVER"
  else
    # a changed file no build under --filter compiles has no entry in the report, so none of its functions is checked (Q820);
    # the tool failing (pinned build, compile, toolchain, a malformed report) is a FAIL item naming its last stderr line
    miss=$(bash "$(dirname "$0")/../bayan-tool.sh" coverage-missing "$COV/bayan-quality.json" "$COVER" 2> "$LOG/coverage-missing.txt") \
      || { note "coverage: coverage-missing failed: $(tail -1 "$LOG/coverage-missing.txt")"; miss=""; }
    while read -r f; do
      [ -n "$f" ] || continue
      # a file declaring no function has no counters, so the report never lists it: nothing to cover (any doubt stays a FAIL item)
      if CLI=$(bash "$(dirname "$0")/../pinned-bayan.sh" 2> /dev/null) && ast=$("$CLI" parse --ast "$f" 2> /dev/null) \
        && ! echo "$ast" | awk '$1 ~ /^(Function|Constructor|Getter|Property|Test|Block)$/ { found = 1 } END { exit !found }'; then
        echo "coverage: $f declares no function; nothing to cover"; continue
      fi
      note "coverage: $f is in no build under --filter '$TFILTER' (no entry in tmp/guard-run/coverage/bayan-quality.json), so its touched functions are unchecked"
    done <<< "$miss"
    out=$(bash "$(dirname "$0")/../bayan-tool.sh" coverage-gate "$(git merge-base "$BASE" HEAD)" "$COV/bayan-quality.json" "$COV/functions.json" \
      "$SDIR/$STASKS" "$TASK" "$BYDIR" 2> "$LOG/coverage-gate.txt") \
      || note "coverage: $(tail -1 "$LOG/coverage-gate.txt")"
    while read -r l; do case "$l" in "- "*) note "${l#- }";; ?*) echo "$l";; esac; done <<< "$out"
  fi
fi

# 5 banned C#-isms (Bayan has none of these; see scripts/selfhost/bayan-cheatsheet.md)
while IFS= read -r f; do case "$f" in *.byn) [ -f "$f" ] || continue
  grep -nE '^\s*(let|var)\s*\(' "$f" | head -3 | while read -r l; do echo "banned: $f:${l%%:*} tuple destructuring"; done
  grep -nE '[A-Za-z_)]\.[0-9]+\b' "$f" | grep -vE '"[^"]*\.[0-9]' | head -3 | while read -r l; do echo "banned: $f:${l%%:*} tuple field .N"; done
;; esac; done <<< "$CHANGED" > "$LOG/banned.txt"
while read -r l; do [ -n "$l" ] && note "$l"; done < "$LOG/banned.txt"

# 5 bayan format --check over lib/std/ (only when the branch changes a lib/std .byn file; skipped on Windows, where pinned-bayan.sh exits 127)
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) ;; *)
  case ",$COVER" in *,lib/std/*)
    if CLI=$(bash "$(dirname "$0")/../pinned-bayan.sh" 2> "$LOG/pinned.txt" | tail -1) && [ -n "$CLI" ]; then
      fmt=$("$CLI" format --check lib/std 2>&1) || note "format: bayan format --check lib/std failed: $(echo "$fmt" | grep -v '^\s*$' | head -5 | tr '\n' ' ')"
    else note "format: no pinned bayan for the lib/std format check — $(tail -1 "$LOG/pinned.txt")"; fi;;
  esac;;
esac

# 7 content checks (before mutations: they are cheap)
# the task comes from --task
if [ -n "$TASK" ]; then
  out=$(bash "$(dirname "$0")/../bayan-tool.sh" guard-checks "$BASE" "$TASK" "$ALLOW" "$SPEC" 2> "$LOG/checks.txt") || note "checks: guard-checks failed: $(tail -1 "$LOG/checks.txt")"
  while read -r l; do [ -n "$l" ] && note "$l"; done <<< "$out"
else note "checks: no --task, so the content checks cannot run (pass --task T<n>)"; fi

# 6 mutations (only when everything above passed: a mutation run on a red tree proves nothing)
# the recording and the per-build runs are mutation-step.sh (shared with mutate-batch.sh); the reports are copied to
# tmp/guard-run/ as quality-<n>-<binary>.json
if [ ${#FAIL[@]} = 0 ] && [ -n "$MUTATE" ]; then
  . "$(dirname "$0")/mutation-step.sh"
  if mutation_step "$LOG" "$FILTER" "$MUTATE" 1; then
    # a score below tests/quality-baseline.json fails (mutate-batch.sh, the batch run, raises the baseline)
    if ls "$LOG/quality-"*.json > /dev/null 2>&1; then
      # exit 1 with lines: the drops; a non-zero exit without them: quality-baseline failed on its inputs
      out=$(bash "$(dirname "$0")/../bayan-tool.sh" quality-baseline check tests/quality-baseline.json . "$LOG/quality-"*.json 2> "$LOG/baseline.txt"); BX=$?
      while read -r l; do [ -n "$l" ] && note "$l"; done <<< "$out"
      [ $BX = 0 ] || [ -n "$out" ] || note "baseline: quality-baseline check failed on tests/quality-baseline.json and tmp/guard-run/quality-*.json — $(tail -1 "$LOG/baseline.txt")"
    fi
  fi
fi

if [ ${#FAIL[@]} = 0 ]; then echo "GUARD PASS"; exit 0; fi
echo "GUARD FAIL (${#FAIL[@]} items):"; for x in "${FAIL[@]}"; do echo "- $x"; done; exit 1
