Write a file that declares an error set and two functions for times of day written `HH:MM`. Do not write a `main` function or any top-level statements.

Declare the error set `TimeError` with two cases:

- `badFormat`: the text is not two numbers joined by one colon.
- `outOfRange`: the hour is past 23 or the minute is past 59.

Declare:

```
i64 minutesOfDay(string text) fails TimeError
i64 minutesUntil(string iftar, from string now) fails TimeError
```

`minutesOfDay` returns the minutes since midnight. The text must be two parts separated by one `:`, each part a whole number written with digits only. One digit is enough (`5:07` is 307). Anything else fails `badFormat`: no colon, two colons, an empty part, a sign, a letter. A well-formed text with an hour above 23 or a minute above 59 fails `outOfRange`.

`minutesUntil` returns how many minutes pass from `now` until `iftar`, both in the same form. When `iftar` is earlier in the day than `now`, it is tomorrow's iftar, so the answer is still 0 or more. An error from either text is passed on unchanged.

Examples: `minutesOfDay("18:42")` is 1122. `minutesUntil("18:42", from: "17:30")` is 72. `minutesUntil("18:42", from: "19:00")` is 1422.
