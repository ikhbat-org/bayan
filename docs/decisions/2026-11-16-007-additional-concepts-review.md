# 007 — Review of the additional concepts draft

Status: decided (all answers recorded below; Q4 confirmed 2026-11-16)
Date: 2026-11-16
Sources: `docs/bayan-additional-concepts.md`; `docs/bayan-spec.md` (§0, §19, Appendix A, Appendix B); `docs/bayan-grammar.md` §4, §12, §13; `docs/STATUS.md`; `docs/bayan-not-planned.md`; `docs/bayan-nice-to-have.md`; `docs/revisions/0019`, `0022`, `0023`; drafts `specs/023-spec-catch-up/023-spec.md` and `decisions/2026-11-16-006-after-022-roadmap-decisions.md` (not on `dev`).

**Overall judgement.** Of the draft's four top picks, two are already in the spec (1, 2), one is settled as rejected (6), and one needs no new syntax (5). Nothing in section A justifies a syntax revision. The part worth keeping is two library or lint items (4, 7), three source rows for the grammar guide, and the priority order in C.

The brief names `docs/GRAMMAR.md` and `docs/STYLE.md`; the files are `docs/bayan-grammar.md` and `docs/bayan-style.md`.

## Summary

| Item | Exists? | Verdict | Slot | Syntax? |
|---|---|---|---|---|
| A1 Isnād provenance | Partly (SPEC §19.3) | Adopt later; grades in English | Plan v0.3 packages; 023 item 22 (after the 0.4 cut) | No (manifest data) |
| A2 Naskh deprecation | Yes, spec-only (`@deprecated`) | No new decision; build the existing design; reject `@abrogated` | Add a row to 023 | No |
| A3 Five severities | Yes (error, warning, suggestion, none) | Reject; write the severity model down in SPEC §21.1 | Doc erratum | No |
| A4 Minimal `unsafe` lint | New | Adopt later, smaller | 023 item 17 (phase 4) | No |
| A5 Narrowed capabilities | Partly (handlers are values; SPEC §23) | Adopt later as library handlers; reject a static form | 023 item 16a (phase 2) | No |
| A6 `guarantees` | Rejected (`ensures`) | Reject | none | Yes |
| A7 `Ratio`, `Money.split` | New | Adopt `split` later; `Ratio` needs a question | Sūq first, then a library tier | No |
| A8 `once` | Yes (`lazy`, spec-only) | Reject; fix the `lazy` gaps | Add a row to 023 | Yes |
| A9 `@stamped` states | New | Reject | none | No (attribute, hidden effect) |
| A10 `only` | New | Reject now; revisit with evidence | After 023 item 5 | Yes |
| B conditionals | Gap is real | Adopt with narrower wording | Doc now | No |
| B tamyīz (units) | New row | Adopt | Doc now | No |
| B `never` | New row | Adopt with a neutral example | Doc now | No |
| B qirāʾāt (style) | New row | Reject | none | No |
| B rasm and ḥarakāt (hints) | New row | Adopt | Doc now | No |
| B capability defaults | Clashes with ḥaṣr in §23 | Reject | none | No |
| B idghām (fusion) | New row plus a new diagnostic | Row later; reject the diagnostic | 023 item 15a | No |
| C priority order | Partly (SPEC §0, principles 9 and 11) | Adopt after testing against past decisions; plain English name | Decision doc now | No |
| C style presets | New | Reject now | After packages exist | No (but breaks "data only") |

## A. Features

