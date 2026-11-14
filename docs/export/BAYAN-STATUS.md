Commit `821afa40`, 2026-11-09.

# Bayān status

One row per feature, keyword, pattern, effect, stdlib member family and diagnostic family, showing what was decided, where it was decided and what the compiler does at this commit.

Status values:
- `built`: parsed and checked, with a golden.
- `partial`: some forms are built and others are not.
- `spec-only`: in SPEC, not in the compiler.
- `deferred`: moved to a later round.
- `rejected`: decided against. Where the word is still lexed, it is kept only as an input form with a teaching error.
- `proposed`: only in a proposal or draft.
- `not found`: no document or code defines it.
- `unverified`: not checked for this export.

"SPEC" is `docs/bayan-spec.md` (exported as `docs/export/BAYAN-SPEC.md`), "GRAMMAR" is `docs/bayan-grammar.md`, "rev NNNN" is `docs/revisions/NNNN-*.md`. Goldens are under `tests/cases/`. Source paths are shortened to file name and line. Per-code detail is in `BAYAN-DIAGNOSTICS.md`; problems are in `BAYAN-AUDIT.md`.

## Required rows

| name | decided in | status | evidence |
|---|---|---|---|
| `then` | round-4 draft `docs/bayan-design-round-4-draft.md:270` | proposed | Not in `Keywords.cs` |
| `ensures` | Not adopted in the round-4 draft (:348); unreserved by rev 0019 (:33) | rejected | Not in `Keywords.cs`; `run/ensures-identifier.byn:1` uses it as a name; see AUDIT A18, A25 |
| `-er` doer pattern | SPEC §5.2 (:760) | spec-only | SPEC §5.2's pattern, with no checker (GRAMMAR:25, "No dedicated code yet"); no code is allocated for it (rev 0020). BYN5101 is `NounOnMutator` (`DiagnosticCodes.cs:350`, `Naming.cs:79`, `diag/noun-on-mutator.diag`); see AUDIT A1 |
| BYN5100 | Only in round-4 draft :269 ("Naming rules BYN5100/5101") | not found | BYN5100 is unallocated (rev 0020): no descriptor; no document states an iḍāfa rule; see AUDIT A1 |
| `Secret<T>` | SPEC §15.2 | unverified | unverified |
| `Untrusted<T>` | SPEC §15.1 | built | `TypeResolver.cs:128`, `Types.cs:341`, `BinderCalls.cs:753`; `diag/run-untrusted.diag`, `diag/expects-reads-untrusted.byn:1` |
| `xOp` | SPEC §5.2 (:746) | spec-only | `Op<T, E>` is defined nowhere; see AUDIT A34 |
| `T.Builder` | SPEC §5.2 (:760) | spec-only | SPEC:788, "derivation mechanism is not in v0.1" |
| `T.Patch` | SPEC §5.2 (:765) | spec-only | SPEC:788 |
| `T.Field` | SPEC §5.2 (:762) | spec-only | SPEC:788 |
| typestate (`becomes`, `become`) | SPEC; codes BYN70xx | built | `run/typestate-order.byn:3`, `diag/become-undeclared.diag`; 14 codes, `DiagnosticCodes.cs:363-379` |
| `except` | SPEC §6.8 | partial | Error-set form built (`TypeResolver.cs:433`, `run/errors-except-narrowing.byn:7`). Sequence form is parsed (`Parser.cs:3375`, `parse/except-expr.byn:1`) but not bound; see AUDIT A15 |
| `because` | SPEC §15 | built | BYN8001 (`BinderCalls.cs:32`, `Parser.cs:676`); `diag/missing-because.diag`, `diag/because-unchecked.diag`, `parse/because.byn:1` |
| particles | GRAMMAR | built | `Lexicon.cs:98`, `Particles.cs:28`, `BinderCalls.cs:425`; `diag/argument-needs-particle.diag` |
| units | SPEC §3.4 | spec-only | `Builtins.cs:187` ("units are spec-only"); a suffix is reported Unsupported at `BinderExpressions.cs:415`; see AUDIT A16 |
| effects (`uses`) | SPEC §14 | built | `EffectAnalysis.cs:18`; `parse/clauses-line-start.byn:5`; 7 codes BYN60xx, `DiagnosticCodes.cs:354-361` |
| `provide` | SPEC §14 | partial | Only `alloc` (and `allocator`) is supported (`Binder.cs:1425-1440`); other handlers are reported Unsupported (:1433); `parse/provide-become.byn:2`; see AUDIT A10, A32 |
| `rest` | SPEC §2.4, §8 | built | `Parser.cs:1436`, `:1471`; `BinderCalls.cs:382`; `RegionAnalysis.cs:159`; `run/rest.byn:3` |
| `expects` | SPEC §2.5 | built | `Parser.cs:250`, `:1211`; `Binder.cs:234` (BYN8006), `:238` (BYN5011); `diag/expects-reads-untrusted.byn:1` |
| subjectless `switch` | round-4 draft :226, :239-244; rev 0016 :78 | deferred | `Parser.cs:2907` requires a subject; BYN1071 reserved (`DiagnosticCodes.cs:388`) |
| `when` guards | SPEC §6.5 | built | `Parser.cs:2955`, `:3601`; `diag/non-exhaustive-union-guard.byn:8`; rev 0016 :78 still says deferred (AUDIT A17) |

