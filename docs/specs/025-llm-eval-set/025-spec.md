# 025 — Evaluation set for LLM-written Bayān
Status: draft
Release: unscheduled (nothing a user runs changes)
Sources: user 2026-11-17 ("yes start the llm eval set in parallel"); `docs/bayan-spec.md` (revisions 0001–0024, syntax freeze of revision 0023); `docs/decisions/2026-11-02-002-tooling-port-rules.md` (tooling is Bayān or shell)
Created: 2026-11-17

## Problem
No model has seen much Bayān. The language is new, its syntax was frozen only at revision 0023, and almost all of its text lives in this repository. The owner plans to fine-tune a small local open coder model (7 to 14 billion parameters, LoRA first, then reinforcement learning with rewards the compiler can verify) to write good Bayān. Before any of that, there is no way to say how well a model writes Bayān today, whether a change made it better, or how a small local model compares with a large hosted one.

An evaluation set answers that, provided it measures every model the same way and nobody's opinion enters the score. Bayān has what that needs: a compiler with numbered diagnostics, a test runner, style lints and a formatter. This spec defines the set, how a candidate is scored, and the runner. It comes with a seed of 12 tasks so the format is tested against the compiler before the rest is written.

## Goals
- One task format that covers every category below, with hidden checks and a reference solution per task.
- A score that comes only from the compiler and the tests: compiles, passes its checks, lint-clean, unchanged by `bayan format`.
- The same measurement for a base model, a fine-tuned model and a hosted model, through one command that reads a prompt and prints code.
- A held-out split that no training, prompt tuning or few-shot example ever uses.
- Tasks pinned to a language revision, so a number stays comparable while the language moves.
- A seed of 12 tasks, 2 in each of 6 categories, each with a reference solution checked against the repository's compiler.

## Non-goals
- Training, fine-tuning, or building a training corpus. The set measures; it does not teach.
- Choosing a model, a serving program or a quantisation.
- Network calls in the runner itself. The model command may reach a hosted model; that is the command's business, and the runner neither knows nor helps.
- An LLM judge, a text-similarity score, or human grading.
- Any change to the compiler, the runtime, std, `csharp/`, `src/`, or a golden case.
- A public leaderboard.
- Judging style beyond what the lints and the formatter report.

## User stories
- As the owner, I want one number per model on tasks no model was trained on, so that I can tell whether fine-tuning helped.
- As the person fine-tuning, I want per-category and per-tier results and the compile rate, so that I know what the model gets wrong: syntax, std, errors, contracts.
- As a contributor adding a task, I want a fixed format and one command that proves my reference solution passes, so that a broken task never enters the set.
- As the compiler maintainer, I want the set re-checked when a revision lands, so that a language change shows up as a failing reference and not as a silent drop in every model's score.

## Requirements

### Task format
- R1 A task is one directory named `<category>-<NNN>-<slug>` (the number is per category, three digits, never reused). It holds `task.md`, `prompt.md`, `checks/` and `reference/solution.byn`, plus `starter/solution.byn` when the model is given a file to repair or finish, and `source.<ext>` when it is given a program to port.
- R2 `task.md` starts with the title and the header lines `Category:`, `Tier:`, `Split:`, `Revision:`, `Checked:` and `Check:`, followed by the sections *Files*, *Notes* and *Check command*. `Check:` is `stdout` or `tests`.
- R3 `prompt.md` is all the task-specific text the model sees. The text of a starter file or a source program is inside the prompt. Nothing under `checks/` or `reference/` is ever shown to a model.
- R4 A `stdout` task is a whole program. It is run with `checks/stdin` as standard input (empty input when the file is absent). Its standard output must equal `checks/expected.stdout` byte for byte and its exit code must equal the number in `checks/exitcode` (0 when the file is absent).
- R5 A `tests` task is a file of declarations with no `main`. `checks/checks.test.byn` holds the hidden tests, compiled into the same module as the solution, and `bayan test` must exit 0. `checks/entry.byn` holds an empty `main`, so that `bayan check` has an entry point (R11).
- R6 A check asserts only behaviour the prompt states. Each kind of input the checks use is described in the prompt; the prompt may show an example, never the hidden input itself.
- R7 `expected.stdout` of a port task is the recorded output of the original program on `checks/stdin`. The diagnostic text in a repair prompt is the compiler's own output for the starter file, with only the directory removed from the path. Neither is typed by hand.
- R8 Every task has a reference solution that compiles with no diagnostic, is unchanged by `bayan format`, and passes its checks. `task.md` records the command that shows it.

