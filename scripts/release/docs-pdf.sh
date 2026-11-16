#!/usr/bin/env bash
# Prints the manifesto and the book to PDF with headless Chrome: dist/bayan-manifesto-<version>.pdf and
# dist/bayan-book-<version>.pdf, from the site build (site/build.sh).
#   scripts/release/docs-pdf.sh
# CHROME names the browser; the default is Google Chrome on macOS, else google-chrome or chromium on PATH. Exit 2 if none.
set -eu
root=$(cd "$(dirname "$0")/../.." && pwd)
. "$root/scripts/release/version.sh"
version=$(bayan_version "$root")

chrome=${CHROME:-}
if [ -z "$chrome" ]; then
  if [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  elif command -v google-chrome > /dev/null 2>&1; then
    chrome=google-chrome
  elif command -v chromium > /dev/null 2>&1; then
    chrome=chromium
  else
    echo "docs-pdf: no Chrome found; set CHROME to a Chrome or Chromium binary" >&2
    exit 2
  fi
fi
command -v "$chrome" > /dev/null 2>&1 || { echo "docs-pdf: $chrome not found; set CHROME to a Chrome or Chromium binary" >&2; exit 2; }

sh "$root/site/build.sh"
mkdir -p "$root/dist"
for name in manifesto book; do
  out="$root/dist/bayan-$name-$version.pdf"
  "$chrome" --headless --disable-gpu --use-mock-keychain --no-pdf-header-footer \
    --print-to-pdf="$out" "file://$root/site/out/$name.html"
  echo "wrote $out"
done
