#!/bin/bash
# t10-remote.sh on a fixture repo under tmp/, with a fake ssh and scp on PATH that record their arguments (never ghosthive or wp1):
# --dry-run prints both legs' commands and calls neither; the vm leg passes on the compare's exit code (0 and 1), stops the unit
# when ghosthive's memory runs low or the hour is up, and stops the VM only when it started it; the wp1 leg passes on its code too
# and fetches tmp/t10/.
set -e
root="$(cd "$(dirname "$0")/../.." && pwd)"
t="$root/tmp/t10-remote-test"; S="$root/scripts/selfhost/t10-remote.sh"
rm -rf "$t" && mkdir -p "$t/bin" "$t/aux/t10" "$t/repo" && cd "$t/repo"
fail=0; ok() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: expected [$3] got [$2]"; fail=1; fi; }
git init -q -b base . && git config user.email t@t && git config user.name t
printf 'tmp/\n' > .gitignore; git add -A && git commit -qm "test: base"
s8=$(git rev-parse HEAD | cut -c1-8); A=$t/aux; export A
printf '{}\n' > "$A/t10/results.json"

# the fake ssh: ghosthive's VM state from $A/vm, MemAvailable from $A/mem, the rc file from $A/rc (empty: still running);
# wp1's run prints a log and exits $A/rc
cat > "$t/bin/ssh" <<'X'
#!/bin/bash
echo "ssh $*" >> "$A/calls"
rc=$(cat "$A/rc")
case "$*" in
  *"incus list"*) cat "$A/vm";;
  *MemAvailable*) st=active; [ -z "$rc" ] || st=inactive; printf 'MemAvailable: %s kB\n---\n%s\n---\n%s\n' "$(cat "$A/mem")" "$rc" "$st";;
  *"out/log"*|*t10-compare.sh*) echo "t10: runner exit 0"; [ "$rc" = 0 ] && echo "t10: AGREE on Fake" || echo "t10: DISAGREE on Fake (files under x)";
    case "$*" in *t10-compare.sh*) exit "$rc";; esac;;
  *"tar -C"*) COPYFILE_DISABLE=1 tar -C "$A/t10" -cf - .;;
esac
exit 0
X
cat > "$t/bin/scp" <<'X'
#!/bin/bash
echo "scp $*" >> "$A/calls"
[ "$1" != -r ] || { mkdir -p "${!#}"; cp "$A/t10/results.json" "${!#}/"; }
exit 0
X
chmod +x "$t/bin/ssh" "$t/bin/scp"
r() { : > "$A/calls"; set +e; out=$(T10R_POLL_S=${POLL-0} PATH="$t/bin:$PATH" /bin/bash "$S" run "$@" 2>&1); rc=$?; set -e; }
called() { grep -cF -- "$1" "$A/calls" || true; }

# dry run: nothing called, the command lines printed
echo RUNNING > "$A/vm"; echo 0 > "$A/rc"; echo 20000000 > "$A/mem"
POLL=30 r --host vm --dry-run
ok "vm dry run: exit 0, no ssh" "$rc $(wc -l < "$A/calls" | tr -d ' ')" "0 0"
ok "vm dry run: no bundle made" "$([ -e "tmp/t10-remote/$s8/vm.bundle" ] && echo made || echo none)" "none"
ok "vm dry run: bundle push" "$(echo "$out" | grep -cxF "ssh ghosthive \"timeout 600 incus exec bayan-test01 -- bash -c 'mkdir -p /root/t10-scratch && cat > /root/t10-scratch/$s8.bundle'\" < tmp/t10-remote/$s8/vm.bundle")" "1"
ok "vm dry run: clone as bt" "$(echo "$out" | grep -cxF "  runuser -u bt -- bash -c 'git clone -q /home/bt/t10/$s8/in.bundle /home/bt/t10/$s8/repo && git -C /home/bt/t10/$s8/repo checkout -q -B dev $(git rev-parse HEAD)'")" "1"
ok "vm dry run: the systemd unit" "$(echo "$out" | grep -cxF "  systemd-run -q --unit=t10-$s8 --uid=bt --gid=bt -p OOMPolicy=continue --working-directory=/home/bt/t10/$s8 -E HOME=/home/bt /bin/bash /home/bt/t10/$s8/run.sh")" "1"
ok "vm dry run: UTF-8 locale" "$(echo "$out" | grep -cxF "  export HOME=/home/bt LANG=C.UTF-8")" "1"
ok "vm dry run: ~/.dotnet on PATH" "$(echo "$out" | grep -c '^  if \[ -x \$HOME/.dotnet/dotnet \]; then export DOTNET_ROOT=\$HOME/.dotnet;')" "1"
ok "vm dry run: runs the compare" "$(echo "$out" | grep -cxF "  cd /home/bt/t10/$s8/repo; bash scripts/selfhost/t10-compare.sh > /home/bt/t10/$s8/out/log 2>&1; echo \$? > /home/bt/t10/$s8/out/rc")" "1"
ok "vm dry run: hour limit" "$(echo "$out" | grep -c '^every 30s up to 3600s: ')" "1"
ok "vm dry run: fetch and removal" "$(echo "$out" | grep -cxF "ssh ghosthive 'timeout 300 incus exec bayan-test01 -- tar -C /home/bt/t10/$s8/repo/tmp/t10 -cf - .' | tar -C tmp/t10-remote/$s8/vm -xf -")$(echo "$out" | grep -cxF "ssh ghosthive 'timeout 60 incus exec bayan-test01 -- rm -rf /home/bt/t10/$s8 /root/t10-scratch/$s8.bundle'")" "11"
r --host wp1 --dry-run
ok "wp1 dry run: exit 0, no ssh" "$rc $(wc -l < "$A/calls" | tr -d ' ')" "0 0"
ok "wp1 dry run: scp the bundle" "$(echo "$out" | grep -cxF "scp -q tmp/t10-remote/$s8/wp1.bundle wp1:/C:/home/code/extrode.com/bayan/tmp/t10-$s8.bundle")" "1"
ok "wp1 dry run: clone and the compare under Git Bash" "$(echo "$out" | grep -c "^ssh wp1 \"Set-Location 'C:/home/code/extrode.com/bayan/tmp';.* git clone -q -b base t10-$s8.bundle t10-$s8;.*\$env:LANG = 'C.UTF-8'; & 'C:\\\\home\\\\apps\\\\Git\\\\bin\\\\bash.exe' scripts/selfhost/t10-compare.sh; exit \$LASTEXITCODE\" > tmp/t10-remote/$s8/wp1.log$")" "1"
ok "wp1 dry run: fetch" "$(echo "$out" | grep -cxF "scp -r -q wp1:/C:/home/code/extrode.com/bayan/tmp/t10-$s8/tmp/t10 tmp/t10-remote/$s8/wp1")" "1"
r --host mac --dry-run; ok "unknown host refused" "$rc $out" "2 t10-remote: --host vm or --host wp1"

