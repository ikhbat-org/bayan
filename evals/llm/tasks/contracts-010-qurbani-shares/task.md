# contracts-010-qurbani-shares

Title: Nested checked types and two validation sets
Category: contracts
Tier: 3
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: tests

## Files
- `prompt.md`: the text the model is given.
- `checks/checks.test.byn`: hidden. Tests compiled into the same module as the solution.
- `checks/entry.byn`: hidden. An empty `main`, so that `bayan check` has an entry point and reports lints.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The hidden tests build bookings with and without change, share counts of 0, 8 and below 0, empty and overlong family names, payments short by one and below 0, and a booking whose shares and booking both break (the shares are reported). They check each `verdict` line, an empty cow, cows filled to seven, a full cow refused one more share, `addedAll` with no bookings and with bookings that overflow, and a `Booking` built from a constant `Shares(4)`. `Cow { taken: 0 }` is checked while compiling, so `emptyCow` takes no `try`; `verdict` tells the two `ValidationError` sets apart by type.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only contracts-010-qurbani-shares
```
