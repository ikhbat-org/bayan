Commit `821afa40`, 2026-11-09.

# Bayān audit

Contradictions, stale examples, grammar-rule violations, wrong code references and spec-vs-code mismatches found while writing the export. Sources: the diagnostics writer's notes, the spec and grammar writer's notes (each re-checked against the files at this commit), and the status writer's own findings. No fix is applied here. Each entry gives location, problem, the rule it conflicts with, and a proposed fix.

"SPEC" is `docs/bayan-spec.md`, "GRAMMAR" is `docs/bayan-grammar.md`, "STYLE" is `docs/bayan-style.md`. Code paths are relative to the repository root. Code under `src/` and `tests/` is identical at `821afa40` and at this branch's head.

## Wrong code references

**A1. Criteria names for BYN5100 and BYN5101**
- Location: `tmp/spec-snapshot/criteria.md` (file 3 required rows); `src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs:350`; `docs/bayan-design-round-4-draft.md:269`; `docs/bayan-design-round-4-inventory.md:13`, `:240`.
- Problem: the criteria call BYN5101 "the `-er` doer rule" and BYN5100 "the iḍāfa naming rule". In code BYN5101 is `NounOnMutator`, "`{0}` is a noun on a `ref this` member; name the action" (warning; golden `tests/cases/diag/noun-on-mutator.diag:1`). BYN5100 is allocated nowhere; it appears only as "Naming rules BYN5100/5101", a v0.2 proposal without name or message. No document states an iḍāfa naming rule. The `-er` doer pattern is SPEC §5.2 (`docs/bayan-spec.md:760`) and has no checker ("No dedicated code yet", GRAMMAR:25).
- Rule: a cited code must be allocated and mean what the citation says.
- Fix: correct the criteria wording, or allocate the codes through a revision. Until then the `-er` rule is spec-only and the iḍāfa rule is not found.

**A2. `work/todo.md:154` cites BYN1237**
- Location: `work/todo.md:154` ("No golden covers the BYN1237 `NoTargetType` help").
- Problem: BYN1237 is not allocated. `NoTargetType` is BYN2218 (`DiagnosticCodes.cs:175`).
- Rule: a cited code must be allocated.
- Fix: change BYN1237 to BYN2218.

**A3. Round-4 reserved comment lines describe draft wording that changed**
- Location: `DiagnosticCodes.cs:387`, `:390`; `docs/revisions/0016-addendum-a1-midflight.md:80`.
- Problem: the comments say round 4's draft cites BYN1069 and BYN7010, which collide with live codes. The draft now says BYN1070 (`docs/bayan-design-round-4-draft.md:231`) and BYN7013 (`:228`, `:252`), so the comments are stale. Revision 0016:80 still says "`final` states and BYN7010", and BYN7010 is the live `BecomesNeedsRef` (`DiagnosticCodes.cs:377`).
- Rule: a code number names one diagnostic; a reserved line must match its source.
- Fix: drop the "draft says" clauses from the two comments; correct revision 0016:80 to BYN7013 through a new revision.

**A4. SPEC cites codes that have no descriptor as live errors**
- Location: SPEC:270 (BYN3203), :301 and STYLE:56 (BYN3210), :790 (BYN8002), :791 (BYN3211), :1058 (BYN2232), :1678 (BYN8003), :1691 (BYN8004).
- Problem: written as compile errors, but `DiagnosticCodes.cs` has no descriptor and `docs/diagnostics/` no page. Revision 0005 counts these as spec-only allocations. BYN2232 is listed in SPEC:1058, while the round-2 plan says it was "not added".
- Rule: revision 0005 (spec-only codes are allocations, not live checks).
- Fix: tag each `(spec-only)`; drop BYN2232 from SPEC:1058.