## Keywords (`src/Bayan.Syntax/Lexing/Keywords.cs`)

All rows are decided in SPEC §2.4 unless the row says otherwise. `contextual` means `TokenKindFacts.IsContextualKeyword` (`TokenKind.cs:197-201`), so the word is also a valid name.

| name | decided in | status | evidence |
|---|---|---|---|
| `struct` | SPEC §2.4 | built | `Keywords.cs:9`; `lex/comments.byn:6` |
| `unique` | SPEC §2.4 | built | `Keywords.cs:9`; 9 golden files |
| `union` | SPEC §2.4 | built | `Keywords.cs:9`; 162 golden files |
| `enum` | SPEC §2.4 | built | `Keywords.cs:10`; 37 golden files |
| `flags` | SPEC §2.4 (:127 says not a keyword) | unverified | `Keywords.cs:10`; contextual; used as a name in `parse/contextual-keywords.byn`; AUDIT A13 |
| `open` | SPEC §2.4 | unverified | `Keywords.cs:10`; contextual |
| `extensible` | SPEC §2.4 | unverified | `Keywords.cs:11`; contextual; used as a name in `parse/contextual-keywords.byn` |
| `interface` | SPEC §2.4 | built | `Keywords.cs:11`; 97 golden files |
| `delegate` | SPEC §2.4 (:127, not a keyword) | rejected | `Keywords.cs:12`; teaching error at `Parser.cs:554`; `diag/input-delegate-semicolon.byn:3` |
| `extension` | SPEC §2.4 | built | `Keywords.cs:12`; `parse/interfaces.byn:26` |
| `derivation` | SPEC §2.4; SPEC:788 (mechanism not in v0.1) | spec-only | `Keywords.cs:13`; contextual; used only as a name in `parse/contextual-keywords.byn` |
| `attribute` | SPEC §2.4 | unverified | `Keywords.cs:13`; contextual; used as a name in `parse/contextual-keywords.byn` |
| `error` | SPEC §2.4 | built | `Keywords.cs:14`; contextual; 118 golden files |
| `set` | SPEC §2.4 (:131 says it left) | unverified | `Keywords.cs:14`; contextual; used as a name in `parse/contextual-keywords.byn`; AUDIT A13 |
| `unit` | SPEC §3.4 | spec-only | `Keywords.cs:14`; contextual; `Builtins.cs:187` |
| `distinct` | SPEC §2.4 | built | `Keywords.cs:15`; contextual; `diag/distinct-bare-literal.byn:1` |
| `type` | SPEC §2.4 | built | `Keywords.cs:15`; contextual; 42 golden files |
| `import` | SPEC §2.4 | built | `Keywords.cs:15`; 22 golden files |
| `as` | SPEC §2.4 | built | `Keywords.cs:16`; 20 golden files |
| `public` | SPEC §2.4 | built | `Keywords.cs:16`; 71 golden files |
| `private` | SPEC §2.4 | built | `Keywords.cs:16`; `parse/structs.byn:5` |
| `static` | SPEC §2.4 | built | `Keywords.cs:17`; 13 golden files |
| `readonly` | SPEC §2.4 | built | `Keywords.cs:17`; 23 golden files |
| `required` | SPEC §2.4 | built | `Keywords.cs:18`; `diag/required-with-default.byn:2` |
| `const` | SPEC §2.4 | built | `Keywords.cs:18`; 22 golden files |
| `let` | SPEC §2.4 | built | `Keywords.cs:18`; 317 golden files |
| `var` | SPEC §2.4 | built | `Keywords.cs:19`; 328 golden files |
| `embed` | SPEC §2.4 | unverified | `Keywords.cs:19`; contextual; used as a name in `parse/contextual-keywords.byn` |
| `extern` | SPEC §2.4 | spec-only | `Keywords.cs:19`; no golden outside `lex/` |
| `unsafe` | SPEC §2.4 | spec-only | `Keywords.cs:20`; no golden outside `lex/` |
| `if` | SPEC §2.4 | built | `Keywords.cs:20`; 164 golden files |
| `else` | SPEC §2.4 | built | `Keywords.cs:20`; `diag/else-on-new-line.byn:5` |
| `unless` | SPEC §2.4 | built | `Keywords.cs:21`; 16 golden files |
| `switch` | SPEC §2.4 | built | `Keywords.cs:21`; 100 golden files |
| `case` | SPEC §2.4 | built | `Keywords.cs:21`; 38 golden files |
| `default` | SPEC §2.4 | built | `Keywords.cs:22`; 27 golden files |
| `for` | SPEC §2.4 | built | `Keywords.cs:22`; 170 golden files |
| `in` | SPEC §2.4 | built | `Keywords.cs:22`; 176 golden files |
| `while` | SPEC §2.4 | built | `Keywords.cs:23`; 29 golden files |
| `do` | SPEC §2.4 | unverified | `Keywords.cs:23`; `diag/input-parenthesized-condition.byn:13` |
| `break` | SPEC §2.4 | built | `Keywords.cs:23`; 28 golden files |
| `continue` | SPEC §2.4 | built | `Keywords.cs:24`; 15 golden files |
| `return` | SPEC §2.4 | built | `Keywords.cs:24`; 284 golden files |
| `yield` | SPEC §2.4 | spec-only | `Keywords.cs:24`; no golden outside `lex/` |
| `defer` | SPEC §2.4 | built | `Keywords.cs:25`; 30 golden files |
| `errdefer` | SPEC §2.4 (:127, not a keyword) | rejected | `Keywords.cs:25`; teaching error at `Parser.cs:2309`, `:2992`; `diag/input-errdefer.byn:7` |
| `using` | SPEC §2.4 | built | `Keywords.cs:25`; 64 golden files |
| `context` | SPEC §2.4 | unverified | `Keywords.cs:26`; `diag/context-block-input.byn:2` (BYN6006) |
| `fails` | SPEC §2.4 | built | `Keywords.cs:26`; 151 golden files |
| `try` | SPEC §2.4 | built | `Keywords.cs:26`; 82 golden files |
| `catch` | SPEC §2.4 | built | `Keywords.cs:27`; 71 golden files |
| `never` | SPEC §2.4 | built | `Keywords.cs:27`; `diag/never-returns.byn:1` |
| `noalloc` | SPEC §2.4 (:131, left) | rejected | `Keywords.cs:27`; BYN6001 at `Parser.cs:1346-1355`; `diag/noalloc-removed.byn:1` |
| `nosuspend` | SPEC §2.4 (:131, left) | rejected | `Keywords.cs:28`; BYN6001 at `Parser.cs:1346-1355`; `diag/nosuspend-removed.byn` |
| `suspends` | SPEC §2.4 (:131, left) | rejected | `Keywords.cs:28`; BYN6001 at `Parser.cs:1346-1355`; `diag/nosuspend-removed.byn` |
| `async` | SPEC §13; replaced by rev 0019 | rejected | Still lexed at `Keywords.cs:29`; no golden outside `lex/`; AUDIT A12, A20 |
| `await` | SPEC §13; replaced by rev 0019 | rejected | Still lexed at `Keywords.cs:29`; no golden outside `lex/`; AUDIT A12, A20 |
| `is` | SPEC §2.4 | built | `Keywords.cs:29`; 60 golden files |
| `and` | SPEC §2.4 | built | `Keywords.cs:30`; `diag/switch-move-overlap.byn:16` |
| `or` | SPEC §2.4 | built | `Keywords.cs:30`; 23 golden files |
| `not` | SPEC §2.4 | built | `Keywords.cs:30`; 11 golden files |
| `with` | SPEC §2.4 | built | `Keywords.cs:31`; 17 golden files |
| `move` | SPEC §2.4 | built | `Keywords.cs:31`; 73 golden files |
| `ref` | SPEC §2.4 | built | `Keywords.cs:31`; 188 golden files |
| `out` | SPEC §2.4 | built | `Keywords.cs:32`; 18 golden files |
| `this` | SPEC §2.4 | built | `Keywords.cs:32`; 120 golden files |
| `null` | SPEC §2.4 | built | `Keywords.cs:32`; 52 golden files |
| `true` | SPEC §2.4 | built | `Keywords.cs:33`; 77 golden files |
| `false` | SPEC §2.4 | built | `Keywords.cs:33`; 44 golden files |
| `comptime` | SPEC §2.4 | spec-only | `Keywords.cs:33`; no golden outside `lex/` |
| `checked` | SPEC §2.4 | spec-only | `Keywords.cs:34`; no golden outside `lex/` |
| `test` | SPEC §2.4 | built | `Keywords.cs:34`; 17 golden files |
| `assert` | SPEC §2.4 | built | `Keywords.cs:34`; 30 golden files |
| `property` | SPEC §2.4 | spec-only | `Keywords.cs:35`; no golden outside `lex/` |
| `fuzz` | SPEC §2.4 | spec-only | `Keywords.cs:36`; no golden outside `lex/` |
| `model` | SPEC §2.4 | spec-only | `Keywords.cs:36`; no golden outside `lex/` |
| `foreach` | SPEC §21.5 (input form) | rejected | `Keywords.cs:36`; `TokenKind.cs:176-177` ("Accepted for C# compatibility"); `diag/input-for.byn:6` |
| `new` | SPEC §2.4 (accepted, removed by the formatter) | unverified | `Keywords.cs:37`; `TokenKind.cs:176-178`; no golden outside `lex/` |
| `goto` | SPEC §2.4 | rejected | `Keywords.cs:37`; `TokenKind.cs:179`; `diag/goto-case.byn:4` |
| `actor` | SPEC §2.4 | deferred | `Keywords.cs:37`; reserved (`TokenKind.cs:194`); `lex/reserved.byn` |
| `effect` | SPEC §14 (effect aliases) | built | `Keywords.cs:38`; contextual; `EffectAnalysis.cs:207`; `diag/unknown-effect.byn:1` |
| `macro` | SPEC §2.4 | deferred | `Keywords.cs:38`; reserved (`TokenKind.cs:194`); `lex/reserved.byn` |
| `select` | SPEC §2.4 | deferred | `Keywords.cs:38`; reserved (`TokenKind.cs:194`); `lex/reserved.byn` |
| `become` | SPEC (typestate) | built | `Keywords.cs:39`; `diag/become-undeclared.byn:9` |
| `fail` | SPEC §2.4 | built | `Keywords.cs:39`; `parse/catch-block-assign.byn:4` |
| `law` | SPEC §2.4; rev 0013 | partial | `Keywords.cs:39`; contextual; "Declaration-only, no meaning yet" (`TokenKind.cs:172`) |
| `requires` | SPEC §2.4 | built | `Keywords.cs:40`; `parse/requires-rules.byn:1`, `run/requires.byn:2` |
| `because` | SPEC §15 | built | `Keywords.cs:40`; `parse/because.byn:1` |
| `uses` | SPEC §14 | built | `Keywords.cs:40`; `parse/clauses-line-start.byn:5` |
| `except` | SPEC §6.8 | partial | `Keywords.cs:41`; `parse/error-set.byn:3`; see the required row |
| `provide` | SPEC §14 | partial | `Keywords.cs:41`; `parse/provide-become.byn:2`; see the required row |

