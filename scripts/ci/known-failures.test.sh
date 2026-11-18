#!/usr/bin/env bash
# Tests scripts/ci/known-failures.py against reports of scripts/test.sh (fixtures: summary lines and kept part logs).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="$root/scripts/ci/known-failures.py"
mkdir -p "$root/tmp"
tmp="$(mktemp -d "$root/tmp/known-failures-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

# report FILE PART... : a report whose parts fail, each with its log at $tmp/<part>.log (written by the caller); the others pass.
report() {
  local f="$1" p; shift
  : > "$f"
  for p in golden bayan; do
    case " $* " in
      (*" $p "*) printf 'test: %-8s %-4s %4ss  x (exit 1; log: %s/%s.log)\n' "$p" FAIL 3 "$tmp" "$p" >> "$f" ;;
      (*) printf 'test: %-8s %-4s %4ss  x\n' "$p" pass 3 >> "$f" ;;
    esac
  done
  case " $* " in
    (*" scripts "*) printf 'test: %-8s %-4s %4ss  x (exit 1; log: %s/scripts.log)\n' scripts FAIL 3 "$tmp" >> "$f"
                    echo "scripts: some script failed" > "$tmp/scripts.log" ;;
  esac
  echo "test: FAILED$(printf ' %s' "$@")" >> "$f"
}

# run NAME EXPECTED_CODE PATTERN ARGS...
run() {
  local name="$1" want="$2" pat="$3"; shift 3
  local out code=0
  out="$(python3 -I "$script" "$@" 2>&1)" || code=$?
  if [ "$code" != "$want" ]; then
    echo "FAIL $name: exit $code, want $want"; echo "$out"; exit 1
  fi
  if [ -n "$pat" ] && ! grep -qF -- "$pat" <<<"$out"; then
    echo "FAIL $name: output lacks '$pat'"; echo "$out"; exit 1
  fi
}

list="$tmp/list.txt"
printf '# comment\nrun/one\nstd/x: two\n' > "$list"

printf 'passed run/ok\n    detail\nfailed run/one\n    expected\ntimed out diag/slow\n' > "$tmp/golden.log"
printf '== lib/std/x\n  \xe2\x9c\x97 std/x: two\n      boom\n' > "$tmp/bayan.log"

# a timed-out case is a failure too; both listed failures present, one unlisted
report "$tmp/new.txt" golden bayan
run new-failure 1 "new failure: diag/slow" "$list" "$tmp/new.txt"

printf '# only comments\nrun/one\ndiag/slow\nstd/x: two\n' > "$tmp/all.txt"
run all-listed 0 "0 new, 0 now passing" "$tmp/all.txt" "$tmp/new.txt"

printf 'failed run/one\n' > "$tmp/golden.log"
report "$tmp/g.txt" golden
run listed-passes 1 "now passes: remove it from $list: std/x: two" "$list" "$tmp/g.txt"

printf 'run/one\n' > "$tmp/one.txt"
run only-listed 0 "0 new" "$tmp/one.txt" "$tmp/g.txt"

report "$tmp/s.txt" scripts
run part-as-id 1 "new failure: scripts" "$list" "$tmp/s.txt"
printf 'scripts\n' > "$tmp/sl.txt"
run part-listed 0 "1 known" "$tmp/sl.txt" "$tmp/s.txt"

# a nested ✗ inside a test's detail is not an id
printf '== lib/std/x\n  \xe2\x9c\x97 std/x: two\n      \xe2\x9c\x97 build failed: 1 error, 0 warnings\n' > "$tmp/bayan.log"
report "$tmp/nest.txt" bayan
printf 'std/x: two\n' > "$tmp/nl.txt"
run nested-not-an-id 0 "1 known, 0 new" "$tmp/nl.txt" "$tmp/nest.txt"

printf 'driver build failed\n' > "$tmp/golden.log"
report "$tmp/np.txt" golden
run no-test-name 1 "new failure: golden" "$list" "$tmp/np.txt"

printf 'test: golden   pass    1s  x\ntest: all passed\n' > "$tmp/pass.txt"
run all-pass-listed 1 "now passes: remove it from $list: run/one" "$list" "$tmp/pass.txt"
: > "$tmp/empty.txt"
run all-pass-empty-list 0 "0 failed" "$tmp/empty.txt" "$tmp/pass.txt"

run no-args 2 "usage"
run one-arg 2 "usage" "$list"
run extra-arg 2 "usage" "$list" "$tmp/pass.txt" "$tmp/pass.txt"
run missing-list 2 "" "$tmp/nope.txt" "$tmp/pass.txt"
run missing-report 2 "" "$list" "$tmp/nope.txt"
echo "no summary here" > "$tmp/bad.txt"
run no-summary 2 "no 'test:" "$list" "$tmp/bad.txt"
printf 'test: golden   FAIL    1s  x (exit 1; log: %s/gone.log)\n' "$tmp" > "$tmp/nolog.txt"
run missing-log 2 "" "$list" "$tmp/nolog.txt"

echo PASS
