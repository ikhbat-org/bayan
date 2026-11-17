# effects-004-pledge-lines

Title: Effects that follow from the calls a function makes
Category: effects
Tier: 2
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
Building a string by interpolation allocates, so `describePledge` and `describeAll` need `uses alloc`; `print` needs `uses console`; a function that calls an allocating function inherits `alloc`, so `announcePledge` and `announceAll` need both if they call `describePledge` or `describeAll`. A candidate that leaves out an effect it needs does not compile (BYN6002). The text of the total line is not checked. The last test stores each function in a local of a function type that bounds its effects (none for `pledgedTotal`, `uses alloc` for the two that return text, `uses alloc, console` for the two that print), so an extra effect fails the tests build with BYN6005, while a candidate that prints without calling the allocating function and so needs only `console` is accepted.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only effects-004-pledge-lines
```
