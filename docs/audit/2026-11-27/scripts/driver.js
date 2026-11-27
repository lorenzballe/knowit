// A browser that stays open and takes orders, for walking through the site
// and the web app as a new user would. One process, many profiles.
//
//   SHOTS=/path/to/shots PROFILES=/path/to/profiles node driver.js &
//   ./d "open a device=pixel locale=en-US url=https://astutetheapp.com/app/; wait 8000; shot a01"
//
// Events to PostHog are answered here and never sent: the audit leaves the
// project's numbers alone. What would have been sent is written to
// events-<profile>.jsonl, which is how the tracking plan is checked.
const { chromium, devices } = require('playwright');
const http = require('http');
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const SHOTS = process.env.SHOTS || path.join(process.cwd(), 'shots');
const PROFILES = process.env.PROFILES || path.join(process.cwd(), 'profiles');
const PORT = Number(process.env.PORT || 7717);
fs.mkdirSync(SHOTS, { recursive: true });
fs.mkdirSync(PROFILES, { recursive: true });

const DEVICES = {
  pixel: devices['Pixel 7'],
  iphone: devices['iPhone 15'],
  small: { ...devices['iPhone SE'] },
  tablet: devices['iPad (gen 7)'],
  desktop: { viewport: { width: 1440, height: 900 }, deviceScaleFactor: 2, isMobile: false, hasTouch: false },
  laptop: { viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1, isMobile: false, hasTouch: false },
};

const sessions = {}; // name -> { context, page, cdp, opts, log }
let cur = null;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function dateShim(offsetMs) {
  // Moves "now" without touching timers or frames.
  return `(() => {
    const R = window.__RealDate || Date; window.__RealDate = R; const OFF = ${offsetMs};
    function D(...a) {
      if (!new.target) return new R(R.now() + OFF).toString();
      if (a.length === 0) return new R(R.now() + OFF);
      return new R(...a);
    }
    D.prototype = R.prototype; D.now = () => R.now() + OFF; D.parse = R.parse; D.UTC = R.UTC;
    window.Date = D;
  })();`;
}

function decodePosthog(req) {
  // Returns the list of events in a capture request, as far as it can be read.
  try {
    const buf = req.postDataBuffer();
    if (!buf) return [];
    let text = null;
    try { text = zlib.gunzipSync(buf).toString('utf8'); } catch (e) { text = buf.toString('utf8'); }
    if (text.startsWith('data=')) {
      const raw = decodeURIComponent(text.slice(5).split('&')[0]);
      try { text = Buffer.from(raw, 'base64').toString('utf8'); } catch (e) { text = raw; }
    }
    const json = JSON.parse(text);
    const list = Array.isArray(json) ? json : json.batch ? json.batch : [json];
    return list.map((e) => ({ event: e.event, properties: e.properties || {}, set: e.$set || (e.properties || {}).$set }));
  } catch (e) {
    return [{ event: '(unreadable)', properties: {} }];
  }
}

async function attach(name, context, opts) {
  const s = { name, context, opts, log: { console: [], failed: [], events: [], popups: [], dialogs: [], hosts: new Set() } };
  const eventsFile = path.join(SHOTS, `events-${name}.jsonl`);
  if (opts.blockPosthog !== false) {
    await context.route(/posthog\.com/, async (route) => {
      const req = route.request();
      const u = new URL(req.url());
      const isCapture = req.method() === 'POST' && /^\/(e|i\/v0\/e|batch|s|capture|engage|track)\/?$/.test(u.pathname);
      if (isCapture) {
        const evs = u.pathname.startsWith('/s') ? [{ event: '(replay chunk)', properties: {} }] : decodePosthog(req);
        for (const e of evs) {
          s.log.events.push(e.event);
          fs.appendFileSync(eventsFile, JSON.stringify({ t: new Date().toISOString(), ...e }) + '\n');
        }
        return route.fulfill({ status: 200, contentType: 'application/json', body: '{"status":1}' });
      }
      return route.continue();
    });
  }
  const wire = (page) => {
    page.on('console', (m) => { if (m.type() === 'error' || m.type() === 'warning') s.log.console.push(`[${m.type()}] ${m.text().slice(0, 300)}`); });
    page.on('pageerror', (e) => s.log.console.push(`[pageerror] ${String(e).slice(0, 300)}`));
    page.on('requestfailed', (r) => s.log.failed.push(`${r.method()} ${r.url().slice(0, 160)} :: ${(r.failure() || {}).errorText}`));
    page.on('response', (r) => { if (r.status() >= 400) s.log.failed.push(`${r.status()} ${r.url().slice(0, 160)}`); });
    page.on('request', (r) => { try { s.log.hosts.add(new URL(r.url()).host); } catch (e) {} });
    page.on('dialog', async (d) => { s.log.dialogs.push(`${d.type()}: ${d.message().slice(0, 200)}`); try { await d.dismiss(); } catch (e) {} });
  };
  context.on('page', async (p) => {
    if (s.page && p !== s.page) {
      try { await p.waitForLoadState('domcontentloaded', { timeout: 8000 }); } catch (e) {}
      s.log.popups.push(p.url());
      if (!opts.keepPopups) { try { await p.close(); } catch (e) {} }
    }
  });
  s.page = context.pages()[0] || (await context.newPage());
  wire(s.page);
  s.cdp = await context.newCDPSession(s.page);
  sessions[name] = s;
  cur = s;
  return s;
}

