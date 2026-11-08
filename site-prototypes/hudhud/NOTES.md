# hudhud (night)

## Tokens
- Colour: night `#14202E` ground, deep `#0F1823` code panels, raise `#1A2A3C`, line `#2C4057`; cream `#EDE6D6` text, muted `#B7B3A6`; light gold `#E0AE55` for dots, links, labels; sand `#D9A05B` only inside the hoopoe. Diagnostic colours are the terminal-style dark column (error `#FF8A80`, help `#8DB8F2`, ok `#8FD694`).
- Type: Hanken Grotesk (Latin), Noto Kufi Arabic (Arabic, `lang="ar" dir="rtl"`), JetBrains Mono (code). Scale is clamp-based, headings 700 with -0.02em tracking, left-aligned.
- Layout: 76rem wrap; hero is a 7fr/5fr grid with the bird spanning both rows; bands use a 4fr/8fr split (label left, content right); docs is 15rem / content / 13rem.
- `hoopoe-night.svg` is the calligraphic hoopoe recoloured for night (navy body to cream, wing to sand, bands to night, dots to light gold). Same geometry as `../assets/hoopoe-calligraphic.svg`.

## Bold element
Hero: a real BYN5005 diagnostic (from tests/cases/diag) in a terminal panel beside the calligraphic hoopoe. The only motion is that panel typing in once (`script.js`, Web Animations clip; text stays in the DOM; skipped under reduced motion).

## Cut
- The "Three commands" band on the landing page (duplicated the tutorial).
- Light-mode toggle (optional in the brief).
- Wordmark SVG (navy text, unreadable on night); header uses the night mark plus live text.

## Notes
- Docs sidebar links other than the current page point to the spec on GitHub; no other docs pages exist in this prototype.
- Tutorial step 1 is build-from-source (README); no prebuilt download is documented. Hello and error output were produced with the local compiler build.
- Flat hoopoe poses use navy on a cream badge in docs so they read on night.
