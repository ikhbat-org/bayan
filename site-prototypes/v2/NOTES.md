# v2

Landing is ijam's look, docs are qalam's layout in the same palette, tutorial follows the docs styling. One `style.css`. Brand files are copied into `brand/` (`wordmark/`, `favicon/`).

## Per review note
1. Palette: parchment `#F6F1E7`, navy `#1F3A5F`, gold `#C08A2E` for shapes and rules only, text gold `#8A5F12` for links and labels. Docs keep qalam's three columns (sidebar, content, "On this page"), prev/next pager and ruled tables, restyled. Alegreya for prose, Inter for UI, headings and tables.
2. Hero: inline brand SVG paths (outlined Inter SemiBold / Amiri Bold, no font dependency) split per letter and revealed with CSS `clip-path: inset()` wipes. Arabic first, right to left: ba, ya, alif, nun (بيان). Then bayān left to right: b, a, y, a, n, then the macron. Then the flying hoopoe (`brand/mascot/bayan-hoopoe-flying-light.svg`) glides in from the right and swaps to the perched hoopoe sitting on the macron (the wordmark's own group). End state is the brand wordmark plus the Arabic wordmark. Runs once (about 7 s). All animation sits inside `prefers-reduced-motion: no-preference`, so reduced motion shows the end state directly. The perch pose differs slightly from the flying pose, so the landing is a quick cross-swap rather than a morph.
3. Header: cropped copy of the English wordmark with the perched hoopoe (`brand/wordmark/bayan-wordmark-en-header.svg`, only the viewBox changed) plus live text بيان (`lang="ar" dir="rtl"`, Amiri Bold). No بين mark or lockup used. Favicon: `brand/favicon/favicon-auto.svg` and `favicon.ico`.
4. Code font: JetBrains Mono from Google Fonts, ligatures off. Nerd Font not used: it only adds icon glyphs, and nothing on the site needs them; it would be a heavier, non-Google-Fonts download for no visible gain.
5. Docs: "On this page" button (top of content, always visible) toggles the column. `aria-expanded` and `aria-controls="toc"`, native `<button>` so Enter/Space work. Collapsed: the grid drops to two columns and content takes the freed width. State in `localStorage` key `bayan-toc`, applied on load.
6. No C# positioning anywhere. Removed from the qalam docs: the `out` row's "C# compatibility" (now "Output parameter. Prefer returning T? or a tuple."), "C#-style ambiguity resolution".
7. No Arabic explanation: removed the Arabic particle etymology sentence from docs; no dots history, hoopoe story or meaning gloss.
8. Landing examples, source beside output: hello (`tests/cases/run/hello.byn`, `hello.stdout`); structs and enums (`shapes.byn`, written for this page, output from `dotnet run --project src/Bayan.Cli -- run`); errors (`errors-defer-failing.byn` verbatim, output from `.stdout`).

Docs content is qalam's Parameters and arguments page, unchanged apart from note 6/7 edits. Tutorial text is qalam's.

## Unverified
- Mid-animation and end-of-timeline frames: headless Chrome with `--virtual-time-budget` does not advance CSS animation time for the real delays (frames stay at start). A copy with zero delays confirmed the wipes, the flying hoopoe and the fade-in; the full 7 s sequence and landing position were not seen in a browser. Reduced-motion end states are in `shots/`.
- Google Fonts need network; the screenshots show fallbacks if blocked. Contrast checked by token, not by tool.
- The hoopoe overlay position (`.fly`) is computed from the SVG coordinates; check the landing against the perched bird in a real browser.
- Docs sidebar links other than the current page are `#`; qalam's search box and version picker were dropped as non-functional.
- `shapes.byn` is not in `tests/cases`.

## Polish pass (verified with Playwright, Chromium, real time)
- Hero captured at 1, 4, 6, 6.5 and 8 s: Arabic wipes right to left, bayān left to right, hoopoe flies in and rests on the macron (fly box 358-443 px, perch 363-438 px at 1400 px). Fix: `.art svg` (width 100%) beat `.fly`'s width, so the flying bird was full width; now `.art .fly`.
- `details.quiz`, `.next-box`, `dl`, `var` styled; tables outside `.tablewrap` scroll inside their box under 860 px (from-python overflowed to 487 px before).
- Docs sidebar starts closed below 64rem so it no longer pushes the page text down on phones.
- Shots in `shots/` (1400 and 360). ref-diagnostics is clipped to its first 7000 px (page is about 250000 px tall). No overflow at 360 px, no non-local request from any page in `out/`.
