# The LLM evaluation set

Tasks that measure how well a model writes Bayān. The spec is `docs/specs/025-llm-eval-set/025-spec.md`. This guide says how to write a task, how to check it and how to run it. The task text is under ISL-P 1.2 like the rest of the repository, and `NOTICE.md` names `evals/`.

The `dev` tasks live in `evals/llm/tasks/`. The `heldout` tasks are in a separate private repository and are never committed here.

## Format

A task is one directory, `<category>-<NNN>-<slug>`. The number is three digits, counted per category, and never reused.

```
repair-001-missing-particle/
  task.md                 the header and the notes
  prompt.md               all the task text the model sees
  checks/                 hidden
  reference/solution.byn  a solution that passes every check
  starter/solution.byn    only when the model repairs or finishes a file
  source.<ext>            only when the model ports a program
```

Nothing under `checks/` or `reference/` is ever shown to a model. The text of a starter file or a source program goes inside `prompt.md`.

`task.md` starts with a title, then these header lines:

```
Category: repair
Tier: 1
Split: dev
Revision: 0023
Checked: bayan 0.3.3-dev (commit 0530e92ea69c)
Check: stdout
```

`Revision:` is the language revision the task was written against. `Checked:` is the compiler version and commit the reference last passed with. `Check:` is `stdout` or `tests`. After the header come three sections: *Files*, *Notes* and *Check command*. Copy them from a seed task.

### Categories

| Category | The model is asked for | Check |
|---|---|---|
| `small` | A small whole program: input, a computation, output | stdout |
| `std` | A program that uses a std module | stdout |
| `errors` | Error sets, `fails`, `fail`, `try`, `catch` | tests |
| `effects` | Public functions with the right `uses` clause, handlers given with `provide` | tests |
| `contracts` | `requires` on types and fields, `expects` on functions | tests |
| `port` | A port of a given Python or shell program, same output for the same input | stdout |
| `repair` | A file that does not compile, and its diagnostic; the fixed file | stdout |
| `spec` | A question about the language, answered by a program that compiles and prints the answer | stdout |

A task belongs to one category. A task about `expects` is a `contracts` task.

### Tiers

| Tier | Meaning |
|---|---|
| 1 | One construct, one function or a short `main`. A reference of about 25 lines or fewer. |
| 2 | Several constructs that must work together. A reference of about 25 to 60 lines. |
| 3 | Several types, a module of more than one file, or a design choice the prompt leaves to the model. A reference of more than 60 lines. |

### The two checks

A `stdout` task is a whole program. It is run with `checks/stdin` as standard input; with no such file the input is empty. Its standard output must equal `checks/expected.stdout` byte for byte. Its exit code must equal the number in `checks/exitcode`; with no such file the code is 0.

A `tests` task is a file of declarations with no `main`. `checks/checks.test.byn` holds the hidden tests. They are compiled into the same module as the solution, and `bayan test` must exit 0. `checks/entry.byn` holds an empty `main`, so that `bayan check` has an entry point.

## Writing a task

1. Write new text. A prompt is never copied or adapted from the repository. Do not take text from `tests/cases/`, `examples/`, `lib/std/` and its tests, `src/`, `tools/`, the code samples in `docs/`, or the site. Before you commit, search those places for the function names and strings of your task.
2. The reverse holds too. Never reuse an eval task as a repository test or a docs sample.
3. Use Islamic names and themes where a name is needed: Aisha, Bilal, Zaynab, iftar, zakat, sadaqah.
4. A check asserts only behaviour the prompt states. Describe each kind of input the checks use. The prompt may show an example. It never shows the hidden input.
5. Write the reference first. It must compile with no diagnostic, be unchanged by `bayan format`, and pass the checks. Put the command that shows this in the *Check command* section.
6. Never type recorded output by hand. See the port rule and the repair rule below.
7. Never describe Bayān as like another language in a prompt.
8. Set the tier from the reference's size and shape (the table above).

### The `expects` rule

