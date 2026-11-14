// The one motion moment: the hero diagnostic types in once, line by line.
// The text stays in the DOM; only a clip is animated. Skipped under reduced motion.
(function () {
  var term = document.querySelector('[data-type]');
  if (!term || !term.animate || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  var delay = 300;
  term.querySelectorAll('.ln').forEach(function (ln) {
    var n = ln.textContent.length;
    if (!n) return;
    var ms = Math.min(n * 18, 700);
    ln.animate(
      [{ clipPath: 'inset(0 100% 0 0)' }, { clipPath: 'inset(0 0 0 0)' }],
      { duration: ms, delay: delay, easing: 'steps(' + Math.min(n, 40) + ', end)', fill: 'backwards' }
    );
    delay += ms + 80;
  });
})();
