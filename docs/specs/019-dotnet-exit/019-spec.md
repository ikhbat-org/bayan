# 019 — The .NET exit: goldens, a Bayān language server, CI from the bootstrap, and the C# archive
Status: approved as amended through 2026-11-18 (owner, 2026-11-18)
Release: unscheduled
Sources: docs/bayan-milestones.md (Target: zero dependencies; user 2026-11-13); docs/decisions/2026-11-16-006-after-022-roadmap-decisions.md (§1 order, §2 freeze E1–E3, §3 option (c), §4 ratchet, C# archive plan; user 2026-11-16); docs/decisions/2026-11-16-007-additional-concepts-review.md (Q9, syntax freeze until 019a); docs/bayan-roadmap.md (row 3)
Created: 2026-11-17

## Problem
Building, testing and shipping Bayān needs the .NET 10 SDK today, although the compiler people download has been the self-hosted one since 0.3.0. Measured on `dev` at 06eab86f (the 0.3.2 release merge):

- **CI and releases start from C#.** `.github/workflows/ci.yml` runs `dotnet test Bayan.slnx` and `dotnet publish csharp/Bayan.Cli`; `release.yml` publishes the C# compiler, uses it to build stage 1, and stage 1 builds the shipped stage 2. `laws-nightly.yml`, `editor-gate.yml`, `scripts/release/memory-gate.sh` and `scripts/pinned-bayan.sh` all call `dotnet`. 46 files under `scripts/` and `.github/` name `dotnet`.
- **The whole suite is one xUnit assembly.** `csharp/tests/Bayan.Tests` holds 103 test classes (767 `[Fact]`, 98 `[Theory]`) and compiles in `src/tests/` with 112 more (523 `[Fact]`, 185 `[Theory]`). 68 files use `[MemberData]` and 31 use a fixture or collection. Spec 020 puts the expanded suite at about 13,500 tests.
- **Most expected output is not a file.** `tests/cases/` has 12 kinds and 2,452 files, but of the 117 files in `src/tests`, 78 use `SelfhostSemanticsHarness`, 41 use `SelfhostEmitterHarness` and 19 call the C# CLI in process (98 files use at least one): they compute their expected lines from the C# compiler while the test runs. Remove the C# compiler and those expectations no longer exist anywhere.
- **Every law is checked through .NET.** All 31 law files in `docs/laws/` have a `check:` line that starts `dotnet test`; 18 name `csharp/` in their `scope:`.
- **The language server is C#.** `editors/language-server` is 2,299 lines of C# (`bayan-lsp`, NativeAOT), with 42 tests in two classes that are part of the release gate (`docs/memory-leaks.md`).
- **Docs generators read C# sources.** `scripts/docs/gen-diagnostics.sh` reads `DiagnosticCodes.cs`, `gen-status.sh` reads `Keywords.cs`, `TokenKind.cs` and `BuiltinMembers.cs`, and `scripts/release/version.sh` mirrors the version into `Toolchain.cs`.

While the C# compiler is the oracle, every language change is built twice. The owner fixed the order on 2026-11-16: 019, then the catch-up (023), then the test-result cache (020). 019 mixes a reversible job (make the suite run with no .NET) and an irreversible one (remove the C# compiler), so it is split: **019a** and **019b**.

## Goals
- **019a.** The suite, CI and the release build run on a machine with no .NET SDK; so does the editor gate once the Bayān server passes (placement C, below). Expected outputs that came from the C# compiler are files, frozen at the `v0.3.2` tag. `bayan test` runs the golden cases itself. The compiler is built from `bootstrap/bayan.c` with a C compiler.
- **019b.** The C# compiler leaves `dev` in one commit, after a tag and a decision doc that make it easy to find, read and restore. A frozen copy stays buildable for diverse double-compiling.
- No test is lost without a written reason, and no coverage figure drops.
- `bayan-lsp` is a Bayān program before 019b starts (R30). The port is part of 019a's work but not of its landing condition: 019a can land while the C# server is still the one editors run (decided 2026-11-17, owner, Fable's recommendation: placement C).
- The catch-up (023) and sabk (024) can start the day 019a lands; the syntax freeze ends then.

