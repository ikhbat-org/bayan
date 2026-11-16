import sys

rows = [line.split() for line in sys.stdin if line.strip()]
width = max(len(name) for name, _ in rows)
total = 0
for name, dishes in rows:
    total += int(dishes)
    print(f"{name.ljust(width)} {int(dishes):>3}")
print(f"{'total'.ljust(width)} {total:>3}")
