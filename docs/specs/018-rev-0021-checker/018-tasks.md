# 018 — Tasks
Plan: ./018-plan.md

Order: P1; Part 5 = T1, T2, then merge `feat/018-rev-0021-checker` into `dev`; Part 3 = T3, T4, merge; Part 4 = T5–T9, merge.
Routing (Gemini quota week): writers `gem-code` (Argon), `codegen-lite` when agy's shell rules block the task; gates `review`.
Questions: Q1168–Q1175.

- [x] P1 Landing row — files: `scripts/selfhost/specs.tsv` (row 018: bydir `selfhost/semantics`, shared `selfhost/semantics/ctx.byn`, prefix `SelfhostRevisionT`, base `feat/018-rev-0021-checker`), `scripts/selfhost/land-rows.test.sh`, `018-api.md` — done when: `bash scripts/selfhost/land-rows.test.sh` passes.
- [x] T1 BYN7001 help, C# — files: `src/Bayan.Semantics/Binding/BinderStates.cs`, `tests/cases/diag/wrong-state-member-test.diag` (new) — covers: R1 — done when: the new golden shows the help, every other golden is unchanged, `dotnet test` green.
- [x] T2 BYN7001 help, `.byn` — files: `selfhost/semantics/states.byn`, `selfhost/semantics/binder2.byn`, `tests/Bayan.Tests/SelfhostRevisionT2Tests.cs` — covers: R1, R8 — done when: land.sh lands it; the T1 golden's lines match the C# output.
- [x] T3 Word classes, C# — files: `Manifest.cs`, `Lexicon.cs`, `Naming.cs`, `DiagnosticCodes.cs`, BYN5014 goldens and `docs/diagnostics/BYN5014.md` (+ diagdocs regen), a manifest-overlap golden — covers: R2–R5 — done when: goldens rewritten from the C# run, only BYN5014 goldens changed, `dotnet test` green.
- [ ] T4 Word classes, `.byn` — files: `selfhost/semantics/manifest.byn`, `naming.byn`, `codes.byn` (BYN5014 text), `ctx.byn` (T4 state: lexicon lists), `tests/Bayan.Tests/SelfhostRevisionT4Tests.cs` (whole-set lexicon parity: verbs, nouns, adjectives, collectives, irregular plurals) — covers: R2–R5, R8 — done when: land.sh lands it.
- [ ] T5 BYN5104 + BYN5105, C# — files: `Naming.cs`, `DiagnosticCodes.cs`, `docs/diagnostics-allocated.txt` (delete the code's `plan` line, dev 233d35de), goldens, `docs/diagnostics/BYN5104.md`, `BYN5105.md` — covers: R6, R7 — done when: goldens per R7, hits over `lib/` and `selfhost/` listed in the report, `dotnet test` green.
- [ ] T6 BYN5106 + BYN5107, C# — files: as T5 for 5106/5107 (their `plan` lines too) — covers: R6, R7 — done when: as T5.
- [ ] T7 BYN5104 + BYN5105, `.byn` — files: `naming.byn`, `codes.byn`, `SelfhostRevisionT7Tests.cs` — covers: R6, R8 — done when: land.sh lands it.
- [ ] T8 BYN5106 + BYN5107, `.byn` — files: as T7 — covers: R6, R8 — done when: land.sh lands it.
- [ ] T9 Part 4 docs — files: `DIAGNOSTICS.md` (generated), `selfhost/driver/diagdocs.byn` (regenerated), handoff Progress log — covers: R7 — done when: `bash scripts/docs/check.sh` 0 and L028 holds.
