#!/usr/bin/env bash
# Re-checks the smoke subset of the LLM eval set (spec 025 R29, T31): the tasks named in evals/llm/smoke.txt, each with
# `llm-eval recheck evals/llm/tasks --only <task>`. CI runs it on every push; the whole set runs nightly
# (.github/workflows/llm-eval-nightly.yml). The pinned bayan is built (or found in its cache) once before the first task,
# so the 12 calls share one build.
# Usage: scripts/ci/llm-eval-smoke.sh [--check-list] [<list>]
#   --check-list  only check the list, run nothing
#   <list>        default evals/llm/smoke.txt; tasks are always looked up in evals/llm/tasks
# The list holds 12 names over all 8 categories: one task at tier 1 or 2 from each, and 4 tier-3 tasks from four
# different categories. Exit 0 every task passed (or the list is good, with --check-list), 1 a task failed, 2 bad list or usage.
set -uo pipefail
cd "$(dirname "$0")/../.."
check_only=false
[ "${1:-}" = --check-list ] && { check_only=true; shift; }
list="${1:-evals/llm/smoke.txt}"
tasks=evals/llm/tasks
[ $# -le 1 ] || { echo "usage: llm-eval-smoke.sh [--check-list] [<list>]" >&2; exit 2; }
[ -f "$list" ] || { echo "llm-eval-smoke: no list at $list" >&2; exit 2; }

# field <task> <key>: the value of the `<key>:` line in the task's task.md.
field() { sed -n "s/^$2: *//p" "$tasks/$1/task.md" | head -n 1; }
names=() bad=0 low="" high=""
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in (""|"#"*) continue ;; esac
  names+=("$line")
  if [ ! -f "$tasks/$line/task.md" ]; then
    echo "llm-eval-smoke: $list names $line, which has no directory with a task.md in $tasks" >&2; bad=1; continue
  fi
  case "$(field "$line" Tier)" in
    (1|2) low="$low$(field "$line" Category)"$'\n' ;;
    (3) high="$high$(field "$line" Category)"$'\n' ;;
    (*) echo "llm-eval-smoke: $line has no tier 1, 2 or 3" >&2; bad=1 ;;
  esac
done < "$list"
# count <lines>: how many distinct non-empty lines.
count() { printf '%s' "$1" | sed '/^$/d' | sort -u | wc -l | tr -d ' '; }
total="$(count "$(printf '%s\n' "$low" "$high")")"
[ ${#names[@]} = 12 ] || { echo "llm-eval-smoke: $list holds ${#names[@]} names, not 12" >&2; bad=1; }
[ "$total" = 8 ] || { echo "llm-eval-smoke: $list covers $total categories, not 8" >&2; bad=1; }
[ "$(count "$low")" = 8 ] && [ "$(printf '%s' "$low" | sed '/^$/d' | wc -l | tr -d ' ')" = 8 ] ||
  { echo "llm-eval-smoke: $list does not hold one tier 1 or 2 task from each of the 8 categories" >&2; bad=1; }
[ "$(count "$high")" = 4 ] && [ "$(printf '%s' "$high" | sed '/^$/d' | wc -l | tr -d ' ')" = 4 ] ||
  { echo "llm-eval-smoke: $list does not hold 4 tier-3 tasks from four different categories" >&2; bad=1; }
[ $bad = 0 ] || exit 2
$check_only && { echo "llm-eval-smoke: $list is good (12 tasks, 8 categories)"; exit 0; }

bayan="$(bash scripts/pinned-bayan.sh)" || exit 1
echo "llm-eval-smoke: pinned bayan $bayan"
failed=()
for n in "${names[@]}"; do
  bash scripts/bayan-tool.sh llm-eval recheck "$tasks" --only "$n" || failed+=("$n")
done
[ ${#failed[@]} = 0 ] && { echo "llm-eval-smoke: ${#names[@]} passed in ${SECONDS} s"; exit 0; }
printf 'llm-eval-smoke: FAILED %s\n' "${failed[@]}"; exit 1
