# bayan.run content map

What the site holds, page by page, and who writes it. Format: `FORMAT.md`. Source of truth for the language: `docs/bayan-spec.md` (and Appendix A for settled decisions); the compiler at `$BAYAN` (default `dist/macos-arm64/latest/bayan`) is the judge of what works today.

## Models

| Site | What we take from it |
|---|---|
| The Rust Book (doc.rust-lang.org/book) | A numbered book read front to back; each chapter teaches one idea with a running program; project chapters (a guessing game, a CLI tool, a server) tie earlier chapters together; error messages shown and explained. |
| The Brown Rust Book (rust-book.cs.brown.edu) | "Check your understanding" quizzes at the end of each chapter section, with answers and an explanation of why each wrong answer is wrong; diagrams of where values live. |
| Zig language reference (ziglang.org/documentation/master) | One exhaustive reference per area, a short runnable test-style example per feature, every rule stated once, a table of contents that lists every feature. |
| go.dev/doc | A short tour of small steps; "Effective Go" (idioms and why); tutorials by task; an FAQ that answers "why does the language do X" in a paragraph. |

## Rules for every page

- Every program whose output a page shows is an `<example>` that `check-examples.sh` runs. Outputs come from the compiler, never typed by hand (`check-examples.sh --update`, then read the `.out` and confirm it is what the text says).
- A feature the compiler does not implement yet is described from the spec with a `<note>` saying "Planned: not in the compiler yet", and shown only as a `<pre><code class="byn">` fragment. Never present it as working. If unsure, try it with the compiler.
- A compiler error shown on a page is the compiler's real output pasted into a `<figure class="diag">` (see `NOTES.md`).
- No "familiar to C#" claims, no explaining Arabic (the Arabic terms in the spec such as waqf or ishtiqāq are not used on the site; say what the feature does in English).
- Plain English, short sentences, second person. Name the concrete thing. A comparison with another language is a sentence or a side-by-side `class="other"` block, not a tagline.
- Quizzes: at the end of each book chapter, a `<h2 id="quiz">Check your understanding</h2>` with 3–5 questions, each a `<details class="quiz"><summary>question</summary>answer and why each wrong option is wrong</details>`. Questions about what a program prints use a real example's output.
- Each writer owns only the files listed for it below and example names with its prefix. Do not edit another writer's pages, the templates, `assets/`, `gen/` or the cookbook pages.

## Navigation groups and orders

`nav` must be one of `Start`, `Learn`, `Guides`, `Reference` (the generator rejects others). Orders below are fixed so the sidebar does not collide.

### Start (writer: start)
| order | file | title |
|---|---|---|
| 10 | `tutorial.page` (exists) | Your first Bayan program |
| 15 | `install.page` | Install Bayan |
| 18 | `tour.page` | A tour of Bayan (Go-tour style: 20–30 tiny steps, each one example) |
| 20 | `why.page` (exists) | Why Bayan |
| 30 | `features.page` (exists) | What makes Bayan different |

### Learn: the Bayan Book (writers: book-a, book-b, book-c)
Chapter titles carry their number. Each chapter: what it teaches, one running program built up step by step, the errors a reader will hit (real diagnostics), a quiz.

