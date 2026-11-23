# Dropoff: what the Rein IDE core needs from Bayan (concurrency first)
Release: unscheduled
Sources: Rein IDE redesign, `extrode.com/rein` (2026-11-23)

From: `extrode.com/rein`. The IDE redesign (`rein/docs/research/ide-redesign/2026-11-23-prototypes/README.md`)
puts a Bayan program under the web UI as its core: workspace files, search, git, processes and the UI protocol.
Written here, not in `bayan/docs/handoffs/`, because the bayan checkout was on `feat/011-self-hosted-emitter`
with untracked files on 2026-11-23. Move it into the repo when picked up.

Owner's call (2026-11-23): **concurrency is next.**

## Checked on 2026-11-23 against bayan `dev` (276d6e21e)

| Need | State | Evidence |
|---|---|---|
| JSON | exists | `lib/std/json/{reader,value}.byn` + `json.test.byn` |
| Regex | exists | `lib/std/regex/regex.byn` + test (the `matches` operator still says "arrives with std.regex after v0.1") |
| Glob | exists | `lib/std/fs/glob.byn`, `lib/std/path/glob.byn` |
| Wall-clock time | **missing** | only `Io.monotonicNanos` (`Builtins.cs:80`); `std.time` is spec 021, `Status: deferred`, gates G1 and G5 not met |
| Concurrency | **designed, not specced or built** | `docs/bayan-concurrency.md` (confirmed 2026-11-01; "spec in round 4, runtime in v0.2"); no spec dir |
| `extern c` | **missing** | no `extern` form parses (BYN1016; `DiagnosticCodesTests.cs:127`) |
| Processes | partial | `Io.run`, `Io.runBatch` wait for exit; no streaming of a running child |
| Sockets, WebSocket | missing | — |
| wasm32 library export | missing | wasi `main` only |

## P0: concurrency (next)

Start a spec from `docs/bayan-concurrency.md` (R1-R7, §9 syntax and diagnostics, §12 the round-4 §13 rewrite).
What the IDE core uses it for, as acceptance:

| Use | Acceptance |
|---|---|
| Protocol loop on stdin while other work runs | a `scope` with one fiber reading framed stdin messages and others answering; a slow git call never delays a ping reply by more than 10 ms |
| Child process streamed as it runs (`git log`, test runs, a language server over stdio) | read a child's stdout line by line inside a fiber, write its stdin, get its exit code; cancel kills the child |
| Cancellation | a request canceled by the UI unwinds its fiber and kills its children (R3) |
| CPU work off the loop | diff / fuzzy match / lane layout in `scope(workers: .compute)` (R6) |
| `bayan run` single worker | the same program works with one worker (R1 remedy) |

Streaming child I/O is the one P0 item outside the design doc: `Io.run` today blocks until exit. It fits as
the `suspend`-using form of `Io.run`.

## P1: after concurrency

1. `extern c` (spec text at `bayan-spec.md:2034`, `@blocking` per R6). The IDE wants it for a pty (`forkpty`,
   ConPTY), file watching (FSEvents, inotify, ReadDirectoryChangesW), tree-sitter, libgit2 and webview.
2. Sockets plus a WebSocket server (browser and remote attach).
3. `std.time` wall clock: `now()` as Unix time plus ISO 8601 formatting is enough for the IDE (spec 021 Phase 2+
   covers it; a minimal `Io.wallNanos` would unblock it sooner).
4. wasm32 library export: functions JS can call, not only a wasi `main`. Fibers on wasm wait for stack
   switching (§10), so exported compute functions must be `suspend`-free.

## Not needed from Bayan

UI (Monaco, xterm.js in the web front end), syntax highlighting (vscode-textmate), LSP servers themselves.
