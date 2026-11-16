Port this Python program to Bayān. For the same standard input, the port prints the same standard output, byte for byte.

```python
import sys

rows = [line.split() for line in sys.stdin if line.strip()]
width = max(len(name) for name, _ in rows)
total = 0
for name, dishes in rows:
    total += int(dishes)
    print(f"{name.ljust(width)} {int(dishes):>3}")
print(f"{'total'.ljust(width)} {total:>3}")
```

The input is lines of a name and a whole number of 0 or more, separated by spaces. Names are ASCII with no spaces inside. Lines may have extra spaces, and blank lines may appear. There is at least one non-blank line. You do not need to handle any other input.