## Non-goals
- Reaching 100% coverage. 019 holds a ratchet; the climb is its own track (decision 006 §4, E3).
- Porting the Visual Studio extension (`editors/visualstudio`); it stays .NET (user 2026-11-13). The VS Code extension keeps running on the editor's Node host.
- Removing zig, Python, bash or PowerShell (`docs/bayan-milestones.md`, the other rows of the dependency table; spec 015).
- Building the test-result cache (spec 020) or any slice of it, unless requirement R17's stop condition is met and the owner says so.
- Building any catch-up feature (spec 023), or changing the language. The golden runner is a command-line feature; `@cases` with a constant list is already in the spec (§20).
- New language server features. The port answers the same requests as the C# server.
- Fault injection in the C runtime (decision 006 §4): part of the coverage track.

## User stories
- As a contributor on a fresh machine, I want to build and test Bayān with a C compiler and nothing else from .NET, so that setup is one command.
- As the owner, I want every expected output that came from the C# compiler stored as a file from one named tag, so that removing the compiler loses no evidence.
- As a reviewer, I want one line per golden case with the first differing line, so that a failing run shows every failure, not the first.
- As anyone adding a case, I want to drop a file under `tests/cases/<kind>/` and have it run, with no test source to edit.
- As an editor user, I want `bayan-lsp` to behave as before and stay within its memory bounds.
- As the owner, I want the C# compiler one command away after it is removed, and a regular check that it and the bootstrap still agree.

## Requirements

### 019a: the golden runner (built first)
- **R1 Cases are tests.** Given a cases directory, `bayan test` treats every case under `<dir>/<kind>/` as one test, with no test source. Every kind present at the freeze is covered: `diag`, `diag-json`, `emit`, `lex`, `manifest`, `new`, `out`, `parse`, `quality`, `run`, `style`, `typed`, and any kind R10 adds. A case with no process-level form (no driver command produces it) is reported skipped, naming the Bayān test block that compares its frozen expected files; that block must exist and run (the list of such cases has one home, checked by T10). `BAYAN_UPDATE=1` does not rewrite those files.
- **R2 One result per case.** Each case reports its own result under the name `<kind>/<case>`: passed, failed, skipped or timed out. A failure names the input path and shows the first differing line, expected and actual. A failing case never stops the cases after it.
- **R3 Selection and time limit.** `--only` selects cases by name. Every case has a time limit; a case over it is reported as timed out and the run continues.
- **R4 Parallel, same report.** `--jobs N` runs up to N cases at once. For any N the set of results, their order in the report and the exit code are the same.
- **R5 Update only when asked.** With `BAYAN_UPDATE=1` the runner rewrites expected files that differ and reports each one. Without it, a run writes no file under the cases directory. A `.pending` case keeps its expected files in both modes and fails once its output matches.
- **R6 Existing conventions hold.** The case conventions of the xUnit harness at the freeze keep their meaning: the `// mode:` and `// os:` header lines, `.args`, `.stdin`, `.stdout`, the optional `.stderr` and `.exitcode`, `.test.byn` cases run as tests, a subdirectory as one multi-module case entered at `main.byn`, `.pending`, and CR LF read as LF.
- **R7 Table tests.** `@cases` with a constant list (spec §20) works in `bayan test`: one reported test per row, selectable with `--only`. A non-constant value is a diagnostic.
- **R8 One report.** Golden cases appear in the text summary, in `--json` output and in the exit code under the same rules as `test` blocks, and the summary states how many of each ran.
- **R9 Bounded.** The runner keeps a head and a tail of each child's output, bounds its directory walk, and removes its scratch directories (`docs/memory-leaks.md` rules 1, 4 and 7). A memory-bound test for a run over the full cases tree is part of the release gate.

