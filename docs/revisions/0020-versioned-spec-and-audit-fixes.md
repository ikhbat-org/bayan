# 0020 — Versioned spec, 2026-11-04 style standard, AUDIT fixes

Status: accepted (user decision 2026-11-09)

## Problem

SPEC, GRAMMAR and STYLE carry no version, so a reader cannot tell which compiler they describe or which features it delivers. SPEC §19.2 and STYLE still show the style knobs from before the 2026-11-04 style decision (`docs/bayan-style-proposal.md`). The snapshot audit (`docs/export/BAYAN-AUDIT.md`, A1–A37) lists wrong code references, spec-vs-code mismatches, contradictions and unapplied revision text.

## Decision

1. Each source document carries a version header naming the release `bayan --version` prints (`0.2.0`, `src/Bayan.Backend.C/Toolchain.cs:33`) and the revisions applied.
2. SPEC marks every feature the 0.2 compiler does not implement with `(not in 0.2)` or `(partial in 0.2: …)` (table under "Status tags").
3. The 2026-11-04 style standard is applied as recorded in `docs/bayan-style-proposal.md`; where the task text differs, the record wins (see "Differs from the task text").
4. The AUDIT "apply now" items are applied below, each as a numbered item naming its AUDIT id. Corrections to frozen documents outside this revision's file list are recorded here as "supersedes <file:line>" items and not edited there.

Edits are anchored on text and section, not line numbers.

