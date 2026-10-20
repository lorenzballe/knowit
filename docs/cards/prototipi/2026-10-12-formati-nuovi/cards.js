// New formats, October 2026. Eight cards, eight techniques, eight layouts.
// Every card ends the same way: the reader's answer, how sure they are, then the why.
// Text lives in strings.js (STR.en / STR.it); the page sets window.LANG.
(() => {
const LANG = window.LANG || 'en';
const T = STR[LANG];
const calm = matchMedia('(prefers-reduced-motion: reduce)').matches;
const D = s => calm ? 0 : s;
const wait = ms => new Promise(r => setTimeout(r, ms));
const $ = id => document.getElementById(id);
const fmt = n => n.toLocaleString(LANG === 'it' ? 'it-IT' : 'en-GB');
const NS = 'http://www.w3.org/2000/svg';
const mk = (tag, a, p) => Kit.mk(tag, a, p);
const txt = (p, x, y, s, a = {}) => { const e = mk('text', Object.assign({x, y}, a), p); e.textContent = s; return e; };
const cq = el => el.closest('.card').clientHeight / 100;   // 1cqh in px
const LEVELS = [50, 60, 70, 80, 90];
const CHECK = '<svg viewBox="0 0 24 24" width="62%" height="62%"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
const CROSS = '<svg viewBox="0 0 24 24" width="56%" height="56%"><path d="M6.5 6.5l11 11M17.5 6.5l-11 11" fill="none" stroke="currentColor" stroke-width="3.2" stroke-linecap="round"/></svg>';

// The subjects' own marks, from the app (lib/data/subject_icons.dart).
const ICON = {
  History: 'M5 3h14 M5 21h14 M7 3c0 6 10 12 10 18 M17 3c0 6-10 12-10 18',
  Thinking: 'M9 18h6 M10 21h4 M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.3 1 2.1h5c0-.8.4-1.6 1-2.1A6 6 0 0 0 12 3z',
  Psychology: 'M20 11a8 8 0 1 0-4 6.93V21 M12 8a3 3 0 1 0 2.12 5.12',
  Medicine: 'M11 3h2a1 1 0 0 1 1 1v6h6a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1h-6v6a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-6H4a1 1 0 0 1-1-1v-2a1 1 0 0 1 1-1h6V4a1 1 0 0 1 1-1z',
  Science: 'M9 3h6 M10 3v6l-5.54 8.95A2 2 0 0 0 6.16 21h11.68a2 2 0 0 0 1.7-3.05L14 9V3 M6.29 15h11.42',
  Life: 'M12 21v-9 M12 12c0-4 3-6 7-6 0 4-3 6-7 6z M12 15c0-3-2.5-5-6-5 0 3 2.5 5 6 5z',
  Space: 'M12 5.5a6.5 6.5 0 1 0 0 13 6.5 6.5 0 1 0 0-13z M15.48 6.51A10.5 3.6 -30 1 1 5.51 12.27',
  'Weird facts': 'M10 6.5l1.9 5.1 5.1 1.9-5.1 1.9-1.9 5.1-1.9-5.1-5.1-1.9 5.1-1.9z M18.5 3.5l.65 1.85 1.85.65-1.85.65-.65 1.85-.65-1.85-1.85-.65 1.85-.65z'
};
const CARDS = [
  {id: 'lamp', subj: 'History', c: '#FFB000', k: '#10100c', e: '#a06c00'},
  {id: 'births', subj: 'Thinking', c: '#F2F1EC', k: '#10100c', e: '#8f8d84'},
  {id: 'bean', subj: 'Psychology', c: '#9B5CFF', k: '#ffffff', e: '#5a2ea6'},
  {id: 'polio', subj: 'Medicine', c: '#FF3B30', k: '#ffffff', e: '#9e1c14'},
  {id: 'pour', subj: 'Science', c: '#00E5A0', k: '#10100c', e: '#00835b'},
  {id: 'town', subj: 'Life', c: '#FFC49B', k: '#10100c', e: '#a8714a'},
  {id: 'sun', subj: 'Space', c: '#2B5CFF', k: '#ffffff', e: '#152f8f'},
  {id: 'bollard', subj: 'Weird facts', c: '#E040FB', k: '#ffffff', e: '#82208f'}
];

// ---------- the frame ----------
const label = (c) => `<div class="label"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="${ICON[c.subj]}" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/></svg><span class="t">${T[c.id].subject}</span><span class="tag">${T[c.id].tag}</span></div>`;
const end = (id, kind, line) => `<div class="keep gone" id="${id}Keep"><b>${kind === 'ask' ? T.ask : T.keep}</b>${line}</div>`;
const foot = id => `<div class="foot"><span class="src">${T[id].src}</span></div>`;
const BODY = {
  lamp: () => `<div class="stagebox" id="lampBox"><svg class="full" id="lampSvg" role="img" aria-label="${T.lamp.tray}"></svg></div>
    <div id="lampSure"></div><p class="say" id="lampSay"></p>${end('lamp', 'keep', T.lamp.keep)}${foot('lamp')}`,
  births: () => `<div class="stagebox" id="birthsBox">${['A', 'B', 'C'].map((n, i) => `<button class="strip" data-i="${i}" aria-label="${n}"><b class="sl">${n}</b><svg class="sg"></svg><span class="sr"><span class="mono">${T.births.years}</span><span class="lr"></span></span><span class="stamp">${T.births.stamp}</span></button>`).join('')}</div>
    <div id="birthsSure"></div><p class="say" id="birthsSay"></p>${end('births', 'keep', T.births.keep)}${foot('births')}`,
  bean: () => `<div class="stagebox" id="beanBox"><div class="trayb" id="beanTray"><canvas id="beanCv"></canvas><svg id="beanChart" class="gone"></svg><div class="lid" id="beanLid">${T.bean.lidReady}</div></div>
      <div class="rounds" id="beanRounds"><span>1</span><span>2</span><span>3</span></div></div>
    <div class="ctl" id="beanCtl"><button class="btn" id="beanGo">${T.bean.throwBtn}</button><span class="mono" id="beanRound">${T.bean.round(1)}</span></div>
    <div class="pad gone" id="beanPad">${Array.from({length: 13}, (_, i) => `<button data-n="${i + 3}">${i + 3}</button>`).join('')}</div>
    <div id="beanSure" class="gone"></div><p class="say" id="beanSay"></p>${end('bean', 'keep', T.bean.keep)}${foot('bean')}`,
  polio: () => `<div class="stagebox" id="polioBox"><div class="felt" id="polioFelt"><div class="spots" id="polioSpots">${T.polio.spots.map(([b, em], i) => `<div class="spot" data-i="${i}"><b>${b}</b><em>${em}</em><span class="pc">0%</span></div>`).join('')}</div>
      <div class="rack" id="polioRack"></div></div></div>
    <div class="ctl" id="polioCtl"><button class="btn" id="polioGo" disabled>${T.polio.bet}</button></div>
    <p class="say" id="polioSay"></p>${end('polio', 'keep', T.polio.keep)}${foot('polio')}`,
  pour: () => `<div class="stagebox" id="pourBox"><div class="flaskbox"><svg id="pourSvg"></svg></div>
      <div class="ear"><span class="mono">${T.pour.hear}</span><div class="scope"><canvas id="pourCv"></canvas><svg id="pourChart" class="gone"></svg></div><span class="cap" id="pourCap">${T.pour.caps[0]}</span></div></div>
    <div class="ctl" id="pourCtl"><button class="hold" id="pourHold">${T.pour.hold}</button><button class="btn ghost gone" id="pourDone">${T.pour.done}</button></div>
    <div id="pourSure" class="gone"></div><p class="say" id="pourSay"></p>${end('pour', 'keep', T.pour.keep)}${foot('pour')}`,
  town: () => `<div class="stagebox" id="townBox"><div class="readout"><span class="n num" id="tN">50<small>%</small></span><span class="lab"><span class="mono">${T.town.alike}</span><span class="mono" id="tWant"></span></span></div>
      <div class="office"><canvas id="tCv"></canvas></div>
      <div class="slide"><input type="range" id="tRange" min="0" max="60" step="1" value="0" aria-label="${T.town.knob}"><span class="lk" id="tLock">${T.town.lock}</span></div></div>
    <div class="pick" id="tPick">${T.town.opts.map(([a], i) => `<button class="pb" data-i="${i}">${a}</button>`).join('')}</div>
    <div id="tSure"></div><p class="say" id="tSay"></p>${end('town', 'keep', T.town.keep)}${foot('town')}`,
  sun: () => `<div class="stagebox" id="sunBox"><div class="viewer" id="sunView"><canvas id="sunCv" aria-label="${T.sun.drag}"></canvas></div><div class="noon" id="sunNoon"><svg id="sunNoonSvg"></svg></div></div>
    <div class="pick" id="sunPick">${T.sun.opts.map(([a], i) => `<button class="pb" data-i="${i}">${a}</button>`).join('')}</div>
    <div id="sunSure"></div><p class="say" id="sunSay"></p>${end('sun', 'keep', T.sun.keep)}${foot('sun')}`,
  bollard: () => `<div class="stagebox" id="bollardBox"><div class="world" id="bWorld"><svg id="bSvg"></svg></div></div>
    <div class="pick gone" id="bPick">${T.bollard.opts.map(([a, s], i) => `<button class="pb" data-i="${i}">${a}<small>${s}</small></button>`).join('')}</div>
    <div id="bSure"></div><p class="say" id="bSay"></p>${end('bollard', 'keep', T.bollard.keep)}${foot('bollard')}`
};
const stage = document.querySelector('.stage');
stage.insertAdjacentHTML('beforeend', CARDS.map(c => `<article class="card" id="${c.id}" style="--c:${c.c};--k:${c.k};--edge:${c.e}" data-kind="${T[c.id].kind}"><div class="in">${label(c)}${T[c.id].place ? `<p class="place">${T[c.id].place}</p>` : ''}<h2 class="q">${T[c.id].q}</h2>${BODY[c.id]()}</div></article>`).join(''));
document.querySelector('.top h1').textContent = T.today;

// ---------- the reader's answer and how sure ----------
function Sure(host, question, onPick) {
  const build = () => {
    host.className = 'sure off';
    host.innerHTML = `<span class="sq">${question}</span><div class="row">${LEVELS.map(v => `<button class="sb" data-v="${v}">${v}%</button>`).join('')}</div>`;
  };
  build();
  host.addEventListener('click', e => {
    const b = e.target.closest('.sb'); if (!b || host.classList.contains('off') || !host.classList.contains('sure')) return;
    host.querySelectorAll('.sb').forEach(x => x.classList.toggle('on', x === b));
    onPick(+b.dataset.v);
  });
  return {
    on() { host.classList.remove('off'); },
    ask(q) { const e = host.querySelector('.sq'); if (e) e.textContent = q; },
    reset: build,
    grade(ok, pct, note) {
      host.className = 'grade ' + (ok ? 'ok' : 'no');
      host.innerHTML = `<i>${ok ? CHECK : CROSS}</i><span>${note ? note + ' · ' : (ok ? T.right : T.wrong) + ' · '}${T.saidPct(pct)}</span>`;
      if (!calm) gsap.from(host, {opacity: 0, y: 6, duration: .35, ease: 'power3.out'});
    }
  };
}
const say = (id, html) => { const e = $(id); e.innerHTML = html; if (!calm) gsap.fromTo(e, {opacity: .25}, {opacity: 1, duration: .35, ease: 'power2.out'}); };
const watchSize = (el, fn) => { let wh = ''; new ResizeObserver(() => { const b = el.getBoundingClientRect(); const k = Math.round(b.width) + 'x' + Math.round(b.height); if (b.width && k !== wh) { wh = k; fn(); } }).observe(el); };

// Label placement in an SVG: try each candidate offset until the text overlaps nothing placed so far.
function placer(svg, W, H) {
  const boxes = [];
  const hit = b => boxes.some(o => b.x < o.x + o.width && o.x < b.x + b.width && b.y < o.y + o.height && o.y < b.y + b.height);
  return {
    reserve(b) { boxes.push(b); },
    put(e, cands, pd = [2, 1]) {
      const at = (x, y, anchor) => {
        e.setAttribute('x', x); e.setAttribute('y', y); if (anchor) e.setAttribute('text-anchor', anchor);
        const b = e.getBBox(); return {b, pad: {x: b.x - pd[0], y: b.y - pd[1], width: b.width + 2 * pd[0], height: b.height + 2 * pd[1]}};
      };
      const fits = ({b, pad}) => b.x >= 1 && b.y >= 1 && b.x + b.width <= W - 1 && b.y + b.height <= H - 1 && !hit(pad);
      for (const [x, y, anchor] of cands) { const r = at(x, y, anchor); if (fits(r)) { boxes.push(r.pad); return true; } }
      // every candidate is taken: walk outwards from the first one, a little at a time
      const [x0, y0, a0] = cands[0], h0 = at(x0, y0, a0).b.height || 10;
      for (let k = 1; k <= 6; k++) for (let j = 0; j < 8; j++) {
        const t = j * Math.PI / 4, r = at(x0 + Math.cos(t) * k * h0 * 1.1, y0 + Math.sin(t) * k * h0 * .8, a0);
        if (fits(r)) { boxes.push(r.pad); return true; }
      }
      const r = at(x0, y0, a0); boxes.push(r.b); return false;
    }
  };
}
// A label with a dark pill behind it, for text over a busy drawing.
function pill(parent, x, y, s, fs, fg, bg, anchor = 'middle') {
  const g = mk('g', {}, parent);
  const r = mk('rect', {rx: fs * .45, fill: bg}, g);
  const t = txt(g, x, y, s, {'font-family': 'Figtree', 'font-weight': 800, 'font-size': fs, fill: fg, 'text-anchor': anchor, 'letter-spacing': '.04em'});
  const fit = () => { const b = t.getBBox(); r.setAttribute('x', b.x - fs * .45); r.setAttribute('y', b.y - fs * .2); r.setAttribute('width', b.width + fs * .9); r.setAttribute('height', b.height + fs * .4); };
  fit(); g._t = t; g._fit = fit; return g;
}

/* =====================================================================
   1 · Drop the pin: Lampedusa on a real map (Natural Earth, geo.js)
   ===================================================================== */
(() => {
  const L = T.lamp, svg = $('lampSvg');
  const sure = Sure($('lampSure'), L.sure, v => { conf = v; reveal(); });
  let pin = null, step = 0, conf = 0, geo = null, revealed = false;
  const KX = Math.cos(35.5 * Math.PI / 180), KM = 111.32;
  const hav = (a, b) => { const r = Math.PI / 180, dLa = (b[1] - a[1]) * r, dLo = (b[0] - a[0]) * r; const s = Math.sin(dLa / 2) ** 2 + Math.cos(a[1] * r) * Math.cos(b[1] * r) * Math.sin(dLo / 2) ** 2; return 2 * 6371.0088 * Math.asin(Math.sqrt(s)); };
  const pip = (p, ring) => { let ins = false; for (let i = 0, j = ring.length / 2 - 1; i < ring.length / 2; j = i++) { const xi = ring[2 * i], yi = ring[2 * i + 1], xj = ring[2 * j], yj = ring[2 * j + 1]; if ((yi > p[1]) !== (yj > p[1]) && p[0] < (xj - xi) * (p[1] - yi) / (yj - yi) + xi) ins = !ins; } return ins; };
  const isDeep = p => GEO.deep.reduce((n, r) => n + (pip(p, r) ? 1 : 0), 0) % 2 === 1;
  function proj(W, H) {
    const [X0, Y0, X1, Y1] = GEO.box;
    const F = [9.9, 33.1, 15.9, 38.35];
    const sFocus = Math.min(W / ((F[2] - F[0]) * KX), H / (F[3] - F[1]));
    const sBox = Math.max(W / ((X1 - X0) * KX), H / (Y1 - Y0));
    const s = Math.max(sFocus, sBox);
    const hw = W / (2 * s * KX), hh = H / (2 * s);
    let cx = (F[0] + F[2]) / 2, cy = (F[1] + F[3]) / 2;
    cx = Math.min(Math.max(cx, X0 + hw), X1 - hw); cy = Math.min(Math.max(cy, Y0 + hh), Y1 - hh);
    const X = lon => (lon - (cx - hw)) * s * KX, Y = lat => ((cy + hh) - lat) * s;
    return {s, X, Y, W, H, lon: x => x / (s * KX) + cx - hw, lat: y => cy + hh - y / s, km: k => k / KM * s};
  }
  // Rings are cut to the view so nothing is drawn outside the card: each run inside is closed along
  // the view's edge in the ring's own turning direction (Africa and Calabria are one ring in the data).
  function cutRing(pts, X0, Y0, X1, Y1) {
    const ins = p => p[0] >= X0 && p[0] <= X1 && p[1] >= Y0 && p[1] <= Y1;
    const area = pts.reduce((a, p, i) => { const q = pts[(i + 1) % pts.length]; return a + p[0] * q[1] - q[0] * p[1]; }, 0);
    if (pts.every(ins)) return [pts];
    const box = [[X0, Y0], [X1, Y0], [X1, Y1], [X0, Y1]];
    const inPoly = (p) => { let c = false; for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) { const [xi, yi] = pts[i], [xj, yj] = pts[j]; if ((yi > p[1]) !== (yj > p[1]) && p[0] < (xj - xi) * (p[1] - yi) / (yj - yi) + xi) c = !c; } return c; };
    if (!pts.some(ins)) return inPoly([(X0 + X1) / 2, (Y0 + Y1) / 2]) ? [area > 0 ? box : box.slice().reverse()] : [];
    const w = X1 - X0, h = Y1 - Y0, PER = 2 * (w + h);
    const per = ([x, y]) => Math.abs(y - Y0) < 1e-6 ? x - X0 : Math.abs(x - X1) < 1e-6 ? w + (y - Y0) : Math.abs(y - Y1) < 1e-6 ? w + h + (X1 - x) : 2 * w + h + (Y1 - y);
    const corners = [[0, [X0, Y0]], [w, [X1, Y0]], [w + h, [X1, Y1]], [2 * w + h, [X0, Y1]]];
    const cross = (a, b) => { let best = null; for (const [k, v] of [[0, X0], [0, X1], [1, Y0], [1, Y1]]) { const da = a[k] - v, db = b[k] - v; if (da === db || da * db > 0) continue; const t = da / (da - db), p = [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]; if (p[0] >= X0 - 1e-6 && p[0] <= X1 + 1e-6 && p[1] >= Y0 - 1e-6 && p[1] <= Y1 + 1e-6 && (!best || t < best[0])) best = [t, [Math.min(Math.max(p[0], X0), X1), Math.min(Math.max(p[1], Y0), Y1)]]; } return best && best[1]; };
    const s0 = pts.findIndex(p => !ins(p)), q = pts.slice(s0).concat(pts.slice(0, s0)), n = q.length, runs = [];
    let cur = null;
    for (let i = 0; i < n; i++) {
      const a = q[i], b = q[(i + 1) % n];
      if (ins(b) && !ins(a)) cur = [cross(b, a), b];
      else if (ins(b) && ins(a)) cur.push(b);
      else if (ins(a) && !ins(b)) { cur.push(cross(a, b)); runs.push(cur); cur = null; }
    }
    const ccw = area > 0, out = [], used = runs.map(() => false);
    for (let k = 0; k < runs.length; k++) {
      if (used[k]) continue;
      let poly = [], j = k;
      for (;;) {
        used[j] = true; poly = poly.concat(runs[j]);
        const ex = per(runs[j][runs[j].length - 1]);
        let best = null, bj = -1;
        runs.forEach((r, m) => { const en = per(r[0]), dd = ccw ? ((en - ex) % PER + PER) % PER : ((ex - en) % PER + PER) % PER; if (best === null || dd < best) { best = dd; bj = m; } });
        const cs = corners.map(([cp, c]) => [ccw ? ((cp - ex) % PER + PER) % PER : ((ex - cp) % PER + PER) % PER, c]).filter(([dd]) => dd > 0 && dd < best).sort((a, b) => a[0] - b[0]);
        poly = poly.concat(cs.map(c => c[1]));
        j = bj; if (used[j]) break;
      }
      out.push(poly);
    }
    return out;
  }
  const path = (rings, P) => rings.map(r => {
    const pts = []; for (let i = 0; i < r.length; i += 2) pts.push([P.X(r[i]), P.Y(r[i + 1])]);
    return cutRing(pts, -1, -1, P.W + 1, P.H + 1).map(pp => pp.map((p, i) => (i ? 'L' : 'M') + p[0].toFixed(1) + ',' + p[1].toFixed(1)).join('') + 'Z').join('');
  }).join('');
  function draw() {
    svg.innerHTML = '';
    const {W, H} = Kit.fitSvg(svg), u = cq(svg), fs = Math.max(9, Math.min(1.25 * u, 12));
    const P = proj(W, H); geo = {W, H, P, u, fs};
    mk('rect', {x: 0, y: 0, width: W, height: H, fill: revealed ? '#3a3326' : '#24201a', id: 'lampSea'}, svg);
    mk('path', {d: path(GEO.deep, P), fill: revealed ? '#100e0a' : '#24201a', 'fill-rule': 'evenodd', id: 'lampDeep'}, svg);
    const gr = mk('g', {stroke: '#F2F1EC', 'stroke-opacity': .07, 'stroke-width': 1}, svg);
    for (let la = 32; la <= 39; la++) if (P.Y(la) > 0 && P.Y(la) < H) mk('line', {x1: 0, x2: W, y1: P.Y(la), y2: P.Y(la)}, gr);
    for (let lo = 9; lo <= 17; lo++) if (P.X(lo) > 0 && P.X(lo) < W) mk('line', {y1: 0, y2: H, x1: P.X(lo), x2: P.X(lo)}, gr);
    mk('path', {d: path(GEO.land, P), fill: '#F2F1EC'}, svg);
    const pl = placer(svg, W, H); geo.pl = pl;
    const nm = L.names, lab = (lon, lat, s, big, onLand) => {
      const e = txt(svg, 0, 0, s, {'font-family': 'Figtree', 'font-weight': big ? 800 : 700, 'font-size': big ? fs * 1.05 : fs * .9, fill: onLand ? '#10100c' : '#F2F1EC', 'fill-opacity': onLand ? .55 : .8, 'letter-spacing': big ? '.16em' : '.04em', 'text-anchor': 'middle'});
      const x = P.X(lon), y = P.Y(lat);
      pl.put(e, [[x, y, 'middle'], [x, y - fs * 1.2, 'middle'], [x + fs * 2, y, 'start'], [x - fs * 2, y, 'end']]);
    };
    lab(14.15, 37.45, nm.sicily, true, true);
    lab(10.25, 35.05, nm.tunisia, true, true);
    if (P.Y(31.95) < H) lab(12.4, 32.2, nm.libya, true, true);
    lab(14.4, 35.62, nm.malta, false, false);
    lab(11.99, 36.52, nm.pantelleria, false, false);
    const tg = mk('g', {id: 'lampTruth', opacity: revealed ? 1 : 0}, svg);
    mk('path', {d: path([GEO.lamp, GEO.linosa], P), fill: '#FFB000', stroke: '#FFB000', 'stroke-width': 1.2}, tg);
    geo.reveal = mk('g', {id: 'lampReveal'}, svg);
    geo.pinG = mk('g', {id: 'lampPin'}, svg);
    if (revealed) paintReveal(false);
    paintPin();
  }
  function paintPin() {
    const {P, fs, W, H} = geo, g = geo.pinG; g.innerHTML = '';
    if (!pin) { // the tray: the island waiting to be dragged, bottom right, far from the answer
      const t = mk('g', {id: 'lampTray', style: 'cursor:grab'}, g);
      const r = mk('rect', {x: -fs * .6, y: -fs * 1.55, rx: fs * 1.05, height: fs * 2.1, fill: '#FFB000'}, t);
      mk('circle', {cx: fs * .35, cy: -fs * .5, r: fs * .32, fill: '#10100c'}, t);
      const tt = txt(t, fs * 1.05, -fs * .14, `${L.tray} · ${L.drag}`, {'font-family': 'Figtree', 'font-weight': 800, 'font-size': fs * .95, fill: '#10100c', 'letter-spacing': '.1em'});
      const w = tt.getBBox().width + fs * 2.1; r.setAttribute('width', w);
      t.setAttribute('transform', `translate(${W - w - fs * .1},${H - fs * .75})`);
      if (!calm && step === 0) gsap.fromTo(t, {opacity: .55}, {opacity: 1, duration: .9, yoyo: true, repeat: 3, ease: 'sine.inOut'});
      return;
    }
    const x = P.X(pin[0]), y = P.Y(pin[1]), rr = P.km(50);
    mk('circle', {cx: x, cy: y, r: rr, fill: '#FFB000', 'fill-opacity': revealed ? .06 : .14, stroke: '#FFB000', 'stroke-width': 1.6, 'stroke-dasharray': '5 4', 'stroke-opacity': revealed ? .5 : 1}, g);
    if (!revealed) txt(g, x + rr * .72, y - rr * .72 - 3, L.ring, {'font-family': 'Figtree', 'font-weight': 800, 'font-size': fs * .85, fill: '#FFB000'});
    const hd = mk('g', {transform: `translate(${x},${y})`, style: revealed ? '' : 'cursor:grab'}, g);
    mk('path', {d: `M0,0 C${-fs * .3},${-fs * .9} ${-fs * .95},${-fs * 1.25} ${-fs * .95},${-fs * 1.9} a${fs * .95},${fs * .95} 0 1,1 ${fs * 1.9},0 C${fs * .95},${-fs * 1.25} ${fs * .3},${-fs * .9} 0,0z`, fill: revealed ? '#c9c4b5' : '#F2F1EC', stroke: '#10100c', 'stroke-width': 1.2}, hd);
    mk('circle', {cx: 0, cy: -fs * 1.9, r: fs * .36, fill: '#10100c'}, hd);
  }
  function toLL(e) { const r = svg.getBoundingClientRect(); const x = (e.clientX - r.left) * geo.W / r.width, y = (e.clientY - r.top) * geo.H / r.height; return [geo.P.lon(Math.max(4, Math.min(geo.W - 4, x))), geo.P.lat(Math.max(4, Math.min(geo.H - 4, y)))]; }
  let dragging = false;
  svg.addEventListener('pointerdown', e => {
    if (revealed) return;
    const hitTray = !pin && e.target.closest('#lampTray'), hitPin = pin && e.target.closest('#lampPin');
    if (!hitTray && !hitPin) return;
    dragging = true; svg.setPointerCapture(e.pointerId); e.preventDefault();
  });
  svg.addEventListener('pointermove', e => { if (!dragging) return; pin = toLL(e); paintPin(); });
  const drop = () => { if (!dragging) return; dragging = false; if (!pin) return; if (step === 0) { step = 1; sure.on(); say('lampSay', L.say1); } };
  svg.addEventListener('pointerup', drop); svg.addEventListener('pointercancel', drop);
  function reveal() {
    revealed = true; step = 2;
    const d = hav(pin, GEO.lampC), inside = d <= 50;
    sure.grade(inside, conf, inside ? L.inside : L.outside);
    paintPin(); paintReveal(true);
    say('lampSay', L.say2); Kit.show('lampKeep');
  }
  function paintReveal(anim) {
    const {P, fs, W, pl} = geo, g = geo.reveal; g.innerHTML = '';
    const sea = svg.querySelector('#lampSea'), deep = svg.querySelector('#lampDeep'), truth = svg.querySelector('#lampTruth');
    const T0 = anim && !calm;
    if (T0) { gsap.to(sea, {attr: {fill: '#3a3326'}, duration: .9, delay: .9}); gsap.to(deep, {attr: {fill: '#100e0a'}, duration: .9, delay: .9}); gsap.fromTo(truth, {opacity: 0}, {opacity: 1, duration: .4}); }
    else { sea.setAttribute('fill', '#3a3326'); deep.setAttribute('fill', '#100e0a'); truth.setAttribute('opacity', 1); }
    const C = GEO.lampC, cx = P.X(C[0]), cy = P.Y(C[1]), px = P.X(pin[0]), py = P.Y(pin[1]);
    const contour = mk('path', {d: path(GEO.deep, P), fill: 'none', stroke: '#FFB000', 'stroke-opacity': .3, 'stroke-width': .9}, g);
    pl.reserve({x: cx - fs, y: cy - fs, width: fs * 2, height: fs * 2});
    pl.reserve({x: px - fs, y: py - fs * 2.9, width: fs * 2, height: fs * 3});
    const PILL = [fs * .55, fs * .3];
    // the miss first: it is what the reader is looking for
    const miss = mk('line', {x1: px, y1: py, x2: cx, y2: cy, stroke: '#FFB000', 'stroke-width': 2.2, 'stroke-linecap': 'round'}, g);
    const km = Math.round(hav(pin, C));
    const mp = pill(g, 0, 0, L.off(km), fs * .95, '#10100c', '#F2F1EC');
    const ang = Math.atan2(cy - py, cx - px), nx = -Math.sin(ang), ny = Math.cos(ang), mx = (px + cx) / 2, my = (py + cy) / 2;
    pl.put(mp._t, [[mx + nx * fs * 1.5, my + ny * fs * 1.5 + fs * .35, 'middle'], [mx - nx * fs * 1.5, my - ny * fs * 1.5 + fs * .35, 'middle'], [px, py - fs * 3.2, 'middle'], [px, py + fs * 1.6, 'middle'], [mx, my + fs * 2.2, 'middle']], PILL);
    mp._fit();
    const ring = mk('circle', {cx, cy, r: fs * .9, fill: 'none', stroke: '#FFB000', 'stroke-width': 2}, g);
    // the two shores
    const seg = (a, b, s, cands) => {
      const l = mk('line', {x1: P.X(a[0]), y1: P.Y(a[1]), x2: P.X(b[0]), y2: P.Y(b[1]), stroke: '#F2F1EC', 'stroke-width': 1.2, 'stroke-opacity': .8}, g);
      const x = (P.X(a[0]) + P.X(b[0])) / 2, y = (P.Y(a[1]) + P.Y(b[1])) / 2;
      const p = pill(g, x, y, s, fs * .85, '#10100c', '#FFB000');
      pl.put(p._t, cands(x, y), PILL); p._fit();
      return [l, p];
    };
    const sTun = seg(GEO.pts.lampTun, GEO.pts.nearTun, L.kmTun, (x, y) => [[x, y - fs * .55, 'middle'], [x, y + fs * 1.4, 'middle'], [x - fs * .8, y + fs * .35, 'end'], [x + fs * .8, y + fs * .35, 'start']]);
    const sSic = seg(GEO.pts.lampSic, GEO.pts.nearSic, L.kmSic, (x, y) => [[x + fs * .7, y + fs * .35, 'start'], [x - fs * .7, y + fs * .35, 'end'], [x, y - fs * .6, 'middle'], [x, y + fs * 1.5, 'middle']]);
    // the shelf, named on a spot that is really shallow
    const sl = txt(g, 0, 0, L.shelf, {'font-family': 'Figtree', 'font-weight': 800, 'font-size': fs * .8, fill: '#F2F1EC', 'fill-opacity': .8, 'letter-spacing': '.08em'});
    const shelfSpots = [[11.7, 34.3], [12.2, 34.65], [11.4, 33.8], [12.6, 34.2]].filter(p => !isDeep(p));
    pl.put(sl, shelfSpots.map(p => [P.X(p[0]), P.Y(p[1]), 'middle']));
    // the latitude: further south than Tunis
    const latY = P.Y(35.5);
    const latL = mk('line', {x1: 0, x2: W, y1: latY, y2: latY, stroke: '#FFB000', 'stroke-width': 1, 'stroke-dasharray': '1 4', 'stroke-opacity': .9}, g);
    const tn = GEO.pts.tunis, tx = P.X(tn[0]), ty = P.Y(tn[1]);
    const td = mk('circle', {cx: tx, cy: ty, r: 2.8, fill: '#10100c'}, g);
    const tl = pill(g, 0, 0, L.tunisLat, fs * .8, '#10100c', '#F2F1EC');
    pl.put(tl._t, [[tx + fs * .9, ty + fs * .3, 'start'], [tx, ty - fs * .75, 'middle'], [tx, ty + fs * 1.35, 'middle'], [tx - fs * .9, ty + fs * .3, 'end']], PILL);
    tl._fit();
    const ll = txt(g, 0, 0, L.lat, {'font-family': 'JetBrains Mono, monospace', 'font-weight': 700, 'font-size': fs * .85, fill: '#FFB000'});
    pl.put(ll, [[W - 4, latY - 4, 'end'], [W - 4, latY + fs, 'end'], [4, latY - 4, 'start'], [4, latY + fs, 'start']]);
    if (T0) {
      const len = Math.hypot(cx - px, cy - py);
      gsap.fromTo(miss, {attr: {'stroke-dasharray': `${len} ${len}`, 'stroke-dashoffset': len}}, {attr: {'stroke-dashoffset': 0}, duration: .6, ease: 'power2.inOut'});
      gsap.fromTo(ring, {attr: {r: fs * 3}, opacity: 0}, {attr: {r: fs * .9}, opacity: 1, duration: .5, ease: 'power3.out'});
      gsap.from(mp, {opacity: 0, duration: .3, delay: .5});
      gsap.from([contour, sl], {opacity: 0, duration: .6, delay: 1.0, stagger: .12});
      gsap.from([...sTun, ...sSic], {opacity: 0, duration: .4, delay: 1.6, stagger: .1});
      gsap.from([latL, ll, td, tl], {opacity: 0, duration: .5, delay: 2.1, stagger: .08});
    }
  }
  function reset() {
    pin = null; step = 0; conf = 0; revealed = false; sure.reset(); Kit.hide('lampKeep'); say('lampSay', L.say0); draw();
  }
  say('lampSay', L.say0);
  watchSize(svg, () => draw());
  Kit.onShow.lamp = () => draw();
  Kit.play.lamp = async () => { reset(); pin = [13.05, 36.55]; step = 1; sure.on(); paintPin(); await wait(200); $('lampSure').querySelector('[data-v="70"]').click(); await wait(2900); };
})();

/* =====================================================================
   2 · Spot the fake: London's christenings 1629-1710 (Arbuthnot), beside two made-up records
   ===================================================================== */
(() => {
  const C = T.births, boxEl = $('birthsBox');
  // One square a year: 'B' when more boys than girls were christened, 'G' when more girls.
  const SEQ = [
    'BGBBBBGBBBBBBBBBBBBBBBBGBBBBBBBBBBBBGBBGBBBBBBBBBBBGBBBBBBBBBBBBBBBBBBBBBBBGBBBBBB', // made up: 75 of 82
    'BBBBBBBBGBGGBBBGBGGBBBBGBGBBBGBBBGGBBBBGBGBBBBBGGBBGGBBGBBBBBGBBBBBBBBBBBBGBBBBBGB', // made up: 61 of 82
    'B'.repeat(82)                    // London 1629-1710, HistData::Arbuthnot: more boys in all 82 years
  ];
  const REAL = 2, COLS = 21, ROWS = 4;
  const boys = s => s.split('B').length - 1;
  const strips = [...boxEl.querySelectorAll('.strip')];
  let pick = -1, conf = 0, revealed = false;
  const sure = Sure($('birthsSure'), T.howSure, v => { conf = v; reveal(); });
  function drawStrip(k, show) {
    const st = strips[k], svg = st.querySelector('svg');
    svg.innerHTML = '';
    const r = svg.getBoundingClientRect(); if (!r.width) return;
    const W = r.width, H = r.height; svg.setAttribute('viewBox', `0 0 ${W} ${H}`);
    const p = Math.min(W / COLS, H / ROWS), ox = (W - p * COLS) / 2, oy = (H - p * ROWS) / 2, s = SEQ[k];
    const g = p * .13, w = p - 2 * g, lw = Math.max(1, p * .1);
    for (let i = 0; i < s.length; i++) {
      const x = ox + (i % COLS) * p, y = oy + Math.floor(i / COLS) * p;
      if (show && s[i] === 'G') {           // the tell: a year the girls won
        const hl = mk('rect', {x: x + g * .25, y: y + g * .25, width: p - g * .5, height: p - g * .5, rx: p * .2, fill: '#FFE600'}, svg);
        if (!calm && show === 'anim') gsap.from(hl, {opacity: 0, scale: .4, transformOrigin: 'center', duration: .3, delay: .25 + .12 * k + i * .004});
      }
      if (s[i] === 'B') mk('rect', {x: x + g, y: y + g, width: w, height: w, rx: p * .12, fill: '#10100c'}, svg);
      else mk('rect', {x: x + g + lw / 2, y: y + g + lw / 2, width: w - lw, height: w - lw, rx: p * .1, fill: 'none', stroke: '#10100c', 'stroke-width': lw}, svg);
    }
  }
  const drawAll = show => strips.forEach((_, k) => drawStrip(k, show));
  strips.forEach((st, k) => st.addEventListener('click', () => {
    if (revealed) return; pick = k;
    strips.forEach((x, j) => x.classList.toggle('on', j === k));
    sure.on(); say('birthsSay', C.say1('ABC'[k]));
  }));
  function reveal() {
    revealed = true;
    strips.forEach((st, k) => {
      const lr = st.querySelector('.lr'); lr.innerHTML = `${C.ahead}<b>${boys(SEQ[k])}</b>`;
      st.classList.toggle('fake', k !== REAL); st.classList.toggle('real', k === REAL);
      if (!calm) gsap.to(lr, {opacity: 1, duration: .3, delay: .2 + .1 * k}); else lr.style.opacity = 1;
    });
    const stamp = strips[REAL].querySelector('.stamp');
    if (!calm) gsap.fromTo(stamp, {opacity: 0, scale: 1.6}, {opacity: 1, scale: 1, duration: .35, delay: .7, ease: 'back.out(2)'}); else stamp.style.opacity = 1;
    drawAll('anim');
    sure.grade(pick === REAL, conf, `${'ABC'[pick]} · ${pick === REAL ? T.right : T.wrong}`);
    say('birthsSay', C.say2); Kit.show('birthsKeep');
  }
  function reset() {
    pick = -1; conf = 0; revealed = false; sure.reset(); Kit.hide('birthsKeep'); say('birthsSay', C.say0);
    strips.forEach(st => { st.classList.remove('on', 'fake', 'real'); const lr = st.querySelector('.lr'); lr.textContent = ''; lr.style.opacity = 0; st.querySelector('.stamp').style.opacity = 0; gsap.set(st.querySelector('.stamp'), {clearProps: 'transform'}); });
    drawAll(false);
  }
  say('birthsSay', C.say0);
  watchSize(boxEl, () => drawAll(revealed));
  Kit.onShow.births = () => drawAll(revealed);
  Kit.play.births = async () => { reset(); strips[0].click(); await wait(150); $('birthsSure').querySelector('[data-v="80"]').click(); await wait(1500); };
})();

/* =====================================================================
   3 · Glance and count: Jevons's beans
   ===================================================================== */
(() => {
  const B = T.bean, cv = $('beanCv'), lid = $('beanLid'), pad = $('beanPad'), go = $('beanGo');
  const COUNTS = [4, 7, 11];
  // Jevons (1871): share of throws estimated right, by number of beans (HistData::Jevons)
  const JEV = [[3, 100], [4, 100], [5, 95.3], [6, 81.6], [7, 72.4], [8, 56.3], [9, 62.3], [10, 43.0], [11, 37.7], [12, 42.2], [13, 23.1], [14, 28.6], [15, 18.2]];
  let round = 0, answers = [], beans = [], phase = 'ready', conf = 0, seed = 11;
  const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  const sure = Sure($('beanSure'), B.sure, v => { conf = v; reveal(); });
  function layout(n, W, H) {
    const out = [], m = Math.min(W, H) * .16, r = Math.min(W, H) * .052;
    let tries = 0;
    while (out.length < n && tries++ < 4000) {
      const x = m + rnd() * (W - 2 * m), y = m + rnd() * (H - 2 * m);
      if (out.every(b => Math.hypot(b.x - x, b.y - y) > r * 2.6)) out.push({x, y, a: rnd() * Math.PI, r});
    }
    return out;
  }
  function paint(t = 1) {
    const {x, W, H} = Kit.fitCanvas(cv); x.clearRect(0, 0, W, H);
    for (const b of beans) {
      const k = Math.min(1, Math.max(0, t * 1.4 - b.d)), e = 1 - Math.pow(1 - k, 3);
      const bx = b.x + (b.fx - b.x) * (1 - e), by = b.y + (b.fy - b.y) * (1 - e);
      x.save(); x.translate(bx, by); x.rotate(b.a + (1 - e) * 3);
      x.fillStyle = '#00000022'; x.beginPath(); x.ellipse(b.r * .18, b.r * .32, b.r * 1.05, b.r * .68, 0, 0, 7); x.fill();
      x.fillStyle = '#15120f'; x.beginPath(); x.ellipse(0, 0, b.r * 1.05, b.r * .66, 0, 0, 7); x.fill();
      x.fillStyle = '#ffffff40'; x.beginPath(); x.ellipse(-b.r * .35, -b.r * .22, b.r * .38, b.r * .14, -.3, 0, 7); x.fill();
      x.strokeStyle = '#ffffff22'; x.lineWidth = 1; x.beginPath(); x.moveTo(-b.r * .5, b.r * .08); x.quadraticCurveTo(0, b.r * .28, b.r * .5, b.r * .08); x.stroke();
      x.restore();
    }
  }
  const lidTo = (shut, dur) => new Promise(res => {
    if (shut) lid.style.visibility = 'visible';
    const fin = () => { if (!shut) lid.style.visibility = 'hidden'; res(); };
    if (calm || !dur) { gsap.set(lid, {xPercent: shut ? 0 : -102}); return fin(); }
    gsap.to(lid, {xPercent: shut ? 0 : -102, duration: dur, ease: shut ? 'power3.out' : 'power2.inOut', onComplete: fin});
  });
  const shut = s => { lid.textContent = s; gsap.set(lid, {xPercent: 0}); lid.style.visibility = 'visible'; };
  shut(B.lidReady);
  async function throwBeans() {
    if (phase !== 'ready') return; phase = 'flash';
    go.disabled = true; beans = []; paint(1);
    await lidTo(false, .25);
    const r = cv.getBoundingClientRect();
    beans = layout(COUNTS[round], r.width, r.height).map((b, i) => Object.assign(b, {fx: r.width * (.3 + rnd() * .4), fy: r.height + 30, d: i * .04}));
    if (calm) paint(1); else await new Promise(res => gsap.to({t: 0}, {t: 1, duration: .55, ease: 'none', onUpdate() { paint(this.targets()[0].t); }, onComplete: res}));
    await wait(500);
    lid.textContent = B.lid; await lidTo(true, .22);
    phase = 'answer'; pad.classList.remove('gone', 'off'); Kit.hide('beanCtl'); say('beanSay', B.ask);
  }
  function mark(i) {
    const n = answers[i], ok = n === COUNTS[i], chip = $('beanRounds').children[i];
    chip.className = ok ? 'ok' : 'no'; chip.innerHTML = `<b>${B.fb(COUNTS[i], n)}</b><span>${ok ? '✓' : '✗'}</span>`;
  }
  async function answer(n) {
    if (phase !== 'answer') return; phase = 'feedback';
    answers.push(n);
    pad.querySelectorAll('button').forEach(b => b.classList.toggle('on', +b.dataset.n === n));
    if (round === 2) {   // the last throw is the bet: say how sure before the lid opens
      await wait(calm ? 0 : 200);
      pad.classList.add('gone'); sure.ask(B.sureN(n)); Kit.show('beanSure'); sure.on(); phase = 'sure'; say('beanSay', ''); return;
    }
    mark(round);
    await lidTo(false, .3); pad.classList.add('off');
    await wait(calm ? 300 : 900);
    round++;
    pad.classList.add('gone'); pad.querySelectorAll('button').forEach(b => b.classList.remove('on'));
    lid.textContent = B.lidReady; await lidTo(true, .25); beans = []; paint(1);
    Kit.show('beanCtl'); go.disabled = false; $('beanRound').textContent = B.round(round + 1); phase = 'ready'; say('beanSay', B.say0);
  }
  pad.addEventListener('click', e => { const b = e.target.closest('button'); if (b) answer(+b.dataset.n); });
  go.addEventListener('click', throwBeans);
  function chart(anim) {
    const svg = $('beanChart'); svg.classList.remove('gone'); svg.innerHTML = '';
    const {W, H} = Kit.fitSvg(svg), u = cq(svg), fs = Math.max(9, Math.min(1.3 * u, 12.5));
    const L0 = fs * 3.2, R0 = fs * 1.2, T0 = fs * 2.6, B0 = fs * 2.8;
    const X = n => L0 + (n - 3) / 12 * (W - L0 - R0), Y = p => T0 + (1 - p / 100) * (H - T0 - B0);
    const ink = '#15120f';
    mk('rect', {x: 0, y: 0, width: W, height: H, fill: '#f6f3ea'}, svg);
    for (const p of [0, 50, 100]) { mk('line', {x1: L0, x2: W - R0, y1: Y(p), y2: Y(p), stroke: ink, 'stroke-opacity': .14}, svg); txt(svg, L0 - fs * .4, Y(p) + fs * .35, p + '%', {'font-family': 'Figtree', 'font-weight': 700, 'font-size': fs * .85, fill: ink, 'fill-opacity': .6, 'text-anchor': 'end'}); }
    for (const n of [3, 5, 10, 15]) txt(svg, X(n), H - B0 + fs * 1.25, n, {'font-family': 'Figtree', 'font-weight': 700, 'font-size': fs * .85, fill: ink, 'fill-opacity': .6, 'text-anchor': 'middle'});
    txt(svg, L0, T0 - fs * .9, B.yAxis, {'font-family': 'Figtree', 'font-weight': 800, 'font-size': fs * .8, fill: ink, 'letter-spacing': '.08em'});
    txt(svg, W - R0, H - fs * .35, B.xAxis, {'font-family': 'Figtree', 'font-weight': 800, 'font-size': fs * .8, fill: ink, 'letter-spacing': '.08em', 'text-anchor': 'end'});
    const area = mk('path', {d: `M${X(3)},${Y(0)} ` + JEV.map(([n, p]) => `L${X(n)},${Y(p)}`).join(' ') + ` L${X(15)},${Y(0)}Z`, fill: '#9B5CFF', 'fill-opacity': .18}, svg);
    const line = mk('polyline', {points: JEV.map(([n, p]) => X(n) + ',' + Y(p)).join(' '), fill: 'none', stroke: '#5a2ea6', 'stroke-width': 3, 'stroke-linejoin': 'round', 'stroke-linecap': 'round'}, svg);
    const dots = JEV.map(([n, p]) => mk('circle', {cx: X(n), cy: Y(p), r: fs * .28, fill: '#5a2ea6'}, svg));
    // the reader's three throws, on the same axis: filled if right
    const marks = COUNTS.map((n, i) => {
      const ok = answers[i] === n, g = mk('g', {}, svg), y = Y(JEV.find(j => j[0] === n)[1]);
      mk('line', {x1: X(n), x2: X(n), y1: y, y2: H - B0, stroke: '#15120f', 'stroke-opacity': .35, 'stroke-dasharray': '2 3'}, g);
      mk('circle', {cx: X(n), cy: y, r: fs * .78, fill: ok ? '#15120f' : '#f6f3ea', stroke: '#15120f', 'stroke-width': 2}, g);
      const m = mk('path', {d: ok ? `M${X(n) - fs * .35},${y} l${fs * .25},${fs * .27} l${fs * .45},${-fs * .5}` : `M${X(n) - fs * .3},${y - fs * .3} l${fs * .6},${fs * .6} M${X(n) + fs * .3},${y - fs * .3} l${-fs * .6},${fs * .6}`, fill: 'none', stroke: ok ? '#f6f3ea' : '#15120f', 'stroke-width': 2, 'stroke-linecap': 'round'}, g);
      return g;
    });
    const yl = mk('g', {}, svg);   // the key, top right, clear of the curve
    const ylt = txt(yl, W - R0, T0 - fs * .9, B.you, {'font-family': 'Figtree', 'font-weight': 800, 'font-size': fs * .8, fill: ink, 'letter-spacing': '.08em', 'text-anchor': 'end'});
    const kb = ylt.getBBox(); mk('circle', {cx: kb.x - fs * .62, cy: kb.y + kb.height / 2, r: fs * .38, fill: 'none', stroke: ink, 'stroke-width': 1.6}, yl);
    if (anim && !calm) {
      const len = line.getTotalLength();
      gsap.fromTo(line, {attr: {'stroke-dasharray': `${len} ${len}`, 'stroke-dashoffset': len}}, {attr: {'stroke-dashoffset': 0}, duration: .9, ease: 'power2.inOut'});
      gsap.from([area, ...dots], {opacity: 0, duration: .5, delay: .4});
      gsap.from([...marks, yl], {opacity: 0, scale: .6, transformOrigin: 'center', duration: .35, stagger: .12, delay: .9, ease: 'back.out(2)'});
    }
  }
  async function reveal() {
    phase = 'done'; mark(2);
    sure.grade(answers[2] === COUNTS[2], conf, B.note(COUNTS[2], answers[2]));
    await lidTo(false, .3);                       // the beans you bet on, then where they sit on Jevons's curve
    await wait(calm ? 0 : 1100);
    lid.style.visibility = 'hidden'; cv.style.visibility = 'hidden'; Kit.hide('beanRounds');
    requestAnimationFrame(() => chart(true));
    say('beanSay', B.say2); Kit.show('beanKeep');
  }
  function reset() {
    round = 0; answers = []; beans = []; phase = 'ready'; conf = 0; seed = 11;
    cv.style.visibility = ''; shut(B.lidReady);
    $('beanChart').classList.add('gone'); Kit.show('beanRounds');
    [...$('beanRounds').children].forEach((c, i) => { c.className = ''; c.innerHTML = `<span>${B.round(i + 1).replace(/ (OF|DI) 3/, '')}</span>`; });
    pad.classList.add('gone'); pad.querySelectorAll('button').forEach(b => b.classList.remove('on'));
    Kit.show('beanCtl'); go.disabled = false; $('beanRound').textContent = B.round(1);
    Kit.hide('beanSure'); sure.reset(); Kit.hide('beanKeep'); say('beanSay', B.say0); paint(1);
  }
  reset();
  watchSize(cv, () => { if (phase === 'done') chart(false); else paint(1); });
  Kit.onShow.bean = () => { if (phase === 'done') chart(false); else paint(1); };
  Kit.play.bean = async () => {
    reset();
    for (const n of [4, 7, 9]) { await throwBeans(); await wait(120); await answer(n); await wait(80); }
    $('beanSure').querySelector('[data-v="70"]').click(); await wait(3400);
  };
})();

/* =====================================================================
   4 · Stake your chips: the 1954 polio vaccine trial (Francis et al. 1955)
   ===================================================================== */
(() => {
  const R = T.polio, felt = $('polioFelt'), spots = [...felt.querySelectorAll('.spot')], go = $('polioGo');
  // Polio cases (paralytic or not) per 100,000 children in the randomised areas, HistData::PolioTrials:
  // vaccine 57 of 200,745; salt water 142 of 201,229; parents said no 157 of 338,778.
  const RATE = [57 / 200745 * 1e5, 142 / 201229 * 1e5, 157 / 338778 * 1e5], WIN = 1;
  const chips = []; let placed = new Array(10).fill(-1), done = false, dragging = null, downAt = null;
  for (let i = 0; i < 10; i++) { const c = document.createElement('div'); c.className = 'token'; c.dataset.i = i; felt.appendChild(c); chips.push(c); }
  const count = s => placed.filter(p => p === s).length;
  function spotXY(s, j) { // chip j of spot s, stacked up from the floor of the column
    const fr = felt.getBoundingClientRect(), r = spots[s].getBoundingClientRect(), u = cq(felt);
    return [r.left - fr.left + r.width / 2, r.bottom - fr.top - 7.4 * u - j * .62 * u];
  }
  function rackXY(j, n) { const fr = felt.getBoundingClientRect(), u = cq(felt); return [fr.width / 2 + (j - (n - 1) / 2) * 3.4 * u, fr.height - 4.6 * u]; }
  function layout(anim) {
    const inRack = chips.filter((_, i) => placed[i] === -1), per = [0, 0, 0];
    if (!done) chips.forEach((c, i) => {
      if (c === dragging) return;
      const s = placed[i];
      const [x, y] = s === -1 ? rackXY(inRack.indexOf(c), inRack.length) : spotXY(s, per[s]++);
      c.style.zIndex = s === -1 ? 2 : 3 + per[s];
      if (anim && !calm) gsap.to(c, {x, y, duration: .28, ease: 'power3.out'}); else gsap.set(c, {x, y});
    });
    if (!done) spots.forEach((sp, s) => { sp.querySelector('.pc').textContent = count(s) * 10 + '%'; sp.classList.toggle('hot', count(s) > 0); });
    if (!done) $('polioRack').textContent = R.rack(inRack.length);
    go.disabled = inRack.length > 0 || done;
  }
  const overSpot = (x, y) => spots.findIndex(sp => { const r = sp.getBoundingClientRect(); return x >= r.left && x <= r.right && y >= r.top && y <= r.bottom; });
  felt.addEventListener('pointerdown', e => {
    if (done) return;
    const c = e.target.closest('.token'); downAt = {x: e.clientX, y: e.clientY, spot: e.target.closest('.spot')};
    if (c) { dragging = c; felt.setPointerCapture(e.pointerId); c.style.zIndex = 50; e.preventDefault(); }
  });
  felt.addEventListener('pointermove', e => {
    if (!dragging) return;
    const fr = felt.getBoundingClientRect(); gsap.set(dragging, {x: e.clientX - fr.left, y: e.clientY - fr.top});
    const s = overSpot(e.clientX, e.clientY); spots.forEach((sp, k) => sp.classList.toggle('hot', k === s || count(k) > 0));
  });
  felt.addEventListener('pointerup', e => {
    if (done || !downAt) return;
    const moved = Math.hypot(e.clientX - downAt.x, e.clientY - downAt.y) > 6;
    if (dragging) {
      const i = +dragging.dataset.i; dragging.style.zIndex = ''; dragging = null;
      if (moved) placed[i] = overSpot(e.clientX, e.clientY);
      else if (placed[i] !== -1) placed[i] = -1;                 // tap a chip on the table: take it back
      else { const s = overSpot(e.clientX, e.clientY); if (s >= 0) placed[i] = s; }
    } else if (downAt.spot) {                                     // tap a column: add one chip from the rack
      const i = placed.indexOf(-1); if (i >= 0) placed[i] = +downAt.spot.dataset.i;
    }
    downAt = null; layout(true);
  });
  function truth(anim) { // in each column the true rate rises, all three on one scale
    const max = Math.max(...RATE), u = cq(felt);
    const avail = Math.max(12, Math.min(...spots.map(sp => { const tb = sp.querySelector('b'); return sp.clientHeight - (tb.offsetTop + tb.offsetHeight) - 7.6 * u; })));
    spots.forEach((sp, s) => {
      let bar = sp.querySelector('.truth');
      if (!bar) { bar = document.createElement('div'); bar.className = 'truth'; bar.innerHTML = '<b></b>'; sp.appendChild(bar); }
      bar.querySelector('b').textContent = fmt(Math.round(RATE[s]));
      sp.querySelector('.pc').innerHTML = `<small>${R.chips(count(s))}</small>`;
      const h = Math.max(3, RATE[s] / max * avail) + 'px';
      gsap.killTweensOf(bar);
      if (anim && !calm) gsap.fromTo(bar, {height: 0}, {height: h, duration: .8, delay: .15 * s, ease: 'power3.out'}); else bar.style.height = h;
    });
  }
  async function bet() {
    if (done || placed.includes(-1)) return; done = true; go.disabled = true;
    const n = [0, 1, 2].map(count), top = n.indexOf(Math.max(...n)), pct = n[top] * 10, k = n[WIN];
    spots.forEach((sp, s) => sp.classList.add(s === WIN ? 'win' : 'lose'));
    felt.classList.add('done'); $('polioRack').textContent = R.legend;
    const pr = spots[WIN].querySelector('.pc').getBoundingClientRect(), fr = felt.getBoundingClientRect();
    const tx = pr.left - fr.left + cq(felt) * 1.2, ty = pr.top - fr.top + pr.height / 2;
    chips.forEach((c, i) => {
      if (calm) { c.style.opacity = 0; return; }
      if (placed[i] !== WIN) gsap.to(c, {y: '-=' + cq(felt) * 26, opacity: 0, duration: .5, delay: .03 * i, ease: 'power2.in'});
      else gsap.timeline({delay: .55}).to(c, {scale: 1.12, duration: .16, yoyo: true, repeat: 1}).to(c, {x: tx, y: ty, scale: .4, opacity: 0, duration: .45, ease: 'power2.in', delay: .3 + .04 * i});
    });
    const g = document.createElement('div'); g.id = 'polioGrade'; $('polioBox').after(g);
    g.className = 'grade ' + (top === WIN ? 'ok' : 'no');
    g.innerHTML = `<i>${top === WIN ? CHECK : CROSS}</i><span>${R.spots[top][0]} · ${T.saidPct(pct)} · ${R.kept(k).replace(/<\/?b>/g, '')}</span>`;
    if (!calm) gsap.from(g, {opacity: 0, y: 6, duration: .35, ease: 'power3.out'});
    $('polioBox').dataset.state = 'done';
    say('polioSay', R.say2); Kit.hide('polioCtl'); Kit.show('polioKeep');
    await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));   // let the column settle first
    layout(false); truth(true);
    await wait(calm ? 0 : 1200);
  }
  go.addEventListener('click', bet);
  function reset() {
    placed = new Array(10).fill(-1); done = false;
    $('polioGrade')?.remove(); $('polioBox').dataset.state = '';
    felt.classList.remove('done');
    spots.forEach(sp => { sp.classList.remove('win', 'lose', 'hot'); sp.querySelector('.truth')?.remove(); });
    chips.forEach(c => { gsap.killTweensOf(c); c.style.opacity = ''; gsap.set(c, {scale: 1, opacity: 1}); });
    Kit.show('polioCtl'); Kit.hide('polioKeep'); say('polioSay', R.say0); layout(false);
  }
  say('polioSay', R.say0);
  watchSize(felt, () => { layout(false); if ($('polioBox').dataset.state === 'done') truth(false); });
  Kit.onShow.polio = () => { layout(false); if ($('polioBox').dataset.state === 'done') truth(false); };
  Kit.play.polio = async () => { reset(); [0, 0, 1, 1, 1, 1, 1, 2, 2, 2].forEach((s, i) => placed[i] = s); layout(false); await wait(200); await bet(); await wait(600); };
})();

