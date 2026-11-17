#!/usr/bin/env bash
# Tests scripts/cleanup/2026-11-17-vm-zig-cache.sh against a fake ssh that logs
# every call and never reaches a host.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="$root/scripts/cleanup/2026-11-17-vm-zig-cache.sh"
tmp="$root/tmp/vm-zig-cache-test"
rm -rf "$tmp"
mkdir -p "$tmp/bin"
trap 'rm -rf "$tmp"' EXIT

# FAKE_STATE: what `incus list` prints. FAKE_FAIL: an incus exec command word that fails.
cat > "$tmp/bin/ssh" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$FAKE_LOG"
shift
case "$1 $2" in
  "incus list") echo "$FAKE_STATE" ;;
  "incus exec") [ "${5:-}" != "${FAKE_FAIL:-}" ] || exit 1 ;;
  "incus stop") [ -z "${FAKE_STOP_FAIL:-}" ] || exit 1 ;;
esac
exit 0
EOF
chmod +x "$tmp/bin/ssh"

# run NAME STATE FAIL WANT_CODE ARGS...
run() {
  local name="$1" state="$2" fail="$3" want="$4"; shift 4
  : > "$tmp/log"
  local code=0
  FAKE_LOG="$tmp/log" FAKE_STATE="$state" FAKE_FAIL="$fail" PATH="$tmp/bin:$PATH" \
    bash "$script" "$@" > "$tmp/out" 2>&1 || code=$?
  if [ "$code" != "$want" ]; then
    echo "FAIL $name: exit $code, want $want"; cat "$tmp/out"; exit 1
  fi
}
has()  { grep -q -- "$2" "$tmp/log" || { echo "FAIL $1: no call matching '$2'"; cat "$tmp/log"; exit 1; }; }
# before NAME FIRST SECOND: the first call matching FIRST precedes the first matching SECOND
before() {
  local a b
  a=$(grep -n -- "$2" "$tmp/log" | head -1 | cut -d: -f1); b=$(grep -n -- "$3" "$tmp/log" | head -1 | cut -d: -f1)
  [ -n "$a" ] && [ -n "$b" ] && [ "$a" -lt "$b" ] || { echo "FAIL $1: '$2' not before '$3'"; cat "$tmp/log"; exit 1; }
}
hasnt() { ! grep -q -- "$2" "$tmp/log" || { echo "FAIL $1: unexpected call matching '$2'"; cat "$tmp/log"; exit 1; }; }

run "stopped vm, act" STOPPED "" 0 --execute --delete-zig-cache
has "stopped vm, act" "incus start"
has "stopped vm, act" "rm -rf -- /home/bt/.cache/zig"
has "stopped vm, act" "incus stop"
before "stopped vm, act" "rm -rf -- /home/bench/.cache/zig" "incus stop"

run "running vm, delete refused" RUNNING "" 1 --execute --delete-zig-cache
hasnt "running vm, delete refused" "rm -rf"
hasnt "running vm, delete refused" "incus stop"

run "running vm, execute only" RUNNING "" 0 --execute
hasnt "running vm, execute only" "incus stop"

run "failure after start still stops" STOPPED df 1 --execute --delete-zig-cache
has "failure after start still stops" "incus stop"

FAKE_STOP_FAIL=1 run "failed stop is reported" STOPPED "" 1 --execute --delete-zig-cache
grep -q "FAILED to stop" "$tmp/out" || { echo "FAIL failed stop is reported: no message"; cat "$tmp/out"; exit 1; }

run "frozen vm refused" FROZEN "" 1 --execute --delete-zig-cache
hasnt "frozen vm refused" "incus start"
hasnt "frozen vm refused" "rm -rf"

run "dry run" STOPPED "" 0
hasnt "dry run" "incus start"

echo "ok: 7 cases"