| order | file | title | writer |
|---|---|---|---|
| 10 | `reading.page` (exists) | Reading Bayan code | start |
| 100 | `book-01-start.page` | 1. Getting started: install, `bayan run`, scripts, projects | book-a |
| 200 | `book-02-project-words.page` | 2. Project: a word counter (read a file, split, count, sort, print) | book-a |
| 300 | `book-03-basics.page` | 3. Values, types and control flow (`let`/`var`, primitives, strings, `if`/postfix `if`, loops, `switch`) | book-a |
| 400 | `book-04-functions.page` | 4. Functions and parameters (type-first, particles `by:`/`from:`, defaults, `ref`, expression bodies) | book-a |
| 500 | `book-05-structs.page` | 5. Structs and methods (`ref this`, copy-and-update, extensions) | book-a |
| 600 | `book-06-unions.page` | 6. Unions, enums and patterns (`.member`, `match`/`switch`, optionals, tuples) | book-a |
| 700 | `book-07-collections.page` | 7. Lists, maps, spans and strings | book-b |
| 800 | `book-08-errors.page` | 8. Errors (`fails`, `try`, `catch`, error unions, `except`, panics) | book-b |
| 900 | `book-09-interfaces.page` | 9. Interfaces and generics | book-b |
| 1000 | `book-10-lambdas.page` | 10. Lambdas, `it` and function types | book-b |
| 1100 | `book-11-modules.page` | 11. Modules, visibility and packages | book-b |
| 1200 | `book-12-testing.page` | 12. Testing (`.test.byn`, `bayan test`, coverage) | book-b |
| 1300 | `book-13-memory.page` | 13. Memory, ownership and regions | book-c |
| 1400 | `book-14-effects.page` | 14. Effects and capabilities (`uses fs`, `provide`/`context`) | book-c |
| 1500 | `book-15-cleanup.page` | 15. Cleanup and resources (`defer`, move-only types, handles) | book-c |
| 1600 | `book-16-types-that-check.page` | 16. Types that check for you (units, distinct types, `requires`, typestate) | book-c |
| 1700 | `book-17-concurrency.page` | 17. Concurrency (structured concurrency; mark what is planned) | book-c |
| 1800 | `book-18-project-cli.page` | 18. Project: a grep-like command-line tool (args, files, errors, exit codes, tests) | book-c |
| 1900 | `book-19-c.page` | 19. Talking to C (FFI) and building for other targets (`--target`, `Target`) | book-c |

### Guides (writer: guides; cookbooks exist and stay as they are)
| order | file | title |
|---|---|---|
| 20 | `errors.page` (exists) | Errors |
| 30 | `memory.page` (exists) | Memory and ownership |
| 40 | `effective.page` | Effective Bayan (Effective-Go style: naming, when to use which form, idioms and why) |
| 45 | `from-python.page` | Bayan for Python programmers |
| 46 | `from-go.page` | Bayan for Go programmers |
| 47 | `from-rust.page` | Bayan for Rust programmers |
| 48 | `from-typescript.page` | Bayan for TypeScript programmers |
| 50–60 | `cookbook-*.page` (exist) | cookbooks |

### Reference (writers: ref-lang, ref-tools)
Zig style: every rule once, a small checked example per feature, a full table of contents.

| order | file | title | writer |
|---|---|---|---|
| 10 | `ref-lexical.page` | Lexical structure (source text, comments, literals, keywords, statement ends) | ref-lang |
| 20 | `ref-types.page` | Types (primitives, strings, symbols, arrays/spans/collections, optionals, tuples, results, `never`, structs, unions, enums, errors, interfaces, function types) | ref-lang |
| 30 | `ref-declarations.page` | Declarations, modules, visibility, extensions, attributes and purpose clauses | ref-lang |
| 35 | `ref-naming.page` | Naming rules and derived names | ref-lang |
| 40 | `ref-expressions.page` | Expressions (operators, casts, target-typed literals, copy-and-update, patterns, interpolation, equality, `except`) | ref-lang |
| 45 | `ref-statements.page` | Statements (bindings, conditionals, postfix forms, loops, `switch`, cleanup, `provide`/`context`, `requires`) | ref-lang |
| 50 | `parameters.page` (exists) | Parameters and arguments | ref-lang (may extend) |
| 60 | `ref-memory.page` | Memory model | ref-lang |
| 65 | `ref-effects.page` | Effects and capabilities | ref-lang |
| 70 | `ref-std.page` | Standard library (`Io`, `Fs`, `Env`, `Path`, `Target`, text, math, collections) | ref-tools |
| 80 | `ref-cli.page` | The `bayan` command (every subcommand and flag, exit codes, project layout, outputs) | ref-tools |
| 85 | `ref-diagnostics.page` | Diagnostics index (every `BYN` code: what it means, a minimal trigger, the fix) | ref-tools |
| 90 | `ref-design.page` | Design decisions (the settled choices and why, from Appendix A and the principles) | ref-tools |
| 95 | `faq.page` | FAQ (Go-FAQ style "why does Bayan…") | ref-tools |
| 99 | `glossary.page` | Glossary | ref-tools |

## Example name prefixes
`start-*`/`tour-*` (start), `book-NN-*` (book writers, by chapter), `guide-*` (guides), `ref-*` (ref-lang), `std-*`/`cli-*`/`diag-*` (ref-tools).
