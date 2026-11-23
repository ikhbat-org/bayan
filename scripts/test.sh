#!/usr/bin/env bash
# The full suite with no dotnet call (spec 019 R15, T23): golden cases, Bayān tests, CLI parity cases, script tests,
# runtime C tests.
#   bash scripts/test.sh [--jobs N] [--only golden|bayan|parity|scripts|runtime] [--skip <part>]... [--shard i/n] [--coverage]
# Parts, in order:
#   golden   $BAYAN_EXE test tests/cases --jobs N (the self-hosted golden runner, src/driver/golden.byn)
#   bayan    $BAYAN_EXE test --package src src/<m> for each src/<m> with a test block, then test lib/std/<m> for each module
#   parity   scripts/parity/run.sh <tool> --impl $BAYAN_EXE for each tests/parity/cli-<tool> (spec 019 T25); skipped on Windows
#   scripts  scripts/ci/script-tests.sh: unix on macOS, unix and docs on Linux (ci.yml's split); skipped on Windows
#   runtime  runtime/tests/run.sh; skipped with no C compiler (no $CC, cc or zig)
# --jobs (default: the CPU count) goes to the golden runner, the one part that runs in parallel.
# --skip <part> (repeatable) leaves that part out, as --only leaves out the others (ci.yml: `--skip golden` beside the golden shards).
# --shard i/n (1 <= i <= n <= 64): the golden part runs shard i of n (BAYAN_TEST_SHARD, src/driver/golden.byn goldenShard; spec 019
# T30, R17). The variable is set for the golden part only; one from the caller is dropped, since the bayan part's test blocks start the
# runner.
# --coverage: the bayan part runs the src/ packages through scripts/quality/coverage.sh (`test --coverage`, then the
# ratchet against tests/quality-baseline.json, spec 019 R16, T29; report in tmp/quality/bayan-quality.json); the other
# parts have no coverage build and run as without it.
# BAYAN_EXE: the self-hosted driver; unset, src/driver is built with the pinned bayan (scripts/pinned-bayan.sh) into the
# run's log directory. Each part's output is in <root>/tmp/test.XXXXXX/<part>.log,
# removed when every part passes. One summary line per part; exit 1 when any part fails, 2 on a usage error.
# Tests only: TEST_SH_GOLDEN, TEST_SH_BAYAN, TEST_SH_PARITY, TEST_SH_SCRIPTS, TEST_SH_RUNTIME replace a part's command (golden's gets
# `--jobs N`), and no driver is built for a replaced part. bash 3.2.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 2

