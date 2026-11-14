# Bayān: not planned

What Bayān will not do, or not soon. State of `dev` at 04366a4f, 2026-11-14. Every row names its source. The plan for what does come is `docs/bayan-roadmap.md`. Settled decisions are not re-proposed (`docs/bayan-spec.md`, Appendix A).

## Rejected

Decided against.

| Item | Decision | Why | Source |
|---|---|---|---|
| Garbage collector, `Gc<T>`, `.gc` capability | There is no GC tier | Shared heap objects come from library types; interop is C only, so there is no GC edge to serve | `docs/bayan-spec.md` Appendix A; `docs/revisions/0019-round-4-batches-1-8-consistency.md` items 1, 2, 21, 23; `docs/bayan-design-round-4-draft.md` §8 |
| Inheritance, `class`, `object`, `dynamic` | Not in the language | Replaced by structs, interfaces and comptime | `docs/bayan-spec.md` Appendix A and the C# comparison table ("Classes, inheritance, …"); `docs/bayan-design-round-4-draft.md` §8 |
| `async` / `await`, `Io.group()` | Replaced by `scope` / `spawn` (user, 2026-11-04) | One spelling for concurrency; structured cancellation | `docs/revisions/0019-round-4-batches-1-8-consistency.md` item 3; `docs/misc/2026-11-04-design-inputs-review.md` (D-A); `docs/bayan-concurrency.md` |
| `provide timeout: d { … }` | Replaced by `scope(timeout:)` and `until:` (user, 2026-11-04) | Two spellings for one deadline; clashes with BYN6007 | `docs/misc/2026-11-04-design-inputs-review.md` (D-B); `docs/bayan-concurrency.md` |
| Casts `(T)x` | Not a form of the language; `T(x)` is the conversion and `(T)x` is accepted only as an input form with a fix-it (BYN1057) | One spelling per construct; a conversion reads as a call | `docs/bayan-spec.md` lines 852, 865, 2530 |
| Integer casts and integer-to-enum casts | Closed: data enters through `T.tryParse` | Unknown input must fail | `docs/bayan-spec.md` lines 431, 456 |
| Exceptions | Failure is `fails`, `Result` and panics | Errors are values in the signature | `docs/bayan-spec.md` line 12 and the comparison table ("Exceptions"); `docs/bayan-design-round-4-draft.md` §9 |
| Runtime reflection | Compile-time reflection only | Reflection that needs runtime metadata breaks AOT | `docs/bayan-design-round-4-draft.md` §9 and the comptime note; `docs/design/lessons-from-other-languages.md` (X05) |
| `ensures` postconditions | Not adopted; unreserved by revision 0019 | A `requires` on the return type, `@cases` tests, `property` tests and laws cover it; it would trap on hot paths | `docs/bayan-spec.md` Appendix A; `docs/revisions/0019-round-4-batches-1-8-consistency.md` item 19; `docs/revisions/0022-contract-hardening-doc-consistency.md` item 13 |
| `!` shorthand for `fails` in source | Editor input form only | One spelling per construct | `docs/bayan-spec.md` Appendix A |
| Symbols for effects; `noalloc`, `nosuspend` | Gone | Effects are the closed `uses` list | `docs/bayan-spec.md` Appendix A |
| Ruby-style `?` suffix on boolean members | `?` means only `T?`, `?.`, `??` and the ternary | One meaning for `?` | `docs/bayan-spec.md` Appendix A |
| Angle-bracket unit syntax (`5<s>`) | Units use suffixes and `type distinct` | Settled | `docs/bayan-spec.md` Appendix A |
| Language-level JSON | JSON is a standard-library feature | Settled | `docs/bayan-spec.md` Appendix A; `import std.json` in `CHANGELOG.md` `[0.3.0]` |
| Derived `withF(v)` | One copy-with-changes form: `x with { f: v }` | One spelling per construct | `docs/bayan-spec.md` Appendix A |
| `otherwise` / `elif` | Not adopted | Renames the keyword; the subjectless `switch` fixes the shape | `docs/bayan-design-round-4-draft.md` §9 |
| `under` (one-statement `provide`) | Not adopted | Paraphrase of `provide` | `docs/bayan-design-round-4-draft.md` §9 |
| `never` as negation | Not adopted | `never` is the bottom type | `docs/bayan-design-round-4-draft.md` §9 |
| `return … from f` | Not adopted | Cuts across `fail` and `catch` | `docs/bayan-design-round-4-draft.md` §9 |
| Closure-based row API (`rows.each { }`) | Not adopted | Synonym of `for try`; loses `break`, `continue` and outer `return` | `docs/bayan-design-round-4-draft.md` §9 |
| Heap-less model from Goose | Not adopted | Conflicts with `alloc`, arenas and collections | `docs/bayan-design-round-4-draft.md` §9 |
| Macros, resumable effects, types-as-values comptime | Not adopted | Dialects, stack switching, slow compiles | `docs/bayan-design-round-4-draft.md` §9 |
| Implicit conversions, explicit lifetimes, dependent types | Not adopted | Each contradicts a recorded decision | `docs/bayan-design-round-4-draft.md` §9 |
| `@` as lambda shorthand | Keep `it` | The source gives no reason | `docs/bayan-design-round-3.md` ("Rejected", line 1020); `docs/bayan-spec.md` Appendix A |
| `mut` | Keep `ref this` | The source gives no reason | same |
| Automatic `T.Count` / `T.Index`; `Count of T`; `per` for units | Rejected | The source gives no reason | same |
| Bare `0` for unit types | Rejected, with a fix-it to `0g` | Units must be written | `docs/bayan-design-round-3.md` ("Rejected" and the unit rules) |
| `T.Validated` / `validated(T)`; value-dependent return types; parenthesized refinement types | Rejected | Too much ceremony; `Order.shipped order` replaces them | `docs/bayan-design-round-3.md` ("Rejected") |
| `stmt unless not cond` | Rejected, with a fix-it to `if` | One spelling | `docs/bayan-design-round-3.md` ("Rejected") |
| `with` as the handler keyword; `panic` as an effect; file-level or struct-level `uses` | Rejected | `with` is struct update | `docs/bayan-design-round-3.md` ("Rejected") |
| Bare string as a purpose clause | Keep `because` | The source gives no reason | `docs/bayan-design-round-3.md` ("Rejected") |
| Identifiers that start with a digit | Rejected | The source gives no reason | `docs/bayan-design-round-3.md` ("Rejected") |
| `on` prefix for events and handlers (`onChange`, `Panic.onPanic`) | Rejected | A member is named with a verb or a noun | `docs/bayan-design-round-3.md` ("Rejected", §12) |
| Bracket calls (`xs.removeRange[2..5]`) | Rejected | The source gives no reason | `docs/bayan-design-round-3.md` ("Rejected") |
| `=to` / `to` for range ends | Use `through` / `until` | The source gives no reason | `docs/bayan-design-round-3.md` ("Rejected") |
| `:n` SQL placeholders | `$n` | Postgres's native form; `:` clashes with `::` casts | `docs/bayan-design-round-3.md` ("Rejected") |
| A method named after a particle (`at(k)`) | Rejected | The source gives no reason | `docs/bayan-design-round-3.md` ("Rejected") |
| Instance `toX` and `asX` members | Rejected | The source gives no reason | `docs/bayan-design-round-3.md` ("Rejected") |
| Test builds at `-O0` | Closed; `bayan test` stays at `-O2` | The gate failed: 1,416 s against 1,334 s, and 200 failures against 20, mostly out of memory | `docs/plans/2026-11-13-010-test-builds-at-o0.md` (Result) |