### A1. Isnād → package provenance
1. **Partly exists.** `docs/bayan-spec.md:2313`: "Isnād: each version carries a signed provenance chain (author → source commit → reproducible build → registry), graded by strength." Appendix B defers "Isnād registry design". `docs/plans/2026-11-05-003-v0.3-packages.md` item 2 has signed publishes and a transparency log. New here: named grades, `minProvenance`, independent rebuilders.
2. **No conflict.** `docs/decisions/2026-11-14-003-versioned-docs-and-provenance.md` is about document provenance, not packages.
3. **Value:** a minimum grade gives `bayan audit` something to enforce. **Cost:** registry, signing keys, a rebuilder network, lockfile fields; none exists (`docs/STATUS.md:60`, no lockfile is written).
4. **Adopt later.** The model is already promised; only the grade names and the manifest key are new. It belongs with 023 item 22, which the catch-up draft marks "may stay spec-only after 0.4".
5. **Smallest version:** an English enum such as `.unsigned`, `.signed`, `.built`, `.reproduced`, reported by `bayan audit`. `minProvenance` waits for a registry. Not syntax.

Would change my mind: a public registry before 0.4, which pulls this forward.

### A2. Naskh → deprecation naming its replacement
1. **Exists, spec-only.** `docs/bayan-spec.md:1538`: `@deprecated(by:, until:)`, the error keyed to the consumer's edition, "without `by:` the attribute requires `because`". Accepted as R4.3 (`docs/bayan-design-round-4-inventory.md:165`). `bayan migrate` applies it (`docs/bayan-spec.md:2446`; packages plan item 7). It is listed in `docs/bayan-nice-to-have.md`. I found no code for it and no row in the 023 inventory.
2. **`@abrogated` conflicts** with one spelling per construct (SPEC §0.3) and with the draft's own caution about religious terms.
3. **The draft's three differences are worse than the existing design:**
   - A mandatory replacement fails when something is removed with none; the existing "`by:` or `because`" rule covers that.
   - `bayan format` rewriting calls is the wrong tool; `bayan migrate` already owns that job.
   - `because` on every deprecation widens it beyond "bypass of a safety rule" (Appendix A).
4. **No new decision.** Build R4.3 as written.
5. Add `@deprecated` and its two diagnostics to the 023 inventory, size S. Attribute only, not syntax.

### A3. Five rulings → five severities
1. **Exists.** The draft's "only errors and lints" is wrong.
   - Built: `Error`, `Warning`, `Note` (`csharp/Bayan.Syntax/Diagnostics/Diagnostic.cs:6`); 318 error and 14 warning codes in `docs/DIAGNOSTICS.md`.
   - Specified: lint levels `.suggestion` (default), `.warning`, `.none`, set per lint (`docs/bayan-spec.md` §19.2, `docs/bayan-style.md:8`).
   - The "never leave forbidden" rule exists for libraries: "Projects may raise a library's warnings to errors but never lower its errors" (`docs/bayan-spec.md:1538`).
2. No conflict; it duplicates.
3. **No value.** "Required" is the same diagnostic as "forbidden" seen from the other side, and "allowed" is no diagnostic. Five collapse to the three that exist plus `.none`.
4. **Reject.** The real gap is that SPEC §21.1 never states the severity model in one place.
5. One paragraph in §21.1: levels, who may move which, and that compiler errors cannot be lowered. Doc only.

### A4. Ḍarūra → minimal `unsafe`
1. **New.** `unsafe because "…" { … }` is in SPEC §4.4 and §9.7 but not built (`docs/STATUS.md:114`: an `unsafe { … }` block is BYN1002). The draft's "you already require `because`" is true of the spec only.
2. No conflict.
3. **Value:** small audit surface; `bayan audit` already lists every block. **Cost:** low, since the checker must already know which operations need `unsafe`. **Risk:** a per-statement lint splits one logical operation into several blocks, each with its own `because`, which reads worse and repeats reasons.
4. **Adopt later**, with `extern` and `unsafe` (023 item 17).
5. **Smallest version:** a warning on an `unsafe` block that contains no operation needing it. The per-statement form is an idiom lint, `.suggestion` by default. Not syntax.

Would change my mind: Sūq's sodium module or selfhost FFI showing wide blocks in practice; then make the per-statement lint a warning.

