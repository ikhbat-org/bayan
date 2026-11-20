---
id: L003
title: Map iterates live keys in first-insertion order
status: enacted
release: 0.1.0
sources: none recorded
kind: invariant
scope: csharp/Bayan.Semantics/Binding/BuiltinMembers.cs
proof: src/driver/mapmodel.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only 'run/map-' && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'map model: '
enacted: 2026-10-20
---

## Statement
After any sequence of `map[k] = v`, `remove`, `clear` and `slot(k)` on a `Map<K, V>`, iteration visits exactly the live keys, each once, in the order each was first inserted since it was last removed (an update keeps its position; a key re-inserted after removal goes to the end); `getOr(k, d)` returns the last value set for every live key and `d` otherwise; `map[k]` panics exactly for keys that aren't live; `length` equals the number of live keys.

## Counterexample looks like
`m[a] = 1; m[b] = 2; m.remove(a); m[a] = 3` iterating as `a, b` instead of `b, a`, `m.length` being 3 after it, or `m[c]` returning a default instead of panicking.

## Proof notes
Proof 2026-11-19 (spec 019 T31b): the proof is the `map model: ` test blocks of src/driver/mapmodel.byn, the port of all 49 MapModelTests (generated sources byte-equal with the C#, the same custom RNG and seeds), so no export is needed. The check runs them (49 passed) after the `run/map-` cases (12 passed); `--only 'map model: zzz-nomatch'` exits 2 (`no test name contains`). The re-insertion break was not rerun in this part.
Break 2026-11-20 (spec 019 T31b, 019-t31b2): commenting out `h->live--;` in `byn_map_remove` (src/driver/runtime.byn:3135, the embedded runtime/bayan-rt.c:2495) made the check fail: `run/map-` 4 of 12 failed (run/map-key-tuple, run/map-many, run/map-model, run/map-slot) and `map model: ` 40 of 49 failed (first `map model: L003 generated sequence matches model (seed: 1, stringKeys: false)`), exit 3; restored, both pass again (12 and 49).
