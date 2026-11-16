# 018 — Plan
Spec: ./018-spec.md

## Approach
Three parts, each finished on `feat/018-rev-0021-checker` and merged to `dev` `--no-ff` before the next starts (5, then 3,
then 4). Inside a part the C# task lands first (it is the reference); the `.byn` port lands through
`scripts/selfhost/land.sh 018 T<n>` with expected lines taken from the C# run, never typed. No step of 017 or 015 owns
`Naming.cs`, `Lexicon.cs`, `Manifest.cs` or `states.byn` (checked 2026-11-10), so the parts land mid-flight as the revision
allows, provided every existing golden passes unchanged.

Lexicon sharing: no mechanism exists, so two copies stay (`src/Bayan.Semantics/Lexicon.cs`, `selfhost/semantics/naming.byn`
`buildLexicon`) and T3 replaces the sample-based parity check with a whole-set comparison. Rejected: generating one copy from
the other (new infrastructure, forbidden by the revision).

## Tech / dependencies
None new. .NET 10, zig 0.17.0 as pinned.

## Changes by area
- `src/Bayan.Semantics/Binding/BinderStates.cs` `ReportWrongState` — R1: the help line when the enclosing `if` condition is a
  member access `x.p` whose member body is exactly `this is .s` with `.s` in the wanted states; the code comment of R1.
- `selfhost/semantics/states.byn` (the BYN7001 report at the `check the state with` help) — R1 port.
- `src/Bayan.Syntax/Packages/Manifest.cs` `GrammarFields` and the grammar reader — R2, R3: `collectives`, the overlap check
  through the existing `Invalid(...)` manifest error path.
- `src/Bayan.Semantics/Lexicon.cs` — R5: `Collectives`, irregular plurals, adjectives.
- `src/Bayan.Semantics/Naming.cs` and `src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs` `UnknownWord` — R4.
- `selfhost/semantics/manifest.byn`, `naming.byn` — R2–R5 port.
- `Naming.cs` / `naming.byn` — R6: the four lints beside the existing BYN51xx lints; `DiagnosticCodes.cs` / `codes.byn`
  allocate BYN5104–5107 only.
- `docs/diagnostics/BYN5104.md`–`BYN5107.md`, `DIAGNOSTICS.md` (generated), `selfhost/driver/diagdocs.byn` (regenerated) — R7.
- `tests/cases/diag/` goldens — R1, R4, R7. `tests/Bayan.Tests/SelfhostRevisionT<n>Tests.cs` — R8.
- `scripts/selfhost/specs.tsv` row 018, `scripts/selfhost/land-rows.test.sh` — landing.

## Data / interfaces
`Grammar { verbs, nouns, adjectives, collectives, forms }`. Diagnostic texts are the revision's, verbatim.

## Risks & mitigations
- Part 4 lints fire on existing `lib/std` and `selfhost/` public names and break goldens or warnings-as-errors builds: each lint
  task first runs the lint over `lib/` and `selfhost/` and lists the hits in its report; hits are fixed with rename attributes
  only if the revision's exemptions cover them, else they become a Question (not a silent rename).
- Part 5 reading member bodies could leak into narrowing: the help reads the body only after BYN7001 has already fired.
- No input handling, auth or external calls.

## Coverage check
R1 T1/T2 · R2–R5 T3/T4 · R6 T5–T8 · R7 T5–T9 · R8 T2, T4, T7, T8 (and T4's whole-set lexicon test).
