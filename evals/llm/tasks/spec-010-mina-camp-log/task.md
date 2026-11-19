# spec-010-mina-camp-log

Title: A union with payloads, built from input and reported by switch
Category: spec
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
The case is settled by section 3.12 of the spec: a union declares its cases one per line with named payloads (`tent(i64 beds, i64 pilgrims)`; a payload without a name is BYN1064), a case with several payloads is built with labels (`.tent(beds: b, pilgrims: p)`; the pinned compiler also accepts them without), and a `switch` over a union is exhaustive with no `default` needed, binding the payload by position (`.bus(let seats)`) or the whole value by name (`.tent t` then `t.beds`). The prompt names the union and the `switch`, not the syntax. A model that reaches for a class hierarchy has no inheritance to use (section 3.10). A candidate that keeps no union and prints as it reads is not caught by the output alone. The design left to the model is the names of the cases and how parsing and reporting are split into functions. The expected output is the pinned compiler's.

The input covers: a tent with free beds, one that is full, one that is short (with spaces around the line), an empty tent (0 and 0, full), a bus of 0 seats, a blank line (skipped), `Rest` (wrong case), `bus` with no count, `bus` with two counts, `tent` with one count, `tent` with a word for a count, `bus` with a negative count, `rest` with an extra field and an unknown word. The seats total equals the pilgrims total, so `every pilgrim seated` is `yes` on the boundary.

## Check command
```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only spec-010-mina-camp-log
```
