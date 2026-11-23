#!/usr/bin/env bash
# Ported from NamingPackageGrammarTests.StdSourcesHaveOnlyTheKnownNamingLintHits (spec 019 T27): user builds skip the standard library
# for BYN5104 to BYN5107 (Q1191); `bayan check` of each lib/std directory with a .byn file, compiled as an ordinary package where they
# run, has exactly the hits Q1191 exempts: std.json's `JsonReader` reads with `next` (BYN5106). A new hit, or an exemption that is
# gone, fails with the hit named.
# BAYAN_EXE: the self-hosted driver; unset, bootstrap/bayan.c is built with cc into tmp/. bash 3.2, no dotnet.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$root"
fail() { echo "FAIL $1"; exit 1; }
bayan="${BAYAN_EXE:-}"
if [ -z "$bayan" ]; then
  bayan="$root/tmp/std-naming-lints-bayan"
  cc -std=c11 -O2 -DBYN_NDEBUG -fwrapv -ffp-contract=off -w bootstrap/bayan.c bootstrap/bayan-rt.c -lm -o "$bayan" || fail "cannot build bootstrap/bayan.c"
fi
known="BYN5106 lib/std/json/reader.byn JsonReader"
n=0; hits=""
while IFS= read -r d; do
  ls "$d"/*.byn >/dev/null 2>&1 || continue
  n=$((n + 1))
  # `--diagnostics json` lines: code, file (absolute) and the name between the message's first backticks
  hits="$hits$("$bayan" check --diagnostics json "$d" 2>&1 | grep -E '^\{"code":"BYN510[4-7]"' \
    | sed -E 's/^\{"code":"([^"]*)".*"file":"([^"]*)".*"message":"[^`]*`([^`]*)`.*$/\1 \2 \3/' | sed "s# $root/# #" || true)
"
done < <(find lib/std -type d | LC_ALL=C sort)
[ "$n" -gt 0 ] || fail "no directory under lib/std holds a .byn file"
actual="$(printf '%s' "$hits" | grep -v '^$' | LC_ALL=C sort || true)"
[ "$actual" = "$known" ] || fail "std-sources-have-only-the-known-naming-lint-hits: expected [$known], found [$(tr '\n' ';' <<<"$actual")]"
# Ported from SelfhostStdImportTests.StdIsNotCheckedByTheNamingLints (spec 019 T26): the test's generated main.byn (MainSource, verbatim)
# replaces src/semantics/main.byn and runs its `lint-std` and `lint-user` cases over the test's fixture trees; a std module is not
# checked by the naming lints (no ` BYN510` line in `== path lint-std`), the same declarations in user code are (`diag BYN5104 `,
# `BYN5105 ` and `BYN5106 ` lines in `== path lint-user`).
t="$root/tmp/std-naming-lints-std-import"; rm -rf "$t"
mkdir -p "$t/src" "$t/cases/stds/lint/lint" "$t/cases/stds/probe/probe" "$t/cases/lint" "$t/cases/lintuser"
cp -R src/lexer src/parser src/semantics "$t/src/"
cat > "$t/src/semantics/main.byn" <<'EOF'
import lexer
import parser

i32 main(ReadOnlySpan<string> args) {
    var i: i64 = 0
    while i + 4 < args.length {
        let kind = args[i]
        let name = args[i + 1]
        let path = args[i + 2]
        let stdDir = args[i + 3]
        let flags = args[i + 4]
        print($"== {kind} {name}")
        var std = List<StdSource>()
        readStd(stdDir, at: "", to: ref std)
        var options = CompilationOptions { std: move std }
        if flags.contains("c") {
            var capabilities = List<string>()
            capabilities.append("net")
            options.capabilities = move capabilities
            options.packageName = "local/p"
        }
        if kind == "project" {
            let c = fromProject(path, for: "app", by: in options)
            dump(in c)
        } else {
            let c = fromPath(path, by: in options, wholeDirectory: flags.contains("w"))
            dump(in c)
        }
        i += 5
    }
    return 0
}

/// Every file under `dir`, its path under the std directory (`prefix` so far) and its text.
void readStd(string dir, at string prefix, to ref List<StdSource> std) {
    for name in t11ListFiles(dir) {
        let full = t11Combine(dir, by: name)
        let path = prefix.length == 0 ? name : $"{prefix}/{name}"
        if t11DirectoryExists(full) {
            readStd(full, at: path, to: ref std)
        } else {
            let bytes = t11ReadAllBytes(full)
            std.append(StdSource { path: path, text: $"{Utf8.decode(bytes.span, invalid: .replace)}" })
        }
    }
}

string diagLine(in Ctx c, for in Diag d) {
    let pos = linePosition(c.files[d.file].text.span, at: d.span.start)
    return $"diag {d.code} {c.files[d.file].displayPath} {pos.line}:{pos.column} {d.message} | {d.label} | {d.help}"
}

void dump(in Ctx c) {
    for m in c.moduleOrder {
        print($"module {c.modules[m].name} {c.modules[m].directory} {c.modules[m].cName}")
        for f in c.modules[m].files {
            print($"file {c.files[f].displayPath}")
            for (alias, imported) in c.files[f].imports { print($"import {alias} {c.modules[imported].name}") }
        }
    }
    for d in c.diagnostics { print(diagLine(in c, for: in d)) }
}
EOF
cat > "$t/cases/stds/lint/lint/lint.byn" <<'EOF'
public struct Line {
    public i64 grams
    public List<Line> line
    public i64 linesCount
}

public i64 total(List<Line> line) => line.length

public interface IOrder {
    List<Line> item
    i64 linesCount
    i64 weigh(List<Line> line)
}

public union Delivery {
    shipped(List<Line> item, i64 numBoxes)
}

public union error OrderError {
    rejected(List<Line> line)
}

public struct CsvParser {
    i64 n
}
EOF
cat > "$t/cases/stds/probe/probe/probe.byn" <<'EOF'
public string greet() {
    return "probe"
}

string hidden() {
    return "hidden"
}

public void save(string text) uses fs {
    Io.writeFile("probe.txt", text) catch { return }
}
EOF
printf 'test "t" {}\n' > "$t/cases/stds/probe/probe/probe.test.byn"
printf 'import std.lint\nprint("hi")\n' > "$t/cases/lint/main.byn"
cat > "$t/cases/lintuser/main.byn" <<'EOF'
public struct Line {
    public i64 grams
    public List<Line> line
    public i64 linesCount
}

public i64 total(List<Line> line) => line.length

public interface IOrder {
    List<Line> item
}

public union Delivery {
    shipped(List<Line> item, i64 numBoxes)
}

public union error OrderError {
    rejected(List<Line> line)
}

public struct CsvParser {
    i64 n
}
EOF
"$bayan" build --mode fast --package "$t/src" -o "$t/prog" "$t/src/semantics" >"$t/build.out" 2>&1 \
  || fail "std-is-not-checked-by-the-naming-lints: the semantics program did not build: $(head -c 500 "$t/build.out")"
"$t/prog" path lint-std "$t/cases/lint" "$t/cases/stds/lint" "" path lint-user "$t/cases/lintuser" "$t/cases/stds/probe" "" >"$t/stdout" \
  || fail "std-is-not-checked-by-the-naming-lints: the program exited nonzero"
section() { awk -v h="== $1" '$0 == h { on = 1; next } /^== / { on = 0 } on' "$t/stdout"; }
[ "$(grep -c '^== path lint-std$' "$t/stdout")" = 1 ] && [ "$(grep -c '^== path lint-user$' "$t/stdout")" = 1 ] \
  || fail "std-is-not-checked-by-the-naming-lints: sections not printed once: $(grep '^== ' "$t/stdout" | tr '\n' ';')"
! section "path lint-std" | grep -qF ' BYN510' || fail "std-is-not-checked-by-the-naming-lints: lint-std has [$(section "path lint-std" | grep -F ' BYN510' | tr '\n' ';')]"
for code in BYN5104 BYN5105 BYN5106; do
  section "path lint-user" | grep -q "^diag $code " || fail "std-is-not-checked-by-the-naming-lints: lint-user has no diag $code line"
done
echo "std-naming-lints: ok ($n directories, std-is-not-checked-by-the-naming-lints)"
