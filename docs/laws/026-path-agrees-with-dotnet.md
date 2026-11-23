---
id: L026
title: Path agrees with .NET
status: enacted
release: 0.2.0
sources: none recorded
kind: property
scope: runtime/bayan-rt.c (byn_path_*), csharp/Bayan.Semantics/Builtins.cs (Path members), csharp/Bayan.Backend.C/CEmitter.cs (Path calls)
proof: csharp/tests/Bayan.Tests/StdPathLawTests.cs
check: bash runtime/tests/run.sh && bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'run/path'
timeout: 300
enacted: 2026-11-05
amended: 2026-11-20
---

## Statement

For every `run/path` case in the freeze manifest, the compiled Bayan program prints the frozen expected stdout byte for byte and, for the cases that hold them (`path-full-path-empty`, `path-relative-empty`, `path-relative-nul`), the frozen stderr and exit code. The frozen files are the C# compiler's output at the freeze (L043).

Dropped from the statement in force before 2026-11-20: the corpus is the fixed `run/path` cases, not a seeded one, and the clause that expected outputs are per host with .NET run on the same host. The frozen files are one set, so the `path-windows-*` cases are frozen output too. The clause that a .NET throw becomes a panic with a nonzero exit is kept through the three cases above, which record a nonzero exit code.

## Counterexample looks like
An input and function name, the Bayan output, and the .NET result (or exception) on the same OS, for example `directoryName("C:\\")` printing `C:\` where .NET returns null.

## Proof notes
`BAYAN_LAW_TIER`: unset runs a fixed seeded subset sized to about 3 minutes; `full` runs the whole corpus. The proof runs on macOS and on wp1, each against .NET on that host; no expected value is shared across hosts. Amended and enacted by the user 2026-11-05 ("agrees with .NET running on the same host"). It reuses the `StdPathTests` corpus generator and runs every function's whole corpus in one program per seed.
