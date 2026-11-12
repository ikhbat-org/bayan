# 0023 — Syntax freeze to 0.3.0, provisional sections, §13 placeholder

Status: accepted (user decision 2026-11-12, "I approve any changes", after an outside review of the 2026-11-09 export)

## Problem

An outside review of the export at `8d5e5c71` (`docs/export/BAYAN-AUDIT.md`), checked against dev at `9fda8d47`, raised four points that hold:

1. Syntax revisions keep landing while spec 017 makes the self-hosted compiler the default. Every syntax change is paid twice, in `src/` and in `selfhost/`.
2. Revision 0020 tags unbuilt features `(not in 0.2)`, but the tagged text is still normative: every revision has to stay consistent with designs nobody has built or tested together.
3. SPEC §13's heading says `scope`/`spawn` replaces it (revision 0019), but its body still specifies `async`/`await`, `Io.group`, `provide timeout:` and fibers in the present tense (AUDIT A20).
4. A cited code can be missing from the diagnostics index: revision 0022 cited BYN6008 with no entry until review fix 2026-11-12-3 added one.

## Decision

1. **Syntax freeze until 0.3.0 is released.** No revision adds, removes or renames a keyword, operator, clause or grammar form until the 0.3.0 release tag exists. The numeric-conversions revision from the 2026-11-11 drop (planned as 0023 in earlier notes, now **0024**) is the last syntax change admitted. Errata, status tags, doc-consistency fixes and revisions that remove unbuilt text are allowed.
2. **Tagged text is provisional.** A section or item tagged `(not in 0.2)`, `(not in 0.x)`, `(partial in 0.2: …)` or `spec-only` describes a design, not a promise. Building it may change it by revision with no compatibility cost (SPEC §19.4 applies to released behaviour only), and a revision need not keep provisional text consistent with itself: a conflict is resolved when the feature is built. The text stays in the spec, so section numbers and the many `§n` citations in code, goldens and docs stay valid. Moving it to a separate proposals document was considered and rejected for that reason.
3. **SPEC §13 becomes a placeholder.** §13.1–13.5 are removed. 0.x programs are single-threaded; the planned design is `docs/bayan-concurrency.md`, a design document (not normative) that a later revision turns into spec text. The lexer keeps `async` and `await` as reserved words (no keyword change under item 1). SPEC §9 (BYN3217) now points at the design document, not §13.3.
4. **Cited codes are checked.** `scripts/docs/check.sh` (e): every `BYNnnnn` in SPEC, GRAMMAR and STYLE must have its own row in `docs/DIAGNOSTICS.md`, so a planned code is allocated in `docs/diagnostics-allocated.txt` (or as a `// BYNnnnn Name: … // target:` comment in `DiagnosticCodes.cs`) before a document cites it. Revisions are not scanned: they are records and keep the codes of their day (some since renumbered or retired).

## Naming errors reviewed (no change in this revision)

The review proposed demoting the naming rules (SPEC §5.2) to lints. The test applied: a rule stays an error only when breaking it breaks something mechanical (particle call syntax, a derivation contract, a name that collides with syntax); a rule that depends on classifying English words becomes a lint. The `BYN50xx` errors (ten live, one planned):

| Code | Rule | Mechanical? | Verdict |
|---|---|---|---|
| BYN5001 | an `xed()` member takes `ref this` | No: needs the lexicon to read a word as a participle, and English participles are irregular (`read`, `set`, `split`, `cut`, `put`) | **lint candidate** |
| BYN5002 | an `isX`/`hasX`/`canX` member modifies `this` | Yes: fixed prefixes, no word classification | keep |
| BYN5003 | `tryX` returns neither `T?` nor `bool` | Yes: the `tryX` derivation contract (partial in 0.2) | keep |
| BYN5004 | several unlabeled parameters | Yes: particle call syntax | keep |
| BYN5005 | an argument without its particle | Yes: particle call syntax | keep |
| BYN5006 | a required parameter with no particle | Yes: particle call syntax | keep |
| BYN5007 | `Log.<level>` as a verb | Yes: a missing member with a teaching message | keep |
| BYN5008 | an unknown particle | Yes: particle call syntax | keep |
| BYN5009 | a member named like a particle (`to`, `as`, `toX`, `asX`) | Yes: collides with particle syntax | keep |
| BYN5013 | a particle used twice | Yes: particle call syntax | keep |
| BYN5010 (plan) | a stored function field or event named with the `on` prefix | Yes: a fixed prefix, no word classification | keep |

The seven `BYN51xx` rules (BYN5101–BYN5107) are lints already, and BYN5011 and BYN5014 are warnings; none blocks a build. So one error (BYN5001) fails the test. Demoting it changes both compilers and their goldens, so it waits for a revision after 0.3.0 (`work/todo.md`).

## Sections

