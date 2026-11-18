# 019 T19, share 019-t19a: the `cli/SelfhostDefault*` rows of tests/cases/DIVERGENCES.tsv

82 rows. 77 now pass and are deleted (outcome b), 2 are deliberate (a), 3 cannot be reproduced (c).

## (b) What made the 77 pass

- scripts/selfhost/land-export.sh: `mask_doctor` masks the `bayan` row as `<version>`; `mask_commit` masks `(commit …)` and the
  message after `isn't writable:` in SelfhostDefaultT5Tests' streams. Test: the Plain T5 fixture in land-export.test.sh.
- src/driver/goldenexport.byn, staging for the SelfhostDefault classes: a plain `input` with `input.name`; a T5 input tree no path
  names placed at its first env path; `links` and `modes` applied; `env.git` written as `<bin>/git`. A scratch that `modes` locked is
  opened again after the run.
- src/driver/goldenexport.byn, SelfhostDefaultT9Tests (`Same`, SelfhostDefaultT9Tests.cs:870-925): a step case `<test>-<name>-n` replays
  steps 1 to n-1 in one tree, each with its seed and `Before` action (:931-1294); `$PATH` in `env` is the inherited PATH and
  `tmp/t9-cache/` directories are made below a sibling of the scratch (the odd `cc` stubs of :1012-1018, the logging `zig` of
  :1130-1136), that sibling dropped from the output as `Machineless` drops the repo root. The pointer rewrite of script-oldpointer
  steps 2-3 is left out: only the C# side asserts on it, the output is `hi` either way.

## (a) Deliberate differences

- `cli/SelfhostDefaultT1Tests/ExplainsEveryDocumentedCode-140`: Q1274, side `driver`. The BYN2206 explanation carries the
  `dec(x)` sentence of rev 0024 (spec §3.1, §6.2); the export predates it.
- `cli/SelfhostDefaultT2Tests/FeaturesMatchesTheCSharpCliOnTheCorpus-1006`: `new`, side `driver` recommended.

### New question (T2-1006)

**Which `std` modules does the "import one of" help of an unresolved library name list?** The export was taken when `std/` held
`std.json` only, so its expected help reads ``import one of `std.json` ``. The current `std/` also holds `std.encoding`, `std.fs`,
`std.path` and `std.regex`, and the driver lists every module of the tree it runs from. Cases:
`cli/SelfhostDefaultT2Tests/FeaturesMatchesTheCSharpCliOnTheCorpus-1006`. Recommended side: `driver`, since the help should name the
modules that exist; the expected file would then be re-exported, not edited by hand.

## (c) Cannot be reproduced (`remove`, `pending`)

- `cli/SelfhostDefaultT3Tests/TheCommandsRunBeforeTheCacheArmsStillMatch-4`: the output names the project directory, which in the
  C# run was `dispatch-check`; the export masked it as `<root>` and recorded no name, so the runner's scratch name cannot stand in.
- `cli/SelfhostDefaultT5Tests/AnUnwritableCache-4`: the blocking `cache/file` was left by an earlier row of the same theory and
  is not in this row's export.
- `cli/SelfhostDefaultT5Tests/AWorkingCompilerFromTheEnvironmentAndNoZigOrGit-4`: BAYAN_CC holds a path with a space, so the
  export did not record `fakecc` as an input; the stub compiler cannot be staged.
