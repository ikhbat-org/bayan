#!/usr/bin/env bash
# Spec 019 T10 gate: the golden runner (`bayan test tests/cases`) and the xUnit classes that read tests/cases/ agree on
# every case of the 12 kinds, and the five `style` shapes the runner skips are each covered by a test block that exists
# and passes. Run from anywhere in the repo, once per OS (macOS, Linux, Windows under Git Bash). bash 3.2, POSIX tools.
# Prints per kind the runner's and xUnit's passed/failed/skipped counts and every case in one set and not the other,
# then the style table. Exit 0 only when all 12 kinds agree and the five covering blocks exist and pass.
#   BAYAN_EXE    the self-hosted driver; unset, src/driver is built with the pinned bayan at HEAD into tmp/t10/bayan
#   T10_JOBS     the runner's --jobs (default 4, xunit.runner.json's maxParallelThreads)
#   T10_RESULTS  reuse this results.json instead of running the runner
#   T10_TRX      reuse this .trx instead of running dotnet test
# "skipped" on the xUnit side is a `run` case whose `// os:` line names another OS: RunGolden returns early and xUnit
# reports it passed (RunTests.cs:46-47); the runner reports it skipped. Both sides are counted as skipped for it.
set -uo pipefail
export MSBUILDDISABLENODEREUSE=1 DOTNET_CLI_USE_MSBUILD_SERVER=0
cd "$(git rev-parse --show-toplevel)" || exit 2
root="$PWD"
out="$root/tmp/t10"
mkdir -p "$out"
kinds="diag run parse style lex manifest typed diag-json new out emit quality"
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) os=windows; other="// os: unix" ;; *) os=unix; other="// os: windows" ;; esac

# 1. The driver.
if [ -z "${BAYAN_EXE:-}" ]; then
  BAYAN_EXE="$out/bayan"; [ "$os" = windows ] && BAYAN_EXE="$out/bayan.exe"
  echo "t10: building src/driver into $BAYAN_EXE" >&2
  pinned="$(PINNED_BAYAN_REF="${PINNED_BAYAN_REF:-HEAD}" bash scripts/pinned-bayan.sh)" \
    && "$pinned" build --mode safe --package src -o "$BAYAN_EXE" src/driver > "$out/build.log" 2>&1 || { echo "t10: build of src/driver failed" >&2; exit 2; }
fi
export BAYAN_EXE
echo "t10: BAYAN_EXE=$BAYAN_EXE ($("$BAYAN_EXE" --version 2>&1 | head -1))"

# 2. The runner: results.json -> lines `kind<TAB>case<TAB>status` (passed, failed, skipped) and the skip details.
if [ -n "${T10_RESULTS:-}" ]; then
  cp "$T10_RESULTS" "$out/results.json"
else
  echo "t10: runner: $BAYAN_EXE test tests/cases --json --jobs ${T10_JOBS:-4}" >&2
  start=$(date +%s)
  "$BAYAN_EXE" test tests/cases --json --jobs "${T10_JOBS:-4}" > "$out/runner-stdout.json" 2> "$out/runner-stderr.txt"
  echo "t10: runner exit $? in $(( $(date +%s) - start )) s" >&2
  cp out/test/results.json "$out/results.json" || { echo "t10: no out/test/results.json" >&2; exit 2; }
fi
# One entry per golden case; the writer puts each field on its own line, in the order name, ..., status, ..., output,
# kind, caseKind, path. A field value is one JSON string, so a line holds it whole.
awk '
  function val(line) { sub(/^[^:]*: *"/, "", line); sub(/",? *$/, "", line); return line }
  /^ *"name": /     { name = val($0) }
  /^ *"status": /   { status = val($0) }
  /^ *"output": /   { output = val($0) }
  /^ *"kind": /     { kind = val($0) }
  /^ *"caseKind": / {
    if (kind != "golden") next
    s = status == "pass" ? "passed" : status == "pending" ? "skipped" : "failed"
    print val($0) "\t" name "\t" s > runner
    if (s == "skipped") print name "\t" output > skips
  }
' runner="$out/runner.tsv" skips="$out/runner-skips.tsv" "$out/results.json"
: >> "$out/runner-skips.tsv"

