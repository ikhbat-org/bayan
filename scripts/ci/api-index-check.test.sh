#!/usr/bin/env bash
# Tests scripts/ci/api-index-check.sh on a fixture tree under tmp/: a clean pass (010 with a wrapped parameter list and a uses
# clause joined, 012 and 011 entries, the 011 markers), then each failure alone: a 010 signature changed, a signature followed
# by other text, a malformed index line, an index naming a missing file, an index with no entries, a 012 entry missing,
# a 012 entry wrapped (012 does not join), a 011 entry missing, each 011 marker string gone, the ltree marker gone.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/api-index-check-test"; rm -rf "$t"; mkdir -p "$t"
chk="$root/scripts/ci/api-index-check.sh"
run_check() { rc=0; out="$(bash "$chk" "$t" 2>&1)" || rc=$?; }
expect() { # name exit [text the output must hold]
  run_check
  [ "$rc" = "$2" ] || fail "$1: exit $rc, wanted $2: $out"
  [ -z "${3:-}" ] || grep -qF -- "$3" <<<"$out" || fail "$1: no '$3' in: $out"
}
i010="$t/docs/specs/010-self-hosted-semantics/010-api.md"
i012="$t/docs/specs/012-self-hosted-bootstrap/012-api.md"
i011="$t/docs/specs/011-self-hosted-emitter/011-api.md"
good() {
  rm -rf "$t/docs" "$t/src"
  mkdir -p "${i010%/*}" "${i012%/*}" "${i011%/*}" "$t/src/semantics" "$t/src/driver" "$t/src/emitter/ltree"
  cat > "$i010" <<'EOF'
# 010 index
- T1 a.byn: i32 one(i32 x)  ← A.cs:1 One
- T1 a.byn: i32 two(ref Ctx c, i32 y) uses alloc  ← A.cs:2 Two
- T2 a.byn: bool three()  ← A.cs:3 Three
EOF
  cat > "$t/src/semantics/a.byn" <<'EOF'
public i32 one(i32 x) => x

i32 two(
    ref Ctx c,
    i32 y,
)
    uses alloc {
    return y
}

bool three() {
    return true
}
EOF
  printf -- '- T1 driver/main.byn: string versionLine()  ← CliApp.cs:33 VersionLine\n' > "$i012"
  printf 'string versionLine() uses alloc {\n    return ""\n}\n' > "$t/src/driver/main.byn"
  printf -- '- T1 emitter/e.byn: void e(i32 a)  ← e.byn:1 e\n\n`LoweredNodes.cs:118`; `CEmitter.cs:1937`, `1942-1945`, `1961`\n' > "$i011"
  printf 'void e(i32 a) {\n}\n' > "$t/src/emitter/e.byn"
  printf 'struct L {\n    // Q1: round 4 redoes this table\n\n    public LocalId env\n}\n' > "$t/src/emitter/ltree/ltree.byn"
}
edit() { sed -i.bak "$1" "$2"; rm "$2.bak"; }

good
expect "clean" 0 "api-index-check: ok"
edit 's/^public i32 one(i32 x)/public i32 one(i64 x)/' "$t/src/semantics/a.byn"
expect "010 signature changed" 1 "api-index-check: docs/specs/010-self-hosted-semantics/010-api.md: T1 a.byn: i32 one(i32 x): not declared verbatim in src/semantics/a.byn"
good
edit 's/^bool three() {/bool three(), x {/' "$t/src/semantics/a.byn"
expect "signature followed by other text" 1 "T2 a.byn: bool three(): not declared verbatim"
good
edit 's/^    uses alloc {/    uses io {/' "$t/src/semantics/a.byn"
expect "joined uses clause differs" 1 "T1 a.byn: i32 two(ref Ctx c, i32 y) uses alloc: not declared verbatim"
good
printf -- '- T3 a.byn: bool four()\n' >> "$i010"
expect "malformed index line" 1 "010-api.md: malformed index line: - T3 a.byn: bool four()"
good
printf -- '- T3 gone.byn: bool four()  ← G.cs:1 Four\n' >> "$i010"
expect "missing file" 1 "T3 gone.byn: no file src/semantics/gone.byn"
good
printf '# no entries\n' > "$i010"
expect "no entries" 1 "010-api.md: no \`- T\` index lines"
good
edit 's/versionLine()/versionLine2()/' "$t/src/driver/main.byn"
expect "012 entry missing" 1 "012-api.md: T1 driver/main.byn: string versionLine(): not declared verbatim in src/driver/main.byn"
good
printf 'string versionLine(\n) {\n}\n' > "$t/src/driver/main.byn"
expect "012 does not join wrapped lists" 1 "T1 driver/main.byn: string versionLine(): not declared verbatim"
good
edit 's/^void e(i32 a)/void e(i32 b)/' "$t/src/emitter/e.byn"
expect "011 entry missing" 1 "011-api.md: T1 emitter/e.byn: void e(i32 a): not declared verbatim in src/emitter/e.byn"
good
edit 's/LoweredNodes.cs:118/LoweredNodes.cs:119/' "$i011"
expect "011 round-four table gone" 1 "011-api.md does not hold \`LoweredNodes.cs:118\`"
good
edit 's/`1942-1945`/`1942`/' "$i011"
expect "011 CEmitter lines gone" 1 "011-api.md does not hold \`CEmitter.cs:1937\`, \`1942-1945\`, \`1961\`"
good
edit 's/round 4 redoes/round 5 redoes/' "$t/src/emitter/ltree/ltree.byn"
expect "ltree marker gone" 1 "src/emitter/ltree/ltree.byn has no '// Q1: round 4 redoes this' line"
good
edit 's/^$/    let x = 1/' "$t/src/emitter/ltree/ltree.byn"
expect "ltree marker not before env" 1 "src/emitter/ltree/ltree.byn has no"
rm -rf "$t"
echo "api-index-check.test: ok"
