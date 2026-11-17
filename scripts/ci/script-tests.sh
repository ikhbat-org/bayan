#!/usr/bin/env bash
# The ci job's script tests, one list for .github/workflows/ci.yml and for the run before a push, so the two cannot drift.
#   bash scripts/ci/script-tests.sh [unix] [docs]   (no group: both; `list` prints the files)
# unix: every non-Windows job runs it; docs: the Linux job. Each test runs under the bash running this script, so
# `/bin/bash scripts/ci/script-tests.sh` on macOS is the macOS job's bash 3.2. Every test runs; exit 1 names the failures.
set -uo pipefail
cd "$(dirname "$0")/../.."
unix=(scripts/ci/bash32-parse.test.sh scripts/ci/install-zig.test.sh scripts/ci/install-dotnet.test.sh
  scripts/ci/sdk-patch-check.test.sh scripts/ci/known-failures.test.sh scripts/ci/script-tests.test.sh scripts/ci/pre-push.test.sh
  scripts/release/package.test.sh scripts/release/docs-pdf.test.sh scripts/release/memory-gate.test.sh scripts/release/editor-gate.test.sh
  scripts/release/refuse-draft.test.sh scripts/release/release-workflow.test.sh scripts/bayan-tool.test.sh
  scripts/parity/run.test.sh scripts/sabk/record-encodings.test.sh scripts/sabk/record-macho.test.sh)
docs=(scripts/release/set-version.test.sh scripts/release/cut.test.sh scripts/docs/*.test.sh scripts/docs/check.sh)
groups=("$@"); [ ${#groups[@]} -gt 0 ] || groups=(unix docs)
run=()
for g in "${groups[@]}"; do
  case "$g" in
    (unix) run+=("${unix[@]}") ;;
    (docs) run+=("${docs[@]}") ;;
    (list) printf '%s\n' "${unix[@]}" "${docs[@]}"; exit 0 ;;
    (*) echo "script-tests: unknown group '$g' (unix, docs)" >&2; exit 2 ;;
  esac
done
failed=()
for t in "${run[@]}"; do
  echo "== $t"
  "$BASH" "$t" || failed+=("$t")
done
[ ${#failed[@]} = 0 ] && { echo "script-tests: ${#run[@]} passed (bash $BASH_VERSION)"; exit 0; }
printf 'script-tests: FAILED %s\n' "${failed[@]}"; exit 1
