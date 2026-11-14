# Bayān roadmap

State of `dev` at 04366a4f, 2026-11-14. Release history is in `CHANGELOG.md`. What Bayān will not do is in `docs/bayan-not-planned.md`. Optional improvements with no commitment are in `docs/bayan-nice-to-have.md`.

Bayān compiles itself. Release 0.3.0 makes the self-hosted compiler the `bayan` you download (`CHANGELOG.md`, 0.3.0). The next goals are to drop .NET and the C# compiler's role (`docs/bayan-handoff.md`, Target: zero dependencies) and to land the tooling ports.

## Where we are

| Release | Date | Tag | State | Source |
|---|---|---|---|---|
| 0.1.0 | 2026-11-02 | `v0.1.0` | shipped | `CHANGELOG.md` `[0.1.0]` |
| 0.2.0 | 2026-11-06 | `v0.2.0` | shipped | `CHANGELOG.md` `[0.2.0]` |
| 0.3.0 | 2026-11-14 | `v0.3.0` | cut on `dev` (`VERSION` is `0.3.0`, `CHANGELOG.md` `[0.3.0]`); waits for the dev → main merge and the tag, both the user's | `VERSION`, `CHANGELOG.md` `[0.3.0]`, `docs/RELEASING.md` |

### 0.1.0: the C# compiler (M0 — Skeleton to M12 — CLI completeness and machine-readable output)

Source: `CHANGELOG.md` `[0.1.0]`, `docs/bayan-handoff.md` (Milestones).

| Milestone | What it delivered |
|---|---|
| M0 — Skeleton | Solution, AOT CLI, diagnostics renderer, golden harness, CI |
| M1 — Lexer | UTF-8 lexer, BYN0001–0016, `bayan lex`, `bayan explain` |
| M2 — Parser | AST, recovery, BYN1001–1016, parse and diag goldens |
| M3 — Semantics I: names, types, mutability | Names, types, mutability, flow, error sets; 95 diagnostics |
| M4 — C backend: hello world | Lowering, C backend, runtime, `bayan build` and `run` |
| M5 — Errors | Error-handling goldens, `Result<T, E>`, non-exhaustive catch |
| M6 — Memory basics | Memory goldens, region analysis BYN3002–3005 |
| M7 — Tests | `bayan test`, one child process per test |
| M8 — tally-lite (exit criterion) | The v0.1 exit criterion, met |
| M9 — `bayan new` and `bayan init` | Project scaffolding, `package.byn` reader, project builds |
| M10 — Build outputs: `out/` and `dist/` | `--target`, `test --json`, `dist`, `clean` |
| M11 — Global cache and worktrees | Shared build cache, worktree reuse, cache stats |
| M12 — CLI completeness and machine-readable output | Colour, `bayan doctor`, `test --changed`, `--version`, `--diagnostics json`, exit codes 0–4 |

It also holds specs 001–010 and 013 and design round 3 (revisions 0002–0010). Archives: linux-x64, linux-arm64, macos-arm64, macos-x64, windows-x64, windows-arm64, with SHA256SUMS (`CHANGELOG.md` `[0.1.0]`).

### 0.2.0: Bayān compiles itself

Source: `CHANGELOG.md` `[0.2.0]`. The released binary was still the C# compiler.

| Item | What it delivered |
|---|---|
| Spec 011, self-hosted emitter | `selfhost/emitter/` emits the same C as the C# backend, byte for byte (L024, L025) |
| Spec 012, self-hosted driver and bootstrap | `selfhost/driver/`; stage 1, 2 and 3 emit identical C; `bootstrap/bayan.c` builds a compiler with only a C compiler (L028) |
| Spec 014, `Path` module | `Path.combine`, `directoryName`, `fullPath` agree with .NET (L026); `tests/windows-known-failures.txt` is empty |
| `bayan-lsp` and CLI memory bounds | `bayan-lsp` peaks at 81 MB where it passed 200 GB; test output, program cache and C compiler runs are capped |
| Move to the Ikhbat Foundation | Repository at `github.com/ikhbat-org/bayan`; home page `https://bayan.run` |

### 0.3.0: the self-hosted compiler is the default (spec 017)

