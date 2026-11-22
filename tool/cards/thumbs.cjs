// Photographs every free card's page, its front and its back, as the small pictures the app shows
// where a card is not opened: the day's five once read, the saved and liked shelves, Explore's feed.
//
//   node tool/cards/thumbs.cjs                 every page whose picture is missing or older than it
//   node tool/cards/thumbs.cjs <id> <id> ...   those pages, again
//
// A page is opened as the app opens it (the app's bridge in front, the kit and its fonts served from
// docs/cards/kit, nothing from the network), at the card's size on a 402-wide phone, at night. The
// front is taken once the page says it is ready and its entrance has come to rest, its drawing as it
// ends; the back once Kit.play has played it through and it, too, has come to rest. Each is a WebP under web/cards/thumbs/, and thumbs/index.json
// keeps the hash of the page each was taken from (tool/cards/bundle.py names the pictures with it,
// and leaves a card without pictures until they are taken).
const path = require('path'), fs = require('fs'), crypto = require('crypto');
let pw; try { pw = require('playwright'); } catch { pw = require('/opt/node22/lib/node_modules/playwright'); }

const ROOT = path.join(__dirname, '../..');
const BANK = path.join(ROOT, 'tool/cards/bank');
const KIT = path.join(ROOT, 'docs/cards/kit');
const OUT = path.join(ROOT, 'web/cards/thumbs');
const INDEX = path.join(OUT, 'index.json');
// The photographs as taken, before tool/cards/thumbs_webp.py makes them small.
const RAW = path.join(require('os').tmpdir(), 'astute-thumbs');
const RAW_SHELF = RAW + '-shelf';
const vendor = path.join(KIT, 'vendor');
const executablePath = fs.existsSync('/opt/pw-browsers/chromium') ? '/opt/pw-browsers/chromium' : undefined;
const local = url => { const base = url.split('?')[0].split('/').pop(); for (const d of [vendor, path.join(vendor, 'gsap-plugins')]) { const p = path.join(d, base); if (fs.existsSync(p)) return p; } return null; };
const TYPES = {'.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.woff2': 'font/woff2', '.wasm': 'application/wasm', '.json': 'application/json', '.html': 'text/html', '.png': 'image/png', '.svg': 'image/svg+xml'};
const typeOf = p => TYPES[path.extname(p)] || 'application/octet-stream';
// The card on Today on a 402-wide phone (card_check.cjs, "medium"), photographed at two and a half
// times its size: the large pictures, for the places that show a card at full width, are these as
// taken; the small ones, for shelves and tiles, are made from them (thumbs_webp.py).
const SIZE = {width: 366, height: 606}, SCALE = 2.5;
// The finished day's shelf sets every card on the proportion of 324 by 452 its cards in words are drawn
// on: a picture taken at the deck's 366 by 606 had to shrink into it, its words smaller and a band of
// ground either side. So each page is also taken at the shelf's proportion, into thumbs/shelf/: 366
// across like the deck's, so the page has nearly the room it has there and its drawing, drawn again
// at that size, is not squashed (taken at 324 by 452 it was, on a card of Space).
const SHELF = {width: 366, height: 511};
const ORIGIN = 'https://card.astute/';
const hashOf = html => crypto.createHash('sha256').update(html, 'utf8').digest('hex').slice(0, 12);

function pages() {
  const out = [];
  for (const topic of fs.readdirSync(BANK)) {
    const dir = path.join(BANK, topic);
    if (!fs.statSync(dir).isDirectory()) continue;
    for (const f of fs.readdirSync(dir)) {
      if (!f.endsWith('.html')) continue;
      const json = path.join(dir, f.replace(/\.html$/, '.json'));
      if (!fs.existsSync(json)) continue;
      const html = fs.readFileSync(path.join(dir, f), 'utf8');
      if (!/Kit\.single\(\)/.test(html)) continue;
      out.push({id: f.replace(/\.html$/, ''), html, meta: JSON.parse(fs.readFileSync(json, 'utf8'))});
    }
  }
  return out;
}

