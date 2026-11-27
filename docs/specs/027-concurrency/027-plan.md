# 027 — Plan
Spec: ./027-spec.md

Status: draft
Release: unscheduled (phase 1 planned for 0.5.0, with spec 023's units (#9) and spec 028's `Duration` and `Uptime`)
Sources: `./027-spec.md` (owner decisions D1–D8, 2026-11-23; owner answer on `Untrusted`, 2026-11-27);
`docs/bayan-concurrency.md`; `docs/memory-leaks.md`; `docs/bayan-library-tiers.md`;
`docs/specs/028-units-duration-uptime/028-spec.md`; `docs/specs/023-spec-catch-up/023-spec.md`

## Approach
Phase 1 is one worker thread running many fibers. Every piece of it lives in three places: the C runtime
(`runtime/bayan-rt.c`, copied into `src/driver/runtime.byn` by `scripts/selfhost/gen-driver-files.sh`), the emitter's
lowering of suspend points, and the checker's rules for `scope`, `spawn`, borrows and effects.

The lowering is the central choice. A function with the `suspend` effect lowers to C as a function with an error
channel, whether or not it fails, and that channel has one hidden status, cancel. A suspend point that finds a cancel
pending returns cancel. The emitter propagates it like an error through every frame, runs `defer`, bare
`defer failing` and `defer canceling` on the way, skips `defer failing (e)`, and never lets a `catch` take it. Only
the scope that was canceled turns it back into a normal exit (R6b) or into `DeadlineError.exceeded` (R5). Nothing in
the source language sees the status: it is in no `fails` list.

Parking is real stack switching: a parked fiber keeps its C stack and the worker runs another fiber. So fibers stay
colorless, and a library function that reads a child's pipe works the same from `main` or from a spawned child.

A program in which no function has `suspend` emits the same C as today. The runtime's fiber code is reached only from
emitted calls, so the compiler (R13), the bootstrap and every existing `run/` case keep their bytes;
`tests/cases/emit/run-c.sha256` changes only for new cases.

Order: the spec revision first (the §13 rewrite and its companions, spec Goals), then the parser, the runtime core,
the checker and the emitter for `scope`/`spawn`, then cancellation sources, deadlines, channels, the `Io`
implementations, stdin, child processes, the abort path, `wasm32`, bounds and the IDE rows. Each task lands with its
golden cases.

```cs
i32 streamLog(ref Sender<Untrusted<string>> lines) uses process, suspend, alloc fails IoError, ChannelError {
    var child = try Io.start("git", args: ["log", "--oneline"])
    var output = child.takeStdout() ?? return -1
    while let line = try output.readLine(max: 1048576) {
        try lines.send(line)
    }
    return try child.wait()
}
```

## Decisions
1. **Fiber stacks.** Chosen: fixed-size stacks, 1 MiB reserved per fiber and committed by the OS on first touch, with
   one `PROT_NONE` guard page below each (POSIX `mmap`; Windows `CreateFiberEx` with 64 KiB committed and 1 MiB
   reserved, whose guard page the OS keeps). Freed stacks go to a cache of at most 16 and the rest are unmapped. An
   overflow faults on the guard page and the process dies, as a thread-stack overflow does today; there is no
   overflow handler in phase 1. Context switches are a short assembly switch for x86-64 SysV and AArch64 (the
   `linux-*` and `macos-*` targets of `targetNames` in `src/driver/cc.byn`) and the Fibers API on `windows-*`.
   Rejected: segmented or growable stacks. The C backend has no stack maps, so a stack cannot be moved or grown in
   place, and C frames from libc or a future `extern c` cannot be split. Rejected for the switch: `ucontext`, which
   musl (the `linux-*` triples are `*-linux-musl`) does not provide and which makes a signal-mask syscall per switch.
   Provisional values (1 MiB, 16 cached): measured in T3 against the `run/` cases, the R14 bound and the P1 benchmark.
2. **Event-loop backend.** Chosen: one loop interface in the runtime with two backends in phase 1: `poll(2)` on POSIX
   (stdin, the parent ends of child pipes, one wake pipe, a timer heap on `byn_io_monotonic_nanos`) and an I/O
   completion port on Windows. One worker watches a handful of descriptors, so `poll` costs nothing measurable there.
   Rejected: kqueue, epoll and IOCP in phase 1. They pay off with many descriptors and many workers (phase 2 sockets
   and `.perCore`), and three backends triple the platform-specific code that must pass P1–P4 first. Phase 2 swaps in
   kqueue and epoll behind the same interface.
