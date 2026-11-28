// Makes a short vertical video of a drawn card, for TikTok, Reels and Shorts: 1080 by 1920, H.264, silent
// (the kit has no sounds of its own), 20 to 40 seconds. Five beats: the question alone on the night paper;
// the card itself, played by its own hand (Kit.play, as tool/cards/card_check.cjs plays it) with a finger
// shown where it taps; the answer it ends on, held; the why in one line, with its source; and the close
// every video shares, "Five like this every morning · Astute" and where to get it.
//
//   node tool/marketing/card_video.cjs <card id> [--lang it|en] [--out dir] [--frames]
//
// The card is the page the app shows, opened as the app opens it (docs/cards/kit/astute-bridge.js in front,
// the kit and its fonts served from docs/cards/kit, nothing from the network), at the size of the card on
// Today on a 402-wide phone, and filmed with Playwright a frame at a time on the page's own clock (see
// film() for why not Playwright's video). The stills around it are pages of their own, photographed.
// ffmpeg puts them together and encodes the MP4.
//
// The video is in the card's own language. --lang it asks for Italian, and gets it when the card is written
// in Italian; a card in English (all of them, for now) makes an English video, and says so. Its words around
// the card, the close included, are in the same language, so a video never mixes two.
//
// Out: <out>/<id>-<lang>.mp4 (the system's temporary folder, astute-videos/, when no --out is given), and with --frames a
// still of each beat beside it, <id>-<lang>-1.png to -6.png, to be looked at before the video is posted.
// tool/marketing/README.md says how the owner makes one a day.
const path = require('path'), fs = require('fs'), os = require('os'), {execFileSync} = require('child_process');
let pw; try { pw = require('playwright'); } catch { pw = require('/opt/node22/lib/node_modules/playwright'); }

const ROOT = path.join(__dirname, '../..');
const BANK = path.join(ROOT, 'tool/cards/bank');
const KIT = path.join(ROOT, 'docs/cards/kit');
const vendor = path.join(KIT, 'vendor');
const executablePath = fs.existsSync('/opt/pw-browsers/chromium') ? '/opt/pw-browsers/chromium' : undefined;
const local = url => { const base = url.split('?')[0].split('/').pop(); for (const d of [vendor, path.join(vendor, 'gsap-plugins')]) { const p = path.join(d, base); if (fs.existsSync(p)) return p; } return null; };
const TYPES = {'.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css', '.woff2': 'font/woff2', '.wasm': 'application/wasm', '.json': 'application/json', '.html': 'text/html', '.png': 'image/png', '.svg': 'image/svg+xml'};
const typeOf = p => TYPES[path.extname(p)] || 'application/octet-stream';
const ORIGIN = 'https://card.astute/';

// The frame, and the card in it: the card on Today on a 402-wide phone (card_check.cjs, "medium"), recorded
// at two and a half times its size and shown 800 across, high enough that the apps' own buttons and captions
// at the foot of the screen leave its answer clear.
const FRAME = {w: 1080, h: 1920}, CARD = {w: 366, h: 606}, SCALE = 2.5, SHOWN = 800, TOP = 170;
// How long each beat holds, in seconds, and the fade between two.
const BEAT = {question: 2.6, why: 3.6, close: 3.2, fade: 0.35}, FPS = 30, LEAST = 20.5;
const NIGHT = '#0d0d0f', CREAM = '#f2f1ec', QUIET = '#a8a59d';

// The words around the card, in each language a video can be made in.
const WORDS = {
  en: {why: 'Why', source: 'Source', close: 'Five like this every morning', store: open => open ? 'On Google Play and the App Store' : 'Get it on Google Play'},
  it: {why: 'Perché', source: 'Fonte', close: 'Cinque così ogni mattina', store: open => open ? 'Su Google Play e sull’App Store' : 'Disponibile su Google Play'},
};

function args(argv) {
  const out = {id: null, lang: 'it', out: null, frames: false};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--lang') out.lang = argv[++i];
    else if (a === '--out') out.out = argv[++i];
    else if (a === '--frames') out.frames = true;
    else if (!out.id) out.id = a.replace(/\.html$/, '').split('/').pop();
  }
  if (!out.id) { console.error('usage: node tool/marketing/card_video.cjs <card id> [--lang it|en] [--out dir] [--frames]'); process.exit(2); }
  if (!WORDS[out.lang]) { console.error(`no words for ${out.lang}: it or en`); process.exit(2); }
  return out;
}

