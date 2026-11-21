// Photographs cards on three phones and reports what the eye would catch: something spilling out of
// the card, the card's column overflowing, labels in a drawing overlapping, words covered, a big empty band.
//
//   node tool/cards/card_check.cjs docs/cards/prototipi/giro-3.html [out-dir]      a page of prototypes
//   node tool/cards/card_check.cjs tool/cards/bank/<topic>/<id>.html [out-dir]     one free card
//
// A page of prototypes uses the kit's deck (docs/cards/kit: .card > .in, #next to advance). Each
// card is checked as it first appears and, if the page registers Kit.play[cardId] (see
// docs/cards/kit/astute-card.js), again after it is played through.
//
// A free card (a page that calls Kit.single(), like tool/cards/web/template.html) is checked the way
// the app shows it: at the size of the card on Today on three phones, in a window of exactly that
// size, with the app's bridge in front of it (docs/cards/kit/astute-bridge.js) and a stand-in for the
// app behind the bridge that hears every message. On top of what a deck is checked for: the page
// must say it is ready, an asking card must send an answer the app can record once it is played
// through (with motion on and with motion reduced), nothing may sit under the save and share in the
// corner, no text may be set too small to read, the page may not scroll, and nothing may be asked of
// the network: the kit and its fonts are served from docs/cards/kit, and any other request fails.
//
// Its photographs carry the app's corners and the save and share, to be looked at as a reader would.
// With BARE=1 they are the page alone, as the app's own camera wants them to set inside its frame.
const path = require('path'), fs = require('fs');
let pw; try { pw = require('playwright'); } catch { pw = require('/opt/node22/lib/node_modules/playwright'); }
const file = path.resolve(process.argv[2]); const out = path.resolve(process.argv[3] || path.join(path.dirname(file), 'check'));
fs.mkdirSync(out, {recursive: true});
const KIT = path.join(__dirname, '../../docs/cards/kit');
const vendor = path.join(KIT, 'vendor');
const executablePath = fs.existsSync('/opt/pw-browsers/chromium') ? '/opt/pw-browsers/chromium' : undefined;
// Pages link libraries from the CDN; serve them from the kit's vendor/ copies so the check works
// offline and tests the same files.
const local = url => { const base = url.split('?')[0].split('/').pop(); for (const d of [vendor, path.join(vendor, 'gsap-plugins')]) { const p = path.join(d, base); if (fs.existsSync(p)) return p; } return null; };
const TYPES = {'.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.woff2': 'font/woff2', '.wasm': 'application/wasm', '.json': 'application/json', '.html': 'text/html', '.png': 'image/png', '.svg': 'image/svg+xml'};
const typeOf = p => TYPES[path.extname(p)] || 'application/octet-stream';
const source = fs.readFileSync(file, 'utf8');

if (/Kit\.single\(\)/.test(source)) single().catch(e => { console.error(e); process.exit(1); });
else deck().catch(e => { console.error(e); process.exit(1); });

