# contracts-009-hajj-savings

Title: A precondition beside an error set
Category: contracts
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`, `checks/exitcode`: hidden. The input the program is run on, the output it must print and the exit code it must end with.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input has plans that round up and that divide evenly, a plan already met, a plan with no monthly saving (also one already met), bad lines (too few and too many fields, a word for a number, a number below 0), blank lines and lines with spaces around them, then a plan whose savings pass its goal; the program must abort there and print nothing after it. `checks/exitcode` holds 134. The function has both an `expects` clause and a `fails` clause, which must come in that order.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only contracts-009-hajj-savings
```
