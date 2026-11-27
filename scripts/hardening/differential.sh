#!/usr/bin/env bash
# Plan 020 step 4: the golden run/ cases built through cc-wrap.sh per cell (gcc and clang, each with the flag sets below) and their
# outcomes compared with the first cell that ran (gcc/O0 by default). The golden runner keeps no per-case outcome (it removes
# tmp/run-build when it ends), so each case is built and run here the way goldenRunOutcome (src/driver/golden.byn) does it:
# `build --mode <first-line mode> -o <program> <source>` from the repo root (a flat case from a copy alone in a `run/` directory,
# a `<dir>/main.byn` case in place), then the program in an empty work directory with its .args and .stdin; a .test.byn case is
# `test -v` of a work directory holding only it, its `<n>.<nn>s` masked as `Ts`. Each cell runs in tmp/hardening/diff-<cc>-<set>/
# with its own BAYAN_CACHE; the cell's directory is masked as `<cell>` in both streams. A record line per case in records.tsv:
# `<case>\t<exit>\t<sha256 of stdout>\t<sha256 of stderr>`, exit `build` when it did not build and `debug` for a `// mode: debug`
# case (not built, skipped from comparison). Prints counts per cell and the divergent names; full diffs go to
# tmp/hardening/diff-report.txt. Exits 0 when it ran, 1 when the harness could not run, 2 on usage.
usage() {
    echo "usage: BAYAN_EXE=<driver> $0 [--only <case filter>] (default run/) [--cells <cc>/<set>,...] [--werror]" >&2
    echo "  cc: gcc clang; set: O0 O2 O3 O2-strict-aliasing O2-unsigned-char O2-signed-char" >&2
    exit 2
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
self="$root/scripts/hardening/differential.sh"
wrap="$root/scripts/hardening/cc-wrap.sh"
werror_flags='-O2 -Werror=implicit-function-declaration -Werror=return-type -Werror=incompatible-pointer-types -Werror=int-conversion -Werror=uninitialized -Werror=sequence-point -Werror=shift-count-overflow -Werror=strict-aliasing -Werror=format'

# flags_of <set>: the HARDEN_CFLAGS of a flag set; fails on an unknown one.
flags_of() {
    case $1 in
        O0) echo "-O0" ;;
        O2) echo "-O2" ;;
        O3) echo "-O3" ;;
        O2-strict-aliasing) echo "-O2 -fstrict-aliasing" ;;
        O2-unsigned-char) echo "-O2 -funsigned-char" ;;
        O2-signed-char) echo "-O2 -fsigned-char" ;;
        werror) echo "$werror_flags" ;;
        *) return 1 ;;
    esac
}

cell_dir() { echo "$root/tmp/hardening/diff-${1%%/*}-${1#*/}"; }

# trap_line <stderr file>: its first line naming a Bayān panic, trap or error (trap 10: the trap line, not the signal).
trap_line() { grep -m1 -E 'panic|trap|error' "$1" 2>/dev/null; }

# compare_cells <base dir> <cell dir> <report file>: the cell's records against the base's. A case diverges when its stdout hash
# differs, or its exit differs unless both are non-zero with the same non-empty trap line. Debug records are counted and skipped.
# Prints `cases N, divergent M, debug skipped D` and the divergent names (20 at most); appends the diffs to the report.
compare_cells() {
    local base=$1 other=$2 report=$3 n=0 m=0 d=0 names="" k
    local tab=$'\t'
    while IFS="$tab" read -r c be bo bs oe oo os; do
        if [ "$be" = debug ] || [ "$oe" = debug ]; then d=$((d + 1)); continue; fi
        n=$((n + 1))
        local div=0 f=${c//\//_}
        if [ "$bo" != "$oo" ]; then
            div=1
        elif [ "$be" != "$oe" ]; then
            local bt ot
            bt=$(trap_line "$base/out/$f.stderr"); ot=$(trap_line "$other/out/$f.stderr")
            if [ "$be" = 0 ] || [ "$oe" = 0 ] || [ -z "$bt" ] || [ "$bt" != "$ot" ]; then div=1; fi
        fi
        [ $div = 1 ] || continue
        m=$((m + 1))
        [ $m -le 20 ] && names="$names  $c"$'\n'
        {
            echo "== $c: exit $be vs $oe ($base vs $other)"
            diff -u "$base/out/$f.stdout" "$other/out/$f.stdout"
            diff -u "$base/out/$f.stderr" "$other/out/$f.stderr"
        } >>"$report" 2>&1
    done < <(LC_ALL=C join -t "$tab" -a 2 -e MISSING -o 0,1.2,1.3,1.4,2.2,2.3,2.4 "$base/records.tsv" "$other/records.tsv")
    echo "cases $n, divergent $m, debug skipped $d"
    printf '%s' "$names"
    if [ $m -gt 20 ]; then k=$((m - 20)); echo "  … and $k more"; fi
}

sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum <"$1" | cut -d' ' -f1; else shasum -a 256 <"$1" | cut -d' ' -f1; fi; }