# 3. xUnit: the methods that compare against tests/cases/, one trx; each result named as the runner names its case.
filter="FullyQualifiedName~Bayan.Tests.DiagTests.DiagGolden|FullyQualifiedName~Bayan.Tests.RunTests.RunGolden"
filter="$filter|FullyQualifiedName~Bayan.Tests.ParserTests.ParseGolden|FullyQualifiedName~Bayan.Tests.LexerTests.GoldenCase"
filter="$filter|FullyQualifiedName~Bayan.Tests.TypedDumpTests.TypedGolden|FullyQualifiedName~Bayan.Tests.ManifestTests.ManifestGolden"
filter="$filter|FullyQualifiedName~Bayan.Tests.DiagJsonTests.DiagJsonGolden|FullyQualifiedName~Bayan.Tests.StyleTests.RendersThreeWays"
filter="$filter|FullyQualifiedName~Bayan.Tests.ScaffoldTests.NewWritesTheLayout"
filter="$filter|FullyQualifiedName~Bayan.Tests.OutputTests.BuildRunAndTestWriteToOut"
filter="$filter|FullyQualifiedName~Bayan.Tests.OutputTests.FailingTestsAreReportedInTheResultsFile"
filter="$filter|FullyQualifiedName~Bayan.Tests.OutputTests.DistWritesAVersionDirectoryAndLatest"
filter="$filter|FullyQualifiedName~Bayan.Tests.MutantSchemataTests.PlainBuildEmitsTheSameC"
filter="$filter|FullyQualifiedName~Bayan.Tests.QualityReportTests.JsonMatchesTheGolden"
if [ -n "${T10_TRX:-}" ]; then
  cp "$T10_TRX" "$out/xunit.trx"
else
  rm -f "$out/xunit.trx"
  echo "t10: xunit: dotnet test csharp/tests/Bayan.Tests --filter <the 14 methods>" >&2
  start=$(date +%s)
  dotnet test csharp/tests/Bayan.Tests -p:NuGetAudit=false -v q --nologo --filter "$filter" \
    --logger "trx;LogFileName=$out/xunit.trx" > "$out/xunit-stdout.txt" 2>&1
  echo "t10: dotnet test exit $? in $(( $(date +%s) - start )) s" >&2
  [ -f "$out/xunit.trx" ] || { echo "t10: no trx; see $out/xunit-stdout.txt" >&2; exit 2; }
