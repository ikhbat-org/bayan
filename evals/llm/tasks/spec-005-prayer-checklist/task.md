# spec-005-prayer-checklist

Title: Enums, list removal, byte slices, search and copy-and-update in one program
Category: spec
Tier: 3
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/expected.stdout`: hidden. The output the program must print. There is no `checks/stdin`; the program reads no input.
- `reference/solution.byn`: a solution that passes every check.

## Notes
Five questions, each settled by the spec. Section 3.13: an enum with constant data has a generated `values` and `name`. Section 3.5: `xs.remove(from: a, until: b)` removes `[a, b)` and `remove(from: a, through: b)` includes `b`. Section 3.2: a range slice `s[a..b]` takes byte offsets, `length` is the byte length, `runeCount` counts scalars, and `position(x)` gives an optional byte position. Section 6.4: `with { ... }` is the copy-and-update form and leaves the original unchanged. The prompt names no member except the `remove` labels. The expected output is the pinned compiler's: the first slice is 7 bytes and 5 scalars because `Ḥ` is 3 bytes, `ibn` is at byte 8, and the removals leave 10, 40, 50 and then 40, 50. The design left to the model is how the five parts are split into functions and what they are named.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only spec-005-prayer-checklist
```
