#!/usr/bin/env bash
# Parity baselines for spec 015: runs a tool over its recorded cases and compares exit code, stdout, stderr and the
# work directory afterwards with what the original (Python/Deno/PowerShell) script produced when the case was recorded.
# Usage: scripts/parity/run.sh <tool> [--impl '<command>'] [--record] [case...]
#   <tool>     a directory under tests/parity/
#   --impl     the command under test (default: the tool's `impl` file: the original script, or for the cli-* tools the
#              stage-1 driver tmp/bootstrap-check/bayan that scripts/ci/bootstrap-check.sh leaves); a port passes its own,
#              e.g. --impl "$(scripts/pinned-bayan.sh) run tools/mutation-exempt.byn"
#   --record   write expected/ from this run instead of comparing (only ever with the original script); refused (exit 2)
#              for a cli-* tool, whose expected files are frozen from the C# CLI at v0.3.2
# A case is tests/parity/<tool>/<case>/ holding:
#   args       arguments, one per line (optional); `$ROOT` and `$WORK` in a line become the repo root and the work directory
#   in/        inputs; copied to a scratch directory that becomes the working directory (files in in/bin/ made executable)
#   stdin      bytes fed on stdin (optional)
#   env        KEY=VALUE lines added to the environment (optional); `$ROOT`, `$WORK` and `$PATH` expand, so
#              PATH=$WORK/bin:$PATH puts a stub (say a `git` printing a recorded diff) first
#   setup      a bash script run in the work directory before the tool (optional; e.g. builds a git repo)
#   steps      several commands in place of `args` (optional, spec 019 T25), one per line, run in order in the work directory:
#              a line `$ <command>` runs `bash -c <command>` with $BAYAN set to the command under test (word-split, so
#              `$BAYAN build x` runs it); any other line runs the command under test with the line's tab-separated fields as
#              arguments. Each step's stdout and stderr are appended under a line `== <n>` (stdout: `== <n> exit <code>`);
#              exit is the last step's
#   masks      mask names, one per line, applied to stdout and stderr before comparing or recording (optional, spec 019 T25):
#                seconds       a time `1.23s` (digits, a point, digits, then `s`) becomes `#s`
#                staging       a cache staging-key name, 16 hex digits, `-`, 32 hex digits, becomes `<staging>`
#                dotnet-error  on a line `bayan: cannot …`, the text after its `(<path>): ` or `` `<name>`: `` becomes `<error>`
#                              (the .NET exception message the C# CLI appends)
#   nofiles    an empty file: the work directory is not compared (optional; a case that builds leaves binaries and a cache)
#   expected/  exit, stdout, stderr, and files/ (the work directory's files after the run, setup's .git excluded)
# Prints `PASS <tool> <n> cases` or one `FAIL <tool>/<case>: …` line per mismatch and exits 1.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tool="${1:?usage: run.sh <tool> [--impl cmd] [--record] [case...]}"; shift
dir="$root/tests/parity/$tool"
case "$tool" in ""|.|..|*/*) echo "parity: bad tool name: $tool" >&2; exit 2 ;; esac
[ -d "$dir" ] || { echo "parity: no cases at tests/parity/$tool" >&2; exit 2; }
impl=""; record=0; cases=()
while [ $# -gt 0 ]; do
  case "$1" in
    --impl) impl="$2"; shift 2 ;;
    --record) record=1; shift ;;
    *) cases+=("$1"); shift ;;
  esac
done
case "$tool" in cli-*) [ $record = 0 ] || { echo "parity: the expected files of the cli-* tools are frozen from the C# CLI at v0.3.2 and are not re-recorded" >&2; exit 2; } ;; esac
[ -n "$impl" ] || impl="$(sed "s|\$ROOT|$root|g" "$dir/impl")"
[ ${#cases[@]} -gt 0 ] || for c in "$dir"/*/; do cases+=("$(basename "$c")"); done