A task about `expects` is `Check: stdout`. `expects` aborts the program when it fails, so the hidden run must end with that abort. Put the expected exit code in `checks/exitcode` (134). The check passes only when the stdout and the exit code both match. A candidate without the `expects` cannot get the exit code.

### The port rule

`checks/expected.stdout` of a port task is the recorded output of the original program (`source.<ext>`) on `checks/stdin`. Run the original and save its output. `task.md` names the interpreter and its version.

### The repair rule

A repair task has a `starter/solution.byn` that fails `bayan check` with the code its title names (for example `Repair BYN5005`). `recheck` checks this.

The diagnostic text in the prompt is the compiler's own output for the starter, with only the directory removed from the path. Do not type it.

The program must read its data from `checks/stdin`. The prompt shows an example run on input that is not the hidden input. If the program read nothing and the prompt showed the whole expected output, a candidate of plain `print` lines would pass. `recheck` fails any `stdout` task whose whole `checks/expected.stdout` appears in its `prompt.md`.

## Commands

All three run through `scripts/bayan-tool.sh`. They score with the pinned compiler (`scripts/pinned-bayan.sh`), never the working tree's. Run with no arguments, the tool prints:

```
usage: llm-eval score <task-dir> <candidate-file> [--out <dir>]
       llm-eval recheck <tasks-dir> [--only <task>] [--out <dir>]
       llm-eval run <tasks-dir> --model '<command>' (--machine <text> | --remote <provider>) [--samples <k>] [--context <file>]
            [--label <text>] [--settings <text>] [--only <task>] [--out <dir>]
```

Exit codes of all three: 0 on success, 1 when it could not start (or, for `recheck`, when a task failed), 2 on bad usage.

### Scoring

A candidate is scored in a new, empty scratch directory that holds the candidate as `solution.byn` and a copy of every `checks/*.byn`. Each candidate gets four results, in this order:

| Result | How it is decided |
|---|---|
| compiles | `bayan check --diagnostics json` exits 0 |
| passes | the `stdout` rule above, or `bayan test` exits 0 |
| lint-clean | the check printed no diagnostic whose file is `solution.byn` (a note counts) |
| format-stable | `bayan format --check` exits 0 |

A task is passed when the candidate compiles and passes. The other two results never change that. When a candidate does not compile, the other three are not reached.

A build has 120 seconds, a run 10 seconds and its output 1 MiB. Reaching a limit is a fail with the outcome `limit`. The candidate runs in an OS sandbox with no network, no read access to the task set and writes only in the scratch directory. When no sandbox is available the record says so.

### `score`

`score` scores one candidate against one task and prints one JSON record: `task`, `category`, `tier`, `split`, `revision`, `sample`, `compiles`, `passes`, `lintClean`, `formatStable`, `outcome` (`pass`, `fail`, `no-compile` or `limit`), `passed`, `sandbox` and `limits`. It exits 0 when it printed the record, whatever the candidate scored. `--out` defaults to `tmp/llm-eval/score/`. An existing sample directory is refused.

```sh
bash scripts/bayan-tool.sh llm-eval score evals/llm/tasks/small-001-zakat-due my-candidate.byn
```

### `recheck`

`recheck` runs every task's reference through scoring and checks the task itself: its name and number, its files, its header, that a repair starter fails with only the code its title names, that a `stdout` prompt does not hold the whole expected output, and the marker (see below). It prints `PASS <task>` or `FAIL <task>: <reasons>`, then the slowest run.

```sh
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks
bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks --only small-001-zakat-due
```

Run it before you commit a task. It exits 1 when any task fails. CI runs it over the `dev` tasks.

When every task passed, `--only` was not used and nothing under the tasks directory is uncommitted, `recheck` writes a stamp and prints `stamp: <path>`. Otherwise it prints `no stamp: <reason>`. The stamp is a file named `<task-set commit>-<compiler commit>` under `tmp/llm-eval/recheck/stamps/` at the repository root. Set `LLM_EVAL_STAMP_DIR` to write the stamps elsewhere (the tests do). It holds three lines: `taskSetCommit:`, `compiler:` and `tasks:`.

### `run`

`run` sends each task's prompt to a model command and scores each reply.

