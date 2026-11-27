# 028 — Plan

Spec: ./028-spec.md

Status: draft
Release: unscheduled (planned for 0.5.0, before spec 027 phase 1 uses `Duration` and `Uptime`)
Sources: `./028-spec.md` (owner decisions D1–D8, 2026-11-23); `docs/bayan-spec.md` §3.4, §3.5, §16.5; `docs/revisions/0017-addendum-a2-diagnostic-codes.md`; `docs/DIAGNOSTICS.md`; Neon plan review 2026-11-27 (`tmp/plan-review/028-review.md`)

## Approach
Units are a checker feature with no runtime representation. The bound tree and the lowered tree (`src/emitter/ltree`) keep `unitType` and `uptime` as their own types, because formatting, debug output and equality need the unit and its symbol. Erasure happens in `cprint`: each unit type and `Uptime` is emitted as its storage C type (`common.byn`), each operator as the storage type's checked helper (`byn_add_N` and the rest, `runtime/bayan-rt.h:555`–`:578`), and each finer conversion as a checked multiply by a constant scale. There is no separate SIR step for the C path; `src/sabk/` has its own SIR and is not touched.

The work lands in this order (details under Order):

1. Spec text first, as a new revision, so the code is built from the document (`docs/revisions/README.md`).
2. `unit` declarations in the parser, then unit types, families, scales and the `core` time units in the checker.
3. Unit literals, conversions, operators, rounding methods and formatting.
4. `Uptime` as a built-in type of `std.time`, its runtime clock per platform, and the target check.
5. The `Millis` retirement in two commits, because the compiler's own source names `Millis` (`src/driver/cc.byn:273`, `:290`) and the bootstrap must compile each commit with the previous one (`bootstrap/README.md`).

`Io.monotonicNanos()` and the built-in `Time` do not change.

## Decisions
- **D-OQ1 Units as `Map` keys and `const` values.** Chosen: every unit type, `Duration` included, is a valid `Map` key and a valid module-level scalar `const` value. `Uptime` is neither. A `const` array of a unit type stays BYN2229.
  - Rejected: making `Uptime` a `Map` key or a `const`. An `Uptime` reading has no meaning across runs, and its only source, `Uptime.now()`, is not a constant (BYN2219). Allowing it later breaks no program; withdrawing it would.
  - Why units are allowed: they are integer-backed with integer `==` (R1, R10), which is the rule §3.5 already applies to integer types. R7's own case `const big: Nanoseconds = 9_223_372_037s` (BYN2204) needs a unit `const`. `const` arrays stay closed because the `.rodata` rule (`docs/bayan-spec.md:300`) names number types, and widening it is not needed for 027.
  - Spec text change: the §3.5 key list (`docs/bayan-spec.md:298`) adds "a unit type (§3.4)" after "an integer type", and says that `Uptime` is not a key. §3.4 gains one line: a module-level `const` may hold a unit value given by a unit literal or a constant unit expression.
- **D-OQ2a Diagnostic codes.** Chosen: the new codes take the next free numbers in the semantics range after BYN2236 (2000–3999 semantics in `AGENTS.md`; addendum A2 places the existing unit codes BYN3203 and BYN3205 in 3xxx, and the new declaration and literal codes join the 22xx block beside BYN2202–BYN2236), and the target check takes the next free backend number after BYN4002. Each was checked free in `docs/DIAGNOSTICS.md`, `docs/diagnostics-allocated.txt`, `src/semantics/codes.byn` and every spec under `docs/specs/` (spec 027 allocates none). The table is under Data / interfaces.
  - Rejected: 19xx codes for `MinutesNotMeters` and `RetiredDoubleSuffix`, as the "spelling (19xx)" note in `docs/specs/021-std-time/021-spec.md:256` suggests. Both need to know which units are visible, which the parser does not know. Both are errors, not the x900 lints of addendum A2.
  - BYN2231 and BYN2232 are unused gaps. They are left alone, because the brief asks for the next number after the last code in the area.
  - The numbers are provisional until merge. The T1 spec revision re-checks that they are still free and records them in `docs/diagnostics-allocated.txt`.
- **D-OQ2b R14 has no new code.** Chosen: `string(t)` and `$"{t}"` on `Uptime` report the existing BYN2225 `NotFormattable`. Rejected: a new `UptimeNotDisplayable` code. R14 allows the existing error, and BYN2225 already says what is wrong.
- **D-OQ2c `AbbreviatedUnitName` is not added.** Chosen: under R17, `Millis` gets the ordinary unknown-type error. Rejected: keeping the planned lint from `docs/bayan-spec.md:2356`. R17 asks for the unknown-type error, and a lint that names `Millis` keeps the name alive in the compiler.
- **D-OQ2d `Io.monotonicNanos()` and `Time` stay unchanged during 028.** Chosen: both keep their signatures, their `clock` effect (`src/semantics/effects.byn:768`) and their runtime (`byn_io_monotonic_nanos`, `byn_time_now` in `runtime/bayan-rt.c`). Rejected: making `Io.monotonicNanos()` return `Uptime` now. That breaks its call sites in the compiler for no 027 need. Retiring it belongs with spec 021. `FixedClock` vs `FakeClock` stays out of scope, as the spec says.
- **D-U1 `Uptime` is a compiler built-in type, not std source.** Chosen: a new `BuiltinKind.uptime` in `src/semantics/types.byn`, resolved by name only in a file that imports `std.time`, in type positions and as a call receiver. Rejected: `public struct Uptime { i64 nanos }` in `lib/std/time/`. `Uptime` needs `+`, `-` and ordering, and user operator overloading is not in 0.4 (`docs/bayan-spec.md:1109`).
- **D-U2 The `Millis` retirement uses a bridge commit.** Chosen: T8a makes `Io.run(timeout:)` take `Duration?` and lets `Millis` convert implicitly to `Duration` (×1 000 000) and to `Duration?` inside the compiler. T8b then rewrites every `src/driver/` call site to `Milliseconds(…)` and deletes `Millis` everywhere. No release ships T8a alone, and the end state has no alias (D1).
  - Rejected: one commit. The previous bootstrap would type-check the new `cc.byn` against its own `Io.run(timeout: Millis?)` and fail `scripts/ci/bootstrap-check.sh`.
  - Audit (`dev` 9e26b3dbc): every driver site passes a `Millis(n)` value, never a `Millis?` variable, and no driver site reads the `after` payload: each `.timeout` arm discards field 0 (`src/driver/cc.byn:274`, `src/driver/golden.byn:1022`, `src/driver/mutate.byn:797`, `src/driver/test.byn:999`). So the bridge needs only `Millis` → `Duration` and its lift into `Duration?`.
