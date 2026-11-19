#!/usr/bin/env bash
# scripts/dist.sh with a fake bootstrap build and compiler: layout per target and version, latest replaced on each build, --from import, refusals,
# and bayan-lsp beside bayan in every build, built by the same compiler (spec 019 R37).
set -uo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
t="$root/tmp/dist-test-$$"
mkdir -p "$t/bin"
trap 'rm -rf "$t"' EXIT
fail=0
check() { if [ "$2" = "$3" ]; then echo "ok: $1"; else echo "FAIL: $1: got '$2', want '$3'"; fail=1; fi; }
d="$t/dist"
# a scratch checkout: dist.sh, release/version.sh, VERSION, and a fake scripts/bootstrap-build.sh printing a fake compiler. The fake
# compiler takes `build --mode safe --package src [--target <t>] -o <exe> src/driver` and writes "<target|host> $FAKE_BUILD", and
# `build --package editors/language-server/src [--target <t>] -o <exe> editors/language-server/src/app` writes "lsp <target|host> $FAKE_BUILD"
# (FAKE_LSPFAIL=1: that build fails).
g="$t/repo"; mkdir -p "$g/scripts/release" "$g/src/driver" "$g/editors/language-server/src/app"
cp "$root/scripts/dist.sh" "$g/scripts/"; cp "$root/scripts/release/version.sh" "$g/scripts/release/"; cp "$root/VERSION" "$g/"
echo tmp/ > "$g/.gitignore"
touch "$g/src/driver/main.bn" "$g/editors/language-server/src/app/main.bn"
cat > "$g/scripts/bootstrap-build.sh" <<'FAKE'
#!/usr/bin/env bash
[ "${FAKE_BOOT_FAIL:-}" = 1 ] && exit 1
[ "${FAKE_BOOT_MARK:-}" = "" ] || echo x >> "$FAKE_BOOT_MARK"
[ "$1" = --out ] && [ -n "$2" ] || exit 2
mkdir -p "$2"; cp "$FAKE_COMPILER" "$2/bayan-stage1"; echo "$2/bayan-stage1"
FAKE
cat > "$t/compiler" <<'FAKE'
#!/usr/bin/env bash
if [ "$1 $2 $3" = "build --package editors/language-server/src" ]; then
  shift 3; target=host
  while [ $# -gt 0 ]; do case "$1" in --target) target=$2; shift 2 ;; -o) out=$2; shift 2 ;; *) last=$1; shift ;; esac; done
  [ "$last" = editors/language-server/src/app ] && [ -d editors/language-server/src/app ] || exit 4
  [ "${FAKE_LSPFAIL:-}" = 1 ] && exit 1
  echo "lsp $target ${FAKE_BUILD:-1}" > "$out"; exit 0
fi
[ "$1 $2 $3 $4 $5" = "build --mode safe --package src" ] || exit 3
shift 5; target=host
while [ $# -gt 0 ]; do case "$1" in --target) target=$2; shift 2 ;; -o) out=$2; shift 2 ;; *) last=$1; shift ;; esac; done
[ "$last" = src/driver ] && [ -d src/driver ] || exit 4
[ -n "${FAKE_RMDIR:-}" ] && rmdir "$FAKE_RMDIR" && exit 1
[ "${FAKE_FAIL:-}" = 1 ] && exit 1
[ "${FAKE_NOWRITE:-}" = 1 ] && exit 0
echo "$target ${FAKE_BUILD:-1}" > "$out"
touch "${FAKE_MARK:-/dev/null}"
FAKE
chmod +x "$t/compiler" "$g/scripts/bootstrap-build.sh"
git -C "$g" init -q && git -C "$g" add -A && GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t git -C "$g" -c core.hooksPath=/dev/null commit -qm "test: fixture"
check "scratch repo committed" "$(git -C "$g" rev-list --count HEAD 2>/dev/null)" 1
export FAKE_COMPILER="$t/compiler"
run() { bash "$g/scripts/dist.sh" --dist "$d" "$@"; }
# what the fake compiler writes for <rid> <n>: the host rid is built without --target, any other with the release target name
case "$(uname -s)-$(uname -m)" in Darwin-arm64) hrid=osx-arm64 ;; Darwin-x86_64) hrid=osx-x64 ;; Linux-aarch64|Linux-arm64) hrid=linux-arm64 ;; Linux-x86_64) hrid=linux-x64 ;; *) hrid=none ;; esac
want() { local tg=$1; case "$1" in osx-*) tg=macos-${1#osx-} ;; win-*) tg=windows-${1#win-} ;; esac; [ "$1" = "$hrid" ] && tg=host; echo "$tg $2"; }

out=$(FAKE_BUILD=1 run --rid osx-arm64 --label 1.0.0 2>/dev/null); check "first build exits 0" "$?" 0
check "prints the binary path" "$out" "$d/macos-arm64/1.0.0/bayan"
check "version dir binary" "$(cat "$d/macos-arm64/1.0.0/bayan")" "$(want osx-arm64 1)"
check "latest binary" "$(cat "$d/macos-arm64/latest/bayan")" "$(want osx-arm64 1)"
check "binary executable" "$([ -x "$d/macos-arm64/1.0.0/bayan" ] && echo y)" y
check "bayan-lsp beside bayan" "$(cat "$d/macos-arm64/1.0.0/bayan-lsp")" "lsp $(want osx-arm64 1)"
check "latest bayan-lsp" "$(cat "$d/macos-arm64/latest/bayan-lsp")" "lsp $(want osx-arm64 1)"
check "bayan-lsp executable" "$([ -x "$d/macos-arm64/1.0.0/bayan-lsp" ] && echo y)" y
check "BUILD-INFO lsp built" "$(grep '^lsp ' "$d/macos-arm64/1.0.0/BUILD-INFO")" "lsp built"
check "BUILD-INFO version" "$(grep '^version ' "$d/macos-arm64/latest/BUILD-INFO")" "version 1.0.0"
check "BUILD-INFO rid" "$(grep '^rid ' "$d/macos-arm64/1.0.0/BUILD-INFO")" "rid osx-arm64"

FAKE_BUILD=2 run --rid osx-arm64 --label 1.1.0 >/dev/null 2>&1
check "older version kept" "$(cat "$d/macos-arm64/1.0.0/bayan")" "$(want osx-arm64 1)"
check "new version dir" "$(cat "$d/macos-arm64/1.1.0/bayan")" "$(want osx-arm64 2)"
check "latest replaced by the newest build" "$(cat "$d/macos-arm64/latest/bayan")" "$(want osx-arm64 2)"
check "latest bayan-lsp replaced" "$(cat "$d/macos-arm64/latest/bayan-lsp")" "lsp $(want osx-arm64 2)"
check "latest BUILD-INFO replaced" "$(grep '^version ' "$d/macos-arm64/latest/BUILD-INFO")" "version 1.1.0"
check "no staging dir left" "$(ls -A "$d/macos-arm64" | tr '\n' ' ')" "1.0.0 1.1.0 latest "

FAKE_BUILD=3 run --rid win-x64 --rid linux-arm64 --label 1.1.0 >/dev/null 2>&1
check "windows target name and exe" "$(cat "$d/windows-x64/latest/bayan.exe")" "$(want win-x64 3)"
check "windows bayan-lsp.exe" "$(cat "$d/windows-x64/latest/bayan-lsp.exe")" "lsp $(want win-x64 3)"
check "linux bayan-lsp" "$(cat "$d/linux-arm64/1.1.0/bayan-lsp")" "lsp $(want linux-arm64 3)"
check "linux target" "$(cat "$d/linux-arm64/1.1.0/bayan")" "$(want linux-arm64 3)"
check "other targets untouched" "$(cat "$d/macos-arm64/latest/bayan")" "$(want osx-arm64 2)"

mkdir -p "$t/pub"; echo imported > "$t/pub/bayan.exe"
# an imported bayan.exe with no bayan-lsp.exe beside it: a warning and BUILD-INFO `lsp none`
err=$(run --from "$t/pub" --rid win-x64 --label 1.1.9 2>&1); check "--from without bayan-lsp exits 0" "$?" 0
check "--from without bayan-lsp warns" "$(echo "$err" | grep -c "^dist: warning: $t/pub has no bayan-lsp.exe")" 1
check "--from without bayan-lsp ships none" "$([ -e "$d/windows-x64/1.1.9/bayan-lsp.exe" ] && echo y || echo n)" n
check "--from without bayan-lsp BUILD-INFO" "$(grep '^lsp ' "$d/windows-x64/1.1.9/BUILD-INFO")" "lsp none"
echo imported-lsp > "$t/pub/bayan-lsp.exe"
run --from "$t/pub" --rid win-x64 --label 1.2.0 >/dev/null 2>&1; check "--from exits 0" "$?" 0
check "--from bayan-lsp BUILD-INFO" "$(grep '^lsp ' "$d/windows-x64/1.2.0/BUILD-INFO")" "lsp imported"
check "--from imported bayan-lsp" "$(cat "$d/windows-x64/latest/bayan-lsp.exe")" imported-lsp
check "--from imported" "$(cat "$d/windows-x64/latest/bayan.exe")" imported
check "--from source recorded" "$(grep '^source ' "$d/windows-x64/1.2.0/BUILD-INFO")" "source $t/pub"
check "--from commit unknown without --commit" "$(grep '^commit ' "$d/windows-x64/1.2.0/BUILD-INFO")" "commit unknown"
run --from "$t/pub" --rid win-x64 --label 1.2.1 --commit abc123 >/dev/null 2>&1
check "--commit recorded" "$(grep '^commit ' "$d/windows-x64/1.2.1/BUILD-INFO")" "commit abc123"
check "host build records this checkout" "$(grep '^commit ' "$d/macos-arm64/1.0.0/BUILD-INFO")" "commit $(git -C "$g" rev-parse HEAD)"

FAKE_FAIL=1 run --rid osx-arm64 --label 2.0.0 >/dev/null 2>&1; check "failed build exits 1" "$?" 1
check "failed publish leaves latest" "$(cat "$d/macos-arm64/latest/bayan")" "$(want osx-arm64 2)"
check "failed publish makes no version dir" "$([ -e "$d/macos-arm64/2.0.0" ] && echo y || echo n)" n
err=$(FAKE_LSPFAIL=1 run --rid osx-arm64 --label 2.0.1 2>&1); check "failed bayan-lsp build exits 1" "$?" 1
check "failed bayan-lsp build says where" "$(echo "$err" | grep -c '^dist: building bayan-lsp for osx-arm64 failed, see tmp/dist-lsp-osx-arm64.log')" 1
check "failed bayan-lsp build leaves latest" "$(cat "$d/macos-arm64/latest/bayan-lsp")" "lsp $(want osx-arm64 2)"
check "failed bayan-lsp build makes no version dir" "$([ -e "$d/macos-arm64/2.0.1" ] && echo y || echo n)" n

err=$(run --rid sparc-x64 --label 1.0.0 2>&1); check "unknown rid exits 1" "$?" 1
check "unknown rid message" "$err" "dist: unknown rid sparc-x64"
run --rid osx-arm64 --label latest >/dev/null 2>&1; check "label 'latest' refused" "$?" 1
run --rid osx-arm64 --label ../x >/dev/null 2>&1; check "label with / refused" "$?" 1
run --from "$t/pub" >/dev/null 2>&1; check "--from without --rid refused" "$?" 1
run --bogus >/dev/null 2>&1; check "unknown argument refused" "$?" 1

lbl=$(FAKE_BUILD=4 run 2>/dev/null); check "host build exits 0" "$?" 0
check "default label is VERSION(+commit)(.dirty)" "$(echo "$lbl" | grep -cE "/$(cat "$g/VERSION")\+[0-9a-f]{12}(\.dirty)?/bayan(\.exe)?\$")" 1
printf '7.8.9\n' > "$g/VERSION"; lbl=$(FAKE_BUILD=4 run 2>/dev/null); git -C "$g" checkout -q -- VERSION
check "the label follows VERSION" "$(echo "$lbl" | grep -cE '/7\.8\.9\.dirty/bayan(\.exe)?$')" 1
prev="$(cat "$d/macos-arm64/latest/bayan")" prevv="$(grep '^version ' "$d/macos-arm64/latest/BUILD-INFO")"
mkdir "$d/macos-arm64/.lock"
FAKE_MARK="$t/published" FAKE_BUILD=5 run --rid osx-arm64 --label 3.0.0 >/dev/null 2>&1; check "held lock exits 1" "$?" 1
check "held lock refuses before publishing" "$([ -e "$t/published" ] && echo y || echo n)" n
check "held lock leaves latest" "$(cat "$d/macos-arm64/latest/bayan")" "$prev"
check "held lock makes no version dir" "$([ -e "$d/macos-arm64/3.0.0" ] && echo y || echo n)" n
rmdir "$d/macos-arm64/.lock"

# a mv that cannot move latest aside, as Windows refuses for a folder holding a running bayan.exe
mkdir -p "$t/nomv"
printf '#!/usr/bin/env bash\ncase "$1" in */latest) exit 1 ;; esac\nexec /bin/mv "$@"\n' > "$t/nomv/mv"; chmod +x "$t/nomv/mv"
PATH="$t/nomv:$PATH" FAKE_BUILD=6 run --rid osx-arm64 --label 3.1.0 >/dev/null 2>&1; check "latest in use exits 1" "$?" 1
check "latest in use is unchanged" "$(cat "$d/macos-arm64/latest/bayan")" "$prev"
check "latest in use keeps its BUILD-INFO" "$(grep '^version ' "$d/macos-arm64/latest/BUILD-INFO")" "$prevv"
check "latest in use leaves no staging or lock" "$(ls -A "$d/macos-arm64" | grep -c '^\.')" 0

mkdir -p "$d/macos-arm64/.latest-old/sub"; touch "$d/macos-arm64/.latest-old/sub/f"; chmod 500 "$d/macos-arm64/.latest-old/sub"
err=$(FAKE_BUILD=7 run --rid osx-arm64 --label 3.2.0 2>&1); check "uncleanable .latest-old exits 1" "$?" 1
check "uncleanable .latest-old says why" "$(echo "$err" | grep -c '^dist: cannot clear')" 1
chmod 700 "$d/macos-arm64/.latest-old/sub"
check "--help ends with the BUILD-INFO lsp line" "$(bash "$g/scripts/dist.sh" --help | tail -1 | grep -c 'BUILD-INFO `lsp`')" 1

err=$(run --rid osx-arm64 --label .latest-next 2>&1); check "label starting with . refused" "$err" "dist: bad version label '.latest-next'"
run --rid osx-arm64 --label "1.0 x" >/dev/null 2>&1; check "label with a space refused" "$?" 1
err=$(bash "$g/scripts/dist.sh" --dist "" --rid osx-arm64 --label 1.0.0 2>&1); check "empty --dist refused" "$err" "dist: --dist needs a directory"

# .dirty counts untracked files outside tmp/ (the scratch repo ignores tmp/)
grun() { bash "$g/scripts/dist.sh" --dist "$t/gdist" --rid osx-arm64 2>/dev/null; }
check "clean scratch repo has no .dirty" "$(grun | grep -c '\.dirty/')" 0
touch "$g/notes.txt"
check "untracked file outside src/ is dirty" "$(grun | grep -c '\.dirty/')" 1


# a publish that succeeds without writing a binary must not pick up the previous run's from tmp/dist-publish/<rid>
FAKE_NOWRITE=1 run --rid osx-arm64 --label 4.0.0 >/dev/null 2>&1; check "publish without a binary exits 1" "$?" 1
check "publish without a binary makes no version dir" "$([ -e "$d/macos-arm64/4.0.0" ] && echo y || echo n)" n
touch "$t/afile"
err=$(bash "$g/scripts/dist.sh" --dist "$t/afile" --rid osx-arm64 --label 1.0.0 2>&1); check "--dist on a file exits 1" "$?" 1
check "--dist on a file says why" "$err" "dist: cannot create $t/afile/macos-arm64"
mkdir -p "$g/tmp/dist-publish.lock"
FAKE_MARK="$t/gpublished" grun >/dev/null; check "held publish lock exits 1" "$?" 1
check "held publish lock refuses before publishing" "$([ -e "$t/gpublished" ] && echo y || echo n)" n
check "held publish lock frees the target lock" "$([ -e "$t/gdist/macos-arm64/.lock" ] && echo y || echo n)" n
rmdir "$g/tmp/dist-publish.lock"
grun >/dev/null; check "publish lock released after a run" "$([ -e "$g/tmp/dist-publish.lock" ] && echo y || echo n)" n

FAKE_RMDIR="$g/tmp/dist-publish.lock" grun >/dev/null; check "publish lock removed mid-run exits 1" "$?" 1
check "publish lock removed mid-run still frees the target lock" "$([ -e "$t/gdist/macos-arm64/.lock" ] && echo y || echo n)" n

# spec 019 R25: the compiler is built once per run by bootstrap-build.sh, each rid is built from src/ with --target unless it is the host
FAKE_BOOT_MARK="$t/boots" run --rid linux-x64 --rid win-x64 --rid osx-x64 --label 5.0.0 >/dev/null
check "one bootstrap build for three rids" "$(wc -l < "$t/boots" | tr -d ' ')" 1
check "cross-built linux target name" "$(cat "$d/linux-x64/5.0.0/bayan")" "$(want linux-x64 1)"
check "cross-built windows target name" "$(cat "$d/windows-x64/5.0.0/bayan.exe")" "$(want win-x64 1)"
check "cross-built macos target name" "$(cat "$d/macos-x64/5.0.0/bayan")" "$(want osx-x64 1)"
check "cross-built bayan-lsp target name" "$(cat "$d/windows-x64/5.0.0/bayan-lsp.exe")" "lsp $(want win-x64 1)"
check "BUILD-INFO source is the bootstrap build" "$(grep '^source ' "$d/linux-x64/5.0.0/BUILD-INFO")" "source bootstrap build"
check "BUILD-INFO never says dotnet" "$(grep -ci dotnet "$d/linux-x64/5.0.0/BUILD-INFO")" 0
FAKE_BOOT_FAIL=1 run --rid linux-x64 --label 5.1.0 >/dev/null 2>&1; check "failed bootstrap exits 1" "$?" 1
check "failed bootstrap makes no version dir" "$([ -e "$d/linux-x64/5.1.0" ] && echo y || echo n)" n
check "failed bootstrap frees the build lock" "$([ -e "$g/tmp/dist-publish.lock" ] && echo y || echo n)" n
check "dist.sh has no dotnet" "$(grep -ci dotnet "$root/scripts/dist.sh")" 0
exit $fail
