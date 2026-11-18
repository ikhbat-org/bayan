#!/bin/bash
# t10-remote.sh — run the spec 019 T10 gate (scripts/selfhost/t10-compare.sh) at a branch head on the Linux VM or on wp1, and
# copy its tmp/t10/ back.
#   bash scripts/selfhost/t10-remote.sh run --host vm|wp1 [--branch B] [--dry-run]
# --branch (default: the current branch) is bundled; the run is at its head. Output: tmp/t10-remote/<sha8>/<host>/ holds the
# remote tmp/t10/, tmp/t10-remote/<sha8>/<host>.log the compare's stdout and stderr. Prints that log's last line (`t10: AGREE on
# ...` or `t10: DISAGREE on ...`) and exits with the compare's exit code.
# vm: ghosthive's bayan-test01 is started when stopped (and stopped at the end only then), its
# qemu reniced, the bundle cloned as user bt into /home/bt/t10/<sha8>/repo and the compare run there under
# systemd-run --unit=t10-<sha8> with dotnet and zig on PATH and LANG=C.UTF-8. Polled every 30 s; aborted (unit stopped) when
# ghosthive's MemAvailable drops below 10 GiB (exit 3), when ghosthive or the VM does not answer 10 polls in a row (exit 4) or
# after 1 hour (exit 5). /home/bt/t10/<sha8> and the pushed bundle are removed at the end.
# wp1: as wp1-test.sh (WIN_HOST, default wp1). The bundle is scp'd to C:/home/code/extrode.com/bayan/tmp/, cloned there into
# t10-<sha8> (replaced only when its t10-<sha8>.t10-remote marker says this script made it, else exit 3; exit 4 when the clone
# is not the sha), and the compare run under Git Bash (WIN_BASH, default C:\home\apps\Git\bin\bash.exe) with
# PowerShell's PATH (dotnet) and LANG=C.UTF-8; tmp/t10/ is fetched with scp -r and the remote clone removed.
# --dry-run prints the commands and runs none of them.
set -u
VM=bayan-test01; GH=ghosthive; MIN_KB=$((10*1024*1024)); POLL_S=${T10R_POLL_S:-30}; MAX_POLLS=${T10R_MAX_POLLS:-120}
R=C:/home/code/extrode.com/bayan/tmp

# gh, vmssh and poll_state: ssh to ghosthive, ssh to the VM through incus exec, and the VM state poll
gh() { ssh -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=4 "$GH" "$@"; }
vmssh() { gh "timeout 60 incus exec $VM -- $*"; }
# poll_state: one poll's output in (the host's MemAvailable line, then `---`, the rc file, `---`, the unit state), one verdict
# out: `miss`, `done <rc>`, `lowmem <kB>`, `ended` or `running`
poll_state() {
  local out rc mem; out=$(cat)
  mem=$(printf '%s\n' "$out" | sed -n 's/^MemAvailable: *\([0-9]*\) kB/\1/p')
  if [ -n "$mem" ] && [ "$mem" -lt "$MIN_KB" ]; then echo "lowmem $mem"; return; fi
  printf '%s\n' "$out" | grep -qx -- '---' || { echo miss; return; }
  rc=$(printf '%s\n' "$out" | awk '/^---$/ { n++; next } n == 1 { print; exit }')
  [ -z "$rc" ] || { echo "done $rc"; return; }
  if printf '%s\n' "$out" | grep -qx 'inactive\|failed'; then echo ended; return; fi
  echo running
}

vm_setup() { # sha: the script run as root in the VM (as slice_vm's, for one unit)
  local sha=$1 s=${1:0:8} D=/home/bt/t10/${1:0:8}
  echo "set -e"
  echo "id bt >/dev/null 2>&1 || useradd -m bt"
  echo "[ -d /home/bt/bayan-tools ] || { cp -a /root/bayan-tools /home/bt/bayan-tools; chown -R bt:bt /home/bt/bayan-tools; }"
  echo "rm -rf $D; mkdir -p $D/out; cp /root/t10-scratch/$s.bundle $D/in.bundle"
  echo "cat > $D/run.sh <<'EOF_RUN'"
  echo "export HOME=/home/bt LANG=C.UTF-8"
  # ~/.dotnet when bt has one, else the VM's shared install (slice_vm's)
  echo "if [ -x \$HOME/.dotnet/dotnet ]; then export DOTNET_ROOT=\$HOME/.dotnet; else export DOTNET_ROOT=/home/bt/bayan-tools/dotnet; fi"
  echo "export BAYAN_CC_JOBS=2 BAYAN_CC_JOBS_DIR=/home/bt/shard/cc-jobs"
  echo "export PATH=/home/bt/bayan-tools/zig/zig-x86_64-linux-0.17.0:\$DOTNET_ROOT:\$PATH"
  echo "cd $D/repo; bash scripts/selfhost/t10-compare.sh > $D/out/log 2>&1; echo \$? > $D/out/rc"
  echo "EOF_RUN"
  echo "mkdir -p /home/bt/shard/cc-jobs; chown bt:bt /home/bt/shard /home/bt/shard/cc-jobs; chown -R bt:bt /home/bt/t10"
  echo "runuser -u bt -- bash -c 'git clone -q $D/in.bundle $D/repo && git -C $D/repo checkout -q -B dev $sha'"
  echo "systemctl reset-failed t10-$s 2>/dev/null || true"
  echo "systemd-run -q --unit=t10-$s --uid=bt --gid=bt -p OOMPolicy=continue --working-directory=$D -E HOME=/home/bt /bin/bash $D/run.sh"
}

