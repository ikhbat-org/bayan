#!/usr/bin/env bash
# Law L046 (spec 024 R3) with no dotnet, ported from SabkEncoderLawTests.EncodeMatchesTheReferenceAssembler (src/tests/SabkLawTests.cs):
# the zig on PATH (or ~/.local/bin/zig) is the pinned one (.zig-version); the sweep below is assembled by
# scripts/sabk/record-encodings.sh into tmp/sabk-law046/sweep.tsv; `$BAYAN_EXE test --package src src/sabk --only L046:` passes
# exactly 1 test, which compares the recorded encodings.tsv and every sweep row with `encode` and writes the sweep rows it
# compared to tmp/sabk-law046/checked.txt; that count equals the sweep's, so a sweep it did not read cannot pass.
# The sweep is the C# test's, row for row: per form, each register of each slot with the rest drawn, each immediate edge
# with the rest drawn, then 40 fully drawn rows, from .NET's seeded Random(46) (the Knuth subtractive generator;
# Next(n) is (int)(Sample() * n); NextInt64(n) draws three samples and keeps the top ceil(log2 n) of the third's 20 bits,
# drawing again past n). Label forms branch to a label at their own address.
# BAYAN_EXE: the self-hosted driver; unset, src/driver is built with the pinned bayan (scripts/pinned-bayan.sh) into tmp/, as
# scripts/test.sh does. Off arm64 macOS it prints why and exits 0. bash 3.2.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$root"
if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then echo "l046: skipped: sabk tests need arm64 macOS (024 R9)"; exit 0; fi
fail() { echo "FAIL L046: $1"; exit 1; }

zig=zig; command -v zig >/dev/null 2>&1 || zig="$HOME/.local/bin/zig"
found="$("$zig" version 2>&1)" || true
pinned="$(tr -d '[:space:]' < .zig-version)"
[ "$found" = "$pinned" ] || fail "the reference assembler is zig $pinned (.zig-version); found $found"

bayan="${BAYAN_EXE:-}"
if [ -z "$bayan" ]; then
  mkdir -p tmp
  bayan="$root/tmp/sabk-law046-bayan"
  pin="$(bash scripts/pinned-bayan.sh 2>"$bayan.log")" && "$pin" build --mode safe --package src -o "$bayan" src/driver >>"$bayan.log" 2>&1 \
    || fail "building src/driver with the pinned bayan failed; log: $bayan.log"
fi
export BAYAN_EXE="$bayan"