/* =====================================================================
   5 · Pour by ear: the note of the air in a filling flask
   ===================================================================== */
(() => {
  const P = T.pour, svg = $('pourSvg'), cv = $('pourCv'), hold = $('pourHold'), done = $('pourDone');
  const DEPTH = 24, RAD = 3.5, C = 343;                    // cm, cm, m/s
  const f = h => C / (4 * ((DEPTH - Math.min(h, DEPTH)) / 100 + .61 * RAD / 100));   // Hz
  let level = 0, pouring = false, spilled = false, stopped = false, conf = 0, raf = 0, last = 0, phase = 0, revealed = false;
  let ac = null, nodes = null;
  const sure = Sure($('pourSure'), P.sure, v => { conf = v; reveal(); });
  function audioStart() {
    try {
      if (!ac) {
        ac = new (window.AudioContext || window.webkitAudioContext)();
        const len = ac.sampleRate * 2, buf = ac.createBuffer(1, len, ac.sampleRate), d = buf.getChannelData(0);
        for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
        const src = ac.createBufferSource(); src.buffer = buf; src.loop = true;
        const bp = ac.createBiquadFilter(); bp.type = 'bandpass'; bp.Q.value = 22;
        const bp2 = ac.createBiquadFilter(); bp2.type = 'bandpass'; bp2.Q.value = 22;
        const lp = ac.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 900;
        const g = ac.createGain(); g.gain.value = 0; const gs = ac.createGain(); gs.gain.value = 0;
        src.connect(bp); bp.connect(bp2); bp2.connect(g); g.connect(ac.destination);
        src.connect(lp); lp.connect(gs); gs.connect(ac.destination);
        src.start(); nodes = {bp, bp2, g, gs};
      }
      if (ac.state === 'suspended') ac.resume();
    } catch (e) { ac = null; }
  }
  function audioSet(on) {
    if (!nodes) return; const t = ac.currentTime, fr = f(level);
    nodes.bp.frequency.setTargetAtTime(fr, t, .02); nodes.bp2.frequency.setTargetAtTime(fr, t, .02);
    nodes.g.gain.setTargetAtTime(on ? .55 : 0, t, on ? .03 : .06); nodes.gs.gain.setTargetAtTime(on ? .05 : 0, t, .05);
  }
  function caption() {
    if (spilled) return P.caps[4];
    if (!pouring && level === 0) return P.caps[0];
    const left = DEPTH - level; return left > 12 ? P.caps[1] : left > 3 ? P.caps[2] : P.caps[3];
  }
  function flask() {
    svg.innerHTML = '';
    const {W, H} = Kit.fitSvg(svg), u = cq(svg), fs = Math.max(9, Math.min(1.25 * u, 12));
    if (W < 20 || H < 40) return;
    const fw = Math.min(W * .44, H * .3), fx = (W - fw) / 2, top = H * .26, bot = H - fs * 1.7, fh = bot - top;
    const defs = mk('defs', {}, svg);
    const lg = mk('linearGradient', {id: 'steel', x1: 0, x2: 1, y1: 0, y2: 0}, defs);
    [['0', '#7d8b88'], ['.18', '#e9f0ee'], ['.42', '#a9b6b3'], ['.7', '#d8e1df'], ['1', '#6c7a77']].forEach(([o, c]) => mk('stop', {offset: o, 'stop-color': c}, lg));
    // the tap, coming in from the left
    const sx = W / 2, py = fs * 1.1, sy = Math.max(py + fs * 1.6, top * .45);
    mk('path', {d: `M0,${py} H${sx - fs * .9} Q${sx},${py} ${sx},${py + fs * .9} V${sy}`, fill: 'none', stroke: '#c9d3d1', 'stroke-width': fs * 1.1}, svg);
    mk('rect', {x: sx - fs * .75, y: sy - 1, width: fs * 1.5, height: fs * .55, rx: 2, fill: '#9aa6a4'}, svg);
    mk('rect', {x: sx - fs * 1.6, y: py - fs * 1.05, width: fs * 1.4, height: fs * .5, rx: fs * .25, fill: '#9aa6a4'}, svg);
    mk('rect', {id: 'pourStream', x: sx - fs * .22, y: sy + fs * .55, width: fs * .44, height: Math.max(0, top - sy - fs * .55 + 3), rx: fs * .22, fill: '#e7fbff', opacity: pouring ? .95 : 0}, svg);
    // the flask: opaque steel, open at the top
    mk('rect', {x: fx, y: top, width: fw, height: fh, rx: fw * .14, fill: 'url(#steel)', stroke: '#10100c', 'stroke-opacity': .35, 'stroke-width': 1}, svg);
    mk('rect', {x: fx - 1.5, y: top - fs * .15, width: fw + 3, height: fs * .55, rx: fs * .27, fill: '#6c7a77'}, svg);
    if (revealed) { // the cut-away: water, the brim, the gap
      const inner = {x: fx + fw * .16, y: top + fs * .55, w: fw * .68, h: fh - fs * 1.2};
      const wy = inner.y + inner.h * (1 - Math.min(level, DEPTH) / DEPTH);
      mk('rect', {x: inner.x, y: inner.y, width: inner.w, height: inner.h, rx: fw * .1, fill: '#0f2a22'}, svg);
      mk('rect', {x: inner.x, y: wy, width: inner.w, height: Math.max(0, inner.y + inner.h - wy), rx: fw * .08, fill: '#5ad2ff'}, svg);
      mk('line', {x1: fx - fs * .3, x2: fx + fw + fs * .3, y1: inner.y, y2: inner.y, stroke: '#10100c', 'stroke-width': 1.4, 'stroke-dasharray': '3 3'}, svg);
      const bt = txt(svg, fx + fw + fs * .45, inner.y + fs * .35, P.brim, {'font-family': 'Figtree', 'font-weight': 800, 'font-size': fs * .8, fill: '#10100c'});
      const bb = bt.getBBox(); if (bb.x + bb.width > W - 2) { bt.setAttribute('x', fx - fs * .45); bt.setAttribute('text-anchor', 'end'); }
      const msg = spilled ? P.spilled : P.short(fmtCm(DEPTH - level));
      const t = txt(svg, W / 2, H - fs * .45, msg, {'font-family': 'Figtree', 'font-weight': 800, 'font-size': fs * .9, fill: '#10100c', 'text-anchor': 'middle'});
      if (t.getBBox().width > W - 4) t.setAttribute('font-size', fs * .75);
    }
  }
  const fmtCm = v => (Math.round(v * 10) / 10).toLocaleString(LANG === 'it' ? 'it-IT' : 'en-GB', {minimumFractionDigits: 1});
  function scope(t) {
    const {x, W, H} = Kit.fitCanvas(cv); x.clearRect(0, 0, W, H);
    x.strokeStyle = '#ffffff14'; x.lineWidth = 1; for (let i = 1; i < 4; i++) { x.beginPath(); x.moveTo(0, H * i / 4); x.lineTo(W, H * i / 4); x.stroke(); }
    const on = pouring && !spilled, cyc = f(level) / 120, amp = on ? H * .3 : 0;
    x.strokeStyle = '#00E5A0'; x.lineWidth = 2; x.beginPath();
    for (let i = 0; i <= W; i += 1) { const p = i / W; const y = H / 2 + amp * Math.sin(2 * Math.PI * (cyc * p) + phase) * (0.75 + .25 * Math.sin(p * 9 + t * 7)); i ? x.lineTo(i, y) : x.moveTo(i, y); }
    x.stroke();
  }
  function loop(now) {
    const dt = Math.min(.05, (now - last) / 1000 || 0); last = now;
    if (pouring && !spilled) {
      level += 2.4 * dt; phase += dt * 30;
      if (level >= DEPTH) { level = DEPTH + .2; spilled = true; stopPour(); }
      audioSet(true);
      $('pourStream') && ($('pourStream').style.opacity = .95);
    }
    scope(now / 1000); $('pourCap').textContent = caption();
    raf = pouring ? requestAnimationFrame(loop) : 0;
  }
  function startPour() { if (stopped || spilled) return; pouring = true; hold.classList.add('down'); audioStart(); last = performance.now(); if (!raf) raf = requestAnimationFrame(loop); done.classList.remove('gone'); flask(); }
  function stopPour() { if (!pouring) return; pouring = false; hold.classList.remove('down'); audioSet(false); flask(); scope(0); $('pourCap').textContent = caption(); if (spilled) finish(); }
  hold.addEventListener('pointerdown', e => { e.preventDefault(); hold.setPointerCapture(e.pointerId); startPour(); });
  hold.addEventListener('pointerup', stopPour); hold.addEventListener('pointercancel', stopPour); hold.addEventListener('lostpointercapture', stopPour);
  hold.addEventListener('keydown', e => { if ((e.key === ' ' || e.key === 'Enter') && !e.repeat) { e.preventDefault(); startPour(); } });
  hold.addEventListener('keyup', e => { if (e.key === ' ' || e.key === 'Enter') stopPour(); });
  function finish() { if (stopped) return; stopped = true; Kit.hide('pourCtl'); Kit.show('pourSure'); sure.on(); say('pourSay', ''); }
  done.addEventListener('click', () => { stopPour(); finish(); });
  function chart(anim) {
    const s2 = $('pourChart'); s2.classList.remove('gone'); s2.innerHTML = '';
    const {W, H} = Kit.fitSvg(s2), u = cq(s2), fs = Math.max(8.5, Math.min(1.15 * u, 11));
    const L0 = fs * .9, R0 = fs * .9, T0 = fs * 2.4, B0 = fs * 2.4;
    const lf = Math.log(300), hf = Math.log(4300);
    const X = h => L0 + h / DEPTH * (W - L0 - R0), Y = hz => T0 + (1 - (Math.log(hz) - lf) / (hf - lf)) * (H - T0 - B0);
    const pl = placer(s2, W, H), lab = (s, a = {}) => txt(s2, 0, 0, s, Object.assign({'font-family': 'Figtree', 'font-weight': 800, 'font-size': fs * .78, fill: '#fff', 'letter-spacing': '.05em'}, a));
    pl.put(lab(P.pitch, {fill: '#00E5A0'}), [[L0, fs * 1.2, 'start']]);
    pl.put(lab(P.level + ' →', {'fill-opacity': .6}), [[L0, H - fs * .45, 'start']]);
    let d = ''; for (let i = 0; i <= 120; i++) { const h = i / 120 * DEPTH; d += (i ? 'L' : 'M') + X(h).toFixed(1) + ',' + Y(f(h)).toFixed(1); }
    const curve = mk('path', {d, fill: 'none', stroke: '#00E5A0', 'stroke-width': 2.4}, s2);
    const h = Math.min(level, DEPTH), ux = X(h), uy = Y(f(h));
    mk('line', {x1: ux, x2: ux, y1: uy + fs * .6, y2: H - B0 + fs * .4, stroke: '#fff', 'stroke-width': 1.1, 'stroke-dasharray': '2 3'}, s2);
    const you = mk('circle', {cx: ux, cy: uy, r: fs * .5, fill: spilled ? '#ff6b5b' : '#fff', stroke: '#0f2a22', 'stroke-width': 2}, s2);
    pl.reserve({x: ux - fs * .6, y: uy - fs * .6, width: fs * 1.2, height: fs * 1.2});
    const yt = lab(P.stopped, {'font-size': fs * .72});
    pl.put(yt, [[ux - fs * .9, uy + fs * .3, 'end'], [ux - fs * .9, uy + fs * 1.4, 'end'], [ux, H - B0 + fs * 1.3, 'end'], [ux - fs * .9, uy - fs * .8, 'end']]);
    const dot = hh => mk('circle', {cx: X(hh), cy: Y(f(hh)), r: 2.4, fill: '#fff'}, s2);
    dot(0); dot(DEPTH);
    const a = lab(fmt(Math.round(f(0) / 10) * 10) + ' Hz', {'font-weight': 700});
    pl.put(a, [[X(0) + 2, Y(f(0)) - fs * .6, 'start'], [X(0) + 2, Y(f(0)) + fs * 1.2, 'start']]);
    const b = lab(fmt(Math.round(f(DEPTH) / 100) * 100) + ' Hz', {'font-weight': 700});
    pl.put(b, [[X(DEPTH) - fs * .6, Y(f(DEPTH)) + fs * .3, 'end'], [X(DEPTH), Y(f(DEPTH)) - fs * .5, 'end'], [X(DEPTH) - fs * .6, Y(f(DEPTH)) + fs * 1.4, 'end']]);
    if (anim && !calm) { const len = curve.getTotalLength(); gsap.fromTo(curve, {attr: {'stroke-dasharray': `${len} ${len}`, 'stroke-dashoffset': len}}, {attr: {'stroke-dashoffset': 0}, duration: .9, ease: 'power2.inOut'}); gsap.from([a, b, you, yt], {opacity: 0, duration: .35, delay: .7, stagger: .1}); }
  }
  function reveal() {
    revealed = true; flask(); cv.style.visibility = 'hidden'; $('pourCap').textContent = '';
    requestAnimationFrame(() => chart(true));
    const ok = !spilled && DEPTH - level <= 1;
    sure.grade(ok, conf, spilled ? P.spilled : P.short(fmtCm(DEPTH - level)));
    say('pourSay', P.say2); Kit.show('pourKeep');
  }
  function reset() {
    level = 0; pouring = false; spilled = false; stopped = false; conf = 0; revealed = false; if (raf) cancelAnimationFrame(raf); raf = 0;
    cv.style.visibility = ''; $('pourChart').classList.add('gone'); Kit.show('pourCtl'); done.classList.add('gone'); Kit.hide('pourSure'); sure.reset(); Kit.hide('pourKeep');
    say('pourSay', P.say0); $('pourCap').textContent = P.caps[0]; flask(); scope(0);
  }
  reset();
  watchSize(svg, () => { flask(); if (revealed) chart(false); else scope(0); });
  Kit.onShow.pour = () => { flask(); if (revealed) chart(false); else scope(0); };
  Kit.onHide.pour = () => stopPour();
  Kit.play.pour = async () => { reset(); level = 22.6; pouring = true; scope(1); $('pourCap').textContent = caption(); pouring = false; done.classList.remove('gone'); finish(); await wait(100); $('pourSure').querySelector('[data-v="70"]').click(); await wait(1200); };
})();

