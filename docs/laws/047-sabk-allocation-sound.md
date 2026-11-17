---
id: L047
title: Allocation is sound
status: enacted
enacted: 2026-11-17
release: unscheduled
sources: spec 024 R7
kind: property
scope: src/sabk/ra/linear.byn, src/sabk/ra/liveness.byn, src/sabk/check/sound.byn
---

## Statement
For every SIR function in which every virtual register is written on every path before it is read, and which the allocator (`allocate`) accepts without returning an `AllocError`:
- on every control-flow path from entry, at every read of a virtual register's location (register or spill slot), the most recent write to that location on that path wrote that virtual register's value, and no call between that write and the read clobbers the location (every caller-saved register counts as clobbered at a call);
- no two values live at the same point share a location;
- every callee-saved register (x19–x28) the allocation assigns is listed in `usedCalleeSaved`;
- `frameSize` covers every spill slot the allocation assigns.

Functions the allocator refuses are not covered. Lowering (`ra/lower.byn`: argument moves, the x16/x17 scratch, prologue, epilogue, slot offsets) is not covered.

## Counterexample looks like
A function where a parameter is read after a call at position 0, and `allocate` puts it in `x9`: the call clobbers `x9`, so the read after it sees the callee's value (the bug fixed in df753ad2). Or two values assigned spill slot `[sp, #24]` where the second's store lands between the first's store and its reload.

## Proof notes
Not proven. `/prove` (task T18) runs `checkAllocation` (`src/sabk/check/sound.byn`), a forward dataflow that shares no code with `ra/`, over every SIR test function and a generated set (straight-line, loop and call shapes, 0–40 live values), tagged `Law=L047`. The proof asserts that the generated set is accepted (a law over accepted functions holds vacuously if every one is refused). The `Allocation` to `Segment` translation (`segmentsOf` in `sound.test.byn`) is trusted test code.
