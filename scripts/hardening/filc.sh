#!/usr/bin/env bash
# Plan 020 step 3: the golden run/ cases through $BAYAN_EXE with the runtime and program built by the Fil-C clang (install-filc.sh,
# or $FILC_CC), via cc-wrap.sh, in tmp/hardening/filc-cell/ (the golden runner's child cache is $PWD/tmp/cache). First an audit
# pass over the runtime C for constructs Fil-C treats badly (inline asm, pointer/integer casts). A finding is a case whose exit
# differs from its expected one (a `failed ` line in the golden output) and whose stderr, kept under the cell's log dir, names Fil-C:
# the marker is "filc panic" or "Fil-C" (case-insensitive "filc"), which covers Fil-C's "filc safety error"/"filc panic" text.
# Output: audit count, golden counts, finding names; logs in the cell dir. Exits 0 when it ran, 1 on harness failure, 2 on usage.
usage() { echo "usage: BAYAN_EXE=<driver> $0 [--only <case filter>] (default filter run/)" >&2; exit 2; }

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
wrap="$root/scripts/hardening/cc-wrap.sh"
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
findings=$(grep -ciE 'filc panic|fil-c|filc safety' "$dir/log/golden.txt")
echo "filc: golden $gp passed, $gf failed; findings $findings"
sed -nE "s/^(failed|timed out) /  golden \1 /p" "$dir/log/golden.txt"
grep -iE 'filc panic|fil-c|filc safety' "$dir/log/golden.txt" | cut -c1-160 | sed 's/^/  finding: /'
exit 0
