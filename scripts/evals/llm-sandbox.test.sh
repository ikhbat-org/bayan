#!/usr/bin/env bash
# Test for scripts/evals/llm-sandbox.sh. Scratch is under the repo's tmp/. The sandbox cases run on macOS only; elsewhere the
# status file must say `sandbox: none`.
#   bash scripts/evals/llm-sandbox.test.sh
set -uo pipefail
cd "$(dirname "$0")/../.."
sb=scripts/evals/llm-sandbox.sh
root=$PWD/tmp/llm-sandbox-test
rm -rf "$root"; mkdir -p "$root/tasks" "$root/w/pids" "$root/other"
# At exit, every process the test started that is still alive is killed: the server, the launcher of the TERM case, the
# lingerer of the exit-3 case, and each process whose pid a sweep case wrote under $root/w/pids.
cleanup() {
  local p
  for p in ${srv:-} ${lp:-} ${ling:-} $(cat "$root"/w/pids/* 2> /dev/null); do
    kill -0 "$p" 2> /dev/null && kill -KILL "$p" 2> /dev/null
  done
  rm -rf "$root"
}
trap cleanup EXIT

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
  run -- git -C "$PWD" show HEAD:scripts/evals/llm-sandbox.sh 2> /dev/null
  check "git show of the repo's history refused" "$([ "$(field exit)" != 0 ] && [ ! -s "$root/out" ] && echo denied)" "denied"
  # git may fail on its own libraries first, so the read rule is also tested with cat on the repository's git directory.
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
  run -- env /bin/cat /etc/hosts 2> /dev/null
  check "env /bin/cat /etc/hosts refused" "$([ "$(field exit)" != 0 ] && [ ! -s "$root/out" ] && echo denied)" "denied"
  # /etc is not readable either, so the exec rule alone is tested with a program under /usr, which is.
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

# --sweep. Each process a case leaves behind writes its pid under $root/w/pids, which the EXIT trap kills, and ends by itself
# within 30 seconds: the fifo is opened read-write, so the open never blocks, and the read gives up after 30 seconds.
mkfifo "$root/w/fifo"
run --sweep "$root/w" -- "$shell" -c "( read -t 30 x <> '$root/w/fifo' ) > /dev/null 2>&1 & echo \$! > '$root/w/pids/a'; : marker-$$-a"
check "--sweep: a child in the program's group is reaped" "$(ps -axo command= | grep -c "[m]arker-$$-a")" "0"

if command -v zig > /dev/null 2>&1; then
  # lingerer <secs> [fork <pidfile>]: with "fork", double-forks into a new session, writes the last child's pid to <pidfile>
  # and sleeps there; the parent exits at once.
  cat > "$root/lingerer.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char** argv) {
    int secs = argc > 1 ? atoi(argv[1]) : 5;
    if (argc > 3) {
        pid_t a = fork();
        if (a < 0) return 3;
        if (a > 0) return 0;
        setsid();
        pid_t b = fork();
        if (b < 0) return 3;
        if (b > 0) return 0;
        FILE* f = fopen(argv[3], "w");
        if (f) { fprintf(f, "%d\n", (int)getpid()); fclose(f); }
    }
    sleep(secs);
    return 0;
}
EOF
  zig cc -o "$root/w/lingerer" "$root/lingerer.c" 2> "$root/zig.err" || { cat "$root/zig.err"; bad "zig cc lingerer.c"; }
  # tamper <dir>: writes 0 into every file in <dir>, makes it read-only, exits 7. The program can write TMPDIR, so no file
  # there may carry its exit code (review 2026-11-18, loop 2).
  cat > "$root/tamper.c" <<'EOF'
#include <dirent.h>
#include <stdio.h>
#include <sys/stat.h>
int main(int argc, char** argv) {
    DIR* d = opendir(argv[1]);
    struct dirent* e;
    char p[4096];
    while (d && (e = readdir(d)) != NULL) {
        if (e->d_name[0] == '.') continue;
        snprintf(p, sizeof p, "%s/%s", argv[1], e->d_name);
        FILE* f = fopen(p, "w");
        if (f) { fputs("0\n", f); fclose(f); chmod(p, 0444); }
    }
    return 7;
}
EOF
  zig cc -o "$root/w/tamper" "$root/tamper.c" 2> "$root/zig.err" || { cat "$root/zig.err"; bad "zig cc tamper.c"; }
  mkdir -p "$root/w/tmp"
  TMPDIR="$root/w/tmp" run -- "$root/w/tamper" "$root/w/tmp" 2> /dev/null
  check "exit code not rewritable from TMPDIR" "$(field exit)" "7"
  TMPDIR="$root/w/tmp" run --sweep "$root/w" -- "$root/w/tamper" "$root/w/tmp" 2> /dev/null
  check "exit code not rewritable from TMPDIR (--sweep)" "$(field exit)" "7"
  chmod -R u+w "$root/w/tmp"
  lingering() { ps -axo command= | grep -c "^$root/w/[l]ingerer"; }
  run --sweep "$root/w" -- "$shell" -c "'$root/w/lingerer' 20 fork '$root/w/pids/b' > /dev/null 2>&1"
  check "--sweep: a child that left the group and the session is reaped" "$(field exit) $(lingering)" "0 0"

  # TERM to the launcher while the program runs: a lingerer that left the group and the session, and the program, a shell
  # waiting on the fifo. The launcher sweeps both and exits 143.
  rm -f "$root/out" "$root/status"
  "$bash" "$sb" --write "$root/w" --sweep "$root/w" --stdout "$root/out" --status "$root/status" -- \
    "$shell" -c "'$root/w/lingerer' 20 fork '$root/w/pids/c' > /dev/null 2>&1; read -t 30 x <> '$root/w/fifo'; : marker-$$-t" &
  lp=$!
  for _ in $(seq 1 100); do [ -s "$root/w/pids/c" ] && break; sleep 0.1; done
  kill -TERM "$lp"
  wait "$lp"; code=$?; lp=""
  check "--sweep: TERM to the launcher leaves no process and exits 143" \
    "$code $(lingering) $(ps -axo command= | grep -c "[m]arker-$$-t")" "143 0 0"

  if $mac; then
    # A scan that always finds a process: the launcher says so and exits 3. The process it names is a lingerer under the
    # sweep directory, which the launcher kills; the stub still names it.
    "$root/w/lingerer" 20 & ling=$!
    mkdir -p "$root/stub"
    printf '#!/bin/sh\nprintf "p%%s\\nn%%s\\n" %s "%s"\n' "$ling" "$root/w/lingerer" > "$root/stub/lsof"
    chmod +x "$root/stub/lsof"
    PATH="$root/stub:$PATH" run --sweep "$root/w" -- true 2> /dev/null
    check "--sweep: a process left after the sweep gives exit 3" "$? $([ -e "$root/status" ] && echo status || echo none)" "3 none"
    wait "$ling" 2> /dev/null; ling=""
  fi
else
  echo "skip lingerer cases: zig missing"
fi

echo "llm-sandbox.test: $pass passed, $fail failed"
[ "$fail" = 0 ]