## Not soon

Deferred with no slot. Each waits for evidence or a user decision.

| Item | Decision | Why | Source |
|---|---|---|---|
| Isnād registry design, Arabic prose templates | Deferred | No design exists | `docs/bayan-spec.md` Appendix B |
| SIMD types, inline assembly, variadic generics | Deferred | No design exists; SIMD waits on tiers Q12 | `docs/bayan-spec.md` Appendix B; `docs/bayan-design-round-4-inventory.md` (Tiers Q12) |
| `bayan verify` (contract proofs, Z3) | Deferred to v1.x | Needs `law` syntax first | `docs/bayan-spec.md` Appendix B; `docs/bayan-design-round-4-inventory.md` (A002 §3 verify) |
| JS backend, `bayan gen ts` | Deferred | No design exists | `docs/bayan-spec.md` Appendix B |
| Guaranteed tail calls | Deferred | `become` now means typestate; the spelling is open | `docs/bayan-spec.md` Appendix B |
| Interpolating prefixed literals (`sql"…{x}…"`, `html"…"`) | Deferred | No design exists | `docs/bayan-spec.md` Appendix B |
| Fiber isolation on panic, `if let`, string `+`, fluent asserts | Deferred | No design exists | `docs/bayan-spec.md` Appendix B |
| Effect variables in function types and interfaces | Deferred | No design exists | `docs/bayan-spec.md` Appendix B |
| Growing the particle set (`until`, `between`, `per`, `within`) | Only by revision when Sūq shows a need | Evidence first | `docs/bayan-spec.md` Appendix B |
| Compile-time evaluation (section 12) | Not in 0.2; waits for evidence | Provisional text | `docs/bayan-spec.md` §12; `docs/bayan-design-round-4-inventory.md` (R4D §7 v0.3 comptime) |
| `unit` declarations and unit suffixes | Not in 0.2 | Only `type distinct` is built | `docs/bayan-spec.md` §3.4 |
| `extension` declarations, `derivation` mechanism, `Event<T>` | Not in 0.2 | Spec-only | `docs/bayan-spec.md` §4.3, §5.3; `docs/STATUS.md` |
| `.par()` parallel iterators | Proposed, not in the spec | Needs the closure rule and a renumbered code | `docs/STATUS.md`; `docs/bayan-design-round-4-inventory.md` (A002 §4) |
| `@soa` layout | Wait | Needs a hand-made prototype with a measurable gain | `docs/plans/2026-11-05-005-parking-lot.md` (P06) |
| Content-addressed definitions beyond the build cache | Wait | Needs measured misses from renames | `docs/plans/2026-11-05-005-parking-lot.md` (B06) |
| Hot reload | Wait | Needs `kit.ui` with a real app | `docs/plans/2026-11-05-005-parking-lot.md` (B08) |
| REPL | Wait | Needs instant builds (TinyCC `bayan run` or the debug backend) | `docs/plans/2026-11-05-005-parking-lot.md` (B09) |
| Scripted builds (`build.byn`) | `package.byn` stays data | Needs three projects that cannot express their build | `docs/plans/2026-11-05-005-parking-lot.md` (X04) |
| Compile-time reflection syntax | Wait | Needs a derivation that comptime cannot express | `docs/plans/2026-11-05-005-parking-lot.md` (X05) |
| Channels, actors, supervisor pattern | Wait | Need fibers and `scope` in use, then a design that passes "no lock across a suspend point" | `docs/plans/2026-11-05-005-parking-lot.md` (C05, E05) |
| Generated documentation site | Wait | Waits for public release planning | `docs/plans/2026-11-05-005-parking-lot.md` (D06) |
| libFuzzer engine for `bayan test --fuzz` | Wait | Only if the built-in fuzzer misses a bug class | `docs/plans/2026-11-05-005-parking-lot.md` (M08) |
| Native port of JauntyQ's SQL model | Wait | Needs `sql"…"` and the v0.4 pilot | `docs/plans/2026-11-05-005-parking-lot.md` (I02) |
| `t6EmitFunction` in an arena (plan 015 phase C) | Deferred by the user 2026-11-14 | Needs a caller-owned `keep` arena; 16 string writes and three interners write into `Ctx` | `docs/plans/2026-11-14-015-q31-followups.md` (Phase C); `work/todo.md` line 773 |
| `(T)-x` as a cast | Open; parses as subtraction | Needs a language decision | `work/todo.md` (Later, Q24) |
| `i64.max` and `i64.min` limits | Open | Needs a spec decision on syntax | `work/todo.md` (Later, Q25) |
