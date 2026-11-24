# spec-008-eidi-ledger

Title: Reading a missing map key, and adding one
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
The case is settled by section 16 of the spec (Maps): reading `map[k]` panics when `k` is missing, `map.tryGet(at: k) ?? fallback` reads without inserting, and `map.slot(k)` gets or inserts a default. The prompt names neither member. A model that reads with `map[k]` for `ask`, or adds with `map[k] += n` for the first `give` to a name, ends in a panic (exit 134); one that reads by getting-or-inserting a default counts the asked names in `children`. The expected output is the pinned compiler's.

The input covers: `ask` and `children` on the empty map, a first `give`, a `give` of 0 (the name enters the map with 0 and counts as a child), a second `give` to the same name (the amounts add), an `ask` for a name that differs only in case, an `ask` for a name never given to followed by `children` (it is not counted), and a later `give` to that name.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only spec-008-eidi-ledger
```
