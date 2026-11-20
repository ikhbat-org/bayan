---
id: L043
title: Frozen files come from the frozen compiler
status: enacted
enacted: 2026-11-18
release: unscheduled
sources: spec 019 R10, R12, R13, R27
kind: property
scope: tests/cases/FREEZE.tsv, tests/cases/DIVERGENCES.tsv, scripts/ci/ddc.sh
proof: scripts/selfhost/reexport-check.test.sh
check: bash scripts/selfhost/reexport-check.sh
---

## Statement
For every manifest row unchanged since the freeze, the C# compiler built from the export branch head recorded in `tests/cases/FREEZE.tsv` produces the same bytes for that case's input as the expected file in the tree, except for the cases listed in the divergence list. The proof is a weekly sample re-export (one class per kind); the full re-export runs on manual dispatch.

## Counterexample looks like
A manifest row unchanged since the freeze and outside the divergence list, with the expected file in the tree and the first byte where the frozen C# compiler's output for the same input differs.
