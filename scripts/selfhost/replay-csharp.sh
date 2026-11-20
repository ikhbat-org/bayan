#!/usr/bin/env bash
# Spec 019 T59 part 2 (019-t59b), the L043 replay: the frozen expected files export mode does not write, run again through the C# CLI
# built from the export head. scripts/selfhost/reexport-check.sh builds that CLI, picks the units and calls this (one entry point).
#   bash scripts/selfhost/replay-csharp.sh --list
#   bash scripts/selfhost/replay-csharp.sh <C# bayan> <units file> <work dir>
# --list prints `<unit>\t<route>\t<reason>` for each EXPORT.tsv class export mode leaves out (<kind>/<Class>) and each flat kind (<kind>):
# the route `case`, `scratch` or `flat` when it is replayed, `-` and the reason when it is not.
# <units file>: lines `<kind>/<Class>` (every case of the class) or `<kind> <kind>/<rel path>` (one flat input, named as freeze-csharp.sh
# names it). Every run has CI=1, BAYAN_CACHE <work dir>/cache and stdin empty (a case's `stdin` file aside); routes:
#   case     emit-c and sem classes the T27 route recorded with relative paths: the argv of the case's `args` runs in the case's
#            directory of the tree (its input.byn or input/ in place); stdout is expected.c (emit-c) or expected.stdout, with expected.stderr and
#            expected.exitcode; the case directory reads back as the relative path (`<dir>/input.byn` as
#            `input.byn`, as the recorded bytes hold it: the C# check prints the path it was given made absolute)
#   scratch  cli classes whose `args` name `<repo>/...`: a fresh scratch dir stands for the repo; the input (input.byn, or the one file
#            of input.tsv over tests/cases/inputs/files) is placed at the first `<repo>/` path of `args`; `env` lines are set (a bare
#            NAME is unset); `<repo>` in args, env and stdin reads as the scratch dir, and the scratch dir reads back as `<repo>` in what
#            the run printed (the T27 recording, goldenexport.byn:1764); compare word `seconds-masked` maps ` in <n>.<nn>s` to
#            ` in masked` (the recording mask, goldenexport.byn:1827); the run is in the scratch dir; every run has NO_COLOR, FORCE_COLOR,
#            COLORTERM, BAYAN_THEME and COLORFGBG unset (goldenexport.byn:639)
#   flat     the argv of freeze-csharp.sh in the input's directory of the tree: parse `parse --ast <file>` (stdout is <stem>.ast),
#            typed `types --package . <file>` (stdout is <stem>.types); the exit code is compared with the input's line of
#            tests/cases/emit/exit/expected.<kind>.exitcode
# A produced file is compared by bytes with the tree's when that tree path has a FREEZE.tsv file row (an exit-code line: when the input
# has a line there), unless its case is on DIVERGENCES.tsv (<kind>/<Class>/<case>, <Class>.<case> or <Class>.<Test> for a case
# <Test>-<n>; flat: <kind>/<stem>). A differing file is printed with its first differing line; a frozen file the replay did not
# produce is printed as missing. Prints `replay: <n> files compared, <d> on the divergence list, <f> failed`; exit 0 when none failed,
# 1 when one did, 2 on a usage error.
# DIVERGENCES.tsv rows with question T59 for wall times in frozen bytes (the `untimed` compare word of the T27 sem cases):
#   grep -l -E ' in [0-9]+\.[0-9][0-9]s' tests/cases/sem/{BuiltinResultsTests,FunctionTypeTests}/*/expected.stdout
# bash 3.2.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root" || exit 2
cases=tests/cases; tab="$(printf '\t')"