### A5. Wakāla → narrowed capabilities
1. **Partly exists.**
   - Handlers are ordinary values: `provide net: FakeNet(label)` (`docs/bayan-spec.md:1123`). A restricted handler is a library type and needs no new form.
   - Scripts already have scoped grants: `#:allow none except net("api.github.com"), read("./dist")` (`docs/bayan-spec.md:2575`).
   - Only `alloc` can be provided today (`docs/STATUS.md:41`, `:82`).
2. **A static form conflicts.** "May use this part of fs" in the type system needs effect parameters; SPEC §14 says an effect bound in a type "is the only form of effect parameter; general effect variables are deferred" (also Appendix B). A runtime-checked handler has no conflict.
3. **Value:** the highest in the draft. Importers and carrier clients get least privilege at the call site. **Cost:**
   - Path containment has to survive symlinks and `..`, and needs a law.
   - Denial needs a defined result (an error case, not a panic).
   - `within` and `only` break the naming rules (not verbs), and `within` is a deferred particle word (Appendix B).
4. **Adopt later as library handlers**, with 023 item 16a (`provide` for `net`, `fs`). Reject finer-grained `uses:` grants in the manifest for now: hosts and paths are runtime values, so the compiler cannot check them, and the manifest key itself is still in conflict (`capabilities:` in SPEC §19.2 against `uses:` in `docs/bayan-library-tiers.md:196`, review row C13).
5. **Smallest version:** two restricted handlers in `std`, for example `fs.restricted(to: path)` and `net.restricted(to: host)`, plus a law "no path outside the root is opened". Not syntax.

Would change my mind: a need to prove confinement at compile time. That becomes an effect-parameter design, not this.

### A6. Ḍamān → postconditions
1. **Rejected.** `guarantees` is `ensures` under another name.
2. **Conflicts with three settled points:**
   - Appendix A (`docs/bayan-spec.md:2647`): "No `ensures` … Re-propose only with a Sūq or selfhost case that none of them can express."
   - Principle 9 (`docs/bayan-spec.md:33`): "checked at return in debug builds" makes a check a build-mode option.
   - `it` already means the lambda parameter and the `requires` subject.
3. The draft's example, `total >= Money.zero`, is a `requires` on the return type, which is the recorded replacement (`docs/bayan-not-planned.md`, `ensures` row).
4. **Reject.** The draft gives no Sūq or selfhost case, which is the stated bar.
5. Not applicable.

Would change my mind: a real case relating the result to the arguments that neither a law nor a property test can state. A7's "parts sum to the total" is not one; a law covers it.

### A7. Farāʾiḍ → exact splitting
1. **New.** `Money` is in SPEC §3.4 (`docs/bayan-spec.md:280`) with `rounded()`, `tryAdd`, `add`; no `split`. No `Ratio` anywhere. `docs/bayan-library-tiers.md` has no `Money` row, so its tier is undecided. The retired contracts design used `splitEvenly` as its example (`docs/design/laws-contracts-and-parallel-iterators.md:130`), so the need was already seen.
2. No conflict.
3. **Value:** real and common in commerce (tax lines, split payments, pro-rated discounts); hand-written versions lose a cent. **Cost:** one function, one law, and a stated tie rule for the remainder. `Ratio` costs more: `std` only grows, so a rational type is permanent, with overflow and normalisation rules.
4. **Adopt `split` later; `Ratio` needs a question.** Integer weights do the whole job, including proportional scaling when shares exceed the whole, so `Ratio` is not required.
5. **Smallest version:** `List<Money> split(by ReadOnlySpan<i64> weights) uses alloc` with largest-remainder allocation and a law "the parts sum to the total". Prove it in Sūq, then promote. Library only.

### A8. Ism al-marra → `once`
1. **Exists, spec-only.** `docs/bayan-spec.md:692`: "Runtime setup uses `static let x = lazy load()` (thread-safe, runs once on first use)"; `:2622` maps C# static constructors to `lazy`.
2. **Conflicts with SPEC §0.3:** `once` would be a synonym of `lazy`.
3. No value beyond what `lazy` gives.
4. **Reject.**
5. Gaps to record instead: `lazy` is missing from the keyword lists in SPEC §2.4, from `docs/STATUS.md`, and from the 023 inventory.

