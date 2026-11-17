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
For every SIR function the allocator (`allocate`) accepts, without returning a typed error: on every control-flow path from entry, at every read of a virtual register's location (register or spill slot), the most recent write to that location on that path wrote that virtual register's value, and no call between that write and the read clobbers the location (every caller-saved register counts as clobbered at a call). Functions the allocator refuses (more than 8 call arguments, frame over the limit) are not covered.

Corollary: no two values whose live intervals overlap share a location. It follows from the statement and is not proven separately, since it rests on `ra/liveness.byn`'s intervals, which the checker does not use.

## Counterexample looks like
A function where a parameter is read after a call at position 0, and `allocate` puts it in `x9`: the call clobbers `x9`, so the read after it sees the callee's value (the bug fixed in df753ad2). Or two values assigned spill slot `[sp, #24]` where the second's store lands between the first's store and its reload.

## Proof notes
Not proven. `/prove` (task T18) runs `checkAllocation` (`src/sabk/check/sound.byn`), a forward dataflow that shares no code with `ra/`, over every SIR test function and a generated set (straight-line, loop and call shapes, 0–40 live values), tagged `Law=L047`.
