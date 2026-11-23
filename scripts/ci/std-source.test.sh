#!/usr/bin/env bash
# Ported from SelfhostStdSourceTests (spec 019 T26): src/semantics/stdsource.byn is what scripts/selfhost/gen-stdsource.sh
# makes of lib/std (std-source-equals-lib-std), and the generator lists every file of a fixture tree (generated-file-lists-every-file).
# BAYAN_UPDATE=1 rewrites the file first. No bayan binary, no dotnet; bash 3.2.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
fail() { echo "FAIL $1"; exit 1; }
gen=scripts/selfhost/gen-stdsource.sh
file=src/semantics/stdsource.byn

[ -z "${BAYAN_UPDATE:-}" ] || bash "$gen" > "$file"
bash "$gen" | cmp -s - "$file" || fail "std-source-equals-lib-std: $file is not what $gen makes of lib/std (BAYAN_UPDATE=1 regenerates it)"

# A nested module, a test file and text with braces, which lib/std need not hold.
t="$root/tmp/std-source-fixture"; rm -rf "$t"; mkdir -p "$t/probe" "$t/a/b"
printf 'public i64 one() {\n    return 1\n}\n' > "$t/probe/probe.byn"
printf 'test "t" {}\n' > "$t/probe/probe.test.byn"
printf '// {x}\n' > "$t/a/b/b.byn"
out="$(bash "$gen" "$t")"
listed="$(grep -E '^    sources\.append' <<<"$out" | sed -E 's/^.*path: "([^"]*)".*$/\1/' | tr '\n' ' ')"
[ "$listed" = "a/b/b.byn probe/probe.byn probe/probe.test.byn " ] || fail "generated-file-lists-every-file: listed [$listed]"
grep -qF 'const stdSource0: string = """// {x}
"""' <<<"$out" || fail "generated-file-lists-every-file: text of a/b/b.byn not carried"
echo "std-source: ok"