// What every check looks for on the card in front: the column, the spills, the overlaps, the bands.
function inspect() {
  const card = document.querySelector('.card.on'); if (!card) return {id: '?', issues: ['no card shown']};
  const cb = card.getBoundingClientRect(), inn = card.querySelector('.in'), issues = [];
  if (inn && inn.scrollHeight > inn.clientHeight + 2) issues.push(`column overflows by ${inn.scrollHeight - inn.clientHeight}px`);
  for (const el of card.querySelectorAll('.in *')) {
    const s = getComputedStyle(el); if (s.display === 'none' || s.visibility === 'hidden' || el.closest('.gone')) continue;
    const b = el.getBoundingClientRect(); if (!b.width || !b.height) continue;
    if (b.right > cb.right + 1 || b.left < cb.left - 1 || b.bottom > cb.bottom + 1) { issues.push(`spills out: <${el.tagName.toLowerCase()}${el.id ? '#' + el.id : ''}> "${(el.textContent || '').trim().slice(0, 30)}"`); break; }
  }
  // Something drawn outside its own block of the column lands on the block next to it.
  if (inn) for (const blk of inn.children) {
    if (blk.classList.contains('gone') || getComputedStyle(blk).display === 'none') continue;
    const bb = blk.getBoundingClientRect(); let hit = null;
    for (const el of blk.querySelectorAll('*')) { const s = getComputedStyle(el); if (s.display === 'none' || s.visibility === 'hidden' || +s.opacity === 0 || el.closest('.gone') || el.closest('svg') && el.tagName !== 'svg') continue; const b = el.getBoundingClientRect(); if (b.width && b.height && (b.bottom > bb.bottom + 3 || b.top < bb.top - 3)) { hit = el; break; } }
    if (hit) { issues.push(`spills out of its block: <${hit.tagName.toLowerCase()}> "${(hit.textContent || '').trim().slice(0, 30)}"`); break; }
  }
  // HTML pieces placed by hand (absolute) must not cover each other's text.
  const boxes = [...card.querySelectorAll('.chip, .city, .float, .badge')].filter(e => getComputedStyle(e).display !== 'none' && !e.closest('.gone')).map(e => ({e, b: e.getBoundingClientRect()}));
  for (let a = 0; a < boxes.length; a++) for (let c = a + 1; c < boxes.length; c++) { const A = boxes[a].b, B = boxes[c].b; if (A.left < B.right - 2 && B.left < A.right - 2 && A.top < B.bottom - 2 && B.top < A.bottom - 2) { issues.push(`pieces overlap: "${boxes[a].e.textContent.trim().slice(0, 20)}" / "${boxes[c].e.textContent.trim().slice(0, 20)}"`); a = boxes.length; break; } }
  const texts = [...card.querySelectorAll('svg text')].filter(t => { const s = getComputedStyle(t); return s.display !== 'none' && s.visibility !== 'hidden' && +s.opacity !== 0 && +(t.getAttribute('fill-opacity') ?? 1) !== 0 && !t.closest('[opacity="0"]'); }).map(t => ({t: t.textContent, b: t.getBoundingClientRect()})).filter(x => x.b.width);
  for (let a = 0; a < texts.length; a++) for (let c = a + 1; c < texts.length; c++) { const A = texts[a].b, B = texts[c].b; if (A.left < B.right && B.left < A.right && A.top < B.bottom && B.top < A.bottom) { issues.push(`labels overlap: "${texts[a].t}" / "${texts[c].t}"`); a = texts.length; break; } }
  // Words covered, judged on what is painted, not on boxes: a drawing's label on the column's words, words
  // on words, a drawing drawn past its own box over the words (a box on a box that paints nothing there is no fault).
  if (inn) {
    const pe = document.createElement('style'); pe.textContent = '*{pointer-events:auto!important} svg *{pointer-events:visiblePainted!important}'; document.head.appendChild(pe);
    const alpha = c => { const m = /rgba?\(([^)]+)\)/.exec(c || ''); if (!m) return c === 'none' || c === 'transparent' ? 0 : 1; const q = m[1].split(/[ ,/]+/).filter(Boolean); return q.length > 3 ? parseFloat(q[3]) : 1; };
    const seen = el => { for (let e = el; e && e !== document.body; e = e.parentElement) { const st = getComputedStyle(e); if (st.display === 'none' || st.visibility === 'hidden' || +st.opacity < 0.05 || e.classList.contains('gone') || e.getAttribute('opacity') === '0') return false; } return true; };
    const inked = el => { const st = getComputedStyle(el); return alpha(st.color) > 0.05 || st.backgroundClip === 'text' || st.webkitBackgroundClip === 'text'; };
    const paints = g => { const st = getComputedStyle(g); let o = 1; for (let e = g; e && e.tagName !== 'svg'; e = e.parentElement) o *= +getComputedStyle(e).opacity; const f = (st.fill || '').startsWith('url') ? 1 : alpha(st.fill), k = (st.stroke || '').startsWith('url') ? 1 : alpha(st.stroke); return o * Math.max(f * +st.fillOpacity, parseFloat(st.strokeWidth) > 0 ? k * +st.strokeOpacity : 0) >= 0.25; };
    const meet = (A, B) => ({l: Math.max(A.left, B.left), r: Math.min(A.right, B.right), t: Math.max(A.top, B.top), b: Math.min(A.bottom, B.bottom)});
    const both = (I, A, B) => { let n = 0; for (let i = 0; i < 5; i++) for (let j = 0; j < 5; j++) { const at = document.elementsFromPoint(I.l + (I.r - I.l) * (i + .5) / 5, I.t + (I.b - I.t) * (j + .5) / 5); if (at.includes(A) && at.includes(B) && ++n >= 2) return true; } return false; };
    const over = (A, B) => { const wv = Math.min(A.right, B.right) - Math.max(A.left, B.left), hv = Math.min(A.bottom, B.bottom) - Math.max(A.top, B.top); return wv > 4 && hv > .35 * Math.min(A.height, B.height) && hv > 3; };
    const words = [], tw = document.createTreeWalker(inn, NodeFilter.SHOW_TEXT);
    for (let n = tw.nextNode(); n; n = tw.nextNode()) { const el = n.parentElement; if (!n.textContent.trim() || !el || el.closest('svg') || el.closest('.label') || !seen(el) || !inked(el)) continue; const rg = document.createRange(); rg.selectNodeContents(n); for (const b of rg.getClientRects()) if (b.width > 2 && b.height > 2) words.push({el, t: n.textContent.trim().slice(0, 24), b}); }
    const marks = [...inn.querySelectorAll('svg text')].filter(t => t.textContent.trim() && seen(t) && paints(t)).map(t => ({el: t, t: t.textContent.trim().slice(0, 24), b: t.getBoundingClientRect()}));
    for (const m of marks) { const w = words.find(w => over(m.b, w.b) && both(meet(m.b, w.b), m.el, w.el)); if (w) { issues.push(`a drawing's label covers the words: "${m.t}" / "${w.t}"`); break; } }
    words: for (let a = 0; a < words.length; a++) for (let c = a + 1; c < words.length; c++) { const A = words[a], B = words[c]; if (A.el === B.el || A.el.contains(B.el) || B.el.contains(A.el)) continue; if (over(A.b, B.b) && both(meet(A.b, B.b), A.el, B.el)) { issues.push(`words cover words: "${A.t}" / "${B.t}"`); break words; } }
    spill: for (const svg of inn.querySelectorAll('svg')) { if (svg.parentElement.closest('svg') || svg.closest('.label') || !seen(svg)) continue; const sb = svg.getBoundingClientRect(); if (sb.width < 20) continue;
      for (const g of svg.querySelectorAll('path,rect,circle,ellipse,line,polyline,polygon,text,image,use')) { if (g.closest('defs,clipPath,mask,pattern,marker,symbol') || !seen(g) || (!g.matches('image,use') && !paints(g))) continue; const b = g.getBoundingClientRect();
        if (b.width < 2 && b.height < 2 || !(b.bottom > sb.bottom + 4 || b.top < sb.top - 4 || b.left < sb.left - 4 || b.right > sb.right + 4)) continue;
        const w = words.find(w => { const I = meet(b, w.b); return I.r - I.l > 4 && I.b - I.t > 4 && !(I.t >= sb.top - 4 && I.b <= sb.bottom + 4 && I.l >= sb.left - 4 && I.r <= sb.right + 4) && both(I, g, w.el); });
        if (w) { issues.push(`the drawing spills over the words: "${w.t}"`); break spill; } } }
    pe.remove();
  }
  const kids = inn ? [...inn.children].filter(k => !k.classList.contains('gone') && getComputedStyle(k).display !== 'none') : [];
  for (let k = 1; k < kids.length; k++) { const gap = kids[k].getBoundingClientRect().top - kids[k - 1].getBoundingClientRect().bottom; if (gap > cb.height * .22 && !kids[k - 1].classList.contains('stagebox')) issues.push(`empty band of ${Math.round(gap)}px`); }
  // How tall the drawing is, and how much of the column's foot is left empty: held start to end by the caller.
  const pics = inn ? [...inn.querySelectorAll('svg, canvas')].filter(e => !e.closest('.gone') && !e.parentElement.closest('svg') && getComputedStyle(e).display !== 'none') : [];
  const painted = e => { if (e.tagName !== 'svg') return e.getBoundingClientRect(); let t = Infinity, b = -Infinity;
    for (const g of e.querySelectorAll('path,rect,circle,ellipse,line,polyline,polygon,text,image,use')) { const st = getComputedStyle(g); if (st.display === 'none' || st.visibility === 'hidden' || +st.opacity === 0 || g.closest('[opacity="0"],defs,clipPath,mask,pattern')) continue; const r = g.getBoundingClientRect(); if (!r.width && !r.height) continue; t = Math.min(t, r.top); b = Math.max(b, r.bottom); }
    return {height: b > t ? b - t : 0}; };
  const drawH = Math.max(0, ...pics.map(e => painted(e).height));
  // How large a drawing is shown against the size it was drawn for: an SVG drawn once for the room it
  // had and then given less (the answer coming in) is shrunk whole, labels and all, into a corner of it.
  // Each drawing by its place among them, so the end compares a drawing with itself at the start (an icon drawn
  // small on purpose, shown only at the end, is no drawing shrunk).
  const fit = {}; pics.forEach((e, i) => { if (e.tagName !== 'svg' || !e.viewBox || !e.viewBox.baseVal || !e.viewBox.baseVal.width || (e.getAttribute('preserveAspectRatio') || '').startsWith('none')) return;
    const r = e.getBoundingClientRect(), v = e.viewBox.baseVal; if (r.width >= 60 && r.height >= 40) fit[e.id || 'svg' + i] = Math.min(r.width / v.width, r.height / v.height); });
  const body = kids.filter(k => !k.matches('.foot, .src'));
  const footEl = inn && inn.querySelector(':scope > .foot, :scope > .src');
  let low = -Infinity; for (const k of body) for (const el of [k, ...k.querySelectorAll('*')]) { if (el.closest('svg') && el.tagName !== 'svg') continue; const st = getComputedStyle(el); if (st.display === 'none' || st.visibility === 'hidden' || +st.opacity === 0 || el.closest('.gone')) continue; if (!([...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()) || el.matches('svg,canvas,img,button,input'))) continue; const r = el.getBoundingClientRect(); if (r.width && r.height) low = Math.max(low, r.bottom); }
  const foot = isFinite(low) ? (footEl ? footEl.getBoundingClientRect().top : inn.getBoundingClientRect().bottom) - low : 0;
  // A drawing left too little room to draw again (under 100 px, a small phone) keeps the one it has, shown
  // smaller and whole, and says so (data-kept): drawn again in a strip, it would break.
  const kept = !!(inn && inn.querySelector('[data-kept]'));
  return {id: card.id, issues, drawH, fit, kept, foot, cardH: cb.height};
}

