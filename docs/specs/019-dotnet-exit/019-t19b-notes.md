# 019 T19, share 019-t19b: notes

Status: draft; working notes, 2026-11-19.

The 99 pending rows of tests/cases/DIVERGENCES.tsv whose case does not start with `cli/SelfhostDefault`. Each ends as one of: deleted (it
passes), a question number and side, `new` (question below), `remove` (cannot be reproduced, below) or `waits on t19a staging:`.

| Outcome | Rows |
|---|---|
| (b) deleted, the case passes | 43 |
| (a) answered question | 1 (Q1018, driver) |
| (a) `new` question | 7 |
| (c) `remove` | 7 |
| waits on t19a staging | 41 |

## (b) Runner and land-time changes

- Version: land-export.sh `mask_version` writes `bayan <version> (masked)` for the version line in cli expected.stdout and expected.stderr;
  `goldenCliVersionLine` masks the run's line the same way. 8 rows.
- Std module list: land-export.sh `mask_std` writes `import one of <std modules>` for the export's `std.json`-only list in expected.*
  files; `goldenStdModules` masks any back-quoted list after `import one of ` when the expected text holds `<std modules>`
  (`goldenDiffer`, `goldenProgramCheck`, `goldenProgramSame`). The 14 landed files were re-landed through land-export.sh from
  tmp/export-t17x. 14 rows.
- SelfhostDriverT5Tests: `goldenCliT5Stub` writes the fake zig (tmp/t5/pdb-bin) and the rejecting cc (tmp/t5/rejecting-bin) that
  the C# wrote on `PATH` (LeavesNoLinkByProductAsCliApp, -2, -3, -6; RejectedCAsCliApp, -2, -3); `EmitCAsCliAppOnEveryRunInput*` builds
  in tmp/t5/emit/run_<stem>/ (11 rows); `RunAsCliAppOnEveryRunInput*` runs in a fresh tmp/t5/cwd/<stem>/ (-123, -129);
  `OutputNamesAsCliApp*` runs in tmp/t5/cs/<the SameIn name>/ (-2).

## (a) Answered

- cli/SelfhostDriverT5Tests/LeavesNoLinkByProductAsCliApp-4: Q1018 (a), driver. expected.stderr rewritten with the driver's output
  (golden update; the output changes because the driver prints its IoError text, not .NET's exception text).

## (a) New questions

1. **A C compiler killed by a signal.** `build` with a cc that kills itself (`kill -9 $$`): the export printed BYN4001 `C compiler failed
   (exit 137)` and exited 4 (Q53: a child killed by a signal reports exit code 128+signal); the driver's `Io.run` now returns
   `IoError.signaled` (007) and the driver prints `bayan: cannot run the C compiler <path>: The child process was ended by this signal; ...`.
   Which report does a signaled C compiler get? Cases: cli/SelfhostDriverT3Tests/ACompilerKilledBySignalIsAFailure. Recommended side:
   csharp (the compiler ran and failed; BYN4001 with its exit status, 128+signal, keeps one report for every failed compile).
2. **T18 case expressions typed as errorExpr.** The export's model types the case expression as `literal i32` (2362:8), `methodGroup
   privFn` (2412:12) and `methodGroup hiddenFn` (2384:14); the self-hosted model gives `errorExpr` at column 5 of the same lines. Is
   the self-hosted model's error the intended result for these inputs? Cases: sem/SelfhostSemanticsT18Tests/CaseMatches-22,
   CaseMatches-47, CaseMatches-107. Recommended side: csharp (the inputs type-check in the export; analysed only to the first differing
   line).
3. **T25 area order.** The export's area dump lists area `r` at depth 2 first (`area depth r 2 727`, `r 2 144`); the self-hosted one lists
   `s` at depth 1 with no offset. Which order and depth does the dump give? Cases: sem/SelfhostSemanticsT25Tests/RunMatches, RunMatches-2.
   Recommended side: csharp (analysed only to the first differing line).
4. **T25 union member order.** The export's dump orders the union members by index (`[0:y,1:x]`), the self-hosted one by name
   (`[1:x,0:y]`). Which order does the dump give? Cases: sem/SelfhostSemanticsT25Tests/UnionAndLentMatch. Recommended side: csharp.

## (c) Cannot be reproduced (`remove`, right `pending`)

- cli/SelfhostDriverStage2FormatTests/FormatTreesAsCliApp-84, cli/SelfhostDriverT1Tests/FormatAsCliApp-32: the C# linked
  `link -> other/deep` to a file outside the formatted tree; the export recorded neither the link nor other/a.byn.
- cli/SelfhostDriverT5Tests/EmitCAsCliAppOnEveryRunInput: the C# built run/alias-field-default-import/main.byn in
  tmp/t5/emit/run_alias-field-default-import_main/; the export recorded the input as main.byn alone, and the expected stderr prints the
  run case's directory name.
- sem/SelfhostSemanticsT9Tests/FunctionsMatchTheCSharpBuiltins: the expected table holds line numbers of the export-era
  src/semantics/builtins.byn; the case reads the tree's file.
- sem/SelfhostSemanticsT9Tests/AliasesBindAsTheCSharp: the C# bound modules sub/ and main/; the export recorded main only.
- sem/SelfhostSemanticsTests/UnobservableMarksMatchCompilation, -2: the C# wrote tmp/t26-tests/unobservable/marks.byn from a C# constant
  at run time; the export recorded no input for it.

## Waits on t19a staging

links or modes files (symlinks and permission bits):

- cli/SelfhostDriverStage2FormatTests: ALoopingFileLinkAsCliApp, AnUnwritableFileAsCliApp, FormatTreesAsCliApp-3, -61, -85, -88, -101,
  -113, UnreadablePathsAsCliApp, -2, -3
- cli/SelfhostDriverT1Tests: AuditReportsADanglingLinkAsCliApp, AuditReportsALoopingFileLinkAsCliApp,
  AuditReportsWhatItCannotReadAsCliApp, -2, -3, -4, AuditWalksLinksAsCliApp-2, -3, FormatAsCliApp-13, -38, -40, -49, -53, -54,
  FormatReportsALoopingFileLinkAsCliApp, FormatReportsAnUnreadablePathAsCliApp, -2, -3, FormatReportsAnUnwritableFileAsCliApp

input.byn.ref with input.name:

- cli/SelfhostDriverT1Tests: DiagnosticsJsonAsCliAppDoes, -2, -3, -4
- cli/SelfhostDriverT2Tests: ArgumentErrorsAsCliApp-12, -13
- cli/SelfhostDriverT5Tests: ReadsModuleFilesAndScriptsAsCliApp-4

plain input with input.name:

- cli/SelfhostDriverT1Tests/MutateArgumentsAsCliAppDoes-10, cli/SelfhostDriverT2Tests/ParsesAFileNamedDash

env-path input:

- cli/SelfhostDriverT3Tests/FindOnPathSkipsDirectoriesAndEmptyEntriesAsToolchain

empty input tree at the args path:

- cli/SelfhostDriverT1Tests/AuditAsCliApp-11 (input.tsv is empty: the empty directory <repo>/tmp/t6-audit/empty is not created)
