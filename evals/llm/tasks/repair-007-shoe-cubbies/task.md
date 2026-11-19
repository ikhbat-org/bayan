# repair-007-shoe-cubbies

Title: Repair BYN2202
Category: repair
Tier: 1
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
`starter/solution.byn` fails `bayan check` with BYN2202: an `i64` assigned to a `u8?`, which Bayān never narrows implicitly. The diagnostic offers no fix. The checked conversion `u8.tryFrom(number)` gives `null` out of range; with `u8(number)` the `is null` test no longer compiles (BYN2411), and without the test `u8(number)` traps on the first number out of range. The input covers: cubbies 0, 15, 16 and 255, a number in the middle, 256, a negative number, a number far above 255, a word that is not a number, a line with three fields, a blank line, spaces around a line, a name that repeats. The diagnostic text in the prompt is the pinned compiler's output with the directory removed from the path.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only repair-007-shoe-cubbies
```
