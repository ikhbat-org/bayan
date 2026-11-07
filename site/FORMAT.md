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
