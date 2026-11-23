---
id: L007
title: An Untrusted value never reaches a command-running API unchecked
status: enacted
release: 0.1.0
sources: none recorded
kind: guard
scope: csharp/Bayan.Semantics/Binding/BinderCalls.cs
proof: src/driver/goldenexport.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only '/l007-'
enacted: 2026-10-21
---

## Statement
A call to `Io.runBatch`, `Io.run` or any other API that runs a command, where any argument (the program or path, or an element of the argument list) has type `Untrusted<T>` or holds one, is rejected at compile time with the taint-sink diagnostic (BYN2786). The same call with each such argument validated or wrapped in `trust(…, reason:)` compiles.

## Counterexample looks like
`Io.runBatch(".\\build.cmd", [name])` or `Io.run("git", [name])` that compiles when `name` is `Untrusted<string>`, or `Io.run("git", [trust(name, reason: "checked against the branch list")])` that is rejected.

## Proof notes
`csharp/tests/Bayan.Tests/L007UntrustedSinkTests.cs`, tagged `[Trait("Law", "L007")]`, runs 12 rows against both `Io.run` and `Io.runBatch` (24 cases) through `Compilation.Create`. Rejected with BYN2786 naming the API: an untrusted program or path, an untrusted element in a list literal, a `List<Untrusted<string>>` variable as the arguments, and a span of them. Accepted: each of those with `trust(…, reason:)`, and plain values. A struct holding an `Untrusted` field is rejected with BYN2202 rather than BYN2786, because a struct never converts to `string`; the table asserts that. Break-test: dropping `Io.run` from the sinks fails its 6 BYN2786 rows.

Proof 2026-11-19 (spec 019 T31b): the proof is the 24 exported cases cli/L007UntrustedSinkTests/l007-* (12 rows for `Io.run` and for `Io.runBatch`, each `bayan check`), expected output from the v0.3.2 C# export, run by `goldenCli` in src/driver/goldenexport.byn (the L006–L016 comment block); warning text is now compared too. Broke it by removing `Io.run` from `b.sinkArgument` (src/semantics/calls.byn): 6 of 24 failed, e.g. `l007-io-run-list-of-untrusted-as-args`.
