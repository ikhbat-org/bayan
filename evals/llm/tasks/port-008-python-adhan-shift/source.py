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
