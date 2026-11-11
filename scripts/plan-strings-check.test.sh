#!/usr/bin/env bash
# plan-strings-check (tools/plan-strings-check.byn, run by scripts/bayan-tool.sh) on a fixture repo under tmp/: plan strings
# copied verbatim pass with the codes found from the descriptor diff; a help that drifts from the plan fails and names it;
# a page without the plan's strings fails; a plan help without a leading verb fails, alone and in --all-help; `{{ }}`
# escapes and a `(plan, revision NNNN)` tag are matched.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
d="$root/tmp/plan-strings-check-test"
trap 'rm -rf "$d"' EXIT
fail() { echo "FAIL: $1"; echo "$2"; exit 1; }
put() { mkdir -p "$d/$(dirname "$1")"; printf '%s\n' "$2" > "$d/$1"; }
page() { printf '# %s: title\n\n**Message.** %s\n\n**Help.** %s\n' "$1" "$2" "$3"; }
g() { git -C "$d" -c user.email=t@t -c user.name=t "$@"; }
check() { (cd "$d" && bash "$root/scripts/bayan-tool.sh" plan-strings-check "$@") && echo "rc=0" || echo "rc=$?"; }
plan=docs/plans/2026-10-22-002-design-round-3.md

# fixture <help of BYN1044 in Parser.cs>
fixture() {
  rm -rf "$d"; mkdir -p "$d"
  put $plan '- (c) BYN1044 `KeywordOrder` "`{0}` is an input form; write `{1}`" (label at the keywords; help "put the kind first: `{1}`"; fix yes).
- (c) BYN1043 `TypeNameOrder` (revised), two forms. A field: "`{0}: {1}` is an input form; write `{1} {0}`" (label "name before type"; help "put the type before the name; declarations are type-first"; fix yes).
- (c) BYN1053 `OneLine` "`{0}` declares its cases on one line" (O1; label at the first `,`; help "write each case on its own line"; fix yes).
- (c) BYN6006 `ContextInput` "`context (…) { }` is now `provide … { }`" (label at `context`; help "write `provide`"; fix yes).'
  put src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs 'class DiagnosticCodes {}'
  put tests/Bayan.Tests/HelpLanguageTests.cs '    private static readonly Dictionary<string, string> Allowed = new()
    {
        ["did you mean `"] = "question",
    };'
  put src/Bayan.Semantics/Lexicon.cs '    public static readonly FrozenSet<string> Verbs = [
        "put", "write",
    ];'
  g init -q -b dev; g add -A; g commit -q --no-verify -m base
  put src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs 'class DiagnosticCodes {
    public static readonly DiagnosticDescriptor KeywordOrder = Error("BYN1044", "`{0}` is an input form; write `{1}`");
    public static readonly DiagnosticDescriptor TypeNameOrder = Error("BYN1043", "`{0}` is an input form; write `{1}`");
    public static readonly DiagnosticDescriptor OneLine = Error("BYN1053", "`{0}` declares its cases on one line");
    public static readonly DiagnosticDescriptor ContextInput = Error("BYN6006", "`context (…) {{ }}` is now `provide … {{ }}`");
}'
  put src/Bayan.Syntax/Parsing/Parser.cs "class Parser {
    void A() { Report(KeywordOrder, help: \$\"$1\"); }
    void B() { Report(TypeNameOrder, help: \"put the type before the name; declarations are type-first\"); }
    void C() { Report(OneLine, help: \"write each case on its own line\"); }
    void D() { Report(ContextInput, help: \"write \`provide\`\"); }
}"
  put tests/cases/diag/field.diag 'error[BYN1043]: `x: i64` is an input form; write `i64 x`'; mkdir -p "$d/docs/diagnostics"
  page BYN1044 '`{0}` is an input form; write `{1}`' 'put the kind first: `{1}`' > "$d/docs/diagnostics/BYN1044.md"
  page BYN1043 '`x: i64` is an input form; write `i64 x`' 'put the type before the name; declarations are type-first' > "$d/docs/diagnostics/BYN1043.md"
  page BYN1053 '`{0}` declares its cases on one line' 'write each case on its own line' > "$d/docs/diagnostics/BYN1053.md"
  page BYN6006 '`context (…) { }` is now `provide … { }`' 'write `provide`' > "$d/docs/diagnostics/BYN6006.md"
  g checkout -q -b feat/x; g add -A; g commit -q --no-verify -m step
}

fixture 'put the kind first: `{canonical}`'
out=$(check)
grep -qx 'all plan strings found for 4 code(s)' <<< "$out" && grep -qx rc=0 <<< "$out" || fail "plan strings copied verbatim did not pass from the descriptor diff" "$out"

fixture 'write the kind before the modifier: `{canonical}`'
out=$(check BYN1044)
grep -qxF 'BYN1044 help not in src/: "put the kind first: `{1}`"' <<< "$out" && grep -qx rc=1 <<< "$out" || fail "a help that drifts from the plan passed" "$out"

fixture 'put the kind first: `{canonical}`'
printf '# BYN1053: title\n\n**Why.** prose only\n' > "$d/docs/diagnostics/BYN1053.md"
out=$(check BYN1053)
grep -q '^BYN1053 help not in docs/diagnostics/BYN1053.md' <<< "$out" && grep -q '^BYN1053 message not in docs/diagnostics/BYN1053.md' <<< "$out" \
  && grep -qx rc=1 <<< "$out" || fail "a page without the plan's strings passed" "$out"

fixture 'put the kind first: `{canonical}`'
cp "$d/$plan" "$d/plan.orig"
sed 's/help "write each case on its own line"/help "each case goes on its own line"/' "$d/plan.orig" > "$d/$plan"
out=$(check BYN1053)
grep -qxF 'BYN1053 help in the plan does not start with a verb from src/Bayan.Semantics/Lexicon.cs: "each case goes on its own line"' <<< "$out" \
  && grep -qx rc=1 <<< "$out" || fail "a plan help without a leading verb passed" "$out"
out=$(check --all-help)
grep -qx '1 plan help(s) without a leading verb' <<< "$out" && grep -qx rc=1 <<< "$out" || fail "--all-help passed a help without a leading verb" "$out"
cp "$d/plan.orig" "$d/$plan"
out=$(check --all-help)
grep -qx rc=0 <<< "$out" || fail "--all-help failed a plan whose helps all start with a verb" "$out"

fixture 'put the kind first: `{canonical}`'
printf '%s\n' '- (c) BYN7005 `StateLiteralNeedsState` "`{0}` has states; write `{0}.{1} {{ … }}`" (label at the type name; help "write the state"; fix no). BYN7008 (plan) `StateShadowsStatic` "state `.{0}` shadows `{1}.{0}`" (label at the state; help "write another name"; fix no). BYN7009 (plan, revision 0002) `MissingBecome` "`{0}` returns without `become`" (label at the return; help "write `become .{1}(…)`"; fix no).' >> "$d/$plan"
put src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs 'class DiagnosticCodes {
    public static readonly DiagnosticDescriptor StateLiteralNeedsState = Error("BYN7005", "`{0}` has states; write `{0}.{1} {{ … }}`");
    public static readonly DiagnosticDescriptor StateShadowsStatic = Error("BYN7008", "state `.{0}` shadows `{1}.{0}`");
}'
put src/Bayan.Syntax/Parsing/States.cs 'class S { void A() { Help("write the state"); Help("write another name"); } }'
page BYN7005 '`{0}` has states; write `{0}.{1} { … }`' 'write the state' > "$d/docs/diagnostics/BYN7005.md"
page BYN7008 'state `.{0}` shadows `{1}.{0}`' 'write another name' > "$d/docs/diagnostics/BYN7008.md"
g add -A
out=$(check BYN7005 BYN7008)
grep -qx 'all plan strings found for 2 code(s)' <<< "$out" && grep -qx rc=0 <<< "$out" || fail "{{ }} escapes or a (plan, revision NNNN) tag did not match" "$out"
echo PASS