/* =====================================================================
   6 · Push the slider: Schelling's neighbours (1971), simulated live
   ===================================================================== */
(() => {
  const S = T.town, cv = $('tCv'), range = $('tRange');
  const GW = 28, GH = 14, N = GW * GH, EMPTY = Math.round(N * .1), CAP0 = 25, ASKED = 33, OK = 2;
  const COL = ['', '#10100c', '#e4572e'];
  let cells = [], want = 0, cap = CAP0, chosen = -1, conf = 0, revealed = false, raf = 0, last = 0, seed = 7, moving = [], acc = 0;
  const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  // the 8 cells around each cell (fewer on the edge)
  const NB = Array.from({length: N}, (_, i) => {
    const x = i % GW, y = Math.floor(i / GW), o = [];
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { const xx = x + dx, yy = y + dy; if ((dx || dy) && xx >= 0 && xx < GW && yy >= 0 && yy < GH) o.push(yy * GW + xx); }
    return o;
  });
  const share = (i, kind = cells[i]) => { let a = 0, n = 0; for (const j of NB[i]) if (cells[j]) { n++; if (cells[j] === kind) a++; } return n ? a / n : 1; };
  const unhappy = () => { const u = []; for (let i = 0; i < N; i++) if (cells[i] && share(i) < want - 1e-9) u.push(i); return u; };
  function alike() { let s = 0, n = 0; for (let i = 0; i < N; i++) if (cells[i] && NB[i].some(j => cells[j])) { s += share(i); n++; } return n ? s / n : 0; }
  function init() { // two kinds of family in equal numbers, a tenth of the lots empty, mixed at random
    seed = 7; moving = []; acc = 0;
    const k = (N - EMPTY) >> 1; cells = [...Array(k).fill(1), ...Array(k).fill(2), ...Array(N - 2 * k).fill(0)];
    for (let i = N - 1; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [cells[i], cells[j]] = [cells[j], cells[i]]; }
  }
  function moveOne() { // one unhappy family moves to an empty lot picked at random
    const u = unhappy(); if (!u.length) return false;
    const i = u[Math.floor(rnd() * u.length)], empties = [];
    for (let j = 0; j < N; j++) if (!cells[j]) empties.push(j);
    const j = empties[Math.floor(rnd() * empties.length)];
    cells[j] = cells[i]; cells[i] = 0; moving.push({from: i, to: j, kind: cells[j], t: 0});
    return true;
  }
  const settle = () => { let n = 0; while (n++ < 5000 && moveOne()); moving = []; };
  function readout() {
    $('tN').innerHTML = `${Math.round(alike() * 100)}<small>%</small>`;
    $('tWant').textContent = S.wants(Math.round(want * 100));
  }
  function house(x, cx, cy, s, col, sad) {
    x.globalAlpha = sad ? .38 : 1; x.fillStyle = col;
    x.beginPath(); x.moveTo(cx - s / 2, cy + s / 2); x.lineTo(cx - s / 2, cy - s * .08); x.lineTo(cx, cy - s / 2); x.lineTo(cx + s / 2, cy - s * .08); x.lineTo(cx + s / 2, cy + s / 2); x.closePath(); x.fill();
    x.globalAlpha = 1;
  }
  function draw() {
    const {x, W, H} = Kit.fitCanvas(cv); if (!W || !H) return;
    const p = Math.min(W / GW, H / GH), ox = (W - p * GW) / 2, oy = (H - p * GH) / 2;
    const pos = i => [ox + (i % GW + .5) * p, oy + (Math.floor(i / GW) + .5) * p];
    x.clearRect(0, 0, W, H);
    const flying = new Set(moving.map(m => m.to)), sad = new Set(unhappy());
    for (let i = 0; i < N; i++) {
      const [cx, cy] = pos(i);
      if (!cells[i] || flying.has(i)) { x.fillStyle = '#a8714a40'; x.beginPath(); x.arc(cx, cy, p * .09, 0, 7); x.fill(); continue; }
      house(x, cx, cy, p * .78, COL[cells[i]], sad.has(i));
    }
    for (const m of moving) {
      const e = m.t < .5 ? 2 * m.t * m.t : 1 - Math.pow(-2 * m.t + 2, 2) / 2, [ax, ay] = pos(m.from), [bx, by] = pos(m.to);
      house(x, ax + (bx - ax) * e, ay + (by - ay) * e - Math.sin(Math.PI * e) * p * 1.4, p * .78 * (1 + .35 * Math.sin(Math.PI * e)), COL[m.kind], false);
    }
  }
  function loop(now) {
    const dt = Math.min(.05, (now - last) / 1000 || 0); last = now;
    acc += dt * 40;                                   // at most about 40 moves a second
    while (acc >= 1) { acc -= 1; if (!moveOne()) { acc = 0; break; } }
    moving.forEach(m => m.t += dt / .45); moving = moving.filter(m => m.t < 1);
    draw(); readout();
    raf = requestAnimationFrame(loop);
  }
  const startLoop = () => { if (calm) { draw(); return; } if (!raf) { last = performance.now(); raf = requestAnimationFrame(loop); } };
  const stopLoop = () => { if (raf) cancelAnimationFrame(raf); raf = 0; };
  range.addEventListener('input', () => {
    let v = +range.value; if (v > cap) { v = cap; range.value = cap; }
    want = v / 100; readout();
    if (calm) { settle(); draw(); readout(); }
    if (!revealed && v >= CAP0) say('tSay', S.say1);
  });
  $('tPick').addEventListener('click', e => {
    const b = e.target.closest('.pb'); if (!b || revealed) return;
    chosen = +b.dataset.i; [...$('tPick').children].forEach(x => x.classList.toggle('on', x === b)); sure.on();
  });
  const sure = Sure($('tSure'), T.howSure, v => { conf = v; reveal(); });
  function reveal() {
    revealed = true; cap = 60; $('tLock').textContent = '0 - 60%';
    Kit.hide('tPick');
    sure.grade(chosen === OK, conf, `${S.opts[chosen][0]} · ${chosen === OK ? T.right : T.wrong}`);
    const o = {v: +range.value};
    const to = () => { range.value = Math.round(o.v); want = Math.round(o.v) / 100; readout(); };
    if (calm) { o.v = ASKED; to(); settle(); draw(); readout(); } else gsap.to(o, {v: ASKED, duration: .8, ease: 'power2.inOut', onUpdate: to});
    say('tSay', S.say2); Kit.show('townKeep');
  }
  function reset() {
    want = 0; cap = CAP0; chosen = -1; conf = 0; revealed = false; range.value = 0; $('tLock').textContent = S.lock;
    [...$('tPick').children].forEach(x => x.classList.remove('on')); Kit.show('tPick');
    sure.reset(); Kit.hide('townKeep'); say('tSay', S.say0); init(); readout(); draw();
  }
  reset();
  watchSize(cv, () => draw());
  Kit.onShow.town = () => { draw(); startLoop(); };
  Kit.onHide.town = () => stopLoop();
  Kit.play.town = async () => {
    reset(); range.value = CAP0; range.dispatchEvent(new Event('input')); settle(); draw(); readout(); await wait(200);
    $('tPick').children[1].click(); await wait(100); $('tSure').querySelector('[data-v="70"]').click();
    await wait(1000); settle(); draw(); readout(); await wait(300);
  };
})();

