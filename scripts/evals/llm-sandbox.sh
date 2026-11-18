#!/usr/bin/env bash
# Starts one process of the LLM eval scorer (spec 025, R14, R15): clean environment, output cap, and on macOS an OS sandbox.
#   llm-sandbox.sh --write <dir> [--deny-read <dir>]... [--stdin <file>] [--no-fork] [--sweep <dir>] --stdout <file> --status <file>
#                  -- <program> [args...]
# The program's standard output goes to --stdout, cut at 1 MiB. --status gets three lines: `exit: <code>`, `limit: true|false`
# (output past 1 MiB was cut) and `sandbox: sandbox-exec/2|none` (`/2` names the profile: reads denied but for the system,
# the program's directory, zig, dotnet, TMPDIR, BAYAN_CACHE and --write; no signal outside the sandbox, no mach lookup, exec
# only of the program, env, zig and under those directories). The launcher exits 0 when it ran the program, 2 on bad usage
# or a path the profile cannot hold (`"`, `\` or a newline), 3 when the sweep left a process, 143 on TERM or INT.
# --no-fork denies fork to the program on macOS. --sweep runs the program as its own process group and, when it ends or the
# launcher gets TERM or INT, kills that group, its descendants, and every process of this user whose image is under <dir>.
# The environment is an allowlist; HOME is TMPDIR when set, else the --write directory.
# Runs under bash 3.2: no associative arrays, no mapfile.
set -uo pipefail

cap=1048576
usage() { echo "usage: llm-sandbox.sh --write <dir> [--deny-read <dir>]... [--stdin <file>] [--no-fork] [--sweep <dir>] --stdout <file> --status <file> -- <program> [args...]" >&2; exit 2; }

