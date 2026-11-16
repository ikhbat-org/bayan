# 0024 — Numeric conversions and `dec`

Status: done (accepted: user decisions 2026-11-12 on Q1, Q1274, Q2–Q4, Q6; text written 2026-11-17)
Release: unscheduled
Sources: user, 2026-11-11 (numeric conversions and .NET 11 drop); user decisions 2026-11-12 (`docs/decisions/2026-11-14-004-answered-questions.md` "Rev 0024: Q2–Q4 and Q6 accepted", Q1274); revisions 0013, 0015, 0020, 0023

## Problem

A review of the exports at `8d5e5c71` and experiments across .NET 10, .NET 11 (which changed `decimal` and `BigInteger` floating-point conversions to round the exact value once, dotnet/runtime#130565 and #130566) and gcc on x86-64 found eight gaps in the specification:

1. **D1 (`dec`).** SPEC §3.1, §2.3 and §25 mention `dec` in one table row each, with no width, scale, rounding, overflow, conversions, formatting or parsing rules, and `docs/STATUS.md` has no `dec` row.
2. **D2 (§6.2 numeric conversion pairs).** "Lossless numeric widening: implicit" is not enumerated. There is no row for `i64`→`f64`, `f64`→`f32` or `f64`/`f32`↔`dec`, or for their rounding.
3. **D3 (§6.2 float→int).** Integer narrowing traps (`u8(x)`), while float-to-integer conversion saturates. The asymmetry is stated without saying it is deliberate, and the rounding direction for float→int is not stated.
4. **D4 (§4.3 `Duration` extension example).** `Duration(h * 3600s)` multiplies an `f64` by an `i64`-backed unit, which no rule in §3.4 or §6.2 allows.
5. **D5 (§17 float hashing vs §3.5 `Map` keys).** §17 says derived hashing on floats uses `totalOrder`, while §3.5 (revision 0013) excludes floats and structs containing them from `Map` keys.
6. **D6 (AUDIT A29).** Already applied by revision 0020 item 30.
7. **D7 (§12 comptime numeric results).** Comptime is described as deterministic, without stating that comptime numeric evaluation produces the same bit-for-bit results as the compiled program.
8. **D8 (§17 `@fastMath` at comptime).** §17 does not say whether `@fastMath` applies during comptime evaluation.

## Decision

The owner decisions (`docs/decisions/2026-11-14-004-answered-questions.md` line 927 and Q1274):

1. **Q1 and Q1274 (`f64`/`f32` → `dec`).** `dec(x)` on any `f32` or `f64` operand is a compile error (BYN2206 `InvalidCast`). When the operand is a float literal (`dec(0.1)`), the fix-it replaces it with the `dec` literal (`0.1dec`). When the operand is a runtime `f32` or `f64` value, the fix-it rewrites it to `dec.fromF64(x, digits: n)`, which converts a finite `f64` rounded to `digits` fractional digits (0..=28, nearest, ties to even) and traps on `nan`, `±inf` or an out-of-range magnitude. Loosening this later breaks no code.
2. **Q2 (`dec` representation).** .NET-compatible 128-bit decimal layout: a 96-bit unsigned integer coefficient (`0` to `2^96 - 1`, `79_228_162_514_264_337_593_543_950_335`), a sign bit, and a scale `0..=28` (divisor `10^scale`), so C ABI interop with NativeAOT libraries and database numerics map directly.
3. **Q3 (scale preservation).** Scale is preserved: `1.50dec` has scale 2, formats as `"1.50"`, and compares equal to `1.5dec` (`1.50dec == 1.5dec` is `true`, and `<=`/`>=`/ordering compare numerical values). Addition and subtraction keep the larger of the operands' scales, multiplication adds scales, and division uses the scale needed for the result, each capped at 28 with rounding when nonzero digits are discarded.
4. **Q4 (rounding and overflow).** Overflow and division by zero trap in every build mode (§0, §17); `+% -% *%` and `+| -| *|` do not apply to `dec`. Arithmetic that exceeds 28 decimal places or 96 bits of coefficient rounds once to nearest, ties to even. Explicit `x.rounded()` and `x.rounded(digits: n)` (`0..=28`, default `0`) round to nearest, ties away from zero, matching §3.4 unit `rounded` and `Money.rounded()`; `x.floor()` and `x.ceiling()` round toward `−∞` and `+∞`.
5. **Q5 (`T.tryFrom` on floats).** Already shipped and unchanged: `i32.tryFrom(x)` (and every integer type's `tryFrom` on `f32`/`f64`) returns `null` when `x` is `nan`, out of the target's range, or has a nonzero fractional part.
6. **Q6 (`@fastMath` at comptime).** Comptime evaluation ignores `@fastMath` and always uses strict IEEE 754 semantics; a function marked `@fastMath` may therefore produce a different result at run time than at comptime. Outside `@fastMath`, comptime numeric results equal the compiled program's bit for bit (D7).
7. **D2 (all numeric conversion pairs).** §6.2 enumerates every pair of numeric types (implicit lossless widening, explicit conversion, or BYN2206). Every explicit numeric conversion (`i64`→`f64`, `u64`→`f64`, `i32`/`u32`/`i64`/`u64`→`f32`, `f64`→`f32`, `dec`→`f64`/`f32`) rounds the mathematical value once to the target type, to nearest, ties to even.
8. **D3 (float→int).** §6.2 states that `I(x)` from `f32`/`f64` to any integer type truncates toward zero, saturates to `I`'s minimum or maximum when out of range (negative inputs saturate to `0` for unsigned `I`), and maps `nan` to `0`; it is the one narrowing conversion that saturates instead of trapping, while `I.tryFrom(x)` is the strict counterpart that returns `null` on `nan`, out of range or a nonzero fraction.
9. **D4 (§4.3 example).** The `Duration.fromHours(f64 h)` extension example in §4.3 is marked proposed until a float-to-unit conversion rule is specified.
10. **D5 (§17 float equality and hashing).** §17 drops "and hashing" from the float sentence and points to §3.5: floats and types containing them are not `Map` keys (BYN2760, BYN2831), while derived equality on structs containing floats still uses IEEE `totalOrder`.

`dec` is not implemented in `bayan 0.3.2`; every `dec` item added to the spec is tagged `(not in 0.3)`.

## Sections

- SPEC Header: `Revisions applied: 0001–0024`.
- SPEC §2.3: literal table `dec` note and `dec` literal form `(not in 0.3, §3.1)`.
- SPEC §3.1: `dec` subsection (representation, scale, arithmetic, rounding, overflow, conversions, formatting, parsing `dec.tryParse`, `dec.fromF64`, `Map` keys; all tagged `(not in 0.3)`).
- SPEC §4.3: `Duration.fromHours` example tagged `(proposed: float-to-unit conversion is not specified)`.
- SPEC §6.2: numeric conversion pairs table, single-rounding rule, float→int saturation and `tryFrom` rule, `dec` conversion and `tryParse` rows `(not in 0.3)`.
- SPEC §12.4: comptime numeric results equal the compiled program's bit for bit, except under `@fastMath` (§17).
- SPEC §17: `dec` overflow traps; float derived equality uses `totalOrder` (floats are not `Map` keys, §3.5); `@fastMath` is ignored at comptime.
- SPEC §25: `m` / `d` suffix row notes `dec(0.1)` is BYN2206 with fix-it `0.1dec`, and runtime `f64` converts via `dec.fromF64(x, digits: n)`.
- `docs/diagnostics/BYN2206.md`: `dec` cases and fix-its (`0.1dec` on literals, `dec.fromF64(x, digits: n)` on runtime floats).
- `docs/STATUS.md`: `dec` feature row (`spec-only`, rev 0024) and header bump.
- `docs/bayan-grammar.md`, `docs/bayan-style.md`, `docs/DIAGNOSTICS.md`, `docs/bayan-feature-history.md`: header bump to `0001–0024`, plus 0024 entries in `docs/bayan-feature-history.md`.
- `docs/bayan-roadmap.md`: row 1 state updated.

## Codes

None added or retired. `BYN2206` (`InvalidCast`) gains the `dec(x)` on `f32`/`f64` cases (with fix-it `0.1dec` on a float literal and `dec.fromF64(x, digits: n)` on a runtime float, not in 0.3).

## Sūq files

None affected yet; Sūq `Money` and zakat/sadaqah calculations use `dec` once implemented.

## Effect on work already done

- No compiler, runtime or test changes in this revision (`dec` is not in 0.3).
- Float→int saturation (`D3`, `T3` in the drop) is already implemented in the C runtime (`byn_f2i_*` in `runtime/bayan-rt.h`) and in constant folding; only conformance goldens remain to add.
- Known host-sensitive sites in the C# compiler (verified 2026-11-11; no decimal or `BigInteger`→`double` site exists in the compiler) to address in follow-up work, not changed here:
  1. `csharp/Bayan.Semantics/Binding/BinderExpressions.cs`: `f32` literals are parsed `string` → `f64` → `f32` (double rounding on midpoint cases).
  2. `csharp/Bayan.Semantics/Binding/BinderExpressions.cs`: `double.Parse` beside it.
  3. `csharp/Bayan.Backend.C/CEmitter.cs`: formatting floats with `"R"`.

## Diff

The changes are applied directly to `docs/bayan-spec.md`, `docs/diagnostics/BYN2206.md`, `docs/STATUS.md`, `docs/bayan-feature-history.md` and `docs/bayan-roadmap.md`.