- **D-U3 Frozen cases touched by the rename.** Chosen: each frozen expected file that changes (22 `Millis` rows in `tests/cases/FREEZE.tsv`) gets its row rewritten by `scripts/ci/freeze-check.sh --write` in the same commit. Each such case gets one `tests/cases/DIVERGENCES.tsv` row: the case, a question number opened in `docs/bayan-questions.md`, right `driver`, and the reason "spec 028 R17: `Millis` retired". No row is `pending`.
  - Rejected: deleting the frozen cases. They still cover `Io.run` and the error payload once the type name changes.
- **D-U4 Order of scales in a family.** A unit `A` is finer than `B` in the same family when `A.scale` divides `B.scale` and they differ. Implicit conversion, mixed-scale `+`, `-`, comparison and `/`, `+=`/`-=`, and the rounding methods all use this order, so every factor is an exact integer. Two members of a branching family whose scales do not divide (`unit Two(tw) = 2 b`, `unit Three(th) = 3 b`) are not ordered; what that means is open (Needs decision, ND1), and until it is settled the plan rejects every implicit conversion and operator between them.
- **D-U5 Rounding methods.** `t.floor<U>()`, `t.ceiling<U>()` and `t.rounded<U>()` need `U` to be a unit strictly coarser than `t`'s unit under D-U4. A `U` outside the family, a non-unit `U`, the same unit, a finer unit, or an unordered member is BYN2244 (one reason each). A missing type argument (`1500ms.floor()`) is BYN2023 `wrongTypeArgumentCount` (`src/semantics/codes.byn:313`). A receiver that is not a unit (`5.floor<Seconds>()`) is BYN2003 `unknownMember` (`src/semantics/codes.byn:294`), as for any absent method. Rejecting the same-scale and finer cases is the conservative choice: allowing them later breaks no program.
- **D-U6 Wrap and unwrap.** For a unit `U` with storage `S`: `U(x)` wraps when `x` converts implicitly to `S` (so `Seconds(42)` and `Seconds(n)` with `n: i32` wrap). When `x` is a unit of `U`'s family, `U(x)` is the R7 conversion: a coarser `x` (`Milliseconds(2s)`) converts with the checked multiply, and a finer or unordered `x` (`Seconds(1500ms)`) is BYN3205 with the rounding help, so wrapping never bypasses R8. Any other `x` is BYN2206. `T(u)` unwraps only when `T` is exactly `S`; `i32(Seconds(42))` is BYN2206 with help ``write `i32(i64(…))` ``. `Uptime(x)` and `T(t)` for `t: Uptime` are BYN2206 for every `x` and `T`.
- **D-U7 Bare literals beside units.** BYN3203 fires wherever a bare integer constant meets a unit or `Uptime`: in `convert` (initialize, assign, return, pass), and in `bindBinary` and the compound-assignment path before `common` is tried, because `common` (`src/semantics/conversions.byn:135`) finds no type for `2s + 500` and the binary path would report BYN2208 through `t19BadOperands` (`src/semantics/express3.byn:389`). Scalar `*` (`3 * 250ms`, `250ms * 3`) stays valid and is checked first; `/` and `%` with a scalar and `*=` stay BYN2208 (R10).
- **D-U8 `Io.run(timeout:)` to the runtime.** Open (Needs decision, ND2). Meanwhile the plan keeps the runtime's `int64_t timeout_ms` and makes the conversion exact in the emitter: `null` → `-1` (no timeout), `d <= 0ns` → `0` (expires at once), `d > 0ns` → `d / 1 000 000 + (d % 1 000 000 != 0)` (ceiling, so a positive timeout never fires early and never becomes `0`). The `IoError.timeout` payload stays the caller's `Duration`, unrounded.
- **D-U9 `Uptime` debug output.** `$"{t, as: .debug}"` prints `Uptime(` the nanosecond count ` ns)`, for example `Uptime(81234567 ns)`. R14 asks for debug output only; the text is fixed in the T1 revision.

## Tech / dependencies
- No new tool or library. Both build paths stay as they are: the C emitter with zig cc, and the bootstrap C.
- New platform calls in `runtime/bayan-rt.c`:
  - Linux: `clock_gettime(CLOCK_BOOTTIME, …)`.
  - macOS: `mach_continuous_time` and `mach_timebase_info` from `<mach/mach_time.h>`.
  - Windows: `QueryInterruptTimePrecise` from `<realtimeapiset.h>`.
  - Any other target gets no `Uptime` clock and no fallback (BYN4003).
- `BYN_RUNTIME_VERSION` goes from 4 to 5 (`runtime/bayan-rt.h:10`). `src/driver/runtime.byn` is regenerated (it is generated from `runtime/`), and the bootstrap copies follow `bootstrap/README.md`.
- Spec 027 depends on T2–T7 here (Order).

## Changes by area
### Spec and documents
- `docs/revisions/` new revision (number taken at merge, after 0025 of plan 026) — §3.4 built for `unit` and suffixes, §3.5 key list, §16.5 `Duration` and `Uptime` built, new codes, the D-U4 to D-U9 rules — R1–R16, D-OQ1
- `docs/bayan-spec.md` §3.4 (`:266`), §3.5 (`:298`), §16.5 — status lines and the D-OQ1 text; the `Millis` sites listed in R17 (`:271`, `:281`, `:381`, `:484`, `:1417`, `:1989`, `:1994`, `:1996`, `:2684`) change in T8b; in T8b the `:2181` sentence about the doc sweep is deleted, and the `AbbreviatedUnitName` row (`:2356`) is deleted (D-OQ2c) — R1–R17
- `docs/specs/023-spec-catch-up/023-spec.md` `:72`, `:158` — `Millis` → `Milliseconds` in T8b — R17
- `docs/diagnostics/BYN2237.md` … `BYN2244.md`, `BYN3203.md`, `BYN3205.md`, `BYN4003.md` (all new) — explain pages; `docs/DIAGNOSTICS.md` regenerated by `scripts/docs/gen-diagnostics.sh` — R1, R2, R4–R8, R16
- `docs/diagnostics/BYN1043.md` (`:15`, `:21`, the `timeout(Millis after)` example) — `Duration` in T8b, and `src/driver/diagdocs.byn` regenerated from it — R17
- `docs/STATUS.md`, `CHANGELOG.md` (breaking: `Millis` removed, `Io.run(timeout:)` takes `Duration`) — R17

