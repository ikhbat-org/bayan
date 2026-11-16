# Working on Bayān: rules, stack, layout and conventions

How work on the compiler is done. The spec (`docs/bayan-spec.md`) is the source of truth for the language; `AGENTS.md` holds the short agent rules. This file keeps only what neither of them says. The milestones are in `docs/bayan-milestones.md`.

## Ground rules

- `docs/bayan-spec.md` is the source of truth, and Appendix A of the spec lists settled decisions: see `AGENTS.md`. Spec gaps go to `docs/bayan-questions.md`, with the most conservative option implemented until the question is answered.
- Update `docs/bayan-progress-log.md` at the end of every working session (see `AGENTS.md`).
- Prefer small, test-backed steps. Every milestone has acceptance criteria; a milestone isn't done until they pass in CI.

## Stack and constraints

The .NET, NativeAOT, reflection and lexer rules are in `AGENTS.md`. Beyond those:

- Hand-written lexer and recursive-descent parser with Pratt-style expression parsing.
- C output is **C11** and is compiled with `zig cc` (found on `PATH`, or via the `BAYAN_CC` environment variable). Default flags: `-std=c11 -fwrapv -ffp-contract=off` (`-fwrapv` applies to `fast` builds; `debug`/`safe` use checked arithmetic; see M4).
- Target platforms for CI: Linux x64, macOS arm64, Windows x64.

## Repository layout

The main directories (the top level also holds `bench/`, `dist/`, `editors/`, `scripts/`, `site/`, `suq/` and `work/`):

```
bayan/
  src/
    Bayan.Cli/              bayan executable: run, build, test, explain, --version
    Bayan.Syntax/           source text, lexer, tokens, parser, AST, diagnostics
    Bayan.Semantics/        binder, symbols, types, checks
    Bayan.Lowering/         typed AST → lowered tree (seam for DIR later)
    Bayan.Backend.C/        C emitter, toolchain invocation
    Bayan.Testing/
    runtime/                bayan-rt.h / bayan-rt.c: panic, print, bounds checks, arena, list
  selfhost/                 the compiler in Bayān: lexer, parser, semantics, emitter, driver
  bootstrap/                bayan.c and the runtime, the C that builds the self-hosted compiler
  lib/std/                  the standard library written in Bayān
  tools/                    lex-diff, the syntax fuzzer and other tools
  tests/
    Bayan.Tests/            test runner for golden files
    cases/
      lex/        *.byn → *.tokens
      parse/      *.byn → *.ast
      diag/       *.byn → *.diag        (expected diagnostics, exact text)
      run/        *.byn → *.stdout      (+ optional *.exitcode)
                  (and diag-json, emit, manifest, new, out, quality, style, typed)
    native/
    parity/
  docs/
    bayan-spec.md
    diagnostics/BYN0001.md …            one file per diagnostic code (`bayan explain`)
  examples/
    hello/main.byn
    tally-lite/…
```

## Conventions

### Diagnostics

- Every diagnostic has a code `BYN####`, a span, a message, an optional **help** line, and an optional **fix** (replacement text plus span).
- Code ranges: see `AGENTS.md`.
- Rendered format (snapshot-tested):

```
error BYN2104: `total` is immutable

  12 │     total += line.price;
     │     ^^^^^ declared with `let` on line 9
     │
  help: declare it with `var` if it should change
     │  9 │     var total = 0;
```

- Each code has `docs/diagnostics/BYN####.md` (why it exists, an example, the fix). `bayan explain BYN2104` prints it.

### Golden tests

- One input file per case; expected output beside it. `dotnet test` runs everything.
- Updating expected files: see `AGENTS.md`; the diffs are reviewed like code.
- What needs a `diag/` or `run/` case: see `AGENTS.md`.

### C emission

- Names: `byn_<module>_<name>`; struct `T` → `typedef struct byn_<module>_T byn_<module>_T;`.
- `string` → `typedef struct { const uint8_t* ptr; int64_t len; } byn_str;`. Literals are static arrays.
- `Span<T>` → `{ T* ptr; int64_t len; }`, one instantiation per element type.
- Panics: `byn_panic(const char* msg, const char* file, int line)` prints `panic: <msg>` plus location and calls `abort()`.
- `debug`/`safe`: arithmetic through `__builtin_add_overflow` and friends, panicking on overflow. `fast`: plain arithmetic with `-fwrapv`.
- **Bounds checks in every mode** (spec principle 9). Remove only checks the compiler proves redundant (start with `for (let i in 0..xs.length) xs[i]`).
- Emit `#line` directives so debuggers point at `.byn` lines.

## Testing the compiler itself

- Golden tests for every phase (above).
- The lexer and parser are the compiler's untrusted-input surface: add **SharpFuzz** on `bayan parse` once M2 is stable (nightly CI).
- Run **Stryker.NET** on `Bayan.Syntax` and `Bayan.Semantics` before v0.1 to find weak tests.
- Reproducibility: CI compiles `examples/` twice and compares the emitted C byte-for-byte.
