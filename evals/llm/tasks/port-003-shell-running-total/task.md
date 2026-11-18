# port-003-shell-running-total

Title: Port a shell running total
Category: port
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `source.sh`: the original program; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`expected.stdout` is the output of `sh source.sh` on `checks/stdin`, recorded with GNU bash 3.2.57 run as `sh` (macOS). The input covers: a blank line, numbers with spaces around them, a zero, a new largest number and a smaller one after it.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only port-003-shell-running-total
```
