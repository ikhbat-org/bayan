# 015 — Tasks
Plan: ./015-plan.md

- [x] T1 Launcher — files: `scripts/bayan-tool.sh`, `scripts/bayan-tool.test.sh`, `.github/workflows/ci.yml` — covers: R1 — done when: the test passes and fails with `--` dropped.
- [ ] T2 Settle port 1 — files: `docs/specs/015-tooling/015-spec.md` (port order row 1), `scripts/parity/run.test.sh` (probe `review-brief`), `work/todo.md` — covers: R2 — done when: `run.test.sh` passes without the mutation-exempt cases.
- [ ] T3 Port `review-brief` — files: `tools/review-brief.byn`, `tests/parity/review-brief/impl`, `scripts/selfhost/{land.sh,wave-brief.py,wave-brief.test.sh}`, delete `scripts/selfhost/review-brief.py` — covers: R5, R6 — done when: `run.sh review-brief` passes every case with the port and `wave-brief.test.sh` passes.
- [ ] T4 Port `plan-strings-check` — files: `tools/plan-strings-check.byn`, `tests/parity/plan-strings-check/impl`, `scripts/selfhost/{preflight.sh,wave-brief.py}`, `scripts/plan-strings-check.test.sh` (new), delete `scripts/plan-strings-check.{js,test.js}` — covers: R5, R6 — done when: `run.sh plan-strings-check` passes every case with the port and the new test passes.
