#!/usr/bin/env bash
# Plan 020 step 5 (H8, crash part): crash fuzzing of `bayan check` with AFL++, and runtime/tests/run.sh under Valgrind. Work goes
# under $FUZZ_DIR (default tmp/hardening/fuzz). Modes, one per call:
#   --build: $BAYAN_EXE builds src/driver into $FUZZ_DIR/bayan-afl through cc-wrap.sh, with HARDEN_CC=$FUZZ_CC (default
#     afl-clang-fast) and HARDEN_CFLAGS=-fsanitize=address. Log: build.log.
#   --afl [--minutes N] (default 30): checks the .byn seeds in $FUZZ_CORPUS (default tests/hardening/fuzz-corpus: at most 40
#     files, each at most 4096 bytes) and copies them to seeds/ (the README stays out), clears out/ and runs afl-fuzz on `bayan-afl check in/main.byn` (main.byn sits alone in in/, as `check` on
#     a file checks its folder), $FUZZ_TIMEOUT_MS (default 5000) per run. Prints the counts of out/default/fuzzer_stats and up to 20
#     crash/hang files. Log: afl.log.
#   --valgrind: runs runtime/tests/run.sh ($FUZZ_RUNSH) with CC set to this script's --vg-cc mode, which builds each test driver
#     with $HARDEN_CC (default cc) to <exe>.real and writes <exe> as a script running it under valgrind; a run exiting 99 is a
#     finding. Logs: valgrind/ (run.log, runs.tsv, vg.<exe>.<pid>).
#   --triage: reruns $BAYAN_EXE check on each out/default/crashes file, copied alone into triage/<n>/main.byn, and prints
#     `<file>\t<exit code>\t<first ASan/panic line>`; an exit 0 or 1 without such a line is diagnostics only, not a finding.
# The tools are $FUZZ_AFL (default afl-fuzz), $FUZZ_CC and $FUZZ_VALGRIND (default valgrind). Exits 0 when it ran (findings or
# not), 1 when the harness could not run (naming the missing tool), 2 on usage. --afl and --triage start under `setarch <arch> -R`
# ($FUZZ_SETARCH, default setarch, skipped when it cannot run): see sanitize.sh for the ASan DEADLYSIGNAL loop it avoids.
usage() { echo "usage: [BAYAN_EXE=<driver>] $0 --build | --afl [--minutes N] | --valgrind | --triage" >&2; exit 2; }

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
self="$root/scripts/hardening/fuzz.sh"
wrap="$root/scripts/hardening/cc-wrap.sh"
dir="${FUZZ_DIR:-$root/tmp/hardening/fuzz}"
corpus="${FUZZ_CORPUS:-$root/tests/hardening/fuzz-corpus}"
afl="${FUZZ_AFL:-afl-fuzz}"
vg="${FUZZ_VALGRIND:-valgrind}"
norand=()
sa="${FUZZ_SETARCH:-setarch}"
if "$sa" "$(uname -m)" -R true >/dev/null 2>&1; then norand=("$sa" "$(uname -m)" -R); fi

# --vg-cc <cc arguments>: the C compiler run.sh calls in --valgrind mode (see above). $FUZZ_VG_DIR is the log directory.
if [ "$1" = --vg-cc ]; then
    shift
    real=${HARDEN_CC:-cc}
    args=(); out=""; prev=""
    for a in "$@"; do
        if [ "$prev" = -o ]; then out=$a; args+=("$a.real"); else args+=("$a"); fi
        prev=$a
    done
    [ -n "$out" ] || exec $real "$@"
    $real "${args[@]}" || exit $?
    cat >"$out" <<EOF
