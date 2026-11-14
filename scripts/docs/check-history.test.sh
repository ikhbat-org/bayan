#!/usr/bin/env bash
# check-history.sh on a fixture: passes clean, then fails on an uncited revision and on a section with no row.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
t="$root/tmp/docs-history-test"
rm -rf "$t" && mkdir -p "$t"
trap 'rm -rf "$t"' EXIT
s="$root/scripts/docs/check-history.sh"
mkdir -p "$t/clean/revisions"
printf '# 0001 First\n' > "$t/clean/revisions/0001-first.md"
printf '# 0002 Second\n' > "$t/clean/revisions/0002-second.md"
printf '# Revisions\n' > "$t/clean/revisions/README.md"
cat > "$t/clean/spec.md" <<'EOF'
# Spec

## 0. Principles

## 1. Types (not in 0.3)

### 1.1 Not a section

## Appendix A
EOF
cat > "$t/clean/history.md" <<'EOF'
# History

### §0. Principles

- `0001-first.md`: added.

### §1. Types (not in 0.3)

- `0002-second.md`: changed.
EOF
cp -R "$t/clean" "$t/repo"
fail() { echo "FAIL: $1" >&2; exit 1; }
reset() { rm -rf "$t/repo" && cp -R "$t/clean" "$t/repo"; }
run() { bash "$s" "$t/repo/history.md" "$t/repo/spec.md" "$t/repo/revisions"; }
# expect <what> <message fragment>: check-history.sh must fail and print the fragment.
expect() {
  local out
  out="$(run 2>&1)" && fail "$1: check passed"
  echo "$out" | grep -qF "$2" || fail "$1: no '$2' in: $out"
  reset
}

run || fail "clean fixture fails"

printf '# 0003 Third\n' > "$t/repo/revisions/0003-third.md"
expect "uncited revision" "revisions/0003-third.md is not cited in"

printf '\n## 2. Memory\n' >> "$t/repo/spec.md"
expect "missing section" "SPEC section 2 has no row in"

echo PASS
