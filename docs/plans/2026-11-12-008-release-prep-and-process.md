# 008 — 0.3.0 release prep, faster landing, docs drift

Tier: Standard. Approved by the user 2026-11-12. The decisions are listed in `docs/bayan-handoff.md` (*Questions*, "Decided by the user (2026-11-12)", and Q1274).
Branch: `feat/008-release-prep-and-process`. Each work package (W) is one writer on its own worker branch, gated against its section below, then landed here. W1–W5 own disjoint files. **No writer edits `docs/bayan-handoff.md`**: the dispatcher writes the Progress log. A spec gap becomes a line in the writer's final reply, not a handoff edit.

## W1 — `Io.run` bounded capture, and timed-out output kept (Q1216 + Q1227 (a), blocks 0.3.0)

Today, when a self-hosted (stage 2) test prints forever, `Io.run` keeps every byte and peaks at 4.6 GB (bound 300 MB, `SelfhostDefaultBoundsTests` row M1). A timed-out test's output is also dropped: the C# prints `timed out after N s` followed by what the test printed, while the driver prints only the first line.

1. The runtime's capture of each stream (`src/runtime/bayan-rt.c`, POSIX and Windows drain paths, and `bootstrap/bayan-rt.c` regenerated the way the repo regenerates it) keeps at most a head of H bytes and a tail of T bytes per stream. When it drops bytes, the result is head + a marker line `… N bytes omitted …` (N is the exact count dropped; U+2026 on both sides) + tail. The C# test runner (`CliApp.RunTest`) keeps output the same way with the same H, T and marker, so the C# stays the oracle. Pick H and T so that a test printing forever stays under the M1 bound with margin, and so that every existing golden is unchanged (no current case prints that much). Name the constants once on each side.
2. A timed-out `Io.run` reports the output captured before the kill. The decision says `IoError.timeout` carries it. If giving the `timeout` case a payload changes the std type in a way the 0.x freeze forbids (`docs/revisions/0023-syntax-freeze-provisional-sections.md`), keep the type and expose the capture through the smallest std-API addition instead, and say which in the reply. The driver's `test` command prints the C#'s `timed out after N s` line, then the captured output, byte for byte as `CliApp` does.
3. Tests:
   - runtime `run/` cases for the marker and for timed-out capture;
   - a C# unit test of the bound;
   - the `SelfhostDefaultBoundsTests` M1 row passes under 300 MB through stage 2 (run it on macOS or wp1; record the measured peak);
   - a driver-vs-C# test for a timed-out test's output.
   Expected lines come from the C# implementation, never typed by hand.
4. `docs/memory-leaks.md`: the Q1227 entry is marked fixed, with the measured peak. The spec's `Io.run` section states the bound and the marker. It also states that the lookup uses the parent's PATH and directory: neither the child's `env` nor its `directory` affects which program is found (Q1247).

## W2 — release workflow and cut checks (Q1270 (b), Q1264, Q1262, Q1263, Q1265, Q31 note, editor gate)

1. **Q1264.** `.github/workflows/release.yml` gains a `dry_run` dispatch input (boolean, default true). The `release` job (the draft) refuses with a clear message, and exits non-zero, when the tag contains `-rc` or the run is a dispatch. The check is in a step, not only in the job's `if:`, and both cases are covered by a script test (`scripts/release/*.test.sh` style) of the check's logic.
2. **Q1270 (b).** The full tier is a required job of the release workflow. `laws-nightly.yml` becomes callable (`workflow_call`) and keeps its schedule. `release.yml` calls it, and `release` needs it next to `build` and `memory-gate`. Merges stay on the fast tier. L028's front matter is left as enacted. Its *Proposed amendment* records the Q1270 (b) outcome: the full tier measured 37 min on wp1, the nightly/release job allows 180 min, and the seeded subset keeps `timeout: 1200`.
3. **Q1262.** `scripts/release/cut.sh` fails, before it commits or tags anything, when any tracked file still contains the previous `-dev` version string (for example `0.3.0-dev`) after the bump. Covered in `cut.test.sh`.
4. **Q1263.** Every workflow that needs zig gets it through `scripts/ci/install-zig.sh` at the pinned version. A test fails if a workflow installs zig any other way (for example `setup-zig`, or a download without the pin).
5. **Q1265.** `docs/RELEASING.md`: after `cut.sh`, run the release workflow by hand as a dry run (`dry_run: true`, version `X.Y.Z-rc.N`), then tag. The doc also states the 2.94 GB stage-2 build of `selfhost/driver` as a known limit, and `scripts/release/package.sh notes` prints that line in the release notes (Q31, until the per-phase arenas land after 0.3.0).
6. **Editor memory gate.** A CI job runs the memory gate for the VS Code extension and `bayan-lsp` on every merge to `dev` and on the release tag, and `release` needs it. This replaces the manual pre-packaging step: `scripts/release/memory-gate.sh`'s header and `docs/memory-leaks.md`'s *Release gate* say so. If the extension cannot be exercised headless on a runner, gate `bayan-lsp` (the language server, `editors/language-server`) and package the extension (`vsce package`, size bound), and say so in the reply.