#!/bin/sh
"$vg" --error-exitcode=99 --leak-check=no -q --log-file="$FUZZ_VG_DIR/vg.${out##*/}.%p" "$out.real" "\$@"
rc=\$?
n="${out##*/}"; [ \$# -gt 0 ] && n="\$n \${1##*/}"
printf '%s\t%s\n' "\$n" "\$rc" >>"$FUZZ_VG_DIR/runs.tsv"
exit \$rc
EOF
    chmod +x "$out"
    exit 0
fi

mode=""; minutes=30
while [ $# -gt 0 ]; do
    case "$1" in
        --build|--afl|--valgrind|--triage) [ -z "$mode" ] || usage; mode=$1 ;;
        --minutes) [ $# -ge 2 ] || usage; minutes=$2; shift ;;
        *) usage ;;
    esac
    shift
done
[ -n "$mode" ] || usage
case "$minutes" in ''|*[!0-9]*|0) usage ;; esac
need() { command -v "$1" >/dev/null 2>&1 || { echo "fuzz: no $1 on PATH ($2)" >&2; exit 1; }; }
need_exe() {
    [ -n "$BAYAN_EXE" ] || usage
    [ -x "$BAYAN_EXE" ] || { echo "fuzz: BAYAN_EXE ($BAYAN_EXE) is not an executable: build the driver first" >&2; exit 1; }
    case "$BAYAN_EXE" in /*) ;; *) BAYAN_EXE="$PWD/$BAYAN_EXE" ;; esac
}
mkdir -p "$dir"

case $mode in
--build)
    need_exe
    cc=${FUZZ_CC:-afl-clang-fast}
    need "${cc%% *}" "install AFL++ or set FUZZ_CC"
    rm -f "$dir/bayan-afl"
    (cd "$root" && env BAYAN_CC="$wrap" HARDEN_CC="$cc" HARDEN_CFLAGS=-fsanitize=address HARDEN_STRIP="" BAYAN_CACHE="$dir/cache" \
        "$BAYAN_EXE" build --package src -o "$dir/bayan-afl" src/driver) >"$dir/build.log" 2>&1
    rc=$?
    if [ $rc != 0 ] || [ ! -x "$dir/bayan-afl" ]; then
        echo "fuzz: the build failed (exit $rc), see $dir/build.log" >&2; tail -n 3 "$dir/build.log" >&2; exit 1
    fi
    echo "build: $dir/bayan-afl"
    ;;
--afl)
    need "$afl" "install AFL++ or set FUZZ_AFL"
    [ -x "$dir/bayan-afl" ] || { echo "fuzz: no $dir/bayan-afl: run --build first" >&2; exit 1; }
    seeds=0
    rm -rf "$dir/seeds"; mkdir -p "$dir/seeds"
    for f in "$corpus"/*.byn; do
        [ -f "$f" ] || continue
        seeds=$((seeds + 1))
        size=$(wc -c <"$f" | tr -d ' ')
        [ "$size" -le 4096 ] || { echo "fuzz: corpus file $f is $size bytes, over 4096" >&2; exit 1; }
        cp "$f" "$dir/seeds/"
    done
    [ $seeds -gt 0 ] || { echo "fuzz: no seeds in $corpus" >&2; exit 1; }
    [ $seeds -le 40 ] || { echo "fuzz: $corpus holds $seeds files, over 40" >&2; exit 1; }
    rm -rf "$dir/out" "$dir/in"; mkdir -p "$dir/in" "$dir/cache"
    if [ -r /proc/sys/kernel/core_pattern ] && [ "$(head -c 1 /proc/sys/kernel/core_pattern)" = "|" ]; then
        export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
        echo "afl: core_pattern pipes to a handler (not changed, no root): set AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1"
    fi
    # AFL_DEBUG_CHILD=1: on wp1 WSL (afl-fuzz++4.04c) the fork server dies with signal 11 when afl-fuzz redirects the target's
    # stdout/stderr itself; with the child's output passed through it runs (7291 execs in 20 s, 2026-11-27). The diagnostics
    # then reach this log, so it keeps only its last 4 MB.
    env AFL_SKIP_CPUFREQ=1 AFL_NO_UI=1 AFL_DEBUG_CHILD=1 BAYAN_CACHE="$dir/cache" \
        ASAN_OPTIONS=abort_on_error=1:symbolize=0:detect_leaks=0:detect_stack_use_after_return=0 \
        ${norand[@]+"${norand[@]}"} "$afl" -V $((minutes * 60)) -t "${FUZZ_TIMEOUT_MS:-5000}" -m none -i "$dir/seeds" -o "$dir/out" -f "$dir/in/main.byn" \
        -- "$dir/bayan-afl" check "$dir/in/main.byn" 2>&1 | tail -c 4000000 >"$dir/afl.log"
    rc=${PIPESTATUS[0]}
    stats="$dir/out/default/fuzzer_stats"
    if [ ! -f "$stats" ]; then
        echo "fuzz: afl-fuzz did not run (exit $rc), see $dir/afl.log" >&2; tail -n 5 "$dir/afl.log" >&2; exit 1
    fi
    awk -F' *: *' '
        $1 == "execs_done" { e = $2 }
        $1 == "corpus_count" || $1 == "paths_total" { p = $2 }
        $1 == "saved_crashes" || $1 == "unique_crashes" { c = $2 }
        $1 == "saved_hangs" || $1 == "unique_hangs" { h = $2 }
        END { printf "afl: execs %d, paths %d, crashes %d, hangs %d\n", e, p, c, h }' "$stats"
    for f in "$dir"/out/default/crashes/id:* "$dir"/out/default/hangs/id:*; do [ -f "$f" ] && echo "  $f"; done | head -n 20
    ;;
--valgrind)
    need "$vg" "install Valgrind or set FUZZ_VALGRIND"
    need "${HARDEN_CC:-cc}" "set HARDEN_CC"
    runsh="${FUZZ_RUNSH:-$root/runtime/tests/run.sh}"
    [ -f "$runsh" ] || { echo "fuzz: no $runsh" >&2; exit 1; }
    v="$dir/valgrind"
    rm -rf "$v"; mkdir -p "$v"
    env CC="bash $self --vg-cc" FUZZ_VG_DIR="$v" FUZZ_VALGRIND="$vg" bash "$runsh" >"$v/run.log" 2>&1
    [ -s "$v/runs.tsv" ] || { echo "fuzz: no test driver ran under valgrind, see $v/run.log" >&2; tail -n 3 "$v/run.log" >&2; exit 1; }
    n=$(wc -l <"$v/runs.tsv" | tr -d ' ')
    e=$(awk -F'\t' '$2 == 99' "$v/runs.tsv" | wc -l | tr -d ' ')
    echo "valgrind: tests $n, clean $((n - e)), errors $e (run.sh: $(tail -n 1 "$v/run.log"))"
    awk -F'\t' '$2 == 99 { print "  error " $1 }' "$v/runs.tsv" | head -n 20
    ;;
--triage)
    need_exe
    rm -rf "$dir/triage"; mkdir -p "$dir/triage" "$dir/cache"
    i=0; findings=0
    for f in "$dir"/out/default/crashes/id:*; do
        [ -f "$f" ] || continue
        i=$((i + 1)); t="$dir/triage/$i"
        mkdir -p "$t"; cp "$f" "$t/main.byn"
        (cd "$t" && ${norand[@]+"${norand[@]}"} env BAYAN_CACHE="$dir/cache" "$BAYAN_EXE" check main.byn) >"$t/stdout" 2>"$t/stderr"
        rc=$?
        line=$(grep -m 1 -E 'ERROR: AddressSanitizer|panic' "$t/stderr" | cut -c1-160)
        if [ -n "$line" ] || { [ $rc != 0 ] && [ $rc != 1 ]; }; then findings=$((findings + 1)); fi
        printf '%s\t%s\t%s\n' "$f" "$rc" "${line:--}"
    done
    echo "triage: crashes $i, findings $findings"
    ;;
esac
exit 0
