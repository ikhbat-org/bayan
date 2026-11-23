# Bayān feature history

Version: 0.4.0-dev (matches `bayan --version`)
Revisions applied: 0001–0024

Where each numbered section of `docs/bayan-spec.md` came from, how it changed, and which release built it.
Rejected features are under "Not built" at the end.
`scripts/docs/check-history.sh` fails when a revision is not cited here or a numbered section has no entry.

## How to read this

- **From:** where the section came from.
  All 26 numbered sections were in the first spec, commit `62b0a4ec` (2026-10-20, "docs: add Bayan spec and v0.1 handoff").
  It came with `docs/bayan-handoff.md` ("HANDOFF — Bayan v0.1 bootstrap compiler"), added in the same commit `62b0a4ec` and deleted by the docs split (`3c7f8b69`); read it with `git show 62b0a4ec:docs/bayan-handoff.md`.
  The design rounds named after it are the ones the section's own `> Round …` notes cite.
- **Built:** the release that built the section, with its source.
  A `(not in 0.3)` or `(partial in 0.3: …)` tag in the spec marks what `bayan 0.3.0` does not implement.
  The tags were added as `(not in 0.2)` by revision 0020 and retagged to 0.3 on 2026-11-14 (commit `263a17ae`).
- **Changes:** one line per revision: the file, what changed, and why.
  "In v0.1.0" means the revision file is in that tag's tree.

Releases:

| release | date | source |
|---|---|---|
| 0.1.0 | 2026-11-02 | tag `v0.1.0`; `CHANGELOG.md` [0.1.0]; milestones M0–M12 (`docs/bayan-milestones.md`) |
| 0.2.0 | 2026-11-07 (tag); 2026-11-06 in `CHANGELOG.md` | tag `v0.2.0`; `CHANGELOG.md` [0.2.0] |
| 0.3.0 | 2026-11-15 (tag); 2026-11-14 in `CHANGELOG.md` | tag `v0.3.0`; `CHANGELOG.md` [0.3.0] |

Design sources:
`docs/bayan-design-round-2.md` (round 2),
`docs/bayan-design-round-3.md` (round 3, "HANDOFF"),
`docs/bayan-design-round-3-addendum-1.md` (round 3 addendum 1),
`docs/bayan-design-round-4-draft.md` and `docs/bayan-design-round-4-inventory.md` (round 4).

## Sections

### §0. Principles

- From: first spec; round 2 §18 (style is guidance applied by `bayan format`); round 3 §1, §28 (one spelling per construct, head-first order).
- Built: not a feature; the principles have no status tag.
- Changes:
  - `0022-contract-hardening-doc-consistency.md`: principle 9 now says no check is a build-mode option, not only memory safety.
    Why: a review of the contracts paper P4454R0 found that build-mode independence was stated only piecemeal.

### §1. The core on one page

- From: first spec.
- Built: not a feature; a summary of the later sections.
- Changes:
  - `0019-round-4-batches-1-8-consistency.md`: the design table says there is no GC tier, and `scope`/`spawn` replaces call-site `async`/`await`.
    Why: round-4 batches 1–9 settled these, and the spec still gave the old answer.
  - `0020-versioned-spec-and-audit-fixes.md`: §1 fixes from the snapshot audit (A1–A37).
    Why: the audit found wrong references and spec-vs-code mismatches.

### §2. Lexical structure

- From: first spec; round 2 §1, §6, §7, §8, §10, §11, §16; round 3 §2, §3, §4, §6, §7, §13, §14, §24, §28.
- Built: 0.1.0. The UTF-8 lexer (M1) and semicolon-free termination with waqf rules (round 3), `CHANGELOG.md` [0.1.0].
  0.3.0: the clause order `where`, `expects`, `uses`, `becomes`, `fails` (BYN1065), and `ensures` unreserved, `CHANGELOG.md` [0.3.0].
  Unit-suffixed, C string and UTF-16 literal rows are `(not in 0.3)`.
- Changes:
  - `0002-round-3-consistency-review.md` items 1, 25: `expects` joins the clause order; `fail` follows the line rule of `return`.
    Why: the review found contradictions between the HANDOFF and the plan.
  - `0003-strings-and-formatting.md` §3, §4: `b"…"` names bytes; `$"…"` allocates unless a formatting sink takes it.
    Why: so the allocation is visible.
  - `0004-conflicts-after-0002-0003.md` item 3: §2.3 raw multi-line literal stays as defined; revision 0003 §4 was amended instead.
    Why: the literal predates 0003, and 0003 §4's "not decided" was wrong.
  - `0019-round-4-batches-1-8-consistency.md`: §2.4 reserved words: `ensures` unreserved, `Gc`/`gc` gone.
    Why: round-4 batch 1 removed the GC tier and did not adopt `ensures`.
  - `0020-versioned-spec-and-audit-fixes.md` items 24 and others: §2.3 status tags, §2.4, the §2.5 note; records the round-4 clause order.
    Why: a reader could not tell which features the 0.2 compiler had.
  - `0024-numeric-conversions-and-dec.md`: §2.3 `dec` literal suffix row tagged `(not in 0.3, §3.1)`.
    Why: `dec` is specified in §3.1 and not built in 0.3.

