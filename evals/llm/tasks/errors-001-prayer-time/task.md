# errors-001-prayer-time

Title: Times of day that can fail
Category: errors
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5810cf25b398)
Check: tests

## Files
- `prompt.md`: the text the model is given.
- `checks/checks.test.byn`: hidden. Tests compiled into the same module as the solution.
- `checks/entry.byn`: hidden. An empty `main`, so that `bayan check` has an entry point and reports lints.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The hidden tests call both functions with valid times, malformed times and out-of-range times, and assert the case each failure carries.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only errors-001-prayer-time
```
