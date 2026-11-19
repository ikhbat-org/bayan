# small-010-khatm-circle

Title: Khatm circle of the 30 juz
Category: small
Tier: 3
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The task tests a union whose cases carry named payloads: the declaration form, construction (`.claimed(name)`), binding in `switch` and in `is` (`case .claimed(let by)`), and that a case with a payload cannot be matched by its bare name (BYN2705). A helper with a second required parameter needs a particle (BYN5006).

The input covers: `status` before any claim (one run 1-30), a claim of a claimed juz by the same name and by another, `done` and `release` by another name, `done` and `release` of an open juz, every command on a finished juz, a release then a second release, surrounding spaces, juz 0 and 31, a word for the juz, a missing field, an extra field, an unknown command, `status` with an extra field, a blank line, and `status` lines with a single open juz, runs ending at 29 and at 28. The case with no open juz (`none`) is not in the input.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only small-010-khatm-circle
```
