# std-009-json-hajj-forms

Title: Hajj form shapes with the std.json reader
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
The input covers: nested objects and lists with `null`, `true` and numbers; a blank line and a line of spaces that count in the numbering; a text document (depth 0); `[]`; `{}` with surrounding spaces; lists inside lists; a second value after the first; an unclosed list; a missing `:`; nesting 129 deep (invalid) and 128 deep (valid); a repeated key; a non-ASCII key and text, and a negative number with an exponent; `nul`; empty containers as values.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only std-009-json-hajj-forms
```
