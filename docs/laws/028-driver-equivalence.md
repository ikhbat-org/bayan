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
Draft for the user to re-enact; the front matter and the Statement above stay as enacted until then. The tests (`SelfhostDriverGoldenTests.CommandAsCSharpCli`) already implement this corpus, a superset of the enacted one, so the enacted Statement still holds. `timeout:` proposed value: see Q1223 in docs/bayan-handoff.md.

### Statement (proposed)
For every case of the R10 corpus, the R2 usage corpus, and the 017 corpus (every command line of `tests/cases/{run,diag,diag-json,style,new,quality}` and of the C# CLI tests that `SelfhostDriverGoldenTests.Commands` lists per command: explain, features, clean, cache, new, init, doctor, audit, format, test, dist, mutate), stage 2's stdout, stderr, exit code and the set and bytes of the files it writes under the work directory equal `CliApp.Run`'s, with elapsed time masked as before (`[0-9]+\.[0-9]{2}s` becomes `<t>s`; `"durationMs": <number>` becomes `0`; the other timing keys of `bayan-quality.json` and the `timing:` line of a mutation summary likewise, `SelfhostDriverGoldenTests.MaskTest`), the version line's parenthesised part masked (012 Q3), and cache paths under `BAYAN_CACHE` masked to `<cache>`; the comparison runs with stderr not a terminal and `CI` set, and with `BAYAN_CACHE` pointing at a fresh directory per case. Two further masks (Q1222): the 64-hex hash at the start of a `SHA256SUMS` line, and a file that is not UTF-8 text (a native executable, which two C# builds already make differently) is compared by name only.

### Counterexample looks like (proposed)
A corpus case (its argv, cwd and input files) and the first differing stream or file between stage 2 and `CliApp.Run`, both shown masked.

### Proof notes (proposed)
`BAYAN_LAW_TIER` unset = a seeded subset per command (at least one row per command); `full` = every row, as L018/L023 do. The `check:` line stays `dotnet test -v q --filter "Law=L028"`.
