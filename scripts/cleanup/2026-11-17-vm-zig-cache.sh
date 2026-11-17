#!/usr/bin/env bash
# Written 2026-11-17 during spec 024 R9: bayan-test01 hit "No space left on
# device" (117G disk, 3.3G free); zig's global cache held 70G under bt and
# 8.7G under bench. Zig rebuilds this cache on demand.
#
#   bash scripts/cleanup/2026-11-17-vm-zig-cache.sh                                  # dry run
#   bash scripts/cleanup/2026-11-17-vm-zig-cache.sh --execute --delete-zig-cache     # act
#
# Starts bayan-test01 if stopped, waits for its agent, and stops it at the end.
set -euo pipefail

execute=0 delete=0
for a in "$@"; do
    case $a in
        -e|--execute) execute=1 ;;
        --delete-zig-cache) delete=1 ;;
        *) printf 'unknown argument: %s\n' "$a" >&2; exit 2 ;;
    esac
done

host=ghosthive vm=bayan-test01
targets=(/home/bt/.cache/zig /home/bench/.cache/zig)
failed=0

# 1. Gate: the host must answer and the VM must exist.
state=$(ssh "$host" incus list "$vm" -c s -f csv) || { echo "refuse: cannot reach $host"; exit 1; }
[ -n "$state" ] || { echo "refuse: $vm does not exist on $host"; exit 1; }
echo "$vm is $state"

if [ "$state" != RUNNING ]; then
    if [ $execute -eq 0 ]; then
        echo "dry run: $vm is not running; would start it, measure, delete, then stop it"
        for t in "${targets[@]}"; do echo "would delete: $t"; done
        exit 0
    fi
    ssh "$host" incus start "$vm"
fi
# The VM agent comes up some seconds after start; wait up to 3 minutes.
for _ in $(seq 1 36); do
    ssh "$host" incus exec "$vm" -- true 2>/dev/null && break
    sleep 5
done
ssh "$host" incus exec "$vm" -- true || { echo "refuse: $vm agent did not come up"; exit 1; }

# 2. Sizes before.
ssh "$host" incus exec "$vm" -- df -h /
for t in "${targets[@]}"; do
    if ssh "$host" incus exec "$vm" -- test -d "$t"; then
        ssh "$host" incus exec "$vm" -- du -sh "$t"
    else
        echo "skip:  $t is already gone"
    fi
done

# 3. Delete (needs both flags).
if [ $execute -eq 1 ] && [ $delete -eq 1 ]; then
    for t in "${targets[@]}"; do
        ssh "$host" incus exec "$vm" -- test -d "$t" || continue
        if ssh "$host" incus exec "$vm" -- rm -rf -- "$t"; then
            echo "deleted: $t"
        else
            echo "failed:  $t"; failed=1
        fi
    done
elif [ $execute -eq 1 ]; then
    echo "--execute without --delete-zig-cache: nothing deleted"
fi

# 4. State after.
ssh "$host" incus exec "$vm" -- df -h /
if [ $execute -eq 1 ]; then ssh "$host" incus stop "$vm"; echo "$vm stopped (it stays stopped between jobs)"; fi
if [ $execute -eq 1 ] && [ $failed -eq 1 ]; then exit 1; fi
exit 0
