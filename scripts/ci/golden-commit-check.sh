#!/usr/bin/env bash
# Refuses a commit range with a golden-update commit that breaks spec 019 R14 (decision 006 §2).
#   scripts/ci/golden-commit-check.sh <base>..<head>
# Every non-merge commit in the range is checked (merge commits are skipped, as are the commits listed in
# scripts/ci/golden-commit-allow.txt as of <head>):
#   - it changes no expected file: passes;
#   - it changes an expected file and any file that is neither an expected file nor the manifest: refused;
#   - it changes only expected files (and the manifest) and its message names no cause: refused.
# Decision 006 gives no exact form for either term, so this script fixes them:
#   expected file: a file under tests/cases/ with one of the extensions the README there lists as expected output
#     (.tokens .ast .diag .jsonl .types .stdout .stderr .exitcode .tree .color .plain .ascii), tests/cases/out/results-fail.json,
#     or any expected.* file of an exported case directory (T17c: expected.golden, expected.sections, expected.c, ...).
#   manifest: tests/cases/FREEZE.tsv (it may not exist yet).
#   cause: the message holds a 7-40 hex commit sha containing a digit, a question number Q### or Q####, or a task reference T<digits>
#     with an optional lowercase suffix (T21, T41b, T123).
# Exit 0 clean, 1 refused (sha, subject and reason on stderr), 2 usage or git error.
set -uo pipefail
[ $# = 1 ] && [[ "$1" == *..* ]] || { echo "usage: scripts/ci/golden-commit-check.sh <base>..<head>" >&2; exit 2; }
manifest=tests/cases/FREEZE.tsv
is_expected() {
  case "$1" in
    (tests/cases/out/results-fail.json) return 0 ;;
    (tests/cases/*/expected.*) return 0 ;;
    (tests/cases/*.tokens|tests/cases/*.ast|tests/cases/*.diag|tests/cases/*.jsonl|tests/cases/*.types|tests/cases/*.stdout|\
     tests/cases/*.stderr|tests/cases/*.exitcode|tests/cases/*.tree|tests/cases/*.color|tests/cases/*.plain|tests/cases/*.ascii) return 0 ;;
  esac
  return 1
}
has_cause() {
  local tok
  git log -1 --format=%B "$1" | grep -Eq '(^|[^[:alnum:]])(Q[0-9]{3,4}|T[0-9]+[a-z]*)([^[:alnum:]]|$)' && return 0
  for tok in $(git log -1 --format=%B "$1" | grep -oE '(^|[^[:alnum:]])[0-9a-f]{7,40}([^[:alnum:]]|$)' | tr -c '0-9a-f\n' ' '); do
    case "$tok" in (*[0-9]*) return 0 ;; esac
  done
  return 1
}
commits=$(git rev-list --reverse --no-merges "$1") || { echo "golden-commit-check: bad range '$1'" >&2; exit 2; }
allowed=" $(git show "${1##*..}:scripts/ci/golden-commit-allow.txt" 2>/dev/null | sed 's/#.*//' | tr -s ' \t\n' '   ') "
bad=0; n=0
for c in $commits; do
  n=$((n + 1))
  case "$allowed" in (*" $c "*) echo "golden-commit-check: $(git log -1 --format='%h' "$c"): allowed by scripts/ci/golden-commit-allow.txt"; continue ;; esac
  exp=0; other=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if is_expected "$f"; then exp=1; elif [ "$f" != "$manifest" ]; then other=1; fi
  done <<EOT
$(git -c core.quotepath=off diff-tree -r --root --no-commit-id --name-only "$c")
EOT
  [ $exp = 1 ] || continue
  reason=""
  if [ $other = 1 ]; then reason="changes an expected file together with a file that is not an expected file or the manifest"
  elif ! has_cause "$c"; then reason="changes only expected files but its message names no cause (a commit sha, Q### or a task id like T41b)"; fi
  if [ -n "$reason" ]; then
    echo "golden-commit-check: $(git log -1 --format='%h %s' "$c"): $reason" >&2
    bad=$((bad + 1))
  fi
done
[ $bad = 0 ] || { echo "golden-commit-check: $bad commit(s) refused in $1" >&2; exit 1; }
echo "golden-commit-check: clean ($n commits in $1)"
