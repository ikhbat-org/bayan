# bench

Local benchmark harness (A2.2 to A2.4). `bench/run.sh` runs by hand and nothing fails on a slow result there; the nightly workflow (below) gates on ratios. Scratch and build outputs go under `tmp/bench/` (gitignored); only `bench/results/*.txt` is committed.

Needs the bootstrap `bayan` (built on demand with `bash scripts/bootstrap-build.sh`, or set `BAYAN_BIN`). `cc`, `rustc`, `zig` and `go` are optional: a missing one prints `n/a (no <tool>)` in its cells.

| Script | Measures | Writes |
| --- | --- | --- |
| `bash bench/run.sh` | Hashing (FNV-1a 64 over 8 MiB, 16 passes) and parsing (decimal integers in CSV lines, 4 MiB, 8 passes) in Bayan, C (`cc -O2`), Rust (`rustc -O`), Zig (`-O ReleaseFast`) and Go (`go build`, default flags), plus the self-hosted lexer (`src/lexer`, `--time`) on `src/semantics/*.byn` concatenated. Each program generates its input from the same LCG seed and times only its work loop with a monotonic clock. Median of `BENCH_RUNS` (default 5) runs, ratio to C. Checksums must agree across languages before the table is printed. | `results/<commit>.txt` |
| `bash bench/baseline.sh` | Clean build time of the self-hosted compiler (`src/semantics` with its `parser` and `lexer` siblings, empty `BAYAN_CACHE`), rebuild time after a one-file change (on a copy), and sizes in bytes of the NativeAOT `bayan` and three goldens (`arithmetic`, `collection-copy`, `collection-literals`) built by it. One run each, wall seconds. | `results/<commit>-baseline.txt` |
| `bash bench/friction.sh` | Counts in `src/**/*.byn` of `unsafe`, `@allow`, `...Unchecked(` calls and `@unformatted`, and the BYN50xx diagnostics `bayan check` reports on the self-hosted package. The textual counts skip comment-only lines but include string literals. | `results/<commit>-friction.txt` |

Tests: `bash bench/run.test.sh`, `bash bench/baseline.test.sh`, `bash bench/friction.test.sh`.

## Go column

`bench/programs/go/hash.go` and `parse.go` do the same work as the C versions and print the same checksums. `go build` is run with no flags. Without `go`, the cells say `n/a (no go)`.

## Nightly run

`.github/workflows/bench-nightly.yml` runs `bench/run.sh` once a day on `dev`, and on demand. It uses two jobs, `ubuntu-latest` and `macos-latest`, each limited to 30 minutes. If `dev` has not moved since the last good run, a job stops at once with "no new commits".

- Results: the table and the ratios are an artifact of the run, kept 14 days. The last good ratios and sha are kept in an `actions/cache` entry per OS.
- Gate: a run fails when Bayan/C on `hash` or `parse` is more than 10% worse than the last stored ratio for that OS. Raw times are printed, never gated. The first run on an OS passes and stores its ratios. A failed run stores nothing.

Sample table:

```
bayan bench 32330daf (Linux x86_64, median of 5 runs, ratio to C, lower is better)
benchmark bayan                    c                        rust                     zig                      go                       checksum
hash     240.1 ms (1.05x)         229.5 ms (1.00x)         229.3 ms (1.00x)         231.7 ms (1.01x)         177.7 ms (0.77x)         12143377579992967301
parse    46.5 ms (0.75x)          61.6 ms (1.00x)          33.9 ms (0.55x)          79.9 ms (1.30x)          45.1 ms (0.73x)          14091657157103084200
lexer    9.8 ms (n/a)             n/a (no port)            n/a (no port)            n/a (no port)            n/a (no port)            -
```

## Notes

- Losses are reported as measured; nothing is dropped.
- The lexer benchmark has no C, Rust, Zig or Go port, so those cells print `n/a (no port)` and it has no ratio to C.
- Bayan's monotonic clock (`Io.monotonicNanos`) ticks in microseconds on this machine, so Bayan timings are microsecond-granular.
- The self-hosted package is built from a copy laid out as `src/app` (semantics), `src/parser`, `src/lexer` with a generated `package.byn` (`capabilities: [.fs]`), because the bootstrap resolves sibling modules from `src/`. The BYN5014 warnings come from that generated manifest having no `grammar`.
- Rebuild after a one-file change appends a function to `bigint.byn` in the copy. The bootstrap rebuilds the whole program, so the rebuild time is about the clean build time (no incremental gain is hidden or claimed).
