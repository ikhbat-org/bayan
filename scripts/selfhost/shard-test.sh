#!/bin/bash
# shard-test.sh — run the full Bayan.Tests suite split by test class into weighted slices on several hosts at once, then merge.
#   bash scripts/selfhost/shard-test.sh [run] [--host NAME=SPEED[:SLICES[:THREADS]] ...] [--times tmp/shard/class-times.tsv]
#                                       [--classes FILE] [--branch B] [--max-filter 20000] [--dry-run]
#   e.g. --host vm=0.91:2:4 --host wp1=0.52 --host wlt1=0.45
#   bash scripts/selfhost/shard-test.sh times <a.trx> [b.trx ...] [out.tsv]   per-class seconds from `dotnet test --logger trx` files,
#     the larger when a class is in two (default out: tmp/shard/class-times.tsv); e.g. times tmp/shard/<sha8>/*/chunk*.trx tmp/shard/<sha8>/*/out/chunk*.trx
# Hosts (NAME): vm (bayan-test01 on ghosthive: started once, reniced, each slice run as user bt via its own systemd-run unit
# shard-<sha8>-<i> in /home/bt/shard/<sha8>-<i>, stopped at the end, also on failure), wp1 and wlt1 (through scripts/selfhost/wp1-test.sh
# with WIN_HOST=<name>; wlt1 gets zig put on PATH there) and mb1 (this Mac: the bundle cloned into tmp/shard/<sha8>/mb1/repo, run under
# nice with ~/.dotnet, never the working tree). SPEED is the host's speed (higher is faster; 1/c, c = wall seconds per model second
# from tmp/shard/assess-4way.md: vm 0.91, wp1 0.52 measured, wlt1 ~0.45 and mb1 ~0.71 estimated). SLICES (default 1; only vm may have
# more) is the number of `dotnet test` processes on that host: vm=0.91:2 runs units vm1 and vm2. THREADS (default 4, as
# xunit.runner.json) is passed to every test process there as `-- xUnit.MaxParallelThreads=N`. Default hosts: vm=0.91 wp1=0.52
# (wlt1 and mb1 only when named). A VM that was already running is left running at the end; one this script started is stopped.
# Class weights: tmp/shard/class-times.tsv (class<TAB>seconds); a class missing there gets the median weight. The class list comes from
# `dotnet test --list-tests` on the built assembly (or --classes FILE, one class per line), so a new class is never dropped.
# Serial classes (run one at a time by xunit) are those carrying [Collection(nameof(X))] or [Collection("X")] for a
# [CollectionDefinition(nameof(X), DisableParallelization = true)] in tests/Bayan.Tests/*.cs. A unit's load is
# (serial seconds + parallel seconds / THREADS) / SPEED; packing is greedy longest-first onto the unit that would finish earliest.
# Each slice is --filter terms `FullyQualifiedName~Ns.Class.` joined by `|`, chunked to --max-filter chars (Windows argv limit 32767)
# and run chunk after chunk. The vm slices are aborted (all units stopped) when ghosthive's MemAvailable (the host, not the VM) drops
# below 10 GiB, when ghosthive or the VM does not answer 10 polls in a row (each poll gives up after about a minute), or after 3 hours.
# --branch (default: the current branch) must be at the commit under test (wp1-test.sh bundles a branch).
# Output in tmp/shard/<sha8>/: <unit>.result, <unit>.log, summary, and the trx files under <unit>/ for `times`.
# Internal sub-commands (used by shard-test.test.sh): host-spec SPEC, pack CLASSES TSV hosts [SERIAL], serial DIR, filters MAX,
# merge DIR, poll-state [UNIT].
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

# times TRX... -> one class<TAB>seconds list, the larger when a class is in more than one file
times_merge() {
  local f; for f in "$@"; do trx_times "$f"; done |
    awk -F'\t' '!($1 in s) || $2 + 0 > s[$1] + 0 { s[$1] = $2 } END { for (c in s) printf "%s\t%s\n", c, s[c] }' | sort
}