### A9. Mafʿal → timestamped states
1. **New.** State payloads exist (`paid(PaymentId payment)`, SPEC §3.17).
2. **Pulls against principle 1** (no hidden costs): `become` would read the clock without saying so on that line.
3. **The headline claim is false.** Payloads belong to one state: `shipped(PaymentId payment, TrackingId tracking)` restates `payment`, so `paidAt` is gone after `become .shipped` unless carried by hand. Order history does not "come for free". The explicit form is one field and one argument.
4. **Reject.** It also depends on `std.time` and a `clock` handler, neither built.
5. Not applicable.

Would change my mind: a Sūq friction entry showing repeated stamp code, together with a decision that payloads persist across states.

### A10. Ḥaṣr → `only`
1. **New.** Ḥaṣr is already a named source for something else: "Permissions are deny-by-default (ḥaṣr)" (`docs/bayan-spec.md:2580`).
2. **Syntax change** under the freeze (rev 0023), and SPEC §0.3 requires new syntax to have its own job.
3. `only .paid` would narrow the element type, which `where` is not specified to do, so it has a job. But `orders except not .paid` may already say it, and sequence `except` is not built (`docs/STATUS.md:36`, BYN2022).
4. **Reject now.** The draft doubts it too. Revisit after 023 item 5 lands and real code shows `except not .x`.
5. Not applicable.

## B. Sources

Are these documentation only? Five are. Two imply behaviour: idghām asks for a new diagnostic, and the conditionals row invites `if likely` if recorded as a one-to-one mapping.

- **Conditionals.** The gap is real: `docs/bayan-grammar.md:399` says "source: to be confirmed". No behaviour change, since `if unlikely` and `if never` exist (SPEC §7.2). The mapping is not "almost exact":
  - Plain `if` makes no likelihood claim, which is nearer to *in* than to *idhā*.
  - *Idhā* (expected) would be `if likely`, which the language does not have.
  - *Law* is counterfactual, not prohibited.
  - `unless` is unmapped.

  **Adopt with narrower wording:** "Arabic marks the speaker's expectation on the conditional particle itself (idhā, in, law); Bayān puts the likelihood word in the same place, directly after `if`." Do not record a one-to-one table.
- **Tamyīz for unit literals.** Accurate: the noun that specifies what a number counts. Matches Appendix A ("bare literals are rejected"). Unit suffixes are not in 0.3 (SPEC §3.4 heading), so the row describes a spec-only rule. **Adopt.**
- **`never` type.** The grammar fits: the particle denies that any member of a kind exists, and `never` is the empty union. The draft's example is Qurʾān 2:2; use the textbook example *lā rajula fī al-dār* instead. **Adopt.**
- **Qirāʾāt for the two style choices.** **Reject.** Comparing `&&` against `and` to the canonical readings of the Qurʾān reads badly, and the readings are transmitted, not chosen per project. The guide already admits "no Arabic source" for casing (`docs/bayan-grammar.md:395`); do the same here.
- **Rasm and ḥarakāt for inlay hints.** Accurate, and consistent with the brand's use of rasm and iʿjām (`docs/bayan-brand-brief.md` §2). Matches SPEC §21.2: hints are "never a stored form". **Adopt.**
- **Capability defaults.** **Reject.** It is a legal maxim, not grammar; it casts effects as "worship"; and SPEC §23 already attributes deny-by-default to ḥaṣr, so one rule would have two sources.
- **Idghām for fusion.** The term is accurate. The diagnostic is a behaviour change, and it has nothing to report: lazy iterators "are structs with inlined lambdas" (`docs/bayan-spec.md:1715`), so fusion is how they are built, not an optimisation that can stop. Lazy queries are not in 0.3. **Add the row when 023 item 15a lands; reject the diagnostic.**

