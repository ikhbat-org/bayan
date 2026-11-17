# 019 export runners: how each exported case is run and compared

Source of truth: the C# tests on the export branch, `src/tests/` (written `$T`). Cases: `tmp/export-full/<kind>/<Class>/<case>/`.
Case dir name is `<test>[-row][-n]`. A case never names the program it ran; the C# builds it. This file records that program.
All C# citations are `$T/<file>:<line>`; the file column abbreviates `Selfhost<X>Tests.cs` as `<X>`.

Shared programs:

- **GenEmit(Main)**: all `src/emitter/*.byn` except `main.byn`, ordinal-sorted, plus the class's C# `const string Main` as `src/emitter/main.byn`. Package root `src/`, fast mode (`SelfhostSemanticsHarness.BuildFast`), `BAYAN_CACHE=tmp/cache`.
- **bayan-emit**: all `src/emitter/*.byn` including `main.byn`, root `src/`, fast (`SelfhostEmitterHarness.cs:29-42`, `Run(args)` :42).
- **GenSem(input)**: all `src/semantics/*.byn` except `main.byn`, plus the case `input.byn` as `src/semantics/main.byn`, root `src/`, fast (`SelfhostSemanticsHarness.cs:27-52`, `RunSections` :392-426). Stdout is split on `== name` lines (`Sections` ~:433). `section` is the name the C# asked for. `expected.sections` holds the printed header.
- **bayan-check**: all `src/semantics/*.byn` including `main.byn`, root `src/`, fast (`SemanticsTests:31-43`).
- **bayan-parse**: all `src/parser/*.byn` including `main.byn`, root `src/`, fast (`ParserTests:26-39`, `BuildParser` :30-37).
- **bayan-lex**: `Compilation.FromPath(src/lexer/main.byn)`, fast (`LexerTests:21-33`).

Default compare when the `compare` file is absent: exact, line by line (CRLF read as LF). `AssertSame` is `SelfhostEmitterHarness.cs:50-79`.

## emit-c

