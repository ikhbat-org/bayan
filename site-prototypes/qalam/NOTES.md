# qalam

## Tokens
- Colour: paper `#FBFAF7`, panel `#F1F4F2`, ink `#14201E`, teal `#0E5E54` (primary, links, keywords), deep teal `#0A453E` (hover), cool grey `#55605D` (secondary text), line `#D5DBD8`. Terracotta `#C25B3A` appears only as shapes: pen nib dot, hoopoe and mark dots, list markers. Never text.
- Code colours: keywords teal, types deep teal, strings `#5E3B7A`, numbers `#1F5FA8`, comments grey italic, particles teal underlined. Diagnostic error label `#9B2C1B`.
- Type: IBM Plex Sans (UI, body), Plex Sans Arabic (`lang="ar"`), Plex Mono (code), Plex Serif for docs prose only.
- Layout: 72rem wrap; docs are three columns (14rem nav, 42rem prose, 12rem contents) from 64rem, one column below; tutorial 46rem single column; landing panes are three columns from 56rem, stacked below.
- Assets: `mark.svg`, `favicon.svg`, `hoopoe-note.svg` are the shared assets recoloured (navy to teal, gold to terracotta, sand to `#E2A184`, cream to paper).

## The one bold element
Code-first landing: a tabbed three-pane strip (source, generated C, output) for three real test cases (`hello`, `overloads`, `errors-defer-failing`). Source and output are verbatim from `tests/cases/run`. The C is real `bayan build --emit-c` output with `#line` directives removed and some lines elided (marked, and labelled on the page). Tabs are vanilla JS (arrow keys work); without JS all three show stacked. The qalam is a thin line drawing that writes the underline under the headline, the only animation (off under reduced motion).

## Cut
- Diamond connectors between the three panes.
- A hoopoe on the docs and tutorial pages, a footer sitemap, and any card grid: routes are ruled columns.

## Known gaps
- Docs sidebar and prev/next links other than the current page are `#`. Search is non-functional.
- Tutorial step 1 is build-from-source because no installer is documented in the repo.
- The compiler's suggested fix in the BYN5005 output (`width(end, until: start)`) keeps the wrong argument order; the tutorial says so and applies the correct fix.
- Not verified: Google Fonts load (no network check), contrast measured by eye and by token, not by tool.
