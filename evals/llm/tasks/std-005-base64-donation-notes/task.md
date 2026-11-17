# std-005-base64-donation-notes

Title: Sealed donation notes with std.encoding
Category: std
Tier: 3
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The input covers: surrounding spaces, a blank line that counts in the numbering, a repeated donor, no colon, an empty donor, text that is not Base64, Base64 of bytes that are not UTF-8, one field, two spaces, three fields, a kind in the wrong case, a zero amount, a word amount, a tie in the donor sums broken by first appearance, a donor whose later notes are the larger, and a note with two faults (an empty donor and bad Base64).

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only std-005-base64-donation-notes
```
