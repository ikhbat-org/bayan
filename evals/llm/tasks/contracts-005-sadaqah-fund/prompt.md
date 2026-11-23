Write a file with a distinct type, a struct and five functions, all with rules that are checked when a value is built. Do not write a `main` function or any top-level statements.

Declare `Amount` as a distinct type over `i64` that only holds 1 through 1000000. The rule is a `requires` rule on the type.

Declare the struct `Fund`, a sadaqah fund with a target. It has three fields:

- `name`, a `string`, of 1 through 20 characters,
- `target`, an `i64`, above 0,
- `raised`, an `i64`, of 0 or more.

It has one more rule: `raised` is never above `target`.

Write every rule as a `requires` rule, so that an invalid `Amount` or `Fund` cannot exist.

Declare:

```
Fund openFund(string name, for i64 target) fails ValidationError<Fund>
Fund donate(Fund fund, by Amount gift) fails ValidationError<Fund>
Fund donateAll(Fund fund, from List<i64> gifts) fails ValidationError<Amount>, ValidationError<Fund>
Fund mergeFunds(Fund a, to Fund b) fails ValidationError<Fund>
i64 roomLeft(Fund fund)
```

`openFund` returns a fund with nothing raised. `donate` returns the fund with `gift` added to what is raised, and fails when that breaks a rule. `donateAll` adds each gift in order, first making an `Amount` of it. It stops at the first gift that fails and returns that failure. `mergeFunds` returns one fund: the names mergeFunds with ` and ` between them, the targets added and the raised amounts added. It fails when the result breaks a rule. `roomLeft` returns how much is left to raise.

Examples: a fund opened for 500 has 500 `roomLeft`. A `donate` of 600 to it fails.
