# 028 — Plan

Spec: ./028-spec.md

Status: draft
Release: unscheduled (planned for 0.5.0, before spec 027 phase 1 uses `Duration` and `Uptime`)
Sources: `./028-spec.md` (owner decisions D1–D8, 2026-11-23); `docs/bayan-spec.md` §3.4, §3.5, §16.5; `docs/revisions/0017-addendum-a2-diagnostic-codes.md`; `docs/DIAGNOSTICS.md`

## Approach
Units are a checker feature. They are erased before lowering: a unit value is its storage integer, and a conversion is a multiply by a constant scale. The emitter sees `int64_t` (or the storage type) and a checked multiply, except in formatting, where it appends the symbol.

The work lands in this order (details under Order):

1. Spec text first, as a new revision, so the code is built from the document (`docs/revisions/README.md`).
2. `unit` declarations in the parser, then unit types, families and scales in the checker.
3. Unit literals, conversions, operators, rounding methods and formatting.
4. The six time units and `type Duration = Nanoseconds` as `core` source, beside the existing built-in sources in `src/semantics/builtins.byn`.
5. `Uptime` as a built-in type of `std.time`, its runtime clock per platform, and the target check.
6. The `Millis` retirement in two commits, because the compiler's own source names `Millis` (`src/driver/cc.byn:273`, `:290`) and the bootstrap must compile each commit with the previous one (`bootstrap/README.md`).

`Io.monotonicNanos()` and the built-in `Time` do not change.

## Decisions
- **D-OQ1 Units as `Map` keys and `const` values.** Chosen: every unit type, `Duration` included, is a valid `Map` key and a valid module-level scalar `const` value. `Uptime` is neither. A `const` array of a unit type stays BYN2229.
  - Rejected: making `Uptime` a `Map` key or a `const`. An `Uptime` reading has no meaning across runs, and its only source, `Uptime.now()`, is not a constant (BYN2219). Allowing it later breaks no program; withdrawing it would.
  - Why units are allowed: they are integer-backed with integer `==` (R1, R10), which is the rule §3.5 already applies to integer types. R7's own case `const big: Nanoseconds = 9_223_372_037s` (BYN2204) needs a unit `const`. `const` arrays stay closed because the `.rodata` rule (`docs/bayan-spec.md:300`) names number types, and widening it is not needed for 027.
  - Spec text change: the §3.5 key list (`docs/bayan-spec.md:298`) adds "a unit type (§3.4)" after "an integer type", and says that `Uptime` is not a key. §3.4 gains one line: a module-level `const` may hold a unit value given by a unit literal or a constant unit expression.
- **D-OQ2a Diagnostic codes.** Chosen: the new codes take the next free numbers in the semantics range after BYN2236 (2000–3999 semantics in `AGENTS.md`; units are BYN2xxx in addendum A2), and the target check takes the next free backend number after BYN4002. Each was checked free in `docs/DIAGNOSTICS.md`, `docs/diagnostics-allocated.txt`, `src/semantics/codes.byn` and every spec under `docs/specs/` (spec 027 allocates none). The table is under Data / interfaces.
  - Rejected: 19xx codes for `MinutesNotMeters` and `RetiredDoubleSuffix`, as the "spelling (19xx)" note in `docs/specs/021-std-time/021-spec.md:256` suggests. Both need to know which units are visible, which the parser does not know. Both are errors, not the x900 lints of addendum A2.
  - BYN2231 and BYN2232 are unused gaps. They are left alone, because the brief asks for the next number after the last code in the area.
  - The numbers are provisional until merge. The T1 spec revision re-checks that they are still free and records them in `docs/diagnostics-allocated.txt`.