/* =====================================================================
   7 · Two images: the Sun on 3 January and on 6 July
   ===================================================================== */
(() => {
  const S = T.sun, cv = $('sunCv'), view = $('sunView');
  const RATIO = 32.52 / 31.45;                  // angular diameters, perihelion over aphelion (ERFA)
  const JAN = 0;                                 // photo A is January
  let split = .5, chosen = -1, conf = 0, revealed = false, imgs = null, G = null;
  const sure = Sure($('sunSure'), T.howSure, v => { conf = v; reveal(); });
  function sunImage(D, spots, s0) {
    const c = document.createElement('canvas'), dpr = devicePixelRatio, n = Math.ceil(D * dpr) + 4; c.width = c.height = n;
    const x = c.getContext('2d'); x.scale(dpr, dpr); const r = D / 2, o = r + 2 / dpr;
    let seed = s0; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    const g = x.createRadialGradient(o, o, 0, o, o, r);
    g.addColorStop(0, '#fff6d6'); g.addColorStop(.55, '#ffd98a'); g.addColorStop(.86, '#ffab3d'); g.addColorStop(1, '#e8701e');
    x.fillStyle = g; x.beginPath(); x.arc(o, o, r, 0, 7); x.fill();
    x.save(); x.beginPath(); x.arc(o, o, r, 0, 7); x.clip();
    for (let i = 0; i < D * 9; i++) { const a = rnd() * 7, d = Math.sqrt(rnd()) * r, px = o + d * Math.cos(a), py = o + d * Math.sin(a); x.fillStyle = rnd() < .5 ? '#ffffff14' : '#9a3a0012'; x.beginPath(); x.arc(px, py, .6 + rnd() * 1.4, 0, 7); x.fill(); }
    for (const [sx, sy, sr] of spots) { x.fillStyle = '#7a3a0a88'; x.beginPath(); x.arc(o + sx * r, o + sy * r, sr * r * 1.8, 0, 7); x.fill(); x.fillStyle = '#2a1204'; x.beginPath(); x.arc(o + sx * r, o + sy * r, sr * r, 0, 7); x.fill(); }
    x.restore();
    return c;
  }
  function build() {
    const r = cv.getBoundingClientRect(); if (!r.width) return;
    const fs = Math.max(9, Math.min(1.3 * cq(cv), 12.5));
    const base = revealed ? Math.max(12, Math.min(r.width / 2.6, (r.height - fs * 5.2) / 1.18)) : Math.min(r.width, r.height) * .66;
    const dB = base / Math.sqrt(RATIO), dA = base * Math.sqrt(RATIO);
    imgs = [sunImage(dA, [[-.32, .18, .035], [-.24, .24, .02], [.4, -.3, .03]], 3), sunImage(dB, [[.12, .35, .03], [.18, .31, .018], [-.45, -.1, .025]], 9)];
    imgs.d = [dA, dB]; imgs.base = base;
  }
  function draw() {
    if (!imgs) build(); if (!imgs) return;
    const {x, W, H} = Kit.fitCanvas(cv), u = cq(cv), fs = Math.max(9, Math.min(1.3 * u, 12.5));
    const cx = W / 2, cy = H / 2 + fs * .2, sx = W * split; G = {W, H, cx, cy, fs};
    x.fillStyle = '#070b24'; x.fillRect(0, 0, W, H);
    const blit = (k, clipL, clipR) => { const im = imgs[k], dd = im.width / devicePixelRatio; x.save(); x.beginPath(); x.rect(clipL, 0, clipR - clipL, H); x.clip(); x.drawImage(im, cx - dd / 2, cy - dd / 2, dd, dd); x.restore(); };
    if (revealed) { // side by side, at the same scale
      const off = W * .25, yc = H / 2 - fs * .1;
      x.save(); x.translate(-off, yc - cy); blit(0, 0, W); x.restore(); x.save(); x.translate(off, yc - cy); blit(1, 0, W); x.restore();
      ring(x, cx - off, yc, imgs.base / 2, .55); ring(x, cx + off, yc, imgs.base / 2, .55);
      G.off = off; G.yc = yc;
    } else { blit(0, 0, sx); blit(1, sx, W); ring(x, cx, cy, imgs.base / 2, .9); }
    // labels
    x.font = `900 ${fs * 1.5}px Fraunces, Georgia, serif`; x.fillStyle = '#fff'; x.textAlign = 'left'; x.fillText('A', fs * .8, fs * 1.9);
    x.textAlign = 'right'; x.fillText('B', W - fs * .8, fs * 1.9);
    x.font = `800 ${fs * .78}px Figtree, system-ui, sans-serif`; x.fillStyle = '#ffffffb0';
    if (revealed) {
      x.textAlign = 'center';
      [[S.jan, cx - G.off], [S.jul, cx + G.off]].forEach(([t, px]) => { const [a, b] = t.split(' · '); x.fillStyle = '#fff'; x.fillText(a, px, H - fs * 1.75); x.fillStyle = '#ffffffa0'; x.fillText(b, px, H - fs * .6); });
      x.fillStyle = '#ffd98a'; x.font = `800 ${fs * .85}px Figtree, system-ui, sans-serif`; x.fillText(S.wider, cx, fs * 1.6);
    } else {
      // the divider and its grip
      x.strokeStyle = '#fff'; x.lineWidth = 2; x.beginPath(); x.moveTo(sx, 0); x.lineTo(sx, H); x.stroke();
      x.fillStyle = '#fff'; x.beginPath(); x.arc(sx, H - fs * 2.2, fs * 1.05, 0, 7); x.fill();
      x.strokeStyle = '#2B5CFF'; x.lineWidth = 2; x.beginPath(); x.moveTo(sx - fs * .55, H - fs * 2.2); x.lineTo(sx - fs * .2, H - fs * 2.55); x.moveTo(sx - fs * .55, H - fs * 2.2); x.lineTo(sx - fs * .2, H - fs * 1.85); x.moveTo(sx + fs * .55, H - fs * 2.2); x.lineTo(sx + fs * .2, H - fs * 2.55); x.moveTo(sx + fs * .55, H - fs * 2.2); x.lineTo(sx + fs * .2, H - fs * 1.85); x.stroke();
      x.textAlign = 'center'; x.fillStyle = '#ffffff99'; x.fillText(S.drag, cx, H - fs * .5);
      loupe(x, W, H, cx, cy, sx, fs);
    }
  }
  function ring(x, cx, cy, r, a) {
    x.strokeStyle = `rgba(255,255,255,${a})`; x.lineWidth = 1; x.setLineDash([3, 3]); x.beginPath(); x.arc(cx, cy, r, 0, 7); x.stroke(); x.setLineDash([]);
    x.beginPath(); for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) { x.moveTo(cx + dx * r * 1.06, cy + dy * r * 1.06); x.lineTo(cx + dx * r * 1.16, cy + dy * r * 1.16); } x.stroke();
  }
  function loupe(x, W, H, cx, cy, sx, fs) { // a magnified view of where the divider crosses the top of the disc
    const R = imgs.base / 2, dxs = Math.max(-R * .95, Math.min(R * .95, sx - cx)), ey = cy - Math.sqrt(R * R - dxs * dxs);
    const lr = Math.min(W, H) * .13, lx = W - lr - fs * .6, ly = lr + fs * 2.6, z = 6;
    x.save(); x.beginPath(); x.arc(lx, ly, lr, 0, 7); x.clip();
    x.fillStyle = '#070b24'; x.fillRect(lx - lr, ly - lr, lr * 2, lr * 2);
    x.translate(lx, ly); x.scale(z, z); x.translate(-sx, -ey);
    for (const [k, l, r] of [[0, -9999, sx], [1, sx, 9999]]) { const im = imgs[k], dd = im.width / devicePixelRatio; x.save(); x.beginPath(); x.rect(l, -9999, r - l, 19999); x.clip(); x.drawImage(im, cx - dd / 2, cy - dd / 2, dd, dd); x.restore(); }
    x.strokeStyle = '#ffffffcc'; x.lineWidth = 1 / z; x.setLineDash([3 / z, 3 / z]); x.beginPath(); x.arc(cx, cy, R, 0, 7); x.stroke(); x.setLineDash([]);
    x.strokeStyle = '#fff'; x.lineWidth = 2 / z; x.beginPath(); x.moveTo(sx, ey - 99); x.lineTo(sx, ey + 99); x.stroke();
    x.restore();
    x.strokeStyle = '#fff'; x.lineWidth = 2; x.beginPath(); x.arc(lx, ly, lr, 0, 7); x.stroke();
    x.font = `800 ${fs * .7}px Figtree, system-ui, sans-serif`; x.fillStyle = '#ffffffb0'; x.textAlign = 'center'; x.fillText('×6', lx, ly + lr + fs * 1.05);
  }
  let drag = false;
  const setSplit = e => { const r = cv.getBoundingClientRect(); split = Math.max(.04, Math.min(.96, (e.clientX - r.left) / r.width)); draw(); };
  view.addEventListener('pointerdown', e => { if (revealed) return; drag = true; view.setPointerCapture(e.pointerId); setSplit(e); });
  view.addEventListener('pointermove', e => { if (drag) setSplit(e); });
  view.addEventListener('pointerup', () => drag = false); view.addEventListener('pointercancel', () => drag = false);
  $('sunPick').addEventListener('click', e => { const b = e.target.closest('.pb'); if (!b || revealed) return; chosen = +b.dataset.i; [...$('sunPick').children].forEach(x => x.classList.toggle('on', x === b)); sure.on(); });
  function noon(anim) {
    const svg = $('sunNoonSvg'); svg.innerHTML = '';
    const {W, H} = Kit.fitSvg(svg), u = cq(svg), fs = Math.max(8.5, Math.min(1.15 * u, 11.5));
    const half = W / 2, gy = H - fs * 1.55, oh = Math.min((gy - fs * 1.2) * .62, half * .24);
    mk('line', {x1: half, x2: half, y1: fs * .5, y2: H - fs * .5, stroke: '#fff', 'stroke-opacity': .18}, svg);
    [[72, S.june, 0], [25, S.dec, 1]].forEach(([alt, lab, k]) => {
      const x0 = k ? half : 0, ox = x0 + half * .4, rad = alt * Math.PI / 180, top = gy - oh;
      const g = mk('g', {}, svg);
      mk('line', {x1: x0 + fs * .6, x2: x0 + half - fs * .6, y1: gy, y2: gy, stroke: '#fff', 'stroke-opacity': .55}, g);
      const sh = oh / Math.tan(rad);
      mk('path', {d: `M${ox},${gy} L${ox + sh},${gy} L${ox},${gy - 2}Z`, fill: '#000', 'fill-opacity': .5, stroke: '#000', 'stroke-opacity': .5, 'stroke-width': 2}, g);
      const L = Math.min((ox - x0 - fs * 1.1) / Math.cos(rad), (top - fs * 1.1) / Math.sin(rad));
      const sx2 = ox - L * Math.cos(rad), sy2 = top - L * Math.sin(rad);
      mk('line', {x1: sx2, y1: sy2, x2: ox + sh, y2: gy, stroke: '#ffd98a', 'stroke-width': 1, 'stroke-dasharray': '2 3'}, g);
      mk('path', {d: `M${ox - fs * .24},${gy} L${ox - fs * .17},${top + fs * .4} L${ox},${top} L${ox + fs * .17},${top + fs * .4} L${ox + fs * .24},${gy}Z`, fill: '#fff'}, g);
      mk('circle', {cx: sx2, cy: sy2, r: fs * .6, fill: '#ffd98a'}, g);
      txt(g, x0 + half / 2, H - fs * .4, lab, {'font-family': 'Figtree', 'font-weight': 800, 'font-size': fs * .74, fill: '#fff', 'text-anchor': 'middle', 'letter-spacing': '.04em'});
      if (anim && !calm) gsap.from(g, {opacity: 0, x: k ? 8 : -8, duration: .45, delay: .9 + k * .25, ease: 'power3.out'});
    });
  }
  function reveal() {
    revealed = true; Kit.hide('sunPick');
    sure.grade(chosen === JAN, conf, `${S.opts[chosen][0]} · ${chosen === JAN ? T.right : T.wrong}`);
    $('sunNoon').style.display = 'block'; view.style.cursor = 'default';
    requestAnimationFrame(() => { build(); draw(); noon(true); });
    say('sunSay', S.say2); Kit.show('sunKeep');
  }
  function reset() {
    split = .5; chosen = -1; conf = 0; revealed = false; $('sunNoon').style.display = ''; view.style.cursor = '';
    [...$('sunPick').children].forEach(x => x.classList.remove('on')); Kit.show('sunPick');
    sure.reset(); Kit.hide('sunKeep'); say('sunSay', S.say0); imgs = null; draw();
  }
  say('sunSay', S.say0);
  watchSize(cv, () => { imgs = null; build(); draw(); if (revealed) noon(false); });
  Kit.onShow.sun = () => { imgs = null; build(); draw(); if (revealed) noon(false); };
  Kit.play.sun = async () => { reset(); split = .5; draw(); $('sunPick').children[1].click(); await wait(100); $('sunSure').querySelector('[data-v="80"]').click(); await wait(1500); };
})();

