Write a file that declares two error sets, the second narrowed from the first, and two functions that read where a reader of the Quran stopped. Do not write a `main` function or any top-level statements.

Declare the error set `PageError` with three cases:

- `blank`: the text is empty.
- `notNumber`: the text is not a whole number of 1 or more.
- `pastEnd`, carrying the last page as an `i64` named `last`.

Declare the error set `ResumeError` as `PageError` without its `blank` case. Do not declare its cases again: a `PageError.notNumber` must be a `ResumeError`.

Declare:

```
i64 pageOf(string text) fails PageError
i64 resumePage(string text) fails ResumeError
```

`pageOf` reads a page of a mushaf of 604 pages. A page is a whole number written with digits only; leading zeros are allowed. Empty text fails `blank`. Text that is not a whole number (a word, a decimal point, a sign, a space) fails `notNumber`, and so does 0. A page above 604 fails `pastEnd` with `last` set to 604.

`resumePage` reads the page with `pageOf`. When nothing is written, the reader starts at page 1, so `blank` gives 1. Every other error is passed on unchanged.

Example: `resumePage("41")` is 41.