STARTED=0
vm_stop() { [ "$STARTED" = 0 ] || gh "timeout 300 incus stop $VM" > /dev/null 2>&1; }

run_vm() { # sha bundle dest log -> the compare's exit code (3 low memory, 4 no answer, 5 over an hour, 1 setup failed)
  local sha=$1 s=${1:0:8} b=$2 dest=$3 log=$4 D=/home/bt/t10/${1:0:8} i=0 polls=0 miss=0 rc="" sf=0 v r
  if ! gh "incus list $VM -c s -f csv" | grep -qi running; then
    gh "incus start $VM" || { echo "t10-remote: incus start $VM failed" > "$log"; return 1; }
    STARTED=1
  fi
  gh 'for p in $(pgrep -f "[q]emu.*'$VM'"); do renice -n 15 -p $p; done' > /dev/null 2>&1
  until vmssh true > /dev/null 2>&1; do i=$((i+1)); [ $i -lt 60 ] || { echo "t10-remote: $VM did not answer" > "$log"; return 1; }; sleep 5; done
  gh "timeout 600 incus exec $VM -- bash -c 'mkdir -p /root/t10-scratch && cat > /root/t10-scratch/$s.bundle'" < "$b" ||
    { echo "t10-remote: bundle push failed" > "$log"; return 1; }
  vm_setup "$sha" > "$dest.setup.sh"
  if ! gh "timeout 600 incus exec $VM -- bash -s" < "$dest.setup.sh" > "$dest.setup.out" 2>&1; then
    vmssh "systemctl stop t10-$s" > /dev/null 2>&1
    cp "$dest.setup.out" "$log"; rc=1; sf=1
  fi
  while [ -z "$rc" ]; do
    sleep "$POLL_S"; polls=$((polls+1))
    v=$(gh "grep MemAvailable /proc/meminfo; timeout 60 incus exec $VM -- bash -c 'echo ---; cat $D/out/rc 2>/dev/null; echo ---; systemctl is-active t10-$s'" 2>/dev/null | poll_state)
    case $v in
      miss) miss=$((miss+1))
        [ "$miss" -lt 10 ] || { echo "t10-remote: $GH or $VM did not answer 10 polls in a row; stopping t10-$s" >&2; vmssh "systemctl stop t10-$s" > /dev/null 2>&1; rc=4; }
        continue;;
      "done "*) rc=${v#done };;
      "lowmem "*) echo "t10-remote: $GH MemAvailable ${v#lowmem } kB below 10 GiB; stopping t10-$s" >&2; vmssh "systemctl stop t10-$s" > /dev/null 2>&1; rc=3;;
      ended) r=$(vmssh "cat $D/out/rc" 2>/dev/null); rc=${r:-1};;
    esac
    miss=0
    [ -n "$rc" ] || [ "$polls" -lt "$MAX_POLLS" ] || { echo "t10-remote: over $((MAX_POLLS * POLL_S))s; stopping t10-$s" >&2; vmssh "systemctl stop t10-$s" > /dev/null 2>&1; rc=5; }
  done
  [ $sf = 1 ] || gh "timeout 60 incus exec $VM -- cat $D/out/log" > "$log" 2> /dev/null
  gh "timeout 300 incus exec $VM -- tar -C $D/repo/tmp/t10 -cf - ." 2> /dev/null | tar -C "$dest" -xf - 2> /dev/null
  vmssh "rm -rf $D /root/t10-scratch/$s.bundle" > /dev/null 2>&1
  return "$rc"
}

win_cmd() { # branch sha: the PowerShell command (wp1-test.sh's clone path, then the compare under Git Bash)
  local s=${2:0:8} d=t10-${2:0:8}
  printf '%s' "Set-Location '$R'; if (Test-Path '$d') { if (-not (Test-Path '$d.t10-remote')) { Write-Output 't10-remote: $R/$d exists and t10-remote.sh did not create it'; exit 3 }; Remove-Item -Recurse -Force '$d' }; \
New-Item -ItemType File -Force '$d.t10-remote' | Out-Null; git clone -q -b $1 $d.bundle $d; if (\$LASTEXITCODE) { exit \$LASTEXITCODE }; \
Set-Location '$d'; if ((git rev-parse HEAD) -ne '$2') { Write-Output 't10-remote: $1 moved after $2 was resolved; the clone is not $2'; exit 4 }; \
\$env:BAYAN_TEST_TIME_SCALE = '${BAYAN_TEST_TIME_SCALE:-3}'; \$env:LANG = 'C.UTF-8'; & '$WB' scripts/selfhost/t10-compare.sh; exit \$LASTEXITCODE"
}

