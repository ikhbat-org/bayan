# Memory and disk leaks

Version: 0.4.0-dev (matches `bayan --version`)

Every Bayan memory or disk leak found so far, what caused it, and the rule that keeps it
from coming back. Read this before writing anything that walks directories, watches files,
caches, buffers child output, recurses on input, or runs for longer than one command.

## Incidents

| Date | What happened | Cause | Fix |
|---|---|---|---|
| 2026-10 (twice), 2026-11-06 | `bayan-lsp` grew past 200 GB on mb1 and the machine killed parallel workers | `Workspace.IndexFolder` indexed every `.byn` under the root: 2.33M files, 1.27M of them in `.worktrees/` and 1.05M in `tmp/`. The client's `**/*.byn` watcher then loaded every new mutant and staging copy. | `fix/lsp-index-bound` (100fbcba): skip hidden, `tmp` and build dirs and symlinks, ignore watcher events there, budgets of 20k files / 256 Mi chars / 4 MiB per file. Peak on the real repo dropped to 41–81 MB. |
| 2026-11-05 | Long mutation recordings crashed the test host on mb1 | Homebrew dotnet GC crash under long runs | Run them on wp1 |
| 2026-11-06 audit | 66.9 GB in 132 `.worktrees`, 18.4 GB in `tmp/ignored-*` | Worktrees with test output under `tmp/` could never be retired | `cow-worktree.js`: files under a `CACHEDIR.TAG` dir no longer block removal; Bayan tags its caches |
| 2026-11-18 | zig's global cache reached 500+ GB on mb1 | `zig cc` used zig's default global cache, which zig never trims | 019 T17d: the driver's own `<cache>/zig`, `o/` capped at 2000 entries, none younger than 10 minutes removed (catalog below) |

## Rules

1. **Every walk is bounded.** A directory walk skips hidden dirs, `tmp`, `.worktrees`, build
   output and symlinks, and has a file, byte and directory budget. Cross the budget → stop and
   log one line, never keep going.
2. **Every watcher filters like the walk.** An event for a path the walk would skip is ignored.
3. **Every cache evicts.** It has a size or entry cap with LRU eviction (`programs/` and `runtime/` share one cap), a sweep for staging
   left by killed processes, and a `CACHEDIR.TAG` in `v1/` (never the `$BAYAN_CACHE` root, which a user may share).
4. **Child output is never buffered whole.** Keep a head and tail (`BoundedCapture`), or
   stream it. Waits after a kill have a timeout.
5. **Recursion on input has a depth cap** (lexer, parser, type walks). Past the cap: a
   diagnostic, not a stack overflow.
6. **Retained per-item state is proportional and counted.** A budget counts what is kept, not
   just its source size. Closed or unopened documents keep only what the index needs.
7. **Temp dirs are removed in `finally` and swept on start** (entries older than 24 h), because
   a killed process never runs its `finally`.
8. **Long-lived processes get a memory-bound test** that fails when the bound breaks. No release
   ships without them green (see *Release gate*). 2026-11-20 (Decision, Fable for the owner, spec 019 T43): the golden
   runner bound is sampled on shard 1/12 of `tests/cases` by the release gate and on the full tree every night
   (`laws-nightly.yml` job `golden-bound`, `scripts/ci/nightly-modes.sh --mode bound`, Linux and macOS): a hosted runner
   took 889 s for one twelfth of the tree at `--jobs 3`, so the full tree needs about 3 hours there.
9. **Builds don't leave servers behind.** Scripts that run `dotnet` set
   `MSBUILDDISABLENODEREUSE=1` and `DOTNET_CLI_USE_MSBUILD_SERVER=0`.

## Catalog (2026-11-06 audit)

Severity: HIGH = unbounded growth reachable in normal use; MEDIUM = bounded only by input size
or by luck; LOW = small or one-shot. Source reports: `tmp/leak-audit/*.out` (scratch, not kept).

### bayan-lsp

