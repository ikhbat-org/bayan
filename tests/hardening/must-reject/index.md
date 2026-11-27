# Must-reject index: safety rules and the diag goldens that cover them
Status: in progress (step 8a: index of existing cases; new cases come in later steps)
Release: unscheduled
Sources: docs/handoffs/2026-11-27-hardening.md §H7; docs/plans/2026-11-27-020-hardening.md Order row 8; tests/cases/diag; docs/bayan-spec.md

Each list line is `- diag/<case>: <code>[, <code>]`; the code is one the case's expected output shows. `scripts/hardening/must-reject-index.sh` checks every line. Lists name a sample of the large groups, not every case: `grep -l <code> tests/cases/diag/*.diag` finds the rest. A gap is a sub-case the spec states that no listed case shows.

## Regions and borrows

Spec: `docs/bayan-spec.md` §9.4 (rules 1-8), §3.16 (lambda capture). Codes: BYN3001, BYN3002, BYN3003, BYN2708.

- diag/borrow-field: BYN3001
- diag/borrow-own-field-mutated: BYN3001
- diag/borrow-state-payload: BYN3001
- diag/borrow-escapes-region: BYN3002
- diag/lambda-escapes-region: BYN3002
- diag/owned-escapes-arena: BYN3002
- diag/union-borrow-escapes-region: BYN3002
- diag/map-key-string-part: BYN3002
- diag/region-provide-declared: BYN3002
- diag/region-combo-all-three: BYN3002
- diag/borrow-returned: BYN3003
- diag/dyn-ref-returned-local: BYN3003
- diag/region-copy-list: BYN3003
- diag/region-copy-span: BYN3003
- diag/region-fixpoint-chain: BYN3003
- diag/region-transfer-out-return: BYN3003
- diag/union-borrow-payload: BYN2708

### Gaps

- Borrow passed to a fiber outliving the referent, BYN3217: no case (spec §9.4 rule 8, second sub-bullet; fibers are not in 0.x, §13).
- `arena.reset()` needs exclusive access: no case shows a reset while a borrow is alive (spec §9.4 rule 6).

## `ref` and `out` escape

Spec: `docs/bayan-spec.md` §9.4 rules 3 and 8, §10 (parameters). Codes: BYN3002.

- diag/ref-out-escape-ref: BYN3002
- diag/ref-out-escape-out: BYN3002
- diag/ref-out-escape-out-field: BYN3002
- diag/ref-out-escape-ref-element: BYN3002
- diag/ref-out-escape-list-append: BYN3002
- diag/ref-out-escape-map-slot: BYN3002
- diag/ref-out-escape-ref-this-field: BYN3002
- diag/ref-out-escape-local-alias: BYN3002
- diag/ref-out-escape-two-levels: BYN3002
- diag/ref-out-escape-call-result: BYN3002
- diag/ref-out-return-one: BYN3002
- diag/ref-out-return-through-local: BYN3002
- diag/ref-this-store-through-later-method: BYN3002

### Gaps

- none found (spec §9.4 rule 3 is exercised through ref, out, `ref this`, collections, aliases, calls and recursion; the `ref`/`out` rules have no separate spec sentence beyond §9.4).

## `unique` and `move`

Spec: `docs/bayan-spec.md` §3.11, §9.3. Codes: BYN2780, BYN2781, BYN2782, BYN2784, BYN2788, BYN2789, BYN2790, BYN2791, BYN3209, BYN2615.

- diag/unique-implicit-copy: BYN2780
- diag/unique-param-store: BYN2780
- diag/unique-struct-containment: BYN2780
- diag/with-unique-copy: BYN2780
- diag/lambda-capture-unique: BYN2780
- diag/map-copy: BYN2780
- diag/unique-use-after-move: BYN2781
- diag/unique-move-in-branch: BYN2781
- diag/unique-move-in-loop: BYN2781
- diag/switch-move-use-after: BYN2781
- diag/ownership-defer-move-break: BYN2781
- diag/move-narrowed-use-after: BYN2781
- diag/unique-move-from-field: BYN2782
- diag/lambda-move: BYN2782
- diag/move-with-parenthesized: BYN2782
- diag/collection-copy-unique-element: BYN2784
- diag/take-unsupported: BYN2788
- diag/switch-move-field: BYN2789
- diag/switch-move-overlap: BYN2790
- diag/switch-move-guard-mutate: BYN2791
- diag/generic-guard-mutate-rebind: BYN2791
- diag/unique-const: BYN3209
- diag/panic-handler-reads-moved: BYN2615

### Gaps

- Runtime ownership check in debug builds (`second owner of`, `use of moved`) is a panic, not a diagnostic, so it is not in diag (spec §9.3).

## Mutation while borrowed

Spec: `docs/bayan-spec.md` §9.4 rule 5. Codes: BYN3004, BYN3005, BYN3006, BYN2783.

