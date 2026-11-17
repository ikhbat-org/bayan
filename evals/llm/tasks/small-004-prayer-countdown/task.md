# small-004-prayer-countdown

Title: Time left to each prayer
Category: small
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: surrounding spaces on the first line, a passed prayer, a prayer equal to now, a tie for the next prayer, a wait under one hour, hour 24, minute 61, a one-digit hour, two spaces between name and time, one field.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only small-004-prayer-countdown
```