### Lexer
- `src/lexer/lexer.byn` numeric suffix scan (`:792`–`:821`) — no change expected: a non-ASCII suffix start is decoded and tested with `isIdentifierStart` (`:324`–`:329`), and U+00B5 and U+03BC are both lowercase letters. T2 adds a `lex/` case for both code points; if either is rejected, T2 fixes `isIdentifierStartAt` for them in the same commit. BYN0011 (`suffixOnHexOrBinary`, `:814`) already covers hex and binary — R4, R5

### Parser
- `src/parser/nodes.byn` — new `UnitDecl` (span, `Modifiers modifiers` as in `TypeAliasDecl` (`:459`) so `public unit` works, name, symbol span or null, storage type or scale `N` and right-hand symbol, or a compound right-hand side kept for BYN2022, doc, attributes) and new `Decl.unitDecl(Owned<UnitDecl> node)` in `union Decl` (`:190`) — R1, R2, R3, R4
- `src/parser/decls.byn` declaration dispatch (`:175`–`:189`, the `typeAliasDecl` and `effectDecl` arms) — contextual `unit` at top level when followed by a name; new `parseUnit` in `src/parser/decls2.byn` — R1, R2, R3
- `src/parser/dump.byn`, `src/parser/spans.byn` (`:290` area) — `unitDecl` arms — R1

