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
For every instruction form in sabk's arm64 subset (spec 024 plan, subset table) and every operand value the test generator draws for that form (registers 0–30, immediates across their full range including both edges, branch offsets across their range), `encode` returns the same four bytes the reference assembler (`zig cc -c -target aarch64-macos`, read back with `otool -t`) produces for the same assembler text. An operand outside the form's range is not covered: there `encode` must return `EncodeError`, not bytes (R2, R11).

## Counterexample looks like
`add x3, x7, #4095`: the TSV row's hex (recorded from the assembler) and `encode`'s bytes for the same form differ in one bit field, such as the `sf` bit, or `encode` returns `EncodeError` for this in-range operand.

## Proof notes
Not proven. Number reserved after spec 019's L040–L045. `/prove` (task T16) tags the TSV test plus a generated sweep `Law=L046`.
