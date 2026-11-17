# effects-001-iftar-tables

Title: A public function that allocates
Category: effects
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 0530e92ea69c)
Check: tests

## Files
- `prompt.md`: the text the model is given.
- `checks/checks.test.byn`: hidden. Tests compiled into the same module as the solution.
- `checks/entry.byn`: hidden. An empty `main`, so that `bayan check` has an entry point and reports lints.
- `reference/solution.byn`: a solution that passes every check.

## Notes
A public function that builds a list must declare `uses alloc`: without it, or with only another effect, the candidate does not compile (BYN6002). One hidden test calls the function under `provide allocator:` with an arena. The last test stores the function in a local of type `(i64, i64) -> List<i64> uses alloc`, so a clause with an extra effect fails the tests build with BYN6005; `bayan check` alone accepts it.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only effects-001-iftar-tables
```
