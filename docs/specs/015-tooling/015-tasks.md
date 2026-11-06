# 015 — Tasks
Plan: ./015-plan.md

- [x] T1 Launcher — files: `scripts/bayan-tool.sh`, `scripts/bayan-tool.test.sh`, `.github/workflows/ci.yml` — covers: R1 — done when: the test passes and fails with `--` dropped.
- [x] T2 Settle port 1 — files: `docs/specs/015-tooling/015-spec.md` (port order row 1), `scripts/parity/run.test.sh` (probe `review-brief`), `work/todo.md` — covers: R2 — done when: `run.test.sh` passes without the mutation-exempt cases.
- [ ] T3 Port `review-brief` — files: `tools/review-brief.byn`, `tests/parity/review-brief/impl`, `scripts/selfhost/{land.sh,wave-brief.py,wave-brief.test.sh}`, delete `scripts/selfhost/review-brief.py` — covers: R5, R6 — done when: `run.sh review-brief` passes every case with the port and `wave-brief.test.sh` passes.
- [ ] T4 Port `plan-strings-check` — files: `tools/plan-strings-check.byn`, `tests/parity/plan-strings-check/impl`, `scripts/selfhost/{preflight.sh,wave-brief.py}`, `scripts/plan-strings-check.test.sh` (new), delete `scripts/plan-strings-check.{js,test.js}` — covers: R5, R6 — done when: `run.sh plan-strings-check` passes every case with the port and the new test passes.
- [ ] T5 S6: named arguments on `Io.run` (`directory:`, `input:`, `env:`) — files: `src/Bayan.Semantics/`, `src/Bayan.Backend.C/CEmitter.cs`, `src/runtime/bayan-rt.{h,c}`, `selfhost/semantics/`, `selfhost/emitter/`, generated `selfhost/driver/runtime.byn`, `tests/cases/{run,diag}/` — covers: R3, R4 (S6) — done when: tmp/015/criteria-t5.md holds and `dotnet test` passes.
- [x] T6 Spec 016: `import std.x` and library source (user, 2026-11-06) — files: `docs/specs/016-*/016-spec.md` — done when: the spec is written and its open questions are with the user.
