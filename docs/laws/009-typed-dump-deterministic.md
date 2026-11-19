---
id: L009
title: The typed dump is deterministic
status: enacted
release: 0.1.0
sources: none recorded
kind: property
scope: csharp/Bayan.Semantics/Binding/TypedDump.cs
proof: src/driver/golden.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'typed/' --only 'typed-dump/'
enacted: 2026-10-21
---

## Statement
For every program, the typed dump (`bayan types`) is byte-identical across two runs, and across a run on a copy of the program in another directory with the same relative path. Spec 010 builds the binder-equivalence law on it.

## Counterexample looks like
Two runs of `bayan types` on the same file whose dumps differ in the order of functions or bindings (a hash-set iteration leaking into the output), or a dump of a copy under another directory whose `path` fields carry the absolute directory.

## Proof notes
`csharp/tests/Bayan.Tests/TypedDumpTests.cs`, theory `DumpIsDeterministic` tagged `[Trait("Law", "L009")]`, runs once per case in `tests/cases/typed/*.byn` and `tests/cases/run/*.byn` (77 cases on 2026-10-21: 5 typed, 72 run). Each dump is a fresh `Compilation.FromPath` of the file by absolute path, as `bayan types file.byn` does for a script, so source paths are absolute and reach `TypedDump.PathOf`; the case is dumped twice in place and once from a copy at `tmp/l009/<guid>/<same repo-relative path>`, and all three must be equal. A multi-module case (a subdirectory with `main.byn`) is compiled as a whole directory and copied with its directory; none exist today. A case with errors would be compared all the same, since `TypedDump.ToJson` accepts any compilation; measured 2026-10-21, all 77 compile without errors. Mutation: writing `fn.File!.Source.Path` instead of `PathOf(c, ...)` in `TypedDump.cs` made all 77 cases fail; restored. Limits: the cases are the golden corpus, not generated programs; imports of sibling directories outside the case directory are not copied.

Proof 2026-11-19 (spec 019 T30f): the proof is the `typed-dump` kind of the golden runner, `goldenDeterministic` in src/driver/golden.byn, run by `bayan test tests/cases --only 'typed-dump/'`: one case per tests/cases/typed and tests/cases/run case (371: 18 typed, 353 run, one of them the multi-module run/alias-field-default-import), each dumped twice in place and once from a copy at tmp/l009/<case>/<repo-relative path> (a multi-module case with its directory), as `DumpIsDeterministic` does; every pair of the three is compared and a differing pair is named with its first differing line. As in the C#, each dump is `semantics.fromPath` of the absolute path and a case with errors is dumped all the same; the `typed/` cases keep their comparison with the frozen `.types`. The `bayan types` fact of TypedDumpTests is the cli case cli/TypedDumpTests/SelfHostSymbolTablesTypesAreByteIdentical, expected output from the v0.3.2 C# CLI. Broke it by writing `let shown = path` in `t26PathOf` (src/semantics/typed.byn), the counterpart of the C# mutation above: 370 of 371 failed (`failed typed-dump/run-arithmetic`, `dump 1 (in place) and dump 3 (copy at …/tmp/l009/run-arithmetic/tests/cases/run/arithmetic.byn) differ at line 5`), run/test-output.test passed (compiled without its test blocks, as the C# does, its dump lists no function), and the 18 `typed/` cases passed, since they compile by bare file name; restored. Measured on macOS arm64: the `--only 'typed-dump/'` run takes about 5 s.
