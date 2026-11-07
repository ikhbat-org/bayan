#!/bin/sh
# Builds a fixture site in a fresh <worktree>/tmp/gen-fixture.XXXXXX with the generator and checks the
# pages it writes, then breaks the fixture four ways and checks each `file:line: message`.
#   site/gen/test.sh
set -u
gen=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$gen/../.." && pwd)
bayan=${BAYAN:-$root/dist/macos-arm64/latest/bayan}
mkdir -p "$root/tmp"
site=$(mktemp -d "$root/tmp/gen-fixture.XXXXXX") || { echo "gen/test.sh: mktemp failed" >&2; exit 1; }
meta=
trap 'rm -rf "$site" "$meta"' EXIT
passed=0
failed=0

ok() { passed=$((passed + 1)); }
bad() { failed=$((failed + 1)); echo "FAIL $1" >&2; }

# has <file> <text>: the file contains the text
has() { if grep -qF -- "$2" "$1"; then ok; else bad "$(basename "$1") lacks: $2"; fi; }
lacks() { if grep -qF -- "$2" "$1"; then bad "$(basename "$1") has: $2"; else ok; fi; }

fixture() {
  rm -rf "$site"
  mkdir -p "$site/content" "$site/templates" "$site/examples" "$site/out"
  printf '<title>{{title}}</title>\n<nav>{{headnav}}</nav>\n<aside>\n{{sidebar}}</aside>\n<p class="group">{{group}}</p>\n<main>\n{{body}}\n</main>\n<ul>\n{{toc}}</ul>\n<nav class="pager">\n{{pager}}</nav>\n' > "$site/templates/docs.html"
  printf '<title>{{title}}</title>\n<a href="{{docs}}">docs</a>\n{{body}}\n' > "$site/templates/landing.html"
  printf 'print("a < b")\n' > "$site/examples/lt.byn"
  printf 'a < b\n' > "$site/examples/lt.out"
  printf 'title: Home & away\ntemplate: landing\n---\n<p>home</p>\n' > "$site/content/index.page"
  printf 'title: First\nnav: Start\norder: 1\ntemplate: docs\n---\n<h2 id="one">One</h2>\n<example name="lt"/>\n<note>Careful</note>\n<h2 id="two">Two</h2>\n<pre><code class="byn">let s = "&lt;"</code></pre>\n' > "$site/content/zfirst.page"
  printf 'title: Second\nnav: Start\norder: 2\ntemplate: docs\n---\n<p>two</p>\n' > "$site/content/second.page"
  printf 'title: Ref\nnav: Reference\ntemplate: docs\n---\n<p>ref</p>\n' > "$site/content/ref.page"
}

run() { "$bayan" run "$gen" -- "$site" > "$site/stdout" 2> "$site/stderr"; }

# expect <name> <stderr text>: the generator fails with exit 1 and names the file and line
expect() {
  run
  status=$?
  if [ "$status" = 1 ] && grep -qF -- "$2" "$site/stderr"; then ok; else bad "$1: exit $status, stderr: $(cat "$site/stderr")"; fi
}

fixture
if run; then ok; else bad "fixture build: $(cat "$site/stderr")"; fi
out="$site/out"
for name in index zfirst second ref; do
  if [ -f "$out/$name.html" ]; then ok; else bad "no out/$name.html"; fi
done
has "$out/index.html" '<title>Home &amp; away</title>'
has "$out/index.html" '<a href="ref.html">docs</a>'
has "$out/zfirst.html" '<p class="grp">Start</p>'
has "$out/zfirst.html" '<p class="grp">Reference</p>'
has "$out/zfirst.html" '<li><a href="zfirst.html" aria-current="page">First</a></li>'
lacks "$out/zfirst.html" 'index.html">Home'
has "$out/zfirst.html" '<li><a href="#one">One</a></li>'
has "$out/zfirst.html" '<li><a href="#two">Two</a></li>'
has "$out/zfirst.html" '<a class="next" href="second.html" rel="next">'
lacks "$out/zfirst.html" 'class="prev"'
has "$out/second.html" '<a class="prev" href="zfirst.html" rel="prev">'
has "$out/second.html" '<a class="next" href="ref.html" rel="next">'
has "$out/ref.html" '<p class="group">Reference</p>'
has "$out/zfirst.html" '<figcaption class="label">lt.byn</figcaption>'
has "$out/zfirst.html" '<span class="fn">print</span>(<span class="str">&quot;a &lt; b&quot;</span>)'
has "$out/zfirst.html" '<pre class="out"><code>a &lt; b</code></pre>'
has "$out/zfirst.html" '<aside class="note">Careful</aside>'
has "$out/zfirst.html" '<span class="kw">let</span> s = <span class="str">&quot;&lt;&quot;</span>'
has "$out/zfirst.html" '<a href="ref.html" aria-current="page">Docs</a>'

