#!/usr/bin/env bash
# Tests scripts/selfhost/freeze-csharp.sh on a fixture cases dir under tmp/ with a stub C# bayan (no .NET): the line format of the
# mode and exit-code files, their sort order and LF endings, a rejected input recorded with its exit code in every mode, the argv
# of each kind with no absolute path, two runs from two directories byte-identical, the run-c.sha256 comparison in the `// mode:`
# mode (exit 1 and a `run-c mismatch` line on a changed line), and a pick file limiting the inputs.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
tool="$root/scripts/selfhost/freeze-csharp.sh"
fail() { echo "FAIL $1"; exit 1; }
t="$root/tmp/freeze-csharp-test"; rm -rf "$t"; mkdir -p "$t/tmp"
export TMPDIR="$t/tmp"
if command -v sha256sum > /dev/null 2>&1; then h() { sha256sum | cut -c1-64; }; else h() { shasum -a 256 | cut -c1-64; }; fi

# the stub: `build` prints C naming the file and mode (exit 1 on REJECT), the others exit 1 on BAD; every argv is logged
cat > "$t/cs" << EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$t/argv"
if [ "\$1" = build ]; then grep -q REJECT "\${@: -1}" && exit 1; printf 'c %s %s\n' "\${@: -1}" "\$4"; exit 0; fi
f="\${@: -1}"; [ -d "\$f" ] && f=src/app/lib.byn
grep -q BAD "\$f" && exit 1; exit 0
EOF
chmod +x "$t/cs"
c="$t/a/cases"
mkdir -p "$c/run/d" "$c/parse" "$c/typed" "$c/diag/pkg" "$c/diag/proj/src/app" "$c/emit"
printf 'print("a")\n' > "$c/run/a.byn"
printf '// mode: debug\nprint("b")\n' > "$c/run/b.byn"
printf 'REJECT\n' > "$c/run/r.byn"
printf 'print("d")\n' > "$c/run/d/main.byn"
printf 'ok\n' > "$c/parse/p.byn"; printf 'BAD\n' > "$c/parse/q.byn"; printf 'ok\n' > "$c/typed/t.byn"
printf 'BAD\n' > "$c/diag/x.byn"; printf 'ok\n' > "$c/diag/pkg/main.byn"; printf 'ok\n' > "$c/diag/proj/main.byn"
printf 'BAD\n' > "$c/diag/proj/src/app/lib.byn"
{ printf '%s  run/a.byn\n' "$(printf 'c a.byn safe\n' | h)"; printf '%s  run/b.byn\n' "$(printf 'c b.byn debug\n' | h)"
  printf '%s  run/d/main.byn\n' "$(printf 'c main.byn safe\n' | h)"; } > "$c/emit/run-c.sha256"

o="$t/out1"
bash "$tool" "$t/cs" "$c" "$o" > "$t/log" 2>&1 || fail "full run exit $?: $(cat "$t/log")"
grep -qx 'freeze-csharp: run-c.sha256 3 of 3 lines reproduced' "$t/log" || fail "run-c summary: $(cat "$t/log")"
for m in debug safe fast; do
  f="$o/emit/modes/expected.$m.sha256"
  [ "$(wc -l < "$f" | tr -d ' ')" = 4 ] || fail "$m: $(wc -l < "$f") lines"
  ! grep -vE '^([0-9a-f]{64}|exit:[0-9]+)  run/[^ ]' "$f" || fail "$m: a malformed line"
  grep -qx 'exit:1  run/r.byn' "$f" || fail "$m: the rejected input is not recorded: $(cat "$f")"
  grep -qx "$(printf 'c a.byn %s\n' "$m" | h)  run/a.byn" "$f" || fail "$m: run/a.byn has the wrong hash"
