#!/usr/bin/env bash
# Generates docs/DIAGNOSTICS.md, the diagnostics index: every code registered in
# the self-hosted message tables (src/lexer/diagnostics.byn, src/parser/codes.byn, src/semantics/codes.byn), then the
# plan, reserved and retired lists. Retired and reserved codes, the round-4 block and the few names and severities the
# tables do not give are the rows of scripts/docs/data/csharp-facts.tsv (read once from the retired C# DiagnosticCodes.cs); plan codes and reservations without a descriptor or comment come from the hand-kept
# docs/diagnostics-allocated.txt. Deterministic: sorted by code, LF, no dates.
#   gen-diagnostics.sh            print it
#   gen-diagnostics.sh --write    write docs/DIAGNOSTICS.md
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$root/scripts/release/version.sh"
die() { echo "gen-diagnostics: $*" >&2; exit 1; }
facts_tsv="$root/scripts/docs/data/csharp-facts.tsv"
lists="$root/docs/diagnostics-allocated.txt"
[ -f "$facts_tsv" ] || die "scripts/docs/data/csharp-facts.tsv not found"
[ -f "$lists" ] || die "docs/diagnostics-allocated.txt not found"
v="$(bayan_version "$root")"; rev="$(bayan_latest_revision "$root")"
[ -n "$rev" ] || die "no docs/revisions/NNNN-*.md"
t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
export LC_ALL=C

# Markdown table cell: a literal | is escaped.
cell() { sed -E 's/\|/\\|/g'; }