## Stdlib member families (`src/Bayan.Semantics/Binding/BuiltinMembers.cs`)

The decided-in section was not checked for each family. Goldens were checked only where named.

| name | decided in | status | evidence |
|---|---|---|---|
| String properties (`length`, `bytes`, `isEmpty`, `runeCount`, `isAscii`, `runes`, `utf16`, `lines`) | SPEC §16 | built | `BuiltinMembers.cs:15-22` |
| String methods (`copy`, `startsWith`, `endsWith`, `contains`, `position`, `lastPosition`, `count`, `trimmed`, `equals`, `lowercased`, `uppercased`, `replaced`, `repeated`, `padded`, `parts`) | SPEC §16; rev 0004, rev 0015 | built | `BuiltinMembers.cs:60-82`; `run/string-trimmed.byn` |
| Text views (`Runes` `take`, `skip`, `takeLast`; `Utf16` `copy`) | SPEC §16 | built | `BuiltinMembers.cs:83-86` |
| `joined` | SPEC §16 | built | `BuiltinMembers.cs:87-88` |
| Span | SPEC | built | `BuiltinMembers.cs:23-24`, `:92` |
| List (`length`, `isEmpty`, `span`, `mutableSpan`, `copy`, `append`, `clear`, `removeLast`, `remove`, `replace`, `tryGet`, `sort`, `take`) | SPEC | built | `BuiltinMembers.cs:25-28`, `:89`, `:93-107` |
| Map | SPEC | built | `BuiltinMembers.cs:29`, `:108-114` |
| Array | SPEC | built | `BuiltinMembers.cs:30-31`, `:90` |
| StrBuf (`finish` is a loan) | SPEC | built | `BuiltinMembers.cs:32-33`, `:116-127` |
| Symbol | SPEC | built | `BuiltinMembers.cs:34` |
| ProcessResult | SPEC | built | `BuiltinMembers.cs:35-37` |
| Panic | SPEC | built | `BuiltinMembers.cs:38` |
| Time | SPEC | built | `BuiltinMembers.cs:39` |
| FormatSpec | SPEC §6.6 | built | `BuiltinMembers.cs:41-46` |
| rune `value` | SPEC | built | `BuiltinMembers.cs:47` |
| Result | SPEC | built | `BuiltinMembers.cs:48-50` |
| Owned | SPEC | built | `BuiltinMembers.cs:51` |
| Enum `name`, `ordinal` | SPEC | built | `BuiltinMembers.cs:52-53` |
| Arena `reset` | SPEC §9 | built | `BuiltinMembers.cs:115` |
| Optional `take` | SPEC | built | `BuiltinMembers.cs:128` |
| Io `write` | SPEC | built | `BuiltinMembers.cs:129` |
| Io `readAll`, `readAllBytes` | SPEC | built | `BuiltinMembers.cs:131`, `:135-137`; `IoRun` uses `process` and `alloc` (`EffectAnalysis.cs:264`) |

