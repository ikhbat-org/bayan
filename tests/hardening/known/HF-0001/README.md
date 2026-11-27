# HF-0001: `Untrusted<bool>` converts implicitly to `bool`

`bayan check main.byn` exits 0. Expected: BYN2202, as for `Untrusted<string>` and `Untrusted<i64>` assigned to `string`/`i64` (both rejected with BYN2202 on dev 70be08e7e). Spec §15.1: "There is no implicit conversion either way"; only an `Untrusted<bool>` used as a condition is clean.
