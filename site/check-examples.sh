#!/bin/sh
# Runs every site/examples/<name>.byn and compares its stdout with <name>.out.
#   check-examples.sh            check; exit 1 if any output differs or a program fails
#   check-examples.sh --update   write the .out files from the real output
# Each program runs from a directory of its own: the compiler treats a directory as one module,
# so two examples side by side would be one program.
set -u
here=$(cd "$(dirname "$0")" && pwd)
bayan=${BAYAN:-/Users/sy/Developer/ikhbat.org/bayan/dist/macos-arm64/latest/bayan}
update=no
case "${1:-}" in
  --update) update=yes ;;
  "") ;;
  *) echo "usage: check-examples.sh [--update]" >&2; exit 2 ;;
esac

work=$(mktemp -d "${TMPDIR:-/tmp}/bayan-examples.XXXXXX")
trap 'rm -rf "$work"' EXIT
failed=0
count=0
for src in "$here"/examples/*.byn; do
  [ -e "$src" ] || continue
  name=$(basename "$src" .byn)
  count=$((count + 1))
  mkdir -p "$work/$name"
  cp "$src" "$work/$name/$name.byn"
  if ! (cd "$work/$name" && "$bayan" run "$name.byn") > "$work/$name.stdout" 2> "$work/$name.stderr"; then
    echo "FAIL $name: the program did not run" >&2
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
