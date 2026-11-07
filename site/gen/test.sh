#!/bin/sh
# Builds a fixture site in <worktree>/tmp/gen-fixture with the generator and checks the pages it
# writes, then breaks the fixture four ways and checks each `file:line: message`.
#   site/gen/test.sh
set -u
gen=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$gen/../.." && pwd)
bayan=${BAYAN:-/Users/sy/Developer/ikhbat.org/bayan/dist/macos-arm64/latest/bayan}
site="$root/tmp/gen-fixture"
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
  printf 'title: First\nnav: Start\norder: 1\ntemplate: docs\n---\n<h2 id="one">One</h2>\n<example name="lt"/>\n<note>Careful</note>\n<h2 id="two">Two</h2>\n<pre><code class="byn">let s = "&lt;"</code></pre>\n' > "$site/content/first.page"
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
for name in index first second ref; do
  if [ -f "$out/$name.html" ]; then ok; else bad "no out/$name.html"; fi
done
has "$out/index.html" '<title>Home &amp; away</title>'
has "$out/index.html" '<a href="ref.html">docs</a>'
has "$out/first.html" '<p class="grp">Start</p>'
has "$out/first.html" '<p class="grp">Reference</p>'
has "$out/first.html" '<li><a href="first.html" aria-current="page">First</a></li>'
lacks "$out/first.html" 'index.html">Home'
has "$out/first.html" '<li><a href="#one">One</a></li>'
has "$out/first.html" '<li><a href="#two">Two</a></li>'
has "$out/first.html" '<a class="next" href="second.html" rel="next">'
lacks "$out/first.html" 'class="prev"'
has "$out/second.html" '<a class="prev" href="first.html" rel="prev">'
has "$out/second.html" '<a class="next" href="ref.html" rel="next">'
has "$out/ref.html" '<p class="group">Reference</p>'
has "$out/first.html" '<figcaption class="label">lt.byn</figcaption>'
has "$out/first.html" '<span class="fn">print</span>(<span class="str">&quot;a &lt; b&quot;</span>)'
has "$out/first.html" '<pre class="out"><code>a &lt; b</code></pre>'
has "$out/first.html" '<aside class="note">Careful</aside>'
has "$out/first.html" '<span class="kw">let</span> s = <span class="str">&quot;&lt;&quot;</span>'
has "$out/first.html" '<a href="ref.html" aria-current="page">Docs</a>'

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

rm -rf "$site"
echo "gen/test.sh: $passed passed, $failed failed"
[ "$failed" = 0 ]
