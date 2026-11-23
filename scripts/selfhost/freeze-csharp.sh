#!/usr/bin/env bash
# Spec 019 T64a: freezes what the redrafted L017, L022 and L024 drop, from the frozen C# compiler, before T67 removes it.
#   bash scripts/selfhost/freeze-csharp.sh <C# bayan> <cases dir> <out dir> [<pick file>]
# <C# bayan> is the C# CLI built from csharp/ (its apphost, e.g. tmp/t64a/cs/bayan; DOTNET_ROOT set). <cases dir> is tests/cases.
# The inputs of a kind are its top-level *.byn files and every main.byn below it (C# Golden.Cases), named `<kind>/<rel path>`. With
# <pick file> (one name per line) only the named inputs run: a sample, written to <out dir> as partial files.
# Writes, under <out dir>, each file sorted by name (LC_ALL=C), LF, two spaces between the columns:
#   emit/modes/expected.<mode>.sha256    one per BuildMode (debug, safe, fast; Toolchain.cs:11), a line per run/ input:
#                                        `<sha256 of the emitted C>  run/<input>` (the format of emit/run-c.sha256), or
#                                        `exit:<n>  run/<input>` when the C# exits n != 0; the C is
#                                        `build --emit-c --mode <mode> --package . <file>` run in the input's directory
#   emit/exit/expected.<kind>.exitcode   kind parse, typed, diag: `<exit code>  <kind>/<input>`, the argv of
#                                        SelfhostDriverGoldenTests (parse `parse --ast`, typed `types --package .`, diag `check --all`)
# Every run is in the input's directory with relative paths, CI=1 and stdin empty, so no output holds the host path. Then, unless a pick
# file is given, each line of <cases dir>/emit/run-c.sha256 is compared with the line of the mode its input's `// mode:` names (safe
# when none, MutantSchemataTests.ModeOf); with one, only the picked inputs' lines. A differing or missing line is printed as
# `run-c mismatch: <line>`. FREEZE.tsv rows: `bash scripts/ci/freeze-check.sh --write` after a full run into tests/cases.
# Prints the counts and the run-c result; exit 0 when every compared run-c.sha256 line is reproduced, 1 when one is not, 2 on usage.
set -euo pipefail
[ $# = 3 ] || [ $# = 4 ] || { echo "usage: freeze-csharp.sh <C# bayan> <cases dir> <out dir> [<pick file>]" >&2; exit 2; }
cs="$1"; cases="${2%/}"; out="${3%/}"; pick="${4:-}"
case "$cs" in (/*) ;; (*) cs="$PWD/$cs" ;; esac
[ -x "$cs" ] || { echo "freeze-csharp: no executable $cs" >&2; exit 2; }
[ -d "$cases/run" ] || { echo "freeze-csharp: no $cases/run" >&2; exit 2; }
[ -z "$pick" ] || [ -f "$pick" ] || { echo "freeze-csharp: no pick file $pick" >&2; exit 2; }
cases="$(cd "$cases" && pwd)"
if command -v sha256sum > /dev/null 2>&1; then sum="sha256sum"; else sum="shasum -a 256"; fi
work="$(mktemp -d "${TMPDIR:-/tmp}/freeze-csharp.XXXXXX")"
trap 'rm -rf "$work"' EXIT
export CI=1

# inputs <kind>: the kind's input names, sorted, restricted to the pick file when there is one
inputs() {
  (cd "$cases" && { find "$1" -mindepth 1 -maxdepth 1 -type f -name '*.byn'; find "$1" -mindepth 2 -type f -name main.byn; }) |
    LC_ALL=C sort > "$work/all"
  if [ -n "$pick" ]; then LC_ALL=C sort -u "$pick" | LC_ALL=C comm -12 "$work/all" -; else cat "$work/all"; fi
}

# csharp <name> <args...>: runs the C# in the input's directory; stdout to $work/stdout, sets $rc
csharp() {
  local dir="$cases/${1%/*}"; shift
  rc=0; (cd "$dir" && "$cs" "$@" < /dev/null > "$work/stdout" 2> /dev/null) || rc=$?
}

mkdir -p "$out/emit/modes" "$out/emit/exit"
inputs run > "$work/run"
for mode in debug safe fast; do
  : > "$work/lines"
  while IFS= read -r name; do
    csharp "$name" build --emit-c --mode "$mode" --package . "${name##*/}"
    if [ $rc = 0 ]; then
      printf '%s  %s\n' "$($sum < "$work/stdout" | cut -c1-64)" "$name" >> "$work/lines"
    else
      printf 'exit:%s  %s\n' "$rc" "$name" >> "$work/lines"
    fi
  done < "$work/run"
  cp "$work/lines" "$out/emit/modes/expected.$mode.sha256"
done
for kind in parse typed diag; do
  : > "$work/lines"
  while IFS= read -r name; do
    file="${name##*/}"
    case "$name" in
      (parse/*) csharp "$name" parse --ast "$file" ;;
      (typed/*) csharp "$name" types --package . "$file" ;;
      (*/*/*) if [ -d "$cases/${name%/*}/src" ]; then csharp "$name" check --all .; else csharp "$name" check --all --package . "$file"; fi ;;
      (*) csharp "$name" check --all --package . "$file" ;;
    esac
    printf '%s  %s\n' "$rc" "$name" >> "$work/lines"
  done < <(inputs "$kind")
  cp "$work/lines" "$out/emit/exit/expected.$kind.exitcode"
  echo "freeze-csharp: $kind $(wc -l < "$work/lines" | tr -d ' ') exit codes"
done
echo "freeze-csharp: run $(wc -l < "$work/run" | tr -d ' ') inputs x 3 modes, $(grep -c '^exit:' "$out/emit/modes/expected.safe.sha256" || true) rejected in safe"

# run-c.sha256: each line against the mode its input names
seen=0; bad=0
while IFS= read -r line; do
  name="${line#*  }"
  [ -z "$pick" ] || grep -qxF "$name" "$work/run" || continue
  mode=safe; first="$(head -n 1 "$cases/$name" | tr -d '\r')"
  case "$first" in ("// mode: "*) m="${first#// mode: }"; m="${m%"${m##*[! ]}"}"; case "$m" in (debug|safe|fast) mode="$m" ;; esac ;; esac
  seen=$((seen + 1))
  grep -qxF "$line" "$out/emit/modes/expected.$mode.sha256" && continue
  got="$(awk -v n="$name" 'substr($0, index($0, "  ") + 2) == n { print $1 }' "$out/emit/modes/expected.$mode.sha256")"
  echo "run-c mismatch: $line ($mode: ${got:-no line})"; bad=$((bad + 1))
done < "$cases/emit/run-c.sha256"
echo "freeze-csharp: run-c.sha256 $((seen - bad)) of $seen lines reproduced"
[ $bad = 0 ]