| Sev | Leak | Status |
|---|---|---|
| HIGH | Whole-tree indexing, watcher loads mutants (incident above) | fixed, `fix/lsp-index-bound` |
| HIGH | Close re-read files from disk and kept them forever, ignoring exclusions and budgets | fixed, `fix/review-2026-11-06-1` |
| HIGH | Retained state per file is 10–80× its text (tokens, diagnostics kept for closed files) | fixed, `fix/lsp-leaks` L1 |
| HIGH | Stack overflow from nested interpolation (Lexer) and member chains (`TypeOfReceiver`) | fixed, `fix/lsp-leaks` L2 |
| MEDIUM | `_chars` budget drifted on edits and reloads | fixed, `fix/review-2026-11-06-1` |
| MEDIUM | Folder delete or rename left the old subtree indexed and skipped the new one | fixed, `fix/lsp-leaks` L3 |
| MEDIUM | `Invalidate` kept replaced documents alive (2.9× after watcher storms) | fixed, `fix/lsp-leaks` L4 |
| MEDIUM | No cap on open-buffer size (32 MB didOpen → 1.09 GB) | fixed, `fix/lsp-leaks` L5 |
| MEDIUM | No cap on diagnostics; JSON-RPC body buffer never shrank | fixed, `fix/lsp-leaks` L6 |
| LOW | Body allocated from the header up front (256 MiB); truncated stream crashed | fixed, `fix/lsp-leaks` L7 |
| LOW | Walk time unbounded on roots with few `.byn` files | fixed, `fix/lsp-leaks` L8 |
| LOW | One file through two paths (symlink) became two documents | fixed, `fix/lsp-leaks` L9 |

### CLI and compiler (C#)

| Sev | Leak | Status |
|---|---|---|
| HIGH | `bayan test` buffered each test's whole stdout and stderr | fixed, `fix/cli-memory-bounds` M1 (`BoundedCapture`) |
| HIGH | Mutation runner buffered discarded output up to 300 s per mutant | fixed, M2 |
| HIGH | `bayan format <dir>` walked `.worktrees`, `tmp` and followed symlinks out of the root | fixed, M3 |
| MEDIUM | `dist` inputs hash followed symlinks | fixed, M4 |
| MEDIUM | Program cache `v1/programs` never evicted | fixed, M5: LRU, 2 GiB / 4000 entries, `BAYAN_CACHE_MAX_MB` |
| MEDIUM | Prebuilt runtime objects (`v1/runtime/<rkey>/`, plan 009) could pile up, one per compiler and flag set | bounded: they share the 2 GiB / 4000-entry LRU and the `v1/tmp/` staging sweep with `programs/` (`Toolchain.Evict`, `SweepStale`) |
| LOW | Per-process compiler identity memo (`Toolchain.identities`, plan 009) | bounded: cleared past 64 entries (`Toolchain.cs:223`) |
| MEDIUM | Staging dirs left by killed compiles; macOS `program.dSYM` moved into cache entries | fixed, M5/M6: stale sweep |
| MEDIUM | Parser and ownership analysis recurse with input depth | open: needs a BYN1xxx diagnostic and selfhost parity (decision) |
| LOW | C compiler ran with no timeout | fixed, M7: 10 min, `BAYAN_CC_TIMEOUT_S` |
| MEDIUM | Concurrent C program compiles had no host-wide cap: two VM shard slots ran several 2.6 GB selfhost `zig` compiles at once and the OOM killer took one (2026-11-13) | fixed, `fix/cc-jobs-limit`: `BAYAN_CC_JOBS` lock-file slots (`Toolchain.CompileSlot`), set to 2 for VM slices by `shard-test.sh`; the self-hosted driver does not read it |
| LOW | `AstDump` `[ThreadStatic]` lists keep their last contents | open, todo |

### Native runtime and selfhost

