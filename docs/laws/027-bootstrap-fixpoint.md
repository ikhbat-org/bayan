---
id: L027
title: Bootstrap fixpoint
status: enacted
release: 0.2.0
sources: none recorded
kind: property
scope: src/driver/**, src/emitter/**, src/semantics/**, bootstrap/bayan.c
proof: csharp/tests/Bayan.Tests/BootstrapTests.cs
check: bash scripts/ci/bootstrap-check.sh
timeout: 900
---

## Statement
For the driver's sources and each of `safe` and `debug`, the C stage 1 emits and the C stage 2 emits are byte-identical, and contain no absolute path and no timestamp, all stages built on the same host; this becomes a no-.NET check once T31 lands. For the frozen tree, the C the C# compiler built from the frozen ref emits is byte-identical to that C too; this half runs in the ddc job against the frozen ref (`v0.3.2` until `csharp-final` exists).

## Counterexample looks like
A mode and the first differing byte offset between two stages' emitted C (for example stage 1 vs stage 2 in `debug`), with the C# source line each side came from; or an absolute path or timestamp found in one stage's C.

## Proof notes
Cross-host byte identity for the same `--target` is a tracked future strengthening, not part of L027. Approved by the user 2026-11-05 with this wording (012-spec.md, Law candidates). Enactment is the user's edit of `status:` (012 T11).

## History
Amended 2026-11-18 (spec 019 D8): the statement covers the frozen tree; the C# half moves to the ddc job. The `check:` stays until T31 swaps it. L045 is retired in its favour.
