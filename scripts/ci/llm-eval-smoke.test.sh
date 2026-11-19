#!/usr/bin/env bash
# Tests scripts/ci/llm-eval-smoke.sh without a build: the tracked list is well formed, and a bad list (a name with no
# directory; 11 names; a fifth tier-3 task) exits 2 before any recheck. PINNED_BAYAN is a stub that leaves a file when
# bayan-tool.sh starts it, so a recheck that ran is seen; a good list with the stub shows the stub is reached.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="$root/scripts/ci/llm-eval-smoke.sh"
list="$root/evals/llm/smoke.txt"
tmp="$root/tmp/llm-eval-smoke-test"
rm -rf "$tmp"; mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }
printf '#!/bin/sh\ntouch "%s/ran"\nexit 1\n' "$tmp" > "$tmp/bayan"; chmod +x "$tmp/bayan"
export PINNED_BAYAN="$tmp/bayan"

# The tracked list: 12 names, every directory there, 8 categories at tier 1 or 2 and 4 tier-3 from four categories.
"$BASH" "$script" --check-list > "$tmp/out" 2>&1 || fail "the tracked list is refused: $(cat "$tmp/out")"
names="$(grep -v '^#' "$list" | sed '/^$/d')"
[ "$(printf '%s\n' "$names" | wc -l | tr -d ' ')" = 12 ] || fail "the tracked list does not hold 12 names"
cats="$(for n in $names; do [ -d "$root/evals/llm/tasks/$n" ] || fail "no directory for $n"; sed -n 's/^Category: *//p' "$root/evals/llm/tasks/$n/task.md"; done)"
[ "$(printf '%s\n' "$cats" | sort -u | wc -l | tr -d ' ')" = 8 ] || fail "the tracked list does not cover 8 categories"
tier3="$(for n in $names; do grep -q '^Tier: 3$' "$root/evals/llm/tasks/$n/task.md" && echo "${n%%-*}"; done || true)"
[ "$(printf '%s\n' "$tier3" | sort -u | wc -l | tr -d ' ')" = 4 ] && [ "$(printf '%s\n' "$tier3" | wc -l | tr -d ' ')" = 4 ] ||
  fail "the tracked list does not hold 4 tier-3 tasks from four categories: $tier3"

# refused <name> <list-file> <message>: the script exits 2 with <message> and never starts the compiler.
refused() {
  local code=0
  "$BASH" "$script" "$2" > "$tmp/out" 2>&1 || code=$?
  [ "$code" = 2 ] || fail "$1: exit $code, want 2: $(cat "$tmp/out")"
  grep -q "$3" "$tmp/out" || fail "$1: no '$3' in: $(cat "$tmp/out")"
  [ ! -e "$tmp/ran" ] || fail "$1: a recheck ran"
}
sed 's/^small-006-locker-codes$/small-999-no-such-task/' "$list" > "$tmp/missing.txt"
refused "a name with no directory" "$tmp/missing.txt" "small-999-no-such-task, which has no directory"
grep -v '^small-006-locker-codes$' "$list" > "$tmp/eleven.txt"
refused "11 names" "$tmp/eleven.txt" "holds 11 names, not 12"
sed 's/^small-006-locker-codes$/spec-010-mina-camp-log/' "$list" > "$tmp/tier3.txt"
refused "a fifth tier-3 task" "$tmp/tier3.txt" "one tier 1 or 2 task from each"

# A good list reaches the compiler: the stub runs and fails, so the script exits 1.
code=0; "$BASH" "$script" > "$tmp/out" 2>&1 || code=$?
[ "$code" = 1 ] && [ -e "$tmp/ran" ] || fail "a good list did not start a recheck (exit $code): $(cat "$tmp/out")"
echo PASS
