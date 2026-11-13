# 009 — Prebuilt runtime object and the C compiler's identity in the program key

Status: approved by the user 2026-11-13. Measurements: tmp/bench (m1–m3), summarised below.

## Why

Every program build compiles `bayan-rt.c` again with the program's `main.c`. Measured on mb1 (zig 0.17.0, fresh directory and `-ffile-prefix-map` per build as `Toolchain.Compile` does, so zig's own cache misses as it does in Bayan):

| | builds | today (-O2, main.c + bayan-rt.c) | prebuilt `bayan-rt.o` (-O2), main.c -O2 |
|---|---|---|---|
| 30-program sample, 5 rounds, median per build | 150 | 0.692 s | 0.179 s |
| corpus, 1204 programs under 1 MB of C, mean | 1204 | 0.752 s | ~0.18 s (sample) |
| corpus, 92 programs over 1 MB (compiler-sized), mean | 92 | 19.8 s | unchanged (main.c dominates) |

So for the whole corpus (1296 buildable programs, 27 more fail to build under every variant) zig time drops from 2724 s to about 2030 s (−25%), all of it in small programs, which are most test builds. The binaries stay -O2 throughout; only where the runtime is compiled changes. Separately, spec 020's review found that the program key holds the C compiler's command but not its identity, so an in-place zig upgrade can reuse stale binaries; the user decided 2026-11-13 to add it (spec 020 decision 5). Both change the program key, so they land together and cost users one cold rebuild, not two.

## Approach

1. **Runtime object cache.** Beside `programs/`, the cache gets `runtime/<rkey>/bayan-rt.o` (+ `.sha256`, as programs have). `rkey` = hash of the compiler identity, the compiler command, every flag of the build except the program's own inputs, the target, and `bayan-rt.h` + `bayan-rt.c`. A miss compiles the runtime once with `-c` in a staging directory (`-ffile-prefix-map`, same flags as today) and renames it in, with the same race rule as programs (the loser uses the winner's entry). A program build then compiles `main.c` and links the object: `… main.c <cache>/runtime/<rkey>/bayan-rt.o -o program -lm`.
2. **Compiler identity.** `CompilerIdentity` = the output of `<compiler> --version` (for zig: `zig version`) plus the SHA-256 of the resolved compiler executable, computed once per process. It joins the program key, the script key and `rkey`.
3. **Same in both compilers.** The C# (`Toolchain.cs`) and the self-hosted driver (`selfhost/driver/cache.byn` `t9Key`/`t9Compile`, `cc.byn` `ccArguments`, which port it) change in one branch, landed through `scripts/selfhost/land.sh` with the C# as the oracle; `bootstrap/bayan.c` is regenerated. The C#-vs-stage-2 tests that compare built bytes (`SelfhostDriverGoldenTests.cs:878`) must keep passing: both sides link the same object in the same order.
4. **Bounds** (docs/memory-leaks.md): `runtime/` is part of the existing cache cap and LRU eviction (one entry per flag set and target, a handful in practice), its staging is swept with the program staging, and `bayan clean --cache` removes it.
5. **Not changed:** optimisation levels, sanitizer builds (`-fsanitize=address` builds keep one compile step: the runtime must be instrumented too, so ASan gets its own `rkey` with the ASan flags, same mechanism), cross builds (same mechanism, target in `rkey`).

## Changes by area

- `src/Bayan.Backend.C/Toolchain.cs` — `CompilerIdentity`; `rkey`; `RuntimeObject(...)` lookup/compile; `Compile` links the object; keys gain the identity; eviction and sweep cover `runtime/`.
- `selfhost/driver/cache.byn`, `selfhost/driver/cc.byn` — the same, ported line for line with `// Toolchain.cs:<line>` cites.
- `bootstrap/bayan.c` — regenerated.
- Tests (`tests/Bayan.Tests`): runtime object reused across two programs (one `-c` call, counted with a logging `BAYAN_CC` wrapper); a damaged `bayan-rt.o` is discarded and rebuilt; a changed compiler identity misses every key; two concurrent builds race for one `rkey`; ASan and cross builds get their own object; eviction removes `runtime/` entries; `bayan clean --cache` removes it; stage-2 parity for each of these.
- `docs/bayan-handoff.md` — Progress log; CHANGELOG `[Unreleased]`: "builds compile the runtime once per toolchain and flag set; the cache key includes the C compiler's identity (one cold rebuild after upgrading)".

## Risks

- **Link order or symbol differences** between one-step and two-step builds: covered by the run corpus (outputs and exit codes) and the parity tests; m2 found identical outputs on 30 of 30 (at -O0 vs -O2; one-step vs two-step at -O2 is checked by the corpus runs in the suite).
- **`BAYAN_CC` set to something that is not a compiler driver** (a wrapper script): `--version` may fail; then the identity is the hash of the wrapper file plus its arguments, and the build goes on.
- **LTO-style cross-unit inlining** of runtime functions into `main.c` is lost at -O2. Not measured; the run corpus timings in the suite show it if it matters.

## Coverage

Program key, script key, runtime key, both compilers, bounds, clean, ASan, cross, parity: each has a test above.
