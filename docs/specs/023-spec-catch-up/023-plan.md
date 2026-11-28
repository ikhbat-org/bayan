# 023 — Plan

Spec: ./023-spec.md

Status: draft
Release: unscheduled (Phases 1–4 are the catch-up cut; see Needs decision ND1 for its release number)
Sources: `./023-spec.md`; `docs/STATUS.md` (0.4.1); `docs/bayan-roadmap.md` (dev 6fae880df, 2026-11-27); `docs/audits/2026-11-28-decisions-0.4.md`; plans `docs/specs/026-extensible-error-sets/026-plan.md`, `docs/specs/027-concurrency/027-plan.md`, `docs/specs/028-units-duration-uptime/028-plan.md`; `docs/specs/021-std-time/021-spec.md`; `docs/specs/015-tooling/015-tasks.md`; `docs/decisions/2026-11-23-011-csharp-archive.md`

## Approach
Spec 019 is done (removal commit 493d3fd78), so every item is built in the self-hosted compiler only: `src/lexer/`, `src/parser/`, `src/semantics/`, `src/emitter/` (lowering in `src/emitter/*.byn`, C output in `src/emitter/cprint/`), `src/driver/`, the runtime in `runtime/bayan-rt.{h,c}` (copied into `src/driver/runtime.byn`), and std sources in `lib/std/` (bundled through `src/semantics/stdsource.byn`). `src/sabk/` is not touched by any item; a feature Sabk cannot lower is reported by Sabk's existing refusal path.

Each item lands as its own change, in this order inside the item:
1. The revision text, when the item changes `docs/bayan-spec.md` (`docs/revisions/README.md`). Numbers are taken at merge: 0025 is planned by spec 026, the next ones by 027 and 028.
2. Parser, then checker, then emitter and runtime, then std.
3. Goldens under `tests/cases/` (`parse/`, `diag/`, `run/`, `cli/`), the explain page `docs/diagnostics/BYNxxxx.md` for each new code, the STATUS row and the removal of the spec tag, in the same commit (R1, R7).
4. `scripts/selfhost/land.sh` for every change under `src/`, so `bootstrap/` is regenerated and the next commit compiles with the previous one.

Items owned by another spec are not planned again here. They are listed under Ownership, and this plan only tracks them as dependencies and updates the 023 rows when they land.

## Ownership of overlapping items
| 023 item | Owner | What 023 keeps |
|---|---|---|
| #6 `extensible` on error sets | spec 026 (rev 0025, BYN2412, `IoError` extensible) | `enum open`; `extensible` on public `enum` and `union` (non-error) |
| #9 units | spec 028 (all of R1–R17: `unit` declarations, suffixes, BYN3203, BYN3205, core time units, `Duration`, `Millis` → `Milliseconds`) | nothing; 023 waits on 028 T4 for #16b and on 028 T8b for the `Millis` lines in `023-spec.md` |
| #16b `Duration`, `Uptime` | spec 028 (T4, T7) | the calendar part, which is spec 021 Phases 1b–5 (021 says 028 wins on time units) |
| #16b calendar types, zones, format and parse | spec 021 (parked; gates G1, G5) | scheduling only: 021 starts in Phase 3 once 028 meets G1 |
| #16a `Io.Simulated` (scheduler and virtual clock) | spec 027 T10 (minimal `Io.Simulated`, `provide io:`) | the `clock`, `random`, `console`, `log` handlers and `fs.restricted`, which extend 027's `Io.Simulated` |
| #23 `scope`/`spawn`, fibers, cancellation, channels | spec 027 phase 1 (0.5.0) and phase 2 (`ISendable`, `Mutex`, `@threadLocal`) | multi-threaded and per-arena `Symbol.intern` (OQ19); `actor`, `macro`, `select` stay reserved |
| #25 `Io.run` streaming | spec 027 (R11, Decision 3: `Io.start`, `Child`, T11–T13) | 015 T17 tracking; R14's shape is 027's Needs decision 2 and decision 2.2 of `docs/audits/2026-11-28-decisions-0.4.md` |
| #18 `std.regex`, `Base64` | spec 015 T14 and T16, both done (`lib/std/regex/regex.byn`, `lib/std/encoding/base64.byn`) | `s.matches(re)` and `s.replaced(re, by:)` on `string`, `std.text` members, `grouping:` and `case:` specs |
| 015 T15 | spec 015, after spec 026 T10 (`IoError.alreadyExists`) | tracking for acceptance criterion 1 |

