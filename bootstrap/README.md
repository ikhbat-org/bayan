# bootstrap

`bayan.c` is the self-hosted compiler (`src/driver`) as C: stage 1's
`build --emit-c --mode safe --package src src/driver` (spec 012 R11). `bayan-rt.h` and
`bayan-rt.c` copy `runtime/bayan-rt.h` and `runtime/bayan-rt.c` byte-for-byte.

<!-- prose-check: off -->
Build from the repository root with a C11 compiler, no .NET or Zig (flags: the `safe` ones of `src/driver/cc.byn`):
<!-- prose-check: on -->

```
cc -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off bootstrap/bayan.c bootstrap/bayan-rt.c -lm
```

On Windows use `-lshell32` instead of `-lm`.

The result is `a.out`; `./a.out version` prints `bayan <version> (selfhost)`.

<!-- prose-check: off -->
To regenerate the three files with no .NET (spec 019 R26), copy `runtime/bayan-rt.h` and `runtime/bayan-rt.c` here, run `scripts/ci/bootstrap-check.sh`; it fails on a file stale against `src/`, `runtime/` or the previous commit's bootstrap. When it names `bootstrap/bayan.c`, copy the kept C (stage 1 and its C stay in `tmp/bootstrap-check/`) and rerun:
<!-- prose-check: on -->

```
bash scripts/ci/bootstrap-check.sh
cp tmp/bootstrap-check/bayan.c bootstrap/bayan.c
bash scripts/ci/bootstrap-check.sh
```

`scripts/selfhost/land.sh` does this when a change under `src/` or `runtime/` lands.
