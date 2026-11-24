# small-001-zakat-due

Title: Zakat due per saver
Category: small
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5810cf25b398)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: at, below and above the nisab, a blank line, surrounding spaces, three fields, one field, a word for the amount, a negative amount.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only small-001-zakat-due
```
