# std-007-regex-eid-cards

Title: Hiding a name in Eid cards with std.regex
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
The input covers: a name with `(`, `)`, `.` and spaces, so that an unescaped pattern matches other text; two occurrences with nothing between them; a blank card line; the name with its punctuation changed (`!` for `.`, the parentheses gone); the name in lower case; the name without its last character; leading and trailing spaces kept; two occurrences apart in one line; a line with no occurrence. A name that overlaps itself is described in the prompt and not checked by this input.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only std-007-regex-eid-cards
```
