# 011 — The C# compiler archive (`csharp-final`)

Status: decided (spec 019 R31, R32; owner 2026-11-18, option a of T65)
Release: unscheduled (0.4.0)
Date: 2026-11-23
Sources: `docs/specs/019-dotnet-exit/019-spec.md` (R31–R34), `019-tasks.md` (T65, T66, T67)

The C# compiler stops being part of the tree with 019b. Its last state is kept as an annotated git tag, so it can be read, built and restored without searching history.

## The tag

| | |
|---|---|
| Tag | `csharp-final` (annotated) |
| Commit | `e57839016`, the 019a merge commit on `dev` (`Merge feat/019-dotnet-exit: 019a, the .NET exit (ci 45168518573, laws-nightly 45168530621 green)`) |
| Checked before the tag is pushed | one `dotnet test` and one manual ddc run on that commit (R31); the tag was made locally on 2026-11-23 and pushed by the owner the same day; the owner accepted both results as R31 met on 2026-11-24 (below) |
| 019b starts at | the commit after it on `dev`; the removal commit is titled `chore(019b): remove the C# compiler` (R33) |

## What it holds

- `csharp/`: the C# compiler (lexer, parser, semantics, C backend, CLI) and its xUnit suite under `csharp/tests/Bayan.Tests/`.
- `src/tests/*.cs`, `Bayan.slnx`, the C# sources of `editors/language-server`, `tools/Bayan.SyntaxFuzz` and `tools/Bayan.UnicodeGen`.
- The .NET CI jobs as they ran at that commit (`.github/workflows/`).

`global.json` stays in the tree after 019b: `scripts/ci/install-dotnet.sh` reads it for the weekly ddc job (R27, R34), which builds the C# compiler from this tag.

## Reading, checking out and restoring it

Read one file:

```
git show csharp-final:csharp/Bayan.Cli/Program.cs
```

Check out the whole tree beside the working copy:

```
git worktree add ../bayan-csharp csharp-final
```

Restore `csharp/` into the current tree:

```
git restore --source=csharp-final -- csharp/
```

## R31 results (macOS arm64, .NET 10, `NuGetAudit=false`, 2026-11-23)

- **ddc:** `bash scripts/ci/ddc.sh csharp-final` reproduced `bootstrap/bayan.c` byte for byte; L027 7/7; 226 s.
- **`dotnet test`, unfiltered:** the host stops on a stack overflow (the `InstantiateType` recursion T64a accepts as exit 134) and the `Selfhost*` classes fail. Every failure is drift: those tests compare the C# against `.byn` sources, cases and CLI text that 019a changed after the C# froze at `v0.3.2` (new builtins `ioStdinRead` and `fsFileSize`, BYN2745, new case kinds, the `mutate` usage line). The same suite at `v0.3.2` passes 15,589 of 15,589.
- **`dotnet test -c Release`, drift excluded:** 3,540 of 3,543 passed in 13 min 11 s. Two of the three failures are drift (`StdTestFilesTests.ModuleTestsPass` and `ModuleTestsPassInAHarnessBuild` for `fs`: `std/fs` calls `Fs.fileSize`, which the C# does not have, BYN2003). The third, `CliMemoryBoundsTests.M1_ATestPrintingUntilKilledStaysSmallAndReportsTheElidedBytes`, failed under load and passes alone (8 s). The filter:

```
FullyQualifiedName!~Selfhost&FullyQualifiedName!~Bayan.Tests.DiagTests&FullyQualifiedName!~Bayan.Tests.DiagnosticCodesTests.EveryDocExampleReportsItsOwnCode&FullyQualifiedName!~Bayan.Tests.DiagnosticCodesTests.EveryDocBelongsToACode&FullyQualifiedName!~Bayan.Tests.RunTests&FullyQualifiedName!~Bayan.Tests.NotEmittedLawTests.NotEmittedSitesAreReportedNotEmittedOverRunCases&FullyQualifiedName!~Bayan.Tests.MutantSchemataTests&FullyQualifiedName!~Bayan.Tests.CoverageTests&FullyQualifiedName!~Bayan.Tests.OwnershipCheckerTests.SafeAndFastCHaveNoChecker&FullyQualifiedName!~Bayan.Tests.InstrumentedRunLawTests
```

The owner accepted these as R31 met on 2026-11-24: the tag stays on `e57839016`, and no C# is fixed after it.

The tag is frozen: it is never moved, and C# fixes are not made after it. The weekly ddc job (`.github/workflows/ddc.yml`) defaults to it since T65 (pushed 2026-11-23) and builds the C# compiler from it to reproduce `bootstrap/bayan.c` (diverse double-compiling).
