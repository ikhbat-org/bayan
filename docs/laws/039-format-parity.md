---
id: L039
title: Format parity
status: retired
release: unscheduled
sources: spec 022 R5
kind: property
scope: src/driver/**, csharp/Bayan.Cli/Format.cs
proof: src/tests/SelfhostDriverTests.cs
check: dotnet test -v q --filter "Law=L039"
---

## Statement
For every argument list and input tree of `bayan format` (with and without `--check`), the self-hosted driver's exit code, stdout and stderr equal the C# CLI's, byte for byte, and so do the files it writes.

## Counterexample looks like
An argument list and a tree of input files, with the first stream or file that differs between the self-hosted driver and `CliApp.Run`.

## Proof notes
Not proven. `SelfhostDriverStage2FormatTests` compares the two on the style cases and on the sources; it does not carry the `Law=L039` trait. `/prove` writes the test.

## History
Retired unenacted 2026-11-18 (owner, on Fable's recommendation): without the C# CLI the statement reduces to "format cases match their frozen files", which the golden runner and L043 already hold. L038 carries the formatter property.
