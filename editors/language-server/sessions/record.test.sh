#!/usr/bin/env bash
# Tests editors/language-server/sessions/record.sh with a stub server (BAYAN_LSP), so no dotnet: it frames in.jsonl,
# expands @WS@, @repeat and @concat, makes fs steps after the answers before them, writes raw bytes, normalizes
# out.jsonl (workspace path, workspace/symbol order, publishDiagnostics runs), and --check passes on a match,
# fails on a difference and on a nondeterministic server.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
record="$root/editors/language-server/sessions/record.sh"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/record-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

# The stub answers a request with {"method", "params"}; `read` with the text of the file at params.path; a
# workspace/symbol with three symbols, last first; a didOpen with publishDiagnostics for b then a; `exit` ends it.
# NONDET in the environment adds the process id to every answer.
cat > "$tmp/stub" <<'STUB'
#!/usr/bin/env python3
import json, os, sys
inp, out = sys.stdin.buffer, sys.stdout.buffer
def send(m):
    b = json.dumps(dict(jsonrpc="2.0", **m)).encode()
    out.write(b"Content-Length: %d\r\n\r\n" % len(b) + b); out.flush()
while True:
    n = None
    while True:
        line = inp.readline()
        if not line: sys.exit(0)
        line = line.strip()
        if not line:
            if n is not None: break
            continue
        if line.lower().startswith(b"content-length:"): n = int(line.split(b":")[1])
    body = inp.read(n)
    if len(body) < n: sys.exit(0)
    m = json.loads(body)
    meth, p = m.get("method"), m.get("params")
    if meth == "exit": sys.exit(0)
    if meth == "textDocument/didOpen":
        u = p["textDocument"]["uri"]
        for x in ("b", "a"): send({"method": "textDocument/publishDiagnostics", "params": {"uri": u + x, "diagnostics": []}})
    if "id" not in m: continue
    if meth == "read": r = open(p["path"]).read()
    elif meth == "workspace/symbol": r = [{"name": "c"}, {"name": "b"}, {"name": "a"}]
    else: r = {"method": meth, "params": p}
    if os.environ.get("NONDET"): r = [r, os.getpid()]
    send({"id": m["id"], "result": r})
STUB
chmod +x "$tmp/stub"
export BAYAN_LSP="$tmp/stub"

s="$tmp/s1"; mkdir -p "$s/workspace/src"; printf 'struct Aisha {}\n' > "$s/workspace/src/a.byn"
cat > "$s/in.jsonl" <<'IN'
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"rootUri":"file://@WS@","n":{"@concat":["ab",{"@repeat":"é","@times":3}]}}}
{"fs":"write","path":"src/b.byn","text":{"@repeat":"x","@times":4}}
{"jsonrpc":"2.0","id":2,"method":"read","params":{"path":"@WS@/src/b.byn"}}
{"jsonrpc":"2.0","id":3,"method":"read","params":{"path":"@WS@/src/a.byn"}}
{"fs":"move","path":"src/a.byn","to":"src/c.byn"}
{"jsonrpc":"2.0","id":4,"method":"read","params":{"path":"@WS@/src/c.byn"}}
{"jsonrpc":"2.0","method":"textDocument/didOpen","params":{"textDocument":{"uri":"file://@WS@/src/","text":"x"}}}
{"jsonrpc":"2.0","id":5,"method":"workspace/symbol","params":{"query":""}}
{"jsonrpc":"2.0","method":"exit"}
IN

bash "$record" "$s" 2> "$tmp/err" || fail "record exited non-zero: $(cat "$tmp/err")"
[ -f "$s/out.jsonl" ] || fail "no out.jsonl"
expect() { grep -qxF "$1" "$s/out.jsonl" || fail "out.jsonl has no line $1: $(cat "$s/out.jsonl")"; }
expect '{"jsonrpc":"2.0","id":1,"result":{"method":"initialize","params":{"rootUri":"file://@WS@","n":"abééé"}}}'
expect '{"jsonrpc":"2.0","id":2,"result":"xxxx"}'
expect '{"jsonrpc":"2.0","id":3,"result":"struct Aisha {}\n"}'
expect '{"jsonrpc":"2.0","id":4,"result":"struct Aisha {}\n"}'
expect '{"jsonrpc":"2.0","id":5,"result":[{"name":"a"},{"name":"b"},{"name":"c"}]}'
[ "$(sed -n 5p "$s/out.jsonl")" = '{"jsonrpc":"2.0","method":"textDocument/publishDiagnostics","params":{"uri":"file://@WS@/src/a","diagnostics":[]}}' ] \
  || fail "the publishDiagnostics run is not sorted by uri: $(cat "$s/out.jsonl")"
[ "$(wc -l < "$s/out.jsonl" | tr -d ' ')" = 7 ] || fail "expected 7 messages: $(cat "$s/out.jsonl")"
! grep -q "$tmp" "$s/out.jsonl" || fail "the scratch path leaked into out.jsonl"
[ "$(cat "$s/workspace/src/a.byn")" = 'struct Aisha {}' ] || fail "an fs step changed the session's own workspace"

bash "$record" --check "$s" 2> "$tmp/err" || fail "--check of a fresh recording failed: $(cat "$tmp/err")"
sed -i.bak -e 's/"xxxx"/"xxx"/' "$s/out.jsonl"
bash "$record" --check "$s" > /dev/null 2> "$tmp/err" && st=0 || st=$?
[ $st = 1 ] || fail "--check on a difference exited $st, not 1"
grep -q "s1: differs from out.jsonl" "$tmp/err" || fail "the difference was not named: $(cat "$tmp/err")"

NONDET=1 bash "$record" "$s" > /dev/null 2> "$tmp/err" && st=0 || st=$?
[ $st = 1 ] || fail "a nondeterministic server exited $st, not 1"
grep -q "s1: nondeterministic" "$tmp/err" || fail "nondeterminism was not named: $(cat "$tmp/err")"

# An fs step after a notification has nothing to wait for: refused.
r="$tmp/s2"; mkdir -p "$r"
printf '%s\n' '{"jsonrpc":"2.0","method":"initialized","params":{}}' '{"fs":"write","path":"x.byn","text":""}' > "$r/in.jsonl"
bash "$record" "$r" > /dev/null 2> "$tmp/err" && st=0 || st=$?
[ $st = 2 ] || fail "an fs step after a notification exited $st, not 2"
grep -q "must follow a request" "$tmp/err" || fail "the misplaced fs step was not named: $(cat "$tmp/err")"

# Raw bytes go out unframed: a truncated body ends the stub's input, so nothing after it is answered.
r="$tmp/s3"; mkdir -p "$r"
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' '{"raw":"Content-Length: 1000\r\n\r\n{\"id\":"}' \
  '{"jsonrpc":"2.0","id":2,"method":"initialize","params":{}}' > "$r/in.jsonl"
bash "$record" "$r" 2> "$tmp/err" || fail "the raw session failed: $(cat "$tmp/err")"
[ "$(wc -l < "$r/out.jsonl" | tr -d ' ')" = 1 ] || fail "a message after the truncated body was answered: $(cat "$r/out.jsonl")"

bash "$record" nosuch > /dev/null 2>&1 && st=0 || st=$?
[ $st = 2 ] || fail "an unknown session exited $st, not 2"

echo "record.test: PASS"
