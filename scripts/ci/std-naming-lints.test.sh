#!/usr/bin/env bash
# Ported from NamingPackageGrammarTests.StdSourcesHaveOnlyTheKnownNamingLintHits (spec 019 T27): user builds skip the standard library
# for BYN5104 to BYN5107 (Q1191); `bayan check` of each lib/std directory with a .byn file, compiled as an ordinary package where they
# run, has exactly the hits Q1191 exempts: std.json's `JsonReader` reads with `next` (BYN5106). A new hit, or an exemption that is
# gone, fails with the hit named.
# BAYAN_EXE: the self-hosted driver; unset, bootstrap/bayan.c is built with cc into tmp/. bash 3.2, no dotnet.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
fail() { echo "FAIL $1"; exit 1; }
bayan="${BAYAN_EXE:-}"
if [ -z "$bayan" ]; then
  bayan="$root/tmp/std-naming-lints-bayan"
  cc -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off -w bootstrap/bayan.c bootstrap/bayan-rt.c -lm -o "$bayan" || fail "cannot build bootstrap/bayan.c"
fi
known="BYN5106 lib/std/json/reader.byn JsonReader"
n=0; hits=""
while IFS= read -r d; do
  ls "$d"/*.byn >/dev/null 2>&1 || continue
  n=$((n + 1))
  # `--diagnostics json` lines: code, file (absolute) and the name between the message's first backticks
  hits="$hits$("$bayan" check --diagnostics json "$d" 2>&1 | grep -E '^\{"code":"BYN510[4-7]"' \
    | sed -E 's/^\{"code":"([^"]*)".*"file":"([^"]*)".*"message":"[^`]*`([^`]*)`.*$/\1 \2 \3/' | sed "s# $root/# #" || true)
"
done < <(find lib/std -type d | LC_ALL=C sort)
[ "$n" -gt 0 ] || fail "no directory under lib/std holds a .byn file"
actual="$(printf '%s' "$hits" | grep -v '^$' | LC_ALL=C sort || true)"
[ "$actual" = "$known" ] || fail "std-sources-have-only-the-known-naming-lint-hits: expected [$known], found [$(tr '\n' ';' <<<"$actual")]"
echo "std-naming-lints: ok ($n directories)"
