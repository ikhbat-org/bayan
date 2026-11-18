Port this Python program to Bayān. For the same standard input, the port prints the same standard output, byte for byte.

```python
import sys

totals = {}
for line in sys.stdin:
    parts = line.split()
    if not parts:
        continue
    if len(parts) != 2 or not parts[1].isdigit():
        print(f"ignored: {line.strip()}")
        continue
    name, amount = parts[0], int(parts[1])
    totals[name] = totals.get(name, 0) + amount
for name, amount in totals.items():
    print(f"{name:<8}{amount:>6}")
if totals:
    best = max(totals, key=totals.get)
    print(f"leader: {best}")
```

The input is lines of text. A good line is a name and a whole number of 0 or more, with no leading zeros and at most nine digits, separated by spaces, and it may have extra spaces around and between the fields. Names are ASCII, have no spaces inside and are at most 7 characters. A line may be blank. A line that is not blank and not good may have any other shape: a different number of fields, or a second field with a letter or a sign in it. You do not need to handle any other input.
