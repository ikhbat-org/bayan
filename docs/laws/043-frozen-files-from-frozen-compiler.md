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
- 2026-11-20 (T59 part 2, 019-t59b): `scripts/selfhost/replay-csharp.sh`, called by reexport-check.sh, builds the C# CLI from the export head and replays 14 of the 15 left-out classes (cli, emit-c and sem cases recorded through the CLI) and the flat kinds parse (`parse --ast`) and typed (`types --package .`) with their lines in emit/exit/expected.*.exitcode: 443 files and lines, 401 compared and 42 on the divergence list, 0 failed. Round 2 adds the emit kind (freeze-csharp.sh over the inputs: the modes hashes, run-c.sha256 and emit/exit/expected.diag.exitcode; `--class emit` 2,083 lines compared, 1 on the divergence list, 1 failed, 399 s) and the golden kinds run, style, new and out (the self-hosted golden runner with BAYAN_EXE the C# CLI; `--class run --class style --class new --class out` 529 files compared, 1 on the divergence list, 1 failed, 187 s). The failure in both is run/io-stdin-read (`read` is not a member of `IoInput` at the export head). out/dist is skipped by its existing DIVERGENCES.tsv row (655cb84a3: its tree names the compiler version); no new rows. Still left out, printed with the reason: cli/MutatorTests (MaskMutation compare), the flat kinds diag, diag-json, lex and manifest (rendered in process, no CLI route), 5 style shapes rendered in process (15 files), 2 run cases skipped by their os line, and the run-c.sha256 lines of 4 .test.byn inputs. Break: one byte appended to tests/cases/parse/assert.ast; `--class parse` exited 1 with `replay: differs from the frozen compiler: tests/cases/parse/assert.ast` and `replay: 128 files compared, 0 on the divergence list, 1 failed`; restored by hand.
