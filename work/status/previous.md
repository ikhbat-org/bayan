# Previous

0.3.0 release preflight on three hosts (handoff Progress log, "2026-11-14 — 0.3.0 release preflight on three hosts"), merged into `dev`, unpushed.

- Scratch merge `test/release-0.3.0-preflight-2` ran on bayan-test01, wp1 and mb1: all failures fell in three groups.
- Fixed: the two goldens changed by the "Salam, world!" scaffold text (73780e92); the `BAYAN_CACHE` race in the mutate driver tests (`fix/mutate-env-race`, merged efa7f58b); the `PeakSampler` first-sample wait on macOS (`fix/peak-sampler-first-sample`, merged c3632438); the removed Windows known failure (45acbbc1).
- Left as known: `OwnershipTableTests.ARunPastItsTimeoutIsKilledAndReported` fails under load on wp1 (`work/todo.md`).
