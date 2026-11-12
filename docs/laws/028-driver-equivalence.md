---
id: L028
title: Driver equivalence
status: enacted
kind: property
scope: selfhost/driver/**, src/Bayan.Cli/CliApp.cs
proof: tests/Bayan.Tests/SelfhostDriverGoldenTests.cs
check: dotnet test -v q --filter "Law=L028"
timeout: 1200
---

## Statement
For every case of the R10 corpus and the R2 usage corpus, stage 2's stdout, stderr and exit code equal `CliApp.Run`'s with elapsed time masked (before comparing, every match of the regex `[0-9]+\.[0-9]{2}s` — the `build.seconds` and `test.seconds` messages, `CliApp.cs` `Seconds` — becomes `<t>s`, and every JSON `"durationMs": <number>` value — `TestReport.cs` — becomes `"durationMs": 0`; nothing else is masked); the comparison runs with stderr not a terminal and `CI` set.

## Counterexample looks like
A corpus case (its argv and input files), and the first differing stream (stdout, stderr or exit code) between stage 2 and `CliApp.Run`, both outputs shown with elapsed seconds masked.

## Proof notes
`BAYAN_LAW_TIER`: unset runs a seeded subset; `full` runs the whole corpus, as L018/L023 do. Approved by the user 2026-11-05 with this wording (012-spec.md, Law candidates). Enactment is the user's edit of `status:` (012 T13).

## Proposed amendment (017 T14)
Draft for the user to re-enact; the front matter and the Statement above stay as enacted until then. The tests already hold the enacted Statement; the proposed one adds written files and the 017 commands. Proposed front matter value: `timeout: 1800` (the front matter stays 1200 until re-enacted; the full tier is measured by the dispatcher on wp1, Q1223).

### Statement (proposed)
For every case of the R10 corpus, the R2 usage corpus, and the 017 corpus (the rows of `SelfhostDriverGoldenTests.Commands`: explain, features, clean, cache, new, init, doctor, audit, format, test, dist, mutate and `--version`/`version`, taken from the C# CLI tests; the `test` and `mutate` theories of the same class; `SelfhostDefaultT1/T2/T5/T9/T12Tests` for their commands), stage 2's stdout, stderr and exit code equal `CliApp.Run`'s, and, in the theories listed below, so do the set of files written under the work directory, their bytes and the owner executable bit of each file. Masks, each with its scope:
- elapsed seconds `[0-9]+\.[0-9]{2}s` become `<t>s` in every stream, as enacted;
- in the streams of the `test` and `mutate` rows, and in `results.json` and `bayan-quality.json` written by them: `"durationMs": <number>` becomes `0` and the other timing keys of `bayan-quality.json` and the `timing:` line of a mutation summary likewise (`SelfhostDriverGoldenTests.MaskTest`); nothing else in any other file;
- in the streams of the `doctor` and `--version`/`version` rows only: the parenthesised commit of a line of exactly the form `bayan VERSION (commit X)` or `bayan VERSION (selfhost)`, with `doctor`'s leading `◆ `, becomes `(<commit>)` (012 Q3);
- in the `dist` rows only: the 64-hex hash at the start of a line of the `SHA256SUMS` file becomes `<sha256>` (a native executable is not reproducible, two C# builds differ), and a written file of a `dist` row that is not UTF-8 text (the executable or archive) is compared by name and mode, not by bytes; in every other command a file that is not UTF-8 text is compared byte for byte, except a file in a `.git/` directory (git's own index, refreshed by git from file times, not Bayan output), compared by name and mode;
- in `CommandAsCSharpCli` only: the row's cache directory in a stream or text file becomes `<cache>`.
The comparison runs with stderr not a terminal.

Which theory compares what:
- `SelfhostDriverGoldenTests.CommandAsCSharpCli` (and the `test` and `mutate` theories of that class through the shared `RunBoth`): streams, exit code and every file written in the work directory; `CommandAsCSharpCli` runs with `CI` set and its own `BAYAN_CACHE`, which is deleted and recreated empty at the same path before the C# run and again before the stage 2 run, so stage 2 never sees the C# run's entries and both runs compile cold; the `test`/`mutate` theories use the harness's shared cache (`BAYAN_CACHE=tmp/cache`), where stage 2 may hit the executable the C# run just stored. That is acceptable there because the cold path is covered by the `dist` and `test` rows of `CommandAsCSharpCli` and by T9's `Same` rows.
- `SelfhostDriverGoldenTests.RunGolden` (`run` rows): streams and exit code, and, through the same `RunBoth` (C# first, the work directory put back, then stage 2), every file the case writes into its work directory (`input.bin`, `copy.bin`, `empty.bin`, `a.txt`, `bad.txt`, `fs-file-exists.tmp`, the `tool` and `sh` files and so on); the shared harness cache. The compiled program goes to the cache, not the work directory.
- `DiagAsCSharpCli`, `DiagJsonGolden`, `LexGolden`, `ParseGolden`, `TypedGolden`, `TypesAndCheckAsCliApp`, `CasesTypeMismatchAsCSharpTest`: streams and exit code only (or the case's golden), the shared harness cache. They compare no written files because none is written where they run: the `check`/`types`/`lex`/`parse` rows leave `tests/cases` unchanged (Q1225).
- `SelfhostDefaultT1/T2/T5/T9/T12Tests`: their own Same/Oracle comparisons (streams and exit code, and the named files each checks), the shared cache. `tests/cases/style` is compared by `SelfhostDefaultT5Tests`; `tests/cases/new` trees are the C# `ScaffoldTests`' golden and are not claimed here (the `new` and `init` rows compare stage 2 with the C# on app, lib and script); `tests/cases/quality` is not claimed.

### Counterexample looks like (proposed)
A corpus case (its argv, cwd and input files) and the first differing stream or file between stage 2 and `CliApp.Run`, both shown masked.

### Proof notes (proposed)
`BAYAN_LAW_TIER` unset = a seeded subset per command (at least one row per command); `full` = every row, as L018/L023 do. The `check:` line stays `dotnet test -v q --filter "Law=L028"`.