## C. Process

- **Priority order.** Partly exists: principle 11 puts C# familiarity last, principle 9 puts checks above build-mode speed, and principle 1 names performance first. The draft's example order contradicts the record in one place: `ensures` was rejected partly because it "would trap on hot paths" (`docs/bayan-design-round-4-draft.md:350`). **Adopt** as a short decision doc, but only after checking the order against five or six past decisions (bounds checks in every mode, `ensures`, the two synonym exceptions, traps on overflow, `expects` never reading `Untrusted`). If the order does not predict them, it is the wrong order. Do not name it after maqāṣid al-sharīʿa.
- **Style presets.** **Reject now.** `style: .from("…")` is a call, and `package.byn` is "data only (no calls, no `comptime`)" (`docs/bayan-spec.md:2265`). It would make `bayan format` depend on dependency resolution, and no package system exists. The knob set is closed at seven, so copying a block is cheap. Revisit when a registry exists and two organisations ask.

## Naming

**Current practice.** Keywords and message text are English. Arabic terms appear in three places:
- parenthetically in spec headings (waqf §2.5, kāna / ṣāra §3.17, istithnāʾ §6.8);
- the Sources table (`docs/bayan-grammar.md` §12);
- the "Where this comes from" paragraph of diagnostic pages (for example `docs/diagnostics/BYN5003.md`), which `bayan explain` prints.

So "keep them out of diagnostics" holds for the message line, not for explain text. Arabic library tier names were considered and rejected (`docs/bayan-library-tiers.md:25`). The brand brief forbids religious text as decoration and lists a cultural review of Qurʾānic references as pending (`docs/bayan-brand-brief.md` §4 rule 5, §7).

**The draft changes the kind of source.** Existing sources are linguistic (grammar, script, recitation marks) plus the hudhud; isnād and ḥaṣr are the two exceptions. Section A draws on law and hadith science. That is the owner's call, and it should be made once, not item by item.

| Draft term | Accurate? | Note |
|---|---|---|
| Isnād grades | Stretch | Mutawātir and ṣaḥīḥ are not points on one scale: the first is about the number of chains, the second grades single-chain reports and requires more than a complete chain. A broken chain is one kind of ḍaʿīf. Labelling a package ḍaʿīf will read badly. |
| Naskh | Sensitive | Abrogation is a contested doctrine about scripture. It can occur with no replacement, so it does not support "must name a replacement". `@abrogated` puts the term in source code. |
| Five rulings | List correct, mapping poor | See A3. The draft already flags ḥarām in a CLI. |
| Ḍarūra | Good fit | The maxim is misvocalised: it is *al-ḍarūra tuqaddaru bi-qadarihā*, not "taqaddar". |
| Wakāla | Good fit | Restricted agency is a real category; an agent cannot exceed the principal's own authority. |
| Ḍamān | Stretch | It means liability or suretyship for loss, not a promise about a result. |
| Farāʾiḍ, ʿawl | Accurate | ʿAwl is not accepted by every school, so presenting it as "Islamic inheritance law" simplifies. |
| Ism al-marra | Mild stretch | It says an act happened once, not that something is initialised lazily. |
| Mafʿal | Accurate | Easy to confuse with mafʿūl and mifʿāl, already in the guide. |
| Ḥaṣr | Accurate | Already used for another rule (§23). Classical ḥaṣr is often built with an exception (*mā … illā*), which supports the view that `only` re-spells `except`. |
| Maqāṣid, madhhab | Read badly | They equate design priorities and style presets with the aims and schools of sacred law. |

## What the draft gets wrong about Bayān today

