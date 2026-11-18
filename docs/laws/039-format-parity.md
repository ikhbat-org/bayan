---
id: L039
title: Format parity
status: proposed
release: unscheduled
sources: spec 022 R5
kind: property
scope: src/driver/**, csharp/Bayan.Cli/Format.cs
proof: src/tests/SelfhostDriverTests.cs
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'cli/format'
---

## Statement
For every argument list and input tree of `bayan format` (with and without `--check`), the self-hosted driver's exit code, stdout and stderr equal the C# CLI's, byte for byte, and so do the files it writes.

## Counterexample looks like
An argument list and a tree of input files, with the first stream or file that differs between the self-hosted driver and `CliApp.Run`.

## Proof notes
Not proven. `SelfhostDriverStage2FormatTests` compares the two on the style cases and on the sources; it does not carry the `Law=L039` trait. `/prove` writes the test.