Source: `CHANGELOG.md` `[0.3.0]`, `docs/specs/017-selfhost-default/017-tasks.md` (22 of 22 ticked).

| Item | What it delivered |
|---|---|
| Spec 017, self-hosted default | The released `bayan` is stage 2, built by the C# compiler's stage 1; `bayan version` prints `bayan X.Y.Z (selfhost)` |
| Spec 016, std library in the binary | `import std.<name>` loads modules from `lib/std/` (BYN2032, BYN2033); `std.json` is the first module |
| Revisions 0020–0023 | Versioned spec, agreement and doer nouns, contract hardening, syntax freeze (`CHANGELOG.md` `[0.3.0]` Revisions) |
| Spec 018, revision 0021 checker parts | Lint BYN5104–5107 and word classes, landed in all three parts (`docs/handoffs/2026-11-10-rev-0021-report.md`, `docs/specs/018-rev-0021-checker/018-tasks.md`: 11 of 11 ticked) |
| Signature clause order | `where`, `expects`, `uses`, `becomes`, `fails`; the old order is BYN1065 (`CHANGELOG.md` `[0.3.0]` Changed) |
| Runtime and release hardening | `Io.randomU64()`, SipHash-1-3 map hashing, bounded `Io.run` capture, prebuilt runtime object, release workflow gates, `docs/RELEASING.md` |
| License | ISL-P 1.2 with the ISL-OE 1.2 output exception |

Known limits of 0.3.0: Windows expects no failing test; archives do not include `bayan-lsp` (`CHANGELOG.md` `[0.3.0]` Known limits). The stage-2 build peak of 2.94 GB is named in the release notes (`docs/bayan-handoff.md`, Progress log, 2026-11-12 decisions).

## Next releases

The order below follows the sources where they give one and the dependencies where they do not. Nothing here has a calendar date. The syntax freeze (revision 0023) means no syntax change before 0.3.0 ships, except revision 0024 (`docs/bayan-spec.md` line 8, `docs/revisions/0023-syntax-freeze-provisional-sections.md`).

| Order | Item | State today | Source |
|---|---|---|---|
| 1 | Revision 0024, numeric conversions and .NET 11 | The last syntax change admitted after the freeze. The text is not in `docs/revisions/` yet; Q1 and Q1274 are decided (`dec(x)` on any `f32` or `f64` is an error with a fix-it) | `docs/bayan-spec.md` line 8, `docs/bayan-handoff.md` Questions 1274, `docs/plans/2026-11-12-008-release-prep-and-process.md` |
| 2 | Plan 015, Q31 memory follow-ups | Phases A, B and D are merged into `dev`; phase C (emit arena) is deferred by the user. Left open: the LOWs below | `docs/plans/2026-11-14-015-q31-followups.md`, `docs/bayan-handoff.md` Progress log (2026-11-14), `work/todo.md` lines 770–775, 794 |
| 3 | Spec 019, the .NET exit | Approved 2026-11-13, not written; to be written after 0.3.0, estimate 4–7 weeks. C# test outputs become goldens, the language server moves to Bayān, CI builds from `bootstrap/bayan.c`, the C# compiler stays frozen for diverse double-compiling | `docs/bayan-handoff.md` (Target: zero dependencies) |
| 4 | Spec 020, test-result cache | Approved; 0 of 27 tasks ticked. Build now with a thin adaptor if cheap, otherwise after 019 | `docs/specs/020-test-result-cache/020-spec.md` (Open questions, item 4), `020-tasks.md` |
| 5 | Sabk, native debug backend (`bayan build --backend native`) | Scheduled by the user 2026-11-13 after spec 019. `c` stays the default path; LLVM stays for release builds | `docs/plans/2026-11-05-005-parking-lot.md` (B04), `docs/bayan-handoff.md` (Target: zero dependencies) |
| 6 | Spec 015, tooling ports | 8 of 17 tasks ticked; T9–T17 open (`gen-lowercase`, `stryker-to-quality`, `quality-baseline`, `mutate-plan`, `std.regex`, `guard-checks`, `Base64`, `replay`). 012 is done, so the original wait is over | `docs/specs/015-tooling/015-tasks.md`, `docs/handoffs/2026-11-02-spec-015-tooling.md` |
| 7 | Round-4 design work, A1 and A2 addenda | 42 inventory rows open and 2 open as conflicts. Batches 1–8 landed as revisions 0019–0023; the rest wait for evidence or a user decision | `docs/bayan-design-round-4-inventory.md`, `docs/revisions/0019-round-4-batches-1-8-consistency.md`, `docs/revisions/a2-lessons-mid-flight.md`, `docs/revisions/0016-addendum-a1-midflight.md`, `docs/revisions/0017-addendum-a2-diagnostic-codes.md` |
| 8 | Concurrency, `scope` and `spawn` | Design confirmed, spec removed from §13 by revision 0023 (placeholder). Spec and runtime not written; `async` and `await` stay reserved in the lexer | `docs/bayan-concurrency.md`, `docs/misc/2026-11-04-design-inputs-review.md`, `work/todo.md` (A12) |
| 9 | Std items the spec tags as after v0.1 | `std.regex` (task T14 of spec 015), `std.text` members (`words`, `graphemes`, `normalized`, `Base64`), `matches(re)` and `replaced(re, by:)` | `docs/bayan-spec.md` §15.4 and the lines "After v0.1", `docs/revisions/0011-regex-after-v0-1-and-validation-error-instantiations.md` |
| 10 | Release plans v0.2a, v0.2b, v0.3, v0.4 | Written 2026-11-05, gated on round 4 (v0.2a, v0.2b) and on toolchain phase 2 (v0.4). Their version labels predate the 0.2.0 and 0.3.0 numbering | `docs/plans/2026-11-05-001-v0.2a-loop.md` to `-004-v0.4-interop.md` |