### §3. Types

- From: first spec; round 2 §1, §2, §4, §8, §9, §10, §11, §12, §13, §15; round 3 §2, §8, §9, §10, §12, §13, §14, §26, §27, §28; round 3 addendum 1 §3.
- Built: 0.1.0. M3 types, tagged unions, user generics, `Map`, `Owned<T>`; spec 006 interfaces; spec 007 lambdas; spec 008 `Symbol`; round-3 `type distinct`, `@sealed`, typestate (`CHANGELOG.md` [0.1.0]).
  Units, `dec`, `?.`, generic lambda aliases and other items are tagged `(not in 0.3)` or `(partial in 0.3: …)` in the text.
- Changes:
  - `0001-round-3-pointers-line-freeze.md`: BYN1030 retired; C# primitive names stay reserved words.
    Why: BYN1030 broke `style.primitives: .csharp` projects (Q140).
  - `0002-round-3-consistency-review.md`: §3 consistency edits from the round-3 review.
    Why: decisions with no build step and rules an implementer would have to guess.
  - `0003-strings-and-formatting.md` §1: decoding is a codec (`Utf8.decode`); `string(x)` always formats.
    Why: in generic code `string(x)` would format and in concrete code decode: one expression, two results.
  - `0004-conflicts-after-0002-0003.md` item 2: §3.2 follows the `-ed` rule: `-ed` names a changed copy or a view.
    Why: 0002 and 0003 left §3.2 contradicting them.
  - `0006-error-payloads-byn2322-help-verbs.md`: error cases carry payloads (`timeout(i64 after)`); a new plan step 5.3h builds them.
    Why: §3.14 used payloads, but no step built them and they failed to parse (BYN1001).
  - `0007-field-writes-and-with-moves.md`: §3.10, only structs with `requires`, states or `@sealed` restrict outside field writes.
    Why: rejecting every outside write cost plain data `with` copies and one-off methods, with no invariant to protect.
  - `0010-becomes-needs-ref-this.md`: §3.17, only a `ref this` method may declare `becomes` (BYN7010–BYN7012).
    Why: every place a value's state can change must be visible in a signature.
  - `0011-regex-after-v0-1-and-validation-error-instantiations.md`: §3.14, instantiations of one generic error set compose.
    Why: a bare `ValidationError` covered none of the per-struct sets (Q339).
  - `0012-lambdas-shipped-subset.md`: §3.16 gains the spec 007 supported subset and its self-hosting gaps.
    Why: the section described the full design and did not say what spec 007 shipped.
  - `0013-hashmap-symbols-shipped-subset.md`: §3.3 `Symbol` subset; §3.5 `Map` key types; `HashMap` is BYN2830.
    Why: `Symbol` had two sentences; spec 008 did not add `HashMap`.
  - `0018-strbuf-finish-loan.md`: §3.5, `StrBuf.finish()` returns a loan on the buffer, not a consumed string.
    Why: no compiler or runtime implemented consumption (Q745); the spec follows the implementation.
  - `0019-round-4-batches-1-8-consistency.md`: the inheritance bullet (no GC tier) and §3.11.
    Why: round-4 batch 1.
  - `0020-versioned-spec-and-audit-fixes.md`: §3.1, §3.4, §3.5, §3.6, §3.10, §3.16 status tags and audit fixes.
    Why: version the spec and fix the snapshot audit's findings.
  - `0024-numeric-conversions-and-dec.md`: §3.1 `dec` representation (96-bit integer and scale 0..=28), scale preservation, rounding, overflow, conversions, `dec.fromF64(x, digits: n)` and `dec.tryParse`.
    Why: `dec` had only one table row, and .NET 11 changed decimal/float conversions.

### §4. Declarations and modules

- From: first spec; round 3 §4 (`@` attributes, `because`).
- Built: 0.1.0. Attributes (spec 001), `@attr` and `because` (round 3), `CHANGELOG.md` [0.1.0].
  §4.3 extensions are `(not in 0.3: … BYN2022)`.
- Changes:
  - `0007-field-writes-and-with-moves.md`: the attribute list adds `@sealed`.
    Why: plain data opts out of field-write checks only when the type says so.
  - `0008-sealed-help-positional-and-move-with.md`: `@positional` generates the positional constructor (step 5.3g).
    Why: J39 exempted `@positional` constructors, but no step built the attribute.
  - `0014-test-tooling.md`: §4.4, statements may carry attributes, from an allow-list.
    Why: `@unobservable` had to mark a statement, and attributes had no statement syntax.
  - `0020-versioned-spec-and-audit-fixes.md`: §4.3 status tag.
    Why: version the spec.
  - `0024-numeric-conversions-and-dec.md`: §4.3 `Duration.fromHours` example marked proposed.
    Why: `h * 3600s` multiplies an `f64` by an `i64`-backed unit with no conversion rule.