3. **Method names.** Chosen: `Io.start(…)` returns a `unique` `Child`. `child.read(max:)` is spec 023 R14's
   combined next-chunk read (stdout or stderr, whichever is ready). `child.takeStdin()`, `child.takeStdout()` and
   `child.takeStderr()` split off `unique` `ChildStdin` and `ChildReader` handles, once each (a second call returns
   `null`). `ChildReader` and `Io.stdin` get `read(max:)` and `readLine(max:)`. `ChildStdin` gets `write(_)` and
   `close(move this)`. `child.wait(move this)` returns the exit code. The existing `Io.stdin.read(to:)`, `readAll()`
   and `readAllBytes()` keep their names and their blocking behavior. Rejected: `Io.spawn` for the child, which
   reuses the fiber keyword for a different thing; and spec 023 R14's `read(into:)` spelling, which would rename the
   shipped `Io.stdin.read(to:)` (§15.1). The new reads differ from it by particle (`max:` against `to:`), which
   overloads already allow.
4. **Kill-wait and per-line cap defaults.** Chosen: dropping a running `Child` sends `SIGKILL` to its process group
   (POSIX) or calls `TerminateJobObject` (Windows), then waits at most 1 s; past that it writes one line to stderr
   naming the pid and continues, and the event loop reaps the child later. `readLine` has no default: `max:` is a
   required argument, and the examples and docs use 1 MiB. `read(max:)` defaults to 64 KiB, the size of one half of
   `Io.run`'s bounded capture. Rejected: `SIGTERM` first with `Io.run`'s 2 s grace (`BYN_RUN_GRACE_MS`): a child that
   ignores it would miss P3's 100 ms, and a caller that wants a graceful stop closes stdin and calls `wait()`.
   Provisional (1 s, 64 KiB, the 1 MiB used in docs): measured in T12.
5. **Child results out of the child arena (R2).** Chosen: copy on exit. A child runs with a child arena as
   `context.allocator`. When it ends, the spawn thunk copies its result into the parent's allocator with the same
   deep copy `copy()` lowers to, then frees the arena. A value sent on a channel is copied into the channel's
   allocator in the same way. A child whose spawn call passes any `ref` argument or a mutable `Span<T>` runs in the
   parent's allocator with no arena, so nothing it stores through a parent borrow can dangle. This also covers
   collections: a list binds its allocator on first growth (`if (!l->alloc) l->alloc = byn_context;` in
   `src/emitter/cprint/builtin.byn`, line 212; the `alloc` field of `byn_map_hdr` in `runtime/bayan-rt.h`), so an
   empty parent list first grown inside a child arena would dangle. Rejected: restricting
   result types to values with no heap data, which fails R2's own criterion (a child returns a `string` it built).
   The copy's cost is measured in T6.
6. **`IoError` variants for streamed children.** Chosen: two new variants, `closed` (a write to a child's stdin after
   the child closed it; POSIX `EPIPE`, Windows `ERROR_NO_DATA` and `ERROR_BROKEN_PIPE`) and `lineTooLong(i64 limit)`
   (a line longer than `max:`). A streamed child killed by a signal fails with the existing
   `signaled(i32 signal, string stdout, string stderr)` with both strings empty. Rejected: a new payload-free
   `killed(i32 signal)` variant, which gives one fact two names and adds a switch arm to every caller; and `other` or
   `invalidInput` for the two new failures (`invalidInput` means "nothing was done", and a line read has consumed
   bytes). After `lineTooLong`, the next read continues inside the same line.
7. **`Io.Simulated` with real stdin and children.** Chosen: refuse the suspending forms. Under `Io.Simulated`,
   `Io.start`, `Io.stdin.read(max:)` and `Io.stdin.readLine(max:)` fail `IoError.unsupported`; the blocking `Io.run`,
   `Io.runBatch`, `readAll`, `readAllBytes` and `read(to:)` keep working as today, so the existing `test` blocks that
   call them do not change. A test that needs a real child writes `provide io: Io.Evented(workers: 1) { … }`.
   Rejected: passing OS waits through, which makes the simulated schedule depend on when the OS delivers bytes and
   deadlocks P2's shape (one fiber writes a child's stdin while another reads it) on a scheduler that blocks.
8. **`CancelSource` shared state.** Chosen: `CancelSource()` allocates one small cell (the canceled flag and the
   attached scope, if any) from `context.allocator`; copies share the cell, and it lives as long as that allocator.
   A copy follows the placement rule a `string` made in the same allocator follows. A `scope(cancel:)` records itself
   in the cell on entry and clears it on exit, so a cancel after the scope does nothing and `isCanceled` still reads
   the flag. `CancelSource()` therefore uses `alloc`. Rejected: a generation-checked runtime table like §9.6's
   `Handle<T>`. A slot freed at scope exit forgets a cancel made before attaching and loses `isCanceled` after the
   block (R6b needs both), and a slot kept forever grows with every request.
