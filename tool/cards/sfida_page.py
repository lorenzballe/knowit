"""Today's challenge, on the site: a page where a friend plays the five
questions a reader played, and sees the two scores side by side.

The five at the top of Explore in the app — Today's challenge, La sfida di
oggi — are the same for every reader that day, and the deploy publishes them
for every day from the day before it to four hundred after
(tool/todays_five.dart: five/days.json, and for each card
five/cards/<id>.json). A reader who has played them can send a friend
"Challenge a friend" (lib/explore/blocks/bets/five_challenge.dart): a line in
the reader's language and a link to this page,

    https://astutetheapp.com/sfida?d=2026-11-27&s=4

the day the five were dealt, on the reader's calendar, and how many of them
the reader got right. Nothing else: no name, no id. The friend, with or
without the app (the app does not claim the address: site/.well-known/ names
/c/* alone), meets:

- the line "A friend got 4 of today's 5. Your turn.";
- the five, one at a time, each in its subject's colour as the landing page
  draws a card, a pick tapped and locked in or a share set on a track of
  whole points, as in the app;
- the result: "You 3 · Your friend 4", and each question with the friend's
  answer, the right one and its why — every answer judged as the app judges
  it, from the card's own file (the page holds no rule of its own: a pick is
  right on the option the file names, a share between the two guesses it
  gives, which are the card's own test read guess by guess);
- "Five new ones tomorrow", and the way to the app, as the stores stand
  (tool/site/chrome.py: until the App Store listing is live, Google Play is
  the button and the App Store is marked as coming, leading to the list for
  the iPhone).

A link without a score is the five alone, and the friend's score at the end.
A day the site has no five for falls back to the friend's own today, and says
so. One page for every day, so a link is never a page that is not there.

In each of the site's languages (WORDS: English at /sfida, Italian at
/it/sfida, where a browser in Italian is sent): the page's words and the
script's, the line the friend passes on as the app's own. The cards' words
are the cards', in English, and marked so. The site's own chrome, stylesheet
and script (the nav, the footer, what the site measures: the page read and
the store buttons pressed, nothing more); the page's own style and script
inline, so it is one request and quick.

Written when the site is put together (.github/workflows/deploy.yml), into
<site>/sfida.html and <site>/it/sfida.html, which the site serves at /sfida
and /it/sfida.

    python3 tool/cards/sfida_page.py _site
"""
from __future__ import annotations

import html
import json
import sys
from pathlib import Path


# The site's chrome and the stores as they stand: one switch there
# (APP_STORE_OPEN) reaches this page too.
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "site"))
import chrome  # noqa: E402
from chrome import APP_STORE_OPEN, GOOGLE_PLAY_OPEN, where  # noqa: E402

SITE = "https://astutetheapp.com"
PATH = "sfida"