**A5. BYN5010 cited as an enforced rule**
- Location: SPEC:368, :769, :777, :1108, :1822; GRAMMAR (3 citations); `docs/bayan-design-round-3-addendum-1.md:70`.
- Problem: `EventOnPrefix` has no descriptor and nothing rejects an `onX` name. The addendum says BYN5010 "now also covers" stored function fields, as if it existed.
- Rule: same as A4.
- Fix: mark BYN5010 `plan` wherever it is cited.

**A6. SPEC §15.4 points to the wrong section**
- Location: SPEC:1729 (export `docs/export/BAYAN-SPEC.md:1734`).
- Problem: "a pattern built from `Untrusted` input still needs `Regex.escape` (§15.2)". §15.2 is Secrets; the `Regex.escape` sink row is in §15.1.
- Rule: cross-references point to the section that holds the rule.
- Fix: change `(§15.2)` to `(§15.1)`.

**A7. Code comments cite the wrong section for debug formatting**
- Location: `src/Bayan.Semantics/Binding/BinderExpressions.cs:2049` ("spec §13"), `:2133` ("HANDOFF §13").
- Problem: SPEC §13 is Concurrency. Display and `as: .debug` are SPEC §6.6 (SPEC:916-921).
- Rule: a code comment cites the section that states the rule.
- Fix: cite SPEC §6.6 in both comments.

**A8. BAYAN-DIAGNOSTICS.md count of spec-only codes**
- Location: `docs/export/BAYAN-DIAGNOSTICS.md:380`; `docs/plans/2026-10-22-002-design-round-3.md:467`; `docs/revisions/0005-byn5001-and-code-counts.md:3`, `:8`.
- Problem: the export says 10 of revision 0005's 12 codes were found and 2 are unverified. The plan's gate note names the list: 11 codes (3203, 3205, 3210, 3211, 3213, 3215, 5010, 8002, 8003, 8004, 8005), after BYN1055 left the row (revision 0012). BYN3213, BYN3215 and BYN8004 are in the export's reserved section, so none is missing.
- Rule: counts agree with the list they count.
- Fix: replace the sentence with the 11 codes and their status.

**A9. `DiagnosticCodes.cs` header overstates coverage**
- Location: `DiagnosticCodes.cs:3-6`.
- Problem: it says every code has a docs page and at least one golden case. Thirteen descriptors have no golden file (BYN1030, 1032, 1049, 2026, 2113, 2116, 2224, 2322, 2707, 2762, 3213, 3215, 3217). BYN2307's only golden hit is a comment in `tests/cases/diag/arguments-swapped.byn:1`. The test (`tests/Bayan.Tests/DiagnosticCodesTests.cs:37-50`) skips codes whose explain text says "No longer reported" or "Not reported yet".
- Rule: a comment states what the test enforces.
- Fix: "every live code has … at least one golden case".

**A10. BYN6007 message and SPEC §14 list handlers the binder does not support**
- Location: `DiagnosticCodes.cs:361`; SPEC §14 (export :1653); `src/Bayan.Semantics/Binding/Binder.cs:1431-1434`.
- Problem: the message and SPEC say `provide` takes `alloc`, `net`, `fs`, `clock`, `random`, `env`, `process`, `console` or `log`. The binder accepts only `alloc` (and `allocator`) and reports the others as `Unsupported`. SPEC does not say the others are not built yet.
- Rule: SPEC states what v0.1 does or marks the gap.
- Fix: add a v0.1 note to SPEC §14 that only the `alloc` handler is implemented.

## Spec-vs-code mismatches

**A11. Keyword lists in SPEC §2.4 differ from the lexer**
- Location: SPEC §2.4 (export :109, :115, :123); `src/Bayan.Syntax/Lexing/Keywords.cs:7-42`; `src/Bayan.Syntax/Parsing/Parser.cs:250`, `:1211`, `:1436`.
- Problem: `rest` is listed as a declaration keyword but is not in `Keywords.cs`; the parser reads it contextually (`Parser.cs:1436`). `expects` appears in neither the keyword lists nor the contextual-word list, but the parser reads it contextually (`Parser.cs:250`, `:1211`). `when` (pattern guards, §6.5) is also missing from the contextual list (`Parser.cs:2955`).
- Rule: SPEC §2.4 is the keyword list.
- Fix: move `rest` to the contextual list and add `expects` and `when` there.

