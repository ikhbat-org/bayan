# bayan.run site: layout and content format

The site is static HTML built by a generator written in Bayan (`site/gen/`). Everything it needs is in `site/`; the built pages reference nothing outside (no CDN, no web fonts from elsewhere, no scripts from elsewhere).

```
site/
  FORMAT.md            this file
  build.sh             builds site/out/ (runs the generator, copies assets), then checks the examples
  check-examples.sh    runs every site/examples/*.byn with the compiler and compares stdout with its .out file
  gen/*.byn            the generator (Bayan)
  templates/*.html     page shells: landing.html, docs.html
  content/*.page       one file per page
  examples/<name>.byn  complete programs shown on pages; <name>.out is their real stdout
  assets/              style.css, fonts/, brand/ (copied as-is into out/)
  gen/markdown.byn     the Markdown renderer for the release docs (§Release docs)
  out/                 the built site (gitignored)
```

Compiler: `$BAYAN` if set, else `/Users/sy/Developer/ikhbat.org/bayan/dist/macos-arm64/latest/bayan`.

## A `.page` file

Header lines, a line `---`, then the HTML body.

```
title: Reading Bayan
nav: Learn
order: 30
template: docs
---
<p>Body HTML…</p>
```

- `title`: the page title, also its `<h1>` and the `<title>`.
- `nav`: the sidebar group (`Start`, `Learn`, `Guides`, `Reference`). The sidebar is built from all pages: grouped by `nav` in the order Start, Learn, Guides, Reference, and within a group sorted by `order`.
- `order`: an integer.
- `template`: `landing` (only `index.page`) or `docs`.
- The output file is `out/<page file name without .page>.html`; `index.page` becomes `out/index.html`.

## Body markup the generator handles

- `<h2 id="x">Text</h2>`: each `h2` becomes an entry in the "On this page" column. Every `h2` needs an `id`.
- `<example name="hello"/>`: replaced by the highlighted source of `examples/hello.byn` beside its output `examples/hello.out`, captioned with the file name. Use this for every program whose output the page shows. Outputs are never typed by hand; `check-examples.sh` regenerates or checks them.
- `<example name="hello" output="no"/>`: the source only.
- `<pre><code class="byn">…</code></pre>`: an inline Bayan fragment (not a whole program, so not run). Write `<`, `>` and `&` in it as `&lt;`, `&gt;` and `&amp;`. It is highlighted like an example.
- `<pre><code class="other" data-lang="Python">…</code></pre>`: code in another language, shown as is with a caption naming the language and no highlighting. Use it only for side-by-side comparisons.
- `<note>…</note>`: an aside box.
- Everything else passes through unchanged.

## Highlighting

The generator tokenizes Bayan and wraps tokens in `<span class="…">`, with the classes `kw` (keywords), `ty` (type names: built-in types and capitalized names), `fn` (a name directly before `(`), `str` (string and char literals, including `$"…{…}"` interpolation text), `num`, `com` (comments, `///` doc comments too), `at` (attributes `@name`), `pa` (a particle label before `:` in a call or parameter list: `by:`, `from:`, `to:` …), and `op` for `=>`, `?`, `!`. `style.css` gives each class a colour from the brand palette, readable on parchment (WCAG AA, 4.5:1).

## Manifesto and book

- `out/manifesto.html` is `docs/manifesto/bayan-manifesto.md` through the renderer, with the docs template and a `{{toc}}` of its headings (skipped if the file is absent). `build.sh` copies `docs/manifesto/assets/*.svg` into `out/assets/`, where its images point. Its ```` ```mermaid ```` fences are plain text. The footer of every page links it (`{{root}}manifesto.html`), and `index.page` links it once.
- `out/book.html` holds every `content/book-*.page` body in `order`, each chapter starting with its title as `<h1>`, on one page for printing. It is not in the sidebar.
- `style.css` has an `@media print` block: header, footer, sidebar, theme button and toc hidden, light colors, each `h1` on a new page, code blocks kept whole where they fit, links without decoration.
- `scripts/release/docs-pdf.sh` runs `site/build.sh`, then prints both pages with headless Chrome (`$CHROME`, else Google Chrome on macOS, else `google-chrome` or `chromium`; exit 2 if none) to `dist/bayan-manifesto-<version>.pdf` and `dist/bayan-book-<version>.pdf`.

## Release docs

`build.sh` sources `scripts/release/version.sh` and runs the generator as `bayan run site/gen -- site $bayan_release_docs CHANGELOG.md`. The version is the trimmed first line of `VERSION`, read by the generator from `site/../VERSION`; a `-dev` version is shown as is. Every page's header shows it through `{{version}}` (`<span class="version">Bayān {{version}}</span>`).

- Each doc (a path from the repo root) becomes `out/docs/<version>/<name>.html`. `<name>` is the base name without `.md`, with a leading `YYYY-MM-DD-` dropped (`docs/security/2026-11-06-runtime-audit.md` is `runtime-audit`). Names shared by several docs get the parent directory as a prefix (`docs/laws/README.md` is `laws-README`).
- A page uses `templates/docs.html`. Its title is the first `# ` heading, which leaves the body (the template prints the `<h1>`); `{{toc}}` holds the `##` and `###` headings. The sidebar lists every release doc.
- `out/docs/<version>/index.html` lists the docs by title.
- `docs/bayan-roadmap.md` is also written as `out/roadmap.html`. The header nav has Roadmap (`roadmap.html`) and Docs (`docs/<version>/index.html`) links; `{{root}}` (empty, or `../../` under `out/docs/<version>/`) leads back to `out/`.
- Links: a relative link to a published doc becomes `<name>.html#frag`. Any other relative link goes to `https://github.com/ikhbat-org/bayan/blob/<ref>/<path>`, where `<ref>` is `v<version>`, or `dev` for a `-dev` version. Absolute URLs (with a scheme) and `#frag` links are kept.

The renderer (`gen/markdown.byn`) handles this subset; anything else is shown as escaped text, and all text is escaped (`& < > "`):

- ATX headings `#` to `######` with an optional closing `#` run. Ids are slugs: lowercase, ASCII letters and digits kept, every other run becomes one `-`, leading and trailing `-` dropped (`section` if nothing is left); a repeat gets `-2`, `-3`.
- Images `![alt](path)`: `<img src="path" alt="alt">`, both escaped; the path is kept as written (not rewritten like links). No closing `)` leaves the text as it is.
- Paragraphs; `*em*`, `_em_` (not inside a word), `**strong**`; code spans of any backtick run length; `\` before punctuation.
- Links `[text](url)` and autolinks `<https://…>`.
- Fences of three or more `` ` `` or `~` with an info string; `bayan` and `byn` fences are highlighted (§Highlighting), others are plain text. An unclosed fence runs to the end.
- `-`, `*` and `1.` lists, nested by indentation, continued on indented and lazy lines; a blank line between items makes the items paragraphs.
- GFM pipe tables with an alignment row, blockquotes (with lazy lines), and `---` rules.
- Lists and blockquotes nest at most 16 deep (docs/memory-leaks.md); deeper markers render as text. Every scan moves forward, so no input makes the renderer recurse without bound or loop.