# vm, already running, compare agrees: exit 0, output fetched, the VM left running, remote dirs removed
r --host vm
ok "vm agree: exit 0 and the last line" "$rc|$out" "0|t10: AGREE on Fake"
ok "vm agree: tmp/t10 fetched" "$([ -f "tmp/t10-remote/$s8/vm/results.json" ] && echo yes || echo no)" "yes"
ok "vm agree: running VM neither started nor stopped" "$(called 'incus start')$(called 'incus stop')" "00"
ok "vm agree: qemu reniced, remote dirs removed" "$(called 'renice -n 15')$(called "rm -rf /home/bt/t10/$s8 /root/t10-scratch/$s8.bundle")" "11"
# vm, stopped, compare disagrees: exit 1, the VM started and stopped again
echo STOPPED > "$A/vm"; echo 1 > "$A/rc"
r --host vm
ok "vm disagree: exit 1 and the last line" "$rc|$out" "1|t10: DISAGREE on Fake (files under x)"
ok "vm disagree: stopped VM started and stopped" "$(called 'incus start bayan-test01')$(called 'incus stop bayan-test01')" "11"
# low memory on ghosthive while the unit runs: the unit is stopped, exit 3
echo RUNNING > "$A/vm"; : > "$A/rc"; echo 9000000 > "$A/mem"
r --host vm
ok "vm low memory: exit 3" "$rc $(echo "$out" | grep -c 'MemAvailable 9000000 kB below 10 GiB; stopping t10-')" "3 1"
ok "vm low memory: the unit stopped, the VM not" "$(called "systemctl stop t10-$s8")$(called 'incus stop')" "10"
# the hour is up: the unit is stopped, exit 5; a VM this script started is stopped on that path too
echo STOPPED > "$A/vm"; echo 20000000 > "$A/mem"
: > "$A/calls"; set +e; out=$(T10R_POLL_S=0 T10R_MAX_POLLS=3 PATH="$t/bin:$PATH" /bin/bash "$S" run --host vm 2>&1); rc=$?; set -e
ok "vm over the limit: exit 5, unit and VM stopped" "$rc $(called "systemctl stop t10-$s8")$(called 'incus stop bayan-test01')" "5 11"
ok "vm over the limit: polled 3 times" "$(called 'MemAvailable')" "3"

# wp1: exit code passed on, tmp/t10 fetched, the remote clone removed
echo 0 > "$A/rc"; r --host wp1
ok "wp1 agree: exit 0 and the last line" "$rc|$out" "0|t10: AGREE on Fake"
ok "wp1 agree: tmp/t10 fetched" "$([ -f "tmp/t10-remote/$s8/wp1/results.json" ] && echo yes || echo no)" "yes"
ok "wp1 agree: remote clone removed" "$(called "Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 't10-$s8','t10-$s8.bundle','t10-$s8.t10-remote'")" "1"
echo 1 > "$A/rc"; r --host wp1
ok "wp1 disagree: exit 1 and the last line" "$rc|$out" "1|t10: DISAGREE on Fake (files under x)"
ok "wp1: bundle holds the branch" "$(git bundle list-heads "tmp/t10-remote/$s8/wp1.bundle" | grep -c "refs/heads/base$")" "1"

cd "$root"; rm -rf "$t"
[ $fail = 0 ] && echo "t10-remote.test: all passed" || { echo "t10-remote.test: FAILED"; exit 1; }
