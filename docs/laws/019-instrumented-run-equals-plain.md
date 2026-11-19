---
id: L019
title: An instrumented run's output and exit code equal the plain run's
status: enacted
release: 0.1.0
sources: none recorded
kind: property
scope: csharp/Bayan.Backend.C, csharp/Bayan.Lowering (coverage counters, mutant schemata)
proof: src/driver/l019.test.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'L019:'
enacted: 2026-10-31
---

## Statement
For every program, the instrumented run's output and exit code equal the plain run's (spec 013 R10). Instrumented means built with `--coverage` or `--mutate` and run with no mutant selected.

## Counterexample looks like
A `tests/cases/run/` program whose stdout, stderr or exit code differs between `bayan run` and the same program built with coverage counters or mutant schemata and run with `BAYAN_MUTANT` unset or `0`.

## Proof notes
Enacted by the agent on the user's instruction ("Enact on my behalf", 2026-10-31). Proof owed by spec 013 T21.
Proof 2026-11-01: broke it by making the coverage counter writer print a byte to stdout; the test failed with `run/arithmetic.byn, --coverage, BAYAN_COVERAGE set: differs from the plain run in stdout`.
Proof 2026-11-19 (spec 019 T31b): the proof is the `L019:` test block of src/driver/l019.test.byn. Each `run/*.test.byn` case (4 at this date) is built by `bayan test`, `bayan test --coverage` and `bayan test --mutate` as a one-module package, and every test of the plain binary (`--test i`) is compared with the `--coverage` binary (BAYAN_COVERAGE unset and set) and the `--mutate` binary (BAYAN_MUTANT unset and `0`) over stdout, stderr and exit code. The block also asserts that the coverage build wrote a counter file. Plain `run/*.byn` cases are not covered: `bayan build` has no `--coverage` or `--mutate`. About 10 s per run. Broke it by making the coverage counter writer print `x` to stdout; the block failed with `L019 counterexample: run/assert-fails.test.byn, test 0, --coverage, BAYAN_COVERAGE set: differs from the plain run in stdout`. `--only 'L019:zzz-nomatch'` exits 2.
