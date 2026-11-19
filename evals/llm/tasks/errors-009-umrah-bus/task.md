# errors-009-umrah-bus

Title: Undoing work when a function fails
Category: errors
Tier: 2
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
The hidden tests board groups onto empty and partly filled buses, fill the last seat, and fail on an empty group, an empty name in the middle, at the end and at the start, a name already aboard, a name repeated inside the group, a group that does not fit and a bus of 0 seats. After every failure they compare `riders` with what it was before the call. They read the `twice` and `full` payloads through `catch switch`, check that a name differing only in case boards, check that a name already aboard on a full bus fails `twice` and that the first check to apply decides the case, and run `boardAll` over a mix of groups that fit and fail, and over no groups.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only errors-009-umrah-bus
```
