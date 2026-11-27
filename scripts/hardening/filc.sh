#!/usr/bin/env bash
# Plan 020 step 3: the golden run/ cases through $BAYAN_EXE with the runtime and program built by the Fil-C clang (install-filc.sh,
# or $FILC_CC), via cc-wrap.sh, in tmp/hardening/filc-cell/ (the golden runner's child cache is $PWD/tmp/cache). First an audit
# pass over the runtime C for constructs Fil-C treats badly (inline asm, pointer/integer casts). A finding is a case whose exit
# differs from its expected one (the case's .exitcode, else 0) and whose own stderr names Fil-C: the golden runner keeps no program
# stderr, so each run/ case is also built and run by differential.sh's run_case (sourced, run through its `--case`), which records
# the program's stderr under the cell's out/. The marker is the case-insensitive extended regex "filc (panic|safety)" (Fil-C's
# "filc panic"/"filc safety error" text). A case that did not build (a compile error) is not a finding, nor is Fil-C's abort():
# exit 133 with "filc user error: abort() called" and no safety error, where the case expects SIGABRT's 134.
# Output: audit count, golden counts, finding names (also in log/findings.txt); logs in the cell dir. Exits 0 when it ran, 1 on harness failure, 2 on usage.

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wrap="$root/scripts/hardening/cc-wrap.sh"
# shellcheck source=differential.sh
source "$root/scripts/hardening/differential.sh"
usage() { echo "usage: BAYAN_EXE=<driver> $0 [--only <case filter>] (default filter run/)" >&2; exit 2; }
[ -n "$BAYAN_EXE" ] || usage
only="run/"
while [ $# -gt 0 ]; do
    case "$1" in
        --only) [ $# -ge 2 ] || usage; only=$2; shift ;;
        *) usage ;;
    esac
    shift
done
[ -x "$BAYAN_EXE" ] || { echo "filc: BAYAN_EXE ($BAYAN_EXE) is not an executable: build the driver first" >&2; exit 1; }
case "$BAYAN_EXE" in /*) ;; *) BAYAN_EXE="$PWD/$BAYAN_EXE" ;; esac
export BAYAN_EXE

cc="$FILC_CC"
if [ -z "$cc" ]; then
    cc=$(bash "$root/scripts/hardening/install-filc.sh") || { echo "filc: install-filc.sh failed" >&2; exit 1; }
fi
[ -x "$cc" ] || { echo "filc: $cc is not an executable" >&2; exit 1; }

dir="$root/tmp/hardening/filc-cell"
rm -rf "$dir"; mkdir -p "$dir/log" "$dir/cache"

files=""
for f in "$root/runtime/bayan-rt.c" "$root/bootstrap/bayan-rt.c"; do [ -f "$f" ] && files="$files $f"; done
[ -z "$files" ] || grep -n -E '__asm__|asm *\(|\(u?intptr_t\)|\(size_t\) *\(?[a-z_]*\*' $files >"$dir/log/audit.txt"
audit=$(wc -l <"$dir/log/audit.txt" 2>/dev/null | tr -d ' ')
echo "filc: audit ${audit:-0} lines (see $dir/log/audit.txt)"

(cd "$dir" && env BAYAN_CC="$wrap" HARDEN_CC="$cc" HARDEN_STRIP="" BAYAN_CC_TIMEOUT_S=1800 BAYAN_CACHE="$dir/cache" \
    "$BAYAN_EXE" test "$root/tests/cases" --only "$only" --jobs 4) >"$dir/log/golden.txt" 2>&1
rc=$?
gp=$(grep -c '^passed ' "$dir/log/golden.txt")
gf=$(grep -c '^failed \|^timed out ' "$dir/log/golden.txt")
if [ "$gp" = 0 ] && [ "$gf" = 0 ] && [ $rc != 0 ]; then
    echo "filc: the golden runner did not run (exit $rc), see $dir/log/golden.txt"; tail -n 3 "$dir/log/golden.txt"
    exit 1
fi
selected="$dir/selected.txt"
mkdir -p "$dir/rec" "$dir/out" "$dir/run" "$dir/run-build"
list_cases | LC_ALL=C sort | while read -r n f; do
    case "run/$n" in *"$only"*) head -n 2 "$f" | tr -d '\r' | grep -qx '// os: windows' || echo "$n $f" ;; esac
done >"$selected"
env BAYAN_CC="$wrap" HARDEN_CC="$cc" HARDEN_STRIP="" BAYAN_CC_TIMEOUT_S=1800 BAYAN_CACHE="$dir/cache" \
    xargs -n 2 -P 4 bash "$root/scripts/hardening/differential.sh" --case "$dir" <"$selected"
cat "$dir"/rec/* 2>/dev/null | LC_ALL=C sort >"$dir/records.tsv"
: >"$dir/log/findings.txt"
while IFS=$'\t' read -r c rc _; do
    case "$rc" in build|debug) continue ;; esac
    n=${c#run/}
    f=$(awk -v n="$n" '$1 == n { print $2 }' "$selected")
    want=0; [ -f "${f%.byn}.exitcode" ] && want=$(tr -d ' \r\n' <"${f%.byn}.exitcode")
    [ "$rc" != "$want" ] || continue
    e="$dir/out/run_${n//\//_}.stderr"
    # Fil-C reports abort() as exit 133 with "filc user error: abort() called" (and "filc panic: user thwarted themselves."),
    # where a native build gets SIGABRT's 134: a panic case doing that is the expected abort, unless a safety error came first.
    if [ "$want" = 134 ] && [ "$rc" = 133 ] && grep -qF 'filc user error: abort() called' "$e" && ! grep -qi 'filc safety' "$e"; then
        continue
    fi
    grep -qiE 'filc (panic|safety)' "$e" && echo "$c" >>"$dir/log/findings.txt"
done <"$dir/records.tsv"
findings=$(wc -l <"$dir/log/findings.txt" | tr -d ' ')
echo "filc: golden $gp passed, $gf failed; findings $findings"
sed -nE "s/^(failed|timed out) /  golden \1 /p" "$dir/log/golden.txt"
sed 's/^/  finding /' "$dir/log/findings.txt"
exit 0