```sh
bash scripts/bayan-tool.sh llm-eval run evals/llm/tasks \
  --model 'my-model-command' --machine 'MacBook Pro, M3 Max, 64 GB, macOS' \
  --samples 1 --label baseline
```

- `--model` is a shell command. It reads the prompt on standard input and prints its reply on standard output. It may print one line `tokens: <n>` on standard error.
- Exactly one of `--machine <text>` and `--remote <provider>` is required, so a speed number is never unnamed. A local machine is named by its model, chip, memory, operating system, serving program and quantisation. A hosted model is labelled remote and is not compared with a local one.
- `--samples <k>` is the number of replies per task. The default is 1.
- `--context <file>` is text put between the preamble and the prompt. Runs with different contexts are different runs. Never average them.
- `--label` and `--settings` are free text kept in the summary (for example the sampling settings).
- `--only <task>` runs one task. `--out <dir>` defaults to `tmp/llm-eval/run/`.

The prompt is `evals/llm/preamble.md`, the context file when given, then the task's `prompt.md`. The code is the contents of the last fenced code block of the reply, or the whole reply when there is none. The same rule applies to every model.

The runner writes into `<out>/<n>/`, where `<n>` is the first free number:

- `records.jsonl`: one record per task and sample, as `score` prints it, plus `wallMs`, `tokens` (when printed) and `reply`.
- `summary.json`: one block per split. Each holds pass@1, pass@k, compile rate, lint-clean rate and format-stable rate as counts and rates, overall, per category, per tier and per revision. It names the task-set commit, the compiler, the revisions, the context, the label, the settings, k, the limits, the sandbox, the machine or the provider, and the speed. Tokens per second appear only when every sample printed `tokens:`.
- `work/<task>/<sample>/`: the scratch directories.

It writes nothing into the task set and makes no network call. The model command may.

`summary.json` has a `verified` flag. It is true when the task set is committed and `recheck` has written its stamp for that task-set commit and compiler commit. The `headline` (pass@1 over `heldout`) is written only when `verified` is true. A `dev` result is always labelled as `dev`.

## Re-checking on a branch

Locally the pin is the tip of `dev`. A branch that changes the compiler is scored by the old compiler. On a branch that implements a revision, commit, then run:

```sh
PINNED_BAYAN_REF=HEAD bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks
```

Do this before you merge. CI sets the variable for the whole job.

## Splits

Every task is in one split.

- `dev` tasks may be read by anyone, used to tune prompts, and used as few-shot examples. They are never training data for the project's own models.
- `heldout` tasks are never used for training, for prompt tuning or as examples. Their prompts, checks and references never enter a training corpus. They stay in the private repository. Never copy one into this repository, a prompt, an issue or a chat.
- A task never moves from `dev` to `heldout`. A `heldout` task that leaks moves to `dev`. A leak is a task shown in a prompt, found in a corpus or published.

The tool cannot prove these rules. Nothing checks a training corpus. People keep them.

The headline number of a model is its result on `heldout`. `heldout` tasks are re-checked on the owner's machine.

### The marker

Every file of a `heldout` task carries one marker string, so that a leak into a corpus can be searched for. The exempt files are `checks/stdin`, `checks/expected.stdout` and `checks/exitcode`, because they are fed or compared byte for byte. Every other file carries the marker. That includes hidden files such as `.DS_Store`, which are counted: delete them before you commit.

The marker is in the file `MARKER` at the root of the tasks directory. When `recheck` finds that file, it fails a task whose `Split:` is `heldout` and which has a non-exempt file without the string. Without `MARKER` the check is skipped. This repository has no `MARKER` and no marker string.

## Correcting or retiring a task

When the pinned compiler first implements a new revision, re-run every reference. The first re-check is at revision 0024 (numeric conversions).

When a reference fails:

- Correct the task. Change what the revision broke, run `recheck`, and set `Revision:` to the new revision and `Checked:` to the compiler that passed it.
- Or retire the task. Delete the directory. Never reuse its name or its number.

A result records the revision. Never join results from different revisions into one series without saying so.