// The card's page and its file, wherever its subject keeps it.
function find(id) {
  for (const topic of fs.readdirSync(BANK)) {
    const html = path.join(BANK, topic, `${id}.html`);
    if (fs.existsSync(html)) {
      const json = html.replace(/\.html$/, '.json');
      return {html, source: fs.readFileSync(html, 'utf8'), meta: fs.existsSync(json) ? JSON.parse(fs.readFileSync(json, 'utf8')) : {}};
    }
  }
  console.error(`no page for ${id} in tool/cards/bank`); process.exit(1);
}

// What the app's strings call a subject, and Go deeper, in [lang] (lib/l10n/app_<lang>.arb).
function appWords(lang) {
  const arb = l => path.join(ROOT, 'lib/l10n', `app_${l}.arb`);
  return JSON.parse(fs.readFileSync(fs.existsSync(arb(lang)) ? arb(lang) : arb('en'), 'utf8'));
}
const subjectIn = (words, key) => (String(words.subjectName || '').match(new RegExp(`(?:^|\\s)${key}\\{([^}]*)\\}`)) || [])[1] || key;

// The source as the card's foot says it: who, then where and when — "Geopop · YouTube, 2018".
function shortSource(source) {
  const s = String(source || '').trim();
  if (!s) return '';
  const who = s.split(/,\s*[“"]/)[0].split(',')[0].trim();
  const where = (s.match(/\(([^()]*)\)\s*\.?$/) || [])[1];
  return where ? `${who} · ${where}` : who;
}

// The colour of the card's subject, as the kit draws it; on the night paper a deep one is lifted until small
// words read in it, as a hard card's ring lifts it (tool/cards/card_check.cjs, HARD).
function colourOf(topic) {
  const kit = fs.readFileSync(path.join(KIT, 'astute-card.js'), 'utf8');
  const colour = (kit.match(new RegExp(`\\b${topic}: \\['[^']*', '(#[0-9A-Fa-f]{6})'`)) || [])[1] || CREAM;
  const rgb = colour.slice(1).match(/../g).map(h => parseInt(h, 16));
  const lin = c => { c /= 255; return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); };
  const lum = 0.2126 * lin(rgb[0]) + 0.7152 * lin(rgb[1]) + 0.0722 * lin(rgb[2]);
  if (lum >= 0.16) return colour;
  return '#' + rgb.map(c => Math.round(c + (255 - c) * 0.4).toString(16).padStart(2, '0')).join('');
}

// Whether the App Store listing is open, as the site says (tool/site/chrome.py): the close names it then.
const appStoreOpen = () => /^APP_STORE_OPEN = True/m.test(fs.readFileSync(path.join(ROOT, 'tool/site/chrome.py'), 'utf8'));

const font = (name, file) => `@font-face{font-family:'${name}';src:url(data:font/woff2;base64,${fs.readFileSync(path.join(KIT, 'fonts', file)).toString('base64')}) format('woff2');font-weight:100 900;font-display:block}`;
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

// The stills: pages of their own, set in the app's faces on the night paper, kept inside the part of the
// screen the apps leave clear (their names at the top, their buttons on the right and captions at the foot).
function still(body, style) {
  return `<!doctype html><meta charset="utf-8"><style>${font('Fraunces', 'Fraunces.woff2')}${font('Figtree', 'Figtree.woff2')}
  html,body{margin:0;width:${FRAME.w}px;height:${FRAME.h}px;background:${NIGHT};color:${CREAM};overflow:hidden}
  body{font-family:Figtree,sans-serif;-webkit-font-smoothing:antialiased}
  .kick{font:700 30px/1 Figtree;letter-spacing:.16em;text-transform:uppercase}
  .big{font-family:Fraunces,serif;font-weight:560;letter-spacing:-.01em;text-wrap:balance}
  ${style}</style><body>${body}</body>`;
}

async function stills(browser, dir, v) {
  const page = await browser.newPage({viewport: {width: FRAME.w, height: FRAME.h}, deviceScaleFactor: 1});
  const shoot = async (name, html) => { await page.setContent(html); await page.evaluate(() => document.fonts.ready); await page.waitForTimeout(150); const p = path.join(dir, name); await page.screenshot({path: p}); return p; };
  const mark = `data:image/png;base64,${fs.readFileSync(path.join(ROOT, 'assets/brand/mark-dark.png')).toString('base64')}`;
  const question = await shoot('question.png', still(
    `<div class="col"><div class="kick" style="color:${v.colour}">${esc(v.subject)}</div><div class="big q">${esc(v.question)}</div><div class="rule" style="background:${v.colour}"></div></div>`,
    `.col{position:absolute;left:96px;right:150px;top:0;bottom:420px;display:flex;flex-direction:column;justify-content:center;gap:44px}
     .q{font-size:${v.question.length > 70 ? 82 : 96}px;line-height:1.08}.rule{width:120px;height:8px;border-radius:4px}`));
  const why = await shoot('why.png', still(
    `<div class="col"><div class="kick" style="color:${v.colour}">${esc(v.words.why)}</div><div class="big w">${esc(v.why)}</div>${v.source ? `<div class="src">${esc(v.words.source)} · ${esc(v.source)}</div>` : ''}</div>`,
    `.col{position:absolute;left:96px;right:150px;top:0;bottom:420px;display:flex;flex-direction:column;justify-content:center;gap:40px}
     .w{font-size:${v.why.length > 90 ? 64 : 76}px;line-height:1.14}.src{font:500 32px/1.3 Figtree;color:${QUIET}}`));
  const close = await shoot('close.png', still(
    `<div class="col"><img src="${mark}" alt=""><div class="big c">${esc(v.words.close)}</div><div class="name">Astute</div><div class="store">${esc(v.words.store(appStoreOpen()))}</div></div>`,
    `.col{position:absolute;left:96px;right:96px;top:0;bottom:360px;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;gap:34px}
     img{width:168px;height:168px;border-radius:38px;box-shadow:0 0 0 2px #26262b}
     .c{font-size:88px;line-height:1.08}.name{font:600 64px/1 Fraunces;letter-spacing:-.01em;color:${CREAM}}
     .store{font:600 32px/1 Figtree;letter-spacing:.02em;color:${CREAM};border:2px solid #4a4a50;border-radius:999px;padding:20px 34px}`));
  await page.close();
  return {question, why, close};
}

// The card, played and filmed, frame by frame. The page's clock is Playwright's and stands still between
// frames: each frame moves it on a thirtieth of a second and photographs the card at two and a half times
// its size, so nothing is dropped however busy the machine is, and every line is sharp. (Playwright's own
// video records a page at its size in CSS pixels, 366 by 606 for a card, too coarse for a 1080 frame.)
// Returns how many frames were taken, and the frame the card was played at.
async function film(browser, dir, card, v) {
  const env = {mode: 'app', theme: 'dark', lang: v.cardLang, calm: false, sound: false, touch: (card.meta.web || {}).touch || 'taps', platform: 'android', shown: true,
    size: {w: CARD.w, h: CARD.h}, safe: {top: 0, right: 0, bottom: 0, left: 0}, corner: {w: 88, h: 37},
    subject: {key: v.topic, name: v.subject}, note: null, foot: 'line', deeper: v.app.deeperTitle, why: null};
  const bridge = fs.readFileSync(path.join(KIT, 'astute-bridge.js'), 'utf8');
  const page = await browser.newPage({viewport: {width: CARD.w, height: CARD.h}, deviceScaleFactor: SCALE});
  const start = new Date('2026-11-28T08:30:00');
  await page.clock.install({time: start});
  await page.clock.pauseAt(new Date(start.getTime() + 1000));
  const heard = [], errors = [];
  await page.exposeFunction('__astuteHeard', text => heard.push(JSON.parse(text)));
  await page.addInitScript(([e, b]) => { window.ASTUTE_ENV = e; window.ASTUTE_SEND = t => window.__astuteHeard(t); (0, eval)(b); }, [env, bridge]);
  // A finger where the card is pressed: a soft ring at the middle of what Kit.play clicks, or where an event
  // it sends says the pointer is, drawn over everything and never in the way of a tap. It moves on the
  // page's own clock, so it is filmed like the card.
  await page.addInitScript(() => {
    const ring = (x, y) => {
      const r = document.createElement('div');
      r.style.cssText = `position:fixed;left:${x - 22}px;top:${y - 22}px;width:44px;height:44px;border-radius:50%;background:rgba(255,255,255,.34);box-shadow:0 0 0 2.5px rgba(255,255,255,.9),0 2px 10px rgba(0,0,0,.25);pointer-events:none;z-index:2147483647;opacity:0`;
      document.documentElement.appendChild(r);
      const t0 = performance.now();
      const step = () => {
        const t = (performance.now() - t0) / 720;
        if (t >= 1) { r.remove(); return; }
        const inT = Math.min(1, t / 0.35), outT = Math.max(0, (t - 0.5) / 0.5);
        r.style.opacity = String(Math.min(inT, 1 - outT));
        r.style.transform = `scale(${0.55 + 0.45 * (1 - (1 - inT) ** 3) + 0.2 * outT})`;
        requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    };
    let last = -1e9;
    const once = (x, y) => { const now = performance.now(); if (now - last < 120) return; last = now; ring(x, y); };
    const click = HTMLElement.prototype.click;
    HTMLElement.prototype.click = function () { const b = this.getBoundingClientRect(); if (b.width && b.height) once(b.left + b.width / 2, b.top + b.height / 2); return click.call(this); };
    const send = EventTarget.prototype.dispatchEvent;
    EventTarget.prototype.dispatchEvent = function (ev) {
      if (ev && /^(click|pointerdown|mousedown|touchstart)$/.test(ev.type) && ev.isTrusted === false) {
        let x = ev.clientX, y = ev.clientY;
        if (!(x || y) && this.getBoundingClientRect) { const b = this.getBoundingClientRect(); x = b.left + b.width / 2; y = b.top + b.height / 2; }
        if (x || y) once(x, y);
      }
      return send.call(this, ev);
    };
  });
  // The card's corners, as the app rounds them, on the night paper of the frame around it.
  await page.addInitScript(night => addEventListener('DOMContentLoaded', () => {
    const f = document.createElement('div');
    f.style.cssText = `position:fixed;inset:0;pointer-events:none;z-index:2147483646;border-radius:34px;box-shadow:0 0 0 40px ${night}`;
    document.documentElement.appendChild(f);
  }), NIGHT);
  page.on('pageerror', e => errors.push(e.message));
  await page.route('**/*', r => {
    const url = r.request().url();
    if (url === ORIGIN + 'card.html') return r.fulfill({body: card.source, contentType: 'text/html'});
    if (url.startsWith(ORIGIN + 'kit/')) { const p = path.join(KIT, decodeURIComponent(url.slice(ORIGIN.length + 4).split('?')[0])); return fs.existsSync(p) ? r.fulfill({path: p, contentType: typeOf(p)}) : r.abort(); }
    if (/^https:\/\/(cdn\.jsdelivr\.net|cdnjs\.cloudflare\.com|unpkg\.com)\//.test(url)) { const p = local(url); if (p) return r.fulfill({path: p, contentType: typeOf(p)}); }
    if (/^https:\/\/fonts\.googleapis\.com\/css2/.test(url)) return r.fulfill({body: fs.readFileSync(path.join(KIT, 'fonts.css'), 'utf8').replace(/url\(fonts\//g, `url(${ORIGIN}kit/fonts/`), contentType: 'text/css'});
    if (url.startsWith('data:') || url.startsWith('blob:')) return r.continue();
    return r.abort();
  });
  await page.goto(ORIGIN + 'card.html');
  // Ready is said after the fonts and two frames: the clock is moved on until it is.
  for (let t = 0; t < 100 && !heard.some(m => m.t === 'ready'); t++) { await page.clock.runFor(50); await page.waitForTimeout(10); }
  if (!heard.some(m => m.t === 'ready')) throw new Error('the card never said it was ready');
  let n = 0;
  const frame = async () => { await page.clock.runFor(1000 / FPS); await page.screenshot({path: path.join(dir, `f${String(n++).padStart(5, '0')}.png`)}); };
  const hold = async seconds => { for (let i = Math.round(seconds * FPS); i > 0; i--) await frame(); };
  // Its entrance, then a moment to read the question on it.
  await hold(2.3);
  const playAt = n;
  await page.evaluate(() => { const f = typeof Kit !== 'undefined' && Kit.play && Kit.play[document.querySelector('.card')?.id]; window.__played = f ? 'playing' : 'none'; if (f) Promise.resolve(f()).then(() => { window.__played = 'done'; }, e => { window.__played = 'failed: ' + e; }); });
  for (let i = 0; i < 60 * FPS; i++) {
    const state = await page.evaluate(() => window.__played);
    if (state === 'none') throw new Error(`${card.meta.id || 'the card'} has no Kit.play: there is no gesture to film`);
    if (state !== 'playing') { if (state !== 'done') throw new Error(state); break; }
    await frame();
  }
  // Its end coming to rest, then the answer held long enough to be read: longer after a quick gesture, so
  // that no video runs under twenty seconds.
  await hold(3.2 + 2.2);
  const least = Math.ceil((LEAST - BEAT.question - BEAT.why - BEAT.close + 3 * BEAT.fade) * FPS);
  while (n < least) await frame();
  await page.close();
  if (errors.length) console.log(`  the page said: ${errors.join(' | ')}`);
  return {frames: n, playAt};
}

function ffmpeg(list) { execFileSync('ffmpeg', ['-hide_banner', '-loglevel', 'error', '-y', ...list], {stdio: 'inherit'}); }

async function main() {
  const a = args(process.argv.slice(2));
  const card = find(a.id);
  const cardLang = card.meta.language || 'en';
  const lang = cardLang === a.lang ? a.lang : (WORDS[cardLang] ? cardLang : 'en');
  if (lang !== a.lang) console.log(`${a.id} is written in ${cardLang === 'en' ? 'English' : cardLang}: the video is in ${lang === 'en' ? 'English' : lang}.`);
  const topic = card.meta.topic || (card.source.match(/data-topic="([a-z_]+)"/) || [])[1] || 'thinking';
  const app = appWords(lang);
  const v = {words: WORDS[lang], app, topic, cardLang: lang, subject: subjectIn(app, topic), colour: colourOf(topic),
    question: card.meta.question || '', why: card.meta.move || '', source: shortSource(card.meta.source)};
  if (!v.question || !v.why) throw new Error(`${a.id} has no question or no line to keep in its file`);
  const out = path.resolve(a.out || path.join(os.tmpdir(), 'astute-videos'));
  fs.mkdirSync(out, {recursive: true});
  const work = fs.mkdtempSync(path.join(os.tmpdir(), `card-video-${a.id}-`));
  const browser = await pw.chromium.launch({executablePath});
  try {
    const s = await stills(browser, work, v);
    const frames = path.join(work, 'frames');
    fs.mkdirSync(frames);
    const r = await film(browser, frames, card, v);
    const cardLen = r.frames / FPS;
    const f = BEAT.fade, shown = {w: SHOWN, h: Math.round(SHOWN * CARD.h / CARD.w / 2) * 2};
    const mp4 = path.join(out, `${a.id}-${lang}.mp4`);
    const o1 = BEAT.question - f, o2 = o1 + cardLen - f, o3 = o2 + BEAT.why - f;
    ffmpeg([
      '-loop', '1', '-t', String(BEAT.question), '-i', s.question,
      '-framerate', String(FPS), '-i', path.join(frames, 'f%05d.png'),
      '-loop', '1', '-t', String(BEAT.why), '-i', s.why,
      '-loop', '1', '-t', String(BEAT.close), '-i', s.close,
      '-filter_complex', [
        `[0:v]fps=${FPS},format=yuv420p,setsar=1[q]`,
        `[1:v]fps=${FPS},scale=${shown.w}:${shown.h}:flags=lanczos,pad=${FRAME.w}:${FRAME.h}:${(FRAME.w - shown.w) / 2}:${TOP}:color=${NIGHT},format=yuv420p,setsar=1[c]`,
        `[2:v]fps=${FPS},format=yuv420p,setsar=1[w]`,
        `[3:v]fps=${FPS},format=yuv420p,setsar=1[e]`,
        `[q][c]xfade=transition=fade:duration=${f}:offset=${o1.toFixed(3)}[qc]`,
        `[qc][w]xfade=transition=fade:duration=${f}:offset=${o2.toFixed(3)}[qcw]`,
        `[qcw][e]xfade=transition=fade:duration=${f}:offset=${o3.toFixed(3)}[v]`,
      ].join(';'),
      '-map', '[v]', '-an', '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-pix_fmt', 'yuv420p', '-r', String(FPS), '-movflags', '+faststart', mp4,
    ]);
    const total = o3 + BEAT.close;
    console.log(`${path.relative(process.cwd(), mp4)}: ${total.toFixed(1)} s, ${Math.round(fs.statSync(mp4).size / 1024)} kB`);
    if (a.frames) {
      // A still of each beat: the question, the card before its gesture and as it starts, the answer, the
      // why, the close.
      const played = o1 + r.playAt / FPS;
      const at = [BEAT.question / 2, played - 0.4, played + 0.3, o2 - 0.4, o2 + f + BEAT.why / 2, o3 + f + 1];
      at.forEach((t, i) => ffmpeg(['-ss', t.toFixed(2), '-i', mp4, '-frames:v', '1', path.join(out, `${a.id}-${lang}-${i + 1}.png`)]));
    }
  } finally {
    await browser.close();
    fs.rmSync(work, {recursive: true, force: true});
  }
}

main().catch(e => { console.error(e.message || e); process.exit(1); });