- diag/mutated-while-borrowed: BYN3004
- diag/borrow-then-mutated-in-initializer: BYN3004
- diag/call-result-borrows-ref-argument: BYN3004
- diag/for-user-modified-while-iterating: BYN3004
- diag/map-modified-while-iterating: BYN3004
- diag/lambda-capture-borrow-modified: BYN3004
- diag/this-ref-call-modifies-borrowed-field: BYN3004
- diag/region-loop-back-edge: BYN3004
- diag/region-defer-lifo: BYN3004
- diag/strbuf-finish-then-clear: BYN3004
- diag/ref-and-value: BYN3005
- diag/dyn-ref-list-element-ref-and-value: BYN3005
- diag/region-alias-ref-this: BYN3005
- diag/region-alias-this-field: BYN3005
- diag/region-transfer-ref-collect: BYN3005
- diag/moved-while-borrowed: BYN3006
- diag/strbuf-loan-refusals: BYN3006
- diag/unique-borrowed-mutation: BYN2783
- diag/map-copy: BYN2783
- diag/switch-move-use-after: BYN2783

### Gaps

- `arena.reset()` while borrowed: see regions Gaps (spec §9.4 rule 6).

## Effects and capabilities (`uses`)

Spec: `docs/bayan-spec.md` §14. Codes: BYN6002, BYN6003, BYN6004, BYN6005.

- diag/effect-not-declared: BYN6002
- diag/effect-for-enumerator: BYN6002
- diag/effect-direct-after-indirect-span: BYN6002
- diag/lambda-effects: BYN6002
- diag/fs-copy-needs-fs: BYN6002
- diag/env-get-needs-env: BYN6002
- diag/time-now-needs-clock: BYN6002
- diag/symbol-intern-needs-alloc: BYN6002
- diag/unknown-effect: BYN6003
- diag/function-type-unknown-effect: BYN6003
- diag/capability-exceeded: BYN6004
- diag/capability-direct-after-indirect: BYN6004
- diag/capability-direct-before-indirect: BYN6004
- diag/effect-bound-exceeded: BYN6005
- diag/for-unique-item: BYN6005
- diag/lambda-effects: BYN6005

### Gaps

- none found (every code BYN6002 to BYN6005 has a case).

## `Untrusted<T>` taint

Spec: `docs/bayan-spec.md` §15.1. Codes: BYN2786, BYN8006.

- diag/run-untrusted: BYN2786
- diag/run-batch-untrusted: BYN2786
- diag/expects-reads-untrusted: BYN8006

### Gaps

- Sinks other than process arguments: file path segment, redirect URL, outbound HTTP, sizes and bounds, regex, header values, decoding limits (spec §15.1 sink table); BYN8004 is spec-only and has no case.
- Layer 1, a `string` where a sink type is expected, BYN8003 (spec §15.1): spec-only, no case.

## Typestate

Spec: `docs/bayan-spec.md` §3.17. Codes: BYN7001, BYN7002, BYN7003, BYN7004, BYN7005, BYN7007, BYN7008, BYN7009, BYN7010, BYN7011, BYN7012.

- diag/wrong-state: BYN7001
- diag/wrong-state-member-test: BYN7001
- diag/states-branch-no-else: BYN7001
- diag/states-join-stale-loop-if-no-else: BYN7001
- diag/this-narrowing: BYN7001
- diag/payload-not-in-state: BYN7002
- diag/states-defer-local: BYN7002
- diag/assignment-changes-state: BYN7002
- diag/become-undeclared: BYN7003
- diag/clause-order-inserts: BYN7003
- diag/state-switch-not-exhaustive: BYN7004
- diag/state-literal-needs-state: BYN7005
- diag/participle-changes-this: BYN7005
- diag/unknown-state: BYN7007
- diag/conformance-interface-receiver-state: BYN7007
- diag/state-shadows-static: BYN7008
- diag/missing-become: BYN7009
- diag/become-without-ref-this: BYN7010
- diag/becomes-needs-ref: BYN7010
- diag/becomes-on-ref-parameter: BYN7011
- diag/generic-body-changes-state: BYN7012
- diag/generic-ref-changes-state: BYN7012

### Gaps

- none found.

## `expects` and `requires` contracts

Spec: `docs/bayan-spec.md` §7.9. Codes: BYN2320, BYN2321, BYN5011, BYN1063, BYN3206, BYN3207, BYN3208, BYN3218.

- diag/requires-not-bool: BYN2320
- diag/requires-literal-violated: BYN2321
- diag/requires-violated: BYN2321
- diag/state-literal-violated: BYN2321
- diag/literal-needs-try: BYN3207
- diag/checked-field-assignment: BYN3208
- diag/requires-mixes-fields: BYN3218
- diag/rule-target-not-field: BYN3206
- diag/requires-on-function: BYN1063
- diag/expects-single-parameter: BYN5011

### Gaps

- A runtime `expects` or `requires` violation is a panic or `ValidationError`, not a diagnostic, so it is not in diag (spec §7.9; belongs to run cases).
