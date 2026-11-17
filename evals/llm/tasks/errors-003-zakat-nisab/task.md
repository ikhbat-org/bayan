# errors-003-zakat-nisab

Title: A failing function with ordered checks
Category: errors
Tier: 1
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
The hidden tests call `zakatDue` with valid amounts, with a nisab of 0 or less, with negative savings and with savings below the nisab, and assert the case each failure carries, including which case wins when two apply.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only errors-003-zakat-nisab
```