| Sev | Leak | Status |
|---|---|---|
| HIGH | `General` allocator never frees (Q31); selfhost stage1 reached 2.4 GB | decided: option (a), an arena per phase (Q31 note). Done for `mutate` re-binds (plan 012, `schemataRebinds`/`schemataMarkOf`: an arena per site): `std-json.byn` 2,490 MB → 23 MB, all run inputs in one process 5,541 MB → 179 MB (max RSS, macOS, 2026-11-13; `SelfhostDefaultT10Tests.MutateOfALargeInputStaysBounded`). Done for the region-summary fixpoint and the cache size reads (plan 013): `check` of the driver 2,629 → 781 MB (macOS), 2,705 → 840 MB (Linux); `doctor` over 64 × 4 MB 543 → 33 MB; `SelfhostDefaultBoundsTests.CheckOfTheDriverStaysBounded`/`DoctorOfALargeCacheStaysBounded`. Done for `analyzeRegions` and every summary pass, each run in an arena, undone and rerun in `General` when it fills a `changedFields` memo entry or a diagnostic (plan 014), and `sweepStale` tests the prefix before building paths: max RSS of bayan alone (fake zig), macOS / Linux, check 743 → 396 / 841 → 472 MB, `--emit-c` 1,026 → 678 / 1,155 → 786 MB, `build` 1,072 → 699 / 1,168 → 798 MB (2026-11-14). The 1.7 GB `build` figure was the `zig cc -O2` child (1,663 MB), not bayan. Linux PeakSampler break-tests of `CheckOfTheDriverStaysBounded` (bound 560 MB, bayan-test01, 2026-11-14): region arena off 628 MB, summary arena off 2,506 MB; both fail. `t42AnalyzeRegions` and `t42SummaryInArena` stay in `General` when a bag is the sink (plan 015; without it 10 of the 73 earlier bagged region cases print freed memory, `SelfhostSemanticsT25Tests.RegionsInABagKeepTheirDiagnostics`). Done for the frontend before the C compiler (plan 015 phase B): `build` (without `--emit-c`, which stays in `General`, 1,038 → 689 MB on macOS) and `run` compile, emit and prepare the output in one arena freed before `t9Build` starts zig, keeping only the C source, output path, program name, verbose `shown` line and timings; on Linux bayan holds 21/29 MB when zig starts (was about 800 MB) and bayan + zig peak 2,241 → 1,437 MB, bayan alone 831 → 977 MB (arena lists keep every grown capacity); macOS keeps freed chunks charged to the process, so it gains nothing there (bayan alone 700 → 1,010 MB); `SelfhostDefaultBoundsTests.BuildFreesTheFrontendBeforeTheCCompiler` (Linux, bound 100 MB; 788/801 MB with the arena reverted). Done for `analyzeEffects` (plan 015 phase D, `t42AnalyzeEffects`: an arena, rerun in `General` on any diagnostic): `check` of the driver 466–471 → 422–434 MB (Linux), 393 → 388 MB (macOS). Open: `t6EmitFunction` (175 MB), `test`/`mutate`/`dist` still build with the frontend alive, macOS chunk release (`work/todo.md`) |
| HIGH | zig's global cache grew without bound (500+ GB on mb1, 2026-11-18) | fixed, 019 T17d: with `ZIG_GLOBAL_CACHE_DIR` unset the driver gives each `zig cc` `<cache>/zig` and, before the compile, removes the oldest entries of its `o/` by write time past `zigCacheEntries` = 2000 (each build adds one or two entries, so this keeps about 1000 recent builds, the same order as the 4000-program cap), never one written in the last 10 minutes (`zigCacheMinAge`, `evict`'s guard, so a concurrent `zig cc` keeps its entry; zig's own libc and compiler_rt entries may age out and be rebuilt); a set `ZIG_GLOBAL_CACHE_DIR` is passed through and never trimmed |
| MEDIUM | 012 driver `.bayan-staging-*` left beside output; dSYM, non-recursive remove | fixed, 017 T9: the driver stages under the cache's `v1/tmp/` and `sweepStale` removes what a dead build left |
| MEDIUM | `Io.run` buffers child output whole, then copies (2× peak) | fixed, 008 W1 (Q1227): with `timeout:`, `Io.run` keeps each stream's first and last 64 KiB around one `… N bytes omitted …` line, as `BoundedCapture` does; a test printing until killed peaks at 39 MB through the stage-2 driver (40416 KB, the highest of three runs on macOS, 2026-11-12; bound 300 MB; was 4619 MB; `SelfhostDefaultBoundsTests` M1 on the driver). Without `timeout:` every byte is still kept, by design: `bayan run` and callers that need a child's whole output; exported golden program runs (spec 019 T17b2c, `goldenProgramRun`) capture whole output, bounded by the case time limit only (their case child is killed at it, the runner's capture of that child staying at 64 KiB per half) |
| MEDIUM | `StrBuf` growth abandons old blocks (Q745 by design); ~2× under `General` | follows the allocator decision |
| MEDIUM | `Symbol` intern table never shrinks (spec 008 R10, by design) | accepted |
| LOW | Error paths in `byn_io_read*`/`list_dir` skip frees; `io_read` buffer not shrunk | open, todo |
| LOW | Arena resize always copies (≤ 2× geometric) | accepted |
| LOW | Caught panic skips `byn_arena_free` of unwound frames | open, todo |
| LOW | Owned payload in an error `Result` never dropped (Q311) | open |
| MEDIUM | Golden runner (`bayan test tests/cases`, spec 019): the runner and its `--golden-worker` children over the full cases tree, child output, scratch dirs | bounded, 019 T9a/T9b: runner and each worker under 15 MB, no scratch dir left in `tmp/` (macOS arm64, 2026-11-17: runner 9.3–10.0 MB, largest worker 9.6–9.8 MB; Linux x64 VM, one run: runner 9.4 MB, largest worker 9.6 MB; `tmp/cache` is the program cache, kept, not scratch); in the *Release gate*. 2026-11-21 (019 golden-mem): the runner kept 5.4 KB a case for 422 bytes of JSON (the report's ~60 JSON pieces a case, a second copy of the results and of the case list, a field list per listed line); the report is now built in an arena, each JSON entry in one of its own, so the runner's max RSS with a fake driver (macOS arm64, `--jobs 2`) went diag/ 13,136 → 12,736 KB, lex/ 141,984 → 48,752 KB, full tree 265,888 → 88,560 KB, shard 1/12 29,568 → 13,408 KB; the full tree is still over 15 MB (about 1.9 KB a case: the results, the JSON held whole and its `StrBuf` growth); test block "the runner over 12000 generated cases …" (bound 56 MB, 83,040 KB with the change reverted) |

### Tests and tooling

| Sev | Leak | Status |
|---|---|---|
| HIGH | `.worktrees` with `tmp/cache` could not be retired (66.9 GB) | fixed, `cow-worktree.js` CACHEDIR.TAG rule; Bayan tags its program cache and `pinned-bayan.sh` its `.cache/bayan` (`fix/cachedir-tag`) |
| HIGH | `tmp/ignored-*` parked output never removed (18.4 GB) | cleanup script |
| HIGH | Orphaned MSBuild nodes and VBCSCompiler (~4.5 GB) | fixed, `fix/tooling-bounds` T3 |
| HIGH | No xunit parallelism limit; static `Lazy` caches held to host exit | open: decision (class fixtures, `maxParallelThreads`) |
| MEDIUM | Test temp dirs not deleted (T8) or not deleted on kill | fixed, `fix/tooling-bounds` T1 (finally + 24 h sweep) |
| MEDIUM | `.cache/bayan/<sha>` from `pinned-bayan.sh` never evicted | fixed, T2: newest 3 kept, `src` dropped |
| MEDIUM | 47,228 empty 6-char dirs in `$TMPDIR`, creator unknown | open: investigate |
| LOW | `land.sh` leaves `tmp/land-*`; `dotnet-diagnostic-*` sockets; old pre-v1 cache | cleanup script; todo |

## Release gate

No Bayan product (compiler, runtime, LSP, VS Code extension, tools) is released while any of
these fail:

```sh
"$BAYAN_EXE" test --package editors/language-server/src editors/language-server/src/bounds     # LSP walk, budgets, retention, depth, buffers
"$BAYAN_EXE" test --package src src/driver --only 'bound: '       # CLI capture, cache eviction, walks, timeouts
"$BAYAN_EXE" test tests/cases --only cli/SelfhostDefaultT12Tests/TheInputsHashDoesNotFollowLinks  # inputs hash skips links
bash scripts/pinned-bayan.test.sh                                  # pinned build cache eviction
env BAYAN_GOLDEN_BOUND_SHARD="$bound_shard" BAYAN_TEST_TIMEOUT_MS="$bound_ms" "$BAYAN_EXE" test --package src src/driver --only 'a run over tests/cases keeps the runner and each worker under 15 MB and leaves no scratch directory'  # golden runner bound: shard 1/12, 30 min
```

The first line runs the bound blocks of `editors/language-server/src/bounds/bounds.byn` (spec 019 T38a, R22) with no .NET;
they are pending on Windows (no `sh` or `ps`), and on Linux and macOS the gate fails when any is pending or none passed.
The block "16 messages of 2 MiB read and 16 written …" allows less than four messages (8192 KB) of growth on macOS for the reads
and for the writes, two (4096 KB) elsewhere (spec 019 T43, 2026-11-20). The hosted macos-15 runner grew 6288 KB on the reads and
4160 KB on the writes (release dry run 44688158908). On macOS arm64 a scratch copy of the block, its input framed once and
moved into the transport (0.5 GB resident at 256 messages instead of 3 GB, which the loaded machine paged out), grew on the
reads 16, 496 and 16 KB at 16 messages, 1376, 1792 and 1616 KB at 64, 528, 1616 and -3056 KB at 256; the writes alone (no
input held beside them) grew 1184, 2640 and 32 KB at 16, 1520, 2128 and 3104 KB at 64, 2896, 3584 and 3408 KB at 256. Kept
messages would add 32768, 131072 and 524288 KB: the growth stays flat as the count rises sixteenfold, so it is the allocator
keeping pages, not a message kept. Break: the server kept each message read in a list; the block failed in 6 of 8 runs at
+32928 to +33248 KB on the reads; the 2 passes came under heavier memory pressure (swap 5.5 of 7 GB), the kept pages
compressed out of the resident set that `ps` reads.

The second line runs the `bound: ` test blocks of `src/driver/bounds.byn` (spec 019 T28, R9, R15): the bounds
`CliMemoryBoundsTests` and `SelfhostDefaultBoundsTests` checked, with the same numbers, measured by
`scripts/release/peak-rss.sh`. They are pending on Windows (no `sh` or `ps`) and the Linux-only C-compiler row is pending
elsewhere; on Linux and macOS the gate fails when none of them passed. The `bound: evict …` blocks run the driver's evict over
the trees of `tests/cases/bounds/evict/`, exported from the C# `Toolchain.Evict` (spec 019 T28 part 2).
The macOS bound of "bound: check of the driver stays under its plan 014 bound" is 520 MB (spec 019 T43, 2026-11-20; was 480):
the bound follows the size of src/driver, as the check reads the whole package. Plan 014 set 480 on 396 MB for `selfhost/driver`
at 780,342 bytes of `.byn` (package `selfhost` 3,441,419 bytes); at bd0ba8688 src/driver is 1,745,700 bytes (package `src`
4,950,529 bytes) and peaked at 481 MB on the hosted macos-15 runner (release dry run 44688158908) and at 429, 486, 299, 318 and
290 MB in five runs on macOS arm64 (stage-1 driver, loaded machine), so the peak per source byte fell. 486 MB plus 5%, rounded
up to the next 10. Linux (560) and Windows (1,700) are unchanged.

The third line runs the cli cases `TheInputsHashDoesNotFollowLinks` and `-2` (the M4 row `SelfhostDefaultBoundsTests` delegated to
`SelfhostDefaultT12Tests`); the gate fails unless both passed.

The last line is the `src/driver/golden.byn` test block "a run over tests/cases keeps the runner and each worker
under 15 MB and leaves no scratch directory" (spec 019 R9): a run of `$BAYAN_EXE test tests/cases` keeps the runner and
each `--golden-worker` under 15 MB of resident set and leaves no scratch directory in `tmp/`. Measured on macOS arm64
(2026-11-17, four runs): runner 9.3–10.0 MB, largest worker 9.6–9.8 MB; Linux x64 (bayan-test01, 2026-11-17, one run from a fresh clone): runner 9.4 MB, largest worker 9.6 MB. `tmp/cache` (the program cache the runner names, CACHEDIR.TAG) is kept between runs and is not counted as scratch. Without
`BAYAN_TEST_TIMEOUT_MS` (it needs minutes) or on Windows (no `sh` or `ps`) the block reports pending; the gate fails a
pending result on Linux and macOS. `BAYAN_EXE` is the self-hosted driver; when it is unset, the gate builds `src/driver`
with the pinned bayan at `HEAD` into `tmp/memory-gate/`.

`BAYAN_GOLDEN_BOUND_SHARD` (`i/n`) has the block sample one shard: the sampled run gets it as `BAYAN_TEST_SHARD`; empty or
unset, the full tree; another form fails the block, naming the variable. The gate sets `bound_shard=1/12` and
`bound_ms=1800000` (30 minutes); `memory-gate.sh --full` samples the full tree with the caller's `BAYAN_TEST_TIMEOUT_MS`.
2026-11-20 (spec 019 T43): release dry run 44688158908 gave the full tree 10 minutes and the block failed on both hosts
after 590 s ("the sampled run did not end"); a hosted runner took 889 s for shard 11/12 at `--jobs 3` (ci.yml, osx-arm64),
so the full tree needs about 3 hours there. Decision 2026-11-20 (Fable for the owner): the release gate samples shard 1/12,
and `laws-nightly.yml`'s `golden-bound` job samples the full tree every night on ubuntu-24.04 and macos-15
(`scripts/ci/nightly-modes.sh --mode bound`, 5 hours for the block, 330 minutes for the job; not run when `release.yml`
calls the workflow). A block that ran and failed is reported once, as failed; "did not run (no test matched)" means no
test ran.
Measured 2026-11-20 (macOS arm64, stage-1 driver at 4c8dff730, shard 1/12): sampled run exit 0, runner 9,904 KB,
largest worker 13,680 KB, under the 15 MB bound. An earlier run that day (483 s) gave runner 73,680 KB and worker
133,104 KB; 019-t43a fixed it: each case frees its allocations when it ends, and the case listing peaks at 10.7 MB, not 45 MB.

`bash scripts/release/memory-gate.sh` runs this block and names every failing command; `release.yml`'s
`memory-gate` job runs it on Linux and macOS, and no draft release is made without it. The VS Code
extension and `bayan-lsp` are gated by `scripts/release/editor-gate.sh` (`.github/workflows/editor-gate.yml`):
it runs the `LanguageServer` tests and packages the extension (`vsce package`, size bound), on every push to
`dev` and before a release (`release.yml`'s `release` job needs it); there is no manual pre-packaging step. The
extension itself is not exercised headless on a runner.
`scripts/release/memory-gate.test.sh` fails when the script and this block drift apart.

plus, for a release that changes the runtime or selfhost: `leaks --atExit` over the run goldens
on macOS (2026-11-06: ≤ 3.6 KB per golden; 2026-11-12 through stage 2: median 16 B, max 1.1 MB in `io-run-input.byn`; probes show a `List`'s last buffer left allocated at exit, in any function, Q1228 and Q1229) and peak RSS of a selfhost build of `src/`
(2026-11-12: 2.94 GB for `src/driver`, Q1228; 2026-11-14, 0.3.0 at `bootstrap/bayan.c` regenerated for the release: 1.69 GB, median of 3 on macOS (1,656,848,384, 1,688,387,584 and 1,693,663,232 bytes, 34 s each); record the number in the release notes; a rise over 20 % blocks until explained).

A new long-running component, cache, walk or watcher adds its bound test to this list in the
same branch.
