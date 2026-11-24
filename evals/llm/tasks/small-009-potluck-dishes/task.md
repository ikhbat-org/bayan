# small-009-potluck-dishes

Title: Potluck dishes and who brings them
Category: small
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
The task tests building text without `+` on strings (BYN2209): the name list is built with `StrBuf`, interpolation or `joined`. A list held in a `Map` cannot be appended to in place (BYN2106), and `List` has no `contains`, so the grouping goes through parallel lists.

The input covers: dishes with one, two, three and four names, a name with two pledges, two dishes that differ only in case, a missing field, three fields, two spaces between fields, surrounding spaces, a blank line.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only small-009-potluck-dishes
```
