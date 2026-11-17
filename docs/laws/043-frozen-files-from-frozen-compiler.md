---
id: L043
title: Frozen files come from the frozen compiler
status: proposed
release: unscheduled
sources: spec 019 R10, R12, R13, R27
kind: property
scope: tests/cases/FREEZE.tsv, tests/cases/DIVERGENCES.tsv, scripts/ci/ddc.sh
---

## Statement
For every expected file named in the freeze manifest, the C# compiler built from the `csharp-final` tag produces the same bytes for that case's input, except for the cases listed in the divergence list.

## Counterexample looks like
A manifest row outside the divergence list, with the expected file in the tree and the first byte where the frozen C# compiler's output for the same input differs.