## Diagnostic families (`src/Bayan.Syntax/Diagnostics/DiagnosticCodes.cs`)

Counts are descriptors in `DiagnosticCodes.cs`. Per-code status (live, plan, reserved, retired) is in `BAYAN-DIAGNOSTICS.md`, which counts 343 codes: 314 live, 10 plan, 9 reserved and 10 retired.

| name | decided in | status | evidence |
|---|---|---|---|
| Lexer BYN0001-0016 | SPEC §2 | built | 16 descriptors, `DiagnosticCodes.cs:22-38` |
| Parser BYN10xx | SPEC §21.5, GRAMMAR §3 | built | 61 descriptors, `:40-105`; retired comments `:57`, `:69`, `:72`; round-4 reservations `:385-391` |
| Semantics BYN20xx | SPEC | built | 32 descriptors, `:108-140`; retired comment `:132` |
| Semantics BYN21xx | SPEC | built | 17 descriptors, `:141-157` |
| Semantics BYN22xx | SPEC | built | 33 descriptors, `:158-190` |
| Semantics BYN23xx | SPEC | built | 12 descriptors, `:191-204`; retired comments `:197`, `:203` |
| Semantics BYN24xx | SPEC | built | 11 descriptors, `:205-215` |
| Semantics BYN26xx | SPEC | built | 15 descriptors, `:216-230` |
| Semantics BYN27xx | SPEC | built | 44 descriptors, `:231-275`; retired comment `:256` |
| Semantics BYN28xx | SPEC | built | 25 descriptors, `:276-300` |
| Borrows BYN30xx | SPEC §8 | built | 6 descriptors, `:301-306` |
| Manifest BYN31xx | SPEC §21 | built | 5 descriptors, `:325-330` |
| BYN32xx | SPEC §10 | partial | 14 descriptors, `:307-323`; reserved descriptors `:314`, `:317`, `:320`; spec-only codes (AUDIT A4) |
| Backend BYN40xx | unverified | built | 2 descriptors, `:332-334` |
| Grammar BYN50xx | GRAMMAR; SPEC §5 | partial | 13 descriptors, `:335-349`; BYN5010 is plan only (AUDIT A5) |
| Lints BYN51xx | GRAMMAR | built | 3 descriptors, `:350-352`; `Naming.cs:79`, `:205` |
| Effects BYN60xx | SPEC §14 | built | 7 descriptors, `:354-361` |
| Typestate BYN70xx | SPEC | built | 14 descriptors, `:363-379` |
| Security BYN80xx | SPEC §15 | partial | 2 descriptors, `:381-383`; BYN8002-8005 spec-only (AUDIT A4) |

