# Tasklist — bayan

Every task for the body of work currently underway. This file **stays put** while work moves
through it: the `status/` rotation is a three-deep sliding window over this list, not a copy of
it.

The unit is one body of work, not one task and not the whole project. "Migrate the storage layer"
is a tasklist. When that work is done the file is emptied and refilled for the next body of work,
and what shipped is summarised in `CHANGELOG.md`.

## How it feeds the rotation

```
tasklist.md        T1 [x]  T2 [x]  T3 [x]  T4 [ ]  T5 [ ]  T6 [ ]  T7 [ ]
                            |       |       |
                            v       v       v
status/          previous.md  current.md  next.md      <- one task each
```

On each task completion, in this order:
1. `current.md` -> `previous.md`
2. `next.md` -> `current.md`
3. the next unchecked task here -> `next.md`, and tick it off here when it lands

`/status roll` does exactly this. `tasklist.md` is not touched by the rotation except for the
tick.

## Relationship to the neighbours

- `todo.md` is the *unscheduled* backlog: things worth doing that nobody has committed to. A task
  arrives here from there, or from a spec, or from the user directly.
- For Durable-tier work this list is `docs/specs/<NNN>-*/<NNN>-tasks.md`. Point at it rather than
  duplicating it — two copies of a task list is one stale copy.
- `milestones.md` is where the project is going. A tasklist is how one milestone gets done.

## Current work: the 0.3.0 release and its follow-ups (detail: `docs/RELEASING.md`, `docs/bayan-progress-log.md`)

- [x] **T1 — Preflight done, dev ready** — done when: the three-host preflight is fixed and merged into dev (`docs/bayan-progress-log.md`, "0.3.0 release preflight on three hosts")
- [ ] **T2 — Release 0.3.0** — done when: dev is pushed and merged to main, the `0.3.0-rc.1` dry run passes, tag v0.3.0 is published (the user does these)
- [ ] **T3 — Recheck `CliMemoryBoundsTests` on the dry run** — done when: the 25 rows pass on Linux in the release dry run (failed the 2026-11-12 dry run)
- [ ] **T4 — Write spec 019, the .NET exit** — done when: `docs/specs/019-*/` holds spec, plan and tasks (`docs/bayan-milestones.md`, Target: zero dependencies)
- [ ] **T5 — Spec 015 ports T9–T17** — done when: the listed scripts are Bayān tools with parity tests (`docs/specs/015-tooling/015-tasks.md`)