| # | AUDIT / part | File, section | Change |
| --- | --- | --- | --- |
| 1 | A36 | `tmp/spec-snapshot/criteria*.md` (gitignored, not in the repo) | Intentional: only Arabic sources are cited. The snapshot criterion asking for Japanese, Chinese or Esperanto rows was removed by the dispatcher; no other action. `docs/bayan-design-round-2.md` is unchanged |
| 2 | A1 | `docs/export/BAYAN-STATUS.md` naming rows; `docs/export/BAYAN-DIAGNOSTICS.md` BYN5100 row | `-er` is SPEC §5.2's pattern with no checker; BYN5101 is `NounOnMutator`; BYN5100 is unallocated. Supersedes `docs/bayan-design-round-4-draft.md:269` and `docs/bayan-design-round-4-inventory.md:13`, `:240` ("Naming rules BYN5100/5101"): BYN5100 is unallocated and BYN5101 is `NounOnMutator` |
| 3 | Part 2.1 | SPEC §19.2 `style` block and text; STYLE Defaults, Configuration, new "Style lints" and "Opting out" | Knobs per the record §4.2 (`docs/bayan-style-proposal.md:330-342`): `indent: 4`, `width: 120`, `align: .runs` (or `.none`), `trailingCommas: .multiline` (or `.never`), `booleans`, `primitives`, `lints`. `braces`, the 100-column line knob and `trailingCommas: true` are gone. `{` always ends the line, no own-line `{` (record §3.4, :155); header continuations at two levels (:172). Layout is never compiler-enforced; idiom lints are diagnostics, `.suggestion` by default (C9, :309, :399; the knob change is review row C8, :393-397). The five initial lints (:313-321) and `@unformatted because "…"` (§4.4, :359-368). Tagged not / partial in 0.2 (manifest check `src/Bayan.Syntax/Packages/Manifest.cs:35`, `:179-184`) |
| 4 | Part 2.2 | (none; Open items) | Style-lint codes: the record puts each lint in the `x900–x999` range of its area (`docs/bayan-style-proposal.md:311`), assigned at the round-4 renumbering, which avoids the live BYN4001 and BYN4002. No code is allocated; added to Open items for the round-4 renumbering list |
| 5 | Part 2.3, A30 (revision 0002 item 26) | SPEC §19.2 `grammar` dictionary | `adjectives: ["idempotent"]` beside `verbs` and `nouns`; the text names all three. The BYN5014 message and fix-it change is queued in `work/todo.md` |
| 6 | Part 2.4 | SPEC, GRAMMAR, STYLE under the H1; `docs/export/BAYAN-GRAMMAR.md` | `Version: 0.2.0 (matches \`bayan --version\`)` and `Revisions applied: 0001–0020`. The export GRAMMAR title loses "(rev 0016)"; its header says `Revisions applied: 0001–0019`, since its body is the 8d5e5c71 snapshot. Its body tag "(rev 0016)" on the doer row reads "(revision 0016)" |
| 7 | Part 4.3 | SPEC, throughout | Status tags; full list under "Status tags" |
| 8 | A2 | `work/todo.md:162` | BYN1237 → BYN2218 (`NoTargetType`, `src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs:175`) |
| 9 | A3 | `docs/revisions/0016-addendum-a1-midflight.md:79` | Supersedes revision 0016:79: "`final` states and BYN7010" reads "`final` states and BYN7013" (round-4 draft `docs/bayan-design-round-4-draft.md:228`, `:252`); BYN7010 is the live `BecomesNeedsRef`. The stale "draft says" comments at `DiagnosticCodes.cs:387`, `:390` are a queued code task |
| 10 | A4 | SPEC §3.4 (BYN3203), §3.5 (BYN3210), §5.3 (BYN8002, BYN3211), §7.4 note (BYN2232), §15.1 (BYN8003, BYN8004), §15.2 (BYN8002); STYLE "Trees and graphs" (BYN3210) | BYN3203, BYN3210, BYN3211, BYN8002, BYN8003, BYN8004 tagged `(spec-only)` (revision 0005); BYN2232 dropped from the §7.4 note (round-2 plan: "not added") |
| 11 | A5 | SPEC §3.10, §5.2, §7.6, §16.1 (seven sites); GRAMMAR §1, §2 and §13 (three sites) | BYN5010 `EventOnPrefix` marked "(plan)"; GRAMMAR's links to the nonexistent `docs/diagnostics/BYN5010.md` removed. Supersedes `docs/bayan-design-round-3-addendum-1.md:70`: BYN5010 is a plan code with no descriptor, so it "would cover" stored function fields once added, not "now also covers" |
| 12 | A6 | SPEC §15.4 | `Regex.escape` cites `(§15.1)`, not `(§15.2)` |
| 13 | A7 | (code) | Queued in `work/todo.md` |
| 14 | A8 | `docs/export/BAYAN-DIAGNOSTICS.md`, spec-only paragraph | The count sentence names the 11 codes of `docs/plans/2026-10-22-002-design-round-3.md:467`: BYN3203, 3205, 3210, 3211, 5010, 8002, 8003, 8005 are plan rows; BYN3213, 3215 are reserved descriptors (`DiagnosticCodes.cs:314`, `:317`); BYN8004 is in the Reserved table |
| 15 | A9 | (code) | Queued in `work/todo.md` (`DiagnosticCodes.cs:3-6` header) |
| 16 | A11 | SPEC §2.4 | `rest` moves from the declaration keywords to the contextual words; `expects` and `when` are added there (`src/Bayan.Syntax/Parsing/Parser.cs:250`, `:1211`, `:1436`, `:2955`) |
| 17 | A13 | SPEC §2.4 | `flags`, `errdefer`, `delegate`, `set`, `noalloc`, `nosuspend`, `suspends`, `foreach` are lexed only for the teaching errors (BYN1019, BYN1020, BYN1028, BYN6001; §21.5); `flags` and `set` are contextual, the others cannot be identifiers |
| 18 | A14 | SPEC §5.2 | `tryX` row: "(partial in 0.2: a hand-written `tryX` is checked; none is derived)" (`src/Bayan.Semantics/Naming.cs:75`) |
| 19 | A15 | SPEC §6.8 heading | "(partial in 0.2: only the error-set form; sequence `except` parses but is reported as unsupported, BYN2022)". Checked: `for l in lines except "a"` gives BYN2022 "this expression is not supported" (`src/Bayan.Semantics/Binding/BinderExpressions.cs:387`); the error-set form binds (`src/Bayan.Semantics/TypeResolver.cs:433`) |
| 20 | A16 | SPEC §3.4 heading | "(partial in 0.2: `type distinct` only; `unit` declarations and unit suffixes are not in 0.2)" (`src/Bayan.Semantics/Builtins.cs:187` "units are spec-only"; `BinderExpressions.cs:415` reports a unit suffix as BYN2022; `type distinct` has BYN3204 and run golden `tests/cases/run/struct-requires.byn`) |
| 21 | A17 | `docs/revisions/0016-addendum-a1-midflight.md:78` | Supersedes revision 0016:78 "subjectless `switch` and `when` guards": `when` guards are built (SPEC §6.5; `Parser.cs:2955`; golden `tests/cases/diag/non-exhaustive-union-guard.byn:8`); only the subjectless `switch` waits for round 4 (`Parser.cs:2907` requires a subject; BYN1071 reserved, `DiagnosticCodes.cs:388`) |
| 22 | A18 | `docs/revisions/0019-round-4-batches-1-8-consistency.md:75` | Supersedes revision 0019:75: applied. `src/Bayan.Syntax/Lexing/Keywords.cs` has no `ensures`, and `tests/cases/run/ensures-identifier.byn:1` uses it as a name |
| 23 | A19 | SPEC §1 table, Data row | "no GC in v1" → "there is no GC tier (revision 0019)" |
| 24 | A21 | SPEC §2.5 note | Records the clause order `where` → `expects` → `uses` → `becomes` → `fails`, which the BYN1065 message (`DiagnosticCodes.cs:101`) and the parser (`Parser.cs:1304-1321`) use. Supersedes revision 0002 item 1 (`docs/revisions/0002-round-3-consistency-review.md:11`, `where` → `expects` → `becomes` → `fails` → `uses`). The SPEC note cites this item |
| 25 | A22 | SPEC §10 Overloading, rules 2-5 | Each prefixed "(not in 0.2: type overloads, rule 1)"; rule 4 cites BYN3215 as reserved (`DiagnosticCodes.cs:317`). Applies revision 0019:74 |
| 26 | A23 | SPEC §21.4 Projects | `bayan.lock` → `package.lock.byn` (decided 2026-11-06: `docs/bayan-handoff-addendum-001.md:94`, `docs/bayan-design-round-4-inventory.md` batch 1), tagged "not in 0.2: no lockfile is written" (no lockfile name in `src/`). Supersedes `docs/bayan-handoff.md:239` (`bayan.lock` → `package.lock.byn`) |
| 27 | A24 | GRAMMAR §3 | Points to SPEC §21.5 as the complete list of input forms; GRAMMAR's tables are a selection |
| 28 | A27 | `docs/diagnostics/BYN2006.md` | Not applied. A corrected example would report BYN2006, and `tests/Bayan.Tests/DiagnosticCodesTests.cs:170-171` then fails until the stale skip entry at `:80` is removed, which is a test change. Queued in `work/todo.md` as one task (page example from golden `tests/cases/diag/duplicate-overload-types.byn` plus the skip entry) |
| 29 | A28 | SPEC §4.3 `isBlank` example (the AUDIT says §6.6) | `trim().isEmpty` → `trimmed().isEmpty` (revision 0004 item 2) |
| 30 | A29 | SPEC §6.2 conversions table; §16.4 Conversions and v0.1 scope line | Revision 0015 applied: a "Text → float" row; §16.4 names `f32.tryParse` / `f64.tryParse`; the scope line's `lowercased`/`uppercased` use Unicode simple case mapping, not ASCII (golden `tests/cases/run/float-try-parse.byn`) |
| 31 | A30 | SPEC §3.1 (lowercase type names), §3.3 laws line, §7.9 `requires`, §24 pipeline (DIR) | The C# primitive names stay reserved words (revision 0001; `Keywords.cs:50-53`); L016 "Equal keys are one entry" (revision 0013 item 6); the BYN3218 mixed-`requires` rule (revisions 0002 item 27, 0004 item 1; `DiagnosticCodes.cs:322`); `#line N "file.byn"` before each statement, none in generated helpers, a C diagnostic is an internal compiler error (revision 0001). The `adjectives` part is item 5 |
| 32 | A33 | `docs/bayan-handoff-addendum-002.md:137`, `:146`, `:155` | Supersedes addendum 002: `[Prove]` → `@prove` (:137, and :61 likewise); `orders.par().where(o => o.isPaid).sum(o => o.total);` → no trailing `;` (:146); `Atomic<int>` → `Atomic<i32>` (:155) |
| 33 | A35 | SPEC §21 | §21.3 Performance targets moves before §21.4 Projects, outputs and VCS; no text changes |