| class | test-name prefix | program | call (argv / stdin) | compared output | compare | C# file:line |
|---|---|---|---|---|---|---|
| DefaultT10 | coverage/mutate words (AnInputWithErrors, CoverageCounters, SitesJson, MutateOfALargeInput, MutateSkips, FoldsFloatsAndEscapes, EdgeFixture main, RichFixture main) | GenEmit(T10 Main, DefaultT10:23) | `args` file: `coverage\|mutate [-skip\|-tests] ...` | stdout vs `expected.c` | default | DefaultT10:141, :151, :168, :175, :203, :229, :255, :282, :402 |
| DefaultT10 | args start with `-` (`--coverage`, `--mutate`, `--package`, `--mode`; CoverageC/MutateC theory, FixtureC, EdgeFixture, RichFixture) | bayan-emit | `args` file; plain-file input maps `--package` dir to `.`, directory input is `input/` | stdout vs `expected.c` | default | DefaultT10:291, :321, :364, :371, :422 |
| DefaultT10 | FixtureC SameAsCli cases (2) | bayan-emit | `args` file | stderr, stdout (`expected.c`), exit (`expected.exitcode`) | default | DefaultT10:374 |
| Harness | BadArgumentsFailLikeBuild (8) | bayan-emit | `args` = C# CLI args; self argv = args minus `build --emit-c`; map by case label | stderr, `expected.c`, `expected.exitcode` | default | EmitterParity:308 |
| Harness | CacheAppWithAStoringCalleeFailsLikeBuild (1) | bayan-emit | as above | as above | default | EmitterParity:227 |
| Harness | CorpusErrorInputsAgree (105) | bayan-emit | as above | as above | default | EmitterParity:85 (class), EmitterHarness.cs:149-173 (`SameAsCli`) |
| Harness | DiagnosticOptionsAgree (1284) | bayan-emit | as above | as above | default | EmitterParity:85, EmitterHarness.cs:149-173 |
| Harness | ErrorInputsAgree (642) | bayan-emit | as above; input is `Isolate(name)` copy | as above | default | EmitterParity:~104-120 |
| Harness | GlobalOptionsFailLikeBuildOnAnErrorInput (3) | bayan-emit | as above; `--color` global | as above | default | EmitterParity:264-269 |
| Harness | ManifestErrorsAgree (21) | bayan-emit | as above | as above | default | EmitterParity:131-141 |
| Harness | ModeAndTimeFailLikeBuildOnAnErrorInput (2) | bayan-emit | as above; `--mode fast\|turbo`, `--time` map differently | as above | default | EmitterParity:235-239 |
| Harness | PackageAndTestsFailLikeBuildOnAnErrorInput (4) | bayan-emit | as above; `test` becomes `--tests`, `--package <dir>` | as above | default | EmitterParity:295-303 |
| Harness | ProjectAndScriptErrorsAgree (12) | bayan-emit | as above | as above | default | EmitterParity:160 |
| Harness | ProjectDirectoriesAgree (13) | bayan-emit | as above | as above | default | EmitterParity:193 |
| Harness | WarningsDoNotStopEmission (2) | bayan-emit | as above | as above | default | EmitterParity:209, :222 |
| Parity | RunInputsEmitTheSameC (346) | bayan-emit | `args` file: `--mode <ModeOf> --package <dir> <input>`; `*.test.byn` uses `--tests` form | stdout vs `expected.c` | default | EmitterParity:46-48 |
| Parity | RunTestInputsEmitTheSameC (4) | bayan-emit | `--tests <work>` | `expected.c` | default | EmitterParity:60-63 |
| Parity | ExamplesEmitTheSameC (2) | bayan-emit | SameAsCli; `args` = `build --emit-c <path>`, self argv `[path]` | stderr, `expected.c`, `expected.exitcode` | default | EmitterParity:72 |
| Parity | CacheAppEmitsTheSameC (1) | bayan-emit | SameAsCli | as above | default | EmitterParity:80 |
| T13 | module-order (1) | bayan-emit | `build --emit-c <main>` -> self argv `[main]` | stderr, `expected.c`, `expected.exitcode` | default | EmitterT13:23 |
| T21 | all (33: CorpusAssertConditions 25, Fixtures 8); no `args` | GenSem with the T21 Main | argv = input path; case names starting `+` pass the `+` prefix (all-expr mode) | section named by path vs `expected.c` | default | EmitterT21:18-38 (Main), :136 (RunSections), :143 (AssertSame, `TrimStart('+')`) |
| T22 | Shapes_MatchCSharp (1); no `args` | GenEmit(T22 Main) | `shapes <path>` | `expected.c` | default | EmitterT22:20 (Main), :110 (BuildNow), :269, :271 |
| T7 | Corpus_MatchesCSharp (1360); no `args` | GenEmit(T7 Main) | `corpus <path>` | per `== section` vs `expected.c` | default | EmitterT7:25 (Main), :224 (BuildNow), :472, :352-360 (AssertSections) |
| T7 | Thunk_MatchesCSharp (6) | GenEmit(T7 Main) | `thunk <function> <local> <path>` | as above | default | EmitterT7:532 |
| T7 | Types_Own_Dyn...PlainTypes (4) | GenEmit(T7 Main) | `corpus <path>` | as above | default | EmitterT7:410 |
| T7 | ...StatesAndSlots (4) | GenEmit(T7 Main) | `corpus <path>` | as above | default | EmitterT7:453 |
| T7 | ...StatesAndUnions (4) | GenEmit(T7 Main) | `corpus <path>` | as above | default | EmitterT7:639 |
| T7 | Types_OfATypeNoCaseMatches (1) | GenEmit(T7 Main) | `iface <path>` | as above | default | EmitterT7:574 |
| T2 | * (3) | GenEmit(T2 Main) | `args`: `<mode> - - input.byn` | stdout section vs `expected.sections` | default | EmitterT2:24 (Main), :573 (BuildNow); EmitterHarness.cs:194-215 (AssertSection) |
| T4 | * (23) | GenEmit(T4 Main) | `args`: `<mode> <fn> <decl\|*> input.byn` | as above | default | EmitterT4:20, :252 |
| T5 | * (5) | GenEmit(T5 Main) | `args`: `<mode> - - ...` | as above | default | EmitterT5:23, :443 |
| T6 | * (30) | GenEmit(T6 Main) | `args`: `<mode> input.byn [flag]`; flag `root:<path>` exceptions; section `""` has no header (`main` mode) | as above | default | EmitterT6:22, :254, :41, :317 |
| T8 | * (6) | GenEmit(T8 Main) | `args`: `corpus - input.byn` | as above | default | EmitterT8:21, :290 |
| T9 | * (4) | GenEmit(T9 Main) | `args`: `emit true\|false input.byn` | as above | default | EmitterT9:22, :514 |
| T10 | * (3) | GenEmit(T10 Main) | `args`: `expr\|owned byn_file_0 "a.byn" input.byn` | as above | default | EmitterT10:23, :404 |

