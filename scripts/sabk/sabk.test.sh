#!/usr/bin/env bash
# Ported from SabkTests (src/tests/SabkTests.cs, spec 024 T12, T13) with no dotnet; SabkSourceTestsPass is scripts/test.sh's
# bayan part (`test --package src src/sabk`).
# recorded: record-encodings.sh and record-macho.sh, run on src/sabk/testdata/encodings.s and macho.s into tmp/sabk/, write
#   the bytes of the tracked encodings.tsv and macho-expected.txt.
# e2e: `$BAYAN_EXE test --package src src/sabk --only salam.o` passes 1 test and writes tmp/sabk/salam.o; clang links it with
#   runtime/bayan-rt.c (compiled by clang -O2 -DBYN_NDEBUG) printing nothing; the program prints "Salam, world!\n", nothing on
#   stderr, and exits 42; its sections (segname sectname align flags, otool -l order) and sorted symbols (nm -m without
#   addresses) equal those of clang's object of src/sabk/testdata/salam.s.
# BAYAN_EXE: the self-hosted driver; unset, src/driver is built with the pinned bayan (scripts/pinned-bayan.sh) into tmp/, as
# scripts/test.sh does. Off arm64 macOS it prints why and exits 0 (the recorders need zig cc, clang, otool and nm). bash 3.2.
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root" || exit 2
if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then echo "sabk.test: skipped: sabk tests need arm64 macOS (024 R9)"; exit 0; fi

bayan="${BAYAN_EXE:-}"
if [ -z "$bayan" ]; then
  mkdir -p tmp
  bayan="$root/tmp/sabk-test-bayan"
  pin="$(bash scripts/pinned-bayan.sh 2>"$bayan.log")" && "$pin" build --mode safe --package src -o "$bayan" src/driver >>"$bayan.log" 2>&1 \
    || { echo "FAIL sabk.test: building src/driver with the pinned bayan failed; log: $bayan.log"; exit 1; }
fi
export BAYAN_EXE="$bayan"

dir="$root/tmp/sabk"
data="$root/src/sabk/testdata"
passed=0; failed=0
fail() { echo "FAIL $1"; failed=$((failed + 1)); }

recorded() {
  local script input tracked
  rm -rf "$dir" && mkdir -p "$dir"
  for script in record-encodings:encodings.s:encodings.tsv record-macho:macho.s:macho-expected.txt; do
    tracked=${script##*:}; input=${script#*:}; input=${input%%:*}; script=${script%%:*}.sh
    bash "scripts/sabk/$script" "$data/$input" "$dir/$tracked" > "$dir/$script.log" 2>&1 \
      || { fail "recorded: $script failed: $(tail -n 5 "$dir/$script.log")"; return; }
    cmp -s "$data/$tracked" "$dir/$tracked" || { fail "recorded: $tracked differs from what $script records; re-run the script"; return; }
  done
  passed=$((passed + 1))
}

# sections <obj>: one "segname sectname align flags" line per section of otool -l.
sections() {
  otool -l "$1" | awk '
    { sub(/^[ \t]+/, ""); sub(/[ \t]+$/, "") }
    $0 == "Section" { on = 1; next }
    !on { next }
    /^(sectname|segname|align|flags) / { k = $1; v = substr($0, length(k) + 2); s[k] = v
      if (k == "flags") { print s["segname"] " " s["sectname"] " " s["align"] " " s["flags"]; on = 0 } }'
}

# symbols <obj>: nm -m lines without the address column, sorted.
symbols() { nm -m "$1" | grep -v '^$' | sed -E 's/^[0-9a-f]*[[:space:]]+//' | LC_ALL=C sort; }

e2e() {
  local obj="$dir/salam.o" rt="$dir/bayan-rt.o" exe="$dir/salam" ref="$dir/salam-ref.o" rc out a b
  mkdir -p "$dir"; rm -f "$obj"
  rc=0; out="$("$bayan" test --package src src/sabk --only salam.o 2>&1)" || rc=$?
  case "$out" in (*"◆ 1 passed"*) [ $rc = 0 ] ;; (*) false ;; esac || { fail "e2e: the sabk e2e entry failed (exit $rc):
$out"; return; }
  [ -f "$obj" ] || { fail "e2e: the sabk e2e entry wrote no $obj"; return; }
  clang -c -O2 -DBYN_NDEBUG runtime/bayan-rt.c -o "$rt" > "$dir/rt.log" 2>&1 || { fail "e2e: clang -c runtime/bayan-rt.c failed: $(cat "$dir/rt.log")"; return; }
  clang "$obj" "$rt" -o "$exe" > "$dir/link.out" 2> "$dir/link.err" || { fail "e2e: the link failed: $(cat "$dir/link.out" "$dir/link.err")"; return; }
  [ ! -s "$dir/link.out" ] && [ ! -s "$dir/link.err" ] || { fail "e2e: the link printed: $(cat "$dir/link.out" "$dir/link.err")"; return; }
  rc=0; "$exe" > "$dir/run.out" 2> "$dir/run.err" || rc=$?
  printf 'Salam, world!\n' > "$dir/run.want"
  cmp -s "$dir/run.want" "$dir/run.out" || { fail "e2e: the program printed '$(cat "$dir/run.out")', not 'Salam, world!'"; return; }
  [ ! -s "$dir/run.err" ] || { fail "e2e: the program wrote to stderr: $(cat "$dir/run.err")"; return; }
  [ $rc = 42 ] || { fail "e2e: the program exited $rc, not 42"; return; }
  clang -c -target arm64-apple-macos15 "$data/salam.s" -o "$ref" > "$dir/ref.log" 2>&1 || { fail "e2e: clang -c salam.s failed: $(cat "$dir/ref.log")"; return; }
  a="$(sections "$ref")"; b="$(sections "$obj")"
  [ -n "$a" ] && [ -n "$b" ] || { fail "e2e: otool -l lists no section in salam-ref.o or salam.o"; return; }
  [ "$a" = "$b" ] || { fail "e2e: sections differ; salam.s: [$a] salam.o: [$b]"; return; }
  a="$(symbols "$ref")"; b="$(symbols "$obj")"
  [ -n "$a" ] && [ -n "$b" ] || { fail "e2e: nm -m lists no symbol in salam-ref.o or salam.o"; return; }
  [ "$a" = "$b" ] || { fail "e2e: symbols differ; salam.s: [$a] salam.o: [$b]"; return; }
  passed=$((passed + 1))
}

recorded
e2e
[ $failed = 0 ] && { echo "sabk.test: $passed passed"; exit 0; }
echo "sabk.test: $passed passed, $failed failed"; exit 1
