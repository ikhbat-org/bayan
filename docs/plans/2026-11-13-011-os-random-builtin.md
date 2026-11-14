# 011 — `Io.randomU64`: OS random for unique cache names

Status: done (1d6d190c).

Approved by the user 2026-11-13 ("Builtin first"), as an A1 exception like Q1042/Q1111.

## Why
The driver's `t9Unique` (selfhost/driver/cache.byn:169) stands in for `Guid.NewGuid()` with `{Time.now().nanos}-{Io.monotonicNanos()}-{d.uniques}`. On macOS both clocks tick in microseconds and `d.uniques` starts at 0 in every process, so two processes can build the same staging name. Plan 009's stage-2 race test (`ParallelBuildsNeverCorruptTheCache`, runtime count) fails 3 of 6 runs with "cannot write the build output or cache" or a leftover `v1/tmp` directory. Q1149 (1) says processes collide "only with the same nanosecond on both clocks", which is wrong on macOS.

## Approach
1. **Builtin.** `u64 Io.randomU64() uses random`: 8 bytes from the OS CSPRNG, the same source as the runtime's hash seed (`byn_os_random` in the runtime: `getrandom` on Linux, `arc4random_buf` elsewhere on POSIX, `BCryptGenRandom` on Windows; failure panics as today). If `u64` is not a primitive the builtins can return, use `i64` and say so in the progress log. No new diagnostic.
2. **Both compilers.** C#: `Symbols.cs` enum, `Builtins.cs` (`Make`, property, `"randomU64"` lookup), `EffectAnalysis.cs` (`["random"]`), the BYN suggestion list in `BinderExpressions.cs:693`, `CEmitter.cs`, and the runtime (`src/runtime/bayan-rt.c`/`.h`; plan 006 W1 rules and `libc-uses.txt` rows if a new libc call appears). Self-hosted: `selfhost/semantics/builtins.byn` and the emitter sites that handle `monotonicNanos`, ported with `// <File>.cs:<line>` cites, plus `selfhost/driver/runtime.byn` if the runtime text is mirrored there. `bootstrap/bayan.c` regenerated (`BAYAN_UPDATE=1 nice dotnet test -v q --filter FullyQualifiedName~BootstrapTests`).
3. **Use it.** `t9Unique` appends `Io.randomU64()` (hex or decimal) to its name and declares `random` in its `uses`; callers' effect lists follow. Q1149 (1) is updated: names now carry 64 OS-random bits.
4. **Docs.** Spec: the std builtin list gains the line; handoff: a new Question recording the A1 exception and decision, Q1149 (1) amended, Progress log entry; CHANGELOG `[Unreleased]`.

## Tests
- `tests/cases/run/io-random-u64.byn` (+ expected): two calls differ, prints a fixed line (never the value).
- A `diag/` case only if a new diagnostic appears (none expected); calling it from a function without `uses random` gives the existing effect diagnostic — add a `diag/` case for that.
- Self-hosted parity: the existing semantics/emitter corpus parity and golden tests pass with the new case; expected values from the C# run.
- Driver: a stage-2 test that `t9Unique`-named staging directories of two driver processes started together differ (or the plan 009 race test once merged); at minimum `SelfhostDefaultT9Tests` stays green.
- Break-test each new test (break, see it fail, `git checkout --`).
- Filters: `FullyQualifiedName~Golden|FullyQualifiedName~Effect|FullyQualifiedName~SelfhostDefaultT9|FullyQualifiedName~BootstrapTests|FullyQualifiedName~Selfhost` subsets, nice. The full suite (sharded, VM + wp1) is run by the lander after the gate, not a gate criterion.

## Risks
- Entropy failure panics (same as the hash seed today).
- WASI/other targets: follow whatever `byn_os_random` already does.