### Open follow-ups

| Follow-up | State | Source |
|---|---|---|
| Spec 018, Q1186–Q1191 | Open "Decision needed" rows on naming lints when the rev 0021 report was written; later status not checked | `docs/handoffs/2026-11-10-rev-0021-report.md` |
| Plan 015 LOWs | `test`, `mutate` and `dist` still build with the frontend alive; `--emit-c` runs in the arena for no gain; `t42SummaryInArena` has no `c.sink` guard | `work/todo.md` lines 771, 775, 794 |
| mmap arena chunks | `bayan-rt.c` large arena chunks through `mmap` and `munmap`, so macOS returns freed arenas to the OS | `work/todo.md` line 772 |
| Mutation CI | The `mutation` workflow stays disabled; `ci` and `laws-nightly` are re-enabled | `docs/bayan-handoff.md` Progress log, "CI repair before 0.3.0" |
| After 0.3.0 list | Q1229, Q1272, Q1273, the General allocator (Q31) arena per phase, parser and ownership depth (BYN1xxx "nested too deep") | `docs/bayan-handoff.md` (Decided by the user 2026-11-12, "After 0.3.0") |
| Before the tag | `authors` CI is red on `dev` since 2026-11-03; fixing needs a history rewrite the user runs | `work/todo.md` ("Before 0.3.0"), `scripts/move/2026-11-14-history-rewrite.sh` |

## Pending specs and plans

Slots: "(proposed)" marks a dependency-order proposal. A slot without it comes from the source named.

### Specs

| Id | Title | Status in the source | What is left | Depends on | Proposed slot |
|---|---|---|---|---|---|
| 015 | Tooling | decided (2026-11-02); ports wait for 012 (S1) | T9–T17 of 17 | 012 (done); `std.regex` (T14) before T15; `Io.run` streaming (Q1141) before T17 | After spec 019 (proposed) |
| 019 | .NET exit | not written (`docs/specs/019-*` does not exist) | Write the spec, then do it | 0.3.0 tag | After 0.3.0 (`docs/bayan-handoff.md`) |
| 020 | Test-result cache | approved | 27 of 27 tasks | Task 1 measures the per-unit process cost; 019 | Thin adaptor now or after 019 (`020-spec.md`) |
| 011 | Self-hosted emitter | draft (rev 3) | T16, the batch mutation run for `tests/quality-baseline.json` | mutation CI (disabled) | No slot |
| 012 | Self-hosted bootstrap | approved | T22, the driver batch mutation; parked by the user 2026-11-06 | mutation CI (disabled) | No slot |

