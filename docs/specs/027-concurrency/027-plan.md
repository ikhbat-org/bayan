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

The lowering is the central choice. A function that may be canceled lowers to C as a function with an error
channel, whether or not it fails, and that channel has one hidden status, cancel. "May be canceled" (`mayCancel`) is
an emitter-internal bit, not an effect: the transitive closure over calls of the `suspend` effect (declared or
inferred) and of `Fiber.checkCanceled()`. `Fiber.checkCanceled()` has no effect (R8b), so a function without
`suspend` that calls it still unwinds and runs `defer canceling` (R8) without gaining `suspend` or BYN6012. An
indirect call (a lambda, a function value, an interface method) lowers with the channel when the program has any
`mayCancel` function. A suspend point or `Fiber.checkCanceled()` that finds a cancel pending returns cancel. The
emitter propagates it like an error through every frame, runs `defer`, bare `defer failing` and `defer canceling` on
the way, skips `defer failing (e)`, and never lets a `catch` take it. The status names its target scope: only that
scope turns it back into a normal exit (R6b) or into `DeadlineError.exceeded` (R5), any other scope boundary passes
it on, and when an inner and an enclosing cancel are both pending the fiber keeps the outermost target (R6b's "a
cancel of an enclosing scope … continues outward"). Nothing in the source language sees the status: it is in no
`fails` list.

Parking is real stack switching: a parked fiber keeps its C stack and the worker runs another fiber. So fibers stay
colorless, and a library function that reads a child's pipe works the same from `main` or from a spawned child.

A program with no `mayCancel` function emits no fiber calls. The runtime's fiber code is reached only from emitted
calls, so the compiler (R13) and the bootstrap stay free of it. Their C still changes in one place: `byn_errors[]`
and `byn_exit_codes` hold a row for every built-in variant (`src/emitter/cprint/program.byn:37`; `IoError` is bound in
every program, `src/semantics/builtins.byn:208`), so the new built-in sets and `IoError` variants change `bootstrap/`
and every existing `tests/cases/emit/run-c.sha256` line once, in T4. That diff is checked to touch only those rows
and the user error codes after them; after T4, `run-c.sha256` changes only for new cases.

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
   one `PROT_NONE` guard page of `sysconf(_SC_PAGESIZE)` bytes below each (16 KiB on macOS AArch64; POSIX `mmap`;
   Windows `CreateFiberEx` with 64 KiB committed and 1 MiB reserved, whose guard page the OS keeps). Freed stacks go
   to a cache of at most 16 and the rest are unmapped. An overflow faults on the guard page and the process dies, as
   a thread-stack overflow does today; there is no overflow handler in phase 1. Context switches are a short assembly
   switch for x86-64 SysV and AArch64 (the `linux-*` and `macos-*` targets of `targetNames` in `src/driver/cc.byn`)
   and the Fibers API on `windows-*`. The switch saves each ABI's callee-saved state: x86-64 SysV `rbx`, `rbp`,
   `r12`–`r15`, `rsp` and the MXCSR and x87 control words; AArch64 `x19`–`x28`, `fp`, `lr`, `sp` and `d8`–`d15`.
   Rejected: segmented or growable stacks. The C backend has no stack maps, so a stack cannot be moved or grown in
   place, and C frames from libc or a future `extern c` cannot be split. Rejected for the switch: `ucontext`, which
   musl (the `linux-*` triples are `*-linux-musl`) does not provide and which makes a signal-mask syscall per switch.
   Provisional values (1 MiB, 16 cached): measured against the R14 bound in T17 and the P1 benchmark in T18, once
   those exist.
2. **Event-loop backend.** Chosen: one loop interface in the runtime with two backends in phase 1: `poll(2)` on POSIX
   (stdin, the parent ends of child pipes, one wake pipe, a `SIGCHLD` handler that writes to the wake pipe, a timer
   heap on `byn_io_monotonic_nanos`) and an I/O completion port on Windows, which learns of child exits through
   `RegisterWaitForSingleObject`. One worker watches a handful of descriptors, so `poll` costs nothing measurable
   there. `poll` cannot wait on a pid, and pipe EOF is not an exit (a child may close its pipes and keep running, and
   a grandchild may hold them open), so on each wake the loop reaps only the pids on its live-children list with
   `waitpid(pid, &status, WNOHANG)`. `Io.run` already waits for its own pid that way (`runtime/bayan-rt.c:4444`), so
   neither steals the other's child. The handler is installed with `SA_RESTART | SA_NOCLDSTOP` when the first
   streamed child starts. Rejected: kqueue and epoll in phase 1. They pay off with many descriptors and many workers
   (phase 2 sockets and `.perCore`), and each extra backend adds platform-specific code that must pass P1–P4 first.
   Phase 2 swaps in kqueue and epoll behind the same interface.
3. **Method names.** Chosen: `Io.start(…)` returns a `unique` `Child`. `child.read(max:)` is spec 023 R14's
   combined next-chunk read (stdout or stderr, whichever is ready). `child.takeStdin()`, `child.takeStdout()` and
   `child.takeStderr()` split off `unique` `ChildStdin` and `ChildReader` handles, once each (a second call returns
   `null`). `ChildReader` and `Io.stdin` get `read(max:)` and `readLine(max:)`. `ChildStdin` gets `write(_)` and
   `close(move this)`. `child.wait(move this)` returns the exit code. The existing `Io.stdin.read(to:)`, `readAll()`
   and `readAllBytes()` keep their names and their blocking behavior. Rejected: `Io.spawn` for the child, which
   reuses the fiber keyword for a different thing; and spec 023 R14's `read(into:)` spelling, which would rename the
   shipped `Io.stdin.read(to:)` (§15.1). The new reads differ from it by particle (`max:` against `to:`), which
   overloads already allow. Whether the chunk reads allocate (`read(max:)`) or fill a caller's buffer, the shape R11
   names, is Needs decision 2.
4. **Kill-wait and per-line cap defaults.** Chosen: dropping a running `Child` sends `SIGKILL` to its process group
   (POSIX) or calls `TerminateJobObject` (Windows), then parks the dropping fiber for at most 1 s while the event loop
   waits for the exit; past that it writes one line to stderr naming the pid and continues, and the event loop reaps
   the child later. The wait runs as a shield, so a pending cancel does not cut it short, and other fibers run
   meanwhile (P1). Dropping a `Child` is therefore a suspend point: a function that drops one infers `suspend`, and
   `Io.start` has `suspend` too (R8b's criterion, `docs/specs/027-concurrency/027-spec.md:231`), so an owner already
   has it. Under `Io.Blocking` the wait blocks the thread, as every OS wait there does (R12). `readLine` has no default: `max:` is a
   required argument, and the examples and docs use 1 MiB. `read(max:)` defaults to 64 KiB, the size of one half of
   `Io.run`'s bounded capture. Rejected: `SIGTERM` first with `Io.run`'s 2 s grace (`BYN_RUN_GRACE_MS`): a child that
   ignores it would miss P3's 100 ms, and a caller that wants a graceful stop closes stdin and calls `wait()`.
   Provisional (1 s, 64 KiB, the 1 MiB used in docs): the kill-wait measured against P3 in T18, the chunk default and
   the line size against the R14 bound in T17.
5. **Child results out of the child arena (R2).** Chosen: relocate on exit. A child runs with a child arena as
   `context.allocator`. When it ends, the spawn thunk relocates its result, or its error payload if it failed
   (`IoError.signaled` carries two strings), into the parent's allocator, then frees the arena. Relocation is
   emitter-internal: the deep walk `copy()` lowers to, extended to `unique` types, so a user `unique` struct with
   `string` fields is relocated field by field while `copy()` itself stays unavailable on it (R9, D8). The runtime
   allocates its handles (`Sender<T>`, `Receiver<T>` and their channel, `Child`, `ChildStdin`, `ChildReader`) from its
   own heap, not `context.allocator`, and frees them in their `unique` drop, so relocation moves their pointer.
   Channels: `send` relocates the value into a slot buffer the channel owns, and `receive` relocates it into the
   receiving fiber's `context.allocator` and frees the slot buffer, so a streaming channel holds at most `capacity`
   items (R14). A child whose spawn call passes a `ref` argument or a mutable `Span<T>` runs in the parent's allocator
   with no arena, so nothing it stores through a parent borrow can dangle. A `ref` to a runtime handle is exempt,
   because none of its operations stores into the caller's allocator (`send` fills the slot buffer, `receive` and the
   child reads allocate in the child's own arena), so the Approach's `ref Sender<…>` worker keeps its arena. Until
   Needs decision 1 is answered, relocation copies a `CancelSource` by pointer (copies share its cell, R6b), and a
   child whose result type, error payloads, arguments or sent item types contain a `CancelSource` runs in the
   parent's allocator with no arena, so a cell made in a child arena never outlives it. This also covers
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
8. **`CancelSource` shared state.** Chosen: `CancelSource()` allocates one small cell (the canceled flag and an
   intrusive doubly linked list of attached scopes) from `context.allocator`; copies share the cell, and it lives as
   long as that allocator (its placement when a source leaves a child arena: Decision 5 and Needs decision 1). Each
   `scope(cancel:)` links a node kept in its own `byn_scope` frame into the cell's list on entry and unlinks it on
   exit, so one source attached to two live scopes (nested or siblings) cancels both, a cancel after every scope
   ended does nothing, and `isCanceled` still reads the flag. `CancelSource()` therefore uses `alloc`. Rejected: a
   generation-checked runtime table like §9.6's `Handle<T>`. A slot freed at scope exit forgets a cancel made before
   attaching and loses `isCanceled` after the block (R6b needs both), and a slot kept forever grows with every
   request. Rejected: one attached-scope slot, which a second attachment would overwrite.
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
  `mprotect`, `sysconf(_SC_PAGESIZE)`, `poll`, `sigaction` for `SIGCHLD`, `waitpid` with `WNOHANG`, `posix_spawn`
  with `POSIX_SPAWN_SETSIGDEF` (its set includes `SIGCHLD`), `POSIX_SPAWN_SETSIGMASK` and `POSIX_SPAWN_SETPGROUP` on
  POSIX, and `CreateFiberEx`, `SwitchToFiber`, `IsThreadAFiber`, `ConvertThreadToFiber`, named pipes with
  `FILE_FLAG_OVERLAPPED`, `CreateIoCompletionPort`, `RegisterWaitForSingleObject` and job objects on Windows.
- Spec 028 lands first: `Duration`, `Uptime` and unit literals (`50ms`) are the types of `timeout:`, `until:` and
  `Fiber.sleep(for:)`.
- Spec 023 #9 (units) lands first, through spec 028. Spec 023 #17 (`extern c`) is needed only by phase 3.
- Spec 026 lands before T1: T1 writes §8's built-in numbers after 026's numbering is in (Data / interfaces), and once
  `IoError` is `extensible`, adding `closed` and `lineTooLong` in T4 does not break switches. 026 is approved and not
  landed (no `extensible` under `src/semantics/` today).
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
- `docs/diagnostics/BYN1081.md` … `BYN1084.md`, `BYN6009.md` … `BYN6013.md`, `BYN3220.md` — new explain pages, each
  landing with the task that adds its code;
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
  statement before `{` or `( … ) {`, with `atContextual`; for the `(` form, `matchingClose`
  (`src/parser/stmts.byn:638`) finds the balanced `)` and the next token must be `{`, so a call statement
  `scope(x)` still parses as a call — R2, R4, R5, R6b, R7
- `src/parser/exprs.byn` (`parsePrefixed`, line 310) — `spawn` before a name on the same line (`breaksLine`,
  `src/parser/recover.byn:79`) starts a spawn expression, so `return spawn` followed by a newline stays a return of
  an identifier named `spawn` (D6) — R3
- `src/parser/stmts2.byn` (`parseDefer`, line 143; the contextual `failing`/`panicking` test, line 157) — `canceling`
  after `defer` — R6
- `src/parser/nodes.byn` (`DeferKind`, line 781) — a `canceling` case; new `ScopeStmt`, `ShieldStmt`, `SpawnExpr`
  nodes — R2, R3, R6, R7
- `src/parser/dump.byn`, `src/parser/dump2.byn` — the new nodes in the parse dump — R2, R3
- `src/parser/codes.byn` — BYN1081, BYN1082, BYN1083, BYN1084 with `// target:` comments — R12, R14

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
  error set as the union of the body's and the children's, except under `policy: .collectAll`, where it is the body's
  alone and a child's set reaches the parent only through its `join()` (R3); plus `DeadlineError` with
  `timeout:`/`until:` and in every explicit `shield`; BYN6010; BYN6011. Options together: `timeout:` with `until:`
  takes the earlier deadline; `cancel:` with either ends the scope normally on a source cancel and fails it with
  `DeadlineError.exceeded` on the deadline, whichever comes first; a child's earlier failure beats both (R5); a
  dynamic `limit:` below 1 traps (R4) — R1, R3, R4, R5, R7
- `src/semantics/effects.byn` (`t23Primitives`, line 77; `analyzeEffects`, line 107) — `suspend` on `scope`, `join`,
  channel operations, `Fiber.yieldNow`, `Fiber.sleep`, `Io.start`, the dropping of a `Child` (Decision 4), child and
  new stdin operations and a suspending `defer` body; none on `Fiber.checkCanceled()`; BYN6012 when the target is
  `wasm32`; BYN6013 for an `Io.Evented(workers:)` constant other than 1 — R8b, R12, R20
- `src/semantics/flow.byn` (`t23Assign`, line 62) — definite assignment flows out of a `scope` block, but not out of a
  `scope(cancel:)` — R2, R6b
- `src/semantics/region.byn`, `src/semantics/region2.byn` — a spawn argument or method receiver (`spawn
  obj.method()`) borrowed by `ref` is exclusive until the task is joined or the scope ends (BYN3220 on a use, BYN3004
  and BYN3006 with a concurrency help line); one borrowed read-only cannot be mutated by the parent or a sibling for
  as long (BYN3004, `ModifiedWhileBorrowed`, `src/semantics/codes.byn:485`, with the same help line); a spawn that
  borrows a local declared in a block nested inside the scope, which dies before the scope ends, is BYN3002
  (`BorrowOutlivesSource`, `src/semantics/codes.byn:483`) with a concurrency help line; `Task<T>` borrows its scope
  (§9.4 rule 8, BYN3002 and BYN3003); BYN3217 for a borrowed `T` in `Channel<T>` — R1, R2, R3, R9
- `src/semantics/ownership.byn` (`isUnique`, line 218) — `Task<T>`, `Sender<T>`, `Receiver<T>`, `Child`, `ChildStdin`,
  `ChildReader` are `unique`; `join()`, `wait()` and `close()` consume — R3, R9, R10
- `src/semantics/express.byn` (`.unusedValue`, line 110) — a bare `spawn` statement is exempt from BYN3201 — R3
- `src/semantics/express.byn` (`b.sinkArgument` and `.untrustedSink`, lines 234–238) — `Io.start`'s program and
  arguments marked as a sink, as `Io.run`'s are, so BYN2786 applies — R10
- `src/semantics/codes.byn` — BYN6009–BYN6013 with `// target: 6xxx concurrency` and BYN3220 with
  `// target: 3xxx borrows` (Addendum A2, `docs/revisions/0017-addendum-a2-diagnostic-codes.md:57`); BYN3217 made live with a channel message; BYN6007's message
  gains `io`; BYN2606's help points to `defer canceling`; BYN2610's message names `defer canceling` — R6, R12b, R14

### Emitter
- `src/emitter/lctx.byn` (`LCleanup`, line 28) — a cleanup kind that runs on cancel, and the rule that
  `errdeferCleanup` with a binding does not — R6
- `src/emitter/lowerstmt.byn` (`deferStmt`/`errdeferStmt` cleanups, lines 113–119) — `defer canceling`; each
  `mayCancel` `defer` body wrapped in the implicit shield (a body that cannot suspend cannot be canceled, so pure
  defers keep today's C, R13, R20): its 5 s grace timer is armed only when a cancel is pending at entry or arrives
  mid-body, each `defer` gets its own, at expiry the rest of that body is abandoned and the next `defer` runs, and a
  panic unwind arms none (R7); `scope`, `shield` and the spawn thunk (child arena, relocation of the result or error
  payload, arena free); `return`, `break`, `continue` and `try` that leave a `scope` run its exit (cancel unfinished
  children, wait for all) as a cleanup, as they run `defer`; a `spawn` under `limit:` is a suspend point that parks at
  the cap and checks cancel — R2, R4, R6, R7
- `src/emitter/lowerexpr.byn` — the `mayCancel` bit (Approach); calls to `mayCancel` functions and suspend points
  check the cancel status and propagate it; `Fiber.checkCanceled()` lowers to the check alone — R6, R8
- `src/emitter/cprint/expr.byn` (the `byn_io_read_stdin_some` and `byn_io_run_with` thunks, lines 501 and 551) — new
  thunks for the stdin reads, `Io.start` and the child handles — R10, R11
- `src/emitter/cprint/program.byn` (`int main`, line 225; `byn_errors[]`, line 32) — a program with `suspend` starts
  the runtime's `Io.Evented(workers: 1)` (or the `#:io` choice) around `main` and the test runner's `Io.Simulated`
  around tests; the new built-in error rows — R5, R9, R12, R12b, R13

### Runtime
- `runtime/bayan-rt.c`, `runtime/bayan-rt.h` (new section) — fiber stacks and switch, ready queue, timer heap, the
  `poll` loop and the IOCP loop, `Io.Evented(workers: 1)`, `Io.Blocking`, `Io.Simulated`, channels, cancel cells,
  scope bookkeeping (`limit:` cap, deadlines, first-failure cancel, the cancel target) — R2–R9, R12, R12b
- `runtime/bayan-rt.c` (`Io.Blocking`) — `spawn` runs the child inline to its end before the parent continues (R12);
  `Fiber.yieldNow` does nothing; `Fiber.sleep` and the kill-wait block the thread; a deadline is checked at every
  suspend point and bounds every OS wait, so a child sleeping past `scope(timeout:)` wakes at the deadline and
  unwinds — R5, R8, R12
- `runtime/bayan-rt.c` (`Io.Simulated`) — when every fiber is parked and no virtual timer is pending, it panics with
  the Blocking panic's text (D7) instead of hanging — R12b
- `runtime/bayan-rt.c` (`provide io:`) — `provide io: X { … }` runs its block on a new scheduler of kind X on the
  current thread; the entering fiber, and the outer scheduler's other fibers, resume only after every fiber of the
  block has ended, as the block is a scope. On Windows a scheduler calls `ConvertThreadToFiber` only when
  `IsThreadAFiber()` is false, and converts back only if it converted — R12b
- `runtime/bayan-rt.c` (`byn_panic_handlers`, line 70; `byn_panic_resume`, line 112) — the handler chain becomes
  per-fiber state swapped on every switch, as `byn_context` (`runtime/bayan-rt.h` line 301) does. An
  allocation-free `byn_kill_all_children()` (`SIGKILL` to each live group, `TerminateJobObject` on Windows, no wait)
  runs at both abort sites: before the `abort()` that ends the chain (line 127) and before the panic-in-a-handler
  `abort()` in `byn_panic_raise` (line 95). Out of memory already reaches the chain: every allocation failure calls
  `byn_panic("out of memory", …)` (for example line 1413), which raises through `byn_panic_resume` (line 107) —
  R12c, R10
- `runtime/bayan-rt.c` (`byn_io_read_stdin_some`, line 2848) — the suspending reads on fd 0 through `poll`, never
  `O_NONBLOCK` on 0–2. On every OS one stdin read-ahead buffer, which `read(max:)`, `readLine(max:)`, `readAll`,
  `readAllBytes` and `read(to:)` all drain first, so `readLine` makes no one-byte reads and bytes it read ahead are
  not lost to a later `readAll`. One stdin reader at a time: another fiber reading stdin parks in a FIFO waiter
  queue, so one `POLLIN` wakes one reader and no second blocking `read(0, …)` stalls the worker. On Windows a reader
  thread feeding the port fills the same buffer — R11
- `runtime/bayan-rt.c` (POSIX spawn, lines 4336–4351; the fork path, line 4213; the job object, lines 3936–3985) —
  `Io.start` with the same lookup and refusal rules as `byn_io_run_with` (line 4243), default signal dispositions
  (`SIGCHLD` included) and an empty mask on both paths: the fork path (`byn_fork_exec`, taken whenever `directory:`
  is given, line 4334) already calls `setpgid(0, 0)` for a grouped child (line 4213) and gains a `SIG_DFL` loop and
  `sigprocmask` before `exec`. Its own process group or job, parent pipe ends non-blocking, `SIGPIPE` ignored around
  each stdin write as at line 4385, a live-children list for drop, `wait` and abort, reaped as Decision 2 says.
  `take*()` moves the pipe's fd (on Windows its handle and `OVERLAPPED`) into the new handle, so the `Child`'s drop
  and `wait` close only untaken pipes; `byn_child` holds the pid or process handle, the group or job and the untaken
  pipes, and no split handle points into it — R10
- `runtime/bayan-rt.c` (`byn_io_monotonic_nanos`, line 4511) — the timer clock under `Io.Evented` and `Io.Blocking`.
  `Uptime.now()`, deadlines and `Fiber.sleep` read the active `Io`'s clock hook, which is the virtual clock under
  `Io.Simulated`, so `scope(until: Uptime.now() + 50ms)` in a test uses one clock — R5, R7, R8, R12b
- `src/driver/runtime.byn` — regenerated by `scripts/selfhost/gen-driver-files.sh`; `BYN_RUNTIME_VERSION` bumped —
  R13

### Driver and tooling
- `src/driver/scaffold.byn` (`scaffoldScript`, line 32) — `bayan new --script` writes no `#:io` line — R12
- `src/driver/` (where the entry file is chosen; T2 finds the file before editing) — BYN1084 for a `#:io` directive
  in any file but the entry file (the script, or the file with `main`), and for a second `#:io` in the entry file,
  so a library never chooses an `Io` (R12) — R12
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
public struct unique Sender<T> { void send(ref this, T value) uses suspend, alloc fails ChannelError; Sender<T> share(this); void close(move this) }
public struct unique Receiver<T> { T? receive(ref this) uses suspend }
void Fiber.yieldNow() uses suspend
void Fiber.sleep(for: Duration d) uses suspend
void Fiber.checkCanceled()

// std.process
Child Io.start(program, args:, directory:, env:) uses process, suspend, alloc fails IoError   // Io.run's parameters, without input: and timeout:
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

// Io implementations (spelling of docs/bayan-concurrency.md:31)
Io Io.Evented(workers: i64 n)   // phase 1: n is 1; another constant is BYN6013, another value traps
Io Io.Blocking                  // a value, not a call
Io Io.Simulated                 // a value, not a call
```

- `scope` options: `limit: i64`, `timeout: Duration`, `until: Uptime`, `policy: .collectAll`, `cancel: CancelSource`.
  `shield(timeout: Duration = 5s)`. `readLine` returns the line without its `\n` or `\r\n`; at EOF a last line without
  a terminator is returned, then `null`.
- Contracts:
  - `child.read(max:)` reads only the streams not taken; after both `takeStdout()` and `takeStderr()` it returns
    `null`.
  - Dropping a `ChildStdin` closes it as `close()` does; `close()` makes the point explicit.
  - `child.wait()` closes an untaken stdin first, so a child reading stdin sees EOF; a taken `ChildStdin` stays open
    until its own close or drop. A `ChildReader` taken before `wait()` keeps reading what the pipe holds until EOF.
  - After `IoError.invalidUtf8` the bad line is consumed and the next `readLine` starts at the next line.
  - `max:` below 1 on any read traps, as a dynamic `limit:` below 1 does (R4).
  - A `Task<T>` dropped without `join()` cancels nothing: its child runs until it ends or the scope ends, its result
    is dropped there, and under the default policy its failure still fails the scope.
  - `Sender<T>.close(move this)` ends that sender; `receive` returns `null` once every sender is closed or dropped
    and the buffer is drained (R9).
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
  BYN3219). Message text is a draft; T2, T4, T5, T10 and T15 fix it with the explain page.

| Code | Name | Area | Draft message | R |
|---|---|---|---|---|
| BYN1081 | AsyncAwaitInput | parser, `// target: 19xx input form` | `` `{0}` is not Bayān; run work at once with `scope { spawn … }` and `join()` `` | D6 |
| BYN1082 | IoThreadedInput | parser, `// target: 19xx input form` | `` `#:io threaded` is now `#:io evented` `` | R12 |
| BYN1083 | UnknownIoDirective | parser, `// target: 0xxx project` | `` `#:io {0}` is not an `Io` choice; write `evented` or `blocking` `` | R12 |
| BYN1084 | IoDirectiveMisplaced | driver, `// target: 0xxx project` | `` `#:io` chooses the program's `Io`, so it belongs once, in the entry file `` | R12 |
| BYN6009 | SpawnOutsideScope | effects and concurrency, `// target: 6xxx concurrency` | `` `spawn` is allowed only inside a `scope` block `` | R1 |
| BYN6010 | SpawnFailureLost | effects and concurrency, `// target: 6xxx concurrency` | `` `{0}` can fail and its task is not kept, so under `.collectAll` its failure would be lost `` | R3 |
| BYN6011 | CountBelowOne | effects and concurrency, `// target: 6xxx concurrency` | `` `{0}` must be at least 1 `` (`limit:`, `capacity:`) | R4, R9 |
| BYN6012 | SuspendOnWasm | effects and concurrency, `// target: 6xxx concurrency` | `` `{0}` suspends, and `wasm32` has no fibers `` | R20 |
| BYN6013 | WorkersNotOne | effects and concurrency, `// target: 6xxx concurrency` | `` phase 1 runs one worker; write `Io.Evented(workers: 1)` `` | R12 |
| BYN3220 | UsedWhileFiberBorrows | borrows, `// target: 3xxx borrows` | `` `{0}` is used while the task `{1}` holds `ref` to it `` | R2 |

Reused: BYN3217 (reserved, now live), BYN3002, BYN3003, BYN3004, BYN3006, BYN6002, BYN6007, BYN2024, BYN2601,
BYN2606, BYN2610, BYN2786, BYN3201 (exemption only), BYN0012 (other reserved words).

## Phases
### Phase 1 (0.5.0)
Spec 026 lands before T1 (Tech / dependencies). Each task lands the explain pages of the codes it adds.
- T1 Spec revision and companion edits; §8 numbers; library tiers rows; every new code (BYN1081–1084, BYN6009–6013,
  BYN3220) added to `docs/diagnostics-allocated.txt` as a `plan` row. Done when `bash scripts/docs/check.sh` passes.
- T2 Parser: contextual `scope`/`spawn`/`shield` (same-line `spawn`, `matchingClose` lookahead), `defer canceling`,
  BYN1081, the `#:io` directive reader, BYN1082, BYN1083, BYN1084 in the driver; `src/driver/scaffold.byn`.
- T3 Runtime core: stacks (page-size guard), the switch with each ABI's callee-saved registers, ready queue, timer
  heap with the clock hook, per-fiber panic chain and context allocator, the `poll` loop with the `SIGCHLD` wake and
  the IOCP loop. Every existing `run/` case still passes; the stack size and cache are measured in T17 and T18.
- T4 Checker for `scope`/`spawn`/`Task`: BYN6009, BYN6010, BYN6011, the error set (the `.collectAll` rule), option
  precedence, BYN3201 exemption, effects (`Io.start` and `Child` drop with `suspend`). The built-in sets
  `DeadlineError` and `ChannelError` and `IoError`'s `closed` and `lineTooLong` with their `byn_errors[]` rows: the
  one regeneration of `bootstrap/` and of every `run-c.sha256` line, diffed to show only those rows and the user
  codes after them (Approach).
- T5 Borrows and flow: BYN3220, help lines on BYN3002, BYN3004 and BYN3006, read-only spawn borrows, method receivers,
  locals of nested blocks, `Task<T>` escape, definite assignment.
- T6 Emitter: the `mayCancel` bit and the cancel status with its target scope, `scope`/`spawn`/`join`, scope exit on
  `return`/`break`/`continue`/`try`, first-failure cancel, `.collectAll`, `limit:` (spawn as a suspend point),
  child arenas and relocation of results, error payloads and `unique` values. Measures the relocation cost
  (Decision 5).
- T7 Deadlines and `shield`: `timeout:`, `until:`, `DeadlineError`, the implicit `defer` shield with lazy grace,
  `Fiber.*` including `Fiber.checkCanceled()`.
- T8 `CancelSource` and `scope(cancel:)`, the cell's list of attached scopes; the cell's placement per Needs
  decision 1.
- T9 Channels, `share()`, `close()`, slot buffers freed on `receive`, BYN3217 live.
- T10 `Io.Blocking` with its panic, `Io.Simulated` with its virtual clock and deadlock panic, `provide io:` and its
  nesting, `#:io` selection, BYN6007's message, BYN6013.
- T11 Suspending stdin reads on all three OSes, the shared read-ahead buffer and the waiter queue (the chunk read's
  shape per Needs decision 2).
- T12 `Io.start` and the child handles on POSIX: `SIGCHLD` reaping, fd transfer on `take*()`, default signals on both
  spawn paths, the parked kill-wait; `IoError.closed`, `lineTooLong` raised.
- T13 The child handles on Windows (named pipes, the port, job objects).
- T14 The abort path: per-fiber `defer panicking`, `Panic.handler`, out of memory, every live child killed at both
  abort sites.
- T15 BYN6012 on `wasm32`.
- T16 R13: build the compiler and confirm the regenerated `bootstrap/` C contains no call into the fiber runtime and
  that no `run-c.sha256` line present after T4 changed; confirm how `src/sabk/` reports a program it cannot lower
  and that a `suspend` program gets that report.
- T17 Bounds: `docs/memory-leaks.md` rows, `src/driver/bounds.byn` blocks, `scripts/release/memory-gate.sh`. Measures
  the stack cache (Decision 1), the chunk default and the line size used in docs (Decision 4) against the bounds.
- T18 IDE rows P1–P4 end to end, and the P1 benchmark. Measures the stack size (Decision 1) and the kill-wait
  (Decision 4, P3).
- T19 `docs/DIAGNOSTICS.md` regenerated and checked, changelog, progress log.

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
  (BYN2601), `effect-start-undeclared` (BYN6002, R8b), `scope-cancel-definite-assignment`,
  `io-directive-duplicate` and `io-directive-in-library` (BYN1084; the second a directory case, as
  `tests/cases/diag/std-imports-package/` is), `io-evented-workers` (BYN6013), `spawn-readonly-borrow-mutated`
  (BYN3004 help), `spawn-borrows-nested-local` (BYN3002 help), `spawn-receiver-used-by-parent` (BYN3220 on
  `spawn obj.method()`), `spawn-ref-moved` (BYN3006 help), `defer-canceling-jump-out` (BYN2610's message),
  `suspend-on-wasm32-inferred` (BYN6012 through a private function; `suspend-on-wasm32` is the declared one).
- `parse/` cases: `scope-forms`, `spawn-expression`, `shield-forms`, `defer-canceling`, and
  `contextual-scope-spawn-shield-names` (existing identifiers named `scope`, `spawn`, `shield` still parse,
  including `return spawn` followed by a newline and the call statements `scope(x)` and `shield(x)`).
- `run/` cases, one per runtime feature, each row of the spec's acceptance criteria: `scope-return-cancels`,
  `scope-join-string`, `scope-collectall`, `scope-first-failure`, `scope-limit`, `scope-timeout`, `scope-until`,
  `cancel-catch-passes`, `cancel-defer-forms`, `cancel-source-two-scopes`, `cancel-source-after`, `shield-delays`,
  `shield-timeout`, `shield-nested`, `fiber-yield-interleave`, `fiber-sleep`, `channel-three-senders`,
  `channel-closed`, `stdin-read-message` (with `.stdin`), `stdin-readline-cap`, `child-stream-lines`,
  `child-line-too-long`, `child-drop-kills`, `child-signaled`, `child-sigpipe`, `child-stdin-closed`,
  `blocking-deadlock-panic`, `panic-kills-children`, `io-blocking-directive`. Added after the Neon review:
  `fiber-check-canceled` (a function without `suspend` that calls `Fiber.checkCanceled()` unwinds and runs its
  `defer canceling`), `scope-limit-dynamic-trap`, `channel-capacity-dynamic-trap`, `read-max-dynamic-trap`,
  `scope-timeout-zero`, `scope-until-past`, `scope-timeout-and-until` (the earlier wins),
  `scope-failure-beats-timeout`, `scope-collectall-error-set` (a child failure leaves the scope, reaches only its
  `join()`), `scope-break-continue-try` (each exit cancels and waits), `scope-task-dropped`,
  `cancel-source-outer-and-inner` (the outer cancel continues outward), `cancel-source-attached-twice` (both scopes
  unwind), `cancel-source-returned-from-child` (the cell survives the child), `defer-shield-mid-cancel`,
  `defer-shield-grace-expires` (the next `defer` gets its own grace), `channel-cancel-parked`,
  `channel-sender-close`, `channel-streaming-bounded` (slot buffers freed on `receive`), `child-unique-result`
  (a `unique` result with `string` fields relocated), `child-error-payload` (an `IoError.signaled` from a child read
  after the arena is freed), `child-combined-read` (one reader, both pipes filling, no deadlock),
  `child-readline-invalid-utf8` (the next line still reads), `child-split-handles-after-wait`,
  `child-wait-pipes-closed-early` (a child that closes stdout and keeps running), `child-wait-grandchild-holds-pipe`,
  `child-directory-signals` (the fork path's default signals), `stdin-readline-then-readall`, `stdin-two-readers`,
  `blocking-sleep`, `oom-kills-children` (T14 confirms the `run/` harness can cap memory; if it cannot, a script
  test). Timing rows use `BAYAN_TEST_TIME_SCALE`.
- `test` blocks under `Io.Simulated`: deterministic interleaving, virtual time for `Fiber.sleep` and deadlines,
  `Uptime.now()` on the virtual clock with `scope(until:)`, the all-parked panic, the refusal of `Io.start`
  (Decision 7), and `provide io: Io.Evented(workers: 1)`, nested.
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
- `tests/cases/emit/run-c.sha256`: every existing line changes once, in T4 (Approach); after T4 new lines only, and
  T16 checks that no line present after T4 changed.

## Risks & mitigations
- A frame that suspends but was lowered without the cancel status would skip defers. Mitigation: the `mayCancel`
  bit, from the checker's inferred `suspend` effect and `Fiber.checkCanceled()` calls, not a syntactic test, decides
  the lowering; T6 adds a `run/` case with a private function that suspends only through inference.
- Per-fiber state missed in the switch (`byn_panic_handlers`, `byn_context`, coverage counters, stdout buffer
  ownership). Mitigation: T3 lists every `_Thread_local` and file-level mutable in `runtime/bayan-rt.c` and records
  for each whether it is per-fiber or per-worker.
- A child-arena value escapes through a path Decision 5 did not name (a module-level `var`, an `Untrusted` wrapper).
  Mitigation: T6 lists every way a child can store outside its frame; any path not covered makes that child run in
  the parent's allocator.
- Adding `IoError` variants breaks exhaustive switches if spec 026 has not landed. Mitigation: 026 lands before T1
  (Tech / dependencies).
- Stdin read-ahead takes bytes a later blocking `readAll` expects. Mitigation: every stdin read drains the one
  read-ahead buffer first, on every OS; `stdin-readline-then-readall` mixes them.
- A child in its own process group that reads the terminal gets `SIGTTIN`. Mitigation: streamed children get piped
  stdin; the explain text says so.
- A parent killed by `SIGKILL` cannot kill its children on POSIX (Windows job objects with
  `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` do). Mitigation: documented as outside R10, which names panics and out of
  memory.
- The fiber stack overflow is a plain crash, as on the thread stack today, and live children survive it on POSIX.
  Mitigation: the guard page makes it a crash, not corruption; an overflow handler is noted for phase 2.
- `Io.stdin.read(to:)` (blocking) and `read(max:)` (suspending) look alike, and the blocking one stalls every fiber.
  Mitigation: the explain page of BYN6002 and the §15.1 text name the difference; a style note can follow later.
- Another plan claims BYN6009–6013, BYN1081–1084 or BYN3220 first. Mitigation: T1 adds them to
  `docs/diagnostics-allocated.txt` as `plan` rows, and `scripts/docs/check.sh` fails on a duplicate.
- The P1 10 ms median depends on `poll` wake-up latency and the stdout flush. Mitigation: T18 measures it on Linux,
  macOS and Windows; the stdin reads flush stdout first, as `read(to:)` does today.

## Needs decision
1. **`CancelSource` across a child arena** (finding 2). The cell lives in the allocator that made it, and Decision 5
   frees a child's arena when the child ends, so a source made in a child and returned or sent out would dangle;
   a deep relocation would split the cell and break R6b's sharing.
   - (a) `CancelSource` becomes `unique` with `share()`, over a reference-counted cell on the runtime heap, as
     `Sender<T>` does (D8). Sound everywhere, and phase 2's sendable `CancelSource` (R16) only makes the count
     atomic. It changes R6b's "copies of it share one source" (`docs/specs/027-concurrency/027-spec.md:99`) and
     §5.2's `share()` text, so it needs the owner.
   - (b) Copyable, cell in `context.allocator`, relocated by pointer, and a child whose result, error payloads,
     arguments or sent item types contain a `CancelSource` runs without an arena (Decision 5). No spec change, but
     such children lose R2's arena isolation, and the rule is one more exception to explain.
   - (c) Copyable, cell on the runtime heap, never freed. Rejected already in Decision 8: it grows with every request.
   Recommended: (a). Meanwhile the plan follows (b), the option that needs no spec change.
2. **Shape of the chunk reads** (finding 9). R11 names "the `read(into:)` shape spec 023 R14 accepted"
   (`docs/specs/027-concurrency/027-spec.md:144`, `docs/specs/023-spec-catch-up/023-spec.md:43`): a read into a
   buffer the caller owns, as the shipped `Io.stdin.read(to:)` is (`src/semantics/builtins.byn:363`). Decision 3's
   `read(max:) -> Untrusted<List<u8>>?` allocates every chunk instead, and the owner's 2026-11-27 answer asks for
   `Untrusted<…>` results, which a filled caller buffer does not carry.
   - (a) Caller-buffered suspending reads, `readSome(into: Span<u8>) -> i64` on `Io.stdin`, `ChildReader` and
     `Child` (the last also returning the `ChildStream`), with the buffer's bytes untrusted only by documentation.
     Honors R11's shape; no allocation per chunk; gives up `Untrusted` on chunk reads.
   - (b) Keep `read(max:)` allocating, record an owner amendment to R11, and state that a loop's chunks are freed per
     iteration only if the loop runs in a child (each request fiber's arena); the 100 MB streaming bound (T17)
     checks it.
   Recommended: (b), as the owner already chose `Untrusted` results for these reads. Meanwhile T11 and T12 build the
   runtime read on a caller buffer (`byn_io_read_stdin_some` already takes one, `runtime/bayan-rt.c:2848`), land
   `readLine(max:)` first, and land the chunk read's Bayān surface only after the answer.

## Coverage check
| R | Covered by |
|---|---|
| R1 | Semantics (BYN6009, BYN3217 scope), Testing `spawn-outside-scope`; T4 |
| R2 | Decision 5 (relocation of results, error payloads, `unique` values; handle exemption); Semantics (flow, region: `ref` and read-only borrows, receivers, nested-block locals); Emitter (spawn thunk, scope exit on `return`/`break`/`continue`/`try`); Testing `scope-return-cancels`, `scope-join-string`, `spawn-ref-*`, `spawn-readonly-borrow-mutated`, `spawn-borrows-nested-local`, `scope-break-continue-try`, `child-unique-result`, `child-error-payload`; T5, T6 |
| R3 | Semantics (builtins, ownership, BYN6010, BYN3201 exemption, `.collectAll` error set); Data (`Task<T>` drop); Testing `scope-collectall`, `scope-collectall-error-set`, `scope-first-failure`, `scope-task-dropped`, `task-returned-from-scope`; T4, T6 |
| R4 | Semantics (BYN6011, dynamic trap); Runtime (cap); Emitter (`spawn` at the cap is a suspend point); Testing `scope-limit`, `scope-limit-zero`, `scope-limit-dynamic-trap`; T4, T6 |
| R5 | Runtime (timer heap, clock hook); Data (`DeadlineError`); Semantics (option precedence); Testing `scope-timeout`, `scope-until`, `scope-timeout-zero`, `scope-until-past`, `scope-timeout-and-until`, `scope-failure-beats-timeout`; T7 |
| R6 | Approach (cancel status, `mayCancel`, target scope); Emitter (lctx, lowerstmt); Testing `cancel-catch-passes`, `cancel-defer-forms`, `defer-canceling-jump-out`; T6 |
| R6b | Decision 8 (list of attached scopes); Approach (target scope); Semantics (flow); Testing `cancel-source-*`, `scope-cancel-definite-assignment`; T8 — partial: the cell's placement across a child arena waits on Needs decision 1 (plan follows option b) |
| R7 | Emitter (implicit shield on `mayCancel` defers, lazy grace per `defer`); Testing `shield-*`, `defer-shield-mid-cancel`, `defer-shield-grace-expires`; T7 |
| R8 | Approach (`mayCancel`); Data (`Fiber`); Testing `fiber-yield-interleave`, `fiber-sleep`, `fiber-check-canceled`; T7 |
| R8b | Semantics (effects: `Io.start`, `Child` drop); Data (`Io.start` with `suspend`); Testing `effect-start-undeclared`; T4, T12 |
| R9 | Decision 5 (slot buffers); Data (channels, `Sender.close`); Semantics (BYN3217, BYN2024, BYN6011); Testing `channel-*`; T9 |
| R10 | Decisions 2, 3, 4, 6; Runtime (spawn paths, `SIGCHLD` reaping, fd transfer, live-children list, both abort sites); Data (contracts); Testing `child-*`, `panic-kills-children`, `oom-kills-children`; T12, T13, T14 |
| R11 | Decision 3; Runtime (stdin buffer, waiter queue); Testing `stdin-*`, the flags script test; T11 — partial: the chunk read's shape waits on Needs decision 2 |
| R12 | Lexer and parser (`#:io`, BYN1082, BYN1083, BYN1084); Data (`Io` implementations, BYN6013); Runtime (`Io.Blocking`); Testing `blocking-deadlock-panic`, `blocking-sleep`, `io-blocking-directive`, `io-directive-*`, `io-evented-workers`; T2, T10 |
| R12b | Decision 7; Semantics (`bindContext`); Runtime (virtual clock, all-parked panic, nested `provide io:`); Testing `test` blocks under `Io.Simulated`; T10 |
| R12c | Runtime (per-fiber panic chain, both abort sites); Testing `panic-kills-children`, `oom-kills-children`; T14 |
| R13 | Approach (`mayCancel`, the one T4 regeneration); Not touched; T16 |
| R14 | Data (codes with `// target:` comments); Spec and documents (explain pages per task); Testing (diag, run, bounds); T1, T17, T19 |
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

Gaps: R15–R19 and P5 are phase 2 and 3 work, as the spec's acceptance criteria say. In phase 1, R6b and R11 are
partial until Needs decisions 1 and 2 are answered (review findings 2 and 9); everything else is covered.

## Review response (Neon, 2026-11-27)
1. fixed: the emitter-internal `mayCancel` bit (Approach) decides the cancel channel; `Fiber.checkCanceled()` keeps no effect; `fiber-check-canceled`.
2. needs decision: Needs decision 1 (unique `CancelSource` with `share()` recommended); meanwhile Decision 5 runs children that move a source out without an arena.
3. fixed: Decision 8's cell keeps an intrusive list of attached scopes; `cancel-source-attached-twice`.
4. fixed: Decision 5 relocates results, error payloads and `unique` values, uses channel slot buffers freed on `receive`, and exempts `ref` runtime handles from the no-arena rule.
5. fixed: region rules for read-only spawn borrows (BYN3004, `src/semantics/codes.byn:485`) and nested-block locals (BYN3002, `src/semantics/codes.byn:483`), with diag cases.
6. fixed: `Io.start` has `suspend`; dropping a `Child` parks the fiber inside a shield for the bounded wait (Decision 4).
7. fixed: Decision 2 adds the `SIGCHLD` wake and per-pid `waitpid(WNOHANG)`, as `Io.run` already waits (`runtime/bayan-rt.c:4444`); `SIGCHLD` in the default-signal set on both spawn paths.
8. fixed: `take*()` moves the fd and `OVERLAPPED` into the split handle; `Child` closes only untaken pipes (Runtime).
9. needs decision: Needs decision 2 (allocating `read(max:)` with an R11 amendment recommended); meanwhile the chunk read's surface waits and `readLine` lands first.
10. fixed: under `.collectAll` the scope's error set is the body's alone (Semantics, binder); `scope-collectall-error-set`.
11. fixed: `Uptime.now()`, deadlines and `Fiber.sleep` read the active `Io`'s clock hook, virtual under `Io.Simulated` (Runtime).
12. fixed: BYN1084 for `#:io` outside the entry file and for a duplicate, from the driver, with two diag cases.
13. fixed: out of memory already reaches `byn_panic_resume` (`runtime/bayan-rt.c:1413` calls `byn_panic`, `runtime/bayan-rt.c:107` resumes); the unhooked site was the panic-in-a-handler `abort()` at `runtime/bayan-rt.c:95`, now hooked beside `runtime/bayan-rt.c:127`; `oom-kills-children` added.
14. fixed: the implicit shield wraps only `mayCancel` defers, arms its grace lazily, resets it per `defer`; two `run/` cases.
15. fixed: one stdin read-ahead buffer on every OS, drained by every stdin read, and a FIFO waiter queue (Runtime).
16. fixed: `Io` implementations in Data / interfaces, BYN6013 for `workers:` other than 1, nested `provide io:` scoping and the `IsThreadAFiber()` guard (Runtime).
17. fixed: the Contracts list in Data / interfaces, `Sender<T>.close(move this)`, `Task<T>` drop.
18. fixed: option precedence (Semantics), cancel target scope (Approach), scope exit on `return`/`break`/`continue`/`try`, receiver borrows, `spawn` at the `limit:` cap as a suspend point (Emitter).
19. fixed: same-line `spawn` through the existing `breaksLine` (`src/parser/recover.byn:79`) and the `(…) {` lookahead through the existing `matchingClose` (`src/parser/stmts.byn:638`); parse cases extended.
20. fixed: `Io.Blocking` and `Io.Simulated` behaviors in Runtime; the fork path already calls `setpgid(0, 0)` (`runtime/bayan-rt.c:4213`) and is taken whenever `directory:` is given on any POSIX system, not only musl (`runtime/bayan-rt.c:4334`); it gains the signal reset.
21. fixed: spec 026 before T1; measurements moved to T17 and T18; explain pages land with their tasks; `byn_errors[]` rows are emitted for every built-in variant (`src/emitter/cprint/program.byn:37`), so T4 regenerates `bootstrap/` and `run-c.sha256` once and T16 checks fiber-free bootstrap C and no change after T4.
22. fixed: the missing `diag/` and `run/` cases added under Testing.
23. fixed: Decision 2 rejects only kqueue and epoll.
24. fixed: `// target:` comments for BYN1083, BYN1084, BYN6009–BYN6013 and BYN3220 in Semantics `codes.byn` and the diagnostics table.
25. fixed: Decision 1 names each ABI's callee-saved registers (AArch64 `d8`–`d15` included) and sizes the guard page with `sysconf(_SC_PAGESIZE)`.
