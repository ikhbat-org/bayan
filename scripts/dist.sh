#!/usr/bin/env bash
# Local compiler builds kept by target and version (dist/ is gitignored).
#   scripts/dist.sh [--rid <rid>]... [--label <version>] [--from <publish-dir> [--commit <sha>]] [--dist <dir>]
# Layout:
#   dist/<target>/<version>/bayan[.exe]   one directory per version, with BUILD-INFO and bayan-lsp[.exe] (019 R37)
#   dist/<target>/latest/                 a copy of the most recent build for that target, replaced on every build
# Targets use the release names (scripts/release/package.sh): osx-arm64 -> macos-arm64, win-x64 -> windows-x64.
# <version> is VERSION (scripts/release/version.sh); a prerelease (0.2.0-dev) gets +<12-hex commit>, and a tree with
# any change not yet committed, untracked files included (the binary embeds docs/diagnostics too), gets .dirty:
# each commit has its own directory, a release keeps its plain number, and .dirty builds of one commit replace each other.
# Each rid is built from src/ by a compiler built from src/ (scripts/bootstrap-build.sh, no .NET; spec 019 R25); a rid
# other than the host's cross-builds through zig (--target). --from <dir> --rid <rid> imports a binary built elsewhere
# (BUILD-INFO commit "unknown" unless --commit). bayan-lsp is built from editors/language-server by the same compiler,
# or --from takes <dir>/bayan-lsp; BUILD-INFO `lsp` is built, imported or none (--from without one, with a warning).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=release/version.sh
. "$root/scripts/release/version.sh"
lock="" plock=""
trap '[ -z "$plock" ] || rmdir "$plock" 2>/dev/null || :; [ -z "$lock" ] || rmdir "$lock" 2>/dev/null || :' EXIT
die() { echo "dist: $*" >&2; exit 1; }
usage() { sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

host_rid() {
  local arch
  case "$2" in arm64|aarch64) arch=arm64 ;; x86_64|amd64) arch=x64 ;; *) return 1 ;; esac
  case "$1" in
    Darwin) echo "osx-$arch" ;;
    Linux) echo "linux-$arch" ;;
    MINGW*|MSYS*|CYGWIN*) echo "win-$arch" ;;
    *) return 1 ;;
  esac
}

# target <rid> -> "<target> <exe>"
target() {
  case "$1" in
    linux-x64|linux-arm64) echo "$1 bayan" ;;
    osx-x64|osx-arm64) echo "macos-${1#osx-} bayan" ;;
    win-x64|win-arm64) echo "windows-${1#win-} bayan.exe" ;;
    *) return 1 ;;
  esac
}

label() {
  local v sha dirty=""
  v="$(bayan_version "$root")" || die "no version in $root/VERSION"
  [ -z "$(git -C "$root" status --porcelain 2>/dev/null)" ] || dirty=.dirty
  case "$v" in
    *-*) sha="$(git -C "$root" rev-parse --short=12 HEAD 2>/dev/null)" || die "a prerelease label needs a git checkout"
         echo "$v+$sha$dirty" ;;
    *) echo "$v$dirty" ;;
  esac
}

