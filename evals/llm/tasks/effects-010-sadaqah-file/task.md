# effects-010-sadaqah-file

Title: The file system effect and which file calls allocate
Category: effects
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
Every file call carries `fs`, but only the calls that hand back new data allocate: `Io.readText` is `uses fs, alloc`, while `Io.writeFile`, `Fs.fileExists` and `Io.remove` are `uses fs` alone. So `savedGifts` declares `uses fs, alloc fails IoError`, `saveBox` the same (building the text allocates), `boxSaved` only `uses fs` and `discardBox` `uses fs fails IoError`; `uses` comes before `fails` (BYN1065 otherwise). A candidate that leaves out an effect does not compile (BYN6002). Hidden public functions declared `uses fs` (one also `fails IoError`) call `boxSaved` and `discardBox`, and one with no `uses` clause reads `count`, `total` and `entryAt`, so a candidate that adds `alloc` to any of them fails the tests build with BYN6002; the last test stores the five functions in locals of function types that bound their effects, so an extra effect fails with BYN6005. The line format is left to the model; the tests read the file back only through `savedGifts`. The hidden input covers a box of three gifts and an empty box (count, total, entries), saving, counting and removing a file, saving twice to one path (the second, smaller box replaces the first), an empty box saved as an empty file, and a missing path, where `boxSaved` is false, `savedGifts` fails with `notFound` and `discardBox` succeeds. The tests write their files in the scratch directory under relative names starting `sadaqah-` and remove them. The text of the printed lines is not checked.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only effects-010-sadaqah-file
```
