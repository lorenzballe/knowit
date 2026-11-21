// HTML=film-en.html OUT=frames-en node render.cjs frames  -> every frame, 30 fps
// HTML=film-en.html OUT=stills node render.cjs stills 0 4.2 -> single moments
// then: ffmpeg -framerate 30 -i frames-en/f%04d.png -c:v libx264 -preset slow
//   -tune animation -crf 26 -pix_fmt yuv420p -movflags +faststart film.mp4
const { chromium } = require('playwright');
const path = require('path'), fs = require('fs');
const FPS = 30, PAGE = 'file://' + path.join(__dirname, process.env.HTML || 'eratostene.html');
async function open(browser) {
  const p = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  p.on('pageerror', e => console.error('pageerror', e.message));
  p.on('console', m => { if (m.type() === 'error') console.error('console', m.text()); });
  await p.addInitScript(() => { window.__noAutoplay = true; });
  await p.goto(PAGE);
  await p.waitForFunction(() => window.__ready === true, null, { timeout: 30000 });
  return p;
}
(async () => {
  const [mode, ...args] = process.argv.slice(2);
  const browser = await chromium.launch();
  if (mode === 'stills') {
    const dir = path.join(__dirname, process.env.OUT || 'stills'); fs.mkdirSync(dir, { recursive: true });
    const p = await open(browser);
    for (const a of args) {
      const t = parseFloat(a);
      await p.evaluate(t => window.renderAt(t), t);
      await p.screenshot({ path: path.join(dir, 't' + t.toFixed(2).padStart(5, '0') + '.png') });
    }
  } else {
    const dir = path.join(__dirname, process.env.OUT || 'frames'); fs.rmSync(dir, { recursive: true, force: true }); fs.mkdirSync(dir, { recursive: true });
    const p0 = await open(browser);
    const dur = await p0.evaluate(() => window.DURATION);
    const N = Math.round(dur * FPS), W = 4, chunk = Math.ceil(N / W);
    const pages = [p0]; for (let i = 1; i < W; i++) pages.push(await open(browser));
    const t0 = Date.now();
    await Promise.all(pages.map(async (p, w) => {
      for (let i = w * chunk; i < Math.min(N, (w + 1) * chunk); i++) {
        await p.evaluate(t => window.renderAt(t), i / FPS);
        await p.screenshot({ path: path.join(dir, 'f' + String(i).padStart(4, '0') + '.png') });
      }
    }));
    console.log(N, 'frames in', ((Date.now() - t0) / 1000).toFixed(0), 's');
  }
  await browser.close();
})();