# host-spec NAME=SPEED[:SLICES[:THREADS]] -> NAME=SPEED:SLICES:THREADS, or a message naming the bad part and exit 2
host_spec() {
  local h=$1 n r sp sl=1 th=4
  n=${h%%=*}; r=${h#*=}
  case $n in vm|wp1|wlt1|mb1) :;; *) echo "shard-test: unsupported host $n in $h (vm, wp1, wlt1, mb1)"; exit 2;; esac
  [[ $h == *=* && $r =~ ^([^:]*)(:([^:]*)(:([^:]*))?)?$ ]] || { echo "shard-test: bad host $h (NAME=SPEED[:SLICES[:THREADS]])"; exit 2; }
  sp=${BASH_REMATCH[1]}
  [ -z "${BASH_REMATCH[2]}" ] || sl=${BASH_REMATCH[3]}
  [ -z "${BASH_REMATCH[4]}" ] || th=${BASH_REMATCH[5]}
  case $sp in ''|*[!0-9.]*) echo "shard-test: bad speed in $h"; exit 2;; esac
  awk -v v="$sp" 'BEGIN { exit !(v + 0 > 0) }' || { echo "shard-test: bad speed in $h (must be above 0)"; exit 2; }
  case $sl in ''|*[!0-9]*) echo "shard-test: bad slices in $h (a positive integer)"; exit 2;; esac
  [ "$sl" -gt 0 ] || { echo "shard-test: bad slices in $h (a positive integer)"; exit 2; }
  [ "$n" = vm ] || [ "$sl" -eq 1 ] || { echo "shard-test: bad slices in $h (only vm runs more than one slice)"; exit 2; }
  case $th in ''|*[!0-9]*) echo "shard-test: bad threads in $h (a positive integer)"; exit 2;; esac
  [ "$th" -gt 0 ] || { echo "shard-test: bad threads in $h (a positive integer)"; exit 2; }
  echo "$n=$sp:$((10#$sl)):$((10#$th))"
}