list() {
  local why_mut="its stdout went through the C# MaskMutation (SelfhostDriverMutateTests.cs:52-71), which the replay does not carry"
  local why_inproc="the C# golden test rendered it in process (golden.byn:704 goldenProduce); no CLI argv writes these bytes"
  local why_slice="a CLI route exists but is not replayed in this slice (019-t59b)"
  printf '%s\t%s\t%s\n' \
    cli/DiagnosticRendererTests scratch "" \
    cli/L007UntrustedSinkTests scratch "" \
    cli/L010Utf8DecodeTests scratch "" \
    cli/MutatorTests - "$why_mut" \
    cli/TypedDumpTests scratch "" \
    emit-c/CollectionLiteralTests case "" \
    emit-c/DynRefEmitTests case "" \
    emit-c/GenericsTests case "" \
    emit-c/LambdaEmitTests case "" \
    emit-c/MapKeyEmitTests case "" \
    emit-c/SymbolEmitTests case "" \
    sem/BuiltinResultsTests case "" \
    sem/ErrorUnionTypeTests case "" \
    sem/FunctionTypeTests case "" \
    sem/InterfaceDeclarationTests case "" \
    parse flat "" \
    typed flat "" \
    diag - "$why_inproc" \
    diag-json - "$why_inproc" \
    lex - "$why_inproc" \
    manifest - "$why_inproc" \
    emit - "$why_slice (freeze-csharp.sh writes it; its exit-code files are checked line by line through parse and typed)" \
    run - "$why_slice" \
    style - "$why_slice" \
    new - "$why_slice" \
    out - "$why_slice"
}
if [ $# = 1 ] && [ "$1" = --list ]; then list; exit 0; fi
[ $# = 3 ] || { echo "usage: replay-csharp.sh --list | <C# bayan> <units file> <work dir>" >&2; exit 2; }
cs="$1"; units="$2"; w="$3"
case "$cs" in (/*) ;; (*) cs="$PWD/$cs" ;; esac
[ -x "$cs" ] && [ -f "$units" ] && [ -d "$w" ] || { echo "replay-csharp: no executable $cs, units file $units or work dir $w" >&2; exit 2; }
w="$(cd "$w" && pwd)"
mkdir -p "$w/cache" "$w/s"
list > "$w/routes"
awk -F'\t' '$1 == "file" { print $3 }' "$cases/FREEZE.tsv" > "$w/frozen"
awk -F'\t' 'NR > 1 { print $1 }' "$cases/DIVERGENCES.tsv" > "$w/divkeys"
n=0; ndiv=0; bad=0

# put <text file> <from> <to>: the file with each <from> read as <to> (literal text), in place
put() {
  awk -v a="$2" -v b="$3" '{ s = $0; o = ""; while ((i = index(s, a)) > 0) { o = o substr(s, 1, i - 1) b; s = substr(s, i + length(a)) } print o s }' \
    "$1" > "$1.put" && mv "$1.put" "$1"
}
# lines <file>: its lines, CR dropped, the last one with or without a newline
lines() { [ -f "$1" ] || return 0; tr -d '\r' < "$1" | awk '{ print }'; }

# run <dir> <stdin> <out dir> <env file or empty> <args...>: the C# in <dir>, its streams and exit code into <out dir>
run() {
  local dir="$1" in="$2" o="$3" envf="$4"; shift 4
  local -a sets unsets; sets=(CI=1 "BAYAN_CACHE=$w/cache"); unsets=(-u NO_COLOR -u FORCE_COLOR -u COLORTERM -u BAYAN_THEME -u COLORFGBG)
  if [ -n "$envf" ]; then
    while IFS= read -r l; do
      [ -n "$l" ] || continue
      case "$l" in (*=*) sets+=("$l") ;; (*) unsets+=(-u "$l") ;; esac
    done < "$envf"
  fi
  mkdir -p "$o"
  (cd "$dir" && env ${unsets[@]+"${unsets[@]}"} "${sets[@]}" "$cs" "$@" < "$in" > "$o/stdout" 2> "$o/stderr")
  echo $? > "$o/exitcode"
}

# check <produced file> <tree path> <case key...>: one compared file
check() {
  local got="$1" p="$2"; shift 2
  grep -qxF "$p" "$w/frozen" || return 0
  local k; for k in "$@"; do grep -qxF "$k" "$w/divkeys" && { ndiv=$((ndiv + 1)); return 0; }; done
  n=$((n + 1))
  if [ ! -f "$got" ]; then echo "replay: missing from the replay: $p"; bad=$((bad + 1)); return 0; fi
  if [ ! -f "$p" ]; then echo "replay: frozen file not in the tree: $p"; bad=$((bad + 1)); return 0; fi
  cmp -s "$got" "$p" && return 0
  echo "replay: differs from the frozen compiler: $p (first difference: $(cmp "$got" "$p" 2>&1 | sed 's/.*differ: //; s/^cmp: //'))"
  bad=$((bad + 1))
}

# a class case: <kind>/<Class>/<case>
replay_case() {
  local kc="$1" route="$2" d="$cases/$1" kind="${1%%/*}" s o args word=""
  local cls="${kc#*/}"; cls="${cls%%/*}"; local name="${kc##*/}"; local base="${name%-[0-9]*}"
  s="$w/s/$(echo "$kc" | tr / _)"; o="$w/o/$kc"; rm -rf "$s"; mkdir -p "$s/r" "$o"
  lines "$d/args" > "$o/args"; [ ! -f "$d/compare" ] || word="$(lines "$d/compare" | head -n 1)"
  local in=/dev/null envf="" target="" at="$root/$d"
  if [ "$route" = scratch ]; then
    put "$o/args" "<repo>" "$s/r"
    target="$(awk -v p="$s/r/" "index(\$0, p) == 1 { print; exit }" "$o/args")"; [ -n "$target" ] || target="$s/r/input.byn"
    mkdir -p "${target%/*}"
    if [ -f "$d/env" ]; then lines "$d/env" > "$o/env"; put "$o/env" "<repo>" "$s/r"; envf="$o/env"
      sed -n "s/^PATH=//p" "$o/env" | tr : "\n" | awk -v p="$s/r/" "index(\$0, p) == 1" | while IFS= read -r p; do mkdir -p "$p"; done; fi
    if [ -f "$d/stdin" ]; then lines "$d/stdin" > "$o/stdin"; put "$o/stdin" "<repo>" "$s/r"; in="$o/stdin"; fi
    at="$s/r"
  fi
  if [ "$route" = case ]; then :
  elif [ -f "$d/input.byn" ]; then cp "$d/input.byn" "$target"
  elif [ -d "$d/input" ]; then cp -R "$d/input/." "${target%/*}/"
  elif [ -f "$d/input.tsv" ]; then
    [ "$(lines "$d/input.tsv" | grep -c .)" = 1 ] && lines "$d/input.tsv" | grep -q "${tab}file:" ||
      { echo "replay: $kc: input.tsv holds more than one file, not placed by the replay"; bad=$((bad + 1)); return 0; }
    cp "$cases/inputs/files/$(lines "$d/input.tsv" | sed 's/.*file:\([0-9a-f]*\).*/\1/')" "$target"
  fi
  local -a argv; argv=(); while IFS= read -r a; do argv+=("$a"); done < "$o/args"
  run "$at" "$in" "$o" "$envf" ${argv[@]+"${argv[@]}"}
  local f
  for f in stdout stderr; do
    if [ "$route" = scratch ]; then put "$o/$f" "$s/r" "<repo>"; else put "$o/$f" "$at/" ""; fi
    if [ "$word" = seconds-masked ]; then sed -E 's/ in [0-9]+\.[0-9]{2}s/ in masked/g' "$o/$f" > "$o/$f.m" && mv "$o/$f.m" "$o/$f"; fi
  done
  [ "$kind" != emit-c ] || mv "$o/stdout" "$o/c"
  for f in "$d"/expected.*; do
    [ -f "$f" ] || continue
    check "$o/${f##*/expected.}" "$f" "$kc" "$cls.$name" "$cls.$base"
  done
  rm -rf "$s"
}

# a flat input: <kind> <kind>/<rel path>
replay_flat() {
  local kind="$1" name="$2" file="${2##*/}" ending
  local o="$w/o/$name"; local dir="$cases/${name%/*}"
  case "$kind" in
    (parse) ending=ast; run "$dir" /dev/null "$o" "" parse --ast "$file" ;;
    (typed) ending=types; run "$dir" /dev/null "$o" "" types --package . "$file" ;;
    (*) echo "replay: $kind has no flat route"; bad=$((bad + 1)); return 0 ;;
  esac
  local stem="${name%.byn}"; local key="$stem"; [ "$file" != main.byn ] || key="${name%/main.byn}"
  check "$o/stdout" "$cases/$stem.$ending" "$key"
  local ex="$cases/emit/exit/expected.$kind.exitcode"
  if grep -qxF "$ex" "$w/frozen" && grep -q "  $name\$" "$ex"; then
    grep -qxF "$key" "$w/divkeys" && { ndiv=$((ndiv + 1)); return 0; }
    n=$((n + 1))
    grep -qxF "$(cat "$o/exitcode")  $name" "$ex" ||
      { echo "replay: differs from the frozen compiler: $ex (the line of $name: exit $(cat "$o/exitcode"))"; bad=$((bad + 1)); }
  fi
}

while IFS= read -r u; do
  [ -n "$u" ] || continue
  case "$u" in
    (*" "*) replay_flat "${u%% *}" "${u#* }" ;;
    (*)
      route="$(awk -F'\t' -v u="$u" '$1 == u { print $2 }' "$w/routes")"
      case "$route" in
        (case|scratch) for d in "$cases/$u"/*/; do [ -d "$d" ] || continue; d="${d%/}"; replay_case "${d#$cases/}" "$route"; done ;;
        (*) echo "replay: $u is not replayed: $(awk -F'\t' -v u="$u" '$1 == u { print $3 }' "$w/routes")"; bad=$((bad + 1)) ;;
      esac ;;
  esac
done < "$units"
echo "replay: $n files compared, $ndiv on the divergence list, $bad failed"
[ $bad = 0 ]