## Status tags

Every tag names what the 0.2 compiler (`bayan 0.2.0`) lacks. BYN2022 is `Unsupported`, "… is not supported in v0.1". Older "Not in v0.1" notes already in SPEC (for example §5.3 `derivation`, §10 rule 1, §20 `property`) are left as written; they still hold for 0.2.

| SPEC section | Tag | Evidence |
| --- | --- | --- |
| §2.3 Literals, Unit-suffixed row | (not in 0.2, §3.4) | `src/Bayan.Semantics/Binding/BinderExpressions.cs:415` |
| §2.3 Literals, C string and UTF-16 rows | (not in 0.2) | `BinderExpressions.cs:464` |
| §3.1 Primitives, `dec` row | (not in 0.2) | `src/Bayan.Semantics/TypeResolver.cs:214` |
| §3.4 Units and distinct types | (partial in 0.2: `type distinct` only; `unit` declarations and unit suffixes are not in 0.2) | `src/Bayan.Semantics/Builtins.cs:187`; `BinderExpressions.cs:415`; BYN3204 (`src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs:309`) |
| §3.6 Optionals, `?.` | (not in 0.2) | `BinderExpressions.cs:654` |
| §3.16 Lambdas and function types | (partial in 0.2: a lambda outside a function body is not supported) | `BinderExpressions.cs:1939` |
| §4.3 Extensions | (not in 0.2: `extension` declarations are reported as unsupported, BYN2022) | `src/Bayan.Semantics/Compilation.cs:508` |
| §5.2 `tryX` row | (partial in 0.2: a hand-written `tryX` is checked; none is derived) | `src/Bayan.Semantics/Naming.cs:75` |
| §5.2 `xOp` row | (not in 0.2) | `docs/export/BAYAN-STATUS.md` `xOp` row (no `Op<T, E>` in `src/`) |
| §5.2 `xInto` row | (partial in 0.2: only `formatInto` → `format`) | `BinderExpressions.cs:2169`, `:2175` |
| §5.2 Noun patterns | (not in 0.2: no noun type is derived; the `derivation` mechanism is not in 0.2, §5.3) | `docs/export/BAYAN-STATUS.md` `T.Builder`, `T.Patch`, `T.Field` rows |
| §5.3 Derivations, `@derive` | (not in 0.2: no `@derive` is implemented) | no `@derive` in `src/` or `tests/cases` |
| §6.5 Patterns | (partial in 0.2: no list patterns, no deconstruction (positional) patterns, no variables inside `or` patterns, no named patterns) | `src/Bayan.Semantics/Binding/BinderCalls.cs:1285`, `:1278`, `:1242`; `BinderExpressions.cs:380` |
| §6.8 `except` | (partial in 0.2: only the error-set form; sequence `except` parses but is reported as unsupported, BYN2022) | `BinderExpressions.cs:387`; `TypeResolver.cs:433` |
| §7.9 Validation: `requires` | (partial in 0.2: not on a plain `type` alias or a generic struct) | `Compilation.cs:531`, `:1130` |
| §9.6 Handles | (not in 0.2) | no `Pool` or `Handle` in `src/Bayan.Semantics` |
| §10 Overloading, rules 2-5 | (not in 0.2: type overloads, rule 1) | revision 0019:74; BYN3213, BYN3215 reserved (`DiagnosticCodes.cs:314`, `:317`) |
| §11 Generics | (partial in 0.2: no generic methods on types, no calls to generic interface methods) | `Compilation.cs:1048`; `BinderExpressions.cs:939` |
| §12 Comptime | (not in 0.2) | `comptime` is only a token (`src/Bayan.Syntax/Lexing/Keywords.cs:33`); nothing in `src/Bayan.Semantics` |
| §13 Concurrency | (not in 0.2: no `async`/`await`, `Io` implementations or fibers; revision 0019 replaces this section with `scope`/`spawn`, not yet written) | no `async`/`await` binding in `src/Bayan.Semantics`; AUDIT A20 |
| §15.2 Secrets | (not in 0.2) | no `Secret` in `src/` |
| §16.1 Events | (not in 0.2) | no `Event<T>` in `src/`; `docs/export/BAYAN-STATUS.md` `Event<T>` row |
| §19.2 Manifest, `style` | (partial in 0.2: the manifest check accepts only the pre-2026-11-04 knob set, and no style lint exists) | `src/Bayan.Syntax/Packages/Manifest.cs:35`, `:179-184` |
| §21.4 Projects, lockfile | not in 0.2: no lockfile is written | no lockfile name in `src/` |

