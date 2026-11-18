== r.byn
notEmitted boundary 0
notEmitted relational 0
notEmitted logical 0
notEmitted condition 2
notEmitted bool 1
notEmitted arithmetic 0
notEmitted literal 4
notEmitted negation 0
notEmitted statement 0
notEmitted emptyReturn 0
notEmitted variant 4
switches 71
{
  "version": 1,
  "sites": [
    {
      "id": 1,
      "file": "r.byn",
      "line": 19,
      "column": 25,
      "operator": "condition",
      "original": "x > 10",
      "mutated": "!(x > 10)"
    },
    {
      "id": 2,
      "file": "r.byn",
      "line": 19,
      "column": 25,
      "operator": "boundary",
      "original": "x > 10",
      "mutated": "x >= 10"
    },
    {
      "id": 3,
      "file": "r.byn",
      "line": 19,
      "column": 25,
      "operator": "relational",
      "original": "x > 10",
      "mutated": "x <= 10"
    },
    {
      "id": 4,
      "file": "r.byn",
      "line": 19,
      "column": 29,
      "operator": "literal",
      "original": "10",
      "mutated": "11"
    },
    {
      "id": 5,
      "file": "r.byn",
      "line": 19,
      "column": 29,
      "operator": "literal",
      "original": "10",
      "mutated": "9"
    },
    {
      "id": 6,
      "file": "r.byn",
      "line": 19,
      "column": 10,
      "operator": "variant",
      "original": ".b(code: x)",
      "mutated": ".c(code: x)"
    },
    {
      "id": 7,
      "file": "r.byn",
      "line": 20,
      "column": 25,
      "operator": "condition",
      "original": "x == 3",
      "mutated": "!(x == 3)"
    },
    {
      "id": 8,
      "file": "r.byn",
      "line": 20,
      "column": 25,
      "operator": "relational",
      "original": "x == 3",
      "mutated": "x != 3"
    },
    {
      "id": 9,
      "file": "r.byn",
      "line": 20,
      "column": 30,
      "operator": "literal",
      "original": "3",
      "mutated": "4"
    },
    {
      "id": 10,
      "file": "r.byn",
      "line": 20,
      "column": 30,
      "operator": "literal",
      "original": "3",
      "mutated": "2"
    },
    {
      "id": 11,
      "file": "r.byn",
      "line": 20,
      "column": 10,
      "operator": "variant",
      "original": ".c(code: 1)",
      "mutated": ".b(code: 1)"
    },
    {
      "id": 12,
      "file": "r.byn",
      "line": 21,
      "column": 12,
      "operator": "condition",
      "original": "x != 4",
      "mutated": "!(x != 4)",
      "emitted": false
    },
    {
      "id": 13,
      "file": "r.byn",
      "line": 21,
      "column": 12,
      "operator": "relational",
      "original": "x != 4",
      "mutated": "x == 4"
    },
    {
      "id": 14,
      "file": "r.byn",
      "line": 21,
      "column": 17,
      "operator": "literal",
      "original": "4",
      "mutated": "5"
    },
    {
      "id": 15,
      "file": "r.byn",
      "line": 21,
      "column": 17,
      "operator": "literal",
      "original": "4",
      "mutated": "3"
    },
    {
      "id": 16,
      "file": "r.byn",
      "line": 22,
      "column": 12,
      "operator": "emptyReturn",
      "original": "x * 2",
      "mutated": "0"
    },
    {
      "id": 17,
      "file": "r.byn",
      "line": 22,
      "column": 12,
      "operator": "arithmetic",
      "original": "x * 2",
      "mutated": "x / 2"
    },
    {
      "id": 18,
      "file": "r.byn",
      "line": 22,
      "column": 16,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 19,
      "file": "r.byn",
      "line": 22,
      "column": 16,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 20,
      "file": "r.byn",
      "line": 26,
      "column": 13,
      "operator": "arithmetic",
      "original": "(try risky(x)) + 1",
      "mutated": "(try risky(x)) - 1"
    },
    {
      "id": 21,
      "file": "r.byn",
      "line": 26,
      "column": 30,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 22,
      "file": "r.byn",
      "line": 26,
      "column": 30,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 23,
      "file": "r.byn",
      "line": 27,
      "column": 12,
      "operator": "emptyReturn",
      "original": "v - 1",
      "mutated": "0"
    },
    {
      "id": 24,
      "file": "r.byn",
      "line": 27,
      "column": 12,
      "operator": "arithmetic",
      "original": "v - 1",
      "mutated": "v + 1"
    },
    {
      "id": 25,
      "file": "r.byn",
      "line": 27,
      "column": 16,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 26,
      "file": "r.byn",
      "line": 27,
      "column": 16,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 27,
      "file": "r.byn",
      "line": 31,
      "column": 22,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 28,
      "file": "r.byn",
      "line": 31,
      "column": 22,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 29,
      "file": "r.byn",
      "line": 32,
      "column": 18,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 30,
      "file": "r.byn",
      "line": 32,
      "column": 18,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 31,
      "file": "r.byn",
      "line": 34,
      "column": 12,
      "operator": "condition",
      "original": "i >= n",
      "mutated": "!(i >= n)"
    },
    {
      "id": 32,
      "file": "r.byn",
      "line": 34,
      "column": 12,
      "operator": "boundary",
      "original": "i >= n",
      "mutated": "i > n"
    },
    {
      "id": 33,
      "file": "r.byn",
      "line": 34,
      "column": 12,
      "operator": "relational",
      "original": "i >= n",
      "mutated": "i < n"
    },
    {
      "id": 34,
      "file": "r.byn",
      "line": 35,
      "column": 9,
      "operator": "statement",
      "original": "total += i",
      "mutated": ""
    },
    {
      "id": 35,
      "file": "r.byn",
      "line": 35,
      "column": 9,
      "operator": "arithmetic",
      "original": "total += i",
      "mutated": "total -= i"
    },
    {
      "id": 36,
      "file": "r.byn",
      "line": 36,
      "column": 9,
      "operator": "statement",
      "original": "total -= 1",
      "mutated": ""
    },
    {
      "id": 37,
      "file": "r.byn",
      "line": 36,
      "column": 9,
      "operator": "arithmetic",
      "original": "total -= 1",
      "mutated": "total += 1"
    },
    {
      "id": 38,
      "file": "r.byn",
      "line": 36,
      "column": 18,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 39,
      "file": "r.byn",
      "line": 36,
      "column": 18,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 40,
      "file": "r.byn",
      "line": 37,
      "column": 9,
      "operator": "statement",
      "original": "total *= 2",
      "mutated": ""
    },
    {
      "id": 41,
      "file": "r.byn",
      "line": 37,
      "column": 9,
      "operator": "arithmetic",
      "original": "total *= 2",
      "mutated": "total /= 2"
    },
    {
      "id": 42,
      "file": "r.byn",
      "line": 37,
      "column": 18,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 43,
      "file": "r.byn",
      "line": 37,
      "column": 18,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 44,
      "file": "r.byn",
      "line": 38,
      "column": 9,
      "operator": "statement",
      "original": "total /= 2",
      "mutated": ""
    },
    {
      "id": 45,
      "file": "r.byn",
      "line": 38,
      "column": 9,
      "operator": "arithmetic",
      "original": "total /= 2",
      "mutated": "total *= 2"
    },
    {
      "id": 46,
      "file": "r.byn",
      "line": 38,
      "column": 18,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 47,
      "file": "r.byn",
      "line": 38,
      "column": 18,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 48,
      "file": "r.byn",
      "line": 39,
      "column": 9,
      "operator": "statement",
      "original": "total %= 1000",
      "mutated": ""
    },
    {
      "id": 49,
      "file": "r.byn",
      "line": 39,
      "column": 9,
      "operator": "arithmetic",
      "original": "total %= 1000",
      "mutated": "total *= 1000"
    },
    {
      "id": 50,
      "file": "r.byn",
      "line": 39,
      "column": 18,
      "operator": "literal",
      "original": "1000",
      "mutated": "1001"
    },
    {
      "id": 51,
      "file": "r.byn",
      "line": 39,
      "column": 18,
      "operator": "literal",
      "original": "1000",
      "mutated": "999"
    },
    {
      "id": 52,
      "file": "r.byn",
      "line": 40,
      "column": 9,
      "operator": "statement",
      "original": "i += 1",
      "mutated": ""
    },
    {
      "id": 53,
      "file": "r.byn",
      "line": 40,
      "column": 9,
      "operator": "arithmetic",
      "original": "i += 1",
      "mutated": "i -= 1"
    },
    {
      "id": 54,
      "file": "r.byn",
      "line": 40,
      "column": 14,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 55,
      "file": "r.byn",
      "line": 40,
      "column": 14,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 56,
      "file": "r.byn",
      "line": 42,
      "column": 15,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 57,
      "file": "r.byn",
      "line": 42,
      "column": 15,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 58,
      "file": "r.byn",
      "line": 42,
      "column": 18,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 59,
      "file": "r.byn",
      "line": 42,
      "column": 18,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 60,
      "file": "r.byn",
      "line": 42,
      "column": 21,
      "operator": "literal",
      "original": "3",
      "mutated": "4"
    },
    {
      "id": 61,
      "file": "r.byn",
      "line": 42,
      "column": 21,
      "operator": "literal",
      "original": "3",
      "mutated": "2"
    },
    {
      "id": 62,
      "file": "r.byn",
      "line": 43,
      "column": 5,
      "operator": "statement",
      "original": "xs[0] = 7",
      "mutated": ""
    },
    {
      "id": 63,
      "file": "r.byn",
      "line": 43,
      "column": 8,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 64,
      "file": "r.byn",
      "line": 43,
      "column": 13,
      "operator": "literal",
      "original": "7",
      "mutated": "8"
    },
    {
      "id": 65,
      "file": "r.byn",
      "line": 43,
      "column": 13,
      "operator": "literal",
      "original": "7",
      "mutated": "6"
    },
    {
      "id": 66,
      "file": "r.byn",
      "line": 44,
      "column": 5,
      "operator": "statement",
      "original": "xs[^1] = 9",
      "mutated": ""
    },
    {
      "id": 67,
      "file": "r.byn",
      "line": 44,
      "column": 9,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 68,
      "file": "r.byn",
      "line": 44,
      "column": 14,
      "operator": "literal",
      "original": "9",
      "mutated": "10"
    },
    {
      "id": 69,
      "file": "r.byn",
      "line": 44,
      "column": 14,
      "operator": "literal",
      "original": "9",
      "mutated": "8"
    },
    {
      "id": 70,
      "file": "r.byn",
      "line": 47,
      "column": 13,
      "operator": "condition",
      "original": "false",
      "mutated": "!(false)"
    },
    {
      "id": 71,
      "file": "r.byn",
      "line": 46,
      "column": 9,
      "operator": "statement",
      "original": "total += 1",
      "mutated": ""
    },
    {
      "id": 72,
      "file": "r.byn",
      "line": 46,
      "column": 9,
      "operator": "arithmetic",
      "original": "total += 1",
      "mutated": "total -= 1"
    },
    {
      "id": 73,
      "file": "r.byn",
      "line": 46,
      "column": 18,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 74,
      "file": "r.byn",
      "line": 46,
      "column": 18,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 75,
      "file": "r.byn",
      "line": 47,
      "column": 13,
      "operator": "bool",
      "original": "false",
      "mutated": "true"
    },
    {
      "id": 76,
      "file": "r.byn",
      "line": 48,
      "column": 16,
      "operator": "bool",
      "original": "false",
      "mutated": "true"
    },
    {
      "id": 77,
      "file": "r.byn",
      "line": 49,
      "column": 5,
      "operator": "statement",
      "original": "flag = true",
      "mutated": ""
    },
    {
      "id": 78,
      "file": "r.byn",
      "line": 49,
      "column": 12,
      "operator": "bool",
      "original": "true",
      "mutated": "false"
    },
    {
      "id": 79,
      "file": "r.byn",
      "line": 50,
      "column": 8,
      "operator": "condition",
      "original": "flag && true",
      "mutated": "!(flag && true)"
    },
    {
      "id": 80,
      "file": "r.byn",
      "line": 50,
      "column": 8,
      "operator": "logical",
      "original": "flag && true",
      "mutated": "flag || true"
    },
    {
      "id": 81,
      "file": "r.byn",
      "line": 50,
      "column": 16,
      "operator": "bool",
      "original": "true",
      "mutated": "false"
    },
    {
      "id": 82,
      "file": "r.byn",
      "line": 50,
      "column": 23,
      "operator": "statement",
      "original": "total -= 1",
      "mutated": ""
    },
    {
      "id": 83,
      "file": "r.byn",
      "line": 50,
      "column": 23,
      "operator": "arithmetic",
      "original": "total -= 1",
      "mutated": "total += 1"
    },
    {
      "id": 84,
      "file": "r.byn",
      "line": 50,
      "column": 32,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 85,
      "file": "r.byn",
      "line": 50,
      "column": 32,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 86,
      "file": "r.byn",
      "line": 51,
      "column": 22,
      "operator": "literal",
      "original": "-5",
      "mutated": "-4"
    },
    {
      "id": 87,
      "file": "r.byn",
      "line": 51,
      "column": 22,
      "operator": "literal",
      "original": "-5",
      "mutated": "-6"
    },
    {
      "id": 88,
      "file": "r.byn",
      "line": 53,
      "column": 12,
      "operator": "emptyReturn",
      "original": "total + xs[0] + xs[^1] + i64(small) + f(1) + pick(1)",
      "mutated": "0"
    },
    {
      "id": 89,
      "file": "r.byn",
      "line": 53,
      "column": 12,
      "operator": "arithmetic",
      "original": "total + xs[0] + xs[^1] + i64(small) + f(1) + pick(1)",
      "mutated": "total + xs[0] + xs[^1] + i64(small) + f(1) - pick(1)"
    },
    {
      "id": 90,
      "file": "r.byn",
      "line": 53,
      "column": 12,
      "operator": "arithmetic",
      "original": "total + xs[0] + xs[^1] + i64(small) + f(1)",
      "mutated": "total + xs[0] + xs[^1] + i64(small) - f(1)"
    },
    {
      "id": 91,
      "file": "r.byn",
      "line": 53,
      "column": 12,
      "operator": "arithmetic",
      "original": "total + xs[0] + xs[^1] + i64(small)",
      "mutated": "total + xs[0] + xs[^1] - i64(small)"
    },
    {
      "id": 92,
      "file": "r.byn",
      "line": 53,
      "column": 12,
      "operator": "arithmetic",
      "original": "total + xs[0] + xs[^1]",
      "mutated": "total + xs[0] - xs[^1]"
    },
    {
      "id": 93,
      "file": "r.byn",
      "line": 53,
      "column": 12,
      "operator": "arithmetic",
      "original": "total + xs[0]",
      "mutated": "total - xs[0]"
    },
    {
      "id": 94,
      "file": "r.byn",
      "line": 53,
      "column": 23,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 95,
      "file": "r.byn",
      "line": 53,
      "column": 32,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 96,
      "file": "r.byn",
      "line": 53,
      "column": 52,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 97,
      "file": "r.byn",
      "line": 53,
      "column": 52,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 98,
      "file": "r.byn",
      "line": 53,
      "column": 62,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 99,
      "file": "r.byn",
      "line": 53,
      "column": 62,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 100,
      "file": "r.byn",
      "line": 59,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 101,
      "file": "r.byn",
      "line": 59,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 102,
      "file": "r.byn",
      "line": 59,
      "column": 30,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 103,
      "file": "r.byn",
      "line": 59,
      "column": 30,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 104,
      "file": "r.byn",
      "line": 60,
      "column": 19,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 105,
      "file": "r.byn",
      "line": 60,
      "column": 19,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 106,
      "file": "r.byn",
      "line": 60,
      "column": 28,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 107,
      "file": "r.byn",
      "line": 60,
      "column": 28,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 108,
      "file": "r.byn",
      "line": 61,
      "column": 19,
      "operator": "literal",
      "original": "20",
      "mutated": "21"
    },
    {
      "id": 109,
      "file": "r.byn",
      "line": 61,
      "column": 19,
      "operator": "literal",
      "original": "20",
      "mutated": "19"
    },
    {
      "id": 110,
      "file": "r.byn",
      "line": 61,
      "column": 29,
      "operator": "literal",
      "original": "5",
      "mutated": "6"
    },
    {
      "id": 111,
      "file": "r.byn",
      "line": 61,
      "column": 29,
      "operator": "literal",
      "original": "5",
      "mutated": "4"
    },
    {
      "id": 112,
      "file": "r.byn",
      "line": 62,
      "column": 5,
      "operator": "statement",
      "original": "print($\"{p.sum} {p.scaled(3)} {r} {q} {loops(5)} {escapes()}\")",
      "mutated": ""
    },
    {
      "id": 113,
      "file": "r.byn",
      "line": 62,
      "column": 31,
      "operator": "literal",
      "original": "3",
      "mutated": "4"
    },
    {
      "id": 114,
      "file": "r.byn",
      "line": 62,
      "column": 31,
      "operator": "literal",
      "original": "3",
      "mutated": "2"
    },
    {
      "id": 115,
      "file": "r.byn",
      "line": 62,
      "column": 50,
      "operator": "literal",
      "original": "5",
      "mutated": "6"
    },
    {
      "id": 116,
      "file": "r.byn",
      "line": 62,
      "column": 50,
      "operator": "literal",
      "original": "5",
      "mutated": "4"
    },
    {
      "id": 117,
      "file": "r.byn",
      "line": 11,
      "column": 16,
      "operator": "arithmetic",
      "original": "x + y",
      "mutated": "x - y"
    },
    {
      "id": 118,
      "file": "r.byn",
      "line": 13,
      "column": 26,
      "operator": "arithmetic",
      "original": "x * k + y",
      "mutated": "x * k - y"
    },
    {
      "id": 119,
      "file": "r.byn",
      "line": 13,
      "column": 26,
      "operator": "arithmetic",
      "original": "x * k",
      "mutated": "x / k"
    },
    {
      "id": 120,
      "file": "r.byn",
      "line": 52,
      "column": 30,
      "operator": "arithmetic",
      "original": "a + 1",
      "mutated": "a - 1"
    },
    {
      "id": 121,
      "file": "r.byn",
      "line": 52,
      "column": 34,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 122,
      "file": "r.byn",
      "line": 52,
      "column": 34,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    }
  ]
}
