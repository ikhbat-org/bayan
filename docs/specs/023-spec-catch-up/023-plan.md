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

### T0 Tooling before Phase 1
- `scripts/docs/gen-status.sh`, `scripts/docs/gen-status.test.sh` — read keywords from `src/lexer/` and members from `src/semantics/builtins.byn`; evidence columns cite `src/` paths (D5, R7).
- `docs/specs/023-spec-catch-up/023-spec.md` — ownership notes on rows #6, #9, #16b, #18, #23, #25 (pointing at 026, 027, 028, 021, 015); R5 wording per D1; #2 per D2.

### Phase 1 (catch-up cut): #1, #2, #3 part 1, #18 rest
- **#1 `dec` (rev 0024, applied).** `src/lexer/lexer.byn` (`dec` literal suffix) — `src/semantics/types.byn` (new builtin kind), `typeresolve.byn`, `express.byn` (`bindLiteral`), `conversions.byn` (`dec(0.1)`, `dec(f64)` BYN2206 with the two fix-its; `dec.fromF64(x, digits)`; `x.truncate<T>()`), `express3.byn` (operators), `fold.byn`; `src/emitter/cprint/common.byn`, `builtin.byn`, `helpers.byn` (format); `runtime/bayan-rt.{h,c}` (96-bit coefficient, sign, scale 0..=28, ties-to-even, traps) and `BYN_RUNTIME_VERSION` bump. Goldens: `run/dec-*` including negative zero and non-terminating quotients; `diag/dec-from-float*`.
- **#2 `checked(expr)` and `if unlikely`.** `src/parser/exprs.byn` (`checked` keyword expression, already lexed); `src/semantics/express3.byn` (result `T?`, covers the OQ2 operators and narrowing, also on `dec`); new warning code for a `checked(...)` with no covered operator (R8) in `src/semantics/codes.byn`; `src/emitter/cprint/builtin.byn` (non-trapping helpers returning `has`); `if unlikely` parse exists (`src/parser/stmts.byn`), so `src/emitter/lowerstmt.byn` and `cprint` emit `__builtin_expect`, plus the §7.2 lint on `if unlikely` around error returns. `small`: no change (D2).
- **#3 part 1.** `src/semantics/effects.byn` — BYN6008 purity check on `expects` and `requires`; `src/semantics/declare*.byn` and `typeresolve.byn` — `requires` on `type` aliases and generic structs; BYN2320/2321 wording in `codes.byn` and `src/driver/diagdocs.byn`. The four revision 0022 goldens.
- **#18 rest.** `src/semantics/builtins.byn` — `string.matches(Regex)`, `string.replaced(Regex, by:)` (D3); `std.text` members in a new `lib/std/text/` (`words`, `graphemes`, case mapping and folding, `normalized`, casing helpers, `truncated`, `wrapped`, `escaped`) with tables generated beside `src/lexer/unicode-tables.byn` (Unicode 16.0.0); `Utf16.decode`; `grouping:` and `case:` in `src/semantics/express4.byn` (`bindInterpolated`) and `src/emitter/cprint/helpers.byn` (`format`). Date specs `as: .iso/.date/.time` move to #16b.
- Done when: rev 0024 features, `checked(expr)`, `if unlikely`, BYN6008, the `requires` forms and the #18 members pass their goldens and std tests; 015 T14 and T16 stay green.

### Phase 2 (catch-up cut): #16a, #19a first, then #4, #5, #6 rest, #7, #8, #10, #11, #12
- **#16a.** Revision for OQ9 (D6). `src/semantics/effects.byn` and the provide binding (handler names in `codes.byn` BYN6007 already list them) — accept `clock`, `random`, `console`, `log`, built-in `fs.restricted`; keep user `fs`, `net`, `env`, `process` handlers as BYN2022; `effect name = …` aliases in `src/parser/decls*.byn` and `src/semantics/declare*.byn` (`effect` is already contextual); ambient `log(msg, as:)` in `builtins.byn`; `context.Io`; `runtime/bayan-rt.c` handler slots on 027's `Io` (D4); `FakeClock` in std.
- **#19a.** `src/parser/decls*.byn` — `property "…" (T x)`, `fuzz "…"`, `bench "…" { measure … }`, `@cases(constList)`, `@pairwise`, `@nightly`; `src/semantics/` — generators from `requires` rules (#3), shrinking; `src/driver/test.byn` — property runner with seed reporting, fuzz runner that saves each input before running it in a child process (R11), corpus and minimizer, bench output; doctests from `///` fenced blocks; `src/driver/testreport.byn` for results.
- **#4 `Secret<T>`.** Revision for OQ3/R9. `builtins.byn` (type and `equalsConstantTime`), `express4.byn` (`***` in `Display` and debug), `@secret` attribute, BYN8002–BYN8005 in `codes.byn`; `runtime/bayan-rt.c` heap copy and volatile wipe on dispose; sinks today are `Io.run` and `Io.runBatch` only.
- **#5 `except` for-form.** `src/semantics/express.byn` (the BYN2022 site), `flow.byn` (narrowing, taint kept), `src/emitter/lowerstmt.byn`. The standalone form keeps BYN2022 until #15a (OQ4).
- **#6 rest.** `src/parser/decls*.byn` — `enum open`, `extensible` on `enum` and `union` (reusing 026's flag); `src/semantics/calls4.byn` exhaustiveness (026's BYN2412 path); `open` enums accept unknown integers from C (consumed by #17).
- **#7 `embed`.** Revision for OQ5 (name for the whole embedded value). `src/parser/decls*.byn`; `src/semantics/declare*.byn` (promotion, every collision an error); `src/emitter/cprint/types.byn` (field at offset 0).
- **#8 attributes.** `struct attribute Name { … }` in `src/parser/decls*.byn`; constant-argument checks and BYN2770 narrowing in `src/semantics/`; `@json(name:)`, `@column(…)` exempting members from BYN51xx in `src/semantics/naming.byn`.
- **#10 patterns.** `?.` in `src/parser/exprs*.byn` and `src/semantics/express*.byn`; named patterns, list patterns, `or` bindings, string prefix/suffix, active patterns per OQ7 and positional `@positional` in `src/parser/patterns.byn`, `src/semantics/` pattern binding, `src/emitter/lowerpat.byn`; subjectless `switch` (BYN1071 reserved) in `src/parser/stmts*.byn`; operator overloading in `src/semantics/express3.byn`.
- **#11.** Methods and computed properties in `union`/`enum` bodies (`src/parser/decls*.byn`, `src/semantics/declare*.byn`); generated `tryParse`, `values`, `fromOrdinal`, `EnumMap`; conformance in `src/semantics/conformance.byn` (removing BYN2815).
- **#12.** `extension` already parses (`src/parser/decls.byn`, `extensionDecl`); add `extension static`, retroactive `: I`, `static abstract` and `Self` in `conformance.byn` and `generics.byn`, generic methods, associated-type bounds, `const N` parameters, type overloads (lifting BYN2006 for distinct types, BYN3213, BYN3215).
- Done when: `bayan test` passes with each Phase 2 feature covered by a `property` or `fuzz` test besides its goldens, and the planted-bug self-test of #19a finds and shrinks its counterexample.

