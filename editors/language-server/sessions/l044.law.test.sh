#!/usr/bin/env bash
# L044: for every recorded session here, the replies of the Bayan bayan-lsp equal out.jsonl, message for message.
#   bash editors/language-server/sessions/l044.law.test.sh
# BAYAN_EXE  the self-hosted compiler; unset, scripts/bootstrap-build.sh builds it from bootstrap/ with a C compiler.
# BAYAN_LSP  a built bayan-lsp; unset, it is built from editors/language-server/src with BAYAN_EXE.
# The sessions are the directories here that hold an in.jsonl, so a new session is covered. Each is replayed with
# record.sh --check; a failure prints the session and the first message that differs, is missing or is extra.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
cd "$root"
mkdir -p tmp; tmp="$(mktemp -d "$root/tmp/l044.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

if [ -z "${BAYAN_LSP:-}" ]; then
  if [ -z "${BAYAN_EXE:-}" ]; then BAYAN_EXE="$(bash scripts/bootstrap-build.sh)" || { echo "L044: bootstrap build failed" >&2; exit 2; }; fi
  "$BAYAN_EXE" build --package editors/language-server/src -o "$tmp/bayan-lsp" editors/language-server/src/app >&2 \
    || { echo "L044: building bayan-lsp failed" >&2; exit 2; }
  BAYAN_LSP="$tmp/bayan-lsp"
fi
export BAYAN_LSP

total=0; failed=0
for d in "$here"/*/; do
  [ -f "$d/in.jsonl" ] || continue
  name="$(basename "$d")"; total=$((total + 1))
  if ! bash "$here/record.sh" --check "$name" > "$tmp/log" 2>&1; then
    failed=$((failed + 1))
    first="$(grep -m1 -E '^[0-9]+([,a-z0-9]*)[acd][0-9]' "$tmp/log" || true)"
    echo "L044 counterexample: session $name: first difference at message (diff line range) ${first:-unknown}" >&2
    cat "$tmp/log" >&2
  fi
done
[ "$total" -gt 0 ] || { echo "L044: no sessions found under $here" >&2; exit 1; }
[ "$failed" -eq 0 ] || { echo "L044: $failed of $total sessions differ" >&2; exit 1; }
echo "L044: $total of $total sessions same"
