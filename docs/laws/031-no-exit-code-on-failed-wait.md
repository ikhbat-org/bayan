---
id: L031
title: No exit code on a failed wait
status: enacted
release: unscheduled
sources: Q1157
kind: property
scope: runtime/bayan-rt.c
proof: runtime/tests/wait-status.c
check: bash runtime/tests/run.sh
enacted: 2026-11-28
---

## Statement
`byn_wait_status`, the one mapping every `Io.run` and `Io.runBatch` wait goes through, never reports an exit code it did not read: a failed wait (`waitpid` other than EINTR, `WaitForSingleObject`) or a failed exit-code query (`GetExitCodeProcess`) is `IoError.other` whatever the raw status, so 0 and 259 (`STILL_ACTIVE`) never reach `ProcessResult.exitCode`; a timeout is `IoError.timeout` with the detail slot untouched; a child killed by a signal is `IoError.signaled` with the signal number in the detail slot, never 128 + n (its captured streams ride in the variant's `stdout` and `stderr`, Q1157, but no exit code does); only a completed wait yields an exit code.

## Counterexample looks like
An outcome and raw status, and `byn_wait_status` returning 0 with a code (for example `BYN_WAIT_FAILED` with raw 0 giving exit 0, or `BYN_WAIT_QUERY_FAILED` with raw 259 giving exit 259), or a SIGKILL status giving an exit code instead of `BYN_IO_SIGNALED` with detail 9.

## Proof notes
`runtime/tests/run.sh` builds `runtime/tests/wait-status.c` against `bayan-rt.c` and checks six cases (plan 007 step 4; the proof moved off the C# `RuntimeNativeTests.WaitStatusMapping`, which goes with the C# tree, owner 2026-11-22): `FAILED` with raw 0, `QUERY_FAILED` with raw 259, `FAILED` with raw 259, `TIMED_OUT` (detail left at its sentinel), a real SIGKILL status from `fork`+`kill`+`waitpid` (POSIX only, detail 9) and a normal exit 3. The user's 2026-11-08 decision enacted L031 once its proof passed on musl, macOS and wp1; it passed on macOS and on wp1 (2026-11-28, dev f156e50, 5 cases, SIGKILL is POSIX-only), and the owner enacted it on 2026-11-28 before a musl run. The musl run passed the same day (all 6 cases, `CC="zig cc -target x86_64-linux-musl"` with zig 0.17.0 in the Debian WSL on wp1, dev e5e9ca4).
