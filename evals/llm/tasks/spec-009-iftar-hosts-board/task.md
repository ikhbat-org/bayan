# spec-009-iftar-hosts-board

Title: Width, fill and alignment in an interpolation hole
Category: spec
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
The case is settled by section 6.6 of the spec: format options are named arguments inside the hole (`{x, width: 10, align: .start, fill: '.'}`), with `align:` taking `.start`, `.end` or `.center` (section 16.4 lists them). The C# forms `{x,-10}` and `{x:D4}` do not compile (BYN1001). The prompt states the layout in words, including the two points the spec does not fix (columns count Unicode scalars, the odd `*` goes after the word); the pinned compiler does both, and the expected output is its. A program that pads by hand with `length` (bytes) puts too few `.` after each name with a letter of more than one byte.

The input covers: a 5-letter name, 0 guests, a name with a 3-byte letter (`Ḥamza`), a 9-scalar name with two 2-byte letters (`ʿAbdullāh`, one `.`), a name of 11 letters (wider than the field, printed whole), a name of 10 letters (no padding), 9999 guests (4 columns, no padding), a name with a 2-byte letter (`Sāra`), and a total of 5 digits (wider than its field). The title `total` has 5 columns of padding, split 2 before and 3 after.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only spec-009-iftar-hosts-board
```