### §5. Naming and morphology (ishtiqāq)

- From: first spec; round 2 §1, §9, §17, §19; round 3 §11, §12, §16, §27, O15.
- Built: 0.1.0. Naming checks BYN5001–5003 (`docs/STATUS.md`), the verb lexicon and BYN5014 (round 3, `CHANGELOG.md` [0.1.0]).
  Derivations, `@derive` and noun patterns are `(not in 0.3)`; `tryX` and `xInto` are `(partial in 0.3: …)`.
- Changes:
  - `0002-round-3-consistency-review.md` item 17: `bayan expand` is deferred, so the text says what it will show.
    Why: the review found plan text with no build step.
  - `0005-byn5001-and-code-counts.md`: BYN5001 re-scoped: it fires on an `-ed` member that takes `ref this`.
    Why: 0004 allowed `-ed` without a mutating verb, which BYN5001 as built rejected.
  - `0020-versioned-spec-and-audit-fixes.md`: §5.2 and §5.3 status tags; the `-er` doer pattern gets no code.
    Why: version the spec; audit finding on unallocated codes.
  - `0021-agreement-word-classes-doer-nouns.md` Part 4: lints BYN5104 `NumberAgreement`, BYN5105 `CountName`, BYN5106 `DoerWithoutVerb`, BYN5107 `InstrumentChangesThis`.
    Why: number agreement and word classes had no check; each new rule is a public-API warning.

### §6. Expressions

- From: first spec; round 2 §1, §2, §3, §5, §7, §10, §12, §13, §19; round 3 §2, §5, §7, §27, O13.
- Built: 0.1.0. M3 and M4 expressions, `format()` and `Display.formatInto`, conversions `T(x)` (round 3, `CHANGELOG.md` [0.1.0]).
  `checked(expr)`, operator overloading and the derived `format()` are `(not in 0.3: …)`; patterns and `except` are `(partial in 0.3: …)`.
- Changes:
  - `0002-round-3-consistency-review.md` item 24: §6.2, `string(bytes)` decoded UTF-8; later replaced by 0003.
    Why: the review's byte-decoding rule.
  - `0003-strings-and-formatting.md` §1, §6: §6.2 conversions are codecs; §6.6 format specs are named arguments (BYN1068).
    Why: one meaning for `string(x)`; specs read as calls like every other option.
  - `0008-sealed-help-positional-and-move-with.md`: §6.1 precedence, `with` binds below the unary operators.
    Why: `move tx with { … }` parsed as `move (tx with { … })` and reported BYN2782.
  - `0015-float-parse-and-unicode-lowercase.md`: §6.2 gains a "Text → float" row, `f32.tryParse` and `f64.tryParse`.
    Why: no way to read a float from text, which the self-hosted compiler needs.
  - `0020-versioned-spec-and-audit-fixes.md`: §6.2, §6.5, §6.8 status tags and audit fixes.
    Why: version the spec.
  - `0022-contract-hardening-doc-consistency.md` item 9: §6.1, ranges bind looser than arithmetic, as the parser does.
    Why: §6.1 stated one precedence and the parser used another (user: keep the parser, Q1).
  - `0024-numeric-conversions-and-dec.md`: §6.2 enumerates every numeric conversion pair, single-rounding rule, float-to-integer saturation and `tryFrom`, and `dec` conversions (BYN2206 on `dec(x)` for floats).
    Why: numeric pairs and rounding were unenumerated, and `dec` conversions were unspecified.

### §7. Statements

- From: first spec; round 2 §4, §6, §7; round 3 §3, §5, §7, §11, §12, §13, §19, §25, O3, O4.
- Built: 0.1.0. Control flow, `for`, `defer`, `requires` at construction, `Panic.handler`, `print(…, to: .stderr)` (milestones M2–M5, round 3, `CHANGELOG.md` [0.1.0]).
  Several items are `(not in 0.3: …)`, among them `Rule.pattern(Regex re)`, BYN6008 and lazy queries; §7.7 `io:` is `(not in 0.x)`.