# The page's own style, on the site's (site/assets/site.css: the night, the
# cream, Fraunces and Figtree). A card is drawn as the landing page draws one
# (site/assets/landing.css: .paper, .label, .mark), its colours given as the
# app gives them: the subject's, and its ink as three numbers, so the ink can
# be laid at any strength.
CSS = """.duel-page{position:relative;overflow:hidden}
.duel-glow{position:absolute;left:0;right:0;top:0;height:760px;pointer-events:none;
  background:radial-gradient(56% 72% at 50% 0%,color-mix(in srgb,var(--glow,#F2F1EC) 22%,transparent),transparent 70%)}
.duel{position:relative;max-width:620px;margin:0 auto;padding:calc(var(--nav-h) + 40px) var(--gutter) 72px}
.duel-sr{position:absolute;width:1px;height:1px;margin:-1px;padding:0;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap;border:0}
.duel-when{display:flex;flex-wrap:wrap;align-items:center;gap:6px 10px;margin:0 0 16px;font:700 11px/1.4 var(--font-text);letter-spacing:.14em;text-transform:uppercase;color:var(--cream-60)}
.duel-title{margin:0;font:500 clamp(34px,9vw,58px)/1.03 var(--font-display);letter-spacing:-.028em;font-variation-settings:'opsz' 144;text-wrap:balance}
.duel-title span{display:block;color:var(--cream-50)}
.duel-lede{margin:14px 0 0;max-width:520px;font:400 16px/1.55 var(--font-text);color:var(--cream-70);text-wrap:pretty}
.duel-note{margin:16px 0 0;padding:12px 14px;border-radius:14px;border:1px solid var(--hairline-strong);font:500 14px/1.45 var(--font-text);color:var(--cream-85)}
.duel-play{margin-top:26px}
.duel-steps{display:none;gap:6px;margin:0 0 14px;padding:0;list-style:none}
.js .duel-steps{display:flex}
.duel-steps li{flex:1 1 0;height:4px;border-radius:2px;background:rgba(242,241,236,.16);transition:background .3s ease,flex-grow .3s ease}
.duel-steps li.done{background:var(--cream-60)}
.duel-steps li.now{flex-grow:1.8;background:var(--cream)}
.duel-card{display:flex;flex-direction:column;padding:20px 20px 20px;border-radius:28px;background-color:var(--c);color:rgb(var(--ink))}
.duel-wait{display:none;min-height:440px;background:rgba(242,241,236,.04);border:1px solid var(--hairline)}
.js .duel-wait{display:block}
.paper{background-image:linear-gradient(160deg,rgba(255,255,255,.16),rgba(255,255,255,0) 48%),radial-gradient(120% 90% at 100% 100%,rgba(0,0,0,.08),transparent 60%);
  box-shadow:inset 0 1px 0 rgba(255,255,255,.28),0 30px 60px -30px rgba(0,0,0,.7)}
.label{display:flex;align-items:center;gap:8px;margin:0;font:600 11px/16px var(--font-text);letter-spacing:1.4px;text-transform:uppercase;white-space:nowrap;color:rgb(var(--ink) / .72)}
.mark{flex:none;width:16px;height:16px;color:rgb(var(--ink));fill:none;stroke:currentColor;stroke-width:1.9;stroke-linecap:round;stroke-linejoin:round;overflow:visible}
.duel-n{margin-left:auto;font-variant-numeric:tabular-nums}
.duel-q{margin:14px 0 20px;outline:none;font:600 calc(var(--fs,24px) * var(--k,1))/1.08 var(--font-display);letter-spacing:calc(-.4px - var(--fs,24px) * var(--k,1) * .028);
  font-optical-sizing:auto;font-variation-settings:'SOFT' 30,'WONK' 0;text-wrap:pretty}
@media (max-width:380px){.duel-q{--k:.88}}
.duel-opts{display:flex;flex-direction:column;gap:8px}
.duel-opt{all:unset;box-sizing:border-box;display:flex;align-items:center;gap:12px;min-height:52px;padding:13px 14px 13px 16px;border-radius:16px;cursor:pointer;
  background:rgb(var(--ink) / .1);color:rgb(var(--ink));font:600 16px/1.3 var(--font-text);-webkit-tap-highlight-color:transparent;
  transition:background .16s ease,color .16s ease,transform .12s ease}
.duel-opt span{flex:1 1 auto;min-width:0;overflow-wrap:anywhere}
.duel-opt i{position:relative;flex:none;width:22px;height:22px;border-radius:50%;box-sizing:border-box;border:2px solid rgb(var(--ink) / .4);transition:background .16s ease,border-color .16s ease}
.duel-opt i::after{content:"";position:absolute;left:6px;top:4px;width:5px;height:9px;border:solid var(--c);border-width:0 2.4px 2.4px 0;transform:rotate(45deg);opacity:0;transition:opacity .16s ease}
.duel-opt[aria-pressed="true"]{background:rgb(var(--ink));color:var(--c)}
.duel-opt[aria-pressed="true"] i{border-color:var(--c);background:rgb(var(--ink))}
.duel-opt[aria-pressed="true"] i::after{opacity:1}
@media (hover:hover){.duel-opt:hover{background:rgb(var(--ink) / .17)}.duel-opt[aria-pressed="true"]:hover{background:rgb(var(--ink))}}
.duel-opt:active{transform:scale(.985)}
.duel-opt:focus-visible{outline:2px solid rgb(var(--ink));outline-offset:2px}
.duel-share{padding:2px 0 0}
.duel-figure{margin:0 0 12px;font:600 52px/1 var(--font-display);letter-spacing:-1.6px;font-variant-numeric:tabular-nums}
.duel-range{--p:calc(13px + (100% - 26px) * var(--t,.5));-webkit-appearance:none;appearance:none;display:block;width:100%;height:32px;margin:0;background:transparent;cursor:pointer;touch-action:pan-y}
.duel-range::-webkit-slider-runnable-track{height:8px;border-radius:8px;background:linear-gradient(90deg,rgb(var(--ink)) 0 var(--p),rgb(var(--ink) / .16) var(--p) 100%)}
.duel-range::-webkit-slider-thumb{-webkit-appearance:none;width:26px;height:26px;margin-top:-9px;border-radius:50%;box-sizing:border-box;background:var(--c);border:3px solid rgb(var(--ink))}
.duel-range::-moz-range-track{height:8px;border-radius:8px;background:rgb(var(--ink) / .16)}
.duel-range::-moz-range-progress{height:8px;border-radius:8px;background:rgb(var(--ink))}
.duel-range::-moz-range-thumb{width:26px;height:26px;border-radius:50%;box-sizing:border-box;background:var(--c);border:3px solid rgb(var(--ink))}
.duel-range:focus{outline:none}
.duel-range:focus-visible::-webkit-slider-thumb{box-shadow:0 0 0 4px rgb(var(--ink) / .3)}
.duel-range:focus-visible::-moz-range-thumb{box-shadow:0 0 0 4px rgb(var(--ink) / .3)}
.duel-ends{display:flex;justify-content:space-between;margin:6px 0 0;font:600 12px/1 var(--font-text);color:rgb(var(--ink) / .6)}
.duel-lock{all:unset;box-sizing:border-box;display:flex;align-items:center;justify-content:center;margin-top:18px;min-height:52px;padding:0 22px;border-radius:26px;cursor:pointer;
  background:rgb(var(--ink));color:var(--c);font:700 15px/1 var(--font-text);-webkit-tap-highlight-color:transparent;transition:opacity .2s ease,transform .12s ease}
.duel-lock:disabled{opacity:.36;cursor:default}
.duel-lock:not(:disabled):active{transform:translateY(1px) scale(.99)}
.duel-lock:focus-visible{outline:2px solid rgb(var(--ink));outline-offset:3px}
.duel-fail{margin:0;font:500 16px/1.5 var(--font-text);color:var(--cream-85)}
.duel-fail button{all:unset;cursor:pointer;margin-left:6px;text-decoration:underline;text-underline-offset:3px}
@keyframes duel-in{from{opacity:0;transform:translateX(28px)}to{opacity:1;transform:none}}
@keyframes duel-up{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:none}}
.duel-card.enter{animation:duel-in .34s var(--ease) both}
.duel-result:not([hidden]) .duel-sheet{animation:duel-up .55s var(--ease) both}
.duel-sheet{--ink:20 20 22;padding:24px 20px 22px;border-radius:28px;background:var(--cream);color:var(--night);
  box-shadow:inset 0 1px 0 rgba(255,255,255,.6),0 40px 90px -50px rgba(0,0,0,.9)}
.duel-sheet ::selection{background:var(--night);color:var(--cream)}
.duel-kicker{margin:0 0 14px;font:700 11px/1.4 var(--font-text);letter-spacing:.14em;text-transform:uppercase;color:var(--ink-60)}
.duel-score{display:grid;grid-template-columns:1fr 1fr;margin:0;font-weight:inherit;outline:none}
.duel-score.solo{grid-template-columns:1fr}
.duel-side{display:flex;flex-direction:column;align-items:flex-start;gap:6px;min-width:0}
.duel-side+.duel-side{padding-left:18px;border-left:1px solid var(--ink-hairline)}
.duel-side small{font:700 12px/1.2 var(--font-text);letter-spacing:.08em;text-transform:uppercase;color:var(--ink-60)}
.duel-side b{font:600 clamp(76px,23vw,108px)/.86 var(--font-display);letter-spacing:-.04em;font-variation-settings:'opsz' 72,'SOFT' 50,'WONK' 0;font-variant-numeric:tabular-nums}
.duel-side b em{font:600 18px/1 var(--font-text);letter-spacing:0;font-style:normal;color:var(--ink-60)}
.duel-squares{display:flex;gap:5px;margin-top:6px}
.duel-squares i{width:14px;height:14px;border-radius:4px;box-sizing:border-box;border:1.8px solid var(--night)}
.duel-squares i.on{background:var(--night)}
.duel-verdict{margin:18px 0 24px;font:600 22px/1.25 var(--font-display);letter-spacing:-.015em;text-wrap:balance}
.duel-rows{margin:0;padding:0;list-style:none}
.duel-row{padding:16px 0 18px;border-top:1px solid var(--ink-hairline)}
.duel-row .label{color:var(--ink-60)}
.duel-mark{margin-left:auto;width:16px;height:16px;border-radius:4px;box-sizing:border-box;border:1.8px solid var(--night)}
.duel-row.is-right .duel-mark{background:var(--night)}
.duel-row-q{margin:9px 0 8px;font:700 15.5px/1.35 var(--font-text);text-wrap:pretty}
.duel-yours,.duel-right{margin:3px 0 0;font:500 14.5px/1.4 var(--font-text)}
.duel-row.is-wrong .duel-yours{color:var(--ink-60);text-decoration:line-through;text-decoration-thickness:1px}
.duel-right{font-weight:700}
.duel-why{margin:9px 0 0;font:400 14.5px/1.5 var(--font-text);color:var(--ink-70);text-wrap:pretty}
.duel-pass{all:unset;box-sizing:border-box;display:flex;align-items:center;justify-content:center;width:100%;min-height:50px;margin-top:6px;padding:0 20px;border-radius:25px;cursor:pointer;
  border:1.5px solid var(--night);color:var(--night);font:700 15px/1 var(--font-text);transition:background .2s ease,color .2s ease}
@media (hover:hover){.duel-pass:hover{background:var(--night);color:var(--cream)}}
.duel-pass:focus-visible{outline:2px solid var(--night);outline-offset:3px}
.duel-passed{min-height:1.4em;margin:10px 0 0;font:500 13px/1.4 var(--font-text);color:var(--ink-60);text-align:center;overflow-wrap:anywhere}
.duel-more{margin-top:56px;text-align:center}
.js .duel-more.later{display:none}
.duel-more h2{margin:0 0 12px;font:500 clamp(32px,7.4vw,46px)/1.04 var(--font-display);letter-spacing:-.025em;font-variation-settings:'opsz' 144;text-wrap:balance}
.duel-more p{max-width:460px;margin:0 auto 26px;font:400 16px/1.55 var(--font-text);color:var(--cream-70);text-wrap:pretty}
@media (min-width:768px){.duel{padding-top:calc(var(--nav-h) + 72px)}.duel-card{padding:24px 26px 24px}.duel-sheet{padding:32px 32px 28px}}
@media (prefers-reduced-motion:reduce){.duel-card.enter,.duel-result:not([hidden]) .duel-sheet{animation:none}.duel-steps li{transition:none}}
"""