**A12. `async` and `await` still reserved; `scope` and `spawn` absent**
- Location: SPEC §2.4 (export :117); `Keywords.cs:29`.
- Problem: revision 0019 replaces `async`/`await` with `scope`/`spawn` (user decision 2026-11-04). The lexer still reserves `async` and `await` and has no `scope` or `spawn`.
- Rule: revision 0019.
- Fix: update the lexer and §2.4 when the §13 rewrite (A20) lands.

**A13. Words SPEC removed are still lexed as keywords**
- Location: SPEC §2.4 (export :127, :131); `Keywords.cs:10`, `:12`, `:14`, `:25`, `:27-28`, `:36`; `src/Bayan.Syntax/Lexing/TokenKind.cs:197-201`.
- Problem: SPEC says "`flags`, `errdefer` and `delegate` are not keywords" and that `set`, `noalloc`, `nosuspend` and `suspends` left the list. All are keyword tokens in the lexer. `flags` and `set` are contextual (names elsewhere). `errdefer`, `delegate`, `noalloc`, `nosuspend`, `suspends` and `foreach` are not contextual, so they cannot be identifiers. The lexer keeps them so the parser can give the teaching errors (BYN1020, BYN1028, BYN6001, `Parser.cs:1349`).
- Rule: SPEC §2.4.
- Fix: SPEC says they are lexed only for the teaching error and are not identifiers, or make them contextual in `TokenKindFacts.IsContextualKeyword`.

**A14. `tryX` is described as derived but only checked**
- Location: SPEC §5.2 (`docs/bayan-spec.md:742`); `src/Bayan.Semantics/Naming.cs:75`.
- Problem: SPEC says `tryX()` is "derived from `x() fails`". The compiler checks a hand-written `tryX` (BYN5003, golden `tests/cases/diag/try-wrong-return.diag`); no code derives one.
- Rule: SPEC states what v0.1 does or marks the gap.
- Fix: mark derivation of `tryX` as not in v0.1, like the `derivation` mechanism (SPEC:788).

**A15. Sequence `except` is parsed but not bound**
- Location: SPEC §6.8 (export :947-962); `Parser.cs:3375`; `src/Bayan.Semantics/Binding/BinderCalls.cs:583`; `tests/cases/parse/except-expr.byn:1`.
- Problem: SPEC §6.8 describes `for line in lines except inactive` and `users except null` without a v0.1 note. The parser builds `ExceptExpr`, but the only reference to it in `src/Bayan.Semantics` is `BinderCalls.cs:583`. Only the error-set form (`TypeResolver.cs:433`, `tests/cases/run/errors-except-narrowing.byn:7`) has a run golden.
- Rule: SPEC states what v0.1 does or marks the gap.
- Fix: mark sequence `except` as not yet bound in v0.1, or bind it.

**A16. Units described without a v0.1 note**
- Location: SPEC §3.4 (export :257-280); `src/Bayan.Semantics/Builtins.cs:187`; `src/Bayan.Semantics/Binding/BinderExpressions.cs:415`.
- Problem: the code says "units are spec-only", has no `unit` declaration parse, and reports a unit suffix as `Unsupported`. SPEC §3.4 reads as implemented.
- Rule: SPEC states what v0.1 does or marks the gap.
- Fix: add "Units are not in v0.1" to §3.4.

**A17. Revision 0016 defers `when` guards that are built**
- Location: `docs/revisions/0016-addendum-a1-midflight.md:78`; SPEC §6.5 (export :878); `Parser.cs:2955`, `:3601`; `tests/cases/diag/non-exhaustive-union-guard.byn:8`.
- Problem: revision 0016 lists "subjectless `switch` and `when` guards" as waiting for round 4. `when` guards are in SPEC §6.5 and parsed and checked. The subjectless `switch` is not built (`Parser.cs:2907` requires a subject; BYN1071 reserved at `DiagnosticCodes.cs:388`).
- Rule: later revision wins; here the code and SPEC disagree with the revision.
- Fix: a revision that records `when` guards as built and keeps only the subjectless `switch` in round 4.