Consequence for the phases: #23 and #25 move earlier than the spec's Phase 6 and Phase 1 positions imply, on 027's schedule, and #9 lands with 028. The spec's cut labels for those items are replaced by their owner's release.

## Decisions
- **D1 Verification without the C# compiler (R5).** The C# compiler is not in the tree; it is the tag `csharp-final` (`docs/decisions/2026-11-23-011-csharp-archive.md`). "Frozen C# binary" in the spec's Checked-by column means: outputs recorded once from a `csharp-final` build into `tests/cases/` (as 019a did for the existing goldens), never a CI dependency on .NET. Where a row names it (#2, #5, #8, #13, #16b), the task records those fixtures in its own commit with the command used. Every item also has (b) a property, fuzz or differential test once Phase 2 lands, and (c) reviewed goldens.
- **D2 `small` mode is out of the cut.** `docs/audits/2026-11-28-decisions-0.4.md` §2.7 (owner, done) keeps `--mode small` a usage error in 0.4 (`tests/cases/cli/SelfhostDriverModeTests/ABuildWithModeSmallIsAUsageError`) and revisits it at 0.5. #2 keeps `checked(expr)` and `if unlikely`; `small` keeps its STATUS `partial` tag.
- **D3 #18 regex members.** `Regex.matches(text)` and `Regex.replaced(text, by:)` exist on `Regex`. The spec's `s.matches(re)` and `s.replaced(re, by:)` become `string` members in `src/semantics/builtins.byn` that call into `lib/std/regex/`, available only in a file that imports `std.regex`, the gating 028 uses for `Uptime`.
- **D4 `Io.Simulated` has one implementation.** #16a starts after 027 T10 and adds handlers to 027's `Io.Simulated` in `runtime/bayan-rt.c`. If 027 T10 is not merged when #16a is due, #16a builds only the handler checks and the `clock`, `random`, `console`, `log` providers on top of `provide`, without `Io.Simulated`, and adds `Io.Simulated` once T10 lands.
- **D5 STATUS generation.** R7 asks to regenerate the keyword and stdlib tables, but `scripts/docs/gen-status.sh` reads the frozen `scripts/docs/data/csharp-facts.tsv`. T0 changes it to read `src/lexer/` keyword data and `src/semantics/builtins.byn` before the first item lands, or else every new keyword or member would be hand-edited into a generated table.
- **D6 New handler interface names.** OQ9 says `IClock`, `IRandom` and `ILogSink` are proposals. T1's revision fixes them; this plan uses them only as placeholders.

## Tech / dependencies
- No new tool or library. C11 runtime built by zig or the system C compiler; goldens through the existing runner (`src/driver/golden.byn`); tests through `bayan test` (`src/driver/test.byn`).
- Spec 019: done. The syntax freeze of revision 0023 is over (roadmap, Next releases), so R2 no longer blocks syntax items; each still needs its revision first.
- Spec 026 lands before #6's remaining part (the `extensible` flag and parser path are reused).
- Spec 028 T3–T4 before #16b and before any golden that writes a unit literal; 028 T8b before 023's `Millis` lines change.
- Spec 027 T10 before #16a's `Io.Simulated` (D4); 027 T11–T13 before 015 T17.
- Spec 021 gates G1 (met by 028) and G5 (`lib/std/` tier rows) before #16b's calendar code.
- 0.4.2 (the five open audit HIGHs, roadmap order 0) is not a dependency, but items that touch the same files (`src/semantics/region*.byn`, `ownership.byn`, `effects.byn`) start after it merges.

## Changes by area, by phase

Task rule: a task edits at most the two source files it names. Its goldens, explain pages and STATUS row land in the same commit (R1, R7) and are not counted. "Found first" means the task's first step is a grep for the site, recorded in the commit message. `rt` means `runtime/bayan-rt.{h,c}`, with `src/driver/runtime.byn` regenerated by `scripts/selfhost/gen-driver-files.sh`. Case names are relative to `tests/cases/`.

### T0 Tooling before Phase 1
- T0.1 STATUS generator reads `src/` (D5, R7) — `scripts/docs/gen-status.sh`, `scripts/docs/gen-status.test.sh`.
- T0.2 Ownership notes on rows #6, #9, #16b, #18, #23, #25; R5 per D1; #2 per D2 — `docs/specs/023-spec-catch-up/023-spec.md`.

