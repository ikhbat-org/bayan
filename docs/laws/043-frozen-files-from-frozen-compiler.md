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

## Proof notes
- 2026-11-20 (T59 part 1): `scripts/selfhost/reexport-check.sh` checks the classes export mode writes at the export head (95 of 110 at e0cf66ea9); the 15 recorded through the C# CLI, and the flat kinds, are printed as left out and wait for T59b. Break: one byte appended to tests/cases/parse/SelfhostParserO3Tests/FieldRulesSplitAsTheCSharpParser-2/expected.ast; `--class parse/SelfhostParserO3Tests` exited 1 with `differs from the frozen compiler: tests/cases/parse/SelfhostParserO3Tests/FieldRulesSplitAsTheCSharpParser-2/expected.ast` and `14 files compared, 0 on the divergence list, 0 skipped by an os file, 1 failed`; restored by hand.
