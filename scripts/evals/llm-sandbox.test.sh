#!/usr/bin/env bash
# Test for scripts/evals/llm-sandbox.sh. Scratch is under the repo's tmp/. The sandbox cases run on macOS only; elsewhere the
# status file must say `sandbox: none`.
#   bash scripts/evals/llm-sandbox.test.sh
set -uo pipefail
cd "$(dirname "$0")/../.."
sb=$PWD/scripts/evals/llm-sandbox.sh
root=$PWD/tmp/llm-sandbox-test
rm -rf "$root"; mkdir -p "$root/tasks" "$root/w/pids" "$root/other"
# At exit, every process the test started that is still alive is killed: the server, the launcher of the TERM case, the
# lingerer of the exit-3 case, the fifo's holder, and each process whose pid a sweep case wrote under $root/w/pids.
cleanup() {
  local p
  for p in ${srv:-} ${lp:-} ${ling:-} ${hold:-} $(cat "$root"/w/pids/* 2> /dev/null); do
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
if $mac; then check "sandbox name" "$(field sandbox)" "sandbox-exec/3"; else check "sandbox name" "$(field sandbox)" "none"; fi

# a program not on PATH is named
run -- "no-such-program-$$" 2> "$root/err"
check "program not found names it" "$? $(grep -c "program not found: no-such-program-$$\$" "$root/err")" "2 1"

# environment allowlist
export SECRET_TOKEN=abc ANTHROPIC_API_KEY=xyz NO_COLOR=1
run -- env
names=$(sed 's/=.*//' "$root/out" | sort | tr '\n' ' ')
extra=""
for n in $names; do
  case "$n" in (HOME|PATH|TMPDIR|BAYAN_CACHE|BAYAN_TEST_TIMEOUT_MS|NO_COLOR|DOTNET_ROOT|ZIG_LIB_DIR|PWD|SHLVL|_|OLDPWD) ;; (*) extra="$extra $n" ;; esac
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

  # Exec: without --sweep, only the program, env and what is under --write, TMPDIR or BAYAN_CACHE.
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
# within 20 seconds. With --sweep the program may start only what lies under a swept directory, so every case's program is
# built there with zig.
if command -v zig > /dev/null 2>&1; then
  # lingerer <secs> [child|fork|stay <pidfile>]: "child" forks a child that stays in the program's group; "fork"
  # double-forks into a new session; "stay" does as "fork" and the first process sleeps too. The last child writes its pid
  # to <pidfile>. Each sleeps <secs>; a first process that does not stay exits at once.
  cat > "$root/lingerer.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
int main(int argc, char** argv) {
    int secs = argc > 1 ? atoi(argv[1]) : 5;
    if (argc > 3) {
        pid_t a = fork();
        if (a < 0) return 3;
        if (a > 0) {
            if (strcmp(argv[2], "stay") == 0) sleep(secs);
            return 0;
        }
        if (strcmp(argv[2], "child") != 0) {
            setsid();
            pid_t b = fork();
            if (b < 0) return 3;
            if (b > 0) return 0;
        }
        FILE* f = fopen(argv[3], "w");
        if (f) { fprintf(f, "%d\n", (int)getpid()); fclose(f); }
    }
    sleep(secs);
    return 0;
}
EOF
  zig cc -o "$root/w/lingerer" "$root/lingerer.c" 2> "$root/zig.err" || { cat "$root/zig.err"; bad "zig cc lingerer.c"; }
  # alive <pidfile>: "started" when the pid was written, then "alive" or "dead".
  alive() { local p; p=$(cat "$1" 2> /dev/null); echo "$([ -n "$p" ] && echo started) $([ -n "$p" ] && kill -0 "$p" 2> /dev/null && echo alive || echo dead)"; }
  run --sweep "$root/w" -- "$root/w/lingerer" 20 child "$root/w/pids/a"
  check "--sweep: a child in the program's group is reaped" "$(field exit) $(alive "$root/w/pids/a")" "0 started dead"
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
  run --sweep "$root/w" -- "$root/w/lingerer" 20 fork "$root/w/pids/b"
  check "--sweep: a child that left the group and the session is reaped" "$(field exit) $(lingering)" "0 0"

  # TERM to the launcher while the program runs: a lingerer that left the group and the session, and the program, a
  # lingerer that stays. The launcher sweeps both and exits 143.
  rm -f "$root/out" "$root/status"
  "$bash" "$sb" --write "$root/w" --sweep "$root/w" --stdout "$root/out" --status "$root/status" -- \
    "$root/w/lingerer" 20 stay "$root/w/pids/c" &
  lp=$!
  for _ in $(seq 1 100); do [ -s "$root/w/pids/c" ] && break; sleep 0.1; done
  kill -TERM "$lp"
  wait "$lp"; code=$?; lp=""
  check "--sweep: TERM to the launcher leaves no process and exits 143" "$code $(lingering)" "143 0"

  # --prime (R14): the program is started suspended and killed, so it writes nothing and prints nothing, and a program
  # that loops costs no time. Elsewhere --prime runs nothing, which the same checks hold for.
  cat > "$root/marker.c" <<'EOF'
#include <stdio.h>
int main(int argc, char** argv) {
    FILE* f = fopen(argv[1], "w");
    if (f) { fputs("ran\n", f); fclose(f); }
    puts("ran");
    return 0;
}
EOF
  # The looper ends by itself after 20 seconds, so a prime that runs it fails the check instead of hanging the test.
  printf '#include <time.h>\nint main(void) {\n    time_t start = time(0);\n    while (time(0) - start < 20) {\n    }\n    return 0;\n}\n' > "$root/looper.c"
  zig cc -o "$root/w/marker" "$root/marker.c" 2> "$root/zig.err" || { cat "$root/zig.err"; bad "zig cc marker.c"; }
  zig cc -o "$root/w/looper" "$root/looper.c" 2> "$root/zig.err" || { cat "$root/zig.err"; bad "zig cc looper.c"; }
  primed() { ps -axo command= | grep -c "^$root/w/[m]arker\|^$root/w/[l]ooper"; }
  start=$(date +%s)
  run --prime --sweep "$root/w" -- "$root/w/marker" "$root/w/marked"; code=$?
  secs=$(($(date +%s) - start))
  check "--prime: returns 0 within 5 s, the program wrote no file, printed nothing and is gone" \
    "$code $(field exit) $([ "$secs" -le 5 ] && echo fast) $([ -e "$root/w/marked" ] && echo file || echo nofile) $(wc -c < "$root/out" | tr -d ' ') $(primed)" \
    "0 0 fast nofile 0 0"
  start=$(date +%s)
  run --prime --sweep "$root/w" -- "$root/w/looper"; code=$?
  secs=$(($(date +%s) - start))
  check "--prime: a looping program returns within 5 s and is gone" \
    "$code $(field exit) $([ "$secs" -le 5 ] && echo fast) $(primed)" "0 0 fast 0"
  run -- "$root/w/marker" "$root/w/marked"
  check "the program primed runs after" "$(field exit) $(cat "$root/out") $(cat "$root/w/marked")" "0 ran ran"

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

    # Exec only from swept directories (T44, sandbox-exec/3). Zig and the program are started from copies in a tools
    # directory, which the sweep covers and the program cannot write. A holder keeps the fifo open for 20 seconds, so a
    # process reading it ends by itself then.
    tools=$root/tools
    mkdir -p "$tools/zig"
    zexe=$(zig env | sed -n 's/^ *\.zig_exe = "\(.*\)",$/\1/p')
    zlib=$(zig env | sed -n 's/^ *\.lib_dir = "\(.*\)",$/\1/p')
    cp -c "$zexe" "$tools/zig/zig" 2> /dev/null || cp "$zexe" "$tools/zig/zig"
    "$tools/zig/zig" version > /dev/null  # the system's check of a new copy, before any case
    # detach <pidfile> <program> [args...]: double-forks into a new session; the last child writes its pid to <pidfile> and
    # execs <program> (on PATH) with standard input kept. Returns once that exec is done. `detach read` reads its standard
    # input to the end.
    cat > "$root/detach.c" <<'EOF'
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
int main(int argc, char** argv) {
    char buf[256];
    if (argc == 2 && strcmp(argv[1], "read") == 0) {
        while (read(0, buf, sizeof buf) > 0) {
        }
        return 0;
    }
    if (argc < 3) return 2;
    int p[2];
    if (pipe(p) != 0) return 3;
    fcntl(p[1], F_SETFD, FD_CLOEXEC);
    pid_t a = fork();
    if (a < 0) return 3;
    if (a > 0) {
        close(p[1]);
        while (read(p[0], buf, 1) > 0) {
        }
        return 0;
    }
    setsid();
    pid_t b = fork();
    if (b < 0) return 3;
    if (b > 0) return 0;
    FILE* f = fopen(argv[1], "w");
    if (f) { fprintf(f, "%d\n", (int)getpid()); fclose(f); }
    int n = open("/dev/null", O_WRONLY);
    dup2(n, 1);
    dup2(n, 2);
    execvp(argv[2], argv + 2);
    return 127;
}
EOF
    zig cc -o "$root/w/detach" "$root/detach.c" 2> "$root/zig.err" || { cat "$root/zig.err"; bad "zig cc detach.c"; }
    cp "$root/w/detach" "$tools/detach"
    mkfifo "$root/zfifo"
    sleep 20 3<> "$root/zfifo" & hold=$!
    PATH="$tools/zig:$PATH" ZIG_LIB_DIR="$zlib" run --sweep "$root/w" --tools "$tools" --stdin "$root/zfifo" -- \
      "$root/w/detach" "$root/w/pids/z" zig fmt --stdin
    check "/3: a detached zig fmt --stdin is dead after the sweep" "$(field exit) $(alive "$root/w/pids/z")" "0 started dead"
    run --sweep "$root/w" --tools "$tools" --stdin "$root/zfifo" -- "$tools/detach" "$root/w/pids/y" "$tools/detach" read
    check "/3: the program's own path, detached, is dead after the sweep" "$(field exit) $(alive "$root/w/pids/y")" "0 started dead"
    ZIG_LIB_DIR="$zlib" run --tools "$tools" -- "$tools/zig/zig" version
    check "/3: zig from the tools directory runs" "$(field exit) $(cat "$root/out")" "0 $("$zexe" version)"
    ZIG_LIB_DIR="$zlib" run --tools "$tools" -- env "$zexe" version 2> /dev/null
    check "/3: exec of the real zig refused" "$([ "$(field exit)" != 0 ] && [ ! -s "$root/out" ] && echo denied)" "denied"
    # The tools directory lies under --write here, so only its own rule keeps the program from writing it.
    mkdir -p "$root/w/tools"
    run --sweep "$root/w" --tools "$root/w/tools" -- "$root/w/marker" "$root/w/tools/made"
    check "/3: a write to the tools directory refused" "$(field exit) $([ -e "$root/w/tools/made" ] && echo made || echo none)" "0 none"
    rm -f "$root/w/marked"
    run --prime --sweep "$root/w" --tools "$tools" -- "$root/w/marker" "$root/w/marked"
    check "/3: --prime with --tools builds its helper there" \
      "$(field exit) $([ -x "$tools/llm-prime" ] && echo helper) $([ -e "$root/w/marked" ] && echo file || echo nofile)" "0 helper nofile"
  fi
else
  echo "skip lingerer cases: zig missing"
fi


# --stdout and --status are written and read by the launcher outside the sandbox, so neither may be a symlink nor lie under
# --write, where the program could plant one (0.4.0 audit 16 #1). Each refusal leaves the outside file as it was.
printf 'kept\n' > "$root/other/victim"
refused() { "$bash" "$sb" "$@" -- "$shell" -c 'head -c 1048600 /dev/zero' > /dev/null 2> "$root/err"; echo "$? $(cat "$root/other/victim")"; }
check "--stdout under --write refused" "$(refused --write "$root/w" --stdout "$root/w/out" --status "$root/status")" "2 kept"
check "--status under --write refused" "$(refused --write "$root/w" --stdout "$root/out" --status "$root/w/status")" "2 kept"
ln -sfn "$root/w" "$root/wlink"
check "--stdout under --write named through a symlink refused" \
  "$(refused --write "$root/wlink" --stdout "$root/w/out" --status "$root/status")" "2 kept"
rm -f "$root/out" "$root/status"
ln -s "$root/other/victim" "$root/out"
check "--stdout a symlink refused" "$(refused --write "$root/w" --stdout "$root/out" --status "$root/status")" "2 kept"
rm -f "$root/out"
ln -s "$root/other/victim" "$root/status"
check "--status a symlink refused" "$(refused --write "$root/w" --stdout "$root/out" --status "$root/status")" "2 kept"
rm -f "$root/status"
ln -s "$root/other/victim" "$root/w/big.cut"
check "--stdout whose .cut is planted under --write refused" \
  "$(refused --write "$root/w" --stdout "$root/w/big" --status "$root/status")" "2 kept"
rm -f "$root/w/big.cut"
check "--status in a missing directory under --write named through a symlink refused" \
  "$(refused --write "$root/wlink" --stdout "$root/out" --status "$root/wlink/new/status")" "2 kept"
check "--status in a missing directory outside --write refused" \
  "$(refused --write "$root/w" --stdout "$root/out" --status "$root/other/new/status")" "2 kept"
mkdir -p "$root/w/rel"
check "relative --status under --write refused" \
  "$(cd "$root/w" && refused --write . --stdout "$root/out" --status rel/status) $(grep -c 'under --write' "$root/err")" "2 kept 1"
check "relative --stdout under --write refused" \
  "$(cd "$root/w" && refused --write . --stdout ./out --status "$root/status") $(grep -c 'under --write' "$root/err")" "2 kept 1"
mkdir -p "$root/other/rel"
check "relative --status under --write refused with CDPATH exported" \
  "$(cd "$root/w" && export CDPATH="$root/other" && refused --write . --stdout "$root/out" --status rel/status) $(grep -c 'under --write' "$root/err")" "2 kept 1"
check "--write / refused" "$(refused --write / --stdout "$root/out" --status "$root/status")" "2 kept"
check "--status naming a directory refused" \
  "$(refused --write "$root/w" --stdout "$root/out" --status "$root/other/") $(grep -c 'name a file' "$root/err")" "2 kept 1"
rm -f "$root/wlink"
# `..` after a symlink is resolved as the kernel does: other/l/.. is w, not other.
mkdir -p "$root/w/deep"
ln -sfn "$root/w/deep" "$root/other/l"
check "--status through a symlink and .. into --write refused" \
  "$(refused --write "$root/w" --stdout "$root/out" --status "$root/other/l/../x") $(grep -c 'under --write' "$root/err")" "2 kept 1"
rm -f "$root/other/l"
# A symlink in the given path that lies under --write is read once, at the check: the program retargeting it during its
# run does not move the launcher's writes.
mkdir -p "$root/w/evil"
ln -sfn "$root/other" "$root/w/link"
ln -sfn "$root/other/victim" "$root/w/evil/status"
"$bash" "$sb" --write "$root/w" --stdout "$root/out" --status "$root/w/link/status" -- /bin/ln -sfn "$root/w/evil" "$root/w/link" \
  > /dev/null 2> "$root/err"
check "a symlink retargeted by the program does not move --status" \
  "$? $(cat "$root/other/victim") $(grep -c '^exit:' "$root/other/status")" "0 kept 1"
rm -rf "$root/w/link" "$root/w/evil" "$root/other/status"
echo "llm-sandbox.test: $pass passed, $fail failed"
[ "$fail" = 0 ]