### Scoring
- R9 Scoring uses the compiler and the tests only (see Non-goals). The same candidate gets the same result on every run: scoring reads no clock, no network and no state outside the task and the candidate.
- R10 A candidate is scored in a new, empty scratch directory that holds the candidate as `solution.byn` and a copy of every `checks/*.byn`. Nothing else may be in it: the compiler treats every `.byn` file in a file's directory as one module.
- R11 Each candidate gets four results, in this order:

  | Result | How it is decided |
  |---|---|
  | compiles | `bayan check --diagnostics json <scratch>` exits 0 |
  | passes | `stdout` tasks: R4. `tests` tasks: `bayan test <scratch>` exits 0 |
  | lint-clean | the `check` run above printed no diagnostic whose file is `solution.byn` (no warning and no note; style lints are notes) |
  | format-stable | `bayan format --check <scratch>/solution.byn` exits 0 |

  A candidate that does not compile has the other three recorded as not reached. `bayan fmt` is not a command; the formatter is `bayan format`.
- R12 A task is passed when the candidate compiles and passes. Lint-clean and format-stable are reported beside it and never change whether a task is passed.
- R13 A repair task also requires that its starter file fails `bayan check` with the diagnostic code the task names. This is a property of the task, checked with the reference, not of the candidate.
- R14 Each build and each run has a time limit and an output limit, the same for every model and stated in the result. Reaching a limit is a fail, never a retry, and is reported as its own outcome, `limit`. The limits are 120 seconds to build, 10 seconds to run and 1 MiB of output, loose enough that only a program that does not stop reaches them.
- R15 A candidate is a program written by a model and is run as one. The runner starts it in the scratch directory as a process with no secrets in its environment, under an OS sandbox that denies network access, denies reading the task set and allows writes only in the scratch directory (macOS first). A `tests` candidate runs inside `bayan test`, which builds it first, so that call may also write the scoring's own build, cache and temporary directories beside the scratch directory, and nothing shared. Where no sandbox is available the runner says so in the result.
- R16 The code is taken from the model's reply by one fixed rule, the same for every model: the contents of the last fenced code block when there is one, otherwise the whole reply.

### Categories
- R17 The set has eight categories. A task belongs to one.

  | Category | What the model is asked for | Check | Seed tasks |
  |---|---|---|---|
  | `small` | A small whole program: input, a computation, output | stdout | 2 |
  | `std` | A program that uses a std module (`std.json`, `std.encoding`, later ones) | stdout | 2 |
  | `errors` | Error sets, `fails`, `fail`, `try`, `catch` | tests | 2 |
  | `effects` | Public functions with the right `uses` clause, handlers given with `provide` | tests | 0 |
  | `contracts` | `requires` on types and fields, `expects` on functions | tests | 2 |
  | `port` | A port of a given Python or shell snippet, with the same output for the same input | stdout | 2 |
  | `repair` | A file that does not compile and its `BYN` diagnostic; the fixed file | stdout | 2 |
  | `spec` | A question about what the language does, answered by a program that compiles and prints the answer | stdout | 0 |

- R18 `effects` and `spec` have no seed task. Before the first task of either is written, its check is tried against the compiler the way the seed was (see *Findings from the seed*).

### Difficulty tiers
- R19 Every task has a tier.

  | Tier | Meaning |
  |---|---|
  | 1 | One construct, one function or a short `main`; a reference of about 25 lines or fewer |
  | 2 | Several constructs that must work together (for example an error set, a loop and a `catch switch`); a reference of about 25 to 60 lines |
  | 3 | Several types or a module of more than one file, or a design choice the prompt leaves to the model; a reference of more than 60 lines |

  The seed has tiers 1 and 2 only. Results are reported per tier as well as overall.