9. **Where the new names live.** Chosen: compiler built-ins bound in `src/semantics/builtins.byn`, as `Io` is today,
   with `std.fiber` (`Fiber`, `Channel`, `Sender`, `Receiver`, `Task`, `CancelSource`, `DeadlineError`,
   `ChannelError`) and `std.process` (`Child`, `ChildStdin`, `ChildReader`, `ChildChunk`, `ChildStream`) as their home
   in `docs/bayan-library-tiers.md`. Rejected: Bayān source under `lib/std/`, which cannot switch stacks or poll
   without `extern c` (spec 023 #17, not in 0.5.0).
10. **`async`/`await` and `#:io` diagnostics.** Chosen: new input-form codes BYN1081 and BYN1082, after the precedent
    of BYN1020 (`errdefer` is now `defer failing`); BYN0012 stays for every other reserved word. Rejected: a help line
    on BYN0012, which would give one code two meanings in the explain pages.

## Tech / dependencies
- No new tool or library. The runtime stays one C11 file built by zig or the system C compiler. It uses `mmap`,
  `mprotect`, `poll`, `posix_spawn` with `POSIX_SPAWN_SETSIGDEF`, `POSIX_SPAWN_SETSIGMASK` and
  `POSIX_SPAWN_SETPGROUP` on POSIX, and `CreateFiberEx`, `SwitchToFiber`, `ConvertThreadToFiber`, named pipes with
  `FILE_FLAG_OVERLAPPED`, `CreateIoCompletionPort`, `RegisterWaitForSingleObject` and job objects on Windows.
- Spec 028 lands first: `Duration`, `Uptime` and unit literals (`50ms`) are the types of `timeout:`, `until:` and
  `Fiber.sleep(for:)`.
- Spec 023 #9 (units) lands first, through spec 028. Spec 023 #17 (`extern c`) is needed only by phase 3.
- Spec 026 should land before T12: once `IoError` is `extensible`, adding `closed` and `lineTooLong` does not break
  switches. If 026 has not landed, T12 fixes every BYN2410 site in the repository in the same change.
- Spec 023 #16a (`provide` handlers and `Io.Simulated`) is not a prerequisite. T10 builds the minimal
  `Io.Simulated` that R12b needs, and #16a extends it.

## Changes by area
### Spec and documents
- `docs/revisions/` — new revision, next free number at T1 (0025 is planned by spec 026): the §13 rewrite and the
  companion edits the spec lists (§1, §2.4, §5.2 `share()`, §7.6, §7.7 and `Io.evented()`, §8, §9.2, §9.4, §14,
  §16.5, §20, §21.4, §23, Appendix A, design §12 and its `bayan new --script` row) — R1–R14, R20
- `docs/bayan-spec.md` §13 (line 1706), §8 (line 1395, built-in error numbering for `DeadlineError`, `ChannelError`
  and the new `IoError` variants), §15.1 (line 1801, the new stdin reads, `Io.start`, `Untrusted` results) — R5, R9,
  R10, R11, R14
- `docs/bayan-concurrency.md` §12 — the Blocking panic names the blocked fiber and its operation (D7) — R12
- `docs/memory-leaks.md` — catalog rows for fiber stacks, child arenas and child pipes; release-gate lines for the
  new bound blocks — R14
- `docs/bayan-library-tiers.md` (line 101 `std.process`, line 106 `std.fiber`) — the phase 1 members and their status
  — R8, R9, R10
- `docs/diagnostics/BYN1081.md` … `BYN1083.md`, `BYN6009.md` … `BYN6012.md`, `BYN3220.md` — new explain pages;
  `docs/diagnostics/BYN3217.md` from reserved to live; `docs/DIAGNOSTICS.md` and `docs/diagnostics-allocated.txt`
  regenerated by `scripts/docs/gen-diagnostics.sh` — R14
- `docs/specs/023-spec-catch-up/023-spec.md` row 23 and row 25 — note that spec 027 phase 1 covers them — R10, R13
- `CHANGELOG.md`, `docs/bayan-progress-log.md`, `docs/specs/README.md` (`scripts/docs/gen-spec-index.sh --write`)

### Lexer and parser
- `src/lexer/lexer.byn` (line 418, the `#:` trivia branch) — keep `#:` lines as trivia and record each directive's
  span and text for the parser, which reads `#:io evented`, `#:io blocking` and the input form `#:io threaded` — R12
- `src/lexer/tokens.byn` (`asyncKeyword`, `awaitKeyword`, line 145) — unchanged; the tokens stay reserved — D6
- `src/parser/recover.byn` (line 515, `reservedKeyword`) — `async` and `await` report BYN1081 instead of BYN0012 — D6
- `src/parser/stmts.byn` (`parseStatement`, line 57) — `scope` and `shield` as contextual keywords at the start of a
  statement before `{` or `( … ) {`, with `atContextual` — R2, R4, R5, R6b, R7
- `src/parser/exprs.byn` (`parsePrefixed`, line 310) — `spawn` before a name starts a spawn expression — R3
- `src/parser/stmts2.byn` (`parseDefer`, line 143; the contextual `failing`/`panicking` test, line 157) — `canceling`
  after `defer` — R6
- `src/parser/nodes.byn` (`DeferKind`, line 781) — a `canceling` case; new `ScopeStmt`, `ShieldStmt`, `SpawnExpr`
  nodes — R2, R3, R6, R7
- `src/parser/dump.byn`, `src/parser/dump2.byn` — the new nodes in the parse dump — R2, R3
- `src/parser/codes.byn` — BYN1081, BYN1082, BYN1083 with `// target:` comments — R12, R14

### Semantics
- `src/semantics/builtins.byn` — sources and bindings for `Task<T>`, `Fiber`, `CancelSource`, `Channel<T>`,
  `Sender<T>`, `Receiver<T>`, `Child`, `ChildStdin`, `ChildReader`, `ChildChunk`, `ChildStream`, `Io.start`, the new
  `Io.stdin` reads (beside `Io.stdin.read`, line 367, and the `name == "read"` test, line 1416); new
  `deadlineErrorSource` and `channelErrorSource` beside `ioErrorSource` (line 60); `closed` and
  `lineTooLong(i64 limit)` added to `ioErrorSource` — R3, R5, R6b, R8, R9, R10, R11
- `src/semantics/types.byn` (built-in type list, `ioInput` at line 92) — the new built-in types — R3, R9, R10
- `src/semantics/binder3.byn` (`bindContext`, line 1141; the handler-name test and BYN6007, lines 1146–1163) — `io`
  as a `provide` handler taking an `Io` value — R12b
- `src/semantics/binder*.byn` (statement binding, found by T4 before editing) — bind `scope` with its options
  (`limit:`, `timeout:`, `until:`, `policy:`, `cancel:`), `spawn`, `shield`; BYN6009 outside a scope; the scope's
  error set as the union of the body's and the children's, plus `DeadlineError` with `timeout:`/`until:` and in every
  explicit `shield`; BYN6010; BYN6011 — R1, R3, R4, R5, R7
- `src/semantics/effects.byn` (`t23Primitives`, line 77; `analyzeEffects`, line 107) — `suspend` on `scope`, `join`,
  channel operations, `Fiber.yieldNow`, `Fiber.sleep`, child and new stdin operations and a suspending `defer` body;
  BYN6012 when the target is `wasm32` — R8b, R20
- `src/semantics/flow.byn` (`t23Assign`, line 62) — definite assignment flows out of a `scope` block, but not out of a
  `scope(cancel:)` — R2, R6b
- `src/semantics/region.byn`, `src/semantics/region2.byn` — a spawn argument borrowed by `ref` is exclusive until the
  task is joined or the scope ends (BYN3220 on a use, BYN3004 and BYN3006 with a concurrency help line); `Task<T>`
  borrows its scope (§9.4 rule 8, BYN3002 and BYN3003); BYN3217 for a borrowed `T` in `Channel<T>` — R1, R2, R3, R9
- `src/semantics/ownership.byn` (`isUnique`, line 218) — `Task<T>`, `Sender<T>`, `Receiver<T>`, `Child`, `ChildStdin`,
  `ChildReader` are `unique`; `join()`, `wait()` and `close()` consume — R3, R9, R10
- `src/semantics/express.byn` (`.unusedValue`, line 110) — a bare `spawn` statement is exempt from BYN3201 — R3
- `src/semantics/express.byn` (`b.sinkArgument` and `.untrustedSink`, lines 234–238) — `Io.start`'s program and
  arguments marked as a sink, as `Io.run`'s are, so BYN2786 applies — R10
- `src/semantics/codes.byn` — BYN6009–BYN6012, BYN3220; BYN3217 made live with a channel message; BYN6007's message
  gains `io`; BYN2606's help points to `defer canceling`; BYN2610's message names `defer canceling` — R6, R12b, R14

### Emitter
- `src/emitter/lctx.byn` (`LCleanup`, line 28) — a cleanup kind that runs on cancel, and the rule that
  `errdeferCleanup` with a binding does not — R6
- `src/emitter/lowerstmt.byn` (`deferStmt`/`errdeferStmt` cleanups, lines 113–119) — `defer canceling`; each `defer`
  body wrapped in the implicit shield; `scope`, `shield` and the spawn thunk (child arena, result copy, arena free) —
  R2, R6, R7
- `src/emitter/lowerexpr.byn` — suspend-point calls check the cancel status and propagate it — R6, R8
- `src/emitter/cprint/expr.byn` (the `byn_io_read_stdin_some` and `byn_io_run_with` thunks, lines 501 and 551) — new
  thunks for the stdin reads, `Io.start` and the child handles — R10, R11
- `src/emitter/cprint/program.byn` (`int main`, line 225; `byn_errors[]`, line 32) — a program with `suspend` starts
  the runtime's `Io.Evented(workers: 1)` (or the `#:io` choice) around `main` and the test runner's `Io.Simulated`
  around tests; the new built-in error rows — R5, R9, R12, R12b, R13

### Runtime
- `runtime/bayan-rt.c`, `runtime/bayan-rt.h` (new section) — fiber stacks and switch, ready queue, timer heap, the
  `poll` loop and the IOCP loop, `Io.Evented(workers: 1)`, `Io.Blocking`, `Io.Simulated`, channels, cancel cells,
  scope bookkeeping (`limit:` cap, deadlines, first-failure cancel) — R2–R9, R12, R12b
- `runtime/bayan-rt.c` (`byn_panic_handlers`, line 70; `byn_panic_resume`, line 112) — the handler chain becomes
  per-fiber state swapped on every switch, as `byn_context` (`runtime/bayan-rt.h` line 301) does; at the end of the
  chain, kill every live child before `abort()` — R12c, R10
- `runtime/bayan-rt.c` (`byn_io_read_stdin_some`, line 2848) — the suspending reads on fd 0 through `poll`, never
  `O_NONBLOCK` on 0–2; on Windows a reader thread feeding the port and a read-ahead buffer that `readAll` drains
  first — R11
- `runtime/bayan-rt.c` (POSIX spawn, lines 4336–4351; the fork path, line 4213; the job object, lines 3936–3985) —
  `Io.start` with the same lookup and refusal rules as `byn_io_run_with` (line 4243), default signal dispositions and
  an empty mask, its own process group or job, parent pipe ends non-blocking, `SIGPIPE` ignored around each stdin
  write as at line 4385, a live-children list for drop and abort — R10
- `runtime/bayan-rt.c` (`byn_io_monotonic_nanos`, line 4511) — the timer clock — R5, R7, R8
- `src/driver/runtime.byn` — regenerated by `scripts/selfhost/gen-driver-files.sh`; `BYN_RUNTIME_VERSION` bumped —
  R13

### Driver and tooling
- `src/driver/scaffold.byn` (`scaffoldScript`, line 32) — `bayan new --script` writes no `#:io` line — R12
- `src/driver/cc.byn` (`targetNames`, line 21) — the target name reaches the checker for BYN6012 (new field) — R20
- `src/driver/diagdocs.byn` — explain text for the new codes — R14
- `src/driver/bounds.byn` — new `bound: ` blocks for 10,000 spawns under `limit: 8` and a child streaming 100 MB — R14
- `scripts/release/memory-gate.sh`, `scripts/release/memory-gate.test.sh` — the new blocks — R14

### Cases
- `tests/cases/diag/`, `tests/cases/parse/`, `tests/cases/run/`, `tests/cases/emit/run-c.sha256` — listed under
  Testing — R1–R14, R20

### Not touched
- `bootstrap/` (regenerated only through `scripts/selfhost/land.sh` when `src/` changes, and its C must not grow fiber
  calls, R13), `src/sabk/` (spec 024's native backend; R13 asks only the C backend to compile these features),
  `lib/std/`.

## Data / interfaces
Signatures in Bayān form; effects as R8b gives them. `Duration` and `Uptime` are spec 028's.

```cs
// std.fiber
public struct unique Task<T> { public T join(move this) uses suspend fails … }   // the child's own error set
public struct CancelSource { public void cancel(this); public bool isCanceled }
CancelSource CancelSource() uses alloc
public union error DeadlineError { exceeded }
public union error ChannelError { closed }
(Sender<T> sender, Receiver<T> receiver) Channel<T>.open(capacity: i64 n) uses alloc
public struct unique Sender<T> { void send(ref this, T value) uses suspend, alloc fails ChannelError; Sender<T> share(this) }
public struct unique Receiver<T> { T? receive(ref this) uses suspend }
void Fiber.yieldNow() uses suspend
void Fiber.sleep(for: Duration d) uses suspend
void Fiber.checkCanceled()

// std.process
Child Io.start(program, args:, directory:, env:) uses process, alloc fails IoError   // Io.run's parameters, without input: and timeout:
public enum ChildStream { stdout, stderr }
public struct ChildChunk { public ChildStream from; public Untrusted<List<u8>> bytes }
public struct unique Child {
    ChildChunk? read(ref this, max: i64 limit = 65536) uses process, suspend, alloc fails IoError   // null: both streams closed
    ChildStdin? takeStdin(ref this)
    ChildReader? takeStdout(ref this)
    ChildReader? takeStderr(ref this)
    i32 wait(move this) uses process, suspend fails IoError                                         // .signaled with empty strings
}
public struct unique ChildReader {
    Untrusted<List<u8>>? read(ref this, max: i64 limit = 65536) uses process, suspend, alloc fails IoError
    Untrusted<string>? readLine(ref this, max: i64 limit) uses process, suspend, alloc fails IoError   // .lineTooLong, .invalidUtf8
}
public struct unique ChildStdin {
    void write(ref this, ReadOnlySpan<u8> bytes) uses process, suspend fails IoError                   // .closed
    void close(move this)
}

// Io.stdin, new members (read(to:), readAll(), readAllBytes() unchanged)
Untrusted<List<u8>>? read(max: i64 limit = 65536) uses console, suspend, alloc fails IoError
Untrusted<string>? readLine(max: i64 limit) uses console, suspend, alloc fails IoError
```

- `scope` options: `limit: i64`, `timeout: Duration`, `until: Uptime`, `policy: .collectAll`, `cancel: CancelSource`.
  `shield(timeout: Duration = 5s)`. `readLine` returns the line without its `\n` or `\r\n`; at EOF a last line without
  a terminator is returned, then `null`.
- Built-in error codes: `DeadlineError.exceeded`, `ChannelError.closed`, `IoError.closed` and
  `IoError.lineTooLong` take the next built-in numbers in the order of `byn_errors[]`
  (`src/emitter/cprint/program.byn`); the user-variant start in §8 moves past them. T1 writes the numbers after
  spec 026's numbering is in.
- Runtime ABI (new, `runtime/bayan-rt.h`): `byn_fiber` (stack, saved context, panic chain, context allocator, cancel
  state, name and source location for the Blocking panic), `byn_scope`, `byn_cancel_cell`, `byn_channel`, `byn_child`.
  A suspending runtime call returns `uint32_t` with a reserved cancel status that no `byn_errors[]` row uses.
- The Blocking panic: `panic: fiber `{name}` ({file}:{line}) waits on `{operation}`, which no running fiber can
  complete`.
- Diagnostics (next free in each area per `docs/DIAGNOSTICS.md`: 1xxx after BYN1080, 6xxx after BYN6008, 3xxx after
  BYN3219). Message text is a draft; T2, T4, T5 and T15 fix it with the explain page.

| Code | Name | Area | Draft message | R |
|---|---|---|---|---|
| BYN1081 | AsyncAwaitInput | parser, `// target: 19xx input form` | `` `{0}` is not Bayān; run work at once with `scope { spawn … }` and `join()` `` | D6 |
| BYN1082 | IoThreadedInput | parser, `// target: 19xx input form` | `` `#:io threaded` is now `#:io evented` `` | R12 |
| BYN1083 | UnknownIoDirective | parser, target per Addendum A2 (T2) | `` `#:io {0}` is not an `Io` choice; write `evented` or `blocking` `` | R12 |
| BYN6009 | SpawnOutsideScope | effects and concurrency | `` `spawn` is allowed only inside a `scope` block `` | R1 |
| BYN6010 | SpawnFailureLost | effects and concurrency | `` `{0}` can fail and its task is not kept, so under `.collectAll` its failure would be lost `` | R3 |
| BYN6011 | CountBelowOne | effects and concurrency | `` `{0}` must be at least 1 `` (`limit:`, `capacity:`) | R4, R9 |
| BYN6012 | SuspendOnWasm | effects and concurrency | `` `{0}` suspends, and `wasm32` has no fibers `` | R20 |
| BYN3220 | UsedWhileFiberBorrows | borrows | `` `{0}` is used while the task `{1}` holds `ref` to it `` | R2 |

Reused: BYN3217 (reserved, now live), BYN3002, BYN3003, BYN3004, BYN3006, BYN6002, BYN6007, BYN2024, BYN2601,
BYN2606, BYN2610, BYN2786, BYN3201 (exemption only), BYN0012 (other reserved words).

## Phases
### Phase 1 (0.5.0)
- T1 Spec revision and companion edits; §8 numbers; library tiers rows. Done when `bash scripts/docs/check.sh` passes.
- T2 Parser: contextual `scope`/`spawn`/`shield`, `defer canceling`, BYN1081, the `#:io` directive reader, BYN1082,
  BYN1083; `src/driver/scaffold.byn`.
- T3 Runtime core: stacks, switch, ready queue, timer heap, per-fiber panic chain and context allocator, the `poll`
  and IOCP loops. Measures the stack size and cache (Decision 1).
- T4 Checker for `scope`/`spawn`/`Task`: BYN6009, BYN6010, BYN6011, error-set union, BYN3201 exemption, effects.
- T5 Borrows and flow: BYN3220, help lines on BYN3004 and BYN3006, `Task<T>` escape, definite assignment.
- T6 Emitter: the cancel status, `scope`/`spawn`/`join`, first-failure cancel, `.collectAll`, `limit:`, child arenas
  and the result copy. Measures the copy cost (Decision 5).
- T7 Deadlines and `shield`: `timeout:`, `until:`, `DeadlineError`, the implicit `defer` shield, `Fiber.*`.
- T8 `CancelSource` and `scope(cancel:)`.
- T9 Channels, `share()`, BYN3217 live.
- T10 `Io.Blocking` with its panic, `Io.Simulated`, `provide io:`, `#:io` selection, BYN6007's message.
- T11 Suspending stdin reads on all three OSes.
- T12 `Io.start` and the child handles on POSIX; `IoError.closed`, `lineTooLong`. Measures the kill-wait, the chunk
  default and the line size used in docs (Decision 4).
- T13 The child handles on Windows (named pipes, the port, job objects).
- T14 The abort path: per-fiber `defer panicking`, `Panic.handler`, out of memory, every live child killed.
- T15 BYN6012 on `wasm32`.
- T16 R13: build the compiler and confirm `bootstrap/` and every existing `run-c.sha256` line are unchanged; confirm
  how `src/sabk/` reports a program it cannot lower and that a `suspend` program gets that report.
- T17 Bounds: `docs/memory-leaks.md` rows, `src/driver/bounds.byn` blocks, `scripts/release/memory-gate.sh`.
- T18 IDE rows P1–P4 end to end, and the P1 benchmark.
- T19 Explain pages, `docs/DIAGNOSTICS.md`, changelog, progress log.

### Phase 2 (after 0.5.0)
R15–R18c: `.perCore` workers with kqueue and epoll, `ISendable`/`IShareable` and `@sendable`, `.compute`, `Mutex`
guards and `AsyncMutex`, `Arc<T>`, `Atomic<T>`, `@threadLocal`, the debug watchdog and detector; IDE row P5. The
`CancelSource` cell's flag becomes atomic (R16 makes it sendable). Planned in its own plan.

### Phase 3
R19: `@blocking` externs on the bounded pool, after spec 023 #17. Planned in its own plan.

## Testing
- `diag/` cases, one per new diagnostic and one per changed message:
  `async-await-input`, `io-threaded-input`, `io-directive-unknown`, `spawn-outside-scope`,
  `spawn-collectall-lost-failure`, `scope-limit-zero`, `channel-capacity-zero`, `suspend-on-wasm32`,
  `spawn-ref-used-by-parent`, `spawn-ref-modified-by-sibling` (BYN3004 help), `task-returned-from-scope`,
  `channel-borrowed-item` (BYN3217), `channel-optional-item` (BYN2024), `start-untrusted-argument` (BYN2786),
  `provide-unknown-handler` (BYN6007 with `io`), `defer-failing-no-fails-help` (BYN2606), `defer-canceling-try`
  (BYN2601), `effect-start-undeclared` (BYN6002, R8b), `scope-cancel-definite-assignment`.
- `parse/` cases: `scope-forms`, `spawn-expression`, `shield-forms`, `defer-canceling`, and
  `contextual-scope-spawn-shield-names` (existing identifiers named `scope`, `spawn`, `shield` still parse).
- `run/` cases, one per runtime feature, each row of the spec's acceptance criteria: `scope-return-cancels`,
  `scope-join-string`, `scope-collectall`, `scope-first-failure`, `scope-limit`, `scope-timeout`, `scope-until`,
  `cancel-catch-passes`, `cancel-defer-forms`, `cancel-source-two-scopes`, `cancel-source-after`, `shield-delays`,
  `shield-timeout`, `shield-nested`, `fiber-yield-interleave`, `fiber-sleep`, `channel-three-senders`,
  `channel-closed`, `stdin-read-message` (with `.stdin`), `stdin-readline-cap`, `child-stream-lines`,
  `child-line-too-long`, `child-drop-kills`, `child-signaled`, `child-sigpipe`, `child-stdin-closed`,
  `blocking-deadlock-panic`, `panic-kills-children`, `io-blocking-directive`. Timing rows use
  `BAYAN_TEST_TIME_SCALE`.
- `test` blocks under `Io.Simulated`: deterministic interleaving, virtual time for `Fiber.sleep` and deadlines, the
  refusal of `Io.start` (Decision 7), and `provide io: Io.Evented(workers: 1)`.
- Script tests: a new `scripts/` `.test.sh` (the script part of `bash scripts/test.sh`) checks that stdin's file status flags (`fcntl F_GETFL`) are the same after the program
  exits, for a pipe and, where a pty is available, a terminal (R11).
- Memory bounds (rules 4, 6 and 8 of `docs/memory-leaks.md`): `bound: ` blocks in `src/driver/bounds.byn` for 10,000
  spawns under `limit: 8` and for a child streaming 100 MB through `readLine` and through `read(max:)`, measured
  with `scripts/release/peak-rss.sh`, added to the release gate and to `scripts/release/memory-gate.sh`. The bound
  numbers are set from T17's measurements and recorded in `docs/memory-leaks.md`.
- IDE rows P1–P4: end-to-end tests through `bayan run` and a built program, with a Bayān stand-in child for P2; the P1
  median from a separate unloaded benchmark.
- OS coverage: `.github/workflows/ci.yml`'s matrix (`ubuntu-latest`, `macos-latest`, `windows-latest`) runs every
  case above. The bound blocks are pending on Windows, as every `bound: ` block is (no `sh` or `ps`), so T13 adds one
  Windows child-streaming `run/` case with a fixed output size. Full runs, Windows runs and the benchmark go to wp1 or
  wlt1, never the working machine.
- `tests/cases/emit/run-c.sha256`: new lines only; T16 checks that no existing line changed.

## Risks & mitigations
- A frame that suspends but was lowered without the cancel status would skip defers. Mitigation: the checker's
  inferred `suspend` effect, not a syntactic test, decides the lowering; T6 adds a `run/` case with a private
  function that suspends only through inference.
- Per-fiber state missed in the switch (`byn_panic_handlers`, `byn_context`, coverage counters, stdout buffer
  ownership). Mitigation: T3 lists every `_Thread_local` and file-level mutable in `runtime/bayan-rt.c` and records
  for each whether it is per-fiber or per-worker.
- A child-arena value escapes through a path Decision 5 did not name (a module-level `var`, an `Untrusted` wrapper).
  Mitigation: T6 lists every way a child can store outside its frame; any path not covered makes that child run in
  the parent's allocator.
- Adding `IoError` variants breaks exhaustive switches if spec 026 has not landed. Mitigation: the dependency above;
  otherwise T12 fixes every BYN2410 site in the same change.
- Windows stdin read-ahead takes bytes a later blocking `readAll` expects. Mitigation: `readAll` and `read(to:)`
  drain the read-ahead buffer first; a `run/` case mixes them.
- A child in its own process group that reads the terminal gets `SIGTTIN`. Mitigation: streamed children get piped
  stdin; the explain text says so.
- A parent killed by `SIGKILL` cannot kill its children on POSIX (Windows job objects with
  `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` do). Mitigation: documented as outside R10, which names panics and out of
  memory.
- The fiber stack overflow is a plain crash, as on the thread stack today, and live children survive it on POSIX.
  Mitigation: the guard page makes it a crash, not corruption; an overflow handler is noted for phase 2.
- `Io.stdin.read(to:)` (blocking) and `read(max:)` (suspending) look alike, and the blocking one stalls every fiber.
  Mitigation: the explain page of BYN6002 and the §15.1 text name the difference; a style note can follow later.
- Another plan claims BYN6009–6012, BYN1081–1083 or BYN3220 first. Mitigation: T1 adds them to
  `docs/diagnostics-allocated.txt` as `plan` rows, and `scripts/docs/check.sh` fails on a duplicate.
- The P1 10 ms median depends on `poll` wake-up latency and the stdout flush. Mitigation: T18 measures it on Linux,
  macOS and Windows; the stdin reads flush stdout first, as `read(to:)` does today.

## Coverage check
| R | Covered by |
|---|---|
| R1 | Semantics (BYN6009, BYN3217 scope), Testing `spawn-outside-scope`; T4 |
| R2 | Decisions 5; Semantics (flow, region); Emitter (spawn thunk); Testing `scope-return-cancels`, `scope-join-string`, `spawn-ref-*`; T5, T6 |
| R3 | Semantics (builtins, ownership, BYN6010, BYN3201 exemption); Testing `scope-collectall`, `scope-first-failure`, `task-returned-from-scope`; T4, T6 |
| R4 | Semantics (BYN6011); Runtime (cap); Testing `scope-limit`, `scope-limit-zero`; T4, T6 |
| R5 | Runtime (timer heap); Data (`DeadlineError`); Testing `scope-timeout`, `scope-until`; T7 |
| R6 | Approach (cancel status); Emitter (lctx, lowerstmt); Testing `cancel-catch-passes`, `cancel-defer-forms`; T6 |
| R6b | Decision 8; Semantics (flow); Testing `cancel-source-*`, `scope-cancel-definite-assignment`; T8 |
| R7 | Emitter (implicit shield); Testing `shield-*`; T7 |
| R8 | Data (`Fiber`); Testing `fiber-yield-interleave`, `fiber-sleep`; T7 |
| R8b | Semantics (effects); Testing `effect-start-undeclared`; T4, T12 |
| R9 | Data (channels); Semantics (BYN3217, BYN2024, BYN6011); Testing `channel-*`; T9 |
| R10 | Decisions 3, 4, 6; Runtime (spawn, live-children list); Testing `child-*`, `panic-kills-children`; T12, T13, T14 |
| R11 | Decision 3; Runtime (stdin); Testing `stdin-*`, the flags script test; T11 |
| R12 | Lexer and parser (`#:io`, BYN1082, BYN1083); Runtime (`Io.Blocking`); Testing `blocking-deadlock-panic`, `io-blocking-directive`; T2, T10 |
| R12b | Decision 7; Semantics (`bindContext`); Testing `test` blocks under `Io.Simulated`; T10 |
| R12c | Runtime (per-fiber panic chain); Testing `panic-kills-children`; T14 |
| R13 | Approach; Not touched; T16 |
| R14 | Data (codes); Spec and documents; Testing (diag, run, bounds); T17, T19 |
| R15 | Phase 2; not covered by this plan (phase 2 plan) |
| R16 | Phase 2; not covered by this plan (phase 2 plan) |
| R17 | Phase 2; not covered by this plan (phase 2 plan) |
| R18 | Phase 2; not covered by this plan (phase 2 plan) |
| R18b | Phase 2; not covered by this plan (phase 2 plan) |
| R18c | Phase 2; not covered by this plan (phase 2 plan) |
| R19 | Phase 3; not covered by this plan (phase 3 plan, after spec 023 #17) |
| R20 | Semantics (effects, BYN6012); Driver (`cc.byn`); Testing `suspend-on-wasm32`; T15 |
| D6 (`async`/`await`) | Decision 10; Lexer and parser (BYN1081); Testing `async-await-input`; T2 |
| P1–P4 | Testing (IDE rows); T18 |

Gaps: R15–R19 and P5 are phase 2 and 3 work, as the spec's acceptance criteria say; nothing in phase 1 is
uncovered.