# The page's own script: the day and the score read from the link, the five
# fetched from what the deploy publishes, played one at a time, judged, and
# the result. Nothing is kept: a reload starts again.
SCRIPT = """(() => {
  const $ = (s, root = document) => root.querySelector(s);
  const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const pad = n => String(n).padStart(2, '0');
  const keyOf = d => d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
  const dateOf = key => { const p = key.split('-').map(Number); return new Date(p[0], p[1] - 1, p[2], 12); };
  // The page's words, in its language (WORDS, below, as the page writes them).
  const W = @WORDS@;
  const say = (d, o) => new Intl.DateTimeFormat(W.locale, o).format(d);
  const esc = s => String(s).replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch]);
  const hex = h => (/^#[0-9a-f]{6}$/i.test(h) ? h : '#F2F1EC');
  const triplet = h => (/^#[0-9a-f]{6}$/i.test(h) ? [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16)).join(' ') : '16 16 12');
  const json = url => fetch(url).then(r => (r.ok ? r.json() : Promise.reject(new Error(url))));
  const percent = v => Math.round(v * 10) / 10 + '%';
  const words = W.numbers;
  const subject = topic => W.subjects[topic] || topic;

  // The link: the day the five were dealt on the sender's calendar, and how
  // many of them the sender got right. Anything else is not read.
  const query = new URLSearchParams(location.search);
  const asked = /^\\d{4}-\\d{2}-\\d{2}$/.test(query.get('d') || '') ? query.get('d') : null;
  const scored = /^[0-5]$/.test(query.get('s') || '') ? Number(query.get('s')) : null;
  const today = keyOf(new Date());

  const head = $('[data-head]'), play = $('[data-play]'), stage = $('[data-stage]');
  const fail = $('[data-fail]'), result = $('[data-result]'), more = $('[data-more]');
  const status = $('[data-status]'), glow = $('[data-glow]');
  const steps = Array.from(document.querySelectorAll('[data-steps] li'));
  let day = null, cards = [], friend = null, you = 0;
  const answers = [];

  // A card the five can play, as tool/todays_five.dart writes it: a pick of
  // two or three options with the right one, or a share with its answer.
  const playable = c => !!c && typeof c.id === 'string' && typeof c.question === 'string' && (c.kind === 'pick'
    ? Array.isArray(c.options) && c.options.length >= 2 && c.options.length <= 3
      && Number.isInteger(c.correct) && c.correct >= 0 && c.correct < c.options.length
    : c.kind === 'share' && typeof c.value === 'number');

  // Right as the app counts it (lib/explore/blocks/bets/three.dart): a pick
  // on the option the card names; a share, set in whole points, between the
  // first and last guess the card itself counts right, which its file gives
  // (read from the card's own test, guess by guess). No rule of the page's.
  const judge = (c, said) => (c.kind === 'pick'
    ? said === c.correct
    : Array.isArray(c.right) && said >= c.right[0] && said <= c.right[1]);

  // The question as large as its length allows, as the app sizes a card's.
  const sizeOf = q => (q.length <= 60 ? 30 : q.length <= 95 ? 27 : q.length <= 135 ? 24 : 21);

  // The subject's mark, drawn from the symbols the site's header carries.
  const label = (c, end) => '<p class="label"><svg class="mark" aria-hidden="true"><use href="#subject-'
    + esc(String(c.topic || '').toLowerCase().replace(/[^a-z]+/g, '-')) + '"/></svg><span>' + esc(subject(c.topic)) + '</span>' + (end || '') + '</p>';

  function show(i) {
    const c = cards[i];
    const pick = c.kind === 'pick';
    stage.innerHTML = '<article class="duel-card paper' + (i > 0 && !still ? ' enter' : '') + '" style="--c:' + hex(c.color) + ';--ink:' + triplet(c.ink) + '">'
      + label(c, '<span class="duel-n">' + (i + 1) + '/5</span>')
      + '<h2 class="duel-q" tabindex="-1" lang="en" style="--fs:' + sizeOf(c.question) + 'px">' + esc(c.question) + '</h2>'
      + (pick
        ? '<div class="duel-opts" role="group" aria-label="' + W.answers + '" lang="en">' + c.options.map((o, k) => '<button type="button" class="duel-opt" aria-pressed="false" data-i="' + k + '"><span>' + esc(o) + '</span><i aria-hidden="true"></i></button>').join('') + '</div>'
        : '<div class="duel-share"><p class="duel-figure" aria-hidden="true">50%</p><input class="duel-range" type="range" min="0" max="100" step="1" value="50" aria-label="' + W.guess + '" aria-valuetext="50%"><p class="duel-ends" aria-hidden="true"><span>0%</span><span>100%</span></p></div>')
      + '<button type="button" class="duel-lock"' + (pick ? ' disabled' : '') + '>' + (pick ? W.pickFirst : W.lock) + '</button>'
      + '</article>';
    steps.forEach((li, k) => { li.className = k < i ? 'done' : k === i ? 'now' : ''; });
    if (glow) glow.style.setProperty('--glow', hex(c.color));
    const card = stage.firstElementChild;
    const lock = $('.duel-lock', card);
    let said = null;
    if (pick) {
      const options = Array.from(card.querySelectorAll('.duel-opt'));
      options.forEach(b => b.addEventListener('click', () => {
        said = Number(b.dataset.i);
        options.forEach(o => o.setAttribute('aria-pressed', String(o === b)));
        lock.disabled = false;
        lock.textContent = W.lock;
      }));
    } else {
      const range = $('.duel-range', card), figure = $('.duel-figure', card);
      const set = () => {
        said = Number(range.value);
        figure.textContent = said + '%';
        range.setAttribute('aria-valuetext', said + '%');
        range.style.setProperty('--t', said / 100);
      };
      range.addEventListener('input', set);
      set();
    }
    lock.addEventListener('click', () => {
      if (said === null) return;
      answers[i] = said;
      if (i + 1 >= cards.length) return finish();
      show(i + 1);
      // On a phone scrolled down to the button, the next card from its top.
      const top = play.getBoundingClientRect().top;
      if (top < 64) window.scrollBy({ top: top - 76, behavior: still ? 'auto' : 'smooth' });
      $('.duel-q', stage).focus({ preventScroll: true });
      status.textContent = W.question.replace('{n}', i + 2);
    });
  }

  function finish() {
    const marks = cards.map((c, i) => judge(c, answers[i]));
    you = marks.filter(Boolean).length;
    const squares = '<span class="duel-squares" aria-hidden="true">' + marks.map(m => '<i' + (m ? ' class="on"' : '') + '></i>').join('') + '</span>';
    const score = $('[data-score]');
    if (friend !== null) {
      score.innerHTML = '<span class="duel-side"><small>' + W.you + '</small><b>' + you + '</b>' + squares + '</span>'
        + '<span class="duel-side"><small>' + W.friend + '</small><b>' + friend + '</b></span>';
      score.setAttribute('aria-label', W.you + ' ' + you + ' \\u00b7 ' + W.friend + ' ' + friend);
    } else {
      score.classList.add('solo');
      score.innerHTML = '<span class="duel-side"><small>' + W.you + '</small><b>' + you + '<em> ' + W.of5 + '</em></b>' + squares + '</span>';
      score.setAttribute('aria-label', W.youGot.replace('{n}', you));
    }
    const missed = 5 - you;
    $('[data-verdict]').textContent = friend !== null
      ? (you > friend ? W.youWin.replace('{n}', words[you - friend]) : you < friend ? W.friendWins.replace('{n}', words[friend - you]) : W.draw)
      : you === 5 ? W.allRight : you === 0 ? W.noneRight
        : W.someRight.replace('{right}', words[you][0].toUpperCase() + words[you].slice(1)).replace('{missed}', words[missed]);
    $('[data-rows]').innerHTML = cards.map((c, i) => {
      const pick = c.kind === 'pick';
      const yours = pick ? c.options[answers[i]] : percent(answers[i]);
      const right = pick ? c.options[c.correct] : percent(c.value);
      return '<li class="duel-row ' + (marks[i] ? 'is-right' : 'is-wrong') + '">'
        + label(c, '<span class="duel-mark" role="img" aria-label="' + (marks[i] ? W.right : W.notRight) + '"></span>')
        + '<p class="duel-row-q" lang="en">' + esc(c.question) + '</p>'
        + (pick && marks[i] ? '' : '<p class="duel-yours">' + W.yours + ' <span lang="en">' + esc(yours) + '</span></p>')
        + '<p class="duel-right">' + W.rightIs + ' <span lang="en">' + esc(right) + '</span></p>'
        + (c.why ? '<p class="duel-why" lang="en">' + esc(c.why) + '</p>' : '')
        + '</li>';
    }).join('');
    $('[data-pass]').textContent = friend !== null ? W.passOn : W.challenge;
    head.hidden = true;
    play.hidden = true;
    result.hidden = false;
    more.classList.remove('later');
    if (glow) glow.style.setProperty('--glow', '#F2F1EC');
    window.scrollTo({ top: 0, behavior: 'auto' });
    score.focus({ preventScroll: true });
    status.textContent = score.getAttribute('aria-label') + '.';
  }

  // Sent on by the friend, as the app sends it: the score, and this page
  // for the same day. Through the phone's own sheet where there is one.
  $('[data-pass]').addEventListener('click', () => {
    const whose = day === today ? W.today : W.ofDay.replace('{day}', say(dateOf(day), { weekday: 'long' }));
    const text = (you === 5 ? W.shareAll : W.share).replace('{n}', you).replace('{whose}', whose);
    const url = 'https://astutetheapp.com/sfida?d=' + day + '&s=' + you;
    const passed = $('[data-passed]');
    if (navigator.share) {
      navigator.share({ text: text, url: url }).catch(() => {});
    } else if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text + '\\n' + url).then(() => { passed.textContent = W.copied; }, () => { passed.textContent = url; });
    } else {
      passed.textContent = url;
    }
  });

  function begin(d, got, fellBack) {
    day = d;
    cards = got;
    friend = fellBack ? null : scored;
    const date = dateOf(day);
    const isToday = day === today;
    const weekday = say(date, { weekday: 'long' });
    const when = (isToday ? W.todays : W.theChallenge) + ' \\u00b7 ' + say(date, { weekday: 'long', day: 'numeric', month: 'long' });
    document.querySelectorAll('[data-when]').forEach(el => { el.textContent = when; });
    const whose = isToday ? W.today : W.ofDay.replace('{day}', weekday);
    $('[data-title]').innerHTML = esc(friend !== null
      ? (friend === 1 ? W.friendGotOne : W.friendGot).replace('{n}', friend).replace('{whose}', whose)
      : (isToday ? W.todaysTitle : W.dayTitle.replace('{day}', weekday))) + ' <span>' + W.yourTurn + '</span>';
    $('[data-lede]').textContent = W.lede.replace('{when}', isToday ? W.todayWord : W.onDay.replace('{day}', weekday));
    if (fellBack) {
      const note = $('[data-note]');
      note.textContent = W.fellBack;
      note.hidden = false;
    }
    if (friend !== null) document.title = W.docTitle.replace('{n}', friend) + ' \\u00b7 Astute';
    show(0);
  }

  // The day the link names, if the site has its five; the friend's own
  // today if not, said so; and if the site has neither, a way to try again.
  function load() {
    fail.hidden = true;
    json('/five/days.json')
      .then(data => {
        const days = (data && data.days) || {};
        const has = k => !!k && !!days[k] && Array.isArray(days[k].five) && days[k].five.length === 5;
        let d = has(asked) ? asked : null;
        const fellBack = !!asked && !d;
        if (!d && has(today)) d = today;
        if (!d) throw new Error('no five');
        return Promise.all(days[d].five.map(id => json('/five/cards/' + encodeURIComponent(id) + '.json')))
          .then(got => ({ d, got, fellBack }));
      })
      .then(({ d, got, fellBack }) => {
        if (!got.every(playable)) throw new Error('not playable');
        begin(d, got, fellBack);
      })
      .catch(() => {
        stage.innerHTML = '';
        fail.hidden = false;
        more.classList.remove('later');
      });
  }
  $('[data-retry]').addEventListener('click', load);
  load();
})();
"""

