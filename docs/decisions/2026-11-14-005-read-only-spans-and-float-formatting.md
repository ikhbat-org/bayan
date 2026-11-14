# Read-only spans and float formatting
Status: decided 2026-10-20 (addendum 001 to the v0.1 work plan, answering Q34 and the float formatting boundary). Applied to the spec: `ReadOnlySpan<T>` (spec §3.5 and §6.2) and float formatting (spec §6.6). Q34 is also in `docs/decisions/2026-11-14-004-answered-questions.md`.

### Q34 — read-only `string.bytes`

**Decision: add `ReadOnlySpan<T>`, with C#'s semantics.**

- `Span<T>` is a mutable view; `ReadOnlySpan<T>` is a read-only view. `Span<T>` → `ReadOnlySpan<T>` is implicit. `List<T>` → `ReadOnlySpan<T>` is implicit as a function argument, like `List<T>` → `Span<T>`.
- `string.bytes` returns `ReadOnlySpan<u8>`. A `string` itself converts implicitly to `ReadOnlySpan<u8>` as an argument.
- Standard-library functions that only read take `ReadOnlySpan<T>`.
- New lint **BYN2310**: a `Span<T>` parameter that is never written to → "use `ReadOnlySpan<T>`" with a fix-it.

Why not make span parameters read-only by default: it would give `Span<T>` a different meaning from C#, breaking the rule that zero-allocation C# compiles unchanged (that code uses `ReadOnlySpan<T>` heavily). The cautious `.copy(to:)` requirement goes away for read-only callers.

### Float formatting boundary

**Decision: match .NET's thresholds, with Bayan's exponent spelling.**

- Digits: always the **shortest string that round-trips** to the same `f64`/`f32` (Ryu-style).
- Fixed notation when `1e-5 ≤ |x| < 1e15`; exponential outside that range (the same boundaries as .NET Core 3.0+'s default `ToString()`).
- Exponent spelling: lowercase, no `+`, no leading zeros: `1e15`, `1.5e-7`, `-2.25e20`. The output is always a valid Bayan literal and valid JSON.
- Special values: `nan`, `inf`, `-inf` in `$"{x}"`; `Json.encode` rejects them (`JsonError.nonFinite`).
- `-0.0` prints `-0`. Integral values print without a decimal point (`42`, not `42.0`), matching .NET.
- Fixed-format control (`{x:F2}`) remains deferred to the format-specifier design. Superseded by revision 0003 §6 (batch 9): format specifiers are settled, and `{x:.2}` is an input form that `bayan format` rewrites to `{x, digits: 2}` (BYN1068).

Add golden cases at the boundaries: `999999999999999.9`, `1e15`, `0.00001`, `0.0000099`, `0.1 + 0.2`, `-0.0`, `nan`.
