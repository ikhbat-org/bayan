# Plan 013: arenas for the region-summary fixpoint and the cache size reads (Q31)

Approved by the user 2026-11-13 ("plan and implement" the remaining two-slot VM OOM: bootstrap stage-1 and `doctor` peaks), unattended.

## Context
Plan 012 fixed the `mutate` re-binds. The two-slot VM run on it still lost slot 1: a self-hosted `bayan` at 2.6 GB RSS was OOM-killed, alongside 4.8 GB of `zig` and two 1.2 GB `dotnet` hosts (unit peak 7.4 GB in an 11 GiB VM). A `debug` worker measured on mb1, using the stage-1 binary and `--package selfhost selfhost/driver`:

| Run | Max RSS |
|---|---|
| `build -o` | 2,981 MB |
| `build --emit-c --mode safe` | 2,938 MB |
| `check` | 2,629 MB |
| `doctor` with a 109.5 MB cache | 266 MB |
| `doctor` with an empty cache | 33 MB |

The worker also built early-exit compilers that stop at points inside `bindAll` (`selfhost/semantics/generics.byn`):

| Stopped | Peak |
|---|---|
| Before `summarizeRegions` | 381 MB |
| After `summarizeRegions` | 2,410 MB |

So about 2.0 GB comes from one function. The `doctor` peak is about 2× the cache size.

## Causes
1. **`summarizeRegions`** (`selfhost/semantics/region.byn:196`). Its fixpoint loop re-runs `runRegions` on every summarised function on every iteration. Each run builds a throwaway `Regions`, with borrow lists and maps per expression. Under `General` none of it is freed.
2. **`cacheStats`** (`selfhost/driver/cache.byn:60`) and **`t9Evict`** (`:657`). They read each cached file whole, only to take its `.length`. There is no size builtin (Q1148). `cacheStats` serves `doctor` and `cache`. `t9Evict` runs after every build.

## Approach
- **Fix 1: a fresh arena around each `Regions` run in `summarizeRegions`, after the first fixpoint pass.**
  - The first pass runs in `General`, as before. It fills `Ctx`'s lazy memo `changedFields` (`region2.byn:713`, written at `:751`), in today's order. An arena on the first pass freed memo entries that later passes read: ASan reported a use-after-free and stage 1 panicked with "index out of range". Later passes only read the memo, so each of their runs gets its own arena.
  - `t41SummaryRun` runs `runRegions` and copies `r.pairs` and `r.returns` into lists declared *before* the region, and only when a length differs.
  - Why those lists are safe: a `List` keeps the allocator it was created with (`byn_list_reserve(..., l->alloc)`, `bootstrap/bayan-rt.c:2317`), so appends inside the region grow them in `General`. `StorePair` and the ids are plain data.
  - After the region, the loop stores the copies into `c.storeSummaries`/`c.returnSummaries`, exactly as today.
  - `fieldLocal` (`region2.byn:679`) appends to `c.locals` during summary runs. That append also grows with `c.locals`'s own allocator, and the `LocalSymbol` holds a name taken from `c.fields`, so nothing in it lives in the arena and LocalIds don't change.
  - Diagnostics are not written in summary mode (`regionReport` returns on `r.summary`, `region2.byn:1011`).
- **Fix 2: a fresh arena around each file read** in `cacheStats` and `t9Evict`. Only the `i64` length leaves it.
- **Fix 3 (found by measuring): an arena inside `t1FileExists`** (`selfhost/driver/main.byn:293`). It ports `File.Exists` by listing the path and then reading the file whole, and `cacheStats` calls it on every cached file before the length read. Both results are discarded, so the arena frees them for every caller.
- The output stays byte-identical to the C#: same computation, same order, same LocalIds. The C# is untouched (the GC already frees).
- `bootstrap/bayan.c` is regenerated, as for every `selfhost/` change.
- Out of scope: the per-function analyses loop (about 220 MB), emit (about 300 MB; `newTemp` appends and the C text must leave), `analyzeEffects` (about 67 MB), and a real `Fs.size` (Q1148).

## Tests
- `SelfhostDefaultBoundsTests`, check bound: `Stage2Executable()` runs `check --package selfhost selfhost/driver` with a fresh `BAYAN_CACHE`, through `PeakSampler.Run`.
  - Assert exit 0, `Peak > 0`, and peak under a bound of 2× the larger after-fix figure (macOS, VM), rounded up; 3× would not separate from the before figure (Results).
  - Break-test: revert fix 1, and the peak goes back above 2.4 GB.
- `doctor` bound: a fresh `BAYAN_CACHE` holding 64 files of 4 MB under `v1/programs/x/` (one 256 MB file would measure one read's own peak, which no arena lowers). `doctor` must stay under a bound set the same way (before the fix: about 2× the cache size).
  - Break-test: revert fix 2, then fix 3, each alone.
- The parity suites stay green: `BootstrapTests` (stage fixpoint, C# emit equals stage 1), `SelfhostDefaultT5Tests` (doctor), `SelfhostDefaultT9Tests` (evict), and the semantics/region goldens.

## Verification
1. The new bound tests, and the classes above, pass on mb1.
2. Max RSS before and after for `check` and `build` on `selfhost/driver`, and for `doctor`, recorded here and in `docs/memory-leaks.md` (Q31 row).
3. The two-slot VM run (`shard-test.sh --host vm=0.91:2:4`): both slots finish, 0 failed.
4. `laws-check.js --run`, `structure-audit.js`, a review worker, then a `--no-ff` merge to dev, unpushed. This is the same land.sh deviation as plans 009, 011 and 012: specs.tsv has no row for this plan.

## Results
Max RSS of the stage-1 compiler built from the emitted C (`cc -O2`), on `--package selfhost selfhost/driver`. macOS: `/usr/bin/time -l` on mb1. Linux: `wait4` `ru_maxrss` on bayan-test01. "Before" is dev's `bootstrap/bayan.c` at c0f9f286.

| Run | macOS before | macOS after | Linux before | Linux after |
|---|---|---|---|---|
| `check` | 2,629 MB | 781 MB | 2,705 MB | 840 MB |
| `build -o` | 2,981 MB | 1,665 MB | | |
| `doctor`, 64 × 4 MB cache | 543 MB | 33 MB | 514 MB | 15 MB |
| `doctor`, empty cache | 33 MB | 33 MB | 3 MB | 3 MB |

- Bounds (`SelfhostDefaultBoundsTests`): check 1,700 MB, 2× the larger after figure. 3× (2,520 MB) would not separate from the before figure. Doctor 100 MB, 3× the larger, rounded up.
- Break-tests: each fix reverted alone fails its bound test (see the handoff entry).
- ASan (`-fsanitize=address`, stage 1 from the emitted C): `check` and `doctor` clean.
- `build` still peaks at 1.7 GB: the per-function analyses and emit stay in `General` (out of scope above).
- Two-slot VM run (`shard-test.sh --host vm=0.91:2:4`, b5b5705d): both slots finished, no self-hosted `bayan` was killed. vm1 5,468 passed, 0 failed. vm2 8,018 passed, 118 failed: the kernel OOM killer took a `zig` (2.6 GB anon RSS) compiling `selfhost/semantics` for `SelfhostSemanticsT17Tests`, with several other `zig` processes running at the same time. All 118 failures are that class's shared build. Alone on the VM (db4f3ca8): 118 passed, 0 failed. Verification step 3 is unmet because of `zig`'s own memory, which is outside this plan (`work/todo.md`).
