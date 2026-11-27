# HANDOFF: Bayan editor tooling (v0.0.1)

`.byn` support for VS Code and Visual Studio 2022. Phase 1 is done and needs no
compiler; phases 2–4 connect it. Spec: round 3, revisions 0002–0007.

## 1. What exists

| Path | What | Status |
| --- | --- | --- |
| `editors/vscode/syntaxes/bayan.tmLanguage.json` | TextMate grammar, shared by VS Code and VS | Verified with vscode-textmate |
| `editors/vscode/language-configuration.json` | `//` toggle, brackets, auto-close, `///` continuation | Done |
| `editors/vscode/snippets/bayan.json` | Canonical forms (type-first, no parens, `union error`) | Done |
| `editors/vscode/extension.js`, `package.json` | LSP client (stdio), `bayan` debug type, `.byn` breakpoints | Packaged to `.vsix` |
| `editors/language-server` | `bayan-lsp` in Bayān: hand-rolled JSON-RPC, no LSP library | Builds; 53 sessions replay in the editor gate |
| `editors/visualstudio` | TextMate drop-in; VisualStudio.Extensibility LSP skeleton | Not built (needs Windows) |

Server features: incremental sync; lexical diagnostics (BYN1040 `;`, BYN1047 `/* */`, unclosed literals); completion (scoped locals, members after `.`, target-typed `.case`/`.state`, `@` attributes, keywords, primitives, builtins); hover (header + `///` docs, keyword docs); definition (locals, params, fields, methods, cases, states, types, across files); outline; workspace symbols via a lazily rebuilt index (name, container, types); signature help (receiver skipped, multi-line calls); lazy `completionItem/resolve` docs; context-narrowed `.x` (`fail .` → error cases, `is .`/`becomes .` → states). Type flow is shallow: declared types, `let x = Type {…}`, member chains `a.b().c`.

## 2. Gate rules

- The server never forks the compiler's rules: phase 2 deletes its lexer and indexer instead of syncing.
- Messages use the compiler's plain-English text and codes; after phase 2, the server adds none.
- Bounded memory: each message is answered in its own arena; a document's text, tokens and symbols live in an arena freed when it is replaced or removed (bounds: `docs/memory-leaks.md`).

## 3. Phase 2: compiler front end in the server

1. Move `editors/language-server` into the compiler tree; import its lexer, parser, semantics.
2. One `Compilation` per `package.byn` replaces per-document analysis; re-bind changed files where the binder allows, else debounce 150 ms after the last edit.
3. Diagnostics: map code, message, label span and help to LSP; `help` in `relatedInformation` or the message's second line, `codeDescription.href` to the code's docs page.
4. Every `fix: yes` diagnostic (BYN1043, 1044, 1053, 1061, 1065, 3209, …) is a `quickfix`; the compiler supplies the edits, the server transports them.
5. Completion, hover, definition, signature help from bound symbols: exact types, overloads by type and particle, effects (`uses …` in hover), states, `fails` sets. Keep response shapes; no client changes.
6. Read the compiler's keyword table, not the server's; test that every keyword appears in the grammar's keyword regexes.
7. Add `references`, `rename` (the grammar checker's naming rules), `formatting` (`bayan format` in-process, per `package.byn` `style`) and `semanticTokens` (fields, locals, states, effects; the grammar stays as fallback).

## 4. Phase 3: `bayan lsp`

Host the same server as `bayan lsp` (stdio); the VS Code setting becomes `"bayan.server.path": "bayan", "bayan.server.args": ["lsp"]`, `bayan-lsp` stays an alias.

## 5. Phase 4: debugging

The extension registers a `bayan` debug type and `.byn` breakpoints, delegating to a native debugger; the compiler must provide:

1. `bayan build --debug --print-output`: C with `-g -O0` (MSVC: `/Zi /Od`), `#line` kept (J93), the executable's absolute path as stdout's last line.
2. Debug-friendly C names: locals and fields keep their Bayan names where legal (`order`, not `_b_order_3`); document the rest's mangling for watch expressions.
3. Pretty printers, later: LLDB Python formatters and a `.natvis` for `string` (UTF-8 ptr+len), spans, unions (tag + payload), typestate tags, beside the binary.
4. No Bayan DAP adapter until Bayan expression evaluation is wanted.

## 6. Visual Studio

`scripts/bayan-tool.sh install-textmate` gives colouring. `Bayan.VisualStudio` starts `bayan-lsp` through `LanguageServerProvider`; build on Windows, fix NuGet package versions, test completion, hover, definition, diagnostics.

## 7. Known gaps (phase 1)

- Name-first forms (`f() -> T`, `x: T` params) are not indexed; diagnostics later.
- Overloads collapse to the first declaration in hover and definition.
- Builtin member tables are hand-written (revision 0003, SPEC §16); phase 2 replaces them.
- `import` and module visibility are ignored: every workspace symbol is visible.
