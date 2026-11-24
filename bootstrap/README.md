# bootstrap

`bayan.c` is the self-hosted compiler (`src/driver`) as C: the C that stage 1 emits for
`build --emit-c --mode safe --package src src/driver` (spec 012 R11). `bayan-rt.h` and
`bayan-rt.c` are byte-for-byte copies of `runtime/bayan-rt.h` and `runtime/bayan-rt.c`.
`scripts/ci/bootstrap-check.sh` fails when any of the three differs from what it copies or what the previous commit's bootstrap builds.

Build it with a C11 compiler and no .NET or Zig, from the repository root (the flags are the
`safe` ones of `src/driver/cc.byn`):

```
cc -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off bootstrap/bayan.c bootstrap/bayan-rt.c -lm
```

The result is `a.out`; `./a.out version` prints `bayan <version> (selfhost)`.

Regenerate the three files with no .NET (spec 019 R26): copy `runtime/bayan-rt.h` and `runtime/bayan-rt.c` here, then
run `bash scripts/ci/bootstrap-check.sh`. When it reports that `bootstrap/bayan.c` is not the C that `src/driver` emits,
copy the C it kept (stage 1 and its C stay in `tmp/bootstrap-check/`) and run the check again:

```
bash scripts/ci/bootstrap-check.sh
cp tmp/bootstrap-check/bayan.c bootstrap/bayan.c
bash scripts/ci/bootstrap-check.sh
```

`scripts/selfhost/land.sh` does this when it lands a change under `src/` or `runtime/`.