- **D-OQ2b R14 has no new code.** Chosen: `string(t)` and `$"{t}"` on `Uptime` report the existing BYN2225 `NotFormattable`. Rejected: a new `UptimeNotDisplayable` code. R14 allows the existing error, and BYN2225 already says what is wrong.
- **D-OQ2c `AbbreviatedUnitName` is not added.** Chosen: under R17, `Millis` gets the ordinary unknown-type error. Rejected: keeping the planned lint from `docs/bayan-spec.md:2356`. R17 asks for the unknown-type error, and a lint that names `Millis` keeps the name alive in the compiler.
- **D-OQ2d `Io.monotonicNanos()` and `Time` stay unchanged during 028.** Chosen: both keep their signatures, their `clock` effect (`src/semantics/effects.byn:768`) and their runtime (`byn_io_monotonic_nanos`, `byn_time_now` in `runtime/bayan-rt.c`). Rejected: making `Io.monotonicNanos()` return `Uptime` now. That breaks its call sites in the compiler for no 027 need. Retiring it belongs with spec 021. `FixedClock` vs `FakeClock` stays out of scope, as the spec says.
- **D-U1 `Uptime` is a compiler built-in type, not std source.** Chosen: a new `BuiltinKind.uptime` in `src/semantics/types.byn`, resolved by name only in a file that imports `std.time`. Rejected: `public struct Uptime { i64 nanos }` in `lib/std/time/`. `Uptime` needs `+`, `-` and ordering, and user operator overloading is not in 0.4 (`docs/bayan-spec.md:1109`).
- **D-U2 The `Millis` retirement uses a bridge commit.** Chosen: T8a makes `Io.run(timeout:)` take `Duration?` and lets `Millis` convert implicitly to `Duration` (×1 000 000) inside the compiler. T8b then rewrites `src/driver/cc.byn` to `Milliseconds(limit)` and deletes `Millis` everywhere. No release ships T8a alone, and the end state has no alias (D1).
  - Rejected: one commit. The previous bootstrap would type-check the new `cc.byn` against its own `Io.run(timeout: Millis?)` and fail `scripts/ci/bootstrap-check.sh`.
- **D-U3 Frozen cases touched by the rename.** Chosen: each frozen expected file that changes (22 `Millis` rows in `tests/cases/FREEZE.tsv`) gets its row rewritten by `scripts/ci/freeze-check.sh --write` in the same commit. Each such case gets one `tests/cases/DIVERGENCES.tsv` row: the case, a question number opened in `docs/bayan-questions.md`, right `driver`, and the reason "spec 028 R17: `Millis` retired". No row is `pending`.
  - Rejected: deleting the frozen cases. They still cover `Io.run` and the error payload once the type name changes.

## Tech / dependencies
- No new tool or library. Both build paths stay as they are: the C emitter with zig cc, and the bootstrap C.
- New platform calls in `runtime/bayan-rt.c`:
  - Linux: `clock_gettime(CLOCK_BOOTTIME, …)`.
  - macOS: `mach_continuous_time` and `mach_timebase_info` from `<mach/mach_time.h>`.
  - Windows: `QueryInterruptTimePrecise` from `<realtimeapiset.h>`.
  - wasm32 gets no `Uptime` clock and no fallback.
- `BYN_RUNTIME_VERSION` goes from 4 to 5 (`runtime/bayan-rt.h:10`). `src/driver/runtime.byn` is regenerated (it is generated from `runtime/`), and the bootstrap copies follow `bootstrap/README.md`.
- Spec 027 depends on T2–T7 here (Order).

## Changes by area
### Spec and documents
- `docs/revisions/` new revision (number taken at merge, after 0025 of plan 026) — §3.4 built for `unit` and suffixes, §3.5 key list, §16.5 `Duration` and `Uptime` built, new codes — R1–R16, D-OQ1
- `docs/bayan-spec.md` §3.4 (`:266`), §3.5 (`:298`), §16.5 — status lines and the D-OQ1 text; the `Millis` sites listed in R17 (`:271`, `:281`, `:381`, `:484`, `:1417`, `:1989`, `:1994`, `:1996`) change in T8b — R1–R17
- `docs/specs/023-spec-catch-up/023-spec.md` `:72`, `:158` — `Millis` → `Milliseconds` in T8b — R17
- `docs/diagnostics/BYN2237.md` … `BYN2244.md`, `BYN3203.md`, `BYN3205.md`, `BYN4003.md` (all new) — explain pages; `docs/DIAGNOSTICS.md` regenerated by `scripts/docs/gen-diagnostics.sh` — R1, R2, R4–R8, R16
- `docs/STATUS.md`, `CHANGELOG.md` (breaking: `Millis` removed, `Io.run(timeout:)` takes `Duration`) — R17

