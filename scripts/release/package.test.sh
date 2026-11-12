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

# mkexe <fmt> <machine hex, big-endian as printed by od> <path>: a header-only fake executable.
mkexe() {
  mkdir -p "$(dirname "$3")"
  case "$1" in
    elf) printf '\177ELF\002\001\001\000\000\000\000\000\000\000\000\000\002\000' > "$3"; printf "\\x${2:2:2}\\x${2:0:2}" >> "$3" ;;
    macho) printf '\317\372\355\376' > "$3"; printf "\\x${2:6:2}\\x${2:4:2}\\x${2:2:2}\\x${2:0:2}" >> "$3" ;;
    pe) { printf 'MZ'; head -c 58 /dev/zero; printf '\100\000\000\000'; printf "PE\\0\\0\\x${2:2:2}\\x${2:0:2}"; } > "$3" ;;
    junk) printf 'bin' > "$3" ;;
  esac
}
mkexe macho 0100000c "$t/pub/unix/bayan"; mkexe pe aa64 "$t/pub/win/bayan.exe"
mkexe elf 003e "$t/pub/linux/bayan"
bash "$s" pack osx-arm64 "$t/pub/unix" "$t/out" >/dev/null 2>"$t/warn"
grep -q "::warning::package: the repo has no LICENSE" "$t/warn" || fail "no missing-LICENSE warning: $(cat "$t/warn")"
bash "$s" pack linux-x64 "$t/pub/linux" "$t/out" >/dev/null
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
# The machine guard: each format matching and mismatching, and an unknown format.
for row in "elf 003e linux-x64 linux-arm64" "elf 00b7 linux-arm64 linux-x64" "macho 01000007 osx-x64 osx-arm64" "macho 0100000c osx-arm64 osx-x64" \
  "pe 8664 win-x64 win-arm64" "pe aa64 win-arm64 win-x64"; do
  set -- $row; fmt=$1; mach=$2; good=$3; bad=$4; exe=bayan; case "$fmt" in pe) exe=bayan.exe ;; esac
  mkexe "$fmt" "$mach" "$t/g-$good/$exe"
  bash "$s" pack "$good" "$t/g-$good" "$t/gout" >/dev/null 2>&1 || fail "$good header refused for $good"
  out="$(bash "$s" pack "$bad" "$t/g-$good" "$t/gout" 2>&1)" && fail "$good header accepted for $bad"
  echo "$out" | grep -q "needs" || fail "no machine message for $good header as $bad: $out"
done
mkexe junk x "$t/g-junk/bayan"
out="$(bash "$s" pack linux-x64 "$t/g-junk" "$t/gout" 2>&1)" && fail "an unknown executable format accepted"
echo "$out" | grep -q "is not an ELF, 64-bit Mach-O or PE executable" || fail "no unknown-format message: $out"
out="$(bash "$s" pack freebsd-x64 "$t/pub/unix" "$t/out" 2>&1)" && fail "unknown rid accepted"

bash "$s" sums "$t/out" >/dev/null
[ "$(wc -l < "$t/out/SHA256SUMS" | tr -d ' ')" = 4 ] || fail "SHA256SUMS lines: $(cat "$t/out/SHA256SUMS")"
grep -q " bayan-1.2.3-docs.tar.gz$" "$t/out/SHA256SUMS" || fail "SHA256SUMS lacks the docs archive"
(cd "$t/out" && if command -v sha256sum >/dev/null; then sha256sum -c --quiet SHA256SUMS; else shasum -a 256 -c --quiet SHA256SUMS; fi) || fail "sums do not verify"
mkdir -p "$t/empty"; bash "$s" sums "$t/empty" 2>/dev/null && fail "sums over no archives accepted"

[ "$(bash "$s" notes 1.2.3)" = "$(printf '\n### Added\n- one\n\nKnown limit: the stage-2 build of `selfhost/driver` peaks at 2.94 GB of memory.')" ] || fail "notes: $(bash "$s" notes 1.2.3)"
bash "$s" notes 9.9.9 2>/dev/null && fail "missing CHANGELOG section accepted"

# release.yml builds the shipped bayan as stage 2 and smoke-tests the "(selfhost)" version line (spec 017 R5).
y="$root/.github/workflows/release.yml"
yline() { grep -nxF -m1 -- "$1" "$y" | cut -d: -f1 || true; } # the line number of a whole line, with its indent; empty when absent
l_pub="$(yline '      - name: Publish (NativeAOT)')"; l_pkg="$(yline '      - name: Package')"; l_mg="$(yline '  memory-gate:')"
l_zig="$(yline '        run: bash scripts/ci/install-zig.sh "$RUNNER_TEMP/zig" >> "$GITHUB_PATH"')"
l_s1="$(yline '        run: ./publish/${{ matrix.exe }} build --mode safe --package selfhost -o "$RUNNER_TEMP/stage1-${{ matrix.exe }}" selfhost/driver')"
l_s2="$(yline '          "$RUNNER_TEMP/stage1-${{ matrix.exe }}" build --mode safe --package selfhost -o publish/${{ matrix.exe }} selfhost/driver')"
l_sm="$(yline '        run: ./publish/${{ matrix.exe }} --version | grep -F "bayan ${RELEASE_TAG#v} (selfhost)"')"
[ -n "$l_pub" ] && [ -n "$l_pkg" ] && [ -n "$l_mg" ] || fail "release.yml lacks the Publish or Package step or the memory-gate job"
[ -n "$l_zig" ] && [ "$l_zig" -gt "$l_pub" ] && [ "$l_zig" -lt "$l_mg" ] || fail "release.yml: no Install zig run in the build job after Publish"
[ -n "$l_s1" ] || fail "release.yml lacks the stage 1 build"
[ -n "$l_s2" ] || fail "release.yml lacks the stage 2 build"
[ -n "$l_sm" ] || fail "release.yml smoke test lacks (selfhost)"
[ "$l_zig" -lt "$l_s1" ] && [ "$l_s1" -lt "$l_s2" ] && [ "$l_s2" -lt "$l_sm" ] && [ "$l_sm" -lt "$l_pkg" ] || fail "release.yml: zig, stage 1, stage 2, smoke test and Package are out of order"
grep -qxF -- '    needs: [build, memory-gate, editor-gate, laws]' "$y" || fail "release job no longer needs build, memory-gate, editor-gate and laws"
# The dry run: workflow_dispatch with a version input, one tag value per job, the release job only on a tag push or a non-dry dispatch (which refuse-draft.sh stops).
for line in '  workflow_dispatch:' "      version: { description: 'Dry-run version (e.g. 0.3.0)', required: true }" \
  "      RELEASE_TAG: \${{ github.event_name == 'workflow_dispatch' && format('v{0}', inputs.version) || github.ref_name }}" \
  '        run: bash scripts/release/package.sh check-tag "$RELEASE_TAG"' "    if: github.event_name == 'push' || !inputs.dry_run"; do
  [ -n "$(yline "$line")" ] || fail "release.yml lacks the line: $line"
done
[ "$(yline "    if: github.event_name == 'push' || !inputs.dry_run")" -gt "$(yline '  release:')" ] || fail "the dry-run-aware if: is not in the release job"
! grep -q 'inputs.version' <(grep -v '^      RELEASE_TAG:' "$y" | grep -v 'description:') || fail "release.yml reads inputs.version outside the RELEASE_TAG env"
echo PASS