fixture
printf 'title: About {{body}}\nnav: Start\norder: 2\ntemplate: docs\n---\n<h2 id="p">The {{pager}} slot</h2>\n' > "$site/content/second.page"
if run; then ok; else bad "placeholder build: $(cat "$site/stderr")"; fi
has "$out/second.html" '<title>About {{body}}</title>'
has "$out/second.html" '<li><a href="#p">The {{pager}} slot</a></li>'

fixture
printf 'nav: Start\ntemplate: docs\n---\n' > "$site/content/second.page"
expect "no title" "content/second.page:1: page has no title"

fixture
printf 'title: Second\n\ntemplate: wiki\n---\n' > "$site/content/second.page"
expect "unknown template" "content/second.page:3: unknown template \`wiki\`"

fixture
printf 'title: Second\ntemplate: docs\n---\n<p>x</p>\n<example name="gone"/>\n' > "$site/content/second.page"
expect "missing example" "content/second.page:5: example \`gone\`: $site/examples/gone.byn not found"

fixture
printf 'title: Second\ntemplate: docs\n---\n\n\n<h2>Title</h2>\n' > "$site/content/second.page"
expect "h2 with no id" "content/second.page:6: h2 has no id"

if [ -z "${GEN_TEST_META:-}" ]; then
# The shell scripts, run from copies in a throwaway repo whose compiler only records its arguments.
# GEN_TEST_META keeps the copies from running this section again.
export GEN_TEST_META=1
meta=$(mktemp -d "$root/tmp/gen-meta.XXXXXX") || { echo "gen/test.sh: mktemp failed" >&2; exit 1; }
repo="$meta/repo"
latest="$repo/dist/macos-arm64/latest"
mkdir -p "$latest" "$repo/site/gen" "$repo/site/assets" "$repo/site/examples" "$meta/fakebin"
printf '#!/bin/sh\necho "$@" >> "$(dirname "$0")/calls"\n' > "$latest/bayan"
cp "$latest/bayan" "$repo/site/fakebayan"
printf '#!/bin/sh\nexit 1\n' > "$meta/fakebin/mktemp"
chmod +x "$latest/bayan" "$repo/site/fakebayan" "$meta/fakebin/mktemp"
cp "$gen/../build.sh" "$gen/../check-examples.sh" "$repo/site/"
cp "$gen/test.sh" "$repo/site/gen/"
: > "$repo/site/examples/x.byn"
: > "$repo/site/examples/x.out"

# default compiler: each script finds <repo>/dist/macos-arm64/latest/bayan when BAYAN is unset
for script in check-examples.sh build.sh gen/test.sh; do
  rm -f "$latest/calls"
  (cd "$repo" && env -u BAYAN sh "site/$script" > /dev/null 2>&1)
  if [ -f "$latest/calls" ]; then ok; else bad "$script: default compiler under the repo root not used"; fi
done

# test.sh: a fixture directory per run, removed at exit
rm -f "$latest/calls"
(cd "$repo" && env -u BAYAN sh site/gen/test.sh > /dev/null 2>&1)
first=$(sed -n '1s/.* //p' "$latest/calls")
rm -f "$latest/calls"
(cd "$repo" && env -u BAYAN sh site/gen/test.sh > /dev/null 2>&1)
second=$(sed -n '1s/.* //p' "$latest/calls")
if [ -n "$first" ] && [ "$first" != "$second" ]; then ok; else bad "test.sh reuses its fixture directory: $first"; fi
if ls "$repo/tmp" | grep -q '^gen-fixture'; then bad "test.sh leaves its fixture directory behind"; else ok; fi

# check-examples.sh: a relative BAYAN works
rm -f "$latest/calls"
out=$(cd "$repo/site" && BAYAN=./fakebayan sh check-examples.sh 2>&1)
if [ $? = 0 ] && [ "$out" = "examples: 1 checked" ]; then ok; else bad "relative BAYAN: $out"; fi

# check-examples.sh: a failing mktemp is an error
out=$(cd "$repo/site" && PATH="$meta/fakebin:$PATH" BAYAN=./fakebayan sh check-examples.sh 2>&1)
status=$?
case $out in
  *"mktemp failed"*) if [ "$status" = 1 ]; then ok; else bad "mktemp failure: exit $status"; fi ;;
  *) bad "mktemp failure not reported: $out" ;;
esac
fi

echo "gen/test.sh: $passed passed, $failed failed"
[ "$failed" = 0 ]