### Plans

| Id | Title | Status in the source | What is left | Depends on | Proposed slot |
|---|---|---|---|---|---|
| 015 (2026-11-14) | Q31 follow-ups | phases A, B, D merged into `dev`; C deferred | Phase C, the LOWs in the table above, the one-time VM full suite and `/code-review low --fix`, the unrun cleanup script `scripts/cleanup/q31-followups.sh` | Phase C needs a `keep` arena design | Phase C: no slot |
| 006 | In-band errors and the C boundary | "Plan only" | W0 shipped as plan 007; W1 (runtime audit), W2, W3, W7, W8 not checked | none known | No slot |
| v0.2a | Fast loop, inspection, testing | dated 2026-11-05 | 10 items plus TinyCC `bayan run`, `@packed`, `@derive(Decode)` | Round-4 batch merged; A2 baselines | After round 4 (proposed) |
| v0.2b | IDE and syntax API | dated 2026-11-05 | all items | Round-4 batch; v0.2a item 2 (module cache) | After v0.2a (`002-v0.2b-ide.md`) |
| v0.3 | Packages and supply chain | dated 2026-11-05 | all items | v0.2a merged; before any public registry | After v0.2a (`003-v0.3-packages.md`) |
| v0.4 | Interop and targets | dated 2026-11-05 | all items | Toolchain phase 2: `cc bootstrap/bayan.c`, clang, gcc, TinyCC drivers | After toolchain phase 2 (`004-v0.4-interop.md`) |
| 005 | Parking lot | evidence-triggered | Each row waits for its trigger | triggers | No slot (see `docs/bayan-not-planned.md`) |

Not listed as pending: plan 000 (an index) and plan r4-section-10 (appended to the round-4 draft §10).

### Done, with a stale `Status:` line

I did not edit the spec files. Another writer owns them.

| Spec or plan | Status line says | Evidence it is done |
|---|---|---|
| 001 Self-hosted lexer | implemented (laws L001–L004 await enactment) | `docs/laws/001`–`004` say `status: enacted`; tasks T24–T31 are the enact and prove steps |
| 002 Ownership and law alignment | done (L005–L008 await enactment) | `docs/laws/005`–`008` say `status: enacted` |
| 011 Self-hosted emitter | draft (rev 3) | `CHANGELOG.md` `[0.2.0]`; handoff spec table row 011; 23 of 24 tasks ticked |
| 012 Self-hosted bootstrap | approved | `CHANGELOG.md` `[0.2.0]`; handoff spec table row 012; 23 of 24 ticked |
| 016 Std library source | done | Status is current; `CHANGELOG.md` `[0.3.0]` Added |
| 017 Selfhost default | approved | `CHANGELOG.md` `[0.3.0]`; 22 of 22 ticked; handoff row 017 |
| 018 Rev 0021 checker | approved | `docs/handoffs/2026-11-10-rev-0021-report.md` (merges 36921d29, 71021224, 10bb0a0d); 11 of 11 ticked |
| Plan 2026-11-02-003 Move to Ikhbat | waiting for approval | `CHANGELOG.md` `[0.2.0]` Changed (repository moved) |
| Plan 2026-10-21-001 Design round 2 | "awaiting approval" | `docs/bayan-handoff.md` Question 101 (decisions "superseded by design round 2 C1"); `docs/plans/2026-10-22-002-design-round-3.md` takes round 2 as input and wins over it |
| Plan 2026-10-22-002 Design round 3 | no status line | `CHANGELOG.md` `[0.1.0]` Added (revisions 0002–0010) |
| Plans 007, 009, 010, 011, 012, 013, 014 | approved or closed | 007: handoff Progress log (Phase A and B); 009, 011: `CHANGELOG.md` `[0.3.0]`; 010: closed, gate failed (see not-planned); 012–014: handoff Progress log and merges on `dev` |
| Plan 008 Release prep | approved | `CHANGELOG.md` `[0.3.0]` Changed (release gates) |
