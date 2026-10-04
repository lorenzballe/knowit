// Astute card kit: the deck around the cards and the helpers every card uses.
// Each card registers what to do when it is shown: Kit.onShow[cardId] = () => { ... }.
const Kit = (() => {
  const $ = id => document.getElementById(id);
  const has = () => typeof gsap !== 'undefined';
  // Reveal a hidden element (class "gone") with a short rise.
  const show = id => { const e = $(id); if (!e.classList.contains('gone')) return; e.classList.remove('gone'); if (has()) gsap.fromTo(e, {opacity: 0, y: 12}, {opacity: 1, y: 0, duration: .5, ease: 'power2.out'}); };
  const hide = id => $(id).classList.add('gone');
  // A canvas or an SVG sized to its real box, so drawings and text never stretch.
  const fitCanvas = cv => { const r = cv.getBoundingClientRect(), W = Math.max(1, r.width), H = Math.max(1, r.height); cv.width = W * devicePixelRatio; cv.height = H * devicePixelRatio; const x = cv.getContext('2d'); x.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0); return {x, W, H}; };
  const fitSvg = svg => { const r = svg.getBoundingClientRect(), W = Math.max(1, r.width), H = Math.max(1, r.height); svg.setAttribute('viewBox', `0 0 ${W} ${H}`); return {W, H, f: Math.max(10, Math.min(H / 18, W / 22))}; };
  const mk = (tag, attrs, parent) => { const e = document.createElementNS('http://www.w3.org/2000/svg', tag); for (const k in attrs) e.setAttribute(k, attrs[k]); parent && parent.appendChild(e); return e; };
  // Seeded randomness, so a card looks the same on every phone.
  let seed = 7; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  const gauss = () => { let u = 0, v = 0; while (!u) u = rnd(); while (!v) v = rnd(); return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v); };
  // Kit.play[cardId] = async () => {...} plays the card through (taps, drags) so the checker can photograph the end state too.
  const onShow = {}, onHide = {}, play = {};
  function deck() {
    const cards = [...document.querySelectorAll('.card')]; let at = 0; const dots = $('dots');
    if (dots) cards.forEach(() => dots.appendChild(document.createElement('span')));
    function go(i) { onHide[cards[at].id]?.(); at = (i + cards.length) % cards.length; cards.forEach((c, k) => c.classList.toggle('on', k === at)); if (dots) [...dots.children].forEach((d, k) => d.classList.toggle('on', k <= at)); if ($('kind')) $('kind').textContent = (at + 1) + ' / ' + cards.length + ' · ' + (cards[at].dataset.kind || ''); if (has()) gsap.fromTo(cards[at], {opacity: 0, scale: .985}, {opacity: 1, scale: 1, duration: .45, ease: 'power3.out'}); requestAnimationFrame(() => onShow[cards[at].id]?.()); }
    $('prev') && ($('prev').onclick = () => go(at - 1)); $('next') && ($('next').onclick = () => go(at + 1));
    addEventListener('keydown', e => { if (e.target.tagName === 'INPUT') return; if (e.key === 'ArrowRight') go(at + 1); if (e.key === 'ArrowLeft') go(at - 1); });
    addEventListener('resize', () => onShow[cards[at].id]?.());
    go(0); return go;
  }
  return {$, show, hide, fitCanvas, fitSvg, mk, rnd, gauss, onShow, onHide, play, deck};
})();
