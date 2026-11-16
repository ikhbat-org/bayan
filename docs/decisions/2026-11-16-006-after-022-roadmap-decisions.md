# 006 — Decisions after spec 022: order, oracle freeze, test runner, coverage, catch-up, open questions

Status: proposed (awaiting the user's answers on 2, 3, 4 and 6)
Date: 2026-11-16
Input: an independent review by Fable (think worker, key `s022-decisions`) given the full facts and no recommendations; verdicts below are Fable's unless marked otherwise.

## Summary

| # | Question | User so far | Fable's verdict |
|---|---|---|---|
| 1 | Order: 019 (.NET exit) → spec catch-up (023) → 020 (test cache) | yes | Yes, with two changes: split 019 into 019a "suite runs with no .NET" and 019b "delete C#"; measure 020's per-process cost (its task 1) now. |
| 2 | Freeze the C# oracle at the 0.3.2 cut | leaning yes | Yes at a tag, if three conditions hold there (below). If rev 0024 is not ready, freeze anyway and make 0024 the first catch-up item. |
| 3 | `bayan test` features before migrating | wants comparison | Neither (a) nor (b): option (c), a golden runner in the driver, plus `@cases(constList)` (already in spec §20) and a parallel runner. No function-valued `@cases`. |
| 4 | 100% coverage by end of 019, `Io` fault hook | prefers parallel/after | Not an exit condition of 019. Inside 019: a ratchet (no file drops below baseline). The climb to 100% runs in parallel. Fault injection: yes, in the C runtime via an environment variable, not a language hook. |
| 5 | Catch-up spec | yes | Yes: dependency order, a cut line for 0.4, and a "how it is checked" line per item. Write it during 019. |
| 6 | Q1272, Q1186–Q1189 | wants plain explanation | Q1272 reword; Q1186 accept the attributes and exempt all BYN51xx; Q1187 keep scope; Q1188 keep "warn only when sure"; Q1189 keep the particle rule and amend the revision. Settle all five before the freeze. |

## Decided by the user, 2026-11-16 (second message)

- **0.3.2 waits for the site docs.** The cut is delayed until bayan.run names the version it documents and publishes that version's release docs (`bayan_release_docs` in `scripts/release/version.sh`, plus `CHANGELOG.md`) and the roadmap.
- **Sabk** (`bayan build --backend native`) starts after 019a and runs in parallel with the catch-up spec 023 (`docs/bayan-roadmap.md`, Next releases, row 5).
- **Site look.** More neutral background and foreground colours, navy and gold kept as accents, a modular type scale. Three mockups go to the user first.
- **The roadmap is live.** Updated whenever an order or state changes; `scripts/release/cut.sh` refuses a roadmap dated before the previous release; published on the site.

## C# archive plan (019b)

Removing the C# compiler must leave a copy that is easy to find and restore:
1. Before removal, an annotated tag `csharp-final` on the last `dev` commit that still builds and tests the C# compiler, with a message naming the spec 019b commit range.
2. A decision doc `docs/decisions/<date>-NNN-csharp-archive.md` naming the tag, its sha, what it contains (`csharp/`, the xUnit suite, the .NET CI jobs), and the commands to look at or restore it:
   ```sh
   git show csharp-final:csharp/Bayan.Cli/Program.cs
   git worktree add ../bayan-csharp csharp-final
   git restore --source=csharp-final -- csharp/
   ```
3. The removal is its own commit (`chore(019b): remove the C# compiler`), with no other change, so `git log -- csharp/` ends at a commit that says where the code went.
4. The frozen C# compiler stays buildable from that tag for diverse double-compiling (2026-11-13 decision).

The user pushes the tag; the agent never does.

## Facts the brief had wrong

- **Syntax freeze end.** `docs/revisions/0023-syntax-freeze-provisional-sections.md:18` says the freeze lasts "until the 0.3.0 release tag exists", not "until after 0.3.x". If it was extended, that is not written down. Matters for decision 3 (a).
- **`@cases` with computed rows is already in the spec.** §20 (`docs/bayan-spec.md:2338`, `:2369`) has `@cases(discountCases)` "from a const list (xUnit MemberData)", tagged "not in 0.3". Building it is no syntax change. A function-valued `@cases` is not in the spec.
- **`bayan test` runs tests one at a time.** `src/driver/test.byn:348-352` is a plain loop, one `Io.run` per test.
- **The low coverage figures mislead.** Lexer 7%, parser 13%, semantics 47% are the three stage `main.byn` files (128, 114, 195 lines). Real weak spots: `semantics/symbols.byn` 73%, `cli.byn` 75%, `states.byn` 85%, `generics.byn` 86%, `compile.byn` and `calls*.byn` 90%.
- **28 of 111 files (about 24,200 of 88,565 lines) have no figure**, including `lexer/lexer.byn`, most of the parser, `driver/layout.byn` and `driver/runtime.byn`.
- **Two marker conventions.** `coverage-exempt: Qnnn` appears 258 times in `src/`, `coverage-blocked` 25 times. A 100% rule must define both.
- Fixture/collection use is 36 files, not 11. MemberData: 33 files.

## 1. Order

019 first because while C# is the oracle every catch-up feature is built twice; over 4–6 months of catch-up that doubling costs more than all of 019.

Risks the brief missed:
- **The suite gets slower before 020.** After 019, golden cases run as child processes. About 15,000 cases at 100 ms each is 25 minutes sequential, before builds. So the parallel runner belongs in 019.
- **020 depends on an unmeasured number.** `docs/bayan-roadmap.md:105`: 020 task 1 measures per-unit process cost. It is cheap; run it now.
- **019 mixes a reversible and an irreversible job.** 019a: freeze outputs, move tests, suite runs with no .NET. 019b: remove C# from CI, port the language server. Catch-up may start after 019a.

Would change the verdict: if the post-019 suite exceeds about 45 minutes even with a parallel runner, pull a thin slice of 020 (skip unchanged golden cases) ahead of catch-up.

## 2. When to freeze the oracle

A release tag is the right kind of point: frozen outputs then describe a downloadable version. 0.3.2 is right if these hold at that tag:

1. **Rev 0024 (numeric conversions) is in, or explicitly out.** Landing it after the freeze makes it the first feature with no oracle, and it touches arithmetic everywhere.
2. **Message-wording questions are settled** (Q1272, Q1186–Q1189). Each changes `.diag` output; after the freeze there is no second compiler to check a regenerated golden against.
3. **Known divergences are listed.** Wherever the two compilers differ on purpose (the Q-numbered exemptions), the frozen file records which one is right; otherwise a C# bug becomes the expected output forever.

Unnamed risk: after the freeze `BAYAN_UPDATE=1` is the only authority, and a regression looks like an intended change in a diff. Add a rule in 019: a golden-update commit contains only golden files and names the change that caused it.

Recommendation: freeze at 0.3.2 if 1–3 hold. If 0024 is not ready, freeze at 0.3.2 anyway and make 0024 the first catch-up item, its goldens reviewed by hand. Waiting costs more double work than hand-reviewing one feature.

## 3. `bayan test` features before migrating

Most MemberData rows are "every file in a folder", which is what the golden harness does. The largest piece of work is not a language feature: it is porting `Golden.cs` into the driver.

### (a) `@cases` taking a function, plus a parallel runner

```
// Not valid today and not in the spec.
List<string> runCases() uses alloc, fs {
    return Io.listDir("tests/cases/run") catch panic("no cases")
}

@cases(runCases)
test "run golden" (string name) {
    assert(runGolden(name))
}
```

- **Pros:** one reported test per file; `--only` and per-case timeouts work; closest to xUnit.
- **Cons:** the spec says every `@cases` value "must be a constant" (`:2369`). A function means running user code to learn how many tests exist, so discovery, `--only`, 020 cache keys and mutation test indexes all change. Needs a spec revision, and arguably falls under the syntax freeze.
- **Consequence:** `--test <index>` (`test.byn:764`) stops being a compile-time number.

### (a') `@cases(constList)`, as spec §20 already has it

```
// Spec §20 form, tagged "not in 0.3". The const spelling is a guess;
// no const list exists in tests/cases/run to copy.
const boundCases = [(0, false), (1, true), (100, true), (101, false)]

@cases(boundCases)
test "quantity bounds" (i32 input, bool valid) {
    assert(inRange(input) == valid)
}
```

- **Pros:** no syntax or spec change; covers seed lists and tables (`Seeds`, `KeyTypeSeeds`, `Sequences`).
- **Cons:** cannot list a folder. A generated const list of 800 file names would need regenerating whenever a case is added.

### (b) Loops inside one test, plus shell scripts

```
// Syntax is real; whether a test may call Io and declare effects is unverified.
test "run goldens" {
    let names = Io.listDir("tests/cases/run") catch panic("no cases")
    for name in names {
        assert(runGolden(name))
    }
}
```

- **Pros:** nothing to build.
- **Cons:** the first failing file stops the loop, so one run shows one failure out of 812. No per-file `--only`, timeout or 020 cache entry; a timeout loses coverage for everything. Collecting failures and asserting once fixes only the first problem. Shell scripts lose Windows.

### (c) Recommended: golden runner as a driver feature

No test source for golden cases. The driver walks `tests/cases/<kind>/`, runs each case, diffs against the expected file, and reports each as a test. The flag name is illustrative; nothing like it exists yet.

```
bayan test --golden tests/cases
✗ run/suq-packing                        tests/cases/run/suq-packing.byn
  expected line 4: 12 boxes
  actual   line 4: 13 boxes
```

`src/driver/walk.byn` already walks directories and `runTest` already runs a child with a timeout. The missing text diff belongs here, and each case is a natural 020 cache unit (inputs: case file, expected file, compiler binary).

### Comparison

| | (a) function | (a') const list | (b) loops | (c) driver goldens |
|---|---|---|---|---|
| Syntax or spec change | yes, needs a revision | none | none | none (a CLI flag) |
| Per-case reporting | yes | yes | no | yes |
| Folder-driven rows | yes | only if generated | yes | yes |
| Fits 020 cache | harder | yes | no | best |
| Windows | yes | yes | no (shell) | yes |
| Work | runner redesign | small | none | medium, mostly a port of `Golden.cs` |

**Recommendation: (c) for goldens, (a') for tables, a `--jobs` worker pool around the loop at `test.byn:348`.** Fixtures need no feature: each Bayān test is its own process, so shared setup becomes a build step the driver does once (compile the compiler under test, then run cases against it). Least certain part: check the 36 fixture files against that claim before committing.

Would change the verdict: if many of the 33 MemberData files compute rows from code and are neither folders nor constant tables, (a) becomes worth a revision.

## 4. Coverage

Size of the gap (`tests/quality-baseline.json` plus line counts):

| Area | Lines | Unmeasured lines | Uncovered in measured files (lower bound) |
|---|---|---|---|
| semantics | 43,078 | 6,080 | about 2,500 |
| parser | 12,515 | 6,434 | about 390 |
| driver | 16,861 | 7,846 | about 220 |
| emitter | 11,864 | 96 | about 220 |
| lexer | 4,247 | 3,767 | about 160 |

Of 83 measured files, 20 are at 100% lines, 14 at 100% branches, 55 at 95% or more. Each was measured under one task's filter, so a whole-suite run will raise most at no cost.

Effort, wide error bars:
- Whole-suite coverage run and a baseline for all 111 files: 1–2 days. Do first; every other estimate depends on it.
- Semantics tail (symbols, cli, generics, states, compile, calls): 2–4 weeks of small goldens after the whole-suite run shrinks the list.
- Driver error paths: about 180 `Io.` call sites; 15 `coverage-exempt` markers under Q1219 alone stay exempt without fault injection.
- The three stage `main.byn` files: delete if the unified driver replaced them, or three CLI cases.

**100% by end of 019: no.** Tying a number to the migration deadline produces markers, not tests (283 exist already). Inside 019: a ratchet, no file below its baseline; a dropped C# test shows up as a drop.

**Parallel, as its own track**, starting with the whole-suite baseline. Overlaps 019 only in `tests/cases/` (both add files). Finish before catch-up is far along: new features with full coverage are cheaper than retrofits.

**`Io` fault injection: yes, in the C runtime.** Spec §20's long-term answer is `Io.Simulated` and `provide` handlers, both unbuilt; a test-only language hook would be a second mechanism to remove later. `runtime/bayan-rt.c` returns `uint32_t` error codes from every `byn_io_*` call, so an environment variable read there (like `BAYAN_MUTANT` and `BAYAN_COVERAGE`) can make the Nth call of a named operation return a chosen code. No syntax, no semantics; the driver sets it per child. Risk: it must be compiled out of release runtimes.

Would change the verdict: if the whole-suite run shows every file above about 97%, a 100% gate at the end of 019 becomes cheap enough.

## 5. Catch-up spec (023)

Beyond an ordered list:
- **Dependency order.** `std.regex` blocks 015 T15; `Io.run` streaming blocks 015 T17; `provide` handlers before simulated `Io`; `@derive` before derived law tests; property tests need `requires`-driven generation; `comptime` and concurrency (§13 is a placeholder) last.
- **A cut line** for 0.4; the rest stays spec-only with its status tag.
- **A "how it is checked" line per item**: goldens reviewed by a person, or a second method (property tests, the frozen C# binary where it supports the feature).
- Test tooling (property, fuzz, simulated `Io`) early: it replaces part of what the oracle gave.

## 6. The open questions in plain language

`docs/decisions/2026-11-14-004-answered-questions.md:918` schedules Q1272 "after 0.3.0" without a wording. Q1186–Q1189 are listed there with decision date "not recorded"; each has a current behaviour in the code. All five change diagnostic output in both compilers, so decide them before the oracle freeze.

### Q1272: the error says `requires` when you wrote `expects`

`expects` is a condition on a function's arguments; `requires` is a rule on a type. Two messages written for `requires` are reused for `expects` (BYN2320, BYN2321).

```
i32 width(i32 start, i32 end) expects start <= end { return end - start }
let w = width(5, 2)
```

- Today: "`5` violates `requires start <= end` of `width`"
- Proposed: "`5` violates `expects start <= end` of `width`"

**Recommendation: reword.** The message quotes a keyword the user did not type and sends them looking for a clause that is not there.

### Q1186: fields renamed for JSON or a database still get naming warnings

The naming lints check that a name reads well. A field whose outside name is set by an attribute (`@json`, `@column`) was meant to be exempt. Today the plural lints (BYN5104/5105) skip such a field, the older ones (BYN5101/5102) do not, and the attribute itself is rejected as unknown (BYN2770).

```
struct Row {
    @column("items") List<Item> item    // argument form is a guess; the entry says "any arguments"
}
```

- Today: BYN2770 "unknown attribute"; BYN5104 skipped; BYN5101/5102 would still fire.
- Proposed: the attribute is accepted, and every BYN51xx lint skips the field.

**Recommendation: do it.** Today's state is inconsistent three ways, and the exemption is useless while its attribute is an error. `attribute` declarations are spec-only, so accept only these two names for now and say so.

### Q1187: which declarations the singular/plural lint checks

BYN5104/5105 check that a collection has a plural name and a single value a singular one. Checked today: public struct fields and properties, parameters of public functions and methods, public interface members, public union payload fields. Not checked: anything non-public, locals, constants, tests, lambdas, `main`, `bool` values.

```
public void pack(Span<i32> order) { … }      // warned: a collection named in the singular
void helper(Span<i32> order) { … }           // not warned: not public
```

**Recommendation: keep this scope and write the list into the revision.** Public names are what other people read; warning on every local buries the useful warnings. Also verify `T[]` resolution, which the entry marks unverified.

### Q1188: how the compiler knows a word is plural

There is no dictionary of every English word. The lint uses the project's `forms` list, then regular spelling rules (`-s`, `-es`, `-ies`), and warns only when it recognises the word.

```
public struct Cart {
    public List<Line> line          // warned: `line` is a known noun, not plural; fix: `lines`
    public List<Line> covered       // not warned: `covered` is not a known noun
    public Person people            // warned, no fix offered: irregular plural, singular unknown
}
```

The revision could be read as "warn on everything not provably plural"; the code does "warn only when sure".

**Recommendation: keep "only when sure".** A lint that guesses wrong on `covered` or `distinct` gets switched off and then catches nothing. Add singulars to the irregular list (`people` → `person`) so a fix is offered there too.

### Q1189: which word in a name decides singular or plural

The revision says the last word decides. On the compiler's own source that gave wrong advice:

```
Map<string, Module> modulesByDir     // last-word rule: `Dir` is singular → rename to `modulesByDirs`
```

The code uses the word before the first particle (`by`, `of`, `in`): `modules` decides and the name passes; `lineByName` is flagged and fixed to `linesByName`. Names that start with a particle (`byPath`, `inGroup`) are not checked.

**Recommendation: keep the code's rule and amend the revision.** `modulesByDirs` is worse English than what was written. Record the `byPath` gap in the revision.

## Noticed, not acted on

- `docs/bayan-spec.md` §20 code fences are tagged `csharp`; the rule against describing Bayān that way may want a different tag.
- Spec §20 says `assert expr` takes no parentheses; all four `tests/cases/run/*.test.byn` files write `assert(...)`.

## Decided by the user, 2026-11-16 (third message)

- **2 (oracle freeze): yes.** Freeze the C# outputs at the 0.3.2 tag under the three conditions in §2.
- **4 (coverage): agreed.** Not an exit condition of 019; a no-drop ratchet inside 019, the climb to 100% as its own track, `Io` fault injection in the C runtime.
- **3 (test runner) and 6 (Q1272, Q1186–Q1189):** the owner asked for more examples; sent 2026-11-16 with real compiler output. Correction found while preparing them: Q1188's `people` already gets the fix `person`.
- **Site look:** mockup b for the light theme, mockup c for dark mode.
