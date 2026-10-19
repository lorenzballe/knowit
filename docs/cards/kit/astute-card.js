// Astute card kit: the deck around the cards and the helpers every card uses.
// Each card registers what to do when it is shown: Kit.onShow[cardId] = () => { ... }.
//
// Two ways to run. Kit.deck() is the page of prototypes, several cards with arrows between them.
// Kit.single() is one card that fills its window: a free card, shown in the app inside the native
// card frame (the app speaks to it through window.Astute, astute-bridge.js), or opened in a browser
// and by tool/cards/card_check.cjs, which stand in for the app.
const Kit = (() => {
  const $ = id => document.getElementById(id);
  const has = () => typeof gsap !== 'undefined';
  // Reveal a hidden element (class "gone") with a short rise.
  const show = id => { const e = $(id); if (!e.classList.contains('gone')) return; e.classList.remove('gone'); if (has() && !calm()) gsap.fromTo(e, {opacity: 0, y: 12}, {opacity: 1, y: 0, duration: .5, ease: 'power2.out'}); };
  const hide = id => $(id).classList.add('gone');
  // A canvas or an SVG sized to its real box, so drawings and text never stretch.
  const fitCanvas = cv => { const r = cv.getBoundingClientRect(), W = Math.max(1, r.width), H = Math.max(1, r.height); cv.width = W * devicePixelRatio; cv.height = H * devicePixelRatio; const x = cv.getContext('2d'); x.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0); return {x, W, H}; };
  const fitSvg = svg => { const r = svg.getBoundingClientRect(), W = Math.max(1, r.width), H = Math.max(1, r.height); svg.setAttribute('viewBox', `0 0 ${W} ${H}`); return {W, H, f: Math.max(10, Math.min(H / 18, W / 22))}; };
  const mk = (tag, attrs, parent) => { const e = document.createElementNS('http://www.w3.org/2000/svg', tag); for (const k in attrs) e.setAttribute(k, attrs[k]); parent && parent.appendChild(e); return e; };
  // Seeded randomness, so a card looks the same on every phone.
  let seed = 7; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  const gauss = () => { let u = 0, v = 0; while (!u) u = rnd(); while (!v) v = rnd(); return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v); };
  // Kit.play[cardId] = async () => {...} plays the card through (taps, drags) so the checker can photograph the end state too.
  // Kit.onEnter[cardId] runs when the card is first in front of the reader: in the app that can be well after it was drawn.
  const onShow = {}, onHide = {}, play = {}, onEnter = {};
  function deck() {
    const cards = [...document.querySelectorAll('.card')]; let at = 0; const dots = $('dots');
    if (dots) cards.forEach(() => dots.appendChild(document.createElement('span')));
    function go(i) { onHide[cards[at].id]?.(); at = (i + cards.length) % cards.length; cards.forEach((c, k) => c.classList.toggle('on', k === at)); if (dots) [...dots.children].forEach((d, k) => d.classList.toggle('on', k <= at)); if ($('kind')) $('kind').textContent = (at + 1) + ' / ' + cards.length + ' · ' + (cards[at].dataset.kind || ''); if (has()) gsap.fromTo(cards[at], {opacity: 0, scale: .985}, {opacity: 1, scale: 1, duration: .45, ease: 'power3.out'}); requestAnimationFrame(() => { onShow[cards[at].id]?.(); onEnter[cards[at].id]?.(); }); }
    $('prev') && ($('prev').onclick = () => go(at - 1)); $('next') && ($('next').onclick = () => go(at + 1));
    addEventListener('keydown', e => { if (e.target.tagName === 'INPUT') return; if (e.key === 'ArrowRight') go(at + 1); if (e.key === 'ArrowLeft') go(at - 1); });
    addEventListener('resize', () => onShow[cards[at].id]?.());
    go(0); return go;
  }

  // ---------- one card, in the app or standing in for it ----------

  // The subjects as the app draws them (lib/data/topics.dart, lib/data/subject_icons.dart; a test in
  // test/web/ keeps the two in step): name, colour, ink, edge, mark. In the app the same come in
  // Astute.env.subject, the name in the reader's language.
  const SUBJECTS = {
    thinking: ['Thinking', '#F2F1EC', '#10100c', '#8f8d84', 'M9 18h6 M10 21h4 M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.3 1 2.1h5c0-.8.4-1.6 1-2.1A6 6 0 0 0 12 3z'],
    economics: ['Economics', '#FFE600', '#10100c', '#9c8d00', 'M3 17l6-6 4 4 8-8 M15 7h6v6'],
    sport: ['Sport', '#A6FF00', '#10100c', '#5f9400', 'M7 4h10v4a5 5 0 0 1-10 0V4z M7 5H4.42v2a3 3 0 0 0 3 3 M17 5h2.58v2a3 3 0 0 1-3 3 M12 13v4 M9 20h6l-1-3h-4z'],
    nature: ['Nature', '#00D451', '#10100c', '#007a2f', 'M6 18C6 10 12 4 20 4c0 8-6 14-14 14z M4 20L15 9'],
    science: ['Science', '#00E5A0', '#10100c', '#00835b', 'M9 3h6 M10 3v6l-5.54 8.95A2 2 0 0 0 6.16 21h11.68a2 2 0 0 0 1.7-3.05L14 9V3 M6.29 15h11.42'],
    maths: ['Maths', '#0E9A70', '#ffffff', '#085941', 'M4.5 8c1.2-1.6 2.6-2.4 4.6-2.4H19.5 M9.4 5.6c0 5.2-.9 9.9-3.4 13.4 M15 5.6v10.9c0 1.6.7 2.4 2 2.4.9 0 1.5-.4 1.8-1.2'],
    language: ['Language', '#00D9D9', '#10100c', '#007f80', 'M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H9l-5 4V6z M9 13l3-6 3 6 M10 11h4'],
    technology: ['Technology', '#00A6FF', '#10100c', '#005e91', 'M7 5h10a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2z M10 9h4a1 1 0 0 1 1 1v4a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1v-4a1 1 0 0 1 1-1z M9 5V3 M15 5V3 M9 21v-2 M15 21v-2 M5 9H3 M5 15H3 M21 9h-2 M21 15h-2'],
    space: ['Space', '#2B5CFF', '#ffffff', '#152f8f', 'M12 5.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 1 0 0-13z M15.48 6.51A10.5 3.6 -30 1 1 5.51 12.27'],
    philosophy: ['Philosophy', '#4C6FFF', '#ffffff', '#2a3fa3', 'M3 9h18L12 3 3 9z M5.5 9v12 M9.83 9v12 M14.17 9v12 M18.5 9v12 M3 21h18'],
    cinema: ['Cinema', '#6E3AFF', '#ffffff', '#3d1e99', 'M3 9h18v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9z M3 9V6a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v3 M8 4l-2 5 M13 4l-2 5 M18 4l-2 5'],
    psychology: ['Psychology', '#9B5CFF', '#ffffff', '#5a2ea6', 'M20 11a8 8 0 1 0-4 6.93V21 M12 8a3 3 0 1 0 2.12 5.12'],
    music: ['Music', '#C13AFF', '#ffffff', '#6e1a99', 'M9.5 17.75V5.75l10-2v12 M9.5 17.75a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0z M19.5 15.75a2.5 2.5 0 1 1-5 0 2.5 2.5 0 0 1 5 0z M9.5 8.75l10-2'],
    weird_facts: ['Weird facts', '#E040FB', '#ffffff', '#82208f', 'M10 6.5l1.9 5.1 5.1 1.9-5.1 1.9-1.9 5.1-1.9-5.1-5.1-1.9 5.1-1.9z M18.5 3.5l.65 1.85 1.85.65-1.85.65-.65 1.85-.65-1.85-1.85-.65 1.85-.65z'],
    art: ['Art', '#FF00A8', '#ffffff', '#990066', 'M12 3a9 9 0 1 0 0 18 2 2 0 0 0 1.6-3.2 2 2 0 0 1 1.6-3.2H18a3 3 0 0 0 3-3c0-4.9-4-8.6-9-8.6z M6.83 13.88h.01 M7.02 9.68h.01 M10.12 6.83h.01 M14.32 7.02h.01'],
    pop_culture: ['Pop culture', '#FF3D7F', '#ffffff', '#a3204d', 'M12 3.86l2.65 5.36 5.91.86-4.28 4.17 1.01 5.89L12 17.36l-5.29 2.78 1.01-5.89-4.28-4.17 5.91-.86z'],
    human_body: ['Human body', '#FF2D5F', '#ffffff', '#9e1638', 'M12 19.63s-8-5.25-8-10.74A4.57 4.57 0 0 1 12 5.92a4.57 4.57 0 0 1 8 2.97c0 5.49-8 10.74-8 10.74z'],
    medicine: ['Medicine', '#FF3B30', '#ffffff', '#9e1c14', 'M11 3h2a1 1 0 0 1 1 1v6h6a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1h-6v6a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-6H4a1 1 0 0 1-1-1v-2a1 1 0 0 1 1-1h6V4a1 1 0 0 1 1-1z'],
    food: ['Food', '#FF7A1A', '#10100c', '#a3470a', 'M6 3v7a2 2 0 0 0 4 0V3 M8 12v9 M18 3v18 M18 3c-2.5 1.5-3.5 4.5-3.5 7.5a1.5 1.5 0 0 0 1.5 1.5H18'],
    history: ['History', '#FFB000', '#10100c', '#a06c00', 'M5 3h14 M5 21h14 M7 3c0 6 10 12 10 18 M17 3c0 6-10 12-10 18'],
    life: ['Life', '#FFC49B', '#10100c', '#a8714a', 'M12 21v-9 M12 12c0-4 3-6 7-6 0 4-3 6-7 6z M12 15c0-3-2.5-5-6-5 0 3 2.5 5 6 5z']
  };
  const bridge = () => (typeof window !== 'undefined' && window.Astute) || null;
  // What the app says about where the card is shown. Standing alone, a dark phone that plays sound.
  const env = () => Object.assign({theme: 'dark', lang: 'en', calm: matchMedia('(prefers-reduced-motion: reduce)').matches, sound: true, touch: 'taps', platform: 'browser', corner: null}, bridge() ? bridge().env : {});
  const calm = () => env().calm;
  let card = null, shown = false, isReady = false, answered = null;

  // The clock waits for the reader. In the app the next card is drawn while the reader is still on
  // this one, so its first frame is ready the moment it comes up; but anything that moves would have
  // moved for nobody. After the first frame GSAP's timeline, CSS animations and requestAnimationFrame
  // (held by the bridge, which runs before any library can keep its own copy) all stand still until
  // the app says the card is in front of the reader, and again whenever it leaves.
  const nativeFrame = fn => (bridge() ? bridge().frame : window.requestAnimationFrame)(fn);
  let holding = false;
  function hold() { if (holding || !bridge()) return; holding = true; if (has()) gsap.globalTimeline.pause(); document.documentElement.classList.add('kit-held'); bridge().hold(); }
  function release() { if (!holding) return; holding = false; if (has()) gsap.globalTimeline.resume(); document.documentElement.classList.remove('kit-held'); bridge().release(); }

  // A tap the page did nothing with turns the card over, as a tap on a native card does. Anything a
  // finger is meant to press (a button, a link, something drawn with a pointer cursor or held with
  // touch-action:none, or marked data-tap) keeps its tap.
  const PRESSABLE = 'a,button,input,select,textarea,label,summary,[role=button],[role=link],[role=slider],[role=checkbox],[role=radio],[role=tab],[data-tap],[onclick]';
  const TOUCHED = new Set(['pointer', 'grab', 'grabbing', 'move', 'crosshair', 'ew-resize', 'ns-resize', 'col-resize', 'row-resize', 'text']);
  function pressable(el) {
    for (; el && el.nodeType === 1 && el !== document.body; el = el.parentElement) {
      if (el.matches(PRESSABLE)) return true;
      const s = getComputedStyle(el);
      if (TOUCHED.has(s.cursor) || s.touchAction === 'none') return true;
      if (el.classList.contains('card')) return false;
    }
    return false;
  }

  // Where the page wants every touch, for a card that declares touch "drags": whatever is marked
  // data-drag, and whatever holds the finger itself (touch-action:none). The app gives a touch that
  // starts there to the page, and keeps every other drag for throwing the card.
  let lastZones = '';
  function zones() {
    if (env().touch !== 'drags' || !card) return;
    const rects = [];
    for (const el of card.querySelectorAll('*')) {
      if (el.closest('svg') && el.tagName.toLowerCase() !== 'svg') continue;
      if (!el.hasAttribute('data-drag') && getComputedStyle(el).touchAction !== 'none') continue;
      if (el.closest('.gone') || el.getAttribute('data-drag') === 'off') continue;
      const s = getComputedStyle(el); if (s.display === 'none' || s.visibility === 'hidden') continue;
      const b = el.getBoundingClientRect(); if (b.width < 1 || b.height < 1) continue;
      rects.push([Math.round(b.left), Math.round(b.top), Math.round(b.width), Math.round(b.height)]);
    }
    const key = JSON.stringify(rects); if (key === lastZones) return; lastZones = key;
    bridge() ? bridge().zones(rects) : (Kit.zoneRects = rects);
  }
  let zonesQueued = false;
  const zonesSoon = () => { if (zonesQueued) return; zonesQueued = true; nativeFrame(() => { zonesQueued = false; zones(); }); };

  // On the web build the card is an iframe, and the app never sees a finger on it: a drag that is
  // not the page's own is handed out to the app, which throws the card with it.
  function forwardPans() {
    let pan = null;
    const inZone = e => { const r = JSON.parse(lastZones || '[]'); return r.some(([x, y, w, h]) => e.clientX >= x && e.clientX <= x + w && e.clientY >= y && e.clientY <= y + h); };
    addEventListener('pointerdown', e => { pan = inZone(e) ? null : {id: e.pointerId, x: e.screenX, y: e.screenY, lx: e.screenX, ly: e.screenY, on: false, trail: [[e.timeStamp, e.screenX, e.screenY]]}; }, true);
    addEventListener('pointermove', e => {
      if (!pan || e.pointerId !== pan.id) return;
      if (!pan.on && Math.hypot(e.screenX - pan.x, e.screenY - pan.y) > 8) { pan.on = true; bridge().send({t: 'pan', phase: 'start'}); }
      if (!pan.on) return;
      e.preventDefault();
      bridge().send({t: 'pan', phase: 'update', dx: e.screenX - pan.lx, dy: e.screenY - pan.ly});
      pan.lx = e.screenX; pan.ly = e.screenY; pan.trail.push([e.timeStamp, e.screenX, e.screenY]); if (pan.trail.length > 8) pan.trail.shift();
    }, {capture: true, passive: false});
    const end = e => {
      if (!pan || e.pointerId !== pan.id) return;
      if (pan.on) {
        const [t0, x0, y0] = pan.trail[0], dt = Math.max(1, e.timeStamp - t0) / 1000;
        bridge().send({t: 'pan', phase: 'end', vx: (e.screenX - x0) / dt, vy: (e.screenY - y0) / dt});
        // the click a drag ends on is not a tap
        addEventListener('click', ev => { ev.stopPropagation(); ev.preventDefault(); }, {capture: true, once: true});
      }
      pan = null;
    };
    addEventListener('pointerup', end, true); addEventListener('pointercancel', end, true);
  }

  // The card's ground, its subject's mark and name, and in the app the line and the chip a native
  // card carries under its head.
  function dress() {
    const e = env(), key = (e.subject && e.subject.key) || card.dataset.topic || '', own = SUBJECTS[key];
    const s = Object.assign(own ? {key, name: own[0], c: own[1], k: own[2], edge: own[3], icon: own[4]} : {}, e.subject || {});
    if (!s.c) return;
    const st = card.style;
    if (!st.getPropertyValue('--c')) { st.setProperty('--c', s.c); st.setProperty('--k', s.k); st.setProperty('--edge', s.edge); }
    document.documentElement.style.setProperty('--ground', st.getPropertyValue('--c') || s.c);
    const label = card.querySelector('.label');
    if (!label) return;
    const svg = label.querySelector('svg');
    if (svg && !svg.childElementCount && s.icon) { svg.setAttribute('viewBox', '0 0 24 24'); svg.setAttribute('aria-hidden', 'true'); mk('path', {d: s.icon, fill: 'none', stroke: 'currentColor', 'stroke-width': 1.9, 'stroke-linecap': 'round', 'stroke-linejoin': 'round'}, svg); }
    const name = label.querySelector('.t'); if (name && s.name) name.textContent = s.name;
    label.querySelector('.kit-chip')?.remove(); card.querySelector('.kit-note')?.remove();
    if (e.chip && name) { const c = document.createElement('span'); c.className = 'kit-chip'; c.textContent = e.chip; name.after(c); }
    if (e.note) { const n = document.createElement('p'); n.className = 'kit-note'; n.textContent = e.note; label.after(n); }
  }
  function apply() {
    const e = env(), root = document.documentElement;
    root.classList.toggle('kit-calm', !!e.calm);
    root.dataset.theme = e.theme; root.dataset.platform = e.platform;
    const c = e.corner; root.style.setProperty('--kit-corner-w', c ? c.w + 'px' : '0px'); root.style.setProperty('--kit-corner-h', c ? c.h + 'px' : '0px');
    if (card) dress();
  }

  function single() {
    card = document.querySelector('.card');
    if (!card) return;
    const root = document.documentElement, app = !!bridge();
    root.classList.add('kit-single'); if (app) root.classList.add('kit-app');
    card.classList.add('on');
    apply();
    if (app) {
      bridge().on(msg => {
        if (msg.t === 'env') { apply(); zonesSoon(); Kit.onEnv?.(env()); }
        else if (msg.t === 'show') enter();
        else if (msg.t === 'hide') { shown && onHide[card.id]?.(); hold(); }
      });
      document.addEventListener('click', e => { if (!e.defaultPrevented && !pressable(e.target)) bridge().tap(); });
      if (env().platform === 'web') forwardPans();
    }
    new MutationObserver(zonesSoon).observe(card, {subtree: true, childList: true, attributes: true, attributeFilter: ['class', 'style', 'data-drag']});
    addEventListener('resize', () => { onShow[card.id]?.(); zonesSoon(); });
    const first = () => {
      onShow[card.id]?.();
      nativeFrame(() => nativeFrame(() => {
        isReady = true; zones();
        if (app) { bridge().ready(); if (!bridge().env.shown) hold(); else enter(); } else enter();
      }));
    };
    // The faces are in the page itself, but a first frame drawn before they are read would be
    // measured in the fallback font and drawn again.
    (document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve()).then(first, first);
  }
  function enter() {
    release();
    if (shown || !isReady) return;
    shown = true; onEnter[card.id]?.();
  }

  // How sure: a row of the app's five levels under the reader's answer, off until there is an answer
  // to be sure of (on()), then the verdict in its place (grade()). From the new formats of October 2026.
  const LEVELS = [50, 60, 70, 80, 90];
  const MARK = {yes: '<svg viewBox="0 0 24 24" width="62%" height="62%" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/></svg>',
    no: '<svg viewBox="0 0 24 24" width="56%" height="56%" aria-hidden="true"><path d="M6.5 6.5l11 11M17.5 6.5l-11 11" fill="none" stroke="currentColor" stroke-width="3.2" stroke-linecap="round"/></svg>'};
  function sure(host, question, onPick, words = {}) {
    const w = Object.assign({right: 'Right', wrong: 'Wrong', said: n => `you said ${n}%`}, words);
    // A row kept hidden until the answer is in (class gone) stays hidden when it is built.
    const build = () => { host.className = 'sure off' + (host.classList.contains('gone') ? ' gone' : ''); host.innerHTML = `<span class="sq">${question}</span><div class="row">${LEVELS.map(v => `<button class="sb" data-v="${v}">${v}%</button>`).join('')}</div>`; };
    build();
    host.addEventListener('click', e => {
      const b = e.target.closest('.sb'); if (!b || !host.classList.contains('sure') || host.classList.contains('off')) return;
      host.querySelectorAll('.sb').forEach(x => x.classList.toggle('on', x === b)); haptic('selection'); onPick(+b.dataset.v);
    });
    return {
      on() { host.classList.remove('off'); },
      ask(q) { const e = host.querySelector('.sq'); if (e) e.textContent = q; },
      reset: build,
      grade(ok, pct, note) {
        host.className = 'grade ' + (ok ? 'ok' : 'no');
        host.innerHTML = `<i>${ok ? MARK.yes : MARK.no}</i><span>${note ? note + ' · ' : (ok ? w.right : w.wrong) + ' · '}${w.said(pct)}</span>`;
        if (has() && !calm()) gsap.from(host, {opacity: 0, y: 6, duration: .35, ease: 'power3.out'});
      }
    };
  }

  // What the card tells the app. Standing alone they are kept on Kit, for the checker to read.
  // answer: {choice: what the reader said, in a few words (or the option's index on a card whose
  // kind is pickOne or debate); correct: true, false, or null where nothing is right or wrong;
  // sure: how sure they said they were, 50 to 90, or null}.
  function answer(a) { answered = {choice: String(a.choice ?? ''), correct: a.correct ?? null, sure: a.sure ?? null}; if (bridge()) bridge().answer(answered); Kit.answered = answered; }
  const flip = () => bridge() ? bridge().flip() : (Kit.flipped = true);
  const done = () => bridge() ? bridge().done() : (Kit.finished = true);
  const haptic = kind => bridge()?.haptic(kind || 'light');
  const open = url => bridge() ? bridge().open(url) : window.open(url, '_blank', 'noopener');
  // A file of the kit's own, as a URL this page can load: beside the kit standing alone, and in the
  // app the bytes the app put inside the page (data-kit-url, lib/widgets/web/card_kit.dart).
  const urls = {};
  function url(path) {
    if (urls[path]) return urls[path];
    const kept = document.querySelector(`script[data-kit-url="${path}"]`);
    if (kept) { const bin = atob(kept.textContent.trim()), bytes = new Uint8Array(bin.length); for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i); return (urls[path] = URL.createObjectURL(new Blob([bytes], {type: kept.dataset.mime || 'application/octet-stream'}))); }
    return (urls[path] = (base || 'kit/') + path);
  }
  const base = (() => { const s = document.currentScript && document.currentScript.src; return s ? s.slice(0, s.lastIndexOf('/') + 1) : ''; })();

  return {$, show, hide, fitCanvas, fitSvg, mk, rnd, gauss, onShow, onHide, onEnter, play, deck, single, sure, answer, flip, done, haptic, open, url, SUBJECTS, LEVELS,
    get app() { return !!bridge(); }, get env() { return env(); }, get calm() { return calm(); }, get sound() { return env().sound; }, get ready() { return isReady; }};
})();
