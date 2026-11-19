# std-008-json-khatm-pledges

Title: Khatm pledges written with std.json
Category: std
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: surrounding spaces, a blank line that counts in the numbering, a `"` and a `\` in a name, a name with one non-ASCII letter, an Arabic name, juz 0, juz 31, a word juz, a negative juz, a decimal juz, two spaces, three fields, one field, and a total of 30 (`complete` is `true` at the boundary). Juz 30 and an empty `readers` or `skipped` list are described in the prompt and not checked by this input.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only std-008-json-khatm-pledges
```
