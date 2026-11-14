#!/usr/bin/env bash
# Guard (i), plan 016: every docs/revisions/NNNN-*.md is cited by file name in the feature history,
# and every numbered SPEC section (`## N.`) has a `### §N.` row there. One line per problem; exit 1 on any.
# Usage: check-history.sh [history] [spec] [revisions-dir]
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
history="${1:-$root/docs/bayan-feature-history.md}"
spec="${2:-$root/docs/bayan-spec.md}"
revisions="${3:-$root/docs/revisions}"
rel() { echo "${1#"$root"/}"; }
bad=0

for f in "$revisions"/[0-9][0-9][0-9][0-9]-*.md; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  if ! grep -qF "$name" "$history"; then
    echo "$(rel "$f") is not cited in $(rel "$history")"
    bad=1
  fi
done

while read -r n; do
  if ! grep -qE "^### §$n\. " "$history"; then
    echo "SPEC section $n has no row in $(rel "$history")"
    bad=1
  fi
done < <(sed -nE 's/^## ([0-9]+)\. .*/\1/p' "$spec")

exit "$bad"