# What the page says, in each of the site's languages: the page's own words
# (the template's {placeholders}) and its script's (W). The names are the
# app's: Today's challenge, La sfida di oggi (fiveTitle); the line a friend
# passes on is the app's own (fiveChallengeLine, fiveChallengeAll), and so
# are Lock in and Pick one first (betsLockIn, betsPickFirst).
WORDS = {
    "en": {
        "title": "Today’s challenge · Astute",
        "description": ("A friend played today’s challenge on Astute: five questions from five subjects, "
                        "the same for everyone today. Your turn."),
        "og_title": "Today’s challenge: your turn",
        "skip": "Skip to content",
        "when": "Today’s challenge",
        "h1": "Today’s challenge. <span>Your turn.</span>",
        "lede": "Five questions from five subjects, the same for everyone today. About two minutes.",
        "five": "The five questions",
        "noscript": "The five are played on this page with JavaScript on. They are in the app every morning too.",
        "fail": "Today’s challenge did not load.",
        "retry": "Try again",
        "result": "Your result",
        "rows": "Question by question",
        "pass": "Challenge someone else",
        "more": "Five new ones tomorrow.",
        "more_line": ("Every morning, five new questions in the Astute app, the same for everyone, "
                      "and five cards with the why behind each."),
        "js": {
            "locale": "en-GB",
            "numbers": ["none", "one", "two", "three", "four", "five"],
            "subjects": {},
            "answers": "Answers",
            "guess": "Your guess, in per cent",
            "pickFirst": "Pick one first",
            "lock": "Lock in",
            "question": "Question {n} of 5.",
            "you": "You",
            "friend": "Your friend",
            "of5": "of 5",
            "youGot": "You got {n} of 5",
            "youWin": "You win by {n}.",
            "friendWins": "Your friend wins by {n}.",
            "draw": "A draw.",
            "allRight": "All five right.",
            "noneRight": "None right this time.",
            "someRight": "{right} right, {missed} missed.",
            "right": "Right",
            "notRight": "Not right",
            "yours": "Yours:",
            "rightIs": "Right:",
            "passOn": "Challenge someone else",
            "challenge": "Challenge a friend",
            "today": "today’s",
            "ofDay": "{day}’s",
            "share": "I got {n} of {whose} 5 on Astute. Can you beat me?",
            "shareAll": "I got all of {whose} 5 on Astute. Can you match it?",
            "copied": "Copied. Paste it to a friend.",
            "todays": "Today’s challenge",
            "theChallenge": "The challenge",
            "friendGot": "A friend got {n} of {whose} 5.",
            "friendGotOne": "A friend got 1 of {whose} 5.",
            "todaysTitle": "Today’s challenge.",
            "dayTitle": "{day}’s challenge.",
            "yourTurn": "Your turn.",
            "lede": "Five questions from five subjects, the same for everyone {when}. About two minutes.",
            "todayWord": "today",
            "onDay": "on {day}",
            "fellBack": "The five your friend played are no longer here, so these are today’s.",
            "docTitle": "A friend got {n} of 5",
        },
    },
    "it": {
        "title": "La sfida di oggi · Astute",
        "description": ("Un amico ha giocato la sfida di oggi su Astute: cinque domande da cinque materie, "
                        "le stesse per tutti oggi. Tocca a te."),
        "og_title": "La sfida di oggi: tocca a te",
        "skip": "Vai al contenuto",
        "when": "La sfida di oggi",
        "h1": "La sfida di oggi. <span>Tocca a te.</span>",
        "lede": "Cinque domande da cinque materie, le stesse per tutti oggi. Circa due minuti.",
        "five": "Le cinque domande",
        "noscript": "Le cinque si giocano su questa pagina con JavaScript attivo. Ogni mattina sono anche nell’app.",
        "fail": "La sfida di oggi non si è caricata.",
        "retry": "Riprova",
        "result": "Il tuo risultato",
        "rows": "Domanda per domanda",
        "pass": "Sfida qualcun altro",
        "more": "Domani, cinque nuove.",
        "more_line": ("Ogni mattina, nell’app Astute, cinque domande nuove, le stesse per tutti, "
                      "e cinque carte con il perché di ognuna."),
        "js": {
            "locale": "it-IT",
            "numbers": ["nessuna", "una", "due", "tre", "quattro", "cinque"],
            "subjects": {
                "Economics": "Economia", "Sport": "Sport", "Nature": "Natura", "Science": "Scienza",
                "Maths": "Matematica", "Language": "Lingua", "Technology": "Tecnologia", "Space": "Spazio",
                "Philosophy": "Filosofia", "Cinema": "Cinema", "Psychology": "Psicologia", "Music": "Musica",
                "Weird facts": "Stranezze", "Art": "Arte", "Pop culture": "Cultura pop",
                "Human body": "Corpo umano", "Medicine": "Medicina", "Food": "Cibo", "History": "Storia",
                "Life": "Vita", "Thinking": "Pensiero",
            },
            "answers": "Risposte",
            "guess": "La tua stima, in percentuale",
            "pickFirst": "Prima scegline una",
            "lock": "Conferma",
            "question": "Domanda {n} di 5.",
            "you": "Tu",
            "friend": "Il tuo amico",
            "of5": "su 5",
            "youGot": "Ne hai indovinate {n} su 5",
            "youWin": "Vinci tu, di {n}.",
            "friendWins": "Vince il tuo amico, di {n}.",
            "draw": "Pari.",
            "allRight": "Tutte e cinque giuste.",
            "noneRight": "Nessuna giusta, stavolta.",
            "someRight": "{right} giuste, {missed} sbagliate.",
            "right": "Giusta",
            "notRight": "Sbagliata",
            "yours": "La tua:",
            "rightIs": "Giusta:",
            "passOn": "Sfida qualcun altro",
            "challenge": "Sfida un amico",
            "today": "di oggi",
            "ofDay": "di {day}",
            "share": "Ho indovinato {n} delle cinque {whose} su Astute. Riesci a battermi?",
            "shareAll": "Ho indovinato tutte le cinque {whose} su Astute. Riesci a fare lo stesso?",
            "copied": "Copiato. Incollalo a un amico.",
            "todays": "La sfida di oggi",
            "theChallenge": "La sfida",
            "friendGot": "Un amico ne ha indovinate {n} delle cinque {whose}.",
            "friendGotOne": "Un amico ne ha indovinata 1 delle cinque {whose}.",
            "todaysTitle": "La sfida di oggi.",
            "dayTitle": "La sfida di {day}.",
            "yourTurn": "Tocca a te.",
            "lede": "Cinque domande da cinque materie, le stesse per tutti {when}. Circa due minuti.",
            "todayWord": "oggi",
            "onDay": "{day}",
            "fellBack": "Le cinque giocate dal tuo amico non ci sono più: queste sono quelle di oggi.",
            "docTitle": "Un amico ha fatto {n} su 5",
        },
    },
}

