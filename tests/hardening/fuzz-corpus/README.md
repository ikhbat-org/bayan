# Fuzz corpus

Seeds for `scripts/hardening/fuzz.sh --afl` (plan 020 step 5, H8). Only the `.byn` files here are seeds; this README is not
copied to AFL.

Where they came from: 36 single-file inputs copied unchanged from `tests/cases/`, 12 from each of `run/`, `diag/` and
`parse/`. Each name is the source directory plus the original file name (`run-switch.byn` is `tests/cases/run/switch.byn`). They
were picked as every n-th file, in byte order, of that directory's top-level `.byn` files of at most 4096 bytes, so the set
spans the alphabet rather than one feature.

Limits: at most 40 files, each at most 4096 bytes. `fuzz.sh --afl` refuses to run when a file is over the size limit or the set
is over the count limit.

New inputs: AFL's interesting inputs are not added here automatically. After `fuzz.sh --triage`, a crash or a new path worth
keeping is copied in by hand, under the limits above, with a name saying what it reaches.
