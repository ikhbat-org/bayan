#!/usr/bin/env bash
# Tests tools/safety-mutate.byn on fixtures (one site of a kind gives one mutant with its `// expect:` line; decoys give
# none) and classify of scripts/hardening/safety-mutate.sh on fake check outputs. SAFETY_MUTATE overrides the script.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=safety-mutate.sh
source "${SAFETY_MUTATE:-$root/scripts/hardening/safety-mutate.sh}"
mkdir -p "$root/tmp"; tmp="$(mktemp -d "$root/tmp/safety-mutate-test.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

pass=0; failed=0
check() { if [ "$2" = 0 ]; then pass=$((pass + 1)); else failed=$((failed + 1)); echo "FAIL: $1"; fi; }

# mutate <name>: the tool on $tmp/<name>.byn into $tmp/out-<name>, its lines in $tmp/<name>.lines
mutate() { bash "$root/scripts/bayan-tool.sh" safety-mutate "$tmp/$1.byn" "$tmp/out-$1" >"$tmp/$1.lines" 2>&1; }
# one <name> <kind> <code> <inserted line>: exactly one mutant, of <kind>, expecting <code>, holding <inserted line>
one() {
    local p
    mutate "$1" && [ "$(wc -l <"$tmp/$1.lines" | tr -d ' ')" = 1 ] && p=$(cut -f2 "$tmp/$1.lines") \
        && [ "$(cut -f1,3 "$tmp/$1.lines")" = "$2"$'\t'"$3" ] && [ "$p" = "$tmp/out-$1/$1.$2.1.byn" ] \
        && [ "$(head -n 1 "$p")" = "// expect: $3" ] && grep -qxF "$4" "$p"
}

cat >"$tmp/uam.byn" <<'E'
void consume(List<i64> xs) {
}
void main() {
    var x = List<i64>()
    consume(move x)
}
E
one uam use-after-move BYN2781 '    let _ = x'; check "a move of a local gets a read after it" $?

cat >"$tmp/esc.byn" <<'E'
string name(i64 n) {
    return "a"
}
E
one esc borrow-escape BYN3003 '    return mutantSb.finish()' && grep -qxF '    let mutantBuf = stackalloc u8[16]' "$tmp/out-esc/esc.borrow-escape.1.byn"
check "a function returning string gets a returned borrow of a stackalloc local" $?

cat >"$tmp/wwb.byn" <<'E'
void main() {
    var xs = List<i64>()
    let view = xs.span
}
E
one wwb write-while-borrowed BYN3004 '    let _ = xs.removeLast()' && grep -qxF '    let _ = view.length' "$tmp/out-wwb/wwb.write-while-borrowed.1.byn"
check "a span of a local gets a write and a later use of the span" $?

cat >"$tmp/wwa.byn" <<'E'
void main() {
    using var arena = Arena()
    let name = "a".copy(to: arena)
}
E
one wwa write-while-borrowed BYN3004 '    arena.reset()' && grep -qxF '    let _ = name' "$tmp/out-wwa/wwa.write-while-borrowed.1.byn"
check "a copy into a var arena gets a reset and a later use of the copy" $?

cat >"$tmp/eff.byn" <<'E'
void g() uses alloc {
}
E
one eff effect-outside-uses BYN6002 '    print("mutant")'; check "a uses clause without console gets a print" $?

cat >"$tmp/effp.byn" <<'E'
public i64 f(i64 a) {
    return a
}
E
one effp effect-outside-uses BYN6002 '    print("mutant")'; check "a public function without uses gets a print" $?

cat >"$tmp/untd.byn" <<'E'
let u: Untrusted<List<string>> = Untrusted(List<string>())
E
one untd untrusted-to-trusted BYN2202 'let mutantTrusted: List<string> = u'; check "an Untrusted local is read as its T" $?

cat >"$tmp/untr.byn" <<'E'
void main() fails IoError {
    let u = Untrusted("git")
    let _ = try Io.run(u.trustUnchecked() because "checked", [])
}
E
one untr untrusted-to-trusted BYN2786 '    let _ = try Io.run(u, [])'; check "a trustUnchecked passed to Io.run is removed" $?

# decoys: a moved parameter type, a deferred move, a move in a string, a function-level arena, a span of a field, a
# function with an inferred or console effect, the entry function, a list of Untrusted, a string? or `=>` function
cat >"$tmp/none.byn" <<'E'
T pick<T>(move T a, by move T b) => move a
string? opt() {
}
string label() => "a"
void consume(List<i64> xs) {
}
void h(List<i64> y) uses console {
    defer consume(move y)
    print("move z)")
    using var arena = Arena()
    let v = this.xs.span
}
void k() {
    let s: List<Untrusted<string>> = []
}
public void main() uses fs {
}
E
mutate none && [ ! -s "$tmp/none.lines" ]; check "no site gives no mutant" $?

printf 'error BYN2781: x\nerror BYN2780: y\n' >"$tmp/o1"; printf 'error BYN2780: y\n' >"$tmp/o2"; : >"$tmp/o3"
[ "$(classify 1 BYN2781 "$tmp/o1")" = killed ]; check "rejected with the expected code is killed" $?
[ "$(classify 1 BYN2781 "$tmp/o2")" = discarded ]; check "rejected with other codes only is discarded" $?
[ "$(classify 0 BYN2781 "$tmp/o3")" = accepted ]; check "exit 0 is accepted" $?
[ "$(classify 0 BYN2781 "$tmp/o1")" = accepted ]; check "exit 0 is accepted whatever the output" $?

echo "$pass passed, $failed failed"
[ "$failed" = 0 ]
