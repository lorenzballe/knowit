// HTML=film-en.html OUT=stills node render.cjs stills 0 4.2 -> single moments
// HTML=film-en.html node render.cjs film out.mp4 -> every frame, 30 fps, straight
//   into ffmpeg (libx264, slow, tuned for animation, crf 26, yuv420p, faststart):
//   no frame is kept on the disk, and out.mp4 is replaced only once the film is whole
// HTML=film-en.html OUT=frames-en node render.cjs frames  -> every frame as a PNG
// The frame is 1080 by 2340, a modern phone's nine by nineteen and a half.
// HTML, OUT and the film are beside this file, or where an absolute path says.
// WORKERS=2 sets frames in two pages instead of four, on a machine short of memory.
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const path = require('path'), fs = require('fs');
const FPS = 30, W = 1080, H = 2340, WORKERS = Math.max(1, +process.env.WORKERS || 4);
const ENCODE = ['-c:v', 'libx264', '-preset', 'slow', '-tune', 'animation', '-crf', '26',
  '-pix_fmt', 'yuv420p', '-movflags', '+faststart'];
const PAGE = 'file://' + path.resolve(__dirname, process.env.HTML || 'film-en.html');
async function open(browser) {
  const p = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
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
    const dir = path.resolve(__dirname, process.env.OUT || 'stills'); fs.mkdirSync(dir, { recursive: true });
    const p = await open(browser);
    for (const a of args) {
      const t = parseFloat(a);
      await p.evaluate(t => window.renderAt(t), t);
      await p.screenshot({ path: path.join(dir, 't' + t.toFixed(2).padStart(5, '0') + '.png') });
    }
  } else if (mode === 'film') {
    const out = path.resolve(__dirname, args[0] || 'film.mp4');
    const part = out.replace(/\.mp4$/, '') + '.part.mp4';
    const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS),
      '-i', '-', ...ENCODE, part], { stdio: ['pipe', 'inherit', 'inherit'] });
    const done = new Promise((res, rej) => ff.on('exit', c => c === 0 ? res() : rej(new Error('ffmpeg ' + c))));
    const pages = []; for (let i = 0; i < WORKERS; i++) pages.push(await open(browser));
    const dur = await pages[0].evaluate(() => window.DURATION);
    const N = Math.round(dur * FPS), AHEAD = 24, t0 = Date.now();
    // each page sets every WORKERS-th frame, never far ahead of what ffmpeg has had
    const shot = Array.from({ length: N }, () => { let give; const p = new Promise(r => { give = r; }); return { p, give }; });
    let written = 0;
    // a page the machine takes back for memory is opened again and its frame set again
    async function frame(w, t) {
      for (let tries = 0; ; tries++) {
        try {
          await pages[w].evaluate(t => window.renderAt(t), t);
          return await pages[w].screenshot({ type: 'png' });
        } catch (e) {
          if (tries >= 3) throw e;
          console.error('page', w, 'lost at', t.toFixed(2), 's: opened again');
          await pages[w].close().catch(() => {});
          pages[w] = await open(browser);
        }
      }
    }
    const work = pages.map(async (_, w) => {
      for (let i = w; i < N; i += WORKERS) {
        while (i - written > AHEAD) await new Promise(r => setTimeout(r, 4));
        shot[i].give(await frame(w, i / FPS));
      }
    });
    for (let i = 0; i < N; i++) {
      const buf = await shot[i].p; shot[i] = null;
      if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
      written = i + 1;
    }
    await Promise.all(work);
    ff.stdin.end(); await done;
    fs.renameSync(part, out);
    console.log(N, 'frames into', path.basename(out), 'in', ((Date.now() - t0) / 1000).toFixed(0), 's');
  } else {
    const dir = path.resolve(__dirname, process.env.OUT || 'frames'); fs.rmSync(dir, { recursive: true, force: true }); fs.mkdirSync(dir, { recursive: true });
    const p0 = await open(browser);
    const dur = await p0.evaluate(() => window.DURATION);
    const N = Math.round(dur * FPS), chunk = Math.ceil(N / WORKERS);
    const pages = [p0]; for (let i = 1; i < WORKERS; i++) pages.push(await open(browser));
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
