== e.byn
notEmitted boundary 0
notEmitted relational 0
notEmitted logical 0
notEmitted condition 4
notEmitted bool 1
notEmitted arithmetic 0
notEmitted literal 3
notEmitted negation 0
notEmitted statement 3
notEmitted emptyReturn 2
notEmitted variant 2
switches 143
{
  "version": 1,
  "sites": [
    {
      "id": 1,
      "file": "e.byn",
      "line": 42,
      "column": 26,
      "operator": "condition",
      "original": "n < 0",
      "mutated": "!(n < 0)"
    },
    {
      "id": 2,
      "file": "e.byn",
      "line": 42,
      "column": 26,
      "operator": "boundary",
      "original": "n < 0",
      "mutated": "n <= 0"
    },
    {
      "id": 3,
      "file": "e.byn",
      "line": 42,
      "column": 26,
      "operator": "relational",
      "original": "n < 0",
      "mutated": "n >= 0"
    },
    {
      "id": 4,
      "file": "e.byn",
      "line": 42,
      "column": 30,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 5,
      "file": "e.byn",
      "line": 42,
      "column": 30,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 6,
      "file": "e.byn",
      "line": 43,
      "column": 12,
      "operator": "emptyReturn",
      "original": "n",
      "mutated": "0"
    },
    {
      "id": 7,
      "file": "e.byn",
      "line": 47,
      "column": 26,
      "operator": "condition",
      "original": "n < 0",
      "mutated": "!(n < 0)"
    },
    {
      "id": 8,
      "file": "e.byn",
      "line": 47,
      "column": 26,
      "operator": "boundary",
      "original": "n < 0",
      "mutated": "n <= 0"
    },
    {
      "id": 9,
      "file": "e.byn",
      "line": 47,
      "column": 26,
      "operator": "relational",
      "original": "n < 0",
      "mutated": "n >= 0"
    },
    {
      "id": 10,
      "file": "e.byn",
      "line": 47,
      "column": 30,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 11,
      "file": "e.byn",
      "line": 47,
      "column": 30,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 12,
      "file": "e.byn",
      "line": 48,
      "column": 12,
      "operator": "emptyReturn",
      "original": "n",
      "mutated": "0"
    },
    {
      "id": 13,
      "file": "e.byn",
      "line": 52,
      "column": 12,
      "operator": "emptyReturn",
      "original": "try narrow(n)",
      "mutated": "0"
    },
    {
      "id": 14,
      "file": "e.byn",
      "line": 56,
      "column": 27,
      "operator": "condition",
      "original": "n < 0",
      "mutated": "!(n < 0)"
    },
    {
      "id": 15,
      "file": "e.byn",
      "line": 56,
      "column": 27,
      "operator": "boundary",
      "original": "n < 0",
      "mutated": "n <= 0"
    },
    {
      "id": 16,
      "file": "e.byn",
      "line": 56,
      "column": 27,
      "operator": "relational",
      "original": "n < 0",
      "mutated": "n >= 0"
    },
    {
      "id": 17,
      "file": "e.byn",
      "line": 56,
      "column": 31,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 18,
      "file": "e.byn",
      "line": 56,
      "column": 31,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 19,
      "file": "e.byn",
      "line": 56,
      "column": 10,
      "operator": "variant",
      "original": "H.p (code: n)",
      "mutated": "H.q (code: n)"
    },
    {
      "id": 20,
      "file": "e.byn",
      "line": 57,
      "column": 12,
      "operator": "emptyReturn",
      "original": "n",
      "mutated": "0"
    },
    {
      "id": 21,
      "file": "e.byn",
      "line": 61,
      "column": 9,
      "operator": "literal",
      "original": "4",
      "mutated": "5"
    },
    {
      "id": 22,
      "file": "e.byn",
      "line": 61,
      "column": 9,
      "operator": "literal",
      "original": "4",
      "mutated": "3"
    },
    {
      "id": 23,
      "file": "e.byn",
      "line": 70,
      "column": 12,
      "operator": "emptyReturn",
      "original": "b.length",
      "mutated": "0"
    },
    {
      "id": 24,
      "file": "e.byn",
      "line": 74,
      "column": 12,
      "operator": "emptyReturn",
      "original": "\"ab\"",
      "mutated": "\"\""
    },
    {
      "id": 25,
      "file": "e.byn",
      "line": 85,
      "column": 9,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 26,
      "file": "e.byn",
      "line": 85,
      "column": 9,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 27,
      "file": "e.byn",
      "line": 86,
      "column": 5,
      "operator": "statement",
      "original": "w += 2",
      "mutated": ""
    },
    {
      "id": 28,
      "file": "e.byn",
      "line": 86,
      "column": 5,
      "operator": "arithmetic",
      "original": "w += 2",
      "mutated": "w -= 2"
    },
    {
      "id": 29,
      "file": "e.byn",
      "line": 86,
      "column": 10,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 30,
      "file": "e.byn",
      "line": 86,
      "column": 10,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 31,
      "file": "e.byn",
      "line": 87,
      "column": 13,
      "operator": "literal",
      "original": "5u",
      "mutated": "6u"
    },
    {
      "id": 32,
      "file": "e.byn",
      "line": 87,
      "column": 13,
      "operator": "literal",
      "original": "5u",
      "mutated": "4u"
    },
    {
      "id": 33,
      "file": "e.byn",
      "line": 88,
      "column": 21,
      "operator": "literal",
      "original": "-128",
      "mutated": "-127"
    },
    {
      "id": 34,
      "file": "e.byn",
      "line": 89,
      "column": 13,
      "operator": "arithmetic",
      "original": "7 / 1",
      "mutated": "7 * 1"
    },
    {
      "id": 35,
      "file": "e.byn",
      "line": 89,
      "column": 13,
      "operator": "literal",
      "original": "7",
      "mutated": "8"
    },
    {
      "id": 36,
      "file": "e.byn",
      "line": 89,
      "column": 13,
      "operator": "literal",
      "original": "7",
      "mutated": "6"
    },
    {
      "id": 37,
      "file": "e.byn",
      "line": 89,
      "column": 17,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 38,
      "file": "e.byn",
      "line": 90,
      "column": 13,
      "operator": "arithmetic",
      "original": "7 * -2",
      "mutated": "7 / -2"
    },
    {
      "id": 39,
      "file": "e.byn",
      "line": 90,
      "column": 13,
      "operator": "literal",
      "original": "7",
      "mutated": "8"
    },
    {
      "id": 40,
      "file": "e.byn",
      "line": 90,
      "column": 13,
      "operator": "literal",
      "original": "7",
      "mutated": "6"
    },
    {
      "id": 41,
      "file": "e.byn",
      "line": 90,
      "column": 17,
      "operator": "literal",
      "original": "-2",
      "mutated": "-1"
    },
    {
      "id": 42,
      "file": "e.byn",
      "line": 90,
      "column": 17,
      "operator": "literal",
      "original": "-2",
      "mutated": "-3"
    },
    {
      "id": 43,
      "file": "e.byn",
      "line": 91,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 44,
      "file": "e.byn",
      "line": 91,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 45,
      "file": "e.byn",
      "line": 91,
      "column": 27,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 46,
      "file": "e.byn",
      "line": 91,
      "column": 27,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 47,
      "file": "e.byn",
      "line": 91,
      "column": 30,
      "operator": "literal",
      "original": "3",
      "mutated": "4"
    },
    {
      "id": 48,
      "file": "e.byn",
      "line": 91,
      "column": 30,
      "operator": "literal",
      "original": "3",
      "mutated": "2"
    },
    {
      "id": 49,
      "file": "e.byn",
      "line": 92,
      "column": 13,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 50,
      "file": "e.byn",
      "line": 92,
      "column": 13,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 51,
      "file": "e.byn",
      "line": 93,
      "column": 14,
      "operator": "arithmetic",
      "original": "arr[j] + arr[1u] + arr[2ul] + -limit",
      "mutated": "arr[j] + arr[1u] + arr[2ul] - -limit"
    },
    {
      "id": 52,
      "file": "e.byn",
      "line": 93,
      "column": 14,
      "operator": "arithmetic",
      "original": "arr[j] + arr[1u] + arr[2ul]",
      "mutated": "arr[j] + arr[1u] - arr[2ul]"
    },
    {
      "id": 53,
      "file": "e.byn",
      "line": 93,
      "column": 14,
      "operator": "arithmetic",
      "original": "arr[j] + arr[1u]",
      "mutated": "arr[j] - arr[1u]"
    },
    {
      "id": 54,
      "file": "e.byn",
      "line": 93,
      "column": 27,
      "operator": "literal",
      "original": "1u",
      "mutated": "2u"
    },
    {
      "id": 55,
      "file": "e.byn",
      "line": 93,
      "column": 27,
      "operator": "literal",
      "original": "1u",
      "mutated": "0u"
    },
    {
      "id": 56,
      "file": "e.byn",
      "line": 93,
      "column": 37,
      "operator": "literal",
      "original": "2ul",
      "mutated": "1ul"
    },
    {
      "id": 57,
      "file": "e.byn",
      "line": 93,
      "column": 44,
      "operator": "negation",
      "original": "-limit",
      "mutated": "limit"
    },
    {
      "id": 58,
      "file": "e.byn",
      "line": 94,
      "column": 13,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 59,
      "file": "e.byn",
      "line": 94,
      "column": 13,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 60,
      "file": "e.byn",
      "line": 96,
      "column": 9,
      "operator": "statement",
      "original": "n += 1",
      "mutated": ""
    },
    {
      "id": 61,
      "file": "e.byn",
      "line": 96,
      "column": 9,
      "operator": "arithmetic",
      "original": "n += 1",
      "mutated": "n -= 1"
    },
    {
      "id": 62,
      "file": "e.byn",
      "line": 96,
      "column": 14,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 63,
      "file": "e.byn",
      "line": 96,
      "column": 14,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 64,
      "file": "e.byn",
      "line": 97,
      "column": 12,
      "operator": "condition",
      "original": "n > 3",
      "mutated": "!(n > 3)"
    },
    {
      "id": 65,
      "file": "e.byn",
      "line": 97,
      "column": 12,
      "operator": "boundary",
      "original": "n > 3",
      "mutated": "n >= 3"
    },
    {
      "id": 66,
      "file": "e.byn",
      "line": 97,
      "column": 12,
      "operator": "relational",
      "original": "n > 3",
      "mutated": "n <= 3"
    },
    {
      "id": 67,
      "file": "e.byn",
      "line": 97,
      "column": 16,
      "operator": "literal",
      "original": "3",
      "mutated": "4"
    },
    {
      "id": 68,
      "file": "e.byn",
      "line": 97,
      "column": 16,
      "operator": "literal",
      "original": "3",
      "mutated": "2"
    },
    {
      "id": 69,
      "file": "e.byn",
      "line": 99,
      "column": 11,
      "operator": "condition",
      "original": "false",
      "mutated": "!(false)"
    },
    {
      "id": 70,
      "file": "e.byn",
      "line": 99,
      "column": 11,
      "operator": "bool",
      "original": "false",
      "mutated": "true"
    },
    {
      "id": 71,
      "file": "e.byn",
      "line": 99,
      "column": 19,
      "operator": "statement",
      "original": "n += 1",
      "mutated": ""
    },
    {
      "id": 72,
      "file": "e.byn",
      "line": 99,
      "column": 19,
      "operator": "arithmetic",
      "original": "n += 1",
      "mutated": "n -= 1"
    },
    {
      "id": 73,
      "file": "e.byn",
      "line": 99,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 74,
      "file": "e.byn",
      "line": 99,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 75,
      "file": "e.byn",
      "line": 100,
      "column": 12,
      "operator": "condition",
      "original": "false",
      "mutated": "!(false)",
      "emitted": false
    },
    {
      "id": 76,
      "file": "e.byn",
      "line": 100,
      "column": 20,
      "operator": "statement",
      "original": "n += 2",
      "mutated": ""
    },
    {
      "id": 77,
      "file": "e.byn",
      "line": 100,
      "column": 20,
      "operator": "arithmetic",
      "original": "n += 2",
      "mutated": "n -= 2"
    },
    {
      "id": 78,
      "file": "e.byn",
      "line": 100,
      "column": 25,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 79,
      "file": "e.byn",
      "line": 100,
      "column": 25,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 80,
      "file": "e.byn",
      "line": 101,
      "column": 19,
      "operator": "condition",
      "original": "false",
      "mutated": "!(false)",
      "emitted": false
    },
    {
      "id": 81,
      "file": "e.byn",
      "line": 101,
      "column": 5,
      "operator": "statement",
      "original": "n += 4",
      "mutated": ""
    },
    {
      "id": 82,
      "file": "e.byn",
      "line": 101,
      "column": 5,
      "operator": "arithmetic",
      "original": "n += 4",
      "mutated": "n -= 4"
    },
    {
      "id": 83,
      "file": "e.byn",
      "line": 101,
      "column": 10,
      "operator": "literal",
      "original": "4",
      "mutated": "5"
    },
    {
      "id": 84,
      "file": "e.byn",
      "line": 101,
      "column": 10,
      "operator": "literal",
      "original": "4",
      "mutated": "3"
    },
    {
      "id": 85,
      "file": "e.byn",
      "line": 102,
      "column": 19,
      "operator": "condition",
      "original": "true",
      "mutated": "!(true)",
      "emitted": false
    },
    {
      "id": 86,
      "file": "e.byn",
      "line": 102,
      "column": 5,
      "operator": "statement",
      "original": "n += 5",
      "mutated": ""
    },
    {
      "id": 87,
      "file": "e.byn",
      "line": 102,
      "column": 5,
      "operator": "arithmetic",
      "original": "n += 5",
      "mutated": "n -= 5"
    },
    {
      "id": 88,
      "file": "e.byn",
      "line": 102,
      "column": 10,
      "operator": "literal",
      "original": "5",
      "mutated": "6"
    },
    {
      "id": 89,
      "file": "e.byn",
      "line": 102,
      "column": 10,
      "operator": "literal",
      "original": "5",
      "mutated": "4"
    },
    {
      "id": 90,
      "file": "e.byn",
      "line": 103,
      "column": 8,
      "operator": "condition",
      "original": "enabled",
      "mutated": "!(enabled)"
    },
    {
      "id": 91,
      "file": "e.byn",
      "line": 103,
      "column": 18,
      "operator": "statement",
      "original": "n += 1",
      "mutated": ""
    },
    {
      "id": 92,
      "file": "e.byn",
      "line": 103,
      "column": 18,
      "operator": "arithmetic",
      "original": "n += 1",
      "mutated": "n -= 1"
    },
    {
      "id": 93,
      "file": "e.byn",
      "line": 103,
      "column": 23,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 94,
      "file": "e.byn",
      "line": 103,
      "column": 23,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 95,
      "file": "e.byn",
      "line": 104,
      "column": 5,
      "operator": "statement",
      "original": "@unobservable because \"only logged\"\n    n += 6",
      "mutated": "",
      "unobservable": "only logged"
    },
    {
      "id": 96,
      "file": "e.byn",
      "line": 104,
      "column": 5,
      "operator": "arithmetic",
      "original": "@unobservable because \"only logged\"\n    n += 6",
      "mutated": "@unobservable because \"only logged\"\n    n -= 6",
      "unobservable": "only logged"
    },
    {
      "id": 97,
      "file": "e.byn",
      "line": 105,
      "column": 10,
      "operator": "literal",
      "original": "6",
      "mutated": "7",
      "unobservable": "only logged"
    },
    {
      "id": 98,
      "file": "e.byn",
      "line": 105,
      "column": 10,
      "operator": "literal",
      "original": "6",
      "mutated": "5",
      "unobservable": "only logged"
    },
    {
      "id": 99,
      "file": "e.byn",
      "line": 107,
      "column": 8,
      "operator": "condition",
      "original": "x < 9",
      "mutated": "!(x < 9)"
    },
    {
      "id": 100,
      "file": "e.byn",
      "line": 107,
      "column": 8,
      "operator": "boundary",
      "original": "x < 9",
      "mutated": "x <= 9",
      "unobservable": "x is clamped by the caller"
    },
    {
      "id": 101,
      "file": "e.byn",
      "line": 107,
      "column": 8,
      "operator": "relational",
      "original": "x < 9",
      "mutated": "x >= 9"
    },
    {
      "id": 102,
      "file": "e.byn",
      "line": 107,
      "column": 12,
      "operator": "literal",
      "original": "9",
      "mutated": "10"
    },
    {
      "id": 103,
      "file": "e.byn",
      "line": 107,
      "column": 12,
      "operator": "literal",
      "original": "9",
      "mutated": "8"
    },
    {
      "id": 104,
      "file": "e.byn",
      "line": 107,
      "column": 16,
      "operator": "statement",
      "original": "n += 7",
      "mutated": ""
    },
    {
      "id": 105,
      "file": "e.byn",
      "line": 107,
      "column": 16,
      "operator": "arithmetic",
      "original": "n += 7",
      "mutated": "n -= 7"
    },
    {
      "id": 106,
      "file": "e.byn",
      "line": 107,
      "column": 21,
      "operator": "literal",
      "original": "7",
      "mutated": "8"
    },
    {
      "id": 107,
      "file": "e.byn",
      "line": 107,
      "column": 21,
      "operator": "literal",
      "original": "7",
      "mutated": "6"
    },
    {
      "id": 108,
      "file": "e.byn",
      "line": 108,
      "column": 32,
      "operator": "literal",
      "original": "3",
      "mutated": "4"
    },
    {
      "id": 109,
      "file": "e.byn",
      "line": 108,
      "column": 32,
      "operator": "literal",
      "original": "3",
      "mutated": "2"
    },
    {
      "id": 110,
      "file": "e.byn",
      "line": 109,
      "column": 14,
      "operator": "logical",
      "original": "x > 0 || panic(\"negative\")",
      "mutated": "x > 0 && panic(\"negative\")"
    },
    {
      "id": 111,
      "file": "e.byn",
      "line": 109,
      "column": 14,
      "operator": "boundary",
      "original": "x > 0",
      "mutated": "x >= 0"
    },
    {
      "id": 112,
      "file": "e.byn",
      "line": 109,
      "column": 14,
      "operator": "relational",
      "original": "x > 0",
      "mutated": "x <= 0"
    },
    {
      "id": 113,
      "file": "e.byn",
      "line": 109,
      "column": 18,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 114,
      "file": "e.byn",
      "line": 109,
      "column": 18,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 115,
      "file": "e.byn",
      "line": 110,
      "column": 15,
      "operator": "logical",
      "original": "x > 0 &&\r\n        raw() != \"a\tb\u0001c\bd\fe\"",
      "mutated": "x > 0 ||\r\n        raw() != \"a\tb\u0001c\bd\fe\""
    },
    {
      "id": 116,
      "file": "e.byn",
      "line": 110,
      "column": 15,
      "operator": "boundary",
      "original": "x > 0",
      "mutated": "x >= 0"
    },
    {
      "id": 117,
      "file": "e.byn",
      "line": 110,
      "column": 15,
      "operator": "relational",
      "original": "x > 0",
      "mutated": "x <= 0"
    },
    {
      "id": 118,
      "file": "e.byn",
      "line": 110,
      "column": 19,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 119,
      "file": "e.byn",
      "line": 110,
      "column": 19,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 120,
      "file": "e.byn",
      "line": 111,
      "column": 9,
      "operator": "relational",
      "original": "raw() != \"a\tb\u0001c\bd\fe\"",
      "mutated": "raw() == \"a\tb\u0001c\bd\fe\""
    },
    {
      "id": 121,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "emptyReturn",
      "original": "n + u + w + i64(s) + i64(small) + q + d + a1 + v + x + (odd ? 1 : 0) + (ok ? 1 : 0)",
      "mutated": "0"
    },
    {
      "id": 122,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + u + w + i64(s) + i64(small) + q + d + a1 + v + x + (odd ? 1 : 0) + (ok ? 1 : 0)",
      "mutated": "n + u + w + i64(s) + i64(small) + q + d + a1 + v + x + (odd ? 1 : 0) - (ok ? 1 : 0)"
    },
    {
      "id": 123,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + u + w + i64(s) + i64(small) + q + d + a1 + v + x + (odd ? 1 : 0)",
      "mutated": "n + u + w + i64(s) + i64(small) + q + d + a1 + v + x - (odd ? 1 : 0)"
    },
    {
      "id": 124,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + u + w + i64(s) + i64(small) + q + d + a1 + v + x",
      "mutated": "n + u + w + i64(s) + i64(small) + q + d + a1 + v - x"
    },
    {
      "id": 125,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + u + w + i64(s) + i64(small) + q + d + a1 + v",
      "mutated": "n + u + w + i64(s) + i64(small) + q + d + a1 - v"
    },
    {
      "id": 126,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + u + w + i64(s) + i64(small) + q + d + a1",
      "mutated": "n + u + w + i64(s) + i64(small) + q + d - a1"
    },
    {
      "id": 127,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + u + w + i64(s) + i64(small) + q + d",
      "mutated": "n + u + w + i64(s) + i64(small) + q - d"
    },
    {
      "id": 128,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + u + w + i64(s) + i64(small) + q",
      "mutated": "n + u + w + i64(s) + i64(small) - q"
    },
    {
      "id": 129,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + u + w + i64(s) + i64(small)",
      "mutated": "n + u + w + i64(s) - i64(small)"
    },
    {
      "id": 130,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + u + w + i64(s)",
      "mutated": "n + u + w - i64(s)"
    },
    {
      "id": 131,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + u + w",
      "mutated": "n + u - w"
    },
    {
      "id": 132,
      "file": "e.byn",
      "line": 112,
      "column": 12,
      "operator": "arithmetic",
      "original": "n + u",
      "mutated": "n - u"
    },
    {
      "id": 133,
      "file": "e.byn",
      "line": 112,
      "column": 74,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 134,
      "file": "e.byn",
      "line": 112,
      "column": 74,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 135,
      "file": "e.byn",
      "line": 112,
      "column": 78,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 136,
      "file": "e.byn",
      "line": 112,
      "column": 78,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 137,
      "file": "e.byn",
      "line": 112,
      "column": 89,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 138,
      "file": "e.byn",
      "line": 112,
      "column": 89,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 139,
      "file": "e.byn",
      "line": 112,
      "column": 93,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 140,
      "file": "e.byn",
      "line": 112,
      "column": 93,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 141,
      "file": "e.byn",
      "line": 116,
      "column": 32,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 142,
      "file": "e.byn",
      "line": 116,
      "column": 32,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 143,
      "file": "e.byn",
      "line": 118,
      "column": 20,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 144,
      "file": "e.byn",
      "line": 118,
      "column": 20,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 145,
      "file": "e.byn",
      "line": 118,
      "column": 29,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 146,
      "file": "e.byn",
      "line": 118,
      "column": 29,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 147,
      "file": "e.byn",
      "line": 119,
      "column": 21,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 148,
      "file": "e.byn",
      "line": 119,
      "column": 21,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 149,
      "file": "e.byn",
      "line": 119,
      "column": 30,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 150,
      "file": "e.byn",
      "line": 119,
      "column": 30,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 151,
      "file": "e.byn",
      "line": 120,
      "column": 19,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 152,
      "file": "e.byn",
      "line": 120,
      "column": 19,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 153,
      "file": "e.byn",
      "line": 120,
      "column": 26,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 154,
      "file": "e.byn",
      "line": 120,
      "column": 26,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 155,
      "file": "e.byn",
      "line": 120,
      "column": 33,
      "operator": "bool",
      "original": "true",
      "mutated": "false"
    },
    {
      "id": 156,
      "file": "e.byn",
      "line": 120,
      "column": 45,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 157,
      "file": "e.byn",
      "line": 120,
      "column": 45,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 158,
      "file": "e.byn",
      "line": 121,
      "column": 28,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 159,
      "file": "e.byn",
      "line": 121,
      "column": 28,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 160,
      "file": "e.byn",
      "line": 121,
      "column": 35,
      "operator": "bool",
      "original": "false",
      "mutated": "true"
    },
    {
      "id": 161,
      "file": "e.byn",
      "line": 122,
      "column": 33,
      "operator": "literal",
      "original": "4",
      "mutated": "5"
    },
    {
      "id": 162,
      "file": "e.byn",
      "line": 122,
      "column": 33,
      "operator": "literal",
      "original": "4",
      "mutated": "3"
    },
    {
      "id": 163,
      "file": "e.byn",
      "line": 123,
      "column": 19,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 164,
      "file": "e.byn",
      "line": 123,
      "column": 19,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 165,
      "file": "e.byn",
      "line": 123,
      "column": 28,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 166,
      "file": "e.byn",
      "line": 123,
      "column": 28,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 167,
      "file": "e.byn",
      "line": 124,
      "column": 26,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 168,
      "file": "e.byn",
      "line": 124,
      "column": 26,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 169,
      "file": "e.byn",
      "line": 125,
      "column": 18,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 170,
      "file": "e.byn",
      "line": 125,
      "column": 18,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 171,
      "file": "e.byn",
      "line": 125,
      "column": 24,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 172,
      "file": "e.byn",
      "line": 125,
      "column": 24,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 173,
      "file": "e.byn",
      "line": 127,
      "column": 19,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 174,
      "file": "e.byn",
      "line": 127,
      "column": 19,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 175,
      "file": "e.byn",
      "line": 127,
      "column": 28,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 176,
      "file": "e.byn",
      "line": 127,
      "column": 28,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 177,
      "file": "e.byn",
      "line": 128,
      "column": 17,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 178,
      "file": "e.byn",
      "line": 128,
      "column": 17,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 179,
      "file": "e.byn",
      "line": 128,
      "column": 26,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 180,
      "file": "e.byn",
      "line": 128,
      "column": 26,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 181,
      "file": "e.byn",
      "line": 129,
      "column": 19,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 182,
      "file": "e.byn",
      "line": 129,
      "column": 19,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 183,
      "file": "e.byn",
      "line": 129,
      "column": 28,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 184,
      "file": "e.byn",
      "line": 129,
      "column": 28,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 185,
      "file": "e.byn",
      "line": 130,
      "column": 5,
      "operator": "statement",
      "original": "print($\"{o1} {o2} {nw} {nk} {nb}\")",
      "mutated": ""
    },
    {
      "id": 186,
      "file": "e.byn",
      "line": 131,
      "column": 5,
      "operator": "statement",
      "original": "print($\"{k2} {raw()}\")",
      "mutated": ""
    },
    {
      "id": 187,
      "file": "e.byn",
      "line": 132,
      "column": 12,
      "operator": "emptyReturn",
      "original": "r + rt + k1 + v2 + e + l",
      "mutated": "0"
    },
    {
      "id": 188,
      "file": "e.byn",
      "line": 132,
      "column": 12,
      "operator": "arithmetic",
      "original": "r + rt + k1 + v2 + e + l",
      "mutated": "r + rt + k1 + v2 + e - l"
    },
    {
      "id": 189,
      "file": "e.byn",
      "line": 132,
      "column": 12,
      "operator": "arithmetic",
      "original": "r + rt + k1 + v2 + e",
      "mutated": "r + rt + k1 + v2 - e"
    },
    {
      "id": 190,
      "file": "e.byn",
      "line": 132,
      "column": 12,
      "operator": "arithmetic",
      "original": "r + rt + k1 + v2",
      "mutated": "r + rt + k1 - v2"
    },
    {
      "id": 191,
      "file": "e.byn",
      "line": 132,
      "column": 12,
      "operator": "arithmetic",
      "original": "r + rt + k1",
      "mutated": "r + rt - k1"
    },
    {
      "id": 192,
      "file": "e.byn",
      "line": 132,
      "column": 12,
      "operator": "arithmetic",
      "original": "r + rt",
      "mutated": "r - rt"
    },
    {
      "id": 193,
      "file": "e.byn",
      "line": 136,
      "column": 5,
      "operator": "statement",
      "original": "print($\"{total()}\")",
      "mutated": ""
    },
    {
      "id": 194,
      "file": "e.byn",
      "line": 21,
      "column": 30,
      "operator": "condition",
      "original": "n < 0",
      "mutated": "!(n < 0)"
    },
    {
      "id": 195,
      "file": "e.byn",
      "line": 21,
      "column": 30,
      "operator": "boundary",
      "original": "n < 0",
      "mutated": "n <= 0"
    },
    {
      "id": 196,
      "file": "e.byn",
      "line": 21,
      "column": 30,
      "operator": "relational",
      "original": "n < 0",
      "mutated": "n >= 0"
    },
    {
      "id": 197,
      "file": "e.byn",
      "line": 21,
      "column": 34,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 198,
      "file": "e.byn",
      "line": 21,
      "column": 34,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 199,
      "file": "e.byn",
      "line": 21,
      "column": 14,
      "operator": "variant",
      "original": ".p (code: n)",
      "mutated": ".q (code: n)"
    },
    {
      "id": 200,
      "file": "e.byn",
      "line": 22,
      "column": 16,
      "operator": "emptyReturn",
      "original": "-n",
      "mutated": "0"
    },
    {
      "id": 201,
      "file": "e.byn",
      "line": 22,
      "column": 16,
      "operator": "negation",
      "original": "-n",
      "mutated": "n"
    },
    {
      "id": 202,
      "file": "e.byn",
      "line": 27,
      "column": 13,
      "operator": "negation",
      "original": "-n",
      "mutated": "n"
    },
    {
      "id": 203,
      "file": "e.byn",
      "line": 28,
      "column": 14,
      "operator": "bool",
      "original": "true",
      "mutated": "false"
    },
    {
      "id": 204,
      "file": "e.byn",
      "line": 29,
      "column": 13,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 205,
      "file": "e.byn",
      "line": 29,
      "column": 13,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 206,
      "file": "e.byn",
      "line": 30,
      "column": 5,
      "operator": "statement",
      "original": "k++",
      "mutated": ""
    },
    {
      "id": 207,
      "file": "e.byn",
      "line": 31,
      "column": 5,
      "operator": "statement",
      "original": "k += 2",
      "mutated": ""
    },
    {
      "id": 208,
      "file": "e.byn",
      "line": 31,
      "column": 5,
      "operator": "arithmetic",
      "original": "k += 2",
      "mutated": "k -= 2"
    },
    {
      "id": 209,
      "file": "e.byn",
      "line": 31,
      "column": 10,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 210,
      "file": "e.byn",
      "line": 31,
      "column": 10,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 211,
      "file": "e.byn",
      "line": 32,
      "column": 8,
      "operator": "condition",
      "original": "m > 5 && on",
      "mutated": "!(m > 5 && on)"
    },
    {
      "id": 212,
      "file": "e.byn",
      "line": 32,
      "column": 8,
      "operator": "logical",
      "original": "m > 5 && on",
      "mutated": "m > 5 || on"
    },
    {
      "id": 213,
      "file": "e.byn",
      "line": 32,
      "column": 8,
      "operator": "boundary",
      "original": "m > 5",
      "mutated": "m >= 5"
    },
    {
      "id": 214,
      "file": "e.byn",
      "line": 32,
      "column": 8,
      "operator": "relational",
      "original": "m > 5",
      "mutated": "m <= 5"
    },
    {
      "id": 215,
      "file": "e.byn",
      "line": 32,
      "column": 12,
      "operator": "literal",
      "original": "5",
      "mutated": "6"
    },
    {
      "id": 216,
      "file": "e.byn",
      "line": 32,
      "column": 12,
      "operator": "literal",
      "original": "5",
      "mutated": "4"
    },
    {
      "id": 217,
      "file": "e.byn",
      "line": 32,
      "column": 27,
      "operator": "variant",
      "original": "H.q (code: m)",
      "mutated": "H.p (code: m)"
    },
    {
      "id": 218,
      "file": "e.byn",
      "line": 33,
      "column": 8,
      "operator": "condition",
      "original": "!flip",
      "mutated": "!(!flip)"
    },
    {
      "id": 219,
      "file": "e.byn",
      "line": 33,
      "column": 23,
      "operator": "emptyReturn",
      "original": "a",
      "mutated": "0",
      "emitted": false
    },
    {
      "id": 220,
      "file": "e.byn",
      "line": 34,
      "column": 12,
      "operator": "emptyReturn",
      "original": "a",
      "mutated": "0",
      "emitted": false
    },
    {
      "id": 221,
      "file": "e.byn",
      "line": 38,
      "column": 12,
      "operator": "emptyReturn",
      "original": "a",
      "mutated": "null"
    }
  ]
}
