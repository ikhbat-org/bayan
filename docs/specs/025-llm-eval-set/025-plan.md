# 025 — Plan
Spec: ./025-spec.md
Status: draft
Release: unscheduled
Sources: ./025-spec.md; `docs/decisions/2026-11-17-010-open-questions-019-023-025.md` (Q1–Q8); `docs/specs/015-tooling/015-spec.md` (R1); probes run 2026-11-17 on macOS 26.6.2 with `bayan 0.3.3-dev` (commit `132124b8d146`), listed under *Tech / dependencies*

## Approach
One Bayān tool, `tools/llm-eval.byn`, with three subcommands. It runs through `scripts/bayan-tool.sh`, so it always uses the pinned compiler (015 R1).

- `score <task-dir> <candidate-file>` scores one candidate and prints one JSON record.
- `recheck <tasks-dir>` scores every task's reference, checks the task's own properties, and exits non-zero when any task fails.
- `run <tasks-dir> --model '<command>'` sends each prompt to the model command, scores each reply, and writes records and a summary.

One shell launcher, `scripts/evals/llm-sandbox.sh`, starts every process the scorer runs. It gives the process a clean environment, an output cap, and on macOS an OS sandbox. The tool calls it with `Io.run(…, timeout:)`, which is the watchdog.

The work goes in this order: launcher, `score`, `recheck`, the two leaking repair tasks, CI, `run`, the task-writing guide, the probes for `effects` and `spec`, then the tasks themselves, then the laws. Tasks for `heldout` are written in the private repository and never touch this one.

### Decisions the spec left to the plan

**Compiler used for scoring.** Scoring uses what `scripts/pinned-bayan.sh` prints (R35). Today that is the C# CLI built at the tip of `dev`, not the self-hosted binary a user downloads. The plan keeps the pin and does not add a second compiler path. Three things make this safe. Laws L027 and L028 hold the two compilers equal. Every record names the version line and commit of the binary that scored it (R27). One task (T32) runs the re-check once against a self-hosted binary through the script's `PINNED_BAYAN` variable and records whether all results agree. When spec 019 changes what the pin builds (019 R28), the eval follows with no change, because it only calls the script.

**Re-check on a branch.** Locally the pin is the tip of `dev`, so a branch that changes the compiler is scored by the old compiler. The fix is the variable the script already has: `PINNED_BAYAN_REF=HEAD` scores with the branch's last commit. CI already sets it for the whole job. The guide (T11) says: on a branch that implements a revision, commit, then run `recheck` with `PINNED_BAYAN_REF=HEAD` before merging. No new flag.