## sem

Class file is `SemanticsT<N>` = `SelfhostSemanticsT<N>Tests.cs`. "RS" is the `RunSections` call, "AS" is the assert line. Classes with an `args` file take argv from it (repo-relative paths staged under `input/`). Classes without `args` use the argv written in the cited RS call.

| class | test-name prefix | program | call (argv) | compared output | compare | C# file:line |
|---|---|---|---|---|---|---|
| DefaultP2 (1014) | * | GenSem(input.byn) | `args` | section vs `expected.sections` | default | DefaultP2:167 RS, :176 AS, :438, :487-493 |
| PathT4 (675) | * | GenSem | `args` | section | `t41` (655 cases), else default | PathT4:345 RS, :355, :365-373 |
| PathT7 (9) | LoadingMatchesCSharp (4) | GenSem | `args` | section | default | PathT7:164-165, :172 |
| PathT7 | kind cases (5: dir, full, combine, rel, relslash) | GenSem | `args` | printed section `all` filtered to lines starting `<kind> ` | `prefix:<kind>` | PathT7:189-190 |
| PathT8 (2) | pathof, name | GenSem | `args` | section | `prefix:pathof`, `prefix:name` | PathT8:90 RS, :100-101, :108-109 |
| RevisionT2 (16) | * | GenSem | `args` | section | default | RevisionT2:314, :325 |
| RevisionT4 (24) | LexiconIsTheCSharps (1) | GenSem | `args` | section | `sorted` | RevisionT4:269, :281, :298-299 |
| RevisionT4 | others (23) | GenSem | `args` | section | default | RevisionT4:269, :281 |
| RevisionT7 (14) | * | GenSem | `args` | section | default | RevisionT7:377, :387, :395 |
| RevisionT8 (7) | * | GenSem | `args` | section | default | RevisionT8:403, :417 |
| SemanticsHost (5) | * | GenSem | no `args`; argv in RS | section | default | SemanticsHost:77, :99 |
| T10 (91) | * | GenSem | `args` | section | default | SemanticsT10:135 RS, :470, :494-504 |
| T10 (1) | MainReadsAnUnreadablePackageAsAnEmptyOne | GenSem; `modes` file `package.byn None` | `args` | `expected.golden` | default | SemanticsT10:~170-197 |
| T11 (35) | * | GenSem | `args` | section | default | SemanticsT11:263, :290 |
| T12 (11) | * | GenSem | `args` | section | default | SemanticsT12:265, :292 |
| T13 (17) | * | GenSem | no `args`; argv in RS | section | default | SemanticsT13:1160, :1389 |
| T14 (8) | * | GenSem | no `args`; argv in RS | section | default | SemanticsT14:683, :846 |
| T15 (47) | * | GenSem | no `args`; argv in RS | section | default | SemanticsT15:1191, :1211-1231 |
| T16 (25) | * | GenSem | no `args`; argv in RS | section | default | SemanticsT16:1249, :1259-1271 |
| T17 (118) | * | GenSem | no `args`; argv in RS | section | default | SemanticsT17:1257, :1265-1277 |
| T18 (125) | * | GenSem | `args` | section | default | SemanticsT18:456, :471 |
| T19 (220) | * | GenSem | `args` | section | default | SemanticsT19:513, :528 |
| T20 (98) | * | GenSem | `args` | section | default | SemanticsT20:398, :412 |
| T21 (98) | * | GenSem | `args` | section | default | SemanticsT21:326, :340 |
| T22 (45) | * | GenSem | `args` | section | default | SemanticsT22:342, :357 |
| T23 (51) | * | GenSem | no `args`; argv in RS | section | default | SemanticsT23:544, :557-581 |
| T24 (100) | * | GenSem | no `args`; argv in RS | section | default | SemanticsT24:419, :433 |
| T25 (152) | * | GenSem | `args` | section | default | SemanticsT25:346, :469, :551 RS; :350, :471, :556 AS |
| T34 (95) | * | GenSem | `args` | section | default | SemanticsT34:305, :316 |
| T35 (161) | * | GenSem | `args` | section | default | SemanticsT35:375, :390 |
| T36 (29) | * | GenSem | `args` | section | default | SemanticsT36:628 |
| T37 (98) | * | GenSem | `args` | section | default | SemanticsT37:530, :542 |
| T38 (4) | * | GenSem | `args` | section | default | SemanticsT38:219, :246 |
| T39 (48) | * | GenSem | `args` | section | default | SemanticsT39:450, :464 |
| T40 (3) | sections cases | GenSem | `args` | section | default | SemanticsT40:54, :72, :81 |
| T40 (1+1) | golden case, exitcode/stderr case | GenSem | `args` | `expected.golden`; `expected.exitcode`, `expected.stderr` | default | SemanticsT40:54-81 (the exitcode case body was not read; see cannot-cover) |
| T41 (992) | * | GenSem | `args` | section | `t41` (990 cases) | SemanticsT41:661 RS, :697, :700, :713 (ExportCaller), :728 (Sorted) |
| T4 (4) | * | GenSem | no `args`; argv in RS | section | default | SemanticsT4:337, :544-616 |
| T6 (8) | * | GenSem | no `args`; argv in RS | section | default | SemanticsT6:28, :55 |
| T7 (38) | * | GenSem | no `args`; argv in RS | section | `sorted-end` (36 cases), else default | SemanticsT7:142, :176-189 |
| T8 (10) | * | GenSem | no `args`; argv in RS | section | `sorted` (5 cases), else default | SemanticsT8:321, :359, :366 |
| T9 (8) | * | GenSem | no `args`; argv in RS | section | default | SemanticsT9:175, :381-448 |
| StdImport (16) | * | GenSem | `args` | section | default | StdImport:130, :158 |
| SemanticsTests (51) | SameAsCli cases | bayan-check | `args` with `check` word dropped; `types` becomes `--types` | stdout (`expected.stdout`), stderr, exit | `untimed` | SemanticsTests:198, :206-215, :219-238, :278 |
| SemanticsTests (7) | RunSections cases | GenSem | `args` | section | default | SemanticsTests:147-153 |
| SemanticsTests (5) | GoldenAgrees | bayan-check build (`Built`) | `args` | `expected.golden` | default | SemanticsTests:~546-567 |
| Parity (18) | TypesParity | bayan-check | `args` | `expected.stdout`, stderr, `expected.exitcode` | `untimed` | SemanticsTests:820 (class), :198 |
| Parity (642) | GoldenParity | bayan-check | `--golden --package <dir> [--tests] [--include-path] <path>` | stdout vs `expected.golden`; exit 0, empty stderr | default | SemanticsTests:~546-567 (GoldenSame) |
| Parity (642) | CheckParity | bayan-check | `bayan-check <copy>` | `expected.stderr`, `expected.exitcode` | default | SemanticsTests:~573-597 (CheckSame) |

