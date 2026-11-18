#!/usr/bin/env bash
# Tests scripts/release/editor-gate.sh with a stub bayan (BAYAN_EXE), python3 (the session replay), npm and npx: it builds
# bayan-lsp, runs its bound blocks and replays its sessions with no dotnet call, packages the extension, names every
# failure, refuses pending or missing bound blocks and an oversize .vsix, and release.yml's `release` job needs the gate.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
gate="$root/scripts/release/editor-gate.sh"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/editor-gate-test.XXXXXX")"; mkdir -p "$tmp/bin"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

# dotnet must not be called: the stub only logs.
printf '#!/bin/bash\necho "dotnet $*" >> "$LOG"\nexit 0\n' > "$tmp/bin/dotnet"
# bayan: `build` writes an executable to the -o path; `test` prints a summary (PENDING: one pending, NONE: none passed).
cat > "$tmp/bin/bayan" <<'STUB'
#!/bin/bash
echo "bayan $*" >> "$LOG"
[ "${FAIL_ON:-}" = "bayan-$1" ] && exit 1
if [ "$1" = build ]; then
  while [ $# -gt 0 ]; do [ "$1" = -o ] && { printf '#!/bin/sh\n' > "$2"; chmod +x "$2"; }; shift; done
elif [ -n "${PENDING:-}" ]; then echo "◆ 21 passed · 0 failed · 1 pending · 1s"
elif [ -n "${NONE:-}" ]; then echo "◆ 0 passed · 0.00s"
else echo "◆ 22 passed · 0 failed · 0 pending · 1s"; fi
exit 0
STUB
# python3 runs record.sh's session driver: -I -c <driver> <session> <scratch> <out> <server>; the stub copies the recorded output.
cat > "$tmp/bin/python3" <<'STUB'
#!/bin/bash
echo "python3 server=$7" >> "$LOG"
[ "${FAIL_ON:-}" = python3 ] && exit 1
cp "$4/out.jsonl" "$6"
STUB
printf '#!/bin/bash\necho "npm $*" >> "$LOG"\n[ "${FAIL_ON:-}" = npm ] && exit 1\nexit 0\n' > "$tmp/bin/npm"
# npx writes a .vsix of VSIX_BYTES bytes to the -o path.
cat > "$tmp/bin/npx" <<'STUB'
#!/bin/bash
echo "npx $*" >> "$LOG"
[ "${FAIL_ON:-}" = npx ] && exit 1
while [ $# -gt 0 ]; do [ "$1" = -o ] && { head -c "${VSIX_BYTES:-100}" /dev/zero > "$2"; }; shift; done
exit 0
STUB
chmod +x "$tmp/bin/"*
export LOG="$tmp/log" PATH="$tmp/bin:$PATH" BAYAN_EXE="$tmp/bin/bayan"

: > "$LOG"; FAIL_ON= bash "$gate" > "$tmp/out" 2> "$tmp/err" || fail "an all-pass gate exited non-zero: $(cat "$tmp/err")"
grep -qx "editor-gate: PASS" "$tmp/out" || fail "no PASS"
grep -q '^bayan build --package editors/language-server/src -o .*/bayan-lsp editors/language-server/src/app$' "$LOG" \
  || fail "bayan-lsp was not built: $(cat "$LOG")"
grep -qx 'bayan test --package editors/language-server/src editors/language-server/src/bounds' "$LOG" \
  || fail "the bound blocks did not run: $(cat "$LOG")"
grep -q '^python3 server=.*/bayan-lsp$' "$LOG" || fail "the sessions were not replayed against the built bayan-lsp"
if grep -q '^dotnet' "$LOG"; then fail "the gate called dotnet: $(grep '^dotnet' "$LOG")"; fi
grep -q 'dotnet' "$gate" && fail "editor-gate.sh still names dotnet"
grep -Eq '^npx --yes @vscode/vsce@[0-9]+\.[0-9]+\.[0-9]+ package' "$LOG" || fail "the extension was not packaged"

: > "$LOG"; if FAIL_ON=bayan-test bash "$gate" > "$tmp/out" 2> "$tmp/err"; then fail "failing bound blocks passed"; fi
grep -q "FAILED: .*bayan test --package editors/language-server/src editors/language-server/src/bounds" "$tmp/err" \
  || fail "the bound block failure was not named: $(cat "$tmp/err")"
grep -q '^npx' "$LOG" || fail "a bound block failure stopped the packaging"
if FAIL_ON=bayan-build bash "$gate" > /dev/null 2> "$tmp/err"; then fail "a failing bayan-lsp build passed"; fi
grep -q "FAILED: .*bayan build --package" "$tmp/err" || fail "the build failure was not named"
if FAIL_ON=python3 bash "$gate" > /dev/null 2> "$tmp/err"; then fail "a failing session replay passed"; fi
grep -q "FAILED: env BAYAN_LSP=.* bash editors/language-server/sessions/record.sh --check" "$tmp/err" \
  || fail "the session replay failure was not named: $(cat "$tmp/err")"
if PENDING=1 FAIL_ON= bash "$gate" > /dev/null 2> "$tmp/err"; then fail "pending bound blocks passed"; fi
grep -q "bound blocks reported pending" "$tmp/err" || fail "pending bound blocks were not named"
if NONE=1 FAIL_ON= bash "$gate" > /dev/null 2> "$tmp/err"; then fail "a bound run with none passed passed"; fi
grep -q "bound blocks did not run" "$tmp/err" || fail "a bound run with none passed was not named"
if FAIL_ON=npx bash "$gate" > /dev/null 2> "$tmp/err"; then fail "a failing vsce package passed"; fi
grep -q "FAILED: npx --yes @vscode/vsce@" "$tmp/err" || fail "the vsce failure was not named"
if FAIL_ON=npm bash "$gate" > /dev/null 2> "$tmp/err"; then fail "a failing npm ci passed"; fi
if VSIX_BYTES=5000 VSIX_MAX_BYTES=1000 FAIL_ON= bash "$gate" > /dev/null 2> "$tmp/err"; then fail "an oversize .vsix passed"; fi
grep -q "vsix size 5000 > 1000" "$tmp/err" || fail "the size failure was not named: $(cat "$tmp/err")"
VSIX_BYTES=1000 VSIX_MAX_BYTES=1000 FAIL_ON= bash "$gate" > /dev/null 2>&1 || fail "a .vsix at the bound was refused"

grep -Eq '^vsce=[0-9]+\.[0-9]+\.[0-9]+( |$)' "$gate" || fail "editor-gate.sh does not pin vsce to an exact version"

# Wiring: editor-gate.yml runs the script on push to dev and as a workflow_call; release.yml calls it and `release` needs it.
g="$root/.github/workflows/editor-gate.yml"; wf="$root/.github/workflows/release.yml"
grep -qE '^ +run: bash scripts/release/editor-gate.sh$' "$g" || fail "editor-gate.yml does not run editor-gate.sh"
grep -q 'branches: \[dev\]' "$g" || fail "editor-gate.yml does not run on push to dev"
grep -q 'workflow_call:' "$g" || fail "editor-gate.yml is not callable"
grep -q 'uses: ./.github/workflows/editor-gate.yml' "$wf" || fail "release.yml does not call editor-gate.yml"
awk '/^  release:/{r=1} r&&/needs:/{print; exit}' "$wf" | grep -q 'editor-gate' || fail "release.yml's release job does not need editor-gate"
echo PASS