# units "vm=0.91:2:4,wp1=0.52" -> one unit per line: name speed threads (a vm with 2 slices is vm1 and vm2)
units() {
  local h sp sl th i
  for h in ${1//,/ }; do
    IFS=: read -r sp sl th <<< "${h#*=}"; sl=${sl:-1}; th=${th:-4}
    if [ "$sl" -gt 1 ]; then for ((i = 1; i <= sl; i++)); do echo "${h%%=*}$i $sp $th"; done; else echo "${h%%=*} $sp $th"; fi
  done
}

# serial DIR -> the classes (Ns.Class) in a collection whose [CollectionDefinition] has DisableParallelization = true, from DIR/*.cs
serial_classes() {
  ls "$1"/*.cs > /dev/null 2>&1 || return 0
  awk '
    function cname(s) { sub(/^[^(]*\(/, "", s)
      if (s ~ /^nameof\(/) { sub(/^nameof\(/, "", s); sub(/\).*/, "", s); sub(/.*\./, "", s) } else { sub(/^"/, "", s); sub(/".*/, "", s) }
      return s }
    FNR == 1 { ns = ""; pend = "" }
    pass == 1 && /^[ \t]*\[CollectionDefinition\(/ && /DisableParallelization *= *true/ { dis[cname($0)] = 1; next }
    pass == 1 { next }
    /^[ \t]*namespace / { ns = $2; sub(/[;{].*/, "", ns) }
    /^[ \t]*\[Collection\(/ { pend = cname($0) }
    pend != "" && /^[ \t]*(\[[^]]*\][ \t]*)*((public|internal|private|protected|sealed|static|partial|abstract|file)[ \t]+)*(class|record)[ \t]+[A-Za-z_]/ {
      c = $0; sub(/.*(class|record)[ \t]+/, "", c); sub(/[^A-Za-z0-9_].*/, "", c)
      if (pend in dis) print (ns == "" ? "" : ns ".") c
      pend = "" }' pass=1 "$1"/*.cs pass=2 "$1"/*.cs | sort -u
}

# pack CLASSES TSV "vm=0.91:2:4,wp1=0.52" [SERIAL] -> unit<TAB>weight<TAB>class. A unit's load is (serial seconds + parallel
# seconds / threads) / speed; longest first (a parallel class counts a quarter, as at the default 4 threads) onto the unit that
# would finish earliest. SERIAL lists the classes that run one at a time (none when absent).
pack() {
  awk -F'\t' -v units="$(units "$3" | awk '{ printf "%s%s=%s:%s", (NR > 1 ? "," : ""), $1, $2, $3 }')" -v tsv="$2" -v ser="${4:-/dev/null}" '
    FILENAME == tsv { w[$1] = $2 + 0; vals[++nv] = $2 + 0; next }
    FILENAME == ser { if ($1 != "") s[$1] = 1; next }
    $1 != "" { cl[++nc] = $1 }
    END {
      # median of the recorded weights (1 when none)
      for (i = 1; i <= nv; i++) for (j = i + 1; j <= nv; j++) if (vals[j] < vals[i]) { t = vals[i]; vals[i] = vals[j]; vals[j] = t }
      med = nv == 0 ? 1 : (nv % 2 ? vals[(nv+1)/2] : (vals[nv/2] + vals[nv/2+1]) / 2)
      nh = split(units, hs, ","); for (h = 1; h <= nh; h++) { split(hs[h], kv, "[=:]"); hn[h] = kv[1]; sp[h] = kv[2] + 0; th[h] = kv[3] + 0 }
      for (i = 1; i <= nc; i++) { cw[i] = (cl[i] in w) ? w[cl[i]] : med; ser_[i] = cl[i] in s; key[i] = ser_[i] ? cw[i] : cw[i] / 4; ord[i] = i }
      for (i = 1; i <= nc; i++) for (j = i + 1; j <= nc; j++)
        if (key[ord[j]] > key[ord[i]] || (key[ord[j]] == key[ord[i]] && cl[ord[j]] < cl[ord[i]])) { t = ord[i]; ord[i] = ord[j]; ord[j] = t }
      for (k = 1; k <= nc; k++) {
        i = ord[k]; best = 0
        for (h = 1; h <= nh; h++) {
          f = (sl[h] + (ser_[i] ? cw[i] : 0) + (pl[h] + (ser_[i] ? 0 : cw[i])) / th[h]) / sp[h]
          if (best == 0 || f < bf) { best = h; bf = f }
        }
        if (ser_[i]) sl[best] += cw[i]; else pl[best] += cw[i]
        asg[best] = asg[best] sprintf("%s\t%.3f\t%s\n", hn[best], cw[i], cl[i])
      }
      for (h = 1; h <= nh; h++) printf "%s", asg[h]
    }' "$2" ${4:+"$4"} "$1"
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
# With UNIT, the VM part is the `=== UNIT` section of a poll of several units.
poll_state() { # [unit]
  local out rc mem; out=$(cat)
  [ -z "${1:-}" ] || out=$(printf '%s\n' "$out" | awk -v u="=== $1" '/^MemAvailable/ { print; next } $0 == u { on = 1; next } /^=== / { on = 0 } on')
  # the host's floor first: it holds even when the VM does not answer (a thrashing VM is the likely cause)
  mem=$(printf '%s\n' "$out" | sed -n 's/^MemAvailable: *\([0-9]*\) kB/\1/p')
  if [ -n "$mem" ] && [ "$mem" -lt "$MIN_KB" ]; then echo "lowmem $mem"; return; fi
  printf '%s\n' "$out" | grep -qx -- '---' || { echo miss; return; }
  rc=$(printf '%s\n' "$out" | awk '/^---$/ { n++; next } n == 1 { print; exit }')
  [ -z "$rc" ] || { echo "done $rc"; return; }
  if printf '%s\n' "$out" | grep -qx 'inactive\|failed'; then echo ended; return; fi
  echo running
}

slice_win() { # dir branch host threads: wp1 or wlt1 through wp1-test.sh (own tmp/<host>/ there), trx files to <dir>/<host>/
  local d=$1 h=$3 t0 rc=0 n=0 f r
  t0=$(date +%s); : > "$d/$h.log"; mkdir -p "$d/$h"
  while IFS= read -r f; do
    n=$((n+1)); echo "== chunk $n" >> "$d/$h.log"
    WIN_HOST=$h WIN_THREADS=$4 WIN_TRX=$d/$h/chunk$n.trx bash "$HERE/wp1-test.sh" "$2" "$f" >> "$d/$h.log" 2>&1 || { r=$?; [ "$rc" != 0 ] || rc=$r; }
  done < "$d/$h.filters"
  write_result "$d" "$h" $(( $(date +%s) - t0 )) "$rc" 1 "$d/$h.log"
}

slice_mb1() { # dir bundle sha threads: this Mac, in a clone of the bundle under <dir>/mb1/repo (removed after; trx files kept in <dir>/mb1/)
  local d=$1 m=$1/mb1 t0 rc=0 n=0 f a
  t0=$(date +%s); : > "$d/mb1.log"; rm -rf "$m"; mkdir -p "$m"; a=$(cd "$m" && pwd)
  { git clone -q "$2" "$m/repo" && git -C "$m/repo" checkout -q -B dev "$3"; } >> "$d/mb1.log" 2>&1 || { write_result "$d" mb1 0 1 0 "$d/mb1.log"; return; }
  while IFS= read -r f; do
    n=$((n+1))
    (cd "$m/repo" && DOTNET_ROOT=$HOME/.dotnet PATH=$HOME/.dotnet:$PATH nice dotnet test tests/Bayan.Tests -c Release -p:NuGetAudit=false -v q \
      --logger 'console;verbosity=minimal' --logger "trx;LogFileName=$a/chunk$n.trx" --filter "$f" -- xUnit.MaxParallelThreads="$4") >> "$d/mb1.log" 2>&1 || rc=$?
  done < "$d/mb1.filters"
  rm -rf "$m/repo"
  write_result "$d" mb1 $(( $(date +%s) - t0 )) "$rc" 1 "$d/mb1.log"
}

slice_vm() { # dir sha bundle unit:threads...: one VM start and bundle push, then one systemd unit per vm unit, polled together
  local d=$1 sha=$2 s=${2:0:8} b=$3 t0 out v i=0 k u D polls=0 miss=0 low lost left r q
  local U=() TH=() IX=() RC=() DN=() FT=()
  shift 3
  for k in "$@"; do u=${k%%:*}; U+=("$u"); TH+=("${k#*:}"); i=${u#vm}; IX+=("${i:-1}"); RC+=(""); DN+=(0); mkdir -p "$d/$u"; done
  vm_fail() { for k in "${!U[@]}"; do write_result "$d" "${U[k]}" 0 1 0 "$1"; done; }
  vm_stop_units() { # rc: stop every unit still running, which gets rc
    local k us=""; for k in "${!U[@]}"; do [ -n "${RC[k]}" ] || { us="$us shard-$s-${IX[k]}"; RC[k]=$1; }; done
    [ -z "$us" ] || vmssh "systemctl stop$us" > /dev/null 2>&1; }
  t0=$(date +%s); i=0
  if ! gh "incus list $VM -c s -f csv" | grep -qi running; then
    gh "incus start $VM" || { vm_fail ""; return; }
    : > "$d/vm.started"
  fi
  gh 'for p in $(pgrep -f "[q]emu.*'$VM'"); do renice -n 15 -p $p; done' > /dev/null 2>&1
  until vmssh true > /dev/null 2>&1; do i=$((i+1)); [ $i -lt 60 ] || { vm_fail ""; return; }; sleep 5; done
  gh "timeout 600 incus exec $VM -- bash -c 'mkdir -p /root/shard-scratch && cat > /root/shard-scratch/$s.bundle'" < "$b" || { vm_fail ""; return; }
  {
    echo "set -e"
    echo "id bt >/dev/null 2>&1 || useradd -m bt"
    echo "[ -d /home/bt/bayan-tools ] || { cp -a /root/bayan-tools /home/bt/bayan-tools; chown -R bt:bt /home/bt/bayan-tools; }"
    for k in "${!U[@]}"; do D=/home/bt/shard/$s-${IX[k]}
      echo "rm -rf $D; mkdir -p $D/out; cp /root/shard-scratch/$s.bundle $D/in.bundle"
      echo "cat > $D/filters <<'EOF_FILTERS'"; cat "$d/${U[k]}.filters"; echo "EOF_FILTERS"
      echo "cat > $D/run.sh <<'EOF_RUN'"
      echo "export DOTNET_ROOT=/home/bt/bayan-tools/dotnet HOME=/home/bt"
      echo "export PATH=/home/bt/bayan-tools/zig/zig-x86_64-linux-0.17.0:\$DOTNET_ROOT:\$PATH"
      echo "cd $D/repo; n=0; rc=0"
      echo "while IFS= read -r f; do n=\$((n+1)); $RUNCMD --logger \"trx;LogFileName=$D/out/chunk\$n.trx\" --filter \"\$f\" -- xUnit.MaxParallelThreads=${TH[k]} >> $D/out/log 2>&1 || rc=\$?; done < $D/filters"
      echo "echo \$rc > $D/out/rc"
      echo "EOF_RUN"
    done
    echo "chown -R bt:bt /home/bt/shard"
    for k in "${!U[@]}"; do D=/home/bt/shard/$s-${IX[k]}; u=shard-$s-${IX[k]}
      echo "runuser -u bt -- bash -c 'git clone -q $D/in.bundle $D/repo && git -C $D/repo checkout -q -B dev $sha'"
      echo "systemctl reset-failed $u 2>/dev/null || true"
      echo "systemd-run -q --unit=$u --uid=bt --gid=bt --working-directory=$D -E HOME=/home/bt /bin/bash $D/run.sh"
    done
  } > "$d/vm.setup.sh"
  gh "timeout 600 incus exec $VM -- bash -s" < "$d/vm.setup.sh" > "$d/vm.setup.out" 2>&1 || { vm_fail "$d/vm.setup.out"; return; }
  while :; do
    sleep "$POLL_S"; polls=$((polls+1))
    # one call: the host's MemAvailable (the 10 GiB floor guards ghosthive's other VMs), then each running unit's rc file and state
    q=""; for k in "${!U[@]}"; do [ -n "${RC[k]}" ] && continue; D=/home/bt/shard/$s-${IX[k]}
      q="$q echo === ${U[k]}; echo ---; cat $D/out/rc 2>/dev/null; echo ---; systemctl is-active shard-$s-${IX[k]};"; done
    out=$(gh "grep MemAvailable /proc/meminfo; timeout 60 incus exec $VM -- bash -c '$q'" 2>/dev/null)
    low=""; lost=0
    for k in "${!U[@]}"; do [ -n "${RC[k]}" ] && continue
      v=$(printf '%s\n' "$out" | poll_state "${U[k]}")
      case $v in
        miss) lost=1;;
        "done "*) RC[k]=${v#done }; DN[k]=1; FT[k]=$(date +%s);;
        "lowmem "*) low=${v#lowmem };;
        ended)
          # the unit may have written rc and exited between the two reads: read rc once more
          r=$(vmssh "cat /home/bt/shard/$s-${IX[k]}/out/rc" 2>/dev/null)
          if [ -n "$r" ]; then RC[k]=$r; DN[k]=1; else RC[k]=1; fi; FT[k]=$(date +%s);;
      esac
    done
    if [ -n "$low" ]; then echo "shard-test: $GH MemAvailable $low kB below 10 GiB; stopping the vm units" >&2; vm_stop_units 3; break; fi
    if [ $lost = 1 ]; then
      miss=$((miss+1))
      if [ "$miss" -ge 10 ]; then
        echo "shard-test: $GH or $VM did not answer 10 polls in a row; stopping the vm units and giving up on the vm slices" >&2
        vm_stop_units 4; break
      fi
      continue
    fi
    miss=0; left=0; for k in "${!U[@]}"; do [ -n "${RC[k]}" ] || left=1; done; [ $left = 1 ] || break
    [ "$polls" -lt "$MAX_POLLS" ] || { echo "shard-test: vm slices over $((MAX_POLLS * POLL_S))s; stopping the vm units" >&2; vm_stop_units 5; break; }
  done
  q=""; for k in "${!U[@]}"; do D=/home/bt/shard/$s-${IX[k]}; q="$q $D"
    gh "timeout 300 incus exec $VM -- tar -C $D -cf - out" 2> /dev/null | tar -C "$d/${U[k]}" -xf - 2> /dev/null; done
  vmssh "rm -rf$q /root/shard-scratch/$s.bundle" > /dev/null 2>&1
  for k in "${!U[@]}"; do write_result "$d" "${U[k]}" $(( ${FT[k]:-$(date +%s)} - t0 )) "${RC[k]}" "${DN[k]}" "$d/${U[k]}/out/log"; done
}

vm_stop() { [ ! -f "$SHARD_DIR/vm.started" ] || gh "timeout 300 incus stop $VM" > /dev/null 2>&1; }

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
  hosts=${hosts#,}; [ -n "$hosts" ] || hosts=vm=0.91,wp1=0.52
  local spec=""
  for h in ${hosts//,/ }; do h=$(host_spec "$h") || { echo "$h"; exit 2; }
    case "$spec," in *",${h%%=*}="*) echo "shard-test: host ${h%%=*} given twice (its slices would share tmp/${h%%=*}/)"; exit 2;; esac
    spec="$spec,$h"; done
  hosts=${spec#,}
  [ -n "$br" ] || br=$(git symbolic-ref --short -q HEAD) || { echo "shard-test: detached HEAD, pass --branch"; exit 2; }
  local sha; sha=$(git rev-parse --verify -q "$br^{commit}") || { echo "shard-test: no branch $br"; exit 2; }
  local d=tmp/shard/${sha:0:8}; mkdir -p "$d"
  [ -f "$times" ] || { echo "shard-test: no $times, every class gets weight 1"; : > "$d/empty.tsv"; times=$d/empty.tsv; }
  if [ -z "$classes" ]; then classes=$d/classes.txt; list_classes > "$classes"; fi
  [ -s "$classes" ] || { echo "shard-test: no test classes found"; exit 1; }
  serial_classes tests/Bayan.Tests > "$d/serial.txt"
  pack "$classes" "$times" "$hosts" "$d/serial.txt" > "$d/slices.tsv"
  rm -f "${d:?}"/*.result "${d:?}/overall.wall" "${d:?}/vm.started"; SHARD_DIR=$d
  units "$hosts" > "$d/units"; cut -d' ' -f1 "$d/units" > "$d/hosts"
  local u sp th
  while read -r u sp th; do
    awk -F'\t' -v h="$u" '$1 == h { print $3 }' "$d/slices.tsv" | filters "$maxf" > "$d/$u.filters"
    printf '%s: %s classes (%s serial), est %ss, %s filter chunk(s)\n' "$u" "$(awk -F'\t' -v h="$u" '$1 == h' "$d/slices.tsv" | wc -l | tr -d ' ')" \
      "$(awk -F'\t' -v h="$u" 'FILENAME != ARGV[2] { s[$1] = 1; next } $1 == h && $3 in s { n++ } END { print n + 0 }' "$d/serial.txt" "$d/slices.tsv")" \
      "$(awk -F'\t' -v h="$u" -v sp="$sp" -v th="$th" 'FILENAME != ARGV[2] { s[$1] = 1; next } $1 == h { if ($3 in s) S += $2; else P += $2 }
         END { printf "%d", (S + P / th) / sp }' "$d/serial.txt" "$d/slices.tsv")" "$(wc -l < "$d/$u.filters" | tr -d ' ')"
  done < "$d/units"
  if [ $dry = 1 ]; then
    local n f s=${sha:0:8} i
    while read -r u sp th; do echo "-- $u classes:"; awk -F'\t' -v h="$u" '$1 == h { print "  " $3 " (" $2 "s)" }' "$d/slices.tsv"
      n=0; while IFS= read -r f; do n=$((n+1))
        case $u in
          wp1|wlt1) echo "  WIN_HOST=$u WIN_THREADS=$th bash scripts/selfhost/wp1-test.sh $br '<filter chunk $n, ${#f} chars>'";;
          mb1) echo "  (in $d/mb1/repo, DOTNET_ROOT=\$HOME/.dotnet) nice $RUNCMD --filter '<filter chunk $n, ${#f} chars>' -- xUnit.MaxParallelThreads=$th";;
          *) i=${u#vm}; echo "  ssh $GH incus exec $VM (as bt, systemd-run --unit=shard-$s-${i:-1} in /home/bt/shard/$s-${i:-1}): $RUNCMD --filter '<filter chunk $n, ${#f} chars>' -- xUnit.MaxParallelThreads=$th";;
        esac
      done < "$d/$u.filters"; done < "$d/units"
    grep -q '^vm' "$d/units" && echo "(vm: ssh $GH 'incus start $VM', renice qemu 15, push bundle, poll, fetch, 'incus stop $VM'; abort under 10 GiB MemAvailable)"
    return 0
  fi
  local t0 pids="" vmu="" rc bundle="$d/head.bundle"; t0=$(date +%s)
  if grep -q '^vm\|^mb1' "$d/units"; then
    git bundle create "$bundle" "$br" > /dev/null 2>&1 || { echo "shard-test: git bundle create failed"; exit 1; }
  fi
  while read -r u sp th; do case $u in
    wp1|wlt1) slice_win "$d" "$br" "$u" "$th" & pids="$pids $!";;
    mb1) slice_mb1 "$d" "$bundle" "$sha" "$th" & pids="$pids $!";;
    *) vmu="$vmu $u:$th";;
  esac; done < "$d/units"
  if [ -n "$vmu" ]; then trap vm_stop EXIT; slice_vm "$d" "$sha" "$bundle" $vmu & pids="$pids $!"; fi
  wait $pids
  echo $(( $(date +%s) - t0 )) > "$d/overall.wall"
  merge "$d" | tee "$d/summary"
  rc=${PIPESTATUS[0]}
  ls "$d"/*/chunk*.trx "$d"/*/out/chunk*.trx > /dev/null 2>&1 && echo "(weights: bash scripts/selfhost/shard-test.sh times $d/*/chunk*.trx $d/*/out/chunk*.trx)"
  return "$rc"
}

case "${1:-run}" in
  times) shift; [ $# -ge 1 ] || { echo "usage: shard-test.sh times <a.trx> [b.trx ...] [out.tsv]"; exit 2; }
         o=$TSV_DEFAULT; case ${!#} in *.trx) :;; *) o=${!#}; set -- "${@:1:$#-1}";; esac
         [ $# -ge 1 ] || { echo "usage: shard-test.sh times <a.trx> [b.trx ...] [out.tsv]"; exit 2; }
         mkdir -p "$(dirname "$o")"; times_merge "$@" > "$o"; echo "shard-test: $(wc -l < "$o" | tr -d ' ') classes -> $o";;
  host-spec) host_spec "$2";;
  pack) pack "$2" "$3" "$4" "${5:-}";;
  serial) serial_classes "$2";;
  filters) filters "$2";;
  merge) merge "$2";;
  poll-state) poll_state "${2:-}";;
  run) shift; run "$@"; exit $?;;
  -*) run "$@"; exit $?;;
  *) echo "usage: shard-test.sh [run|times] ..."; exit 2;;
esac
