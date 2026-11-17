#!/usr/bin/env bash
# The full suite with no dotnet call (spec 019 R15, T23): golden cases, Bayān tests, script tests, runtime C tests.
#   bash scripts/test.sh [--jobs N] [--only golden|bayan|scripts|runtime]
# Parts, in order:
#   golden   $BAYAN_EXE test tests/cases --jobs N (the self-hosted golden runner, src/driver/golden.byn)
#   bayan    $BAYAN_EXE test --package src src/<m> for each src/<m> with a test block, then test lib/std/<m> for each module
#   scripts  scripts/ci/script-tests.sh: unix on macOS, unix and docs on Linux (ci.yml's split); skipped on Windows
#   runtime  runtime/tests/run.sh; skipped with no C compiler (no $CC, cc or zig)
# --jobs (default: the CPU count) goes to the golden runner, the one part that runs in parallel.
# BAYAN_EXE: the self-hosted driver; unset, src/driver is built with the pinned bayan (scripts/pinned-bayan.sh) into the
# run's log directory, as scripts/selfhost/t10-compare.sh does. Each part's output is in <root>/tmp/test.XXXXXX/<part>.log,
# removed when every part passes. One summary line per part; exit 1 when any part fails, 2 on a usage error.
# Tests only: TEST_SH_GOLDEN, TEST_SH_BAYAN, TEST_SH_SCRIPTS, TEST_SH_RUNTIME replace a part's command (golden's gets
# `--jobs N`), and no driver is built for a replaced part. bash 3.2.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 2

jobs=""; only=""
while [ $# -gt 0 ]; do
  case "$1" in
    (--jobs) [ $# -ge 2 ] || { echo "test.sh: --jobs expects a number" >&2; exit 2; }; jobs=$2; shift 2 ;;
    (--only) [ $# -ge 2 ] || { echo "test.sh: --only expects a part" >&2; exit 2; }; only=$2; shift 2 ;;
    (*) echo "test.sh: unexpected argument '$1' (--jobs N, --only golden|bayan|scripts|runtime)" >&2; exit 2 ;;
  esac
done
case "$only" in (""|golden|bayan|scripts|runtime) ;; (*) echo "test.sh: unknown part '$only' (golden, bayan, scripts, runtime)" >&2; exit 2 ;; esac
if [ -z "$jobs" ]; then
  jobs=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
fi
case "$jobs" in (""|*[!0-9]*|0) echo "test.sh: --jobs expects a positive whole number, got '$jobs'" >&2; exit 2 ;; esac

os=unix; case "$(uname -s)" in (MINGW*|MSYS*|CYGWIN*) os=windows ;; (Linux) os=linux ;; esac
mkdir -p "$root/tmp"
logs="$(mktemp -d "$root/tmp/test.XXXXXX")" || exit 2
failed=""

# summary <part> <status> <seconds> <detail>
summary() { printf 'test: %-8s %-4s %4ss  %s\n' "$1" "$2" "$3" "$4"; }

# The driver for golden and bayan, built once on first use; empty with the reason in $driver_err when it cannot be had.
driver=""; driver_err=""; driver_tried=0
need_driver() {
  [ $driver_tried = 1 ] && { [ -n "$driver" ]; return; }
  driver_tried=1
  if [ -n "${BAYAN_EXE:-}" ]; then
    [ -x "$BAYAN_EXE" ] && driver=$BAYAN_EXE || driver_err="BAYAN_EXE=$BAYAN_EXE is not an executable"
  else
    local exe="$logs/bayan" pinned
    [ $os = windows ] && exe="$logs/bayan.exe"
    if pinned="$(bash scripts/pinned-bayan.sh 2>"$logs/driver.log")" \
      && "$pinned" build --mode safe --package src -o "$exe" src/driver >>"$logs/driver.log" 2>&1; then
      driver=$exe
    else
      driver_err="building src/driver failed; log: $logs/driver.log"
    fi
  fi
  [ -n "$driver" ] && export BAYAN_EXE="$driver"
  [ -n "$driver" ]
}

golden_run() { "$driver" test tests/cases --jobs "$jobs"; }

bayan_tests() {
  local rc=0 d
  for d in src/*/; do
    d=${d%/}
    grep -lq '^test "' "$d"/*.byn 2>/dev/null || continue
    echo "== $d"; "$driver" test --package src "$d" || rc=1
  done
  for d in lib/std/*/; do
    d=${d%/}
    echo "== $d"; "$driver" test "$d" || rc=1
  done
  return $rc
}

# part <name> <stub override> <detail> <command...>: runs the command into <name>.log and prints the summary line.
part() {
  local name=$1 stub=$2 detail=$3 start rc; shift 3
  [ -z "$only" ] || [ "$only" = "$name" ] || return 0
  start=$(date +%s)
  if [ -n "$stub" ]; then
    "$@" >"$logs/$name.log" 2>&1; rc=$?
  elif { [ "$name" = golden ] || [ "$name" = bayan ]; } && ! need_driver; then
    echo "$driver_err" >"$logs/$name.log"; rc=1; detail="$driver_err"
  else
    "$@" >"$logs/$name.log" 2>&1; rc=$?
  fi
  if [ $rc = 0 ]; then
    summary "$name" pass $(( $(date +%s) - start )) "$detail"
  else
    summary "$name" FAIL $(( $(date +%s) - start )) "$detail (exit $rc; log: $logs/$name.log)"
    tail -n 20 "$logs/$name.log" | sed 's/^/    /'
    failed="$failed $name"
  fi
}

# skip <name> <reason>
skip() { [ -z "$only" ] || [ "$only" = "$1" ] || return 0; summary "$1" skip 0 "$2"; }

if [ -n "${TEST_SH_GOLDEN:-}" ]; then part golden "$TEST_SH_GOLDEN" "golden cases" "$TEST_SH_GOLDEN" --jobs "$jobs"
else part golden "" "bayan test tests/cases --jobs $jobs" golden_run; fi

if [ -n "${TEST_SH_BAYAN:-}" ]; then part bayan "$TEST_SH_BAYAN" "Bayān tests" "$TEST_SH_BAYAN"
else part bayan "" "test blocks of src/ and lib/std/" bayan_tests; fi

groups="unix"; [ $os = linux ] && groups="unix docs"
if [ -n "${TEST_SH_SCRIPTS:-}" ]; then part scripts "$TEST_SH_SCRIPTS" "script tests" "$TEST_SH_SCRIPTS"
elif [ $os = windows ]; then skip scripts "the script tests run on the Linux and macOS jobs only (ci.yml)"
else part scripts "" "scripts/ci/script-tests.sh $groups" "$BASH" scripts/ci/script-tests.sh $groups; fi

if [ -n "${TEST_SH_RUNTIME:-}" ]; then part runtime "$TEST_SH_RUNTIME" "runtime C tests" "$TEST_SH_RUNTIME"
elif [ -z "${CC:-}" ] && ! command -v cc >/dev/null 2>&1 && ! command -v zig >/dev/null 2>&1; then
  skip runtime "no C compiler: set CC, or install cc or zig"
else part runtime "" "runtime/tests/run.sh" bash runtime/tests/run.sh; fi

if [ -n "$failed" ]; then echo "test: FAILED$failed"; exit 1; fi
rm -rf "$logs"
echo "test: all passed"