### Phase 3 (catch-up cut): #13, #14, #15a, #16b
- **#13.** Lift BYN2822 and BYN2782 in `src/semantics/`; `dyn (A -> B)` heap closures in `src/emitter/cprint/func.byn` and `own.byn`; `ref` and `move` captures; generic function-type aliases; lambdas in `Panic.handler`. ASan and leak gate through `scripts/release/memory-gate.sh`.
- **#14.** `lib/std/event/` (`Event<T>`, `Subscription`); `raise`, BYN2825, BYN5010 in `src/semantics/`.
- **#15a.** `Set<T>` (and bitmask form), `Deque<T>`, `Pool<T>`/`Handle<T>`, `Ring<T, const i32 N>`, `NonEmpty<T>`, `List<T, I>` (BYN3210) in `builtins.byn` and `runtime/bayan-rt.c` or `lib/std/`; lazy queries; `stackalloc`; `const Symbol[N]` (BYN2229 narrowed); the standalone `xs except p` (#5).
- **#16b.** Spec 021 Phases 1b onward on 028's units and `Uptime`; date specs `as: .iso/.date/.time` and `DateLayout` in `express4.byn` and `helpers.byn`; `@timeSensitive` corpus; differential fixtures recorded once from a `csharp-final` build (D1).
- Done when: the four items pass `bayan test` with `@timeSensitive` and property suites, and the release memory gate reports zero leaks.

### Phase 4 (catch-up cut line): #17, #20a, #19b part 1
- **#17.** `extern c { … }`, `unsafe because`, `c"…"`, `u16"…"`, `T*`, `readonly T*` in `src/lexer/`, `src/parser/`; C type set per OQ10 in `src/semantics/types.byn`; `@link`, `@cLayout`, `@exportC`, `@blocking` (027 phase 3 uses `@blocking`); `bitcast<T>`; `.sharedLib`/`.staticLib` header emission in `src/emitter/cprint/program.byn` and `src/driver/build.byn`; `bayan audit` (`src/driver/audit.byn`) lists `unsafe` sites.
- **#20a.** Derives generate Bayān AST that is bound like source (R12), in a new `src/semantics/` derive pass before binding; `bayan expand` in `src/driver/commands.byn` prints that AST through the formatter (`src/driver/format.byn`); `format()` and `dbg(x)`; `T.Builder`, `T.Patch`, `T.Field`, `T.Id`; `tryX` and `xInto` → `x()`; `T.rules`; reconcile the STATUS `-er doer pattern` row with BYN5106/BYN5107.
- **#19b part 1.** Derived law tests and `law` execution in `src/driver/test.byn` on the #19a runner.
- Done when: a package calls a C library through `extern c`; `bayan expand Invoice` prints the derived members and splicing them back compiles to the same C; derived law tests run in `bayan test`.

### Phases 5 and 6 (may stay spec-only, keep their tags)
- Phase 5: #3 part 2 (only after range analysis is measured, OQ18), #15b (after its revision, OQ8), #22 (`package.lock.byn` v1 per OQ14, in `src/driver/` and `src/semantics/manifest.byn`), #24 (`std.db`, `bayan migrate`, `bayan new test`, `bayan doc`, `bayan repl`, `--prose`, `#:` directives; 027 T2 adds the `#:io` directive reader first).
- Phase 6: #21 (§12 revision first), #20b and #19b part 2 (after the `Op<T, E>` revision, OQ12), multi-table and threaded `Symbol.intern` (after 027 phase 2).
- Each item gets its own plan when it is scheduled. This plan does not list files for them.

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
| R7 | T0 (D5); Approach step 3; acceptance criterion 5 check |
| R8 | Phase 1 #2 (warning code) |
| R9 | Phase 2 #4 (heap copy, wipe) |
| R10 | Phase 2 #7 (one `embed`, collisions are errors, whole-value name) |
| R11 | Phase 2 #19a (child process, input saved first) |
| R12 | Phase 4 #20a (AST derive pass, `bayan expand`) |
| R13 | Owned by 027 (Ownership #23) |
| R14 | Owned by 027 (Ownership #25); ND2 |