## parse

| class | test-name prefix | program | call (argv / stdin) | compared output | compare | C# file:line |
|---|---|---|---|---|---|---|
| ParserTests (64 files) | ParseGolden | bayan-parse | `Run(Built, input)`: argv `input` | `expected.ast`, `expected.exitcode` | byte-for-byte | ParserTests:~140-160 |
| ParserTests (106) | DiagGolden | bayan-parse | argv `input` | `expected.ast` (from `tmp/parser-ref/*.ast`), exit | `Golden.Compare` | ParserTests:~160-190 (not read in detail) |
| ParserTests (1) | EmptyFile | bayan-parse | argv `input` | `expected.ast`, exit | default | ParserTests:138 |
| ParserTests (64) | CollectorsMatchAstDump | parser files minus `main.byn` plus `collectors-test.byn` (`CollectorsProgram`) | argv `input` | `expected.collectors` | default | ParserTests:407, :421 |
| ParserTests (346) | CollectorsMatchAstDumpOnTheRunPrograms | same collectors program | argv `input` | `expected.collectors` | default | ParserTests:472 |
| ParserTests (12) | BodyAndNameEdges | bayan-parse | `DumpsAsTheCSharpParser(input)` | `expected.ast`, exit | default | ParserTests:552 |
| ParserTests (6) | Truncated | bayan-parse | as above | as above | default | ParserTests:599 |
| ParserTests (3) | StatementSpans | parser files minus `main.byn` plus `statement-spans-test.byn` | argv `input` | `expected.spans` | default | ParserTests:339, :379 |
| ParserTests (1) | CodesMatchDiagnosticCodes | bayan-parse | argv `--codes`; no input | `expected.codes` | default | ParserTests:632 |
| ParserT4 (1) | * | parser files minus `main.byn` plus `t4-test.byn` (`Program()`) | no argv; program and cases embedded in C# | stdout vs `expected.stdout` | default | ParserT4:143-159 |
| ParserT5 (1) | * | plus `t5-test.byn` | no argv | `expected.stdout` | default | ParserT5:133-149 |
| ParserT6 (15) | literals | plus `t6-test.byn` | `args` file; argv `literals` and input | `expected.literals` | default | ParserT6:144-147, :330, :360, :374 |
| ParserT6 (51) | type | plus `t6-test.byn` | `args` file: `type <mode>` is one argv element (`type fat`) | `expected.type` | default | ParserT6:144-147, :330 |
| ParserT7 (31) | * | plus `t7-test.byn` | `Run(path, input)` | `expected.shapes` | default | ParserT7:83-86, :198 |
| ParserT9 (1) | * | plus `t9-test.byn` | no argv | `expected.stdout` | default | ParserT9:257-272 |
| ParserO3 (7) | * | bayan-parse | argv `input` | `expected.ast`, `expected.exitcode` | default | ParserO3:42-45 |

