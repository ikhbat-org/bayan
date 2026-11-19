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
