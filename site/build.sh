#!/bin/sh
# Builds bayan.run into site/out: runs the generator (site/gen), copies site/assets to
# site/out/assets, then checks every example's output (check-examples.sh).
# BAYAN names the compiler; the default is the latest local build.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
export BAYAN="${BAYAN:-/Users/sy/Developer/ikhbat.org/bayan/dist/macos-arm64/latest/bayan}"

# The generator writes into out/ but cannot create directories, so start from an empty one.
rm -rf "$here/out"
mkdir -p "$here/out"
"$BAYAN" run "$here/gen" -- "$here"
cp -R "$here/assets" "$here/out/assets"
"$here/check-examples.sh"
