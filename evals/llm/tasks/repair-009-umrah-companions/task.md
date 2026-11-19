# repair-009-umrah-companions

Title: Repair BYN3004
Category: repair
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `starter/solution.byn`: the file to repair; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`starter/solution.byn` fails `bayan check` with BYN3004: it appends to `group` inside a `for` loop over `group`, and the loop borrows the list until it ends. The fix collects the companions in a second list and appends them after the loop; that list must also be searched, or a companion named by two pilgrims gets two seats. The input covers: a pilgrim with no companion, a companion who is an earlier pilgrim, a companion who is a later pilgrim, two pilgrims naming the same companion, a repeated pilgrim whose second line names a companion, a line with three fields, a blank line, spaces around a line, two companions to append in order. The diagnostic text in the prompt is the pinned compiler's output with the directory removed from the path.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only repair-009-umrah-companions
```
