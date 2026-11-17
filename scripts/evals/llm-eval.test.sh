#!/usr/bin/env bash
# Test for tools/llm-eval.byn `score` (spec 025 T2). Scratch is under the repo's tmp/. Builds small task sets there at run
# time; the seed under evals/llm/tasks is only read.
#   bash scripts/evals/llm-eval.test.sh
set -uo pipefail
cd "$(dirname "$0")/../.."
seed=evals/llm/tasks
root=$PWD/tmp/llm-eval-test
rm -rf "$root"; mkdir -p "$root/tasks" "$root/cand" "$root/out" "$root/rec"
trap 'rm -rf "$root"' EXIT

pass=0 fail=0
ok() { pass=$((pass + 1)); echo "ok   $1"; }
bad() { fail=$((fail + 1)); echo "FAIL $1"; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (got '$2', want '$3')"; fi; }
# score <name> <task-dir> <candidate>: the record goes to $root/rec/<name>, the exit code to $code, the seconds to $secs.
score() {
  local start=$(date +%s)
  bash scripts/bayan-tool.sh llm-eval score "$2" "$3" --out "$root/out/$1" > "$root/rec/$1" 2> "$root/rec/$1.err"
  code=$?
  secs=$(($(date +%s) - start))
}
# get <name> <key>: the value of <key> in the record, as JSON text.
get() { sed -n "s/.*\"$2\": \([^,}]*\).*/\1/p" "$root/rec/$1"; }
four() { echo "$(get "$1" compiles) $(get "$1" passes) $(get "$1" lintClean) $(get "$1" formatStable)"; }

mac=false
[ "$(uname -s)" = Darwin ] && [ -x /usr/bin/sandbox-exec ] && mac=true
sandbox=none; $mac && sandbox=sandbox-exec

# A stdout task that expects exit code 3, and a tests task whose test calls `shout()`.
header() { printf '# %s\n\nTitle: test task\nCategory: %s\nTier: 1\nSplit: dev\nRevision: 0023\nChecked: none\nCheck: %s\n\n## Files\n\n## Notes\n\n## Check command\n' "$1" "$2" "$3"; }
exit3=$root/tasks/small-900-exit-code
mkdir -p "$exit3/checks"
header small-900-exit-code small stdout > "$exit3/task.md"
printf 'salam\n' > "$exit3/checks/expected.stdout"
printf '3\n' > "$exit3/checks/exitcode"
loud=$root/tasks/errors-900-loud
mkdir -p "$loud/checks"
header errors-900-loud errors tests > "$loud/task.md"
printf 'void main() {\n}\n' > "$loud/checks/entry.byn"
printf 'test "shout prints" {\n    shout()\n}\n' > "$loud/checks/checks.test.byn"

printf 'i32 main() {\n    print("salam")\n    return 3\n}\n' > "$root/cand/right.byn"
printf 'i32 main() {\n    print("salam")\n    return 0\n}\n' > "$root/cand/wrong-code.byn"
printf 'i32 main() {\n    var code = 3\n    print("salam")\n    return code\n}\n' > "$root/cand/lint.byn"
printf 'void main() {\n    print(nope)\n}\n' > "$root/cand/broken.byn"
printf 'void main() {\n    var n: i64 = 0\n    while true {\n        n += 1\n    }\n}\n' > "$root/cand/loop.byn"
printf '/// Prints without end.\nvoid shout() {\n    while true {\n        print("a line that repeats")\n    }\n}\n' > "$root/cand/shout.byn"
cat "$seed/errors-001-prayer-time/reference/solution.byn" > "$root/cand/with-main.byn"
printf '\nvoid main() {\n}\n' >> "$root/cand/with-main.byn"

# Each seed reference gets four true (R8, R11).
for t in "$seed"/*/; do
  t=${t%/}; name=$(basename "$t")
  score "seed-$name" "$t" "$t/reference/solution.byn"
  check "$name: reference scores four true" "$code $(four "seed-$name") $(get "seed-$name" outcome)" '0 true true true true "pass"'
done

# A tests task passes under the sandbox from an empty cache/ (R15): the sample directory is new, so its cache/ starts empty.
r=seed-errors-001-prayer-time
check "tests task: sandbox named" "$(get $r sandbox)" "\"$sandbox\""
check "tests task: the sample's cache/ was used" "$([ -n "$(ls -A "$root/out/$r/work/errors-001-prayer-time/1/cache")" ] && echo used)" "used"

# A stdout task: the exit code is compared (R4).
score right "$exit3" "$root/cand/right.byn"; secsRight=$secs
check "exit code 3 as expected passes" "$code $(four right) $(get right outcome) $(get right passed)" '0 true true true true "pass" true'
score wrong-code "$exit3" "$root/cand/wrong-code.byn"
check "wrong exit code fails" "$code $(four wrong-code) $(get wrong-code outcome) $(get wrong-code passed)" '0 true false true true "fail" false'

# A candidate that does not compile: compiles false, the other three not reached (R11).
score broken "$exit3" "$root/cand/broken.byn"
check "no compile" "$code $(four broken) $(get broken outcome)" '0 false "not reached" "not reached" "not reached" "no-compile"'

# A tests candidate with a main does not compile (R5, R10).
score with-main "$seed/errors-001-prayer-time" "$root/cand/with-main.byn"
check "tests candidate with a main" "$code $(get with-main compiles) $(get with-main passed) $(get with-main outcome)" '0 false false "no-compile"'

# A candidate that loops reaches the run limit, not the build limit (R14).
score loop "$exit3" "$root/cand/loop.byn"
check "loop gives limit" "$code $(get loop compiles) $(get loop passes) $(get loop outcome)" '0 true false "limit"'
check "loop is stopped at the run limit" "$([ $((secs - secsRight)) -ge 8 ] && [ $((secs - secsRight)) -le 30 ] && echo yes)" "yes"

# A test that prints without end reaches the per-test run limit (R14).
score shout "$loud" "$root/cand/shout.byn"
check "endless printing test gives limit" "$code $(get shout compiles) $(get shout passes) $(get shout outcome)" '0 true false "limit"'

# The same candidate scored twice gives the same record (R9); a lint warning in solution.byn is not lint-clean (R11, R12).
score lint1 "$exit3" "$root/cand/lint.byn"
score lint2 "$exit3" "$root/cand/lint.byn"
check "lint warning: passed, not lint-clean" "$(four lint1) $(get lint1 passed)" 'true true false true true'
check "scored twice, same record" "$(cat "$root/rec/lint2")" "$(cat "$root/rec/lint1")"

# An existing sample directory is refused; bad usage exits 2.
score lint1 "$exit3" "$root/cand/lint.byn"
check "existing sample directory refused" "$code $(grep -c 'exists' "$root/rec/lint1.err")" "1 1"
bash scripts/bayan-tool.sh llm-eval score "$exit3" > /dev/null 2>&1
check "usage" "$?" "2"

echo "llm-eval.test: $pass passed, $fail failed"
[ "$fail" = 0 ]