- Changes:
  - `0002-round-3-consistency-review.md` items 2, 5, 28: §7.4 `for` is pattern-based (`moveNext(ref this)`); `void main()`; panics print through `print`'s `to:`.
    Why: `Rows<T>` must iterate without claiming an interface whose bound it exceeds.
  - `0004-conflicts-after-0002-0003.md` items 1, 4: §7.4 loses the `T? next() fails E` bullet; a mixed `requires` gets BYN3218 `RequiresMixesFields`.
    Why: `moveNext`/`current` is the only iteration protocol; BYN3207 stays `LiteralNeedsTry`.
  - `0006-error-payloads-byn2322-help-verbs.md`: BYN2322 `RequiresNotHere` retired; the note now sits in §7.9.
    Why: once 5.3b checks `requires` on fields and distinct types, nothing raises it.
  - `0011-regex-after-v0-1-and-validation-error-instantiations.md`: §7.9, a bare `ValidationError` is rejected; `Rule` has no `pattern`.
    Why: no `Regex` type existed (Q326), and the bare set covered no struct (Q339).
  - `0014-test-tooling.md`: the statement rule takes optional leading attributes.
    Why: `@unobservable` marks statements.
  - `0020-versioned-spec-and-audit-fixes.md`: §7.4, §7.6, §7.9 status tags and audit fixes.
    Why: version the spec.
  - `0022-contract-hardening-doc-consistency.md` item 3: §7.9, `expects` clauses are pure; BYN6008 is the later check.
    Why: contract clauses had no purity rule.
  - `0023-syntax-freeze-provisional-sections.md`: §7.7 `io:` tagged `not in 0.x`.
    Why: tagged text describes a design, not a promise, and 0.x has no fibers.

### §8. Errors

- From: first spec; round 2 §5, §6, §15; round 3 §18 (`try` covers the whole expression to its right).
- Built: 0.1.0. M5 errors: `Result<T, E>`, error-handling goldens (`CHANGELOG.md` [0.1.0]; milestones M5); named payloads and `catch switch` (round 3).
  No status tag.
- Changes: no revision names §8.

### §9. Memory

- From: first spec; round 2 §2, §4, §9, §15; round 3 §31 (references in structs).
- Built: 0.1.0. M6 memory basics and region analysis BYN3002–3005; specs 002 and 003 ownership (`CHANGELOG.md` [0.1.0]).
  §9.6 handles are `(not in 0.3)`.
- Changes:
  - `0007-field-writes-and-with-moves.md`: `x = x with { … }` on a `unique` struct is a move.
    Why: the old value is dead once reassigned, yet it was reported as an implicit copy (BYN2780).
  - `0008-sealed-help-positional-and-move-with.md`: §9.3 shows `move x with { … }`.
    Why: 0007's `move tx` advice did not parse as meant.
  - `0019-round-4-batches-1-8-consistency.md`: §9.8, no GC tier and no `Gc<T>` handle.
    Why: round-4 batch 1.
  - `0020-versioned-spec-and-audit-fixes.md`: §9.6 status tag.
    Why: no `Pool` or `Handle` in `src/Bayan.Semantics`.
  - `0021-agreement-word-classes-doer-nouns.md` Part 1: §9.4 `Lexer` example uses `tokenList` and a `tokens` property.
    Why: `toks` was an abbreviation and `tokens()` a noun with no arguments.
  - `0023-syntax-freeze-provisional-sections.md`: the BYN3217 line.
    Why: its cross-reference was in the removed §13 text.

### §10. Parameters and arguments

- From: first spec; round 2 §9; round 3 §15 (argument particles), §24 (defaults, overloading, `rest`), O6, O12.
- Built: 0.1.0. Particles, `T(x)` conversions, `rest` (round 3); argument names (spec 004), `CHANGELOG.md` [0.1.0]; `docs/STATUS.md` rows `particles`, `rest`.
  Type overloads are `(not in 0.3: type overloads, rule 1)`.
- Changes:
  - `0002-round-3-consistency-review.md` item 28: `print` takes `to Stream stream = .stdout`.
    Why: stderr goes through the same formatting.
  - `0019-round-4-batches-1-8-consistency.md`: overloading; type overloads deferred.
    Why: round-4 batches.
  - `0020-versioned-spec-and-audit-fixes.md`: §10 status tags.
    Why: BYN3213 and BYN3215 are reserved, not raised.
  - `0021-agreement-word-classes-doer-nouns.md` Part 1: modifier examples become `ref StrBuf buffer`, `move File file`.
    Why: the examples were name-first, but parameters are type-first.
  - `0022-contract-hardening-doc-consistency.md` item 8: "Modifiers precede the parameter's type".
    Why: the sentence still said "parameter name".

### §11. Generics (partial in 0.3: no generic methods on types, no calls to generic interface methods)

- From: first spec; round 2 §15; round 3 §30 (one compilation strategy in every mode).
- Built: 0.1.0. User generics, monomorphized; spec 006 `where T : I, J` constraints (`CHANGELOG.md` [0.1.0]).
  Partial in 0.3, as the heading says.
