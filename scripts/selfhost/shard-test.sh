#!/bin/bash
# shard-test.sh — run the full Bayan.Tests suite split by test class into weighted slices on several hosts at once, then merge.
#   bash scripts/selfhost/shard-test.sh [run] [--host vm=1.45 --host wp1=1.0] [--times tmp/shard/class-times.tsv] [--classes FILE]
#                                       [--branch B] [--max-filter 20000] [--dry-run]
#   bash scripts/selfhost/shard-test.sh times <file.trx> [out.tsv]   per-class seconds from a `dotnet test --logger trx` file (default out: tmp/shard/class-times.tsv)
# Hosts: vm (bayan-test01 on ghosthive: started, reniced, run as user bt via systemd-run, stopped at the end, also on failure) and
# wp1 (through scripts/selfhost/wp1-test.sh, which has no other host, so wlt1 is not supported). The number after = is the host's speed
# (higher is faster; measured full suite: vm 25.4 min, wp1 36.6 min, so vm=1.45 wp1=1.0). Default hosts: vm=1.45 wp1=1.0.
# A VM that was already running is left running at the end; one this script started is stopped.
# Class weights: tmp/shard/class-times.tsv (class<TAB>seconds); a class missing there gets the median weight. The class list comes from
# `dotnet test --list-tests` on the built assembly (or --classes FILE, one class per line), so a new class is never dropped.
# Packing is greedy longest-first onto the host that would finish earliest (load/speed). Each slice is --filter terms
# `FullyQualifiedName~Ns.Class.` joined by `|`, chunked to --max-filter chars (Windows argv limit 32767) and run chunk after chunk.
# The vm slice is aborted (unit stopped) when ghosthive's MemAvailable (the host, not the VM) drops below 10 GiB, when ghosthive
# or the VM does not answer 10 polls in a row (each poll gives up after about a minute), or after 3 hours. --branch (default: the current branch) must be at
# the commit under test (wp1-test.sh bundles a branch). Output in tmp/shard/<sha8>/: <host>.result, <host>.log, summary.
# Internal sub-commands (used by shard-test.test.sh): pack CLASSES TSV hosts, filters MAX, merge DIR.
# Exit non-zero if a slice failed or did not finish.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
TSV_DEFAULT=tmp/shard/class-times.tsv
VM=bayan-test01; GH=ghosthive; MIN_KB=$((10*1024*1024)); POLL_S=${SHARD_POLL_S:-30}; MAX_POLLS=${SHARD_MAX_POLLS:-360}

# per-class seconds from a TRX: results hold testId + duration, definitions hold testId -> className
trx_times() {
  awk 'BEGIN { RS="<" }
    function attr(n,   m) { if (match($0, " " n "=\"[^\"]*\"")) { m = substr($0, RSTART + length(n) + 3, RLENGTH - length(n) - 4); return m } return "" }
    /^UnitTestResult / { id = attr("testId"); d = attr("duration"); split(d, p, ":"); dur[id] += p[1]*3600 + p[2]*60 + p[3] }
    /^UnitTest / { cur = attr("id") }
    /^TestMethod / { cls[cur] = attr("className") }
    END { for (id in dur) if (id in cls) sum[cls[id]] += dur[id]; for (c in sum) printf "%s\t%.3f\n", c, sum[c] }' "$1" | sort
}

# pack CLASSES TSV "vm=1.45,wp1=1.0" -> host<TAB>weight<TAB>class
pack() {
  awk -F'\t' -v hosts="$3" -v tsv="$2" '
    FILENAME == tsv { w[$1] = $2 + 0; vals[++nv] = $2 + 0; next }
    $1 != "" { cl[++nc] = $1 }
    END {
      # median of the recorded weights (1 when none)
      for (i = 1; i <= nv; i++) for (j = i + 1; j <= nv; j++) if (vals[j] < vals[i]) { t = vals[i]; vals[i] = vals[j]; vals[j] = t }
      med = nv == 0 ? 1 : (nv % 2 ? vals[(nv+1)/2] : (vals[nv/2] + vals[nv/2+1]) / 2)
      nh = split(hosts, hs, ","); for (h = 1; h <= nh; h++) { split(hs[h], kv, "="); hn[h] = kv[1]; sp[h] = kv[2] + 0 }
      for (i = 1; i <= nc; i++) { cw[i] = (cl[i] in w) ? w[cl[i]] : med; ord[i] = i }
      for (i = 1; i <= nc; i++) for (j = i + 1; j <= nc; j++)
        if (cw[ord[j]] > cw[ord[i]] || (cw[ord[j]] == cw[ord[i]] && cl[ord[j]] < cl[ord[i]])) { t = ord[i]; ord[i] = ord[j]; ord[j] = t }
      for (k = 1; k <= nc; k++) {
        i = ord[k]; best = 1
        for (h = 2; h <= nh; h++) if ((load[h] + cw[i]) / sp[h] < (load[best] + cw[i]) / sp[best]) best = h
        load[best] += cw[i]; asg[best] = asg[best] sprintf("%s\t%.3f\t%s\n", hn[best], cw[i], cl[i])
      }
      for (h = 1; h <= nh; h++) printf "%s", asg[h]
    }' "$2" "$1"
}