## lex

| class | test-name prefix | program | call (argv / stdin) | compared output | compare | C# file:line |
|---|---|---|---|---|---|---|
| LexerTests | LexGolden (21) | bayan-lex | argv: input path | `expected.tokens` | `Golden.Compare`, no exit compare | LexerTests:113-121 |
| LexerTests | JsonOnStdinMatchesTheReferenceLexer (21) | bayan-lex | stdin = input bytes; argv `--json` | `expected.json`, `expected.exitcode` | byte-equal | LexerTests:154-168 |
| LexerTests | CorpusMatchesTheReferenceLexer (10000) | bayan-lex | argv: input path (the C# ran `--many <dir>` and split on `== NNNNN.byn` headers; the exported case is one file) | `expected.tokens` | `Golden.Compare` | LexerTests:294-330 |
| LexerTests | BayanLexJsonEqualsTheReferenceLexerOnEveryInput (10021) | bayan-lex | stdin = input; argv `--json` | `expected.json` | byte-equal, no exit compare | LexerTests:413-432 |
| LexerTests | RunOnStdinRunsAPromptProgramOnce (1) | bayan-lex | stdin `x\n`; argv `--json` | `expected.json` | byte-equal | LexerTests:399-409 |
| LexerCaseTests (1) | * | `input.byn` is the generated program, built as `src/t-case.byn` with `Compilation.Create([...], packageRoot: src)`, fast | no argv | stdout vs `expected.stdout` | default | LexerCaseTests:20-70 (program), :24-38 (test) |

## runtime/macos

| class | program | call | compared output | compare | C# file:line |
|---|---|---|---|---|---|
| T24b fixture set | not C#: read by `runtime/tests/run.sh` | per that script | per that script | per that script | none (shell, not read) |

## Section compare words

| word | meaning | C# file:line |
|---|---|---|
| (absent) | exact, line by line, count must match | SemanticsHarness.cs:392-426 |
| `t41` | `Sorted`: diagnostics in order, then `store ` and `returns ` summary lines ordinal-sorted; `returns` indices sorted numerically | SemanticsT41:728 (`Sorted`), used :697, :700; PathT4:365-373 (reflection `T41("Sorted")`) |
| `sorted` | both sides ordinal-sorted | RevisionT4:298-299; SemanticsT8:366-367 |
| `sorted-end` | actual sorted ordinal, plus an appended `end` line | SemanticsT7:185-190 |
| `untimed` | ` in [0-9]+\.[0-9]{2}s(?=\r?$)` (multiline) becomes ` in <time>` on both sides before comparing | SemanticsTests:198 (regex), :278 (writes `compare`), :648 |
| `prefix:<name>` | keep only printed lines starting `<name> ` from section `all` (PathT7 kinds `dir`, `full`, `combine`, `rel`, `relslash`; PathT8 `pathof`, `name`) | PathT7:189-190; PathT8:100-101, :108-109 |

## Cannot cover or needs porting care

- Generated `Main` sources (emit-c T2-T10, T21, T22, DefaultT10) live only in the C# `const string Main`; no case carries them. The port must keep them elsewhere.
- Emit-c T7, T21, T22 and sem classes without `args` (SemanticsHost, T4, T6, T7, T8, T9, T13, T14, T15, T16, T17, T23, T24) have no argv in the case. Argv comes from the cited C# call and the case name only.
- Emit-c HarnessTests `args` hold the C# CLI args (`build --emit-c ...`), not the bayan-emit argv. The mapping from CLI to self argv is by case label and was not tabulated per case.
- Sem Parity `args` hold unmasked repo-relative paths (e.g. `tmp/t26-tests/cli/diag_x.byn/x.byn`, `tests/cases/diag`). The runner must substitute `input.byn` or `input/`.
- Lex Corpus and BayanLexJson cases: the C# call form (`--many <dir>`) does not match the one-file case. The port uses the single-file form.
- Parse T4, T5, T9: programs and cases are embedded in the C# (`Program()`, `Cases`); one case each.
- `DiagGolden` and `Golden.Compare` bodies were not read. The sem T40 exitcode/stderr case body was not read.
- `UNEXPORTED.tsv` rows have no case: emit-c PathT5, DriverT1, EmitterEquivalenceLaw; sem T4 `records`; parse T13 (4 tests) and SpanTakenBeforeTheLastChildLeavesItOutside (:614); lex `batch-cmdline.*` and `path-relative.*`.
- Tests that call `Run(...)` directly (ModeFlagsWantTheirArguments, CleanInputsExitLike...) and T22 `Corpus_LocalsMatchCSharp` (:184) are plain asserts and are not exported.
- runtime/macos was not sampled.
