#!/usr/bin/env bash
# Ported from ContrastTests (spec 019 T25): the §2 colour roles in docs/bayan-terminal-style.md meet WCAG AA and match the driver's
# palette (src/driver/main.byn `t7Prefix`, the C# `Palette`), and `t5Paint` (src/driver/doctor.byn, the C# `Style.Paint`) wraps as before:
#   guide-table-has-five-roles                  Error, Warning, Help, Success, Note, in that order
#   every-guide-colour-meets-aa                 light on #FFFFFF and dark on #14202E, each at least 4.5:1
#   palette-hex-matches-the-guide               the truecolour light and dark rows of `t7Prefix` are the guide's hex, role by role
#   paint-without-colours-is-identity           `t5Paint` returns the text alone when colour is off; no .plain style case holds ESC
#   paint-with-colours-wraps-in-prefix-and-reset  Ansi16 error is ESC[31m, note ESC[2m, and `t5Paint` ends the text with ESC[0m
#   truecolor-prefixes-come-from-hex            light error ESC[38;2;180;35;24m, dark error ESC[38;2;255;138;128m
# No compiler involved. bash 3.2.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
guide="$root/docs/bayan-terminal-style.md"; main="$root/src/driver/main.byn"; doctor="$root/src/driver/doctor.byn"
fail() { echo "FAIL $1" >&2; exit 1; }

# role light dark, one row per line (ContrastTests.RowPattern)
table="$(sed -nE 's/^\|[[:space:]]*(Error|Warning|Help|Success|Note)[^|]*\|[[:space:]]*`(#[0-9A-Fa-f]{6})`[^|]*\|[[:space:]]*`(#[0-9A-Fa-f]{6})`.*/\1 \2 \3/p' "$guide" | awk '{ print $1, toupper($2), toupper($3) }')"
[ "$(echo "$table" | cut -d' ' -f1 | tr '\n' ' ')" = "Error Warning Help Success Note " ] \
  || fail "guide-table-has-five-roles: $(echo "$table" | cut -d' ' -f1 | tr '\n' ' ')"

bad="$(echo "$table" | awk '
  function ch(h, i,  c) { c = index("0123456789ABCDEF", substr(h, i, 1)) * 16 + index("0123456789ABCDEF", substr(h, i + 1, 1)) - 17
    c = c / 255.0; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
  function lum(h) { return 0.2126 * ch(h, 2) + 0.7152 * ch(h, 4) + 0.0722 * ch(h, 6) }
  function contrast(a, b,  x, y) { x = lum(a); y = lum(b); return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05) }
  { l = contrast($2, "#FFFFFF"); d = contrast($3, "#14202E")
    if (l < 4.5) printf "%s light %s on #FFFFFF: %.1f:1 < 4.5:1; ", $1, $2, l
    if (d < 4.5) printf "%s dark %s on #14202E: %.1f:1 < 4.5:1; ", $1, $3, d }')"
[ -z "$bad" ] || fail "every-guide-colour-meets-aa: $bad"

# `t7Prefix`'s rows: the 15 escape literals in order, Ansi16 then light then dark
prefixes="$(awk '/^string t7Prefix\(/ { on = 1 } on && /^}/ { exit } on' "$main" | grep -oE '\\u\{1b\}\[[0-9;]+m' | sed 's/\\u{1b}/ESC/')"
[ "$(echo "$prefixes" | wc -l | tr -d ' ')" = 15 ] || fail "t7Prefix: expected 15 escape rows, found: $prefixes"
hex() { echo "$1" | awk -F'[;m]' '{ printf "#%02X%02X%02X\n", $3, $4, $5 }'; }
i=0
while read -r role light dark; do
  i=$((i + 1))
  l="$(echo "$prefixes" | sed -n "$((5 + i))p")"; d="$(echo "$prefixes" | sed -n "$((10 + i))p")"
  [ "$(hex "$l")" = "$light" ] || fail "palette-hex-matches-the-guide: $role light $l is not $light"
  [ "$(hex "$d")" = "$dark" ] || fail "palette-hex-matches-the-guide: $role dark $d is not $dark"
done <<< "$table"

paint="$(awk '/^string t5Paint\(/ { on = 1 } on && /^}/ { print; exit } on' "$doctor")"
echo "$paint" | grep -A2 -F 'unless style.color {' | grep -qF 'return $"{text}"' \
  || fail "paint-without-colours-is-identity: t5Paint does not return the text alone without colour"
for f in "$root"/tests/cases/style/*.plain; do
  ! grep -q "$(printf '\033')" "$f" || fail "paint-without-colours-is-identity: $f holds an escape"
done

[ "$(echo "$prefixes" | sed -n 1p)" = "ESC[31m" ] || fail "paint-with-colours-wraps-in-prefix-and-reset: Ansi16 error is $(echo "$prefixes" | sed -n 1p)"
[ "$(echo "$prefixes" | sed -n 5p)" = "ESC[2m" ] || fail "paint-with-colours-wraps-in-prefix-and-reset: Ansi16 note is $(echo "$prefixes" | sed -n 5p)"
echo "$paint" | grep -qF 'return $"{prefix}{text}\u{1b}[0m"' \
  || fail "paint-with-colours-wraps-in-prefix-and-reset: t5Paint does not wrap in prefix and reset"

[ "$(echo "$prefixes" | sed -n 6p)" = "ESC[38;2;180;35;24m" ] || fail "truecolor-prefixes-come-from-hex: light error $(echo "$prefixes" | sed -n 6p)"
[ "$(echo "$prefixes" | sed -n 11p)" = "ESC[38;2;255;138;128m" ] || fail "truecolor-prefixes-come-from-hex: dark error $(echo "$prefixes" | sed -n 11p)"
echo "contrast: ok (6 checks)"
