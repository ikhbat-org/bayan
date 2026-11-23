# repair-006-sadaqah-purses

Title: Repair BYN1063
Category: repair
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `starter/solution.byn`: the file to repair; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`, `checks/exitcode`: hidden. The input the program is run on, the output it must print and the exit code it must end with.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`starter/solution.byn` fails `bayan check` with BYN1063: a function precondition written with `requires`, which in Bayān belongs to fields and types; a function's is `expects`. A fix that deletes the clause or turns it into a skip cannot end with exit code 134. The input covers: a share with coins left over, an even share, purses equal to coins, one purse, a blank line, a line with two fields, a line with four fields, then a line with more purses than coins, which ends the run, followed by a good line that must not be printed. `checks/exitcode` holds 134. The diagnostic text in the prompt is the pinned compiler's output with the directory removed from the path.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only repair-006-sadaqah-purses
```
