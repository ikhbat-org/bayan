---
id: L047
title: Allocation is sound
status: proposed
release: unscheduled
sources: spec 024 R7
kind: property
scope: src/sabk/ra/linear.byn, src/sabk/ra/liveness.byn, src/sabk/check/sound.byn
---

## Statement
For every SIR function the allocator (`allocate`) accepts, without returning a typed error: (a) no two values whose live intervals overlap at any position are assigned the same location (register or spill slot), counting a caller-saved register as clobbered at every call it is live across; and (b) on every control-flow path from entry, every read of a location is preceded by a write of that location holding the value being read. Functions the allocator refuses (more than 8 call arguments, frame over the limit) are not covered.

## Counterexample looks like
A function where a parameter is read after a call at position 0, and `allocate` puts it in `x9`: the call clobbers `x9`, so the read after it sees the callee's value (the bug fixed in df753ad2). Or two overlapping intervals both assigned spill slot `[sp, #24]`.

## Proof notes
Not proven. `/prove` (task T18) runs `checkAllocation` over every SIR test function and a generated set (straight-line, loop and call shapes, 0–40 live values), tagged `Law=L047`. The checker shares no code with `ra/`.
