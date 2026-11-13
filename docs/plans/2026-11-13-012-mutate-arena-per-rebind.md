# Self-hosted mutate: free each mutant's re-bind (arena per rebind)

## Context
The vm2 shard slot died from an OOM kill (VM journal: `shard-7721d71f-2.service: Failed with result 'oom-kill'`, process `program` at 4,433,536 kB). The process was the `SelfhostDefaultT10Tests.SitesJsonMatchesTheCSharpOnEveryRunInput` harness running self-hosted `mutate` over all 333 `tests/cases/run` inputs.

Measured on mb1 with the cached harness:

| What ran | Peak |
|---|---|
| All 333 inputs, `mutate` | 5.5 GB |
| `std-json.byn` alone, `mutate` | 2,375 MB |
| `std-json.byn` alone, `coverage` | 8 MB |

`std-json.byn` has 358 switches, so the cost is about 6.6 MB per mutant.

The cause is `schemataRebinds` (`selfhost/emitter/schemata.byn:815`, the twin of `Schemata.cs:116` `Rebinds`). For each mutation site it recompiles the whole program through `semantics.withFile` (`selfhost/semantics/compile.byn:151`), only to check for errors. Under the `General` allocator nothing is ever freed: `docs/memory-leaks.md` HIGH Q31, decided as option (a), an arena per phase (handoff Q31 note).

This is a product problem, not only a test problem. `bayan test --mutate` built by the self-hosted compiler grows by about 6.6 MB per mutant on any real project.

## Approach
Wrap the per-mutant recompile and its error scan in a scoped arena, the pattern already used in `selfhost/lexer/main.byn:79-80` and `selfhost/parser/main.byn:61`:

```
using let arena = Arena()
var emitted = true
provide allocator: arena {
    var text = List<u8>() ...            // mutated source bytes
    let mutant = semantics.withFile(in c, from: in lexer.SourceText.create(source.path, from: move text))
    for d in mutant.diagnostics { if !d.isWarning { emitted = false; break } }
}
return emitted
```

- Only a `bool` leaves the region. `c` is passed `in` (read-only), and `selfhost/semantics`, `lexer`, `parser` and `emitter` have no module-level mutable state (grep found no top-level `var`/`static`). So nothing allocated in the arena outlives it. The region checker (Q29) rejects any escape at compile time.
- Inside the arena: the per-site whole-file `source` copy (`schemata.byn:817`), `descendants`/`t10SyntaxKey` (`:826-829`), the splice, `withFile`, the error scan. Outside: the panic at `:821-823` (same text). `schemataMarkOf`'s per-site copy (`:805`, only with `@unobservable` marks) is wrapped the same way.
- New code drops the redundant `in` modifier (AGENTS.md, spec §10) unless land.sh's guard requires it at these call sites.
- Accepted residue: the `Symbol` intern table copies into `byn_general` (`bayan-rt.c:2562, 2592`, deduplicated), and each input's base `Ctx` stays in `General` (one compile per input, Q31's broader fix).
- The region checker rejects a lexical escape of `mutant` (BYN3002). It does not prove callees keep no global state; that rests on the no-globals grep (Fable re-checked it: only `const`).
- C# is untouched (the GC already frees). The output is byte-identical, so the existing T10 parity tests (`SitesJsonMatchesTheCSharpOnEveryRunInput`, `MutateSkipsAnInputWithErrorsAndMarksMutantsThatDoNotRebind`, `MutateCMatchesTheCSharpOnEveryRunInput`, `RichFixtureMatchesTheCSharpInEveryBuild`) prove the behaviour.
- `bootstrap/bayan.c` is regenerated (`BAYAN_UPDATE=1` on `BootstrapTests`), as for every `selfhost/` change.
- Lands through `scripts/selfhost/land.sh` (spec 010 rule: guard plus an independent review against the C#).

## Files
- `selfhost/emitter/schemata.byn`: `schemataRebinds`, plus one doc line naming the arena and Q31.
- `bootstrap/bayan.c`: regenerated.
- `tests/Bayan.Tests/SelfhostDefaultT10Tests.cs`: a new bound test (below).
- `docs/memory-leaks.md:78`: the Q31 row's status changes from "open: decision" to option (a), as recorded in the handoff (`bayan-handoff.md:1620`), plus "mutate re-binds: arena per mutant (plan NNN), std-json 2,375 MB → <measured>".
- `tests/Bayan.Tests/SelfhostDefaultT10Tests.cs:114-116`: the "frees nothing yet … 4.4 GB" comment is updated to the new figure.
- `work/todo.md`: no change unless something is found along the way.

## New test
`MutateOfALargeInputStaysBounded` in `SelfhostDefaultT10Tests`: run the harness `mutate RunDir std-json.byn`, sample the peak working set as `SelfhostDefaultBoundsTests.Start` does (`tests/Bayan.Tests/SelfhostDefaultBoundsTests.cs:28-50`; reuse it by making a small shared sampler, or copy its 10-line loop), and assert:
- the output is byte-identical to the C# (`Expected([std-json], RunDir, mutate: true)`);
- `peak > 0` (as `SelfhostDefaultBoundsTests.cs:95`), so a missed sample can't pass vacuously;
- the peak is under a bound. Measure on mb1 **and** the VM (Linux reports the kernel high-water mark, macOS sampling reads low), and set the bound at about 3× the larger figure, rounded up and stated in the test's message. Arena chunks double and resize doesn't reuse blocks, so the per-mutant transient is a few × 6.6 MB; the result is still expected well under 300 MB, versus 2,375 MB today.

The sampler: `SelfhostDefaultBoundsTests.Start` is private and hard-wires its program (`:28-31`). Parameterise it on the program path in a small shared helper. Under `BAYAN_SNAPSHOT` or `BAYAN_COVERAGE` (`SelfhostParserTests.cs:71-75`, `SelfhostSemanticsHarness.cs:60-63`) the sampled process isn't the harness, so the test skips in those modes (check how `SelfhostDefaultBoundsTests` handles them and match it).

Break-test: revert `schemataRebinds` with `git checkout --` and rebuild the harness, then confirm the bound test fails.

## Verification
1. `dotnet test -v q --filter "FullyQualifiedName~SelfhostDefaultT10Tests"`: all pass, including the new bound.
2. Measure: `/usr/bin/time -l <harness> mutate tests/cases/run <all 333>` peak, before vs after; record it in the plan and in memory-leaks.md. Before the fix, also confirm that std-json's site count is 358 and its 2,375 MB peak (Fable didn't re-measure these). The expected after-figure is about the sum of the 333 base compiles, which stay in `General`.
3. The full suite through `shard-test.sh` on the VM in **two slots** (`--host vm=0.91:2:4`): both slots finish, 0 failed. This is the original failure.
4. `laws-check.js --run`, `structure-audit.js`, then `land.sh`, a `--no-ff` merge to dev, unpushed.

## Out of scope
- The 3.0 GB bootstrap stage1 build and the 1.7–2.1 GB `doctor` peaks. Same Q31 cause, different phases; one line in work/todo.md.
- A freeing `General` allocator.
- The `fix/t10-harness-batches` batching stays as merged (decided); it is harmless after this fix.
