# contracts-001-date-portion

Title: A struct that cannot be invalid
Category: contracts
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
The hidden tests build valid and invalid portions and assert `fails ValidationError<Portion>`; a solution that checks the rules by hand in `portion` instead of with `requires` cannot produce that error set.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only contracts-001-date-portion
```
