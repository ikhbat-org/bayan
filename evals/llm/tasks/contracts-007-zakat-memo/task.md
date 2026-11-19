# contracts-007-zakat-memo

Title: A with that cannot fail
Category: contracts
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: tests

## Files
- `prompt.md`: the text the model is given.
- `checks/checks.test.byn`: hidden. Tests compiled into the same module as the solution.
- `checks/entry.byn`: hidden. An empty `main`, so that `bayan check` has an entry point and reports lints.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The hidden tests call `withMemo` without `try` (empty, long and repeated notes) and `withAmount` with amounts above, at and below the edge, and build payments at the edges of the payer rule. A `with` that changes only a field no rule reads cannot fail: a solution that writes `try` there, or gives `withMemo` a `fails` clause, does not compile against the tests.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only contracts-007-zakat-memo
```
