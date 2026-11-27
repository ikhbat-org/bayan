# Working on Bayān: rules, stack, layout and conventions

Version: 0.4.1 (matches `bayan --version`)

How compiler work is done. The language: `docs/bayan-spec.md`; agent rules: `AGENTS.md`; this file holds only what neither says. Milestones: `docs/bayan-milestones.md`.

## Ground rules

- The spec (`docs/bayan-spec.md`) is the source of truth; Appendix A holds settled decisions (`AGENTS.md`). Gaps go to `docs/bayan-questions.md`; implement the most conservative option until answered.
- Update `docs/bayan-progress-log.md` at the end of every working session.
- Small, test-backed steps; a milestone must pass its CI acceptance criteria.

## Stack and constraints

Stack and lexer rules are in `AGENTS.md`; beyond them:

- Hand-written lexer; recursive-descent parser with Pratt-style expressions.
- C output is **C11**, compiled by `zig cc` from `PATH` (else `cc`, `clang` or `gcc`) or by `BAYAN_CC`. Defaults: `-std=c11 -fwrapv -ffp-contract=off`; `fast` wraps, `debug`/`safe` check (M4).
- CI targets: Linux x64, macOS arm64, Windows x64.

## Repository layout

Other top-level directories: `bench/`, `dist/`, `editors/`, `scripts/`, `site/`, `suq/`, `work/`.

```
bayan/
  src/                      the compiler in Bayān: lexer, parser, semantics, emitter, sabk, driver
  runtime/                  bayan-rt.h / bayan-rt.c: panic, print, bounds checks, arena, list
    tests/                  the runtime's C tests
  bootstrap/                bayan.c and the runtime, the C that builds the self-hosted compiler
  lib/std/                  the standard library written in Bayān
  tools/                    lex-diff, the syntax fuzzer and other tools
  tests/                    tests both compilers share
    cases/
      lex/        *.byn → *.tokens
      parse/      *.byn → *.ast
      diag/       *.byn → *.diag        (expected diagnostics, exact text)
      run/        *.byn → *.stdout      (+ optional *.exitcode)
                  (and diag-json, emit, manifest, new, out, quality, style, typed)
    parity/
  docs/
    bayan-spec.md
    diagnostics/BYN0001.md …            one file per diagnostic code (`bayan explain`)
  examples/
    hello/main.byn
    tally-lite/…
```

Plan 017 (2026-11-15) moved the tree (last pre-move commit `3c3ccc82`); done records keep old paths, `git log --follow` crosses it.

| Before | After |
|---|---|
| `src/Bayan.*/` | `csharp/Bayan.*/` |
| `tests/Bayan.Tests/` | `csharp/tests/Bayan.Tests/` |
| `tests/Bayan.Tests/Selfhost*.cs` | `src/tests/Selfhost*.cs` |
| `src/runtime/` | `runtime/` |
| `tests/native/` | `runtime/tests/` |
| `selfhost/` | `src/` |
| `tests/cases/`, `tests/parity/` | unchanged |

<!-- prose-check: off -->
Spec 019b removed `csharp/`, `src/tests/*.cs`, `Bayan.slnx`, the C# language server and the two C# tools, kept in tag `csharp-final` (`docs/decisions/2026-11-23-011-csharp-archive.md`).
<!-- prose-check: on -->

## Conventions

### Diagnostics

- Every diagnostic: a `BYN####` code, span, message, optional **help** and optional **fix** (replacement text plus span). Code ranges: `AGENTS.md`.
- Rendered (snapshot-tested):

```
error BYN2104: `total` is immutable

  12 │     total += line.price;
     │     ^^^^^ declared with `let` on line 9
     │
  help: declare it with `var` if it should change
     │  9 │     var total = 0;
```

- `docs/diagnostics/BYN####.md` per code (why, example, fix); `bayan explain BYN2104` prints it.

### Golden tests

- One input per case, expected output beside it; `bash scripts/test.sh` runs all.
- Expected files (diffs reviewed like code) and what needs a `diag/` or `run/` case: `AGENTS.md`.

### C emission

- Names: `byn_<module>_<name>`; struct `T` → `typedef struct byn_<module>_T byn_<module>_T;`.
- `string` → `typedef struct { const uint8_t* ptr; int64_t len; } byn_str;`, literals static arrays.
- `Span<T>` → `{ T* ptr; int64_t len; }`, one instantiation per element type.
- `byn_panic(const char* msg, const char* file, int line)` prints `panic: <msg>` and location, then `abort()`.
- `debug`/`safe`: `__builtin_add_overflow` and friends, panicking on overflow; `fast`: plain arithmetic, `-fwrapv`.
- **Bounds checks in every mode** (spec principle 9); remove only checks proven redundant (start with `for (let i in 0..xs.length) xs[i]`).
- Emit `#line` so debuggers show `.byn` lines.

## Testing the compiler itself

- Golden tests for every phase, above.
<!-- prose-check: off -->
- The lexer and parser face untrusted input. The C# fuzzer (`tools/Bayan.SyntaxFuzz`) left with the C# compiler; no Bayān one yet.
<!-- prose-check: on -->
- Mutation: `bayan test --mutate` (spec 013); runs go to wp1/wlt1.
- Reproducibility: CI compiles `examples/` twice and diffs the C bytes.

## Before a push

The ci job's script tests are one list, `scripts/ci/script-tests.sh`; `.github/workflows/ci.yml` reaches it through `scripts/test.sh` (its `scripts` part) and runs no script test of its own. Run it under macOS's system bash, as the macOS job does. With no group it runs both `unix` (ci splits it into `fast`, the other-parts job, and `slow`, its own job) and `docs` (Linux only):

```
/bin/bash scripts/ci/script-tests.sh
```

Pushes to `dev` or `main` run `scripts/ci/pre-push.sh <sha>` through git's pre-push hook: the hook checks the pushed commit out under `tmp/pre-push/`, runs the script tests there, and refuses the push if they fail (`--no-verify` bypasses it once). By hand: `scripts/ci/pre-push.sh HEAD`; a tree that already passed is skipped.

macOS ships bash 3.2: a `$( … )`, `<( … )` or `>( … )` body parses only when its line runs, so a bare `pat)` case arm closes the substitution; `bash -n` passes and the script dies later. Inside one, write `(pat)`. `scripts/ci/bash32-parse.test.sh` enforces this on every tracked `.sh` on every OS.

## Writing docs

These rules cover every user-facing page (`README.md`, `site/content/`, `bootstrap/README.md`, `editors/README.md`, release docs with a `Version:` header); records keep their text (handoffs, audits, plans, decisions, revisions, progress log, released `CHANGELOG.md` sections).

1. A pattern over a list: `bayan-<version>-<os>-<arch>.tar.gz` (`.zip` on Windows), not six archive names.
2. Say each thing once, where a reader looks for it; link from elsewhere.
3. The current version only; history lives in `CHANGELOG.md`.
4. Bayān on its own terms: no comparison with another language explains a rule; the `from-*.page` guides are the exception.
5. Show, then tell: a real-world example first (code when the point is code), a table for two or more dimensions, a diagram when one beats a paragraph.
6. Clear, plain words: short sentences, the concrete thing named, no filler; `scripts/docs/prose-words.txt` lists the rejected words.
