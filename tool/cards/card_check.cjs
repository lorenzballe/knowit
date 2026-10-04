// Photographs every card in a prototype page on three phones and reports what
// the eye would catch: something spilling out of the card, the card's column
// overflowing, labels in a drawing overlapping, a big empty band.
//
//   node tool/cards/card_check.cjs docs/cards/prototipi/giro-3.html [out-dir]
//
// The page must use the kit (docs/cards/kit): .card > .in, #next to advance.
// Each card is checked as it first appears and, if the page registers
// Kit.play[cardId] (see docs/cards/kit/astute-card.js), again after it is played through.
const path = require('path'), fs = require('fs');
let pw; try { pw = require('playwright'); } catch { pw = require('/opt/node22/lib/node_modules/playwright'); }
const file = path.resolve(process.argv[2]); const out = path.resolve(process.argv[3] || path.join(path.dirname(file), 'check'));
fs.mkdirSync(out, {recursive: true});
const phones = {small: {width: 360, height: 740}, medium: {width: 390, height: 844}, large: {width: 430, height: 932}};
(async () => {
  const browser = await pw.chromium.launch({executablePath: fs.existsSync('/opt/pw-browsers/chromium') ? '/opt/pw-browsers/chromium' : undefined});
  let problems = 0;
  for (const [name, vp] of Object.entries(phones)) {
    const page = await browser.newPage({viewport: vp});
    const errors = []; page.on('pageerror', e => errors.push(e.message));
    await page.goto('file://' + file); await page.waitForTimeout(1500);
    const n = await page.locator('.card').count();
    for (let i = 0; i < n; i++) {
      await page.waitForTimeout(900);
      for (const stage of ['start', 'end']) {
      if (stage === 'end') { const played = await page.evaluate(async () => { const id = document.querySelector('.card.on')?.id; const f = typeof Kit !== 'undefined' && Kit.play && Kit.play[id]; if (!f) return false; await f(); return true; }); if (!played) break; await page.waitForTimeout(3000); }
      const r = await page.evaluate(() => {
        const card = document.querySelector('.card.on'); if (!card) return {id: '?', issues: ['no card shown']};
        const cb = card.getBoundingClientRect(), inn = card.querySelector('.in'), issues = [];
        if (inn && inn.scrollHeight > inn.clientHeight + 2) issues.push(`column overflows by ${inn.scrollHeight - inn.clientHeight}px`);
        for (const el of card.querySelectorAll('.in *')) {
          const s = getComputedStyle(el); if (s.display === 'none' || s.visibility === 'hidden' || el.closest('.gone')) continue;
          const b = el.getBoundingClientRect(); if (!b.width || !b.height) continue;
          if (b.right > cb.right + 1 || b.left < cb.left - 1 || b.bottom > cb.bottom + 1) { issues.push(`spills out: <${el.tagName.toLowerCase()}${el.id ? '#' + el.id : ''}> "${(el.textContent || '').trim().slice(0, 30)}"`); break; }
        }
        const texts = [...card.querySelectorAll('svg text')].map(t => ({t: t.textContent, b: t.getBoundingClientRect()})).filter(x => x.b.width);
        for (let a = 0; a < texts.length; a++) for (let c = a + 1; c < texts.length; c++) { const A = texts[a].b, B = texts[c].b; if (A.left < B.right && B.left < A.right && A.top < B.bottom && B.top < A.bottom) { issues.push(`labels overlap: "${texts[a].t}" / "${texts[c].t}"`); a = texts.length; break; } }
        const kids = inn ? [...inn.children].filter(k => !k.classList.contains('gone') && getComputedStyle(k).display !== 'none') : [];
        for (let k = 1; k < kids.length; k++) { const gap = kids[k].getBoundingClientRect().top - kids[k - 1].getBoundingClientRect().bottom; if (gap > cb.height * .22 && !kids[k - 1].classList.contains('stagebox')) issues.push(`empty band of ${Math.round(gap)}px`); }
        return {id: card.id, issues};
      });
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
})();
