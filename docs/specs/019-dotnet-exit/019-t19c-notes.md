# 019 T19, share 019-t19c: notes

Status: draft; working notes, 2026-11-19.

The 41 rows of tests/cases/DIVERGENCES.tsv whose reason started `waits on t19a staging:`, the 18 failing
cli/SelfhostDriverStage2FormatTests/LayoutInputsFormatAsCliApp cases with no row and the failing
emit-c/SelfhostDefaultT10Tests/EdgeFixtureMatchesTheCSharpInBothModes-edge mutate case with no row.

| Outcome | Rows |
|---|---|
| (b) deleted, the case passes (T19a staging carried to the SelfhostDriver classes) | 33 |
| (b) no row, the case passes (Edge input blob restored) | 1 case (6 Edge cases pass) |
| (c) `remove` | 8 |
| (c) `remove`, new rows (LayoutInputs, not reproducible from the recording) | 18 |
| (a) | 0 |

## (b) Runner and land-time changes

All in src/driver/goldenexport.byn (`goldenCliStage`, `goldenCliTarget`, `goldenCli`) unless named. Each has a test block in
src/driver/goldenstage.byn.

1. SelfhostDriver staging: the plain `input` with its `input.name`, `links` and `modes` are read for the SelfhostDriver classes as for
   the SelfhostDefault ones (SelfhostDriverTests.cs:66-120 `StageInputs`). Test: "a SelfhostDriver plain `input` goes to the path of
   its `input.name`, and its `links` are made below the input's place".
2. A `links` line naming no directory (SelfhostDriverTests.cs:105-108, a named path that is itself a link) is made at the path `args`
   names. Test: "a `links` line naming no directory is made at the path `args` names when one ends in that name".
3. `goldenCliTarget` takes `..` lexically (SelfhostDriverTests.cs:104 `GetFullPath`). Test: "an input's place takes `..` lexically,
   and a `main.byn` stands for its directory".
4. An empty SelfhostDriverT1Tests input.tsv is the empty directory `args` names (only T1: the Fix classes stage the parent of a missing
   file). Test: "an empty T1 input.tsv is the empty directory `args` names, and another class's empty input.tsv creates nothing".
5. An input below the repo's tests/cases gets the other `.byn` files of the cases at that place beside it
   (SelfhostDriverTests.cs:154 `DiagnosticsJsonAsCliAppDoes`). Test: "an input below the repo's tests/cases gets the other `.byn` files
   of the cases at that place beside it".
6. and 7. A SelfhostDriverT3Tests `exit` case runs in the fresh directory of its `-o` output (SelfhostDriverT3Tests.cs:647
   `FindOnPathSkipsDirectoriesAndEmptyEntriesAsToolchain`); a SelfhostDriver case with `modes` is opened again (`chmod -R u+rwx`)
   after its run. Test: "a T3 `exit` case runs in the fresh directory of its `-o` output, and a SelfhostDriver case with `modes` is
   opened again after its run".
8. Land time: tests/cases/inputs/files/a7f3b60a… (the T10 edge fixture, `EdgeText` writes `&&\r\n`) had its CR dropped by git's
   `* text=auto eol=lf` when it landed; its bytes no longer hashed to its name. The CR is restored (the sha256 matches the name again)
   and .gitattributes marks `tests/cases/inputs/files/** -text`, as the blobs are content-addressed bytes. Test: "the T10 edge input
   blob keeps the CRLF line ending its name hashes". All six EdgeFixtureMatchesTheCSharpInBothModes-edge cases pass.

