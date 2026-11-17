# errors-005-gift-lines

Title: Two error sets across several functions
Category: errors
Tier: 3
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: tests

## Files
- `prompt.md`: the text the model is given.
- `checks/checks.test.byn`: hidden. Tests compiled into the same module as the solution.
- `checks/entry.byn`: hidden. An empty `main`, so that `bayan check` has an entry point and reports lints.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The hidden tests parse amounts, read gift lines that fail in each way (including lines where two failures apply), compare the receipt text for every outcome and check the countGifts of a mixed list.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only errors-005-gift-lines
```