rids=() lbl="" from="" dist="$root/dist" commit=""
while [ $# -gt 0 ]; do
  case "$1" in
    --rid) [ $# -ge 2 ] || die "--rid needs a value"; rids+=("$2"); shift 2 ;;
    --label) [ $# -ge 2 ] || die "--label needs a value"; lbl="$2"; shift 2 ;;
    --from) [ $# -ge 2 ] || die "--from needs a value"; from="$2"; shift 2 ;;
    --dist) [ $# -ge 2 ] || die "--dist needs a value"; dist="$2"; shift 2 ;;
    --commit) [ $# -ge 2 ] || die "--commit needs a value"; commit="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; die "unexpected argument '$1'" ;;
  esac
done

if [ ${#rids[@]} -eq 0 ]; then
  [ -z "$from" ] || die "--from needs --rid (the binary's own target)"
  r="$(host_rid "$(uname -s)" "$(uname -m)")" || die "unknown host $(uname -s) $(uname -m); pass --rid"
  rids=("$r")
fi
[ -z "$from" ] || [ ${#rids[@]} -eq 1 ] || die "--from takes exactly one --rid"
[ -n "$dist" ] || die "--dist needs a directory"
[ -n "$lbl" ] || lbl="$(label)"
case "$lbl" in ''|.*|*/*|*\\*|*[[:space:]]*|latest) die "bad version label '$lbl'" ;; esac
# An imported binary was built elsewhere: this checkout's HEAD says nothing about it unless --commit names it.
if [ -z "$commit" ]; then
  if [ -n "$from" ]; then commit=unknown; else commit="$(git -C "$root" rev-parse HEAD 2>/dev/null || echo unknown)"; fi
fi

compiler="" hrid="$(host_rid "$(uname -s)" "$(uname -m)" 2>/dev/null || :)"
for rid in "${rids[@]}"; do
  t="$(target "$rid")" || die "unknown rid $rid"
  tgt="${t% *}" exe="${t#* }"
  lsp="bayan-lsp${exe#bayan}"
  # One run per target at a time, taken before publishing: two runs would share tmp/dist-publish/<rid> and obj/.
  mkdir -p "$dist/$tgt" 2>/dev/null || die "cannot create $dist/$tgt"
  lock="$dist/$tgt/.lock"
  mkdir "$lock" 2>/dev/null || { lock=""; die "another dist run holds $dist/$tgt/.lock (remove it if no run is going)"; }
  if [ -n "$from" ]; then
    pub="$from"
  else
    mkdir -p "$root/tmp"
    # The compiler in tmp/dist-compiler is shared by every run in this checkout: one build at a time.
    plock="$root/tmp/dist-publish.lock"
    mkdir "$plock" 2>/dev/null || { plock=""; die "another dist run is building in this checkout (remove $root/tmp/dist-publish.lock if none is)"; }
    if [ -z "$compiler" ]; then
      echo "dist: building the compiler from bootstrap/bayan.c" >&2
      compiler="$(bash "$root/scripts/bootstrap-build.sh" --out "$root/tmp/dist-compiler" 2>"$root/tmp/dist-compiler.log")" \
        || die "bootstrap build failed, see tmp/dist-compiler.log and tmp/dist-compiler/stage*.log"
    fi
    pub="$root/tmp/dist-publish/$rid"
    rm -rf "$pub"
    mkdir -p "$pub"
    tflag=(--target "$tgt"); [ "$rid" != "$hrid" ] || tflag=()
    echo "dist: building $rid" >&2
    (cd "$root" && "$compiler" build --mode safe --package src ${tflag[@]+"${tflag[@]}"} -o "$pub/$exe" src/driver) \
      >"$root/tmp/dist-publish-$rid.log" 2>&1 || die "building $rid failed, see tmp/dist-publish-$rid.log"
    echo "dist: building $lsp for $rid" >&2
    (cd "$root" && "$compiler" build --package editors/language-server/src ${tflag[@]+"${tflag[@]}"} -o "$pub/$lsp" \
      editors/language-server/src/app) >"$root/tmp/dist-lsp-$rid.log" 2>&1 || die "building $lsp for $rid failed, see tmp/dist-lsp-$rid.log"
    rmdir "$plock"; plock=""
  fi
  [ -f "$pub/$exe" ] || die "$pub/$exe not found"
  lspinfo=built; [ -z "$from" ] || lspinfo=imported
  if [ ! -f "$pub/$lsp" ]; then
    [ -n "$from" ] || die "$pub/$lsp not found"
    echo "dist: warning: $from has no $lsp; this build has none" >&2
    lspinfo=none
  fi

  dir="$dist/$tgt/$lbl"
  mkdir -p "$dir"
  cp "$pub/$exe" "$dir/$exe"
  chmod +x "$dir/$exe"
  if [ "$lspinfo" != none ]; then cp "$pub/$lsp" "$dir/$lsp"; chmod +x "$dir/$lsp"; fi
  printf 'version %s\ntarget %s\nrid %s\ncommit %s\nbuilt %s\nhost %s\nsource %s\nlsp %s\n' \
    "$lbl" "$tgt" "$rid" "$commit" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(uname -n)" "${from:-bootstrap build}" "$lspinfo" > "$dir/BUILD-INFO"

  # latest: copy beside it, move the old one aside, move the copy in. A failed step leaves the old latest in place
  # (Windows refuses to move a folder holding a running bayan.exe).
  latest="$dist/$tgt/latest" next="$dist/$tgt/.latest-next" old="$dist/$tgt/.latest-old"
  rm -rf "$next" "$old" 2>/dev/null || die "cannot clear $old or $next (is a bayan from it running?); $dir is written, latest is not updated"
  cp -R "$dir" "$next"
  if [ -e "$latest" ] && ! mv "$latest" "$old"; then
    rm -rf "$next"; die "cannot replace $latest (is its bayan running?); it is unchanged"
  fi
  if ! mv "$next" "$latest"; then
    if [ -e "$old" ] && ! mv "$old" "$latest"; then die "cannot move the new build into $latest, nor the old one back from $old"; fi
    die "cannot move the new build into $latest; the old one is back"
  fi
  rm -rf "$old" || echo "dist: could not remove $old" >&2
  rmdir "$lock"; lock=""
  echo "$dir/$exe"
done
