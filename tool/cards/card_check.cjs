// Photographs cards on three phones and reports what the eye would catch: something spilling out of
// the card, the card's column overflowing, labels in a drawing overlapping, a big empty band.
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
  const kids = inn ? [...inn.children].filter(k => !k.classList.contains('gone') && getComputedStyle(k).display !== 'none') : [];
  for (let k = 1; k < kids.length; k++) { const gap = kids[k].getBoundingClientRect().top - kids[k - 1].getBoundingClientRect().bottom; if (gap > cb.height * .22 && !kids[k - 1].classList.contains('stagebox')) issues.push(`empty band of ${Math.round(gap)}px`); }
  return {id: card.id, issues};
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
      for (const stage of ['start', 'end']) {
        if (stage === 'end') {
          const played = await p.evaluate(async () => { const f = typeof Kit !== 'undefined' && Kit.play && Kit.play[document.querySelector('.card')?.id]; if (!f) return false; await f(); return true; });
          if (!played) { say(where, ['no Kit.play: the end state cannot be photographed']); break; }
          await p.waitForTimeout(calm ? 800 : 3200);
        }
        const r = await p.evaluate(inspect);
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
        // The photograph is the card as the app draws it: its corners rounded and the save and share
        // in theirs, so it can be looked at as a reader would see it.
        await p.evaluate(controls => {
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
    await s.page.waitForTimeout(400);
    return s;
  }
  await browser.close();
  console.log(problems ? `${problems} problem(s). Screenshots in ${out}` : `${name}: clear on three phones, ready, answered. Screenshots in ${out}`);
  process.exit(problems ? 1 : 0);
}