### 019a: the freeze
- **R10 Every C#-computed expectation becomes a file.** Each expected value that a test at the `v0.3.2` tag computes from the C# compiler while it runs is stored in the repo as an expected file beside its input, written by the C# compiler at that tag. None is typed by hand.
- **R11 Inventory with a disposition per class.** A tracked inventory lists every test class of the suite at the `v0.3.2` tag with its number of tests and one disposition: golden cases, Bayān tests, shell test, proven only by the frozen compiler (R27), no counterpart, or dropped with a reason. A class with no row, or a dropped class with no reason, fails a check. For the 27 classes that test C# internals, "proven only by the frozen compiler" is not allowed: each row is a golden or Bayān test, or "no counterpart" with the owner's approval of that row (OQ4).
- **R12 Known divergences are recorded.** Wherever the two compilers differ on purpose at the tag, the frozen expected file holds the output decided to be right, and a tracked list names the case, the question number and which compiler was right (decision 006 §2, condition 3).
- **R13 Freeze manifest.** A tracked manifest records the tag, its commit, the number of cases per kind and a digest of every frozen expected file. A check fails when a frozen file differs from its digest without a matching manifest change.
- **R14 Golden-update commits.** A commit that changes an expected file contains only expected files and the manifest, and its message names the commit or change that caused the new output. A check refuses a commit range that breaks this rule (decision 006 §2).