// Whether what moves on the page has come to rest: no GSAP animation still to run (one paused, one
// under a paused timeline, or one that repeats forever is waiting, not moving) and no CSS animation
// of a set length still running.
const STILL = () => {
  let moving = 0;
  if (typeof gsap !== 'undefined') {
    for (const t of gsap.globalTimeline.getChildren(true, true, true)) {
      let held = false;
      for (let a = t; a; a = a.parent) if (a.paused && a.paused()) { held = true; break; }
      if (held || (t.repeat && t.repeat() === -1) || t.totalDuration() > 1e5) continue;
      if (t.progress() < 1) moving++;
    }
  }
  for (const a of document.getAnimations()) {
    if (a.playState === 'running' && a.effect?.getTiming?.().iterations !== Infinity) moving++;
  }
  return moving === 0;
};

// Waits at least [least] ms, then until the page is still, up to [most] ms: a card's picture shows
// its drawing as it ends, not halfway through coming in (the owner: the question side, with its
// animation already finished). A page that keeps moving is taken at [most].
async function settle(page, least, most) {
  await page.waitForTimeout(least);
  for (let waited = least; waited < most; waited += 100) {
    if (await page.evaluate(`(${STILL.toString()})()`)) break;
    await page.waitForTimeout(100);
  }
  // The frame after the last change, drawn.
  await page.waitForTimeout(150);
}

