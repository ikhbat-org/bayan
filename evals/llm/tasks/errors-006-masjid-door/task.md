# errors-006-masjid-door

Title: An error set composed of two others
Category: errors
Tier: 1
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
The hidden tests check the key against the right key, near misses (case, a trailing space, a prefix) and an empty key, check the hours 0 and 3 against 4, 5 and 23, assert that `openDoor` reports the hour before the key when both are wrong, read the `opens` payload through a `catch switch` over `DoorError` with a whole-set arm for `KeyError`, and call `checkKey` through `try` in a hidden function that fails `DoorError`, which compiles only when `DoorError` is composed of `KeyError` rather than a set with copied cases.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only errors-006-masjid-door
```
