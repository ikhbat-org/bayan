# port-010-python-volunteer-teams

Title: Port a Python program whose objects are shared between names
Category: port
Tier: 3
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 5b753d2c27b6)
Check: stdout

## Files
- `prompt.md`: the text the model is given.
- `source.py`: the original program; its text is also in the prompt.
- `checks/stdin`, `checks/expected.stdout`: hidden. The input the program is run on and the output it must print.
- `reference/solution.byn`: a solution that passes every check.

## Notes
`expected.stdout` is the output of `source.py` on `checks/stdin`, recorded with Python 3.12.13. The task tests that a Bayān struct is a value and a `List` is `unique`: in Python, `alias` and `helpers` hold references to one `Team`, so a change through one name shows through every other. A port that stores `Team` values in two maps copies them, or does not compile because the `List` field moves; the port keeps each team once and refers to it by index. The tier is 3 for that design choice, which the prompt leaves to the model (the reference is 56 lines). The input covers: a change of duty made through a helper that shows under both names of a team, a `join` through an alias, a team name given a new team while another name and its helpers keep the old one, an alias that points an existing name at another team (the name keeps its place in the order), a duty changed on a team no name refers to any more, a person who joins a second team (their later `duty` changes the second), an empty team, a team, a person and an alias source that do not exist, an unknown command, `team` with too few words, `show` with an extra word, extra spaces and a blank line.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only port-010-python-volunteer-teams
```