/* =====================================================================
   8 · Pull it: a rope round a bollard, the capstan equation (Euler 1762)
   ===================================================================== */
(() => {
  const B = T.bollard, svg = $('bSvg');
  const MU = .3, PULL = 10000, GOAL = Math.log(PULL / 10) / (MU * 2 * Math.PI);  // 3.66 turns to hold it with 10 kg
  const hold = n => PULL / Math.exp(MU * 2 * Math.PI * n);
  const loc = LANG === 'it' ? 'it-IT' : 'en-GB';
  const kg = v => v >= 10 ? fmt(Math.round(v)) : v.toLocaleString(loc, {maximumFractionDigits: 1});
  let turns = 0, locked = false, chosen = -1, conf = 0, revealed = false, chartOn = false, G = null;
  const sure = Sure($('bSure'), T.howSure, v => { conf = v; reveal(); });
  const label = (p, x, y, s, a = 'start', fill = '#fff') => txt(p, x, y, s, {'font-family': 'Figtree', 'font-weight': 800, 'font-size': G.fs * .78, fill, 'fill-opacity': .85, 'letter-spacing': '.1em', 'text-anchor': a});
  function rope(p, d, fs) { // a braided rope: dark edge, light body, tan twist
    mk('path', {d, fill: 'none', stroke: '#3d0a45', 'stroke-width': fs * .66, 'stroke-linecap': 'round', 'stroke-linejoin': 'round'}, p);
    mk('path', {d, fill: 'none', stroke: '#F2F1EC', 'stroke-width': fs * .48, 'stroke-linecap': 'round', 'stroke-linejoin': 'round'}, p);
    mk('path', {d, fill: 'none', stroke: '#b98a4a', 'stroke-width': fs * .48, 'stroke-dasharray': '2 4'}, p);
  }
  function chart(anim) { // what you hold after each whole turn
    const {W, fs} = G, ch = G.ch, g = mk('g', {}, svg);
    mk('rect', {x: 0, y: 0, width: W, height: ch, fill: '#1a0820', 'fill-opacity': .32}, g);
    label(g, fs * .8, fs * 1.45, B.chart);
    const L = fs * 1.2, R = W - fs * 1.2, T0 = fs * 3.5, B0 = ch - fs * 1.75, cw = (R - L) / 5, bw = cw * .5;
    mk('line', {x1: L, x2: R, y1: B0, y2: B0, stroke: '#fff', 'stroke-opacity': .35}, g);
    for (let k = 0; k <= 4; k++) {
      const v = hold(k), bh = Math.max(1.5, v / PULL * (B0 - T0)), x = L + k * cw + (cw - bw) / 2;
      const bar = mk('rect', {x, y: B0 - bh, width: bw, height: bh, rx: 1.5, fill: '#fff', 'fill-opacity': k ? .9 : .45}, g);
      const t = txt(g, x + bw / 2, B0 - bh - fs * .45, kg(v), {'font-family': 'Figtree', 'font-weight': 900, 'font-size': fs * (k ? 1.05 : .95), fill: '#fff', 'text-anchor': 'middle'});
      txt(g, x + bw / 2, B0 + fs * 1.15, B.turnN(k), {'font-family': 'Figtree', 'font-weight': 700, 'font-size': fs * .78, fill: '#fff', 'fill-opacity': .7, 'text-anchor': 'middle'});
      if (anim && !calm) { gsap.from(bar, {attr: {y: B0, height: 0}, duration: .5, delay: .12 * k, ease: 'power3.out'}); gsap.from(t, {opacity: 0, duration: .3, delay: .12 * k + .25}); }
    }
  }
  function scene(anim) {
    svg.innerHTML = '';
    const {W, H} = Kit.fitSvg(svg), u = cq(svg), fs = Math.max(9, Math.min(1.25 * u, 12));
    G = {W, H, fs, ch: chartOn ? Math.round(H * .44) : 0};
    mk('rect', {x: 0, y: 0, width: W, height: H, fill: '#82208f', 'fill-opacity': .35}, svg);
    if (chartOn) chart(anim);
    const sy = G.ch, sh = H - sy;
    // the two forces
    label(svg, fs * .8, sy + fs * 1.45, B.ship);
    txt(svg, fs * .8, sy + fs * 3.35, `${kg(PULL)} kg`, {'font-family': 'Fraunces, Georgia, serif', 'font-weight': 900, 'font-size': fs * 1.75, fill: '#fff'});
    label(svg, W - fs * .8, sy + fs * 1.45, B.hold, 'end');
    txt(svg, W - fs * .8, sy + fs * 3.35, `${kg(hold(turns))} kg`, {'font-family': 'Fraunces, Georgia, serif', 'font-weight': 900, 'font-size': fs * 1.75, fill: '#fff', 'text-anchor': 'end'});
    // water, quay and the ship's bow
    const wy = sy + sh * .74, qx = W * .42, qy = wy - sh * .06;
    mk('rect', {x: 0, y: wy, width: qx, height: H - wy, fill: '#3d0a45', 'fill-opacity': .6}, svg);
    for (let k = 0; k < 2; k++) { let d = ''; for (let x = 0; x <= qx; x += 6) d += (x ? 'L' : 'M') + x + ',' + (wy + fs * (.7 + k * 1.1) + Math.sin(x / 9 + k * 2) * 1.4).toFixed(1); mk('path', {d, fill: 'none', stroke: '#fff', 'stroke-opacity': .22}, svg); }
    mk('rect', {x: qx, y: qy, width: W - qx, height: H - qy, fill: '#f6d7fb'}, svg);
    mk('rect', {x: qx, y: qy, width: W - qx, height: Math.max(2, sh * .02), fill: '#fff', 'fill-opacity': .7}, svg);
    const hy = wy - sh * .17, bowX = W * .3;
    mk('rect', {x: W * .03, y: hy - sh * .1, width: W * .12, height: sh * .1, rx: 2, fill: '#1a0820'}, svg);
    mk('path', {d: `M${-fs},${hy} L${bowX},${hy} L${bowX - sh * .09},${wy + sh * .07} L${-fs},${wy + sh * .07}Z`, fill: '#1a0820'}, svg);
    mk('rect', {x: -fs, y: hy + sh * .035, width: bowX - sh * .02 + fs, height: Math.max(1.5, sh * .018), fill: '#fff', 'fill-opacity': .8}, svg);
    // the bollard
    const bx = W * .63, bw = Math.max(fs * 2, W * .09), bTop = qy - sh * .3;
    mk('rect', {x: bx - bw * .75, y: qy - sh * .03, width: bw * 1.5, height: sh * .03, rx: 1, fill: '#2a0f30'}, svg);
    mk('rect', {x: bx - bw / 2, y: bTop, width: bw, height: qy - bTop, fill: '#2a0f30'}, svg);
    mk('ellipse', {cx: bx, cy: bTop, rx: bw * .72, ry: bw * .22, fill: '#4a1f55'}, svg);
    // the rope: from the bow to the bollard, round it, then to your hand
    const wTop = bTop + bw * .5, wBot = qy - sh * .06, gap = (wBot - wTop) / 4.4;
    const cleat = [bowX - fs * .8, hy - fs * .15];
    rope(svg, `M${cleat[0]},${cleat[1]} Q${(cleat[0] + bx) / 2},${Math.max(cleat[1], wTop) + fs * 1.2} ${bx - bw / 2},${wTop}`, fs);
    const full = Math.floor(turns + 1e-6), frac = turns - full;
    let end = [bx - bw / 2, wTop];
    for (let k = 0; k < Math.ceil(turns - 1e-6); k++) {
      const f = k < full ? 1 : frac, y0 = wTop + k * gap, x0 = bx - bw / 2, x1 = x0 + bw * f, y1 = y0 + gap * .55 * f;
      rope(svg, `M${x0},${y0} L${x1},${y1}`, fs); end = [x1, y1];
    }
    const hx = W * .87, y0h = qy - sh * .3, y1h = qy - sh * .04, hyH = locked ? y1h : y0h + (y1h - y0h) * turns;
    G.track = {y0: y0h, y1: y1h};
    rope(svg, `M${end[0]},${end[1]} Q${(end[0] + hx) / 2},${Math.max(end[1], hyH) + fs * .8} ${hx},${hyH}`, fs);
    if (!locked) {
      const h = mk('g', {id: 'bHandle', transform: `translate(${hx},${hyH})`, style: 'cursor:grab'}, svg);
      mk('circle', {r: fs * 1.75, fill: '#fff'}, h);
      txt(h, 0, fs * .32, B.wind, {'font-family': 'Figtree', 'font-weight': 900, 'font-size': fs * .78, fill: '#82208f', 'text-anchor': 'middle', 'letter-spacing': '.06em'});
    } else {
      mk('circle', {cx: hx, cy: hyH, r: fs * .95, fill: '#fff'}, svg);
      mk('circle', {cx: hx, cy: hyH, r: fs * .95, fill: 'none', stroke: '#3d0a45', 'stroke-width': 1.5}, svg);
    }
    txt(svg, bx, qy + Math.min(fs * 1.7, (H - qy) * .7), B.turns(turns), {'font-family': 'JetBrains Mono, monospace', 'font-weight': 700, 'font-size': fs * .85, fill: '#1a0820', 'text-anchor': 'middle'});
  }
  let dragging = false, y0 = 0, t0 = 0;
  svg.addEventListener('pointerdown', e => { if (locked || revealed || !e.target.closest('#bHandle')) return; dragging = true; svg.setPointerCapture(e.pointerId); const r = svg.getBoundingClientRect(); y0 = (e.clientY - r.top) * G.H / r.height; t0 = turns; e.preventDefault(); });
  svg.addEventListener('pointermove', e => {
    if (!dragging) return; const r = svg.getBoundingClientRect(), y = (e.clientY - r.top) * G.H / r.height;
    turns = Math.max(0, Math.min(1, t0 + (y - y0) / (G.track.y1 - G.track.y0))); scene();
    if (turns >= 1) lock();
  });
  const up = () => { dragging = false; };
  svg.addEventListener('pointerup', up); svg.addEventListener('pointercancel', up);
  function lock() { if (locked) return; dragging = false; locked = true; turns = 1; scene(); Kit.show('bPick'); say('bSay', B.say1); }
  $('bPick').addEventListener('click', e => { const b = e.target.closest('.pb'); if (!b || revealed) return; chosen = +b.dataset.i; [...$('bPick').children].forEach(x => x.classList.toggle('on', x === b)); sure.on(); });
  async function reveal() {
    revealed = true; [...$('bPick').children].forEach(x => x.disabled = true);
    sure.grade(chosen === 0, conf, `${B.opts[chosen][0]} · ${chosen === 0 ? T.right : T.wrong}`);
    Kit.hide('bPick'); say('bSay', B.say2); Kit.show('bollardKeep');
    const o = {n: turns};
    if (!calm) await new Promise(res => gsap.to(o, {n: GOAL, duration: 1.6, ease: 'power1.inOut', onUpdate: () => { turns = o.n; scene(); }, onComplete: res}));
    turns = GOAL; chartOn = true; scene(true);
  }
  function reset() {
    turns = 0; locked = false; chosen = -1; conf = 0; revealed = false; chartOn = false;
    [...$('bPick').children].forEach(x => { x.classList.remove('on'); x.disabled = false; });
    Kit.hide('bPick'); sure.reset(); Kit.hide('bollardKeep'); say('bSay', B.say0); scene();
  }
  say('bSay', B.say0);
  watchSize(svg, () => scene());
  Kit.onShow.bollard = () => scene();
  Kit.play.bollard = async () => { reset(); lock(); await wait(150); $('bPick').children[1].click(); await wait(100); $('bSure').querySelector('[data-v="70"]').click(); await wait(2600); };
})();

