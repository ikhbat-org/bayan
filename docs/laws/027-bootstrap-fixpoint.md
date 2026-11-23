---
id: L027
title: Bootstrap fixpoint
status: enacted
release: 0.2.0
sources: none recorded
kind: property
scope: src/driver/**, src/emitter/**, src/semantics/**, bootstrap/bayan.c
proof: scripts/ci/fixpoint-check.sh
check: bash scripts/ci/bootstrap-check.sh >/dev/null && bash scripts/ci/fixpoint-check.sh
timeout: 900
---

## Statement
For the driver\'s sources and each of `safe` and `debug`, the C stage 1 emits and the C stage 2 emits are byte-identical and contain no absolute path and no timestamp, all stages built on the same host. For the frozen tree (`csharp-final`), the self-hosted compiler built by the C# compiler from that tree emits, for that tree\'s `src/driver` in `safe`, C byte-identical to that tree\'s `bootstrap/bayan.c`.

## Counterexample looks like
A mode and the first differing byte offset between two stages' emitted C (for example stage 1 vs stage 2 in `debug`), with the `src/` line each side came from; or an absolute path or timestamp found in one stage's C.

## Proof notes
Cross-host byte identity for the same `--target` is a tracked future strengthening, not part of L027. Approved by the user 2026-11-05 with this wording (012-spec.md, Law candidates). Enactment is the user's edit of `status:` (012 T11). Until `csharp-final` exists, the ddc job runs the frozen-tree half against `v0.3.2`; the stage 1/stage 2 half becomes a no-.NET check when T31 lands.

Proof 2026-11-19 (spec 019 T31): scripts/ci/fixpoint-check.sh takes stage 1 from tmp/bootstrap-check (bootstrap-check.sh), builds stage 2 with it, emits src/driver in `safe` and `debug` from stage 1 twice and from stage 2, compares the bytes and scans each file for the repo root, $HOME, $TMPDIR, a rooted `#line` file, __DATE__/__TIME__/__TIMESTAMP__ and today's date (the scan of BootstrapTests.cs, ported). The check took 89s wall on macOS arm64 (fixpoint-check.sh 77s of it). Break: a header line holding the repo root added to src/emitter/cprint/program.byn; the check failed naming tmp/fixpoint-check/stage1.safe.c:2, stage2.safe.c:2, stage1.debug.c:5 and stage2.debug.c:5 with the path; restored from HEAD. The frozen-tree half of the Statement runs in the ddc job (scripts/ci/ddc.sh, L027 in scripts/ci/ddc-laws.txt).

## History
Amended 2026-11-18 (spec 019 D8): the statement covers the frozen tree; the C# half moves to the ddc job. The `check:` stays until T31 swaps it. L045 is retired in its favour.
Amended 2026-11-18 (owner approved Fable's corrected text, tmp/fable-owner-queue-1118.md item 3): the frozen-tree half names the self-hosted compiler the C# builds; task ids and the temporary tag moved to Proof notes.
