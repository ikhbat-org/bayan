#!/usr/bin/env bash
# Every tool's recorded cases still hold against the original script (so the baselines stay true while it lives), and a
# command that behaves differently is caught.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fail() { echo "FAIL: $1" >&2; exit 1; }
# A tool whose interpreter is not installed (CI runners have no deno) is skipped, not failed.
needs() { read -r cmd _ < "$1/impl"; command -v "$cmd" > /dev/null; }
for t in "$root"/tests/parity/*/; do
  # The cli-* cases were recorded from the C# `bayan` (scripts/parity/csharp-bayan.sh); scripts/test.sh runs them against the driver.
  case "$(basename "$t")" in cli-*) echo "SKIP $(basename "$t"): recorded from the C# bayan, run by scripts/test.sh --only parity"; continue ;; esac
  needs "$t" || { echo "SKIP $(basename "$t"): $(read -r c _ < "$t/impl"; echo "$c") not installed"; continue; }
  bash "$root/scripts/parity/run.sh" "$(basename "$t")" > /dev/null || fail "$(basename "$t") no longer matches its baseline: $(bash "$root/scripts/parity/run.sh" "$(basename "$t")" | head -3)"
done
# A fixture, not PATH=/nonexistent: macOS bash 3.2 keeps its command hash under a temporary PATH.
mkdir -p "$root/tmp/parity-needs"; echo 'bayan-no-such-interpreter x' > "$root/tmp/parity-needs/impl"
if needs "$root/tmp/parity-needs"; then fail "a missing interpreter was found"; fi
if out=$(bash "$root/scripts/parity/run.sh" probe --impl "printf skip"); then fail "a different implementation passed"; fi
grep -q 'FAIL probe/spans: stdout differs' <<< "$out" || fail "no stdout mismatch reported: $out"
# A left-over file and a changed file both count; an empty directory does not.
t="$root/tmp/parity-test"; mkdir -p "$t"
printf '#!/bin/sh\nmkdir -p empty-dir\necho %s > "$1"\n' "$(printf 'x')" > "$t/impl.sh"
if out=$(bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" spans); then fail "a changed input file passed"; fi
grep -q 'FAIL probe/spans: files differ' <<< "$out" || fail "no file mismatch reported: $out"
printf '#!/bin/sh\ntouch extra\n' > "$t/impl.sh"
if out=$(bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" spans); then fail "an extra file passed"; fi
grep -q 'FAIL probe/spans: files differ' <<< "$out" || fail "no extra-file mismatch reported: $out"
printf '#!/bin/sh\nmkdir -p empty-dir\n' > "$t/impl.sh"
out=$(bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" spans || true)
! grep -q 'files differ' <<< "$out" || fail "an empty directory counted as a file change: $out"
if bash "$root/scripts/parity/run.sh" no-such-tool 2> /dev/null; then fail "an unknown tool passed"; fi
# Only a whole path is rewritten: the work directory followed by more name characters stays as it is.
printf '#!/bin/sh\necho "$PWD/a ${PWD}b"\n' > "$t/impl.sh"
bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" spans > /dev/null || true
got=$(cat "$root/tmp/parity/probe/spans/got/stdout")
[ "$got" = "\$WORK/a \$ROOT/tmp/parity/probe/spans/workb" ] || fail "path rewrite went past a path boundary: $got"
# Traceback caret lines (Python 3.11+ only) are dropped from stderr; other stderr lines stay.
printf '#!/bin/sh\nprintf "  x = 1\\n      ^^^^^\\n   ~~~^^\\nE: ^ not alone\\n" >&2\n' > "$t/impl.sh"
bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" spans > /dev/null || true
got=$(cat "$root/tmp/parity/probe/spans/got/stderr")
[ "$got" = "$(printf '  x = 1\nE: ^ not alone')" ] || fail "caret lines not dropped from stderr: $got"
# A recorded traceback's stderr passes on the exception's message alone; exit code and stdout stay exact.
bash "$root/scripts/parity/run.sh" probe traceback > /dev/null || fail "a stderr holding the traceback's message failed"
printf '#!/bin/sh\necho other >&2\nexit 1\n' > "$t/impl.sh"
if out=$(bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" traceback); then fail "a stderr without the message passed"; fi
grep -q 'FAIL probe/traceback: stderr differs: no' <<< "$out" || fail "missing message not reported: $out"
printf '#!/bin/sh\necho "missing.txt: No such file or directory" >&2\nexit 0\n' > "$t/impl.sh"
if bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" traceback > /dev/null; then fail "a traceback case passed on a different exit code"; fi
# A case or tool name that leaves its directory is refused before anything is removed.
out=$(bash "$root/scripts/parity/run.sh" probe ..) && fail "case .. passed"
grep -q 'bad case name' <<< "$out" || fail "case .. was not refused: $out"
out=$(bash "$root/scripts/parity/run.sh" ../parity 2>&1) && fail "tool ../parity passed"
grep -q 'bad tool name' <<< "$out" || fail "tool ../parity was not refused: $out"
# --record reports a case it could not record.
if bash "$root/scripts/parity/run.sh" probe --record no-such-case > /dev/null; then fail "--record of a missing case exited 0"; fi
# Masks (spec 019 T25): a time, a staging key and the .NET text after `bayan: cannot …` read the same whatever their value;
# a time inside a word, a key with a 33rd hex digit and a `bayan: cannot` line without a path or name stay exact.
cat > "$t/impl.sh" <<'STUB'
#!/bin/sh
cat <<'OUT'
built in 9.87s · 0.1s
v1.2.3s keep 1.5sx
cache/v1/tmp/fedcba9876543210-fedcba9876543210fedcba9876543210
key 0123456789abcdef-0123456789abcdef0123456789abcdefa
bayan: cannot write the build output or cache (/x/cache): Read-only file system
bayan: cannot read `a.byn`: Permission denied
bayan: cannot run: keep this
OUT
STUB
bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" masks > /dev/null || fail "a masked value still differs: $(bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" masks)"
for m in 's/9.87s/9.87x/' 's/0.1s/1.0q/' 's/fedcba9876543210-/fedcba987654321-/' 's/keep 1.5sx/keep #sx/' 's/cdefa$/cdef/' 's/(\/x\/cache): Read-only/(\/x\/cache) Read-only/' 's/: keep this/: other/'; do
  sed "$m" "$t/impl.sh" > "$t/impl2.sh"
  if bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl2.sh" masks > /dev/null; then fail "mask case passed with $m"; fi
done
# steps: each step's exit, stdout and stderr under `== <n>`; a `$ ` step sees $BAYAN; the last step's exit is the case's.
[ "$(cat "$root/tests/parity/probe/steps/expected/stdout")" = "$(printf '== 1 exit 0\none\n== 2 exit 3\none\n== 3 exit 0\ntwo')" ] \
  || fail "steps stdout is not per step: $(cat "$root/tests/parity/probe/steps/expected/stdout")"
printf '#!/bin/sh\ncat "$1"; [ "$1" = b.txt ] && exit 4; exit 0\n' > "$t/impl.sh"
out=$(bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" steps) && fail "a different last-step exit passed"
grep -q 'FAIL probe/steps: exit differs' <<< "$out" || fail "no exit mismatch reported for steps: $out"
grep -q 'FAIL probe/steps: stdout differs' <<< "$out" || fail "no step exit mismatch reported: $out"
# nofiles: the work directory is not compared.
printf '#!/bin/sh\ncat "$1"; touch extra\n' > "$t/impl.sh"
bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" steps > /dev/null || fail "a nofiles case compared its files: $(bash "$root/scripts/parity/run.sh" probe --impl "bash $t/impl.sh" steps)"
echo PASS
