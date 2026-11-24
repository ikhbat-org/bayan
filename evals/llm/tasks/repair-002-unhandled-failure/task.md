# repair-002-unhandled-failure

Title: Repair BYN2602
Category: repair
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 0530e92ea69c)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `starter/solution.byn`: the file to repair; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`starter/solution.byn` fails `bayan check` with BYN2602. The fix the diagnostic offers first (`try`) does not give the expected output; the task needs `catch`. The diagnostic text in the prompt is the pinned compiler's output with the directory removed from the path.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only repair-002-unhandled-failure
```
