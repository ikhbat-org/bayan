---
id: L046
title: Encoder agrees with the reference assembler
status: proposed
release: unscheduled
sources: spec 024 R3
kind: property
scope: src/sabk/enc/encode.byn, src/sabk/testdata/encodings.tsv
---

## Statement
For every instruction form in sabk's arm64 subset (spec 024 plan, subset table) and every operand value in that form's full range (registers 0–30, every immediate the form accepts, every branch offset the form reaches), `encode` returns the same four bytes as the reference assembler for the same assembler text. The reference assembler is `zig cc -c -target aarch64-macos` at the zig version pinned in `scripts/ci/install-zig.sh` (0.17.0 today), read back with `otool -t`.

## Counterexample looks like
`add x3, x7, #4095`: the assembler's bytes and `encode`'s bytes for the same form differ in one bit field, such as the `sf` bit, or `encode` returns `EncodeError` for this in-range operand.

## Proof notes
Not proven. Number reserved after spec 019's L040–L045. Bytes are never typed by hand (R3): `/prove` (task T16) checks the recorded TSV (`src/sabk/testdata/encodings.tsv`, written by `scripts/sabk/record-encodings.sh`) plus a sweep whose bytes come from running the pinned `zig cc` at prove time; the sweep's sampling (range edges plus random interior values per form) is a proof choice, not part of the statement. Tagged `Law=L046`.

Out-of-range refusal (an operand outside the form's range returns `EncodeError` naming the mnemonic and operand, and writes no bytes; R2, R11) is a separate property, tested by T4's tests in `src/sabk/enc/encode.test.byn`, not by this law.
