#!/bin/sh
# Runs every site/examples/<name>.byn and compares its stdout with <name>.out.
#   check-examples.sh            check; exit 1 if any output differs or a program fails
#   check-examples.sh --update   write the .out files from the real output
# Each program runs from a directory of its own: the compiler treats a directory as one module,
# so two examples side by side would be one program.
# A program that exits non-zero on purpose has <name>.exit holding the expected exit code.
set -u
here=$(cd "$(dirname "$0")" && pwd)
bayan=${BAYAN:-$(cd "$here/.." && pwd)/dist/macos-arm64/latest/bayan}
# The examples run after a cd, so a relative path to the compiler must be made absolute first.
case $bayan in
  */*) dir=$(cd "$(dirname "$bayan")" 2>/dev/null && pwd) || { echo "check-examples.sh: no directory for BAYAN=$bayan" >&2; exit 2; }
       bayan=$dir/$(basename "$bayan") ;;
esac
update=no
case "${1:-}" in
  --update) update=yes ;;
  "") ;;
  *) echo "usage: check-examples.sh [--update]" >&2; exit 2 ;;
esac

mkdir -p "$here/../tmp"
work=$(mktemp -d "$here/../tmp/site-examples.XXXXXX") || { echo "check-examples.sh: mktemp failed" >&2; exit 1; }
trap 'rm -rf "$work"' EXIT
failed=0
count=0
for src in "$here"/examples/*.byn; do
  [ -e "$src" ] || continue
  name=$(basename "$src" .byn)
  count=$((count + 1))
  mkdir -p "$work/$name"
  cp "$src" "$work/$name/$name.byn"
  want=0
  [ -f "$here/examples/$name.exit" ] && want=$(cat "$here/examples/$name.exit")
  (cd "$work/$name" && "$bayan" run "$name.byn") > "$work/$name.stdout" 2> "$work/$name.stderr"
  got=$?
  if [ "$got" != "$want" ]; then
    echo "FAIL $name: exit $got, expected $want" >&2
    cat "$work/$name.stderr" >&2
    failed=1
    continue
  fi
  if [ "$update" = yes ]; then
    cp "$work/$name.stdout" "$here/examples/$name.out"
    echo "wrote examples/$name.out"
  elif [ ! -f "$here/examples/$name.out" ]; then
    echo "FAIL $name: examples/$name.out is missing (run check-examples.sh --update)" >&2
    failed=1
  elif ! diff -u "$here/examples/$name.out" "$work/$name.stdout" >&2; then
    echo "FAIL $name: stdout differs from examples/$name.out" >&2
    failed=1
  fi
done
[ "$failed" = 0 ] && echo "examples: $count checked"
exit "$failed"
