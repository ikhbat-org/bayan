# spec-007-zakat-families

Title: Every parameter after the object takes a particle
Category: spec
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The case is settled by section 10 of the spec: a function has at most one unlabeled parameter, the object, and every other required parameter takes a particle from the closed set (`from`, `to`, `until`, `through`, `at`, `by`, `for`, `as`) that call sites must write (BYN5004, BYN5006, BYN5005). The prompt asks for two functions of two `i64` parameters and does not mention particles, so a model that writes `share(i64 zakat, i64 families)` does not compile. Any particle passes. A candidate that inlines the arithmetic into `main` against the instruction is not caught by the output alone. The expected output is the pinned compiler's.

The input covers: a share with a remainder (1000 for 7), fewer dirhams than families (5 for 9, 99 for 100), equal (12 for 12), an exact division (4500 for 3), one dirham for one family, a sum beyond 32 bits (9000000000000 for 4) and one family.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only spec-007-zakat-families
```
