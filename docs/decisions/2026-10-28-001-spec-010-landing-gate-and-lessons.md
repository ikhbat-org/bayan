# Spec 010 landing gate, the `in` modifier, and what the redo taught
Status: decided (2026-10-28); the gate is live in `scripts/selfhost/`. The two follow-ups below are open.

Records the decisions made while spec 010 (self-hosted semantics) was ported, so later ports (011, 012 and any new one) reuse them. The per-task questions are Q710, Q711, Q712, Q713 and Q714 in `docs/decisions/2026-11-14-003-answered-questions.md`; the commands live in `scripts/selfhost/` (`wave-brief.py`, `guard.sh`, `land.sh`, `writer-protocol.md`, `bayan-cheatsheet.md`).

## Decisions

1. **A port lands only through `scripts/selfhost/land.sh` (Q712).** One task is one branch off the base, one writer brief, one guard pass, one independent review, one `land.sh`. `land.sh` refuses unless the guard passes on the branch, `reviews/<T>.md` names the branch head (or its parent when the review file is the last commit), says `Verdict: PASS` and has no open HIGH row. It merges with `--no-ff` and ticks the task. Writers never tick tasks, and a plain `git merge` is not a route.
2. **The guard checks more than tests and mutants.** `guard.sh` runs the older checks, then `guard-checks.py`:
   - Oracle: the test class calls the C# implementation (`Compilation.Create`, `Manifest.Read`, reflection on `Bayan.Semantics`). A hand-typed `expected = new List<string> { "…" }` or `AssertSection(…, ["…"])` literal is rejected; at most 2 per file are exempt, each tagged `// no-oracle: Qnnn`.
   - Stubs: no `// stub: <T>` marker and no empty function body, unless marked `(blocked: Qnnn)`.
   - `ctx.byn`: changes only inside the task's `// ── <T> state` section, no deletions.
   - Gates: no Question saying "before <T>" is still Open.
   - Docs: the task has a Progress log entry; every `file.byn:N` a new Question cites is a real line (not blank, not a brace), and a backticked snippet after it appears within ±2 lines.
   - Mutations: mutants that fail to compile are skipped, not counted as killed. One line per file may carry `// mutation-exempt: Qnnn` on the line above, only when the line's sole effect goes through a sibling's stub.
   - Coverage: a line that is dead in the C# too takes `// coverage-exempt: Qnnn` (or `… through N`); the Question cites the `.byn` line and the C# line that shows the path is dead. A line that runs only once sibling task T<k> ports its stub `<fn>` takes `// coverage-blocked: Qnnn T<k> <fn>` (Q838); T<k> removes the marker before it lands.
   - A guard run takes about 20–40 minutes per task (8 mutants, each a build plus the task's tests).
3. **Tests take expected values from the C# in-process, never typed by hand (Q711, Q712).** Models: `SelfhostSemanticsT10Tests.Expected`, `SelfhostSemanticsT15Tests.cs` (a fresh C# `Binder` by reflection, diagnostics as `code line:col message |label|help|fix`) and `SelfhostSemanticsT13Tests.cs` (private `Compilation` methods by reflection). When a sibling stub is in the way, choose inputs that avoid it or build the sibling's output by hand on both sides; never assert a stub's default.
4. **C# state with no home goes to `ctx.byn` (Q710, Q714).** A task owns a `// ── <T> state` section. State that two tasks touch (`includeTests`, `skipOwnershipCheck`, `mainStatementsFn`/`mainStatements`, `testBodies`, `exitCodes`) goes in the Q714 shared section, added by the dispatcher only. A writer never approximates missing state.
5. **The `in` parameter modifier is optional, and new code leaves it out.** Spec §10: a plain parameter is read-only and the compiler passes by value or by reference by size; `in` is accepted, redundant, and removed by the formatter. A probe on 2026-10-28 confirmed it: a plain parameter of a struct that owns a `List` compiles and runs at the declaration and at the call site (`countPlain(c.boxes[0])`); `countIn(in b)` and `countIn(b)` both compile; the aliasing rule (BYN3005, `ref c` together with `c.boxes[0]` in one call) applies either way. `in` exists only so C# code ports without edits.

## Lessons

- **What went wrong on 27–28 October.** T11–T17 were landed by an agent whose tests typed the expected lines by hand. Those tests pass trivially, and so did the old guard. Q711 lists the defects four independent reviews found: T12 `checkOverloads` panics on any struct that has a method; T14 tests the private bit as if it were the static bit; T13 `checkMutation` and `checkRequires` were empty while the log said they were ported; sibling fallbacks in T15 `bindConstructor`, T16 `bindExitCode`/`bindAssert*`, T17 `bindName`/`bindConverted` and T13's fake `body = 0`; Q704 was skipped; 8 Questions made false claims.
- **Root causes, all fixed (Q710, Q712, Q714).** Nothing compared a port with the C# before it landed; `ctx.byn` was frozen without the C# state the ports need; writers ticked their own tasks; mutants that failed to compile counted as killed.
- **The independent review works.** Reviewers found real HIGH defects even in guarded redos. Always run it, and give the reviewer the code, never the writer's summary. A review takes about 5 minutes and 150k tokens.
- **Decide cross-task state up front, for any new port.** List every field of the C# classes the port touches and add each missing one to `ctx.byn` (shared or sectioned) before writers start.
- **Cross-task state in practice.** T13 needed state written by T11 and T12, so neither task's own section worked. When a reviewer flags missing state that another task writes, add a shared field rather than let a writer approximate it.
- **Land order matters** where a later task reads an earlier task's section (T13 read T15's `typeArgs`).
- **Budgets.** A redo took 100–140 tool calls and 30–75 minutes per task. A first-time task is about 80 agent turns; one that runs out is restarted with a short "finish these items" prompt, not resumed. At most 2 writers at once on a shared machine, each under `nice -n 19`.
- **Port in dependency order, not all in parallel.** Coupling through stubs left paths untestable against the C# (T15 `bindChecks` waited on T38, `bindEnumArguments` on T20; T13's second pass on T15–T17 and T20). Declarations first, then the binder core, then expressions and calls.
- **A break-test restores the file from a copy taken first.** `git checkout --` restores the stub and erases the port.
- **Writers' redo prompt.** A redo starts from the earlier code, keeps what is right, verifies each finding against the C# before fixing it, writes no stand-ins for siblings, and finishes only on `GUARD PASS`, reporting fixed, judged wrong (with the C# line) or blocked (Q number).

## Left to do

- [ ] Remove the redundant `in` from parameters and arguments. About 1,700 `(in ` and `, in ` occurrences remain in `selfhost/semantics/*.byn`, plus 9 in `docs/specs/010-self-hosted-semantics/010-api.md`. Use `bayan fmt` if it implements the removal, otherwise a scripted edit that drops `in ` before a parameter type or argument. `for x in xs` and the range test `x in a..b` use the same keyword and stay. Done when `grep -rnE "\(in |, in " selfhost` matches only those two forms and the self-hosted tests pass. Tracked in `work/todo.md`.
- [ ] Audit the debt markers in `selfhost/`: `mutation-exempt:`, `coverage-exempt:` and `(blocked: Qnnn)` stubs are debts. No `coverage-blocked:` marker may remain (Q838); one is in `selfhost/emitter/cprint/expr.byn`. Done when the grep for it is empty. Tracked in `work/todo.md`.