# Files only: git keeps no empty directories, so they are not part of a case (a case that leaves nothing has no
# expected/files in a checkout).
# Names compare in NFC: macOS tar writes é decomposed, so the copied tree would differ from the checkout by bytes alone.
list_files() { [ -d "$1" ] && (cd "$1" && find . \( -type f -o -type l \) | perl -CS -MUnicode::Normalize -pe '$_ = NFC($_)' | LC_ALL=C sort); return 0; }
same_files() {
  diff <(list_files "$1") <(list_files "$2") || return 1
  local f; while IFS= read -r f; do cmp "$1/$f" "$2/$f" || return 1; done < <(list_files "$2")
}

scratch="$root/tmp/parity/$tool"
bad=0; n=0
for c in "${cases[@]}"; do
  case "$c" in ""|.|..|*/*) echo "FAIL $tool/$c: bad case name"; bad=1; continue ;; esac
  case_dir="$dir/$c"; [ -d "$case_dir" ] || { echo "FAIL $tool/$c: no such case"; bad=1; continue; }
  n=$((n+1))
  work="$scratch/$c/work"; got="$scratch/$c/got"
  rm -rf "${scratch:?}/$c"; mkdir -p "$work" "$got"
  [ -d "$case_dir/in" ] && cp -R "$case_dir/in/." "$work/"
  [ -d "$work/bin" ] && chmod +x "$work/bin"/*  # stubs, whatever mode the checkout gave them
  argv=()
  if [ -f "$case_dir/args" ]; then while IFS= read -r a || [ -n "$a" ]; do a="${a//\$ROOT/$root}"; argv+=("${a//\$WORK/$work}"); done < "$case_dir/args"; fi
  envv=()
  if [ -f "$case_dir/env" ]; then while IFS= read -r e || [ -n "$e" ]; do
    [ -n "$e" ] || continue; e="${e//\$ROOT/$root}"; e="${e//\$WORK/$work}"; envv+=("${e//\$PATH/$PATH}")
  done < "$case_dir/env"; fi
  stdin=/dev/null; [ -f "$case_dir/stdin" ] && stdin="$case_dir/stdin"
  if [ -f "$case_dir/setup" ] && ! (cd "$work" && env ${envv[@]+"${envv[@]}"} bash "$case_dir/setup") > "$got/setup.log" 2>&1; then
    echo "FAIL $tool/$c: setup failed: $(tail -1 "$got/setup.log")"; bad=1; continue
  fi
  set +e
  if [ -f "$case_dir/steps" ]; then
    : > "$got/stdout"; : > "$got/stderr"; i=0; rc=0
    while IFS= read -r s || [ -n "$s" ]; do
      [ -n "$s" ] || continue
      i=$((i+1)); s="${s//\$ROOT/$root}"; s="${s//\$WORK/$work}"
      if [ "${s#\$ }" != "$s" ]; then
        (cd "$work" && env ${envv[@]+"${envv[@]}"} BAYAN="$impl" bash -c "${s#\$ }" < "$stdin" > "$got/step.out" 2> "$got/step.err")
      else
        IFS="$(printf '\t')" read -r -a sargv <<< "$s"
        # shellcheck disable=SC2086  # impl is a command line
        (cd "$work" && env ${envv[@]+"${envv[@]}"} $impl "${sargv[@]}" < "$stdin" > "$got/step.out" 2> "$got/step.err")
      fi
      rc=$?
      { echo "== $i exit $rc"; cat "$got/step.out"; } >> "$got/stdout"; { echo "== $i"; cat "$got/step.err"; } >> "$got/stderr"
    done < "$case_dir/steps"
    rm -f "$got/step.out" "$got/step.err"; echo $rc > "$got/exit"
  else
    # shellcheck disable=SC2086  # impl is a command line
    (cd "$work" && env ${envv[@]+"${envv[@]}"} $impl ${argv[@]+"${argv[@]}"} < "$stdin" > "$got/stdout" 2> "$got/stderr")
    echo $? > "$got/exit"
  fi
  set -e
  mkdir -p "$got/files"
  [ -f "$case_dir/nofiles" ] || (cd "$work" && tar --exclude ./.git -cf - .) | (cd "$got/files" && tar -xf -)
  # Scratch paths differ per checkout: the work and repo paths read as $WORK and $ROOT.
  # Literal match, and only a whole path: a root of /w must not rewrite /wave-brief.
  for f in stdout stderr; do W="$work" R="$root" perl -pi -e 's/\Q$ENV{W}\E(?![\w.-])/\$WORK/g; s/\Q$ENV{R}\E(?![\w.-])/\$ROOT/g' "$got/$f"; done
  # A tool that writes an absolute path into a file: the same rewrite over the files it left.
  find "$got/files" -type f -exec env W="$work" R="$root" perl -pi -e 's/\Q$ENV{W}\E(?![\w.-])/\$WORK/g; s/\Q$ENV{R}\E(?![\w.-])/\$ROOT/g' {} +
  # Python 3.11+ adds traceback caret lines (`  ^^^^`, `~~~^^`) that older Pythons do not print: drop them.
  perl -ni -e 'print unless /^\s*[~^]+\s*$/' "$got/stderr"
  if [ -f "$case_dir/masks" ]; then while IFS= read -r m || [ -n "$m" ]; do
    case "$m" in
      "") ;;
      seconds) perl -pi -e 's/(?<![\w.])\d+\.\d+s(?!\w)/#s/g' "$got/stdout" "$got/stderr" ;;
      staging) perl -pi -e 's/(?<![0-9a-f])[0-9a-f]{16}-[0-9a-f]{32}(?![0-9a-f])/<staging>/g' "$got/stdout" "$got/stderr" ;;
      dotnet-error) perl -pi -e 's/^(bayan: cannot [^(`\n]*(?:\([^)\n]*\)|`[^`\n]*`)): .*$/$1: <error>/' "$got/stdout" "$got/stderr" ;;
      *) echo "FAIL $tool/$c: unknown mask '$m'"; bad=1 ;;
    esac
  done < "$case_dir/masks"; fi
  if [ $record = 1 ]; then
    rm -rf "$case_dir/expected"; mkdir -p "$case_dir/expected"
    cp "$got/exit" "$got/stdout" "$got/stderr" "$case_dir/expected/"; cp -R "$got/files" "$case_dir/expected/files"
    continue
  fi
  [ -d "$case_dir/expected" ] || { echo "FAIL $tool/$c: no expected/ (record it with --record)"; bad=1; continue; }
  # A recorded Python traceback is not a contract: its frames move with every edit and a port cannot print one. Such a
  # case's stderr passes when it holds the exception's message (the last line, after `Name: `); exit and stdout stay exact.
  if [ "$(head -1 "$case_dir/expected/stderr")" = "Traceback (most recent call last):" ]; then
    msg="$(tail -1 "$case_dir/expected/stderr")"; msg="${msg#*: }"
    grep -qF -- "$msg" "$got/stderr" || { echo "FAIL $tool/$c: stderr differs: no \`$msg\` in: $(head -2 "$got/stderr" | tr '\n' ' ' | cut -c1-200)"; bad=1; }
    cp "$case_dir/expected/stderr" "$got/stderr.checked"
  fi
  for f in exit stdout stderr; do
    [ $f = stderr ] && [ -f "$got/stderr.checked" ] && continue
    cmp -s "$case_dir/expected/$f" "$got/$f" || { echo "FAIL $tool/$c: $f differs: $(diff "$case_dir/expected/$f" "$got/$f" | sed -n 2,3p | tr '\n' ' ' | cut -c1-300)"; bad=1; }
  done
  same_files "$case_dir/expected/files" "$got/files" > "$got/files.diff" 2>&1 \
    || { echo "FAIL $tool/$c: files differ: $(head -3 "$got/files.diff" | tr '\n' ' ' | cut -c1-300)"; bad=1; }
done
[ $record = 1 ] && { echo "RECORDED $tool $n cases"; exit $bad; }
[ $bad = 0 ] && echo "PASS $tool $n cases"
exit $bad
