# HANDOFF — Bayan in the browser: runnable docs and a tour (future, not scheduled)

Written 2026-11-22 from a Rein session. Parked idea for a future spec, approved by the owner as "do a handoff for a future implementation". Do not interrupt 011/012/013/015. File it under `docs/handoffs/` when the repo is on `dev` with a clean tree.

## 1. Goal
A reader of the Bayan docs presses **Run** on any code sample and sees it compile and run inside the browser tab. No install, no zig, no server doing the work. Later, a "Tour of Bayan" (like Go's tour): a sequence of short lessons, each with an editable, runnable program, and optionally a terminal that runs `bayan test`.

## 2. Real-life shape
- The docs page for `Untrusted<T>` shows a 10-line snippet. The reader edits it, presses Run, and sees the compile diagnostic or the output under it, in about a second.
- A tour lesson on typestate narrowing (the `orders/` example in `suq/`) lets the reader break the code on purpose and read the diagnostic.
- Comparable products: the Go playground and tour (server-backed), the Rust Playground (server-backed), and Pyodide's REPL on python.org (fully in-browser).

## 3. Two routes, cheapest first

| Route | How | Cost | Catch |
|---|---|---|---|
| A. Bayan programs as wasm | The compiler runs somewhere and emits `wasm32` (wasi) through `zig cc`, which Bayan already supports (`docs/bayan-status-for-suq.md:114`). The page runs the `.wasm` with a small WASI shim (e.g. browser_wasi_shim). | Small if compiling happens on a server; the page only runs output. | Needs a compile server, unless the compiler itself runs in the browser (route B, or the self-hosted compiler from 011/012 compiled to wasm32 and paired with a C compiler in wasm, which is large). Panic handlers do not run on wasi (`bayan-status-for-suq.md:280`). |
| B. Whole toolchain in an in-browser Linux | Use unkernel (github.com/pithings/unkernel): a real Linux 7.x kernel compiled to one wasm module that runs unmodified aarch64 Alpine/Debian userspace. Ship a rootfs with `bayan` and `zig` installed. | Medium: build the image and a page around the unkernel SDK. | The README claims about a 10 MB page and a 4 MB Alpine rootfs; zig adds tens of MB (estimate), and compiling runs well below native speed. Needs Chrome 137+, Firefox 153+ or Safari 27+ (JSPI). GPL kernel parts. No inbound network. |

**Suggested order:** prototype route A with a tiny compile endpoint first. That proves the docs Run button. Consider B only for the tour's terminal or for fully offline docs, and measure the zig-in-browser compile time before committing to it.

## 4. Open questions for the owner (ask before speccing)
- Is a compile server acceptable for the docs site, or must it be fully in-browser and offline?
- Which docs site: the Bayan site under ikhbat.org, `sitegen`, or another?
- Should the self-hosted compiler (011/012) target wasm32 as a goal, so route A needs no server later?
- License: unkernel's kernel and emulator parts are GPL-2.0; its SDK and page are MIT. Is shipping a GPL component on the site fine?

## 5. Sources
- unkernel README (fetched 2026-11-22 via a research worker; sizes and timings are the README's claims, not measured here): https://github.com/pithings/unkernel
- Bayan targets: `docs/bayan-status-for-suq.md:114`, `docs/bayan-handoff.md` (target names), `docs/bayan-spec.md` §24 (pipeline: "WASM via clang wasm32 (+ generated .d.ts)").
- Related Rein note: Rein repo `docs/research/distribution/2026-11-22-local-app-and-remote-offload-brainstorm.md` (branch `docs/dreamcoder-research`).
