# Heldout seeds: what the owner writes

Decision 2026-11-21 (owner): the first cut's 80 `heldout` tasks (spec 025 T23–T30) are made by option E.

- The owner writes 8 seed tasks, one per category.
- A hosted model on the Anthropic API, under its no-training terms, drafts the other 72 from those seeds. Each drafted task's `task.md` header records the provider (spec 025, the fallback in the "heldout repository" decision).
- The drafted tasks are reported as a separate subset.
- The owner spot-checks the drafts.
- The agent runs `recheck` and reports pass/fail counts and failing task names. It does not read heldout content.
- API spend is measured on the first 8 drafts and reported before the other 64 start.

Qwen does not write heldout tasks. Hudhud is Qwen3.8-27B, and a model that writes its own exam picks tasks it can solve.

The tasks themselves never go in this repository. They go in `../bayan-heldout/tasks/`, a separate clone beside the main checkout.

## The 8 seeds

| Seed | Category | Tier | Check | Note |
|---|---|---|---|---|
| `small-011-…` | small | 1 | tests or stdout | |
| `std-011-…` | std | 2 | tests or stdout | |
| `errors-011-…` | errors | 1 | tests | |
| `contracts-011-…` | contracts | 2 | tests | uses `expects`: two of the 10 heldout contracts tasks must |
| `port-011-…` | port | 2 | stdout | |
| `repair-011-…` | repair | 1 | stdout | |
| `effects-011-…` | effects | 3 | tests or stdout | |
| `spec-011-…` | spec | 3 | tests or stdout | |

The tiers split 3/3/2. Tier 1 is one function, like the example below. Tier 3 is a program of several functions that parses its input, with a reference of about 60–100 lines. Category and tier choices are yours; the table above is a suggestion.

Numbering: each category's `dev` tasks run from `-001` to `-010`, so heldout numbers start at `-011`.

## Two heldout-only rules

- **Marker.** Every file must contain the string in `bayan-heldout/tasks/MARKER`. The exceptions are `checks/stdin`, `checks/expected.stdout` and `checks/exitcode`, which are fed or compared byte for byte. The string can go anywhere: a `//` comment in a `.byn` file, a line in a `.md` file. `recheck` fails a heldout task with a non-exempt file that lacks it (`README.md`, "The marker").
- **Header.** Use `Split: heldout`. Seeds have no provider line, because you wrote them.

## Files per task

Every task has `task.md`, `prompt.md` and `reference/solution.byn`. The rest depends on the category:

| Category | Further files |
|---|---|
| small, std, errors, contracts, effects, spec | `checks/checks.test.byn` and `checks/entry.byn` (`Check: tests`), or `checks/stdin` and `checks/expected.stdout` (`Check: stdout`) |
| port | `source.py` or `source.sh` (the program to port), `checks/stdin`, `checks/expected.stdout` |
| repair | `starter/solution.byn`: a broken file that fails with exactly the diagnostic code the title names, shown in full in the prompt. Plus `checks/stdin` and `checks/expected.stdout` |

Public examples of each shape are in `evals/llm/tasks/`: `port-002-shell-numbered-lines`, `repair-001-missing-particle`, and the one below.

## Worked example: `evals/llm/tasks/errors-003-zakat-nisab/` (a dev task)

### `task.md`
```markdown
# errors-003-zakat-nisab

Title: A failing function with ordered checks
Category: errors
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 46e65014bc6e)
Check: tests

## Files
- `prompt.md`: the text the model is given.
- `checks/checks.test.byn`: hidden. Tests compiled into the same module as the solution.
- `checks/entry.byn`: hidden. An empty `main`, so that `bayan check` has an entry point and reports lints.
- `reference/solution.byn`: a solution that passes every check.

## Notes
The hidden tests call `zakatDue` with valid amounts, with a nisab of 0 or less, with negative savings and with savings below the nisab, and assert the case each failure carries, including which case wins when two apply.
```