Not tagged, with reason: §14 `provide` handlers other than `alloc` (`src/Bayan.Semantics/Binding/Binder.cs:1434`) are AUDIT A10, left for the user; overloaded constructors (`Compilation.cs:1080`) and `become` in a static method (`src/Bayan.Semantics/Binding/BinderStates.cs:32`) have no SPEC sentence that claims them; the §2.4 keywords STATUS marks spec-only (`yield`, `checked`, `fuzz`, `model`, `law` and others) have no feature text of their own beyond §2.4 and §20.

## Differs from the task text

1. Brace placement. Task: "`{` on its own line after a wrapped head". Record: `{` always ends the line; a wrapped parameter list closes with `) {`; no own-line `{` and no `braces` knob (`docs/bayan-style-proposal.md:155`, §5 decision table `:382-389`, C21 revised 2026-11-04, Status line `:3`). Applied: the record.
2. Alignment knob. Task: `alignment: .runs`. Record: `align: .runs`, or `.none` (`docs/bayan-style-proposal.md:330-342`, decision table `:382-389`). Applied: `align`.
3. BYN5014. Task: "BYN5014's fix offers only `verbs` or `nouns`". Code: the help already offers `adjectives` (`src/Bayan.Semantics/Naming.cs:145`; golden `tests/cases/diag/unknown-word.diag:7`); the message still says "verb or noun" (`DiagnosticCodes.cs:349`) and no fix-it is offered (`docs/diagnostics/BYN5014.md`; handoff Question 272). The queued task covers the message and the fix-it.
4. Version. Task example: `0.1.0-dev`, `(not in 0.1)`. Applied: `0.2.0`, `(not in 0.2)`, which `bayan --version` prints (`src/Bayan.Backend.C/Toolchain.cs:33`, commit 34b1a122).

