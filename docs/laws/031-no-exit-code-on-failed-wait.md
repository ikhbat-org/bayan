---
id: L031
title: No exit code on a failed wait
status: proposed
kind: property
scope: src/runtime/bayan-rt.c
proof: tests/Bayan.Tests/RuntimeNativeTests.cs
check: dotnet test -v q --filter "Law=L031"
---

## Statement
`byn_wait_status`, the one mapping every `Io.run` and `Io.runBatch` wait goes through, never reports an exit code it did not read: a failed wait (`waitpid` other than EINTR, `WaitForSingleObject`) or a failed exit-code query (`GetExitCodeProcess`) is `IoError.other` whatever the raw status, so 0 and 259 (`STILL_ACTIVE`) never reach `ProcessResult.exitCode`; a timeout is `IoError.timeout` with the detail slot untouched; a child killed by a signal is `IoError.signaled` with the signal number in the detail slot, never 128 + n; only a completed wait yields an exit code.

## Counterexample looks like
An outcome and raw status, and `byn_wait_status` returning 0 with a code (for example `BYN_WAIT_FAILED` with raw 0 giving exit 0, or `BYN_WAIT_QUERY_FAILED` with raw 259 giving exit 259), or a SIGKILL status giving an exit code instead of `BYN_IO_SIGNALED` with detail 9.

## Proof notes
`RuntimeNativeTests.WaitStatusMapping` builds `tests/native/wait-status.c` against `bayan-rt.c` and checks six cases (plan 007 step 4): `FAILED` with raw 0, `QUERY_FAILED` with raw 259, `FAILED` with raw 259, `TIMED_OUT` (detail left at its sentinel), a real SIGKILL status from `fork`+`kill`+`waitpid` (POSIX only, detail 9) and a normal exit 3. The user's 2026-11-08 decision enacts L031 once its proof passes on musl, macOS and wp1; only macOS has run it so far.
