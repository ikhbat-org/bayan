---
id: L038
title: Format is idempotent and meaning-preserving
status: proposed
release: unscheduled
sources: spec 022 R4
kind: property
scope: src/driver/format.byn, src/driver/layout.byn
proof: src/driver/l038.test.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test --package src src/driver --only 'L038:'
---

## Statement
For every `.byn` source that `bayan format` accepts and every `style` setting, formatting the output again gives the same bytes, and the C that `bayan build --emit-c` prints for the formatted program equals the C for the original program apart from source line and column numbers (`#line` directives and the positions the C passes to runtime failure messages, such as `byn_unreachable(file, line)`).

## Counterexample looks like
A source and a `style`, with the first line where the second format differs from the first, or the first line of emitted C that differs between the original and the formatted program.

## Proof notes

Proven 2026-11-28 by `src/driver/l038.test.byn` (5 `L038:` blocks): 380 single-file `run/` cases under the default style, and 22 named cases under all 64 combinations of `booleans`, `primitives`, `align`, `trailingCommas`, `indent` (4/2) and `width` (120/60). Emitted C is compared after dropping `#line` and replacing the line in `w->line = <n>` and `byn_file_<k>, <n>` with `L`. Mutation: `formatCommand` writing the first `+` as `-` made all 5 blocks fail, the first with `L038 counterexample: run/call-result-ref-plain-struct.byn ... byn_add_i64 against byn_sub_i64`. Breaks inside `formatFile` or the layout are not reachable by the second-format check, since `formatFile` loops until the bytes stop changing; no run case spells `and`/`or`/`not`, so words-to-symbols respelling is not exercised. Status stays proposed: the owner approved the wording 2026-11-28 and enacts.
