# 010 — Test builds at -O0

Status: closed 2026-11-13, gate failed at step 1 (see Result). Was: approved by the user 2026-11-13, gated on step 1 (build steps 2–4 only if the suite is ≥10% faster with no new failures). Decisions: `bayan test` for users stays -O2; merge gates at -O0, nightly, release and laws at -O2 (the recommendations). Builds on plan 009 (prebuilt runtime object). Measurements: tmp/bench (m2, m3).

## Why

With the runtime prebuilt at -O2 (plan 009), compiling the program's `main.c` at -O0 instead of -O2 cuts the rest. Measured on mb1, zig 0.17.0, fresh directory per build:

| corpus (1296 buildable programs) | today | plan 009 only | plan 009 + main.c at -O0 |
|---|---|---|---|
| 1204 programs under 1 MB of C, mean build | 0.752 s | ~0.18 s | 0.177 s |
| 92 programs over 1 MB (compiler-sized), mean build | 19.8 s | ~19.8 s | 4.42 s |
| total zig time | 2724 s | ~2030 s | 620 s (−77%) |

For small programs -O0 adds nothing over plan 009; the gain is in the 92 compiler-sized builds (the self-hosted driver and its stages), −15 s each.

Cost on the other side: an -O0 program runs slower. m2 measured the five compiler-sized sample programs on empty input at 0.04 s (-O2) vs 0.11–0.13 s (-O0), about 3×. Tests that run a built compiler over the whole self-hosted source (stage 2 building stage 3, `SelfhostDriver*`, `SelfhostDefault*`) may lose more than they gain. **Not yet measured; step 1 below measures it before anything is built.** Same outputs and exit codes at -O0 and -O2 on 30 of 30 sample programs; 27 corpus programs fail to build under both.

## Approach

1. **Measure first (tmp/, no Bayan change).** On the ghosthive VM `bayan-test01` (Linux, the fastest host), run the full suite twice on one commit with `BAYAN_CC` pointing at a wrapper that rewrites `-O2` to `-O0` for `main.c` only (both runs with plan 009 applied, if merged; else both without). Compare suite wall time, per-class time and failures. Go only if the suite is at least 10% faster with no new failures; otherwise this plan stops and only plan 009 lands.
2. **One switch, `BAYAN_OPT=0`**, read by both compilers. For `safe` and `fast` builds it compiles the program's own C at -O0 (the runtime object stays -O2, `-DBYN_NDEBUG` stays, so semantics do not change); `debug` builds are unaffected; any other value is an error naming the allowed ones. It is part of the flag list and so of every key. Documented in the CLI help as a build-speed switch for development, not for releases.
3. **Who sets it.** `tests/Bayan.Tests/TestSetup.cs` sets it for the test run unless `BAYAN_OPT` is already set; `scripts/selfhost/shard-test.sh` passes it through. The nightly full tier, the release workflow and the laws gate set `BAYAN_OPT=2` explicitly, so the shipped flags are exercised every night and before every release.
4. **Both compilers.** C# `Toolchain.cs` and `selfhost/driver/cc.byn` / `cache.byn` change in one branch through `scripts/selfhost/land.sh`; `bootstrap/bayan.c` regenerated; the byte-comparison parity tests run with the same `BAYAN_OPT` on both sides.

## Changes by area

- `src/Bayan.Backend.C/Toolchain.cs`, `selfhost/driver/cc.byn`, `selfhost/driver/cache.byn` — read `BAYAN_OPT`, pick the program's -O level, error on bad values.
- `tests/Bayan.Tests/TestSetup.cs` — default `BAYAN_OPT=0`; `scripts/selfhost/shard-test.sh` — pass it on; nightly and release workflow files and the laws gate invocation — `BAYAN_OPT=2`.
- Tests: key differs between 0 and 2; `debug` ignores it; a bad value is a diagnostic in both compilers (parity); a run corpus sample built both ways gives the same output; a test that fails if the nightly/release workflows do not set `BAYAN_OPT=2`.
- `docs/bayan-handoff.md` Progress log; CHANGELOG `[Unreleased]`.

## Needs decision (before step 2)

- Should `bayan test` (the user-facing command) also default to -O0 for the programs it builds, or stay -O2 (recommended: stay -O2; users opt in with `BAYAN_OPT=0`)?
- Is a test suite that runs at -O0 on merge gates and at -O2 only nightly and on release acceptable (recommended: yes; an -O2-only bug surfaces within a day, never in a release)?

## Result (2026-11-13)

Gate failed; steps 2–4 not built. One ABAB pair of full sharded runs on bayan-test01 (18 GiB RAM, 8 threads for the measurement, back to 12 GiB after):

| run | flags | wall | failures |
|---|---|---|---|
| A | -O2 (today) | 1334 s | 20 |
| B | -O0 | 1416 s | 200, mostly OOM (exit 137) |

-O0 was 6% slower, not ≥10% faster, and its larger test binaries pushed GB-scale memory into OOM kills. One pair, not the 5-run protocol: the gap and the failure count settle the gate without more runs.