1. Its opening claims not to repeat what Bayān uses; isnād (`docs/bayan-spec.md:2313`) and ḥaṣr (`:2580`) are already used.
2. A2: deprecation with `by:`, `until:` and a required reason already exists (`:1538`).
3. A3: three severities are built and three lint levels are specified.
4. A6: "if the spec doesn't have them yet" is wrong; the spec rejects them by name.
5. A8: `lazy` already does this (`:692`).
6. A9: state payloads do not persist across `become`.
7. A4, A5: `unsafe` blocks and every `provide` handler except `alloc` are not built.
8. B: unit suffixes are not in 0.3; iterator fusion is structural.
9. C: the manifest is data only and the style knobs are a closed set.
10. `docs/bayan-reference-app-coverage.md:62` mentions `if likely`, which the spec does not have. One line; not fixed here.

**Freeze.** The spec header (`docs/bayan-spec.md:8`) ends the freeze at the 0.3.0 release. `CHANGELOG.md` has `[0.3.0]` and `[0.3.1]`, and `VERSION` is `0.3.2-dev`, but `docs/bayan-roadmap.md` still shows the tag as pending and nothing records the freeze as lifted. I could not check the tags here. In practice, until spec 019 lands, every syntax change is still built twice, which is the reason rev 0023 gave.

## Open questions for the owner

1. **May Bayān draw on Islamic law and hadith science as named sources, or only on Arabic language and script?** Recommended: language and script only, keeping isnād as the one existing exception. This settles A2's name, A3, the capability-defaults row and both C names at once.
2. **Should provenance grades have English names?** Recommended: yes, a plain four-step enum; mention isnād only in the "Where this comes from" text.
3. **Is a restricted file or network handler allowed to be a runtime check, or must confinement be proven at compile time?** Recommended: runtime check, shipped with the `provide` handlers in the catch-up.
4. **Where does `Money` live: `std`, `kit`, or each application?** Recommended: decide before adding `split`; start `split` in Sūq and promote it with its law.
5. **Do you want a `Ratio` type at all?** Recommended: no, until `split` by integer weights proves insufficient.
6. **Should the conditionals row claim a one-to-one mapping to idhā, in and law?** Recommended: no; record only that the likelihood word sits where Arabic marks expectation. Otherwise the table argues for `if likely`.
7. **Should `@deprecated` and `lazy` get rows in the catch-up inventory?** Recommended: yes, both small; `lazy` also needs an entry in SPEC §2.4.
8. **Will you write the priority order, and test it against past decisions first?** Recommended: yes, as a decision doc with an English title. A possible order to test: safety checks, then visible cost, then clarity, then familiarity.
9. **Is the syntax freeze still in force after 0.3.1?** Recommended: say so in writing, and extend it until spec 019a lands. Nothing in this review needs it lifted.

## Decided by the user, 2026-11-16

- **Q1:** language and script are the default sources; anything drawn from Islamic law or hadith science goes to the owner before it enters a doc.
- **Q2:** yes, English grade names.
- **Q7:** yes, `@deprecated` and `lazy` rows in 023, `lazy` in SPEC §2.4.
- **Q4:** yes, `Money` goes in `std` (owner confirmed 2026-11-16; SPEC §3.4 already defines it).
- **Q3: yes, run-time check** (after examples, 2026-11-16, fourth message). `fs.restricted` ships with the `provide` handlers of 023 item 16a; its law: no path outside the root is opened, including through `..` and symlinks.
- **Q5: yes, no `Ratio` for now.** Weights (`[3, 2, 1]`) cover the cases; add `Ratio` only when a real case needs it.
- **Q6: yes, the sentence, not the table.** The "where this comes from" doc says Arabic marks expectation on the conditional word and Bayān puts its likelihood word straight after `if`; no idhā/in/law mapping table.
- **Q8: yes.** Priority order: safety, then visible cost, then clarity, then familiarity, with the build order sent 2026-11-16. Before it is written as its own decision doc it is tested against about 10 past decisions in `docs/decisions/`, and any it would have decided differently goes to the owner.
- **Q9:** the syntax freeze stays in force until spec 019a lands (owner agreed after the explanation: no new keywords, statement forms or renamed syntax; library, lint, fix and doc changes continue).