## Other features

| name | decided in | status | evidence |
|---|---|---|---|
| Clause order `where` → `expects` → `uses` → `becomes` → `fails` | round-4 draft (feature table); rev 0002 :11 gave another order | built | BYN1065 (`DiagnosticCodes.cs:101`), `Parser.cs:1304-1321`; `diag/clause-order-inserts.byn`; AUDIT A21 |
| `requires` contracts | SPEC | built | `parse/requires-rules.byn:1`, `run/requires-block.byn:1` |
| Error sets | SPEC | built | `parse/error-set.byn:3`, `run/errors-except-narrowing.byn:7` |
| `format()` and `Display.formatInto` | SPEC §6.6 (:916); rev 0003 | built | `BinderExpressions.cs:962`; BYN2031 `ToStringCall` (`DiagnosticCodes.cs:137`); `run/enums.byn:18` |
| Debug format (`as: .debug`) | SPEC §6.6 | built | `BinderExpressions.cs:2049`, `:2133` |
| Text to float `tryParse` | rev 0015 | built | `run/float-try-parse.byn:15`; not yet in SPEC (AUDIT A29) |
| GC tier | SPEC §9.8; rev 0019 | rejected | SPEC:1325-1326; AUDIT A19 |
| `scope` / `spawn` concurrency | rev 0019 | spec-only | Not in `Keywords.cs`; SPEC §13 not rewritten (AUDIT A20) |
| Type overloads | rev 0019 (not in v0.1) | deferred | BYN2006; AUDIT A22 |
| Lockfile `package.lock.byn` | `docs/bayan-handoff-addendum-001.md:94` | unverified | SPEC:2284 still says `bayan.lock` (AUDIT A23) |
| `Event<T>` / `raise` | SPEC (:1793) | spec-only | Not implemented (AUDIT, Dropped N11) |
| `derivation` mechanism | SPEC:788 | deferred | "not in v0.1" |
| `bayan expand` | SPEC (:172, :754) | deferred | SPEC says "once it lands" |
| `.par()` | `docs/bayan-handoff-addendum-002.md:146` | proposed | Not in SPEC (AUDIT A31) |
| `bayan verify` | `docs/bayan-handoff-addendum-002.md:137` | proposed | Not in SPEC (AUDIT A31) |
| Naming checks BYN5001-5003, BYN5102 | GRAMMAR; SPEC §5 | built | `Naming.cs:70`, `:75`, `:99`, `:205`; `diag/try-wrong-return.diag`, `diag/bool-without-prefix.diag`, `diag/participle-changes-this.diag` |
| Proposals in `docs/bayan-shorthands-proposal.md` | that file only | proposed | Items not listed one by one (unverified) |
| Proposals in `docs/bayan-style-proposal.md` | that file only | proposed | Items not listed one by one (unverified) |