### Lexer
- `src/lexer/lexer.byn` numeric suffix scan (`:792`–`:821`) — no change for ASCII symbols; T2 confirms that `µ` (U+00B5) and `μ` (U+03BC) pass `isIdentifierStartAt` as suffix starts. BYN0011 (`suffixOnHexOrBinary`, `:814`) already covers hex and binary — R4, R5

### Parser
- `src/parser/nodes.byn` — new `UnitDecl` (name, symbol span or null, storage type or scale `N` and right-hand symbol, or a compound right-hand side kept for BYN2022) and new `Decl.unitDecl(Owned<UnitDecl> node)` in `union Decl` (`:190`) — R1, R2, R3
- `src/parser/decls.byn` declaration dispatch (`:175`–`:189`, the `typeAliasDecl` and `effectDecl` arms) — contextual `unit` at top level when followed by a name; new `parseUnit` in `src/parser/decls2.byn` — R1, R2, R3
- `src/parser/dump.byn`, `src/parser/spans.byn` (`:290` area) — `unitDecl` arms — R1

### Semantics
- `src/semantics/types.byn` `TypeKind` (`:24`) — new `unitType`; `BuiltinKind` (`:92`–`:103`) — new `uptime`, `millis` removed in T8b (`:102`, `:188`, `:638`); `isValidKeyInner` default branch (`:867`) — unit types are keys — R1, R14, R17, D-OQ1
- `src/semantics/ctx.byn` — new unit table: family root, scale from the base, storage type, symbol — R1, R2
- `src/semantics/binder.byn` declaration switches (`case .typeAliasDecl` at `:587`, `:652`) and `src/semantics/compile.byn` (`:1110`, `:1695`, `:1933`) — `unitDecl` arms; BYN2008 casing, BYN2237 storage, BYN2238 scale and cycles, BYN2241 duplicate symbols (the `core` symbols included), BYN2022 for compound declarations (`.unsupported`) — R1, R2, R3, R5
- `src/semantics/express.byn` `bindLiteral` (`:874`–`:900`) — replace the `.unsupported` report for an unknown suffix with a unit lookup: unit type, `µs`/`μs` as `us`, BYN2239, BYN2240 for float literals, BYN2242 for `m`, BYN2243 for `d`, BYN2203 out of range — R4, R5
- `src/semantics/express.byn` `convert` (`:273`, the BYN3204 site) — BYN3203 with the `0g` / `Cents(0)` fix-it — R6, R15
- `src/semantics/conversions.byn` `implicit` (`:11`), `explicit` (`:122`), `common` (`:135`) — finer-only implicit conversion, BYN3205, the common unit for mixed scales, BYN2206 for unrelated families — R7, R9, R10, R13
- `src/semantics/express3.byn` `bindBinary` (`:171`), `bindUnary` (`:110` area), `fold` (`:500`, BYN2204), `bindCast` (`:912`) — unit and `Uptime` operators, BYN2208, constant overflow, `S(u)` unwrap — R7, R9, R10, R15
- `src/semantics/calls4.byn` `bindAssign` (`:340`) — `+=`/`-=` with a same-or-coarser right side; `*=` is BYN2208 — R10
- `src/semantics/calls2.byn` `bindConstruction` (`:356`, today's `Millis(n)` arm) — `U(raw)` for units; `bindBuiltinMethodCall` (`:724`) — `.floor<U>()`, `.ceiling<U>()`, `.rounded<U>()` with BYN2244, and `Uptime.now()` — R8, R9, R14
- `src/semantics/express4.byn` `bindInterpolated` (`:899`) and the `string(…)` path — units format; `Uptime` is BYN2225 — R11, R14
- `src/semantics/builtins.byn` — new `core` units source (the six units and `type Duration = Nanoseconds`), parsed like `ioErrorSource` (`:60`); `Uptime.now` registered like `Time.now` (`:586`–`:593`); `runParameters` timeout (`:287`) and the `IoError` source `timeout` payload become `Duration` in T8a — R12, R13, R14, R17
- `src/semantics/symbols.byn` — new `uptimeNow` beside `timeNow` (`:115`) — R14
- `src/semantics/effects.byn` (`:768`) — `.uptimeNow` requires `clock`; unit and `Uptime` operators require nothing — R14, R15
- `src/semantics/typeresolve.byn` (`:394`–`:401`, `:1041`) — `Uptime` when the file imports `std.time`; `"Millis"` removed in T8b — R14, R17
- `src/semantics/compile.byn` (`:937`–`:945`) — the built-in payload type `Millis` becomes `Duration` — R17
- `src/semantics/compile.byn` `hostTargetSplit` (`:83`), `CompilationOptions.target` — BYN4003 when `Uptime.now()` is bound and the target is `wasm32` — R16
- `src/semantics/codes.byn` — the codes in Data / interfaces, plus BYN3203 and BYN3205 — R1–R8, R16

### Emitter
- `src/emitter/cprint/common.byn` (`:50`, `:92`) — a unit type and `Uptime` are their storage C type; the `.millis` arms go in T8b — R1, R14, R17
- `src/emitter/cprint/helpers.byn` `format` (`:321`, the `.millis` arm at `:344`) and equality (`:31`) — value, one space, symbol — R11, R17
- `src/emitter/cprint/expr.byn` (`:695`, `:718` area) — `.uptimeNow` emits `byn_uptime_now()`; conversions emit the checked multiply that already traps on overflow — R7, R10, R14

### Runtime
- `runtime/bayan-rt.c` beside `byn_io_monotonic_nanos` (`:4511`) and `runtime/bayan-rt.h` — new `int64_t byn_uptime_now(void)`: `CLOCK_BOOTTIME`; `mach_continuous_time` × numer / denom split as `t / denom * numer + t % denom * numer / denom` (the pattern at `:4518`); `QueryInterruptTimePrecise` × 100. No definition under `__wasi__` — R16
- `runtime/bayan-rt.h` (`:449`) comment on `IoError.timeout` — `Duration after` — R17
- `src/driver/runtime.byn`, `bootstrap/bayan-rt.c`, `bootstrap/bayan-rt.h` — regenerated copies — R16

### Standard library
- `lib/std/time/uptime.byn` (new) — the `std.time` module file with the `Uptime` doc comments, so that `import std.time` resolves; `lib/std/time/uptime.test.byn` (new); `src/semantics/stdsource.byn` regenerated — R14, R15

### Driver
- `src/driver/cc.byn` (`:273`, `:290`) — `timeout: Milliseconds(limit)` in T8b — R17
- The other `Millis` names in `src/driver/` (`test.byn`, `goldenprograms.byn`, `mutate.byn`, `nopanic-l018.test.byn`, `diagdocs.byn`, `golden.byn`, `cache.byn`) — renamed in T8b — R17

### Not touched
- `src/sabk/`: it consumes SIR, not bound trees, and has no clock or `Millis` path.
- `Io.monotonicNanos()` and `Time` (D-OQ2d).

## Data / interfaces
New diagnostics (messages are drafts, fixed in T1):

| Code | Name | Req | Message |
|---|---|---|---|
| BYN2237 | UnitStorageNotInteger | R1 | unit `{0}` needs an integer storage type, not `{1}` |
| BYN2238 | InvalidUnitScale | R2 | unit `{0}`: {1} (reason: factor not an integer above 1, scale does not fit `{2}`, unknown symbol, or cycle) |
| BYN2239 | UnknownUnitSymbol | R4 | no unit has the symbol `{0}` |
| BYN2240 | UnitOnFloatLiteral | R4 | a unit suffix needs an integer literal; help: write `1500ms` |
| BYN2241 | DuplicateUnitSymbol | R5 | `{0}` and `{1}` both use the symbol `{2}` |
| BYN2242 | MinutesNotMeters | R5 | no unit has the symbol `m`; help: minutes are `min` |
| BYN2243 | RetiredDoubleSuffix | R5 | `d` is not a suffix; help: write `1.0` for a double |
| BYN2244 | UnitFamilyMismatch | R8 | `{0}` is not in the family of `{1}` |
| BYN4003 | NoSuspendingClock | R16 | target `{0}` has no monotonic clock that counts suspend time |

Existing codes used: BYN0011, BYN2008, BYN2022, BYN2202, BYN2203, BYN2204, BYN2206, BYN2208, BYN2219, BYN2225, BYN2229, BYN2760, BYN6002. BYN3203 and BYN3205 go from `plan` to `live`.

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
- `Io.run(…, timeout: Duration?)`; `IoError.timeout(Duration after, string stdout, string stderr)`. The runtime keeps `timeout_ms`. The emitter passes `after / 1 000 000`, and builds the payload from the timeout the caller passed, as it does today.

## Order
- T1 spec revision, code allocation and explain-page stubs (no code).
- T2 parser: `unit` declarations, BYN2022 for compound forms.
- T3 checker: unit table, declaration diagnostics, literal suffixes (R1, R2, R4, R5, R6).
- T4 conversions, operators, rounding methods, wrap and unwrap (R7–R10).
- T5 formatting (R11).
- T6 `core` time units and `Duration` (R12, R13). Regenerate the bootstrap after T6.
- T7 `Uptime`, `std.time`, runtime clocks, BYN4003, runtime version 5 (R14–R16). Regenerate the bootstrap.
- T8a bridge: `Io.run(timeout:)` and `IoError.timeout` take `Duration`; temporary `Millis` → `Duration` conversion. Regenerate the bootstrap.
- T8b: `Millis` removed from compiler, tests, `docs/bayan-spec.md` and spec 023; FREEZE and DIVERGENCES rows (D-U3).

Spec 027 can use `Duration` once T6 lands and `Uptime` once T7 lands. It needs neither T8a nor T8b. T8b must land before 0.5.0 is cut.

## Testing
- `diag/` cases, one per new code and per acceptance case: `unit-storage-float` (BYN2237), `unit-scale-zero`, `unit-scale-one`, `unit-scale-overflow`, `unit-scale-unknown`, `unit-scale-cycle` (BYN2238), `unit-symbol-unknown` (BYN2239), `unit-float-literal` (BYN2240, help `1500ms`), `unit-symbol-duplicate` and `unit-symbol-core-s` (BYN2241), `unit-suffix-m` (BYN2242), `unit-suffix-d` (BYN2243), `unit-floor-other-family` (BYN2244), `uptime-wasm32` (BYN4003; a `diag/` case passes no flags, so T7 runs it as a driver test with `--target wasm32`). Plus one case for each existing code in R1–R17: `unit-lowercase` BYN2008, `unit-compound` BYN2022, `unit-hex` BYN0011, `unit-literal-range` BYN2203, `unit-bare-zero` and `unit-bare-nosymbol` BYN3203, `unit-coarser` and `unit-plus-assign-finer` BYN3205, `unit-mixed-family` and `unit-ops-rejected` BYN2208, `unit-cast-other-family` BYN2206, `unit-const-overflow` BYN2204, `uptime-format` BYN2225, `uptime-no-clock` BYN6002, `uptime-plus-uptime` and `duration-plus-uptime` BYN2208, `uptime-bare` BYN3203, `uptime-map-key` BYN2760, `millis-unknown` (the unknown-type error).
- `run/` cases, one per runtime feature: `unit-arithmetic` (R7, R10 values), `unit-rounding` (the R8 table with negatives), `unit-wrap` (R9), `unit-format` (R11), `core-time-units` (R12), `duration-pure` (R13), `unit-map-const` (D-OQ1), `uptime-arithmetic` (R14, R15), and the trap cases with `.exitcode`: `unit-widen-overflow` (R7) and `unit-divide-zero` (R10). The `io-run-timeout-*` and `io-error-signaled-timeout` cases pass `5s` and print `after` (R17).
- Per-platform clock: a new `runtime/tests/uptime-clock.c`, run by `runtime/tests/run.sh`. It reads the platform clock, then `byn_uptime_now()`, then the clock again, and checks the bracket after scaling. That shows which clock is read on Linux, macOS and Windows (R16). It also checks that 10 000 readings never decrease. On macOS it checks the scaling with a timebase of 125/3 against a 128-bit reference.
- Checker unit tests beside the code (`src/semantics/conversions-t29.test.byn` and the like) for scale products, the common unit, and `rounded` ties away from zero.
- Rename churn (T8b): the 56 files under `tests/` that name `Millis` are regenerated in update mode (`BAYAN_UPDATE=1`) and reviewed as a diff. `tests/cases/diag/millis-bare-literal.*` is replaced by `millis-unknown`. Frozen files: D-U3. `scripts/ci/freeze-check.sh` must pass with no `pending` row. `scripts/ci/bootstrap-check.sh` must pass after T6, T7, T8a and T8b.
- Every code: `scripts/ci/diagnostic-codes.test.sh` (page and golden per live code).
- R17 check: `git grep -w Millis -- src lib tests runtime docs/bayan-spec.md` is empty after T8b. History and changelog entries are not searched.
- The law candidates are left to the laws step. The `unit-rounding` and `uptime-arithmetic` cases are their seeds.

## Risks & mitigations
- `CLOCK_BOOTTIME` may be hidden under `_POSIX_C_SOURCE 200809L` (`runtime/bayan-rt.c:6`) with musl or glibc headers. T7 checks it first. If it is hidden, define it as the Linux ABI value 7 under `__linux__`, with a comment.
- `QueryInterruptTimePrecise` may need an extra import library under zig's mingw (`x86_64-windows-gnu`). T7 links a probe first. If it fails, the call is resolved from the API set DLL at start-up, never replaced by `QueryPerformanceCounter` (R16).
- A `std` module that holds only doc comments may not load as a module. T7 checks this with `import std.time` first. If it does not load, `lib/std/time/uptime.byn` declares one small pure helper over `Uptime`.
- `µ` (U+00B5) may be normalized or rejected by identifier rules before the checker sees it. T2 checks this with a lex case for both code points.
- Spec 027 or another plan may take BYN2237–BYN2244 or BYN4003 first. T1 re-checks the numbers before merge (D-OQ2a).
- The bridge conversion in T8a could outlive T8b. T8b deletes it in the same commit as `BuiltinKind.millis`, and the R17 grep fails if `Millis` remains.
- Mixed-scale arithmetic can overflow where the plain integers would not (`h` to `ns`). R7 and R10 trap in every mode, and the `unit-widen-overflow` case pins it.

## Coverage check
| R | Covered by |
|---|---|
| R1 | Changes by area: Parser (`UnitDecl`), Semantics (`unitType`, BYN2237, BYN2008), Emitter (`common.byn`); Testing `unit-storage-float`, `unit-lowercase` |
| R2 | Semantics (unit table, BYN2238); Testing `unit-scale-*` |
| R3 | Parser (`parseUnit`), Semantics (BYN2022); Testing `unit-compound` |
| R4 | Lexer, Semantics `bindLiteral` (BYN2239, BYN2240, BYN2203, BYN0011); Testing |
| R5 | Semantics `bindLiteral` and declaration checks (BYN2241, BYN2242, BYN2243, `µs`); Testing |
| R6 | Semantics `convert` (BYN3203); Testing `unit-bare-*` |
| R7 | Semantics `conversions.byn`, `fold` (BYN3205, BYN2204), Emitter checked multiply; Testing `unit-arithmetic`, `unit-widen-overflow` |
| R8 | Semantics `bindBuiltinMethodCall` (BYN2244); Testing `unit-rounding` |
| R9 | Semantics `bindConstruction`, `bindCast` (BYN2206); Testing `unit-wrap` |
| R10 | Semantics `bindBinary`, `bindUnary`, `bindAssign` (BYN2208, BYN3205); Testing `unit-arithmetic`, `unit-divide-zero` |
| R11 | Semantics `bindInterpolated`, Emitter `helpers.byn` `format`; Testing `unit-format` |
| R12 | Semantics `builtins.byn` `core` units source; Testing `core-time-units` |
| R13 | Semantics `builtins.byn` (`type Duration = Nanoseconds`), `effects.byn`; Testing `duration-pure` |
| R14 | Semantics `BuiltinKind.uptime`, `uptimeNow`, `effects.byn`, BYN2225; Standard library `lib/std/time/`; Testing `uptime-*` |
| R15 | Semantics `bindBinary` for `Uptime` (BYN2208, BYN3203); Testing `uptime-arithmetic` |
| R16 | Runtime `byn_uptime_now`, Semantics BYN4003; Testing `runtime/tests/uptime-clock.c`, `uptime-wasm32` |
| R17 | Order T8a, T8b; Decisions D-U2, D-U3, D-OQ2c; Testing rename churn and the R17 grep |

Every R# is covered. None is uncovered or partly covered.
