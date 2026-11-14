# Bayān milestones

What v0.1 was, its milestones M0 to M12, what came after, and the road to self-hosting. The coarse table of releases is `work/milestones.md`; the plan after 0.3.0 is `docs/bayan-roadmap.md`.

## Index

These docs replace the former v0.1 work plan and its two addenda (split 2026-11-14):

| Doc | Holds |
|---|---|
| `docs/bayan-milestones.md` | What v0.1 is, M0–M12, after v0.1, zero dependencies, the pinned `bayan`, self-hosting readiness and the spec table (this file) |
| `docs/bayan-contributing.md` | Ground rules, stack and constraints, repository layout, conventions, testing the compiler itself |
| `docs/bayan-questions.md` | Open questions |
| `docs/decisions/2026-11-14-004-answered-questions.md` | Answered questions, with their full text |
| `docs/bayan-progress-log.md` | The progress log |
| `docs/design/laws-contracts-and-parallel-iterators.md` | Design for opt-in laws, contracts and `.par()` (formerly addendum 002) |
| `docs/decisions/2026-11-14-005-read-only-spans-and-float-formatting.md` | `ReadOnlySpan<T>` and float formatting (formerly addendum 001 §1) |

## What v0.1 is

**Status:** shipped as 0.1.0 on 2026-11-02 (`CHANGELOG.md` [0.1.0]).

A bootstrap compiler, written in **C# on .NET 10, published with NativeAOT**, that compiles a useful subset of Bayan to C and then to a native executable via `zig cc`.

**Exit criterion:** `bayan run examples/hello/main.byn` prints `Hello, world!`, and `bayan test examples/tally-lite` passes (a reduced version of the tally example, defined in M8).

The bootstrap compiler is temporary: Bayan will eventually self-host. Optimize for clarity and correctness first, then speed.

### Explicitly out of scope for v0.1

Comptime beyond constant folding · the DIR interpreter · async and `Io.Evented` · user-defined generics (built-in `Span<T>` and `List<T>` only) · derivations (except automatic equality) · interfaces and `dyn` · unions · Java-style enum data · units · regions for borrowed **fields** (see M6) · packages and `package.byn` beyond a minimal form · FFI beyond the runtime's own C · prose translation · LSP · formatter.

## Milestones

### M0 — Skeleton

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

- Solution layout above; `bayan --version`; NativeAOT publish in CI on all three platforms.
- Golden test runner with update mode.
- Diagnostic data model and renderer (with a hand-built diagnostic in a unit test).

**Done when:** CI is green on all platforms and `bayan --version` runs from the AOT binary.

### M1 — Lexer

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

- UTF-8 input; NFC check on identifiers (normalize or report, BYN0005); reject bidi control characters outside string literals (BYN0001).
- All tokens in spec §2: keywords (including reserved ones, which must be rejected as identifiers), identifiers (Unicode), integer literals with `_`, hex, binary; floats with exponents; char literals (32-bit scalars, `\u{…}`); strings, raw `"""` strings, `$"…{expr}…"` interpolation (lex nested expressions), `c"…"`; comments; `///` doc comments kept as trivia attached to the next token.
- Unit suffixes are lexed as a suffix token on numeric literals (semantics come later); reject them on hex/binary literals.
- Recovery: an invalid character produces a diagnostic and lexing continues.

**Done when:** `lex/` golden cases cover every token kind and every lexer diagnostic; lexing a 1 MB file allocates only the token array.

### M2 — Parser

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

Grammar for the v0.1 subset:
- Module-level functions; `struct` with fields (defaults, `required`, `readonly`), properties (`=>` getters), constructors, methods, `public`/`private`.
- Statements: `let`/`var`/`const`, assignment and compound assignment, `++`/`--`, expression statements, `return`, `if`/`else`, `unless` (reject `else`, reject `unless (!x)`), **postfix modifiers** (simple statements only, spec §7.3), `while`, `for (let x in a..b)` / `for (let x in xs)`, labeled `break`/`continue`, `switch` statements (no fall-through, optional trailing `break`), `defer`, `errdefer`, blocks.
- Expressions with C# precedence plus `..`, `..=`, `^`, `+%`, `+|`, `??`, `catch`, `try`, `is` with patterns (constant, relational, `and`/`or`/`not`, `var`, `_`, property, list with slices), `switch` expressions, calls with named arguments, member access, indexing, struct literals `T { f = v }` and target-typed `{ f = v }`, collection literals `[…]`, `$"…"` interpolation, casts `(T)x`, tuples.
- `new` accepted (and noted for the formatter); `goto` produces BYN1010 with the labeled-break fix-it.
- Error recovery at statement and declaration boundaries; one missing `;` must not produce a cascade.
- `bayan parse --ast file.byn` dumps the AST (used by golden tests).

**Done when:** `parse/` cases cover every construct above, and `diag/` cases cover the common syntax errors with helpful messages.

### M3 — Semantics I: names, types, mutability

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

