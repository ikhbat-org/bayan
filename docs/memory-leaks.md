# Memory and disk leaks

Every Bayan memory or disk leak found so far, what caused it, and the rule that keeps it
from coming back. Read this before writing anything that walks directories, watches files,
caches, buffers child output, recurses on input, or runs for longer than one command.

## Incidents

| Date | What happened | Cause | Fix |
|---|---|---|---|
| 2026-10 (twice), 2026-11-06 | `bayan-lsp` grew past 200 GB on mb1 and the machine killed parallel workers | `Workspace.IndexFolder` indexed every `.byn` under the root: 2.33M files, 1.27M of them in `.worktrees/` and 1.05M in `tmp/`. The client's `**/*.byn` watcher then loaded every new mutant and staging copy. | `fix/lsp-index-bound` (c9434a3c): skip hidden, `tmp` and build dirs and symlinks, ignore watcher events there, budgets of 20k files / 256 Mi chars / 4 MiB per file. Peak on the real repo dropped to 41–81 MB. |
| 2026-11-05 | Long mutation recordings crashed the test host on mb1 | Homebrew dotnet GC crash under long runs (see handoff) | Run them on wp1 |
| 2026-11-06 audit | 66.9 GB in 132 `.worktrees`, 18.4 GB in `tmp/ignored-*` | Worktrees with test output under `tmp/` could never be retired | `cow-worktree.js`: files under a `CACHEDIR.TAG` dir no longer block removal; Bayan tags its caches |

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
   ships without them green (see *Release gate*).
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
| LOW | Per-process compiler identity memo (`Toolchain.identities`, plan 009) | bounded: cleared past 64 entries (`Toolchain.cs:196`) |
| MEDIUM | Staging dirs left by killed compiles; macOS `program.dSYM` moved into cache entries | fixed, M5/M6: stale sweep |
| MEDIUM | Parser and ownership analysis recurse with input depth | open: needs a BYN1xxx diagnostic and selfhost parity (decision) |
| LOW | C compiler ran with no timeout | fixed, M7: 10 min, `BAYAN_CC_TIMEOUT_S` |
| LOW | `AstDump` `[ThreadStatic]` lists keep their last contents | open, todo |

### Native runtime and selfhost

| Sev | Leak | Status |
|---|---|---|
| HIGH | `General` allocator never frees (Q31); selfhost stage1 reached 2.4 GB | decided: option (a), an arena per phase (handoff Q31 note). Done for `mutate` re-binds (plan 012, `schemataRebinds`/`schemataMarkOf`: an arena per site): `std-json.byn` 2,490 MB → 23 MB, all run inputs in one process 5,541 MB → 179 MB (max RSS, macOS, 2026-11-13; `SelfhostDefaultT10Tests.MutateOfALargeInputStaysBounded`). Open: the bootstrap stage-1 build (3.0 GB) and `doctor` (1.7–2.1 GB) |
| MEDIUM | 012 driver `.bayan-staging-*` left beside output; dSYM, non-recursive remove | fixed, 017 T9: the driver stages under the cache's `v1/tmp/` and `sweepStale` removes what a dead build left |
| MEDIUM | `Io.run` buffers child output whole, then copies (2× peak) | fixed, 008 W1 (Q1227): with `timeout:`, `Io.run` keeps each stream's first and last 64 KiB around one `… N bytes omitted …` line, as `BoundedCapture` does; a test printing until killed peaks at 39 MB through the stage-2 driver (40416 KB, the highest of three runs on macOS, 2026-11-12; bound 300 MB; was 4619 MB; `SelfhostDefaultBoundsTests` M1 on the driver). Without `timeout:` every byte is still kept, by design: `bayan run` and callers that need a child's whole output |
| MEDIUM | `StrBuf` growth abandons old blocks (Q745 by design); ~2× under `General` | follows the allocator decision |
| MEDIUM | `Symbol` intern table never shrinks (spec 008 R10, by design) | accepted |
| LOW | Error paths in `byn_io_read*`/`list_dir` skip frees; `io_read` buffer not shrunk | open, todo |
| LOW | Arena resize always copies (≤ 2× geometric) | accepted |
| LOW | Caught panic skips `byn_arena_free` of unwound frames | open, todo |
| LOW | Owned payload in an error `Result` never dropped (handoff item 311) | open |

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
dotnet test -v q --filter "FullyQualifiedName~LanguageServer"     # LSP walk, budgets, retention, depth, buffers
dotnet test -v q --filter "FullyQualifiedName~CliMemoryBounds"    # CLI capture, cache eviction, walks, timeouts
dotnet test -v q --filter "FullyQualifiedName~SelfhostDefaultBounds" # the same bounds through the self-hosted driver
bash scripts/pinned-bayan.test.sh                                  # pinned build cache eviction
```

`bash scripts/release/memory-gate.sh` runs this block and names every failing command; `release.yml`'s
`memory-gate` job runs it on Linux and macOS, and no draft release is made without it. The VS Code
extension and `bayan-lsp` are gated by `scripts/release/editor-gate.sh` (`.github/workflows/editor-gate.yml`):
it runs the `LanguageServer` tests and packages the extension (`vsce package`, size bound), on every push to
`dev` and before a release (`release.yml`'s `release` job needs it); there is no manual pre-packaging step. The
extension itself is not exercised headless on a runner.
`scripts/release/memory-gate.test.sh` fails when the script and this block drift apart.

plus, for a release that changes the runtime or selfhost: `leaks --atExit` over the run goldens
on macOS (2026-11-06: ≤ 3.6 KB per golden; 2026-11-12 through stage 2: median 16 B, max 1.1 MB in `io-run-input.byn`; probes show a `List`'s last buffer left allocated at exit, in any function, handoff Q1228 and Q1229) and peak RSS of a selfhost build of `selfhost/`
(2026-11-12: 2.94 GB for `selfhost/driver`, handoff Q1228; record the number in the release notes; a rise over 20 % blocks until explained).

A new long-running component, cache, walk or watcher adds its bound test to this list in the
same branch.
