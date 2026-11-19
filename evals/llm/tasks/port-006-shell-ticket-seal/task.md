# port-006-shell-ticket-seal

Title: Port a shell checksum whose arithmetic wraps
Category: port
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `source.sh`: the original program; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`expected.stdout` is the output of `sh source.sh` on `checks/stdin`, recorded with GNU bash 3.2.57 run as `sh` (macOS). The task tests that integer overflow traps in Bayān: a port with plain `*` and `+` panics at the third ticket, and the port needs the wrapping operators `*%` and `+%`. The input covers: a blank line, numbers with spaces around them, a zero, the largest ticket, a seal that wraps to a negative number and one that wraps back to a positive number.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only port-006-shell-ticket-seal
```
