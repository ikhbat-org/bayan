#!/usr/bin/env bash
# Starts one process of the LLM eval scorer (spec 025, R14, R15): clean environment, output cap, and on macOS an OS sandbox.
#   llm-sandbox.sh --write <dir> [--deny-read <dir>]... [--stdin <file>] [--no-fork] [--prime] [--sweep <dir>]... [--tools <dir>]
#                  --stdout <file> --status <file> -- <program> [args...]
# The program's standard output goes to --stdout, cut at 1 MiB. --status gets three lines: `exit: <code>`, `limit: true|false`
# (output past 1 MiB was cut) and `sandbox: sandbox-exec/3|none` (`/3` names the profile: reads denied but for the system,
# the program's directory, dotnet, ZIG_LIB_DIR, TMPDIR, BAYAN_CACHE, the --sweep and --tools directories and --write; no
# write but to --write, and none to --tools; no signal outside the sandbox, no mach lookup; exec only of env, the --prime
# helper, and anything under --write, TMPDIR, BAYAN_CACHE and the --sweep and --tools directories, and of the program
# itself only when there is no --sweep or --tools). Zig is started from a copy under one of them, ZIG_LIB_DIR naming its lib.
# The launcher exits 0 when it ran the program, 2 on bad usage or a path the profile cannot hold (`"`, `\` or a newline), 3
# when the sweep left a process, 4 when --prime cannot build its helper, 143 on TERM or INT.
# --no-fork denies fork to the program on macOS. --prime does not run the program: on macOS it builds llm-prime.c with zig
# (into --tools, once, when given) and runs it under the same profile, which starts the program suspended and kills it
# before it runs an instruction, so the system's check of a new program is done before the timed run (R14); `exit:` is the
# helper's, 0 when it did so. Elsewhere --prime runs nothing and writes `exit: 0`. With --prime, --no-fork would deny the
# helper its spawn.
# --sweep (more than once) runs the program as its own process group and, when it ends or the launcher gets TERM or INT,
# kills that group, its descendants, and every process of this user whose image is under a --sweep or --tools directory.
# --tools is a directory the program may read and start files from but not write, swept as --sweep is.
# The environment is an allowlist; HOME is TMPDIR when set, else the --write directory.
# Runs under bash 3.2: no associative arrays, no mapfile.
set -uo pipefail

cap=1048576
usage() { echo "usage: llm-sandbox.sh --write <dir> [--deny-read <dir>]... [--stdin <file>] [--no-fork] [--prime] [--sweep <dir>]... [--tools <dir>] --stdout <file> --status <file> -- <program> [args...]" >&2; exit 2; }

