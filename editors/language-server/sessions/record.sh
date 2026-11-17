#!/usr/bin/env bash
# Records the language server sessions of spec 019 (T34, R21) against the C# bayan-lsp, or checks them.
#   record.sh [--check] [session...]   a session is a name under this directory or a path to a session directory;
#                                      none means every directory here that holds an in.jsonl.
# A session directory holds:
#   workspace/  files copied to a scratch directory under the repo tmp/ before the server starts (optional);
#   in.jsonl    one JSON object per line, in order:
#                 - a client message (it has "jsonrpc"): framed with Content-Length onto the server's stdin;
#                 - {"fs": op, "path": rel, ...}: a disk change, made once the server has answered every request
#                   sent so far (so it must follow a request, or come before any message). ops: write (text),
#                   delete, move (to), symlink (target, relative to the workspace), chmod (mode, octal string);
#                 - {"raw": text}: bytes written to stdin as they are, with no framing.
#               In a client message or an fs text, "@WS@" in a string is the scratch workspace (its real path, or that
#               path URI-escaped inside a "file:" string); {"@repeat": s, "@times": n} is s repeated n times and
#               {"@concat": [v, ...]} the values joined, so megabyte inputs stay one short line.
#   out.jsonl   every message the server wrote, one per line, compact JSON with key order kept, the workspace path
#               replaced by @WS@ again. Normalized: a workspace/symbol result array is sorted, and each run of
#               consecutive publishDiagnostics is stably sorted by uri; both follow the order the folder walk
#               enumerated the disk in, which differs between file systems.
# Every session runs twice; two different outputs are a failure ("nondeterministic"). With --check the output is
# compared with out.jsonl instead of written, and a difference is a failure. Exit 0 on success, 1 on a failure,
# 2 on a usage or build error.
# BAYAN_LSP  the server executable; unset, the C# server in editors/language-server is built with dotnet into
#            tmp/lsp-sessions-build/.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
check=0
if [ "${1:-}" = --check ]; then check=1; shift; fi

sessions=()
if [ $# -eq 0 ]; then
  for d in "$here"/*/; do [ -f "$d/in.jsonl" ] && sessions+=("${d%/}"); done
else
  for s in "$@"; do
    case "$s" in */*) d="$s" ;; *) d="$here/$s" ;; esac
    [ -f "$d/in.jsonl" ] || { echo "record: no session at $d" >&2; exit 2; }
    sessions+=("$(cd "$d" && pwd)")
  done
