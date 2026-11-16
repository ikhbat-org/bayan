This Bayān file does not compile. Fix it so that it compiles and prints what its author meant. Change only what the diagnostics require.

```
/// Dates left after every guest takes `each`.
i64 remaining(i64 dates, for i64 guests, by i64 each) => dates - guests * each

void main() {
    let left = remaining(40, 9, 3)
    print($"dates left: {left}")
    print($"enough for Aisha's table: {left >= 0}")
}
```

The compiler reports:

```
error BYN5005: `guests` is passed without its particle `for:`
  --> solution.byn:5:30

  5 │     let left = remaining(40, 9, 3)
    │                              ^ needs `for:`
    │
  help: add `for:` before the argument
    │ 5 │     let left = remaining(40, for: 9, 3)
    │   │                              +++++

error BYN5005: `each` is passed without its particle `by:`
  --> solution.byn:5:33

  5 │     let left = remaining(40, 9, 3)
    │                                 ^ needs `by:`
    │
  help: add `by:` before the argument
    │ 5 │     let left = remaining(40, 9, by: 3)
    │   │                                 ++++

✗ build failed: 2 errors, 0 warnings
  explain: bayan explain BYN5005
```

Expected output of the fixed program:

```
dates left: 13
enough for Aisha's table: true
```
