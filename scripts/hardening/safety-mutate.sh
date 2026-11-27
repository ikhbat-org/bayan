#!/usr/bin/env bash
# Plan 020 step 8b (handoff §H7): safety mutants of the accepted golden run/ cases, each checked by the checker under test.
# The run/ cases whose name contains the --only filter (as differential.sh lists them; .test.byn, `// os: windows` and
# `// mode: debug` cases left out) go through tools/safety-mutate.byn into tmp/hardening/mutants/; each mutant is then
# `"$BAYAN_EXE" check`ed alone in its own directory under tmp/hardening/mutant-check/ (`check` of a file checks its folder).
# A mutant is `killed` when check rejects it and its `// expect:` code is in the output, `discarded` when check rejects it
# with other codes only (plan 020 Noise trap 11: not counted), `accepted` when check exits 0: a finding. A kind with no
# site in an input counts as `no-site`. Prints the counts, the counts per kind and the accepted mutants (20 at most); the
# check output of every mutant goes to tmp/hardening/mutants.log. Exits 0 when it ran, 1 when the harness could not run,
# 2 on usage. Not `bayan test --mutate`, which grades tests; these attack the checker.
usage() {
    echo "usage: BAYAN_EXE=<driver> $0 [--only <case filter>] (default run/)" >&2
    exit 2
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
kinds="use-after-move borrow-escape write-while-borrowed effect-outside-uses untrusted-to-trusted"

# classify <check exit> <expected code> <check output file>: killed, discarded or accepted
classify() {
    if [ "$1" = 0 ]; then echo accepted
    elif grep -q "$2" "$3"; then echo killed
    else echo discarded
    fi
}

# the run/ cases (goldenBynCases): each run/*.byn file and each run/<dir>/main.byn, as `<name> <input>` lines in name order
list_cases() {
    local r="$root/tests/cases/run" f n
    for f in "$r"/*.byn; do [ -f "$f" ] && n=${f#$r/} && echo "${n%.byn} $f"; done
    find "$r" -mindepth 2 -name main.byn -type f | while read -r f; do n=${f#$r/}; echo "${n%/main.byn} $f"; done
}

# a sourced copy (safety-mutate.test.sh) gets the functions only
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
[ -x "$BAYAN_EXE" ] || { echo "safety-mutate: BAYAN_EXE ($BAYAN_EXE) is not an executable: build the driver first" >&2; exit 1; }
case "$BAYAN_EXE" in /*) ;; *) BAYAN_EXE="$PWD/$BAYAN_EXE" ;; esac

mutants="$root/tmp/hardening/mutants"; checks="$root/tmp/hardening/mutant-check"; log="$root/tmp/hardening/mutants.log"
rm -rf "$mutants" "$checks"; mkdir -p "$mutants" "$checks"
: >"$log"
selected="$root/tmp/hardening/mutant-cases.txt"
list_cases | LC_ALL=C sort | while read -r n f; do
    case "run/$n" in *"$only"*) ;; *) continue ;; esac
    [ "${f%.test.byn}" = "$f" ] || continue
    head -n 2 "$f" | tr -d '\r' | grep -qx '// os: windows' && continue
    head -n 1 "$f" | tr -d '\r' | grep -q '^// mode: *debug' && continue
    echo "$n $f"
done >"$selected"
inputs=$(wc -l <"$selected" | tr -d ' ')
[ "$inputs" != 0 ] || { echo "safety-mutate: no accepted run/ case name contains $only" >&2; exit 2; }

m=0; k=0; d=0; a=0; s=0; accepted=""
for kd in $kinds; do eval "m_${kd//-/_}=0 k_${kd//-/_}=0 d_${kd//-/_}=0 a_${kd//-/_}=0 s_${kd//-/_}=0"; done
lines="$root/tmp/hardening/mutant-lines.txt"
while read -r n f; do
    if ! bash "$root/scripts/bayan-tool.sh" safety-mutate "$f" "$mutants" >"$lines" 2>>"$log" </dev/null; then
        echo "safety-mutate: the tool failed on run/$n, see $log" >&2; exit 1
    fi
    for kd in $kinds; do
        grep -q "^$kd"$'\t' "$lines" || { s=$((s + 1)); eval "s_${kd//-/_}=\$((s_${kd//-/_} + 1))"; }
    done
    while IFS=$'\t' read -r kd path code; do
        m=$((m + 1))
        dir="$checks/$m"; mkdir -p "$dir"; cp "$path" "$dir/"
        out="$dir/check.out"
        (cd "$dir" && "$BAYAN_EXE" check "${path##*/}") >"$out" 2>&1 </dev/null
        rc=$?
        c=$(classify "$rc" "$code" "$out")
        case $c in
            killed) k=$((k + 1)); eval "k_${kd//-/_}=\$((k_${kd//-/_} + 1))" ;;
            discarded) d=$((d + 1)); eval "d_${kd//-/_}=\$((d_${kd//-/_} + 1))" ;;
            accepted) a=$((a + 1)); eval "a_${kd//-/_}=\$((a_${kd//-/_} + 1))"; [ $a -le 20 ] && accepted="$accepted  $path"$'\n' ;;
        esac
        eval "m_${kd//-/_}=\$((m_${kd//-/_} + 1))"
        { echo "== $c $kd $path (expect $code, exit $rc)"; cat "$out"; } >>"$log"
    done <"$lines"
done <"$selected"

echo "inputs $inputs, mutants $m, killed $k, discarded $d, accepted $a, no-site $s"
for kd in $kinds; do
    v=${kd//-/_}
    eval "echo \"  $kd: mutants \$m_$v, killed \$k_$v, discarded \$d_$v, accepted \$a_$v, no-site \$s_$v\""
done
[ $a = 0 ] || echo "accepted (findings):"
printf '%s' "$accepted"
[ $a -le 20 ] || echo "  … and $((a - 20)) more"
echo "log $log"
exit 0
