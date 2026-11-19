Port this Python program to Bayān. For the same standard input, the port prints the same standard output, byte for byte.

```python
import sys

DAY = 24 * 60
moved = 0
for line in sys.stdin:
    parts = line.split()
    if len(parts) != 3:
        continue
    prayer, clock, shift = parts[0], parts[1], int(parts[2])
    hours, minutes = clock.split(":")
    total = int(hours) * 60 + int(minutes) + shift
    days, rest = divmod(total, DAY)
    print(f"{prayer} {clock} -> {rest // 60:02d}:{rest % 60:02d} day {days}")
    moved += shift
weeks = moved // (7 * DAY)
print(f"moved {moved} minutes, {weeks} weeks and {moved % (7 * DAY)} minutes")
```

Bilal moves the adhan times of the masjid clock. The input is lines of text. A line with three fields, separated by spaces, is a prayer name (ASCII, no spaces inside), a time written `HH:MM` on the 24-hour clock (two digits each, the hour 00 to 23 and the minute 00 to 59) and a shift in minutes: a whole number with no leading zeros and at most five digits, which may have a `-` in front and never has a `+`. A line may have extra spaces around and between its fields. Any line that does not have three fields is skipped: it may be blank or hold one or two words. You do not need to handle any other input.