PAGE = """<!DOCTYPE html>
<html lang="{lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
{lang_script}
<title>{title}</title>
<meta name="description" content="{description}">
<meta name="robots" content="noindex">
<meta name="theme-color" content="#141416">
<meta name="color-scheme" content="dark">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Astute">
<meta property="og:locale" content="{locale}">
<meta property="og:title" content="{og_title}">
<meta property="og:description" content="{description}">
<meta property="og:url" content="{url}">
<meta property="og:image" content="{site}/assets/og.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<link rel="canonical" href="{url}">
<link rel="icon" type="image/png" sizes="64x64" href="/favicon.png">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="preload" href="/assets/fonts/figtree-latin.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="/assets/fonts/fraunces-latin.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="/five/days.json" as="fetch" crossorigin>
<link rel="stylesheet" href="/assets/site.css">
<style>
{css}</style>
<script src="/assets/main.js" defer></script>
</head>
<body>
<a class="skip" href="#top">{skip}</a>
<div class="grain" aria-hidden="true"></div>

{header}

<main class="duel-page" id="top">
<div class="duel-glow" data-glow aria-hidden="true"></div>
<div class="duel">
  <p class="duel-sr" data-status aria-live="polite"></p>
  <header class="duel-head" data-head>
    <p class="duel-when" data-when>{when}</p>
    <h1 class="duel-title" data-title>{h1}</h1>
    <p class="duel-lede" data-lede>{lede}</p>
    <p class="duel-note" data-note hidden></p>
  </header>

  <section class="duel-play" data-play aria-label="{five}">
    <ol class="duel-steps" data-steps aria-hidden="true"><li class="now"></li><li></li><li></li><li></li><li></li></ol>
    <div class="duel-stage" data-stage><div class="duel-card duel-wait" aria-hidden="true"></div></div>
    <noscript><p class="duel-lede">{noscript}</p></noscript>
    <p class="duel-fail" data-fail hidden>{fail}<button type="button" data-retry>{retry}</button></p>
  </section>

  <section class="duel-result" data-result hidden aria-label="{result}">
    <div class="duel-sheet">
      <p class="duel-kicker" data-when>{when}</p>
      <h2 class="duel-score" data-score tabindex="-1"></h2>
      <p class="duel-verdict" data-verdict></p>
      <p class="duel-kicker">{rows}</p>
      <ol class="duel-rows" data-rows></ol>
      <button type="button" class="duel-pass" data-pass>{pass_}</button>
      <p class="duel-passed" data-passed role="status"></p>
    </div>
  </section>

  <section class="duel-more later" data-more>
    <h2>{more}</h2>
    <p>{more_line} {where}.</p>
    <div class="stores large center">{stores}</div>
  </section>
</div>
</main>

{footer}
<script>
{script}</script>
</body>
</html>
"""

