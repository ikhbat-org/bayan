# effects-003-pledge-rules

Title: Effects of functions that take a function
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
`adjustPledges` builds a list and must declare `uses alloc` (BYN6002 without it). `totalAfter` and `countAbove` allocate nothing and declare no `uses`. A function-typed parameter with no `uses` is effect-polymorphic (spec section 14): `totalAfter` takes the effects of the rule it is given, so one hidden test passes a rule that prints, and a candidate that adds `console` to `totalAfter` fails the last test with BYN6005. The last test stores each function in a local of a function type that bounds its effects (`uses alloc` for `adjustPledges`, none for the other two), so an extra effect fails the tests build; `bayan check` alone accepts it.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only effects-003-pledge-rules
```
