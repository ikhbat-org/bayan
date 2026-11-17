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

mac=false
[ "$(uname -s)" = Darwin ] && [ -x /usr/bin/sandbox-exec ] && mac=true

# exit code and stdin
printf 'hello\n' > "$root/in"
run --stdin "$root/in" -- cat
check "stdout copied" "$(cat "$root/out")" "hello"
check "exit 0" "$(field exit)" "0"
check "limit false" "$(field limit)" "false"
run -- sh -c 'exit 7'
check "exit code kept" "$(field exit)" "7"

# sandbox name
if $mac; then check "sandbox name" "$(field sandbox)" "sandbox-exec"; else check "sandbox name" "$(field sandbox)" "none"; fi

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
run -- sh -c 'head -c 2097152 /dev/zero'
check "output cut at 1 MiB" "$(wc -c < "$root/out" | tr -d ' ')" "1048576"
check "cut is marked" "$(field limit)" "true"
run -- sh -c 'yes'
check "endless output is cut" "$(wc -c < "$root/out" | tr -d ' ')" "1048576"
check "endless output is marked" "$(field limit)" "true"
run -- sh -c 'head -c 1048576 /dev/zero'
check "1 MiB of output is not marked" "$(field limit)" "false"

if $mac; then
  printf 'hidden\n' > "$root/tasks/secret"
  run --deny-read "$root/tasks" -- cat "$root/tasks/secret"
  check "read under tasks denied" "$([ "$(field exit)" != 0 ] && [ ! -s "$root/out" ] && echo denied)" "denied"
  printf 'visible\n' > "$root/other/f"
  run --deny-read "$root/tasks" -- cat "$root/other/f"
  check "read elsewhere allowed" "$(cat "$root/out")" "visible"

  run -- sh -c "echo x > '$root/other/leak'"
  check "write outside --write denied" "$([ "$(field exit)" != 0 ] && [ ! -e "$root/other/leak" ] && echo denied)" "denied"
  run -- sh -c "echo x > '$root/w/made'"
  check "write inside --write allowed" "$([ "$(field exit)" = 0 ] && cat "$root/w/made")" "x"

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

echo "llm-sandbox.test: $pass passed, $fail failed"
[ "$fail" = 0 ]
