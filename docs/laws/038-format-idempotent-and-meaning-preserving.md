---
id: L038
title: Format is idempotent and meaning-preserving
status: proposed
release: unscheduled
sources: spec 022 R4
kind: property
scope: src/driver/format.byn, src/driver/layout.byn
---

## Statement
For every `.byn` source that `bayan format` accepts and every `style` setting, formatting the output again gives the same bytes, and the C that `bayan build --emit-c` prints for the formatted program equals the C for the original program apart from source line and column numbers (`#line` directives and the positions the C passes to runtime failure messages, such as `byn_unreachable(file, line)`).

## Counterexample looks like
A source and a `style`, with the first line where the second format differs from the first, or the first line of emitted C that differs between the original and the formatted program.

## Proof notes
Not proven. Retargeted 2026-11-22 (owner) from the C# `Format.cs` to the Bayān formatter; `proof` and `check` are set when `/prove` writes a Bayān test. The C# `LayoutTests` corpus tests format the corpus twice and compare the token sequences of input and output; they do not yet compare emitted C, and none carries the `Law=L038` trait. `/prove` writes the test.