# filters MAX: class names on stdin -> one --filter string per line, each at most MAX chars (a single longer term still gets its own)
filters() {
  awk -v max="$1" '$1 != "" { t = "FullyQualifiedName~" $1 "."
    if (cur != "" && length(cur) + 1 + length(t) > max) { print cur; cur = "" }
    cur = (cur == "") ? t : cur "|" t }
    END { if (cur != "") print cur }'
}

# merge DIR: <host>.result files (host=, wall=, rc=, done=, log=) -> totals, failing tests per host, walls; non-zero when a slice failed
merge() {
  local d=$1 bad=0 tp=0 tf=0 f h wall rc dn log p fl names
  if [ -f "$d/hosts" ]; then
    for h in $(cat "$d/hosts"); do
      [ -f "$d/$h.result" ] || { printf '%s: no result, DID NOT FINISH\n' "$h"; bad=1; }
    done
  fi
  for f in "$d"/*.result; do
    [ -f "$f" ] || continue
    h=$(sed -n 's/^host=//p' "$f"); wall=$(sed -n 's/^wall=//p' "$f"); rc=$(sed -n 's/^rc=//p' "$f")
    dn=$(sed -n 's/^done=//p' "$f"); log=$(sed -n 's/^log=//p' "$f")
    p=0; fl=0; names=""
    if [ -f "$log" ]; then
      read -r p fl < <(awk '/(Passed|Failed)!.*Failed: *[0-9]+, Passed: *[0-9]+/ { match($0, /Failed: *[0-9]+/); f += substr($0, RSTART + 7, RLENGTH - 7); match($0, /Passed: *[0-9]+/); p += substr($0, RSTART + 7, RLENGTH - 7) } END { print p + 0, f + 0 }' "$log")
      names=$(sed -n -e 's/^ *\[FAIL\] *//p' -e 's/^ *Failed \([^ ]*\).*/\1/p' "$log" | sort -u)
    fi
    tp=$((tp + p)); tf=$((tf + fl))
    printf '%s: passed %s, failed %s, wall %ss, exit %s%s\n' "$h" "$p" "$fl" "$wall" "$rc" "$([ "$dn" = 1 ] || echo ', DID NOT FINISH')"
    [ -z "$names" ] || printf '%s\n' "$names" | sed "s/^/  FAIL [$h] /"
    if [ "$dn" != 1 ] || [ "$rc" != 0 ] || [ "$fl" != 0 ]; then bad=1; fi
  done
  local ow; ow=$(cat "$d/overall.wall" 2>/dev/null)
  if [ -z "$ow" ]; then ow=$(cat "$d"/*.result 2>/dev/null | sed -n 's/^wall=//p' | sort -nr | head -1); fi
  printf 'total: passed %s, failed %s, overall wall %ss (%s min)\n' "$tp" "$tf" "${ow:-0}" "$(awk -v s="${ow:-0}" 'BEGIN { printf "%.1f", s / 60 }')"
  [ $bad = 0 ] && echo "shard-test: ok" || echo "shard-test: FAILED"
  return $bad
}

write_result() { printf 'host=%s\nwall=%s\nrc=%s\ndone=%s\nlog=%s\n' "$2" "$3" "$4" "$5" "$6" > "$1/$2.result"; }
RUNCMD="dotnet test tests/Bayan.Tests -c Release -p:NuGetAudit=false -v q --logger 'console;verbosity=minimal'"
# Every ssh gives up on a dead connection (15 s connect, 60 s unanswered keepalives); the VM side of each poll runs under
# timeout 60 on ghosthive, so a hung incus agent cannot stall the poll loop.
gh() { ssh -o ConnectTimeout=15 -o ServerAliveInterval=15 -o ServerAliveCountMax=4 "$GH" "$@"; }
vmssh() { gh "timeout 60 incus exec $VM -- $*"; }

# poll_state: one poll's output in (the host's MemAvailable line, then `---`, the rc file, `---`, the unit state, all from
# the VM), one verdict out: `miss` (ghosthive or the VM did not answer), `done <rc>`, `lowmem <kB>`, `ended` or `running`.
poll_state() {
  local out; out=$(cat)
  printf '%s\n' "$out" | grep -qx -- '---' || { echo miss; return; }
  local rc mem
  rc=$(printf '%s\n' "$out" | awk '/^---$/ { n++; next } n == 1 { print; exit }')
  [ -z "$rc" ] || { echo "done $rc"; return; }
  mem=$(printf '%s\n' "$out" | sed -n 's/^MemAvailable: *\([0-9]*\) kB/\1/p')
  if [ -n "$mem" ] && [ "$mem" -lt "$MIN_KB" ]; then echo "lowmem $mem"; return; fi
  if printf '%s\n' "$out" | grep -qx 'inactive\|failed'; then echo ended; return; fi
  echo running
}

slice_wp1() { # dir branch
  local d=$1 t0 rc=0 n=0 f r
  t0=$(date +%s); : > "$d/wp1.log"
  while IFS= read -r f; do
    n=$((n+1)); echo "== chunk $n" >> "$d/wp1.log"
    bash "$HERE/wp1-test.sh" "$2" "$f" >> "$d/wp1.log" 2>&1 || { r=$?; [ "$rc" != 0 ] || rc=$r; }
  done < "$d/wp1.filters"
  write_result "$d" wp1 $(( $(date +%s) - t0 )) "$rc" 1 "$d/wp1.log"
}

slice_vm() { # dir sha bundle
  local d=$1 sha=$2 s=${2:0:8} t0 rc="" done=0 D out v unit log i=0 polls=0 miss=0
  D=/home/bt/shard/$s; unit=shard-$s; log=$d/vm/out/log; mkdir -p "$d/vm"; t0=$(date +%s)
  if ! gh "incus list $VM -c s -f csv" | grep -qi running; then
    gh "incus start $VM" || { write_result "$d" vm 0 1 0 ""; return; }
    : > "$d/vm.started"
  fi
  gh 'for p in $(pgrep -f "[q]emu.*'$VM'"); do renice -n 15 -p $p; done' > /dev/null 2>&1
  until vmssh true > /dev/null 2>&1; do i=$((i+1)); [ $i -lt 60 ] || { write_result "$d" vm 0 1 0 ""; return; }; sleep 5; done
  gh "incus exec $VM -- bash -c 'mkdir -p /root/shard-scratch && cat > /root/shard-scratch/$s.bundle'" < "$3" || { write_result "$d" vm 0 1 0 ""; return; }
  {
    echo "set -e"
    echo "id bt >/dev/null 2>&1 || useradd -m bt"
    echo "[ -d /home/bt/bayan-tools ] || { cp -a /root/bayan-tools /home/bt/bayan-tools; chown -R bt:bt /home/bt/bayan-tools; }"
    echo "rm -rf $D; mkdir -p $D/out; cp /root/shard-scratch/$s.bundle $D/in.bundle"
    echo "cat > $D/filters <<'EOF_FILTERS'"; cat "$d/vm.filters"; echo "EOF_FILTERS"
    echo "cat > $D/run.sh <<'EOF_RUN'"
    echo "export DOTNET_ROOT=/home/bt/bayan-tools/dotnet HOME=/home/bt"
    echo "export PATH=/home/bt/bayan-tools/zig/zig-x86_64-linux-0.17.0:\$DOTNET_ROOT:\$PATH"
    echo "cd $D/repo; n=0; rc=0"
    echo "while IFS= read -r f; do n=\$((n+1)); $RUNCMD --logger \"trx;LogFileName=$D/out/chunk\$n.trx\" --filter \"\$f\" >> $D/out/log 2>&1 || rc=\$?; done < $D/filters"
    echo "echo \$rc > $D/out/rc"
    echo "EOF_RUN"
    echo "chown -R bt:bt /home/bt/shard"
    echo "runuser -u bt -- bash -c 'git clone -q $D/in.bundle $D/repo && git -C $D/repo checkout -q -B dev $sha'"
    echo "systemctl reset-failed $unit 2>/dev/null || true"
    echo "systemd-run -q --unit=$unit --uid=bt --gid=bt --working-directory=$D -E HOME=/home/bt /bin/bash $D/run.sh"
  } > "$d/vm.setup.sh"
  gh "incus exec $VM -- bash -s" < "$d/vm.setup.sh" > "$d/vm/setup.out" 2>&1 || { write_result "$d" vm 0 1 0 "$d/vm/setup.out"; return; }
  while :; do
    sleep "$POLL_S"; polls=$((polls+1))
    # one call: the host's MemAvailable (the 10 GiB floor guards ghosthive's other VMs), then the unit's rc file and state
    out=$(gh "grep MemAvailable /proc/meminfo; timeout 60 incus exec $VM -- bash -c 'echo ---; cat $D/out/rc 2>/dev/null; echo ---; systemctl is-active $unit'" 2>/dev/null)
    v=$(printf '%s\n' "$out" | poll_state)
    case $v in
      miss)
        miss=$((miss+1))
        if [ "$miss" -ge 10 ]; then
          echo "shard-test: $GH or $VM did not answer 10 polls in a row; stopping $unit and giving up on the vm slice" >&2
          vmssh "systemctl stop $unit" > /dev/null 2>&1; rc=4; break
        fi
        continue;;
      "done "*) rc=${v#done }; done=1; break;;
      "lowmem "*) echo "shard-test: $GH MemAvailable ${v#lowmem } kB below 10 GiB; stopping $unit" >&2
        vmssh "systemctl stop $unit" > /dev/null 2>&1; rc=3; break;;
      ended)
        # the unit may have written rc and exited between the two reads: read rc once more
        rc=$(vmssh "cat $D/out/rc" 2>/dev/null)
        if [ -n "$rc" ]; then done=1; else rc=1; fi
        break;;
    esac
    miss=0
    [ "$polls" -lt "$MAX_POLLS" ] || { echo "shard-test: vm slice over $((MAX_POLLS * POLL_S))s; stopping $unit" >&2; vmssh "systemctl stop $unit" > /dev/null 2>&1; rc=5; break; }
  done
  gh "incus exec $VM -- tar -C $D -cf - out" 2> /dev/null | tar -C "$d/vm" -xf - 2> /dev/null
  vmssh "rm -rf $D /root/shard-scratch/$s.bundle" > /dev/null 2>&1
  write_result "$d" vm $(( $(date +%s) - t0 )) "$rc" "$done" "$log"
}

vm_stop() { [ ! -f "$SHARD_DIR/vm.started" ] || gh "incus stop $VM" > /dev/null 2>&1; }

list_classes() { # class names from the built test assembly, one per line
  dotnet test tests/Bayan.Tests -c Release -p:NuGetAudit=false --list-tests 2> /dev/null |
    sed -n '/The following Tests are available/,$p' | sed '1d' | sed 's/^ *//; s/(.*//' | grep '\.' | sed 's/\.[^.]*$//' | sort -u
}

run() {
  local hosts="" times=$TSV_DEFAULT classes="" br="" maxf=20000 dry=0 h
  while [ $# -gt 0 ]; do case $1 in
    --host) hosts="$hosts,$2"; shift 2;;
    --times) times=$2; shift 2;;
    --classes) classes=$2; shift 2;;
    --branch) br=$2; shift 2;;
    --max-filter) maxf=$2; shift 2;;
    --dry-run) dry=1; shift;;
    *) echo "shard-test: unknown argument $1"; exit 2;;
  esac; done
  hosts=${hosts#,}; [ -n "$hosts" ] || hosts=vm=1.45,wp1=1.0
  for h in ${hosts//,/ }; do
    case ${h%%=*} in vm|wp1) :;; *) echo "shard-test: unsupported host ${h%%=*} (vm, wp1)"; exit 2;; esac
    case ${h#*=} in ''|*[!0-9.]*|"$h") echo "shard-test: bad speed in $h"; exit 2;; esac
    awk -v v="${h#*=}" 'BEGIN { exit !(v + 0 > 0) }' || { echo "shard-test: bad speed in $h (must be above 0)"; exit 2; }
  done
  [ -n "$br" ] || br=$(git symbolic-ref --short -q HEAD) || { echo "shard-test: detached HEAD, pass --branch"; exit 2; }
  local sha; sha=$(git rev-parse --verify -q "$br^{commit}") || { echo "shard-test: no branch $br"; exit 2; }
  local d=tmp/shard/${sha:0:8}; mkdir -p "$d"
  [ -f "$times" ] || { echo "shard-test: no $times, every class gets weight 1"; : > "$d/empty.tsv"; times=$d/empty.tsv; }
  if [ -z "$classes" ]; then classes=$d/classes.txt; list_classes > "$classes"; fi
  [ -s "$classes" ] || { echo "shard-test: no test classes found"; exit 1; }
  pack "$classes" "$times" "$hosts" > "$d/slices.tsv"
  rm -f "${d:?}"/*.result "${d:?}/overall.wall" "${d:?}/vm.started"; SHARD_DIR=$d
  printf '%s\n' ${hosts//,/ } | sed 's/=.*//' > "$d/hosts"
  for h in ${hosts//,/ }; do
    h=${h%%=*}; awk -F'\t' -v h="$h" '$1 == h { print $3 }' "$d/slices.tsv" | filters "$maxf" > "$d/$h.filters"
    printf '%s: %s classes, est %ss, %s filter chunk(s)\n' "$h" "$(awk -F'\t' -v h="$h" '$1 == h' "$d/slices.tsv" | wc -l | tr -d ' ')" \
      "$(awk -F'\t' -v h="$h" '$1 == h { s += $2 } END { printf "%d", s }' "$d/slices.tsv")" "$(wc -l < "$d/$h.filters" | tr -d ' ')"
  done
  if [ $dry = 1 ]; then
    local n f
    for h in ${hosts//,/ }; do h=${h%%=*}; echo "-- $h classes:"; awk -F'\t' -v h="$h" '$1 == h { print "  " $3 " (" $2 "s)" }' "$d/slices.tsv"
      n=0; while IFS= read -r f; do n=$((n+1))
        if [ $h = wp1 ]; then echo "  bash scripts/selfhost/wp1-test.sh $br '<filter chunk $n, ${#f} chars>'"
        else echo "  ssh $GH incus exec $VM (as bt, systemd-run --unit=shard-${sha:0:8}): $RUNCMD --filter '<filter chunk $n, ${#f} chars>'"; fi
      done < "$d/$h.filters"; done
    echo "(vm: ssh $GH 'incus start $VM', renice qemu 15, push bundle, poll, fetch, 'incus stop $VM'; abort under 10 GiB MemAvailable)"
    return 0
  fi
  local t0 pids="" bundle="$d/head.bundle"; t0=$(date +%s)
  case ",$hosts" in *,vm=*)
    git bundle create "$bundle" "$br" > /dev/null 2>&1 || { echo "shard-test: git bundle create failed"; exit 1; }
    trap vm_stop EXIT;; esac
  case ",$hosts" in *,wp1=*) slice_wp1 "$d" "$br" & pids="$pids $!";; esac
  case ",$hosts" in *,vm=*) slice_vm "$d" "$sha" "$bundle" & pids="$pids $!";; esac
  wait $pids
  echo $(( $(date +%s) - t0 )) > "$d/overall.wall"
  merge "$d" | tee "$d/summary"
  return "${PIPESTATUS[0]}"
}

case "${1:-run}" in
  times) [ $# -ge 2 ] || { echo "usage: shard-test.sh times <file.trx> [out.tsv]"; exit 2; }
         o=${3:-$TSV_DEFAULT}; mkdir -p "$(dirname "$o")"; trx_times "$2" > "$o"; echo "shard-test: $(wc -l < "$o" | tr -d ' ') classes -> $o";;
  pack) pack "$2" "$3" "$4";;
  filters) filters "$2";;
  merge) merge "$2";;
  poll-state) poll_state;;
  run) shift; run "$@"; exit $?;;
  -*) run "$@"; exit $?;;
  *) echo "usage: shard-test.sh [run|times] ..."; exit 2;;
esac
