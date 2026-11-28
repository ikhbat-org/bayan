#!/bin/bash
# wp1-test.sh on a fixture repo under tmp/, with a fake scp and ssh on PATH that record their arguments (never wp1 itself): the bundle
# goes to wp1's tmp/, ssh clones it into the short-sha directory and runs bootstrap-build.sh then scripts/test.sh --only <part>
# (no dotnet); tmp/wp1/<sha>.out holds the header, the output and `exit <code>`; a run without `test: all passed` fails, a remote
# failure keeps its code, and a failed scp skips ssh.
# Then pwsh runs the remote command on a local stand-in for wp1's tmp/: a re-run replaces its own clone, never another directory.
set -e
root="$(cd "$(dirname "$0")/../.." && pwd)"
r="$root/tmp/wp1-test-test"; aux="$root/tmp/wp1-test-test-aux"
rm -rf "$r" "$aux" && mkdir -p "$r" "$aux/bin" && cd "$r"
git init -q -b base && git config user.email t@t && git config user.name t
printf 'tmp/\n' > .gitignore; printf 'x\n' > a.txt; git add -A && git commit -qm "test: base"
git branch feat/x
printf '#!/bin/bash\necho "$*" > "$AUX/scp-args"; [ -f "$AUX/scp-fail" ] && { echo "scp: lost"; exit 3; }; exit 0\n' > "$aux/bin/scp"
printf '#!/bin/bash\ncase "$2" in powercfg*) echo "$*" >> "$AUX/ssh-power"; exit 0;; esac\necho "$*" > "$AUX/ssh-args"; cat "$AUX/ssh-out"; exit "$(cat "$AUX/ssh-rc")"\n' > "$aux/bin/ssh"
chmod +x "$aux/bin/scp" "$aux/bin/ssh"; export AUX=$aux
w() { [ -n "${CACHE_KEEP:-}" ] || rm -rf tmp/wp1/cache; PATH="$aux/bin:$PATH" /bin/bash "$root/scripts/selfhost/wp1-test.sh" "$@" 2>&1 && echo "rc=0" || echo "rc=$?"; }
sha=$(git rev-parse feat/x); tree=$(git rev-parse 'feat/x^{tree}'); s=${sha:0:8}; R=C:/home/code/extrode.com/bayan/tmp
F=golden
printf 'test: all passed\n' > "$aux/ssh-out"; echo 0 > "$aux/ssh-rc"
good=$(w feat/x "$F"); gout=$(cat "tmp/wp1/$sha.out"); scpa=$(cat "$aux/scp-args"); ssha=$(cat "$aux/ssh-args")
bundled=$(git bundle list-heads "tmp/wp1/$s.bundle")
# a passing run is cached by tree + filter: the same again reuses it (no ssh), another filter runs, a failed run is not cached
rm "$aux/ssh-args"; hit=$(CACHE_KEEP=1 w feat/x "$F"); hout=$(cat "tmp/wp1/$sha.out"); [ ! -f "$aux/ssh-args" ] && nossh2=1 || nossh2=0
git branch feat/y feat/x; hity=$(CACHE_KEEP=1 w feat/y "$F")
rm -f "$aux/ssh-args"; CACHE_KEEP=1 w feat/x bayan > /dev/null; [ -f "$aux/ssh-args" ] && other=1 || other=0
: > "$aux/ssh-out"; none=$(w feat/x "$F"); nout=$(cat "tmp/wp1/$sha.out")
printf 'test: FAILED golden\n' > "$aux/ssh-out"; echo 1 > "$aux/ssh-rc"; red=$(w feat/x "$F"); rout=$(cat "tmp/wp1/$sha.out"); [ -z "$(ls tmp/wp1/cache)" ] && rednc=1 || rednc=0
rm "$aux/ssh-args"; touch "$aux/scp-fail"; lost=$(w feat/x "$F"); lout=$(cat "tmp/wp1/$sha.out"); [ ! -f "$aux/ssh-args" ] && noss=1 || noss=0
usage=$(w feat/x); nobr=$(w feat/none "$F"); quote=$(w feat/x "A'B")
# WIN_HOST=wlt1 writes only under tmp/wlt1/ and puts zig on PATH first; WIN_THREADS adds --jobs; a bad WIN_THREADS is refused
rm -f "$aux/scp-fail"; printf 'test: all passed\n' > "$aux/ssh-out"; echo 0 > "$aux/ssh-rc"
w1=$(cat "tmp/wp1/$sha.out"); wl=$(WIN_HOST=wlt1 WIN_THREADS=2 w feat/x "$F"); wla=$(cat "$aux/ssh-args")
[ "$(cat "tmp/wp1/$sha.out")" = "$w1" ] && [ -f "tmp/wlt1/$sha.out" ] && [ -f "tmp/wlt1/$s.bundle" ] && [ -n "$(ls tmp/wlt1/cache)" ] && wlown=1 || wlown=0
badth=$(WIN_THREADS=x w feat/x "$F")
w feat/x "$F" > /dev/null; rm -f "$aux/ssh-args"; tmo=$(CACHE_KEEP=1 BAYAN_TEST_TIMEOUT_MS=90000 w feat/x "$F"); tmoa=$(cat "$aux/ssh-args" 2>/dev/null || true)
badtmo=$(BAYAN_TEST_TIMEOUT_MS=9s w feat/x "$F")
# wlt1 runs under its Performance plan and goes back to Balanced after; wp1 and an empty WIN_PERF_SCHEME never switch; a live holder
# keeps the plan (no switch back); a scheme with a quote is refused
rm -f "$aux/ssh-power"; WIN_HOST=wlt1 w feat/x scripts > /dev/null; pwl=$(cat "$aux/ssh-power" 2>/dev/null || true)
rm -f "$aux/ssh-power"; nr1=$(w feat/x runtime); nr2=$(WIN_HOST=wlt1 WIN_PERF_SCHEME= w feat/x parity); pwnone=$(cat "$aux/ssh-power" 2>/dev/null || true)
rm -f "$aux/ssh-power"; mkdir -p tmp/wlt1/perf-holders; : > "tmp/wlt1/perf-holders/$$"; : > tmp/wlt1/perf-holders/999999
rm -rf tmp/wlt1/cache; WIN_HOST=wlt1 w feat/x scripts > /dev/null; pwheld=$(cat "$aux/ssh-power" 2>/dev/null || true); [ ! -e tmp/wlt1/perf-holders/999999 ] && pruned=1 || pruned=0
rm -rf tmp/wlt1/perf-holders tmp/wlt1/cache; badps=$(WIN_PERF_SCHEME="a'b" w feat/x "$F")
# a holder past 12 h is dropped even with a live pid, a dotfile is no holder; a run from a linked worktree sees the main checkout's holders
rm -f "$aux/ssh-power"; mkdir -p tmp/wlt1/perf-holders; : > tmp/wlt1/perf-holders/.DS_Store; : > "tmp/wlt1/perf-holders/$$"; touch -t 202001010000 "tmp/wlt1/perf-holders/$$"
rm -rf tmp/wlt1/cache; WIN_HOST=wlt1 w feat/x scripts > /dev/null; pwstale=$(cat "$aux/ssh-power" 2>/dev/null || true)
rm -f "$aux/ssh-power"; : > "tmp/wlt1/perf-holders/$$"; git worktree add -q "$aux/wt" -b feat/wt feat/x; cd "$aux/wt"
WIN_HOST=wlt1 w feat/wt scripts > /dev/null; pwwt=$(cat "$aux/ssh-power" 2>/dev/null || true); cd "$r"
rm -rf tmp/wlt1/perf-holders; [ -n "$(ls tmp/wlt1/cache)" ] && seeded=1 || seeded=0; badpsc=$(CACHE_KEEP=1 WIN_HOST=wlt1 WIN_PERF_SCHEME="a'b" w feat/x scripts)
# the remote command itself, run by pwsh with wp1's tmp/ at $aux/remote and a fake Git Bash (WIN_BASH): a re-run replaces the clone it made,
# a directory it did not make is left alone (exit 3)
rm -f "$aux/scp-fail"; mkdir "$aux/remote"; printf 'test: all passed\n' > "$aux/ssh-out"
cat > "$aux/bin/scp" <<'EOF'
#!/bin/bash
cp "$2" "$AUX/remote/"
EOF
cat > "$aux/bin/ssh" <<'EOF'
#!/bin/bash
case "$1" in powercfg*) exit 0;; esac; case "$2" in powercfg*) exit 0;; esac
R=C:/home/code/extrode.com/bayan/tmp; c=${2//"$R"/$AUX/remote}
exec pwsh -NoProfile -NonInteractive -Command "$c"
EOF
cat > "$aux/bin/fakebash" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "$AUX/bash-args"; cat "$AUX/ssh-out"
EOF
chmod +x "$aux/bin/fakebash"; export WIN_BASH=$aux/bin/fakebash
first=$(w feat/x "$F"); [ -f "$aux/remote/$s/a.txt" ] && [ -f "$aux/remote/$s.wp1-test" ] && cloned=1 || cloned=0
touch "$aux/remote/$s/stale"; again=$(w feat/x "$F"); [ -f "$aux/remote/$s/a.txt" ] && [ ! -e "$aux/remote/$s/stale" ] && replaced=1 || replaced=0
# pwsh hands the bash script to Git Bash as one -c argument, after the zig PATH line ran
pw=$(WIN_HOST=wlt1 WIN_THREADS=3 w feat/x bayan); dargs=$(tr '\n' ' ' < "$aux/bash-args")
# WIN_CC sets CC in Git Bash (quoted through PowerShell); unset, CC is unset there; a WIN_CC with a quote or ; is refused
pwc=$(WIN_CC='zig cc' w feat/x runtime); dargsc=$(tr '\n' ' ' < "$aux/bash-args"); badcc=$(WIN_CC='a;b' w feat/x "$F")
rm "$aux/remote/$s.wp1-test"; touch "$aux/remote/$s/stale"; foreign=$(w feat/x "$F"); [ -e "$aux/remote/$s/stale" ] && kept=1 || kept=0
# a commit landing on the branch between the sha lookup and the bundle: the remote clone is not the sha, so the run exits 4
realgit=$(command -v git)
printf '#!/bin/bash\nif [ "$1" = bundle ]; then n=$(%s commit-tree -p feat/x -m moved "feat/x^{tree}"); %s update-ref refs/heads/feat/x "$n"; fi\nexec %s "$@"\n' "$realgit" "$realgit" "$realgit" > "$aux/bin/git"; chmod +x "$aux/bin/git"
rm -rf "$aux/remote/$s"; moved=$(w feat/x "$F"); mout=$(cat "tmp/wp1/$sha.out")
cd "$root"; rm -rf "$r" "$aux"
fail() { echo "FAIL: $1"; echo "$2"; exit 1; }
has() { grep -qxF -- "$2" <<< "$1"; }
[ "$scpa" = "-q tmp/wp1/$s.bundle wp1:/$R/" ] || fail "scp ran '$scpa'" "$good"
CMD=${ssha#wp1 }
for p in "Set-Location '$R';" "git clone -q -b feat/x $s.bundle $s;" "Set-Location '$s'; if ((git rev-parse HEAD) -ne '$sha') { Write-Output 'wp1-test: feat/x moved after $sha was resolved; the clone is not $sha'; exit 4 }; \$env:BAYAN_TEST_TIME_SCALE = '3'; \$env:BAYAN_TEST_TIMEOUT_MS = '300000'; & 'C:\\home\\apps\\Git\\bin\\bash.exe' -c 'unset CC; exe=\$(bash scripts/bootstrap-build.sh) || exit 1; BAYAN_EXE=\$exe bash scripts/test.sh --only $F'; exit \$LASTEXITCODE"; do
  [[ $ssha == "wp1 "*"$p"* ]] || fail "ssh ran '$ssha', without '$p'" "$good"; done
grep -q "^$sha refs/heads/feat/x$" <<< "$bundled" || fail "the bundle does not hold feat/x" "$bundled"
[ "$(head -4 <<< "$gout")" = "$(printf 'branch: feat/x\nsha: %s\nfilter: %s\ncommand: ssh wp1 "%s"' "$sha" "$F" "$CMD")" ] || fail "the .out header is wrong" "$gout"
[ "$(tail -2 <<< "$gout")" = "$(printf 'test: all passed\nexit 0')" ] || fail "the .out does not end in the output and 'exit 0'" "$gout"
has "$good" "rc=0" || fail "a passing run failed" "$good"
cres="tmp/wp1/cache/$tree-$(printf '%s' "$F" | shasum | cut -c1-16).out"
has "$hit" "rc=0" && [ $nossh2 = 1 ] && grep -qF "reusing the cached result $cres (run for $sha), wp1 not run" <<< "$hit" && [ "$(head -1 <<< "$hout")" = "cached: $cres" ] && [ "$(tail -1 <<< "$hout")" = "exit 0" ] || fail "a passing run was not reused for the same tree and filter" "$hit"
grep -qF "reusing the cached result $cres" <<< "$hity" || fail "the same tree on another branch did not hit the cache" "$hity"
[ $other = 1 ] || fail "a different filter reused the cache" "$hit"
[ $rednc = 1 ] || fail "a failed run was cached" "$red"
has "$none" "wp1-test: the run did not report 'test: all passed' (tmp/wp1/$sha.out)" && has "$none" "rc=1" && [ "$(tail -1 <<< "$nout")" = "exit 0" ] || fail "a run without 'test: all passed' passed" "$none"
has "$red" "rc=1" && [ "$(tail -1 <<< "$rout")" = "exit 1" ] || fail "a remote failure did not keep its code" "$red"
has "$lost" "rc=3" && [ "$(tail -2 <<< "$lout")" = "$(printf 'scp: lost\nexit 3')" ] && [ $noss = 1 ] || fail "a failed scp did not stop before ssh" "$lost"
has "$usage" "usage: wp1-test.sh <branch> <part>" && has "$usage" "rc=2" || fail "one argument did not print the usage" "$usage"
has "$nobr" "wp1-test: no branch feat/none" && has "$nobr" "rc=2" || fail "an unknown branch did not fail" "$nobr"
has "$quote" "wp1-test: bad part A'B (golden, bayan, parity, scripts, runtime)" && has "$quote" "rc=2" || fail "a bad part was not refused" "$quote"
[[ $wla == "wlt1 \$env:PATH = 'C:\\home\\lang\\zig\\zig-x86_64-windows-0.17.0;' + \$env:PATH; Set-Location '$R';"* ]] \
  || fail "wlt1 did not get zig on PATH first ('$wla')" "$wl"
[[ $wla == *"bash scripts/test.sh --only $F --jobs 2'; exit"* ]] || fail "WIN_THREADS not in '$wla'" "$wl"
has "$wl" "rc=0" || fail "a wlt1 run failed" "$wl"
[ $wlown = 1 ] || fail "WIN_HOST=wlt1 did not keep to tmp/wlt1/" "$wl"
[[ $ssha != *zig* && $ssha != *--jobs* ]] || fail "wp1 by default got zig or --jobs ('$ssha')" "$good"
# R28: no dotnet in the remote command, which builds with bootstrap-build.sh and then runs scripts/test.sh
[[ $ssha != *dotnet* && $ssha == *scripts/bootstrap-build.sh*BAYAN_EXE=*scripts/test.sh* ]] || fail "the remote command has dotnet, or lacks bootstrap-build.sh then scripts/test.sh ('$ssha')" "$good"
has "$badth" "wp1-test: bad WIN_THREADS x (a positive integer)" && has "$badth" "rc=2" || fail "a bad WIN_THREADS was not refused" "$badth"
has "$tmo" "rc=0" && [[ $tmoa == *"\$env:BAYAN_TEST_TIMEOUT_MS = '90000';"* ]] || fail "a non-default BAYAN_TEST_TIMEOUT_MS hit the default's cache or did not reach the remote env ('$tmoa')" "$tmo"
has "$badtmo" "wp1-test: bad BAYAN_TEST_TIMEOUT_MS 9s (milliseconds)" && has "$badtmo" "rc=2" || fail "a bad BAYAN_TEST_TIMEOUT_MS was not refused" "$badtmo"
[ "$pwl" = "$(printf 'wlt1 powercfg /setactive ae098e76-5b05-4954-be35-3c535b591fce\nwlt1 powercfg /setactive SCHEME_BALANCED')" ] || fail "wlt1 did not run under Performance and go back to Balanced ('$pwl')" "$wl"
[ -z "$pwnone" ] || fail "wp1 or an empty WIN_PERF_SCHEME switched the power plan ('$pwnone')" "$good"
[ "$pwheld" = "wlt1 powercfg /setactive ae098e76-5b05-4954-be35-3c535b591fce" ] && [ $pruned = 1 ] || fail "a live holder did not keep the plan, or a dead holder was not pruned ('$pwheld')" "$wl"
has "$badps" "wp1-test: bad power scheme a'b" && has "$badps" "rc=2" || fail "a bad WIN_PERF_SCHEME was not refused" "$badps"
has "$nr1" "rc=0" && has "$nr2" "rc=0" || fail "the runs behind the no-switch check did not reach the remote run" "$nr1 $nr2"
[ "$pwstale" = "$(printf 'wlt1 powercfg /setactive ae098e76-5b05-4954-be35-3c535b591fce\nwlt1 powercfg /setactive SCHEME_BALANCED')" ] || fail "a 12 h old holder or a dotfile kept wlt1 on Performance ('$pwstale')" "$wl"
[ "$pwwt" = "wlt1 powercfg /setactive ae098e76-5b05-4954-be35-3c535b591fce" ] || fail "a run from a linked worktree ignored the main checkout's holder ('$pwwt')" "$wl"
[ $seeded = 1 ] && has "$badpsc" "wp1-test: bad power scheme a'b" && has "$badpsc" "rc=2" || fail "a bad WIN_PERF_SCHEME was not refused on a cache hit" "$badpsc"
has "$pw" "rc=0" && [[ $dargs == "-c unset CC; exe=\$(bash scripts/bootstrap-build.sh) || exit 1; BAYAN_EXE=\$exe bash scripts/test.sh --only bayan --jobs 3 " ]] || fail "pwsh did not pass the build and test script to Git Bash ('$dargs')" "$pw"
has "$pwc" "rc=0" && [[ $dargsc == "-c export CC='zig cc'; exe=\$(bash scripts/bootstrap-build.sh) || exit 1; BAYAN_EXE=\$exe bash scripts/test.sh --only runtime " ]] || fail "WIN_CC did not reach Git Bash as CC ('$dargsc')" "$pwc"
has "$badcc" "wp1-test: bad WIN_CC a;b" && has "$badcc" "rc=2" || fail "a bad WIN_CC was not refused" "$badcc"
has "$first" "rc=0" && [ $cloned = 1 ] || fail "the remote command did not clone into the short-sha directory with its marker" "$first"
has "$again" "rc=0" && [ $replaced = 1 ] || fail "a re-run for the same sha did not replace the clone it made" "$again"
has "$foreign" "wp1-test: $aux/remote/$s exists and wp1-test.sh did not create it" && has "$foreign" "rc=3" && [ $kept = 1 ] \
  || fail "a directory wp1-test.sh did not make was not left alone" "$foreign"
has "$moved" "rc=4" && [ "$(tail -1 <<< "$mout")" = "exit 4" ] && grep -q "moved after $sha was resolved" <<< "$mout" || fail "a branch that moved after the sha lookup was tested as the sha" "$moved"
echo PASS
