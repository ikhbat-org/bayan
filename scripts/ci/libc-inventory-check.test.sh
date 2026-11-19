#!/usr/bin/env bash
# Tests scripts/ci/libc-inventory-check.sh on a fixture tree under tmp/.
# Runtime list (LibcListIsTheRuntimesLibcCalls): a clean pass (calls in comments and literals, after `.` and `->`, of byn_
# names and of statements not counted; a call split over two lines and one in the header counted), then a call not listed,
# a listed name not called, an unsorted list, a list without memcpy, a table line that is not a row.
# Emitted C (--emitted <dir>): ScanFindsAnUnlistedLibcCall's unit gives exactly strlen (passes when the inventory lists only
# strlen, reports it when not); ScanFindsABraceAssembledAcrossLiterals's unit reports `({`, against the fixture and the repo
# inventory; row tokens and an attribute list split per item; a listed call no unit makes; a *_C macro; a directory with no .c.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/libc-inventory-check-test"; rm -rf "$t"; mkdir -p "$t"
chk="$root/scripts/ci/libc-inventory-check.sh"
run_check() { rc=0; out="$(bash "$chk" "$@" 2>&1)" || rc=$?; }
expect() { # name exit text [check arguments...]: the output must hold text unless it is empty
  local name="$1" want="$2" text="$3"; shift 3
  run_check "$@"
  [ "$rc" = "$want" ] || fail "$name: exit $rc, wanted $want: $out"
  [ -z "$text" ] || grep -qF -- "$text" <<<"$out" || fail "$name: no '$text' in: $out"
}
inv="$t/docs/specs/011-self-hosted-emitter/011-c-inventory.md"
u="$t/units"
good() {
  rm -rf "$t/runtime" "$t/docs" "$u"; mkdir -p "$t/runtime" "${inv%/*}" "$u"
  cat > "$t/runtime/bayan-rt.c" <<'EOF'
#include <string.h>
/* strcpy(x) in a comment, "quoted" */
static int byn_f(const char* s) {
    // puts("no")
    const char* t = "printf(\"x\")";
    char c = '(';
    if (s->len(1) || x.y(2)) return sizeof(c);
    return (int)strlen(s) + memcmp(s, t, 1) + strchr
        (s, 1);
}
int byn_g(void) { return byn_f("a"); }
EOF
  printf '#define BYN_X(a) memcpy(a, a, 0)\nvoid* byn_h(void);\n' > "$t/runtime/bayan-rt.h"
  printf 'memcmp\nmemcpy\nstrchr\nstrlen\n' > "$t/runtime/libc-uses.txt"
  cat > "$inv" <<'EOF'
# inventory

| Site | Token | Why it is needed |
|---|---|---|
| runtime/bayan-rt.h `#define BYN_UNLIKELY(x) __builtin_expect` | `__builtin_expect` | Branch hint. |
| runtime/bayan-rt.h `#define BYN_NORETURN __attribute__` | `__attribute__((noreturn))` | No return. |

## Direct libc calls

- `strlen`
EOF
}
edit() { sed -i.bak "$1" "$2"; rm "$2.bak"; }

good
expect "runtime clean" 0 "libc-inventory-check: ok" "$t"
edit 's/^int byn_g(void) {/int byn_g(void) { abort();/' "$t/runtime/bayan-rt.c"
expect "runtime call not listed" 1 "called by the runtime but not in runtime/libc-uses.txt: abort" "$t"
good
edit 's/ + strchr$/;/; /^        (s, 1);$/d' "$t/runtime/bayan-rt.c"
expect "runtime listed, not called" 1 "in runtime/libc-uses.txt but not called by the runtime: strchr" "$t"
good
printf 'memcmp\nstrchr\nmemcpy\nstrlen\n' > "$t/runtime/libc-uses.txt"
expect "runtime list unsorted" 1 "runtime/libc-uses.txt is not sorted" "$t"
good
edit 's/memcpy(a, a, 0)/strlen(a)/' "$t/runtime/bayan-rt.h"; printf 'memcmp\nstrchr\nstrlen\n' > "$t/runtime/libc-uses.txt"
expect "runtime list without memcpy" 1 "runtime/libc-uses.txt does not list memcpy" "$t"
good
printf '| runtime/bayan-rt.h | `asm` | no anchor |\n' >> "$inv"
expect "inventory line not a row" 1 "011-c-inventory.md: table line is not a row: | runtime/bayan-rt.h | \`asm\` | no anchor |" "$t"

# ScanFindsAnUnlistedLibcCall: the unit's direct calls are exactly strlen (f is defined at column 0, return is a statement)
good
printf 'int f(const char* s) {\n    return strlen(s);\n}\nint g(void) {\n    return f("a");\n}\n' > "$u/unlisted.c"
expect "emitted calls are the list" 0 "libc-inventory-check: ok" --emitted "$u" "$t"
edit '/^- `strlen`$/d' "$inv"
expect "emitted call not listed" 1 "direct libc call in emitted C not listed in 011-c-inventory.md: strlen" --emitted "$u" "$t"
good
printf 'int f(void) {\n    return INT8_C(1) + atoi("1");\n}\n' > "$u/other.c"
expect "emitted listed, not called" 1 "listed in 011-c-inventory.md but no emitted unit calls it: strlen" --emitted "$u" "$t"
grep -qF "atoi" <<<"$out" || fail "emitted atoi not reported: $out"
! grep -qF "INT8_C" <<<"$out" || fail "emitted *_C macro reported: $out"
# ScanFindsABraceAssembledAcrossLiterals
good
printf 'int f(void) { return ({ 1; }); }\n' > "$u/brace.c"
printf 'int h(const char* s) {\n    return strlen(s);\n}\n' > "$u/call.c"
expect "emitted brace" 1 "extension token without a row in 011-c-inventory.md: ({ (first in brace.c)" --emitted "$u" "$t"
expect "emitted brace, repo inventory" 1 "extension token without a row in 011-c-inventory.md: ({" --emitted "$u" "$root"
rm "$u/brace.c"
printf 'static __attribute__((noreturn)) int z;\nint m(int x) {\n    return __builtin_expect(x, 0) + strlen("");\n}\n' > "$u/rows.c"
expect "emitted row tokens" 0 "libc-inventory-check: ok" --emitted "$u" "$t"
edit 's/((noreturn))/((noreturn, cold))/' "$u/rows.c"
expect "emitted attribute list split" 1 "extension token without a row in 011-c-inventory.md: __attribute__((cold)) (first in rows.c)" --emitted "$u" "$t"
! grep -qF "noreturn" <<<"$out" || fail "emitted noreturn reported: $out"
rm -f "$u"/*.c
expect "emitted directory with no .c" 2 "no .c file in" --emitted "$u" "$t"
rm -rf "$t"
echo "libc-inventory-check.test: ok"
