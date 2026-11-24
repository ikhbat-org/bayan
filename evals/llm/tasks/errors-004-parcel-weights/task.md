# errors-004-parcel-weights

Title: Passing an error on and handling it
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
The hidden tests read valid weights, weights that are not numbers, a weight of 0 and a weight over 50, assert the case each failure carries, and check that `totalKilos` reads its first text first and that `kilosOrZero` never fails.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only errors-004-parcel-weights
```
