---
id: L024
title: Emitter equivalence
status: enacted
release: 0.2.0
sources: Q890
kind: property
scope: src/emitter/, csharp/Bayan.Lowering/, csharp/Bayan.Backend.C/CEmitter.cs
proof: src/driver/golden.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'emit/'
timeout: 300
enacted: 2026-11-04
amended: 2026-11-20
---

## Statement

For every emit case in the freeze manifest, `bayan-emit` prints C whose SHA-256 equals the frozen hash in `tests/cases/emit/run-c.sha256`, in the mode the input's `// mode:` line names. The frozen files are the C# compiler's output at the freeze (L043).

Dropped from the statement in force before 2026-11-20: the 010 generator's well-typed programs on the fixed seeds, and every `BuildMode` for each input. The frozen cases are the `tests/cases/run/` inputs, each as one hash in the mode its `// mode:` line names, and the C# backend that produced the other texts is gone. The `*.test.byn` inputs are among the hashed inputs.

## Counterexample looks like

An input, a mode and the first line where the two outputs differ:

```
run/closures.byn (safe): line 212
  C#:    bynt_tup2_i64_str t3 = ((bynt_tup2_i64_str){a, b});
  Bayan: bynt_tup2_i64_str t3 = ((bynt_tup2_i64_str){ a, b });
```

Or a generated program (seed and mode) on which one backend prints and the other reports an error.

## Proof notes

The test builds `bayan-emit` once in `fast` mode (`SelfhostEmitterHarness.Build`), runs it as a
process on each corpus input, and compares with `CliApp.EmitC(Compilation.Create([source], dir), mode)`
in memory, or for `*.test.byn` with what `ExecuteTests` builds. `BAYAN_LAW_TIER` unset runs the fixed quick subset (every `run/` input plus the first N
seeds, N measured at T14 to fit about 3 minutes and written here); `BAYAN_LAW_TIER=full` runs every seed. A
difference fails naming the input, the mode and the first differing line. Mutant and coverage output
(`--mutate`, `--coverage`) is outside the law: only the C# backend produces it (spec 011, non-goals).

Proof (T14): `SelfhostEmitterEquivalenceLawTests.BayanEmitEqualsTheCSharpBackendOnSeedsAndRunInputs` (`Law=L024`) takes its modes from `Enum.GetValues<BuildMode>()` and runs
`bayan-emit --mode m --many <dir>` once per corpus and mode and compares each `== name` section with the C# text.
Seeds: the generator's 8 fixed seeds then a xorshift64 chain from the first, N = 256 (quick; `GenerateValid` writes 15 feature programs and 3 per seed, so 2,632 comparisons in about 15 s) or 1,024 (`BAYAN_LAW_TIER=full`, 9,544 comparisons in
65 s on 2026-11-04). The flat `run/` inputs are in the mode of their `// mode:` line, the `*.test.byn` ones in `safe`
through `TestRunC`. The R6 break-test is `ADeliberateChangeToTheCSharpTextFailsAtLeastOneSeed` (a dropped
`(int64_t)` cast and two swapped struct field lines in the C# text); `BAYAN_L024_BREAK=cast|fields` applies the same
change inside the law test, which then fails.

Enacted by the agent under the standing self-host authorization (2026-10-21; decisions 2026-11-03: the agent enacts L024/L025 after proof; spec 011 T17), with T14's proof passing: `dotnet test -v q --filter "Law=L024"` 1 passed (`SelfhostEmitterEquivalenceLawTests.BayanEmitEqualsTheCSharpBackendOnSeedsAndRunInputs`) on 2026-11-04, 47 s test time (55 s wall; both include rebuilding `bayan-emit`, quick tier). The app `CacheTests.cs:192` passes to `--emit-c` (the `bayan new` template) is not in this law's corpus, which is only the generator seeds and the `tests/cases/run/` inputs (Q890).

Proof 2026-11-20 (spec 019 T31): the proof is the `emit/run-c` case, `goldenEmit` in src/driver/golden.byn (tagged L024): the C of each of the 353 `tests/cases/run/` inputs in its `// mode:`, hashed and compared with tests/cases/emit/run-c.sha256. `emit/` does not match `emit-c/`; a selector that matches nothing exits 2. The check printed `1 passed · 0 test blocks, 1 golden case`. Broke it by dropping the blank line after the `#include` lines (src/emitter/cprint/program.byn:78, `<stdlib.h>\n\n` to `<stdlib.h>\n`), driver rebuilt by stage 1: `emit/run-c` failed at `expected line 1: f53fac6f…  run/alias-field-default-import/main.byn`, `actual line 1: 7399cc69…`; the file was restored from HEAD.
