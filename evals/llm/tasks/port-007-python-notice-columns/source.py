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