- Changes:
  - `0002-round-3-consistency-review.md` item 28: the `print` signature example.
    Why: stderr through `print`'s `to:`.
  - `0006-error-payloads-byn2322-help-verbs.md` names "SPEC §11" for the BYN2322 note; that note is now in §7.9 (see §7).
    Why: section numbers in the revision are those of its time.
  - `0020-versioned-spec-and-audit-fixes.md`: the `(partial in 0.2: …)` heading tag.
    Why: `Compilation.cs` and `BinderExpressions.cs` reject the two forms.

### §12. Comptime (not in 0.3)

- From: first spec; round 2 §4, §10, §19.
- Built: not built. `comptime` is only a token (revision 0020 table). Milestones list comptime beyond constant folding as out of scope for v0.1.
- Changes:
  - `0002-round-3-consistency-review.md` item 17: `bayan expand` deferred, so the text says what it will show.
    Why: no v0.1 step built `expand`.
  - `0019-round-4-batches-1-8-consistency.md` item 16: §12.5 text for the tiers decision on `kit.tls` (batch 7).
    Why: the text still gave the open answer.
  - `0020-versioned-spec-and-audit-fixes.md`: the `(not in 0.2)` heading tag.
    Why: nothing in `src/Bayan.Semantics` implements it.
  - `0024-numeric-conversions-and-dec.md`: §12.4, comptime numeric results equal the compiled program's bit for bit, except under `@fastMath` (§17).
    Why: "deterministic" did not tie comptime numeric evaluation to compiled code.

### §13. Concurrency (not in 0.x)

- From: first spec (async/await, fibers); round 2 §14; round 3 §13.
- Built: not built. 0.x programs are single-threaded. The planned design is `docs/bayan-concurrency.md`.
- Changes:
  - `0019-round-4-batches-1-8-consistency.md` items 3, 4: Appendix A and the design table: `scope`/`spawn` replaces `async`/`await` (user decision 2026-11-04).
    The §13 body was left for a later revision (0023).
    Why: round-4 batches settled it; the spec still said `async`/`await`.
  - `0020-versioned-spec-and-audit-fixes.md`: the `(not in 0.2: …)` tag.
    Why: no `async`/`await` binding exists.
  - `0023-syntax-freeze-provisional-sections.md`: §13.1–13.5 removed; the section is a placeholder.
    Why: the body still specified `async`/`await`, `Io.group` and fibers in the present tense (AUDIT A20).

### §14. Effects and capabilities

- From: first spec; round 2 §10; round 3 §13 (one checked `uses` clause replaces `noalloc`, `nosuspend` and capabilities).
- Built: 0.1.0. `uses` in function types (spec 007) and effects in the self-hosted checker (spec 010), `CHANGELOG.md` [0.1.0]; `docs/STATUS.md` effects rows.
  `provide` is `(partial in 0.3: only `alloc` and `allocator` …)`.
- Changes:
  - `0002-round-3-consistency-review.md` items 5, 17, 21: `main` is exempt from BYN6002; `suspend` has no handler.
    Why: the entry function has no caller to declare effects to.
  - `0019-round-4-batches-1-8-consistency.md`: capabilities text.
    Why: round-4 batches.
  - `0023-syntax-freeze-provisional-sections.md`: `suspend` fiber parking is `not in 0.x`; the effect itself is checked.
    Why: there are no fibers in 0.x.

### §15. Security

- From: first spec; round 2 §2, §7, §13; round 3 §11, §16, §17, O10 (two trust layers).
- Built: 0.1.0. `Untrusted<T>` and `trust` (spec 002), `because` (round 3), `CHANGELOG.md` [0.1.0].
  0.3.0: SipHash-1-3 map hashing and runtime fixes (`CHANGELOG.md` [0.3.0] Security).
  §15.2 secrets are `(not in 0.3)`.
- Changes:
  - `0011-regex-after-v0-1-and-validation-error-instantiations.md`: §15.4, regexes are linear-time and come after v0.1.
    Why: patterns run on untrusted input, and a backtracking engine is a ReDoS risk.
  - `0020-versioned-spec-and-audit-fixes.md`: §15.1, §15.2, §15.4 status tags and fixes.
    Why: no `Secret` in `src/`.
  - `0022-contract-hardening-doc-consistency.md` item 2: §15.5 cites §0 after its "every build mode" sentence.
    Why: one home for the build-mode rule.

### §16. Strings and collections conventions

- From: first spec; round 2 §11, §12; round 3 §12, §15, §26, §27, deliverable 4.
- Built: 0.1.0. Map API (spec 002), string views, `StrBuf`, `FormatSpec`, `Utf8.decode` (round 3), `CHANGELOG.md` [0.1.0].
  §16.1 events and the lambda-taking members are `(not in 0.3: …)`.
