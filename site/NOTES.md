# Notes on the generator

Where the build differs from FORMAT.md, or fills a gap in it, and why.

## Differences forced by the compiler

- **`out/` is created by `build.sh`, not the generator.** `Io` has `readText`, `writeFile` and `listDir` but no way to make a directory, so `build.sh` empties and creates `site/out` before the generator runs, and copies `assets/` with `cp -R`.
- **Examples run one at a time from their own directory.** The compiler treats a directory as one module, so two `.byn` files with top-level statements side by side fail to build (BYN2015). `check-examples.sh` copies each example into a temporary directory of its own before `bayan run`.
- **Compiler errors are not examples.** A program that does not compile cannot be an `<example>` (it has no output to check). The tutorial and the parameters page show the broken program as an inline `<pre><code class="byn">` fragment and the diagnostic as a hand-placed `<figure class="diag">` with the compiler's real output pasted in. The build does not re-check that text; the parameters page's copy matches `tests/cases/diag/arguments-swapped.diag`, which the compiler's own tests do check.

## Choices where FORMAT.md is silent

- **Template placeholders.** Templates use `{{title}}`, `{{name}}`, `{{group}}` (the nav group), `{{docs}}` (href of the Docs link), `{{headnav}}`, `{{sidebar}}`, `{{toc}}`, `{{pager}}` and `{{body}}`. `{{body}}` is filled last, so page text containing `{{…}}` is left alone.
- **Pages without `nav`** (the landing page) are left out of the sidebar and the previous/next links.
- **The header's Docs link** goes to the first Reference page, else the first sidebar page that is not the tutorial. It is marked current on every sidebar page except the tutorial.
- **Unknown header keys are an error** (`unknown header ...`), as are an unknown `nav` group, a non-integer `order`, a missing `---` and a missing `template`, each with file and line.
- **The landing hero lives in `templates/landing.html`.** The page's `title` is the hero heading; the body supplies the sections below it.
- **Plain `<pre><code>`** (no class) is passed through unchanged; the tutorial uses it for shell commands. FORMAT.md reserves `class="other"` for side-by-side comparisons, so it is not used for commands.
- **Type colour.** `.ty` is a lighter navy (#2F5A8A) rather than a gold, so types read apart from keywords (bold dark gold) and from plain names (ink navy). All token colours are at least 4.5:1 on the code background; the ratios are in comments in `assets/style.css`.
- **Box-drawing characters** in diagnostics (`│`) are outside the bundled font subsets, so they come from the system monospace font.