# C#-only facts from the TSV: desc (code, .byn member, C# name), severity (code, severity), retired and reserved
# (code, note), round4 (code, name, note)
facts() { awk -F'\t' -v OFS='\t' -v k="$1" '$1 == k { $1 = ""; sub(/^\t/, ""); print }' "$facts_tsv"; }
facts desc > "$t/desc"; facts severity > "$t/sev"
facts retired | cell | sort -k1,1 > "$t/retired"; facts reserved | cell | sort -k1,1 > "$t/reserved"; facts round4 | cell | sort -k1,1 > "$t/round4"
# code, member, message, warning-or-empty for every case of the three message tables (lexer, parser, semantics), in
# declaration order; a lexer code is its ordinal + 1 (blockComment is BYN1047), the others are `codeText`'s strings.
for f in lexer/diagnostics parser/codes semantics/codes; do
  awk -v lex="$([ "$f" = lexer/diagnostics ] && echo 1 || echo 0)" '
    /^(public )?enum / { en = 1; n = 0; next }
    en && /^}/ { en = 0; next }
    en { gsub(/[ \t]/, ""); if ($0 != "" && $0 !~ /^\/\//) { order[++n] = $0; ord[$0] = n } next }
    /^string codeText\(/ { fn = "code"; next }
    /^string messageFormat\(/ { fn = "msg"; next }
    /^bool isWarning\(/ { fn = "warn"; next }
    /^}/ { fn = ""; next }
    fn == "warn" { s = $0; while (match(s, /\.[A-Za-z0-9]+/)) { warn[substr(s, RSTART + 1, RLENGTH - 1)] = 1; s = substr(s, RSTART + RLENGTH) } }
    (fn == "code" || fn == "msg") && match($0, /^ *\.[A-Za-z0-9]+ +=> +"/) {
      m = substr($0, RSTART, RLENGTH); sub(/^ *\./, "", m); sub(/ .*/, "", m)
      v = substr($0, RSTART + RLENGTH); sub(/",? *$/, "", v)
      if (fn == "code") code[m] = v; else msg[m] = v }
    END { for (i = 1; i <= n; i++) { m = order[i]
            if (lex) code[m] = (m == "blockComment") ? "BYN1047" : sprintf("BYN%04d", i)
            if (m in code && m in msg) print code[m] "\t" m "\t" msg[m] "\t" ((m in warn) ? "Warning" : "") } }' "$root/src/$f.byn"
done > "$t/byn"
[ -s "$t/byn" ] || die "no message tables in src/lexer, src/parser, src/semantics"
# code, name, severity, message: the first case of a code, unless a desc row names another; the name is the member with
# its first letter raised, unless a desc row gives it
awk -F'\t' -v OFS='\t' 'FILENAME == d { want[$1] = $2; nm[$1] = $3; next } FILENAME == v { sv[$1] = $2; next }
  { c = $1; if (c in want ? $2 != want[c] : seen[c]++) next; seen[c] = 1
    n = (c in nm) ? nm[c] : toupper(substr($2, 1, 1)) substr($2, 2)
    print c, n, (c in sv) ? sv[c] : ($4 != "" ? $4 : "Error"), $3 }' d="$t/desc" v="$t/sev" "$t/desc" "$t/sev" "$t/byn" \
  | sed -E 's/\\"/"/g; s/\\\\/\\/g' | cell | sort -k1,1 > "$t/reg"
[ -s "$t/reg" ] || die "no descriptors in the message tables"
dup="$(cut -f1 "$t/reg" | uniq -d)"; [ -z "$dup" ] || die "registered twice: $dup"
# status, code, name, note from the hand-kept file
grep -vE '^(#|[[:space:]]*$)' "$lists" | sed -E 's/^([a-z]+) (BYN[0-9]{4}) ([^ ]+) (.*)$/\1	\2	\3	\4/' > "$t/hand" || true
awk -F'\t' 'NF != 4 || $1 !~ /^(plan|reserved|retired)$/ { print "docs/diagnostics-allocated.txt: bad line: " $0; bad = 1 } END { exit bad }' "$t/hand" >&2 \
  || die "each line is: plan|reserved|retired BYNnnnn Name-or-- note"
# A hand-kept code is listed once, and has no comment line in DiagnosticCodes.cs; a plan code has no descriptor.
clash="$( (cut -f1 "$t/retired" "$t/reserved" "$t/round4"; cut -f2 "$t/hand") | sort | uniq -d | tr '\n' ' ')"
[ -z "$clash" ] || die "listed twice (DiagnosticCodes.cs comments and docs/diagnostics-allocated.txt, or twice in one): $clash"
clash="$( (cut -f1 "$t/reg"; awk -F'\t' '$1 == "plan" { print $2 }' "$t/hand") | sort | uniq -d | tr '\n' ' ')"
[ -z "$clash" ] || die "plan codes in docs/diagnostics-allocated.txt have a descriptor: $clash"
# Hand-kept retired and reserved codes that have a descriptor take that status in the registered table.
awk -F'\t' '$1 != "plan" { print $2 "\t" $1 }' "$t/hand" | sort -k1,1 > "$t/hand-status"

name_of() { awk -F'\t' -v c="$1" '$1 == c { print $2 }' "$t/reg"; }
link() { if [ -f "$root/docs/diagnostics/$1.md" ]; then printf '[%s](diagnostics/%s.md)' "$1" "$1"; else printf '%s' "$1"; fi; }
hand() { awk -F'\t' -v s="$1" '$1 == s { print $2 "\t" $3 "\t" $4 }' "$t/hand" | cell | sort -k1,1; }

n_reg="$(wc -l < "$t/reg" | tr -d ' ')"
n_ret="$(( $(wc -l < "$t/retired") + $(hand retired | wc -l) ))"
n_res="$(( $(wc -l < "$t/reserved") + $(wc -l < "$t/round4") + $(hand reserved | wc -l) ))"
n_plan="$(hand plan | wc -l | tr -d ' ')"
n_live="$(( n_reg - $(wc -l < "$t/retired") - $(wc -l < "$t/reserved") - $(cut -f1 "$t/hand-status" | grep -cFxf - <(cut -f1 "$t/reg") || true) ))"

gen() {
  cat <<EOF
# Bayān diagnostics

Version: $v (matches \`bayan --version\`)
Revisions applied: 0001–$rev

Generated by \`scripts/docs/gen-diagnostics.sh\` from the self-hosted message tables (\`src/lexer/diagnostics.byn\`, \`src/parser/codes.byn\`, \`src/semantics/codes.byn\`), \`scripts/docs/data/csharp-facts.tsv\` (the retired and reserved rows of the C# \`DiagnosticCodes.cs\`, tag \`csharp-final\`), \`docs/diagnostics/\` (one page per code) and \`docs/diagnostics-allocated.txt\` (hand-kept: plan codes allocated in a plan, spec or revision, and reservations with no descriptor). Do not edit by hand; \`scripts/docs/check.sh\` fails when this file is stale. Message text is the format string as written in the source: \`{0}\` is an argument, \`{{\` and \`}}\` are literal braces. Severity is a default; it is not encoded in the number (revision 0017, rule 5).

## Status

- \`live\`: a descriptor in \`DiagnosticCodes.cs\` that is neither retired nor reserved. \`scripts/ci/diagnostic-codes.test.sh\` requires a \`docs/diagnostics/\` page and a golden for each.
- \`plan\`: allocated, with a name, in a plan, spec or revision, but absent from \`DiagnosticCodes.cs\`.
- \`reserved\`: the number is set aside (a descriptor kept for a later feature, a \`// Reserved: round 4\` line, or a hand-kept reservation) and nothing reports it.
- \`retired\`: never reported again; the number is never reused.

## Counts

| Status | Codes |
|---|---|
| live | $n_live |
| plan | $n_plan |
| reserved | $n_res |
| retired | $n_ret |
| total | $(( n_live + n_plan + n_res + n_ret )) |

## Registered codes (\`DiagnosticCodes.cs\`)

| Code | Name | Severity | Status | Message |
|---|---|---|---|---|
EOF
  while IFS=$'\t' read -r code name sev msg; do
    st=live
    grep -q "^$code	" "$t/retired" && st=retired
    grep -q "^$code	" "$t/reserved" && st=reserved
    h="$(awk -F'\t' -v c="$code" '$1 == c { print $2 }' "$t/hand-status")"; [ -z "$h" ] || st="$h"
    printf '| %s | %s | %s | %s | %s |\n' "$(link "$code")" "$name" "$sev" "$st" "$msg"
  done < "$t/reg"
  printf '\n## Plan\n\nFrom `docs/diagnostics-allocated.txt`.\n\n| Code | Name | Note |\n|---|---|---|\n'
  hand plan | while IFS=$'\t' read -r code name note; do printf '| %s | %s | %s |\n' "$code" "$name" "$note"; done
  printf '\n## Reserved\n\n| Code | Name | Note | Source |\n|---|---|---|---|\n'
  { while IFS=$'\t' read -r code note; do printf '%s\t%s\t%s\t%s\n' "$code" "$(name_of "$code")" "$note" '`DiagnosticCodes.cs` descriptor'; done < "$t/reserved"
    while IFS=$'\t' read -r code name note; do printf '%s\t%s\t%s\t%s\n' "$code" "$name" "$note" '`DiagnosticCodes.cs` round-4 block'; done < "$t/round4"
    hand reserved | while IFS=$'\t' read -r code name note; do printf '%s\t%s\t%s\t%s\n' "$code" "$name" "$note" '`docs/diagnostics-allocated.txt`'; done
  } | sort -k1,1 | while IFS=$'\t' read -r code name note src; do printf '| %s | %s | %s | %s |\n' "$(link "$code")" "$name" "$note" "$src"; done
  printf '\n## Retired\n\n| Code | Name | Note | Source |\n|---|---|---|---|\n'
  { while IFS=$'\t' read -r code note; do printf '%s\t%s\t%s\t%s\n' "$code" "$(name_of "$code")" "$note" '`DiagnosticCodes.cs` descriptor'; done < "$t/retired"
    hand retired | while IFS=$'\t' read -r code name note; do printf '%s\t%s\t%s\t%s\n' "$code" "$name" "$note" '`docs/diagnostics-allocated.txt`'; done
  } | sort -k1,1 | while IFS=$'\t' read -r code name note src; do printf '| %s | %s | %s | %s |\n' "$(link "$code")" "$name" "$note" "$src"; done
}

if [ "${1:-}" = --write ]; then gen > "$t/out"; cat "$t/out" > "$root/docs/DIAGNOSTICS.md"; else gen; fi
