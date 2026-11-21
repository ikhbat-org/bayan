#!/usr/bin/env bash
# Diverse double-compiling (spec 019 R27, T46): the frozen C# compiler, built from its tag, builds the self-hosted compiler
# from the frozen tree, and the C that compiler emits for that tree's src/driver must equal that tree's bootstrap/bayan.c.
#   bash scripts/ci/ddc.sh [REF]   (REF: the frozen ref, default csharp-final)
# Steps, in a fresh `git archive` of REF under <root>/tmp/ddc.XXXXXX (no worktree: the checkout's git state is left alone):
#   1. dotnet publish csharp/Bayan.Cli -c Release -r <rid> -o tmp/publish   (the tree's README)
#   2. tmp/publish/bayan build --package src -o tmp/stage1/bayan src/driver  (BootstrapTests' stage 1)
#   3. tmp/stage1/bayan build --emit-c --mode safe --package src src/driver  (bootstrap/README.md: how bayan.c is made)
#   4. the bytes of 3 against bootstrap/bayan.c; a difference names its first differing line
#   5. each law id in scripts/ci/ddc-laws.txt (the laws amended under R18 to rest on the frozen compiler; T31 fills it, one id
#      per line, # comments) runs in the frozen tree as laws-nightly.yml runs laws: BAYAN_LAW_TIER=full dotnet test -v q
#      --filter "Law=<id>". An empty list runs nothing and passes.
# The tree is removed when every step passes and kept for inspection otherwise. Exit 0 when all hold, 1 when a step
# fails, 2 on a usage error or an unknown REF. Tests only: DDC_DOTNET replaces `dotnet`, DDC_RID the rid picked from the host.
# The build needs a C compiler (zig or cc), as the C# `build` does. bash 3.2.
set -uo pipefail
# The frozen tree's projects stay as frozen: a NuGet advisory published after the freeze (NU1903 on
# Microsoft.DotNet.ILCompiler 10.0.12, GHSA-p3jp-9v83-76w9, 2026-11-21) would fail their build under warnings-as-errors.
export NuGetAudit=false
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root" || exit 2

usage() { echo "usage: ddc.sh [REF]   (REF: the frozen ref, default csharp-final)" >&2; exit 2; }
[ $# -le 1 ] || usage
case "${1:-}" in -*) usage ;; esac
ref="${1:-csharp-final}"
git rev-parse -q --verify "$ref^{commit}" >/dev/null || { echo "ddc: no such ref '$ref'" >&2; exit 2; }
dotnet="${DDC_DOTNET:-dotnet}"

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) host=linux-x64 ;;
  Linux-aarch64) host=linux-arm64 ;;
  Darwin-arm64) host=osx-arm64 ;;
  Darwin-x86_64) host=osx-x64 ;;
  MINGW*-x86_64|MSYS*-x86_64) host=win-x64 ;;
  MINGW*-aarch64|MSYS*-aarch64) host=win-arm64 ;;
  *) host="" ;;
esac
rid="${DDC_RID:-$host}"
[ -n "$rid" ] || { echo "ddc: no rid for $(uname -s)-$(uname -m); set DDC_RID" >&2; exit 1; }
case "$rid" in win-*) exe=bayan.exe ;; *) exe=bayan ;; esac

mkdir -p tmp; wt="$(mktemp -d "$root/tmp/ddc.XXXXXX")"
git archive --format=tar "$ref" | tar -xf - -C "$wt" || { echo "ddc: cannot extract $ref into $wt" >&2; exit 1; }
die() { echo "ddc: $1 (tree kept: $wt)" >&2; exit 1; }
start=$(date +%s)
echo "== ddc: $ref ($(git rev-parse --short=12 "$ref^{commit}")), rid $rid"
cd "$wt" || exit 1
# The tree is no git work tree: its C# compiler's version line says "unknown" rather than the enclosing checkout's commit.
export BAYAN_CACHE="$wt/tmp/cache" GIT_CEILING_DIRECTORIES="$root/tmp"

"$dotnet" publish csharp/Bayan.Cli -c Release -r "$rid" -o tmp/publish || die "dotnet publish failed"
mkdir -p tmp/stage1  # the C# `build -o` does not create its directory (BootstrapTests makes it first)
"./tmp/publish/$exe" build --package src -o "tmp/stage1/$exe" src/driver || die "the C# compiler could not build src/driver"
"./tmp/stage1/$exe" build --emit-c --mode safe --package src src/driver > tmp/driver.safe.c || die "stage 1 could not emit C for src/driver"

if ! cmp -s bootstrap/bayan.c tmp/driver.safe.c; then
  line=$(awk 'NR == FNR { a[FNR] = $0; n = FNR; next }
    { if (FNR > n || a[FNR] != $0) { print FNR; found = 1; exit } m = FNR }
    END { if (!found) print (m < n ? m + 1 : m) }' bootstrap/bayan.c tmp/driver.safe.c)
  echo "ddc: $ref: the C stage 1 emits for src/driver differs from bootstrap/bayan.c at line $line" >&2
  echo "  bootstrap/bayan.c: $(sed -n "${line}p" bootstrap/bayan.c | cut -c1-200)" >&2
  echo "  emitted:           $(sed -n "${line}p" tmp/driver.safe.c | cut -c1-200)" >&2
  die "$ref's bootstrap/bayan.c is not reproduced; the emitted C is $wt/tmp/driver.safe.c"
fi
echo "ddc: $ref: bootstrap/bayan.c reproduced byte for byte"

laws=$(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$root/scripts/ci/ddc-laws.txt" | grep -v '^$' || true)
if [ -z "$laws" ]; then
  echo "ddc: no laws listed in scripts/ci/ddc-laws.txt; none run"
else
  failed=""
  for id in $laws; do
    echo "== $id (full tier, frozen compiler)"
    BAYAN_LAW_TIER=full "$dotnet" test -v q --filter "Law=$id" || failed="$failed $id"
  done
  [ -z "$failed" ] || die "laws failed on the frozen compiler:$failed"
  echo "ddc: laws hold on the frozen compiler: $(echo $laws)"
fi

cd "$root" && rm -rf "$wt"
echo "ddc: $ref passed in $(( $(date +%s) - start ))s"