jobs=""; only=""; skips=""; shard=""; coverage=0
while [ $# -gt 0 ]; do
  case "$1" in
    (--jobs) [ $# -ge 2 ] || { echo "test.sh: --jobs expects a number" >&2; exit 2; }; jobs=$2; shift 2 ;;
    (--only) [ $# -ge 2 ] || { echo "test.sh: --only expects a part" >&2; exit 2; }; only=$2; shift 2 ;;
    (--skip) [ $# -ge 2 ] || { echo "test.sh: --skip expects a part" >&2; exit 2; }
      case "$2" in (golden|bayan|parity|scripts|runtime) ;; (*) echo "test.sh: unknown part '$2' (golden, bayan, parity, scripts, runtime)" >&2; exit 2 ;; esac
      skips="$skips $2"; shift 2 ;;
    (--shard) [ $# -ge 2 ] || { echo "test.sh: --shard expects i/n" >&2; exit 2; }; shard=$2; shift 2 ;;
    (--coverage) coverage=1; shift ;;
    (*) echo "test.sh: unexpected argument '$1' (--jobs N, --only golden|bayan|parity|scripts|runtime, --skip <part>, --shard i/n, --coverage)" >&2; exit 2 ;;
  esac
done
case "$only" in (""|golden|bayan|parity|scripts|runtime) ;; (*) echo "test.sh: unknown part '$only' (golden, bayan, parity, scripts, runtime)" >&2; exit 2 ;; esac
# --shard as the runner reads BAYAN_TEST_SHARD: i/n, whole numbers with 1 <= i <= n <= 64.
unset BAYAN_TEST_SHARD
if [ -n "$shard" ]; then
  si=${shard%%/*}; sn=${shard#*/}; ok=1
  case "$shard" in (*/*) ;; (*) ok=0 ;; esac
  case "$si" in (""|*[!0-9]*|?????????*) ok=0 ;; esac
  case "$sn" in (""|*[!0-9]*|?????????*) ok=0 ;; esac
  [ $ok = 1 ] && [ $((10#$si)) -ge 1 ] && [ $((10#$si)) -le $((10#$sn)) ] && [ $((10#$sn)) -le 64 ] \
    || { echo "test.sh: --shard expects i/n, whole numbers with 1 <= i <= n <= 64, got '$shard'" >&2; exit 2; }
fi
if [ -z "$jobs" ]; then
  jobs=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
fi
case "$jobs" in (""|*[!0-9]*|0) echo "test.sh: --jobs expects a positive whole number, got '$jobs'" >&2; exit 2 ;; esac

os=unix; case "$(uname -s)" in (MINGW*|MSYS*|CYGWIN*) os=windows ;; (Linux) os=linux ;; esac
mkdir -p "$root/tmp"
# Every part shares one zig cache unless the caller names one: the driver puts zig's cache under each BAYAN_CACHE when
# ZIG_GLOBAL_CACHE_DIR is unset (T17d), and the per-case caches of the golden runner then rebuild libc and compiler_rt
# per case, past the 300 s limit on windows-latest (ci run 44276585184, 2026-11-18).
if [ -n "${ZIG_GLOBAL_CACHE_DIR:-}" ]; then
  export ZIG_GLOBAL_CACHE_DIR
else
  export ZIG_GLOBAL_CACHE_DIR="$root/tmp/zig-global"
  # Its o/ keeps the newest 2000 entries, past them only those written in the last 10 minutes (a concurrent zig cc), as the
  # driver trims its own (zigCacheEntries, zigCacheMinAge in src/driver/cache.byn). A caller's directory is the caller's to trim.
  # Only entries holding nothing but main/bayan-rt objects go, as zigDriverObject: zig's toolchain pieces (libcompiler_rt.a, libc,
  # crt) are built once and read by every later link through h/, so removing one fails that link with FileNotFound.
  # A manifest in h/ names its inputs, not its o/ entry, so a hit on one whose entry is gone fails FileNotFound; a manifest gone
  # is only a miss. So before any o/ entry goes, every manifest naming main.c or bayan-rt.c goes, as zigTrimEntries does.
  zig_o="$ZIG_GLOBAL_CACHE_DIR/o"
  zig_h="$ZIG_GLOBAL_CACHE_DIR/h"
  if [ -d "$zig_o" ]; then
    zig_keep=$(( $(find "$zig_o" -mindepth 1 -maxdepth 1 -mmin -10 | wc -l) ))
    [ "$zig_keep" -gt 2000 ] || zig_keep=2000
    zig_gone=""
    while IFS= read -r e; do
      [ -d "$zig_o/$e" ] && [ ! -L "$zig_o/$e" ] || continue
      zig_other=$(ls -A "$zig_o/$e" | grep -cvxE 'main\.o|main\.obj|bayan-rt\.o|bayan-rt\.obj')
      [ "$zig_other" = 0 ] && [ -n "$(ls -A "$zig_o/$e")" ] && zig_gone="$zig_gone$e
"
    done <<EOF
$(ls -At "$zig_o" | tail -n +$((zig_keep + 1)))
EOF
    if [ -n "$zig_gone" ]; then
      if [ -d "$zig_h" ]; then
        find "$zig_h" -type f -exec grep -l -a -F -e main.c -e bayan-rt.c {} + 2>/dev/null | while IFS= read -r m; do
          rm -f "$m"
        done
      fi
      printf '%s' "$zig_gone" | while IFS= read -r e; do
        [ -n "$e" ] && rm -rf "${zig_o:?}/$e"
      done
    fi
  fi
fi
logs="$(mktemp -d "$root/tmp/test.XXXXXX")" || exit 2
failed=""

# summary <part> <status> <seconds> <detail>
summary() { printf 'test: %-8s %-4s %4ss  %s\n' "$1" "$2" "$3" "$4"; }

# The driver for golden, bayan and parity, built once on first use; empty with the reason in $driver_err when it cannot be had.
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

# with_shard <command...>: the command with BAYAN_TEST_SHARD set to --shard's value (the golden part only).
with_shard() { BAYAN_TEST_SHARD="$shard" "$@"; }

bayan_tests() {
  local rc=0 d
  if [ $coverage = 1 ]; then
    bash scripts/quality/coverage.sh || rc=1
  else
    for d in src/*/; do
      d=${d%/}
      grep -lq '^test "' "$d"/*.byn 2>/dev/null || continue
      echo "== $d"; "$driver" test --package src "$d" || rc=1
    done
  fi
  for d in lib/std/*/; do
    d=${d%/}
    echo "== $d"; "$driver" test "$d" || rc=1
  done
  return $rc
}

# Each CLI parity tool against the driver; run.sh runs the cases in their own work directories, so the path is absolute.
parity_run() {
  local rc=0 d exe=$driver
  case "$exe" in (/*) ;; (*) exe="$root/$exe" ;; esac
  for d in tests/parity/cli-*/; do
    d=${d%/}
    bash scripts/parity/run.sh "${d#tests/parity/}" --impl "$exe" || rc=1
  done
  return $rc
}

# part <name> <stub override> <detail> <command...>: runs the command into <name>.log and prints the summary line.
part() {
  local name=$1 stub=$2 detail=$3 start rc; shift 3
  [ -z "$only" ] || [ "$only" = "$name" ] || return 0
  case "$skips " in (*" $name "*) return 0 ;; esac
  start=$(date +%s)
  if [ -n "$stub" ]; then
    "$@" >"$logs/$name.log" 2>&1; rc=$?
  elif { [ "$name" = golden ] || [ "$name" = bayan ] || [ "$name" = parity ]; } && ! need_driver; then
    echo "$driver_err" >"$logs/$name.log"; rc=1; detail="$driver_err"
  else
    "$@" >"$logs/$name.log" 2>&1; rc=$?
  fi
  if [ $rc = 0 ]; then
    summary "$name" pass $(( $(date +%s) - start )) "$detail"
  else
    summary "$name" FAIL $(( $(date +%s) - start )) "$detail (exit $rc; log: $logs/$name.log)"
    grep -E '^(failed|timed out) |^  ✗ ' "$logs/$name.log" | head -n 40 | sed 's/^/    /'
    tail -n 20 "$logs/$name.log" | sed 's/^/    /'
    failed="$failed $name"
  fi
}

# skip <name> <reason>
skip() {
  [ -z "$only" ] || [ "$only" = "$1" ] || return 0
  case "$skips " in (*" $1 "*) return 0 ;; esac
  summary "$1" skip 0 "$2"
}

shard_detail=""; [ -z "$shard" ] || shard_detail=", shard $shard"
if [ -n "${TEST_SH_GOLDEN:-}" ]; then part golden "$TEST_SH_GOLDEN" "golden cases$shard_detail" with_shard "$TEST_SH_GOLDEN" --jobs "$jobs"
else part golden "" "bayan test tests/cases --jobs $jobs$shard_detail" with_shard golden_run; fi

if [ -n "${TEST_SH_BAYAN:-}" ]; then part bayan "$TEST_SH_BAYAN" "Bayān tests" "$TEST_SH_BAYAN"
elif [ $coverage = 1 ]; then part bayan "" "test blocks of src/ under coverage and the ratchet, and of lib/std/" bayan_tests
else part bayan "" "test blocks of src/ and lib/std/" bayan_tests; fi

if [ -n "${TEST_SH_PARITY:-}" ]; then part parity "$TEST_SH_PARITY" "CLI parity cases" "$TEST_SH_PARITY"
elif [ $os = windows ]; then skip parity "the CLI parity cases run on Linux and macOS only (bash steps, symlinks)"
else part parity "" "scripts/parity/run.sh cli-* against the driver" parity_run; fi

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