async function shoot(browser, card, size = SIZE, raw = RAW) {
  const page = await browser.newPage({viewport: size, deviceScaleFactor: SCALE});
  const heard = [];
  await page.exposeFunction('__astuteHeard', t => heard.push(JSON.parse(t)));
  const web = card.meta.web || {};
  const env = {mode: 'app', theme: 'dark', lang: 'en', calm: false, sound: false, touch: web.touch || 'taps', platform: 'ios', shown: true,
    size: {w: size.width, h: size.height}, safe: {top: 0, right: 0, bottom: 0, left: 0}, corner: {w: 88, h: 37}, subject: {key: card.meta.topic}};
  const bridge = fs.readFileSync(path.join(KIT, 'astute-bridge.js'), 'utf8');
  await page.addInitScript(([e, b]) => { window.ASTUTE_ENV = e; window.ASTUTE_SEND = t => window.__astuteHeard(t); (0, eval)(b); }, [env, bridge]);
  await page.route('**/*', r => {
    const url = r.request().url();
    if (url === ORIGIN + 'card.html') return r.fulfill({body: card.html, contentType: 'text/html'});
    if (url.startsWith(ORIGIN + 'kit/')) { const p = path.join(KIT, decodeURIComponent(url.slice(ORIGIN.length + 4).split('?')[0])); return fs.existsSync(p) ? r.fulfill({path: p, contentType: typeOf(p)}) : r.abort(); }
    if (/^https:\/\/(cdn\.jsdelivr\.net|cdnjs\.cloudflare\.com|unpkg\.com)\//.test(url)) { const p = local(url); if (p) return r.fulfill({path: p, contentType: typeOf(p)}); }
    if (/^https:\/\/fonts\.googleapis\.com\/css2/.test(url)) return r.fulfill({body: fs.readFileSync(path.join(KIT, 'fonts.css'), 'utf8').replace(/url\(fonts\//g, `url(${ORIGIN}kit/fonts/`), contentType: 'text/css'});
    if (url.startsWith('data:') || url.startsWith('blob:')) return r.continue();
    return r.abort();
  });
  try {
    await page.goto(ORIGIN + 'card.html');
    for (let t = 0; t < 60 && !heard.some(m => m.t === 'ready'); t++) await page.waitForTimeout(100);
    if (!heard.some(m => m.t === 'ready')) throw new Error('never ready');
    await settle(page, 1500, 8000);
    await page.screenshot({path: path.join(raw, `${card.id}-front.png`)});
    const played = await page.evaluate(async () => { const f = typeof Kit !== 'undefined' && Kit.play && Kit.play[document.querySelector('.card')?.id]; if (!f) return false; await f(); return true; });
    if (!played) throw new Error('no Kit.play');
    await settle(page, 3200, 9000);
    // The back is shown for a card someone read, with their own answer, which this one is not: the
    // answer played here is the photographer's. So what speaks of it (the kit's verdict line, and any
    // line or label saying what "you" said or guessed) is hidden, its room kept, before the picture.
    await page.evaluate(() => {
      const YOU = /\b(you (said|were|guessed|picked|chose|put|answered|placed|went)|your (guess|pick|answer|choice|bet|estimate))\b/i;
      document.querySelectorAll('.grade').forEach(el => { el.style.visibility = 'hidden'; });
      for (const el of document.querySelectorAll('.card *')) {
        const own = [...el.childNodes].filter(n => n.nodeType === 3).map(n => n.textContent).join(' ');
        if (YOU.test(own)) el.style.visibility = 'hidden';
      }
    });
    await page.waitForTimeout(100);
    await page.screenshot({path: path.join(raw, `${card.id}-back.png`)});
  } finally {
    await page.close();
  }
}

(async () => {
  fs.mkdirSync(OUT, {recursive: true}); fs.rmSync(RAW, {recursive: true, force: true}); fs.mkdirSync(RAW, {recursive: true});
  fs.rmSync(RAW_SHELF, {recursive: true, force: true}); fs.mkdirSync(RAW_SHELF, {recursive: true});
  const index = fs.existsSync(INDEX) ? JSON.parse(fs.readFileSync(INDEX, 'utf8')) : {};
  const all = pages();
  // --shelf-only takes the shelf's pictures and nothing else: for pages whose others are current.
  const shelfOnly = process.argv.includes('--shelf-only');
  const named = new Set(process.argv.slice(2).filter(a => !a.startsWith('--')));
  const shelfMissing = c => !fs.existsSync(path.join(OUT, 'shelf', `${c.id}-back.webp`));
  const todo = all.filter(c => named.size ? named.has(c.id) : shelfOnly ? shelfMissing(c) : index[c.id] !== hashOf(c.html) || !fs.existsSync(path.join(OUT, `${c.id}-back.webp`)) || !fs.existsSync(path.join(OUT, 'large', `${c.id}-back.webp`)) || shelfMissing(c));
  const browser = await pw.chromium.launch({executablePath});
  let done = 0, failed = [];
  const queue = [...todo];
  const save = () => {
    const live = new Set(all.map(c => c.id));
    const sorted = Object.fromEntries(Object.keys(index).filter(k => live.has(k)).sort().map(k => [k, index[k]]));
    fs.writeFileSync(INDEX, JSON.stringify(sorted, null, 1) + '\n');
  };
  async function worker() {
    for (let c = queue.shift(); c; c = queue.shift()) {
      try { if (!shelfOnly) await shoot(browser, c); await shoot(browser, c, SHELF, RAW_SHELF); index[c.id] = hashOf(c.html); done++; }
      catch (e) { failed.push(`${c.id} (${e.message})`); delete index[c.id]; }
      if ((done + failed.length) % 20 === 0) { save(); console.log(`${done + failed.length} of ${todo.length}`); }
    }
  }
  // Three pages at once, or as many as THUMBS_WORKERS says: a page spends most of its time waiting.
  await Promise.all(Array.from({length: Number(process.env.THUMBS_WORKERS) || 3}, worker));
  await browser.close();
  // Pictures of pages no longer in the bank go.
  const live = new Set(all.map(c => c.id));
  for (const dir of [OUT, path.join(OUT, 'large'), path.join(OUT, 'shelf')]) { if (!fs.existsSync(dir)) continue; for (const f of fs.readdirSync(dir)) { const m = f.match(/^(.*)-(front|back)\.webp$/); if (m && !live.has(m[1])) fs.unlinkSync(path.join(dir, f)); } }
  const made = require('child_process').spawnSync('python3', [path.join(__dirname, 'thumbs_webp.py'), RAW, OUT], {stdio: 'inherit'});
  if (made.status !== 0) { console.error('the pictures could not be made small'); process.exit(1); }
  const shelf = require('child_process').spawnSync('python3', [path.join(__dirname, 'thumbs_webp.py'), RAW_SHELF, path.join(OUT, 'shelf'), '--one'], {stdio: 'inherit'});
  if (shelf.status !== 0) { console.error("the shelf's pictures could not be made"); process.exit(1); }
  save();
  console.log(`${done} pages photographed, ${all.length - todo.length} already current${failed.length ? `; failed: ${failed.join(', ')}` : ''}`);
})().catch(e => { console.error(e); process.exit(1); });
