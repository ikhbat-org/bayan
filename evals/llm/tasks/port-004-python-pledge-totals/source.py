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
