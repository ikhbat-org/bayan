---
id: L045
title: Two bootstraps agree
status: retired
release: unscheduled
sources: spec 019 R27; restates L027 without a live C# compiler and may be enacted as its amendment
kind: property
scope: bootstrap/bayan.c, scripts/ci/ddc.sh
---

## Statement
For the frozen tree, the self-hosted compiler built by the C# compiler from `csharp-final` and the one built from that tree's `bootstrap/bayan.c` emit the same C for `src/driver`, byte for byte.

## Counterexample looks like
The frozen commit and the first line where the C emitted for `src/driver` by the two self-hosted compilers differs.

## History
retired 2026-11-18 unenacted: folded into L027 (D8)
