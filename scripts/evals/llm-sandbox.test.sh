#!/usr/bin/env bash
# Test for scripts/evals/llm-sandbox.sh. Scratch is under the repo's tmp/. The sandbox cases run on macOS only; elsewhere the
# status file must say `sandbox: none`.
#   bash scripts/evals/llm-sandbox.test.sh
set -uo pipefail
cd "$(dirname "$0")/../.."
sb=scripts/evals/llm-sandbox.sh
root=$PWD/tmp/llm-sandbox-test
rm -rf "$root"; mkdir -p "$root/tasks" "$root/w" "$root/other"
trap 'rm -rf "$root"; [ -z "${srv:-}" ] || kill "$srv" 2>/dev/null' EXIT

pass=0 fail=0
ok() { pass=$((pass + 1)); echo "ok   $1"; }
bad() { fail=$((fail + 1)); echo "FAIL $1"; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (got '$2', want '$3')"; fi; }
field() { sed -n "s/^$1: //p" "$root/status"; }
# run <extra launcher args...> -- program args: writes $root/out and $root/status
run() {
  rm -f "$root/out" "$root/status"
  "$bash" "$sb" --write "$root/w" --stdout "$root/out" --status "$root/status" "$@"
}
bash=${BASH:-/bin/bash}
# The shell run as the program: /bin/bash, whose libraries are all under /usr and /System (a sandboxed /bin/sh cannot exec
# the shell it stands for).
shell=/bin/bash

mac=false
[ "$(uname -s)" = Darwin ] && [ -x /usr/bin/sandbox-exec ] && mac=true

# exit code and stdin
printf 'hello\n' > "$root/in"
run --stdin "$root/in" -- cat
check "stdout copied" "$(cat "$root/out")" "hello"
check "exit 0" "$(field exit)" "0"
check "limit false" "$(field limit)" "false"
run -- "$shell" -c 'exit 7'
check "exit code kept" "$(field exit)" "7"

# sandbox name
if $mac; then check "sandbox name" "$(field sandbox)" "sandbox-exec/2"; else check "sandbox name" "$(field sandbox)" "none"; fi

# a program not on PATH is named
run -- "no-such-program-$$" 2> "$root/err"
check "program not found names it" "$? $(grep -c "program not found: no-such-program-$$\$" "$root/err")" "2 1"

# environment allowlist
export SECRET_TOKEN=abc ANTHROPIC_API_KEY=xyz NO_COLOR=1
run -- env
names=$(sed 's/=.*//' "$root/out" | sort | tr '\n' ' ')
extra=""
for n in $names; do
  case "$n" in (HOME|PATH|TMPDIR|BAYAN_CACHE|BAYAN_TEST_TIMEOUT_MS|NO_COLOR|DOTNET_ROOT|PWD|SHLVL|_|OLDPWD) ;; (*) extra="$extra $n" ;; esac
done
check "no names outside the allowlist" "$extra" ""
check "NO_COLOR passed" "$(grep -c '^NO_COLOR=1$' "$root/out")" "1"
check "secret not passed" "$(grep -c 'SECRET_TOKEN\|ANTHROPIC_API_KEY' "$root/out")" "0"

# output cap
run -- head -c 2097152 /dev/zero
check "output cut at 1 MiB" "$(wc -c < "$root/out" | tr -d ' ')" "1048576"
check "cut is marked" "$(field limit)" "true"
run -- yes
check "endless output is cut" "$(wc -c < "$root/out" | tr -d ' ')" "1048576"
check "endless output is marked" "$(field limit)" "true"
run -- head -c 1048576 /dev/zero
check "1 MiB of output is not marked" "$(field limit)" "false"

if $mac; then
  printf 'hidden\n' > "$root/tasks/secret"
  run --deny-read "$root/tasks" -- cat "$root/tasks/secret"
  check "read under tasks denied" "$([ "$(field exit)" != 0 ] && [ ! -s "$root/out" ] && echo denied)" "denied"
  printf 'visible\n' > "$root/other/f"
  run --deny-read "$root/tasks" -- cat "$root/other/f"
  check "read of a sibling outside --write denied" "$([ "$(field exit)" != 0 ] && [ ! -s "$root/out" ] && echo denied)" "denied"
  run -- cat "$(git rev-parse --path-format=absolute --git-common-dir)/HEAD"
  check "read of the repo's history denied" "$([ "$(field exit)" != 0 ] && [ ! -s "$root/out" ] && echo denied)" "denied"

  run -- "$shell" -c "echo x > '$root/other/leak'"
  check "write outside --write denied" "$([ "$(field exit)" != 0 ] && [ ! -e "$root/other/leak" ] && echo denied)" "denied"
  run -- "$shell" -c "echo x > '$root/w/made'"
  check "write inside --write allowed" "$([ "$(field exit)" = 0 ] && cat "$root/w/made")" "x"
  run -- cat "$root/w/made"
  check "read inside --write allowed" "$(cat "$root/out")" "x"

  # Signals: only to processes in the same sandbox.
  run -- "$shell" -c "kill -0 $$"
  check "signal to a process outside denied" "$([ "$(field exit)" != 0 ] && echo denied)" "denied"
  run -- "$shell" -c 'kill -0 $$'
  check "signal to itself allowed" "$(field exit)" "0"

  # Exec: only the program, env, zig and what is under --write, TMPDIR or BAYAN_CACHE.
  # /usr is readable, so only the exec rule stops it.
  run -- env /usr/bin/printf x
  check "exec outside the list denied" "$([ "$(field exit)" != 0 ] && [ ! -s "$root/out" ] && echo denied)" "denied"

  # A path the profile cannot hold is refused before anything runs.
  mkdir -p "$root/q\"d"
  run --deny-read "$root/q\"d" -- true 2> /dev/null
  check "a path with a quote refused" "$? $([ -e "$root/status" ] && echo status || echo none)" "2 none"

  # --no-fork: the program runs, but cannot fork.
  run --no-fork -- "$shell" -c '(exit 0) && echo forked' 2> /dev/null
  check "--no-fork denies fork" "$(cat "$root/out")" ""
  run --no-fork -- "$shell" -c 'echo ok'
  check "--no-fork still runs the program" "$(cat "$root/out")" "ok"

  if command -v python3 >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
    port=$((20000 + $$ % 20000))
    (cd "$root/other" && exec python3 -m http.server "$port" --bind 127.0.0.1 >/dev/null 2>&1) & srv=$!
    for _ in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null "http://127.0.0.1:$port/f" && break; sleep 0.3; done
    run -- curl -s --max-time 5 "http://127.0.0.1:$port/f"
    check "network denied" "$([ "$(field exit)" != 0 ] && [ ! -s "$root/out" ] && echo denied)" "denied"
    check "server was reachable outside the sandbox" "$(curl -s --max-time 5 "http://127.0.0.1:$port/f")" "visible"
  else
    echo "skip network case: python3 or curl missing"
  fi
else
  echo "skip sandbox cases: no sandbox-exec"
fi

# --sweep. The test sends no signal but `kill -0`: a process left behind ends by itself, the fifo reader when the test's
# descriptor closes at exit, the lingerer after 20 seconds.
mkfifo "$root/w/fifo"
exec 3<> "$root/w/fifo"
run --sweep "$root/w" -- "$shell" -c "( read x < '$root/w/fifo' ) > /dev/null 2>&1 & : marker-$$-a"
check "--sweep: a child in the program's group is reaped" "$(ps -axo command= | grep -c "[m]arker-$$-a")" "0"

if command -v zig > /dev/null 2>&1; then
  # lingerer <secs> [fork]: with "fork", double-forks into a new session and sleeps there; the parent exits at once.
  cat > "$root/lingerer.c" <<'EOF'
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char** argv) {
    int secs = argc > 1 ? atoi(argv[1]) : 5;
    if (argc > 2) {
        pid_t a = fork();
        if (a < 0) return 3;
        if (a > 0) return 0;
        setsid();
        pid_t b = fork();
        if (b < 0) return 3;
        if (b > 0) return 0;
    }
    sleep(secs);
    return 0;
}
EOF
  zig cc -o "$root/w/lingerer" "$root/lingerer.c" 2> "$root/zig.err" || { cat "$root/zig.err"; bad "zig cc lingerer.c"; }
  lingering() { ps -axo command= | grep -c "^$root/w/[l]ingerer"; }
  run --sweep "$root/w" -- "$shell" -c "'$root/w/lingerer' 20 fork > /dev/null 2>&1"
  check "--sweep: a child that left the group and the session is reaped" "$(field exit) $(lingering)" "0 0"

  # TERM, as the scorer's time limit sends it: Io.run's timeout signals the launcher, whose trap sweeps. The scorer's own
  # tests cannot see this, since each later launch on the same sample sweeps it too.
  if pinned=$(bash scripts/pinned-bayan.sh 2> /dev/null); then
    cat > "$root/term.byn" <<'EOF'