async function open(name, o) {
  if (sessions[name]) { await sessions[name].context.close(); delete sessions[name]; }
  const dev = DEVICES[o.device || 'pixel'];
  const options = {
    ...dev,
    locale: o.locale || 'en-US',
    timezoneId: o.tz || 'Europe/Rome',
    colorScheme: o.scheme || 'light',
    headless: true,
  };
  if (o.w && o.h) options.viewport = { width: Number(o.w), height: Number(o.h) };
  if (o.reduced) options.reducedMotion = 'reduce';
  const dir = path.join(PROFILES, name);
  if (o.fresh) fs.rmSync(dir, { recursive: true, force: true });
  const context = await chromium.launchPersistentContext(dir, options);
  if (o.days) await context.addInitScript(dateShim(Number(o.days) * 86400000));
  const s = await attach(name, context, { ...o, hasTouch: !!dev.hasTouch });
  if (o.offline) await context.setOffline(true);
  if (o.url) await s.page.goto(o.url, { waitUntil: 'load', timeout: 60000 }).catch((e) => s.log.console.push('[goto] ' + e.message.slice(0, 200)));
  return `opened ${name} (${o.device || 'pixel'}, ${options.locale}, ${options.timezoneId}${o.days ? ', days ' + o.days : ''})`;
}

async function touch(s, type, pts) { await s.cdp.send('Input.dispatchTouchEvent', { type, touchPoints: pts }); }

async function swipe(s, x1, y1, x2, y2, ms = 260, hold = 0) {
  const steps = Math.max(6, Math.round(ms / 16));
  if (s.opts.hasTouch) {
    await touch(s, 'touchStart', [{ x: x1, y: y1 }]);
    for (let i = 1; i <= steps; i++) {
      await touch(s, 'touchMove', [{ x: x1 + ((x2 - x1) * i) / steps, y: y1 + ((y2 - y1) * i) / steps }]);
      await sleep(ms / steps);
    }
    if (hold) await sleep(hold);
    await touch(s, 'touchEnd', []);
  } else {
    await s.page.mouse.move(x1, y1); await s.page.mouse.down();
    for (let i = 1; i <= steps; i++) { await s.page.mouse.move(x1 + ((x2 - x1) * i) / steps, y1 + ((y2 - y1) * i) / steps); await sleep(ms / steps); }
    if (hold) await sleep(hold);
    await s.page.mouse.up();
  }
}

const SEM_DUMP = `(() => {
  const out = [];
  const W = innerWidth, H = innerHeight;
  for (const el of document.querySelectorAll('flt-semantics, [flt-semantics-identifier]')) {
    const r = el.getBoundingClientRect();
    if (r.width < 1 || r.height < 1) continue;
    if (r.bottom < 0 || r.top > H || r.right < 0 || r.left > W) continue;
    const role = el.getAttribute('role') || '';
    let label = el.getAttribute('aria-label') || '';
    if (!label) {
      const own = [...el.childNodes].filter((n) => n.nodeType === 3 || (n.nodeType === 1 && n.tagName === 'SPAN')).map((n) => n.textContent).join(' ').trim();
      label = own;
    }
    const tappable = el.hasAttribute('flt-tappable');
    const checked = el.getAttribute('aria-checked'); const sel = el.getAttribute('aria-selected');
    const dis = el.getAttribute('aria-disabled');
    if (!label && !tappable && !role) continue;
    if (!label && !tappable && (role === 'group' || role === 'presentation' || role === 'generic')) continue;
    out.push({ x: Math.round(r.left), y: Math.round(r.top), w: Math.round(r.width), h: Math.round(r.height), role, tappable, label: label.replace(/\\s+/g, ' ').slice(0, 400), checked, sel, dis });
  }
  out.sort((a, b) => a.y - b.y || a.x - b.x);
  return out;
})()`;

