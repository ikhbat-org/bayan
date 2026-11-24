---
id: L010
title: Decode accepts exactly valid UTF-8
status: enacted
release: 0.1.0
sources: none recorded
kind: property
scope: runtime/bayan-rt.c
proof: src/driver/goldenexport.byn
check: bash scripts/ci/bootstrap-check.sh >/dev/null && BAYAN_EXE=$PWD/tmp/bootstrap-check/bayan tmp/bootstrap-check/bayan test tests/cases --only '/l010-' --only 'run/utf8' --only 'run/string-from'
enacted: 2026-10-21
---

## Statement
For every byte sequence, the decode (`string.from`, `string.tryFrom`, `string.invalidUtf8At`) succeeds exactly when the sequence is valid UTF-8, and then encoding the result gives back the input; on failure, the offset it names is where the first invalid sequence starts.

## Counterexample looks like
`ED A0 80` (a UTF-16 surrogate) or `C0 80` (an overlong NUL) decoding to a string, `string.tryFrom` returning a value where `string.from` fails, or `61 E2 82` reporting offset 2 as anything but 1.

## Proof notes
`csharp/tests/Bayan.Tests/L010Utf8DecodeTests.cs`, tagged `[Trait("Law", "L010")]`, compiles a Bayan driver once (debug build) that reads one hex line per sequence from stdin and prints, per sequence, `string.invalidUtf8At` (-1 for null), whether `string.from` and `string.tryFrom` succeed, and whether each decoded string's `bytes` equal the input. The reference is `System.Text.Rune.DecodeFromUtf8` stepped across the input: the first offset that is not `Done` (invalid or truncated), valid when there is none. Inputs: 55 edge cases (empty, ASCII, both ends of each encoded length, overlongs, surrogates D800 to DFFF, above U+10FFFF, truncations, lone continuations, F5 to FF leads), each alone, after `61`, before `61`, doubled and after `E2 82 AC`; and 4000 random sequences of length 0 to 16 from seed 311312 (`0x4C010`), half random bytes biased toward lead and continuation bytes, half valid runes with one byte possibly changed or the last byte dropped. Measured 2026-10-21 on macOS arm64: 4275 inputs, 1269 valid, all agree, about 1 s. Mutation: dropping the surrogate check in `byn_utf8_invalid_at` failed L010 with 26 counterexamples (first `eda080`); dropping the overlong check (`v < min`) failed it with 42 (first `c080`). On failure the test prints the seed and up to 20 failing inputs in hex.

Proof 2026-11-19 (spec 019 T31b): the proof is the exported case cli/L010Utf8DecodeTests/l010-decode (1 case, `run --mode debug` of the driver with the 4275 hex lines on stdin), expected output from the v0.3.2 C# export, run by `goldenCli` in src/driver/goldenexport.byn (the L006–L016 comment block); `run/utf8` and `run/string-from` stay in the check. Broke it by dropping the surrogate test in `byn_utf8_invalid_at` (src/driver/runtime.byn): `l010-decode` failed at expected line 101 (input `eda080`).
