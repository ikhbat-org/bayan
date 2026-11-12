#!/usr/bin/env bash
# Tests scripts/release/editor-gate.sh with stub dotnet, npm and npx: it runs the LanguageServer tests and packages the
# extension, names every failure, refuses an oversize .vsix, and release.yml's `release` job needs the gate.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
gate="$root/scripts/release/editor-gate.sh"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/editor-gate-test.XXXXXX")"; mkdir -p "$tmp/bin"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }

cat > "$tmp/bin/dotnet" <<'STUB'
#!/bin/bash
echo "dotnet $*" >> "$LOG"
[ "${FAIL_ON:-}" = dotnet ] && exit 1
exit 0
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
export LOG="$tmp/log" PATH="$tmp/bin:$PATH"

: > "$LOG"; FAIL_ON= bash "$gate" > "$tmp/out" 2> "$tmp/err" || fail "an all-pass gate exited non-zero: $(cat "$tmp/err")"
grep -qx "editor-gate: PASS" "$tmp/out" || fail "no PASS"
grep -qx 'dotnet test -v q --filter FullyQualifiedName~LanguageServer' "$LOG" || fail "the LanguageServer tests did not run: $(cat "$LOG")"
grep -q '^npx --yes @vscode/vsce package' "$LOG" || fail "the extension was not packaged"

: > "$LOG"; if FAIL_ON=dotnet bash "$gate" > "$tmp/out" 2> "$tmp/err"; then fail "failing LanguageServer tests passed"; fi
grep -q "FAILED: dotnet test" "$tmp/err" || fail "the dotnet failure was not named"
grep -q '^npx' "$LOG" || fail "a dotnet failure stopped the packaging"
if FAIL_ON=npx bash "$gate" > /dev/null 2> "$tmp/err"; then fail "a failing vsce package passed"; fi
grep -q "FAILED: npx --yes @vscode/vsce package" "$tmp/err" || fail "the vsce failure was not named"
if FAIL_ON=npm bash "$gate" > /dev/null 2> "$tmp/err"; then fail "a failing npm ci passed"; fi
if VSIX_BYTES=5000 VSIX_MAX_BYTES=1000 FAIL_ON= bash "$gate" > /dev/null 2> "$tmp/err"; then fail "an oversize .vsix passed"; fi
grep -q "vsix size 5000 > 1000" "$tmp/err" || fail "the size failure was not named: $(cat "$tmp/err")"
VSIX_BYTES=1000 VSIX_MAX_BYTES=1000 FAIL_ON= bash "$gate" > /dev/null 2>&1 || fail "a .vsix at the bound was refused"

# Wiring: editor-gate.yml runs the script on push to dev and as a workflow_call; release.yml calls it and `release` needs it.
g="$root/.github/workflows/editor-gate.yml"; wf="$root/.github/workflows/release.yml"
grep -qE '^ +run: bash scripts/release/editor-gate.sh$' "$g" || fail "editor-gate.yml does not run editor-gate.sh"
grep -q 'branches: \[dev\]' "$g" || fail "editor-gate.yml does not run on push to dev"
grep -q 'workflow_call:' "$g" || fail "editor-gate.yml is not callable"
grep -q 'uses: ./.github/workflows/editor-gate.yml' "$wf" || fail "release.yml does not call editor-gate.yml"
awk '/^  release:/{r=1} r&&/needs:/{print; exit}' "$wf" | grep -q 'editor-gate' || fail "release.yml's release job does not need editor-gate"
echo PASS