**Watchdog on macOS.** `timeout` is not on stock macOS (`/usr/bin/timeout` is absent; this machine has only Homebrew's). The runner needs none: `Io.run` takes `timeout:` and kills the child's process group when it expires (`runtime/bayan-rt.c`, SIGTERM then SIGKILL). No dependency is added.

**Output limit.** The launcher pipes the process's standard output through `head -c 1048577` into a file. A file longer than 1 MiB is the `limit` outcome. `head -c` is on macOS and Linux.

**Sandbox on macOS.** `/usr/bin/sandbox-exec -f <profile>` with a profile the launcher writes per sample. Probed on this machine: `(deny network*)` stopped `curl` (exit 6), `(deny file-read* (subpath <tasks-dir>))` stopped `cat` of a hidden file, `(deny file-write*)` followed by `(allow file-write* (subpath <dir>))` allowed writes only under `<dir>`, and a built candidate ran and printed its output. On Linux the launcher applies the clean environment and the output cap and reports `sandbox: none`; the record and the summary carry that word (R15). CI on Linux only scores references, which are the project's own code.

**What the sandbox may write.** Each sample gets its own directory with four parts: `src/` (the scratch directory of R10: `solution.byn` and the copied `checks/*.byn`, nothing else), `bin/`, `cache/` and `tmp/`. A `stdout` candidate runs with `src/` as its only writable path, as R15 says. A `tests` candidate runs inside `bayan test`, which compiles first, so that call may write the whole sample directory, with `BAYAN_CACHE` pointing at the sample's `cache/`. This is wider than R15's wording by the sample's own `bin/`, `cache/` and `tmp/`. Nothing shared is writable, so one candidate cannot change what the next one is scored with. A cold cache cost 2.3 s for a `tests` task in the probe. T2 adds one sentence to R15 saying so.

**Time limits for `tests` tasks.** `bayan test` builds and runs in one call. The call gets the 120 s build limit, and `BAYAN_TEST_TIMEOUT_MS=10000` gives each test the 10 s run limit. The scorer reads `bayan test --json`; a test with status `timeout` makes the outcome `limit`. The exit code still decides `passes` (R11).

**The leak in the repair tasks.** `repair-001-missing-particle` and `repair-002-unhandled-failure` both read no input and both show the full expected output in `prompt.md`. A candidate of plain `print` lines passes either. The fix keeps the format of R4 (one `checks/stdin`, one `checks/expected.stdout`): each program is changed to read its data from standard input, the prompt shows an example run on input that differs from the hidden one, and the starter still fails with the same diagnostic code. The directory names stay. `recheck` then refuses any `stdout` task whose whole `expected.stdout` appears in its `prompt.md`, so the leak cannot return. The guide states the rule for every later repair task.

**Re-check in CI.** One new step in the Linux leg of the `build` job in `.github/workflows/ci.yml`: `bash scripts/bayan-tool.sh llm-eval recheck evals/llm/tasks`. The job already sets `PINNED_BAYAN_REF: HEAD`, so the commit under test scores its own tasks, which is what R28 needs. The 12 seed checks took 11.6 s warm on this machine. T31 measures the step at the first cut; over 3 minutes, the full run moves to a nightly workflow and a 12-task subset stays on push.

**Guard for `heldout`.** A passing `recheck` writes a stamp named by the task-set commit and the compiler commit under `tmp/llm-eval/recheck/`. It writes none when the tasks directory has uncommitted changes. `run` on a directory that holds any `Split: heldout` task looks for the stamp of the same two commits. Without it the summary is marked `unverified` and holds no headline number (R29).

**`Checked:` lines.** `recheck` never rewrites a task. `Checked:` changes only when a task is written, corrected, or re-checked at a new revision (R28).

**Laws.** The three law candidates become three pairs of tasks: draft as `proposed` and wait for the owner to enact, then prove. A worker may create a `proposed` file and may not enact it (`docs/laws/README.md`). The proofs are cases in the shell tests, so each law sets `check:` itself.

### Missing, for the owner
- The name and location of the private `heldout` repository, and who may write `heldout` tasks. A hosted-model worker that writes them sends them through a provider (spec, Open questions). T22 cannot start without this.
- R24 asks for the marker in every `heldout` file. `checks/stdin`, `checks/expected.stdout` and `checks/exitcode` are compared or fed byte for byte and cannot hold one. The plan puts the marker in every file that can hold a comment or free text (`task.md`, `prompt.md`, every `.byn`, `source.*`) and exempts those three. This needs the owner's yes, and one sentence in R24.
- The marker string is made in the private repository and is never written in this one. `recheck` reads it from a file named `MARKER` at the root of the tasks directory when that file exists.
- The spec names an acceptance criteria file for this plan. None is in the worktree. The plan works from the list in the task message.

## Tech / dependencies
- The pinned `bayan` (C# CLI at the `dev` tip, `scripts/pinned-bayan.sh`). Commands and flags used, each read from `bayan --help` on the pinned build: `check --diagnostics json <path>`, `build <path> -o <file>`, `test --json <path>`, `format --check <path>`, `--version`. `BAYAN_CACHE` and `BAYAN_TEST_TIMEOUT_MS` are read by the CLI (`csharp/Bayan.Backend.C/Toolchain.cs:48`, `csharp/Bayan.Cli/CliApp.cs:647`, `src/driver/test.byn`).
- Builtins the tool uses, all in `csharp/Bayan.Semantics/Builtins.cs`: `Io.run` with `directory:`, `input:`, `env:`, `timeout:`; `Io.readFile` (bytes), `Io.readText`, `Io.writeFile`, `Io.listDir`, `Io.createDirectory`, `Io.monotonicNanos`, `Env.get`; `std.json` for records.
- Shell: bash 3.2 or later, `head -c`, `env -i`, `git`. macOS only: `/usr/bin/sandbox-exec` (present on 26.6.2; its man page marks it deprecated).
- No Python, no Deno, no new package, no network.
- `scripts/pinned-bayan.sh` variables used as they are: `PINNED_BAYAN_REF` (branch and CI), `PINNED_BAYAN` (T32 only).

## Changes by area
- **Launcher** — `scripts/evals/llm-sandbox.sh` and its test. Clean environment (an allowlist: `PATH`, `HOME` set to the sample's `tmp/`, `TMPDIR`, `BAYAN_CACHE`, `BAYAN_TEST_TIMEOUT_MS`, `NO_COLOR`, `DOTNET_ROOT`), output cap, sandbox profile, a status file with the exit code, whether the cap was reached, and the sandbox name. (R14, R15)
- **Scorer** — `tools/llm-eval.byn`, `score`. Reads the `task.md` header, builds the sample directory, runs the four steps of R11 in order through the launcher, and prints one record. For `stdout` tasks it builds to `bin/solution`, runs it with `checks/stdin`, and compares bytes and exit code. (R2, R4, R5, R9–R12, R14, R35)
- **Re-check** — `tools/llm-eval.byn`, `recheck`. For each task: name and files as R1, header as R2, the reference gets all four results, a repair starter fails with the named code, the leak guard above, the marker when `MARKER` exists, no reused number. Prints `PASS <task>` or `FAIL <task>: <reason>`, the slowest run time, and writes the stamp. (R1, R2, R8, R13, R24, R26, R28, R29)
- **Runner** — `tools/llm-eval.byn`, `run`, and `evals/llm/preamble.md`. Builds the prompt (preamble, optional context file, `prompt.md`), runs the model command with the prompt on standard input, takes the code by R16, scores it, repeats for k samples, writes `records.jsonl` and `summary.json`. (R3, R16, R21, R27, R30–R34, R36–R38)
- **Tests** — `scripts/evals/llm-eval.test.sh`, `scripts/evals/llm-sandbox.test.sh`, both added to the `unix` list of `scripts/ci/script-tests.sh`. They build small task sets under `tmp/` at run time and use stub model commands (`printf` scripts); no task data is added for them.
- **CI** — `.github/workflows/ci.yml`: the re-check step, Linux only. (R29)
- **Seed tasks** — `evals/llm/tasks/repair-001-missing-particle/`, `repair-002-unhandled-failure/` (the leak); the *Check command* section of all 12 `task.md` files becomes the one `recheck --only <task>` line. (R6–R8)
- **Guide** — `evals/llm/README.md`: the format, the rules for writing a task, the repair rule, how to run `recheck` and `run`, the branch re-check, the `heldout` rules, retiring a task. (R17, R19, R20, R22, R23, R25, R28, R39)
- **Spec** — `docs/specs/025-llm-eval-set/025-spec.md`: the R15 and R24 sentences, new findings from the `effects` and `spec` probes, the seed record after T5g. `docs/specs/README.md` is regenerated by `bash scripts/docs/gen-spec-index.sh --write`. (R18)
- **Tasks, `dev`** — `evals/llm/tasks/<category>-NNN-<slug>/`, written per category. (R17, R19, R41)
- **Tasks, `heldout`** — the private repository only. (R20, R24, R39, R41)
- **Laws** — `docs/laws/<NNN>-*.md`, three files, numbers taken when drafted. (Law candidates)
- **Already done, no task** — R40: `NOTICE.md` names `evals/`. R39: the `dev` seed is at `evals/llm/tasks/`.

## Data / interfaces
**Commands.**
```
bash scripts/bayan-tool.sh llm-eval score <task-dir> <candidate-file> [--out <dir>]
bash scripts/bayan-tool.sh llm-eval recheck <tasks-dir> [--only <task>] [--out <dir>]
bash scripts/bayan-tool.sh llm-eval run <tasks-dir> --model '<command>' [--samples <k>] [--context <file>]
     [--label <text>] [--settings <text>] [--machine <text> | --remote <provider>] [--only <task>] [--out <dir>]
scripts/evals/llm-sandbox.sh --write <dir> --deny-read <dir>... --stdin <file> --stdout <file> --status <file> -- <program> [args...]
```
`--out` defaults to `tmp/llm-eval/<subcommand>/`. Nothing is ever written under `<tasks-dir>` (R37). Exit codes: 0 done (for `recheck`: every task passed), 1 a task failed (`recheck`) or a run could not start, 2 usage.

**Sample directory.** `<out>/work/<task>/<sample>/` with `src/`, `bin/`, `cache/`, `tmp/`, made new for each scoring and refused when it already exists.

**Score record**, one JSON object per task and sample:
- `task`, `category`, `tier`, `split`, `revision`, `check`
- `sample` (1 to k)
- `compiles`, `passes`, `lintClean`, `formatStable`: `true`, `false` or `"not reached"`
- `outcome`: `pass`, `fail`, `limit` or `no-compile`
- `passed`: compiles and passes (R12)
- `sandbox`: `sandbox-exec` or `none`
- from `run` only: `wallMs`, `tokens` (absent when the command printed no `tokens:` line), `reply`

The four results, `outcome` and `passed` depend only on the task and the candidate. Times are separate fields and are never an input to them (R9).

**Summary**, `summary.json`: task-set commit, compiler version line and commit, the revisions present, context file or `none`, label, settings, k, the limits, sandbox, machine text or `remote` with the provider, split, `verified` (the stamp was found), then counts and rates for pass@1, pass@k, compile, lint-clean and format-stable: overall, per category, per tier. A summary over `dev` tasks carries `split: dev`. A directory with both splits gives two blocks, never one joined number. Tasks of different revisions are reported per revision and the summary says so.

**Model command.** Run with `sh -c`, prompt on standard input, reply on standard output, optional `tokens: <n>` line on standard error. The runner sets nothing else and opens no socket.

**Sandbox profile**, written per sample, in this order: allow by default; deny all network; deny reads under the tasks directory and under `<out>`, then allow reads under the sample directory; deny all writes, then allow writes under the `--write` directory.

## Risks & mitigations
- **`sandbox-exec` is deprecated.** It works on macOS 26.6.2. The launcher test runs the deny cases on every macOS CI run, so a release that drops it fails the test instead of scoring unsandboxed. The fallback is `sandbox: none` in the record, never silence.
- **The compiler under the sandbox with a cold cache.** The probe ran `bayan test` under the profile with a warm cache only. T2 must pass a `tests` task from an empty `cache/` under the sandbox. If the compiler needs a path the profile denies, the profile gains that one read path; it never gains a write path outside the sample.
- **The scorer is not the shipped compiler.** See the decision above; T32 measures the gap once. A disagreement is a compiler bug to file, and the summary names the binary either way.
- **A test that prints without end.** `bayan test` captures each test's output (the `output` field of `--json`). Whether it bounds that capture was not checked. The 10 s limit per test and the 120 s call limit bound the time. T2 runs one such test and records the memory it reached; if it passes a few hundred MiB, the finding goes in the spec and the question goes to the owner.
- **Non-UTF-8 output.** `Io.run` fails on output that is not UTF-8. The launcher redirects output to files and the tool compares bytes with `Io.readFile`, so a candidate's bytes never pass through a string. A model reply that is not UTF-8 is scored as `no-compile`.
- **A `heldout` prompt sent to a provider.** The runner cannot prevent it. `--remote <provider>` is required when any task is `heldout` and no `--machine` is given, and the provider is in the summary (spec, Open questions).
- **CI time.** About 1 s per task warm here; a cold Linux runner is slower. T31 measures and applies the 3-minute rule.
- **Laws proved by shell tests.** `scripts/selfhost/pre-push-laws.sh` runs `dotnet test --filter Law=<id>` for every enacted law and ignores `check:`. A law proved by a shell test would run zero tests there. T34 changes that script to run a law's own `check:` when it has one, before the first of the three laws is enacted.
- **Law numbers.** `docs/laws/` on `dev` has gaps (029, 030, 032–037) that other branches may hold. Each draft task takes its number with `/laws new` after reading `docs/laws/` on the open branches.
- **Task text copied from the repository (R23).** The guide lists the forbidden sources. Review of each task-writing task includes a search of `tests/cases/`, `examples/`, `lib/std/` and `docs/` for the task's function names and strings.
- **Port tasks need Python or a shell once.** `expected.stdout` is recorded from the original by the task writer (R7). The runner and CI never run the original, so no CI step gains Python (015 R7).

## Coverage check
| R | Where |
|---|---|
| R1 | `recheck` (name, files, numbers); guide |
| R2 | `score` (header reader); `recheck` |
| R3 | `run` (prompt holds only preamble, context, `prompt.md`); sandbox denies reads of the task set; law "Hidden stays hidden" |
| R4 | `score`, `stdout` path |
| R5 | `score`, `tests` path |
| R6 | repair fix; leak guard in `recheck`; guide |
| R7 | repair fix (diagnostic text re-recorded); guide; port tasks |
| R8 | `recheck`; seed *Check command* lines |
| R9 | `score` (no clock in results); law "Scoring is a function" |
| R10 | sample directory, `src/` |
| R11 | `score`, four steps in order |
| R12 | `passed` field |
| R13 | `recheck`, starter check |
| R14 | `Io.run` `timeout:`, `BAYAN_TEST_TIMEOUT_MS`, `head -c` cap, `limit` outcome; T31 checks the 10× margin |
| R15 | launcher; one sentence added to R15 for `tests` tasks |
| R16 | `run`, extraction |
| R17 | task-writing tasks per category; guide |
| R18 | the `effects` and `spec` probes |
| R19 | `Tier:` header; tier counts in each task-writing task; summary per tier |
| R20 | guide; `heldout` only in the private repository |
| R21 | summary split blocks |
| R22 | guide |
| R23 | guide; review search |
| R24 | marker check in `recheck`; needs the owner's answer on data files |
| R25 | guide; task-writing tasks |
| R26 | header; `Checked:` rule above |
| R27 | summary fields |
| R28 | T42; branch re-check with `PINNED_BAYAN_REF=HEAD` |
| R29 | `recheck`; CI step; stamp and guard |
| R30 | summary |
| R31 | `wallMs`, `tokens` |
| R32 | `--machine`, `--remote` |
| R33 | model command interface |
| R34 | no network in tool or launcher; test with the sandbox's network denial around a stub model |
| R35 | `scripts/bayan-tool.sh`; compiler decision |
| R36 | preamble file, `--context` |
| R37 | `--out`, default under `tmp/` |
| R38 | `<tasks-dir>` argument |
| R39 | in place for `dev`; private repository for `heldout` |
| R40 | done (`NOTICE.md`) |
| R41 | first cut: T12–T30; full size: T40a–h, T41a–h |
