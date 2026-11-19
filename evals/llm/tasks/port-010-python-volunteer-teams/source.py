import sys


class Team:
    def __init__(self, duty):
        self.duty = duty
        self.members = []


teams = {}
helpers = {}

for line in sys.stdin:
    words = line.split()
    if not words:
        continue
    cmd, args = words[0], words[1:]
    if cmd == "team" and len(args) == 2:
        teams[args[0]] = Team(args[1])
    elif cmd == "join" and len(args) == 2 and args[1] in teams:
        team = teams[args[1]]
        team.members.append(args[0])
        helpers[args[0]] = team
    elif cmd == "alias" and len(args) == 2 and args[0] in teams:
        teams[args[1]] = teams[args[0]]
    elif cmd == "duty" and len(args) == 2 and args[0] in helpers:
        helpers[args[0]].duty = args[1]
    elif cmd == "show" and not args:
        for name, team in teams.items():
            print(f"{name}: {team.duty} [{', '.join(team.members)}]")
    else:
        print(f"skipped: {' '.join(words)}")
