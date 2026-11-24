# small-007-badge-names

Title: Name badges cut by characters
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
The task tests that a string's `length` and its slices count bytes: the count is `runeCount` and the cut goes through `runes`; a byte slice of Arabic text traps off a rune boundary.

The input covers: names of 5 and of 6 characters, a 6-character Arabic name of 12 bytes, a 4-character Arabic name of 8 bytes, a long Arabic name, Latin letters with dots below (two bytes each), a name with spaces inside whose cut ends on a space, long Latin names of 8 and 10 characters, surrounding spaces, a blank line.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only small-007-badge-names
```