done
printf '0  parse/p.byn\n1  parse/q.byn\n' | cmp -s - "$o/emit/exit/expected.parse.exitcode" || fail "parse: $(cat "$o/emit/exit/expected.parse.exitcode")"
printf '0  typed/t.byn\n' | cmp -s - "$o/emit/exit/expected.typed.exitcode" || fail "typed: $(cat "$o/emit/exit/expected.typed.exitcode")"
printf '0  diag/pkg/main.byn\n1  diag/proj/main.byn\n1  diag/x.byn\n' | cmp -s - "$o/emit/exit/expected.diag.exitcode" ||
  fail "diag: $(cat "$o/emit/exit/expected.diag.exitcode")"
for f in "$o"/emit/*/*; do
  cut -d' ' -f3 "$f" | LC_ALL=C sort -c 2> /dev/null || fail "$f is not sorted by name"
  ! grep -q "$(printf '\r')" "$f" || fail "$f holds a CR"
done
grep -qx 'build --emit-c --mode fast --package . main.byn' "$t/argv" || fail "run dir argv: $(cat "$t/argv")"
grep -qx 'parse --ast q.byn' "$t/argv" && grep -qx 'types --package . t.byn' "$t/argv" && grep -qx 'check --all .' "$t/argv" &&
  grep -qx 'check --all --package . main.byn' "$t/argv" && grep -qx 'check --all --package . x.byn' "$t/argv" ||
  fail "kind argv: $(cat "$t/argv")"
! grep -E '(^| )/' "$t/argv" || fail "an absolute path reached the C#"

# two runs, the second over a copy at another path: byte-identical
mkdir -p "$t/b/c"; cp -R "$c" "$t/b/c/cases"
bash "$tool" "$t/cs" "$t/b/c/cases" "$t/out2" > /dev/null 2>&1 || fail "second run exit $?"
diff -r "$o" "$t/out2" > /dev/null || fail "two runs differ: $(diff -r "$o" "$t/out2")"

# a changed run-c.sha256 line: exit 1, named
sed -i.bak 's/^[0-9a-f]\{4\}/0000/' "$c/emit/run-c.sha256"; sed -n 2p "$c/emit/run-c.sha256" > "$t/changed"
rc=0; bash "$tool" "$t/cs" "$c" "$t/out3" > "$t/log" 2>&1 || rc=$?
[ $rc = 1 ] || fail "changed run-c.sha256: exit $rc"
grep -q "^run-c mismatch: $(cat "$t/changed") (debug: " "$t/log" || fail "no mismatch line for run/b.byn: $(cat "$t/log")"
mv "$c/emit/run-c.sha256.bak" "$c/emit/run-c.sha256"

# a pick file: only its inputs, and only their run-c.sha256 lines
printf 'run/b.byn\nrun/r.byn\ndiag/x.byn\n' > "$t/pick"
bash "$tool" "$t/cs" "$c" "$t/out4" "$t/pick" > "$t/log" 2>&1 || fail "pick run exit $?: $(cat "$t/log")"
[ "$(cut -d' ' -f3 "$t/out4/emit/modes/expected.safe.sha256" | tr '\n' ' ')" = "run/b.byn run/r.byn " ] || fail "pick: $(cat "$t/out4/emit/modes/expected.safe.sha256")"
[ ! -s "$t/out4/emit/exit/expected.parse.exitcode" ] && [ "$(cat "$t/out4/emit/exit/expected.diag.exitcode")" = "1  diag/x.byn" ] || fail "pick kinds"
grep -qx 'freeze-csharp: run-c.sha256 1 of 1 lines reproduced' "$t/log" || fail "pick run-c: $(cat "$t/log")"

# usage
rc=0; bash "$tool" "$t/cs" "$c" > /dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "two arguments exit $rc"
rc=0; bash "$tool" "$t/nope" "$c" "$t/o" > /dev/null 2>&1 || rc=$?; [ $rc = 2 ] || fail "no executable exit $rc"
rm -rf "$t"
echo "freeze-csharp.test: ok"
