# Law checks drafted but not live (spec 019 T31, R18)

Status: draft (T31 part 1, 2026-11-18; part 2 drafts, 2026-11-19)
Release: unscheduled
Sources: docs/specs/019-dotnet-exit/019-tasks.md (T31, T31b); docs/laws/*.md

Decision 2026-11-18 (owner): a live `check:` line is swapped only when the new command runs at least one existing case that covers the statement. These laws keep their old `check:` until the target lands. `bayan test --only X` exits 2 when X matches nothing (verified), so a drafted selector cannot pass vacuously. G = `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases`.

| law | drafted check | waits on |
|---|---|---|
| L002 | `G --only 'lex/'` | T17c: no no-panic fuzz is ported; lex/ cases do not cover it |
| L006 | `G --only '/l006-'` | swapped 2026-11-19 (T31b share C): the 69 exported `l006-` cases of tests/cases/cli/L006OwnershipGuardTests; proof src/driver/goldenexport.byn |
| L007 | `G --only '/l007-'` | swapped 2026-11-19 (T31b share C): the 24 exported `l007-` cases of tests/cases/cli/L007UntrustedSinkTests; proof src/driver/goldenexport.byn |
| L008 | `G --only '/l008-'` | swapped 2026-11-19 (T31b share C): the 24 exported `l008-` cases of tests/cases/cli/L008OwnershipRuntimeTests; proof src/driver/goldenexport.byn |
| L013 | `G --only '/l013-'` | swapped 2026-11-19 (T31b share C): the 96 exported `l013-` cases of tests/cases/cli/L013DirectAndIndirectCallsAgreeTests; proof src/driver/goldenexport.byn |
| L018 | `G --only 'parse/'` | T17c: no no-panic fuzz is ported; parse/ cases do not cover it |
| L019 | `G --only '/l019-'` | swapped 2026-11-19 (T31b share B): the check is the `L019:` block of src/driver/l019.test.byn, not `l019-` cases; see the Part 2 row |
| L020 | `G --only '/l020-'` | swapped 2026-11-19 (T31b share B): the check is `G --only 'emit/'` (emit/run-c.sha256), not `l020-` cases; see the Part 2 row |
| L021 | `G --only '/l021-'` | swapped 2026-11-19 (T31b share B): the check is the 8 not-emitted rows of src/driver/mutate.test.byn, not `l021-` cases; see the Part 2 row |
| L022 | `G --only 'sem/'` | T17c: no sem/ kind yet |
| L023 | `G --only 'sem/'` | T17c: no sem/ kind yet |
| L024 | `G --only 'emit/'` | T17c: emit/ holds one case, not the emitter equivalence |
| L025 | `G --only 'emit/'` | T17c: emit/ holds one case, not the emitter equivalence |
| L027 | `bash scripts/ci/bootstrap-check.sh` | covered by T31 (landed 2026-11-19), which added L027 to scripts/ci/ddc-laws.txt and wrote scripts/ci/fixpoint-check.sh |
| L038 | `G --only '/l038-'` | a port of the law's generator or table as golden cases named lNNN-* (no task owns it yet; placeholder selector) |
| L039 | `G --only 'cli/format'` | T17c: cli/ cases for format |

The table above is the part 1 snapshot (2026-11-18); "Part 2 swap table" below says what each swap waits on as of 2026-11-19.

## Statement amendments for the owner

Part 1 notes, superseded by "Statement amendments for one enactment turn" below.

- L001, L017, L022, L024: name the C# lexer, parser, binder or emitter as the oracle; after 019b the oracle is the frozen expected files.
- L026, L039: name .NET's Path.* and the C# CLI as the oracle; same amendment.
- L028: names `CliApp.Run` as the oracle; after 019b the oracle is the frozen expected files, with the same time masks. Drafted in docs/laws/028-driver-equivalence.md.
- L005: names C# behaviour in its proof notes; after 019b the oracle is the T24b fixtures.
- L027: the Statement says "becomes a no-.NET check once T31 lands"; the frozen-tree half needs L027 in scripts/ci/ddc-laws.txt.

## Statement amendments for one enactment turn

Drafted 2026-11-19 (T31 part 2, share 019-t31d) from the owner-approved template on the T31 line (owner 2026-11-18): "For every <kind> case in the freeze manifest, <tool> prints the frozen expected output byte for byte (L028: with the same time masks). The frozen files are the C# compiler's output at the freeze (L043)." The owner enacts each by replacing the law's `## Statement` with the drafted text. The freeze manifest is tests/cases/FREEZE.tsv, which T20 writes (not in the tree yet).

Each <tool> below is what the paired check runs, not what the current Statement names. Where it differs from the "## Proposed statement" a law file already holds (019-t31-template, b836918a3), the entry says so. The kept and dropped clauses those sections list still apply.

`--only X` selects the cases whose `<kind>/<case>` name contains X (src/driver/golden.byn:708, :728). A `lex/*.byn` or `parse/*.byn` case is produced inside `bayan test` (golden.byn:428-433); an exported `lex/<Class>/<case>` or `parse/<Class>/<case>` directory runs a built program (src/driver/goldenprograms.byn:33-35).

### L001 (docs/laws/001-lexer-equivalence.md)

- Current statement (:16): "For every byte sequence (including invalid UTF-8, unbalanced interpolation, non-NFC identifiers and bidi controls), `bayan-lex` and the C# lexer produce identical structured token dumps (`--json`: kinds, spans, values, diagnostics with codes, spans and fixes). Both lexers read Unicode data from the same generated tables in the repository; neither consults the system's ICU."
- Drafted: "For every lex case in the freeze manifest, the self-hosted lexer (`bayan-lex`, or `bayan test`'s lex dump for a `lex/*.byn` case) prints the frozen expected output byte for byte. The frozen files are the C# compiler's output at the freeze (L043)."
- kind `lex`, tool: the live check (:10) runs `--only 'lex/'`; `lex/*.byn` goes through `goldenLex`, `lexer.dumpFile` (golden.byn:265-270, :430-431); the exported classes run `bayan-lex` (goldenprograms.byn:1420).
- Pairs with the live check, unchanged: `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'lex/'`
- Differs from the law file's draft (:20), which names `bayan-lex` alone; the 21 `lex/*.byn` cases do not run it.

### L017 (docs/laws/017-parser-equivalence.md)

- Current statement (:16): "For every byte sequence, `bayan-parse` and the C# parser produce the same tree dump and the same diagnostics, and exit with the same code."
- Drafted: "For every parse case in the freeze manifest, the self-hosted parser (`bayan-parse`, or `bayan test`'s tree dump for a `parse/*.byn` case) prints the frozen expected output byte for byte. The frozen files are the C# compiler's output at the freeze (L043)."
- kind `parse`, tool: the live check (:11) runs `--only 'parse/'`; `parse/*.byn` goes through `goldenParse` (golden.byn:273-282, :432-433); the exported classes run `bayan-parse` (goldenprograms.byn:1277).
- Pairs with the live check, unchanged: `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'parse/'`
- Differs from the law file's draft (:20) the same way as L001.

### L022 (docs/laws/022-binder-equivalence.md)

- Current statement (:16): "For every program that parses without errors, `bayan-check --types` and `bayan types` print the same typed dump, and `bayan-check` and `bayan check` report the same diagnostics and exit with the same code."
- Drafted: "For every typed, diag and sem case in the freeze manifest, the self-hosted checker (`bayan-check` for a sem case, `bayan test`'s typed dump or rendered diagnostics for a typed or diag case) prints the frozen expected output byte for byte. The frozen files are the C# compiler's output at the freeze (L043)."
- kind `typed`, `diag`, `sem`, tool: the live check (:10) is `dotnet test --filter "Law=L022"`, whose corpus is the diag cases that parse clean and the typed cases (src/tests/SelfhostSemanticsEquivalenceLawTests.cs:11-16, :34, :38, :59), run through `bayan-check` (:128, :170). The drafted check runs those same cases through `goldenTyped` and `goldenDiag` (golden.byn:292, :339, :434-437) and the sem rows through `bayan-check` (goldenprograms.byn:843, :888).
- Pairs with the drafted check: `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'typed/' --only 'diag/' --only 'sem/'`
- Differs from the law file's draft (:20), which names typed and diag with `bayan-check`; the golden runner does not run `bayan-check` on those, and the part 1 drafted line (`--only 'sem/'` alone) does not run the typed and diag cases that are the live corpus. `diag/` does not match `diag-json/`.

### L024 (docs/laws/024-emitter-equivalence.md)

- Current statement (:17-21): "For every program `bayan check` accepts and every `BuildMode` (`debug`, `safe`, `fast` today), the C that `bayan-emit` prints is byte for byte the C that the C# backend prints for the same input and mode (`bayan build --emit-c`; for `*.test.byn`, the C the test run builds). The corpus is every `tests/cases/run/` input in the mode its `// mode:` line names, among them `run/hello.byn` (byte-identical to `examples/hello/main.byn`, which `CliTests` passes to `--emit-c`), and the 010 generator's well-typed programs on the fixed seeds, each in every `BuildMode`."
- Drafted: "For every emit case in the freeze manifest, the self-hosted emitter, as `bayan test` runs it, prints for each `tests/cases/run/` input, in the mode its `// mode:` line names, C whose SHA-256 is the frozen hash in `tests/cases/emit/run-c.sha256`. The frozen files are the C# compiler's output at the freeze (L043)."
- kind `emit`, tool: the live check (:10) is `dotnet test --filter "Law=L024"`, which runs `bayan-emit --many` on the run/ inputs and compares with `CliApp.EmitC` (src/tests/SelfhostEmitterEquivalenceLawTests.cs:13-16, :115, :163). The drafted check runs the one emit case, `goldenEmit`: each run/ input's C from `t5EmitC` in its `// mode:`, hashed (golden.byn:495-497, :1710-1729), against emit/run-c.sha256.
- Pairs with the drafted check: `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'emit/'`
- Differs from the law file's draft (:25), which names `bayan-emit`; the emit case does not run it (the exported `emit-c/` cases do, goldenprograms.byn:1125, but they are not the run/ corpus). `emit/` does not match `emit-c/`.

### L026 (docs/laws/026-path-agrees-with-dotnet.md)

- Current statement (:16): "For every input in a seeded corpus of separators (`/`, and `\` on Windows), drive letters (`C:\x`, `C:x`), UNC roots, `.`/`..` and empty segments, a compiled Bayan program calling `Path.combine` (both forms), `Path.fileName`, `Path.directoryName`, `Path.isRooted`, `Path.fullPath` and `Path.relative` prints what .NET's `Path.Combine`, `GetFileName`, `GetDirectoryName`, `IsPathRooted`, `GetFullPath` and `GetRelativePath` return when .NET runs on the same host. Expected outputs are per host (macOS and Windows `Path` semantics differ); the corpus runs on both. Where .NET throws, the program panics with a nonzero exit."
- Drafted: "For every `run/path` case in the freeze manifest, the program `bayan` builds from the case prints the frozen expected output byte for byte (stdout, and stderr and exit code where the case holds them). The frozen files are the C# compiler's output at the freeze (L043)."
- kind `run/path` (16 cases), tool: the live check (:10) runs `--only 'run/path'`, each case built and run by `$BAYAN_EXE` and compared on `.stdout`, `.stderr`, `.exitcode` (golden.byn:489-490, :1493-1500, :458-461).
- Pairs with the live check, unchanged: `bash runtime/tests/run.sh && bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'run/path'`
- The `runtime/tests/run.sh` half (the T24b fixtures) is not in the template; the statement covers the run/path half only. Same tool and kind as the law file's draft (:20).

### L028 (docs/laws/028-driver-equivalence.md)

- Current statement (:15): "For every case of the R10 corpus and the R2 usage corpus, stage 2's stdout, stderr and exit code equal `CliApp.Run`'s with elapsed time masked (before comparing, every match of the regex `[0-9]+\.[0-9]{2}s` — the `build.seconds` and `test.seconds` messages, `CliApp.cs` `Seconds` — becomes `<t>s`, and every JSON `"durationMs": <number>` value — `TestReport.cs` — becomes `"durationMs": 0`; nothing else is masked); the comparison runs with stderr not a terminal and `CI` set."
- Drafted: "For every case in the freeze manifest (the R10 corpus and the R2 usage corpus), the driver `scripts/ci/bootstrap-check.sh` builds prints the frozen expected output byte for byte, with the same time masks. The frozen files are the C# compiler's output at the freeze (L043)."
- kind: every kind, tool: the live check (:10) runs the whole of tests/cases with `tmp/bootstrap-check/bayan`, which is stage 1, built by the previous commit's bootstrap (scripts/ci/bootstrap-check.sh:4-5, :66), not stage 2; the masks are golden.byn:1594-1597 (`durationMs`) and goldenexport.byn:862-865 (`<t>s`).
- Pairs with the live check, unchanged: `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases`
- Differs from the law file's draft (:19), which says "the stage-2 driver"; the check runs stage 1. The law file's draft also spells the masks out; the owner may keep that sentence.

### L027 (docs/laws/027-bootstrap-fixpoint.md)

The approved wording is already the Statement (owner 2026-11-18, commit 6941593d1, History :25): "For the driver's sources and each of `safe` and `debug`, the C stage 1 emits and the C stage 2 emits are byte-identical and contain no absolute path and no timestamp, all stages built on the same host. For the frozen tree (`csharp-final`), the self-hosted compiler built by the C# compiler from that tree emits, for that tree's `src/driver` in `safe`, C byte-identical to that tree's `bootstrap/bayan.c`." No owner edit is left in the enactment turn. The `check:` swap is in the table below.

### L039 (docs/laws/039-format-parity.md)

Retired by the owner 2026-11-18 (unenacted; commit 23a0dea08). The retirement edit is the status line only, `status: proposed` to `status: retired`, and it is already in the file (:4, History :23). No edit is left for the owner; its `check:` is never swapped.

## Part 2 swap table (2026-11-19)

"Landed" was checked with `git log` on feat/019-dotnet-exit at d7498e9fa. T17c: its cases landed in 2e635d6d6 (2026-11-18), the task line is unticked (its done-when waits on T19's pending rows: 8 remain, all cli/). T31b: not landed (only its task-line commits a8e16d046, c772cdc74). T46: landed (3031d8713, 9dfafe98e); scripts/ci/ddc-laws.txt lists no id. The landed lex/, parse/, sem/ and emit-c/ classes hold no export of the C# no-panic tests (SelfhostLexerTests.cs:376, SelfhostParserNoPanicLawTests.cs:28, SelfhostSemanticsNoPanicLawTests.cs:45, SelfhostEmitterNoPanicLawTests.cs:100) and no task owns that port. An `lNNN-` selector is a placeholder until a port names its cases that way.

Rechecked 2026-11-19 (share 019-t31e) at 362c0e42a: no commit since d7498e9fa touches tests/cases, docs/laws or scripts/ci/ddc-laws.txt, so none of L002, L018, L022, L023, L024, L025 swaps yet. The exported lex/, parse/, sem/ and emit-c/ classes hold no `*NoPanic*` class, no SelfhostSemanticsEquivalenceLawTests and no SelfhostEmitterEquivalenceLawTests, and no case is named `l002-`, `l018-`, `l023-` or `l025-`. Of SelfhostLexerTests the export holds LexGolden, JsonOnStdinMatchesTheReferenceLexer, CorpusMatchesTheReferenceLexer, RunOnStdinRunsAPromptProgramOnce and BayanLexJsonEqualsTheReferenceLexerOnEveryInput (L001, 10021 cases), not BayanLexNeverPanicsAndKeepsSpansInsideTheInput (L002, :376). That L002 fact reads the same `StdinRuns` inputs as the exported L001 cases (SelfhostLexerTests.cs:363, :378), but those cases compare stdout only: only the 21 cases with an `expected.exitcode` compare the exit code (goldenprograms.byn:1487-1491), so they do not check L002's exit clause. L022 and L024 still have their old Statements; the drafted Statements are not enacted. So L002, L018, L023 and L025 each wait on a port of its C# no-panic test (SelfhostLexerTests.cs:376, SelfhostParserNoPanicLawTests.cs:28, SelfhostSemanticsNoPanicLawTests.cs:45, SelfhostEmitterNoPanicLawTests.cs:100) as `lNNN-*` cases, which no task owns, and L022 and L024 each wait on the owner enacting its drafted Statement.

Updated 2026-11-19 (T31c) at c82175292: the four no-panic proofs are ported as Bayān test blocks under src/driver (Decision 2026-11-19 on the T31c line: generated corpus run through the stage-1 tool with `--many`, not frozen `lNNN-` cases), and the live `check:` and `proof:` lines of L002, L018, L023 and L025 are swapped. The paragraph above is the state before those landings. Still open from this table: L022 and L024 (the owner's enactment). L018's proof asserts no panic and spans inside the input; the C# oracle half of the old test (child inside parent against the reference parser) cannot run without .NET and is recorded in its Proof notes as an owner question.

| law | drafted `check:` line | waits on today |
|---|---|---|
| L002 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'L002:'` | nothing: swapped 2026-11-19 (T31c, 91ed52c6e); the proof is the test block in src/driver/nopanic-l002.test.byn, not `l002-*` cases |
| L018 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'L018:'` | nothing: swapped 2026-11-19 (T31c, 1d71369a4); the proof is the test block in src/driver/nopanic-l018.test.byn, not `l018-*` cases |
| L022 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'typed/' --only 'diag/' --only 'sem/'` | the owner enacting the drafted statement above; the cases are in the tree (T17c cases landed 2e635d6d6, no sem/ pending row), but they do not cover the current statement (two programs agreeing) |
| L023 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'L023:'` | nothing: swapped 2026-11-19 (T31c, b2fa8d774); the proof is the test block in src/driver/nopanic-l023.test.byn, not `l023-*` cases |
| L024 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'emit/'` | the owner enacting the drafted statement above; emit/run-c.sha256 is in the tree, but it does not cover every `BuildMode` or the generator seeds the current statement names |
| L025 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'L025:'` | nothing: swapped 2026-11-19 (T31c, eba6069b2); the proof is the test block in src/driver/nopanic-l025.test.byn, not `l025-*` cases |
| L039 | none | retired 2026-11-18 (23a0dea08); no swap |
| L027 | `bash scripts/ci/bootstrap-check.sh >/dev/null && bash scripts/ci/fixpoint-check.sh` | (1) L027 in scripts/ci/ddc-laws.txt: landed (T31). (2) scripts/ci/fixpoint-check.sh: landed (T31), builds stage 2 with stage 1, emits src/driver in `safe` and `debug`, compares the bytes, and scans for absolute paths and timestamps. |
| L006 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only '/l006-'` | swapped 2026-11-19 (T31b share C): the 69 exported `l006-` cases of tests/cases/cli/L006OwnershipGuardTests; proof src/driver/goldenexport.byn |
| L007 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only '/l007-'` | swapped 2026-11-19 (T31b share C): the 24 exported `l007-` cases of tests/cases/cli/L007UntrustedSinkTests; proof src/driver/goldenexport.byn |
| L008 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only '/l008-'` | swapped 2026-11-19 (T31b share C): the 24 exported `l008-` cases of tests/cases/cli/L008OwnershipRuntimeTests; proof src/driver/goldenexport.byn |
| L013 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only '/l013-'` | swapped 2026-11-19 (T31b share C): the 96 exported `l013-` cases of tests/cases/cli/L013DirectAndIndirectCallsAgreeTests; proof src/driver/goldenexport.byn |
| L019 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'L019:'` | swapped 2026-11-19 (T31b share B): the `L019:` block of src/driver/l019.test.byn, over run/*.test.byn only |
| L020 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'emit/'` | swapped 2026-11-19 (T31b share B): emit/run-c.sha256, the port of `PlainBuildEmitsTheSameC` |
| L021 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'mutator: a mutant that would not type-check'` | swapped 2026-11-19 (T31b share B): the 8 not-emitted rows of src/driver/mutate.test.byn; the 300 seeded programs are dropped |
| L038 | `bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only '/l038-'` | T31b, not landed; L038 is proposed and, per the owner (T31 line), is repointed to the self-hosted formatter and proven after 019, so this line may never be used |

## Proof lines that name files 019b deletes

T67 deletes csharp/, src/tests/*.cs and Bayan.slnx (tests/Bayan.Tests/ is not tracked; the C# tests are under csharp/tests/Bayan.Tests/). A `proof:` file must contain the law id literally (docs/laws/README.md:67). src/driver/golden.byn holds no id below L040, so each "golden.byn" target below needs the id added beside the kind's branch (as L040-L042 have theirs) when it is repointed.

| law | current `proof:` | proposed target |
|---|---|---|
| L001 | src/tests/SelfhostLexerTests.cs | src/driver/golden.byn (`goldenLex`, :265) |
| L002 | src/tests/SelfhostLexerTests.cs | swapped 2026-11-19 (T31c): src/driver/nopanic-l002.test.byn |
| L003 | csharp/tests/Bayan.Tests/MapModelTests.cs | swapped 2026-11-19 (T31b share B): src/driver/mapmodel.byn; `check:` adds `--only 'map model: '` after `run/map-` |
| L004 | csharp/tests/Bayan.Tests/L004UnionSwitchTests.cs | src/driver/golden.byn (diag cases, `goldenDiag` :339) |
| L005 | csharp/tests/Bayan.Tests/L005RunBatchTests.cs | runtime/tests/run.sh (its live check; holds no `L005` today) |
| L006 | csharp/tests/Bayan.Tests/L006OwnershipGuardTests.cs | swapped 2026-11-19 (T31b share C): src/driver/goldenexport.byn (the L006–L016 comment above `goldenCli`) |
| L007 | csharp/tests/Bayan.Tests/L007UntrustedSinkTests.cs | swapped 2026-11-19 (T31b share C): src/driver/goldenexport.byn (the L006–L016 comment above `goldenCli`) |
| L008 | csharp/tests/Bayan.Tests/L008OwnershipRuntimeTests.cs | swapped 2026-11-19 (T31b share C): src/driver/goldenexport.byn (the L006–L016 comment above `goldenCli`) |
| L009 | csharp/tests/Bayan.Tests/TypedDumpTests.cs | swapped 2026-11-19 (T30f): src/driver/golden.byn, the `typed-dump` kind (`goldenDeterministic`, :440): each tests/cases/typed and tests/cases/run case (371) dumped twice in place and once from a copy under tmp/l009/, the three compared, as the C# `DumpIsDeterministic`; `goldenTyped` (:400) still compares each typed case with its frozen `.types`. The `bayan types` fact is the cli case cli/TypedDumpTests/SelfHostSymbolTablesTypesAreByteIdentical |
| L010 | csharp/tests/Bayan.Tests/L010Utf8DecodeTests.cs | swapped 2026-11-19 (T31b share C): src/driver/goldenexport.byn (the L006–L016 comment above `goldenCli`) |
| L011 | csharp/tests/Bayan.Tests/L011ColourAddsOnlyEscapesTests.cs | src/driver/golden.byn (style cases) |
| L012 | csharp/tests/Bayan.Tests/L012InterfaceDispatchTests.cs | swapped 2026-11-19 (T31b share C): src/driver/goldenexport.byn (the L006–L016 comment above `goldenCli`) |
| L013 | csharp/tests/Bayan.Tests/L013DirectAndIndirectCallsAgreeTests.cs | swapped 2026-11-19 (T31b share C): src/driver/goldenexport.byn (the L006–L016 comment above `goldenCli`) |
| L014 | csharp/tests/Bayan.Tests/L014CaptureByCopyTests.cs | src/driver/golden.byn (diag and run cases) |
| L015 | csharp/tests/Bayan.Tests/SymbolLawTests.cs | swapped 2026-11-19 (T31b share C): src/driver/goldenexport.byn (the L006–L016 comment above `goldenCli`) |
| L016 | csharp/tests/Bayan.Tests/MapKeyLawTests.cs | swapped 2026-11-19 (T31b share C): src/driver/goldenexport.byn (the L006–L016 comment above `goldenCli`) |
| L017 | src/tests/SelfhostParserEquivalenceLawTests.cs | src/driver/golden.byn (`goldenParse`, :273) |
| L018 | src/tests/SelfhostParserNoPanicLawTests.cs | swapped 2026-11-19 (T31c): src/driver/nopanic-l018.test.byn |
| L019 | csharp/tests/Bayan.Tests/InstrumentedRunLawTests.cs | swapped 2026-11-19 (T31b share B): src/driver/l019.test.byn |
| L020 | csharp/tests/Bayan.Tests/MutantSchemataTests.cs | swapped 2026-11-19 (T31b share B): src/driver/golden.byn (`goldenEmit`, tagged L020) |
| L021 | csharp/tests/Bayan.Tests/NotEmittedLawTests.cs | swapped 2026-11-19 (T31b share B): src/driver/mutate.test.byn (tagged L021) |
| L022 | src/tests/SelfhostSemanticsEquivalenceLawTests.cs | src/driver/golden.byn (`goldenTyped`, `goldenDiag`) and src/driver/goldenprograms.byn (`goldenProgramSem`, :941), after the statement is enacted |
| L023 | src/tests/SelfhostSemanticsNoPanicLawTests.cs | swapped 2026-11-19 (T31c): src/driver/nopanic-l023.test.byn |
| L024 | src/tests/SelfhostEmitterEquivalenceLawTests.cs | src/driver/golden.byn (`goldenEmit`, :1713), after the statement is enacted |
| L025 | src/tests/SelfhostEmitterNoPanicLawTests.cs | swapped 2026-11-19 (T31c): src/driver/nopanic-l025.test.byn |
| L026 | csharp/tests/Bayan.Tests/StdPathLawTests.cs | src/driver/golden.byn (run cases, :1493) |
| L027 | csharp/tests/Bayan.Tests/BootstrapTests.cs | scripts/ci/fixpoint-check.sh (T31, landed) |
| L028 | src/tests/SelfhostDriverGoldenTests.cs | src/driver/golden.byn |
| L031 (proposed) | csharp/tests/Bayan.Tests/RuntimeNativeTests.cs | runtime/tests/run.sh (its check; holds no `L031` today) |
| L038 (proposed) | csharp/tests/Bayan.Tests/LayoutTests.cs | no target yet: the self-hosted formatter proof after 019 (owner, T31 line) |
| L039 (retired) | src/tests/SelfhostDriverTests.cs | none: retired, not gated |
