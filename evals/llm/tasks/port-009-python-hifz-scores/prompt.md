Port this Python program to Bayān. For the same standard input, the port prints the same standard output, byte for byte.

```python
import sys

best = {}
for line in sys.stdin:
    parts = line.split()
    if not parts:
        continue
    name = parts[0]
    score = int(parts[1]) if len(parts) > 1 else None
    if name not in best or best[name] is None:
        best[name] = score
    elif score is not None and score > best[name]:
        best[name] = score
for name, score in best.items():
    print(f"{name}: {score}")
scores = [score for score in best.values() if score is not None]
top = max(scores, default=None)
print(f"top: {top}")
print(f"absent: {list(best.values()).count(None)}")
```

Aisha keeps the scores of the students of the masjid's hifz class, one recitation test per line. A line is blank, or a name alone (the student was called but did not recite), or a name and a score separated by spaces. Names are ASCII with no spaces inside. A score is a whole number from 0 to 100 with no leading zeros. A line may have extra spaces around and between its fields. The same name may appear on many lines, with and without a score. You do not need to handle any other input.
