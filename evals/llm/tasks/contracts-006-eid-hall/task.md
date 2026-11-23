# contracts-006-eid-hall

Title: A struct rule reported against a chosen field
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
The hidden tests build halls with room, full halls, empty halls, halls with too many people (the overflow coming from `men`, from `women` or from both) and halls with a field rule broken, and read the field of each violation. A struct-level rule without `at .capacity` is reported against a field it reads first, so a solution that writes `men + women <= capacity` without `at` names `men`.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only contracts-006-eid-hall
```
