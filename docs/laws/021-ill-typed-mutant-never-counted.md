---
id: L021
title: A mutant that does not type-check is never counted as killed or survived
status: enacted
release: 0.1.0
sources: none recorded
kind: property
scope: csharp/Bayan.Testing
proof: csharp/tests/Bayan.Tests/NotEmittedLawTests.cs
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only '/l021-'
enacted: 2026-10-31
---

## Statement
For every run, a mutant that does not type-check is never counted as killed or survived (spec 013 R4). Such a mutant, including one whose enclosing statement fails re-binding or the ownership check, is counted "not emitted".

## Counterexample looks like
A mutation report that lists a mutant as killed or survived whose mutated statement, compiled on its own, gives a binding or ownership diagnostic.

## Proof notes
Enacted by the agent on the user's instruction ("Enact on my behalf", 2026-10-31). Proof owed by spec 013 T25.
Proof 2026-11-01: broke it by making Schemata.Rebinds return true, failing with `seed 1: ... does not type-check but is emitted`; and by deleting the `!site.Emitted` line in MutationRunner, failing with `... is not emitted but reported NotReached`.
