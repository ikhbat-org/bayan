Port this Python program to Bayān. For the same standard input, the port prints the same standard output, byte for byte.

```python
import sys

for line in sys.stdin:
    line = line.rstrip("\n")
    if not line:
        continue
    at = line.find(":")
    if at < 0:
        print(f"no colon in {len(line)} letters")
        continue
    print(f"{line[:at]} | colon at {at} | {len(line) - at - 1} after")
```

The input is the notice board of the masjid, one notice per line, usually a name, a colon and a message. The text is UTF-8 and may be in any script, Arabic and accented Latin letters included. A line may be empty, may have no colon or more than one, may start with the colon or end with it, and may have spaces anywhere. Every input line ends with a newline, and no line holds a carriage return. You do not need to handle any other input.
