# 019 — Plan

Status: approved (text drafted 2026-11-17, owner to review)
Release: unscheduled
Sources: docs/decisions/2026-11-16-006-after-022-roadmap-decisions.md (§1, §2, §3, §4, C# archive plan); docs/bayan-milestones.md (Target: zero dependencies; user 2026-11-13); docs/decisions/2026-11-16-007-additional-concepts-review.md (Q9)

Spec: ./019-spec.md

## Approach

019a is five steps in a fixed order. Each step leaves `dev` green with the xUnit suite still running, so the work can stop after any of them. 019b is a sixth step that starts only when the entry condition (R30) holds.

1. **Golden runner (first).** `bayan test` learns to read a cases directory. `src/driver/walk.byn` already walks directories and `runTest` in `src/driver/test.byn` already runs a child with a time limit; the loop that calls it runs one test at a time. The runner adds a case walk, a comparison per kind, a worker pool for `--jobs`, and `@cases` rows. It is checked against the cases that exist today: the runner and the xUnit classes that read `tests/cases/` (`DiagTests`, `RunTests`, `ParserTests`, `LexerTests`, `TypedDumpTests`, `ManifestTests`, `DiagJsonTests`, `StyleTests`) must agree on every case before anything else moves.
2. **Inventory and export.** Most expectations are computed while the test runs (see Data / interfaces), so the freeze is an export, not a file move. Each harness gets an export mode, on only when an environment variable names an output directory: instead of asserting, it writes the generated input and the C# compiler's output as a case. The export runs once, on a build of the `v0.3.2` tag. Exported cases are then run by the golden runner with the self-hosted compiler; a case that fails there is either a listed divergence (R12) or a bug to fix before the freeze is declared.
3. **Port what is not a golden.** Tests that assert on behaviour with no stable text output (process handling, memory bounds, the test runner itself, scripts) become Bayān `test` blocks or shell tests. The coverage baseline is taken over the whole suite before this step and the ratchet runs after each batch.
4. **Language server.** Sessions are recorded against the C# `bayan-lsp` at the tag, then the server is written in Bayān under `editors/language-server/` until the replay passes, then the bound tests are ported. Placement C (decided 2026-11-17): this step runs in parallel with steps 1 to 3 and 5, and 019a is declared landed without it; until the replay passes the C# server stays the shipped one and `editor-gate.yml` and the server part of the memory gate keep .NET (R24). Step 6 waits for it (R30).
5. **CI from the bootstrap.** One script builds stage 0 from `bootstrap/bayan.c` and stage 1 from `src/`; every workflow and gate uses it. The .NET install steps go. The diverse double-compiling job is added and is the one place that installs .NET. The xUnit suite stops being run on `dev` here, and 019a is declared landed (R29).
6. **019b.** Tag, decision doc, removal commit, post-removal checks, docs.

The export harness changes (step 2) are the only edits to C# in 019. They live on a branch cut from the `v0.3.2` tag and are not merged to `dev` as test changes: the exported files are what lands. The branch name and its head are recorded in the freeze manifest, so the export can be repeated.

## Tech / dependencies

Verified in the repo at 06eab86f:

| Thing | Version | Where | After 019 |
|---|---|---|---|
| .NET SDK | 10.0.100, `rollForward: latestFeature` | `global.json` | used only by the R27 job and the Visual Studio extension |
| .NET SDK in CI | 10.0.403 | `scripts/ci/install-dotnet.sh` | same script, called only from the R27 workflow |
| xunit | 2.9.3 | `csharp/tests/Bayan.Tests/Bayan.Tests.csproj` | frozen with the tag |
| Microsoft.NET.Test.Sdk | 17.14.1 | same | frozen |
| xunit.runner.visualstudio | 3.1.4 | same | frozen |
| coverlet.collector | 10.1.0 | same | frozen |
| zig | 0.17.0 | `.zig-version` | unchanged |
| vsce | 4.1.0 | `scripts/release/editor-gate.sh` | unchanged |
| Bayān | 0.3.2 | `VERSION` | unchanged by this spec |

The bootstrap build command is the one in `bootstrap/README.md`: `cc -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off bootstrap/bayan.c bootstrap/bayan-rt.c -lm`. No new dependency is added. Python, bash, PowerShell and Node stay where they are today (other rows of the dependency table).

## Changes by area

**Driver (`src/driver/`)**
- `test.byn`: `--jobs`, a cases-directory argument, golden results in the summary, `--json` and the exit code; `@cases` rows as separate tests.
- New `golden.byn`: case discovery per kind, the conventions of R6, comparison, first-difference message, update mode, `.pending`.
- `walk.byn`: reused for discovery; bounded as today.
- `testreport.byn`: the report shape gains a kind and a case path.
- `diagdocs.byn`, `runtime.byn`: generated today under `BAYAN_UPDATE=1` by xUnit classes (`SelfhostDefaultT1Tests`, `SelfhostDriverRuntimeTests`); they get a generator script with a freshness check.

**Cases (`tests/cases/`)**
- Existing 12 kinds stay as they are.
- New kinds from the export, one directory each, named for what is compared: `sem` (one generated program and its `== name` sections), `emit-c` (input and emitted C digest), `cli` (arguments, exit code, stdout, stderr). Final names are fixed by the inventory task.
- `tests/cases/FREEZE.tsv` (manifest, R13) and `tests/cases/DIVERGENCES.tsv` (R12).
- `tests/inventory-019.tsv` (R11).

**Tests in Bayān and shell**
- Bayān `test` blocks beside the code they cover in `src/` and `lib/std/`, for the classes whose disposition is "Bayān tests".
- `tests/parity/` (format already used by `scripts/parity/run.sh`) for command-line behaviour that needs set-up files or an environment.
- `runtime/tests/*.c` (11 files) get a shell runner; today `RuntimeNativeTests` builds and runs them.

**Language server (`editors/language-server/`)**
- New Bayān package beside the C# sources: a `bayan.toml` and `src/` with modules that mirror the seven C# files (transport, lexer, keywords, indexer, workspace, server, main).
- `editors/language-server/sessions/`: recorded sessions (R21).
- `editors/vscode/`, `editors/visualstudio/`: no source change (R23).

**Scripts**
- New `scripts/bootstrap-build.sh` (stage 0 from the bootstrap, stage 1 from `src/`) and `scripts/test.sh` (the full suite: golden cases, Bayān tests, script tests, runtime C tests).
- `scripts/pinned-bayan.sh`, `scripts/dist.sh`, `scripts/selfhost/land.sh`, `guard.sh`, `preflight.sh`, `shard-test.sh`, `wp1-test.sh`, `pre-push-laws.sh`, `mutate-batch.sh`, `mutation-step.sh`, `scripts/quality/coverage.sh`, `scripts/quality/mutate.sh`: every `dotnet` call replaced or removed.
- `scripts/release/memory-gate.sh`, `editor-gate.sh` and their `.test.sh`: the three `dotnet test` filters become runs of the ported bound tests; the Release gate block in `docs/memory-leaks.md` changes in the same commit (the drift test demands it).
- `scripts/docs/gen-diagnostics.sh`, `gen-status.sh`: read the self-hosted compiler's sources or its output. `scripts/release/version.sh`: the `Toolchain.cs` mirror is skipped when the file is absent, so the removal commit needs no script change.
- `scripts/ci/known-failures.py`: reads the new report instead of a `.trx` file.
- New `scripts/ci/golden-commit-check.sh` (R14), `scripts/ci/freeze-check.sh` (R13), `scripts/ci/inventory-check.sh` (R11), `scripts/ci/ddc.sh` (R27).

**Workflows (`.github/workflows/`)**
- `ci.yml`, `release.yml`, `laws-nightly.yml`, `editor-gate.yml`, `mutation.yml`, `pages.yml`: no .NET install; build through `scripts/bootstrap-build.sh`.
- New `ddc.yml`: weekly schedule, and called from `release.yml`.
- `sdk-reminder.yml` and `scripts/ci/sdk-patch-check.sh`: kept for the R27 job's SDK pin.

**Laws (`docs/laws/`)**
- Each of the 31 files gets a new `check:` line or an amendment (R18). The agent drafts; the owner enacts.
- New files for L040–L045.

**Docs**
- `AGENTS.md`, `docs/bayan-contributing.md`, `docs/RELEASING.md`, `docs/memory-leaks.md`, `bootstrap/README.md`, `docs/bayan-milestones.md`, `docs/bayan-roadmap.md`.
- `docs/decisions/<date>-NNN-csharp-archive.md` (the next free number today is 008).

**Removed at 019b, in the one commit**
- `csharp/`, `src/tests/*.cs`, `Bayan.slnx`, the C# sources and project file of `editors/language-server`, and the stale `tests/Bayan.Tests/`. `global.json` and `Directory.Build.props` stay while `tools/` and the Visual Studio extension build with them (OQ5).

## Data / interfaces

### Golden case format

A case is an input and one or more expected files that share its base name, in `tests/cases/<kind>/`. A subdirectory with a `main.byn` is one multi-module case. Measured today:

| Kind | Files | Inputs | Expected | Compared |
|---|---|---|---|---|
| `diag` | 1,312 | 670 `.byn` (22 are subdirectory cases) | 642 `.diag` | diagnostics text |
| `run` | 814 | 347 `.byn` (4 `.test.byn`, 1 subdirectory) | 346 `.stdout`, 59 `.stderr`, 57 `.exitcode`; 4 `.stdin`, 1 `.args` | program output and exit code |
| `parse` | 128 | 64 | `.ast` | tree dump |
| `style` | 66 | 22 groups | `.plain`, `.color`, `.ascii` | rendered diagnostics |
| `lex` | 42 | 21 | `.tokens` | token dump |
| `manifest` | 42 | 21 | `.diag` | manifest diagnostics |
| `typed` | 36 | 18 | `.types` | typed dump |
| `diag-json` | 4 | 2 | `.jsonl` | JSON diagnostics |
| `new` | 3 | | `.tree` | scaffold output |
| `out` | 3 | | 2 `.tree`, 1 `.json` | build output layout |
| `emit` | 1 | | `.sha256` | emitted C digest |
| `quality` | 1 | | `.json` | quality report |

Rules the runner keeps (from `csharp/tests/Bayan.Tests/Golden.cs` and `RunTests.cs`): CR LF is read as LF; `.stdout` is always compared and `.stderr` and `.exitcode` only when present; `// mode: fast|debug` on the first line picks the build mode (default safe); `// os: unix|windows` in the first two lines skips the case elsewhere (23 `run` cases); `.args` is one argument per line; each `run` case gets its own empty working directory; a `.test.byn` case is run with `bayan test -v` and elapsed seconds are masked; `.pending` marks a case expected to fail (none exist today): update mode leaves its files alone, and it fails once its output matches.

A failure line has the shape decision 006 §3 shows: the case name, the input path, then the first differing line as `expected line N` and `actual line N`.

### What the xUnit suite asserts today

215 classes: 1,290 `[Fact]`, 283 `[Theory]`, 1,082 `[InlineData]` rows, 125 `[MemberData]` attributes in 68 files, 31 files with a fixture or collection. The number of tests after theories expand is not measured here (spec 020 says about 13,500); the inventory task measures it per class at the tag.

`csharp/tests/Bayan.Tests` (103 classes, 110 files, 20,467 lines). Families are by file name; the inventory task confirms each class.

| Family | Classes | Facts | Theories | Asserts | Becomes |
|---|---|---|---|---|---|
| Golden folder (`DiagTests`, `RunTests`, `ParserTests`, …) | 11 | 63 | 39 | files in `tests/cases/` | the golden runner reads the same files; the classes go |
| CLI and tools | 25 | 429 | 22 | exit code and text of `bayan` commands, run in process | `cli` golden cases; `tests/parity/` where a case needs set-up |
| C# internals | 29 | 110 | 17 | C# data structures (binder, lowering, ownership tables) | a golden or Bayān test of the same behaviour through the self-hosted compiler, or frozen with reason (OQ4) |
| Law | 15 | 20 | 10 | the properties of L001–L039 | new `check:` commands (R18) |
| Runtime and C | 7 | 41 | 2 | C runtime behaviour, C compile of emitted code | shell runner over `runtime/tests/*.c`; `run` cases |
| Std | 5 | 41 | 3 | library behaviour, some against .NET's own answers | Bayān `test` blocks; tables exported once as `@cases` data |
| Language server | 2 | 42 | 0 | index, bounds, protocol | recorded sessions and Bayān bound tests |
| Infrastructure | 9 | 21 | 5 | the harness itself, build props, generated-file freshness | shell freshness checks; the rest goes with the harness |

`src/tests` (112 classes, 117 files, 54,953 lines):

| Family | Classes | Facts | Theories | Lines | Asserts | Becomes |
|---|---|---|---|---|---|---|
| `SelfhostSemantics*` | 39 | 125 | 44 | 25,787 | sections printed by a generated program built on `src/semantics`, compared with lines computed from the C# compiler | `sem` cases from the export |
| `SelfhostEmitter*` | 20 | 80 | 27 | 9,594 | emitted C equals the C# compiler's (`AssertSame`, `SameAsCli`) | `emit-c` cases; whole-program equality stays in the R27 job |
| `SelfhostParser*` | 16 | 30 | 11 | 3,732 | tree dump equals the C# parser's | `parse` cases |
| `SelfhostLexer*` | 2 | 13 | 1 | 521 | token dump equals the C# lexer's | `lex` cases |
| `SelfhostDriver*` | 11 | 92 | 59 | 5,354 | stage 2 command output equals the C# CLI's; `SelfhostDriverGoldenTests` is L028 | `cli` cases; the cases directory itself for L028 |
| `SelfhostDefault*` | 12 | 155 | 33 | 5,149 | default-compiler behaviour, bounds, generated docs | `cli` cases; Bayān bound tests |
| `SelfhostPath*` | 4 | 9 | 5 | 920 | path functions against tables | `@cases` tables in `lib/std` tests |
| `SelfhostRevision*` | 4 | 2 | 4 | 1,850 | revision examples | `run` and `diag` cases |
| `SelfhostStd*` | 2 | 3 | 1 | 365 | library programs | `run` cases |
| `SelfhostSnapshot*` | 1 | 10 | 0 | 277 | snapshot of emitted output | `emit` cases |
| `SelfhostCoverage*` | 1 | 4 | 0 | 182 | coverage output | `quality` cases |

Harness use in `src/tests`, by file: `SelfhostSemanticsHarness` 78, `SelfhostEmitterHarness` 41, in-process C# CLI 19; 98 of 117 files use at least one.

### Export interface

- Input: a build of the `v0.3.2` tag plus the export branch; `BAYAN_EXPORT_DIR=<dir>`.
- Output: one case per assertion that compares with the C# compiler, named `<kind>/<Class>/<test>[-<row>]`, holding the generated input and the C# output as the expected file.
- A second pass runs the exported cases with the self-hosted compiler through the golden runner. The pass list, the fail list and the divergence list are the export report.

### Tracked tables

- `tests/inventory-019.tsv`: class, file, family, tests at the tag, disposition, target (kind or path), reason.
- `tests/cases/FREEZE.tsv`: tag, commit, export branch head, then kind, case count, and one digest per expected file.
- `tests/cases/DIVERGENCES.tsv`: case, question number, which compiler was right, one-line reason.

### Language server sessions

A session is a directory: a workspace tree, `in.jsonl` (client messages in order) and `out.jsonl` (server messages). Paths are made relative before comparing. The 42 existing tests give the first sessions: 20 facts in `LanguageServerWorkspaceTests` and the protocol parts of the 22 in `LanguageServerLeakTests`; the bound parts become Bayān tests that build a large tree and measure.

## Risks & mitigations

| Risk | Mitigation |
|---|---|
| The suite is slower as processes than in one .NET process: about 15,000 cases at 100 ms is 25 minutes in sequence (decision 006 §1). | `--jobs` is in the first step. `sem` cases keep the harness shape: one built program prints many sections, so the build cost is paid per program, not per assertion. R17 measures; above 45 minutes the work stops for the owner. |
| The export misses an assertion, and it is lost when the C# compiler goes. | The inventory counts tests per class at the tag and the check compares that count with the exported cases. The coverage ratchet catches lost reach. The frozen-files law reruns the C# compiler on every exported input in the R27 job. |
| Exported cases fail under the self-hosted compiler. | Expected for listed divergences only. Any other failure is fixed, or listed with a question number, before the freeze is declared. |
| An in-process C# test has no process-level form (it asserts on an object). | Disposition "frozen with reason" exists; OQ4 forbids dropping without a covering case. |
| Standard input cannot be read message by message from Bayān today (OQ8). | The language server tasks start with that decision. OQ8 is decided (2026-11-17): `Io.stdin.read(into:)` as the first piece of the Q1141 stream API, signature pending the owner's approval (spec, OQ8). The rest of 019a does not depend on it, and 019a lands without the server (placement C). Each new keyword is added to both servers during the gap. |
| Windows: process start is slow and 23 `run` cases are OS-specific. | The known-failures check is ported with the runner (R19); time is measured per OS. |
| A stale `bootstrap/bayan.c` builds an old compiler in CI. | R26 runs in every CI job before the suite. |
| The removal breaks a script nobody listed. | 019b's entry condition requires CI, the nightly and a release dry run to be green with no .NET first; a grep for `dotnet` and `csharp/` outside the allowed files is a task. |
| Law checks change without the owner noticing. | Amendments are drafted as separate files; only the owner sets `status:`. |
| Coverage figures are missing for 28 of 111 files (decision 006 §4). | The whole-suite baseline is taken before any class is dropped (R16). |

## Coverage check

| Requirement | Step | Tasks |
|---|---|---|
| R1 | 1 | T1, T2, T3 |
| R2 | 1 | T2, T4 |
| R3 | 1 | T4 |
| R4 | 1 | T5 |
| R5 | 1 | T6 |
| R6 | 1 | T2, T3 |
| R7 | 1 | T7 |
| R8 | 1 | T8 |
| R9 | 1 | T9a, T9b |
| R10 | 2 | T12–T17 |
| R11 | 2 | T11, T18 |
| R12 | 2 | T19 |
| R13 | 2 | T20 |
| R14 | 2 | T21 |
| R15 | 3, 5 | T23–T28, T41 |
| R16 | 3 | T22, T29 |
| R17 | 3 | T30 |
| R18 | 3 | T31, T32 |
| R19 | 5 | T42 |
| R20 | 4 | T33–T37 |
| R21 | 4 | T34, T37 |
| R22 | 4 | T38a, T38b |
| R23 | 4 | T39 |
| R24 | 5 | T40, T41, T43, T44a, T44b |
| R25 | 5 | T43 |
| R26 | 5 | T45 |
| R27 | 5 | T46 |
| R28 | 5 | T47, T48a–T48d, T49, T50 |
| R29 | 5 | T51 |
| R30 | 6 | T64 |
| R31 | 6 | T65 |
| R32 | 6 | T66 |
| R33 | 6 | T67 |
| R34 | 6 | T68 |
| R35 | 6 | T69a–T69c, T70 |