### Phase 1 (catch-up cut): #1, #2, #3 part 1, #18 rest
- T1.1 `dec` literal suffix — `src/lexer/lexer.byn` — `lex/dec-literal`.
- T1.2 `dec` builtin type — `src/semantics/types.byn`, `src/semantics/typeresolve.byn` — `run/dec-declare`.
- T1.3 `dec` literals and constant folding — `src/semantics/express.byn` (`bindLiteral`), `src/semantics/fold.byn` — `diag/dec-literal-range`.
- T1.4 `dec(0.1)`, `dec(f64)` BYN2206 with fix-its; `dec.fromF64`, `x.truncate<T>()` — `src/semantics/conversions.byn`, `src/semantics/calls2.byn` — `diag/dec-from-float-literal`, `diag/dec-from-f64`, `run/dec-truncate`.
- T1.5 `dec` operators and mixing rules — `src/semantics/express3.byn` — `diag/dec-mixed-f64`.
- T1.6 `dec` arithmetic in the runtime, `BYN_RUNTIME_VERSION` bump — `rt` — `runtime/tests/dec-arith.c` (new).
- T1.7 `dec` C type and operators — `src/emitter/cprint/common.byn`, `src/emitter/cprint/builtin.byn` — `run/dec-arithmetic`, `run/dec-divide-zero` and `run/dec-overflow` (with `.exitcode`).
- T1.8 `dec` formatting — `src/semantics/express4.byn`, `src/emitter/cprint/helpers.byn` — `run/dec-format` (negative zero, scale of a non-terminating quotient).
- T1.9 `checked(expr)` parse — `src/parser/exprs.byn`, `src/parser/nodes.byn` — `parse/checked-expr`.
- T1.10 `checked(expr)` binding, `T?` result, R8 warning — `src/semantics/express3.byn`, `src/semantics/codes.byn` — `diag/checked-no-operator`, `diag/checked-call-only`.
- T1.11 `checked(expr)` lowering — `src/emitter/lowerexpr.byn`, `src/emitter/cprint/builtin.byn` — `run/checked-overflow-null`, `run/checked-dec`, `run/checked-divide-zero-traps`.
- T1.12 `if unlikely` emits `__builtin_expect` — `src/emitter/lowerstmt.byn`, `src/emitter/cprint/func.byn` — `emit-c/if-unlikely`, `run/if-unlikely`.
- T1.13 §7.2 lint on `if unlikely` around an error return — the flow file found first (`src/semantics/flow.byn` expected), `src/semantics/codes.byn` — `diag/unlikely-error-return`.
- T1.14 BYN6008 on `expects` and `requires` — `src/semantics/effects.byn`, `src/semantics/codes.byn` — `diag/expects-not-pure`, `diag/requires-not-pure`.
- T1.15 `requires` on `type` aliases and generic structs — `src/semantics/declare.byn`, `src/semantics/typeresolve.byn` — `run/requires-alias`, `run/requires-generic-struct`, `diag/requires-alias-violated`.
- T1.16 BYN2320 and BYN2321 wording on `expects` — `src/semantics/codes.byn`, `src/driver/diagdocs.byn` — the existing `diag/` goldens of both codes, regenerated and reviewed.
- T1.17 `s.matches(re)`, `s.replaced(re, by:)` behind `import std.regex` (D3) — `src/semantics/builtins.byn`, `src/semantics/calls2.byn` — `run/string-matches-regex`, `diag/string-matches-no-import`.
- T1.18 Unicode 16.0.0 tables for `std.text` — `lib/std/text/tables.byn` (new, generated) and its generator, found first beside the one for `src/lexer/unicode-tables.byn` — `lib/std/text/tables.test.byn`.
- T1.19 `words`, `graphemes` — `lib/std/text/segment.byn` (new), `lib/std/text/segment.test.byn`.
- T1.20 case mapping, folding, `normalized`, `caseFolded` — `lib/std/text/case.byn` (new), `lib/std/text/case.test.byn`.
- T1.21 `camelCased` … `slugged`, `truncated`, `wrapped`, `escaped` — `lib/std/text/transform.byn` (new), `lib/std/text/transform.test.byn`.
- T1.22 `Utf16.decode` — `src/semantics/builtins.byn`, `src/emitter/cprint/builtin.byn` — `run/utf16-decode`.
- T1.23 `grouping:` and `case:` format specs — `src/semantics/express4.byn`, `src/emitter/cprint/helpers.byn` — `run/format-grouping`, `run/format-case`, `diag/format-grouping-on-string`.
- Law candidates: `dec` formatting round-trip (`dec` parsed from `string(x)` equals `x`); `checked` agreement (`checked(a op b)` is `null` exactly when `a op b` traps); `std.text` case folding is idempotent. Seeds: `run/dec-format`, `run/checked-overflow-null`, `lib/std/text/case.test.byn`.
- Done when: every case above passes, std tests pass, and 015 T14 and T16 stay green.

