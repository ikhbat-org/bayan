#!/usr/bin/env bash
# Ported from SelfhostPathT7Tests.DirectoryNameOfRootPanicsWhereCSharpIsNull (spec 019 T26): the test's generated main.byn (MainSource,
# verbatim) replaces src/semantics/main.byn, the semantics program is built with src/lexer and src/parser, and `dirpanic / ""` makes
# t11DirectoryName panic on the root where .NET's Path.GetDirectoryName is null: nonzero exit, no `dirpanic` line on stdout, and
# `t11DirectoryName: no directory name` on stderr.
# BAYAN_EXE: the self-hosted driver; unset, bootstrap/bayan.c is built with cc into tmp/. bash 3.2, no dotnet.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
fail() { echo "FAIL $1"; exit 1; }
bayan="${BAYAN_EXE:-}"
if [ -z "$bayan" ]; then
  bayan="$root/tmp/selfhost-path-dirname-root-panic-bayan"
  cc -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off -w bootstrap/bayan.c bootstrap/bayan-rt.c -lm -o "$bayan" || fail "cannot build bootstrap/bayan.c"
fi
t="$root/tmp/selfhost-path-dirname-root-panic"; rm -rf "$t"; mkdir -p "$t/src"
cp -R src/lexer src/parser src/semantics "$t/src/"
cat > "$t/src/semantics/main.byn" <<'EOF'
i32 main(ReadOnlySpan<string> args) {
    print("== all")
    var i: i64 = 0
    while i + 2 < args.length {
        let kind = args[i]
        let a = args[i + 1]
        let b = args[i + 2]
        if kind == "dir" {
            print($"dir {a} {t11DirectoryName(a)}")
        } else if kind == "full" {
            print($"full {a} {t11FullPath(a)}")
        } else if kind == "combine" {
            print($"combine {a} {b} {t11Combine(a, by: b)}")
        } else if kind == "rel" {
            print($"rel {a} {b} {t11RelativePath(a, to: b)}")
        } else if kind == "relslash" {
            print($"relslash {a} {b} {t11RelativePath(a, to: b).replaced("\\", by: "/")}")
        } else if kind == "dirpanic" {
            print($"dirpanic {a} {t11DirectoryName(a)}")
        }
        i += 3
    }
    return 0
}
EOF
"$bayan" build --mode fast --package "$t/src" -o "$t/prog" "$t/src/semantics" >"$t/build.out" 2>&1 \
  || fail "the semantics program did not build: $(head -c 500 "$t/build.out")"
# Path.GetPathRoot of the test's base directory: / on POSIX
set +e
"$t/prog" dirpanic / "" >"$t/stdout" 2>"$t/stderr"
exit=$?
set -e
[ "$exit" -ne 0 ] || fail "directory-name-of-root-panics-where-csharp-is-null: exit 0, stdout [$(head -c 200 "$t/stdout")]"
! grep -qF dirpanic "$t/stdout" || fail "directory-name-of-root-panics-where-csharp-is-null: stdout has dirpanic: $(grep -F dirpanic "$t/stdout")"
grep -qF 't11DirectoryName: no directory name' "$t/stderr" \
  || fail "directory-name-of-root-panics-where-csharp-is-null: stderr lacks the panic: [$(head -c 300 "$t/stderr")]"
echo "selfhost-path-dirname-root-panic: ok (exit $exit)"