**A18. Revision 0019 says the lexer still reserves `ensures`**
- Location: `docs/revisions/0019-round-4-batches-1-8-consistency.md:75`.
- Problem: it says `Keywords.cs:41` still reserves `ensures`. `Keywords.cs` has no `ensures` at this commit, and `tests/cases/run/ensures-identifier.byn:1` uses it as a name.
- Rule: a found-not-applied note is closed when applied.
- Fix: mark the line applied.

## Contradictions between documents

**A19. "No GC in v1" against "no GC tier"**
- Location: SPEC:41 (§1 table).
- Problem: says "no GC in v1"; SPEC §9.8 (:1325-1326) and revision 0019 say there is no GC tier at all.
- Rule: revision 0019.
- Fix: reword SPEC:41 to "no GC tier". The export already does.

**A20. SPEC §13 still specifies `async`/`await`**
- Location: SPEC §13.1-13.5 and the §14 `suspend` text (export :1537-1590).
- Problem: SPEC §13 still specifies `async f()`, `await`, `Io.group`, `provide timeout:` and fibers. Revision 0019 replaces them with `scope`/`spawn` and lists the §13 rewrite as pending. The replacement rules exist in no document.
- Rule: revision 0019.
- Fix: a revision that rewrites §13. Until then the export marks the old text superseded.

**A21. Clause order has no numbered revision**
- Location: SPEC §2.5 note (export :154); `docs/revisions/0002-round-3-consistency-review.md:11`; `DiagnosticCodes.cs:101`; `Parser.cs:1304-1321`.
- Problem: revision 0002 item 1 orders clauses `where` → `expects` → `becomes` → `fails` → `uses`. SPEC, the BYN1065 message and the parser use `where` → `expects` → `uses` → `becomes` → `fails`, citing "Round 4 §1". That order is a draft row (`docs/bayan-design-round-4-draft.md` feature table), not a numbered revision.
- Rule: SPEC changes only through numbered revisions.
- Fix: a revision that records the current order.

**A22. Type overload rules against "not in v0.1"**
- Location: SPEC §10 overload rules 2-5 (:1385-1389, BYN3213, BYN3215).
- Problem: rules 2-5 describe type overloads. Revision 0019 says type overloads are not in v0.1 (BYN2006), and :74 records this as found, not applied.
- Rule: revision 0019.
- Fix: mark rules 2-5 post-v0.1.

**A23. Lockfile name**
- Location: SPEC:2284 (§21.4); `docs/bayan-handoff.md:239`.
- Problem: both say `bayan.lock`. The name was superseded on 2026-11-06 by `package.lock.byn` (`docs/bayan-handoff-addendum-001.md:94`, `docs/bayan-design-round-4-inventory.md:124`, `docs/plans/2026-11-05-003-v0.3-packages.md:13`). No numbered revision records it.
- Rule: a later decision wins; SPEC changes through revisions.
- Fix: a revision naming `package.lock.byn`, then update SPEC §21.4.

**A24. Two "only lists" of input forms**
- Location: SPEC §21.5 (:2304, "This is the only list"); GRAMMAR §3 tables (:110-124).
- Problem: SPEC §21.5 lists many more input forms (BYN1053, BYN1068, `for T x in e`, `unless` rows) than GRAMMAR §3.
- Rule: SPEC §21.5 "This is the only list".
- Fix: GRAMMAR §3 points to SPEC §21.5, or the tables are synced.

**A25. Addendum 002 gives `ensures` runtime semantics**
- Location: `docs/bayan-handoff-addendum-002.md:167`.
- Problem: plans a SPEC "§14.x Contracts" with "`requires`/`ensures` runtime semantics now". Round 4 does not adopt `ensures` (`docs/bayan-design-round-4-draft.md:348`), and revision 0019 item 19 unreserves it.
- Rule: revision 0019 (later).
- Fix: mark the addendum-002 contracts item superseded for `ensures`.

