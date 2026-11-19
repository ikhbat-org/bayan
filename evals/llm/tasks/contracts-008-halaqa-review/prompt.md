Write a file that declares a struct whose fields have rules, and two functions. Do not write a `main` function or any top-level statements.

Declare the struct `Student`, a student joining a Quran memorisation circle, with three fields and four rules:

- `name`, a `string`: it has 2 through 20 characters, and it has no space at its start or its end (it equals itself trimmed). These are two rules.
- `age`, an `i32`: 7 through 16.
- `juz`, an `i32`, the number of parts memorised: 0 through 30.

Write each rule as its own `requires` rule on its field, so that an invalid `Student` cannot exist and each broken rule is reported on its own.

Declare:

```
Student enrol(string name, at i32 age, for i32 juz) fails ValidationError<Student>
string review(string name, at i32 age, for i32 juz)
```

`enrol` builds a `Student` and fails when a rule is broken. `review` returns `accepted <name>` when `enrol` succeeds. Otherwise it returns `refused: ` followed by the field name of every broken rule, in the order the rules are declared above, separated by `, `. A field with two broken rules appears twice. Do not check the rules by hand in `review`: read them from the error.

Example: `review("Fatima", at: 5, for: 31)` is `refused: age, juz`.