fi
[ ${#sessions[@]} -gt 0 ] || { echo "record: no sessions" >&2; exit 2; }

mkdir -p "$root/tmp"
scratch="$(mktemp -d "$root/tmp/lsp-sessions.XXXXXX")"
trap 'chmod -R u+rwX "$scratch" 2>/dev/null; rm -rf "$scratch"' EXIT

server="${BAYAN_LSP:-}"
if [ -z "$server" ]; then
  build="$root/tmp/lsp-sessions-build"
  echo "record: building bayan-lsp into $build" >&2
  PATH="$HOME/.dotnet:$PATH" DOTNET_ROOT="$HOME/.dotnet" nice dotnet build "$root/editors/language-server/Bayan.LanguageServer.csproj" \
    -c Release -v q -nologo -o "$build" >&2 || { echo "record: build failed" >&2; exit 2; }
  server="$build/bayan-lsp"
fi
[ -x "$server" ] || { echo "record: $server is not executable" >&2; exit 2; }

driver="$(cat <<'PY'
import json, os, shutil, subprocess, sys, threading, urllib.parse

session, scratch, out_path, server = sys.argv[1:5]

def die(msg):
    print(f"record: {os.path.basename(session)}: {msg}", file=sys.stderr)
    sys.exit(2)

ws = os.path.join(scratch, "ws")
if os.path.isdir(os.path.join(session, "workspace")):
    shutil.copytree(os.path.join(session, "workspace"), ws, symlinks=True)
else:
    os.makedirs(ws)
ws_raw = ws
ws = os.path.realpath(ws)
ws_uri = urllib.parse.quote(ws)

def expand(v):
    if isinstance(v, dict):
        if "@repeat" in v: return expand(v["@repeat"]) * v["@times"]
        if "@concat" in v: return "".join(expand(x) for x in v["@concat"])
        return {k: expand(x) for k, x in v.items()}
    if isinstance(v, list): return [expand(x) for x in v]
    if isinstance(v, str): return v.replace("@WS@", ws_uri if v.startswith("file:") else ws)
    return v

def at(rel):
    return os.path.join(ws, rel)

proc = subprocess.Popen(["nice", server], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                        stderr=open(os.path.join(scratch, "stderr"), "wb"), cwd=scratch)
received, answered = [], set()
cond = threading.Condition()

def read():
    out = proc.stdout
    while True:
        length = None
        while True:
            line = out.readline()
            if not line: return
            line = line.strip()
            if not line:
                if length is not None: break
                continue
            k, _, v = line.partition(b":")
            if k.strip().lower() == b"content-length": length = int(v)
        body = out.read(length)
        if len(body) < length: return
        msg = json.loads(body)
        with cond:
            received.append(msg)
            if "method" not in msg and "id" in msg: answered.add(json.dumps(msg["id"]))
            cond.notify_all()

reader = threading.Thread(target=read, daemon=True)
reader.start()

methods, pending = {}, set()
last_was_notification = False
def send(data):
    try:
        proc.stdin.write(data); proc.stdin.flush()
    except BrokenPipeError:
        pass

with open(os.path.join(session, "in.jsonl"), encoding="utf-8") as f:
    for n, line in enumerate(f, 1):
        if not line.strip(): continue
        step = json.loads(line)
        if "fs" in step:
            if last_was_notification: die(f"in.jsonl:{n}: an fs step must follow a request")
            with cond:
                if not cond.wait_for(lambda: pending <= answered or proc.poll() is not None, timeout=600):
                    die(f"in.jsonl:{n}: no answer to {sorted(pending - answered)}")
            op, p = step["fs"], at(step["path"])
            if op == "write":
                os.makedirs(os.path.dirname(p), exist_ok=True)
                with open(p, "w", encoding="utf-8", newline="") as w: w.write(expand(step["text"]))
            elif op == "delete": os.remove(p)
            elif op == "move": os.rename(p, at(step["to"]))
            elif op == "symlink":
                os.makedirs(os.path.dirname(p), exist_ok=True)
                os.symlink(os.path.normpath(at(step["target"])), p)
            elif op == "chmod": os.chmod(p, int(step["mode"], 8))
            else: die(f"in.jsonl:{n}: unknown fs op {op}")
        elif "raw" in step:
            send(step["raw"].encode("utf-8"))
            last_was_notification = True
        else:
            msg = expand(step)
            body = json.dumps(msg, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
            send(b"Content-Length: %d\r\n\r\n" % len(body) + body)
            last_was_notification = "id" not in msg
            if "id" in msg:
                pending.add(json.dumps(msg["id"]))
                methods[json.dumps(msg["id"])] = msg.get("method")

try:
    proc.stdin.close()
except BrokenPipeError:
    pass
try:
    proc.wait(timeout=600)
except subprocess.TimeoutExpired:
    proc.kill(); die("the server did not exit")
reader.join(timeout=60)

def canon(v):
    return json.dumps(v, ensure_ascii=False, separators=(",", ":"))

msgs = []
for m in received:
    if "method" not in m and isinstance(m.get("result"), list) and methods.get(json.dumps(m.get("id"))) == "workspace/symbol":
        m["result"].sort(key=lambda s: canon(s))
    msgs.append(m)
i = 0
while i < len(msgs):
    j = i
    while j < len(msgs) and msgs[j].get("method") == "textDocument/publishDiagnostics": j += 1
    if j > i + 1: msgs[i:j] = sorted(msgs[i:j], key=lambda m: m["params"]["uri"])
    i = max(j, i + 1)

paths = sorted({ws, ws_uri, ws_raw, urllib.parse.quote(ws_raw)}, key=len, reverse=True)
with open(out_path, "w", encoding="utf-8", newline="\n") as out:
    for m in msgs:
        line = canon(m)
        for p in paths: line = line.replace(p, "@WS@")
        out.write(line + "\n")
PY
)"

failed=0
for s in "${sessions[@]}"; do
  name="$(basename "$s")"
  for run in 1 2; do
    mkdir -p "$scratch/$name.$run"
    python3 -I -c "$driver" "$s" "$scratch/$name.$run" "$scratch/$name.$run.out" "$server" || exit 2
  done
  if ! cmp -s "$scratch/$name.1.out" "$scratch/$name.2.out"; then
    echo "record: $name: nondeterministic, two runs differ:" >&2
    diff "$scratch/$name.1.out" "$scratch/$name.2.out" | cut -c1-300 | head -n 10 >&2
    failed=1; continue
  fi
  if [ $check = 1 ]; then
    if cmp -s "$scratch/$name.1.out" "$s/out.jsonl"; then echo "record: $name: same" >&2
    else
      echo "record: $name: differs from out.jsonl:" >&2
      diff "$s/out.jsonl" "$scratch/$name.1.out" | cut -c1-300 | head -n 10 >&2
      failed=1
    fi
  else
    cp "$scratch/$name.1.out" "$s/out.jsonl"
    echo "record: $name: $(wc -l < "$s/out.jsonl" | tr -d ' ') messages" >&2
  fi
done
exit $failed