### `prompt.md`: what the model sees
The prompt carries the most weight in a task. It must be exact enough that exactly one behaviour is right: name every signature, every failure case, the order of the checks and the rounding, and give one or two examples.

````markdown
Write a file that declares an error set and one function that fails. Do not write a `main` function or any top-level statements.

Declare the error set `ZakatError` with three cases:

- `badNisab`: the nisab is 0 or less.
- `negative`: the savings are below 0.
- `belowNisab`: the savings are below the nisab, so no zakat is due.

Declare:

```
i64 zakatDue(i64 savings, at i64 nisab) fails ZakatError
```

`zakatDue` returns the zakat due on `savings`: one fortieth of them, the division rounded down. The checks run in this order, and the first one that applies decides the failure:

1. `nisab` is 0 or less: fail `badNisab`.
2. `savings` is below 0: fail `negative`.
3. `savings` is below `nisab`: fail `belowNisab`.

Savings equal to the nisab are due.

Examples: `zakatDue(1000, at: 500)` is 25. `zakatDue(50, at: 100)` fails `belowNisab`.
````

### `reference/solution.byn`
```
union error ZakatError {
    /// The nisab is 0 or less.
    badNisab
    /// The savings are below 0.
    negative
    /// The savings are below the nisab.
    belowNisab
}

/// One fortieth of `savings`, once they reach `nisab`.
i64 zakatDue(i64 savings, at i64 nisab) fails ZakatError {
    fail .badNisab if nisab <= 0
    fail .negative if savings < 0
    fail .belowNisab if savings < nisab
    return savings / 40
}
```

### `checks/checks.test.byn`: hidden
Cover the edges that the prompt states but does not list as examples: equality at the boundary, rounding, and which failure wins when two apply.

```
@cases((1000, 500, 25), (500, 500, 12), (4000, 85, 100), (39, 1, 0))
test "zakatDue takes a fortieth" (i64 savings, i64 nisab, i64 expected) {
    assert (try zakatDue(savings, at: nisab)) == expected
}

@cases(0, -1, -500)
test "zakatDue refuses a nisab of 0 or less" (i64 nisab) {
    assert zakatDue(1000, at: nisab) fails ZakatError.badNisab
}

test "zakatDue refuses negative savings" {
    assert zakatDue(-1, at: 100) fails ZakatError.negative
    assert zakatDue(-900, at: 100) fails ZakatError.negative
}

@cases((99, 100), (0, 100), (1, 2))
test "zakatDue refuses savings below the nisab" (i64 savings, i64 nisab) {
    assert zakatDue(savings, at: nisab) fails ZakatError.belowNisab
}

test "the first check that applies decides" {
    assert zakatDue(-5, at: 0) fails ZakatError.badNisab
    assert zakatDue(50, at: -3) fails ZakatError.badNisab
    assert zakatDue(-5, at: 100) fails ZakatError.negative
}
```

### `checks/entry.byn`: hidden
```
void main() {
}
```

### As a heldout seed
The same task as a heldout seed would differ in four places:
- the folder would be `errors-011-…` in `bayan-heldout/tasks/`;
- `task.md` would say `Split: heldout`;
- every file above would contain the `MARKER` string, for example a `// <marker>` line at the top of each `.byn` file and a line in each `.md` file;
- the subject would be new: heldout tasks must not paraphrase a dev task.

## Done when

Each seed passes:

```sh
cd /Users/sy/Developer/ikhbat.org/bayan
bash scripts/bayan-tool.sh llm-eval recheck ../bayan-heldout/tasks --only <task-name>
```

`recheck` checks four things: the reference gets all four results, the header and the file set are right, the marker is present, and, for repair tasks, the starter fails with exactly the code the title names.

Estimated effort: 20–40 min per seed, about 4 h in total. Most of it goes into making `prompt.md` unambiguous and the checks sharp. When all 8 pass, tell the agent, and it starts the API drafts for the other 72.
