---
id: L046
title: Encoder agrees with the reference assembler
status: enacted
enacted: 2026-11-17
release: unscheduled
sources: spec 024 R3
kind: property
scope: src/sabk/enc/encode.byn, src/sabk/testdata/encodings.tsv
proof: src/tests/SabkLawTests.cs
check: dotnet test -v q --filter "Law=L046"
---

## Statement
For every instruction form in sabk's arm64 subset (spec 024 plan, subset table) and every operand value in that form's full range (every register the form accepts: x0–x30, and `sp` or `xzr` where the form takes it; every immediate the form accepts), `encode` returns the same 32-bit word (four bytes, little-endian) as the reference assembler emits for the same assembler text, in the `__text` bytes of the object it produces. Forms that carry a label or relocation (branches, `adr`, `adrp`, `add …@PAGEOFF`) are compared with the offset field zero, as the assembler emits them before fixup or link; filling that field is not covered. The reference assembler is `zig cc -c -target aarch64-macos` at the zig version pinned in `scripts/ci/install-zig.sh`.

## Counterexample looks like
`add x3, x7, #4095`: the assembler's bytes and `encode`'s bytes for the same form differ in one bit field, such as the `sf` bit, or `encode` returns `EncodeError` for this in-range operand.

## Proof notes
Proven 2026-11-17 by `SabkEncoderLawTests` (`src/tests/SabkLawTests.cs`), which runs the Bayān test "L046:" in `src/sabk/enc/encode.test.byn` over the 322-row recorded table plus a 7,526-row sweep assembled by the pinned zig at test time; the test asserts the sweep row count it compared, so an unread sweep fails. Mutation: sdiv's base `0x1AC00C00` → `0x1AC00800` in `encode.byn` failed with `sdiv-x: sdiv x7, x8, x9: encode 9ac90907 assembler 9ac90d07`; two edits only the sweep reaches failed on `add x0, x2, x10, asr #57` and `csel x2, x27, x22, al`. Gap: the encoder refuses `wsp` in the 32-bit add/sub immediate forms, which the assembler accepts, so the sweep draws w0–w30 there; whether "`sp` … where the form takes it" covers `wsp` is open. Runs on arm64 macOS only; elsewhere the test returns early with its reason.

Earlier notes: number reserved after spec 019's L040–L045. Bytes are never typed by hand (R3): `/prove` (task T16) checks the recorded TSV (`src/sabk/testdata/encodings.tsv`, written by `scripts/sabk/record-encodings.sh`) plus a sweep whose bytes come from running the pinned `zig cc` at prove time; the sweep's sampling (range edges plus random interior values per form) is a proof choice, not part of the statement. Tagged `Law=L046`. At zig 0.17.0 the bytes are read back with `otool -t`; where `otool` is absent the proof checks the recorded TSV only, so it never runs zero tests.

Out-of-range refusal (an operand outside the form's range returns `EncodeError` naming the mnemonic and operand, and writes no bytes; R2, R11) is a separate property, tested by T4's tests in `src/sabk/enc/encode.test.byn`, not by this law.
