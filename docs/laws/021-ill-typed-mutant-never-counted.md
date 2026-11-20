---
id: L021
title: A mutant that does not type-check is never counted as killed or survived
status: enacted
release: 0.1.0
sources: none recorded
kind: property
scope: csharp/Bayan.Testing
proof: src/driver/mutate.test.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'mutator: a mutant that would not type-check'
enacted: 2026-10-31
---

## Statement
For every run, a mutant that does not type-check is never counted as killed or survived (spec 013 R4). Such a mutant, including one whose enclosing statement fails re-binding or the ownership check, is counted "not emitted".

## Counterexample looks like
A mutation report that lists a mutant as killed or survived whose mutated statement, compiled on its own, gives a binding or ownership diagnostic.

## Proof notes
Enacted by the agent on the user's instruction ("Enact on my behalf", 2026-10-31). Proof owed by spec 013 T25.
Proof 2026-11-01: broke it by making Schemata.Rebinds return true, failing with `seed 1: ... does not type-check but is emitted`; and by deleting the `!site.Emitted` line in MutationRunner, failing with `... is not emitted but reported NotReached`.
Proof 2026-11-19 (spec 019 T31b): the proof is the 8 `mutator: a mutant that would not type-check is counted not emitted` rows of src/driver/mutate.test.byn, which check `emitter.find`'s per-operator not-emitted counts against the C# literals (the port of `Mutator.Find`). The 300 seeded programs of NotEmittedLawTests are dropped: they use `System.Random`, and `bayan test --mutate` reports no per-mutant not-emitted count for a cli case to compare. `--only 'mutator: zzz-nomatch'` exits 2. The rebind break was not rerun in this part.
Break 2026-11-20 (spec 019 T31b, 019-t31b2): commenting out `w.notEmitted[mutatorStatement] += 1` for an assignment to an uninitialized local (src/emitter/schemata.byn:507) made the check fail 2 of 8, the two `op: "statement"` rows (`count: 1` and `count: 3`), exit 3; restored, 8 passed.
