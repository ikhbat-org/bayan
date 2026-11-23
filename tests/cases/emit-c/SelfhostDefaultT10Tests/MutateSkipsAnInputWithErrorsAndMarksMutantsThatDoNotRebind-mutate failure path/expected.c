== a.byn
errors
== b.byn
notEmitted boundary 0
notEmitted relational 0
notEmitted logical 0
notEmitted condition 0
notEmitted bool 0
notEmitted arithmetic 0
notEmitted literal 0
notEmitted negation 0
notEmitted statement 1
notEmitted emptyReturn 0
notEmitted variant 0
switches 28
{
  "version": 1,
  "sites": [
    {
      "id": 1,
      "file": "b.byn",
      "line": 16,
      "column": 8,
      "operator": "condition",
      "original": "x < 0 && x != -5 || x == 9",
      "mutated": "!(x < 0 && x != -5 || x == 9)"
    },
    {
      "id": 2,
      "file": "b.byn",
      "line": 16,
      "column": 8,
      "operator": "logical",
      "original": "x < 0 && x != -5 || x == 9",
      "mutated": "x < 0 && x != -5 && x == 9"
    },
    {
      "id": 3,
      "file": "b.byn",
      "line": 16,
      "column": 8,
      "operator": "logical",
      "original": "x < 0 && x != -5",
      "mutated": "x < 0 || x != -5"
    },
    {
      "id": 4,
      "file": "b.byn",
      "line": 16,
      "column": 8,
      "operator": "boundary",
      "original": "x < 0",
      "mutated": "x <= 0"
    },
    {
      "id": 5,
      "file": "b.byn",
      "line": 16,
      "column": 8,
      "operator": "relational",
      "original": "x < 0",
      "mutated": "x >= 0"
    },
    {
      "id": 6,
      "file": "b.byn",
      "line": 16,
      "column": 12,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 7,
      "file": "b.byn",
      "line": 16,
      "column": 12,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 8,
      "file": "b.byn",
      "line": 16,
      "column": 17,
      "operator": "relational",
      "original": "x != -5",
      "mutated": "x == -5"
    },
    {
      "id": 9,
      "file": "b.byn",
      "line": 16,
      "column": 22,
      "operator": "literal",
      "original": "-5",
      "mutated": "-4"
    },
    {
      "id": 10,
      "file": "b.byn",
      "line": 16,
      "column": 22,
      "operator": "literal",
      "original": "-5",
      "mutated": "-6"
    },
    {
      "id": 11,
      "file": "b.byn",
      "line": 16,
      "column": 28,
      "operator": "relational",
      "original": "x == 9",
      "mutated": "x != 9"
    },
    {
      "id": 12,
      "file": "b.byn",
      "line": 16,
      "column": 33,
      "operator": "literal",
      "original": "9",
      "mutated": "10"
    },
    {
      "id": 13,
      "file": "b.byn",
      "line": 16,
      "column": 33,
      "operator": "literal",
      "original": "9",
      "mutated": "8"
    },
    {
      "id": 14,
      "file": "b.byn",
      "line": 16,
      "column": 42,
      "operator": "variant",
      "original": ".a",
      "mutated": ".b"
    },
    {
      "id": 15,
      "file": "b.byn",
      "line": 17,
      "column": 16,
      "operator": "condition",
      "original": "x > 100",
      "mutated": "!(x > 100)"
    },
    {
      "id": 16,
      "file": "b.byn",
      "line": 17,
      "column": 16,
      "operator": "boundary",
      "original": "x > 100",
      "mutated": "x >= 100"
    },
    {
      "id": 17,
      "file": "b.byn",
      "line": 17,
      "column": 16,
      "operator": "relational",
      "original": "x > 100",
      "mutated": "x <= 100"
    },
    {
      "id": 18,
      "file": "b.byn",
      "line": 17,
      "column": 20,
      "operator": "literal",
      "original": "100",
      "mutated": "101"
    },
    {
      "id": 19,
      "file": "b.byn",
      "line": 17,
      "column": 20,
      "operator": "literal",
      "original": "100",
      "mutated": "99"
    },
    {
      "id": 20,
      "file": "b.byn",
      "line": 17,
      "column": 10,
      "operator": "variant",
      "original": ".b",
      "mutated": ".a"
    },
    {
      "id": 21,
      "file": "b.byn",
      "line": 18,
      "column": 16,
      "operator": "condition",
      "original": "x == 7",
      "mutated": "!(x == 7)"
    },
    {
      "id": 22,
      "file": "b.byn",
      "line": 18,
      "column": 16,
      "operator": "relational",
      "original": "x == 7",
      "mutated": "x != 7"
    },
    {
      "id": 23,
      "file": "b.byn",
      "line": 18,
      "column": 21,
      "operator": "literal",
      "original": "7",
      "mutated": "8"
    },
    {
      "id": 24,
      "file": "b.byn",
      "line": 18,
      "column": 21,
      "operator": "literal",
      "original": "7",
      "mutated": "6"
    },
    {
      "id": 25,
      "file": "b.byn",
      "line": 19,
      "column": 12,
      "operator": "emptyReturn",
      "original": "x",
      "mutated": "0"
    },
    {
      "id": 26,
      "file": "b.byn",
      "line": 24,
      "column": 30,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 27,
      "file": "b.byn",
      "line": 24,
      "column": 30,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 28,
      "file": "b.byn",
      "line": 26,
      "column": 16,
      "operator": "condition",
      "original": "y > 0",
      "mutated": "!(y > 0)"
    },
    {
      "id": 29,
      "file": "b.byn",
      "line": 26,
      "column": 16,
      "operator": "boundary",
      "original": "y > 0",
      "mutated": "y >= 0"
    },
    {
      "id": 30,
      "file": "b.byn",
      "line": 26,
      "column": 16,
      "operator": "relational",
      "original": "y > 0",
      "mutated": "y <= 0"
    },
    {
      "id": 31,
      "file": "b.byn",
      "line": 26,
      "column": 20,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 32,
      "file": "b.byn",
      "line": 26,
      "column": 20,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 33,
      "file": "b.byn",
      "line": 26,
      "column": 25,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 34,
      "file": "b.byn",
      "line": 26,
      "column": 25,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 35,
      "file": "b.byn",
      "line": 30,
      "column": 21,
      "operator": "condition",
      "original": "y > 1",
      "mutated": "!(y > 1)"
    },
    {
      "id": 36,
      "file": "b.byn",
      "line": 30,
      "column": 21,
      "operator": "boundary",
      "original": "y > 1",
      "mutated": "y >= 1"
    },
    {
      "id": 37,
      "file": "b.byn",
      "line": 30,
      "column": 21,
      "operator": "relational",
      "original": "y > 1",
      "mutated": "y <= 1"
    },
    {
      "id": 38,
      "file": "b.byn",
      "line": 30,
      "column": 25,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 39,
      "file": "b.byn",
      "line": 30,
      "column": 25,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 40,
      "file": "b.byn",
      "line": 31,
      "column": 20,
      "operator": "emptyReturn",
      "original": "2",
      "mutated": "0"
    },
    {
      "id": 41,
      "file": "b.byn",
      "line": 31,
      "column": 20,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 42,
      "file": "b.byn",
      "line": 31,
      "column": 20,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 43,
      "file": "b.byn",
      "line": 33,
      "column": 20,
      "operator": "emptyReturn",
      "original": "w",
      "mutated": "0"
    },
    {
      "id": 44,
      "file": "b.byn",
      "line": 42,
      "column": 5,
      "operator": "statement",
      "original": "xs = List<i64>()",
      "mutated": "",
      "emitted": false
    },
    {
      "id": 45,
      "file": "b.byn",
      "line": 43,
      "column": 12,
      "operator": "emptyReturn",
      "original": "n + xs.length",
      "mutated": "0"
    },
    {
      "id": 46,
      "file": "b.byn",
      "line": 43,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + xs.length",
      "mutated": "n - xs.length"
    },
    {
      "id": 47,
      "file": "b.byn",
      "line": 47,
      "column": 5,
      "operator": "statement",
      "original": "print($\"{again()}\")",
      "mutated": ""
    },
    {
      "id": 48,
      "file": "b.byn",
      "line": 48,
      "column": 26,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 49,
      "file": "b.byn",
      "line": 48,
      "column": 26,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 50,
      "file": "b.byn",
      "line": 49,
      "column": 30,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 51,
      "file": "b.byn",
      "line": 49,
      "column": 30,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 52,
      "file": "b.byn",
      "line": 50,
      "column": 5,
      "operator": "statement",
      "original": "print($\"{r}\")",
      "mutated": ""
    }
  ]
}