async function enableSemantics(s) {
  const has = await s.page.evaluate(() => document.querySelectorAll('flt-semantics').length);
  if (has > 0) return 'already on';
  // Desktop: focus. Mobile: a click exactly at the placeholder's centre, twice, a moment apart.
  const how = await s.page.evaluate(async () => {
    const find = () => document.querySelector('flt-semantics-placeholder') || (document.querySelector('flutter-view') || document.body).querySelector('flt-semantics-placeholder');
    let p = find();
    if (!p) { for (const h of document.querySelectorAll('*')) { if (h.shadowRoot) { const q = h.shadowRoot.querySelector('flt-semantics-placeholder'); if (q) { p = q; break; } } } }
    if (!p) return 'no placeholder';
    try { p.focus(); } catch (e) {}
    const r = p.getBoundingClientRect();
    const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
    const fire = () => p.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, clientX: cx, clientY: cy }));
    fire();
    await new Promise((res) => setTimeout(res, 400));
    fire();
    await new Promise((res) => setTimeout(res, 600));
    return 'placeholder ' + Math.round(r.width) + 'x' + Math.round(r.height);
  });
  await sleep(500);
  const n = await s.page.evaluate(() => document.querySelectorAll('flt-semantics').length);
  return `${how} -> ${n} nodes`;
}

function kv(args) {
  const o = {}; const pos = [];
  for (const a of args) { const i = a.indexOf('='); if (i > 0 && /^[a-zA-Z]+$/.test(a.slice(0, i))) o[a.slice(0, i)] = a.slice(i + 1); else pos.push(a); }
  return { o, pos };
}