The 33 deleted rows (outcome b, T19a staging): cli/SelfhostDriverStage2FormatTests ALoopingFileLinkAsCliApp,
AnUnwritableFileAsCliApp, FormatTreesAsCliApp-101, -113, -85, UnreadablePathsAsCliApp, -2, -3; cli/SelfhostDriverT1Tests
AuditAsCliApp-11, AuditReportsADanglingLinkAsCliApp, AuditReportsALoopingFileLinkAsCliApp, AuditReportsWhatItCannotReadAsCliApp,
-2, -3, -4, AuditWalksLinksAsCliApp-3, DiagnosticsJsonAsCliAppDoes, -2, -3, -4, FormatAsCliApp-38, -40, -53,
FormatReportsALoopingFileLinkAsCliApp, FormatReportsAnUnreadablePathAsCliApp, -2, -3, FormatReportsAnUnwritableFileAsCliApp,
MutateArgumentsAsCliAppDoes-10; cli/SelfhostDriverT2Tests ArgumentErrorsAsCliApp-12, -13, ParsesAFileNamedDash;
cli/SelfhostDriverT3Tests FindOnPathSkipsDirectoriesAndEmptyEntriesAsToolchain.

## (c) Cannot be reproduced

Each row is `remove`, `pending`; the export recorded a link but not the file it reaches.

- cli/SelfhostDriverStage2FormatTests/FormatTreesAsCliApp-3, -88, cli/SelfhostDriverT1Tests/FormatAsCliApp-13, -54: `args` name
  proj/sub/f.byn through the directory link proj/sub; the export recorded only `f.byn -> ../g.byn`, not the link proj/sub nor g.byn.
- cli/SelfhostDriverStage2FormatTests/FormatTreesAsCliApp-61, cli/SelfhostDriverT1Tests/FormatAsCliApp-49: `args` name link.byn;
  the export recorded `link.byn -> real.byn`, not real.byn.
- cli/SelfhostDriverT1Tests/AuditWalksLinksAsCliApp-2: `dir/link -> ..` walks to the parent; the export recorded dir/main.byn and the
  link, not the parent's outside.byn.
- cli/SelfhostDriverT5Tests/ReadsModuleFilesAndScriptsAsCliApp-4: the C# read the input's module with its sibling f.byn (`#`); the
  export recorded the input alone.

## (c) Cannot be reproduced: LayoutInputs

cli/SelfhostDriverStage2FormatTests/LayoutInputsFormatAsCliApp and -2, -3, -13, -18, -19, -21, -23, -24, -25, -27, -29, -30, -32, -33,
-34, -35, -38 (`remove`, `pending`). The C# test (`FormatsAsCliApp`) wrote one caseNNN.byn per string literal of a C# test file; the
expected tree shows stray literals among them (case000 `tmp`, case001 `layout`, case002 `main.byn`), and the landed inputs are shifted
against the expected outputs (expected stdout starts `formatted …/case004.byn`, whose landed input already equals its expected text; the
run starts at case006). The recording holds no other copy of the inputs the C# formatted, so the cases cannot be reproduced from it.

## Final share run

`bayan test tests/cases --jobs 4 --only cli/SelfhostDefault --only cli/SelfhostDriver --only sem/ --only emit-c/` under nice, stage1
built from this tree:

    ◆ 14524 passed · ✗ 44 failed · 28 pending · 0 test blocks, 14596 golden cases · 3183.73s

Every one of the 44 failing cases has a row in tests/cases/DIVERGENCES.tsv; no failing case is without one.

## Break tests

The seven test blocks of src/driver/goldenstage.byn passed (`◆ 7 passed`). Then every change above was broken at once (each condition
reverted in goldenexport.byn, the blob's CR stripped) and all seven failed: `assert(dash == "x\n")`, `assert(linked)`,
`assert(goldenCliTarget("/a/b/link/../c.byn") == "/a/b/c.byn")`, `assert(made)`, `assert(y == "y\n")`,
`assert(cwd == $"{scratch}/tmp/t3/out\n")`, `assert(Hex.encode(sha256(bytes.span).span) == name)` (`◆ 0 passed · ✗ 7 failed`). The
modes reopen was then broken alone: `assert(writable)` failed. The file and the blob were restored afterwards.
