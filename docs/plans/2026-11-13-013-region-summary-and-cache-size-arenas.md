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
- **Fix 1: a fresh arena around each `Regions` run in `summarizeRegions`.**
  - Before the region, the loop reads the known summary lengths.
  - Inside it, it runs `runRegions` and copies `r.pairs` and `r.returns` into lists declared *before* the region, and only when a length differs.
  - Why those lists are safe: a `List` keeps the allocator it was created with (`byn_list_reserve(..., l->alloc)`, `bootstrap/bayan-rt.c:2317`), so appends inside the region grow them in `General`. `StorePair` and the ids are plain data.
  - After the region, the loop stores the copies into `c.storeSummaries`/`c.returnSummaries`, exactly as today.
  - `fieldLocal` (`region2.byn:679`) appends to `c.locals` during summary runs. That append also grows with `c.locals`'s own allocator, and the `LocalSymbol` holds a name taken from `c.fields`, so nothing in it lives in the arena and LocalIds don't change.
  - Diagnostics are not written in summary mode (`regionReport` returns on `r.summary`, `region2.byn:1011`).
- **Fix 2: a fresh arena around each file read** in `cacheStats` and `t9Evict`. Only the `i64` length leaves it.
- The output stays byte-identical to the C#: same computation, same order, same LocalIds. The C# is untouched (the GC already frees).
- `bootstrap/bayan.c` is regenerated, as for every `selfhost/` change.
- Out of scope: the per-function analyses loop (about 220 MB), emit (about 300 MB; `newTemp` appends and the C text must leave), `analyzeEffects` (about 67 MB), and a real `Fs.size` (Q1148).

## Tests
- `SelfhostDefaultBoundsTests`, check bound: `Stage2Executable()` runs `check --package selfhost selfhost/driver` with a fresh `BAYAN_CACHE`, through `PeakSampler.Run`.
  - Assert exit 0, `Peak > 0`, and peak under a bound of 3× the larger after-fix figure (macOS, VM), rounded up.
  - Break-test: revert fix 1, and the peak goes back above 2.4 GB.
- `doctor` bound: a fresh `BAYAN_CACHE` holding a 256 MB file under `v1/programs/x/`. `doctor` must stay under a bound set the same way (before the fix: about 2× the file size).
  - Break-test: revert fix 2.
- The parity suites stay green: `BootstrapTests` (stage fixpoint, C# emit equals stage 1), `SelfhostDefaultT5Tests` (doctor), `SelfhostDefaultT9Tests` (evict), and the semantics/region goldens.

## Verification
1. The new bound tests, and the classes above, pass on mb1.
2. Max RSS before and after for `check` and `build` on `selfhost/driver`, and for `doctor`, recorded here and in `docs/memory-leaks.md` (Q31 row).
3. The two-slot VM run (`shard-test.sh --host vm=0.91:2:4`): both slots finish, 0 failed.
4. `laws-check.js --run`, `structure-audit.js`, a review worker, then a `--no-ff` merge to dev, unpushed. This is the same land.sh deviation as plans 009, 011 and 012: specs.tsv has no row for this plan.