### Phase 2 (catch-up cut): #16a, #19a first, then #4, #5, #6 rest, #7, #8, #10, #11, #12
- T2.1 Revision for OQ9: handler interfaces (D6), `FakeClock`, `fs.restricted` — `docs/revisions/` (new), `docs/bayan-spec.md` §7.7, §14.
- T2.2 `provide` accepts `clock`, `random`, `console`, `log`, `fs.restricted`; user `fs`, `net`, `env`, `process` stay BYN2022 — `src/semantics/effects.byn`, `src/semantics/binder3.byn` — `diag/provide-user-fs-handler`, `diag/provide-clock-wrong-type`, `run/provide-clock-fake`, `run/provide-random-seeded`.
- T2.3 handler slots on 027's `Io` (D4) — `rt` — `run/provide-console-capture`.
- T2.4 `effect name = e1, e2` parse — `src/parser/decls2.byn`, `src/parser/nodes.byn` — `parse/effect-alias`.
- T2.5 `effect` alias binding — `src/semantics/declare.byn`, `src/semantics/effects.byn` — `diag/effect-alias-cycle`, `run/effect-alias`.
- T2.6 ambient `log(msg, as:)` — `src/semantics/builtins.byn`, `src/emitter/cprint/expr.byn` — `run/log-recorder`, `bounds/log-disabled-no-alloc`.
- T2.7 `context.Io` — `src/semantics/binder3.byn` (beside `context.allocator`), `src/semantics/builtins.byn` — `run/context-io`.
- T2.8 `FakeClock` and `Io.Simulated` providers in std — `lib/std/` file found first by 027 T10's layout, with its test — `run/io-simulated-fake-clock`.
- T2.9 `property`, `fuzz`, `bench` declarations parse — `src/parser/decls2.byn`, `src/parser/nodes.byn` — `parse/property-fuzz-bench`.
- T2.10 `@cases(constList)`, `@pairwise`, `@nightly` checks — `src/semantics/declare.byn`, `src/semantics/codes.byn` — `diag/cases-not-const`.
- T2.11 generators from `requires` rules (#3) with shrinking — `src/semantics/generics.byn`, `src/driver/test.byn` — `run/property-requires-shrink` (planted bug, minimal counterexample, fixed seed).
- T2.12 `fuzz` runner: child process, input saved first (R11), minimizer — `src/driver/test.byn`, `src/driver/testreport.byn` — `cli/` case `FuzzTrapReportsInput`.
- T2.13 `bench … { measure … }` — `src/driver/test.byn`, `src/emitter/lowerstmt.byn` — `cli/` case `BenchPrintsMeasure`.
- T2.14 `///` fenced doctests — `src/driver/test.byn`, `src/parser/parser.byn` — `cli/` case `DoctestFailsOnWrongOutput`.
- T2.15 Revision for OQ3/R9 (`Secret<T>`) — `docs/revisions/` (new), `docs/bayan-spec.md` §15.2.
- T2.16 `Secret<T>`, `equalsConstantTime`, `@secret` — `src/semantics/builtins.byn`, `src/semantics/declare.byn` — `run/secret-display-masked`, `diag/secret-unsupported-t`.
- T2.17 BYN8002–BYN8005 — `src/semantics/codes.byn`, `src/semantics/calls.byn` — `diag/secret-json-expose`, `diag/untrusted-sql-sink`.
- T2.18 `Secret<T>` heap copy and wipe on dispose — `rt`, `src/emitter/cprint/own.byn` — `run/secret-dispose`.
- T2.19 `for x in xs except p` binding and narrowing — `src/semantics/express.byn`, `src/semantics/flow.byn` — `run/except-for-narrow`, `run/except-for-taint`, `diag/except-standalone-deferred` (BYN2022, OQ4).
- T2.20 `enum open`, `extensible` on `enum`/`union` parse (026's flag) — `src/parser/decls.byn`, `src/parser/decls2.byn` — `parse/enum-open-extensible`.
- T2.21 exhaustiveness on extensible enums and unions — `src/semantics/calls4.byn`, `src/semantics/codes.byn` — `diag/extensible-enum-switch`, `run/enum-open-unknown`.
- T2.22 Revision for OQ5/R10 (`embed`, whole-value name) — `docs/revisions/` (new), `docs/bayan-spec.md` §3.10.
- T2.23 `embed T` parse — `src/parser/decls2.byn`, `src/parser/nodes.byn` — `parse/embed`.
- T2.24 `embed` promotion, collisions an error — `src/semantics/declare.byn`, `src/semantics/declare2.byn` — `diag/embed-collision`, `diag/embed-twice`, `run/embed-promote`.
- T2.25 embedded field at offset 0 — `src/emitter/cprint/types.byn` — `emit-c/embed-offset`.
- T2.26 `struct attribute Name { … }` — `src/parser/decls2.byn`, `src/semantics/declare.byn` — `parse/attribute-decl`, `diag/attribute-arg-not-const`.
- T2.27 `@json(name:)`, `@column(…)` exempt from BYN51xx — `src/semantics/naming.byn`, `src/semantics/compile.byn` — the existing `number-agreement-exempt` goldens, `diag/json-name-not-string`.
- T2.28 `?.` — `src/parser/exprs.byn`, `src/semantics/express2.byn` — `parse/optional-chain`, `run/optional-chain`.
- T2.29 named, list, `or`-binding and string prefix/suffix patterns — `src/parser/patterns.byn`, `src/semantics/binder2.byn` — `parse/patterns-full`, `run/patterns-list`, `diag/or-pattern-binding-mismatch`.
- T2.30 active and `@positional` patterns (OQ7) — `src/semantics/binder2.byn`, `src/emitter/lowerpat.byn` — `run/pattern-active-tryparse`, `diag/positional-not-marked`.
- T2.31 subjectless `switch` — `src/parser/stmts.byn`, `src/emitter/lowerstmt.byn` — `run/switch-subjectless`.
- T2.32 operator overloading — `src/semantics/express3.byn`, `src/semantics/conformance.byn` — `run/operator-overload`, `diag/operator-overload-wrong-arity`.
- T2.33 members in `union`/`enum` bodies — `src/parser/decls2.byn`, `src/semantics/declare.byn` — `run/union-members`.
- T2.34 generated `tryParse`, `values`, `fromOrdinal`, `EnumMap` — `src/semantics/builtins.byn`, `src/semantics/calls2.byn` — `run/enum-generated-members`.
- T2.35 `union`/`enum` conformance (BYN2815 lifted) — `src/semantics/conformance.byn`, `src/semantics/compile.byn` — `run/enum-conforms`.
- T2.36 `extension static`, retroactive `: I` — `src/parser/decls.byn`, `src/semantics/conformance.byn` — `run/extension-retroactive`.
- T2.37 `static abstract`, `Self`, generic methods, associated-type bounds — `src/semantics/generics.byn`, `src/semantics/declare2.byn` — `run/static-abstract-self`, `diag/static-abstract-missing`.
- T2.38 `const N` generic parameters — `src/semantics/generics.byn`, `src/parser/types.byn` — `run/const-generic`.
- T2.39 type overloads, BYN3213, BYN3215 — `src/semantics/declare2.byn`, `src/semantics/codes.byn` — `diag/overload-overlap`, `run/type-overloads`.
- Law candidates: Unit erasure and dimensional safety (spec Law candidates; owned and seeded by spec 028, `run/unit-arithmetic`); deterministic replay under a fixed seed and `FakeClock`; no secret substring in any `string(x)` or `as: .debug` output; `xs except p` equals the manual `!(x is p)` filter; `T.tryParse(v.name) == v` and `T.fromOrdinal(v.ordinal) == v`; operator-derived `<`, `<=`, `>`, `>=` agree with `compare`; `?.` agrees with `if is not null`.
- Done when: every case above passes, each Phase 2 feature has a `property` or `fuzz` test besides its goldens, and `run/property-requires-shrink` finds and shrinks its planted bug.

### Phase 3 (catch-up cut): #13, #14, #15a, #16b
- T3.1 stored function types and generic function-type aliases (BYN2822 lifted) — `src/semantics/declare2.byn`, `src/semantics/generics.byn` — `run/closure-stored-field`, `run/closure-alias-generic`.
- T3.2 `ref` and `move` captures (BYN2782 lifted) — `src/semantics/calls2.byn`, `src/semantics/ownership.byn` — `run/closure-move-capture`, `diag/closure-ref-capture-escapes`.
- T3.3 heap `dyn (A -> B)` — `src/emitter/cprint/func.byn`, `src/emitter/cprint/own.byn` — `run/closure-dyn`, `bounds/closure-dyn-no-leak`.
- T3.4 typed lambda parameters, lambdas in `Panic.handler` — `src/parser/exprs2.byn`, `src/semantics/calls3.byn` — `run/panic-handler-lambda`.
- T3.5 `Event<T>`, `Subscription` — `lib/std/event/event.byn` (new), `lib/std/event/event.test.byn` — `run/event-subscribe-raise`.
- T3.6 `raise`, BYN2825, BYN5010 — `src/semantics/calls.byn`, `src/semantics/naming.byn` — `diag/event-capture-not-move`, `diag/event-name-on-prefix`.
- T3.7 `Set<T>` and bitmask `Set<T>` — `src/semantics/builtins.byn`, `rt` — `run/set-basic`, `run/set-bitmask-enum`.
- T3.8 `Deque<T>`, `Ring<T, const i32 N>`, `NonEmpty<T>` — `src/semantics/builtins.byn`, `src/emitter/cprint/builtin.byn` — `run/deque`, `run/ring`, `diag/nonempty-from-empty`.
- T3.9 `Pool<T>`, `Handle<T>` — `src/semantics/builtins.byn`, `rt` — `run/pool-handle`, `bounds/pool-no-leak`.
- T3.10 typed indices `List<T, I>` (BYN3210) — `src/semantics/typeresolve.byn`, `src/semantics/express2.byn` — `diag/index-type-mismatch`, `run/typed-index`.
- T3.11 lazy queries (`where`, `select`, `sumBy`, … `sorted`) — `src/semantics/builtins.byn`, `src/emitter/lowerexpr.byn` — `run/lazy-queries`.
- T3.12 standalone `xs except p` (OQ4) — `src/semantics/express.byn`, `src/emitter/lowerexpr.byn` — `run/except-standalone`.
- T3.13 `stackalloc T[n] uninit` and `max` — `src/parser/exprs.byn`, `src/emitter/cprint/expr.byn` — `run/stackalloc`.
- T3.14 `const Symbol[N]` (BYN2229 narrowed) — `src/semantics/binder.byn`, `src/emitter/cprint/data.byn` — `run/const-symbol-array`, `diag/const-symbol-array-dynamic`.
- T3.15 spec 021 Phase 1b onward, one task per 021 phase, each planned from 021 (the calendar types and zones).
- T3.16 date specs `as: .iso/.date/.time`, `DateLayout` — `src/semantics/express4.byn`, `src/emitter/cprint/helpers.byn` — `run/date-format-specs`, `diag/date-spec-on-int`.
- T3.17 `@timeSensitive` corpus and recorded `DateOnly`/`DateTimeOffset` fixtures (D1) — `tests/cases/inputs/` fixtures, `src/driver/test.byn`.
- Law candidates: direct and indirect calls agree for `dyn` and `move` closures (L013 extended); subscription order and mid-`raise` subscribe deferred to the next `raise`; bitmask `Set<T>` agrees with `Map<T, bool>`; `Deque<T>` agrees with `List<T>`; lazy `where`/`select` agree with eager loops; L015/L016 symbol laws; date format/parse round-trip.
- Done when: every case above passes with `@timeSensitive` and property suites, and the release memory gate reports zero leaks.

### Phase 4 (catch-up cut line): #17, #20a, #19b part 1
- T4.1 `c"…"`, `u16"…"` literals — `src/lexer/lexer.byn`, `src/lexer/tokens.byn` — `lex/c-string-literals`.
- T4.2 `extern c { … }`, `unsafe because` parse — `src/parser/decls2.byn`, `src/parser/stmts2.byn` — `parse/extern-c`, `parse/unsafe-because`.
- T4.3 C type set (OQ10), `T*`, `readonly T*` — `src/semantics/types.byn`, `src/semantics/typeresolve.byn` — `diag/c-void-not-pointer`, `diag/pointer-outside-unsafe`.
- T4.4 `@link`, `@cLayout`, `@exportC`, `@blocking`, `bitcast<T>` — `src/semantics/declare.byn`, `src/semantics/calls2.byn` — `diag/bitcast-size-mismatch`.
- T4.5 extern calls and layout in C — `src/emitter/cprint/program.byn`, `src/emitter/cprint/types.byn` — `run/extern-c-abs`, `runtime/tests/` layout asserts (`sizeof`, `alignof`, `offsetof`).
- T4.6 `.sharedLib`/`.staticLib` header emission — `src/driver/build.byn`, `src/emitter/cprint/program.byn` — `cli/` case `SharedLibWritesHeader`.
- T4.7 `bayan audit` lists `unsafe` sites — `src/driver/audit.byn` — `cli/` case `AuditListsUnsafe`.
- T4.8 derive pass producing AST (R12) — new `src/semantics/derive.byn`, `src/semantics/compile.byn` — `run/derive-display-order`.
- T4.9 `Builder`, `Patch`, `Field`, `Id` derives — `src/semantics/derive.byn` — `run/derive-builder-patch-field`.
- T4.10 `Json`, `Csv`, `Row`, `CopyIn` derives — `src/semantics/derive.byn` — `run/derive-json-roundtrip`, `diag/derive-unknown-target`.
- T4.11 `format()` and `dbg(x)`; `tryX` and `xInto` → `x()`; `T.rules` — `src/semantics/derive.byn`, `src/semantics/naming.byn` — `run/derive-verbs`.
- T4.12 `bayan expand` — `src/driver/commands.byn`, `src/driver/format.byn` — `cli/` case `ExpandInvoice` (acceptance criterion 4).
- T4.13 derived law tests and `law` execution — `src/driver/test.byn`, `src/semantics/derive.byn` — `cli/` case `DerivedLawBrokenEqFails`.
- T4.14 STATUS `-er doer pattern` row reconciled with BYN5106/BYN5107 — `docs/STATUS.md`.
- Law candidates: Derivation equivalence (spec Law candidates: `@derive(D)` and the spliced `bayan expand` output give the same diagnostics, effects and C); a broken `==` or `tryX` fails its derived law test; `Json` round-trip; extern layout agrees with the C compiler's `sizeof`/`offsetof`.
- Done when: `run/extern-c-abs` passes, `ExpandInvoice` prints the derived members and their splice compiles to the same C, and `DerivedLawBrokenEqFails` fails as expected.

### Phases 5 and 6 (may stay spec-only, keep their tags)
Each item gets its own plan, split into tasks of the same size, when it is scheduled. The cases and laws below are what those plans start from.
- Phase 5: #3 part 2 (after range analysis is measured, OQ18; `run/check-removal-equivalent`), #15b (after its revision, OQ8; `run/yield-generator`, `diag/yield-borrow-across`), #22 (lock v1 per OQ14, `src/driver/` and `src/semantics/manifest.byn`; `cli/` cases `LockWritesHashes`, `LockRejectsTampered`, `PkgDiffSemver`), #24 (`std.db` and the CLI subcommands; 027 T2 adds the `#:io` reader first; `diag/sql-placeholder-count`, `diag/sql-untrusted`, `cli/` case `ProseRoundTrip`).
  - Law candidates: check removal does not change behaviour; MVS resolution is deterministic; `--prose` then `--from-prose` gives the same AST.
- Phase 6: #21 (§12 revision first; `run/comptime-const-fn`, `diag/comptime-budget-exceeded`), #20b and #19b part 2 (after the `Op<T, E>` revision, OQ12; `run/derivation-user`, `run/model-test-cart`), multi-table and threaded `Symbol.intern` (after 027 phase 2; `run/symbol-intern-threads`). `scope`/`spawn` cases are 027's (its Testing section).
  - Law candidates: Comptime determinism (same `.rodata` bytes or the same failing step on every host); Scope lifetime containment (no child fiber runs after its `scope` exits; owned by 027, checked by its `Io.Simulated` exploration tests); `comptime` and runtime evaluation of a pure function agree.

## Data / interfaces
- New codes are allocated at merge in the ranges of `AGENTS.md`, after re-checking `docs/diagnostics-allocated.txt`, `src/semantics/codes.byn` and the plans of 026, 027 and 028 (which hold BYN2237–BYN2244, BYN4003, BYN1081–1084, BYN6009–6013, BYN3220, BYN2412). Codes the spec already names (BYN6008, BYN8002–BYN8005, BYN2825, BYN3210, BYN3213, BYN3215, BYN5010) are checked free first.
- Runtime: each item that changes `runtime/bayan-rt.h` bumps `BYN_RUNTIME_VERSION` once, coordinated with 028 (4 → 5) and 027.
- `bayan expand T` output: Bayān source, formatted by `bayan format`, that compiles in place of the `@derive` (Law candidate "Derivation equivalence").

## Testing and verification
- Per item: the goldens of R1 and the Checked-by method of its row (D1 for the C# column).
- Per phase: the done-when above, `scripts/selfhost/land.sh`, `bash scripts/docs/check.sh`.
- Acceptance criterion 1: 015 T15 passes after 026 T10, and 015 T17 after 027 T11–T13; `tests/parity/` runs with no Python. 023 tracks, it does not build these.
- Acceptance criterion 2: a `diag/` case from 028 (`unit-coarser`) covers `let wait: Seconds = 5s + 500ms` with BYN3205 and the three rounding helps.
- Acceptance criterion 3: a `run/` test case with `provide clock: FakeClock(at: …)` and `provide log: recorder`, asserting the clock value, the recorded line, zero allocation (bounds check in `src/driver/bounds.byn`), and a seeded `property` failure shrunk to its minimum. The `Date.today` part waits for #16b.
- Acceptance criterion 4: `tests/cases/cli/` case running `bayan expand Invoice` on a `@derive(Builder, Patch, Field, Json)` struct, plus the derived law tests passing.
- Acceptance criterion 5: `scripts/docs/check.sh` gains a check that every Phase 1–4 STATUS row owned by 023 is `built` with a golden path, and that unbuilt Phase 5–6 rows keep a non-`built` status and their spec tag.

## Risks & mitigations
- Two `Io.Simulated` implementations (023 #16a, 027 T10). Mitigation: D4.
- The cut label "0.4" is stale: 0.4.0 shipped as the .NET exit. Mitigation: ND1; phases keep their order whatever the number.
- `dec` and `checked` both add helpers to `cprint/builtin.byn` and the runtime that 028 also edits. Mitigation: #1 and #2 rebase on 028 T4 if it merges first; one runtime version bump per merged change.
- Derives as AST (R12) may emit C that differs from hand-written code. Mitigation: the `bayan expand` splice test compares emitted C byte for byte.
- STATUS drift while gen-status still reads C# facts. Mitigation: T0 lands first.

## Questions
All 19 open questions of the spec (OQ1–OQ19) are resolved, so the spec is approved. None is open in this plan. The plan-level choices below are not spec questions.

## Needs decision
- **ND1 Release number of the catch-up cut.** The spec says "needed for 0.4", written before 0.4.0 became the .NET exit release; 027 and 028 target 0.5.0 and pull #9, #23 and #25 into it. Options: (a) the cut is the first release after all of Phases 1–4 land, number set then; (b) Phases 1–4 are 0.5.0 alongside 027 phase 1; (c) the cut is 0.6.0. **Recommended: (a)**, so no phase waits on a calendar. The plan uses "catch-up cut" until decided.
- **ND2 R14 chunk-read shape.** Owned by 027 Needs decision 2 and audit decision 2.2 (awaiting owner). 023 R14 names `read(into:)`, which §10 does not allow (`into` is not a particle, BYN5008). Recommended: amend R14 to whatever 027 settles, by a one-line edit to `023-spec.md` once decided.

## Coverage check
| R | Covered by |
|---|---|
| R1 | Approach steps 3 and 4; each phase's goldens and explain pages |
| R2 | Tech / dependencies (freeze over); revisions first per item |
| R3 | The spec's inventory, unchanged; Ownership maps every row to this plan or its owner |
| R4 | Phases 1–4 cut, Phases 5–6 keep tags; D2 for `small`; ND1 for the number |
| R5 | D1; Testing per item |
| R6 | Phase done-when lines; revisions before items with open text |
| R7 | T0.1 (D5); Approach step 3; acceptance criterion 5 check |
| R8 | T1.10 (warning code) |
| R9 | T2.15–T2.18 (heap copy, wipe in T2.18) |
| R10 | T2.22–T2.25 (one `embed`, collisions are errors, whole-value name) |
| R11 | T2.12 (child process, input saved first) |
| R12 | T4.8–T4.13 (AST derive pass, `bayan expand`) |
| R13 | Owned by 027 (Ownership #23) |
| R14 | Owned by 027 (Ownership #25); ND2 |
