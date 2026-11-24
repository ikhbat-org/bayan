== std-json.byn
notEmitted boundary 0
notEmitted relational 0
notEmitted logical 3
notEmitted condition 17
notEmitted bool 3
notEmitted arithmetic 0
notEmitted literal 3
notEmitted negation 0
notEmitted statement 0
notEmitted emptyReturn 18
notEmitted variant 69
switches 338
{
  "version": 1,
  "sites": [
    {
      "id": 1,
      "file": "<std>/json/reader.byn",
      "line": 366,
      "column": 23,
      "operator": "logical",
      "original": "b >= '0' && b <= '9'",
      "mutated": "b >= '0' || b <= '9'"
    },
    {
      "id": 2,
      "file": "<std>/json/reader.byn",
      "line": 366,
      "column": 23,
      "operator": "boundary",
      "original": "b >= '0'",
      "mutated": "b > '0'"
    },
    {
      "id": 3,
      "file": "<std>/json/reader.byn",
      "line": 366,
      "column": 23,
      "operator": "relational",
      "original": "b >= '0'",
      "mutated": "b < '0'"
    },
    {
      "id": 4,
      "file": "<std>/json/reader.byn",
      "line": 366,
      "column": 35,
      "operator": "boundary",
      "original": "b <= '9'",
      "mutated": "b < '9'"
    },
    {
      "id": 5,
      "file": "<std>/json/reader.byn",
      "line": 366,
      "column": 35,
      "operator": "relational",
      "original": "b <= '9'",
      "mutated": "b > '9'"
    },
    {
      "id": 6,
      "file": "<std>/json/value.byn",
      "line": 51,
      "column": 17,
      "operator": "statement",
      "original": "items.append(try treeOf(ref reader, from: token))",
      "mutated": ""
    },
    {
      "id": 7,
      "file": "<std>/json/value.byn",
      "line": 61,
      "column": 25,
      "operator": "statement",
      "original": "members.append(JsonMember { key: name, value: try treeOf(ref reader, from: next) })",
      "mutated": ""
    },
    {
      "id": 8,
      "file": "<std>/json/value.byn",
      "line": 76,
      "column": 24,
      "operator": "statement",
      "original": "sb.append(\"null\")",
      "mutated": ""
    },
    {
      "id": 9,
      "file": "<std>/json/value.byn",
      "line": 77,
      "column": 32,
      "operator": "statement",
      "original": "sb.append(value ? \"true\" : \"false\")",
      "mutated": ""
    },
    {
      "id": 10,
      "file": "<std>/json/value.byn",
      "line": 79,
      "column": 32,
      "operator": "statement",
      "original": "quoteInto(ref sb, from: value)",
      "mutated": ""
    },
    {
      "id": 11,
      "file": "<std>/json/value.byn",
      "line": 81,
      "column": 36,
      "operator": "condition",
      "original": "level >= maxDepth",
      "mutated": "!(level >= maxDepth)"
    },
    {
      "id": 12,
      "file": "<std>/json/value.byn",
      "line": 81,
      "column": 36,
      "operator": "boundary",
      "original": "level >= maxDepth",
      "mutated": "level > maxDepth"
    },
    {
      "id": 13,
      "file": "<std>/json/value.byn",
      "line": 81,
      "column": 36,
      "operator": "relational",
      "original": "level >= maxDepth",
      "mutated": "level < maxDepth"
    },
    {
      "id": 14,
      "file": "<std>/json/value.byn",
      "line": 81,
      "column": 18,
      "operator": "variant",
      "original": ".nestedTooDeep",
      "mutated": ".nonFinite"
    },
    {
      "id": 15,
      "file": "<std>/json/value.byn",
      "line": 82,
      "column": 16,
      "operator": "condition",
      "original": "items.length == 0",
      "mutated": "!(items.length == 0)"
    },
    {
      "id": 16,
      "file": "<std>/json/value.byn",
      "line": 82,
      "column": 16,
      "operator": "relational",
      "original": "items.length == 0",
      "mutated": "items.length != 0"
    },
    {
      "id": 17,
      "file": "<std>/json/value.byn",
      "line": 82,
      "column": 32,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 18,
      "file": "<std>/json/value.byn",
      "line": 82,
      "column": 32,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 19,
      "file": "<std>/json/value.byn",
      "line": 83,
      "column": 17,
      "operator": "statement",
      "original": "sb.append(\"[]\")",
      "mutated": ""
    },
    {
      "id": 20,
      "file": "<std>/json/value.byn",
      "line": 86,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(\"[\")",
      "mutated": ""
    },
    {
      "id": 21,
      "file": "<std>/json/value.byn",
      "line": 87,
      "column": 22,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 22,
      "file": "<std>/json/value.byn",
      "line": 87,
      "column": 22,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 23,
      "file": "<std>/json/value.byn",
      "line": 88,
      "column": 17,
      "operator": "statement",
      "original": "separate(ref sb, by: indent, at: level + 1, first: i == 0)",
      "mutated": ""
    },
    {
      "id": 24,
      "file": "<std>/json/value.byn",
      "line": 88,
      "column": 50,
      "operator": "arithmetic",
      "original": "level + 1",
      "mutated": "level - 1"
    },
    {
      "id": 25,
      "file": "<std>/json/value.byn",
      "line": 88,
      "column": 58,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 26,
      "file": "<std>/json/value.byn",
      "line": 88,
      "column": 58,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 27,
      "file": "<std>/json/value.byn",
      "line": 88,
      "column": 68,
      "operator": "relational",
      "original": "i == 0",
      "mutated": "i != 0"
    },
    {
      "id": 28,
      "file": "<std>/json/value.byn",
      "line": 88,
      "column": 73,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 29,
      "file": "<std>/json/value.byn",
      "line": 88,
      "column": 73,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 30,
      "file": "<std>/json/value.byn",
      "line": 89,
      "column": 72,
      "operator": "arithmetic",
      "original": "level + 1",
      "mutated": "level - 1"
    },
    {
      "id": 31,
      "file": "<std>/json/value.byn",
      "line": 89,
      "column": 80,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 32,
      "file": "<std>/json/value.byn",
      "line": 89,
      "column": 80,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 33,
      "file": "<std>/json/value.byn",
      "line": 91,
      "column": 13,
      "operator": "statement",
      "original": "newline(ref sb, by: indent, at: level)",
      "mutated": ""
    },
    {
      "id": 34,
      "file": "<std>/json/value.byn",
      "line": 92,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(\"]\")",
      "mutated": ""
    },
    {
      "id": 35,
      "file": "<std>/json/value.byn",
      "line": 94,
      "column": 36,
      "operator": "condition",
      "original": "level >= maxDepth",
      "mutated": "!(level >= maxDepth)"
    },
    {
      "id": 36,
      "file": "<std>/json/value.byn",
      "line": 94,
      "column": 36,
      "operator": "boundary",
      "original": "level >= maxDepth",
      "mutated": "level > maxDepth"
    },
    {
      "id": 37,
      "file": "<std>/json/value.byn",
      "line": 94,
      "column": 36,
      "operator": "relational",
      "original": "level >= maxDepth",
      "mutated": "level < maxDepth"
    },
    {
      "id": 38,
      "file": "<std>/json/value.byn",
      "line": 94,
      "column": 18,
      "operator": "variant",
      "original": ".nestedTooDeep",
      "mutated": ".nonFinite"
    },
    {
      "id": 39,
      "file": "<std>/json/value.byn",
      "line": 95,
      "column": 16,
      "operator": "condition",
      "original": "members.length == 0",
      "mutated": "!(members.length == 0)"
    },
    {
      "id": 40,
      "file": "<std>/json/value.byn",
      "line": 95,
      "column": 16,
      "operator": "relational",
      "original": "members.length == 0",
      "mutated": "members.length != 0"
    },
    {
      "id": 41,
      "file": "<std>/json/value.byn",
      "line": 95,
      "column": 34,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 42,
      "file": "<std>/json/value.byn",
      "line": 95,
      "column": 34,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 43,
      "file": "<std>/json/value.byn",
      "line": 96,
      "column": 17,
      "operator": "statement",
      "original": "sb.append(\"{}\")",
      "mutated": ""
    },
    {
      "id": 44,
      "file": "<std>/json/value.byn",
      "line": 99,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(\"{\")",
      "mutated": ""
    },
    {
      "id": 45,
      "file": "<std>/json/value.byn",
      "line": 100,
      "column": 22,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 46,
      "file": "<std>/json/value.byn",
      "line": 100,
      "column": 22,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 47,
      "file": "<std>/json/value.byn",
      "line": 101,
      "column": 17,
      "operator": "statement",
      "original": "separate(ref sb, by: indent, at: level + 1, first: i == 0)",
      "mutated": ""
    },
    {
      "id": 48,
      "file": "<std>/json/value.byn",
      "line": 101,
      "column": 50,
      "operator": "arithmetic",
      "original": "level + 1",
      "mutated": "level - 1"
    },
    {
      "id": 49,
      "file": "<std>/json/value.byn",
      "line": 101,
      "column": 58,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 50,
      "file": "<std>/json/value.byn",
      "line": 101,
      "column": 58,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 51,
      "file": "<std>/json/value.byn",
      "line": 101,
      "column": 68,
      "operator": "relational",
      "original": "i == 0",
      "mutated": "i != 0"
    },
    {
      "id": 52,
      "file": "<std>/json/value.byn",
      "line": 101,
      "column": 73,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 53,
      "file": "<std>/json/value.byn",
      "line": 101,
      "column": 73,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 54,
      "file": "<std>/json/value.byn",
      "line": 102,
      "column": 17,
      "operator": "statement",
      "original": "quoteInto(ref sb, from: members[i].key)",
      "mutated": ""
    },
    {
      "id": 55,
      "file": "<std>/json/value.byn",
      "line": 103,
      "column": 17,
      "operator": "statement",
      "original": "sb.append(\": \")",
      "mutated": ""
    },
    {
      "id": 56,
      "file": "<std>/json/value.byn",
      "line": 104,
      "column": 80,
      "operator": "arithmetic",
      "original": "level + 1",
      "mutated": "level - 1"
    },
    {
      "id": 57,
      "file": "<std>/json/value.byn",
      "line": 104,
      "column": 88,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 58,
      "file": "<std>/json/value.byn",
      "line": 104,
      "column": 88,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 59,
      "file": "<std>/json/value.byn",
      "line": 106,
      "column": 13,
      "operator": "statement",
      "original": "newline(ref sb, by: indent, at: level)",
      "mutated": ""
    },
    {
      "id": 60,
      "file": "<std>/json/value.byn",
      "line": 107,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(\"}\")",
      "mutated": ""
    },
    {
      "id": 61,
      "file": "<std>/json/value.byn",
      "line": 114,
      "column": 8,
      "operator": "condition",
      "original": "isNumberText(text)",
      "mutated": "!(isNumberText(text))"
    },
    {
      "id": 62,
      "file": "<std>/json/value.byn",
      "line": 115,
      "column": 9,
      "operator": "statement",
      "original": "sb.append(text)",
      "mutated": ""
    },
    {
      "id": 63,
      "file": "<std>/json/value.byn",
      "line": 118,
      "column": 24,
      "operator": "condition",
      "original": "value - value != 0.0",
      "mutated": "!(value - value != 0.0)"
    },
    {
      "id": 64,
      "file": "<std>/json/value.byn",
      "line": 118,
      "column": 24,
      "operator": "relational",
      "original": "value - value != 0.0",
      "mutated": "value - value == 0.0"
    },
    {
      "id": 65,
      "file": "<std>/json/value.byn",
      "line": 118,
      "column": 24,
      "operator": "arithmetic",
      "original": "value - value",
      "mutated": "value + value"
    },
    {
      "id": 66,
      "file": "<std>/json/value.byn",
      "line": 118,
      "column": 10,
      "operator": "variant",
      "original": ".nonFinite",
      "mutated": ".nestedTooDeep"
    },
    {
      "id": 67,
      "file": "<std>/json/value.byn",
      "line": 119,
      "column": 5,
      "operator": "statement",
      "original": "sb.append($\"{value}\")",
      "mutated": ""
    },
    {
      "id": 68,
      "file": "<std>/json/value.byn",
      "line": 125,
      "column": 46,
      "operator": "bool",
      "original": "false",
      "mutated": "true"
    },
    {
      "id": 69,
      "file": "<std>/json/value.byn",
      "line": 126,
      "column": 12,
      "operator": "emptyReturn",
      "original": "token is .number(_, let digits) && digits.length == text.length",
      "mutated": "false"
    },
    {
      "id": 70,
      "file": "<std>/json/value.byn",
      "line": 126,
      "column": 47,
      "operator": "relational",
      "original": "digits.length == text.length",
      "mutated": "digits.length != text.length"
    },
    {
      "id": 71,
      "file": "<std>/json/value.byn",
      "line": 131,
      "column": 8,
      "operator": "condition",
      "original": "!first",
      "mutated": "!(!first)"
    },
    {
      "id": 72,
      "file": "<std>/json/value.byn",
      "line": 132,
      "column": 9,
      "operator": "statement",
      "original": "sb.append(indent > 0 ? \",\" : \", \")",
      "mutated": ""
    },
    {
      "id": 73,
      "file": "<std>/json/value.byn",
      "line": 132,
      "column": 19,
      "operator": "boundary",
      "original": "indent > 0",
      "mutated": "indent >= 0"
    },
    {
      "id": 74,
      "file": "<std>/json/value.byn",
      "line": 132,
      "column": 19,
      "operator": "relational",
      "original": "indent > 0",
      "mutated": "indent <= 0"
    },
    {
      "id": 75,
      "file": "<std>/json/value.byn",
      "line": 132,
      "column": 28,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 76,
      "file": "<std>/json/value.byn",
      "line": 132,
      "column": 28,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 77,
      "file": "<std>/json/value.byn",
      "line": 134,
      "column": 5,
      "operator": "statement",
      "original": "newline(ref sb, by: indent, at: level)",
      "mutated": ""
    },
    {
      "id": 78,
      "file": "<std>/json/value.byn",
      "line": 138,
      "column": 15,
      "operator": "condition",
      "original": "indent <= 0",
      "mutated": "!(indent <= 0)"
    },
    {
      "id": 79,
      "file": "<std>/json/value.byn",
      "line": 138,
      "column": 15,
      "operator": "boundary",
      "original": "indent <= 0",
      "mutated": "indent < 0"
    },
    {
      "id": 80,
      "file": "<std>/json/value.byn",
      "line": 138,
      "column": 15,
      "operator": "relational",
      "original": "indent <= 0",
      "mutated": "indent > 0"
    },
    {
      "id": 81,
      "file": "<std>/json/value.byn",
      "line": 138,
      "column": 25,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 82,
      "file": "<std>/json/value.byn",
      "line": 138,
      "column": 25,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 83,
      "file": "<std>/json/value.byn",
      "line": 139,
      "column": 5,
      "operator": "statement",
      "original": "sb.append(\"\\n\")",
      "mutated": ""
    },
    {
      "id": 84,
      "file": "<std>/json/value.byn",
      "line": 140,
      "column": 5,
      "operator": "statement",
      "original": "sb.appendRepeated(' ', by: indent * level)",
      "mutated": ""
    },
    {
      "id": 85,
      "file": "<std>/json/value.byn",
      "line": 140,
      "column": 32,
      "operator": "arithmetic",
      "original": "indent * level",
      "mutated": "indent / level"
    },
    {
      "id": 86,
      "file": "<std>/json/value.byn",
      "line": 146,
      "column": 5,
      "operator": "statement",
      "original": "sb.append(\"\\\"\")",
      "mutated": ""
    },
    {
      "id": 87,
      "file": "<std>/json/value.byn",
      "line": 149,
      "column": 12,
      "operator": "condition",
      "original": "r == '\"'",
      "mutated": "!(r == '\"')"
    },
    {
      "id": 88,
      "file": "<std>/json/value.byn",
      "line": 149,
      "column": 12,
      "operator": "relational",
      "original": "r == '\"'",
      "mutated": "r != '\"'"
    },
    {
      "id": 89,
      "file": "<std>/json/value.byn",
      "line": 150,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(\"\\\\\\\"\")",
      "mutated": ""
    },
    {
      "id": 90,
      "file": "<std>/json/value.byn",
      "line": 151,
      "column": 19,
      "operator": "condition",
      "original": "r == '\\\\'",
      "mutated": "!(r == '\\\\')"
    },
    {
      "id": 91,
      "file": "<std>/json/value.byn",
      "line": 151,
      "column": 19,
      "operator": "relational",
      "original": "r == '\\\\'",
      "mutated": "r != '\\\\'"
    },
    {
      "id": 92,
      "file": "<std>/json/value.byn",
      "line": 152,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(\"\\\\\\\\\")",
      "mutated": ""
    },
    {
      "id": 93,
      "file": "<std>/json/value.byn",
      "line": 153,
      "column": 19,
      "operator": "condition",
      "original": "r == '\\n'",
      "mutated": "!(r == '\\n')"
    },
    {
      "id": 94,
      "file": "<std>/json/value.byn",
      "line": 153,
      "column": 19,
      "operator": "relational",
      "original": "r == '\\n'",
      "mutated": "r != '\\n'"
    },
    {
      "id": 95,
      "file": "<std>/json/value.byn",
      "line": 154,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(\"\\\\n\")",
      "mutated": ""
    },
    {
      "id": 96,
      "file": "<std>/json/value.byn",
      "line": 155,
      "column": 19,
      "operator": "condition",
      "original": "r == '\\r'",
      "mutated": "!(r == '\\r')"
    },
    {
      "id": 97,
      "file": "<std>/json/value.byn",
      "line": 155,
      "column": 19,
      "operator": "relational",
      "original": "r == '\\r'",
      "mutated": "r != '\\r'"
    },
    {
      "id": 98,
      "file": "<std>/json/value.byn",
      "line": 156,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(\"\\\\r\")",
      "mutated": ""
    },
    {
      "id": 99,
      "file": "<std>/json/value.byn",
      "line": 157,
      "column": 19,
      "operator": "condition",
      "original": "r == '\\t'",
      "mutated": "!(r == '\\t')"
    },
    {
      "id": 100,
      "file": "<std>/json/value.byn",
      "line": 157,
      "column": 19,
      "operator": "relational",
      "original": "r == '\\t'",
      "mutated": "r != '\\t'"
    },
    {
      "id": 101,
      "file": "<std>/json/value.byn",
      "line": 158,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(\"\\\\t\")",
      "mutated": ""
    },
    {
      "id": 102,
      "file": "<std>/json/value.byn",
      "line": 159,
      "column": 19,
      "operator": "condition",
      "original": "cp == 0x8",
      "mutated": "!(cp == 0x8)"
    },
    {
      "id": 103,
      "file": "<std>/json/value.byn",
      "line": 159,
      "column": 19,
      "operator": "relational",
      "original": "cp == 0x8",
      "mutated": "cp != 0x8"
    },
    {
      "id": 104,
      "file": "<std>/json/value.byn",
      "line": 159,
      "column": 25,
      "operator": "literal",
      "original": "0x8",
      "mutated": "9"
    },
    {
      "id": 105,
      "file": "<std>/json/value.byn",
      "line": 159,
      "column": 25,
      "operator": "literal",
      "original": "0x8",
      "mutated": "7"
    },
    {
      "id": 106,
      "file": "<std>/json/value.byn",
      "line": 160,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(\"\\\\b\")",
      "mutated": ""
    },
    {
      "id": 107,
      "file": "<std>/json/value.byn",
      "line": 161,
      "column": 19,
      "operator": "condition",
      "original": "cp == 0xC",
      "mutated": "!(cp == 0xC)"
    },
    {
      "id": 108,
      "file": "<std>/json/value.byn",
      "line": 161,
      "column": 19,
      "operator": "relational",
      "original": "cp == 0xC",
      "mutated": "cp != 0xC"
    },
    {
      "id": 109,
      "file": "<std>/json/value.byn",
      "line": 161,
      "column": 25,
      "operator": "literal",
      "original": "0xC",
      "mutated": "13"
    },
    {
      "id": 110,
      "file": "<std>/json/value.byn",
      "line": 161,
      "column": 25,
      "operator": "literal",
      "original": "0xC",
      "mutated": "11"
    },
    {
      "id": 111,
      "file": "<std>/json/value.byn",
      "line": 162,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(\"\\\\f\")",
      "mutated": ""
    },
    {
      "id": 112,
      "file": "<std>/json/value.byn",
      "line": 164,
      "column": 13,
      "operator": "statement",
      "original": "sb.append($\"{r}\")",
      "mutated": ""
    },
    {
      "id": 113,
      "file": "<std>/json/value.byn",
      "line": 165,
      "column": 19,
      "operator": "condition",
      "original": "cp > 0xFFFF",
      "mutated": "!(cp > 0xFFFF)"
    },
    {
      "id": 114,
      "file": "<std>/json/value.byn",
      "line": 165,
      "column": 19,
      "operator": "boundary",
      "original": "cp > 0xFFFF",
      "mutated": "cp >= 0xFFFF"
    },
    {
      "id": 115,
      "file": "<std>/json/value.byn",
      "line": 165,
      "column": 19,
      "operator": "relational",
      "original": "cp > 0xFFFF",
      "mutated": "cp <= 0xFFFF"
    },
    {
      "id": 116,
      "file": "<std>/json/value.byn",
      "line": 165,
      "column": 24,
      "operator": "literal",
      "original": "0xFFFF",
      "mutated": "65536"
    },
    {
      "id": 117,
      "file": "<std>/json/value.byn",
      "line": 165,
      "column": 24,
      "operator": "literal",
      "original": "0xFFFF",
      "mutated": "65534"
    },
    {
      "id": 118,
      "file": "<std>/json/value.byn",
      "line": 166,
      "column": 21,
      "operator": "arithmetic",
      "original": "cp - 0x10000",
      "mutated": "cp + 0x10000"
    },
    {
      "id": 119,
      "file": "<std>/json/value.byn",
      "line": 166,
      "column": 26,
      "operator": "literal",
      "original": "0x10000",
      "mutated": "65537"
    },
    {
      "id": 120,
      "file": "<std>/json/value.byn",
      "line": 166,
      "column": 26,
      "operator": "literal",
      "original": "0x10000",
      "mutated": "65535"
    },
    {
      "id": 121,
      "file": "<std>/json/value.byn",
      "line": 167,
      "column": 13,
      "operator": "statement",
      "original": "unitInto(ref sb, from: 0xD800 + v / 0x400)",
      "mutated": ""
    },
    {
      "id": 122,
      "file": "<std>/json/value.byn",
      "line": 167,
      "column": 36,
      "operator": "arithmetic",
      "original": "0xD800 + v / 0x400",
      "mutated": "0xD800 - v / 0x400"
    },
    {
      "id": 123,
      "file": "<std>/json/value.byn",
      "line": 167,
      "column": 36,
      "operator": "literal",
      "original": "0xD800",
      "mutated": "55297"
    },
    {
      "id": 124,
      "file": "<std>/json/value.byn",
      "line": 167,
      "column": 36,
      "operator": "literal",
      "original": "0xD800",
      "mutated": "55295"
    },
    {
      "id": 125,
      "file": "<std>/json/value.byn",
      "line": 167,
      "column": 45,
      "operator": "arithmetic",
      "original": "v / 0x400",
      "mutated": "v * 0x400"
    },
    {
      "id": 126,
      "file": "<std>/json/value.byn",
      "line": 167,
      "column": 49,
      "operator": "literal",
      "original": "0x400",
      "mutated": "1025"
    },
    {
      "id": 127,
      "file": "<std>/json/value.byn",
      "line": 167,
      "column": 49,
      "operator": "literal",
      "original": "0x400",
      "mutated": "1023"
    },
    {
      "id": 128,
      "file": "<std>/json/value.byn",
      "line": 168,
      "column": 13,
      "operator": "statement",
      "original": "unitInto(ref sb, from: 0xDC00 + v % 0x400)",
      "mutated": ""
    },
    {
      "id": 129,
      "file": "<std>/json/value.byn",
      "line": 168,
      "column": 36,
      "operator": "arithmetic",
      "original": "0xDC00 + v % 0x400",
      "mutated": "0xDC00 - v % 0x400"
    },
    {
      "id": 130,
      "file": "<std>/json/value.byn",
      "line": 168,
      "column": 36,
      "operator": "literal",
      "original": "0xDC00",
      "mutated": "56321"
    },
    {
      "id": 131,
      "file": "<std>/json/value.byn",
      "line": 168,
      "column": 36,
      "operator": "literal",
      "original": "0xDC00",
      "mutated": "56319"
    },
    {
      "id": 132,
      "file": "<std>/json/value.byn",
      "line": 168,
      "column": 45,
      "operator": "arithmetic",
      "original": "v % 0x400",
      "mutated": "v * 0x400"
    },
    {
      "id": 133,
      "file": "<std>/json/value.byn",
      "line": 168,
      "column": 49,
      "operator": "literal",
      "original": "0x400",
      "mutated": "1025"
    },
    {
      "id": 134,
      "file": "<std>/json/value.byn",
      "line": 168,
      "column": 49,
      "operator": "literal",
      "original": "0x400",
      "mutated": "1023"
    },
    {
      "id": 135,
      "file": "<std>/json/value.byn",
      "line": 170,
      "column": 13,
      "operator": "statement",
      "original": "unitInto(ref sb, from: cp)",
      "mutated": ""
    },
    {
      "id": 136,
      "file": "<std>/json/value.byn",
      "line": 173,
      "column": 5,
      "operator": "statement",
      "original": "sb.append(\"\\\"\")",
      "mutated": ""
    },
    {
      "id": 137,
      "file": "<std>/json/value.byn",
      "line": 177,
      "column": 5,
      "operator": "statement",
      "original": "sb.append(\"\\\\u\")",
      "mutated": ""
    },
    {
      "id": 138,
      "file": "<std>/json/value.byn",
      "line": 179,
      "column": 5,
      "operator": "statement",
      "original": "sb.appendRepeated('0', by: 4 - digits.length)",
      "mutated": ""
    },
    {
      "id": 139,
      "file": "<std>/json/value.byn",
      "line": 179,
      "column": 32,
      "operator": "arithmetic",
      "original": "4 - digits.length",
      "mutated": "4 + digits.length"
    },
    {
      "id": 140,
      "file": "<std>/json/value.byn",
      "line": 179,
      "column": 32,
      "operator": "literal",
      "original": "4",
      "mutated": "5"
    },
    {
      "id": 141,
      "file": "<std>/json/value.byn",
      "line": 179,
      "column": 32,
      "operator": "literal",
      "original": "4",
      "mutated": "3"
    },
    {
      "id": 142,
      "file": "<std>/json/value.byn",
      "line": 180,
      "column": 5,
      "operator": "statement",
      "original": "sb.append(digits)",
      "mutated": ""
    },
    {
      "id": 143,
      "file": "<std>/json/reader.byn",
      "line": 64,
      "column": 9,
      "operator": "statement",
      "original": "skipSpace()",
      "mutated": ""
    },
    {
      "id": 144,
      "file": "<std>/json/reader.byn",
      "line": 71,
      "column": 18,
      "operator": "condition",
      "original": "pos < text.length",
      "mutated": "!(pos < text.length)"
    },
    {
      "id": 145,
      "file": "<std>/json/reader.byn",
      "line": 71,
      "column": 18,
      "operator": "boundary",
      "original": "pos < text.length",
      "mutated": "pos <= text.length"
    },
    {
      "id": 146,
      "file": "<std>/json/reader.byn",
      "line": 71,
      "column": 18,
      "operator": "relational",
      "original": "pos < text.length",
      "mutated": "pos >= text.length"
    },
    {
      "id": 147,
      "file": "<std>/json/reader.byn",
      "line": 79,
      "column": 14,
      "operator": "condition",
      "original": "pos >= text.length",
      "mutated": "!(pos >= text.length)"
    },
    {
      "id": 148,
      "file": "<std>/json/reader.byn",
      "line": 79,
      "column": 14,
      "operator": "boundary",
      "original": "pos >= text.length",
      "mutated": "pos > text.length"
    },
    {
      "id": 149,
      "file": "<std>/json/reader.byn",
      "line": 79,
      "column": 14,
      "operator": "relational",
      "original": "pos >= text.length",
      "mutated": "pos < text.length"
    },
    {
      "id": 150,
      "file": "<std>/json/reader.byn",
      "line": 81,
      "column": 43,
      "operator": "condition",
      "original": "peek() == ']'",
      "mutated": "!(peek() == ']')"
    },
    {
      "id": 151,
      "file": "<std>/json/reader.byn",
      "line": 81,
      "column": 43,
      "operator": "relational",
      "original": "peek() == ']'",
      "mutated": "peek() != ']'"
    },
    {
      "id": 152,
      "file": "<std>/json/reader.byn",
      "line": 81,
      "column": 20,
      "operator": "emptyReturn",
      "original": "close(as: .endList)",
      "mutated": "null"
    },
    {
      "id": 153,
      "file": "<std>/json/reader.byn",
      "line": 87,
      "column": 18,
      "operator": "condition",
      "original": "peek() != ','",
      "mutated": "!(peek() != ',')"
    },
    {
      "id": 154,
      "file": "<std>/json/reader.byn",
      "line": 87,
      "column": 18,
      "operator": "relational",
      "original": "peek() != ','",
      "mutated": "peek() == ','"
    },
    {
      "id": 155,
      "file": "<std>/json/reader.byn",
      "line": 88,
      "column": 13,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 156,
      "file": "<std>/json/reader.byn",
      "line": 88,
      "column": 13,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 157,
      "file": "<std>/json/reader.byn",
      "line": 88,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 158,
      "file": "<std>/json/reader.byn",
      "line": 88,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 159,
      "file": "<std>/json/reader.byn",
      "line": 89,
      "column": 13,
      "operator": "statement",
      "original": "skipSpace()",
      "mutated": ""
    },
    {
      "id": 160,
      "file": "<std>/json/reader.byn",
      "line": 90,
      "column": 13,
      "operator": "statement",
      "original": "state = .listValue",
      "mutated": ""
    },
    {
      "id": 161,
      "file": "<std>/json/reader.byn",
      "line": 92,
      "column": 45,
      "operator": "condition",
      "original": "peek() == '}'",
      "mutated": "!(peek() == '}')"
    },
    {
      "id": 162,
      "file": "<std>/json/reader.byn",
      "line": 92,
      "column": 45,
      "operator": "relational",
      "original": "peek() == '}'",
      "mutated": "peek() != '}'"
    },
    {
      "id": 163,
      "file": "<std>/json/reader.byn",
      "line": 92,
      "column": 20,
      "operator": "emptyReturn",
      "original": "close(as: .endObject)",
      "mutated": "null"
    },
    {
      "id": 164,
      "file": "<std>/json/reader.byn",
      "line": 98,
      "column": 18,
      "operator": "condition",
      "original": "peek() != ','",
      "mutated": "!(peek() != ',')"
    },
    {
      "id": 165,
      "file": "<std>/json/reader.byn",
      "line": 98,
      "column": 18,
      "operator": "relational",
      "original": "peek() != ','",
      "mutated": "peek() == ','"
    },
    {
      "id": 166,
      "file": "<std>/json/reader.byn",
      "line": 99,
      "column": 13,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 167,
      "file": "<std>/json/reader.byn",
      "line": 99,
      "column": 13,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 168,
      "file": "<std>/json/reader.byn",
      "line": 99,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 169,
      "file": "<std>/json/reader.byn",
      "line": 99,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 170,
      "file": "<std>/json/reader.byn",
      "line": 100,
      "column": 13,
      "operator": "statement",
      "original": "skipSpace()",
      "mutated": ""
    },
    {
      "id": 171,
      "file": "<std>/json/reader.byn",
      "line": 101,
      "column": 13,
      "operator": "statement",
      "original": "state = .objectKey",
      "mutated": ""
    },
    {
      "id": 172,
      "file": "<std>/json/reader.byn",
      "line": 103,
      "column": 102,
      "operator": "condition",
      "original": "peek() != ':'",
      "mutated": "!(peek() != ':')"
    },
    {
      "id": 173,
      "file": "<std>/json/reader.byn",
      "line": 103,
      "column": 102,
      "operator": "relational",
      "original": "peek() != ':'",
      "mutated": "peek() == ':'"
    },
    {
      "id": 174,
      "file": "<std>/json/reader.byn",
      "line": 104,
      "column": 13,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 175,
      "file": "<std>/json/reader.byn",
      "line": 104,
      "column": 13,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 176,
      "file": "<std>/json/reader.byn",
      "line": 104,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 177,
      "file": "<std>/json/reader.byn",
      "line": 104,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 178,
      "file": "<std>/json/reader.byn",
      "line": 105,
      "column": 13,
      "operator": "statement",
      "original": "skipSpace()",
      "mutated": ""
    },
    {
      "id": 179,
      "file": "<std>/json/reader.byn",
      "line": 106,
      "column": 13,
      "operator": "statement",
      "original": "state = .objectValue",
      "mutated": ""
    },
    {
      "id": 180,
      "file": "<std>/json/reader.byn",
      "line": 113,
      "column": 14,
      "operator": "condition",
      "original": "pos >= text.length",
      "mutated": "!(pos >= text.length)"
    },
    {
      "id": 181,
      "file": "<std>/json/reader.byn",
      "line": 113,
      "column": 14,
      "operator": "boundary",
      "original": "pos >= text.length",
      "mutated": "pos > text.length"
    },
    {
      "id": 182,
      "file": "<std>/json/reader.byn",
      "line": 113,
      "column": 14,
      "operator": "relational",
      "original": "pos >= text.length",
      "mutated": "pos < text.length"
    },
    {
      "id": 183,
      "file": "<std>/json/reader.byn",
      "line": 115,
      "column": 62,
      "operator": "relational",
      "original": "b == ']'",
      "mutated": "b != ']'"
    },
    {
      "id": 184,
      "file": "<std>/json/reader.byn",
      "line": 115,
      "column": 16,
      "operator": "emptyReturn",
      "original": "close(as: .endList)",
      "mutated": "null"
    },
    {
      "id": 185,
      "file": "<std>/json/reader.byn",
      "line": 116,
      "column": 66,
      "operator": "relational",
      "original": "b == '}'",
      "mutated": "b != '}'"
    },
    {
      "id": 186,
      "file": "<std>/json/reader.byn",
      "line": 116,
      "column": 16,
      "operator": "emptyReturn",
      "original": "close(as: .endObject)",
      "mutated": "null"
    },
    {
      "id": 187,
      "file": "<std>/json/reader.byn",
      "line": 118,
      "column": 111,
      "operator": "condition",
      "original": "b != '\"'",
      "mutated": "!(b != '\"')"
    },
    {
      "id": 188,
      "file": "<std>/json/reader.byn",
      "line": 118,
      "column": 111,
      "operator": "relational",
      "original": "b != '\"'",
      "mutated": "b == '\"'"
    },
    {
      "id": 189,
      "file": "<std>/json/reader.byn",
      "line": 120,
      "column": 13,
      "operator": "statement",
      "original": "state = .objectColon",
      "mutated": ""
    },
    {
      "id": 190,
      "file": "<std>/json/reader.byn",
      "line": 121,
      "column": 20,
      "operator": "emptyReturn",
      "original": ".key(name: name)",
      "mutated": "null"
    },
    {
      "id": 191,
      "file": "<std>/json/reader.byn",
      "line": 123,
      "column": 16,
      "operator": "emptyReturn",
      "original": "try readValue()",
      "mutated": "null"
    },
    {
      "id": 192,
      "file": "<std>/json/reader.byn",
      "line": 127,
      "column": 18,
      "operator": "boundary",
      "original": "pos < text.length",
      "mutated": "pos <= text.length"
    },
    {
      "id": 193,
      "file": "<std>/json/reader.byn",
      "line": 127,
      "column": 18,
      "operator": "relational",
      "original": "pos < text.length",
      "mutated": "pos >= text.length"
    },
    {
      "id": 194,
      "file": "<std>/json/reader.byn",
      "line": 127,
      "column": 56,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 195,
      "file": "<std>/json/reader.byn",
      "line": 130,
      "column": 15,
      "operator": "condition",
      "original": "pos < text.length",
      "mutated": "!(pos < text.length)"
    },
    {
      "id": 196,
      "file": "<std>/json/reader.byn",
      "line": 130,
      "column": 15,
      "operator": "boundary",
      "original": "pos < text.length",
      "mutated": "pos <= text.length"
    },
    {
      "id": 197,
      "file": "<std>/json/reader.byn",
      "line": 130,
      "column": 15,
      "operator": "relational",
      "original": "pos < text.length",
      "mutated": "pos >= text.length"
    },
    {
      "id": 198,
      "file": "<std>/json/reader.byn",
      "line": 132,
      "column": 16,
      "operator": "condition",
      "original": "b == '\\n'",
      "mutated": "!(b == '\\n')"
    },
    {
      "id": 199,
      "file": "<std>/json/reader.byn",
      "line": 132,
      "column": 16,
      "operator": "relational",
      "original": "b == '\\n'",
      "mutated": "b != '\\n'"
    },
    {
      "id": 200,
      "file": "<std>/json/reader.byn",
      "line": 133,
      "column": 17,
      "operator": "statement",
      "original": "line += 1",
      "mutated": ""
    },
    {
      "id": 201,
      "file": "<std>/json/reader.byn",
      "line": 133,
      "column": 17,
      "operator": "arithmetic",
      "original": "line += 1",
      "mutated": "line -= 1"
    },
    {
      "id": 202,
      "file": "<std>/json/reader.byn",
      "line": 133,
      "column": 25,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 203,
      "file": "<std>/json/reader.byn",
      "line": 133,
      "column": 25,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 204,
      "file": "<std>/json/reader.byn",
      "line": 134,
      "column": 17,
      "operator": "statement",
      "original": "lineStart = pos + 1",
      "mutated": ""
    },
    {
      "id": 205,
      "file": "<std>/json/reader.byn",
      "line": 134,
      "column": 29,
      "operator": "arithmetic",
      "original": "pos + 1",
      "mutated": "pos - 1"
    },
    {
      "id": 206,
      "file": "<std>/json/reader.byn",
      "line": 134,
      "column": 35,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 207,
      "file": "<std>/json/reader.byn",
      "line": 134,
      "column": 35,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 208,
      "file": "<std>/json/reader.byn",
      "line": 135,
      "column": 23,
      "operator": "condition",
      "original": "b != ' ' && b != '\\t' && b != '\\r'",
      "mutated": "!(b != ' ' && b != '\\t' && b != '\\r')"
    },
    {
      "id": 209,
      "file": "<std>/json/reader.byn",
      "line": 135,
      "column": 23,
      "operator": "logical",
      "original": "b != ' ' && b != '\\t' && b != '\\r'",
      "mutated": "b != ' ' && b != '\\t' || b != '\\r'"
    },
    {
      "id": 210,
      "file": "<std>/json/reader.byn",
      "line": 135,
      "column": 23,
      "operator": "logical",
      "original": "b != ' ' && b != '\\t'",
      "mutated": "b != ' ' || b != '\\t'"
    },
    {
      "id": 211,
      "file": "<std>/json/reader.byn",
      "line": 135,
      "column": 23,
      "operator": "relational",
      "original": "b != ' '",
      "mutated": "b == ' '"
    },
    {
      "id": 212,
      "file": "<std>/json/reader.byn",
      "line": 135,
      "column": 35,
      "operator": "relational",
      "original": "b != '\\t'",
      "mutated": "b == '\\t'"
    },
    {
      "id": 213,
      "file": "<std>/json/reader.byn",
      "line": 135,
      "column": 48,
      "operator": "relational",
      "original": "b != '\\r'",
      "mutated": "b == '\\r'"
    },
    {
      "id": 214,
      "file": "<std>/json/reader.byn",
      "line": 138,
      "column": 13,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 215,
      "file": "<std>/json/reader.byn",
      "line": 138,
      "column": 13,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 216,
      "file": "<std>/json/reader.byn",
      "line": 138,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 217,
      "file": "<std>/json/reader.byn",
      "line": 138,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 218,
      "file": "<std>/json/reader.byn",
      "line": 143,
      "column": 29,
      "operator": "arithmetic",
      "original": "text[lineStart..at].runeCount + 1",
      "mutated": "text[lineStart..at].runeCount - 1"
    },
    {
      "id": 219,
      "file": "<std>/json/reader.byn",
      "line": 143,
      "column": 61,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 220,
      "file": "<std>/json/reader.byn",
      "line": 143,
      "column": 61,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 221,
      "file": "<std>/json/reader.byn",
      "line": 147,
      "column": 12,
      "operator": "condition",
      "original": "open.length == 0",
      "mutated": "!(open.length == 0)"
    },
    {
      "id": 222,
      "file": "<std>/json/reader.byn",
      "line": 147,
      "column": 12,
      "operator": "relational",
      "original": "open.length == 0",
      "mutated": "open.length != 0"
    },
    {
      "id": 223,
      "file": "<std>/json/reader.byn",
      "line": 147,
      "column": 27,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 224,
      "file": "<std>/json/reader.byn",
      "line": 147,
      "column": 27,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 225,
      "file": "<std>/json/reader.byn",
      "line": 148,
      "column": 13,
      "operator": "statement",
      "original": "state = .done",
      "mutated": ""
    },
    {
      "id": 226,
      "file": "<std>/json/reader.byn",
      "line": 149,
      "column": 19,
      "operator": "condition",
      "original": "open[open.length - 1]",
      "mutated": "!(open[open.length - 1])"
    },
    {
      "id": 227,
      "file": "<std>/json/reader.byn",
      "line": 149,
      "column": 24,
      "operator": "arithmetic",
      "original": "open.length - 1",
      "mutated": "open.length + 1"
    },
    {
      "id": 228,
      "file": "<std>/json/reader.byn",
      "line": 149,
      "column": 38,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 229,
      "file": "<std>/json/reader.byn",
      "line": 149,
      "column": 38,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 230,
      "file": "<std>/json/reader.byn",
      "line": 150,
      "column": 13,
      "operator": "statement",
      "original": "state = .objectNext",
      "mutated": ""
    },
    {
      "id": 231,
      "file": "<std>/json/reader.byn",
      "line": 152,
      "column": 13,
      "operator": "statement",
      "original": "state = .listNext",
      "mutated": ""
    },
    {
      "id": 232,
      "file": "<std>/json/reader.byn",
      "line": 157,
      "column": 9,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 233,
      "file": "<std>/json/reader.byn",
      "line": 157,
      "column": 9,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 234,
      "file": "<std>/json/reader.byn",
      "line": 157,
      "column": 16,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 235,
      "file": "<std>/json/reader.byn",
      "line": 157,
      "column": 16,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 236,
      "file": "<std>/json/reader.byn",
      "line": 159,
      "column": 9,
      "operator": "statement",
      "original": "finishValue()",
      "mutated": ""
    },
    {
      "id": 237,
      "file": "<std>/json/reader.byn",
      "line": 164,
      "column": 74,
      "operator": "condition",
      "original": "open.length >= maxDepth",
      "mutated": "!(open.length >= maxDepth)"
    },
    {
      "id": 238,
      "file": "<std>/json/reader.byn",
      "line": 164,
      "column": 74,
      "operator": "boundary",
      "original": "open.length >= maxDepth",
      "mutated": "open.length > maxDepth"
    },
    {
      "id": 239,
      "file": "<std>/json/reader.byn",
      "line": 164,
      "column": 74,
      "operator": "relational",
      "original": "open.length >= maxDepth",
      "mutated": "open.length < maxDepth"
    },
    {
      "id": 240,
      "file": "<std>/json/reader.byn",
      "line": 165,
      "column": 9,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 241,
      "file": "<std>/json/reader.byn",
      "line": 165,
      "column": 9,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 242,
      "file": "<std>/json/reader.byn",
      "line": 165,
      "column": 16,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 243,
      "file": "<std>/json/reader.byn",
      "line": 165,
      "column": 16,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 244,
      "file": "<std>/json/reader.byn",
      "line": 166,
      "column": 9,
      "operator": "statement",
      "original": "open.append(object)",
      "mutated": ""
    },
    {
      "id": 245,
      "file": "<std>/json/reader.byn",
      "line": 167,
      "column": 9,
      "operator": "statement",
      "original": "state = object ? .objectFirst : .listFirst",
      "mutated": ""
    },
    {
      "id": 246,
      "file": "<std>/json/reader.byn",
      "line": 173,
      "column": 51,
      "operator": "condition",
      "original": "b == '{'",
      "mutated": "!(b == '{')"
    },
    {
      "id": 247,
      "file": "<std>/json/reader.byn",
      "line": 173,
      "column": 51,
      "operator": "relational",
      "original": "b == '{'",
      "mutated": "b != '{'"
    },
    {
      "id": 248,
      "file": "<std>/json/reader.byn",
      "line": 173,
      "column": 42,
      "operator": "bool",
      "original": "true",
      "mutated": "false"
    },
    {
      "id": 249,
      "file": "<std>/json/reader.byn",
      "line": 174,
      "column": 52,
      "operator": "condition",
      "original": "b == '['",
      "mutated": "!(b == '[')"
    },
    {
      "id": 250,
      "file": "<std>/json/reader.byn",
      "line": 174,
      "column": 52,
      "operator": "relational",
      "original": "b == '['",
      "mutated": "b != '['"
    },
    {
      "id": 251,
      "file": "<std>/json/reader.byn",
      "line": 174,
      "column": 42,
      "operator": "bool",
      "original": "false",
      "mutated": "true"
    },
    {
      "id": 252,
      "file": "<std>/json/reader.byn",
      "line": 175,
      "column": 12,
      "operator": "condition",
      "original": "b == '\"'",
      "mutated": "!(b == '\"')"
    },
    {
      "id": 253,
      "file": "<std>/json/reader.byn",
      "line": 175,
      "column": 12,
      "operator": "relational",
      "original": "b == '\"'",
      "mutated": "b != '\"'"
    },
    {
      "id": 254,
      "file": "<std>/json/reader.byn",
      "line": 177,
      "column": 13,
      "operator": "statement",
      "original": "finishValue()",
      "mutated": ""
    },
    {
      "id": 255,
      "file": "<std>/json/reader.byn",
      "line": 180,
      "column": 36,
      "operator": "condition",
      "original": "b == '-' || (b >= '0' && b <= '9')",
      "mutated": "!(b == '-' || (b >= '0' && b <= '9'))"
    },
    {
      "id": 256,
      "file": "<std>/json/reader.byn",
      "line": 180,
      "column": 36,
      "operator": "logical",
      "original": "b == '-' || (b >= '0' && b <= '9')",
      "mutated": "b == '-' && (b >= '0' && b <= '9')"
    },
    {
      "id": 257,
      "file": "<std>/json/reader.byn",
      "line": 180,
      "column": 36,
      "operator": "relational",
      "original": "b == '-'",
      "mutated": "b != '-'"
    },
    {
      "id": 258,
      "file": "<std>/json/reader.byn",
      "line": 180,
      "column": 49,
      "operator": "logical",
      "original": "b >= '0' && b <= '9'",
      "mutated": "b >= '0' || b <= '9'"
    },
    {
      "id": 259,
      "file": "<std>/json/reader.byn",
      "line": 180,
      "column": 49,
      "operator": "boundary",
      "original": "b >= '0'",
      "mutated": "b > '0'"
    },
    {
      "id": 260,
      "file": "<std>/json/reader.byn",
      "line": 180,
      "column": 49,
      "operator": "relational",
      "original": "b >= '0'",
      "mutated": "b < '0'"
    },
    {
      "id": 261,
      "file": "<std>/json/reader.byn",
      "line": 180,
      "column": 61,
      "operator": "boundary",
      "original": "b <= '9'",
      "mutated": "b < '9'"
    },
    {
      "id": 262,
      "file": "<std>/json/reader.byn",
      "line": 180,
      "column": 61,
      "operator": "relational",
      "original": "b <= '9'",
      "mutated": "b > '9'"
    },
    {
      "id": 263,
      "file": "<std>/json/reader.byn",
      "line": 181,
      "column": 12,
      "operator": "condition",
      "original": "literal(\"true\")",
      "mutated": "!(literal(\"true\"))"
    },
    {
      "id": 264,
      "file": "<std>/json/reader.byn",
      "line": 182,
      "column": 13,
      "operator": "statement",
      "original": "finishValue()",
      "mutated": ""
    },
    {
      "id": 265,
      "file": "<std>/json/reader.byn",
      "line": 183,
      "column": 33,
      "operator": "bool",
      "original": "true",
      "mutated": "false"
    },
    {
      "id": 266,
      "file": "<std>/json/reader.byn",
      "line": 185,
      "column": 12,
      "operator": "condition",
      "original": "literal(\"false\")",
      "mutated": "!(literal(\"false\"))"
    },
    {
      "id": 267,
      "file": "<std>/json/reader.byn",
      "line": 186,
      "column": 13,
      "operator": "statement",
      "original": "finishValue()",
      "mutated": ""
    },
    {
      "id": 268,
      "file": "<std>/json/reader.byn",
      "line": 187,
      "column": 33,
      "operator": "bool",
      "original": "false",
      "mutated": "true"
    },
    {
      "id": 269,
      "file": "<std>/json/reader.byn",
      "line": 189,
      "column": 12,
      "operator": "condition",
      "original": "literal(\"null\")",
      "mutated": "!(literal(\"null\"))"
    },
    {
      "id": 270,
      "file": "<std>/json/reader.byn",
      "line": 190,
      "column": 13,
      "operator": "statement",
      "original": "finishValue()",
      "mutated": ""
    },
    {
      "id": 271,
      "file": "<std>/json/reader.byn",
      "line": 198,
      "column": 25,
      "operator": "condition",
      "original": "!text[pos..].startsWith(word)",
      "mutated": "!(!text[pos..].startsWith(word))"
    },
    {
      "id": 272,
      "file": "<std>/json/reader.byn",
      "line": 198,
      "column": 16,
      "operator": "bool",
      "original": "false",
      "mutated": "true"
    },
    {
      "id": 273,
      "file": "<std>/json/reader.byn",
      "line": 199,
      "column": 9,
      "operator": "statement",
      "original": "pos += word.length",
      "mutated": ""
    },
    {
      "id": 274,
      "file": "<std>/json/reader.byn",
      "line": 199,
      "column": 9,
      "operator": "arithmetic",
      "original": "pos += word.length",
      "mutated": "pos -= word.length"
    },
    {
      "id": 275,
      "file": "<std>/json/reader.byn",
      "line": 200,
      "column": 16,
      "operator": "emptyReturn",
      "original": "true",
      "mutated": "false"
    },
    {
      "id": 276,
      "file": "<std>/json/reader.byn",
      "line": 200,
      "column": 16,
      "operator": "bool",
      "original": "true",
      "mutated": "false"
    },
    {
      "id": 277,
      "file": "<std>/json/reader.byn",
      "line": 206,
      "column": 12,
      "operator": "condition",
      "original": "peek() == '-'",
      "mutated": "!(peek() == '-')"
    },
    {
      "id": 278,
      "file": "<std>/json/reader.byn",
      "line": 206,
      "column": 12,
      "operator": "relational",
      "original": "peek() == '-'",
      "mutated": "peek() != '-'"
    },
    {
      "id": 279,
      "file": "<std>/json/reader.byn",
      "line": 207,
      "column": 13,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 280,
      "file": "<std>/json/reader.byn",
      "line": 207,
      "column": 13,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 281,
      "file": "<std>/json/reader.byn",
      "line": 207,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 282,
      "file": "<std>/json/reader.byn",
      "line": 207,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 283,
      "file": "<std>/json/reader.byn",
      "line": 209,
      "column": 12,
      "operator": "condition",
      "original": "peek() == '0'",
      "mutated": "!(peek() == '0')"
    },
    {
      "id": 284,
      "file": "<std>/json/reader.byn",
      "line": 209,
      "column": 12,
      "operator": "relational",
      "original": "peek() == '0'",
      "mutated": "peek() != '0'"
    },
    {
      "id": 285,
      "file": "<std>/json/reader.byn",
      "line": 210,
      "column": 13,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 286,
      "file": "<std>/json/reader.byn",
      "line": 210,
      "column": 13,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 287,
      "file": "<std>/json/reader.byn",
      "line": 210,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 288,
      "file": "<std>/json/reader.byn",
      "line": 210,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 289,
      "file": "<std>/json/reader.byn",
      "line": 216,
      "column": 18,
      "operator": "condition",
      "original": "isDigit(peek())",
      "mutated": "!(isDigit(peek()))"
    },
    {
      "id": 290,
      "file": "<std>/json/reader.byn",
      "line": 217,
      "column": 19,
      "operator": "condition",
      "original": "isDigit(peek())",
      "mutated": "!(isDigit(peek()))"
    },
    {
      "id": 291,
      "file": "<std>/json/reader.byn",
      "line": 218,
      "column": 19,
      "operator": "condition",
      "original": "isDigit(peek())",
      "mutated": "!(isDigit(peek()))"
    },
    {
      "id": 292,
      "file": "<std>/json/reader.byn",
      "line": 219,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 293,
      "file": "<std>/json/reader.byn",
      "line": 219,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 294,
      "file": "<std>/json/reader.byn",
      "line": 219,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 295,
      "file": "<std>/json/reader.byn",
      "line": 219,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 296,
      "file": "<std>/json/reader.byn",
      "line": 224,
      "column": 12,
      "operator": "condition",
      "original": "peek() == '.'",
      "mutated": "!(peek() == '.')"
    },
    {
      "id": 297,
      "file": "<std>/json/reader.byn",
      "line": 224,
      "column": 12,
      "operator": "relational",
      "original": "peek() == '.'",
      "mutated": "peek() != '.'"
    },
    {
      "id": 298,
      "file": "<std>/json/reader.byn",
      "line": 225,
      "column": 13,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 299,
      "file": "<std>/json/reader.byn",
      "line": 225,
      "column": 13,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 300,
      "file": "<std>/json/reader.byn",
      "line": 225,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 301,
      "file": "<std>/json/reader.byn",
      "line": 225,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 302,
      "file": "<std>/json/reader.byn",
      "line": 231,
      "column": 18,
      "operator": "condition",
      "original": "!isDigit(peek())",
      "mutated": "!(!isDigit(peek()))"
    },
    {
      "id": 303,
      "file": "<std>/json/reader.byn",
      "line": 232,
      "column": 19,
      "operator": "condition",
      "original": "isDigit(peek())",
      "mutated": "!(isDigit(peek()))"
    },
    {
      "id": 304,
      "file": "<std>/json/reader.byn",
      "line": 233,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 305,
      "file": "<std>/json/reader.byn",
      "line": 233,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 306,
      "file": "<std>/json/reader.byn",
      "line": 233,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 307,
      "file": "<std>/json/reader.byn",
      "line": 233,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 308,
      "file": "<std>/json/reader.byn",
      "line": 236,
      "column": 12,
      "operator": "condition",
      "original": "peek() == 'e' || peek() == 'E'",
      "mutated": "!(peek() == 'e' || peek() == 'E')"
    },
    {
      "id": 309,
      "file": "<std>/json/reader.byn",
      "line": 236,
      "column": 12,
      "operator": "logical",
      "original": "peek() == 'e' || peek() == 'E'",
      "mutated": "peek() == 'e' && peek() == 'E'"
    },
    {
      "id": 310,
      "file": "<std>/json/reader.byn",
      "line": 236,
      "column": 12,
      "operator": "relational",
      "original": "peek() == 'e'",
      "mutated": "peek() != 'e'"
    },
    {
      "id": 311,
      "file": "<std>/json/reader.byn",
      "line": 236,
      "column": 29,
      "operator": "relational",
      "original": "peek() == 'E'",
      "mutated": "peek() != 'E'"
    },
    {
      "id": 312,
      "file": "<std>/json/reader.byn",
      "line": 237,
      "column": 13,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 313,
      "file": "<std>/json/reader.byn",
      "line": 237,
      "column": 13,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 314,
      "file": "<std>/json/reader.byn",
      "line": 237,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 315,
      "file": "<std>/json/reader.byn",
      "line": 237,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 316,
      "file": "<std>/json/reader.byn",
      "line": 238,
      "column": 16,
      "operator": "condition",
      "original": "peek() == '+' || peek() == '-'",
      "mutated": "!(peek() == '+' || peek() == '-')"
    },
    {
      "id": 317,
      "file": "<std>/json/reader.byn",
      "line": 238,
      "column": 16,
      "operator": "logical",
      "original": "peek() == '+' || peek() == '-'",
      "mutated": "peek() == '+' && peek() == '-'"
    },
    {
      "id": 318,
      "file": "<std>/json/reader.byn",
      "line": 238,
      "column": 16,
      "operator": "relational",
      "original": "peek() == '+'",
      "mutated": "peek() != '+'"
    },
    {
      "id": 319,
      "file": "<std>/json/reader.byn",
      "line": 238,
      "column": 33,
      "operator": "relational",
      "original": "peek() == '-'",
      "mutated": "peek() != '-'"
    },
    {
      "id": 320,
      "file": "<std>/json/reader.byn",
      "line": 239,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 321,
      "file": "<std>/json/reader.byn",
      "line": 239,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 322,
      "file": "<std>/json/reader.byn",
      "line": 239,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 323,
      "file": "<std>/json/reader.byn",
      "line": 239,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 324,
      "file": "<std>/json/reader.byn",
      "line": 246,
      "column": 18,
      "operator": "condition",
      "original": "!isDigit(peek())",
      "mutated": "!(!isDigit(peek()))"
    },
    {
      "id": 325,
      "file": "<std>/json/reader.byn",
      "line": 247,
      "column": 19,
      "operator": "condition",
      "original": "isDigit(peek())",
      "mutated": "!(isDigit(peek()))"
    },
    {
      "id": 326,
      "file": "<std>/json/reader.byn",
      "line": 248,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 327,
      "file": "<std>/json/reader.byn",
      "line": 248,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 328,
      "file": "<std>/json/reader.byn",
      "line": 248,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 329,
      "file": "<std>/json/reader.byn",
      "line": 248,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 330,
      "file": "<std>/json/reader.byn",
      "line": 254,
      "column": 9,
      "operator": "statement",
      "original": "finishValue()",
      "mutated": ""
    },
    {
      "id": 331,
      "file": "<std>/json/reader.byn",
      "line": 261,
      "column": 9,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 332,
      "file": "<std>/json/reader.byn",
      "line": 261,
      "column": 9,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 333,
      "file": "<std>/json/reader.byn",
      "line": 261,
      "column": 16,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 334,
      "file": "<std>/json/reader.byn",
      "line": 261,
      "column": 16,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 335,
      "file": "<std>/json/reader.byn",
      "line": 263,
      "column": 23,
      "operator": "bool",
      "original": "false",
      "mutated": "true"
    },
    {
      "id": 336,
      "file": "<std>/json/reader.byn",
      "line": 271,
      "column": 18,
      "operator": "condition",
      "original": "pos >= text.length",
      "mutated": "!(pos >= text.length)"
    },
    {
      "id": 337,
      "file": "<std>/json/reader.byn",
      "line": 271,
      "column": 18,
      "operator": "boundary",
      "original": "pos >= text.length",
      "mutated": "pos > text.length"
    },
    {
      "id": 338,
      "file": "<std>/json/reader.byn",
      "line": 271,
      "column": 18,
      "operator": "relational",
      "original": "pos >= text.length",
      "mutated": "pos < text.length"
    },
    {
      "id": 339,
      "file": "<std>/json/reader.byn",
      "line": 273,
      "column": 16,
      "operator": "condition",
      "original": "b == '\"'",
      "mutated": "!(b == '\"')"
    },
    {
      "id": 340,
      "file": "<std>/json/reader.byn",
      "line": 273,
      "column": 16,
      "operator": "relational",
      "original": "b == '\"'",
      "mutated": "b != '\"'"
    },
    {
      "id": 341,
      "file": "<std>/json/reader.byn",
      "line": 274,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 342,
      "file": "<std>/json/reader.byn",
      "line": 274,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 343,
      "file": "<std>/json/reader.byn",
      "line": 274,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 344,
      "file": "<std>/json/reader.byn",
      "line": 274,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 345,
      "file": "<std>/json/reader.byn",
      "line": 275,
      "column": 46,
      "operator": "condition",
      "original": "!escaped",
      "mutated": "!(!escaped)"
    },
    {
      "id": 346,
      "file": "<std>/json/reader.byn",
      "line": 275,
      "column": 24,
      "operator": "emptyReturn",
      "original": "text[run..pos - 1]",
      "mutated": "\"\""
    },
    {
      "id": 347,
      "file": "<std>/json/reader.byn",
      "line": 275,
      "column": 34,
      "operator": "arithmetic",
      "original": "pos - 1",
      "mutated": "pos + 1"
    },
    {
      "id": 348,
      "file": "<std>/json/reader.byn",
      "line": 275,
      "column": 40,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 349,
      "file": "<std>/json/reader.byn",
      "line": 275,
      "column": 40,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 350,
      "file": "<std>/json/reader.byn",
      "line": 276,
      "column": 17,
      "operator": "statement",
      "original": "sb.append(text[run..pos - 1])",
      "mutated": ""
    },
    {
      "id": 351,
      "file": "<std>/json/reader.byn",
      "line": 276,
      "column": 37,
      "operator": "arithmetic",
      "original": "pos - 1",
      "mutated": "pos + 1"
    },
    {
      "id": 352,
      "file": "<std>/json/reader.byn",
      "line": 276,
      "column": 43,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 353,
      "file": "<std>/json/reader.byn",
      "line": 276,
      "column": 43,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 354,
      "file": "<std>/json/reader.byn",
      "line": 277,
      "column": 24,
      "operator": "emptyReturn",
      "original": "$\"{sb.finish()}\"",
      "mutated": "\"\""
    },
    {
      "id": 355,
      "file": "<std>/json/reader.byn",
      "line": 284,
      "column": 18,
      "operator": "condition",
      "original": "b < 0x20",
      "mutated": "!(b < 0x20)"
    },
    {
      "id": 356,
      "file": "<std>/json/reader.byn",
      "line": 284,
      "column": 18,
      "operator": "boundary",
      "original": "b < 0x20",
      "mutated": "b <= 0x20"
    },
    {
      "id": 357,
      "file": "<std>/json/reader.byn",
      "line": 284,
      "column": 18,
      "operator": "relational",
      "original": "b < 0x20",
      "mutated": "b >= 0x20"
    },
    {
      "id": 358,
      "file": "<std>/json/reader.byn",
      "line": 284,
      "column": 22,
      "operator": "literal",
      "original": "0x20",
      "mutated": "33"
    },
    {
      "id": 359,
      "file": "<std>/json/reader.byn",
      "line": 284,
      "column": 22,
      "operator": "literal",
      "original": "0x20",
      "mutated": "31"
    },
    {
      "id": 360,
      "file": "<std>/json/reader.byn",
      "line": 285,
      "column": 16,
      "operator": "condition",
      "original": "b != '\\\\'",
      "mutated": "!(b != '\\\\')"
    },
    {
      "id": 361,
      "file": "<std>/json/reader.byn",
      "line": 285,
      "column": 16,
      "operator": "relational",
      "original": "b != '\\\\'",
      "mutated": "b == '\\\\'"
    },
    {
      "id": 362,
      "file": "<std>/json/reader.byn",
      "line": 286,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 363,
      "file": "<std>/json/reader.byn",
      "line": 286,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 364,
      "file": "<std>/json/reader.byn",
      "line": 286,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 365,
      "file": "<std>/json/reader.byn",
      "line": 286,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 366,
      "file": "<std>/json/reader.byn",
      "line": 289,
      "column": 13,
      "operator": "statement",
      "original": "escaped = true",
      "mutated": ""
    },
    {
      "id": 367,
      "file": "<std>/json/reader.byn",
      "line": 289,
      "column": 23,
      "operator": "bool",
      "original": "true",
      "mutated": "false"
    },
    {
      "id": 368,
      "file": "<std>/json/reader.byn",
      "line": 290,
      "column": 13,
      "operator": "statement",
      "original": "sb.append(text[run..pos])",
      "mutated": ""
    },
    {
      "id": 369,
      "file": "<std>/json/reader.byn",
      "line": 292,
      "column": 13,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 370,
      "file": "<std>/json/reader.byn",
      "line": 292,
      "column": 13,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 371,
      "file": "<std>/json/reader.byn",
      "line": 292,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 372,
      "file": "<std>/json/reader.byn",
      "line": 292,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 373,
      "file": "<std>/json/reader.byn",
      "line": 294,
      "column": 16,
      "operator": "condition",
      "original": "e == '\"' || e == '\\\\' || e == '/'",
      "mutated": "!(e == '\"' || e == '\\\\' || e == '/')"
    },
    {
      "id": 374,
      "file": "<std>/json/reader.byn",
      "line": 294,
      "column": 16,
      "operator": "logical",
      "original": "e == '\"' || e == '\\\\' || e == '/'",
      "mutated": "e == '\"' || e == '\\\\' && e == '/'"
    },
    {
      "id": 375,
      "file": "<std>/json/reader.byn",
      "line": 294,
      "column": 16,
      "operator": "logical",
      "original": "e == '\"' || e == '\\\\'",
      "mutated": "e == '\"' && e == '\\\\'"
    },
    {
      "id": 376,
      "file": "<std>/json/reader.byn",
      "line": 294,
      "column": 16,
      "operator": "relational",
      "original": "e == '\"'",
      "mutated": "e != '\"'"
    },
    {
      "id": 377,
      "file": "<std>/json/reader.byn",
      "line": 294,
      "column": 28,
      "operator": "relational",
      "original": "e == '\\\\'",
      "mutated": "e != '\\\\'"
    },
    {
      "id": 378,
      "file": "<std>/json/reader.byn",
      "line": 294,
      "column": 41,
      "operator": "relational",
      "original": "e == '/'",
      "mutated": "e != '/'"
    },
    {
      "id": 379,
      "file": "<std>/json/reader.byn",
      "line": 295,
      "column": 17,
      "operator": "statement",
      "original": "sb.append(text[pos..pos + 1])",
      "mutated": ""
    },
    {
      "id": 380,
      "file": "<std>/json/reader.byn",
      "line": 295,
      "column": 37,
      "operator": "arithmetic",
      "original": "pos + 1",
      "mutated": "pos - 1"
    },
    {
      "id": 381,
      "file": "<std>/json/reader.byn",
      "line": 295,
      "column": 43,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 382,
      "file": "<std>/json/reader.byn",
      "line": 295,
      "column": 43,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 383,
      "file": "<std>/json/reader.byn",
      "line": 296,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 384,
      "file": "<std>/json/reader.byn",
      "line": 296,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 385,
      "file": "<std>/json/reader.byn",
      "line": 296,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 386,
      "file": "<std>/json/reader.byn",
      "line": 296,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 387,
      "file": "<std>/json/reader.byn",
      "line": 297,
      "column": 23,
      "operator": "condition",
      "original": "e == 'b'",
      "mutated": "!(e == 'b')"
    },
    {
      "id": 388,
      "file": "<std>/json/reader.byn",
      "line": 297,
      "column": 23,
      "operator": "relational",
      "original": "e == 'b'",
      "mutated": "e != 'b'"
    },
    {
      "id": 389,
      "file": "<std>/json/reader.byn",
      "line": 298,
      "column": 17,
      "operator": "statement",
      "original": "sb.append(\"\\u{8}\")",
      "mutated": ""
    },
    {
      "id": 390,
      "file": "<std>/json/reader.byn",
      "line": 299,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 391,
      "file": "<std>/json/reader.byn",
      "line": 299,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 392,
      "file": "<std>/json/reader.byn",
      "line": 299,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 393,
      "file": "<std>/json/reader.byn",
      "line": 299,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 394,
      "file": "<std>/json/reader.byn",
      "line": 300,
      "column": 23,
      "operator": "condition",
      "original": "e == 'f'",
      "mutated": "!(e == 'f')"
    },
    {
      "id": 395,
      "file": "<std>/json/reader.byn",
      "line": 300,
      "column": 23,
      "operator": "relational",
      "original": "e == 'f'",
      "mutated": "e != 'f'"
    },
    {
      "id": 396,
      "file": "<std>/json/reader.byn",
      "line": 301,
      "column": 17,
      "operator": "statement",
      "original": "sb.append(\"\\u{C}\")",
      "mutated": ""
    },
    {
      "id": 397,
      "file": "<std>/json/reader.byn",
      "line": 302,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 398,
      "file": "<std>/json/reader.byn",
      "line": 302,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 399,
      "file": "<std>/json/reader.byn",
      "line": 302,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 400,
      "file": "<std>/json/reader.byn",
      "line": 302,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 401,
      "file": "<std>/json/reader.byn",
      "line": 303,
      "column": 23,
      "operator": "condition",
      "original": "e == 'n'",
      "mutated": "!(e == 'n')"
    },
    {
      "id": 402,
      "file": "<std>/json/reader.byn",
      "line": 303,
      "column": 23,
      "operator": "relational",
      "original": "e == 'n'",
      "mutated": "e != 'n'"
    },
    {
      "id": 403,
      "file": "<std>/json/reader.byn",
      "line": 304,
      "column": 17,
      "operator": "statement",
      "original": "sb.append(\"\\n\")",
      "mutated": ""
    },
    {
      "id": 404,
      "file": "<std>/json/reader.byn",
      "line": 305,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 405,
      "file": "<std>/json/reader.byn",
      "line": 305,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 406,
      "file": "<std>/json/reader.byn",
      "line": 305,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 407,
      "file": "<std>/json/reader.byn",
      "line": 305,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 408,
      "file": "<std>/json/reader.byn",
      "line": 306,
      "column": 23,
      "operator": "condition",
      "original": "e == 'r'",
      "mutated": "!(e == 'r')"
    },
    {
      "id": 409,
      "file": "<std>/json/reader.byn",
      "line": 306,
      "column": 23,
      "operator": "relational",
      "original": "e == 'r'",
      "mutated": "e != 'r'"
    },
    {
      "id": 410,
      "file": "<std>/json/reader.byn",
      "line": 307,
      "column": 17,
      "operator": "statement",
      "original": "sb.append(\"\\r\")",
      "mutated": ""
    },
    {
      "id": 411,
      "file": "<std>/json/reader.byn",
      "line": 308,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 412,
      "file": "<std>/json/reader.byn",
      "line": 308,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 413,
      "file": "<std>/json/reader.byn",
      "line": 308,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 414,
      "file": "<std>/json/reader.byn",
      "line": 308,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 415,
      "file": "<std>/json/reader.byn",
      "line": 309,
      "column": 23,
      "operator": "condition",
      "original": "e == 't'",
      "mutated": "!(e == 't')"
    },
    {
      "id": 416,
      "file": "<std>/json/reader.byn",
      "line": 309,
      "column": 23,
      "operator": "relational",
      "original": "e == 't'",
      "mutated": "e != 't'"
    },
    {
      "id": 417,
      "file": "<std>/json/reader.byn",
      "line": 310,
      "column": 17,
      "operator": "statement",
      "original": "sb.append(\"\\t\")",
      "mutated": ""
    },
    {
      "id": 418,
      "file": "<std>/json/reader.byn",
      "line": 311,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 419,
      "file": "<std>/json/reader.byn",
      "line": 311,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 420,
      "file": "<std>/json/reader.byn",
      "line": 311,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 421,
      "file": "<std>/json/reader.byn",
      "line": 311,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 422,
      "file": "<std>/json/reader.byn",
      "line": 312,
      "column": 23,
      "operator": "condition",
      "original": "e == 'u'",
      "mutated": "!(e == 'u')"
    },
    {
      "id": 423,
      "file": "<std>/json/reader.byn",
      "line": 312,
      "column": 23,
      "operator": "relational",
      "original": "e == 'u'",
      "mutated": "e != 'u'"
    },
    {
      "id": 424,
      "file": "<std>/json/reader.byn",
      "line": 313,
      "column": 17,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 425,
      "file": "<std>/json/reader.byn",
      "line": 313,
      "column": 17,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 426,
      "file": "<std>/json/reader.byn",
      "line": 313,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 427,
      "file": "<std>/json/reader.byn",
      "line": 313,
      "column": 24,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 428,
      "file": "<std>/json/reader.byn",
      "line": 321,
      "column": 26,
      "operator": "condition",
      "original": "!text[pos..].startsWith(\"\\\\u\")",
      "mutated": "!(!text[pos..].startsWith(\"\\\\u\"))"
    },
    {
      "id": 429,
      "file": "<std>/json/reader.byn",
      "line": 323,
      "column": 21,
      "operator": "statement",
      "original": "pos += 2",
      "mutated": ""
    },
    {
      "id": 430,
      "file": "<std>/json/reader.byn",
      "line": 323,
      "column": 21,
      "operator": "arithmetic",
      "original": "pos += 2",
      "mutated": "pos -= 2"
    },
    {
      "id": 431,
      "file": "<std>/json/reader.byn",
      "line": 323,
      "column": 28,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 432,
      "file": "<std>/json/reader.byn",
      "line": 323,
      "column": 28,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 433,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 21,
      "operator": "statement",
      "original": "cp = 0x10000 + (cp - 0xD800) * 0x400 + (low - 0xDC00)",
      "mutated": ""
    },
    {
      "id": 434,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 26,
      "operator": "arithmetic",
      "original": "0x10000 + (cp - 0xD800) * 0x400 + (low - 0xDC00)",
      "mutated": "0x10000 + (cp - 0xD800) * 0x400 - (low - 0xDC00)"
    },
    {
      "id": 435,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 26,
      "operator": "arithmetic",
      "original": "0x10000 + (cp - 0xD800) * 0x400",
      "mutated": "0x10000 - (cp - 0xD800) * 0x400"
    },
    {
      "id": 436,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 26,
      "operator": "literal",
      "original": "0x10000",
      "mutated": "65537"
    },
    {
      "id": 437,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 26,
      "operator": "literal",
      "original": "0x10000",
      "mutated": "65535"
    },
    {
      "id": 438,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 36,
      "operator": "arithmetic",
      "original": "(cp - 0xD800) * 0x400",
      "mutated": "(cp - 0xD800) / 0x400"
    },
    {
      "id": 439,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 37,
      "operator": "arithmetic",
      "original": "cp - 0xD800",
      "mutated": "cp + 0xD800"
    },
    {
      "id": 440,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 42,
      "operator": "literal",
      "original": "0xD800",
      "mutated": "55297"
    },
    {
      "id": 441,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 42,
      "operator": "literal",
      "original": "0xD800",
      "mutated": "55295"
    },
    {
      "id": 442,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 52,
      "operator": "literal",
      "original": "0x400",
      "mutated": "1025"
    },
    {
      "id": 443,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 52,
      "operator": "literal",
      "original": "0x400",
      "mutated": "1023"
    },
    {
      "id": 444,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 61,
      "operator": "arithmetic",
      "original": "low - 0xDC00",
      "mutated": "low + 0xDC00"
    },
    {
      "id": 445,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 67,
      "operator": "literal",
      "original": "0xDC00",
      "mutated": "56321"
    },
    {
      "id": 446,
      "file": "<std>/json/reader.byn",
      "line": 332,
      "column": 67,
      "operator": "literal",
      "original": "0xDC00",
      "mutated": "56319"
    },
    {
      "id": 447,
      "file": "<std>/json/reader.byn",
      "line": 336,
      "column": 17,
      "operator": "statement",
      "original": "sb.append($\"{rune(cp)}\")",
      "mutated": ""
    },
    {
      "id": 448,
      "file": "<std>/json/reader.byn",
      "line": 340,
      "column": 13,
      "operator": "statement",
      "original": "run = pos",
      "mutated": ""
    },
    {
      "id": 449,
      "file": "<std>/json/reader.byn",
      "line": 346,
      "column": 26,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 450,
      "file": "<std>/json/reader.byn",
      "line": 347,
      "column": 18,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 451,
      "file": "<std>/json/reader.byn",
      "line": 347,
      "column": 18,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 452,
      "file": "<std>/json/reader.byn",
      "line": 347,
      "column": 21,
      "operator": "literal",
      "original": "4",
      "mutated": "5"
    },
    {
      "id": 453,
      "file": "<std>/json/reader.byn",
      "line": 347,
      "column": 21,
      "operator": "literal",
      "original": "4",
      "mutated": "3"
    },
    {
      "id": 454,
      "file": "<std>/json/reader.byn",
      "line": 349,
      "column": 26,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 455,
      "file": "<std>/json/reader.byn",
      "line": 350,
      "column": 16,
      "operator": "condition",
      "original": "b >= '0' && b <= '9'",
      "mutated": "!(b >= '0' && b <= '9')"
    },
    {
      "id": 456,
      "file": "<std>/json/reader.byn",
      "line": 350,
      "column": 16,
      "operator": "logical",
      "original": "b >= '0' && b <= '9'",
      "mutated": "b >= '0' || b <= '9'"
    },
    {
      "id": 457,
      "file": "<std>/json/reader.byn",
      "line": 350,
      "column": 16,
      "operator": "boundary",
      "original": "b >= '0'",
      "mutated": "b > '0'"
    },
    {
      "id": 458,
      "file": "<std>/json/reader.byn",
      "line": 350,
      "column": 16,
      "operator": "relational",
      "original": "b >= '0'",
      "mutated": "b < '0'"
    },
    {
      "id": 459,
      "file": "<std>/json/reader.byn",
      "line": 350,
      "column": 28,
      "operator": "boundary",
      "original": "b <= '9'",
      "mutated": "b < '9'"
    },
    {
      "id": 460,
      "file": "<std>/json/reader.byn",
      "line": 350,
      "column": 28,
      "operator": "relational",
      "original": "b <= '9'",
      "mutated": "b > '9'"
    },
    {
      "id": 461,
      "file": "<std>/json/reader.byn",
      "line": 351,
      "column": 17,
      "operator": "statement",
      "original": "d = u32(b - '0')",
      "mutated": ""
    },
    {
      "id": 462,
      "file": "<std>/json/reader.byn",
      "line": 351,
      "column": 25,
      "operator": "arithmetic",
      "original": "b - '0'",
      "mutated": "b + '0'"
    },
    {
      "id": 463,
      "file": "<std>/json/reader.byn",
      "line": 352,
      "column": 23,
      "operator": "condition",
      "original": "b >= 'a' && b <= 'f'",
      "mutated": "!(b >= 'a' && b <= 'f')"
    },
    {
      "id": 464,
      "file": "<std>/json/reader.byn",
      "line": 352,
      "column": 23,
      "operator": "logical",
      "original": "b >= 'a' && b <= 'f'",
      "mutated": "b >= 'a' || b <= 'f'"
    },
    {
      "id": 465,
      "file": "<std>/json/reader.byn",
      "line": 352,
      "column": 23,
      "operator": "boundary",
      "original": "b >= 'a'",
      "mutated": "b > 'a'"
    },
    {
      "id": 466,
      "file": "<std>/json/reader.byn",
      "line": 352,
      "column": 23,
      "operator": "relational",
      "original": "b >= 'a'",
      "mutated": "b < 'a'"
    },
    {
      "id": 467,
      "file": "<std>/json/reader.byn",
      "line": 352,
      "column": 35,
      "operator": "boundary",
      "original": "b <= 'f'",
      "mutated": "b < 'f'"
    },
    {
      "id": 468,
      "file": "<std>/json/reader.byn",
      "line": 352,
      "column": 35,
      "operator": "relational",
      "original": "b <= 'f'",
      "mutated": "b > 'f'"
    },
    {
      "id": 469,
      "file": "<std>/json/reader.byn",
      "line": 353,
      "column": 17,
      "operator": "statement",
      "original": "d = u32(b - 'a') + 10",
      "mutated": ""
    },
    {
      "id": 470,
      "file": "<std>/json/reader.byn",
      "line": 353,
      "column": 21,
      "operator": "arithmetic",
      "original": "u32(b - 'a') + 10",
      "mutated": "u32(b - 'a') - 10"
    },
    {
      "id": 471,
      "file": "<std>/json/reader.byn",
      "line": 353,
      "column": 25,
      "operator": "arithmetic",
      "original": "b - 'a'",
      "mutated": "b + 'a'"
    },
    {
      "id": 472,
      "file": "<std>/json/reader.byn",
      "line": 353,
      "column": 36,
      "operator": "literal",
      "original": "10",
      "mutated": "11"
    },
    {
      "id": 473,
      "file": "<std>/json/reader.byn",
      "line": 353,
      "column": 36,
      "operator": "literal",
      "original": "10",
      "mutated": "9"
    },
    {
      "id": 474,
      "file": "<std>/json/reader.byn",
      "line": 354,
      "column": 23,
      "operator": "condition",
      "original": "b >= 'A' && b <= 'F'",
      "mutated": "!(b >= 'A' && b <= 'F')"
    },
    {
      "id": 475,
      "file": "<std>/json/reader.byn",
      "line": 354,
      "column": 23,
      "operator": "logical",
      "original": "b >= 'A' && b <= 'F'",
      "mutated": "b >= 'A' || b <= 'F'"
    },
    {
      "id": 476,
      "file": "<std>/json/reader.byn",
      "line": 354,
      "column": 23,
      "operator": "boundary",
      "original": "b >= 'A'",
      "mutated": "b > 'A'"
    },
    {
      "id": 477,
      "file": "<std>/json/reader.byn",
      "line": 354,
      "column": 23,
      "operator": "relational",
      "original": "b >= 'A'",
      "mutated": "b < 'A'"
    },
    {
      "id": 478,
      "file": "<std>/json/reader.byn",
      "line": 354,
      "column": 35,
      "operator": "boundary",
      "original": "b <= 'F'",
      "mutated": "b < 'F'"
    },
    {
      "id": 479,
      "file": "<std>/json/reader.byn",
      "line": 354,
      "column": 35,
      "operator": "relational",
      "original": "b <= 'F'",
      "mutated": "b > 'F'"
    },
    {
      "id": 480,
      "file": "<std>/json/reader.byn",
      "line": 355,
      "column": 17,
      "operator": "statement",
      "original": "d = u32(b - 'A') + 10",
      "mutated": ""
    },
    {
      "id": 481,
      "file": "<std>/json/reader.byn",
      "line": 355,
      "column": 21,
      "operator": "arithmetic",
      "original": "u32(b - 'A') + 10",
      "mutated": "u32(b - 'A') - 10"
    },
    {
      "id": 482,
      "file": "<std>/json/reader.byn",
      "line": 355,
      "column": 25,
      "operator": "arithmetic",
      "original": "b - 'A'",
      "mutated": "b + 'A'"
    },
    {
      "id": 483,
      "file": "<std>/json/reader.byn",
      "line": 355,
      "column": 36,
      "operator": "literal",
      "original": "10",
      "mutated": "11"
    },
    {
      "id": 484,
      "file": "<std>/json/reader.byn",
      "line": 355,
      "column": 36,
      "operator": "literal",
      "original": "10",
      "mutated": "9"
    },
    {
      "id": 485,
      "file": "<std>/json/reader.byn",
      "line": 359,
      "column": 13,
      "operator": "statement",
      "original": "value = value * 16 + d",
      "mutated": ""
    },
    {
      "id": 486,
      "file": "<std>/json/reader.byn",
      "line": 359,
      "column": 21,
      "operator": "arithmetic",
      "original": "value * 16 + d",
      "mutated": "value * 16 - d"
    },
    {
      "id": 487,
      "file": "<std>/json/reader.byn",
      "line": 359,
      "column": 21,
      "operator": "arithmetic",
      "original": "value * 16",
      "mutated": "value / 16"
    },
    {
      "id": 488,
      "file": "<std>/json/reader.byn",
      "line": 359,
      "column": 29,
      "operator": "literal",
      "original": "16",
      "mutated": "17"
    },
    {
      "id": 489,
      "file": "<std>/json/reader.byn",
      "line": 359,
      "column": 29,
      "operator": "literal",
      "original": "16",
      "mutated": "15"
    },
    {
      "id": 490,
      "file": "<std>/json/reader.byn",
      "line": 360,
      "column": 13,
      "operator": "statement",
      "original": "pos += 1",
      "mutated": ""
    },
    {
      "id": 491,
      "file": "<std>/json/reader.byn",
      "line": 360,
      "column": 13,
      "operator": "arithmetic",
      "original": "pos += 1",
      "mutated": "pos -= 1"
    },
    {
      "id": 492,
      "file": "<std>/json/reader.byn",
      "line": 360,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "2"
    },
    {
      "id": 493,
      "file": "<std>/json/reader.byn",
      "line": 360,
      "column": 20,
      "operator": "literal",
      "original": "1",
      "mutated": "0"
    },
    {
      "id": 494,
      "file": "<std>/json/reader.byn",
      "line": 362,
      "column": 16,
      "operator": "emptyReturn",
      "original": "value",
      "mutated": "0"
    },
    {
      "id": 495,
      "file": "<std>/json/value.byn",
      "line": 38,
      "column": 62,
      "operator": "literal",
      "original": "0",
      "mutated": "1"
    },
    {
      "id": 496,
      "file": "<std>/json/value.byn",
      "line": 38,
      "column": 62,
      "operator": "literal",
      "original": "0",
      "mutated": "-1"
    },
    {
      "id": 497,
      "file": "<std>/json/value.byn",
      "line": 39,
      "column": 16,
      "operator": "emptyReturn",
      "original": "$\"{sb.finish()}\"",
      "mutated": "\"\""
    },
    {
      "id": 498,
      "file": "std-json.byn",
      "line": 7,
      "column": 13,
      "operator": "statement",
      "original": "print($\"syntax: {e.message} at {e.line}:{e.column}\")",
      "mutated": ""
    },
    {
      "id": 499,
      "file": "std-json.byn",
      "line": 11,
      "column": 13,
      "operator": "statement",
      "original": "print($\"too deep at {e.offset}\")",
      "mutated": ""
    },
    {
      "id": 500,
      "file": "std-json.byn",
      "line": 19,
      "column": 16,
      "operator": "logical",
      "original": "m.key == \"name\" && m.value is .text(let name)",
      "mutated": "m.key == \"name\" || m.value is .text(let name)"
    },
    {
      "id": 501,
      "file": "std-json.byn",
      "line": 19,
      "column": 16,
      "operator": "relational",
      "original": "m.key == \"name\"",
      "mutated": "m.key != \"name\""
    },
    {
      "id": 502,
      "file": "std-json.byn",
      "line": 19,
      "column": 64,
      "operator": "statement",
      "original": "print($\"name: {name}\")",
      "mutated": ""
    },
    {
      "id": 503,
      "file": "std-json.byn",
      "line": 22,
      "column": 5,
      "operator": "statement",
      "original": "print(json.Json.encode(v) catch \"not encodable\")",
      "mutated": ""
    },
    {
      "id": 504,
      "file": "std-json.byn",
      "line": 23,
      "column": 5,
      "operator": "statement",
      "original": "print(json.Json.encode(v, indent: 2) catch \"not encodable\")",
      "mutated": ""
    },
    {
      "id": 505,
      "file": "std-json.byn",
      "line": 23,
      "column": 39,
      "operator": "literal",
      "original": "2",
      "mutated": "3"
    },
    {
      "id": 506,
      "file": "std-json.byn",
      "line": 23,
      "column": 39,
      "operator": "literal",
      "original": "2",
      "mutated": "1"
    },
    {
      "id": 507,
      "file": "std-json.byn",
      "line": 27,
      "column": 5,
      "operator": "statement",
      "original": "show(\"\"\"{\"name\": \"Bayān\", \"tags\": [\"a\", \"b\"], \"size\": 1.5, \"ok\": true, \"none\": null, \"empty\": {}}\"\"\")",
      "mutated": ""
    },
    {
      "id": 508,
      "file": "std-json.byn",
      "line": 28,
      "column": 5,
      "operator": "statement",
      "original": "show(\"[1, 2\")",
      "mutated": ""
    },
    {
      "id": 509,
      "file": "std-json.byn",
      "line": 29,
      "column": 5,
      "operator": "statement",
      "original": "show(\"[\".repeated(200))",
      "mutated": ""
    },
    {
      "id": 510,
      "file": "std-json.byn",
      "line": 29,
      "column": 23,
      "operator": "literal",
      "original": "200",
      "mutated": "201"
    },
    {
      "id": 511,
      "file": "std-json.byn",
      "line": 29,
      "column": 23,
      "operator": "literal",
      "original": "200",
      "mutated": "199"
    }
  ]
}
