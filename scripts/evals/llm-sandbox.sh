#!/usr/bin/env bash
# Starts one process of the LLM eval scorer (spec 025, R14, R15): clean environment, output cap, and on macOS an OS sandbox.
#   llm-sandbox.sh --write <dir> [--deny-read <dir>]... [--stdin <file>] --stdout <file> --status <file> -- <program> [args...]
# The program's standard output goes to --stdout, cut at 1 MiB. --status gets three lines: `exit: <code>`, `limit: true|false`
# (output past 1 MiB was cut) and `sandbox: sandbox-exec|none`. The launcher exits 0 when it ran the program, 2 on bad usage.
# The environment is an allowlist; HOME is TMPDIR when set, else the --write directory.
# Runs under bash 3.2: no associative arrays, no mapfile.
set -uo pipefail

cap=1048576
usage() { echo "usage: llm-sandbox.sh --write <dir> [--deny-read <dir>]... [--stdin <file>] --stdout <file> --status <file> -- <program> [args...]" >&2; exit 2; }

write="" stdin="/dev/null" stdout="" status=""
deny=()
while [ $# -gt 0 ]; do
  case "$1" in
    (--write) [ $# -ge 2 ] || usage; write=$2; shift 2 ;;
    (--deny-read) [ $# -ge 2 ] || usage; deny+=("$2"); shift 2 ;;
    (--stdin) [ $# -ge 2 ] || usage; stdin=$2; shift 2 ;;
    (--stdout) [ $# -ge 2 ] || usage; stdout=$2; shift 2 ;;
    (--status) [ $# -ge 2 ] || usage; status=$2; shift 2 ;;
    (--) shift; break ;;
    (*) usage ;;
  esac
done
[ -n "$write" ] && [ -n "$stdout" ] && [ -n "$status" ] && [ $# -gt 0 ] || usage
[ -d "$write" ] || { echo "llm-sandbox: --write is not a directory: $write" >&2; exit 2; }
[ -r "$stdin" ] || { echo "llm-sandbox: cannot read --stdin: $stdin" >&2; exit 2; }

prog=$1; shift
case "$prog" in
  (*/*) ;;
  (*) prog=$(command -v -- "$prog") || { echo "llm-sandbox: program not found: $1" >&2; exit 2; } ;;
esac

# The environment: only these names, copied when set.
envargs=("HOME=${TMPDIR:-$write}")
for name in PATH TMPDIR BAYAN_CACHE BAYAN_TEST_TIMEOUT_MS NO_COLOR DOTNET_ROOT; do
  if [ -n "${!name+x}" ]; then envargs+=("$name=${!name}"); fi
done

sandbox=none
runner=(env -i "${envargs[@]}")
profile=""
if [ "$(uname -s)" = Darwin ] && [ -x /usr/bin/sandbox-exec ]; then
  sandbox=sandbox-exec
  work=$(mktemp -d "${TMPDIR:-/tmp}/llm-sandbox.XXXXXX") || exit 2
  trap 'rm -rf "$work"' EXIT
  profile=$work/profile.sb
  abs() { (cd "$1" 2>/dev/null && pwd -P) || echo "$1"; }
  {
    echo '(version 1)'
    echo '(allow default)'
    echo '(deny network*)'
    for d in ${deny[@]+"${deny[@]}"}; do echo "(deny file-read* (subpath \"$(abs "$d")\"))"; done
    echo "(allow file-read* (subpath \"$(abs "$write")\"))"
    echo '(deny file-write*)'
    echo '(allow file-write* (literal "/dev/null") (literal "/dev/dtracehelper"))'
    echo "(allow file-write* (subpath \"$(abs "$write")\"))"
  } > "$profile"
  runner=(/usr/bin/sandbox-exec -f "$profile" env -i "${envargs[@]}")
fi

# The exit code goes through a file because the pipe to head hides it. head stops at one byte past the cap, so a program that
# prints without end gets SIGPIPE.
codefile=$(mktemp "${TMPDIR:-/tmp}/llm-sandbox-code.XXXXXX") || exit 2
{ "${runner[@]}" "$prog" "$@" < "$stdin"; echo $? > "$codefile"; } | head -c $((cap + 1)) > "$stdout"
code=$(cat "$codefile"); rm -f "$codefile"

limit=false
if [ "$(wc -c < "$stdout" | tr -d ' ')" -gt "$cap" ]; then
  limit=true
  head -c "$cap" "$stdout" > "$stdout.cut" && mv "$stdout.cut" "$stdout"
fi
printf 'exit: %s\nlimit: %s\nsandbox: %s\n' "$code" "$limit" "$sandbox" > "$status"
