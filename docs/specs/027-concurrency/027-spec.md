# 027 — Concurrency: `scope`, `spawn`, cancellation, streamed child processes
Status: draft
Release: unscheduled (phase 1 planned for 0.5.0)
Sources: `docs/bayan-concurrency.md` (design R1–R7, confirmed 2026-11-01); owner decisions 2026-11-23 (D1–D8)
Created: 2026-11-23

Design source: `docs/bayan-concurrency.md` (confirmed 2026-11-01, decisions design R1–R7, cited with "design" so they
are not confused with this spec's R1–R20). Consumer: the Rein IDE core (`docs/handoffs/2026-11-23-rein-ide-needs.md`).
Owner decisions 2026-11-23: concurrency is next after 0.4.0; phased delivery (below); 0.5.0 ships spec 023's units
(#9) and `Uptime` (from #16b) together with phase 1. Review: Gemini Neon 2026-11-23, gated by the owner (decisions
D1–D8 below); consistency pass against SPEC 0.3.3-dev (revisions 0001–0024), 2026-11-23.

## Problem
A Bayān program cannot do two things at once. `Io.run` and `Io.runBatch` block until the child exits, and there is
no way to wait on stdin while other work runs. The Rein IDE core needs a protocol loop on stdin that keeps
answering while git and test runs stream output, and needs to cancel a request and its children when the UI says
so. Spec §13 has been a placeholder since revision 0023, `async`/`await` are still reserved in the lexer (todo
A12), and the `suspend` effect is checked but nothing parks a fiber.

## Owner decisions (2026-11-23)
- D1 Order: 0.5.0 = spec 023 units (#9) and `Uptime` + this spec's phase 1. Durations are `Duration` values;
  `until:` takes an `Uptime`. `extern c` stays in spec 023 (#17); R19 here covers only its concurrency part.
- D2 On-demand cancel: a `CancelSource` attached with `scope(cancel: src)`.
- D3 `defer failing` runs on cancellation; the binding form `defer failing (e) { … }` runs only on failure.
- D4 The streamed child is a `unique` handle whose stdin, stdout and stderr can be split into independent handles
  for separate fibers, and which keeps spec 023 R14's combined next-chunk read for a single reader.
- D5 Channels have many senders and one receiver.
- D6 `scope`, `spawn` and `shield` are contextual keywords (§2.4), so existing names keep working: `scope` and
  `shield` at the start of a statement before `{` or `( … ) {`, `spawn` before a name; `canceling` is contextual
  after `defer`; `async` and `await` stay reserved with a teaching error.
- D7 `Io.Blocking` panics naming the blocked fiber and the operation it waits on (design §12's "naming both" is
  corrected with the §13 revision).
- D8 `share()` is the one verb for another handle to the same resource (`Sender<T>` now, phase 2's `Arc<T>`),
  recorded in §5.2 beside `copy()`, which keeps meaning an independent value.

## Goals
- Phase 1 (0.5.0): one worker runs many fibers. `scope`/`spawn`/`join`, implicit and on-demand cancellation,
  `shield`, `defer canceling`, channels, `Fiber.yieldNow()`/`Fiber.checkCanceled()`/`Fiber.sleep(for:)`, incremental
  stdin reads, and a child process whose stdin, stdout and stderr stream while it runs. The IDE acceptance rows
  P1–P4 below pass.
- Phase 2: one worker per core (design R1), `ISendable`/`IShareable` derivation (design R4),
  `scope(workers: .compute)` (design R6, CPU part), `Mutex` guards and `AsyncMutex` (design R5). IDE row P5 passes.
- Phase 3: `@blocking` externs on a bounded pool (design R6, blocking part), as the IDE's pty, file watching and
  libgit2 bindings need.
- The §13 rewrite and its companion edits (§1, §2.4, §5.2 for `share()`, §7.6, §7.7 including its `Io.evented()`
  spelling, §8, §9.2, §9.4, §14, §16.5, §20, §21.4, §23, Appendix A; design §12 and its `bayan new --script` row)
  land as a spec revision before phase 1 code.

## Non-goals
- `select` over channels, the stale-write lint, the 49xx long-loop lint (design §10).
- WebAssembly fibers (R20 makes suspension an error on `wasm32` until stack switching ships).
- Databases, HTTP pools, SQLite shapes (design §8): library work after phase 2.
- Sockets, WebSocket, the `std.time` wall clock beyond `Uptime` and `Duration` (Rein P1 items 2–3): separate specs.
- Detached tasks of any kind (design R2).
- Base `extern c`, `unsafe because`, `cstr` and `T*`: spec 023 #17.
- Non-blocking stdout and stderr writes: a reader that stops draining stdout stalls the worker (R11).

## User stories
- As an IDE core author, I want a fiber reading framed stdin while other fibers answer, so a slow git call never
  delays a ping reply.
- As an IDE core author, I want to read a child's stdout line by line while it runs and write its stdin, so a
  language server or `git log` streams into the UI.
- As a user of the IDE, I want a canceled request to stop its work and kill its child processes at once.
- As a script author, I want the same program to run under `bayan run` with one worker.
- As a library author, I want a compile error when a value that cannot cross threads is sent to the compute pool.

## Requirements
Phase 1:
- R1 `spawn` is legal only inside a `scope` block; elsewhere it is a 6xxx diagnostic. With R1 and R2 no fiber
  outlives the locals it borrows, so BYN3217 then covers only a borrowed value sent on a channel (R9).
- R2 A `scope` is a block, not a closure: `return`, `break`, `continue` and `try` keep their meaning; leaving early
  cancels unfinished children and waits for all of them before the block exits; definite assignment flows out
  (except from a scope with `cancel:`, R6b). No child outlives its scope. Children may borrow the parent's locals:
  while a child holds `ref` to a local, neither the parent nor a sibling may use it, and while a child holds a
  read-only borrow, neither may mutate it (a borrow error with a concurrency help line). A child's borrow lasts
  until its task is joined or the scope ends. Each child allocates its temporaries from its own child arena, freed
  when the child ends, so repeated request fibers do not grow a long-lived `General` allocator. Nothing that
  outlives the child lives in that arena: not its result, and not anything it stores through a borrow of a parent
  local.
- R3 `spawn f(...)` returns a `Task<T>`; a bare `spawn f(...)` statement is allowed whatever `T` is (no BYN3201).
  `Task<T>` is `unique` and borrows its scope: it cannot be stored or returned past the scope (§9.4 rule 8), and
  `join()` consumes it. `join()` returns the child's value or propagates its failure. By default the first child
  failure, joined or not, cancels the siblings and fails the scope; the scope's error set is the union of its
  body's and its children's. With `policy: .collectAll` no sibling is canceled on failure, each `join()` returns its
  own result, and a child failure does not fail the scope; a bare `spawn` of a function that can fail is then an
  error, because its failure would be lost.
- R4 `limit: n` (`n >= 1`, else a diagnostic when constant and a trap otherwise) caps running children at `n`;
  `spawn` parks the parent at the cap, so memory stays bounded by `n`.
- R5 `timeout: d` (a `Duration`) and `until: t` (an `Uptime`) cancel the scope and fail it with
  `DeadlineError.exceeded`; `d <= 0` or a past `t` cancels at once. A child's earlier failure wins. `DeadlineError`
  (`union error DeadlineError { exceeded }`) is in the scope's set only when one of the two options is given.
  Neither option needs the `clock` effect.
- R6 Cancellation unwinds a fiber at its next suspend point, running in reverse registration order `defer`, bare
  `defer failing` and `defer canceling` bodies. `defer failing (e) { … }` runs only on failure, never on
  cancellation. `defer canceling` runs only on cancellation, is allowed in functions that do not fail (BYN2606's
  help for a bare `defer failing` there points to it), and like every `defer` body cannot `try`. Cancellation is
  not an error value, never appears in a `fails` list, and passes through every `catch`; only the boundary of the
  canceled scope ends the unwind (R6b, and R5 where it becomes `DeadlineError`).
- R6b On-demand cancellation: `CancelSource()` makes a source; copies of it share one source, so a request table
  can hold one while its scope runs. `scope(cancel: src) { … }` attaches it; `src.cancel()` cancels that scope (its
  body and children) without failing it or affecting any other scope. The unwind stops at the scope's boundary and
  control continues after the block; a local first assigned inside the block is therefore not definitely assigned
  after it. `src.isCanceled` says a cancel was requested, not that the block was cut short: a body that reaches no
  suspend point, or a source canceled after its scope ended, still completed, so code that needs the block's result
  assigns it inside (a `T?` local) and tests that. A cancel of an enclosing scope pending at the same time
  continues outward. A source may be canceled before, during or after its scope; after, it does nothing. A canceled
  source stays canceled: attaching it to another `scope(cancel:)` cancels that scope at once.
- R7 `shield(timeout: d) { }` (default 5 s) delays a pending cancel to its end; an explicit shield always has
  `DeadlineError` in its error set. At timeout its region is canceled: a pending cancel continues outward, otherwise
  the shield fails with `DeadlineError.exceeded`. A nested shield is capped at the enclosing shield's remaining time.
  Every `defer` body runs as an implicit shield (default 5 s) whose timeout counts only while a cancel is pending
  (a cancel arriving mid-body gets the full grace); it never adds `DeadlineError`, and a panic unwind gets no grace.
  When a `defer` body's grace runs out, the rest of that body is abandoned and the next `defer` runs with its own.
- R8 `Fiber.yieldNow()` and `Fiber.sleep(for: d)` are suspend points; `Fiber.checkCanceled()` unwinds on a pending
  cancel and otherwise does nothing. `Fiber.sleep(for:)` replaces §16.5's `sleep(for:)`; §16.5's wall-clock
  `sleep(until: Instant)` stays in `std.time` and is not part of phase 1; when it ships it suspends too, so it
  becomes `Fiber.sleep(until:)` with the `suspend` effect.
- R8b Effects: `scope`, `join`, channel `send`/`receive`, `Fiber.yieldNow`, `Fiber.sleep`, streamed child I/O,
  incremental stdin reads and a suspending `defer` body have the `suspend` effect; the streamed child's operations
  also have `process`, and stdin reads `console` (§14). Public functions declare them and private functions infer
  them, as for every effect (BYN6002 on a public function that does not declare one). `scope(timeout:)` needs
  `suspend`, not `clock`. `Fiber.checkCanceled()` has no effect.
- R9 Channels: `Channel<T>.open(capacity: n)` (`n >= 1`) returns a `unique` `Sender<T>` and a `unique`
  `Receiver<T>`, so the runtime sees each sender dropped. `share()` makes another sender for the same channel, so
  many fibers send; `copy()` keeps its meaning of an independent value and does not apply. `send` parks when full
  and fails `ChannelError.closed` when the receiver is gone; `receive` returns `T?`: it parks when empty, drains
  buffered items after every sender is gone or closed, then returns `null`, so `T` may not itself be optional
  (BYN2024). Both are suspend points that unwind on cancel. In phase 1, `T` may not hold a borrowed reference (BYN3217; phase 2's
  `ISendable` replaces the rule).
- R10 Streamed child process: a `unique` child handle. Starting one keeps `Io.run`'s rules: no shell, `.bat`/`.cmd`
  refused on Windows, parent `PATH`/cwd lookup, and `Untrusted<T>` arguments rejected (BYN2786). The child starts
  with default signal dispositions and an empty signal mask whatever the parent ignores or blocks. Its stdin, stdout
  and stderr can be split into independent handles so separate fibers write and read at once; a single reader uses
  the combined next-chunk read of spec 023 R14, which cannot deadlock on a full pipe. Chunk reads return raw bytes;
  line reads enforce a per-line byte cap (memory-leaks rule 4) and fail `IoError.invalidUtf8` on a line that is not
  UTF-8. A stdin write parks on back-pressure, never raises `SIGPIPE` in the parent, and fails `IoError` once the
  child closed its stdin. Each read and write is a suspend point. Closing stdin signals EOF; waiting returns the
  exit code or fails `IoError.signaled`. Dropping the handle while the child runs, on any exit of its owner (normal
  return, failure or cancel), terminates the child's process tree (process group on POSIX, Job object on Windows)
  and waits a bounded time for it before the owner continues. When the process aborts (a panic, out of memory,
  R12c), the runtime terminates every live child's process tree before exiting. The blocking `Io.run`/`Io.runBatch`
  keep their behavior.
- R11 `Io.stdin` gains incremental bounded reads that return the bytes available without waiting for EOF (the
  `read(into:)` shape spec 023 R14 accepted, and a line read with a byte cap). Under `Io.Evented` each is a suspend
  point, so one fiber waits on stdin while others run. Reading never changes the flags of the inherited standard
  streams (no `O_NONBLOCK` on file descriptors 0–2), which the parent shell and child processes share. Writes to
  stdout and stderr stay blocking.
- R12 Every phase 1 entry point (`bayan run`, a built program's `main`, scripts) uses `Io.Evented(workers: 1)`;
  `#:io evented` / `#:io blocking` override it in a script, `#:io threaded` (written by 0.3's `bayan new --script`)
  is an input form for `#:io evented` (a 1xxx code; `#:` directives are lexed as trivia today, so this needs a
  directive parser), and `bayan new --script` writes none of them. The test runner uses
  `Io.Simulated` (§20). Libraries never choose an `Io` implementation. `Io.Blocking` runs `spawn` children inline in
  order; a wait on another fiber (a channel, `join`, the `limit:` cap) that cannot complete without that fiber
  running panics at once, naming the blocked fiber and the operation, never a silent hang. A wait on the operating
  system (stdin, a child's pipes) blocks, and a deadlock through one is not detected.
- R12b `Io.Simulated` and `provide io:` run a program's fibers on a deterministic single-threaded scheduler for
  tests; `io` joins `provide`'s handler list and BYN6007's message.
- R12c A panic in any fiber aborts the process: only `defer panicking` handlers and `Panic.handler` run; out of
  memory aborts. No fiber's panic is caught by its scope.
- R13 The compiler's own source does not use these features, so bootstrapping stays single-threaded and free of
  the fiber runtime; the compiler and its C backend still compile them for user programs.
- R14 Every new diagnostic takes the next free code in its area with a `// target:` comment (Addendum A2): 6xxx
  for the concurrency and effect rules, 1xxx for input forms, 3xxx for borrow errors. Each has a `diag/` case and
  an explain page; every runtime feature has a `run/` case. New built-in error sets
  (`DeadlineError`, `ChannelError`) take the next built-in codes, and §8's "user variants from 13" moves with them.
  `docs/memory-leaks.md` gets rows for fiber stacks, child arenas and child pipes, and
  `scripts/release/memory-gate.sh` covers them.
- R20 A program in which any function has the `suspend` effect, declared or inferred, is a diagnostic on the
  `wasm32` target.

Phase 2:
- R15 `Io.Evented(workers: .perCore | n)`; a fiber never moves between workers; new work goes to the least-loaded
  worker. `Symbol.intern` is safe from every worker.
- R16 `ISendable` and `IShareable` are derived from fields; a value that is not sendable reaching a channel or a
  `.compute` scope, and a value that is not shareable reaching `Arc<T>` or a read-only borrow into `.compute`, is an
  error naming the field path. `@sendable` locks a public type; `@sendable because "…"` (non-empty) admits C
  handles; `bayan audit` lists every `@sendable because` and every change in a public type's sendability.
  `CancelSource` is sendable.
- R17 `scope(workers: .compute)` runs children on a separate pool sized by `package.byn` `workers: Workers { io,
  compute, blocking }` (defaults `.perCore`, `.perCore`, 64); code may override any (`Io.Evented(workers: n)`
  overrides `io`). Under `Io.Blocking` and `Io.Simulated`, `.compute` children run inline.
- R18 A `Mutex` guard alive across a suspend point is an error; `unlock(move this)` is the one early release;
  there is no `Mutex.with`. `AsyncMutex<T>` may be held across suspend points.
- R18b `Arc<T>`, `Atomic<T>` and `@threadLocal`; a `@threadLocal` borrow held across a suspend point is an error.
- R18c Debug builds run a watchdog that reports a fiber running too long without a suspend and a cancel slow to
  finish (naming the slow `defer`), and a detector that reports a scope whose fibers are all parked on each other.

Phase 3:
- R19 `@blocking` externs (spec 023 #17 provides `extern c`) run on the bounded blocking pool (`workers.blocking`,
  default 64) and callers park when it is full; cancellation never unwinds across C frames; a callback from C onto
  a fiber switches to the thread stack, and a panic in it aborts; `bayan audit` lists externs without `@blocking`
  or a non-blocking note.

## Acceptance criteria
Timing bounds below scale with `BAYAN_TEST_TIME_SCALE`; latency medians come from an unloaded benchmark, separate
from the functional tests. Rein IDE rows, each an end-to-end test through the real entry point:
- P1 Given a program with one fiber reading framed stdin messages and another running a child that sleeps 2 s,
  when a ping arrives, then its reply is written while the child is still running; the benchmark's median reply
  time is at most 10 ms.
- P2 Given a Bayān stand-in child that reads stdin and prints 10,000 lines to stdout and to stderr with pauses,
  when one fiber reads its stdout line by line, another its stderr and a third writes its stdin, then the first
  line arrives before the child exits, nothing deadlocks, and the exit code is returned.
- P3 Given a request fiber that owns a running child, when its `CancelSource` is canceled, then its
  `defer canceling` runs, the child's process tree is gone within 100 ms, and no other fiber is affected.
- P4 Given the P1 program, when it runs under `bayan run`, then it behaves the same with one worker.
- P5 (phase 2) Given a diff of two 10 MB files in `scope(workers: .compute)`, when pings arrive during it, then
  replies arrive while the diff runs; the benchmark's median is at most 10 ms.

Per requirement:
- R1: Given `spawn` outside a `scope`, then the 6xxx diagnostic.
- R2: Given a `return` from inside a `scope` with two running children, then both are canceled and have ended
  before the function returns; given a parent write to a local a child holds `ref`, then a borrow error; given a
  child that returns a `string` it built, then the parent reads it intact after `join()`.
- R3: Given three children under `.collectAll` where one fails, then the other two finish and each `join()`
  returns its own result; without it, the other two are canceled and the scope fails; given a bare `spawn` of a
  failing function under `.collectAll`, then an error; given a `Task<T>` returned from its scope, then an error.
- R4: Given `limit: 4` over 1,000 inputs, when it runs, then at most 4 children are alive at any time.
- R5: Given `scope(timeout: 50ms)` around a child that sleeps 1 s, then the scope fails with
  `DeadlineError.exceeded` no earlier than 50 ms and before 500 ms, and the child's `defer` ran.
- R6: Given `catch value` around a call inside a canceled fiber, then the catch does not stop the unwind; given
  `defer failing (e)` in a canceled fiber, then it does not run and a bare `defer failing` does.
- R6b: Given two scopes with separate sources, when one source is canceled, then only its scope unwinds, control
  continues after its block and `src.isCanceled` is `true`; given a read after the block of a local first assigned
  inside it, then a definite-assignment error; given a source canceled after its scope ended, then attaching it to
  a new scope cancels that scope before its body's first suspend point.
- R7: Given a cancel arriving inside `shield(timeout: 1s)` whose body suspends for 200 ms, then the body finishes
  and the unwind starts after it; given no cancel and a body that suspends 2 s, then the shield fails with
  `DeadlineError.exceeded`; given a nested `shield(timeout: 1s)` with 100 ms left on the outer, then it ends at the
  outer's limit.
- R8: Given two fibers that each `Fiber.yieldNow()` in a loop, then their outputs interleave.
- R8b: Given a public function that starts a streamed child without declaring `process` and `suspend`, then
  BYN6002.
- R9: Given three senders made with `share()` and one receiver, then every item arrives once and `receive` returns
  `null` after all three are dropped; a `send` after the receiver is gone fails `ChannelError.closed`.
- R10: Given a child printing one line longer than the cap, then the line read fails rather than buffering it;
  given an owner that returns normally without waiting, then the child is gone before the owner's caller resumes;
  given a fiber that panics while owning a running child, then the child's process tree is gone after the abort;
  given a child that writes to a closed pipe, then it dies of `SIGPIPE` as it would under a shell.
- R11: Given stdin that sends one message and stays open, then the read returns that message; given a terminal
  or pipe on stdin, then its file status flags are unchanged after the program exits.
- R12: Given two siblings where the first receives from a channel only the second sends to, under `Io.Blocking`,
  then the run panics naming the first fiber and its `receive`.
- R14: Given 10,000 spawns under `limit: 8` and a child streaming 100 MB, then peak RSS stays under the bound
  recorded in `docs/memory-leaks.md`.
- R20: Given a function that suspends, declared or inferred, built for `wasm32`, then the diagnostic.
- Phase 2 and 3 rows (R15–R19) are written with those phases' plans.

## Law candidates
- No child outlives its scope: after any program run, every fiber spawned in a scope has ended when the scope's
  block exits by any non-panicking path (R2).
- Cancellation is caught only by its own scope: for every program, no `catch` form stops a cancel unwind, and the
  unwind ends only at the boundary of the scope that was canceled (R6, R6b).
- A child process never survives its owner: for every exit of a fiber that owns a child (return, failure or
  cancel) and for every abort, the child's process tree has exited, or the bounded wait has expired and been
  reported, before the owner continues or the process exits (R10).
- Live children never exceed the limit: for every `scope(limit: n)`, at most `n` children are running at once (R4).
- Sibling borrows are exclusive: no accepted program lets two fibers hold a `ref` to one value, or one a `ref` while
  another reads it (R2).
- No OS lock across a suspend point: no accepted program holds a `Mutex` guard across a suspend point (R18,
  phase 2).
- A fiber stays on its worker: every fiber's suspends resume on the worker that started it (R15, phase 2).

## Open questions
- Fiber stacks: fixed-size stacks with guard pages, or segmented/growable; default size. For `/plan`.
- Event-loop backend per OS (kqueue, epoll, IOCP) or one portable layer first. For `/plan`.
- Method names for the child handle, the split stream handles and the stdin reads (D4, R10, R11). For `/plan`.
- The bounded kill-wait time and the per-line cap defaults (R10). For `/plan`, measured.
- How R2 keeps a child's result and its writes through parent borrows out of the child arena (allocate them from
  the parent's allocator, copy on return, or restrict result types). For `/plan`.
- `IoError` variants for the streamed child: the closed-stdin failure, and `signaled`, whose `stdout`/`stderr`
  payload a streamed child does not keep (empty, or a new variant). For `/plan`.
- What `Io.Simulated` does with real stdin and child processes: pass through, or refuse. For `/plan`.
- What owns a `CancelSource`'s shared state: copies cannot count themselves (only `unique` types have cleanup), so
  a handle with a generation check (like §9.6's `Handle<T>`) fits "after, it does nothing", but a source canceled
  and never attached still needs an owner. For `/plan`.

Answered:
- 2026-11-27 (owner): the new stdin reads and the child-process reads return `Untrusted<…>` now (§15.1 lists stdin
  as a source), not `readAll`'s interim plain `string`. Was: whether they return `Untrusted<…>` now or follow
  `readAll`'s interim plain `string`.