write="" stdin="/dev/null" stdout="" status="" nofork=false prime=false tools=""
deny=() sweeps=()
while [ $# -gt 0 ]; do
  case "$1" in
    (--write) [ $# -ge 2 ] || usage; write=$2; shift 2 ;;
    (--deny-read) [ $# -ge 2 ] || usage; deny+=("$2"); shift 2 ;;
    (--stdin) [ $# -ge 2 ] || usage; stdin=$2; shift 2 ;;
    (--stdout) [ $# -ge 2 ] || usage; stdout=$2; shift 2 ;;
    (--status) [ $# -ge 2 ] || usage; status=$2; shift 2 ;;
    (--no-fork) nofork=true; shift ;;
    (--prime) prime=true; shift ;;
    (--sweep) [ $# -ge 2 ] || usage; sweeps+=("$2"); shift 2 ;;
    (--tools) [ $# -ge 2 ] || usage; tools=$2; shift 2 ;;
    (--) shift; break ;;
    (*) usage ;;
  esac
done
[ -n "$write" ] && [ -n "$stdout" ] && [ -n "$status" ] && [ $# -gt 0 ] || usage
[ -d "$write" ] || { echo "llm-sandbox: --write is not a directory: $write" >&2; exit 2; }
[ -r "$stdin" ] || { echo "llm-sandbox: cannot read --stdin: $stdin" >&2; exit 2; }
[ -z "$tools" ] || [ -d "$tools" ] || { echo "llm-sandbox: --tools is not a directory: $tools" >&2; exit 2; }
if [ -n "$tools" ]; then sweeps+=("$tools"); fi
for d in ${sweeps[@]+"${sweeps[@]}"}; do
  [ -d "$d" ] || { echo "llm-sandbox: --sweep is not a directory: $d" >&2; exit 2; }
done

name=$1; prog=$1; shift
case "$prog" in
  (*/*) ;;
  (*) prog=$(type -P -- "$prog") || { echo "llm-sandbox: program not found: $name" >&2; exit 2; } ;;
esac

# The environment: only these names, copied when set.
envargs=("HOME=${TMPDIR:-$write}")
for name in PATH TMPDIR BAYAN_CACHE BAYAN_TEST_TIMEOUT_MS NO_COLOR DOTNET_ROOT ZIG_LIB_DIR; do
  if [ -n "${!name+x}" ]; then envargs+=("$name=${!name}"); fi
done

nl='
'
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
  sandbox=sandbox-exec/3
  progreal=$(real "$prog")
  progdir=$(dirname "$progreal")
  zlib=""
  if [ -n "${ZIG_LIB_DIR:-}" ]; then zlib=$(abs "$ZIG_LIB_DIR"); fi
  dotnet=$(abs "${DOTNET_ROOT:-/usr/local/share/dotnet}")
  work=$(mktemp -d "${TMPDIR:-/tmp}/llm-sandbox.XXXXXX") || exit 2
  trap 'rm -rf "$work"' EXIT
  helper=""  # the prime helper, built with --prime here, or once in --tools when given
  if $prime; then helper=$(abs "${tools:-$work}")/llm-prime; fi
  wdir=$(abs "$write")
  extra=()  # TMPDIR and BAYAN_CACHE, each when set
  if [ -n "${TMPDIR:-}" ]; then extra+=("$(abs "$TMPDIR")"); fi
  if [ -n "${BAYAN_CACHE:-}" ]; then extra+=("$(abs "$BAYAN_CACHE")"); fi
  denyabs=()
  for d in ${deny[@]+"${deny[@]}"}; do denyabs+=("$(abs "$d")"); done
  sweepabs=()  # the --sweep and --tools directories
  for d in ${sweeps[@]+"${sweeps[@]}"}; do sweepabs+=("$(abs "$d")"); done
  toolsabs=""
  if [ -n "$tools" ]; then toolsabs=$(abs "$tools"); fi
  # A path the profile cannot hold is refused, never escaped: SBPL would end the string at `"` or take `\` as an escape.
  for p in "$progreal" "$progdir" "$helper" "$zlib" "$dotnet" "$wdir" ${extra[@]+"${extra[@]}"} ${denyabs[@]+"${denyabs[@]}"} ${sweepabs[@]+"${sweepabs[@]}"}; do
    case "$p" in
      (*'"'*|*'\'*|*"$nl"*) echo "llm-sandbox: a path holds \", \\ or a newline, which the sandbox profile cannot hold: $p" >&2; exit 2 ;;
    esac
  done
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
    if [ -n "$helper" ]; then echo "(allow file-read* (literal \"$helper\"))"; fi
    if [ -n "$zlib" ]; then echo "(allow file-read* (subpath \"$zlib\"))"; fi
    echo "(allow file-read* (subpath \"$dotnet\"))"
    for d in ${extra[@]+"${extra[@]}"} ${sweepabs[@]+"${sweepabs[@]}"}; do echo "(allow file-read* (subpath \"$d\"))"; done
    for d in ${denyabs[@]+"${denyabs[@]}"}; do echo "(deny file-read* (subpath \"$d\"))"; done
    echo "(allow file-read* (subpath \"$wdir\"))"
    echo '(deny file-write*)'
    echo '(allow file-write* (literal "/dev/null") (literal "/dev/dtracehelper"))'
    echo "(allow file-write* (subpath \"$wdir\"))"
    if [ -n "$toolsabs" ]; then echo "(deny file-write* (subpath \"$toolsabs\"))"; fi
    echo '(deny signal)'
    echo '(allow signal (target same-sandbox))'
    echo '(deny mach-lookup)'
    echo '(deny process-exec*)'
    # With a sweep, every image exec allows but env is under a directory the sweep covers, so nothing the program starts
    # outlives it; the program itself must then lie under one of them.
    printf '(allow process-exec* (literal "/usr/bin/env")'
    if [ ${#sweeps[@]} -eq 0 ]; then printf ' (literal "%s")' "$progreal"; fi
    if [ -n "$helper" ]; then printf ' (literal "%s")' "$helper"; fi
    printf ' (subpath "%s")' "$wdir" ${extra[@]+"${extra[@]}"} ${sweepabs[@]+"${sweepabs[@]}"}
    echo ')'
    if $nofork; then echo '(deny process-fork)'; fi
  } > "$profile"
  runner=(/usr/bin/sandbox-exec -f "$profile" env -i "${envargs[@]}")
  if $prime; then
    if [ ! -x "$helper" ]; then
      zig cc -o "$helper.$$" "$(dirname "$0")/llm-prime.c" >&2 && mv -f "$helper.$$" "$helper" \
        || { rm -f "$helper.$$"; echo "llm-sandbox: cannot build the prime helper with zig" >&2; exit 4; }
    fi
    set -- "$prog" "$@"
    prog=$helper
  fi
elif $prime; then
  : > "$stdout"
  printf 'exit: 0\nlimit: false\nsandbox: %s\n' "$sandbox" > "$status"
  exit 0
fi

# The exit code comes from PIPESTATUS, never a file: a file under TMPDIR or --write is one the program could rewrite. head
# stops at one byte past the cap, so a program that prints without end gets SIGPIPE.
if [ ${#sweeps[@]} -eq 0 ]; then
  "${runner[@]}" "$prog" "$@" < "$stdin" | head -c $((cap + 1)) > "$stdout"
  code=${PIPESTATUS[0]}
else
  # The pipeline is a job of its own (set -m gives it its own process group), so a TERM from the scorer's time limit reaches
  # only the launcher, whose trap sweeps.
  # Each sweep directory as given and with symlinks resolved, one per line, each ending in `/`.
  under=""
  for d in "${sweeps[@]}"; do under="$under$(abs "$d")/$nl$d/$nl"; done
  # image: writes the pids of this user's processes whose image is under a sweep directory.
  image() {
    if [ "$(uname -s)" = Darwin ]; then
      PATH=$PATH:/usr/sbin lsof -a -d txt -u "$(id -u)" -Fpn 2>/dev/null \
        | SWEEP="$under" awk 'BEGIN { k = split(ENVIRON["SWEEP"], u, "\n") } /^p/ { pid = substr($0, 2) } /^n/ { n = substr($0, 2); for (i = 1; i <= k; i++) if (u[i] != "" && index(n, u[i]) == 1) { print pid; break } }' \
        | sort -u
    else
      local e t u
      for e in /proc/[0-9]*/exe; do
        t=$(readlink "$e" 2>/dev/null) || continue
        while IFS= read -r u; do
          case "$t" in ("$u"*) [ -n "$u" ] && { e=${e#/proc/}; echo "${e%/exe}"; break; } ;; esac
        done <<< "$under"
      done
    fi
  }
  # sweep: kills the job's group, its descendants, then whatever runs from under a sweep directory; 1 when a process is left.
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
  trap 'sweep; exit 143' TERM INT
  set -m
  ( "${runner[@]}" "$prog" "$@" < "$stdin" | head -c $((cap + 1)) > "$stdout"; exit "${PIPESTATUS[0]}" ) &
  pgid=$!
  wait "$pgid"
  code=$?
  set +m
  sweep || { echo "llm-sandbox: a process under ${sweeps[*]} outlived the sweep" >&2; exit 3; }
  trap - TERM INT
fi

limit=false
if [ "$(wc -c < "$stdout" | tr -d ' ')" -gt "$cap" ]; then
  limit=true
  head -c "$cap" "$stdout" > "$stdout.cut" && mv "$stdout.cut" "$stdout"
fi
printf 'exit: %s\nlimit: %s\nsandbox: %s\n' "$code" "$limit" "$sandbox" > "$status"
