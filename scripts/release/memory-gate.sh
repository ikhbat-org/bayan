#!/usr/bin/env bash
# The memory and disk release gate of docs/memory-leaks.md, run by .github/workflows/release.yml before any release
# is drafted. The VS Code extension and bayan-lsp are gated by scripts/release/editor-gate.sh, run by
# .github/workflows/editor-gate.yml on every push to dev and by release.yml before a release: no manual step.
# Every command in the doc's *Release gate* block runs here; memory-gate.test.sh fails when the two drift apart.
# Exit 0 only when all of them pass; every failing command is named.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
failed=()
run() { echo "memory-gate: $*" >&2; "$@" || failed+=("$*"); }

run dotnet test -v q --filter "FullyQualifiedName~LanguageServer"
run dotnet test -v q --filter "FullyQualifiedName~CliMemoryBounds"
run dotnet test -v q --filter "FullyQualifiedName~SelfhostDefaultBounds"
run bash scripts/pinned-bayan.test.sh

if [ ${#failed[@]} -gt 0 ]; then
  printf 'memory-gate: FAILED: %s\n' "${failed[@]}" >&2
  exit 1
fi
echo "memory-gate: PASS"
