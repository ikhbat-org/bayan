# 020 — Tasks
Plan: ./020-plan.md

T1 is a go/no-go gate: nothing from T2 on starts until its numbers are reported to the user and the gate passes. Laws take L032–L037 (029 and 030 are absent from `docs/laws/` and left free). R6 is met by plan 009 (`docs/plans/2026-11-13-009-prebuilt-runtime-object.md`, compiler identity in the program key), not by a task here.

- [ ] T1 Measure on bayan-test01 — files: tmp/ only (no repo change) — covers: gate, R12, R19 (feasibility), decision 4 — done when: reported to the user: `strace -V` and the needed options (`-f`, `-o`, directory-read syscalls, fd path decoding) under the `bt` systemd-run unit; `kernel.yama.ptrace_scope`; VM Python version; a hand canary run (read, exec, absent, listing, link, child, grandchild, zig-static child); wall time of one recorded full pass vs the 2026-11-13 warm baseline; per-unit start-up cost; the 200-merge replay share of unit seconds reused; units using the clock (grep); go/no-go per the plan's T1 gate.
- [ ] T2 `result-cache.tsv` lists and `fingerprint` — files: scripts/selfhost/result-cache.tsv, scripts/selfhost/result-cache.py — covers: R4, R5, R8, R11 (Law-trait scan, known-failures) — done when: rows without a reason are refused; `fingerprint` prints os/osVersion/arch/cpus/roots and the tool digest; offline tests pass.
- [ ] T3 `parse-trace` — files: scripts/selfhost/result-cache.py, tests/cases/result-cache/ (recorded traces) — covers: R2, R3, R5, R11 (network, tracked write, volatile) — done when: each input kind and each bar reason is parsed from a kept trace file; runs on macOS.
- [ ] T4 Store, lookup, outcome rule, integrity — files: scripts/selfhost/result-cache.py — covers: R7, R9, R17, R20, R21 — done when: entry schema and checksum per Data / interfaces; failure/skip/timeout never stored; corrupt, unknown-version and altered entries deleted as misses; one-byte input change misses.
- [ ] T5 Admission, barring, eviction, stats, clean — files: scripts/selfhost/result-cache.py — covers: R10, R11, R22, R23 — done when: three identical recordings admit; differing recordings do not; `bar` is permanent until `admit`; cap 512 MB default (0 refused), 8 entries per unit LRU, staging swept after 24 h, CACHEDIR.TAG; `stats` and `clean` work.
- [ ] T6 `result-cache.test.sh` — files: scripts/selfhost/result-cache.test.sh — covers: R7, R9, R10, R11, R13 (guard), R17, R18, R20, R22, R24, R25 — done when: the single-change miss table, poisoning table, corrupt entries, never-stored outcomes, admission/barring, eviction, report text, switch off and "does not open test-map.tsv" cases pass offline; each break-tested.
- [ ] T7 `result-record.sh` — files: scripts/selfhost/result-record.sh — covers: R1, R4, R12, R26 — done when: one unit runs under `strace -f` with `env -i` plus the allow-list, no build step, MSBuild server off; refuses without the recorder-proven marker; a failed recorded run reruns once unrecorded and that result is reported, never stored.
- [ ] T8 `result-canary.test.sh` — files: scripts/selfhost/result-canary.test.sh — covers: R12, R19 — done when: every canary kind (read, exec, absent, listing, link, child, grandchild, zig-static child) appears in its parsed record on the VM, the marker is written, and it skips with a message off Linux.
- [ ] T9 `shard-test.sh` vm slice integration — files: scripts/selfhost/shard-test.sh, scripts/selfhost/shard-test.test.sh — covers: R14, R16, R24, R25 — done when: with the switch on, vm slices look up, rerun the sample (max(1, ceil 5%), ordered by commit+unit hash), record misses, run barred units in one normal process; `merge` prints the report lines; switch off prints `result cache: off`; dry-run and merge test cases pass.
- [ ] T10 Gates forced off — files: scripts/selfhost/pre-push-laws.sh, scripts/release/ (top-level export), result-cache.test.sh guard case — covers: R13 — done when: these export `BAYAN_RESULT_CACHE=off`; a test fails if any workflow, release script, pre-push-laws.sh or law `check:` line sets it on.
- [ ] T11 Nightly shadow — files: scripts/selfhost/result-cache.py (`shadow`) — covers: R15 — done when: after a full run, every unit's would-be answer is compared; a would-be reuse that did not pass exits 1 with `SOUNDNESS:` naming unit and entry, bars it and removes its entries; tested offline.
- [ ] T12 Windows offload pass cache — files: scripts/selfhost/wp1-test.sh, scripts/selfhost/wp1-test.test.sh — covers: decision 2 (R7, R9, R13, R17, R24 applied) — done when: the key gains the wp1 fingerprint (dotnet, zig, OS build) and environment; only passes cached; `cached:` line names the recorded date; tests pass.
- [ ] T13 Memory bound and gate — files: docs/memory-leaks.md, scripts/release/memory-gate.sh, scripts/release/memory-gate.test.sh — covers: R22 — done when: catalog row and Release gate entry added; memory-gate test passes.
- [ ] T14 Law files L032–L037 as proposed — files: docs/laws/032…037-*.md — covers: law candidates — done when: six files with `status: proposed`, each with a `check:` line naming `result-cache.test.sh` or `result-canary.test.sh`.
- [ ] T15 enact L032 single-change miss — done when: the user sets `status: enacted`.
- [ ] T16 prove L032 via /prove — depends on T6 — done when: `laws-check.js --run` holds.
- [ ] T17 enact L033 no entry for failed or barred units — done when: the user sets `status: enacted`.
- [ ] T18 prove L033 via /prove — depends on T6 — done when: `laws-check.js --run` holds.
- [ ] T19 enact L034 altered entry rejected — done when: the user sets `status: enacted`.
- [ ] T20 prove L034 via /prove — depends on T6 — done when: `laws-check.js --run` holds.
- [ ] T21 enact L035 canary completeness — done when: the user sets `status: enacted`.
- [ ] T22 prove L035 via /prove — depends on T8 — done when: `laws-check.js --run` holds.
- [ ] T23 enact L036 gates start every unit — done when: the user sets `status: enacted`.
- [ ] T24 prove L036 via /prove — depends on T10 — done when: `laws-check.js --run` holds.
- [ ] T25 enact L037 environment allow-list — done when: the user sets `status: enacted`.
- [ ] T26 prove L037 via /prove — depends on T7 — done when: `laws-check.js --run` holds.
- [ ] T27 Handoff and changelog — files: docs/bayan-milestones.md, CHANGELOG.md — covers: R23, R25 (how to switch on, read, clear); nightly scheduling line — done when: handoff section and `[Unreleased]` entry written.
