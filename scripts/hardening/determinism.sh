#!/usr/bin/env bash
# Plan 020 step 7 (H2 remainder): each selected golden run/ case is built twice, from a copy at tmp/hardening/det-a/ and from a copy
# at the longer absolute path tmp/hardening/det-b-longer-path/, each with its own fresh BAYAN_CACHE. The emitted C (`build --emit-c
# --mode <mode> <source>`, src/driver/build.byn) is compared byte for byte on every host; the linked binaries (`build --mode <mode>
# -o <program> <source>`, same compiler: $BAYAN_CC as given) only on Linux. BAYAN_CC_JOBS is 1 for copy A and 4 for copy B as
# the plan asks, but nothing under src/driver reads that variable (only src/driver/bounds.byn mentions it in a comment), so it
# has no effect today. A differing case is a `nondeterminism` finding; when the binaries differ and `strings` shows the A or B
# path in either, the finding carries the note `embedded build path`. Counts and finding names go to stdout, the diffs of the
# first 5 differing C files (20 lines each) to tmp/hardening/det-report.txt. Exits 0 when it ran, 1 when the harness could not
# run, 2 on usage.
usage() { echo "usage: BAYAN_EXE=<driver> $0 [--only <case filter>] (default run/)" >&2; exit 2; }

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# compare_case <c a> <c b> <binary a> <binary b> <check binary: 1|0> <path a> <path b>: prints nothing when the case is
# deterministic, else `c`, `bin` or `bin embedded build path` (`c bin ...` when both differ), one line.
compare_case() {
    local out=""
    cmp -s "$1" "$2" || out="c"
    if [ "$5" = 1 ] && ! cmp -s "$3" "$4"; then
        out="${out:+$out }bin"
        if { strings "$3"; strings "$4"; } 2>/dev/null | grep -qF -e "$6" -e "$7"; then out="$out embedded build path"; fi
    fi
    echo "$out"
}

# the run/ cases (goldenBynCases): each run/*.byn file and each run/<dir>/main.byn, as `<name> <input>` lines
list_cases() {
    local r="$root/tests/cases/run" f n
    for f in "$r"/*.byn; do [ -f "$f" ] && [ "${f%.test.byn}" = "$f" ] && n=${f#$r/} && echo "${n%.byn} $f"; done
    find "$r" -mindepth 2 -name main.byn -type f | while read -r f; do n=${f#$r/}; echo "${n%/main.byn} $f"; done
}

# a sourced copy (determinism.test.sh) gets the functions only
[ "${BASH_SOURCE[0]}" = "$0" ] || return 0

[ -n "$BAYAN_EXE" ] || usage
only="run/"
while [ $# -gt 0 ]; do
    case "$1" in
        --only) [ $# -ge 2 ] || usage; only=$2; shift ;;
        *) usage ;;
    esac
    shift
done
[ -x "$BAYAN_EXE" ] || { echo "determinism: BAYAN_EXE ($BAYAN_EXE) is not an executable: build the driver first" >&2; exit 1; }
case "$BAYAN_EXE" in /*) ;; *) BAYAN_EXE="$PWD/$BAYAN_EXE" ;; esac

base="$root/tmp/hardening"
dirs="$base/det-a $base/det-b-longer-path"
rm -rf $dirs; mkdir -p $dirs
report="$base/det-report.txt"; : >"$report"
linux=0; [ "$(uname -s)" = Linux ] && linux=1

# side <dir> <jobs> <case name> <input>: a copy of the case under <dir>/<flat>/ built with a fresh cache; leaves <flat>.c and <flat>.bin
side() {
    local dir=$1 jobs=$2 name=$3 input=$4 flat src first mode=safe
    flat=${name//\//_}
    mkdir -p "$dir/$flat/w" "$dir/cache-$flat"
    if [ "${input##*/}" = main.byn ] && [ "$name" != main ]; then
        cp -R "${input%/main.byn}/." "$dir/$flat/w/"; src="$dir/$flat/w/main.byn"
    else
        cp "$input" "$dir/$flat/w/"; src="$dir/$flat/w/${input##*/}"
    fi
    first=$(head -n 1 "$input" | tr -d '\r')
    case "$first" in "// mode: "*) mode=${first#// mode: }; mode=${mode// /} ;; esac
    case "$mode" in debug|fast) ;; *) mode=safe ;; esac
    (cd "$dir/$flat/w" && env BAYAN_CACHE="$dir/cache-$flat" BAYAN_CC_JOBS=$jobs "$BAYAN_EXE" build --emit-c --mode "$mode" "$src") \
        >"$dir/$flat.c" 2>"$dir/$flat.c.err" </dev/null || return 1
    if [ $linux = 1 ]; then
        (cd "$dir/$flat/w" && env BAYAN_CACHE="$dir/cache-$flat" BAYAN_CC_JOBS=$jobs "$BAYAN_EXE" build --mode "$mode" -o "$dir/$flat.bin" "$src") \
            >"$dir/$flat.bin.err" 2>&1 </dev/null || return 1
    fi
}

n=0; cd_n=0; bd_n=0; unbuilt=0; shown=0; names=""; nf=0
while read -r name input; do
    case "run/$name" in *"$only"*) ;; *) continue ;; esac
    head -n 2 "$input" | tr -d '\r' | grep -qx '// os: windows' && continue
    n=$((n + 1)); flat=${name//\//_}
    if ! side "$base/det-a" 1 "$name" "$input" || ! side "$base/det-b-longer-path" 4 "$name" "$input"; then
        unbuilt=$((unbuilt + 1)); continue
    fi
    r=$(compare_case "$base/det-a/$flat.c" "$base/det-b-longer-path/$flat.c" "$base/det-a/$flat.bin" "$base/det-b-longer-path/$flat.bin" \
        $linux "$base/det-a" "$base/det-b-longer-path")
    [ -n "$r" ] || continue
    nf=$((nf + 1))
    case "$r" in c*) cd_n=$((cd_n + 1)) ;; esac
    case "$r" in *bin*) bd_n=$((bd_n + 1)) ;; esac
    [ $nf -le 20 ] && names="$names  nondeterminism $name: ${r}"$'\n'
    case "$r" in c*)
        if [ $shown -lt 5 ]; then
            shown=$((shown + 1))
            { echo "== $name"; diff -u "$base/det-a/$flat.c" "$base/det-b-longer-path/$flat.c" | head -n 20; } >>"$report"
        fi ;;
    esac
done < <(list_cases | LC_ALL=C sort)

[ $n != 0 ] || { echo "determinism: no run/ case name contains $only" >&2; exit 2; }
if [ $unbuilt = $n ]; then echo "determinism: no case built, see $base/det-a/*.err" >&2; exit 1; fi
bs="skipped"; [ $linux = 1 ] && bs="Linux only"
echo "cases $n, C-differs $cd_n, binary-differs $bd_n ($bs)"
[ $unbuilt = 0 ] || echo "did not build: $unbuilt"
printf '%s' "$names"
[ $nf -le 20 ] || echo "  … and $((nf - 20)) more"
echo "report $report"
exit 0