## W3 — xunit parallelism limit (memory audit, HIGH)

`tests/Bayan.Tests` has no parallelism limit, so on a loaded host the test host can exhaust memory. Add `xunit.runner.json` (copied to the output) with `maxParallelThreads` set to a measured value, and pick it from a short measurement on this machine. Turn the heaviest repeated per-test setup (driver builds, stage-2 builds) into class or collection fixtures where they are not already, without changing what any test asserts. Done when: the full suite passes on wp1, and its wall time and peak memory are reported against the 36.6 min baseline. A slower suite is acceptable only if peak memory falls. Record both numbers in the reply.

Dispatcher notes (2026-11-12, after the W3 writer's reply):
- The heavy builds are already built once per test process behind a static `Lazy` (`SelfhostDriverHarness.Build`/`ProbeBuilt`, `SelfhostEmitterHarness`, `SelfhostDriverT3Tests`, `SelfhostDriverTests` quality/progress builds, `SelfhostDefaultT10Tests`, `SelfhostEmitterT*`). That meets "where not already": no fixture conversion is owed, since `IClassFixture` would rebuild per class.
- Measured on mb1 (10 CPUs, load 4–8), wall time: `SelfhostEmitterT2`–`T7` + `SelfhostDriverT5` (120 tests) 187.9 s at the default, 191.6 s at 4, 203.0 s at 2; `SelfhostDriverT2` + `SelfhostDefaultT4` (807 tests, warm) 25.2 s, 31.2 s, 31.5 s. Value chosen: 4 (≈2% slower on the heavy set, at most 4 classes at once).
- The full-suite run (wall time, peak memory, against 36.6 min) is the dispatcher's, on wp1 and bayan-test01, before the merge to `dev`; a writer cannot reach wp1.

## W4 — LSP depth guard (now) and land-flow speed (A, B, D, E)

1. **LSP depth guard.** `editors/language-server` (`Analysis/Indexer.cs`, `Lexer.cs` and whatever recurses per nesting level) stops descending past a fixed depth, reports one diagnostic at the cut, and never overflows the stack. A test feeds 100 000 nested brackets and blocks and asserts the server answers. The compiler parsers are not touched (the BYN1xxx diagnostic is after 0.3.0).
2. **E, `land.sh --check`.** It runs preflight and the guard for a row, without the review or the merge, and exits as they do. Covered in `land.test.sh`.
3. **B, test selection by changed files.** A map file (`scripts/selfhost/test-map.tsv`: a path glob, then test classes) feeds the per-task wp1 filter in preflight/land. A change to `selfhost/driver/main.byn` brings in `SelfhostDriverT2Tests`, `SelfhostDefaultT4Tests` and `SelfhostDriverT5Tests`. The `work/todo.md` LOW on this is closed. A smoke set of classes always runs. The merge gate's fast tier is the task's classes + the map's classes + the smoke set. Covered in tests.
4. **D, cache results by tree hash.** `scripts/selfhost/wp1-test.sh` keys its result on the commit's tree hash and the filter. A tree already tested with the same filter, and a pass, is not run again; the script prints which cached result it used. Covered in `wp1-test.test.sh`.

## W5 — docs drift (1 and 2) and the json count (Q1267)

1. A `§` reference check in `scripts/docs/check.sh`: every `§N` / `§N.M` cited in `docs/` and in code comments under `src/`, `selfhost/` and `lib/` must name a heading that exists in `docs/bayan-spec.md`. Covered in `check.test.sh`. Fix the stale `§` cites it finds, including the one logged in `work/todo.md`, and close that line.
2. Changing numbers out of prose: `docs/specs/017-selfhost-default/017-spec.md` (94 json tests) and any other "N tests pass" sentence in `docs/` say "the same count as the C# CLI" instead. A test asserts that stage 2's `bayan test lib/std/json` pass count equals the C# CLI's.

## W6 — Linux full-suite failures (found by the bayan-test01 run, 2026-11-12)

The full suite of dev 9af76107 on bayan-test01 (Ubuntu, ext4, non-root, zig 0.17.0 on PATH) fails 7 tests that pass on macOS and wp1. Linux is a release target, so each is fixed at its cause, never by skipping on Linux:
1. **Mutation `timing:` line, 5 tests** (`SelfhostDriverT1Tests.MutateEncodedSiteMapsAsCliAppDoes` (several encodings), `SelfhostDriverTests.TestPathsAsCSharpCli`, `SelfhostDriverGoldenTests.MutateBinaryAsCSharpCli` and `MutationGatesAsCSharpCli`): one side prints `mean 0 s and max 0 s`, the other `mean <t> s and max <t> s`. The test normalisation masks a nonzero time as `<t>` but leaves `0`, so on a fast host one run rounds to 0 and the other does not. Normalise every timing value on that line (zero included) in the shared normaliser, so the comparison no longer depends on speed. The mutation output itself does not change.
2. **`SelfhostDriverT1Tests.AuditWalksLinksAsCliApp(file-link)`**: on ext4, the C# reports `main.byn:1:1` and stage 2 reports `alias.byn:1:1` (a file and a link to it). Directory order differs between file systems, so one side depends on readdir order. Find which, and make both sides walk in the same defined order (the C#'s order is the oracle; if the C# itself depends on readdir order, sort in both and say so). Add a test that does not depend on the host's directory order.
3. **`SelfhostDefaultT12Tests.LatestIsTheHighestVersionNotTheNewestBuild`**: the C# prints `dist/latest/ is 1.0.0-rc.2+meta` and stage 2 prints `dist/latest/ is 1.0.0-rc.2`. Find why stage 2 drops the build metadata on Linux only (directory order between `1.0.0-rc.2` and `1.0.0-rc.2+meta`, which are equal in precedence, is the likely cause) and make stage 2 match the C#; if the C#'s choice itself depends on readdir order, define the tie-break in both and say so.

Not defects: `SourcesAreFormatted` needs a `dev` branch (`scripts/pinned-bayan.sh`), and the root-only and zig-PATH failures came from the VM setup.

## C — sharding the full suite (dispatcher, after W3)

`scripts/selfhost/shard-test.sh` splits the full suite by test class into weighted slices, using the last recorded per-class times. It runs the slices at once on bayan-test01 (on extrode-fleet01, via `ssh ghosthive incus exec …`, started for the job and stopped after) and on wp1 (and wlt1 when idle), then merges the results. bayan-test01's two root-only failures run on wp1. Its slice is sized to its measured speed. Done when one full run's wall time is reported against the 36.6 min single-host baseline.

Dispatcher notes (2026-11-12, after the C writer's PLAN-CHANGE):
- The measured run (wall time against 36.6 min, and the VM speed checked by it) is the dispatcher's, after landing; a writer cannot reach the hosts. The script takes the measured speeds as `--host vm=<x> --host wp1=1.0`.
- The VM slice runs as the non-root user `bt` with a local `dev` branch (`shard-test.sh` creates both), so the two root-only failures do not occur there (rerun as `bt` on 2026-11-12: both passed). No pin list is needed.
- wlt1 is left out for now: it fails 118 T17 and 3 Snapshot tests under full-suite load (memory `test-offload-hosts`), so it takes no unfiltered slice. vm + wp1 meets C.

## Not in this plan (after 0.3.0, decided)

Q1229, Q1272, Q1273, Q31 arenas (with a stated phase-handoff rule), parser/ownership depth BYN1xxx, rev 0024 text (Q1274 open), T28 helper merge (Q1217/Q1218). Drift items 3 (symbol anchors as files are touched) and 4 (generated counts) follow the existing rules.

## Order and limits

At most 3 writers at once, started one at a time, under `nice`, while load is under 12. The order is W1 (codegen, longest), then W2, then W3 + W4 + W5 as slots free. Before the merge to `dev`: the full suite on wp1, `laws-check.js --run`, `structure-audit.js`, `/code-review`.