- Changes:
  - `0002-round-3-consistency-review.md` items 4, 28: `prepare`'s `timeout` is a named optional; `print`'s `to:`.
    Why: every shape follows the particle rule.
  - `0003-strings-and-formatting.md` §3–§6: the "Text" chapter, §16.4: string model, API, culture and formatting.
    Why: the string API and culture rules were scattered or missing.
  - `0004-conflicts-after-0002-0003.md` item 2: `-ed` names a copy or a view; a plain verb acts on `ref this`.
    Why: an immutable `string` has `trimmed()` with no `trim`.
  - `0011-regex-after-v0-1-and-validation-error-instantiations.md`: §16.4 `matches(re)` and `replaced(re, by:)` move after v0.1.
    Why: no `Regex` type and no step to build one (Q326).
  - `0013-hashmap-symbols-shipped-subset.md`: the "Maps:" bullet names the key types.
    Why: no text said which types a `Map` key may have.
  - `0015-float-parse-and-unicode-lowercase.md`: §16.4 names the float `tryParse`; `lowercased()`/`uppercased()` are Unicode.
    Why: the v0.1 scope line shipped case mapping ASCII-only.
  - `0018-strbuf-finish-loan.md`: the `buf.finish()` example is a loan on the buffer.
    Why: the spec follows the implementation.
  - `0019-round-4-batches-1-8-consistency.md`: §16.1.
    Why: round-4 batches.
  - `0020-versioned-spec-and-audit-fixes.md`: §16.1 and §16.4 status tags and fixes.
    Why: no `Event<T>` in `src/`.
  - `0021-agreement-word-classes-doer-nouns.md` Part 1: §16.4 `formatInto` parameter `out` renamed `buffer`.
    Why: `out` is a keyword.

### §17. Numerics

- From: first spec; round 2 §3 (overflow traps in every build mode).
- Built: source not recorded.
  No status tag.
- Changes:
  - `0024-numeric-conversions-and-dec.md`: `dec` overflow traps; `@fastMath` is ignored at comptime; derived equality on floats uses `totalOrder` while floats are not `Map` keys (§3.5).
    Why: §17 mentioned float hashing (ruled out by revision 0013) and left `@fastMath` at comptime unspecified.

### §18. FFI (not in 0.3)

- From: first spec; round 3 §2, §5, §6, §27; Q120 (postfix pointers, decided 2026-10-24).
- Built: not built. The `(not in 0.3)` heading tag was added on 2026-11-14 (commit `263a17ae`); no revision records it.
- Changes:
  - `0001-round-3-pointers-line-freeze.md`: pointers are postfix `T*`; prefix `*T` is input form BYN1066.
    Why: §18 and the Sūq drafts spelled pointers two ways (Q120).
  - `0002-round-3-consistency-review.md` item 20: pointers only inside `extern` (BYN1067).
    Why: a pointer outside `extern` would let unchecked memory into safe code.
  - `0019-round-4-batches-1-8-consistency.md`: extern pointers: also a private `T*` field of a `struct unique` with `dispose(move this)`.
    Why: round-4 batches.

### §19. Packages, editions and builds

- From: first spec; round 2 §10, §18; round 3 §8, §12, §13, §28, O15.
- Built: 0.1.0. `package.byn` reader, `bayan new`/`init`, project builds (M9), `out/` and `dist/` (M10), `CHANGELOG.md` [0.1.0].
  `bayan format` and the style knobs, build mode `small` and the 2026-11-04 knob set are `(partial in 0.3: …)`.
- Changes:
  - `0002-round-3-consistency-review.md` item 26: `adjectives` in `grammar`.
    Why: the review.
  - `0014-test-tooling.md`: §19.2 manifest example and the `Tests` fields.
    Why: coverage and mutation gates need manifest fields.
  - `0019-round-4-batches-1-8-consistency.md`: packages, attributes.
    Why: round-4 batches.
  - `0020-versioned-spec-and-audit-fixes.md` items 3, 5: §19.2 uses the 2026-11-04 style standard; `adjectives` restored.
    Why: §19.2 still showed the knobs from before the style decision (`docs/bayan-style-proposal.md`).
  - `0021-agreement-word-classes-doer-nouns.md` Part 3: `Grammar` gains `adjectives` and `collectives`; BYN5014 names three classes.
    Why: `adjectives` was missing from §19.2 (AUDIT A30).
  - `0022-contract-hardening-doc-consistency.md` item 4: §19.4, adding or narrowing an `expects` or `requires` on a released public API is breaking.
    Why: changing a released contract had no compatibility rule.

### §20. Testing

- From: first spec; round 2 §16; round 3 §6, §14.
- Built: 0.1.0. `bayan test` with child processes (M7); spec 013 mutation and coverage, partial (`CHANGELOG.md` [0.1.0]).
  `fuzz` and `model test` declarations, `@pairwise`, `@nightly` and other items are `(not in 0.3: …)`.
