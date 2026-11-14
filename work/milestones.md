# Milestones — bayan

Where this project is going, coarse. A milestone is a destination worth naming, not a task: it
survives many sprints, it is the thing you would tell someone who asked "what is this for", and
it changes rarely. If an entry here moves week to week, it belongs in `todo.md` or `status/`.

This is the one file in `work/` that is allowed to go a month without an edit. Editing it
means the plan changed, which is worth noticing.

**Distinction from the neighbours.** `milestones.md` is where we are going. `todo.md` is
everything not yet scheduled. `status/current.md` is what is being worked on right now. A single
item legitimately appears in all three at different times in its life, and should be in exactly
one of them at any given moment.

| # | Milestone | Target | Status | Notes |
|---|-----------|--------|--------|-------|
| 1 | 0.1.0: the C# compiler, language and CLI (M0–M12) | 2026-11-02 | shipped | `CHANGELOG.md` [0.1.0]; milestone list in `docs/bayan-handoff.md` (Milestones) |
| 2 | 0.2.0: Bayān compiles itself (self-hosted lexer, parser, checker, emitter, driver, bootstrap) | 2026-11-06 | shipped | `CHANGELOG.md` [0.2.0]; the released binary was still the C# compiler |
| 3 | 0.3.0: the self-hosted compiler is the default `bayan`, with `import std.json` | 2026-11-14 | in progress | Release pending: dev to main, rc.1 dry run, tag v0.3.0 (the user). `CHANGELOG.md` [0.3.0]; `work/status/current.md` |
| 4 | Leave .NET: C# tests become goldens, the language server moves to Bayān, CI builds from `bootstrap/bayan.c` | after 0.3.0 | planned | Spec 019, approved 2026-11-13, not yet written (4–7 weeks); `docs/bayan-handoff.md` (Target: zero dependencies) |
| 5 | Zero non-Bayān tooling: scripts ported off Python, bash and Deno | open | planned | Spec 015, T1–T8 landed and T9–T17 open; `docs/specs/015-tooling/015-spec.md` |
| 6 | Leave zig, then a native debug backend (toolchain phases 3 and 4) | open | planned | Approved 2026-11-13, after spec 019; v0.4 plan and parking lot B04; `docs/bayan-handoff.md` (Target: zero dependencies) |

Status is one of `planned`, `in progress`, `shipped`, `dropped`. A dropped milestone stays in the
table with a note saying why: the reason it was dropped is the most useful thing on the row, and
deleting it means re-litigating the decision in six months.