fi
# `<UnitTestResult ... testName="Bayan.Tests.C.M(arg: &quot;x&quot;, ...)" ... outcome="Passed"`, one element per result.
# xUnit cuts a string argument past 50 characters to `"<first 50>"···`; such a name is resolved against the case inputs
# Golden.Cases lists (`<kind>/*.byn` and `<kind>/**/main.byn`): the results sharing a cut name map onto the inputs
# starting with it when the counts match and the outcomes agree, else each of those inputs is `ambiguous`.
( cd tests/cases && find . -name '*.byn' | sed 's|^\./||' | awk -F/ 'NF == 2 || $NF == "main.byn"' ) > "$out/inputs.txt"
tr '\n' ' ' < "$out/xunit.trx" | grep -o '<UnitTestResult [^>]*>' | awk -v other="$other" -v cases="$root/tests/cases" -v inputs="$out/inputs.txt" '
  function attr(s, a,   i) { i = index(s, " " a "=\""); if (!i) return ""; s = substr(s, i + length(a) + 3); return substr(s, 1, index(s, "\"") - 1) }
  # the first quoted argument of t; cut is set when a character other than `)` or `,` follows its closing quote
  function firstArg(t,   i, rest) {
    cut = 0; i = index(t, "\""); if (!i) return ""; t = substr(t, i + 1); i = index(t, "\"")
    rest = substr(t, i + 1, 1); if (rest != ")" && rest != ",") cut = 1
    return substr(t, 1, i - 1)
  }
  function osSkipped(rel,   line, n, hit) {
    hit = 0; n = 0
    while (n < 2 && (getline line < (cases "/" rel)) > 0) { n++; sub(/\r$/, "", line); if (line == other) hit = 1 }
    close(cases "/" rel); return hit
  }
  function emit(m, a, s,   k, c) {
    if (m == "RunTests.RunGolden" && s == "passed" && osSkipped(a)) s = "skipped"
    k = a; sub(/\/.*/, "", k); c = a; sub(/\/main\.byn$/, "", c); sub(/\.byn$/, "", c)
    print k "\t" c "\t" s
  }
  BEGIN { while ((getline line < inputs) > 0) all[++nall] = line }
  {
    t = attr($0, "testName"); gsub(/&quot;/, "\"", t); o = attr($0, "outcome")
    s = o == "Passed" ? "passed" : o == "NotExecuted" ? "skipped" : "failed"
    m = t; sub(/\(.*/, "", m); n = split(m, p, "."); m = p[n - 1] "." p[n]
    a = firstArg(t)
    if (m ~ /^(DiagTests|RunTests|ParserTests|LexerTests|TypedDumpTests|ManifestTests|DiagJsonTests)\./) {
      if (cut) { key = m SUBSEP a; if (!(key in cuts)) cuts[key] = s; else if (cuts[key] != s) cuts[key] = "mixed"; ncut[key]++; next }
      emit(m, a, s); next
    } else if (m == "StyleTests.RendersThreeWays") { k = "style"; c = "style/" a }
    else if (m == "ScaffoldTests.NewWritesTheLayout") { k = "new"; c = "new/" a }
    else if (m == "OutputTests.BuildRunAndTestWriteToOut") { k = "out"; c = "out/out" }
    else if (m == "OutputTests.FailingTestsAreReportedInTheResultsFile") { k = "out"; c = "out/results-fail" }
    else if (m == "OutputTests.DistWritesAVersionDirectoryAndLatest") { k = "out"; c = "out/dist" }
    else if (m == "MutantSchemataTests.PlainBuildEmitsTheSameC") { k = "emit"; c = "emit/run-c" }
    else if (m == "QualityReportTests.JsonMatchesTheGolden") { k = "quality"; c = "quality/mutation-report" }
    else { print "t10: unmapped xUnit result " t > "/dev/stderr"; next }
    print k "\t" c "\t" s
  }
  END {
    for (key in cuts) {
      split(key, kp, SUBSEP); found = 0
      for (i = 1; i <= nall; i++) if (index(all[i], kp[2]) == 1) hit[++found] = all[i]
      for (i = 1; i <= found; i++) emit(kp[1], hit[i], found == ncut[key] && cuts[key] != "mixed" ? cuts[key] : "ambiguous")
      if (found != ncut[key]) print "t10: xUnit cut name " kp[2] " has " ncut[key] " results and " found " inputs" > "/dev/stderr"
    }
  }
' > "$out/xunit.tsv"

# 4. Per kind. The five in-process style shapes are skipped by the runner by design (step 5 checks them), so on the
# xUnit side they are set aside from the style comparison and compared with their covering blocks instead.
inproc="diag-secondary build-ice lower-ice doctor-ok doctor-fail"
count() { awk -F'\t' -v k="$2" -v s="$3" '$1 == k && $3 == s { n++ } END { print n + 0 }' "$1"; }
agree=1
printf '\n%-10s %-22s %-22s %s\n' kind 'runner pass/fail/skip' 'xunit pass/fail/skip' agree
for k in $kinds; do
  awk -F'\t' -v k="$k" '$1 == k { print $2 "\t" $3 }' "$out/runner.tsv" | LC_ALL=C sort >"$out/r.$k"
  awk -F'\t' -v k="$k" -v ip=" $inproc " '$1 == k && !(k == "style" && index(ip, " " substr($2, 7) " ")) { print $2 "\t" $3 }' "$out/xunit.tsv" | LC_ALL=C sort >"$out/x.$k"
  if [ "$k" = style ]; then
    # the runner's five skips are compared in step 5, not here
    awk -F'\t' -v ip=" $inproc " '!index(ip, " " substr($1, 7) " ")' "$out/r.$k" > "$out/r.$k.tmp" && mv "$out/r.$k.tmp" "$out/r.$k"
  fi
  rp=$(count "$out/runner.tsv" "$k" passed); rf=$(count "$out/runner.tsv" "$k" failed); rs=$(count "$out/runner.tsv" "$k" skipped)
  xp=$(count "$out/xunit.tsv" "$k" passed); xf=$(count "$out/xunit.tsv" "$k" failed); xs=$(count "$out/xunit.tsv" "$k" skipped)
  if cmp -s "$out/r.$k" "$out/x.$k" && [ -s "$out/r.$k" ]; then a=yes; else a=NO; agree=0; fi
  printf '%-10s %-22s %-22s %s\n' "$k" "$rp/$rf/$rs" "$xp/$xf/$xs" "$a"
done
for k in $kinds; do
  cmp -s "$out/r.$k" "$out/x.$k" && continue
  echo; echo "$k: disagreements (case, runner, xunit)"
  # join on the case name: a case missing on one side shows `-`
  LC_ALL=C join -t "$(printf '\t')" -a 1 -a 2 -e - -o 0,1.2,2.2 "$out/r.$k" "$out/x.$k" | awk -F'\t' '$2 != $3 { print "  " $1 "\t" $2 "\t" $3 }'
  [ -s "$out/r.$k" ] || echo "  (no runner cases)"
done

# 5. Style: 17 runner shapes and the 5 skipped, each skip naming a test block that exists and passed.
echo; echo "style shapes (runner, xunit; a skip names its covering block)"
blocks=""; only=""
for s in audit build-fail build-ice build-ok build-ok-cache build-ok-verbose check-ok diag-cap diag-cap-all diag-error-fix \
         diag-removal-fix diag-secondary doctor-fail doctor-ok lower-ice run-fail test-assert-values test-control-chars \
         test-fail test-ok test-pending test-verbose; do
  r=$(awk -F'\t' -v c="style/$s" '$1 == "style" && $2 == c { print $3 }' "$out/runner.tsv"); x=$(awk -F'\t' -v c="style/$s" '$1 == "style" && $2 == c { print $3 }' "$out/xunit.tsv")
  printf '  %-20s %-8s %-8s' "$s" "${r:--}" "${x:--}"
  case " $inproc " in
    *" $s "*)
      d=$(awk -F'\t' -v c="style/$s" '$1 == c { print $2 }' "$out/runner-skips.tsv")
      b=$(printf '%s' "$d" | sed -n 's/.*covered by the test block \\"\(.*\)\\" in \(src\/[^ ]*\)$/\1/p')
      f=$(printf '%s' "$d" | sed -n 's/.*covered by the test block \\"\(.*\)\\" in \(src\/[^ ]*\)$/\2/p')
      if [ "$r" != skipped ] || [ -z "$b" ]; then echo " NO: runner did not skip naming a block ($d)"; agree=0; continue; fi
      if grep -qF "test \"$b\" {" "$f" 2>/dev/null; then echo " block in $f: \"$b\""; else echo " NO: block \"$b\" not in $f"; agree=0; fi
      blocks="$blocks$b