- Changes:
  - `0014-test-tooling.md`: coverage of error paths, mutation operators and report, `@unobservable`.
    Why: §20 promised both in two bullets; spec 013 builds them.
  - `0022-contract-hardening-doc-consistency.md` item 7: the mutation example takes particles, `from i32 lo, through i32 hi`.
    Why: match `x.clamped(from: lo, through: hi)` in §16.2.

### §21. Diagnostics and tooling

- From: first spec; round 2 §15, §18; round 3 §20, §30.
- Built: 0.1.0. `bayan explain`, `--diagnostics json` and exit codes, `bayan doctor`, `bayan format` (M12, round 3), `CHANGELOG.md` [0.1.0].
  0.3.0: lint BYN5103 (`CHANGELOG.md` [0.3.0]).
  `bayan expand` and the lockfile are `(not in 0.3)`.
- Changes:
  - `0001-round-3-pointers-line-freeze.md`: the spec, grammar and style change only by numbered revision.
    Why: they had no change process once round 3 landed.
  - `0002-round-3-consistency-review.md` item 17: `bayan expand` deferred past v0.1.
    Why: no v0.1 step built it.
  - `0003-strings-and-formatting.md` §6: compact format specs are input forms (BYN1068, §21.5).
    Why: `{n:hex}` still types through and is stored as named arguments.
  - `0009-bayan-format-in-v0-1.md`: §21.2, `bayan format` is in v0.1; one CLI table; `--check` output and exit; `bayan fmt` hint.
    Why: §21.2 said "not in v0.1" while step 5.2 had built it, and the table was split in two.
  - `0016-addendum-a1-midflight.md`: round-4 codes reserved as comments: BYN1070, BYN1071, BYN2825, BYN7013; titles read "Bayān".
    Why: only changes with no effect on behavior or emitted output may land during 010–013.
  - `0017-addendum-a2-diagnostic-codes.md`: the code scheme (thousands digit is the area); one `// Reserved: round 4` block.
    Why: renumbering during 010 would collide with the golden harness and parity tasks; it happens once in round 4.
  - `0019-round-4-batches-1-8-consistency.md`: the CLI table.
    Why: round-4 batches.
  - `0020-versioned-spec-and-audit-fixes.md`: §21.3 and §21.4 (lockfile tag).
    Why: no lockfile is written.
  - `0022-contract-hardening-doc-consistency.md` item 2: §21.3 cites §0.
    Why: one home for the build-mode rule.

### §22. Prose translation

- From: first spec.
- Built: not built. No `bayan-prose` or `--from-prose` in `src/` or `selfhost/` (searched 2026-11-15). The section has no status tag.
- Changes: no revision names §22.

### §23. Scripting

- From: first spec.
- Built: 0.1.0 for scripts and script reuse (`CHANGELOG.md` [0.1.0], M9 and M11). Interpreter tiering: source not recorded.
  No status tag.
- Changes: no revision names §23.

### §24. Compilation pipeline

- From: first spec; round 3 §30 (performance contract).
- Built: 0.1.0. Lowering, C backend and runtime through `zig cc` (M4, `CHANGELOG.md` [0.1.0]).
  0.2.0: the self-hosted emitter and driver, byte-identical C (`CHANGELOG.md` [0.2.0]).
  0.3.0: the released `bayan` is the self-hosted compiler (`CHANGELOG.md` [0.3.0]).
  DIR, the interpreter, TinyCC, LLVM and WASM: source not recorded; WASM is "v0.3" in `CHANGELOG.md` [0.2.0] Known limits.
- Changes:
  - `0001-round-3-pointers-line-freeze.md`: the emitter writes `#line` before each statement's C.
    Why: native debuggers stepped through generated C, not Bayan source.
  - `0019-round-4-batches-1-8-consistency.md`: the toolchain diagram.
    Why: round-4 batches.
  - `0020-versioned-spec-and-audit-fixes.md`: §24 audit fixes.
    Why: the snapshot audit.

### §25. C# compatibility

- From: first spec; round 2 §1, §8, §11, §13, §15; round 3 §3, §5, §6, §10, §20, §24, §26, §28, O5.
- What it says: zero-allocation C# code compiles as Bayan, with naming warnings where casing differs; a table maps each C# form to its Bayan form.
- Built: input forms with fix-its, 0.1.0 (round 3, `CHANGELOG.md` [0.1.0]). The full rule: source not recorded.
  No status tag.
- Changes:
  - `0024-numeric-conversions-and-dec.md`: the `m` / `d` suffix row notes `dec(0.1)` is BYN2206 (fix-it `0.1dec`) and runtime `f64` converts via `dec.fromF64(x, digits: n)`.
    Why: record how C# `(decimal)x` maps to Bayan `dec`.

## Not built

Rejected or deferred, with the reason the source gives.
The full lists are `docs/bayan-not-planned.md` and Appendices A and B of the spec.

### Rejected

