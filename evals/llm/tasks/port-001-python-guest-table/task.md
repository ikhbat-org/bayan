# port-001-python-guest-table

Title: Port a Python table printer
Category: port
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5810cf25b398)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `source.py`: the original program; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`expected.stdout` is the output of `source.py` on `checks/stdin`, recorded with Python 3. The input covers: names of different lengths, a two-digit number, a blank line, extra spaces.

## Check command
Run from the repository root. It prints `PASS port-001-python-guest-table` when the reference compiles with no diagnostic, is unchanged by `bayan format`, and passes its checks.

```sh
B=$(bash scripts/pinned-bayan.sh); t=evals/llm/tasks/port-001-python-guest-table; d=tmp/llm-eval/port-001-python-guest-table
mkdir -p "$d" && cp "$t/reference/solution.byn" "$d/"
[ -z "$("$B" check --diagnostics json "$d" 2>&1)" ] && "$B" format --check "$d" &&
  "$B" run "$d/solution.byn" < "$t/checks/stdin" > "$d/actual.stdout" && diff "$d/actual.stdout" "$t/checks/expected.stdout" &&
  python3 "$t/source.py" < "$t/checks/stdin" | diff - "$t/checks/expected.stdout" &&
  echo "PASS port-001-python-guest-table"
```
