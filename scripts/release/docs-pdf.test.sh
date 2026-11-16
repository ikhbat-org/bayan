#!/usr/bin/env bash
# Tests scripts/release/docs-pdf.sh in a throwaway repo with a fake site build and a fake CHROME that records its
# arguments: both PDFs carry the version, --use-mock-keychain is passed, and a missing Chrome is exit 2.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
tmp="$(mktemp -d "${TMPDIR:-/tmp}/docs-pdf-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

repo="$tmp/repo"
mkdir -p "$repo/scripts/release" "$repo/site"
cp "$root/scripts/release/docs-pdf.sh" "$root/scripts/release/version.sh" "$repo/scripts/release/"
printf '1.2.3\n' > "$repo/VERSION"
printf '#!/bin/sh\nmkdir -p "$(dirname "$0")/out"\n: > "$(dirname "$0")/out/manifesto.html"\n: > "$(dirname "$0")/out/book.html"\n' > "$repo/site/build.sh"
printf '#!/bin/sh\necho "$@" >> "%s/calls"\nfor a in "$@"; do case $a in --print-to-pdf=*) : > "${a#--print-to-pdf=}";; esac; done\n' "$tmp" > "$tmp/chrome"
chmod +x "$tmp/chrome"

CHROME="$tmp/chrome" bash "$repo/scripts/release/docs-pdf.sh" > /dev/null || fail "script failed with a fake Chrome"
[ -f "$repo/dist/bayan-manifesto-1.2.3.pdf" ] || fail "no dist/bayan-manifesto-1.2.3.pdf"
[ -f "$repo/dist/bayan-book-1.2.3.pdf" ] || fail "no dist/bayan-book-1.2.3.pdf"
[ "$(wc -l < "$tmp/calls" | tr -d ' ')" = 2 ] || fail "Chrome not run twice: $(cat "$tmp/calls")"
[ "$(grep -c -e '--use-mock-keychain' "$tmp/calls")" = 2 ] || fail "--use-mock-keychain missing: $(cat "$tmp/calls")"
grep -q "file://.*/site/out/book.html" "$tmp/calls" || fail "book.html not printed: $(cat "$tmp/calls")"

out="$(CHROME="$tmp/none" bash "$repo/scripts/release/docs-pdf.sh" 2>&1)" && status=0 || status=$?
[ "$status" = 2 ] || fail "missing Chrome exited $status"
echo "$out" | grep -q CHROME || fail "message does not name CHROME: $out"
echo PASS
