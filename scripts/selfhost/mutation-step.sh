#!/bin/bash
# mutation-step.sh — the mutation step shared by guard.sh (check 6) and mutate-batch.sh (spec 013 T28); source it, do not run it.
#   mutation_step <log dir (absolute, under $PWD)> <filter> <file.byn>[,…] <1 = survivors are FAIL items | 0 = they are not>
# <filter> is `<kind>/<Class>/` selectors joined by `|` or spaces (mutate-plan's, guard.sh's --filter words); a scripts/test.sh
# part word (golden|bayan|parity|scripts|runtime) records nothing and is skipped. The selected golden cases are recorded once
# (`$BAYAN_EXE test tests/cases --only <selector>…` under BAYAN_SNAPSHOT, spec 019 T48c; no dotnet) against schemata builds whose
# sites lie only in the files, then `bayan mutate --binary` runs every site of each build, replaying the recording per mutant
# (replay.py); sites under `@unobservable because "…"` come back marked, not survived. The reports are copied to
# <log dir>/quality-<n>-<binary>.json. BAYAN_EXE is the driver under test (the caller sets it).
# Problems go to the caller's note() (which fills its FAIL array: the step runs only while FAIL is empty). Returns 0 when it
# reached the per-build runs, 1 when the CLI, the recording or the manifest stopped it before. A recording whose cases ran and
# failed (golden lines `failed <kind>/<case>`, `timed out <kind>/<case>`) is noted as `mutation: recording under BAYAN_SNAPSHOT:
# N test(s) failed`, naming each; any other recording failure (no case ran, the driver crashed) as `mutation: recording the
# tests under BAYAN_SNAPSHOT failed`.
mutation_step() {
  local LOG=$1 FILTER=$2 MUTATE=$3 SURV=$4 REL=${1#$PWD/} n name bin sites l MX failed first w
  local BAYAN SNAP=$1/snap REPLAY ONLY
  REPLAY=$(dirname "${BASH_SOURCE[0]}")/replay.py
  # `bayan mutate` is tooling: it runs from the pinned build of dev (scripts/pinned-bayan.sh), never the branch under test
  if ! BAYAN=$(bash "$(dirname "${BASH_SOURCE[0]}")/../pinned-bayan.sh" 2> "$LOG/pinned-bayan.txt"); then
    note "mutation: no pinned bayan — $(tail -1 "$LOG/pinned-bayan.txt")"
  else
    rm -f "$SNAP/manifest.json" "$SNAP/runs.jsonl"
    ONLY=(); for w in ${FILTER//|/ }; do case $w in golden|bayan|parity|scripts|runtime) ;; *) ONLY+=(--only "$w");; esac; done
    if [ -z "${BAYAN_EXE:-}" ] || [ ! -x "$BAYAN_EXE" ]; then
      note "mutation: BAYAN_EXE='${BAYAN_EXE:-}' is not an executable bayan driver to record with"
    elif [ ${#ONLY[@]} = 0 ]; then
      note "mutation: --filter '$FILTER' names no <kind>/<Class>/ selector to record"
    elif ! BAYAN_SNAPSHOT=$SNAP BAYAN_SNAPSHOT_FILES=$MUTATE "$BAYAN_EXE" test tests/cases "${ONLY[@]}" > "$LOG/record.txt" 2>&1; then
      # cases that ran and failed fail the same way on every file of the group; every one is named, as the first alone
      # hid the other two on 2026-11-09. Only the runner's result lines count (`failed <kind>/<case>`, no space in the name)
      failed=$(awk '/^(failed|timed out) [^ ]+$/ { sub(/^(failed|timed out) /, ""); if (!s[$0]++) print }' "$LOG/record.txt")
      first=$(awk '/^(failed|timed out) [^ ]+$/ { on = 1; next } on && /^    / { if (++n > 8) exit; sub(/^ +/, ""); if ($0 != "") printf "%s ", $0; next } on { exit }' "$LOG/record.txt" | sed 's/ $//' | cut -c1-400)
      [ -n "$first" ] || first=$(tail -1 "$LOG/record.txt" | cut -c1-400)
      if [ -n "$failed" ]; then
        note "mutation: recording under BAYAN_SNAPSHOT: $(wc -l <<< "$failed" | tr -d ' ') test(s) failed ($REL/record.txt): $(awk 'NR > 1 { printf "; " } { printf "%s", $0 }' <<< "$failed") — first: $first"
      else
        note "mutation: recording the tests under BAYAN_SNAPSHOT failed ($REL/record.txt) — $first"
      fi
    fi
    if [ ${#FAIL[@]} = 0 ] && [ ! -f "$SNAP/manifest.json" ]; then
      note "mutation: the recording wrote no $REL/snap/manifest.json: no case under --filter '$FILTER' builds a selfhost program"; fi
  fi
  if [ ${#FAIL[@]} = 0 ]; then
    BUILDS=$(bash "$(dirname "${BASH_SOURCE[0]}")/../bayan-tool.sh" manifest-builds "$SNAP/manifest.json" 2> "$LOG/manifest.txt") \
      || note "mutation: $REL/snap/manifest.json is unreadable — $(tail -1 "$LOG/manifest.txt")"
  fi
  [ ${#FAIL[@]} = 0 ] || return 1
  n=0
  while IFS=$'\t' read -r bin sites; do
    [ -n "$bin" ] || continue; n=$((n+1)); name=$n-$(basename "$bin"); rm -f "$(dirname "$bin")/bayan-quality.json"
    # site ids are per build: the replay runs only this build's recorded runs
    "$BAYAN" mutate --binary "$bin" --sites "$sites" -- python3 -I "$REPLAY" --binary "$bin" "$SNAP" > "$LOG/mutate-$name.txt" 2>&1; MX=$?
    # bayan mutate exits 1 only when mutant 0 fails (usage errors exit 2, a gate below its minimum 3)
    if [ $MX = 1 ]; then
      note "mutation: the recording does not replay on the unmutated build $bin (mutant 0) — $(BAYAN_MUTANT=0 python3 -I "$REPLAY" --binary "$bin" "$SNAP" 2>&1 | tail -3 | tr '\n' ' ' | cut -c1-400)"; continue; fi
    [ -f "$(dirname "$bin")/bayan-quality.json" ] || { note "mutation: bayan mutate exited $MX on $bin without a report — $(tail -3 "$LOG/mutate-$name.txt" | tr '\n' ' ')"; continue; }
    cp "$(dirname "$bin")/bayan-quality.json" "$LOG/quality-$name.json"
    echo "mutation build $name (per site: $REL/mutate-$name.txt, report: $REL/quality-$name.json):"
    sed -n '/^mutation: [0-9]/,$p' "$LOG/mutate-$name.txt"
    [ $SURV = 1 ] && while read -r l; do l=${l%: survived}; [ -n "$l" ] && note "mutation survived: ${l#$PWD/} — no test fails under this change; add one that does, or mark the statement @unobservable because \"…\""
    done < <(grep -E ': survived$' "$LOG/mutate-$name.txt")
  done <<< "$BUILDS"
  return 0
}