### Splits and contamination
- R20 Every task is in one split. `dev` tasks may be read by anyone, used to tune prompts, and used as few-shot examples. They are never training data for the project's own models. `heldout` tasks are never used for training, for prompt tuning or as examples, and their prompts, checks and references never enter a training corpus.
- R21 The headline number of a model is its result on `heldout`. A `dev` result is always labelled as such.
- R22 A task never moves from `dev` to `heldout`. A `heldout` task that leaks (shown in a prompt, found in a corpus, published) moves to `dev`.
- R23 No task is copied or adapted from text in this repository: `tests/cases/`, `examples/`, `lib/std/` and its tests, `src/`, `tools/`, the code samples in `docs/`, or the site. Prompts are new text. The reverse also holds: no eval task is later reused as a repository test or a docs sample.
- R24 Every `heldout` file carries one marker string, unique to the set, so that a leak into a corpus can be searched for. The files `checks/stdin`, `checks/expected.stdout` and `checks/exitcode` are exempt, because they are fed or compared byte for byte; every other file of a `heldout` task carries the marker (owner, 2026-11-17, Fable's recommendation).
- R25 Where a name is needed, tasks use Islamic names and themes (Aisha, Bilal, iftar, zakat).

### Versioning
- R26 `Revision:` names the language revision the task was written against. `Checked:` names the compiler version and commit its reference last passed with.
- R27 A result records the commit of the task set, the compiler version and commit, and the revision. Results from different revisions are never joined into one series without saying so.
- R28 When the pinned compiler first implements a new revision, every reference is re-run. The first re-check is at revision 0024 (numeric conversions; its text is applied, its implementation has not started, and it is the last syntax change the freeze admits before 0.3.0). A task whose reference then fails is corrected and gets the new `Revision:`, or is retired; a retired task's directory name is not reused.
- R29 The re-check is one command that runs every task's reference through scoring and exits non-zero when any reference does not get all four results. It runs in CI on every push, in the Linux job, over the `dev` tasks. The `heldout` tasks are re-checked on the owner's machine, and the runner gives no headline number unless that re-check passed for the same compiler commit.

### Metrics
- R30 Reported for every run, overall and per category and per tier, as counts and as rates:

  | Metric | Meaning |
  |---|---|
  | pass@1 | Tasks passed by the first sample |
  | pass@k | Tasks where at least one of k samples passes; k and the sampling settings are stated |
  | compile rate | First samples that compile |
  | lint-clean rate | First samples that compile and are lint-clean |
  | format-stable rate | First samples that compile and are format-stable |

- R31 Wall time per task is measured by the runner around the model command. Output tokens per second is reported only when the model command reports its token count (R33); it is never estimated.
- R32 Speed numbers of a local model name the machine they were measured on: the machine model, chip, memory, operating system, the serving program and the quantisation. Speed numbers of a hosted model are labelled as remote and are not compared with local ones.

### Runner
- R33 The runner takes any model through one command. The command reads the prompt on standard input and prints its reply on standard output. It may print one line `tokens: <n>` on standard error. The runner knows nothing else about the model.
- R34 The runner itself makes no network call and downloads nothing.
- R35 The runner is Bayān or shell, as spec 015 requires of tooling, and scores with the pinned compiler (`scripts/pinned-bayan.sh`), never the working tree's.
- R36 The prompt sent for a task is a fixed preamble (what to reply with: one file, `solution.byn`, in one code block), then an optional context file, then `prompt.md`. The result names the context file. Results with different contexts are different runs and are never averaged together.
- R37 The runner writes one record per task and sample (the four results, the times, the reply) and a summary, to a path it is given, under `tmp/` by default. It writes nothing into the task set.
- R38 The runner takes the tasks directory as an argument, so the same runner scores `evals/llm/tasks` (`dev`) and the separate `heldout` set.
- R39 The task data lives in `evals/llm/tasks/` at the root. The `dev` tasks are committed to this repository. The `heldout` tasks are kept in a separate private repository and are never committed here.
- R40 The task text is under ISL-P 1.2 like the rest of the repository; `NOTICE.md` names `evals/`.
- R41 The target size of the full set is 240 tasks: 30 in each of the 8 categories, tiers in the ratio 12/12/6 per category, two thirds `heldout` (160 `heldout`, 80 `dev`). The first usable cut is 120 tasks (15 per category, tiers 6/6/3, 80 `heldout`, 40 `dev`). `effects` and `spec` counts are provisional until one task of each passes the compiler (R18). Tasks about `expects` are counted in `contracts`.

## Findings from the seed
Facts about the compiler at `bayan 0.3.3-dev` (commit `5810cf25b398`) that the format above depends on. Each was observed while checking the seed.

- Every `.byn` file in a file's directory is compiled with it. A reference and a starter side by side fail as a duplicate declaration, which is why each sits in its own directory and why R10 asks for an empty scratch directory.
- `bayan check` on a directory with no entry point fails with BYN2014 and reports no lint. With an empty `main` in a second file it reports them, which is why `tests` tasks carry `checks/entry.byn`.
- `bayan test` does not report lints. Style lints come from `bayan check` with severity `note`.
- A constant argument to a type with `requires` is checked at compile time, so a hidden test cannot assert that `Percent(101)` fails; it must pass the value through a function.
- A violated `expects` ends the process with exit code 134. A test cannot assert it, so a task about `expects` needs a `stdout` check with `checks/exitcode`. The seed has none.
- A test that prints without end does not grow `bayan test` without bound (`bayan 0.3.3-dev`, commit `0530e92ea69c`, macOS, 2026-11-18). It is stopped at the 10-second test limit with status `timeout`, its `output` field keeps the first and last 64 KiB (the whole `--json` report was 132 KiB), and the peak resident memory of `bayan test` and its children was 80.5 MiB, against 69.6 MiB for the same test printing one line.

## Acceptance criteria
- Given the seed, when the *Check command* of each `task.md` is run from the repository root, then each prints `PASS <task>` (R8). Recorded 2026-11-17: 12 of 12.
- Given a task and a candidate that does not compile, when it is scored, then compiles is false and the other three results are not reached (R11).
- Given a `tests` task and a candidate that contains a `main`, when it is scored, then it does not compile and the task is failed (R5, R10).
- Given the same candidate scored twice, then both records hold the same four results (R9).
- Given a model command that prints a reply with two code blocks, when the runner extracts the code, then it takes the last one (R16).
- Given a run, then its summary holds pass@1, the compile rate, the lint-clean rate and the format-stable rate, overall and per category and tier, with counts (R30), and names the task-set commit, the compiler commit, the revision and the context file (R27, R36).
- Given the runner with a model command that needs no network, when it runs with the network off, then it completes (R34).
- Given the pinned compiler after revision 0024 is implemented, when the re-check runs, then every reference gets all four results or its task is corrected or retired (R28, R29).
- Given a `heldout` task, then no file of it is in a prompt, a few-shot example or a training corpus (R20).

## Law candidates
- **References pass:** for every task in the set, its reference solution compiles, passes its checks, is lint-clean and is format-stable under the pinned compiler (R8, R29). A test can prove this on every commit.
- **Scoring is a function:** for every task and candidate, two scoring runs give the same four results (R9).
- **Hidden stays hidden:** for every task, no line of `checks/` or `reference/` appears in the prompt the runner sends (R3), apart from lines the prompt itself states.

## Open questions
All answered; each resolution is marked with the owner's decision.

- **Where the set lives.** *Resolved:* `evals/llm/tasks/` at the root (R39), with the runner wherever spec 015 puts tooling, not inside `evals/` (owner, 2026-11-17, Fable's recommendation).
  - `tests/` stays the compiler's own cases, which keeps R23 visible in the tree, and a corpus can exclude `evals/` by path.
- **Whether the set ships in the repository.** *Resolved:* `dev` tasks in this repository; `heldout` tasks in a separate private repository, never committed here. The reason is that this repository is public (since 2026-11-01), so anything committed once is public in every clone (owner, 2026-11-17, Fable's recommendation).
  - The runner takes a tasks directory (R38). Leak paths to manage: scoring a hosted model sends every `heldout` prompt to that provider, so `heldout` runs only against endpoints with a no-training term and the result records the provider; `heldout` tasks written by a hosted-model worker also pass through a provider.
  - *Resolved:* the `heldout` tasks live in `github.com/ikhbat-org/bayan-heldout`, a plain private repository (not a fork or submodule of this one), cloned beside the main checkout and passed through R38's tasks-directory argument; only the owner writes to it. `heldout` tasks are written by the owner or a local model; hosted-model workers write `dev` tasks only. If local throughput cannot reach the first cut's 80 `heldout` tasks, the fallback is hosted authoring under the same no-training term, with the provider recorded per task in the `task.md` header and those tasks reported as a separate subset (owner, 2026-11-17, Fable's recommendation; the owner creates the repository).
- **The license of the task text.** *Resolved:* no separate license; task text stays under ISL-P 1.2 and `NOTICE.md` gets one line naming `evals/` (R40) (owner, 2026-11-17, Fable's recommendation).
  - The license is silent on model training; whether the Foundation wants ISL terms to say anything about it is a question for the license, not this spec.
- **Which model runs the first baseline, and with which context.** *Resolved:* the first run is a set-validation run on the strongest hosted model the owner already pays for, twice (no context, then `docs/bayan-grammar.md`), then a local base model the owner picks under the same two contexts (owner, 2026-11-17, Fable's recommendation).
  - The no-context number is the one to track for fine-tuning. The grammar file describes syntax and not std, so `std` tasks measure guessing API names; report `std` separately or accept a low number. The owner still names the local model and its machine.
- **Whether `dev` tasks may be used as training data.** *Resolved:* no; `dev` is for prompt tuning and few-shot examples only, as R20 says (owner, 2026-11-17, Fable's recommendation).
  - This keeps a daily number that stays meaningful and `heldout` looked at rarely. Others may train on `dev` under the license (R40). The scoring procedure (R11) may be reused as a reward on separately written tasks.
- **Size per category and tier, and the share that is `heldout`.** *Resolved:* R41: 240 tasks, two thirds `heldout`, with a first cut of 120 (owner, 2026-11-17, Fable's recommendation).
  - With 160 `heldout` tasks the 95% interval near 50% is about 8 points, enough to see a real change from fine-tuning; paired comparison of two models on the same tasks is tighter.
- **The limits of R14 and the isolation of R15.** *Resolved:* fixed generous limits (R14) and an OS sandbox with no network, no read of the task set and writes only in scratch, macOS first (R15) (owner, 2026-11-17, Fable's recommendation).
  - `timeout` is not on stock macOS, so the runner needs its own watchdog or a stated dependency. Check the limits against the slowest reference (run limit at least 10 times it). Gap: `repair-001-missing-particle/prompt.md` prints the full expected output, so a candidate of two `print` lines passes; repair checks need an input the prompt does not show, or a second hidden case.
- **Whether the re-check of R29 runs in CI.** *Resolved:* yes for `dev`, on every push in the Linux job, with `heldout` re-checked locally under a runner guard (R29) (owner, 2026-11-17, Fable's recommendation).
  - If the re-check takes more than about 3 minutes at full size, it moves to a nightly workflow and a 12-task smoke subset stays on push. To settle in the plan: `scripts/pinned-bayan.sh` pins the tip of `dev` and builds the C# CLI, so the scorer is not the self-hosted compiler users download; and a branch re-check runs the `dev`-tip compiler, not the branch's.

## Seed record
Checked 2026-11-17 with `bayan 0.3.3-dev` (commit `5810cf25b398`) from `scripts/pinned-bayan.sh`; all are `Split: dev`, `Revision: 0023`.

| Task | Tier | Check | What it covers |
|---|---|---|---|
| `small-001-zakat-due` | 1 | stdout | reading lines, parsing a number, skipping bad records |
| `small-002-tasbih-tally` | 2 | stdout | `Map` and `List`, ordering by count with ties |
| `std-001-json-iftar-guests` | 2 | stdout | `std.json`: parse, `Untrusted`, walking a `JsonValue` |
| `std-002-base64-salam` | 1 | stdout | `std.encoding`: `Base64.encode`, `decode`, `Utf8.decode` |
| `errors-001-prayer-time` | 2 | tests | an error set, `fail`, passing an error on with `try` |
| `errors-002-sadaqah-shares` | 2 | tests | error cases with payloads, `catch switch` |
| `contracts-001-date-portion` | 2 | tests | `requires` on fields and on a struct, `with` |
| `contracts-002-discount-percent` | 1 | tests | `type distinct` with `requires` |
| `port-001-python-guest-table` | 2 | stdout | a Python snippet: padding and alignment |
| `port-002-shell-numbered-lines` | 1 | stdout | a shell `read` loop |
| `repair-001-missing-particle` | 1 | stdout | BYN5005, an argument without its particle |
| `repair-002-unhandled-failure` | 2 | stdout | BYN2602, where the offered `try` is not the fix the task needs |
