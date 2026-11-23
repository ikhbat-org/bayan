# 027 — Concurrency: `scope`, `spawn`, cancellation, streamed child processes
Status: draft
Created: 2026-11-23

Design source: `docs/bayan-concurrency.md` (confirmed 2026-11-01, decisions R1–R7). Consumer: the Rein IDE core
(`docs/handoffs/2026-11-23-rein-ide-needs.md`). Owner decisions 2026-11-23: concurrency is next after 0.4.0; phased
delivery (below); phase 1 targets 0.5.0.

## Problem
A Bayān program cannot do two things at once. `Io.run` and `Io.runBatch` block until the child exits, and there is
no way to wait on stdin while other work runs. The Rein IDE core needs a protocol loop on stdin that keeps
answering while git and test runs stream output, and needs to cancel a request and its children when the UI says
so. Spec §13 has been a placeholder since revision 0023, `async`/`await` are still reserved in the lexer (todo
A12), and the `suspend` effect is checked but nothing parks a fiber.

## Goals
- Phase 1 (0.5.0): one worker runs many fibers. `scope`/`spawn`/`join`, implicit cancellation, `shield`,
  `defer canceling`, channels, `Fiber.yieldNow()`/`Fiber.checkCanceled()`, and a child process whose stdin,
  stdout and stderr stream while it runs. The IDE acceptance rows P1–P4 below pass.
- Phase 2: one worker per core (R1), `ISendable`/`IShareable` derivation (R4), `scope(workers: .compute)` (R6, CPU
  part), `Mutex` guards and `AsyncMutex` (R5). IDE row P5 passes.
- Phase 3: `extern c` with `@blocking` on a bounded pool (R6, blocking part), as the IDE's pty, file watching and
  libgit2 bindings need.
- The §13 rewrite (design §12) lands as a spec revision before phase 1 code.

## Non-goals
- `select` over channels, the stale-write lint, the 49xx long-loop lint (design §10).
- WebAssembly fibers: `uses suspend` stays an error on `wasm32` until stack switching ships.
- Databases, HTTP pools, SQLite shapes (design §8): library work after phase 2.
- Sockets, WebSocket, `std.time` wall clock (Rein P1 items 2–3): separate specs.
- Detached tasks of any kind (R2).

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
- R1 `spawn` is legal only inside a `scope` block; elsewhere it is a 6xxx diagnostic (replacing most of BYN3217).
- R2 A `scope` waits for every child before it exits; no child outlives it. Children may borrow the parent's
  locals; a local borrowed `ref` by a child is unusable by the parent until the scope ends, and two children taking
  `ref` to one value is a borrow error.
- R3 `join()` on a child returns its result or its failure. Without `policy: .collectAll`, the first failure cancels
  the siblings and the scope fails with it; the scope's error set is the union of its children's and its body's.
- R4 `limit: n` caps running children at `n`; `spawn` parks the parent at the cap, so memory stays bounded by `n`.
- R5 `timeout: d` / `until: t` cancel the scope and fail it with `DeadlineError.exceeded`; a child's earlier failure
  wins; `DeadlineError` is in the scope's set only when one of the two options is given.
- R6 Cancellation unwinds a fiber at its next suspend point, running `defer`, `defer failing` and `defer
  canceling`; it is not an error value, never appears in a `fails` list, and passes through every `catch`.
- R7 `shield(timeout: d) { }` (default 5 s) delays a pending cancel to its end; at timeout its region is canceled:
  a pending cancel continues outward, otherwise the shield fails with `DeadlineError.exceeded`. Nested shields are
  capped by the outer one. Every `defer` body runs as an implicit shield with the grace rules of design §4.
- R8 `Fiber.yieldNow()` is a suspend point; `Fiber.checkCanceled()` unwinds on a pending cancel and otherwise does
  nothing.
- R9 Channels: `Channel<T>.open(capacity:)` returns a sender and a receiver; `send` parks when full, `receive`
  parks when empty, and a closed channel ends receiving.
- R10 Streamed child process: start a child, write its stdin, read its stdout and stderr line by line or in
  chunks while it runs, close its stdin, and get its exit code. Each read and write is a suspend point. Canceling
  the fiber that owns the child kills the child (and on POSIX its process group) before the unwind continues. The
  blocking `Io.run`/`Io.runBatch` keep their behaviour.