run_win() { # branch sha bundle dest log -> the compare's exit code
  local d=t10-${2:0:8} rc
  scp -q "$3" "$H:/$R/$d.bundle" > "$5" 2>&1; rc=$?
  [ $rc = 0 ] || return $rc
  ssh "$H" "$(win_cmd "$1" "$2")" >> "$5" 2>&1; rc=$?
  scp -r -q "$H:/$R/$d/tmp/t10" "$4" > /dev/null 2>&1
  ssh "$H" "Set-Location '$R'; Remove-Item -Recurse -Force -ErrorAction SilentlyContinue '$d','$d.bundle','$d.t10-remote'" > /dev/null 2>&1
  return $rc
}

run() {
  local host="" br="" dry=0
  while [ $# -gt 0 ]; do case $1 in
    --host) host=${2:-}; shift 2 || shift;;
    --branch) br=${2:-}; shift 2 || shift;;
    --dry-run) dry=1; shift;;
    *) echo "t10-remote: unknown argument $1"; exit 2;;
  esac; done
  case $host in vm|wp1) :;; *) echo "t10-remote: --host vm or --host wp1"; exit 2;; esac
  [ -n "$br" ] || br=$(git symbolic-ref --short -q HEAD) || { echo "t10-remote: detached HEAD, pass --branch"; exit 2; }
  local sha; sha=$(git rev-parse --verify -q "$br^{commit}") || { echo "t10-remote: no branch $br"; exit 2; }
  local s=${sha:0:8} base=tmp/t10-remote/${sha:0:8} hn=$host
  H=${WIN_HOST:-wp1}; WB=${WIN_BASH:-'C:\home\apps\Git\bin\bash.exe'}
  [ "$host" = vm ] || hn=$H
  case $H in ''|*[!A-Za-z0-9_-]*) echo "t10-remote: bad WIN_HOST $H"; exit 2;; esac
  local dest=$base/$hn log=$base/$hn.log b=$base/$hn.bundle D=/home/bt/t10/$s
  if [ $dry = 1 ]; then
    echo "git bundle create $b $br"
    if [ "$host" = vm ]; then
      echo "ssh $GH 'incus list $VM -c s -f csv'   (then ssh $GH 'incus start $VM' when not running)"
      echo "ssh $GH 'for p in \$(pgrep -f \"[q]emu.*$VM\"); do renice -n 15 -p \$p; done'"
      echo "ssh $GH \"timeout 600 incus exec $VM -- bash -c 'mkdir -p /root/t10-scratch && cat > /root/t10-scratch/$s.bundle'\" < $b"
      echo "ssh $GH 'timeout 600 incus exec $VM -- bash -s' < $dest.setup.sh, which is:"
      vm_setup "$sha" | sed 's/^/  /'
      echo "every ${POLL_S}s up to $((MAX_POLLS * POLL_S))s: ssh $GH \"grep MemAvailable /proc/meminfo; timeout 60 incus exec $VM -- bash -c 'echo ---; cat $D/out/rc 2>/dev/null; echo ---; systemctl is-active t10-$s'\""
      echo "  (under 10 GiB MemAvailable, 10 missed polls or over the hour: ssh $GH 'timeout 60 incus exec $VM -- systemctl stop t10-$s')"
      echo "ssh $GH 'timeout 60 incus exec $VM -- cat $D/out/log' > $log"
      echo "ssh $GH 'timeout 300 incus exec $VM -- tar -C $D/repo/tmp/t10 -cf - .' | tar -C $dest -xf -"
      echo "ssh $GH 'timeout 60 incus exec $VM -- rm -rf $D /root/t10-scratch/$s.bundle'"
      echo "ssh $GH 'timeout 300 incus stop $VM'   (only when this script started it)"
    else
      echo "scp -q $b $H:/$R/t10-$s.bundle"
      echo "ssh $H \"$(win_cmd "$br" "$sha")\" > $log"
      echo "scp -r -q $H:/$R/t10-$s/tmp/t10 $dest"
      echo "ssh $H \"Set-Location '$R'; Remove-Item -Recurse -Force -ErrorAction SilentlyContinue 't10-$s','t10-$s.bundle','t10-$s.t10-remote'\""
    fi
    return 0
  fi
  rm -rf "$dest" "$log" "$dest.setup.sh" "$dest.setup.out"; mkdir -p "$base"
  git bundle create "$b" "$br" > /dev/null 2>&1 || { echo "t10-remote: git bundle create failed for $br"; exit 1; }
  local rc
  if [ "$host" = vm ]; then
    mkdir -p "$dest"; trap vm_stop EXIT
    run_vm "$sha" "$b" "$dest" "$log"; rc=$?
  else
    run_win "$br" "$sha" "$b" "$dest" "$log"; rc=$?
  fi
  [ -d "$dest" ] || echo "t10-remote: nothing fetched into $dest" >&2
  tail -1 "$log" 2>/dev/null | tr -d '\r'
  return "$rc"
}

case "${1:-}" in
  run) shift; run "$@"; exit $?;;
  *) echo "usage: t10-remote.sh run --host vm|wp1 [--branch B] [--dry-run]"; exit 2;;
esac
