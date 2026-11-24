---
id: L020
title: A normal build's generated C is byte-identical with or without the test tooling
status: enacted
release: 0.1.0
sources: none recorded
kind: property
scope: csharp/Bayan.Backend.C, csharp/Bayan.Lowering
proof: src/driver/golden.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'emit/'
enacted: 2026-10-31
---

## Statement
For every program, a normal build's generated C is byte-identical with or without the tooling (spec 013 R11). A normal build is one without `--coverage` and without `--mutate`.

## Counterexample looks like
A program whose generated C from a build without `--coverage`/`--mutate` differs by any byte from the C the compiler generated before the tooling was added (the pre-013 golden).

## Proof notes
Enacted by the agent on the user's instruction ("Enact on my behalf", 2026-10-31). Proof owed by spec 013 T23.
Proof 2026-11-01: broke it by adding a space to the generated C header comment in CEmitter; the test failed with `golden mismatch ... run-c.sha256, first difference at line 1` (run/arithmetic.byn). The golden is compared whole, so a run/ case missing from it also fails.
Proof 2026-11-19 (spec 019 T31b): the proof is the `emit/run-c` case, emit/run-c.sha256 checked by `goldenEmit` in src/driver/golden.byn, the port of `PlainBuildEmitsTheSameC`. Broke it by adding a space to the emitted C header comment (src/emitter/cprint/program.byn); `emit/run-c` failed at `expected line 1` (run/alias-field-default-import/main.byn). `--only 'emit/zzz-nomatch'` exits 2.