"; only="$only --only \"$b\"" ;;
    *) echo ;;
  esac
done
n17=$(awk -F'\t' '$1 == "style" && $3 == "passed"' "$out/runner.tsv" | wc -l | tr -d ' ')
echo "  runner style: $n17 passed of 17 CLI shapes"
[ "$n17" = 17 ] || agree=0
echo; echo "t10: running the covering blocks:$only"
rm -f "$out/blocks.args"; printf '%s' "$blocks" | while IFS= read -r b; do [ -n "$b" ] && printf '%s\n' "$b"; done > "$out/blocks.args"
set -- test --package src src/driver --json
while IFS= read -r b; do set -- "$@" --only "$b"; done < "$out/blocks.args"
"$BAYAN_EXE" "$@" > "$out/blocks.json" 2> "$out/blocks-stderr.txt"; bexit=$?
awk '
  function val(line) { sub(/^[^:]*: *"/, "", line); sub(/",? *$/, "", line); return line }
  /^ *"name": / { name = val($0) } /^ *"status": / { print "  " val($0) "\t" name }
' "$out/blocks.json" | tee "$out/blocks.tsv"
nb=$(awk -F'\t' '$1 == "  pass"' "$out/blocks.tsv" | wc -l | tr -d ' ')
echo "  blocks passed: $nb of 5 (exit $bexit)"
[ "$nb" = 5 ] && [ "$bexit" = 0 ] || agree=0

echo
if [ "$agree" = 1 ]; then echo "t10: AGREE on $(uname -s)"; exit 0; fi
echo "t10: DISAGREE on $(uname -s) (files under $out)"; exit 1
