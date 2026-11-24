# Bayan for VS Code

Highlighting, snippets, bracket/comment handling, and (with `bayan-lsp`) diagnostics, completion,
hover docs from `///` comments, Ctrl+Click go to definition, outline, workspace symbols and
signature help. Debugging maps `bayan` launch configs onto CodeLLDB, cpptools or vsdbg.

## Install

    npm install
    npx @vscode/vsce package
    code --install-extension bayan-0.0.1.vsix

Release archives ship `bayan-lsp` beside `bayan`. To build it from source, run
`bayan build --package editors/language-server/src -o bayan-lsp editors/language-server/src/app`.
Put `bayan-lsp` on `PATH`, or set `bayan.server.path`. Without the server, highlighting and snippets
still work.

## Debug

Install CodeLLDB (default) or C/C++ (`bayan.debug.backend`). Add a `Bayan: Launch` configuration
and press F5: the extension runs `bayan build --debug --print-output`, then launches the binary.
Set breakpoints directly in `.byn` files.
