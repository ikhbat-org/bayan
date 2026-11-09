#!/usr/bin/env bash
# Compiler release packaging, run by .github/workflows/release.yml (decision 2026-11-02: GitHub Release per v* tag).
#   package.sh check-tag <tag>                  exit 0 when <tag> is v + VERSION
#   package.sh pack <rid> <publish-dir> <out>   <out>/bayan-<version>-<target>.tar.gz (.zip for Windows), the binary
#                                               inside a bayan-<version>-<target>/ folder with README.md, the docs
#                                               under share/doc/bayan/ (and LICENSE, warning when the repo has none)
#   package.sh docs <out>                       <out>/bayan-<version>-docs.tar.gz, the docs under
#                                               bayan-<version>-docs/share/doc/bayan/
#   package.sh sums <dir>                       <dir>/SHA256SUMS over every archive in <dir>
#   package.sh notes <version>                  the CHANGELOG.md section `## [<version>]`, heading excluded
# Targets use bayan's own names (bayan dist): osx-arm64 -> macos-arm64, win-x64 -> windows-x64.
# The docs (docs/RELEASING.md): SPEC, GRAMMAR, STYLE, DIAGNOSTICS, STATUS and CHANGELOG, as <NAME>.md.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$root/scripts/release/version.sh"
die() { echo "package: $*" >&2; exit 1; }
version() { bayan_version "$root" 2>/dev/null || true; }

# docs <dir>: the shipped docs into <dir>/share/doc/bayan/.
docs() {
  local d="$1/share/doc/bayan" pair
  mkdir -p "$d"
  for pair in SPEC:docs/bayan-spec.md GRAMMAR:docs/bayan-grammar.md STYLE:docs/bayan-style.md \
    DIAGNOSTICS:docs/DIAGNOSTICS.md STATUS:docs/STATUS.md CHANGELOG:CHANGELOG.md; do
    [ -f "$root/${pair#*:}" ] || die "${pair#*:} not found"
    cp "$root/${pair#*:}" "$d/${pair%%:*}.md"
  done
}

case "${1:-}" in
  check-tag)
    tag="${2:?usage: package.sh check-tag <tag>}"; v="$(version)"
    [ -n "$v" ] || die "no version in VERSION"
    [ "$tag" = "v$v" ] || die "tag $tag does not match VERSION $v (expected v$v)"
    case "$v" in *-*) die "VERSION $v is a prerelease; set the release version before tagging" ;; esac
    echo "$v" ;;
  pack)
    rid="${2:?usage: package.sh pack <rid> <publish-dir> <out>}"; pub="${3:?}"; out="${4:?}"
    case "$rid" in
      linux-x64|linux-arm64) target="$rid"; exe=bayan; ext=tar.gz ;;
      osx-x64|osx-arm64) target="macos-${rid#osx-}"; exe=bayan; ext=tar.gz ;;
      win-x64|win-arm64) target="windows-${rid#win-}"; exe=bayan.exe; ext=zip ;;
      *) die "unknown rid $rid" ;;
    esac
    [ -f "$pub/$exe" ] || die "$pub/$exe not found"
    v="$(version)"; name="bayan-$v-$target"
    mkdir -p "$out"; out="$(cd "$out" && pwd)"
    stage="$out/.stage-$target"; rm -rf "$stage"; mkdir -p "$stage/$name"
    cp "$pub/$exe" "$stage/$name/"
    cp "$root/README.md" "$stage/$name/"
    if [ -f "$root/LICENSE" ]; then cp "$root/LICENSE" "$stage/$name/"; else echo "::warning::package: the repo has no LICENSE; $name ships without one" >&2; fi
    docs "$stage/$name"
    if [ "$ext" = zip ]; then
      # bsdtar writes zip: System32's on Windows runners, the system tar on macOS; else Info-ZIP.
      if [ -n "${SYSTEMROOT:-}" ] && [ -x "$SYSTEMROOT/System32/tar.exe" ]; then (cd "$stage" && "$SYSTEMROOT/System32/tar.exe" -a -cf "$out/$name.zip" "$name")
      elif tar --version 2>/dev/null | grep -q bsdtar; then (cd "$stage" && tar -a -cf "$out/$name.zip" "$name")
      else (cd "$stage" && zip -qr "$out/$name.zip" "$name"); fi
    else
      COPYFILE_DISABLE=1 tar -czf "$out/$name.tar.gz" -C "$stage" "$name"
    fi
    rm -rf "$stage"
    echo "$out/$name.$ext" ;;
  docs)
    out="${2:?usage: package.sh docs <out>}"
    v="$(version)"; [ -n "$v" ] || die "no version in VERSION"; name="bayan-$v-docs"
    mkdir -p "$out"; out="$(cd "$out" && pwd)"
    stage="$out/.stage-docs"; rm -rf "$stage"; mkdir -p "$stage/$name"
    docs "$stage/$name"
    COPYFILE_DISABLE=1 tar -czf "$out/$name.tar.gz" -C "$stage" "$name"
    rm -rf "$stage"
    echo "$out/$name.tar.gz" ;;
  sums)
    dir="${2:?usage: package.sh sums <dir>}"
    ( cd "$dir"
      set -- bayan-*.tar.gz bayan-*.zip
      files=(); for f in "$@"; do [ -f "$f" ] && files+=("$f"); done
      [ ${#files[@]} -gt 0 ] || die "no archives in $dir"
      if command -v sha256sum >/dev/null; then sha256sum "${files[@]}"; else shasum -a 256 "${files[@]}"; fi > SHA256SUMS )
    echo "$dir/SHA256SUMS" ;;
  notes)
    v="${2:?usage: package.sh notes <version>}"
    notes="$(awk -v h="## [$v]" 'index($0, h) == 1 { on = 1; next } on && /^## \[/ { exit } on' "$root/CHANGELOG.md")"
    [ -n "$(printf '%s' "$notes" | tr -d '[:space:]')" ] || die "CHANGELOG.md has no ## [$v] section"
    printf '%s\n' "$notes" ;;
  *) die "usage: package.sh check-tag|pack|docs|sums|notes …" ;;
esac
