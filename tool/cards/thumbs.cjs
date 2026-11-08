// Photographs every free card's page, its front and its back, as the small pictures the app shows
// where a card is not opened: the day's five once read, the saved and liked shelves, Explore's feed.
//
//   node tool/cards/thumbs.cjs                 every page whose picture is missing or older than it
//   node tool/cards/thumbs.cjs <id> <id> ...   those pages, again
//
// A page is opened as the app opens it (the app's bridge in front, the kit and its fonts served from
// docs/cards/kit, nothing from the network), at the card's size on a 402-wide phone, at night. The
// front is taken once the page says it is ready and its entrance has settled; the back after
// Kit.play has played it through. Each is a WebP under web/cards/thumbs/, and thumbs/index.json
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
const vendor = path.join(KIT, 'vendor');
const executablePath = fs.existsSync('/opt/pw-browsers/chromium') ? '/opt/pw-browsers/chromium' : undefined;
const local = url => { const base = url.split('?')[0].split('/').pop(); for (const d of [vendor, path.join(vendor, 'gsap-plugins')]) { const p = path.join(d, base); if (fs.existsSync(p)) return p; } return null; };
const TYPES = {'.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.woff2': 'font/woff2', '.wasm': 'application/wasm', '.json': 'application/json', '.html': 'text/html', '.png': 'image/png', '.svg': 'image/svg+xml'};
const typeOf = p => TYPES[path.extname(p)] || 'application/octet-stream';
// The card on Today on a 402-wide phone (card_check.cjs, "medium"), photographed at twice its size.
const SIZE = {width: 366, height: 606}, SCALE = 1.25;
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

async function shoot(browser, card) {
  const page = await browser.newPage({viewport: SIZE, deviceScaleFactor: SCALE});
  const heard = [];
  await page.exposeFunction('__astuteHeard', t => heard.push(JSON.parse(t)));
  const web = card.meta.web || {};
  const env = {mode: 'app', theme: 'dark', lang: 'en', calm: false, sound: false, touch: web.touch || 'taps', platform: 'ios', shown: true,
    size: {w: SIZE.width, h: SIZE.height}, safe: {top: 0, right: 0, bottom: 0, left: 0}, corner: {w: 88, h: 37}, subject: {key: card.meta.topic}};
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
    await page.waitForTimeout(1500);
    await page.screenshot({path: path.join(RAW, `${card.id}-front.png`)});
    const played = await page.evaluate(async () => { const f = typeof Kit !== 'undefined' && Kit.play && Kit.play[document.querySelector('.card')?.id]; if (!f) return false; await f(); return true; });
    if (!played) throw new Error('no Kit.play');
    await page.waitForTimeout(3200);
    await page.screenshot({path: path.join(RAW, `${card.id}-back.png`)});
  } finally {
    await page.close();
  }
}

(async () => {
  fs.mkdirSync(OUT, {recursive: true}); fs.rmSync(RAW, {recursive: true, force: true}); fs.mkdirSync(RAW, {recursive: true});
  const index = fs.existsSync(INDEX) ? JSON.parse(fs.readFileSync(INDEX, 'utf8')) : {};
  const all = pages();
  const named = new Set(process.argv.slice(2));
  const todo = all.filter(c => named.size ? named.has(c.id) : index[c.id] !== hashOf(c.html) || !fs.existsSync(path.join(OUT, `${c.id}-back.webp`)));
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
      try { await shoot(browser, c); index[c.id] = hashOf(c.html); done++; }
      catch (e) { failed.push(`${c.id} (${e.message})`); delete index[c.id]; }
      if ((done + failed.length) % 20 === 0) { save(); console.log(`${done + failed.length} of ${todo.length}`); }
    }
  }
  await Promise.all([worker(), worker(), worker()]);
  await browser.close();
  // Pictures of pages no longer in the bank go.
  const live = new Set(all.map(c => c.id));
  for (const f of fs.readdirSync(OUT)) { const m = f.match(/^(.*)-(front|back)\.webp$/); if (m && !live.has(m[1])) fs.unlinkSync(path.join(OUT, f)); }
  const made = require('child_process').spawnSync('python3', [path.join(__dirname, 'thumbs_webp.py'), RAW, OUT], {stdio: 'inherit'});
  if (made.status !== 0) { console.error('the pictures could not be made small'); process.exit(1); }
  save();
  console.log(`${done} pages photographed, ${all.length - todo.length} already current${failed.length ? `; failed: ${failed.join(', ')}` : ''}`);
})().catch(e => { console.error(e); process.exit(1); });
