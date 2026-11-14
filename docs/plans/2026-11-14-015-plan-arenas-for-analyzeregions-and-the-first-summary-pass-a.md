# Plan: arenas for `analyzeRegions` and the first summary pass; a cheaper `sweepStale` (Q31, `build` peak)

## Context
`work/todo.md:772` and the `docs/memory-leaks.md` Q31 row say the self-hosted `build` of the driver "still peaks at 1.7 GB". A `debug` worker measured it on 2026-11-14 (mb1, stage 1 from `bootstrap/bayan.c`, `cc -O2`, `--package selfhost selfhost/driver`, fresh `BAYAN_CACHE`).

**The 1.7 GB is the `zig cc -O2` child, not bayan.** `/usr/bin/time -l` reports the largest RSS of the process or any child, so the figure is zig compiling the 11.4 MB C file (1,663 MB). With a fake zig, bayan alone peaks at 1,074 MB. bayan keeps that memory while zig runs, so the host carries about 2.7 GB at once. That combined figure is what this plan lowers.

| Phase (stop point) | Increment |
|---|---|
| parse | 114 MB |
| bind (`generics.byn:183`) | 164 MB |
| `analyzeEffects` | 62 MB |
| `summarizeRegions`, first pass (still in `General`) | **169 MB** |
| per-function loop: `analyzeRegions` (`generics.byn:227`) | **188 MB** |
| `t6EmitFunction` loop (`cprint/program.byn:19`) | 175 MB |
| C text assembly, `t6ResolveResets` | about 70 MB |
| `sweepOnce` (`cache.byn:330`; this host's `$TMPDIR` has 110,784 entries) | 37 MB |

Fable verified this plan against the code (2026-11-14). Its 8 corrections are applied: summary runs do reach the memo, Fix 2 must clear `pairs`/`returns`, the bound rule changed, the instance call site stays in `General`, and the rollback break-test is ASan-only.

In the worker's prototype, all three placements below brought `build` (bayan alone) from 1,074 to 698 MB and `--emit-c` from 1,076 to 677 MB. The C stayed byte-identical to `bootstrap/bayan.c`, and the ASan run on the driver was clean. Its `analyzeRegions` arena was safe only by luck: it filled the `changedFields` memo and could add diagnostics inside the arena. The driver happens to report no region diagnostics.

## Approach
Each fix gives one run its own arena. Only plain data (ids, lengths, bools) leaves the arena, or values copied into lists created before it. A `List` or `Map` keeps the allocator it was created with (`bayan-rt.c` `byn_list_reserve(..., l->alloc)`), so appends grow in `General`. Anything *created* inside the arena and stored in `Ctx` would dangle (plan 013's first attempt: an ASan use-after-free).

### Fix 1: `analyzeRegions` in an arena, rolled back if anything lasting was written
A reporting `runRegions` can write three lasting things into `Ctx`:
- **Diagnostics** (`regionReport`, `region2.byn:1010-1032` → `addDiag`, `diag.byn:31`). The message strings are made in the current allocator.
- **The `changedFields` memo** (`region2.byn:751`; reached only from reporting runs, `:65-66`). Its value lists are made in the current allocator.
- **`c.locals` appends** from `fieldLocal` (`region2.byn:679`). These are plain data, but they assign LocalIds.

Do not warm the memo ahead of time, as the worker proposed. Visiting in another order changes the Tarjan root, and with it the field order of a multi-method component's set. `for field in fields` (`:67`) then calls `fieldLocal` in that order, so LocalIds and mutation order could drift from the C#.

New helper `t42RegionsRun(ref c, for fn)`, named on the file's `t41` pattern. Used only at `generics.byn:227`, the template loop, where `c.sink == -1`.
- The other call site, `generics.byn:799` inside `t13AnalyzeInstance`, stays in `General`. It runs with `c.sink >= 0` and measured 0 MB.
- No bag snapshot is needed.

Steps:
1. Before: record `c.diagnostics.length`, `c.locals.length` and `c.changedFieldsLog.length`.
2. Run `analyzeRegions` inside `using let arena = Arena()` / `provide allocator: arena { … }`.
3. Check whether any diagnostic or memo entry was added.
   - If so, undo: truncate `c.diagnostics` and `c.locals` to their snapshots (`remove(from:until:)`, `builtins.byn:584-593`), remove each memo key in the `c.changedFieldsLog` tail (`Map.remove`, `:625`), then truncate the log.
   - Nothing is freed on removal: list remove is a `memmove`, map remove a tombstone, and `byn_alloc` has no free. So the undo is safe inside or after the block. Nothing iterates `c.changedFields` (only `contains`/index at `region2.byn:713-751`), so the re-added keys are unobservable.
4. If it was undone, run `analyzeRegions` again in `General`.
   - The memo and locals are back to their earlier state, so the rerun does what today's code does, in today's order, with the same LocalIds.

`c.changedFieldsLog: List<FuncId>` is a new `Ctx` field. `Ctx` binds its lists' allocator at construction, so the log lives in `General`. It is appended at `region2.byn:751` beside the memo write. It is selfhost-only (no C# twin), with a doc comment naming Q31.

Fable's verify pass grepped everything reachable from `runRegions`. The only lasting writes are the three above, plus Fix 2's `pairs`/`returns`. The `ref c` callees (`templateOf`, `occurs`, `isUnique` → `typeDisplay`, `t41Stores`, …) write nothing, and `LocalSymbol` holds no container. Re-check this if the code moves while implementing.

### Fix 2: `summarizeRegions`, the first pass in an arena with the same rollback
`region.byn:222-224` keeps pass 1 in `General` only because of the memo. Use the same snapshot, undo and rerun around `t41SummaryRun` on every pass.
- Summary runs report nothing (`region2.byn:1011`).
- They do reach `changedFields`. `runRegions` sets `r.reporting = true` for its second walk even in summary mode (`region.byn:329`; C# `RegionAnalysis.cs:169`). So on pass 1 the rollback is the live mechanism for every function whose run first fills a memo entry.
- The undo also clears `pairs` and `returns` before the rerun. They are created before the region and filled inside it (`region.byn:259`, `:263`); without the clear, the rerun doubles them and the fixpoint diverges from the C#.
- The 169 MB prototype figure came from a warm-up, not a rollback. The real saving is lower and is measured before setting the bounds.

### Fix 3: `sweepStale` tests the prefix before `Path.combine`
`cache.byn:743-747` builds three combined paths for each `$TMPDIR` entry, then tests the prefix. Test `startsWith` on the entry name first. The stale set and its order are unchanged. The C# twin already filters by name (`Directory.EnumerateDirectories(tempRoot, pattern)` in `Toolchain.cs` `SweepStale`), so it doesn't change.

### Out of scope (to `work/todo.md`)
- `t6EmitFunction` (175 MB). Each function writes strings into `CCtx` tables (`statics`, `helpers`, `vtables`, `symbolTexts`, `files`), so an arena needs those tables restructured.
- `analyzeEffects` (62 MB, not audited).
- Freeing the frontend before the zig child runs. That gives the largest combined saving, about 1 GB, but means one arena over compile+emit with `source` and the `Ctx` fields that `t9Build` needs copied out. A separate plan.

## Files
- `selfhost/semantics/region.byn`: `t42RegionsRun`; `summarizeRegions` uses it on every pass.
- `selfhost/semantics/region2.byn:751`: log the memo key.
- `selfhost/semantics/ctx.byn` (or wherever `Ctx` is declared): `changedFieldsLog`.
- `selfhost/semantics/generics.byn:227`: call through `t42RegionsRun`.
- `selfhost/driver/cache.byn` `sweepStale`.
- `bootstrap/bayan.c`: regenerated (`BAYAN_UPDATE=1` on `BootstrapTests`).
- `tests/Bayan.Tests/SelfhostDefaultBoundsTests.cs`: bounds (below).
- `docs/memory-leaks.md` Q31 row, `work/todo.md:772` (correct the "1.7 GB" attribution; record what's left), handoff *Progress log*, plan copy in `docs/plans/`.

## Tests
- **Tighten `CheckOfTheDriverStaysBounded`** (now 1,700 MB), and add **`EmitCOfTheDriverStaysBounded`**: `build --emit-c --package selfhost selfhost/driver` through `PeakSampler.Run`. That is bayan alone, with no zig child; assert exit 0 and `Peak > 0`.
- **Bound rule, set only after measuring.** Measure the after-figure on both hosts (macOS and the VM, about 60 MB higher), plus each single-fix-off figure.
  - Bound = the larger after-figure + half the smaller single-fix saving, rounded.
  - Acceptance: both single-fix break-tests fail it on both hosts.
  - If the margin is under about 40 MB on either host, drop that bound to the check test only. Leave the gap in `work/todo.md`; no fragile bound.
  - The figures and the bound go in the test message.
- **Rollback coverage.** Existing goldens drive the undo path: `tests/cases/diag/this-ref-call-modifies-borrowed-field.byn` (`ref this` calls on `this` plus two diagnostics), and 81 `diag/` cases with BYN3002-3006/BYN3214 (13 of them with two or more `ref this` methods). They must stay byte-identical; no new case is needed.
- **Break-tests**, each reverted alone with `git checkout --`, rebuilt, and confirmed to fail:
  - Fix 1 off: the bound fails.
  - Fix 2 off: the bound fails.
  - The rollback off (keep the arena run, skip the undo): ASan only. The stage-1 compiler under ASan on `this-ref-call-modifies-borrowed-field.byn` must report a use-after-free. Without ASan the freed chunk can still print the right text, so a golden diff is not a reliable break-test.
  - Fix 2's `pairs`/`returns` clear off: the summary goldens or `BootstrapTests` differ, because of doubled summaries.
  - Fix 3 off: no test; the saving depends on the host. Record the figure only.

## Verification
1. `dotnet test -v q` on `SelfhostDefaultBoundsTests`, `BootstrapTests`, the selfhost semantics region and diag classes, `SelfhostDefaultT9Tests`.
2. Max RSS before and after on macOS (`/usr/bin/time -l`, fake zig and real zig) and on bayan-test01 (`wait4`): `check`, `--emit-c`, `build -o`. Record them in the plan, `docs/memory-leaks.md` and the handoff.
3. ASan stage 1 (`ulimit -s 65520`) over the driver and over the 81 region `diag/` cases: no reports.
4. The full suite through `shard-test.sh --host vm=0.91:2:4`: both slots, 0 failed.
5. `laws-check.js --run`, `structure-audit.js`, a `review` worker (lands at 0 HIGH / 0 MEDIUM), then a `--no-ff` merge to dev, unpushed.
   - This is the same land.sh deviation as plans 009, 011, 012 and 013: specs.tsv has no row for a Q31 plan.

ETA after approval: about 3–4 h, including the 31-minute VM run.
