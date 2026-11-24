Write a file that lends the books of a masjid library and keeps every refusal as an error value to explain later. Do not write a `main` function or any top-level statements.

Declare the error set `BookError` with two cases:

- `unknownBook`, carrying the book's code as a `string` named `code`.
- `onLoan`, carrying the name of whoever holds the book as a `string` named `holder`.

Declare the error set `MemberError` with two cases:

- `unknownMember`, carrying the name as a `string` named `name`.
- `atLimit`, carrying the member's limit as an `i64` named `limit`.

Declare four structs:

- `Book`, with `string` fields `code` and `holder`. An empty `holder` means the book is on the shelf.
- `Member`, with a `string` field `name` and `i64` fields `limit` (the most books the member may hold) and `holding` (how many they hold now).
- `Library`, with a `List<Book>` field `books` and a `List<Member>` field `members`.
- `Report`, with an `i64` field `lent`, a `List<BookError>` field `bookErrors` and a `List<MemberError>` field `memberErrors`.

Declare:

```
void lend(ref Library library, for string request) fails BookError, MemberError
Report lendAll(ref Library library, from List<string> requests)
string explainBook(BookError error)
string explainMember(MemberError error)
```

A request is `<code> <name>`: a book code and a member name separated by one space, neither of them empty. Codes and names are compared as written, so case counts.

`lend` checks in this order, and the first check that applies decides the failure:

1. No member has the name: fail `unknownMember` with the name.
2. No book has the code: fail `unknownBook` with the code.
3. The book's `holder` is not empty: fail `onLoan` with the holder.
4. The member's `holding` is equal to or above their `limit`: fail `atLimit` with the limit.

Otherwise the book's `holder` becomes the member's name and the member's `holding` goes up by 1. A request that fails changes nothing.

`lendAll` calls `lend` for each request in order and never fails. `lent` counts the requests that succeeded. Each `BookError` is appended to `bookErrors` and each `MemberError` to `memberErrors`, in the order they happened.

`explainBook` returns `no book <code>` or `on loan to <holder>`. `explainMember` returns `no member <name>` or `limit of <limit> reached`.

Example: with one member Umar (limit 1, holding 0) and one book `Q1` on the shelf, the requests `Q1 Umar` and `Q1 Umar` give a `Report` with `lent` 1, one book error that `explainBook` turns into `on loan to Umar`, and no member errors.
