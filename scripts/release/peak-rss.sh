#!/bin/sh
# The peak resident set of one process, for the bound test blocks of src/driver/bounds.byn (docs/memory-leaks.md rule 8),
# as the C# PeakSampler sampled it: the process alone, at start and then every 10 ms until it exits, and on Linux its
# own high-water mark (VmHWM, what PeakWorkingSet64 reads) as well.
#   peak-rss.sh <result> <dir> <command> [args...]
# Runs <command> in <dir>; its stdout and stderr pass through and its exit code is this script's. <result> gets one line,
# `<exit> <peak KB>`, the peak 0 when no sample was taken.
result="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"; dir="$2"; shift 2
pidf="$result.pid"; exitf="$result.exit"
rm -f "$pidf" "$exitf"
( cd "$dir" || { echo 127 > "$exitf"; exit; }; "$@" & echo $! > "$pidf"; wait $!; echo $? > "$exitf" ) &
peak=0
while [ ! -s "$exitf" ]; do
  if [ -s "$pidf" ]; then
    p=$(cat "$pidf")
    k=$(ps -o rss= -p "$p" 2>/dev/null | tr -d ' ')
    [ -n "$k" ] && [ "$k" -gt "$peak" ] && peak=$k
    h=$(awk '/^VmHWM:/ { print $2 }' "/proc/$p/status" 2>/dev/null)
    [ -n "$h" ] && [ "$h" -gt "$peak" ] && peak=$h
  fi
  sleep 0.01
done
wait
code=$(cat "$exitf")
echo "$code $peak" > "$result"
rm -f "$pidf" "$exitf"
exit "$code"
