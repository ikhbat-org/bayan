# small-006-locker-codes

Title: Locker codes from names
Category: small
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
The task tests wrapping arithmetic: a plain `*` on `u32` traps on overflow, so the multiply must be `*%`. It also needs the hex spec with width and fill in an interpolation hole.

The input covers: names long enough to wrap and a three-letter name that does not, codes with one and three leading zero digits, a space inside a name, surrounding spaces, an Arabic-script name (bytes above 127), a one-letter name, a blank line, a line of spaces only, a repeated name.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only small-006-locker-codes
```
