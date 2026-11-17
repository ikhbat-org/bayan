# T13c: sem cases written vs inventory tests

All cases are kind `sem` (export run: `tmp/export-t13c/sem/counts.tsv`). The inventory counts tests (dotnet test rows); a case is one `AssertSection` call that reached the export.

| Class | Inventory | Cases | Reason |
|---|---|---|---|
| SelfhostDefaultP2Tests | 3 | 17 | `ErrorPathNodesRecordTheCSharpSyntax` calls AssertSection once per step (9 cases) and `WithFileRebindsAFileFromTextAsCSharpDoes` twice per file (8 cases). `CorpusBoundNodesRecordTheCSharpSyntax` writes none: it only calls the private `AssertSameAsCSharp` helper, which has no AssertSection call, so it is not one of the 16 call sites. |
| SelfhostPathT4Tests | 1029 | 675 | `DiagnosticsAreTheCSharps` 20 of 27 rows and `T41CorpusIsTheCSharps` 655 of 990 rows: a row whose C# expected list is empty asserts `Assert.Empty` and never reaches AssertSection, so writes none. `TheCSharpReportsDiagnostics` (12 rows) only asserts the C# list is non-empty and compares no self-hosted output: none. |
| SelfhostPathT7Tests | 10 | 9 | 4 `LoadingMatchesCSharp` rows plus 5 `AssertKind` tests. `DirectoryNameOfRootPanicsWhereCSharpIsNull` asserts a panic, no AssertSection: none. |
| SelfhostPathT8Tests | 3 | 2 | `PathOfMatchesCSharp` and `ProgramNameMatchesCSharp` one each. `ProgramNameCoversDirectoryFileTrailingSeparatorAndMain` asserts the inputs only: none. |
| SelfhostRevisionT2Tests | 20 | 16 | 4 of 20 `HelpIsTheCSharps` rows have an empty C# expected list (`Assert.Empty`, no AssertSection). |
| SelfhostRevisionT4Tests | 24 | 24 | equal |
| SelfhostRevisionT7Tests | 14 | 14 | equal |
| SelfhostRevisionT8Tests | 9 | 7 | 2 of 9 `DiagnosticsAreTheCSharps` rows are clean programs with an empty expected list (`Assert.Empty`). |
| SelfhostStdImportTests | 17 | 16 | 16 `CaseMatchesCSharp` rows; `StdIsNotCheckedByTheNamingLints` asserts on the run's lines only: none. |

No missing case is a bug in a call site. Rows with an empty C# expected list write no case by design (nothing for the self-hosted side to reproduce beyond "prints nothing").
