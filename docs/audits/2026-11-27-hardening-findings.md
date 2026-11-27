# Hardening findings (plan 020)
Status: in progress (one entry per finding)
Release: unscheduled
Sources: plan 020 runs

One entry per finding, format from `docs/handoffs/2026-11-27-hardening.md` §5. Repros live in `tests/hardening/known/HF-NNNN/`.

```
HF-0001  Untrusted<bool> assigns to bool without trustUnchecked (string and i64 are rejected with BYN2202)
  oracle:     H7 safety mutants (scripts/hardening/safety-mutate.sh, kind untrusted-to-trusted; source run/untrusted-clean-facts)
  repro:      tests/hardening/known/HF-0001/
  severity:   unsound
  first seen: 70be08e7e (dev)
  status:     open
```
