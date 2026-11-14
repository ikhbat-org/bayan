#!/usr/bin/env bash
# The memory gate of the editor products, run by .github/workflows/editor-gate.yml on every push to dev and before a
# release (release.yml's `release` job needs it). The VS Code extension cannot be exercised headless on a runner, so:
#   - bayan-lsp (editors/language-server) runs its memory-bound tests: dotnet test --filter FullyQualifiedName~LanguageServer;
#   - the extension is packaged (npm ci, vsce package) and the .vsix must stay under VSIX_MAX_BYTES (default 2 MiB).
# Exit 0 only when both pass; every failing step is named.
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
vsce=4.1.0  # exact: the packager is not part of the lockfile
max="${VSIX_MAX_BYTES:-2097152}"
failed=()
run() { echo "editor-gate: $*" >&2; "$@" || failed+=("$*"); }

cd "$root"
run dotnet test -v q --filter "FullyQualifiedName~LanguageServer"

out="$(mktemp -d)"; trap 'rm -rf "$out"' EXIT
cd "$root/editors/vscode"
run npm ci --ignore-scripts
run npx --yes @vscode/vsce@$vsce package -o "$out/bayan.vsix"
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
