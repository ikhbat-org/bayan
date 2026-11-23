# std-004-regex-zakat-log

Title: Zakat log totals with std.regex
Category: std
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: surrounding spaces, a blank line, two months in non-sorted order, a zero amount, a word amount, a one-digit month, trailing text, a double space, a negative amount, a digit in the name, a missing name, a month in another year.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only std-004-regex-zakat-log
```
