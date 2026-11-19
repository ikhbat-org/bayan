# repair-008-masjid-roster

Title: Repair BYN2780
Category: repair
Tier: 2
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `starter/solution.byn`: the file to repair; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`starter/solution.byn` fails `bayan check` with BYN2780: `let before = roster` copies a `List`, which owns its storage. The fix the diagnostic applies (`move roster`) leaves `roster` moved and fails with BYN2781; the snapshot needs an independent copy. The help's `roster.copy(to: alloc)` fails with BYN2001 in `main` on the pinned compiler; the reference uses `roster.copy()`. The input covers: a first day, a day with one new name and one known, a blank line, a day with no new name, two spaces between names, spaces around a line, a name twice on one day, a name that differs from a known one only in case. The diagnostic text in the prompt is the pinned compiler's output with the directory removed from the path.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only repair-008-masjid-roster
```
