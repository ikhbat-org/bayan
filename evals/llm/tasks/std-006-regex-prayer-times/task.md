# std-006-regex-prayer-times

Title: Prayer times and byte offsets with std.regex
Category: std
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
The input covers: two times in a line, a blank line that counts in the numbering, non-ASCII letters before a time (byte and rune offsets differ), times next to `,`, `;`, `(`, `)` and `-`, a letter before a time, a third digit after it, one digit before or after the `:`, `_` after a time, three groups joined by `:` (the overlap rule), `29:99`, a time at the start of a line, Arabic-Indic digits (not ASCII), a line with no time.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only std-006-regex-prayer-times
```