dir="$root/tmp/sabk-law046"
rm -rf "$dir" && mkdir -p "$dir"
awk '
function isample(  a, b, r) {
  a = inext + 1; if (a >= 56) a = 1
  b = inextp + 1; if (b >= 56) b = 1
  r = sa[a] - sa[b]
  if (r == M) r--
  if (r < 0) r += M
  sa[a] = r; inext = a; inextp = b
  return r
}
function next_(n) { return int(isample() * (1.0 / M) * n) }
function next64(n,  bits, v) {
  bits = 0; while (2 ^ bits < n) bits++
  if (bits > 20) { print "l046: NextInt64 past 2^20 is not ported" > "/dev/stderr"; exit 1 }
  do { isample(); isample(); v = int(int(isample() * (1.0 / M) * 1048576) / 2 ^ (20 - bits)) } while (v >= n)
  return v
}
function form(id, w, slots, imms, text, label, valid) {
  nf++; fid[nf] = id; fw[nf] = w; fslots[nf] = slots; fimms[nf] = imms; ftext[nf] = text; flabel[nf] = label; fvalid[nf] = valid
}
function num(reg) { return (reg == "sp" || reg == "xzr" || reg == "wzr") ? 31 : substr(reg, 2) + 0 }
function ok(valid,  m, wb) {
  if (valid == "") return 1
  if (valid == "movsp") return r[0] == "sp" || r[1] == "sp"
  m = substr(valid, 1, 3); wb = substr(valid, 4) == "1"
  return (m == "stp" || num(r[0]) != num(r[1])) && (!wb || (r[2] != "x" num(r[0]) && r[2] != "x" num(r[1])))
}
function subst(s, k, v,  p) {
  while ((p = index(s, k)) > 0) s = substr(s, 1, p - 1) v substr(s, p + length(k))
  return s
}
function add(fixedReg, reg, fixedImm, imm,  attempt, s, k, t) {
  for (attempt = 0; attempt < 1000; attempt++) {
    for (s = 0; s < nslots; s++) r[s] = regs[s, next_(nregs[s])]
    if (fixedReg >= 0) r[fixedReg] = reg
    for (k = 0; k < nimms; k++) i[k] = (ikind[k] == "R") ? ilo[k] + istep[k] * next64((ihi[k] - ilo[k]) / istep[k] + 1) : next_(ihi[k])
    if (fixedImm >= 0) i[fixedImm] = imm
    if (!ok(fvalid[f])) continue
    t = ftext[f]
    for (s = 0; s < nslots; s++) t = subst(t, "{r" s "}", r[s])
    for (k = 0; k < nimms; k++) t = subst(t, "{i" k "}", sprintf("%d", i[k]))
    if (nimms > 0) { t = subst(t, "{shift0}", shifts[i[0]]); t = subst(t, "{cond0}", conds[i[0]]) }
    if (nimms > 1) { t = subst(t, "{sh16}", sprintf("%d", i[1] * 16)); t = subst(t, "{lsl12}", i[1] == 1 ? ", lsl #12" : "") }
    if (flabel[f]) { print "Lsw" rows ":"; t = subst(t, "{label}", "Lsw" rows) }
    print "// form: " fid[f]; print "    " t
    rows++
    return
  }
}
BEGIN {
  M = 2147483647
  mj = 161803398 - 46; sa[55] = mj; mk = 1; ii = 0
  for (n = 1; n < 55; n++) { ii += 21; if (ii >= 55) ii -= 55; sa[ii] = mk; mk = mj - mk; if (mk < 0) mk += M; mj = sa[ii] }
  for (k = 1; k < 5; k++) for (n = 1; n < 56; n++) { j = n + 30; if (j >= 55) j -= 55; sa[n] -= sa[1 + j]; if (sa[n] < 0) sa[n] += M }
  inext = 0; inextp = 21
  split("eq ne hs lo mi pl vs vc hi ls ge lt gt le al", c, " "); for (n = 1; n <= 15; n++) conds[n - 1] = c[n]
  shifts[0] = "lsl"; shifts[1] = "lsr"; shifts[2] = "asr"

  for (wi = 0; wi < 2; wi++) {
    w = wi == 0 ? "x" : "w"
    shiftMax = w == "x" ? 3 : 1; amountMax = w == "x" ? 63 : 31; size = w == "x" ? 8 : 4
    form("movz-" w, w, "Z", "R,0,65535,1 O," (shiftMax + 1), "movz {r0}, #{i0}, lsl #{sh16}")
    form("movk-" w, w, "Z", "R,0,65535,1 O," (shiftMax + 1), "movk {r0}, #{i0}, lsl #{sh16}")
    form("mov-reg-" w, w, "ZZ", "", "mov {r0}, {r1}")
    form("add-imm-" w, w, "SS", "R,0,4095,1 O,2", "add {r0}, {r1}, #{i0}{lsl12}")
    form("sub-imm-" w, w, "SS", "R,0,4095,1 O,2", "sub {r0}, {r1}, #{i0}{lsl12}")
    form("subs-imm-" w, w, "ZS", "R,0,4095,1 O,2", "subs {r0}, {r1}, #{i0}{lsl12}")
    form("cmp-imm-" w, w, "S", "R,0,4095,1 O,2", "cmp {r0}, #{i0}{lsl12}")
    split("add sub subs and orr eor", ms, " ")
    for (n = 1; n <= 6; n++) form(ms[n] "-reg-" w, w, "ZZZ", "O,3 R,0," amountMax ",1", ms[n] " {r0}, {r1}, {r2}, {shift0} #{i1}")
    form("cmp-reg-" w, w, "ZZ", "O,3 R,0," amountMax ",1", "cmp {r0}, {r1}, {shift0} #{i1}")
    form("mul-" w, w, "ZZZ", "", "mul {r0}, {r1}, {r2}")
    form("sdiv-" w, w, "ZZZ", "", "sdiv {r0}, {r1}, {r2}")
    form("msub-" w, w, "ZZZZ", "", "msub {r0}, {r1}, {r2}, {r3}")
    form("neg-" w, w, "ZZ", "", "neg {r0}, {r1}")
    form("cset-" w, w, "Z", "O,14", "cset {r0}, {cond0}")
    form("csel-" w, w, "ZZZ", "O,15", "csel {r0}, {r1}, {r2}, {cond0}")
    form("ldr-" w, w, "ZB", "R,0," (4095 * size) "," size, "ldr {r0}, [{r1}, #{i0}]")
    form("str-" w, w, "ZB", "R,0," (4095 * size) "," size, "str {r0}, [{r1}, #{i0}]")
    form("ldur-" w, w, "ZB", "R,-256,255,1", "ldur {r0}, [{r1}, #{i0}]")
    form("stur-" w, w, "ZB", "R,-256,255,1", "stur {r0}, [{r1}, #{i0}]")
    form("cbz-" w, w, "Z", "", "cbz {r0}, {label}", 1)
    form("cbnz-" w, w, "Z", "", "cbnz {r0}, {label}", 1)
  }
  form("mov-sp", "x", "SS", "", "mov {r0}, {r1}", 0, "movsp")
  split("stp ldp", ms, " ")
  for (n = 1; n <= 2; n++) {
    m = ms[n]
    form(m "-x-off", "x", "ZZS", "R,-512,504,8", m " {r0}, {r1}, [{r2}, #{i0}]", 0, m "0")
    form(m "-x-pre", "x", "ZZS", "R,-512,504,8", m " {r0}, {r1}, [{r2}, #{i0}]!", 0, m "1")
    form(m "-x-post", "x", "ZZS", "R,-512,504,8", m " {r0}, {r1}, [{r2}], #{i0}", 0, m "1")
  }
  form("b", "x", "", "", "b {label}", 1)
  form("bl", "x", "", "", "bl {label}", 1)
  form("b-cond", "x", "", "O,15", "b.{cond0} {label}", 1)
  form("br", "x", "G", "", "br {r0}")
  form("blr", "x", "G", "", "blr {r0}")
  form("ret", "x", "G", "", "ret {r0}")
  form("adrp", "x", "Z", "", "adrp {r0}, _sym@PAGE")
  form("add-pageoff", "x", "SS", "", "add {r0}, {r1}, _sym@PAGEOFF")
  form("adr", "x", "Z", "", "adr {r0}, {label}", 1)

  print ".text"
  rows = 0
  for (f = 1; f <= nf; f++) {
    nslots = length(fslots[f])
    for (s = 0; s < nslots; s++) {
      slot = substr(fslots[f], s + 1, 1); rw = slot == "B" ? "x" : fw[f]
      for (n = 0; n < 31; n++) regs[s, n] = rw n
      nregs[s] = 31
      if (slot == "Z") regs[s, nregs[s]++] = rw == "x" ? "xzr" : "wzr"
      if ((slot == "S" || slot == "B") && rw == "x") regs[s, nregs[s]++] = "sp"
    }
    nimms = fimms[f] == "" ? 0 : split(fimms[f], spec, " ")
    for (k = 0; k < nimms; k++) {
      split(spec[k + 1], p, ","); ikind[k] = p[1]
      if (p[1] == "R") { ilo[k] = p[2] + 0; ihi[k] = p[3] + 0; istep[k] = p[4] + 0 } else ihi[k] = p[2] + 0
    }
    for (s = 0; s < nslots; s++) for (n = 0; n < nregs[s]; n++) add(s, regs[s, n], -1, 0)
    for (k = 0; k < nimms; k++) {
      if (ikind[k] == "R") {
        ne = 0; split(ilo[k] " " (ilo[k] + istep[k]) " " (ihi[k] - istep[k]) " " ihi[k], cand, " ")
        for (n = 1; n <= 4; n++) { dup = 0; for (j = 0; j < ne; j++) if (edge[j] == cand[n] + 0) dup = 1; if (!dup) edge[ne++] = cand[n] + 0 }
      } else { ne = ihi[k]; for (n = 0; n < ne; n++) edge[n] = n }
      for (n = 0; n < ne; n++) add(-1, "", k, edge[n])
    }
    for (n = 0; n < 40; n++) add(-1, "", -1, 0)
  }
  print rows > "/dev/stderr"
}' > "$dir/sweep.s" 2> "$dir/rows" || fail "the sweep generator failed: $(cat "$dir/rows")"
rows="$(cat "$dir/rows")"

bash scripts/sabk/record-encodings.sh "$dir/sweep.s" "$dir/sweep.tsv" > "$dir/record.log" 2>&1 \
  || fail "record-encodings.sh failed on the sweep: $(tail -n 5 "$dir/record.log")"
rc=0; out="$("$bayan" test --package src src/sabk --only 'L046:' 2>&1)" || rc=$?
case "$out" in (*"◆ 1 passed"*) [ $rc = 0 ] ;; (*) false ;; esac || fail "L046: failed (exit $rc):
$out"
checked="$(tr -d '[:space:]' < "$dir/checked.txt" 2>/dev/null || true)"
[ "$checked" = "$rows" ] || fail "the sweep has $rows rows, the Bayān test compared '$checked'"
echo "l046: $rows sweep rows match the reference assembler"
