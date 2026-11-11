#!/usr/bin/env bash
# package.sh on a fixture repo: tag check, archive names and layout per rid (docs under share/doc/bayan/), the docs
# archive, SHA256SUMS, CHANGELOG notes, refusals.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
t="$root/tmp/release-package-test"
rm -rf "$t" && mkdir -p "$t/repo/scripts/release" "$t/repo/docs"
trap 'rm -rf "$t"' EXIT
cp "$root/scripts/release/package.sh" "$root/scripts/release/version.sh" "$t/repo/scripts/release/"
s="$t/repo/scripts/release/package.sh"
fail() { echo "FAIL: $1" >&2; exit 1; }
setv() { printf '%s\n' "$1" > "$t/repo/VERSION"; }
setv 1.2.3
echo readme > "$t/repo/README.md"
for d in bayan-spec bayan-grammar bayan-style DIAGNOSTICS STATUS; do echo "$d" > "$t/repo/docs/$d.md"; done
docs=" share/ share/doc/ share/doc/bayan/ share/doc/bayan/CHANGELOG.md share/doc/bayan/DIAGNOSTICS.md share/doc/bayan/GRAMMAR.md"
docs="$docs share/doc/bayan/SPEC.md share/doc/bayan/STATUS.md share/doc/bayan/STYLE.md"
printf '# Changelog\n\n## [Unreleased]\n\n## [1.2.3] - 2026-11-02\n\n### Added\n- one\n\n## [1.2.2]\n- old\n' > "$t/repo/CHANGELOG.md"

[ "$(bash "$s" check-tag v1.2.3)" = 1.2.3 ] || fail "matching tag refused"
out="$(bash "$s" check-tag v1.2.4 2>&1)" && fail "wrong tag accepted"
echo "$out" | grep -q "does not match VERSION 1.2.3" || fail "no mismatch message: $out"
setv 1.3.0-dev
out="$(bash "$s" check-tag v1.3.0-dev 2>&1)" && fail "prerelease version accepted"
echo "$out" | grep -q "is a prerelease" || fail "no prerelease message: $out"
setv x
out="$(bash "$s" check-tag v1.2.3 2>&1)" && fail "malformed VERSION accepted"
echo "$out" | grep -q "VERSION holds 'x'" || fail "no malformed-VERSION message: $out"
setv 1.2.3

mkdir -p "$t/pub/unix" "$t/pub/win"
printf 'bin' > "$t/pub/unix/bayan"; printf 'exe' > "$t/pub/win/bayan.exe"
bash "$s" pack osx-arm64 "$t/pub/unix" "$t/out" >/dev/null 2>"$t/warn"
grep -q "::warning::package: the repo has no LICENSE" "$t/warn" || fail "no missing-LICENSE warning: $(cat "$t/warn")"
bash "$s" pack linux-x64 "$t/pub/unix" "$t/out" >/dev/null
bash "$s" pack win-arm64 "$t/pub/win" "$t/out" >/dev/null
[ -f "$t/out/bayan-1.2.3-macos-arm64.tar.gz" ] && [ -f "$t/out/bayan-1.2.3-linux-x64.tar.gz" ] || fail "tar.gz names wrong: $(ls "$t/out")"
[ -f "$t/out/bayan-1.2.3-windows-arm64.zip" ] || fail "zip name wrong: $(ls "$t/out")"
layout() { local p="$1" e w=""; shift; for e in "" "$@"; do w="$w$p/$e "; done; printf '%s' "$w"; }
[ "$(tar -tzf "$t/out/bayan-1.2.3-macos-arm64.tar.gz" | LC_ALL=C sort | tr '\n' ' ')" = "$(layout bayan-1.2.3-macos-arm64 README.md bayan $docs)" ] \
  || fail "tar layout: $(tar -tzf "$t/out/bayan-1.2.3-macos-arm64.tar.gz")"
unzip -l "$t/out/bayan-1.2.3-windows-arm64.zip" > "$t/zip-list"
grep -q "bayan-1.2.3-windows-arm64/bayan.exe" "$t/zip-list" || fail "zip lacks the exe"
grep -q "bayan-1.2.3-windows-arm64/share/doc/bayan/STATUS.md" "$t/zip-list" || fail "zip lacks the docs"
[ "$(tar -xzOf "$t/out/bayan-1.2.3-linux-x64.tar.gz" bayan-1.2.3-linux-x64/share/doc/bayan/SPEC.md)" = bayan-spec ] || fail "SPEC.md is not docs/bayan-spec.md"
bash "$s" docs "$t/out" >/dev/null
[ "$(tar -tzf "$t/out/bayan-1.2.3-docs.tar.gz" | LC_ALL=C sort | tr '\n' ' ')" = "$(layout bayan-1.2.3-docs $docs)" ] \
  || fail "docs archive layout: $(tar -tzf "$t/out/bayan-1.2.3-docs.tar.gz")"
[ "$(tar -xzOf "$t/out/bayan-1.2.3-docs.tar.gz" bayan-1.2.3-docs/share/doc/bayan/CHANGELOG.md)" = "$(cat "$t/repo/CHANGELOG.md")" ] || fail "docs archive CHANGELOG.md"
[ -z "$(ls -A "$t/out" | grep '^\.stage' || true)" ] || fail "staging left behind"
mv "$t/repo/docs/STATUS.md" "$t/STATUS.md"
out="$(bash "$s" docs "$t/out2" 2>&1)" && fail "missing doc accepted"
echo "$out" | grep -q "docs/STATUS.md not found" || fail "no missing-doc message: $out"
mv "$t/STATUS.md" "$t/repo/docs/STATUS.md"
out="$(bash "$s" pack win-x64 "$t/pub/unix" "$t/out" 2>&1)" && fail "missing exe accepted"
echo "$out" | grep -q "bayan.exe not found" || fail "no missing-exe message: $out"
out="$(bash "$s" pack freebsd-x64 "$t/pub/unix" "$t/out" 2>&1)" && fail "unknown rid accepted"

bash "$s" sums "$t/out" >/dev/null
[ "$(wc -l < "$t/out/SHA256SUMS" | tr -d ' ')" = 4 ] || fail "SHA256SUMS lines: $(cat "$t/out/SHA256SUMS")"
grep -q " bayan-1.2.3-docs.tar.gz$" "$t/out/SHA256SUMS" || fail "SHA256SUMS lacks the docs archive"
(cd "$t/out" && if command -v sha256sum >/dev/null; then sha256sum -c --quiet SHA256SUMS; else shasum -a 256 -c --quiet SHA256SUMS; fi) || fail "sums do not verify"
mkdir -p "$t/empty"; bash "$s" sums "$t/empty" 2>/dev/null && fail "sums over no archives accepted"

[ "$(bash "$s" notes 1.2.3)" = "$(printf '\n### Added\n- one\n')" ] || fail "notes: $(bash "$s" notes 1.2.3)"
bash "$s" notes 9.9.9 2>/dev/null && fail "missing CHANGELOG section accepted"
echo PASS
