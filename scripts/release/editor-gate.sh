#!/usr/bin/env bash
# The memory gate of the editor products, run by .github/workflows/editor-gate.yml on every push to dev and before a
# release (release.yml's `release` job needs it). The VS Code extension cannot be exercised headless on a runner, so:
#   - bayan-lsp (editors/language-server) is built with the self-hosted compiler, runs its memory-bound test blocks
#     (src/bounds) and replays its recorded sessions (sessions/record.sh --check); no .NET;
#   - the extension is packaged (npm ci, vsce package) and the .vsix must stay under VSIX_MAX_BYTES (default 2 MiB).
# Exit 0 only when both pass; every failing step is named.
# BAYAN_EXE  the self-hosted compiler; unset, scripts/bootstrap-build.sh builds it from bootstrap/ with a C compiler.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
max="${VSIX_MAX_BYTES:-2097152}"
failed=()
run() { echo "editor-gate: $*" >&2; "$@" || failed+=("$*"); }

out="$(mktemp -d)"; trap 'rm -rf "$out"' EXIT
cd "$root"
if [ -z "${BAYAN_EXE:-}" ]; then
  echo "editor-gate: building the self-hosted compiler (scripts/bootstrap-build.sh)" >&2
  BAYAN_EXE="$(bash scripts/bootstrap-build.sh)" || failed+=("bash scripts/bootstrap-build.sh")
fi
if [ -n "${BAYAN_EXE:-}" ]; then
  lsp=editors/language-server
  run "$BAYAN_EXE" build --package "$lsp/src" -o "$out/bayan-lsp" "$lsp/src/app"
  # The bound blocks that read the resident set are pending only on Windows; anywhere else pending means they did not run.
  echo "editor-gate: $BAYAN_EXE test --package $lsp/src $lsp/src/bounds" >&2
  "$BAYAN_EXE" test --package "$lsp/src" "$lsp/src/bounds" | tee "$out/bounds.log" || failed+=("$BAYAN_EXE test --package $lsp/src $lsp/src/bounds")
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) ;;
    *) grep -qE '(^|[^0-9])[1-9][0-9]* pending' "$out/bounds.log" && failed+=("bayan-lsp bound blocks reported pending")
       grep -qE '(^|[^0-9])0 passed' "$out/bounds.log" && failed+=("bayan-lsp bound blocks did not run (none passed)") ;;
  esac
  if [ -x "$out/bayan-lsp" ]; then
    run env BAYAN_LSP="$out/bayan-lsp" bash "$lsp/sessions/record.sh" --check
  fi
fi

cd "$root/editors/vscode"
run npm ci --ignore-scripts
run npx --no-install vsce package -o "$out/bayan.vsix"
if [ -f "$out/bayan.vsix" ]; then
  size="$(wc -c < "$out/bayan.vsix" | tr -d ' ')"
  echo "editor-gate: bayan.vsix is $size bytes (bound $max)" >&2
  [ "$size" -le "$max" ] || failed+=("vsix size $size > $max")
else
  failed+=("vsce package made no .vsix")
fi

if [ ${#failed[@]} -gt 0 ]; then
  printf 'editor-gate: FAILED: %s\n' "${failed[@]}" >&2
  exit 1
fi
echo "editor-gate: PASS"