**A26. BYN2787 against BYN1062 and BYN8001**
- Location: `DiagnosticCodes.cs` BYN2787 `TrustReason`; `docs/diagnostics/BYN2787.md`; `tests/Bayan.Tests/DiagnosticCodesTests.cs:93`.
- Problem: the descriptor still reads "`trust` needs a reason: a non-empty string literal". The `trust(x, reason:)` form is now the input form BYN1062, and BYN8001 `MissingBecause` covers the reason for `x.trustUnchecked() because "…"`.
- Rule: round 3 §17 (later).
- Fix: undecided. Either update the page and message, or retire BYN2787 in favour of BYN8001.

## Stale examples and unapplied revisions

**A27. BYN2006 page example reports other codes**
- Location: `docs/diagnostics/BYN2006.md`; `DiagnosticCodesTests.cs:80`.
- Problem: the test marks it "stale: the example now reports BYN5004 and BYN5006".
- Rule: a page's example reports its code.
- Fix: rewrite the example so it reports BYN2006 (for example the same-name, different-type pair in golden `diag/duplicate-overload-types`).

**A28. `trim()` in SPEC §6.6**
- Location: SPEC:693 (`public bool isBlank => trim().isEmpty`).
- Problem: strings have only `trimmed()` (`src/Bayan.Semantics/Binding/BuiltinMembers.cs:70`; revision 0004 item 2).
- Rule: revision 0004 item 2.
- Fix: `trimmed().isEmpty`. The export already has it.

**A29. Revision 0015 not applied to SPEC**
- Location: SPEC §6.2 conversions table; SPEC:2012 (§16.4 v0.1 scope line).
- Problem: there is no "Text → float" row, §16.4 does not name the float `tryParse`, and the scope line still says "ASCII `lowercased`/`uppercased`". Revision 0015 (:25-26) asks for all three. The code has `f64.tryParse` (`tests/cases/run/float-try-parse.byn:15`).
- Rule: revision 0015.
- Fix: apply the revision 0015 diff to SPEC. The export already has it.

