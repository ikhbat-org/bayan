# contracts-005-sadaqah-fund

Title: Several checked types working together
Category: contracts
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
The hidden tests open funds, donate to them up to and past the target, join two funds whose joined name is too long or whose total passes the sum rule, and check amounts at the edges of their range.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only contracts-005-sadaqah-fund
```
