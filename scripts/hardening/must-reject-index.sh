#!/usr/bin/env bash
# Plan 020 step 8a: checks tests/hardening/must-reject/index.md against tests/cases/diag. Each index line `- diag/<case>: <code>[, <code>]`
# must name a case that exists (<case>.diag, or <case>/ holding *.diag) and whose expected output shows each listed code.
# Usage: must-reject-index.sh [index file] [diag case dir]. Prints `cases N, missing M, code-mismatch K` and the names; exit 1 on any
# missing or mismatch.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
index=${1:-$root/tests/hardening/must-reject/index.md}
dir=${2:-$root/tests/cases/diag}
[ -f "$index" ] || { echo "must-reject-index: no index $index" >&2; exit 1; }
[ -d "$dir" ] || { echo "must-reject-index: no case dir $dir" >&2; exit 1; }
n=0; missing=0; bad=0
while IFS= read -r line; do
    case "$line" in "- diag/"*) ;; *) continue ;; esac
    rest=${line#- diag/}
    name=${rest%%:*}
    codes=${rest#*:}
    n=$((n + 1))
    if [ -f "$dir/$name.diag" ]; then
        files=("$dir/$name.diag")
    elif [ -d "$dir/$name" ] && ls "$dir/$name"/*.diag >/dev/null 2>&1; then
        files=("$dir/$name"/*.diag)
    else
        echo "  missing diag/$name"; missing=$((missing + 1)); continue
    fi
    for code in ${codes//,/ }; do
        grep -q "$code" "${files[@]}" || { echo "  code-mismatch diag/$name: $code"; bad=$((bad + 1)); }
    done
done < "$index"
echo "cases $n, missing $missing, code-mismatch $bad"
[ $missing = 0 ] && [ $bad = 0 ]
