# port-002-shell-numbered-lines

Title: Port a shell line counter
Category: port
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5810cf25b398)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `source.sh`: the original program; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`expected.stdout` is the output of `sh source.sh` on `checks/stdin`. The input covers: blank lines, a line with leading spaces, a line with punctuation.

## Check command
Run from the repository root. It prints `PASS port-002-shell-numbered-lines` when the reference compiles with no diagnostic, is unchanged by `bayan format`, and passes its checks.

```sh
B=$(bash scripts/pinned-bayan.sh); t=evals/llm/tasks/port-002-shell-numbered-lines; d=tmp/llm-eval/port-002-shell-numbered-lines
mkdir -p "$d" && cp "$t/reference/solution.byn" "$d/"
[ -z "$("$B" check --diagnostics json "$d" 2>&1)" ] && "$B" format --check "$d" &&
  "$B" run "$d/solution.byn" < "$t/checks/stdin" > "$d/actual.stdout" && diff "$d/actual.stdout" "$t/checks/expected.stdout" &&
  sh "$t/source.sh" < "$t/checks/stdin" | diff - "$t/checks/expected.stdout" &&
  echo "PASS port-002-shell-numbered-lines"
```