### Semantics
- `src/semantics/types.byn` `TypeKind` (`:24`) — new `unitType`; `BuiltinKind` (`:92`–`:103`) — new `uptime`, `millis` removed in T8b (`:102`, `:188`, `:638`); `isValidKeyInner` default branch (`:867`) — unit types are keys — R1, R14, R17, D-OQ1
- `src/semantics/ctx.byn` — new unit table, one entry per declared unit: declaring module, visibility, family root, scale from the base as `u64`, storage type, symbol (normalized: `µs` and `μs` stored as `us`). Lookup by symbol is per file: the `core` units, the file's own module, and the `public` units of each module in the file's imports (`:65`) — R1, R2, R4, R5
- `src/semantics/binder.byn` declaration switches (`case .typeAliasDecl` at `:587`, `:652`) and `src/semantics/compile.byn` (`:1110`, `:1695`, `:1933`) — `unitDecl` arms, in two passes per module: pass 1 records every unit header and symbol; pass 2 resolves each scaled unit's right-hand symbol and multiplies the factors by depth-first search with an on-stack mark, so a cycle (`a` → `b` → `a`) is BYN2238 at each declaration on it. Scale products are computed with the big-integer helpers `bindLiteral` uses (`bigCmp`, `bigMax`, `src/semantics/express.byn:878`–`:880`) and checked against the base storage type's maximum, signed or unsigned, so a `u64` base may hold scales above `i64` max. Checks: BYN2008 casing, BYN2237 storage, BYN2238 scale and cycles, BYN2022 for compound declarations (`.unsupported`), and BYN2241 for a duplicate symbol against the file's visible set: `core` symbols and units of the same module at the declaration, the built-in suffixes `u`, `l`, `ul`, `f` and `dec` at the declaration (R4 keeps them reserved; without this `unit Feet(f): i64` would compile while `5f` stays `f32`, `src/semantics/express.byn:886`), `µs`/`μs` as `us`, and two imported units with one symbol at the second `import` that brings it in — R1, R2, R3, R4, R5
- `src/semantics/typeresolve.byn` — `Grams` from another module resolves as `mod.Grams` through the existing import path and its `checkVisible` (`:471`–`:475`); a private unit is not visible there, and its symbol is not visible as a suffix — R1, R4
- `src/semantics/express.byn` `bindLiteral` (`:874`–`:900`) and the float arm (`:950`–`:963`) — replace the `.unsupported` report for an unknown suffix with a unit lookup. Precedence on an integer literal: `u`, `l`, `ul`, `f` as today; then a visible unit symbol (`µs`/`μs` as `us`) gives the unit type, BYN2203 when out of range; then `m` is BYN2242 and `d` is BYN2243; any other suffix is BYN2239. On a float literal: `f` as today; then a visible unit symbol is BYN2240; then `d` is BYN2243 and `m` is BYN2242; any other suffix (`dec` included, which is not built) keeps today's `.unsupported` report. BYN2240's help names a rewrite: the coarsest finer unit `F` in the family (D-U4) for which the value times the factor is an integer (`1.5s` → `1500ms`, `1.5kg` → `1500g`); when none exists (`1.5ns`, a base unit, or `1.0000000001s`), the help is ``write a whole number of `{1}` `` — R4, R5
- `src/semantics/express.byn` `convert` (`:273`, the BYN3204 site) — BYN3203 with the `0g` / `Cents(0)` fix-it — R6, R15
- `src/semantics/express.byn` (`:1386`–`:1396`, the built-in receiver names `Fs`, `Time`, `Millis`) — `Uptime` resolves as a receiver only when the file imports `std.time`; otherwise it falls to the undefined-name report below (`:1398`) — R14
- `src/semantics/conversions.byn` `implicit` (`:11`) — finer-only implicit conversion under D-U4 as a new conversion kind, and the optional arm (`:20`–`:26`) also lifts that kind, so `timeout: 5s` converts `Seconds` to `Duration?` (today the arm lifts only `.widen`); `explicit` (`:122`) — D-U6, and the `.millis` arm (`:129`) goes in T8b; `common` (`:135`) — the finer unit of two ordered members, -1 for unordered ones (ND1), BYN2206 for unrelated families — R7, R9, R10, R13, R17
- `src/semantics/express3.byn` `bindBinary` (`:171`; operands converted at `:391`–`:392`), `bindUnary` (`:5`), `fold` (`:500`, BYN2204), `bindCast` (`:912`) — unit and `Uptime` operators; BYN3203 for a bare constant beside a unit or `Uptime` before `common` (D-U7); scalar `*` on either side; BYN2208 for `u * u`, `u / n`, `%`, unary `-` on an unsigned unit, `Uptime + Uptime`, `Duration + Uptime`, and `Uptime` with a non-time unit (`start + 5g`); constant overflow; D-U6 casts. `t19IsEquatable` (`:555`) — `unitType` and `uptime` arms beside `.millis` — R7, R9, R10, R15
- `src/semantics/calls4.byn` `bindAssign` (`:340`; the compound path from `compoundOperator`, `:323`, `:350`) — `+=`/`-=` with a same-or-coarser right side; BYN3203 for a bare constant (`t += 1`); `*=` is BYN2208 — R6, R10
- `src/semantics/calls2.byn` `bindConstruction` (`:356`, today's `Millis(n)` arm) — `U(x)` per D-U6, `Uptime(x)` BYN2206; `bindBuiltinMethodCall` (`:693`) — `.floor<U>()`, `.ceiling<U>()`, `.rounded<U>()` per D-U5, and `Uptime.now()` — R8, R9, R14
- `src/semantics/express4.byn` `bindInterpolated` (`:865`) and the `string(…)` path — units format; `whyNotFormattable` builtin arm (`:1054`) — `unitType` formats, `uptime` does not (BYN2225); `t35WhyNotDebugFormattable` (`:1108`) — `uptime` and `unitType` format under `as: .debug` (D-U9) — R11, R14
- `src/semantics/binder.byn` `const` binding (`:1531`–`:1540`) — a unit `const` passes when its value folds to a constant; `Uptime.now()` stays BYN2219; a unit array keeps the BYN2229 path (`:1559`) — D-OQ1
- `src/semantics/builtins.byn` — new `core` units source (the six units and `type Duration = Nanoseconds`), parsed like `ioErrorSource` (`:60`); `Uptime.now` registered like `Time.now` (`:586`–`:593`); `runParameters` timeout (`:287`) and the `IoError` source `timeout` payload become `Duration` in T8a — R12, R13, R14, R17
- `src/semantics/symbols.byn` — new `uptimeNow` beside `timeNow` (`:115`) — R14
- `src/semantics/effects.byn` (`:768`) — `.uptimeNow` requires `clock`; unit and `Uptime` operators require nothing — R14, R15
- `src/semantics/typeresolve.byn` (`:394`–`:401`, `:1041`) — `Uptime` when the file imports `std.time`; `"Millis"` removed in T8b — R14, R17
- `src/semantics/compile.byn` (`:937`–`:945`) — the built-in payload type `Millis` becomes `Duration` in T8a, with `builtins.byn` — R17
- `src/semantics/compile.byn` `hostTargetSplit` (`:83`), `CompilationOptions.target` — BYN4003 when `Uptime.now()` is bound and the target OS is not one of `linux`, `macos`, `windows` (the `Target.os` names, `src/driver/bounds.byn:528`); `wasm32` splits to OS `wasi` (`:84`) and so fails, as does any other OS; a null target means the host's `Target.os` — R16
- `src/semantics/codes.byn` — the codes in Data / interfaces, plus BYN3203 and BYN3205 — R1–R8, R16

### Emitter
- `src/emitter/cprint/common.byn` (`:50`, `:92`) — a unit type and `Uptime` are their storage C type; the `.millis` arms go in T8b — R1, R14, R17
- `src/emitter/cprint/builtin.byn` `binary` (`:518`; the checked-helper choice at `:527` tests `isInteger`) and the unary path — a unit or `Uptime` operand takes its storage type's suffix, so `+`, `-`, `*`, `/` and unary `-` call `byn_add_N`, `byn_sub_N`, `byn_mul_N`, `byn_div_N`, `byn_neg_N` (`runtime/bayan-rt.h:555`–`:578`) and trap on overflow and division by zero in every mode; a finer conversion is `byn_mul_N(x, scale)` — R7, R10, R15
- `src/emitter/cprint/expr.byn` — rounding: `.floor`, `.ceiling`, `.rounded` lower to helpers `bynh_unit_floor_N`, `bynh_unit_ceiling_N`, `bynh_unit_rounded_N`, emitted once per storage type through `helperFill` (as `src/emitter/cprint/helpers.byn:215` does), with `s` the exact factor (D-U4). Signed: `q = x / s`, `r = x % s`; floor `q - (r < 0)`, ceiling `q + (r > 0)`, rounded `r >= 0 ? q + (r >= s - r) : q - (-r >= s + r)`. Unsigned: floor `q`, ceiling `q + (r != 0)`, rounded `q + (r >= s - r)`. No step overflows: `0 <= |r| < s`, and `|q| + 1` fits because `s >= 2` — R8
- `src/emitter/cprint/expr.byn` (`:695`, `:718` area) — `.uptimeNow` emits `byn_uptime_now()` — R14
- `src/emitter/cprint/expr.byn` (`:551`, the `bynh_io_run_with` helper) — in T8a, `timeout.has ? timeout.value : -1` becomes the D-U8 conversion of the `Duration` to milliseconds; `*detail = timeout.value` keeps the nanoseconds — R17
- `src/emitter/cprint/helpers.byn` `format` (`:321`, the `.millis` arm at `:344`) — a unit writes its value through the storage type's signed or unsigned writer (`byn_w_i64` or `byn_w_u64`, as the primitive arm does at `:332`–`:335`), then `" "` and the symbol only when the unit has one (`Cents(50)` is `50`); equality (`:31`) — `unitType` and `uptime` compare as integers — R11, R14, R17
- `src/emitter/cprint/func.byn` `debug` (`:844`, reached from `:838`) — `uptime` writes the D-U9 form; a unit writes its `format` text — R14
- `Map` keys: no change. A unit key hashes through the scalar default of `KeyHash` (`src/emitter/cprint/helpers.byn:186`), since its C type is its storage integer — D-OQ1
- Copy, ownership and drop: no change. A `unitType` or `Uptime` value is a plain scalar copy: `t7StorageParts` gives it no owned storage, so it is never claimed, dropped or released (the `default` arm, `src/emitter/cprint/own.byn:64`, as for `Millis` today); move tracking is by local kind, not type (`src/semantics/ownership.byn:819`–`:824`); and the `.copy(to: alloc)` hint covers only `List`, `Map` and `StrBuf` (`src/semantics/ownership.byn:766`–`:768`) — R1, R14

### Runtime
- `runtime/bayan-rt.c` beside `byn_io_monotonic_nanos` (`:4511`) and `runtime/bayan-rt.h` — new `int64_t byn_uptime_now(void)`, defined only under `#if defined(__linux__)` (`CLOCK_BOOTTIME`), `#elif defined(__APPLE__)` (`mach_continuous_time`, scaled by `mach_timebase_info` read on each call into a local, so there is no shared state to initialize under spec 027 threads, as `t / denom * numer + t % denom * numer / denom`, the split at `:4519`), `#elif defined(_WIN32)` (`QueryInterruptTimePrecise` × 100). No definition on any other target; BYN4003 stops such a build before C — R16
- `runtime/bayan-rt.h` (`:449`) comment on `IoError.timeout` — `Duration after` — R17
- `src/driver/runtime.byn`, `bootstrap/bayan-rt.c`, `bootstrap/bayan-rt.h` — regenerated copies — R16, R17

### Standard library
- `lib/std/time/uptime.byn` (new) — the `std.time` module file with the `Uptime` doc comments and no declarations; the std module list comes from the file paths (`src/semantics/compile.byn:76`), so a declaration-free file still makes `std.time`. `lib/std/time/uptime.test.byn` (new); `src/semantics/stdsource.byn` regenerated — R14, R15

### Driver
- `src/driver/cc.byn` (`:273`, `:290`) — `timeout: Milliseconds(limit)` in T8b — R17
- The other `Millis` names in `src/driver/` (`test.byn`, `goldenprograms.byn`, `mutate.byn`, `nopanic-l018.test.byn`, `diagdocs.byn`, `golden.byn`, `cache.byn`) — renamed in T8b — R17
- The remaining `Millis` names under `src/` outside the driver, from `git grep -nw Millis -- src` on `dev` 9e26b3dbc, all renamed or removed in T8b — R17:
  - `src/semantics/express.byn:1396` (`if name == "Millis"` → `builtinType(.millis)`), removed with `BuiltinKind.millis`;
  - `src/semantics/calls2.byn:355` (the `Millis(n)` comment) and `src/semantics/builtins.byn:76` (the `DetailVariants` comment), reworded to `Duration`;
  - `src/semantics/calls2-t29.test.byn:61`, `:93` (test names and sources that construct `Millis`), rewritten to `Milliseconds` with their expected offsets regenerated from the compiler;
  - `src/parser/spans-t29.test.byn:593` (`timeout(Millis after)` in a parser fixture), rewritten to `timeout(Duration after)` with its span expectations regenerated;
  - `src/driver/runtime.byn:451`, the generated copy of `runtime/bayan-rt.h`, follows the runtime comment change above;
  - the `.millis` arms in `src/semantics/conversions.byn:129`, `src/semantics/express3.byn:555`, `src/semantics/express4.byn:1054`, `src/emitter/cprint/helpers.byn:31`, `:344` and `src/emitter/cprint/common.byn:50`, `:92`.
  T8b runs the R17 grep before its commit; any site it still finds joins this list.

### Not touched
- `src/sabk/`: it has its own SIR, is not fed by the C emitter's bound or lowered trees, and has no clock or `Millis` path.
- `Io.monotonicNanos()` and `Time` (D-OQ2d).

## Data / interfaces
New diagnostics (messages are drafts, fixed in T1):

| Code | Name | Req | Message |
|---|---|---|---|
| BYN2237 | UnitStorageNotInteger | R1 | unit `{0}` needs an integer storage type, not `{1}` |
| BYN2238 | InvalidUnitScale | R2 | unit `{0}`: {1} (`{1}` is one reason: ``the factor `N` is not an integer above 1``, ``the scale does not fit `i64` ``, ``no unit has the symbol `zz` ``, or `the declaration is part of a cycle`) |
| BYN2239 | UnknownUnitSymbol | R4 | no unit has the symbol `{0}` |
| BYN2240 | UnitOnFloatLiteral | R4 | a unit suffix needs an integer literal; help: write `{1}` (the D-U4-ordered finer rewrite from `bindLiteral`, or ``a whole number of `{0}` ``) |
| BYN2241 | DuplicateUnitSymbol | R4, R5 | `{0}` and `{1}` both use the symbol `{2}` (`{1}` may be ``the built-in suffix `f` ``) |
| BYN2242 | MinutesNotMeters | R5 | no unit has the symbol `m`; help: minutes are `min` |
| BYN2243 | RetiredDoubleSuffix | R5 | `d` is not a suffix; help: write `1.0` for a double |
| BYN2244 | UnitFamilyMismatch | R8 | `{0}` is not a coarser unit in the family of `{1}` (reasons per D-U5) |
| BYN4003 | NoSuspendingClock | R16 | target `{0}` has no monotonic clock that counts suspend time |

Existing codes used: BYN0011, BYN2003, BYN2008, BYN2022, BYN2023, BYN2202, BYN2203, BYN2204, BYN2206, BYN2208, BYN2219, BYN2225, BYN2229, BYN2760, BYN6002. BYN3203 and BYN3205 go from `plan` to `live`. BYN3204 stays live for distinct types, unchanged.

Surface after 028, in Bayān syntax:

```bayan
import std.time

unit Grams(g): i64
unit Kilograms(kg) = 1000 g

public Uptime deadline(Uptime start, Seconds after) => start + after
public Duration elapsed(Uptime end, from Uptime start) => end - start

void main() uses clock {
    let start = Uptime.now()
    let parcel: Grams = 2kg + 500g
    let wait = elapsed(Uptime.now(), from: start).ceiling<Seconds>()
}
```

- A unit value has the size and C type of its storage. `Duration` is `Nanoseconds`, `i64`. `Uptime` is an `int64_t` of nanoseconds with no conversion to or from integers in the language.
- `Io.run(…, timeout: Duration?)`; `IoError.timeout(Duration after, string stdout, string stderr)`. The runtime keeps `int64_t timeout_ms` (pending ND2); the emitter converts per D-U8 and builds the payload from the `Duration` the caller passed, as it does today.

## Order
- T1 spec revision, code allocation and explain-page stubs (no code).
- T2 parser: `unit` declarations with visibility, BYN2022 for compound forms; the `µ`/`μ` lex case.
- T3 checker: unit table, two-pass declaration resolution and declaration diagnostics (R1, R2, R5 at the declaration), and the `core` time units with `type Duration = Nanoseconds` (R12, R13 source; formerly T6), so every later test can use `s`, `ms` and `Duration`. Regenerate the bootstrap after T3.
- T4 literal suffixes and bare literals (R4, R5, R6), then conversions, operators, rounding methods with their emitter helpers, wrap and unwrap (R7–R10).
- T5 formatting and debug output of units (R11).
- T6 the R12 and R13 `run/` cases (`core-time-units`, `duration-pure`), once T4 and T5 give them literals and formatting.
- T7 `Uptime`, `std.time`, its debug output, runtime clocks, BYN4003, runtime version 5 (R14–R16). Regenerate the bootstrap.
- T8a bridge: `Io.run(timeout:)` and `IoError.timeout` take `Duration` (`builtins.byn`, `compile.byn:937`–`:945`, the `expr.byn:551` helper); temporary `Millis` → `Duration` and `Duration?` conversion. Regenerate the bootstrap.
- T8b: `Millis` removed from compiler, tests, `docs/bayan-spec.md`, `docs/diagnostics/BYN1043.md` and spec 023; FREEZE and DIVERGENCES rows (D-U3). Regenerate the bootstrap (`bootstrap/bayan.c` and `bootstrap/bayan-rt.h` name `Millis` today).

Spec 027 can use `Duration` once T4 lands and `Uptime` once T7 lands. It needs neither T8a nor T8b. T8b must land before 0.5.0 is cut.

## Testing
- `diag/` cases, one per new code and per acceptance case: `unit-storage-float` (BYN2237), `unit-scale-zero`, `unit-scale-one`, `unit-scale-overflow`, `unit-scale-unknown`, `unit-scale-cycle` (BYN2238), `unit-symbol-unknown` (BYN2239), `unit-float-literal` (BYN2240, help `1500ms`), `unit-float-literal-base` (BYN2240 on `1.5ns`, the whole-number help), `unit-symbol-duplicate`, `unit-symbol-core-s`, `unit-symbol-core-micro` (`unit X(µs): i64`), `unit-symbol-builtin-f` (`unit Feet(f): i64`) and `unit-symbol-import-pt` (two imported modules with `pt`) (BYN2241), `unit-suffix-m` (BYN2242), `unit-suffix-d` and `unit-suffix-float-d` (`1.5d`) (BYN2243), `unit-floor-other-family`, `unit-floor-same-unit`, `unit-floor-finer` and `unit-floor-non-unit-target` (BYN2244), `unit-floor-no-type-argument` (BYN2023), `unit-private-import` (a private unit's symbol from an import, BYN2239). BYN4003 has no `diag/` case, since a `diag/` case passes no flags: its golden is a `cli/` case, `tests/cases/cli/<class>/UptimeOnWasm32/args` with `--target wasm32` and an `expected.stderr` holding `BYN4003`, the layout of `tests/cases/cli/SelfhostDefaultT12Tests/ABadTargetIsRefused/`; `scripts/ci/diagnostic-codes.test.sh` reads every non-`.byn` file under `tests/cases` (`:78`), so it counts. Plus one case for each existing code in R1–R17: `unit-lowercase` BYN2008, `unit-compound` BYN2022, `unit-hex` BYN0011, `unit-literal-range` BYN2203, `unit-bare-zero`, `unit-bare-nosymbol`, `unit-bare-plus` (`2s + 500`), `unit-bare-compare` (`2s == 0`) and `unit-bare-plus-assign` (`t += 1`) BYN3203, `unit-coarser`, `unit-plus-assign-finer` and `unit-wrap-finer` (`Seconds(1500ms)`) BYN3205, `unit-mixed-family`, `unit-ops-rejected` (`2s * 3s`, `10s / 2`, `10s % 3s`, `t *= 2`) and `unit-negate-unsigned` (`-Packets(1)`) BYN2208, `unit-assign-other-family` (`let w: Grams = 5s`) BYN2202, `unit-cast-other-family`, `unit-unwrap-width` (`i32(Seconds(42))`), `uptime-wrap` (`Uptime(0)`) and `uptime-unwrap` (`i64(t)`) BYN2206, `unit-const-overflow` BYN2204, `unit-const-array` BYN2229, `uptime-const` BYN2219, `uptime-format` BYN2225, `uptime-no-clock` BYN6002, `uptime-no-import` (`Uptime` and `Uptime.now()` without `import std.time`, the unknown-type and undefined-name errors), `uptime-plus-uptime`, `duration-plus-uptime` and `uptime-plus-grams` (`start + 5g`) BYN2208, `uptime-bare` BYN3203, `uptime-map-key` BYN2760, `millis-unknown` (the unknown-type error).
- `run/` cases, one per runtime feature: `unit-arithmetic` (R7, R10 values, `3 * 250ms` and `250ms * 3`), `unit-keyword-identifier` (R1: the three declarations and `let unit = 1`), `unit-rounding` (the R8 table with negatives, plus `u64` and odd-factor cases for the helpers), `unit-wrap` (R9, `Milliseconds(2s)`), `unit-format` (R11, `Cents(50)` with no trailing space, a `u64` unit above `i64` max), `unit-import` (a `public unit` used from another module), `core-time-units` (R12), `duration-pure` (R13), `unit-map-const` (D-OQ1), `uptime-arithmetic` (R14, R15), `uptime-debug` (D-U9: the output matches `Uptime(<digits> ns)`), and the trap cases with `.exitcode`: `unit-widen-overflow` (R7), `unit-divide-zero` (R10) and `uptime-overflow` (R15, `Uptime.now() + Nanoseconds(9_223_372_036_854_775_807)`). The `io-run-timeout-*` and `io-error-signaled-timeout` cases pass `5s` and print `after` (R17); `io-run-timeout-sub-ms` passes `500us` and shows the run is limited, not unbounded (D-U8).
- Per-platform clock: a new `runtime/tests/uptime-clock.c`, run by `runtime/tests/run.sh`. It reads the platform clock, then `byn_uptime_now()`, then the clock again, and checks the bracket after scaling. That shows which clock is read on Linux, macOS and Windows (R16). It also checks that 10 000 readings never decrease. On macOS it checks the scaling with a timebase of 125/3 against a 128-bit reference.
- Checker unit tests beside the code (`src/semantics/conversions-t29.test.byn` and the like) for scale products, the D-U4 order, the common unit, `u64` scales, and `rounded` ties away from zero.
- Rename churn (T8b): the 56 files under `tests/` that name `Millis` are regenerated in update mode (`BAYAN_UPDATE=1`) and reviewed as a diff. `tests/cases/diag/millis-bare-literal.*` (it reports BYN2202, not BYN3204) is replaced by `millis-unknown`; BYN3204 keeps its golden `tests/cases/diag/distinct-bare-literal.diag`. Frozen files: D-U3. `scripts/ci/freeze-check.sh` must pass with no `pending` row. `scripts/ci/bootstrap-check.sh` must pass after T3, T7, T8a and T8b.
- Every code: `scripts/ci/diagnostic-codes.test.sh` (page and golden per live code).
- R17 check: `git grep -w Millis -- src lib tests runtime bootstrap docs/bayan-spec.md docs/diagnostics docs/specs/023-spec-catch-up/023-spec.md` is empty after T8b. History and changelog entries are not searched.
- The law candidates are left to the laws step. The `unit-rounding` and `uptime-arithmetic` cases are their seeds.

## Risks & mitigations
- `CLOCK_BOOTTIME` may be hidden under `_POSIX_C_SOURCE 200809L` (`runtime/bayan-rt.c:6`) with musl or glibc headers. T7 checks it first. If it is hidden, define it as the Linux ABI value 7 under `__linux__`, with a comment.
- `QueryInterruptTimePrecise` may need an extra import library under zig's mingw (`x86_64-windows-gnu`). T7 links a probe first. If it fails, the call is resolved at run time with `LoadLibraryExW` and `GetProcAddress` from the DLL the probe identifies, and a failed lookup panics, as `byn_os_random` does (`runtime/bayan-rt.c:2348`–`:2351`); it is never replaced by `QueryPerformanceCounter` (R16).
- A declaration-free `std` file might not load as a module after all. T7 checks `import std.time` first. If it does not load, T7 fixes the loader to accept it; it does not add API to `std.time`.
- `µ` (U+00B5) may be normalized or rejected by identifier rules before the checker sees it. T2 checks this with a lex case for both code points and fixes the lexer if needed.
- Spec 027 or another plan may take BYN2237–BYN2244 or BYN4003 first. T1 re-checks the numbers before merge (D-OQ2a).
- The bridge conversion in T8a could outlive T8b. T8b deletes it in the same commit as `BuiltinKind.millis`, and the R17 grep fails if `Millis` remains.
- Mixed-scale arithmetic can overflow where the plain integers would not (`h` to `ns`). R7 and R10 trap in every mode, and the `unit-widen-overflow` case pins it.

## Needs decision
- **ND1 Unordered members of a branching family (review finding 1).** R2 allows `unit Two(tw) = 2 b` and `unit Three(th) = 3 b`; R7 and R10 assume an exact integer factor between any two members, and there is none from `Three` to `Two`. Options:
  - (a) Unordered members do not convert or combine: implicit conversion is BYN2202, `+`/`-`/comparison/`/` is BYN2208, `U(x)` is BYN3205, and rounding between them is BYN2244. Each converts to the base, or any common finer member, and they combine there. **Recommended**: no spec text changes, every factor stays exact, and admitting a rule later breaks no program.
  - (b) Unordered members combine at the coarsest member whose scale divides both (the base at worst). Wider, but the result type is a third unit neither operand names, against R10's "return that finer unit type".
  - (c) Reject branching families at the declaration (a new BYN2238 reason). Simplest, but changes R2.
  The plan follows (a) until this is settled.
- **ND2 `Io.run` timeout ABI (review finding 4).** Options:
  - (a) Keep `int64_t timeout_ms` and convert per D-U8 (ceiling for positive, `0` for zero or negative, `-1` for null). **Recommended**: the Windows wait is a millisecond `DWORD` (`runtime/bayan-rt.c:4022`) and the POSIX loop turns milliseconds back into a nanosecond deadline (`:4392`–`:4395`), so a nanosecond ABI gains no precision at the OS call, and the runtime C stays as it is.
  - (b) Change `byn_io_run_with` to `int64_t timeout_ns` in the same runtime version 5 bump, with each platform rounding up to its wait unit. One rounding point in the runtime instead of the emitter, at the cost of runtime changes on three platforms.
  The plan follows (a) until this is settled.

## Review response (Neon, 2026-11-27)
1. needs decision: non-divisible scales in branching families are real; ND1 lists the options, and D-U4 with ND1 (a) keeps every factor exact meanwhile.
2. fixed: rounding helpers per storage type with quotient and remainder and an overflow-free tie test (Emitter, `expr.byn`); `u64` and odd factors in `unit-rounding`.
3. fixed: `as: .debug` exists (`src/semantics/express4.byn:886`, `src/emitter/cprint/func.byn:838`); D-U9 adds `Uptime` debug output in `t35WhyNotDebugFormattable` and `func.byn` `debug`, with `run/uptime-debug`.
4. needs decision: the sub-millisecond and non-positive cases are real (the runtime treats `-1` as no timeout and `>= 0` as a limit, `runtime/bayan-rt.c:4392`); D-U8 defines them now and ND2 picks the ABI.
5. fixed: BYN4003 uses an allowlist of `linux`, `macos`, `windows` and `byn_uptime_now` exists only under `__linux__`, `__APPLE__`, `_WIN32`; targets are free-form `os-arch` names (`src/semantics/compile.byn:83`–`:89`), so a blocklist would miss them.
6. fixed: `UnitDecl` carries `Modifiers` (`src/parser/nodes.byn:459` pattern); symbols are looked up per file from `core`, the module and public units of imports (`src/semantics/ctx.byn:65`); imported clashes are BYN2241 at the import; types resolve through `checkVisible` (`src/semantics/typeresolve.byn:475`).
7. fixed: `u`, `l`, `ul`, `f`, `dec` are rejected as unit symbols with BYN2241 at the declaration (`f` is taken at `src/semantics/express.byn:886`); `diag/unit-symbol-builtin-f`.
8. fixed: right that `convert` alone misses it: `common` finds no type for `2s + 500` and `bindBinary` reports BYN2208 first (`src/semantics/express3.byn:389`); D-U7 adds the check in `bindBinary` and the compound path (`src/semantics/calls4.byn:350`), with three new `diag/` cases.
9. fixed: Approach now says erasure is in `cprint`, not before lowering; the checked operators go through `builtin.byn` `binary` (`src/emitter/cprint/builtin.byn:527` tests `isInteger`, so units need the arm), equality, format, debug and `const` are listed; `Map` hashing needs no change, the scalar default covers it (`src/emitter/cprint/helpers.byn:186`); copy, ownership and drop need no change, since a unit owns no storage (`src/emitter/cprint/own.byn:64`) and move tracking is by local kind (`src/semantics/ownership.byn:819`); and there is no SIR step on the C path.
10. fixed: the audit finds no `Millis?` variable and no `after` reader (`src/driver/cc.byn:274`, `src/driver/mutate.byn:797`), but the optional arm lifts only `.widen` (`src/semantics/conversions.byn:22`), so T8a lifts the new conversion into `Duration?`; T8b regenerates the bootstrap.
11. fixed: `Uptime` joins the receiver names at `src/semantics/express.byn:1386`–`:1396`, gated on `import std.time`; `diag/uptime-no-import`.
12. fixed: the `core` time units and `Duration` move into T3, before the literal and operator work; T6 keeps only the R12 and R13 run cases.
13. fixed: BYN2240's help is computed from the family, with a whole-number help at the base; suffix precedence on integer and float literals is spelled out in `bindLiteral`.
14. fixed: D-U5 gives same unit, finer unit, non-unit target (BYN2244), missing type argument (BYN2023) and non-unit receiver (BYN2003), with `diag/` cases.
15. fixed: D-U6 settles `Seconds(1500ms)` (BYN3205), `Milliseconds(2s)` (conversion), `i32(Seconds(42))`, `Uptime(0)` and `i64(t)` (BYN2206), with `diag/` and `run/` cases.
16. fixed: unit format goes through the signed or unsigned writer (`src/emitter/cprint/helpers.byn:332`–`:335`) and adds `" "` and the symbol only when present.
17. fixed: the lexer already decodes non-ASCII suffix starts (`src/lexer/lexer.byn:324`–`:329`), so no fix is scheduled unless T2's lex case fails; `µs`/`μs` normalize to `us` for BYN2241, with `diag/unit-symbol-core-micro`.
18. fixed: two passes per module with a depth-first cycle check, `u64` scales checked with the big-integer helpers against the storage maximum.
19. fixed: BYN4003's golden is a `cli/` case, which `scripts/ci/diagnostic-codes.test.sh:78` already reads; BYN3204 keeps `tests/cases/diag/distinct-bare-literal.diag`, and `millis-bare-literal.diag` reports BYN2202, not BYN3204.
20. fixed: no helper is added to `std.time` (module names come from file paths, `src/semantics/compile.byn:76`; else T7 fixes the loader); `mach_timebase_info` is read per call, so nothing needs a once-init; a failed Windows lookup panics as at `runtime/bayan-rt.c:2351`.
21. fixed: the listed `diag/` and `run/` cases are added, and the R17 grep covers `bootstrap`, `docs/diagnostics` and spec 023 (`docs/diagnostics/BYN1043.md:15` names `Millis`).
22. fixed: the bullet now says `runtime/bayan-rt.h` (`src/driver/runtime.byn:451` copies `runtime/bayan-rt.h:449`).
23. fixed: BYN2238 has one `{0}`/`{1}` form, the storage type inside the reason text; `compile.byn:937`–`:945` is tagged T8a.
24. fixed: D-OQ2a now places BYN3203 and BYN3205 in 3xxx; Coverage check no longer claims full coverage.

## Coverage check
| R | Covered by |
|---|---|
| R1 | Parser (`UnitDecl` with `Modifiers`), Semantics (`unitType`, BYN2237, BYN2008), Emitter (`common.byn`, `builtin.byn`); Testing `unit-storage-float`, `unit-lowercase`, `unit-keyword-identifier`, `unit-import` |
| R2 | Semantics (unit table, two-pass resolution, `u64` scales, BYN2238); Testing `unit-scale-*`. Partly open: unordered members of branching families (ND1) |
| R3 | Parser (`parseUnit`), Semantics (BYN2022); Testing `unit-compound` |
| R4 | Lexer, Semantics `bindLiteral` precedence (BYN2239, BYN2240, BYN2203, BYN0011), reserved built-in suffixes (BYN2241), per-file symbol visibility; Testing |
| R5 | Semantics `bindLiteral` and declaration checks (BYN2241 at declaration and import, BYN2242, BYN2243, `µs`/`μs`); Testing |
| R6 | Semantics `convert`, `bindBinary`, compound assignment (BYN3203, D-U7); Testing `unit-bare-*` |
| R7 | Semantics `conversions.byn`, `fold` (BYN3205, BYN2202, BYN2204), Emitter checked multiply; Testing `unit-arithmetic`, `unit-widen-overflow`, `unit-assign-other-family`. Partly open: ND1 |
| R8 | Semantics `bindBuiltinMethodCall` (D-U5, BYN2244, BYN2023), Emitter rounding helpers; Testing `unit-rounding`, `unit-floor-*`. Partly open: ND1 |
| R9 | Semantics `bindConstruction`, `bindCast` (D-U6, BYN2206, BYN3205); Testing `unit-wrap`, `unit-wrap-finer`, `unit-unwrap-width` |
| R10 | Semantics `bindBinary`, `bindUnary`, `bindAssign` (BYN2208, BYN3205), Emitter checked operators; Testing `unit-arithmetic`, `unit-divide-zero`, `unit-negate-unsigned`, `unit-ops-rejected`. Partly open: ND1 |
| R11 | Semantics `bindInterpolated`, Emitter `helpers.byn` `format` (signed and unsigned, no symbol); Testing `unit-format` |
| R12 | Semantics `builtins.byn` `core` units source (T3); Testing `core-time-units` |
| R13 | Semantics `builtins.byn` (`type Duration = Nanoseconds`), `effects.byn`; Testing `duration-pure` |
| R14 | Semantics `BuiltinKind.uptime`, receiver and type resolution gated on `std.time`, `uptimeNow`, `effects.byn`, BYN2225, debug (D-U9); Standard library `lib/std/time/`; Testing `uptime-*` |
| R15 | Semantics `bindBinary` for `Uptime` (BYN2208, BYN3203), Emitter checked operators; Testing `uptime-arithmetic`, `uptime-overflow`, `uptime-plus-grams` |
| R16 | Runtime `byn_uptime_now` under the three platform guards, Semantics BYN4003 allowlist; Testing `runtime/tests/uptime-clock.c`, `cli/` `UptimeOnWasm32` |
| R17 | Order T8a, T8b; Decisions D-U2, D-U3, D-U8, D-OQ2c; Spec and documents (`docs/bayan-spec.md` `Millis` sites incl. `:2181`, `:2356`, `:2684`; `docs/diagnostics/BYN1043.md`); Testing rename churn, `io-run-timeout-sub-ms` and the R17 grep. Partly open: the timeout ABI (ND2) |

R2, R7, R8, R10 and R17 are partly open until ND1 and ND2 are decided; the plan follows the recommended option of each meanwhile. Every other R# is covered.