- SPEC header (status note), §7.7 and §14 (`Io.evented()` and fiber wording tagged `not in 0.x`), §9 (BYN3217 line), §13.
- `docs/revisions/README.md`: the freeze rule.

## Codes

None added, changed or retired. BYN1016 (`async` as a modifier) and BYN6002 (`suspend`) stay; their §13 cross-references were in the removed text.

## Sūq files

None.

## Effect on work already done

- Nothing built changes: the 0.2/0.3 compilers implement none of the removed §13 text.
- `docs/bayan-concurrency.md` cites §13.1–13.5 by section and line, and its §12 rewrite list keeps rules whose only spec text was the removed body: a `Mutex` guard or `@threadLocal` borrow alive across a suspension point is an error (§13.4), types holding raw pointers cannot cross threads without `unsafe` (§13.5), and libraries never choose an `Io` implementation (§13.1). The revision that specs `scope`/`spawn` takes them from the Diff below, which keeps the removed text.
- `docs/STATUS.md`: the `scope`/`spawn` row points at this revision.
- Stale "§13" display cites in code and diagnostic pages: `work/todo.md`.

## Diff

Removed from SPEC (§13 as of `9fda8d47`); the placeholder in the spec replaces it.

```markdown
## 13. Concurrency (not in 0.2: no `async`/`await`, `Io` implementations or fibers; revision 0019 replaces this section with `scope`/`spawn`, not yet written)

### 13.1 I/O model
All I/O goes through `context.Io`:

| Implementation | Use |
|---|---|
| `Io.Blocking` | Simple tools |
| `Io.Threaded` | **Default for scripts**; the pool starts on the first `async` |
| `Io.Evented` | Servers (io_uring / IOCP / kqueue + fibers) |
| `Io.Simulated` | Tests: fake clock, seeded scheduling, fault injection, simulated files |

Libraries never choose an implementation. Blocking work is offloaded automatically (DNS, file I/O on epoll, `@blocking` externs). Debug builds warn when a fiber runs over 50 ms without yielding. Scripts may override with `#:io evented`.

### 13.2 Async
- No coloring: functions are never declared `async`. `async` as a function modifier is a teaching error showing the call-site form.
- `async f(args)` is a call-site expression that schedules `f` on `context.io` and returns a `Future<T>` (a `ref struct`); `await` joins; `try await` propagates errors. `await (a, b)` awaits several. Implementation: `async f(x)` hands `fOp(x)` (the maṣdar, §5.2) to `context.io`.
- Under `Io.Blocking`, `async` runs the call eagerly (same code, sequential).
- **Every await can fail**; `Canceled` is in every I/O error set.
- A function without `suspend` in its effects cannot suspend (§14); a violation names the suspending call chain.
- **Futures are scoped:** a future cannot escape its block; leaving the block cancels unfinished futures, which runs their `defer failing` handlers (§7.6).
- v1 uses **fibers** (stackful, lazily committed stacks, guard pages). The stackless transform arrives with the WASM target.

**Deadlines: `provide timeout: d { … }`.**
- Sets a deadline for every suspending operation inside the block, including in called functions, with no parameter plumbing.
- A nested `provide timeout: …` can only shorten the remaining time (the effective deadline is the minimum of the remaining and the new one).
- Expiry fails the suspended operation with `TimeoutError`.
- CPU-bound loops check explicitly: `try context.checkDeadline()`.
- Not in v0.1: async, futures and deadlines (no fibers).

> Round 2 §14: functions stay colorless; scoped futures and block deadlines give cancellation without plumbing. Codes: BYN1016.

### 13.3 Structured concurrency
`let group = Io.group()`, then `group.spawn(…)` and `try await group.all()`. Futures cannot outlive the scope that started them; leaving the scope cancels children; tasks may borrow the caller's stack.

### 13.4 Suspension inference
The compiler infers which functions may suspend (calls through `dyn` are bounded by the function type's `uses` clause). The language server marks such calls with inlay hints (`uses suspend`). Public functions declare `suspend` in their `uses` clause (§14). Errors:
- a suspension point in a function whose effects do not include `suspend` (BYN6002);
- a **`Mutex` guard alive across a suspension point**;
- a **`@threadLocal` borrow alive across a suspension point**.

> Round 2 §15: `bayan format --explicit` is gone; inferred effects are inlay hints, never a stored form.

### 13.5 Data sharing
- `ref` borrows: one task at a time; passing `ref x` to a spawned task locks `x` until the group ends.
- Read-only borrows: any number of tasks.
- Shared mutation: `Mutex<T>`, atomics (sequentially consistent by default; weaker orderings explicit), channels (`Channel<T>`, `Io.first(…)`).
- Types containing raw pointers cannot cross threads without an explicit `unsafe` marker.

`Io.offload(op)` runs CPU-heavy work on the thread pool.
```