write="" stdin="/dev/null" stdout="" status="" nofork=false sweepdir=""
deny=()
while [ $# -gt 0 ]; do
  case "$1" in
    (--write) [ $# -ge 2 ] || usage; write=$2; shift 2 ;;
    (--deny-read) [ $# -ge 2 ] || usage; deny+=("$2"); shift 2 ;;
    (--stdin) [ $# -ge 2 ] || usage; stdin=$2; shift 2 ;;
    (--stdout) [ $# -ge 2 ] || usage; stdout=$2; shift 2 ;;
    (--status) [ $# -ge 2 ] || usage; status=$2; shift 2 ;;
    (--no-fork) nofork=true; shift ;;
    (--sweep) [ $# -ge 2 ] || usage; sweepdir=$2; shift 2 ;;
    (--) shift; break ;;
    (*) usage ;;
  esac
done
[ -n "$write" ] && [ -n "$stdout" ] && [ -n "$status" ] && [ $# -gt 0 ] || usage
[ -d "$write" ] || { echo "llm-sandbox: --write is not a directory: $write" >&2; exit 2; }
[ -r "$stdin" ] || { echo "llm-sandbox: cannot read --stdin: $stdin" >&2; exit 2; }
[ -z "$sweepdir" ] || [ -d "$sweepdir" ] || { echo "llm-sandbox: --sweep is not a directory: $sweepdir" >&2; exit 2; }

name=$1; prog=$1; shift
case "$prog" in
  (*/*) ;;
  (*) prog=$(type -P -- "$prog") || { echo "llm-sandbox: program not found: $name" >&2; exit 2; } ;;
esac

# The environment: only these names, copied when set.
envargs=("HOME=${TMPDIR:-$write}")
for name in PATH TMPDIR BAYAN_CACHE BAYAN_TEST_TIMEOUT_MS NO_COLOR DOTNET_ROOT; do
  if [ -n "${!name+x}" ]; then envargs+=("$name=${!name}"); fi
done

abs() { (cd "$1" 2>/dev/null && pwd -P) || echo "$1"; }
# real <path>: the path with every symlink of its last part followed, in a directory without symlinks.
real() {
  local p=$1 l
  while [ -L "$p" ]; do
    l=$(readlink "$p")
    case "$l" in (/*) p=$l ;; (*) p=$(dirname "$p")/$l ;; esac
  done
  echo "$(abs "$(dirname "$p")")/$(basename "$p")"
}

sandbox=none
runner=(env -i "${envargs[@]}")
profile=""
if [ "$(uname -s)" = Darwin ] && [ -x /usr/bin/sandbox-exec ]; then
  sandbox=sandbox-exec/2
  progreal=$(real "$prog")
  progdir=$(dirname "$progreal")
  ziglink="" zigdir=""
  if ziglink=$(command -v zig 2>/dev/null) && [ -n "$ziglink" ]; then zigdir=$(dirname "$(real "$ziglink")"); else ziglink=""; fi
  dotnet=$(abs "${DOTNET_ROOT:-/usr/local/share/dotnet}")
  wdir=$(abs "$write")
  extra=()  # TMPDIR and BAYAN_CACHE, each when set
  if [ -n "${TMPDIR:-}" ]; then extra+=("$(abs "$TMPDIR")"); fi
  if [ -n "${BAYAN_CACHE:-}" ]; then extra+=("$(abs "$BAYAN_CACHE")"); fi
  denyabs=()
  for d in ${deny[@]+"${deny[@]}"}; do denyabs+=("$(abs "$d")"); done
  # A path the profile cannot hold is refused, never escaped: SBPL would end the string at `"` or take `\` as an escape.
  nl='
'
  for p in "$progreal" "$progdir" "$ziglink" "$zigdir" "$dotnet" "$wdir" ${extra[@]+"${extra[@]}"} ${denyabs[@]+"${denyabs[@]}"}; do
    case "$p" in
      (*'"'*|*'\'*|*"$nl"*) echo "llm-sandbox: a path holds \", \\ or a newline, which the sandbox profile cannot hold: $p" >&2; exit 2 ;;
    esac
  done
  work=$(mktemp -d "${TMPDIR:-/tmp}/llm-sandbox.XXXXXX") || exit 2
  trap 'rm -rf "$work"' EXIT
  profile=$work/profile.sb
  # SBPL takes the last rule that matches.
  {
    echo '(version 1)'
    echo '(allow default)'
    echo '(deny network*)'
    echo '(deny file-read*)'
    echo '(allow file-read-metadata)'
    echo '(allow file-read* (literal "/") (subpath "/usr") (subpath "/System") (subpath "/dev"))'
    echo "(allow file-read* (subpath \"$progdir\"))"
    if [ -n "$ziglink" ]; then echo "(allow file-read* (literal \"$ziglink\") (subpath \"$zigdir\"))"; fi
    echo "(allow file-read* (subpath \"$dotnet\"))"
    for d in ${extra[@]+"${extra[@]}"}; do echo "(allow file-read* (subpath \"$d\"))"; done
    for d in ${denyabs[@]+"${denyabs[@]}"}; do echo "(deny file-read* (subpath \"$d\"))"; done
    echo "(allow file-read* (subpath \"$wdir\"))"
    echo '(deny file-write*)'
    echo '(allow file-write* (literal "/dev/null") (literal "/dev/dtracehelper"))'
    echo "(allow file-write* (subpath \"$wdir\"))"
    echo '(deny signal)'
    echo '(allow signal (target same-sandbox))'
    echo '(deny mach-lookup)'
    echo '(deny process-exec*)'
    printf '(allow process-exec* (literal "/usr/bin/env") (literal "%s")' "$progreal"
    if [ -n "$ziglink" ]; then printf ' (literal "%s") (subpath "%s")' "$ziglink" "$zigdir"; fi
    printf ' (subpath "%s")' "$wdir" ${extra[@]+"${extra[@]}"}
    echo ')'
    if $nofork; then echo '(deny process-fork)'; fi
  } > "$profile"
  runner=(/usr/bin/sandbox-exec -f "$profile" env -i "${envargs[@]}")
fi

# The exit code goes through a file because the pipe to head hides it. head stops at one byte past the cap, so a program that
# prints without end gets SIGPIPE.
codefile=$(mktemp "${TMPDIR:-/tmp}/llm-sandbox-code.XXXXXX") || exit 2
if [ -z "$sweepdir" ]; then
  { "${runner[@]}" "$prog" "$@" < "$stdin"; echo $? > "$codefile"; } | head -c $((cap + 1)) > "$stdout"
else
  # The pipeline is a job of its own (set -m gives it its own process group), so a TERM from the scorer's time limit reaches
  # only the launcher, whose trap sweeps.
  sweepabs=$(abs "$sweepdir")
  # image <pid list file>: writes the pids of this user's processes whose image is under the sweep directory.
  image() {
    if [ "$(uname -s)" = Darwin ]; then
      PATH=$PATH:/usr/sbin lsof -a -d txt -u "$(id -u)" -Fpn 2>/dev/null \
        | awk -v a="$sweepabs/" -v b="$sweepdir/" '/^p/ { pid = substr($0, 2) } /^n/ { n = substr($0, 2); if (index(n, a) == 1 || index(n, b) == 1) print pid }' \
        | sort -u
    else
      local e t
      for e in /proc/[0-9]*/exe; do
        t=$(readlink "$e" 2>/dev/null) || continue
        case "$t" in ("$sweepabs"/*|"$sweepdir"/*) e=${e#/proc/}; echo "${e%/exe}" ;; esac
      done
    fi
  }
  # sweep: kills the job's group, its descendants, then whatever runs from under the sweep directory; 1 when a process is left.
  sweep() {
    local snap own i left
    snap=$(ps -axo pid=,ppid= | awk -v root=$$ '{ kids[$2] = kids[$2] " " $1 } END { q = root; while (q != "") { split(q, h, " "); q = ""; for (k in h) { n = split(kids[h[k]], c, " "); for (j = 1; j <= n; j++) { print c[j]; q = q " " c[j] } } } }')
    own=$(ps -o pgid= -p $$ | tr -d ' ')
    if [ -n "$pgid" ] && [ "$pgid" != "$own" ] && [ "$pgid" != 0 ] && [ "$pgid" != 1 ]; then kill -KILL -- "-$pgid" 2>/dev/null; fi
    for i in $snap; do [ "$i" != $$ ] && kill -KILL "$i" 2>/dev/null; done
    for i in 1 2 3; do
      left=$(image)
      [ -n "$left" ] || return 0
      for p in $left; do [ "$p" != $$ ] && kill -KILL "$p" 2>/dev/null; done
      sleep 0.1
    done
    [ -z "$(image)" ]
  }
  pgid=""
  trap 'sweep; rm -f "$codefile"; exit 143' TERM INT
  set -m
  { "${runner[@]}" "$prog" "$@" < "$stdin"; echo $? > "$codefile"; } | head -c $((cap + 1)) > "$stdout" &
  pgid=$(jobs -p | head -1)
  wait
  set +m
  sweep || { rm -f "$codefile"; echo "llm-sandbox: a process under $sweepdir outlived the sweep" >&2; exit 3; }
  trap - TERM INT
fi
code=$(cat "$codefile"); rm -f "$codefile"

limit=false
if [ "$(wc -c < "$stdout" | tr -d ' ')" -gt "$cap" ]; then
  limit=true
  head -c "$cap" "$stdout" > "$stdout.cut" && mv "$stdout.cut" "$stdout"
fi
printf 'exit: %s\nlimit: %s\nsandbox: %s\n' "$code" "$limit" "$sandbox" > "$status"
