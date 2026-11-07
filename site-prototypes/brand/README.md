# Bayan brand assets

Palette: navy `#1F3A5F`, gold `#C08A2E`, light gold `#E0AE55`, parchment `#F6F1E7`, night `#14202E`, cream `#EDE6D6`, sand `#D9A05B`, bronze `#8A6F3A`. Gold/sand/bronze are decorative only, never text.

All text is converted to outlines (no font dependency). English: Inter SemiBold; Arabic: Amiri Bold (both OFL).

| Folder | Contents |
|---|---|
| `mark/` | Dotted-root mark (بين + four diamond dots): light, dark, mono (`currentColor`); app-icon tiles |
| `favicon/` | 32-grid favicon; `favicon-auto.svg` follows light/dark; `favicon.ico` (16/32/48) |
| `wordmark/` | `bayān` with the hoopoe perched on the gold macron; `بيان` |
| `lockup/` | Horizontal, bilingual, stacked |
| `mascot/` | Faceless hudhud standing and flying; poses: error, tests pass, loading (animated, respects reduced motion) |
| `badge/` | `.byn` file badge |
| `social/` | 1280x640 social/GitHub preview card |
| `png/` | App icon 64-1024, favicon PNGs, apple-touch-icon, icon-192/512, social PNGs |

Mono variants use `currentColor`; hoopoe wing bands are white in mono, so use them on light backgrounds.

```html
<link rel="icon" href="/favicon.ico" sizes="48x48">
<link rel="icon" href="/favicon-auto.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```
