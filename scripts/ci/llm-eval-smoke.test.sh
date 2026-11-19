#!/usr/bin/env bash
# Tests scripts/ci/llm-eval-smoke.sh without a build: the tracked list is well formed, a relative list is read from the
# caller's directory, and a bad list (a name with no directory; 11 names; a fifth tier-3 task; two tier-3 tasks from one
# category) exits 2 before any recheck. PINNED_BAYAN is a stub that leaves a file when bayan-tool.sh starts it and logs
# its arguments, so a recheck that ran is seen; a good list with the stub shows the stub is reached. For --changed-since
# a `git` stub on PATH answers rev-parse and prints a fixed diff, so no commit is needed.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="$root/scripts/ci/llm-eval-smoke.sh"
list="$root/evals/llm/smoke.txt"
tmp="$root/tmp/llm-eval-smoke-test"
rm -rf "$tmp"; mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }
printf '#!/bin/sh\ntouch "%s/ran"\necho "$*" >> "%s/args"\nexit 1\n' "$tmp" "$tmp" > "$tmp/bayan"; chmod +x "$tmp/bayan"
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
# Still one tier 1 or 2 task per category, but two of the 4 tier-3 tasks are from spec.
sed 's/^small-005-pledge-ledger$/spec-010-mina-camp-log/' "$list" > "$tmp/tier3cats.txt"
refused "two tier-3 tasks from one category" "$tmp/tier3cats.txt" "4 tier-3 tasks from four different categories"

# A relative list is read from the caller's directory, not the repo root.
cp "$list" "$tmp/rel.txt"
(cd "$tmp" && "$BASH" "$script" --check-list rel.txt) > "$tmp/out" 2>&1 || fail "a relative list is not found: $(cat "$tmp/out")"

# A good list reaches the compiler: the stub runs and fails, so the script exits 1.
code=0; "$BASH" "$script" > "$tmp/out" 2>&1 || code=$?
[ "$code" = 1 ] && [ -e "$tmp/ran" ] || fail "a good list did not start a recheck (exit $code): $(cat "$tmp/out")"

# --changed-since with the git stub: rev-parse knows every commit but the all-zero sha; the diff names a task outside the
# list (two files), one on it, a new file in a third, a task that no longer exists and a file directly under tasks/.
mkdir -p "$tmp/bin"
printf '#!/bin/sh\necho "$*" >> "%s/git-args"\ncase "$1" in\n  (rev-parse) case "$*" in (*" 0000000000000000000000000000000000000000^{commit}") exit 1 ;; esac; echo 1111111111111111111111111111111111111111 ;;\n  (diff) cat "%s/diff" ;;\n  (*) exit 2 ;;\nesac\n' "$tmp" "$tmp" > "$tmp/bin/git"
chmod +x "$tmp/bin/git"
printf '%s\n' evals/llm/tasks/README.md evals/llm/tasks/std-010-regex-notice-boards/task.md \
  evals/llm/tasks/std-010-regex-notice-boards/reference.byn evals/llm/tasks/small-006-locker-codes/task.md \
  evals/llm/tasks/errors-010-library-loans/new.txt evals/llm/tasks/gone-001-removed/task.md > "$tmp/diff"
# since <commit>: run the script with --changed-since <commit>; it exits 1 (the stub fails every recheck).
since() {
  rm -f "$tmp/args" "$tmp/git-args"; code=0
  PATH="$tmp/bin:$PATH" "$BASH" "$script" --changed-since "$1" > "$tmp/out" 2>&1 || code=$?
  [ "$code" = 1 ] || fail "--changed-since $1: exit $code, want 1: $(cat "$tmp/out")"
}
# runs <task>: how many rechecks named --only <task>.
runs() { grep -c -- "--only $1\$" "$tmp/args" || true; }
since abc123
grep -q '^diff .* abc123 HEAD -- evals/llm/tasks$' "$tmp/git-args" || fail "changed tasks: no diff from abc123 to HEAD: $(cat "$tmp/git-args")"
[ "$(wc -l < "$tmp/args" | tr -d ' ')" = 14 ] || fail "changed tasks: want 14 rechecks: $(cat "$tmp/args")"
for n in std-010-regex-notice-boards errors-010-library-loans small-006-locker-codes; do
  [ "$(runs "$n")" = 1 ] || fail "changed tasks: $n ran $(runs "$n") times, want 1: $(cat "$tmp/args")"
done
since 0000000000000000000000000000000000000000
grep -q "git cannot resolve '0000000000000000000000000000000000000000'" "$tmp/out" || fail "an unknown commit: no message: $(cat "$tmp/out")"
[ "$(cat "$tmp/args")" = "run $root/tools/llm-eval.byn -- recheck evals/llm/tasks" ] ||
  fail "an unknown commit did not take the whole-set path: $(cat "$tmp/args")"
echo PASS
