#!/usr/bin/env bash
# Plan 020 step 2 (H4): the golden run/ cases through $BAYAN_EXE, and runtime/tests/run.sh, built through cc-wrap.sh with UBSan
# (pass 1 keeps the toolchain flags, pass 2 also strips -fwrapv) or ASan (no leak check, no stack use-after-return: panics longjmp).
# Each cell runs in tmp/hardening/<cell>/, so the golden runner's child BAYAN_CACHE (tmp/cache below the working directory) is
# fresh per cell. Sanitizer reports go to tmp/hardening/<cell>/log/san.<program>.<pid>; a finding is a report file holding
# `runtime error:` or `ERROR: AddressSanitizer`, and the golden programs are named run_<case>. Prints counts per cell and the
# failing names; full logs are under tmp/hardening/<cell>/log. Exits 0 when it ran, 1 when the harness could not run, 2 on usage.
# The real compiler is $HARDEN_CC (default cc).
usage() { echo "usage: BAYAN_EXE=<driver> $0 --ubsan|--asan|--all [--only <case filter>] (default filter run/)" >&2; exit 2; }

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wrap="$root/scripts/hardening/cc-wrap.sh"
[ -n "$BAYAN_EXE" ] || usage
modes=""; only="run/"
while [ $# -gt 0 ]; do
    case "$1" in
        --ubsan) modes="$modes ubsan" ;;
        --asan) modes="$modes asan" ;;
        --all) modes="ubsan asan" ;;
        --only) [ $# -ge 2 ] || usage; only=$2; shift ;;
        *) usage ;;
    esac
    shift
done
[ -n "$modes" ] || usage
[ -x "$BAYAN_EXE" ] || { echo "sanitize: BAYAN_EXE ($BAYAN_EXE) is not an executable: build the driver first" >&2; exit 1; }
command -v ${HARDEN_CC:-cc} >/dev/null 2>&1 || { echo "sanitize: no C compiler ${HARDEN_CC:-cc} (set HARDEN_CC)" >&2; exit 1; }
case "$BAYAN_EXE" in /*) ;; *) BAYAN_EXE="$PWD/$BAYAN_EXE" ;; esac
export BAYAN_EXE

harness=0
# cell <name> <extra flags> <stripped flags> <sanitizer options variable> <options>
cell() {
    local name=$1 dir="$root/tmp/hardening/$1"
    rm -rf "$dir"; mkdir -p "$dir/log" "$dir/cache"
    local opts="$5:log_path=$dir/log/san:log_exe_name=1"
    (cd "$dir" && env BAYAN_CC="$wrap" HARDEN_CFLAGS="$2" HARDEN_STRIP="$3" BAYAN_CACHE="$dir/cache" "$4=$opts" \
        "$BAYAN_EXE" test "$root/tests/cases" --only "$only" --jobs 4) >"$dir/log/golden.txt" 2>&1
    local rc=$?
    local gp gf
    gp=$(grep -c '^passed ' "$dir/log/golden.txt")
    gf=$(grep -c '^failed \|^timed out ' "$dir/log/golden.txt")
    if [ "$gp" = 0 ] && [ "$gf" = 0 ] && [ $rc != 0 ]; then
        echo "$name: the golden runner did not run (exit $rc), see $dir/log/golden.txt"; tail -n 3 "$dir/log/golden.txt"
        harness=1
    fi
    local rt="runtime skipped (runtime/tests/run.sh missing)" rp=0 rf=0
    if [ -f "$root/runtime/tests/run.sh" ]; then
        env CC="$wrap" HARDEN_CFLAGS="$2" HARDEN_STRIP="$3" "$4=$opts" bash "$root/runtime/tests/run.sh" >"$dir/log/runtime.txt" 2>&1
        rp=$(grep -c '^ok ' "$dir/log/runtime.txt")
        rf=$(grep -c '^FAIL ' "$dir/log/runtime.txt")
        rt="runtime $rp ok, $rf failed"
    fi
    local reports
    reports=$(grep -lE 'runtime error:|ERROR: AddressSanitizer' "$dir"/log/san.* 2>/dev/null)
    local findings=0
    [ -z "$reports" ] || findings=$(printf '%s\n' "$reports" | wc -l | tr -d ' ')
    echo "$name: golden $gp passed, $gf failed; $rt; findings $findings"
    for f in $reports; do
        local prog=${f##*/san.}; prog=${prog%.*}
        echo "  finding ${prog#run_}: $(grep -m1 -E 'runtime error:|ERROR: AddressSanitizer' "$f" | cut -c1-160)"
    done
    sed -nE "s/^(failed|timed out) /  golden \1 /p" "$dir/log/golden.txt"
    sed -n 's/^FAIL \([^:]*\).*/  runtime failed \1/p' "$dir/log/runtime.txt" 2>/dev/null
}

for m in $modes; do
    case $m in
        ubsan)
            cell ubsan-wrapv "-fsanitize=undefined -fno-sanitize-recover=undefined" "" UBSAN_OPTIONS print_stacktrace=1
            cell ubsan-nowrapv "-fsanitize=undefined -fno-sanitize-recover=undefined" "-fwrapv" UBSAN_OPTIONS print_stacktrace=1 ;;
        asan)
            cell asan "-fsanitize=address" "" ASAN_OPTIONS detect_leaks=0:detect_stack_use_after_return=0:abort_on_error=0 ;;
    esac
done
exit $harness