- Module = directory; `import`; name resolution across files in a module; visibility (`private` / module / `public`).
- Types: primitives (sized names preferred; C# aliases accepted), `string`, `char`, `bool`, structs, tuples, `T?`, `never`, fixed arrays `T[N]`, built-in `Span<T>` and `List<T>`.
- Untyped integer literals adopt their context type; out-of-range literals are errors.
- Implicit lossless widening only; explicit narrowing casts.
- Casing rules (spec §5.1) as **errors**.
- `let` immutability, immutable parameters, definite assignment, `required` fields, unreachable code after `never`.
- Named-argument rules: same-typed parameters and `bool` parameters must be named at call sites.
- `string` has no indexer (BYN2201 with the four fix-its from spec §3.2).

**Done when:** every rule above has passing and failing `diag/` cases.

### M4 — C backend: hello world

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

- Lower the typed AST to a simpler tree (`Bayan.Lowering`) and emit C from that. Keep this seam: DIR replaces it later.
- Runtime: `print`, `panic`, string literals, integer formatting for interpolation, checked arithmetic.
- `bayan build` / `bayan run` invoke `zig cc`; build modes `debug`, `safe`, `fast`.
- Interpolated strings write into a stack buffer and print (no allocation for `print($"…")`).

**Done when:** `examples/hello/main.byn` runs on all platforms; `run/` cases cover arithmetic, overflow panics in `safe`, structs, methods, control flow, postfix modifiers (with the condition evaluated first — include a case proving the statement isn't evaluated when the condition is false), labeled break, and `switch`.

### M5 — Errors

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

- `error enum` declarations with doc comments; `fails` clauses (explicit sets; inferred sets for private functions only); multiple sets; `Result<T, E>` as a type.
- `try`, `catch value`, `catch return …`, `catch (e) switch { … }` with exhaustiveness, `?? return / break / continue`.
- `defer` and `errdefer` with reverse-order execution; bodies may not contain `try` (BYN2601).
- `$"{e}"` prints the doc-comment summary.
- `main` that fails prints the error and exits with code 1.

**Done when:** `run/` cases cover every form, including cleanup order on success and failure, and `diag/` cases cover non-exhaustive `catch` and `try` inside `defer`.

### M6 — Memory basics

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

- Slicing: `xs[a..b]`, `xs[^1]`, `xs[1..^1]`, strings by byte offset (panic mid-code-point), with bounds checks.
- `stackalloc T[N]` (constant `N` only in v0.1).
- `Arena` and `context (allocator: …) { … }`; `List<T>` allocates from the context allocator; `General` allocator as the default for `main`.
- `.copy(to: alloc)`.
- **Region rules, conservative version:** borrowed values (`Span<T>`, string slices) may be locals, parameters and return values, but **not struct fields** in v0.1 (BYN3001, "storing borrows in structs arrives in a later version; copy the data instead"). Enforce spec §9.4 rules 3, 4 (conservative: all arguments) and 5 (no structural mutation while a local borrow is alive).

**Done when:** `run/` cases cover slicing and arenas; `diag/` cases cover a borrow escaping its region, mutation while borrowed, and `List` modified while a span of it is alive.

### M7 — Tests

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

- `test "name" { … }` blocks, in the same file or `x.test.byn`; `assert(cond)` with the expression text in the failure message; `bayan test` compiles test binaries (tests stripped from normal builds), runs each test, catches panics per test (run each test in a child process for v0.1), and reports pass/fail with timing.

**Done when:** `bayan test` runs a suite with passing, failing and panicking tests and reports each correctly.

### M8 — tally-lite (exit criterion)

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

A reduced version of the tally example in `examples/tally-lite`, using only v0.1 features:
- `money`: `Cents` as a plain `i64` alias (no units yet), `Money` struct, `parseAmount` with `fails MoneyError`, `formatInto` into a stack buffer.
- `ledger`: `Expense` storing participants as `List<string>` copied into the arena (no borrowed fields), `splitEvenly`, `balances` (use a `List` of `(string name, i64 cents)` pairs if `Map` isn't ready), `settle`.
- A `main` that reads a hard-coded ledger (file I/O optional) and prints transfers.
- Tests: the unit tests from the original tally example that apply.

Expected output for the sample trip:
```
dina pays alice 91.82 MYR
chen pays alice 59.12 MYR
bob pays alice 1.28 MYR
```
(Verified against a reference implementation: balances alice +15222, bob −128, chen −5912, dina −9182 cents.)

**Done when:** `bayan run` prints the output above and `bayan test examples/tally-lite` passes.

### M9 — `bayan new` and `bayan init`

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

```
bayan new <name>             # app (default)
bayan new <name> --lib       # library
bayan new <name> --script    # single-file script
bayan init [--lib|--script]  # in the current directory (refuses if package.byn exists)
  --vcs git|none             # default: git, when git is installed and not already inside a repository
  --ci github|none           # default: none
```

**Generated app layout:**

```
tally/
  package.byn                 manifest (data only)
  README.md                   name, one-line description, how to run and test
  .gitignore
  .gitattributes
  .editorconfig
  src/
    app/
      main.byn                print("Hello, world!");
  tests/
    app.test.byn              one passing test calling into the app module
  testdata/                   (empty, with .gitkeep)
  docs/                       (empty, with .gitkeep)
  out/                        not created until the first build; ignored
  dist/                       not created until `bayan dist`; ignored
  gen/                        not created until a generator runs; ignored
```

**Library layout** replaces `src/app/main.byn` with `src/<name>/<name>.byn` (one public function and a doc comment) and `tests/<name>.test.byn`. **Script layout** is a single `<name>.byn` with a shebang, `#:io threaded`, and nothing else (no manifest, no git).

**Generated `package.byn` (app):**

```csharp
Package {
    name    = "local/tally",      // `local/` until the user publishes under a verified namespace
    version = "0.1.0",
    edition = 2027,
    kind    = .app,
    capabilities = [],
    deps    = [],
    dist = Dist {
        targets = [.host],        // expands to the machine's own target; see M11
        mode    = .safe,
    },
}
```

**`.gitignore`:**
```
/out/
/dist/
/gen/
```
Lockfile policy (name superseded 2026-11-06: the lockfile is `package.lock.byn`, `docs/bayan-design-round-4-inventory.md` batch 1): `bayan.lock` is committed for apps and libraries alike (reproducible builds); do not ignore it.

**`.gitattributes`:**
```
* text=auto eol=lf
*.byn linguist-language=C#
```
(The `linguist-language` line gives `.byn` files C# highlighting on GitHub until Bayan has its own grammar there.)

**`.editorconfig`:** UTF-8, LF, 4-space indentation, final newline, trim trailing whitespace.

**`--ci github`** adds `.github/workflows/bayan.yml` running `bayan build` (or `bayan check` for a library) and `bayan test`; it does not run `bayan format --check` yet.

**Git behavior:** run `git init` only if `--vcs git` (the default), git is on `PATH`, and the target isn't already inside a work tree (`git rev-parse --is-inside-work-tree`). **Never commit, branch or configure anything.** If git is missing, print a note and continue.

**Acceptance:**
- Golden cases under `tests/cases/new/`: the full file tree plus every file's contents for app, lib and script, snapshot-tested.
- A freshly generated app passes `bayan run` and `bayan test` with no edits.
- `bayan init` in a non-empty directory adds missing files only and lists what it skipped.
- Names are validated (camelCase-or-kebab directory names allowed, package names lowercase with `-`), with teaching diagnostics.

### M10 — Build outputs: `out/` and `dist/`

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

Two different directories with different jobs:

| Directory | Contents | Lifetime |
|---|---|---|
| `out/` | Everything `bayan build`, `run` and `test` produce: emitted C, objects, binaries, test reports | Disposable; per worktree; ignored |
| `dist/` | Versioned release artifacts from `bayan dist` | Kept; immutable per version; ignored by git by default |

**`out/` layout:**
```
out/
  <mode>/<target>/            e.g. out/debug/linux-x64/
    c/                        emitted C (kept for inspection)
    obj/
    tally                     the binary
  test/
    results.json              machine-readable test results
```

**`dist/` layout:**
```
dist/
  0.1.0/
    linux-x64/tally
    linux-arm64/tally
    macos-arm64/tally
    windows-x64/tally.exe
    SHA256SUMS
    BUILDINFO.json
  0.2.0/
    …
  latest/                     a copy of the newest version directory
    VERSION                   contains "0.2.0"
    linux-x64/tally
    …
```

Rules:
- **Target names:** `linux-x64`, `linux-arm64`, `macos-x64`, `macos-arm64`, `windows-x64`, `windows-arm64`, `wasm32`. `.host` in `package.byn` resolves to the current machine. `bayan dist --target all` builds every target `zig cc` supports from the current host.
- The version comes from `package.byn`. **A version directory is immutable:** `bayan dist` refuses to overwrite an existing `dist/<version>/` unless `--force`, and says to bump the version instead.
- `latest/` is a **copy, not a symlink** (symlinks need privileges on Windows and break in archives). It is rebuilt atomically: write to `dist/.latest.tmp/`, then rename. "Newest" means the highest semantic version present, not the most recent build.
- `SHA256SUMS` lists every artifact in the version directory.
- `BUILDINFO.json`: package name and version, compiler version, mode, targets, source commit hash and whether the tree was dirty (if in a git repository), and a hash of the inputs. This is the seed of the isnād provenance chain.
- `bayan dist` refuses to run from a **dirty git tree** unless `--allow-dirty` (recorded in `BUILDINFO.json`).
- Libraries: `dist/<version>/<target>/` contains the static and shared libraries plus the generated C header, once FFI export exists; until then, `bayan dist` on a library reports that library distribution arrives later.
- Scripts have no `dist`.
- `bayan clean` removes `out/`; `--dist` also removes `dist/`; `--cache` clears the global cache (M11). Nothing is removed without one of these commands.

**Acceptance:** golden tests for both layouts (tree listings, `VERSION`, `SHA256SUMS` format, `BUILDINFO.json` schema); immutability and `latest` selection tested with multiple versions; cross-compiling at least `linux-x64`, `macos-arm64` and `windows-x64` from one host in CI.

### M11 — Global cache and worktrees

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

- **Location:** `$BAYAN_CACHE` if set; otherwise `$XDG_CACHE_HOME/bayan` or `~/.cache/bayan` (Linux), `~/Library/Caches/bayan` (macOS), `%LOCALAPPDATA%\bayan\cache` (Windows).
- **Content-addressed:** keys are hashes of (compiler version, mode, target, flags, input content). In v0.1 the unit is the emitted C file and object per module; with DIR it becomes per function.
- **Safe under concurrency:** several worktrees and several agents may build at once. Write to a temporary file and rename atomically; never lock the whole cache; a corrupted entry is detected by its hash and rebuilt.
- **No absolute paths in any output.** `#line` directives and debug info use paths relative to the package root, so cache entries are valid in every worktree and every checkout location.
- `out/` is always local to the worktree; only the cache is shared.
- **Script caching:** `bayan run script.byn` caches the compiled binary under the cache key (source, directives, compiler version); a cache hit starts the binary directly.
- `bayan cache stats` and `bayan clean --cache`.

**Acceptance:** two worktrees of the same repository building the same commit — the second build compiles nothing (asserted from cache statistics); parallel builds of the same package in two directories never corrupt the cache (stress test); moving a project directory does not invalidate its cache hits.

### M12 — CLI completeness and machine-readable output

**Status:** shipped in 0.1.0 (`CHANGELOG.md` [0.1.0]).

- **`--diagnostics json`** on `build`, `run`, `test`: one JSON object per diagnostic (code, severity, file, span, message, help, fixes). Coding agents and editors consume this instead of parsing text.
- **`bayan test --json`** writes results to stdout in the same format as `out/test/results.json`.
- **Exit codes:** `0` success · `1` compile errors · `2` usage errors · `3` test failures · `4` toolchain problems (missing `zig`, unwritable cache). Document them in `bayan --help`.
- **`bayan run`** exits with the CLI code (`1`) when compilation fails; once the program starts, its exit code passes through unchanged (a failing `main` exits `1`, or its `[ExitCode]`). So `bayan run` cannot tell a build failure from a program exiting `1`: anything that needs the distinction runs `bayan build` first or reads `--diagnostics json`. (Same as `cargo run` / `go run`.) CLI tests cover a build failure, a program exiting `0`, and one exiting with a custom code.
- **Color:** on for terminals; off when piped, when `NO_COLOR` is set to a non-empty value, or with `--color never`; `--color` overrides the environment.
- **`bayan doctor`:** reports compiler version, `zig` path and version, git availability, cache location and writability, and the host target. Every failure has a fix suggestion.
- **`bayan test --changed`** (simple version): uses `git diff --name-only` against `HEAD` (or `--base <ref>`) and runs tests in modules whose files changed. Read-only git use only.
- **`bayan --version`** prints the compiler version and the commit it was built from.

**Acceptance:** golden tests for JSON diagnostics and test output; exit codes asserted in `run/`-style CLI tests; `bayan doctor` tested with a missing `zig` (via `BAYAN_CC` pointing nowhere).

- [x] **Output style** (`docs/design/laws-contracts-and-parallel-iterators.md` §6): `docs/bayan-terminal-style.md` is normative for this milestone's output and for the future `bayan laws` report. The output shipped before it predated the guide; implementing the guide in full, with golden tests in colour, with `NO_COLOR` and with `--ascii` (Q57), was spec 005, done 2026-10-22 (spec table below).

## After v0.1 (for orientation only)

Status: the plan as written for v0.1, kept for orientation. The current plan is `docs/bayan-roadmap.md` and `work/milestones.md`.

v0.2: DIR + interpreter (comptime, scripts), generics, interfaces, unions, enums with data, units, `Map`, iterators, `Io.Blocking`/`Threaded`, JSON/CSV, property and fuzz tests, borrowed struct fields with full region inference.
v0.3: fibers and `Io.Evented`, networking, HTTP, TLS through a C wrapper, WASM.
Formatter, LSP, prose tool and packages land across v0.2–v0.4.
Laws, contracts and parallel iterators (`docs/design/laws-contracts-and-parallel-iterators.md`, formerly addendum 002): opt-in `law` declarations and `bayan laws` (v0.2), `requires`/`ensures` contracts (runtime v0.2+, `bayan verify` v1.x), `.par()` parallel iterators (v0.3). Design only; its §1 (reserve `law requires ensures`) is done.

### Design inputs (filed 2026-11-04)

Filed from the user, for round 4 (after 012) and later; none changes 011–013. Open contradictions and decisions: `docs/misc/2026-11-04-design-inputs-review.md`.

- `docs/bayan-design-round-4-draft.md`: now with the clause order `where → expects → uses → becomes → fails` (first commit after 012: flip BYN1065, `bayan format` the repo) and C-only interop (the .NET interop question is closed).
- `docs/bayan-shorthands-proposal.md`: round-4 syntax batch (views `T[]`, implicit type parameters, `some I`, `.member`, `T[U]`, …).
- `docs/bayan-style-proposal.md`: layout rules for `bayan format` and `docs/bayan-style.md`, idiom lints; §3.4 needs a grammar revision.
- `docs/bayan-concurrency.md`: thread-per-core fibers, `scope`/`spawn`, cancellation, locks; spec in round 4, runtime in v0.2 (this section's v0.3 line predates it).
- `docs/bayan-views.md`: `markup` and `@element` views, provisional; `kit.web`/`kit.ui`, v0.2+.

### Target: zero dependencies (set by the user 2026-11-02)

Building, testing and shipping Bayan should need nothing but Bayan. Today it needs:

| Dependency | Used for | Leaves when |
|---|---|---|
| .NET 10 SDK | the C# compiler, the test suite | spec 019 (approved 2026-11-13, written after 0.3.0, est. 4–7 weeks): C# test outputs become goldens run by `bayan test` and shell, the language server is ported to Bayan, CI builds from `bootstrap/bayan.c`. The C# compiler stays frozen for diverse double-compiling, run weekly or per release; the Visual Studio extension stays .NET |
| zig 0.17.0 (or a system cc/clang/gcc, host builds only) | C compiler and cross-target libc (`Toolchain.FindCompiler`) | approved 2026-11-13: toolchain phase 3 (v0.4 plan, B12) removes zig, leaving any C compiler; phase 4, sabk, Bayan's own debug backend to machine code (`bayan build --backend native`; parking lot B04, now scheduled after spec 019), removes the C compiler for debug builds. LLVM (clang or zig) stays for release builds |
| Python 3 | `scripts/ci/known-failures.py`, `scripts/selfhost/*.py`, `scripts/quality/*.py`, `scripts/unicode/gen-lowercase.py` | the scripts are rewritten as Bayan scripts (the interpreter, v0.2) |
| bash, curl, tar/unzip, sha256sum/shasum | `scripts/**/*.sh`, `scripts/ci/install-zig.sh` | the same |
| PowerShell | `scripts/selfhost/wp1-test.sh` (the remote command runs on wp1, a Windows host) | the same |
| Node / VS Code | `editors/vscode/extension.js` (the extension runs inside VS Code) | an LSP server in Bayan leaves only the editor's own host |
| Node 24 (Actions) | `upload-artifact`/`download-artifact` only; no CI step of ours runs on Node | checkout, the .NET SDK and zig install from shell steps (spec 015, T4); the artifact actions stay |

Rule from now on: add no new dependency without the user's say; when touching a script or a workflow step, prefer the option that removes one.

### Pinned bayan for gates and tooling (spec 015, decision T2 in `docs/decisions/2026-11-02-002-tooling-port-rules.md`)

Gates and tooling run `bayan` from `scripts/pinned-bayan.sh`, never the working tree's build, so a broken compiler change cannot disable the gate meant to catch it. The helper resolves `dev`'s tip (every commit there is a merge), builds `src/Bayan.Cli` from a `git clone --shared` checked out at that commit into `<main checkout>/.cache/bayan/<sha>/` (shared by all worktrees, git-ignored) if it is missing, and prints the binary's path. The pin follows `dev`; nobody edits it. A failed build exits 1 naming the commit and its build log; there is no fallback.

- `PINNED_BAYAN_REF` pins another ref; CI's mutation run passes `HEAD` (a depth-1 checkout has no `dev` branch).
- `PINNED_BAYAN` (tests only) names the binary to print instead.
- Callers today: `scripts/selfhost/mutation-step.sh` (the guard's and `mutate-batch.sh`'s `bayan mutate`). The compiler's own tests, and writer probes (`scripts/selfhost/bayan-cheatsheet.md`), still use the working tree.
- Test: `bash scripts/pinned-bayan.test.sh`, local only: its scratch repo commits need a git identity, which CI runners lack and repo-local identities are refused here.

## Self-hosting readiness

`docs/bayan-self-hosting.md` lists what a compiler needs from its own language. Spec 001 (`docs/specs/001-self-hosted-lexer/`) covers phases 1 and 2; milestones M13–M23 continue the numbering above. Correction to that doc's table: file I/O and program arguments were **not** in v0.1; M13 adds them.

| Needed for | Feature | Status |
|---|---|---|
| Reading source files | File I/O, UTF-8 strings, slicing | strings and slicing v0.1; file I/O and args M13 |
| Error reporting | `fails`, error unions, `defer` | v0.1; `[ExitCode]` M13 |
| Fast allocation of syntax trees | Arenas, `context` allocator | v0.1; growable strings M14 |
| Tokens and diagnostics | Structs, fixed arrays, `List<T>` | v0.1; enums M16–M17, static `const` arrays M16 |
| Syntax-tree nodes | Unions + exhaustive `switch` | M18; recursion through `Owned<T>` M21 |
| Symbol tables | `Map` / `HashMap`, `Symbol` interning | `Map` M20; `HashMap` and interning next spec |
| Reusable passes | Generics, interfaces, iterators | generics M19; interfaces and iterators next spec |
| Nodes referring to source text | Borrowed struct fields (full regions) | byte offsets (v0.1); full regions later spec |
| Running `zig cc` | Spawning processes | M15 (`Io.run`, `Io.listDir`) |
| Tests | `test` blocks, `property`, `fuzz` | `test` v0.1; `property`/`fuzz` next spec |

Phase 1 tool: `tools/lex-diff/` (M15). Phase 2: `selfhost/lexer/` checked against the C# lexer by the test suite (M22–M23).

**Friction found porting the lexer (T19).** The port needed no compiler changes, but these cost the most and are candidates for the next spec:
- Must-name rule (BYN2305): ~100 errors; it fires even when argument names equal the parameter names (`fromBounds(start, end)`).
- Returning borrows (BYN3003): a method can't return a span borrowed from its own `List` field; `return sb.asString()` from a local growable `StrBuf` is rejected (workaround `$"{sb.asString()}"`); `string f(span) => utf8(span)` is treated as borrowing the argument.
- No span fields (BYN3001), so source bytes live in a `List<u8>`. Ref aliasing (BYN3005) rejected `renderAll(ref sb, ref result.source, result.diagnostics.asSpan())`.
- `var x = 0` is `i32` while `.length` is `i64`: every position needs an explicit `i64`.
- `error` and `flags` are keywords, so they can't be names.
- No `catch { block }`; no bytes→string conversion (decode appends `$"{(char)cp}"` per scalar); no hex format specifier; no `const string[]`; no delegates; no `List.removeRange`.

**Friction found porting the parser (009).** The port needed no compiler changes beyond making lexer items `public` with `uses alloc` (Q431), but these shaped the code and are candidates for later specs:
- `Owned<T>` payloads and unique node unions (Q436, Q446, Q451, Q461, Q471): `.value` is read-only (BYN2106) and a field cannot be moved out of `Owned` (BYN2782, no `take` on `Owned`), while any node union holding a `List` is unique (BYN2780), so `doc`, `attributes`, `tryKeyword` and split field `requires` rules must be set before wrapping in `Owned`, `a except 1..2` rewinds and reparses the constant instead of moving its child out, `checkUnlessCondition` recurses through `.parenExpr` instead of an `Unwrap` reference return, and readers take nodes `in`.
- No tuple destructuring or field moves (Q450, Q477, Q487): `let (a, b) = …` does not parse and moving out of a tuple or local struct field is BYN2782, so `parseNameThenType` writes the type through a `ref` parameter, `parseParenOrTuple` parses the first element from parts, and `Sexp` is inlined because there is no `params` and move-only union children cannot be put in a list.
- Borrow tracking on decoded strings (Q452, Q455, Q477): `StrBuf.finish()` borrows the local buffer (BYN3003 on return) and a `string` returned from a function taking a byte span counts as borrowing that span (BYN3004 when `p` is used again in a loop), so literal decoders and callers copy with `$"{…}"` in the arena.
- Flow typing on fields and `is`-pattern syntax (Q472, Q480, Q486): `is not null` narrows locals and parameters, not field paths (`d.value.failsKeyword` stays nullable, BYN2211; workaround `if (d.value.failsKeyword is { } fails)`), an empty property pattern `if (x is { } n)` must be parenthesized (BYN1002), a payload variant in `is` needs `(_)` (BYN2705), a pattern binding named like a keyword (`as`) misparses, optionals require `is null`/`is not null` (BYN2027), and `unless` rejects `&&`/`||` (BYN1022).
- Package-root, module and declaration limits (Q430, Q431, Q451, Q480): `bayan build <dir>` has no package-root option so `selfhost/parser` is built through `Compilation.Create`; a struct literal cannot be module-qualified (`lexer.TextSpan { … }` is BYN1001, needing `type` aliases); tuple and `List` parameter defaults are not constant (BYN2219); a parameter sharing its function's name shadows the function in recursive calls (BYN2220).
- Missing library pieces (Q440, Q442, Q475): `List` has no `removeAt` (`unreport` tombstones diagnostics with `code: ""` and skips them in `errorCount` and the dump); there is no Unicode case table so `startsUpper`/`startsLower` are ASCII-only.
- Particles, naming and reserved words (Q431, Q437, Q452, Q461, Q472): the particle rule (BYN5004/BYN5006) requires particles on non-object required parameters (moving cursor and report helpers to `ref this` methods on `Parser`), bool literal arguments must be named (BYN2305), dropped results require `let _ = …` (BYN3201), C# flag and helper names raise BYN5014 word warnings with no `package.byn` under `selfhost/`, and non-contextual keywords (`float`, `import`, `struct`, `if`, `requires`, `except`, `try`, `unless`, `default`) require `…Keyword` or `…Decl`/`…Stmt` suffixes.

**Friction found porting the semantics (010).** The port needed no compiler change beyond the 009 visibility edits and the T28 fixes recorded in its Questions; what it needed and did not get:
- Language: no `public const` (Q520), no tuple or struct-field moves, so shared state is index-addressed arenas (`Ctx`, handles) and every borrow shape of 009 returns; C# immutable collections and `HashSet` became lists and `Map<string, i64>` keys (Q640, Q655); parameter defaults must be constants (Q526); `stripParens` cannot return an expression from a unique union (Q703).
- Process: cross-file calls went through compiling stubs with final signatures (010-api.md) and per-task stand-ins until T28 merged them; the stand-ins are gone (no `// stub:` marker remains in `selfhost/semantics/`), but T28 still owes the stale-citation and unreached-arm lines in `work/todo.md`.
- Not got: `bayan-check --time` prints parse plus check, not the declare/bind/analysis split (Q648); a working-directory builtin, so paths are passed absolute (R1); a C# parser that does not throw on random input, so L018 and L023 stay proposed (Q509, Q662, Q663); a Windows run of the new tests (the UTF-8 harness fix is unmerged, `work/todo.md`).

**Bootstrap from `bootstrap/` (012).** `bootstrap/bayan.c` is the C that stage 1 emits for `build --emit-c --mode safe --package selfhost selfhost/driver`; `bayan-rt.h` and `bayan-rt.c` are byte copies of `src/runtime/`, and `BootstrapTests` fails when any of the three differs. With a C11 compiler and no .NET or Zig, from the repository root:

```
cc -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off bootstrap/bayan.c bootstrap/bayan-rt.c -lm
```

The result is `a.out`, and `./a.out version` prints `bayan <version> (selfhost)`. `BAYAN_UPDATE=1 dotnet test --filter FullyQualifiedName~BootstrapTests` regenerates the three files, and `scripts/selfhost/land.sh` does it when a change under `selfhost/` or `src/runtime/` lands (Q1045). Byte identity is claimed per host only; L027 leaves cross-host identity as a future strengthening (Q975 made `Target.os` and `Target.arch` preprocessor constants so the file is host-neutral).

**Friction found porting the driver (012).** The port needed compiler and runtime additions that earlier ports did not; what it needed and did not get:
- Host state with no builtin (Q919, Q970, Q975, Q978, Q1007): the driver could not read the terminal, the environment or the host, so the user decided on `Target.os`/`Target.arch`, `Env.get` and `Fs.fileExists` (a named exception to the no-new-builtin rule), emitted host-neutral as preprocessor constants; the selfhost bound tree had to mirror the new `BoundHostTarget` record, and `Target.os` is not a constant expression without `--target`.
- Processes and files (Q1009, Q1016, Q1042): `Io.run` has no working directory, so compiler diagnostics name `<dir>/main.c` where the C# says `main.c` (open); with no delete or directory builtin the scratch files stayed beside the output and `run` built beside the program, until `Io.remove`, `Io.createDirectory` and `Io.removeDirectory` were decided (Q1042, Q1026).
- The driver compiling itself found two checker faults (Q1017, Q1031, Q1032, Q1035): a static call through a `type` alias bound to an error expression with no diagnostic, and modules numbered in load order instead of the C# post-order. The user chose one renumber pass after loading; there is no debug-only assert form, so the checks that follow it are plain `assert` statements and the selfhost checker's safe-mode C changes (Q1034, decided 2026-11-05).
- No terminal style in the selfhost (Q941, Q947): the lex and parse dumps, the check summary, the progress line and `--ascii`/`--color` diagnostics differ from the C# on a terminal or with a style flag; the user decided a small spec after 012.
- Cut or accepted divergences (Q917, Q940, Q1018, Q1052): the refusal text has no C# oracle; `parse` without `--ast` is refused because no Bayan renderer prints one file's syntax diagnostics with a path; `-o` into an existing directory fails with BYN4001 where the C# reports a cache error; `diag/` and `run` stderr are compared with the C# CLI because the golden `.diag` is not what any command prints.
- Cost (Q1019, Q1043, Q1055): the C# builds the driver in about 33 s; unset-tier L027 and L028 fit the 3-minute budget, but the `full` tier of L028 takes 13 m 51 s against `timeout: 900` (open).
**Friction found porting the emitter (011).** The port widened `public` in `semantics` and added a bound-node syntax side table to the binder (T21); what it needed and did not get:
- Language: import cycles are rejected, so the lowered tree lives in its own `ltree` module and the arenas are a struct passed beside `Ctx` (Q759); every ported entry point that builds a string needs `uses alloc` written into `011-api.md` (Q788, Q855); `parser.Expr` owns its children, so the bound tree's syntax is kept as a non-owning copy in a side table (Q849, Q850).
- Process: a task whose lines run only once a sibling lands needed compiling stubs with final signatures and `coverage-blocked` markers (Q838, Q845); clearing the markers fell to the owner task and needed dispatcher decisions (Q872, Q875, Q878).
- Process: matching the C# `locals` and temps took a task of its own (T22, Q877, Q879, Q882–Q884).
- Not got: a Windows run of the new tests, since `Path.relative` panics on an empty package root from `/`-only path scans (Q886) and the failing tests sit in `tests/windows-known-failures.txt` until spec 014 (Q757, Q816, Q886, Q888); a cheap line lookup by default: `lineOf` scanned the file on every call and emit ran 120 times slower than the C# until a line-start table was built once per file (Q827); the selfhost parser lacked the C# parser's O3 step for `requires` after a member, so T13 ported it (Q819).

### Road to self-hosting (decided 2026-10-21, revised the same day)

Run unattended, one spec at a time, each merged into `dev` (unpushed) with its worker spend in the progress log. Decisions:

- **Interfaces (§3.15):** static dispatch on constraints (monomorphized), `dyn ref I` fat pointers, default methods, and associated types (`IEnumerator` with `Item`, so `for … in` works on user types). `static abstract` only if the port needs it; retroactive conformance waits.
- **Lambdas and function types (§3.16):** function types (`A -> B`, named with `type` aliases), named functions as values, non-capturing lambdas, and lambdas that capture `let` values and parameters **by copy** (a struct with fields). `ref` captures of `var` and escaping closures wait.
- **Regions (§9.4):** deferred past bootstrap; syntax nodes and tokens keep byte offsets into a source buffer, as `selfhost/lexer/` does.
- **Finish line:** the Bayan compiler does `lex`, `parse`, `check`, `build` (incl. `--emit-c`) and `run`; stage 2's generated C is byte-identical to stage 3's; the full golden suite passes against the Bayan-built compiler; `bootstrap/bayan.c` is committed. Met by 012 on 2026-11-06 in branch: the driver does `lex`, `parse --ast`, `check`, `build` (incl. `--emit-c`) and `run`; stage 2's C equals stage 3's in `safe` and `debug` on one host (`BootstrapTests`); the golden suite runs against stage 2 (`SelfhostDriverGoldenTests`); `bootstrap/bayan.c` is committed. Spec 017 ported every remaining command, the cache and `--json`; from 0.3.0 the release binary `bayan` is the self-hosted compiler (stage 2, built by stage 1, which the C# CLI builds; `bayan-lsp` stays C#), see row 017 of the spec table.
- **Argument names (BYN2305):** an argument that is an identifier equal to its parameter's name, or a member access whose last segment is (`tok.start` for `start`), counts as named. Arguments whose names match the parameters in a swapped order are an error.
- **Contextual keywords:** every declaration-only keyword is contextual: `error`, `flags`, `unit`, `distinct`, `open`, `extensible`, `set`, `type`, `law`, `derivation`, `attribute`, `embed`. Control-flow and expression keywords stay reserved. Both lexers change together (L001).
- **Integer literal typing:** an untyped integer literal initializing an unannotated `var` takes its type from the variable's first constraining use in the same function (assignment, comparison, arithmetic or argument involving a typed value); unconstrained, it is `i32`. Spec update, plus a typed dump of bound declarations (no typed dump exists yet; only the syntax `AstDump` used by `parse/` goldens) that records each local's resolved type, with goldens for: constrained to `i64`, unconstrained `i32`, constrained by a comparison, by an argument, and by an assignment. `fmt --explicit` shows the type once `bayan fmt` exists; spec 004 records that as a Question. The typed dump is stable and deterministic, with a documented JSON form (`docs/` page): entries in declaration order, then by source position; no addresses, hash-order output or run-specific IDs (symbols are named by path and span). Spec 010 uses it for a binder-equivalence law between the C# and Bayan binders, as L001 does for the lexers.
- **Laws:** a law a spec proposes is enacted in the same change as its passing proof (standing authorization, 2026-10-21); a law without a proof stays proposed.

Spec order (numbers are provisional; a spec may split):

| Spec | Scope |
|---|---|
| 003 | **Done 2026-10-21.** Ownership verification: ownership program generator, debug runtime ownership checker, `take()`, `switch (move x)`; L006 `take()` row back as an amendment; prove L008 |
| 004 | **Done 2026-10-21.** Port friction: implied and swapped argument names, contextual declaration keywords, integer literal inference, returning borrows from a method's own fields, fallible bytes→string decode, `catch { block }`, `const` string arrays, `List.removeRange`, `toHex()` (format specifiers stay deferred, Appendix B) |
| 005 | **Done 2026-10-22.** Terminal style (remaining work of M12 — CLI completeness and machine-readable output), before any renderer is ported again |
| 006 | **Done 2026-10-23.** Interfaces and iterators (subset above) |
| 007 | **Done 2026-10-25.** Lambdas and function types (non-capturing and capture by copy) |
| 008 | **Done 2026-10-25.** `Symbol` interning (§3.3) and `Map` keys (§3.5): `Symbol` with compile-time literals and `Symbol.intern`, composite tuple and struct keys hashed field by field; `HashMap` is BYN2830 with a fix to `Map` (revision 0013, Questions 371–381); L015 "Interning is identity on text", L016 "Equal keys are one entry" |
| 009 | **Done 2026-10-26.** Parser in Bayan (`selfhost/parser/`), checked against `bayan parse --ast` on every parse golden; L017 "Parser equivalence" enacted; L018 "No parser panic" proved but kept proposed (C# counterexamples, Q509–Q510) |
| 010 | **Done in branch 2026-11-01 (not yet merged to `dev`).** Semantics in Bayan (`selfhost/semantics/`, `bayan-check`), checked against every `diag/` and `typed/` golden (1,068 parity rows pass), the generator seeds and a 1 MB input (ratio 1.42 against `bayan check`); L022 "Binder equivalence" enacted; L023 "No checker panic" proved but kept proposed (C# parser counterexamples, Q662, Q663) |
| 011 | **Done in branch 2026-11-04 (not yet merged to `dev`).** Lowering and the C emitter in Bayan (`selfhost/emitter/`, `bayan-emit`), checked against `--emit-c` on every `run/` golden (parity 290 of 290, T13), the generator seeds and the R7 speed test (ratio 120 -> 1.26, asserted <= 10, Q827); L024 "Emitter equivalence" and L025 "No emitter panic" enacted and proved (`laws-check --run`: 25 enacted, 0 proposed; L024 makes 2,632 comparisons quick and 9,544 comparisons full, L025 reaches emission with 51 of 1,000 corrupted inputs quick and 533 of 10,000 full); `FullyQualifiedName~SelfhostEmitter`: 1684 passed, full `dotnet test Bayan.slnx -c Release`: 8860 passed (T14); batch mutation scores are added to `tests/quality-baseline.json` by the dispatcher |
| 012 | **Done in branch 2026-11-06 (not yet merged to `dev`).** Driver in Bayan (`selfhost/driver/`: `lex`, `parse --ast`, `types`, `check`, `build` with `--emit-c`, `run`); `BootstrapTests` builds stage 1 (C#), stage 2 and stage 3 and finds stage 2's C equal to stage 3's in `safe` and `debug`; `SelfhostDriverGoldenTests` runs the golden suite against stage 2; `bootstrap/bayan.c`, `bayan-rt.h` and `bayan-rt.c` are committed with a README `cc` command; L027 "Bootstrap fixpoint" and L028 "Driver equivalence" enacted and proved. Batch mutation (T22) is parked, and 012 builds on 014 (`Path`) before 014 reaches `dev` (Q949) |
| 017 | **Done in branch 2026-11-12 (not yet merged to `dev`).** The self-hosted compiler as the default `bayan`. Every command of the C# CLI now runs in the driver (`explain`, `features`, `clean`, `cache`, `new`, `init`, `doctor`, `audit`, `format`, `test` with all its flags, `mutate`, `dist`), with `--diagnostics json`, the build cache and terminal paint; T14 extends the L028 tests to every command on the run/, diag/ and CLI corpora with a written-files comparison, and drafts a proposed amendment (`docs/laws/028-driver-equivalence.md`, "Proposed amendment (017 T14)") that waits for the user to re-enact; L028 itself is unchanged (`status: enacted`, `timeout: 1200`). T15 adds the R6 speed check, T16 the R7 bounds rows through stage 2, T19 the diagnostic and summary paint, and T20 the format package style and primitive renames. T17 switches the release: `release.yml` builds stage 1 with the published C# CLI and stage 2 with stage 1, and `package.sh` packs stage 2 as `bayan`; `bayan-lsp` stays C#. The stage commands, as in `.github/workflows/release.yml`: stage 1 `./publish/${{ matrix.exe }} build --mode safe --package selfhost -o "$RUNNER_TEMP/stage1-${{ matrix.exe }}" selfhost/driver`; stage 2 `"$RUNNER_TEMP/stage1-${{ matrix.exe }}" build --mode safe --package selfhost -o publish/${{ matrix.exe }} selfhost/driver`. Open for the user: (a) L028's amended front matter: re-enactment and the timeout. Measured 2026-11-12 on wp1 at 667d3c8e: full tier 1557 passed, 0 failed, 37 m 11 s of tests, 2246 s wall, of which about 4 min overlapped another wp1 run. The rule (measured x 1.5, rounded up to 5 min) gives `timeout: 3600` (60 min), not the earlier proposed 1800. The run is above 25-30 min, so the choice is between that timeout on every merge and gating merges on the fast tier with the full L028 tier nightly and pre-release; not picked; (b) the release dry run: the trigger is `workflow_dispatch` (Q1264, decided and implemented), but the run itself needs a push and the `dev` to `main` merge and has not happened; (c) the memory gate (R7): the rows and figures are in Q1226-Q1229, the release gate has not been run for 0.3.0 |