# run_case <cell dir> <case name> <input>: builds and runs one case in the cell's environment, writing its record to rec/<flat>.
run_case() {
    local dir=$1 name=$2 input=$3
    local flat="run_${name//\//_}"
    [ "${input##*/}" = main.byn ] && [ "$name" != main ] && flat="${flat}_main"
    local rec="$dir/rec/$flat" o="$dir/out/run_${name//\//_}.stdout" e="$dir/out/run_${name//\//_}.stderr"
    local first mode=safe
    first=$(head -n 1 "$input" | tr -d '\r')
    case "$first" in "// mode: "*) mode=${first#// mode: }; mode=${mode// /} ;; esac
    case "$mode" in debug|fast) ;; *) mode=safe ;; esac
    if [ "$mode" = debug ]; then printf 'run/%s\tdebug\t-\t-\n' "$name" >"$rec"; return; fi
    local work="$dir/run/$flat" rc
    rm -rf "$work"; mkdir -p "$work"
    if [ "${input%.test.byn}" != "$input" ]; then
        cp "$input" "$work/"
        (cd "$root" && "$BAYAN_EXE" test -v "$work") >"$o" 2>"$e" </dev/null
        rc=$?
        perl -pi -e 's/\d+\.\d\ds$/Ts/' "$o"
    else
        local build="$dir/run-build/$flat" src=$input
        rm -rf "$build"; mkdir -p "$build"
        if [ "${input##*/}" != main.byn ] || [ "$name" = main ]; then
            mkdir -p "$build/run"; cp "$input" "$build/run/"; src="$build/run/${input##*/}"
        fi
        if (cd "$root" && "$BAYAN_EXE" build --mode "$mode" -o "$build/$flat" "$src") >"$e" 2>&1 </dev/null; then
            local args=() line stdin=/dev/null
            if [ -f "${input%.byn}.args" ]; then
                while IFS= read -r line || [ -n "$line" ]; do args+=("${line%$'\r'}"); done <"${input%.byn}.args"
            fi
            [ -f "${input%.byn}.stdin" ] && stdin="${input%.byn}.stdin"
            # the outer 2> drops bash's `Abort trap` note on a program that panics; the program's stderr is in $e
            { (cd "$work" && perl -e 'alarm shift; exec @ARGV or exit 127' 120 "$build/$flat" ${args[@]+"${args[@]}"}) \
                >"$o" 2>"$e" <"$stdin"; } 2>/dev/null
            rc=$?
        else
            rc=build; : >"$o"
        fi
    fi
    D="$dir" perl -pi -e 's/\Q$ENV{D}\E/<cell>/g' "$o" "$e"
    printf 'run/%s\t%s\t%s\t%s\n' "$name" "$rc" "$(sha "$o")" "$(sha "$e")" >"$rec"
}