**A30. Other revision text missing from SPEC**
- Location: SPEC §19.2 `grammar` dictionary (:2101-2105); SPEC laws; revision 0002 item 26; revision 0013 item 6; revision 0001 items 2-3; revisions 0002 item 27 and 0004 item 1.
- Problem: the `grammar` dictionary has `verbs`, `nouns` and `forms` but no `adjectives` (revision 0002 item 26). SPEC has no L016 "Equal keys are one entry" (revision 0013 item 6). The spec writer also reports revision 0001 items 2-3 (C# names stay reserved; `#line` placement) and the BYN3218 mixed-`requires` content rule (revisions 0002 item 27, 0004 item 1) missing as rule text. These last two were not re-checked (unverified). The export added all of them from the revision wording.
- Rule: revisions 0001, 0002, 0004, 0013.
- Fix: apply each to SPEC.

**A31. Addendum 002 items with no SPEC text**
- Location: `docs/bayan-handoff-addendum-002.md:137`, `:146-155`, `:167-168`.
- Problem: the contracts §14.x, `.par()` in §16 (v0.3) and the Appendix B `bayan verify` pointer are not in SPEC and were not added to the export.
- Rule: SPEC is the single specification.
- Fix: an owner decision on whether to add them, as a revision.

## Grammar-rule violations

**A32. `provide allocator:` is a synonym of `provide alloc:`**
- Location: `Binder.cs:1430-1431` ("`allocator` is still accepted"); goldens `tests/cases/diag/env-get-escapes-context.byn:6`, `diag/interpolation-escapes-context.byn:6`, `diag/io-read-escapes-context.byn:6`.
- Problem: two spellings of one handler name, with no input-form diagnostic or fix-it. SPEC §14 names handlers after effects (`alloc`).
- Rule: GRAMMAR §3, "Synonym: Rejected: one is canonical, the other is an input form with a fix-it".
- Fix: make `allocator:` an input form with a fix to `alloc:` and update the goldens.

**A33. Addendum 002 examples use C# syntax**
- Location: `docs/bayan-handoff-addendum-002.md:146` (`…sum(o => o.total);`), `:155` (`Atomic<int>`), `:137` (`[Prove]`).
- Problem: a trailing `;`, the C# primitive `int` and a bracket attribute.
- Rule: current syntax: no `;` (SPEC §2.5, BYN1040), sized primitives by default (SPEC §3.1), attributes use `@` (SPEC §1).
- Fix: `orders.par().where(o => o.isPaid).sum(o => o.total)`, `Atomic<i32>`, `@prove`.

**A34. `xOp` names a type SPEC never defines**
- Location: SPEC §5.2 (:746, "Derived; type `Op<T, E>`").
- Problem: `Op<T, E>` appears nowhere else in SPEC and nowhere in `src/`.
- Rule: SPEC defines every type it names.
- Fix: define `Op<T, E>` in SPEC or mark `xOp` as proposed.

## Document structure

**A35. §21.4 comes before §21.3**
- Location: SPEC:2282 (§21.4), :2296 (§21.3).
- Problem: section order breaks numbering.
- Rule: document order follows numbering.
- Fix: move §21.3 before §21.4, or renumber.

**A36. No Japanese, Chinese or Esperanto source rows**
- Location: GRAMMAR §12 "Sources" (:378-400); STYLE.
- Problem: the criteria expect Japanese, Chinese and Esperanto source rows. GRAMMAR has Arabic rows only, plus one mention: "no Arabic or Esperanto source" (:391). Neither file has any Japanese or Chinese text.
- Rule: criteria (keep every source row).
- Fix: confirm whether such rows were meant to exist. None were invented.

**A37. Declaration order in DiagnosticCodes.cs**
- Location: `DiagnosticCodes.cs:73-106`.
- Problem: BYN1043 sits before BYN1040-1042, BYN1046 before BYN1045, and BYN1062 before BYN1058. A reader scanning by number misses them. No functional effect.
- Rule: none (readability).
- Fix: none required; reorder at the round-4 renumbering.

## Dropped

The following notes were checked against the files and not kept:

- **Diag note N7** (BYN2307 and BYN2762 missing from the self-hosted code tables): disproved. `selfhost/semantics/codes.byn:363` holds BYN2307, `:420` holds BYN2762, and `selfhost/parser/codes.byn:100` holds BYN1049.
- **Spec note N8** (`bayan expand` in the present tense): disproved. Every SPEC mention (:172, :754, :1508, :1613, :1639, :2251) says "will show", "once it lands" or "deferred".
- **Spec notes N10 and N14** (`format()` not defined): disproved. SPEC §6.6 (:916) defines `format()` as the allocating form derived from `Display.formatInto`, matching revision 0003 and the BYN2031 message.
- **Spec note N11** (`placed.raise(o)` unverified): no defect. `raise` takes no `ref this` (SPEC:1793), so the call is valid. `Event<T>` is not implemented, so no golden can exist.
- **Spec note N17** (`formatInto` → `format` unverified against `BuiltinMembers.cs`): no defect. `BuiltinMembers.cs` has neither name because `formatInto` is a user-written member (`tests/cases/run/enums.byn:18`).
- **Spec note N20, revision 0017 part** (the export cites pre-renumbering codes): not a defect. Revision 0017 (:5) says no existing code changes until round 4.

Merged rather than dropped:
- Diag N1, spec N7 and spec N15 are A1.
- Spec N3 and the revision 0015 part of N20 are A29.
- Spec N5 and N18 are A20.
- Spec N4 is split between A11 and A12.

Total entries: 37 (A1-A37). Dropped: 7 (the six items above; N10 and N14 count as two).
