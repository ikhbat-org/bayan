# ijam (light manuscript)

## Tokens
- Colour: parchment `#F6F1E7` ground, vellum `#EDE5D3` for code, navy `#1F3A5F` ink, soft ink `#46586F` for captions and marginalia, text gold `#8A5F12` for links only, gold `#C08A2E` for diamonds and rules (never text), error red `#8C2F1E` and help green `#1D5A3C` inside diagnostics only.
- Type: Alegreya for display and body (18px base, 24 lead, 28/36 headings, up to 60 for h1), Amiri for Arabic (`lang="ar" dir="rtl"`), IBM Plex Mono 14.4px for code. Ragged-right, leading 1.65.
- Layout: docs are three columns, nav 14rem, text `68ch`, marginalia 11 to 17rem. Below 1180px the marginal notes fall inline under their paragraph with a gold left rule; below 860px the nav becomes a wrapped row. Landing and tutorial are single-measure. Diamonds (rotated squares) are the only bullets and section markers; tutorial steps are the one real sequence.

## The bold element
The hero mark at monumental size. The rasm of بين draws itself as one stroke (`stroke-dashoffset` on a `pathLength="1"` path, 2.4s), then the four diamonds fall in one by one, then "One form, one meaning." settles beside it. This is the only animation on the site; `prefers-reduced-motion` shows the final state. Without animation support the final state is also what renders.

## What I cut
- Hoopoe on the landing and docs (it appears only on tutorial step 5).
- A table of contents block in the docs body (the on-page contents nest under the page in the nav).
- Hover and scroll effects, JS of any kind, dark mode.
- Links to docs pages that do not exist: Structs, Unions and Errors in the nav are unlinked text.

## Notes
- Programs and diagnostics are copied from `tests/cases` (`data-enums`, `hello`, `undefined-name`, `unknown-enum-member`). The tutorial diagnostic adds the `-->` location line the compiler prints with a real path. `bayan build` and `bayan run` on hello and `bayan check` on the typo program were run to confirm.
- The spec says an enum has `length`; the test prints `Planet.count`. The docs page states both.
- Compiler install is from source (README); no release download is documented, so none is claimed.
