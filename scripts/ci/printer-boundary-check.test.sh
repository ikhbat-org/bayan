#!/usr/bin/env bash
# Tests scripts/ci/printer-boundary-check.sh on a fixture tree under tmp/: a clean pass (C text in cprint/, the JSON literal in
# schemata.byn), the four ScanFlagsCText rows of SelfhostEmitterPrinterBoundaryTests reported and its three
# ScanIgnoresCommentsAndPlainText rows not, C text in a nested folder, the JSON literal outside its file, and a stale JSON entry.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/printer-boundary-check-test"; rm -rf "$t"; mkdir -p "$t"
chk="$root/scripts/ci/printer-boundary-check.sh"
run_check() { rc=0; out="$(bash "$chk" "$t" 2>&1)" || rc=$?; }
expect() { # name exit [text the output must hold]
  run_check
  [ "$rc" = "$2" ] || fail "$1: exit $rc, wanted $2: $out"
  [ -z "${3:-}" ] || grep -qF -- "$3" <<<"$out" || fail "$1: no '$3' in: $out"
}
e="$t/src/emitter"
good() {
  rm -rf "$t/src"; mkdir -p "$e/cprint" "$e/sub"
  printf 'string inc() {\n    return "#include <stdio.h>\\n" + "static int64_t x;\\n"\n}\n' > "$e/cprint/print.byn"
  cat > "$e/schemata.byn" <<'EOF'
string sitesJson() {
    var s = "{\n  \"version\": 1,\n  \"sites\": ["
    return s
}
EOF
  printf 'string plain() {\n    return "unmatched switch"\n}\n' > "$e/x.byn"
  printf 'i32 n() => 1\n' > "$e/sub/y.byn"
}

good
expect "clean" 0 "printer-boundary-check: ok"
# ScanFlagsCText: each line holds a literal with C text
while IFS='|' read -r line word; do
  good; printf '%s\n' "$line" >> "$e/x.byn"
  expect "flags: $line" 1 "x.byn:4: "
  grep -qF -- "has \`$word" <<<"$out" || fail "flags: $line: no word $word in: $out"
done <<'EOF'
let s = "#include <stdio.h>\n"|#include
sb.append($"int64_t x{n};\n")|int64_t
return "goto " + name|goto
x = "a->b"|->
EOF
good; printf 'x = "a;\\nb"\n' >> "$e/x.byn"
expect "flags ;\\n" 1 "x.byn:4: \"a;\\nb\" has \`;\\n\`"
# ScanIgnoresCommentsAndPlainText
while IFS= read -r line; do
  good; printf '%s\n' "$line" >> "$e/x.byn"
  expect "ignores: $line" 0 "printer-boundary-check: ok"
done <<'EOF'
let s = "L" + n // "#include"
/// `goto ` and "static " in a comment
return "unmatched switch"
EOF
good; printf 'let t = "typedef struct"\n' >> "$e/sub/y.byn"
expect "nested folder" 1 "sub/y.byn:2: \"typedef struct\" has \`typedef\`"
good; sed -n 2p "$e/schemata.byn" >> "$e/x.byn"
expect "JSON literal outside its file" 1 "x.byn:4: \"{\\n  \\\"version\\\": 1,\\n  \\\"sites\\\": [\" has \`{\\n\`"
good; printf 'string sitesJson() => "[]"\n' > "$e/schemata.byn"
expect "stale JSON entry" 1 "JSON entry schemata.byn names no literal in its file"
rm -rf "$t"
echo "printer-boundary-check.test: ok"