## Patterns (SPEC §5.2, :740-765)

| name | decided in | status | evidence |
|---|---|---|---|
| `tryX` from `x() fails` | SPEC §5.2 (:742) | partial | A hand-written `tryX` is checked (BYN5003, `Naming.cs:75`); no derivation (AUDIT A14) |
| `xOp` | SPEC §5.2 (:746) | spec-only | See the required row |
| `T.Builder`, verb + `er` | SPEC §5.2 (:760) | spec-only | See the required rows |
| `T.Field` | SPEC §5.2 (:762) | spec-only | See the required row |
| `T.Patch` | SPEC §5.2 (:765) | spec-only | See the required row |

## Effects (SPEC §14)

All effects are checked in `uses` clauses (`EffectAnalysis.cs:18`). Only `alloc` can be provided (`Binder.cs:1425-1440`).

| name | decided in | status | evidence |
|---|---|---|---|
| `alloc` | SPEC §14 | built | `EffectAnalysis.cs:18`; `diag/dyn-ref-local-argument-modified.byn:2`; handler supported |
| `suspend` | SPEC §14 | partial | `EffectAnalysis.cs:18`; only golden is `diag/unknown-handler.byn:6` (UnknownHandler) |
| `net` | SPEC §14 | partial | `EffectAnalysis.cs:18`; `diag/function-type-placement.byn:10`; handler Unsupported |
| `fs` | SPEC §14 | partial | `EffectAnalysis.cs:18`; `diag/capability-exceeded/main.byn:7`; handler Unsupported |
| `clock` | SPEC §14 | partial | `EffectAnalysis.cs:18`; `diag/time-now-needs-clock.byn:6`; handler Unsupported |
| `random` | SPEC §14 | partial | `EffectAnalysis.cs:18`; no golden with it in a `uses` clause |
| `env` | SPEC §14 | partial | `EffectAnalysis.cs:18`; `diag/env-get-escapes-context.byn:2`; handler Unsupported |
| `process` | SPEC §14 | partial | `EffectAnalysis.cs:18`, `:264`; no golden with it in a `uses` clause |
| `console` | SPEC §14 | partial | `EffectAnalysis.cs:18`; `diag/clause-order-inserts.byn:10`; handler Unsupported |
| `log` (handler) | SPEC §14 (:1653) | spec-only | Not among the effects at `EffectAnalysis.cs:18` |
| Capabilities | SPEC §14 | built | `EffectAnalysis.cs:21`; `diag/capability-exceeded/main.byn:7` |