// ---------- the deck and the format notes ----------
Kit.deck();
const sheet = document.createElement('div'); sheet.className = 'sheet'; sheet.innerHTML = '<div class="pane" role="dialog" aria-modal="true"></div>'; document.body.appendChild(sheet);
const nb = document.createElement('button'); nb.className = 'notebtn'; nb.textContent = T.note; document.querySelector('.top').appendChild(nb);
nb.onclick = () => {
  const id = document.querySelector('.card.on')?.id, n = T.notes[id]; if (!n) return;
  const L = T.noteLabels;
  sheet.querySelector('.pane').innerHTML = `<button class="x" aria-label="${T.close}">✕</button><h3>${n.title}</h3><p class="sub">${T[id].kind}</p><dl><div><dt>${L.what}</dt><dd>${n.what}</dd></div><div><dt>${L.why}</dt><dd>${n.why}</dd></div><div><dt>${L.flutter}</dt><dd>${n.flutter}</dd></div><div><dt>${L.unlocks}</dt><dd>${n.unlocks}</dd></div>${CRITIC[id] ? `<div><dt>${L.critic}</dt><dd class="crit"><span class="avg">${(CRITIC[id].s.reduce((a, b) => a + b, 0) / 8).toLocaleString(LANG === 'it' ? 'it-IT' : 'en-GB', {minimumFractionDigits: 1, maximumFractionDigits: 1})}</span>${CRITIC[id].s.map((v, i) => `<span>${T.scoreLabels[i]} <b>${v}</b></span>`).join('')}<em>${CRITIC[id][LANG]}</em></dd></div>` : ''}</dl>`;
  sheet.classList.add('on'); sheet.querySelector('.x').onclick = () => sheet.classList.remove('on');
};
sheet.addEventListener('click', e => { if (e.target === sheet) sheet.classList.remove('on'); });
addEventListener('keydown', e => { if (e.key === 'Escape') sheet.classList.remove('on'); });
})();