- R11 Reading stdin is a suspend point under `Io.Evented`, so one fiber waits on stdin while others run.
- R12 `bayan run` and scripts use `Io.Evented(workers: 1)`; `Io.Blocking` runs children inline in order and
  panics, naming both fibers, when a child waits on something only a later sibling provides.
- R13 The C backend and the self-hosted compiler stay free of these features: the compiler itself needs none.
- R14 Every new diagnostic has a `diag/` case and every runtime feature a `run/` case; `docs/memory-leaks.md`
  gets rows for fiber stacks and child pipes, and its release gate covers them.

Phase 2:
- R15 `Io.Evented(workers: .perCore | n)`; a fiber never moves between workers; new work goes to the least-loaded
  worker.
- R16 `ISendable` and `IShareable` are derived from fields; a value that is not sendable reaching a channel or a
  `.compute` scope is an error naming the field path. `@sendable` locks a public type; `@sendable because "…"`
  (non-empty) admits C handles.
- R17 `scope(workers: .compute)` runs children on a separate pool sized by `package.byn` `workers: Workers { io,
  compute, blocking }`.
- R18 A `Mutex` guard alive across a suspend point is an error; `unlock(move this)` is the one early release;
  `AsyncMutex<T>` may be held across suspend points.

Phase 3:
- R19 `extern c` declarations; `@blocking` externs run on the bounded blocking pool and callers park when it is
  full; cancellation never unwinds across C frames.

## Acceptance criteria
Rein IDE rows, each an end-to-end test through the real entry point:
- P1 Given a program with one fiber reading framed stdin messages and another running a child that sleeps 2 s,
  when a ping arrives, then its reply is written within 10 ms.
- P2 Given `git log` (or a stand-in that prints 10,000 lines with pauses), when a fiber reads it line by line,
  then the first line arrives before the child exits, the fiber can write the child's stdin, and the exit code is
  returned.
- P3 Given a request fiber that owns a running child, when its scope is canceled, then its `defer canceling` runs,
  the child (and its process group) is gone within 100 ms, and no other fiber is affected.
- P4 Given the P1 program, when it runs under `bayan run`, then it behaves the same with one worker.
- P5 (phase 2) Given a diff of two 10 MB files in `scope(workers: .compute)`, when pings arrive during it, then
  replies stay within 10 ms.

Per requirement:
- R4: Given `limit: 4` over 1,000 inputs, when it runs, then at most 4 children are alive at any time.
- R5: Given `scope(timeout: 50ms)` around a child that sleeps 1 s, then the scope fails with
  `DeadlineError.exceeded` after about 50 ms and the child's `defer` ran.
- R6: Given `catch value` around a call inside a canceled fiber, then the catch does not stop the unwind.
- R7: Given a cancel arriving inside `shield(timeout: 1s)` whose body suspends for 200 ms, then the body finishes
  and the unwind starts after it.
- R12: Given two siblings where the first receives from a channel only the second sends to, under `Io.Blocking`,
  then the run panics naming both.

## Law candidates
- No child outlives its scope: after any program run, every fiber spawned in a scope has ended when the scope's
  block exits (R2).
- Cancellation is never caught: for every program, no `catch` form stops a cancel unwind (R6).
- A canceled child process never survives its owner: for every cancel of a fiber that owns a child, the child has
  exited before the owner's unwind finishes (R10).
- No OS lock across a suspend point: no accepted program holds a `Mutex` guard across a suspend point (R18,
  phase 2).

## Open questions
- Streamed child API shape (R10): a new `Io.start(...)` returning a `Child` handle, or a `suspend` form of `Io.run`
  as the handoff suggests. For `/plan`.
- Fiber stacks: fixed-size stacks with guard pages, or segmented/growable; default size. For `/plan`.
- Event-loop backend per OS (kqueue, epoll, IOCP) or one portable layer first. For `/plan`.
- Diagnostic numbers: assigned in 6xxx now, or at the round-4 renumbering (AGENTS.md diagnostic table). For
  `/plan`; conservative default is 6xxx now.
- Lexer: `async`/`await` stay reserved or are freed when `scope`/`spawn` arrive (todo A12). Conservative default:
  keep them reserved with a teaching error.
