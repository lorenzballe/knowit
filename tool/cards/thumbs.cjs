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
//
// A hard card is read ringed (lib/widgets/hard_ring.dart), so it is also taken ringed: told the colours the app
// tells its page (env.hard, tool/cards/hard_env.cjs), at night (<id>-ringed-front, -back) and on the day paper
// (<id>-ringed-day-front, -back), the ring itself left to the app, which draws it round the picture. Its own pictures
// stay as they were, for the builds that draw it as it was. thumbs/ringed.json keeps the hash those were taken
// under: the page's with the ring's edition (RINGED), so a page changed or a ring changed is taken again, under a
// new name the phones fetch anew.
const path = require('path'), fs = require('fs'), crypto = require('crypto');
let pw; try { pw = require('playwright'); } catch { pw = require('/opt/node22/lib/node_modules/playwright'); }
const hardEnv = require('./hard_env.cjs');

const ROOT = path.join(__dirname, '../..');
const BANK = path.join(ROOT, 'tool/cards/bank');
const KIT = path.join(ROOT, 'docs/cards/kit');
const OUT = path.join(ROOT, 'web/cards/thumbs');
const INDEX = path.join(OUT, 'index.json');
const RINGED_INDEX = path.join(OUT, 'ringed.json');
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
// The pictures' edition, as tool/cards/bundle.py keeps it (PICTURES): bumped when the kit changes how
// every page is drawn, so every picture is taken again under a new name.
const PICTURES = '\n<!-- pictures 2 -->';
const hashOf = html => crypto.createHash('sha256').update(html + PICTURES, 'utf8').digest('hex').slice(0, 12);
// The ring's edition, as tool/cards/bundle.py keeps it (RINGED): bumped when a hard card's look ringed changes (its
// colours in lib/widgets/hard_ring.dart and tool/cards/hard_env.cjs, the kit's ring()), so every hard card's ringed
// pictures are taken again under a new name.
const RINGED = '\n<!-- ringed 1 -->';
const ringedHashOf = html => crypto.createHash('sha256').update(html + PICTURES + RINGED, 'utf8').digest('hex').slice(0, 12);
// A hard card's two looks ringed: the name its pictures carry, the paper, and the colours its page is told.
const LOOKS = [{name: 'ringed', theme: 'dark', day: false}, {name: 'ringed-day', theme: 'light', day: true}];
const hard = card => card.meta.difficulty === 'hard';

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

// Takes a page's front and back at [size] into [raw]: as it is, or, with [look] (one of LOOKS), a hard card ringed,
// its pictures named after the look (<id>-ringed-front.png).
async function shoot(browser, card, {size = SIZE, raw = RAW, look = null} = {}) {
  const page = await browser.newPage({viewport: size, deviceScaleFactor: SCALE});
  const heard = [];
  await page.exposeFunction('__astuteHeard', t => heard.push(JSON.parse(t)));
  const web = card.meta.web || {};
  const name = look ? `${card.id}-${look.name}` : card.id;
  const env = {mode: 'app', theme: look ? look.theme : 'dark', lang: 'en', calm: false, sound: false, touch: web.touch || 'taps', platform: 'ios', shown: true,
    size: {w: size.width, h: size.height}, safe: {top: 0, right: 0, bottom: 0, left: 0}, corner: {w: 88, h: 37}, subject: {key: card.meta.topic},
    ...(look ? {hard: hardEnv(card.meta.topic, {day: look.day})} : {})};
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
    await page.screenshot({path: path.join(raw, `${name}-front.png`)});
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
    await page.screenshot({path: path.join(raw, `${name}-back.png`)});
  } finally {
    await page.close();
  }
}

// Whether a picture of [name] (an id, or an id and a look) is on disk in every size the app asks for.
const taken = name => ['', 'large', 'shelf'].every(d => fs.existsSync(path.join(OUT, d, `${name}-back.webp`)));