### 019a: the suite without .NET
- **R15 No .NET to test.** The full suite (golden cases, Bayān tests, script tests, the runtime's C tests) passes on a machine with no .NET SDK, on Linux x64, macOS arm64 and Windows x64.
- **R16 Coverage ratchet.** Measured through the new suite, no file under `src/` is below its line or branch figure in `tests/quality-baseline.json`. Files with no figure today get one from a whole-suite run before any C# test is dropped, and the ratchet then covers them.
- **R17 Suite time is measured.** The wall time of the full suite with `--jobs` on the reference host is measured and recorded. Above 45 minutes, work stops and the number goes to the owner (decision 006 §1).
- **R18 No law loses its proof silently.** Every enacted law has either a check command that runs with no .NET, or a written amendment saying it is proven only by the frozen compiler (R27), or a retirement, each enacted by the owner. The laws gate and the nightly full tier run with no .NET.
- **R19 Windows known failures.** The Windows job's known-failures check reads the new suite's report and still fails on an unlisted failure and on a listed test that passes.

### 019a: the language server (placement C, decided 2026-11-17)
The port is built during 019a, but 019a lands without it (R24, R29). Until the Bayān server passes R21 and R22, the C# server stays the shipped one and each new keyword is added to both servers. R30 holds 019b until the port has passed.

- **R20 Same server, in Bayān.** `bayan-lsp` is built by `bayan` from Bayān source. It answers the requests the C# server answers at the freeze: `initialize`, `shutdown`, `exit`, `textDocument/didOpen`, `didChange`, `didClose`, `completion`, `definition`, `documentSymbol`, `hover`, `signatureHelp`, `workspace/symbol`, `workspace/didChangeWatchedFiles`, and it publishes `textDocument/publishDiagnostics`.
- **R21 Same answers.** For every recorded session (the messages a client sends and the messages the C# server at the tag sends back), the Bayān server sends back the same messages.
- **R22 Same bounds.** The Bayān server keeps the limits listed for `bayan-lsp` in `docs/memory-leaks.md`: the skipped directories, the file, character and per-file budgets, the open-buffer cap, the diagnostics cap, the message size limit and the depth caps. Each limit has a test, and those tests are the editor gate and part of the release gate.
- **R23 Editors unchanged.** The VS Code extension and the Visual Studio extension start the server as today (`bayan-lsp` on `PATH`, `bayan.server.path`, `BAYAN_LSP`), with no change to either extension's source.

### 019a: builds and tooling
- **R24 CI from the bootstrap.** `ci.yml`, `release.yml`, `laws-nightly.yml`, `editor-gate.yml`, `mutation.yml`, `pages.yml` and the memory gate install no .NET SDK, except that `editor-gate.yml` and the server part of the memory gate may install it until the Bayān `bayan-lsp` passes R21 and R22. Each builds the compiler from `bootstrap/bayan.c` with a C compiler, and that compiler builds the one under test from `src/`.
- **R25 The release is unchanged in kind.** The released `bayan` is still a stage built from `src/` by a compiler built from `src/`, for the same six targets, and `bayan --version` prints `bayan X.Y.Z (selfhost)`.
- **R26 Bootstrap freshness.** A check with no .NET fails when `bootstrap/bayan.c` differs from the C the compiler emits for `src/driver`, or when `bootstrap/bayan-rt.c` or `bayan-rt.h` differs from `runtime/`. Regenerating them needs no .NET.
- **R27 Diverse double-compiling.** A job, weekly and before each release, builds the frozen C# compiler from its tag, builds the self-hosted compiler from the frozen tree with it, and fails unless the C it emits for that tree's `src/driver` equals that tree's `bootstrap/bayan.c`. The job also runs the laws amended under R18 to rest on the frozen compiler. This job is the only place .NET is installed.
- **R28 Tooling reads what remains.** The pinned `bayan` (`scripts/pinned-bayan.sh`), `scripts/selfhost/land.sh`, `scripts/dist.sh`, the docs generators (`gen-diagnostics.sh`, `gen-status.sh`) and the version mirrors (`scripts/release/version.sh`) work from files that exist after 019b, and `scripts/docs/check.sh` passes.
- **R29 The syntax freeze ends with 019a.** When 019a lands, the roadmap and the spec header say the freeze of revision 0023 is over, and name the commit.
- **R36 Bootstrap chain.** A check with no .NET fails unless the bootstrap of the previous commit builds the new `src/` and emits the new `bootstrap/bayan.c`. `src/` itself is not limited to what the frozen C# compiler accepts (OQ3).
- **R37 `bayan-lsp` in the archives.** From the first release after the Bayān `bayan-lsp` passes R21 and R22, each of the six release archives holds `bayan-lsp` beside `bayan`, built by that release's own `bayan`. The C# server is never shipped (OQ7).

### 019b: the archive
- **R30 Entry condition.** 019b starts only after 019a has landed on `dev`, R20–R23 are met (the Bayān `bayan-lsp` replays every recorded session, keeps the bounds and starts from both editors), and CI, the laws nightly and one release dry run have passed there with no .NET.
- **R31 The tag.** An annotated tag `csharp-final` sits on the 019a merge commit on `dev`, after one local `dotnet test` and one manual ddc run pass on it (owner 2026-11-18). Its message names the commit where 019b starts. The owner pushes it.
- **R32 The decision doc.** `docs/decisions/<date>-NNN-csharp-archive.md` names the tag, its commit, what it holds (`csharp/`, the xUnit suite, the .NET CI jobs) and the commands to read, check out and restore it.
- **R33 One removal commit.** The removal is one commit, `chore(019b): remove the C# compiler`, with no other change. After it, no tracked file is left under `csharp/`, no `.cs` file under `src/tests/`, none of the C# language server sources, and neither `tools/Bayan.SyntaxFuzz` nor `tools/Bayan.UnicodeGen` (OQ5).
- **R34 Still green, still restorable.** After the removal commit the suite, `scripts/docs/check.sh`, the laws gate and a release dry run pass, and the R27 job, started from `csharp-final`, passes.
- **R35 Docs say what is true.** `AGENTS.md`, `docs/bayan-contributing.md`, `docs/RELEASING.md`, `docs/memory-leaks.md`, `bootstrap/README.md`, the dependency table in `docs/bayan-milestones.md` and the roadmap describe the stack, the test command and the release steps as they are after the removal.

## Acceptance criteria
- Given a checkout on a Linux, macOS or Windows machine with a C compiler, zig and no .NET SDK, when the documented build and test commands run, then the compiler is built from `bootstrap/bayan.c` and the full suite passes (R15, R24).
- Given `tests/cases/` with one `run` case whose `.stdout` has a wrong fourth line, when `bayan test` runs over it with `--jobs 8`, then every other case passes, that case fails with its path and the expected and actual fourth line, the exit code is non-zero, and no file under `tests/cases/` changed (R2, R4, R5).
- Given the same tree, when the run is repeated with `--jobs 1`, then the report is the same (R4).
- Given a case that never exits, when the suite runs, then that case is reported as timed out and the cases after it still report (R3).
- Given the inventory, when its check runs, then all 224 test classes counted at the tag have a row (classes added after the tag, such as SelfhostDriverGoldenListTests, get rows too; Decision 2026-11-18, owner), and the tests of every class not marked dropped are found in the new suite (R11).
- Given a frozen expected file edited by hand, when the manifest check runs, then it fails and names the file (R13). Given a commit that changes an expected file and a `.byn` source under `src/`, when the commit check runs, then it refuses the range (R14).
- Given a whole-suite coverage run before and after the C# tests are dropped, then no file under `src/` has a lower figure (R16).
- Given a recorded editor session against the C# server, when it is replayed against the Bayān `bayan-lsp`, then the replies are the same; and given a root with more files than the budget, then the server stops indexing, logs one line and stays under its memory bound (R21, R22).
- Given a `v*` tag pushed after 019a, when `release.yml` runs, then no step installs .NET, the six archives are built, and `bayan --version` in each prints `(selfhost)` (R24, R25). The editor gate and the server part of the memory gate are the only jobs that may still install .NET, and only until the Bayān server passes.
- Given a change under `src/` without a regenerated bootstrap, when CI runs, then the bootstrap check fails (R26).
- Given `dev` after 019b, when `git log -- csharp/` is read, then its newest commit is `chore(019b): remove the C# compiler`; `git show csharp-final:csharp/Bayan.Cli/Program.cs` prints the file; and the weekly job builds the C# compiler from the tag and reproduces that tree's `bootstrap/bayan.c` (R31, R33, R34).

## Law candidates
- **Every case is reported once.** For every cases directory, selection and `--jobs` value, the runner reports one result for each selected case and none for any other. Kind: invariant (R1, R2, R3).
- **Job count does not change the result.** For every cases directory and every N and M, the report with `--jobs N` equals the report with `--jobs M`, elapsed times masked. Kind: property (R4).
- **A run without update writes nothing.** For every run without `BAYAN_UPDATE`, the cases directory is byte for byte the same afterwards. Kind: guard (R5).
- **Frozen files come from the frozen compiler.** For every expected file in the freeze manifest, the C# compiler built from `csharp-final` produces the same bytes for its input, except the cases in the divergence list. Kind: property (R10, R12, R13, R27).
- **Language server equivalence.** For every recorded session, the Bayān server's replies equal the recorded replies of the C# server at the freeze. Kind: property (R21).
- **Two bootstraps agree.** For the frozen tree, the self-hosted compiler built by the C# compiler and the one built from `bootstrap/bayan.c` emit the same C for `src/driver`. Kind: property (R27). This restates L027 (bootstrap fixpoint) without a live C# compiler and may be enacted as its amendment.

## Open questions
Each had the most conservative option as its default. Decision 008 D7 (2026-11-17) took the defaults for OQ3, OQ4, OQ5, OQ7, OQ9 and OQ10, and OQ1 followed the re-tag in D6. Every question below is now resolved, and the resolution replaces the default.

- **OQ1 The `v0.3.2` tag.** The tag did not resolve in the checkout this text was written in (2026-11-17); `dev` was at the release merge 06eab86f. *Default:* the freeze export waits for the owner's tag and takes its commit from it; no other commit is used. *Update 2026-11-17:* the tag resolves to 984aa479; the freeze export takes that commit.
- **OQ2 Freeze conditions.** Decision 006 §2 sets three conditions for freezing at 0.3.2: revision 0024 in or explicitly out, the wording questions (Q1272, Q1186–Q1189) landed, and divergences listed. At the tag, revision 0024 is out, and the Q1272 rewording is in neither compiler (BYN2321 still reads "violates `requires`" where the clause is `expects`). *Resolved:* Freeze at `v0.3.2` as it is: revision 0024, Q1272 and Q1186 are out at the tag and land after 019a, in the self-hosted compiler only, with hand-reviewed goldens. (owner, 2026-11-17, Fable's recommendation).
  - Q1187 to Q1189 keep the code and fix only the text, so they change no output. Each landing is a golden-update commit (R14). T12 reports the result and no longer stops on it.
- **OQ3 Does `src/` stay compilable by the frozen C# compiler?** After the catch-up, `src/` will use features the C# compiler lacks. *Resolved:* no such limit on `src/`; the R27 job checks the frozen tree only, and later trees are tied to it by R26 and the chain check R36 (the previous commit's bootstrap must build the new `src/` and emit the new `bootstrap/bayan.c`) (owner, 2026-11-17, Fable's recommendation).
  - A feature is usable in `src/` from the landing after the one that teaches the compiler that feature.
- **OQ4 Classes that test C# internals.** 27 classes (110 facts, 17 theories; the inventory's csharp-internals rows, first counted as 29) assert on C# data structures with no command-line output, for example `DiagnosticRendererTests` and `LoweringInvariantTests`. *Resolved:* Each class is ported to a golden or Bayān test, or dropped with a named covering case, or marked "no counterpart" (a C#-only construct) with the owner's approval of that row. (owner, 2026-11-17, Fable's recommendation).
  - "Proven only by the frozen compiler" is not allowed for this family, because the ratchet (R16) cannot see these tests. If more than about a third of the rows are "no counterpart", they are reviewed with the owner as one batch.
- **OQ5 Other .NET projects.** `tools/Bayan.SyntaxFuzz` and `tools/Bayan.UnicodeGen` are C# and compile files under `csharp/`, so neither builds after the removal. *Resolved:* Both tools are removed in the 019b removal commit (R33); `Bayan.UnicodeGen` stays runnable from `csharp-final` and a Bayān port is filed for the next Unicode bump. (owner, 2026-11-17, Fable's recommendation).
  - `SyntaxFuzzTests` gets the inventory row "dropped: fuzzes the C# lexer and parser; L002 and L018 cover the self-hosted ones", after the reason is checked against both laws. `global.json` and `Directory.Build.props` stay only while the Visual Studio extension needs them.
- **OQ6 Where the R27 job runs.** Hosted runners or the owner's machines. *Default:* a scheduled workflow on a hosted Linux runner plus a `needs:` entry in `release.yml`, the same shape as `laws-nightly.yml`. *Decided 2026-11-17 (owner, Fable's recommendation):* option A, the default. A red R27 run on release day most often means the job's surroundings changed (SDK download, runner image), so `docs/RELEASING.md` says to fix the environment and re-run. Revisit if environment failures block two releases (then advisory plus a green last weekly run) or if the job exceeds about 30 minutes on hosted runners.
- **OQ7 `bayan-lsp` in release archives.** 0.3.0 lists "archives do not include `bayan-lsp`" as a known limit. *Resolved:* `bayan-lsp` ships in all six archives from the first release after the Bayān server passes R21 and R22 (R37), and the C# server is never shipped (owner, 2026-11-17, Fable's recommendation).
  - Nothing changes before that. The release notes name any target the editor gate does not run on.
- **OQ8 Message bytes for the server.** The server needs to read a message of a known byte length from standard input and keep running; the runtime today offers `Io.stdin.readAll` and `readAllBytes`, which read to the end. *Default:* a runtime read of a bounded number of bytes is added as a library member with no syntax change, under the Q1141 decision if the owner wants one design for both; if the owner prefers to wait for Q1141, the language server tasks move after it and 019a's other parts land first. *Decided 2026-11-17 (owner, Fable's recommendation):* option C. `Io.stdin.read(into:)` is the first piece of the Q1141 stream API, not a server-only helper.
  - **Shape (owner to approve).** One member that fills a buffer the caller owns and returns how many bytes arrived. It returns 0 only when the pipe is closed. It blocks until at least one byte is available, and it may return fewer bytes than the buffer holds, so the loop that waits for a whole message (header, then `Content-Length` bytes) lives in the server, together with R22's size limit. It fails with `IoError`. The exact signature, the buffer type and the error set are not checked against the grammar; the owner approves them as the first piece of the Q1141 design before T33 starts.
  - **To check before T33.** That `Io.stdout.write` pushes each reply out at once (if it buffers, the editor hangs), and that Windows reads standard input as raw bytes.
  - **If the owner will not approve a public member now,** the only other option is B (wait for the Q1141 design), and placement C absorbs the wait. No runtime code is written by this decision.
- **OQ9 Law numbers.** `docs/laws/` ends at 039 and spec 020 reserves L032–L037. *Resolved:* 019 takes L040–L045, and both reservations are recorded in `docs/laws/README.md` when the first of these laws is written. If "two bootstraps agree" is enacted as an amendment of L027, L045 stays unused. (owner, 2026-11-17, Fable's recommendation)
- **OQ10 Estimate.** The 2026-11-13 estimate is 4–7 weeks for both parts. The count found 215 classes, and 98 of the 117 files in `src/tests` use a harness that compares with the C# compiler. *Resolved:* keep 4–7 weeks until the inventory task (T11) is done. The T11 report then replaces it with three figures: 019a without the language server, the server port, and 019b. (owner, 2026-11-17, Fable's recommendation)
