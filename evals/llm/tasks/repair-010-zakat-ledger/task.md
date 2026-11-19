# repair-010-zakat-ledger

Title: Repair BYN6002
Category: repair
Tier: 3
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
`starter/solution.byn` fails `bayan check` with BYN6002 five times: four public functions use `alloc` or `console` with no `uses` clause, and `readLedger` needs both. A public function's effects are part of its signature and are never inferred; building a `List` and appending to it is `alloc`, reading standard input is both `console` and `alloc`, and `print` is `console`. The prompt asks to keep the public declarations public, so making them private is not the intended fix. The input covers: spaces around the nisab line, an owner with several lines and a debt, a blank line, a net equal to the nisab whose zakat rounds down to 0, a net of 0, a net one below the nisab with the debt before the wealth, an unknown kind, an amount that is not a number, a negative amount, a line with four fields, owners whose lines are not next to each other. The diagnostic text in the prompt is the pinned compiler's output with the directory removed from the path.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only repair-010-zakat-ledger
```