async function run(line) {
  const parts = line.trim().split(/\s+/);
  const cmd = parts.shift();
  const { o, pos } = kv(parts);
  const s = cur;
  const need = () => { if (!s) throw new Error('no profile open'); return s; };
  switch (cmd) {
    case 'open': return open(pos[0], o);
    case 'use': cur = sessions[pos[0]]; if (!cur) throw new Error('no such profile'); return `using ${pos[0]}`;
    case 'close': { const n = pos[0] || (s && s.name); await sessions[n].context.close(); delete sessions[n]; if (cur && cur.name === n) cur = null; return `closed ${n}`; }
    case 'list': return Object.keys(sessions).map((n) => `${n}${cur && cur.name === n ? '*' : ''} ${sessions[n].page.url()}`).join('\n') || '(none)';
    case 'goto': await need().page.goto(pos[0], { waitUntil: o.until || 'load', timeout: 60000 }); return `at ${s.page.url()}`;
    case 'reload': await need().page.reload({ waitUntil: 'load', timeout: 60000 }); return 'reloaded';
    case 'back': await need().page.goBack({ timeout: 15000 }).catch(() => {}); return `back -> ${s.page.url()}`;
    case 'url': return need().page.url();
    case 'wait': await sleep(Number(pos[0] || 500)); return '';
    case 'tap': {
      const x = Number(pos[0]), y = Number(pos[1]);
      if (need().opts.hasTouch) await s.page.touchscreen.tap(x, y); else await s.page.mouse.click(x, y);
      return '';
    }
    case 'click': await need().page.mouse.click(Number(pos[0]), Number(pos[1])); return '';
    case 'hover': await need().page.mouse.move(Number(pos[0]), Number(pos[1])); return '';
    case 'press': { // long press
      const x = Number(pos[0]), y = Number(pos[1]), ms = Number(pos[2] || 800);
      if (need().opts.hasTouch) { await touch(s, 'touchStart', [{ x, y }]); await sleep(ms); await touch(s, 'touchEnd', []); }
      else { await s.page.mouse.move(x, y); await s.page.mouse.down(); await sleep(ms); await s.page.mouse.up(); }
      return '';
    }
    case 'swipe': await swipe(need(), Number(pos[0]), Number(pos[1]), Number(pos[2]), Number(pos[3]), Number(o.ms || 260), Number(o.hold || 0)); return '';
    case 'wheel': await need().page.mouse.move(Number(pos[0]), Number(pos[1])); await s.page.mouse.wheel(Number(pos[2] || 0), Number(pos[3] || 0)); return '';
    case 'type': await need().page.keyboard.type(line.trim().slice(5), { delay: 30 }); return '';
    case 'key': await need().page.keyboard.press(pos[0]); return '';
    case 'shot': {
      const name = pos[0];
      const full = pos.includes('full');
      const big = path.join(SHOTS, `${name}.png`), small = path.join(SHOTS, `${name}.s.png`);
      await need().page.screenshot({ path: small, scale: 'css', fullPage: full, animations: o.still ? 'disabled' : 'allow' });
      if (!o.smallonly) await s.page.screenshot({ path: big, scale: 'device', fullPage: full });
      return small;
    }
    case 'sem': {
      const on = await enableSemantics(need());
      const nodes = await s.page.evaluate(SEM_DUMP);
      const lines = nodes.map((n) => `${String(n.x).padStart(4)},${String(n.y).padStart(4)} ${String(n.w).padStart(3)}x${String(n.h).padEnd(3)} ${n.tappable ? 'T' : ' '} ${(n.role || '-').padEnd(8)} ${n.checked != null ? '[checked=' + n.checked + '] ' : ''}${n.sel != null ? '[sel=' + n.sel + '] ' : ''}${n.dis ? '[disabled] ' : ''}${n.label}`);
      return (on === 'already on' ? '' : `(semantics: ${on})\n`) + lines.join('\n');
    }
    case 'text': { // plain DOM text, for the site's pages
      const t = await need().page.evaluate(() => document.body.innerText);
      return t.slice(0, Number(o.max || 6000));
    }
    case 'eval': { const r = await need().page.evaluate(line.trim().slice(5)); return typeof r === 'string' ? r : JSON.stringify(r, null, 1); }
    case 'scrollall': { // walks down the page so that what appears on scroll has appeared
      const step = Number(o.step || 500), pause = Number(o.pause || 180);
      return String(await need().page.evaluate(async ([step, pause]) => {
        for (let y = 0; y < document.documentElement.scrollHeight; y += step) { window.scrollTo(0, y); await new Promise((r) => setTimeout(r, pause)); }
        window.scrollTo(0, 0); await new Promise((r) => setTimeout(r, 400));
        return document.documentElement.scrollHeight;
      }, [step, pause]));
    }
    case 'scroll': await need().page.evaluate((y) => window.scrollTo(0, y), Number(pos[0])); return '';
    case 'offline': await need().context.setOffline(pos[0] !== 'off'); return `offline ${pos[0] !== 'off'}`;
    case 'days': await need().context.addInitScript(dateShim(Number(pos[0]) * 86400000)); return `date offset ${pos[0]} days from next load`;
    case 'log': {
      const L = need().log;
      const out = [];
      if (L.console.length) out.push('console:\n  ' + [...new Set(L.console)].slice(0, 25).join('\n  '));
      if (L.failed.length) out.push('failed:\n  ' + [...new Set(L.failed)].slice(0, 25).join('\n  '));
      if (L.events.length) out.push('events: ' + L.events.join(', '));
      if (L.popups.length) out.push('popups: ' + L.popups.join(', '));
      if (L.dialogs.length) out.push('dialogs: ' + L.dialogs.join(' | '));
      if (o.hosts) out.push('hosts: ' + [...L.hosts].join(', '));
      L.console = []; L.failed = []; L.events = []; L.popups = []; L.dialogs = [];
      return out.join('\n') || '(nothing logged)';
    }
    case 'storage': {
      return JSON.stringify(await need().page.evaluate(async () => {
        const ls = {}; for (let i = 0; i < localStorage.length; i++) { const k = localStorage.key(i); ls[k] = String(localStorage.getItem(k)).slice(0, 300); }
        let dbs = []; try { dbs = (await indexedDB.databases()).map((d) => d.name); } catch (e) {}
        return { localStorage: ls, indexedDB: dbs, cookies: document.cookie.slice(0, 300) };
      }), null, 1);
    }
    default: throw new Error(`unknown command: ${cmd}`);
  }
}

const server = http.createServer((req, res) => {
  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', async () => {
    const out = [];
    for (const line of body.split('\n').map((l) => l.trim()).filter(Boolean)) {
      try { const r = await run(line); if (r) out.push(r); }
      catch (e) { out.push(`ERROR in "${line.slice(0, 60)}": ${e.message.split('\n')[0]}`); break; }
    }
    res.end(out.join('\n') + '\n');
  });
});
server.listen(PORT, '127.0.0.1', () => console.log(`driver on ${PORT}, shots in ${SHOTS}`));
process.on('SIGTERM', async () => { for (const n of Object.keys(sessions)) { try { await sessions[n].context.close(); } catch (e) {} } process.exit(0); });
