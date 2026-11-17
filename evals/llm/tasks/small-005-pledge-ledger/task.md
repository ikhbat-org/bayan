# small-005-pledge-ledger

Title: Sadaqah pledge ledger
Category: small
Tier: 3
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: a report before any payment, a second pledge by the same name, surrounding spaces, a pay that settles, a pay that overpays, an unknown name, a zero amount, a word for the amount, a negative amount, a missing field, an extra field, an unknown command, `report` with an extra field, a blank line.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only small-005-pledge-ledger
```
