#!/bin/sh
# Builds bayan.run into site/out: runs the generator (site/gen) with the release docs (version.sh
# `bayan_release_docs` and CHANGELOG.md), copies site/assets to site/out/assets, then checks every
# example's output (check-examples.sh).
# BAYAN names the compiler; the default is the latest local build.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)
export BAYAN="${BAYAN:-$root/dist/macos-arm64/latest/bayan}"
. "$root/scripts/release/version.sh"
version=$(bayan_version "$root")

# The generator writes into out/ but cannot create directories, so start from empty ones.
rm -rf "$here/out"
mkdir -p "$here/out/docs/$version"
# shellcheck disable=SC2086 # one argument per doc path
"$BAYAN" run "$here/gen" -- "$here" $bayan_release_docs CHANGELOG.md
cp -R "$here/assets" "$here/out/assets"
"$here/check-examples.sh"
