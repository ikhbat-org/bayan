---
id: L025
title: No emitter panic
status: enacted
release: 0.2.0
sources: Q662, Q663, Q890
kind: property
scope: src/emitter/
proof: src/driver/nopanic-l025.test.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'L025:'
timeout: 1200
enacted: 2026-11-04
---

## Statement

For every program in the corpus (every `tests/cases/run/` input, among them `run/hello.byn`
(byte-identical to `examples/hello/main.byn`, which `CliTests` passes to `--emit-c`), and the 010 generator's programs on the fixed seeds, well-typed or
corrupted) and every `BuildMode` (`debug`, `safe`, `fast` today), `bayan-emit` terminates and each input exits 0 or 1:
it never panics, never exits through the runtime's trap paths, and no `bayan-emit --many` run (one mode, one batch) takes
longer than 120 s. Exit 2 is a usage error (`src/emitter/main.byn:29` `exitUsage`) and never occurs on file input.
Emitter coverage on valid programs comes from the well-typed seeds and the `run/` inputs; the corrupted copies reach the
emitter only where the C# checker still accepts them.

## Counterexample looks like

An input and mode on which `bayan-emit`'s stderr holds `panic:` or a runtime trap (overflow, bounds,
division by zero, invalid char), or whose exit code is outside {0, 1}, or a `--many` run that does not finish in 120 s:

```
seed 1187 (debug): exit 134
  panic: index 7 out of range for list of length 7 at src/emitter/cprint/expr.byn:410
```

## Proof notes

The same corpus runner as L024, checking only termination, exit code and the absence of a panic or
trap line on stderr; an input the checker rejects must exit 1 with bayan-check's diagnostics, which
L024 does not cover. Corrupted seeds come from the 010 no-panic test's corruption step so the two
laws share a generator. Quick and full tiers as L024 (`BAYAN_LAW_TIER`). Where a counterexample is
the C# front end's (a parser or binder panic reproduced by the imported checker), it is recorded as
L023's and does not count against this law, as L018/L023 do today (Q662, Q663). Enacted only after L018 and L023.

Proof (T14): `SelfhostEmitterNoPanicLawTests.BayanEmitNeverPanicsOnSeedsCorruptionsAndRunInputs` (`Law=L025`) runs
`bayan-emit --many` in the three modes over the tier's valid and faulty generator programs (N = 256 seeds quick,
1,024 full), 1,000 (full: 10,000) corrupted copies of the 8 fixed seeds' programs, and the flat `run/` inputs. It asserts
exit 0, no `panic:` on stderr, only `exit 1` lines, and for the seed programs that `exit 1` is printed exactly for the
inputs the C# checker rejects. The modes come from `Enum.GetValues<BuildMode>()`. Each `--many` run (a mode and a corpus) is waited
for 120 s, killed on a miss and fails naming the corpus and mode (`ARunPastItsBoundIsKilledAndNamed`); exit 2 for a run or an input fails the test.
The corrupted corpus is counted: inputs the C# checker accepts, so that they reach emission, number 51 of 1,000 (quick) and 533 of 10,000
(full), measured 2026-11-04; the test fails below a floor of 45 (quick) and 500 (full). Measured 2026-11-04 the whole test takes 21 s quick and 80 s
full (the C# checker over the corpora included); the 20 s and 58 s first noted were the earlier total. Per run (milliseconds, debug/safe/fast):
quick seeds 7127/3075/3100, corrupted 414/400/398, run 249/225/222; full seeds 17076/12205/12282, corrupted 3896/3772/3795, run 269/232/238,
so the figures are per run, never summed over modes, and the largest is 17 s against the 120 s bound. The worst case is 3 corpora x 3 modes x
120 s = 1080 s, so `timeout:` is 1200, not 300, to keep the whole-check limit above the per-run bounds. `laws-check.js --run` runs the quick tier
(`BAYAN_LAW_TIER` unset).

Enacted by the agent under the standing self-host authorization (2026-10-21; decisions 2026-11-03: the agent enacts L024/L025 after proof; spec 011 T19), after L018 and L023 were enacted, with T14's proof passing: `dotnet test -v q --filter "Law=L025"` 1 passed (`SelfhostEmitterNoPanicLawTests.BayanEmitNeverPanicsOnSeedsCorruptionsAndRunInputs`) on 2026-11-04, 47 s test time (55 s wall; both include rebuilding `bayan-emit`, which the Proof notes' 21 s quick figure does not). The app `CacheTests.cs:192` passes to `--emit-c` (the `bayan new` template) is not in this law's corpus, which is only the generator seeds and the `tests/cases/run/` inputs (Q890).

The paragraphs above are the C# proof's history (spec 019 T31c). Bayān port, 2026-11-19 (share S4): the test block `L025: …` in
`src/driver/nopanic-l025.test.byn` builds the stage-1 `bayan-emit` with `goldenProgram("emitter", …)`, writes three corpora under
`tmp/l025-nopanic/` and runs `bayan-emit --mode m --many <dir>` for m in debug, safe and fast over each: the 79 programs of the 8 fixed seeds
(L023's `l023SeedPrograms`, pinned to the C# `PinnedCorpus` hash; the C# 256/1,024-seed tiers are not ported, the statement names the fixed
seeds), the first 1,000 (quick) or 10,000 (`BAYAN_LAW_TIER=full`) inputs of L023's `l023Mutated` over those 79 programs with seed
0x9E3779B97F4A7C15, and the flat `tests/cases/run/*.byn` inputs (352). It asserts exit 0, no `panic:` on stderr, a section per input in
order, only `exit 1` lines, and that each run took at most 120 s; a run dying on a signal is narrowed to the input that dies alone and fails
naming it with its bytes. The C# checker oracle is replaced by the generator's names: a `fault-*` seed's section starts with `exit 1` and a
`valid-*` seed's does not. The floor is measured with the port's own checker, in each mode: corrupted inputs whose section has no `exit 1`
number 51 of 1,000 (quick) and 533 of 10,000 (full), the same as the C# counts of 2026-11-04; the floors stay 45 and 500. Measured
2026-11-19 (macOS, emitter already built): the block takes 4.0 s quick and 32.9 s full; per run (milliseconds, debug/safe/fast) quick seeds
149/127/124, corrupted 664/522/567, run 456/366/381; full seeds 308/161/228, corrupted 11475/6860/9079, run 447/423/340. A cold emitter build
adds about 40 s. The 120 s bound is measured after the run, not enforced by a kill: `goldenChild` keeps whole output only without a
`timeout:` (a timed run keeps 64 KiB of each end, too little for the section check), so a hung run is stopped by the test block's limit
(`BAYAN_TEST_TIMEOUT_MS`, 60 s by default). Break tests, each applied alone and undone: changing `src/emitter/main.byn:99` (`t12Finish`) so a
rejected input returns `exitUsage` fails the block with `L025 counterexample: seeds (debug): exit 2 after fault-MissingFails-000.byn in
…/tmp/l025-nopanic/seeds`; adding `panic("L025 break")` at the top of `emit` in `src/emitter/cprint/program.byn` fails it with
`L025 counterexample: seeds (debug): exit 134 on valid-constants.byn in …/tmp/l025-nopanic/seeds, bytes 636f6e73…` and `L025 break`.
