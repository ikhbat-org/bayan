#!/bin/sh
# A C compiler wrapper for BAYAN_CC (plan 020 steps 1-2): runs $HARDEN_CC (default cc, split on spaces) with the arguments it was
# given, minus each argument that equals one of $HARDEN_STRIP exactly (stripping -w keeps -Wall), plus $HARDEN_CFLAGS on every call
# and $HARDEN_COMPILE_ONLY only on a call with -c (the driver compiles the runtime with -c and links main.c separately). The extra
# flags go after the given ones, so they win where the compiler takes the last. `--version` adds a `cc-wrap:` line naming the extra
# and stripped flags, so the driver's compiler identity differs per flag set. The real compiler's exit status is passed through.
set -f
real=${HARDEN_CC:-cc}

compile=0
version=0
for a in "$@"; do
    [ "$a" = -c ] && compile=1
    [ "$a" = --version ] && version=1
done

n=$#
i=0
while [ $i -lt $n ]; do
    a=$1
    shift
    i=$((i + 1))
    drop=0
    for s in $HARDEN_STRIP; do
        [ "$a" = "$s" ] && drop=1
    done
    [ $drop = 1 ] || set -- "$@" "$a"
done

if [ $version = 1 ]; then
    $real "$@"
    rc=$?
    echo "cc-wrap: extra=${HARDEN_CFLAGS} compile-only=${HARDEN_COMPILE_ONLY} strip=${HARDEN_STRIP}"
    exit $rc
fi

if [ $compile = 1 ]; then
    exec $real "$@" $HARDEN_CFLAGS $HARDEN_COMPILE_ONLY
fi
exec $real "$@" $HARDEN_CFLAGS
