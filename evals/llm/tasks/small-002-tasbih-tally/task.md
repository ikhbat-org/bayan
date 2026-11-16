# small-002-tasbih-tally

Title: Tally of dhikr phrases
Category: small
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5810cf25b398)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: a tie broken by first appearance, a phrase with a space inside, surrounding spaces, a blank line.

## Check command
Run from the repository root. It prints `PASS small-002-tasbih-tally` when the reference compiles with no diagnostic, is unchanged by `bayan format`, and passes its checks.

```sh
B=$(bash scripts/pinned-bayan.sh); t=evals/llm/tasks/small-002-tasbih-tally; d=tmp/llm-eval/small-002-tasbih-tally
mkdir -p "$d" && cp "$t/reference/solution.byn" "$d/"
[ -z "$("$B" check --diagnostics json "$d" 2>&1)" ] && "$B" format --check "$d" &&
  "$B" run "$d/solution.byn" < "$t/checks/stdin" > "$d/actual.stdout" && diff "$d/actual.stdout" "$t/checks/expected.stdout" &&
  echo "PASS small-002-tasbih-tally"
```