async function deck() {
  const phones = {small: {width: 360, height: 740}, medium: {width: 390, height: 844}, large: {width: 430, height: 932}};
  const browser = await pw.chromium.launch({executablePath});
  let problems = 0;
  for (const [name, vp] of Object.entries(phones)) {
    const page = await browser.newPage({viewport: vp});
    await page.route(/^https:\/\/(cdn\.jsdelivr\.net|cdnjs\.cloudflare\.com|unpkg\.com)\//, r => { const p = local(r.request().url()); return p ? r.fulfill({path: p, contentType: typeOf(p)}) : r.continue(); });
    // Fonts come from the system if installed.
    await page.route(/^https:\/\/fonts\.(googleapis|gstatic)\.com\//, r => r.abort());
    const errors = []; page.on('pageerror', e => errors.push(e.message));
    await page.goto('file://' + file); await page.waitForTimeout(1500);
    const n = await page.locator('.card').count();
    for (let i = 0; i < n; i++) {
      await page.waitForTimeout(900);
      for (const stage of ['start', 'end']) {
        if (stage === 'end') { const played = await page.evaluate(async () => { const id = document.querySelector('.card.on')?.id; const f = typeof Kit !== 'undefined' && Kit.play && Kit.play[id]; if (!f) return false; await f(); return true; }); if (!played) break; await page.waitForTimeout(3000); }
        const r = await page.evaluate(inspect);
        await page.screenshot({path: path.join(out, `${r.id}-${name}-${stage}.png`)});
        if (r.issues.length) { problems += r.issues.length; console.log(`✗ ${r.id} on ${name} (${stage}): ${r.issues.join('; ')}`); }
      }
      if (i < n - 1) await page.click('#next');
    }
    if (errors.length) { problems += errors.length; console.log(`✗ script errors on ${name}: ${errors.join(' | ')}`); }
    await page.close();
  }
  await browser.close();
  console.log(problems ? `${problems} problem(s). Screenshots in ${out}` : `All cards clear on three phones. Screenshots in ${out}`);
  process.exit(problems ? 1 : 0);
}

async function single() {
  // The card's face on Today (lib/widgets/pill_card_stack.dart, measured in the app): the phone, and
  // the card the deck gives it, 18 a side and what the bars and the header leave.
  const phones = {small: {phone: '375x667', width: 339, height: 475}, medium: {phone: '402x874', width: 366, height: 606}, large: {phone: '430x932', width: 394, height: 667}};
  // The save and share sit 17 from the right and 15 from the bottom, two 44-point targets 4 apart
  // (_CardControl in lib/widgets/pill_card.dart); inside the page's padding they take 88 by 37.
  const CORNER = {w: 88, h: 37}, CONTROLS = {right: 17, bottom: 15, width: 92, height: 44};
  const json = path.join(path.dirname(file), path.basename(file, '.html') + '.json');
  const meta = fs.existsSync(json) ? JSON.parse(fs.readFileSync(json, 'utf8')) : {};
  const web = meta.web || {};
  const topic = meta.topic || (source.match(/data-topic="([a-z_]+)"/) || [])[1] || 'thinking';
  const asks = meta.kind ? meta.kind !== 'read' : /Kit\.answer\(/.test(source);
  const graded = meta.kind ? ['pickOne', 'number', 'estimate'].includes(meta.kind) || (meta.kind === 'page' && web.graded !== false) : true;
  const name = path.basename(file, '.html');
  const bridge = fs.readFileSync(path.join(KIT, 'astute-bridge.js'), 'utf8');
  const ORIGIN = 'https://card.astute/';
  const browser = await pw.chromium.launch({executablePath});
  let problems = 0;
  const say = (where, list) => { if (!list.length) return; problems += list.length; console.log(`✗ ${name} ${where}: ${list.join('; ')}`); };

  async function open(vp, opts) {
    const page = await browser.newPage({viewport: {width: vp.width, height: vp.height}, deviceScaleFactor: 2});
    const heard = [], errors = [], asked = [];
    await page.exposeFunction('__astuteHeard', text => heard.push(JSON.parse(text)));
    const env = {mode: 'app', theme: opts.theme || 'dark', lang: 'en', calm: !!opts.calm, sound: false, touch: web.touch || 'taps', platform: 'ios', shown: true,
      size: {w: vp.width, h: vp.height}, safe: {top: 0, right: 0, bottom: 0, left: 0}, corner: CORNER, subject: {key: topic}};
    await page.addInitScript(([e, b]) => { window.ASTUTE_ENV = e; window.ASTUTE_SEND = t => window.__astuteHeard(t); (0, eval)(b); }, [env, bridge]);
    page.on('pageerror', e => errors.push(e.message));
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    await page.route('**/*', r => {
      const url = r.request().url();
      if (url === ORIGIN + 'card.html') return r.fulfill({body: source, contentType: 'text/html'});
      if (url.startsWith(ORIGIN + 'kit/')) { const p = path.join(KIT, decodeURIComponent(url.slice(ORIGIN.length + 4).split('?')[0])); return fs.existsSync(p) ? r.fulfill({path: p, contentType: typeOf(p)}) : (asked.push(url), r.abort()); }
      if (/^https:\/\/(cdn\.jsdelivr\.net|cdnjs\.cloudflare\.com|unpkg\.com)\//.test(url)) { const p = local(url); if (p) return r.fulfill({path: p, contentType: typeOf(p)}); }
      if (/^https:\/\/fonts\.googleapis\.com\/css2/.test(url)) return r.fulfill({body: fs.readFileSync(path.join(KIT, 'fonts.css'), 'utf8').replace(/url\(fonts\//g, `url(${ORIGIN}kit/fonts/`), contentType: 'text/css'});
      if (url.startsWith('data:') || url.startsWith('blob:')) return r.continue();
      asked.push(url); return r.abort();
    });
    await page.goto(ORIGIN + 'card.html');
    return {page, heard, errors, asked};
  }

  for (const [phone, vp] of Object.entries(phones)) {
    for (const calm of [false, true]) {
      if (calm && phone !== 'medium') continue;
      const tag = calm ? `${phone}-calm` : phone;
      const s = await openAndWait(vp, {calm});
      const {page: p, heard, errors, asked} = s;
      const where = `on ${phone} (${vp.phone}${calm ? ', motion reduced' : ''})`;
      if (!heard.some(m => m.t === 'ready')) say(where, ['never said it was ready (Kit.single() and a first frame)']);
      // The finger, shared with the deck (lib/widgets/web/page_gestures.dart): a drag that starts
      // outside the zones the page reported throws the card. So every slider on show, and anything
      // the page marked data-drag, must lie inside a zone, or dragging it sends the card away.
      if (!calm) {
        await p.waitForTimeout(300);
        const zones = (heard.filter(m => m.t === 'zones').pop() || {rects: []}).rects;
        const held = await p.evaluate(() => [...document.querySelectorAll('input[type=range],[data-drag]')]
          .filter(el => el.getAttribute('data-drag') !== 'off' && !el.closest('.gone'))
          .map(el => { const s = getComputedStyle(el), b = el.getBoundingClientRect();
            return s.display === 'none' || s.visibility === 'hidden' || b.width < 1 || b.height < 1 ? null
              : {what: el.id ? '#' + el.id : el.tagName.toLowerCase(), x: b.left + b.width / 2, y: b.top + b.height / 2}; })
          .filter(Boolean));
        const inside = (h) => zones.some(([x, y, w, ht]) => h.x >= x && h.x <= x + w && h.y >= y && h.y <= y + ht);
        say(where, held.filter(h => !inside(h)).map(h => `${h.what} is dragged, but the app would throw the card: mark it data-drag on a card whose web.touch is drags`));
      }
      let drawStart = 0, fitStart = {};
      for (const stage of ['start', 'end']) {
        if (stage === 'end') {
          const played = await p.evaluate(async () => { const f = typeof Kit !== 'undefined' && Kit.play && Kit.play[document.querySelector('.card')?.id]; if (!f) return false; await f(); return true; });
          if (!played) { say(where, ['no Kit.play: the end state cannot be photographed']); break; }
          await p.waitForTimeout(calm ? 800 : 3200);
        }
        const r = await p.evaluate(inspect);
        // The drawing must come back as it was when the answer shows: not squeezed to make room, with the foot left bare.
        if (stage === 'start') { drawStart = r.drawH; fitStart = r.fit; }
        else if (drawStart && r.drawH < drawStart * .8 && r.foot > r.cardH * .07) r.issues.push(`the drawing shrinks at the end (${Math.round(drawStart)} to ${Math.round(r.drawH)}px) and leaves ${Math.round(r.foot)}px empty below`);
        // Nor shrunk whole into the room the answer leaves it, nor squeezed to a strip: drawn again, at the size it now has.
        if (stage === 'end' && !r.kept) for (const k in r.fit) if (fitStart[k] && r.fit[k] < fitStart[k] * .88) { r.issues.push(`the drawing is shown at ${Math.round(100 * r.fit[k] / fitStart[k])}% of the size it was drawn for: draw it again when its room changes`); break; }
        if (stage === 'end' && !r.kept && drawStart && r.drawH < drawStart * .45 && r.drawH < r.cardH * .2) r.issues.push(`the drawing is squeezed at the end (${Math.round(drawStart)} to ${Math.round(r.drawH)}px tall)`);
        const more = await p.evaluate(([corner, controls]) => {
          const issues = [], W = innerWidth, H = innerHeight;
          if (document.scrollingElement.scrollHeight > H + 1 || document.scrollingElement.scrollWidth > W + 1) issues.push('the page scrolls');
          // Under the save and share: what a finger meant for the card would press instead.
          const cx = W - controls.right - controls.width, cy = H - controls.bottom - controls.height;
          for (const el of document.querySelectorAll('.card .in *')) {
            const st = getComputedStyle(el); if (st.display === 'none' || st.visibility === 'hidden' || +st.opacity === 0 || el.closest('.gone') || (el.closest('svg') && el.tagName !== 'svg')) continue;
            const own = [...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()) || el.matches('button,input,canvas,svg,img');
            if (!own) continue;
            const b = el.getBoundingClientRect(); if (!b.width || !b.height) continue;
            if (b.right > cx + 1 && b.bottom > cy + 1 && b.left < W - controls.right && b.top < H - controls.bottom) { issues.push(`under the save and share: <${el.tagName.toLowerCase()}> "${(el.textContent || '').trim().slice(0, 24)}"`); break; }
          }
          // Text too small to read on a phone.
          for (const el of document.querySelectorAll('.card *')) {
            const st = getComputedStyle(el); if (st.display === 'none' || st.visibility === 'hidden' || +st.opacity === 0 || el.closest('.gone')) continue;
            if (![...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim())) continue;
            const px = parseFloat(st.fontSize); if (px < 9) { issues.push(`text set at ${px.toFixed(1)}px: "${el.textContent.trim().slice(0, 24)}"`); break; }
          }
          return issues;
        }, [CORNER, CONTROLS]);
        // A canvas drawn once for one size and then shown at another is stretched by the browser: a
        // half circle turns into a flat dome. It happens when the page moves around it (the answer
        // coming in takes room from the drawing) and the page does not draw again.
        more.push(...(await p.evaluate(() => [...document.querySelectorAll('canvas')].filter(cv => {
          const b = cv.getBoundingClientRect(); if (b.width < 40 || b.height < 40 || !cv.width || !cv.height) return false;
          const st = getComputedStyle(cv); if (st.display === 'none' || st.visibility === 'hidden' || cv.closest('.gone')) return false;
          return Math.abs((cv.width / cv.height) / (b.width / b.height) - 1) > 0.03;
        }).map(cv => `the drawing is stretched: ${cv.id ? '#' + cv.id : 'a canvas'} was drawn for another size and not drawn again`))));
        // What to keep, once shown, must be seen: a page that fades it in with its own gsap.from on
        // top of Kit.show's fade catches it at opacity 0 and leaves it there, an empty band at the end.
        if (stage === 'end') more.push(...(await p.evaluate(() => [...document.querySelectorAll('.keep')].filter(el => {
          if (el.closest('.gone')) return false;
          for (let e = el; e && e !== document.body; e = e.parentElement) if (+getComputedStyle(e).opacity < .5) return true;
          return false;
        }).map(() => 'what to keep is shown but invisible (a second fade left it at opacity 0)'))));
        // The photograph is the card as the app draws it: its corners rounded and the save and share
        // in theirs, so it can be looked at as a reader would see it.
        if (!process.env.BARE) await p.evaluate(controls => {
          if (document.getElementById('__frame')) return;
          const f = document.createElement('div'); f.id = '__frame';
          f.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:2147483647;border-radius:34px;box-shadow:0 0 0 40px #000';
          const ink = getComputedStyle(document.querySelector('.card')).getPropertyValue('--k') || '#000';
          f.innerHTML = `<div style="position:absolute;right:${controls.right}px;bottom:${controls.bottom}px;display:flex;gap:4px;opacity:.62;color:${ink}">` +
            ['M6 3h12v18l-6-4-6 4z', 'M12 3v12M7 8l5-5 5 5M5 14v6h14v-6'].map(d => `<svg width="44" height="44" viewBox="-10 -10 44 44"><path d="${d}" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/></svg>`).join('') + '</div>';
          document.body.appendChild(f);
        }, CONTROLS);
        await p.screenshot({path: path.join(out, `${name}-${tag}-${stage}.png`)});
        await p.evaluate(() => document.getElementById('__frame')?.remove());
        say(`${where} (${stage})`, [...r.issues, ...more]);
      }
      // What the app heard.
      const answers = heard.filter(m => m.t === 'answer');
      if (asks && !answers.length) say(where, ['played through, it never sent an answer (Kit.answer)']);
      for (const a of answers) {
        const bad = [];
        if (!a.choice) bad.push('an answer without a choice');
        if (graded && typeof a.correct !== 'boolean') bad.push('a graded card says right or wrong');
        if (a.sure !== null && ![50, 60, 70, 80, 90].includes(a.sure)) bad.push(`sure is ${a.sure}, not one of 50 60 70 80 90`);
        say(where, bad);
      }
      say(where, heard.filter(m => m.t === 'error').map(m => `the page broke: ${m.message}`));
      say(where, errors.map(e => `script error: ${e}`));
      say(where, [...new Set(asked)].map(u => `asked the network for ${u.slice(0, 90)}`));
      await p.close();
    }
  }
  async function openAndWait(vp, opts) {
    const s = await open(vp, opts);
    // Ready is a message to the app: wait for it to arrive, up to six seconds.
    for (let t = 0; t < 60 && !s.heard.some(m => m.t === 'ready'); t++) await s.page.waitForTimeout(100);
    // Then for its entrance to settle: the start photographed is the start a reader looks at.
    await s.page.waitForTimeout(1500);
    return s;
  }
  await browser.close();
  console.log(problems ? `${problems} problem(s). Screenshots in ${out}` : `${name}: clear on three phones, ready, answered. Screenshots in ${out}`);
  process.exit(problems ? 1 : 0);
}