(async () => {
  fs.mkdirSync(OUT, {recursive: true}); fs.rmSync(RAW, {recursive: true, force: true}); fs.mkdirSync(RAW, {recursive: true});
  fs.rmSync(RAW_SHELF, {recursive: true, force: true}); fs.mkdirSync(RAW_SHELF, {recursive: true});
  const index = fs.existsSync(INDEX) ? JSON.parse(fs.readFileSync(INDEX, 'utf8')) : {};
  const ringed = fs.existsSync(RINGED_INDEX) ? JSON.parse(fs.readFileSync(RINGED_INDEX, 'utf8')) : {};
  const all = pages();
  // --shelf-only takes the shelf's pictures and nothing else: for pages whose others are current.
  const shelfOnly = process.argv.includes('--shelf-only');
  const named = new Set(process.argv.slice(2).filter(a => !a.startsWith('--')));
  const shelfMissing = c => !fs.existsSync(path.join(OUT, 'shelf', `${c.id}-back.webp`));
  // What each page needs taken: its own pictures, and on a hard card those ringed, each where they are missing or
  // were taken from another page (or another ring) than this.
  const plainStale = c => named.size ? named.has(c.id) : shelfOnly ? shelfMissing(c) : index[c.id] !== hashOf(c.html) || !taken(c.id);
  const ringStale = c => hard(c) && !shelfOnly && (named.size ? named.has(c.id) : ringed[c.id] !== ringedHashOf(c.html) || LOOKS.some(l => !taken(`${c.id}-${l.name}`)));
  const todo = all.filter(c => plainStale(c) || ringStale(c));
  const browser = await pw.chromium.launch({executablePath});
  let done = 0, failed = [];
  const queue = [...todo];
  const save = () => {
    const live = new Set(all.map(c => c.id)), hardLive = new Set(all.filter(hard).map(c => c.id));
    const sorted = (ix, keep) => Object.fromEntries(Object.keys(ix).filter(k => keep.has(k)).sort().map(k => [k, ix[k]]));
    fs.writeFileSync(INDEX, JSON.stringify(sorted(index, live), null, 1) + '\n');
    fs.writeFileSync(RINGED_INDEX, JSON.stringify(sorted(ringed, hardLive), null, 1) + '\n');
  };
  async function worker() {
    for (let c = queue.shift(); c; c = queue.shift()) {
      const plain = plainStale(c), ring = ringStale(c);
      let plainTaken = false;
      try {
        if (plain) {
          if (!shelfOnly) await shoot(browser, c);
          await shoot(browser, c, {size: SHELF, raw: RAW_SHELF});
          index[c.id] = hashOf(c.html); plainTaken = true;
        }
        if (ring) {
          delete ringed[c.id];
          for (const look of LOOKS) { await shoot(browser, c, {look}); await shoot(browser, c, {size: SHELF, raw: RAW_SHELF, look}); }
          ringed[c.id] = ringedHashOf(c.html);
        }
        done++;
      } catch (e) {
        // What was not taken is named nowhere (bundle.py leaves the card without it) and taken again next time.
        failed.push(`${c.id} (${e.message})`); if (plain && !plainTaken) delete index[c.id]; if (ring) delete ringed[c.id];
      }
      if ((done + failed.length) % 20 === 0) { save(); console.log(`${done + failed.length} of ${todo.length}`); }
    }
  }
  // Three pages at once, or as many as THUMBS_WORKERS says: a page spends most of its time waiting.
  await Promise.all(Array.from({length: Number(process.env.THUMBS_WORKERS) || 3}, worker));
  await browser.close();
  // Pictures of pages no longer in the bank go, and the ringed ones of a card no longer hard.
  const live = new Set(all.map(c => c.id)), hardLive = new Set(all.filter(hard).map(c => c.id));
  for (const dir of [OUT, path.join(OUT, 'large'), path.join(OUT, 'shelf')]) {
    if (!fs.existsSync(dir)) continue;
    for (const f of fs.readdirSync(dir)) {
      const m = f.match(/^(.*?)(-ringed(?:-day)?)?-(front|back)\.webp$/);
      if (m && (m[2] ? !hardLive.has(m[1]) : !live.has(m[1]))) fs.unlinkSync(path.join(dir, f));
    }
  }
  const made = require('child_process').spawnSync('python3', [path.join(__dirname, 'thumbs_webp.py'), RAW, OUT], {stdio: 'inherit'});
  if (made.status !== 0) { console.error('the pictures could not be made small'); process.exit(1); }
  const shelf = require('child_process').spawnSync('python3', [path.join(__dirname, 'thumbs_webp.py'), RAW_SHELF, path.join(OUT, 'shelf'), '--one'], {stdio: 'inherit'});
  if (shelf.status !== 0) { console.error("the shelf's pictures could not be made"); process.exit(1); }
  save();
  console.log(`${done} pages photographed, ${all.length - todo.length} already current${failed.length ? `; failed: ${failed.join(', ')}` : ''}`);
})().catch(e => { console.error(e); process.exit(1); });