# the run/ cases (goldenBynCases): each run/*.byn file and each run/<dir>/main.byn, as `<name> <input>` lines in name order
list_cases() {
    local r="$root/tests/cases/run" f n
    for f in "$r"/*.byn; do [ -f "$f" ] && n=${f#$r/} && echo "${n%.byn} $f"; done
    find "$r" -mindepth 2 -name main.byn -type f | while read -r f; do n=${f#$r/}; echo "${n%/main.byn} $f"; done
}

# a sourced copy (differential.test.sh) gets the functions only; `--case` is one case of a cell, run by xargs below
[ "${BASH_SOURCE[0]}" = "$0" ] || return 0
if [ "$1" = --case ]; then run_case "$2" "$3" "$4"; exit 0; fi

[ -n "$BAYAN_EXE" ] || usage
only="run/"; cells=""; werror=0
while [ $# -gt 0 ]; do
    case "$1" in
        --only) [ $# -ge 2 ] || usage; only=$2; shift ;;
        --cells) [ $# -ge 2 ] || usage; cells=${2//,/ }; shift ;;
        --werror) werror=1 ;;
        *) usage ;;
    esac
    shift
done
if [ -z "$cells" ]; then
    for c in gcc clang; do
        for s in O0 O2 O3 O2-strict-aliasing O2-unsigned-char O2-signed-char; do cells="$cells $c/$s"; done
    done
fi
for c in $cells; do
    case "${c%%/*}" in gcc|clang) ;; *) usage ;; esac
    [ "$c" != "${c#*/}" ] && flags_of "${c#*/}" >/dev/null || usage
done
[ -x "$BAYAN_EXE" ] || { echo "differential: BAYAN_EXE ($BAYAN_EXE) is not an executable: build the driver first" >&2; exit 1; }
case "$BAYAN_EXE" in /*) ;; *) BAYAN_EXE="$PWD/$BAYAN_EXE" ;; esac
export BAYAN_EXE

selected="$root/tmp/hardening/diff-cases.txt"
mkdir -p "$root/tmp/hardening"
list_cases | LC_ALL=C sort | while read -r n f; do
    case "run/$n" in *"$only"*) echo "$n $f" ;; esac
done >"$selected"
total=$(wc -l <"$selected" | tr -d ' ')
[ "$total" != 0 ] || { echo "differential: no run/ case name contains $only" >&2; exit 2; }
report="$root/tmp/hardening/diff-report.txt"
: >"$report"

harness=0
ran=""
# cell <cc>/<set> [stripped flags]: builds and runs the selected cases (4 at a time) through cc-wrap.sh with the set's flags
cell() {
    local name=$1 dir
    dir=$(cell_dir "$1")
    command -v "${name%%/*}" >/dev/null 2>&1 || { echo "$name: skipped, ${name%%/*} is not on PATH"; return 1; }
    rm -rf "$dir"; mkdir -p "$dir/rec" "$dir/out" "$dir/cache" "$dir/run" "$dir/run-build"
    # os: windows cases are left out, as goldenOsSkip does off Windows
    while read -r n f; do
        head -n 2 "$f" | tr -d '\r' | grep -qx '// os: windows' || echo "$n $f"
    done <"$selected" | env BAYAN_CC="$wrap" HARDEN_CC="${name%%/*}" HARDEN_CFLAGS="$(flags_of "${name#*/}")" HARDEN_STRIP="$2" \
        BAYAN_CACHE="$dir/cache" xargs -n 2 -P 4 bash "$self" --case "$dir"
    cat "$dir"/rec/* 2>/dev/null | LC_ALL=C sort >"$dir/records.tsv"
    local n b
    n=$(wc -l <"$dir/records.tsv" | tr -d ' ')
    b=$(cut -f2 "$dir/records.tsv" | grep -cx build)
    echo "$name: ran $n cases, $b did not build"
    if [ "$n" = 0 ] || { [ "$b" = "$n" ] && [ "${name#*/}" != werror ]; }; then
        echo "$name: no case built, see $dir/out"; harness=1
    fi
    return 0
}

for c in $cells; do cell "$c" && ran="$ran $c"; done
set -- $ran
[ $# -gt 0 ] || { echo "differential: no cell ran" >&2; exit 1; }
base=$1
echo "base $base"
shift
for c in "$@"; do
    echo "$c: $(compare_cells "$(cell_dir "$base")" "$(cell_dir "$c")" "$report")"
done

if [ $werror = 1 ]; then
    case " $ran " in *" gcc/O2 "*) ;; *) cell gcc/O2 "" ;; esac
    if cell gcc/werror -w && [ -f "$(cell_dir gcc/O2)/records.tsv" ]; then
        findings=$(LC_ALL=C join -t $'\t' -o 0,1.2,2.2 "$(cell_dir gcc/O2)/records.tsv" "$(cell_dir gcc/werror)/records.tsv" \
            | awk -F'\t' '$2 != "build" && $3 == "build" { print $1 }')
        nf=0; [ -z "$findings" ] || nf=$(printf '%s\n' "$findings" | wc -l | tr -d ' ')
        echo "gcc/werror: findings $nf (build in gcc/O2, not with -Werror)"
        printf '%s\n' "$findings" | head -n 20 | sed '/^$/d; s/^/  /'
        [ "$nf" -le 20 ] || echo "  … and $((nf - 20)) more"
        for f in $findings; do
            echo "== werror $f"; cat "$(cell_dir gcc/werror)/out/${f//\//_}.stderr"
        done >>"$report"
    fi
fi
echo "report $report"
exit $harness
