#!/usr/bin/env bash
# Tests scripts/ci/install-zig.sh against a fake download, and its wiring in .github/workflows/.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script="$root/scripts/ci/install-zig.sh"
tmp="$root/tmp/install-zig-test"
rm -rf "$tmp"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT
fail() { echo "FAIL: $1" >&2; exit 1; }
unset RUNNER_ARCH
sha() { if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) target=x86_64-linux ;;
  Darwin-arm64) target=aarch64-macos ;;
  *) echo "SKIP: no fake archive for $(uname -s)-$(uname -m)"; exit 0 ;;
esac
name="zig-$target-0.17.0"

# A fake release: a tarball whose zig prints its version.
mkdir -p "$tmp/src/$name" "$tmp/site/0.17.0"
printf '#!/bin/sh\necho 0.17.0\n' > "$tmp/src/$name/zig"; chmod +x "$tmp/src/$name/zig"
tar -cJf "$tmp/site/0.17.0/$name.tar.xz" -C "$tmp/src" "$name"
good="$(sha "$tmp/site/0.17.0/$name.tar.xz")"

# The pinned sum does not match the fake archive: refused, archive removed, nothing unpacked.
if out="$(ZIG_BASE_URL="file://$tmp/site" "$script" "$tmp/bad" 2>&1)"; then fail "a mismatched archive was installed"; fi
echo "$out" | grep -q "sha256 mismatch for $name.tar.xz" || fail "no mismatch message: $out"
[ ! -e "$tmp/bad/$name.tar.xz" ] && [ ! -e "$tmp/bad/$name" ] || fail "a mismatched archive was left or unpacked"

# The matching sum: unpacked, its zig runs, stdout is the bin directory only.
bin="$(ZIG_BASE_URL="file://$tmp/site" ZIG_SHA256="$good" "$script" "$tmp/good" 2>"$tmp/err")" || fail "matching archive refused: $(cat "$tmp/err")"
[ "$bin" = "$tmp/good/$name" ] || fail "stdout was '$bin'"
[ "$("$bin/zig" version)" = 0.17.0 ] || fail "installed zig does not run"
grep -qx 0.17.0 "$tmp/err" || fail "zig version not reported on stderr"
[ ! -e "$tmp/good/$name.tar.xz" ] || fail "archive not removed after unpacking"

# A destination path holding a backslash, as Windows runners' RUNNER_TEMP does.
ZIG_BASE_URL="file://$tmp/site" ZIG_SHA256="$good" "$script" "$tmp/back\\slash" >/dev/null 2>"$tmp/err" || fail "backslash path refused: $(cat "$tmp/err")"

# A host with no pinned build is refused by name.
mkdir -p "$tmp/shim"; printf '#!/bin/sh\ncase "$1" in -s) echo Plan9;; -m) echo mips;; esac\n' > "$tmp/shim/uname"; chmod +x "$tmp/shim/uname"
if out="$(PATH="$tmp/shim:$PATH" "$script" "$tmp/none" 2>&1)"; then fail "an unknown host was accepted"; fi
echo "$out" | grep -q "no pinned zig 0.17.0 for Plan9-mips" || fail "no unknown-host message: $out"

# Every pinned platform, through a fake uname: the archive name asked for and the unpacked directory. RUNNER_ARCH wins over uname -m.
host_row() { # os machine runner_arch target ext
  local d="$tmp/row-$1-$2-${3:-none}" n="zig-$4-0.17.0" b
  mkdir -p "$d/shim" "$d/src/$n" "$d/site/0.17.0"
  printf '#!/bin/sh\ncase "$1" in -s) echo %s;; -m) echo %s;; esac\n' "$1" "$2" > "$d/shim/uname"; chmod +x "$d/shim/uname"
  printf '#!/bin/sh\necho 0.17.0\n' > "$d/src/$n/zig"; chmod +x "$d/src/$n/zig"
  if [ "$5" = zip ]; then (cd "$d/src" && zip -qr "$d/site/0.17.0/$n.zip" "$n"); else tar -cJf "$d/site/0.17.0/$n.tar.xz" -C "$d/src" "$n"; fi
  b="$(PATH="$d/shim:$PATH" RUNNER_ARCH="$3" ZIG_BASE_URL="file://$d/site" ZIG_SHA256="$(sha "$d/site/0.17.0/$n.$5")" "$script" "$d/dest" 2>/dev/null)" \
    || fail "$1 $2 ${3:-no RUNNER_ARCH} was refused for $4"
  [ "$b" = "$d/dest/$n" ] || fail "$1 $2 ${3:-no RUNNER_ARCH}: stdout was '$b', want $n"
}
host_row Linux x86_64 "" x86_64-linux tar.xz
host_row Linux aarch64 "" aarch64-linux tar.xz
host_row Darwin arm64 "" aarch64-macos tar.xz
host_row Darwin x86_64 "" x86_64-macos tar.xz
host_row MINGW64_NT-10.0 x86_64 "" x86_64-windows zip
host_row MINGW64_NT-10.0 aarch64 "" aarch64-windows zip
host_row MSYS_NT-10.0 arm64 "" aarch64-windows zip
host_row MINGW64_NT-10.0 x86_64 ARM64 aarch64-windows zip
host_row MINGW64_NT-10.0 aarch64 X64 x86_64-windows zip
host_row Linux x86_64 ARM64 aarch64-linux tar.xz
host_row Darwin arm64 X64 x86_64-macos tar.xz

# A .zig-version the sums are not for is refused before anything is downloaded.
mkdir -p "$tmp/repo/scripts/ci"; cp "$script" "$tmp/repo/scripts/ci/"; echo 0.18.0 > "$tmp/repo/.zig-version"
if out="$(ZIG_BASE_URL="file://$tmp/site" "$tmp/repo/scripts/ci/install-zig.sh" "$tmp/other" 2>&1)"; then fail "a .zig-version without sums was installed"; fi
echo "$out" | grep -q ".zig-version is 0.18.0 but the sums here are for 0.17.0" || fail "no version-mismatch message: $out"
[ ! -e "$tmp/other" ] || fail "something was downloaded for an unpinned version"

# Wiring: no workflow uses a Node 20 action; each zig step runs the script.
for wf in "$root/.github/workflows/ci.yml" "$root/.github/workflows/mutation.yml"; do
  ! grep -q "mlugg/setup-zig" "$wf" || fail "$wf still uses mlugg/setup-zig"
  grep -q "scripts/ci/install-zig.sh" "$wf" || fail "$wf does not run install-zig.sh"
  ! grep -qE "uses: actions/(checkout|setup-dotnet|upload-artifact|download-artifact)@v4" "$wf" || fail "$wf still pins a Node 20 action"
done
echo PASS