LOCALES = {"en": "en_GB", "it": "it_IT"}


def stores(lang: str = "en") -> str:
    """The two stores' badges, as the site draws them (chrome.stores): the
    store the app is in first. Until the App Store listing is live, Google
    Play's is the button and Apple's comes after it, marked as coming and
    leading to the list for the iPhone."""
    return chrome.stores(lang, play_first=True)


def render(lang: str = "en") -> str:
    """The page, whole, in [lang]: the site's chrome around the challenge."""
    w = WORDS[lang]
    script = SCRIPT.replace("@WORDS@", json.dumps(w["js"], ensure_ascii=False))
    return PAGE.format(
        lang=lang,
        lang_script=chrome.lang_script(lang, "/" + PATH),
        title=w["title"],
        description=html.escape(w["description"], quote=True),
        og_title=html.escape(w["og_title"], quote=True),
        locale=LOCALES[lang],
        url=f"{SITE}{chrome.at('/' + PATH, lang)}",
        site=SITE,
        css=CSS,
        skip=w["skip"],
        header=chrome.header(lang, "/" + PATH),
        when=w["when"],
        h1=w["h1"],
        lede=w["lede"],
        five=w["five"],
        noscript=w["noscript"],
        fail=w["fail"],
        retry=w["retry"],
        result=w["result"],
        rows=w["rows"],
        pass_=w["pass"],
        more=w["more"],
        more_line=w["more_line"],
        where=html.escape(where(sentence=True, lang=lang)),
        stores=stores(lang),
        footer=chrome.footer(lang, "/" + PATH),
        script=script,
    )


def write(site: Path) -> Path:
    """Writes the page into [site] in every language the site speaks, where
    the site serves them: /sfida, and /it/sfida. Returns the English one."""
    for lang in chrome.LANGS:
        out = site / chrome.at(f"/{PATH}", lang).lstrip("/")
        out = out.with_name(out.name + ".html")
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(render(lang), encoding="utf-8")
    return site / f"{PATH}.html"


def main(argv: list[str]) -> int:
    if len(argv) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    out = write(Path(argv[0]))
    print(f"today's challenge written to {out}, and in every other language under /<lang>/")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
