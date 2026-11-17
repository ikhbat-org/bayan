# contracts-004-iftar-seats

Title: A function precondition that aborts
Category: contracts
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`, `checks/exitcode`: hidden. The input the program is run on, the output it must print and the exit code it must end with.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input has valid lines, bad lines and ends with a line whose guests exceed its seats; the program must abort there. `checks/exitcode` holds 134. A solution that checks the seats by hand and goes on cannot get that exit code.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only contracts-004-iftar-seats
```