## Open items

- Style-lint codes (item 4): for the round-4 renumbering list (`docs/bayan-design-round-4-draft.md`, and revision 0017's area ranges). Each lint takes a code in `x900–x999` of its area (`docs/bayan-style-proposal.md:311`), clear of the live BYN4001 and BYN4002. Nothing allocated.
- Manifest migration (item 3): `Manifest.cs:35` and `:179-184` still accept `braces`, the 100-column line knob and a bool `trailingCommas`, and reject `width`, `align` and `lints`; `bayan format` reads only `booleans` and `primitives`. A code task once the style lints are scheduled.
- Not settled by the record: nothing the task names is missing; `width`, the `{` rule, `align`, `@unformatted because "…"` and the five lints are all in `docs/bayan-style-proposal.md`.

## Left for the user

- A10: BYN6007 and SPEC §14 list `provide` handlers (`net`, `fs`, `clock`, …) that the binder reports as unsupported; only `alloc` is implemented (`Binder.cs:1431-1434`).
- A20: SPEC §13 still specifies `async`/`await`, `Io.group`, `provide timeout:` and fibers; revision 0019 replaces them with `scope`/`spawn`, but the replacement rules exist in no document.
- A25: addendum 002:167 gives `ensures` runtime semantics; revision 0019 item 19 unreserves `ensures`.
- A26: BYN2787 `TrustReason` overlaps BYN1062 and BYN8001; update the page and message, or retire it.
- A31: addendum 002 items with no SPEC text (contracts §14.x, `.par()` in §16, the `bayan verify` pointer).
- A34: `xOp` names `Op<T, E>`, which SPEC never defines; define it or mark `xOp` proposed (tagged `(not in 0.2)` meanwhile).
- A37: declaration order in `DiagnosticCodes.cs:73-106` (BYN1043, BYN1046, BYN1062 out of numeric order).
- Post-release version: tag `v0.2.0` exists and `Toolchain.cs:33` still says `0.2.0`; the move to the next `-dev` version was never made. The headers follow whatever `bayan --version` prints.

## Sections

SPEC §1, §2.3, §2.4, §2.5 note, §3.1, §3.4, §3.5, §3.6, §3.10, §3.16, §4.3, §5.2, §5.3, §6.2, §6.5, §6.8, §7.4, §7.6, §7.9, §9.6, §10, §11, §12, §13, §15.1, §15.2, §15.4, §16.1, §16.4, §19.2, §21.3, §21.4, §24, and the header. GRAMMAR header, §1, §2, §3, §13. STYLE header, Defaults, Configuration, Trees and graphs, new Style lints and Opting out. `docs/export/BAYAN-GRAMMAR.md` title and header, `BAYAN-STATUS.md` naming rows, `BAYAN-DIAGNOSTICS.md` spec-only paragraph and BYN5100 row. `work/todo.md`. `docs/bayan-handoff.md` Progress log.

## Codes

None added, retired or renumbered. BYN5100 stays unallocated; BYN5010 is a plan code; the style lints get codes at the round-4 renumbering.

## Sūq files

None affected: no Sūq source is changed by a docs revision. `package.byn` files that set `braces` or the 100-column line knob keep working until the manifest migration (Open items).

## Effect on work already done

- `work/todo.md` gains the queued code tasks: BYN5014 message and fix-it, A3, A7, A9, A12, A27, A32, and the manifest style knobs.
- The goldens are unchanged; no test reads SPEC text.

## Diff

The frozen documents below are not edited (dispatcher D13); this diff records how items 2, 9, 11, 21, 22, 24, 26 and 32 supersede them. Where this diff and the frozen text differ, this revision wins. SPEC, GRAMMAR, STYLE and the export files carry their changes directly (items 3-33).

### Item 2 (A1): `docs/bayan-design-round-4-draft.md`, `docs/bayan-design-round-4-inventory.md`
```diff
--- a/docs/bayan-design-round-4-draft.md
+++ b/docs/bayan-design-round-4-draft.md
@@ -269 +269 @@
-| Naming rules BYN5100/5101 | Consistent public APIs | More policing; wait for the friction count in section 3 |
+| Naming rules (BYN5100 unallocated; BYN5101 is `NounOnMutator`) | Consistent public APIs | More policing; wait for the friction count in section 3 |
--- a/docs/bayan-design-round-4-inventory.md
+++ b/docs/bayan-design-round-4-inventory.md
@@ -13 +13 @@
-| R4D §3 row 2 + §7 v0.2 BYN5100/5101 | Particles/naming rules on public API (friction count) | diag | evidence after 012 | M | open |
+| R4D §3 row 2 + §7 v0.2 naming rules (BYN5100 unallocated; BYN5101 is `NounOnMutator`) | Particles/naming rules on public API (friction count) | diag | evidence after 012 | M | open |
@@ -240 +240 @@
-- **Row 2 naming/particle rules (BYN5100/5101):** kept with the >5 `@allow`/renames per 10k lines trigger, measured on
+- **Row 2 naming/particle rules (BYN5100 unallocated; BYN5101 is `NounOnMutator`):** kept with the >5 `@allow`/renames per 10k lines trigger, measured on
```

### Item 9 (A3) and item 21 (A17): `docs/revisions/0016-addendum-a1-midflight.md`
```diff
--- a/docs/revisions/0016-addendum-a1-midflight.md
+++ b/docs/revisions/0016-addendum-a1-midflight.md
@@ -78,2 +78,2 @@
-- subjectless `switch` and `when` guards
-- `final` states and BYN7010
+- subjectless `switch` (`when` guards are built: SPEC §6.5)
+- `final` states and BYN7013
```

### Item 11 (A5): `docs/bayan-design-round-3-addendum-1.md`
```diff
--- a/docs/bayan-design-round-3-addendum-1.md
+++ b/docs/bayan-design-round-3-addendum-1.md
@@ -70 +70 @@
-- (c) Reused: BYN2230 (renamed member) for `onPanic` → `handler`; BYN5010 `EventOnPrefix` now also covers stored function fields (message unchanged, help "name the field for its role, such as `handler`").
+- (c) Reused: BYN2230 (renamed member) for `onPanic` → `handler`; BYN5010 `EventOnPrefix` (plan, no descriptor yet) would also cover stored function fields once added (message unchanged, help "name the field for its role, such as `handler`").
```

### Item 22 (A18): `docs/revisions/0019-round-4-batches-1-8-consistency.md`
```diff
--- a/docs/revisions/0019-round-4-batches-1-8-consistency.md
+++ b/docs/revisions/0019-round-4-batches-1-8-consistency.md
@@ -75 +75 @@
-- Lexer still reserves `ensures` (`Keywords.cs:41`, `selfhost/lexer/tokens.byn:186`); batch 1 unreserves it (line added to `work/todo.md`).
+- Applied (revision 0020): the lexer no longer reserves `ensures` (`tests/cases/run/ensures-identifier.byn:1` uses it as a name); batch 1 unreserves it.
```

### Item 24 (A21): `docs/revisions/0002-round-3-consistency-review.md`
```diff
--- a/docs/revisions/0002-round-3-consistency-review.md
+++ b/docs/revisions/0002-round-3-consistency-review.md
@@ -11 +11 @@
-1. **Clause order includes `expects`:** `where` → `expects` → `becomes` → `fails` → `uses`. Update HANDOFF:83 (shape), HANDOFF:95 (order sentence), and the BYN1065 message at plan:18.
+1. **Clause order includes `expects`:** `where` → `expects` → `uses` → `becomes` → `fails` (revision 0020 item 24). Update HANDOFF:83 (shape), HANDOFF:95 (order sentence), and the BYN1065 message at plan:18.
```

### Item 26 (A23): `docs/bayan-handoff.md`
```diff
--- a/docs/bayan-handoff.md
+++ b/docs/bayan-handoff.md
@@ -239 +239 @@
-Lockfile policy: `bayan.lock` is committed for apps and libraries alike (reproducible builds); do not ignore it.
+Lockfile policy: `package.lock.byn` is committed for apps and libraries alike (reproducible builds); do not ignore it.
```

### Item 32 (A33): `docs/bayan-handoff-addendum-002.md`
```diff
--- a/docs/bayan-handoff-addendum-002.md
+++ b/docs/bayan-handoff-addendum-002.md
@@ -61 +61 @@
-- Attributes: `[Exhaustive(...)]` (bounds for exhaustive checking), `[Prove]` (request the `proved` level, §3), `[Cases(n)]` (number of generated cases; default 10,000).
+- Attributes: `[Exhaustive(...)]` (bounds for exhaustive checking), `@prove` (request the `proved` level, §3), `[Cases(n)]` (number of generated cases; default 10,000).
@@ -137 +137 @@
-- `bayan verify` (v1.x) sends contracts and `[Prove]` laws in the decidable subset (integer arithmetic, arrays, enums, unions) to Z3. Results: proved, counterexample, or unknown (timeout). Unknown falls back to `tested`.
+- `bayan verify` (v1.x) sends contracts and `@prove` laws in the decidable subset (integer arithmetic, arrays, enums, unions) to Z3. Results: proved, counterexample, or unknown (timeout). Unknown falls back to `tested`.
@@ -146 +146 @@
-let revenue = orders.par().where(o => o.isPaid).sum(o => o.total);
+let revenue = orders.par().where(o => o.isPaid).sum(o => o.total)
@@ -155 +155 @@
-  help: use a reduction (`orders.par().count(o => …)`) or an Atomic<int>
+  help: use a reduction (`orders.par().count(o => …)`) or an Atomic<i32>
```
