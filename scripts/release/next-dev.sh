#!/usr/bin/env bash
# Opens development of <X.Y.Z> after a release (docs/RELEASING.md): VERSION, its mirrors and every header become
# X.Y.Z-dev (set-version.sh) and docs/DIAGNOSTICS.md, docs/STATUS.md and docs/specs/README.md are regenerated. Edits files only, never
# commits, tags or pushes; prints each file it changed.
#   next-dev.sh <X.Y.Z>
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
die() { echo "next-dev: $*" >&2; exit 1; }

v="${1:?usage: next-dev.sh <X.Y.Z>}"
echo "$v" | grep -Eqx '[0-9]+\.[0-9]+\.[0-9]+' || die "'$v' is not X.Y.Z"
t="$(mktemp)"; trap 'rm -f "$t"' EXIT

bash "$root/scripts/release/set-version.sh" "$v-dev"
for g in diagnostics:docs/DIAGNOSTICS.md status:docs/STATUS.md spec-index:docs/specs/README.md; do
  doc="${g#*:}"; cp "$root/$doc" "$t"
  bash "$root/scripts/docs/gen-${g%%:*}.sh" --write
  cmp -s "$t" "$root/$doc" || echo "changed $doc"
done