| item | reason | source |
|---|---|---|
| Garbage collector, `Gc<T>` | No GC tier; interop is C only | Appendix A; `0019-round-4-batches-1-8-consistency.md` |
| Inheritance, `class`, `object`, `dynamic` | Structs, interfaces and comptime replace them | Appendix A; `docs/bayan-not-planned.md` |
| `async` / `await`, `Io.group()` | Replaced by `scope` / `spawn` (user, 2026-11-04) | `0019-round-4-batches-1-8-consistency.md` item 3 |
| `provide timeout: d { … }` | Replaced by `scope(timeout:)`; two spellings for one deadline | `docs/bayan-not-planned.md` |
| `ensures` | Postconditions are `@cases` tests, `property` tests and laws | Appendix A; `0022-contract-hardening-doc-consistency.md` item 3 |
| Casts `(T)x` | One spelling per construct; `T(x)` reads as a call; `(T)x` is an input form (BYN1057) | `docs/bayan-not-planned.md` |
| Exceptions | Errors are values in the signature: `fails`, `Result`, panics | `docs/bayan-not-planned.md` |
| Runtime reflection | Needs runtime metadata, which breaks AOT | `docs/bayan-not-planned.md` |
| `!` shorthand for `fails` in source | Editor input form only | Appendix A |
| Symbols for effects; `noalloc`, `nosuspend` | Effects are the closed `uses` list | Appendix A |
| `?` suffix on boolean members | `?` means only `T?`, `?.`, `??`, ternary | Appendix A |
| Angle-bracket units (`5<s>`) | Units use suffixes and `type distinct` | Appendix A |
| Language-level JSON | A standard-library feature (`import std.json`, 0.3.0) | Appendix A |
| Derived `withF(v)` | One copy-with-changes form, `x with { f: v }` | Appendix A |
| `@` as lambda shorthand; `mut` | Keep `it`; keep `ref this`; source not recorded | `docs/bayan-design-round-3.md` (Rejected) |
| `T.Validated` / `validated(T)` | Too much ceremony; `Order.shipped order` replaces it | `docs/bayan-design-round-3.md` (Rejected) |
| `on` prefix (`onChange`, `Panic.onPanic`) | A member is named with a verb or a noun | `docs/bayan-design-round-3.md` (Rejected, §12) |
| Instance `toX` and `asX` members | Source not recorded | `docs/bayan-design-round-3.md` (Rejected) |
| `otherwise` / `elif`, `under`, `never` as negation, `return … from f` | Keyword rename; paraphrase of `provide`; `never` is the bottom type; cuts across `fail` and `catch` | `docs/bayan-design-round-4-draft.md` §9 |
| Macros, resumable effects, types-as-values comptime | Dialects, stack switching, slow compiles | `docs/bayan-design-round-4-draft.md` §9 |
| `HashMap<K, V>` | Not added by spec 008; BYN2830 | `0013-hashmap-symbols-shipped-subset.md` |
| Backtracking regex engine | ReDoS risk on untrusted input; the engine must be linear-time | `0011-regex-after-v0-1-and-validation-error-instantiations.md` (Q326) |
| Test builds at `-O0` | The gate failed: 1,416 s against 1,334 s, 200 failures against 20 | `docs/plans/2026-11-13-010-test-builds-at-o0.md` |

### Deferred

| item | state | source |
|---|---|---|
| Comptime (§12) | `(not in 0.3)`; waits for evidence | §12; `docs/bayan-not-planned.md` |
| `scope` / `spawn` (§13) | Design only, `docs/bayan-concurrency.md` | §13 |
| FFI (§18) | `(not in 0.3)` | §18 |
| Regex, `std.regex` | After v0.1 | `0011-regex-after-v0-1-and-validation-error-instantiations.md` |
| `Set<T>` | Out of v0.1; `Map<T, bool>` instead | Q378, `docs/decisions/2026-11-14-004-answered-questions.md` |
| `const` arrays of `Symbol` | Not in spec 008 (BYN2229) | Q379, `docs/decisions/2026-11-14-004-answered-questions.md` |
| `i64.max` / `i64.min` | None in v0.1; write the literal | Q25, `docs/decisions/2026-11-14-004-answered-questions.md` |
| `(T)-x` as a cast | Parses as subtraction; write `(T)(-x)` | Q24, `docs/decisions/2026-11-14-004-answered-questions.md` |
| Subjectless `switch`, `final` states, `dbg(x)`, the closure escape rule | Wait for round 4 | `0016-addendum-a1-midflight.md` ("Not mid-flight") |
| Diagnostic renumbering | Once, in round 4; old codes alias for one edition | `0017-addendum-a2-diagnostic-codes.md` |
| `bayan verify`, JS backend, SIMD, hot reload, tail calls | No design yet | Appendix B; `docs/bayan-not-planned.md` |

A new revision adds its row here in the same commit.
