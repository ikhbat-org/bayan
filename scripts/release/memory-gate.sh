#!/usr/bin/env bash
# The memory and disk release gate of docs/memory-leaks.md, run by .github/workflows/release.yml before any release
# is drafted. The VS Code extension and bayan-lsp are gated by scripts/release/editor-gate.sh, run by
# .github/workflows/editor-gate.yml on every push to dev and by release.yml before a release: no manual step.
# Every command in the doc's *Release gate* block runs here; memory-gate.test.sh fails when the two drift apart.
# Exit 0 only when all of them pass; every failing command is named.
# BAYAN_EXE  the self-hosted driver the golden runner bound runs; unset, the gate builds src/driver with the pinned bayan
#            (PINNED_BAYAN_REF, default HEAD: the commit being released) into tmp/memory-gate/.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."
failed=()
mkdir -p tmp/memory-gate; log="$(mktemp tmp/memory-gate/out.XXXXXX)"
trap 'rm -f "$log"' EXIT
run() { echo "memory-gate: $*" >&2; "$@" | tee "$log" || failed+=("$*"); }

if [ -z "${BAYAN_EXE:-}" ]; then
  BAYAN_EXE="$PWD/tmp/memory-gate/bayan"
  echo "memory-gate: building src/driver into $BAYAN_EXE" >&2
  pinned="$(PINNED_BAYAN_REF="${PINNED_BAYAN_REF:-HEAD}" bash scripts/pinned-bayan.sh)" \
    && "$pinned" build --mode safe --package src -o "$BAYAN_EXE" src/driver || failed+=("build of src/driver for BAYAN_EXE")
fi
export BAYAN_EXE # the golden runner bound reads the driver path from it

run "$BAYAN_EXE" test --package editors/language-server/src editors/language-server/src/bounds
# The bayan-lsp bound blocks are pending only on Windows; anywhere else pending, or none passing, means they did not run.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) if grep -qE '(^|[^0-9])[1-9][0-9]* pending' "$log"; then failed+=("bayan-lsp bound blocks reported pending")
     elif grep -qE '(^|[^0-9])0 passed' "$log"; then failed+=("bayan-lsp bound blocks did not run (none passed)"); fi ;;
esac
run "$BAYAN_EXE" test --package src src/driver --only 'bound: '
# The bound blocks of src/driver/bounds.byn are pending only on Windows; anywhere else none passing means they did not run.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *) if grep -qE '(^|[^0-9])0 passed' "$log"; then failed+=("the bound: blocks did not run (none passed)"); fi ;;
esac
run "$BAYAN_EXE" test tests/cases --only cli/SelfhostDefaultT12Tests/TheInputsHashDoesNotFollowLinks
# The selector also selects TheInputsHashDoesNotFollowLinks-2 (`--only` matches by substring): both cases must have passed.
grep -qE '(^|[^0-9])2 passed' "$log" || failed+=("the T12 inputs-hash cases did not both pass")
run bash scripts/pinned-bayan.test.sh
run env BAYAN_TEST_TIMEOUT_MS=600000 "$BAYAN_EXE" test --package src src/driver --only 'a run over tests/cases keeps the runner and each worker under 15 MB and leaves no scratch directory'
# The block is pending only on Windows (no sh or ps); anywhere else pending, or a title that selects nothing, means it did
# not run, which must not pass.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;
  *)
    if grep -qF '(pending)' "$log"; then failed+=("the golden runner bound reported pending")
    elif ! grep -qE '(^|[^0-9])1 passed' "$log"; then failed+=("the golden runner bound did not run (no test matched)")
    fi ;;
esac

if [ ${#failed[@]} -gt 0 ]; then
  printf 'memory-gate: FAILED: %s\n' "${failed[@]}" >&2
  exit 1
fi
echo "memory-gate: PASS"
