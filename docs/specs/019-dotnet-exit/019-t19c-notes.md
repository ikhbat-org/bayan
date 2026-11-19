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
| (b) no row, the case passes (LayoutInputs input blobs restored) | 18 cases (all 38 LayoutInputs cases pass) |
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

## (b) LayoutInputs: input blobs restored

cli/SelfhostDriverStage2FormatTests/LayoutInputsFormatAsCliApp and -2, -3, -13, -18, -19, -21, -23, -24, -25, -27, -29, -30, -32, -33,
-34, -35, -38 failed because four input blobs their input.tsv files name had lost CRs to git's `* text=auto eol=lf` at landing, as the
Edge blob had (change 8); the formatter's output for those caseNNN.byn files differed. Restoring the CRs makes each hash to its name:

- 1fedb8e3… (`let a = 1` / `let b = 2`) and 7eb70257… (one empty line): every line ends CRLF.
- 2b8110bf… and 93a02176…: line 2 alone ends CRLF (the one subset of CRLF line ends that hashes to the name).

All four are below `tests/cases/inputs/files/** -text`, so git stores the bytes as written (`git ls-files --eol`: `attr/-text`, worktree
`crlf` or `mixed`). The other blobs the 38 LayoutInputs input.tsv files name already hashed to their names. All 38 LayoutInputs cases
pass (`◆ 38 passed`); their 18 rows are deleted. No expected file changed.

## Final share run

`bayan test tests/cases --jobs 4 --only cli/SelfhostDefault --only cli/SelfhostDriver --only sem/ --only emit-c/` under nice, stage1
built from this tree:

    ◆ 14589 passed · ✗ 27 failed · 28 pending · 0 test blocks, 14644 golden cases · 3493.18s

26 of the 27 failed and each has a row in tests/cases/DIVERGENCES.tsv. The 27th, cli/SelfhostDefaultT12Tests/ABadTargetIsRefused-2
(no row), timed out after 60 s on the loaded machine; run alone it passes (`◆ 1 passed · 0 test blocks, 1 golden case · 9.30s`).
No failing case is without a row.

## Break tests

The seven test blocks of src/driver/goldenstage.byn passed (`◆ 7 passed`). Then every change above was broken at once (each condition
reverted in goldenexport.byn, the blob's CR stripped) and all seven failed: `assert(dash == "x\n")`, `assert(linked)`,
`assert(goldenCliTarget("/a/b/link/../c.byn") == "/a/b/c.byn")`, `assert(made)`, `assert(y == "y\n")`,
`assert(cwd == $"{scratch}/tmp/t3/out\n")`, `assert(Hex.encode(sha256(bytes.span).span) == name)` (`◆ 0 passed · ✗ 7 failed`). The
modes reopen was then broken alone: `assert(writable)` failed. The file and the blob were restored afterwards.

## T19d: the 8 `new pending` rows

- cli/SelfhostDefaultT2Tests/FeaturesMatchesTheCSharpCliOnTheCorpus-1006: (b). Cause: the help line `import one of `std.json`` was landed
  without the land-time std mask (scripts/selfhost/land-export.sh:154-158 `mask_std`). Action: `mask_std` itself (extracted from the
  script and run on the file) rewrote expected.stderr to `import one of <std modules>`, which src/driver/golden.byn:226 matches; the case
  passes; row deleted.
- cli/SelfhostDriverT3Tests/ACompilerKilledBySignalIsAFailure: (a), Q53, `csharp`. Q53 (docs/decisions/2026-11-14-004-answered-questions.md:982):
  "A child killed by a signal reports exit code 128+signal". Cause: src/driver/cache.byn:579-581 (runtime object) and :686-687 (program)
  catch `IoError.signaled` as any IoError and print `cannot run the C compiler …: {e}`; src/driver/cc.byn:272-276 and :285-289 already map
  it to `C compiler failed (exit 128+n)`. Action: row `Q53 csharp`; expected file kept; driver fix left to a task.
- sem/SelfhostSemanticsT18Tests/CaseMatches-22, -47, -107: (b). First differing line: expected `literal|i32|-|-|-|-|-|2362:8|1`
  (-47 `methodGroup|?|-1|privFn|…|2412:12|-`, -107 `methodGroup|?|-1|hiddenFn|…|2384:14|-`), actual `errorExpr|?|-|-|-|-|-|2362:5|-` with
  `BYN2001 124:14 `other` is not defined`. Cause: the C# test writes the module `other` to tmp/t18-cases/other/other.byn before the run
  (src/tests/SelfhostSemanticsT18Tests.cs:446-450 `WriteOther`); the export did not record it, so the runner ran the world without it.
  Not a semantics difference. Action: src/driver/goldenprograms.byn `goldenProgramGenSem` writes `Other` (:23-31) there for the class;
  all 125 T18 cases pass; rows deleted.
- sem/SelfhostSemanticsT25Tests/RunMatches, RunMatches-2: (b). First differing line: expected `area depth r 2 727`, actual
  `area depth s 1 -1` (the program prints `depthOf` in map order). Cause: the C# test sorts the lines and the lists of each ` local `
  line before comparing (src/tests/SelfhostSemanticsT25Tests.cs:347-348); the export wrote no `compare` word. Action: compare word
  `t25-run` in src/driver/goldenprograms.byn `goldenProgramWord`, chosen by `goldenProgramCaseWord` for these cases; both pass; rows deleted.
- sem/SelfhostSemanticsT25Tests/UnionAndLentMatch: (b). First differing line: expected `empty-left [0:y,1:x] [l1,l2] -`, actual
  `empty-left [1:x,0:y] [l1,l2] -`. Cause: the C# test sorts each line's lists (src/tests/SelfhostSemanticsT25Tests.cs:732, `Canon`
  :716-726); no `compare` word was exported. Action: compare word `t25-pure`; the case passes; row deleted.

All 152 T25 cases pass with the two words. Each runner change has a test block in src/driver/goldenprograms.byn (`t25-run`, `t25-pure`
with the case-word mapping, and the T18 `other` module).
