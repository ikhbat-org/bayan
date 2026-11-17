Port this Python program to Bayān. For the same standard input, the port prints the same standard output, byte for byte.

```python
import sys


class FundError(Exception):
    pass


class Fund:
    def __init__(self, name, balance):
        self.name = name
        self.balance = balance

    def take(self, amount):
        if amount > self.balance:
            raise FundError(f"not enough in {self.name}")
        self.balance -= amount


funds = {}


def number(text):
    if not text.isdigit() or int(text) == 0:
        raise FundError("bad amount")
    return int(text)


def find(name):
    if name not in funds:
        raise FundError(f"no fund {name}")
    return funds[name]


def run(words):
    cmd, args = words[0], words[1:]
    if cmd == "open" and len(args) == 2:
        name, amount = args[0], number(args[1])
        if name in funds:
            raise FundError(f"{name} already open")
        funds[name] = Fund(name, amount)
    elif cmd == "give" and len(args) == 2:
        find(args[0]).balance += number(args[1])
    elif cmd == "take" and len(args) == 2:
        find(args[0]).take(number(args[1]))
    elif cmd == "move" and len(args) == 3:
        source = find(args[0])
        target = find(args[1])
        amount = number(args[2])
        source.take(amount)
        target.balance += amount
    elif cmd == "show" and not args:
        for fund in funds.values():
            print(f"{fund.name}: {fund.balance}")
        print(f"total: {sum(f.balance for f in funds.values())}")
    else:
        raise FundError("bad command")


for line in sys.stdin:
    words = line.split()
    if not words:
        continue
    try:
        run(words)
    except FundError as error:
        print(f"error: {error}")
```

The input is lines of text. A blank line is skipped. Any other line is split into words at spaces, and extra spaces are ignored. A fund name is ASCII with no spaces inside. An amount is meant to be a whole number of at most nine digits, with no leading zeros and no sign, but a line may hold any other text in its place. Lines may have any other shape too: a command the program does not know, or the wrong number of words. You do not need to handle any other input.