#!/usr/bin/env bayan
i32 main(ReadOnlySpan<string> argv) {
    var a = List<string>()
    for x in [argv[0], "--write", argv[1], "--sweep", argv[1], "--stdout", argv[2], "--status", argv[3], "--", argv[4], "20"] {
        a.append(x)
    }
    let _ = Io.run("bash", a.span, timeout: Millis(1000)) catch return 9
    return 0
}
EOF
    "$pinned" run "$root/term.byn" -- "$PWD/$sb" "$root/w" "$root/out" "$root/status" "$root/w/lingerer" > /dev/null 2>&1
    check "--sweep: TERM from a time limit reaps the program" "$? $(lingering)" "9 0"
  else
    echo "skip TERM case: no pinned bayan"
  fi

  if $mac; then
    # A scan that always finds a process: the launcher says so and exits 3. The process it names is a lingerer under the
    # sweep directory, which the launcher kills; the stub still names it.
    "$root/w/lingerer" 20 & ling=$!
    mkdir -p "$root/stub"
    printf '#!/bin/sh\nprintf "p%%s\\nn%%s\\n" %s "%s"\n' "$ling" "$root/w/lingerer" > "$root/stub/lsof"
    chmod +x "$root/stub/lsof"
    PATH="$root/stub:$PATH" run --sweep "$root/w" -- true 2> /dev/null
    check "--sweep: a process left after the sweep gives exit 3" "$? $([ -e "$root/status" ] && echo status || echo none)" "3 none"
    wait "$ling" 2> /dev/null
  fi
else
  echo "skip lingerer cases: zig missing"
fi

echo "llm-sandbox.test: $pass passed, $fail failed"
[ "$fail" = 0 ]
