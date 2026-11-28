// astutetheapp.com — the few things on the site that move, without a
// framework. Every page reads without it; this adds the menu, the nav that
// frosts and its progress line, things coming into view, the numbers that
// count up, the light that follows the pointer across a card, the phone that
// turns and goes through today's cards on its shelf, Today's five and the
// time to the next, the rows that scroll, the calibration chart, the cards
// that flip, the plan picker, the questions that open, and the rail beside a
// long page — and it counts the pages read and the store buttons pressed.
(() => {
  const $ = (s, root = document) => root.querySelector(s);
  const $$ = (s, root = document) => Array.from(root.querySelectorAll(s));
  const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const finePointer = window.matchMedia('(hover: hover) and (pointer: fine)').matches;
  const onChange = (mq, fn) => (mq.addEventListener ? mq.addEventListener('change', fn) : mq.addListener(fn));

  // Download links go to Google Play on Android, and on a computer to the QR
  // code at the foot of the landing page, to be scanned with the phone. On
  // an iPhone or iPad they go where tool/site/chrome.py wrote them: the App
  // Store once its listing is live, and until then /get, which says the
  // iPhone app is on its way rather than leave the store to say it has no
  // such page.
  const ua = navigator.userAgent;
  const android = /android/i.test(ua);
  const ios = /iphone|ipad|ipod/i.test(ua) || (/macintosh/i.test(ua) && navigator.maxTouchPoints > 1);
  $$('[data-store]').forEach(a => {
    if (android) a.href = 'https://play.google.com/store/apps/details?id=com.astuto.app';
    else if (!ios) a.href = '/#download';
  });

  // What the site measures: the pages read and the store buttons pressed,
  // through PostHog in the EU, with nothing kept on the device — no cookie,
  // no storage, a new anonymous visitor on every page. A browser that sends
  // Do Not Track or Global Privacy Control gets none of it: the library is
  // not fetched, and every link goes out as it was written.
  //
  // A link shared from the app says where it came from (?ref=share_day,
  // share_card, share_record). The ref rides on every event of the page, on
  // the links to the site's other pages, so that a visit keeps it without
  // anything being stored, and on the store links as their campaign — the
  // page's name when there is no ref: ct on the App Store's, and on Google
  // Play's the campaign of its install referrer, which is a query string of
  // its own and so goes in encoded. Apple counts a ct only beside the
  // account's provider token, which tool/site/chrome.py writes into every
  // App Store link once it is set there.
  if (navigator.doNotTrack !== '1' && navigator.globalPrivacyControl !== true) {
    const POSTHOG_KEY = 'phc_tEhSptLL46d7zJTJqMDssKzBSySEFF6XQ3rYwETEPaFF';
    const POSTHOG_HOST = 'https://eu.i.posthog.com';
    // Served from the site, at a pinned version: the slim build, which has
    // no autocapture, replay, surveys or flags in it to be switched on, and
    // never fetches more script from anywhere.
    const POSTHOG_JS = '/assets/vendor/posthog-js-1.434.14-slim.es.js';

    const given = new URLSearchParams(location.search).get('ref');
    const ref = given && /^[\w-]{1,40}$/.test(given) ? given : null;
    // A campaign token is at most forty characters, at Apple as here.
    const page = location.pathname.replace(/\.html$/, '').replace(/^\/+|\/+$/g, '').replace(/^index$/, '').replace(/[^\w-]+/g, '-').slice(0, 40) || 'home';
    const storeOf = a => {
      if (a.hostname === 'apps.apple.com' && /^\/(?:[a-z]{2}\/)?app\//.test(a.pathname)) return 'app_store';
      if (a.hostname === 'play.google.com' && a.pathname === '/store/apps/details') return 'play';
      return null;
    };

    // Written onto the links once, so what a long press copies is what a tap
    // opens.
    Array.from(document.links).forEach(a => {
      const store = storeOf(a);
      if (!store && !(ref && a.origin === location.origin && a.pathname !== location.pathname)) return;
      const url = new URL(a.href);
      if (store === 'app_store') url.searchParams.set('ct', ref || page);
      else if (store === 'play') url.searchParams.set('referrer', 'utm_source=site&utm_campaign=' + (ref || page));
      else url.searchParams.set('ref', ref);
      a.href = url.href;
    });

    // Clicks made before the library has arrived wait for it. A store button
    // usually takes the page away, so its event goes at once, as a beacon,
    // which the browser delivers after the page has gone.
    let posthog = null;
    const waiting = [];
    const capture = (event, properties, options) => (posthog ? posthog.capture(event, properties, options) : waiting.push([event, properties, options]));
    const onStore = e => {
      if (e.type === 'auxclick' && e.button !== 1) return;
      const a = e.target.closest && e.target.closest('a[href]');
      const store = a && storeOf(a);
      if (store) capture('store clicked', { store, page: location.pathname, ref }, { send_instantly: true, transport: 'sendBeacon' });
    };
    document.addEventListener('click', onStore, true);
    document.addEventListener('auxclick', onStore, true);

    import(POSTHOG_JS).then(({ default: ph }) => {
      ph.init(POSTHOG_KEY, {
        api_host: POSTHOG_HOST,
        // In memory only: no cookie, no localStorage, nothing on the device.
        persistence: 'memory',
        capture_pageview: true,
        // A page view and a store click are the whole of it.
        capture_pageleave: false,
        autocapture: false,
        disable_session_recording: true,
        person_profiles: 'identified_only',
        // No feature flags and no remote settings: nothing the project's
        // dashboard turns on can reach this page.
        advanced_disable_flags: true,
      });
      // Before the page view, which goes out on the next tick.
      if (ref) ph.register({ ref });
      posthog = ph;
      waiting.splice(0).forEach(([event, properties, options]) => ph.capture(event, properties, options));
    }).catch(() => {});
  }

  // Today's edition in the first screen, counted from the date as the app
  // counts it (lib/data/daily.dart, editionOf): the first of September 2026
  // was the first, and every day since one more.
  const kicker = $('#hero-kicker');
  if (kicker) {
    const d = new Date();
    const edition = Math.round((Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()) - Date.UTC(2026, 8, 1)) / 864e5) + 1;
    if (edition > 0) kicker.textContent = 'Edition ' + edition + ' \u00b7 out this morning';
  }

  // The nav frosts once the page has moved; a line along the top shows how
  // far down the page is; the nudge to scroll goes once someone has.
  const nav = $('.site-nav');
  const progress = $('.progress');
  const cue = $('.scroll-cue');
  if (nav) {
    let queued = false;
    const onScroll = () => {
      queued = false;
      nav.classList.toggle('scrolled', window.scrollY > 16);
      if (cue) cue.classList.toggle('gone', window.scrollY > 80);
      if (progress) {
        const max = document.documentElement.scrollHeight - window.innerHeight;
        progress.style.setProperty('--p', max > 0 ? Math.min(1, window.scrollY / max).toFixed(4) : 0);
      }
    };
    window.addEventListener('scroll', () => { if (!queued) { queued = true; requestAnimationFrame(onScroll); } }, { passive: true });
    onScroll();
  }

  // The menu on a phone: a sheet over the page, closed by a link, the
  // button, Escape, or the window growing past a phone.
  const toggle = $('#menu-toggle');
  const menu = $('#mobile-menu');
  if (toggle && menu) {
    $$('a', menu).forEach((a, i) => a.style.setProperty('--i', i));
    const show = open => {
      menu.hidden = !open;
      toggle.setAttribute('aria-expanded', String(open));
      toggle.setAttribute('aria-label', open ? 'Close the menu' : 'Menu');
      if (nav) nav.classList.toggle('open', open);
      document.body.classList.toggle('menu-open', open);
    };
    toggle.addEventListener('click', () => show(menu.hidden));
    $$('a', menu).forEach(a => a.addEventListener('click', () => show(false)));
    document.addEventListener('keydown', e => { if (e.key === 'Escape' && !menu.hidden) show(false); });
    onChange(window.matchMedia('(min-width: 768px)'), e => { if (e.matches && !menu.hidden) show(false); });
  }

  // The section being read, marked in the nav.
  const links = $$('.nav-links a[href^="#"]');
  if (links.length && 'IntersectionObserver' in window) {
    const byId = new Map(links.map(a => [a.getAttribute('href').slice(1), a]));
    const spy = new IntersectionObserver(entries => {
      entries.forEach(e => {
        if (!e.isIntersecting) return;
        links.forEach(a => a.classList.toggle('active', a === byId.get(e.target.id)));
      });
    }, { rootMargin: '-45% 0px -50% 0px' });
    byId.forEach((a, id) => { const s = document.getElementById(id); if (s) spy.observe(s); });
  }

  // Things come into view as they are reached. A group reveals its own
  // children together, each after its own delay.
  const reveal = el => el.classList.add('in');
  if (!still && 'IntersectionObserver' in window) {
    const seen = new IntersectionObserver(entries => {
      entries.forEach(e => {
        if (!e.isIntersecting) return;
        const el = e.target;
        if (el.hasAttribute('data-reveal-group')) $$('[data-reveal]', el).forEach(reveal);
        else reveal(el);
        seen.unobserve(el);
      });
    }, { rootMargin: '0px 0px -8% 0px', threshold: 0.12 });
    const groups = $$('[data-reveal-group]');
    groups.forEach(g => seen.observe(g));
    $$('[data-reveal]').forEach(el => {
      if (!groups.some(g => g.contains(el))) seen.observe(el);
    });
  } else {
    $$('[data-reveal]').forEach(reveal);
  }

  // A number climbs to its value the first time it is seen, rather than
  // landing.
  const counts = $$('[data-count]');
  if (counts.length && !still) {
    const count = el => {
      const to = parseFloat(el.dataset.count);
      if (!isFinite(to)) return;
      const t0 = performance.now();
      const tick = now => {
        const p = Math.min(1, (now - t0) / 1200);
        el.textContent = Math.round(to * (1 - Math.pow(1 - p, 3)));
        if (p < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    };
    counts.forEach(el => { el.textContent = '0'; });
    if ('IntersectionObserver' in window) {
      const io = new IntersectionObserver(entries => {
        entries.forEach(e => {
          if (!e.isIntersecting) return;
          io.unobserve(e.target);
          setTimeout(() => count(e.target), +(e.target.dataset.countDelay || 0));
        });
      }, { threshold: 0.6 });
      counts.forEach(el => io.observe(el));
    } else {
      counts.forEach(count);
    }
  }

  // A light that follows the pointer across a card, and a card that turns a
  // little towards it. Both only where there is a pointer to follow.
  if (finePointer) {
    $$('[data-spot]').forEach(el => el.addEventListener('pointermove', e => {
      const r = el.getBoundingClientRect();
      el.style.setProperty('--mx', (e.clientX - r.left).toFixed(0) + 'px');
      el.style.setProperty('--my', (e.clientY - r.top).toFixed(0) + 'px');
    }));
    if (!still) $$('[data-tilt]').forEach(el => {
      const amp = (el.dataset.tilt || '6').split(' ').map(Number);
      const ax = amp[0] || 6, ay = amp[1] || ax;
      el.addEventListener('pointermove', e => {
        const r = el.getBoundingClientRect();
        el.style.setProperty('--ry', (((e.clientX - r.left) / r.width - 0.5) * ax).toFixed(2) + 'deg');
        el.style.setProperty('--rx', (-((e.clientY - r.top) / r.height - 0.5) * ay).toFixed(2) + 'deg');
      });
      el.addEventListener('pointerleave', () => { el.style.setProperty('--ry', '0deg'); el.style.setProperty('--rx', '0deg'); });
    });
  }

  // The phone in the first screen: it turns a little towards the pointer,
  // the cards around it drift with the scroll and against the pointer, and
  // the card on it plays as in the app — pick an answer, say how sure, turn
  // it over — five times, and then the day as a number.
  const phone = $('.float');
  const hero = phone && phone.closest('section');
  const orbit = $('.orbit');
  if (phone && hero && finePointer && !still) {
    let tx = 0, ty = 0, x = 0, y = 0, running = false;
    const step = () => {
      x += (tx - x) * 0.08;
      y += (ty - y) * 0.08;
      phone.style.setProperty('--ry', x.toFixed(2) + 'deg');
      phone.style.setProperty('--rx', y.toFixed(2) + 'deg');
      if (orbit) {
        orbit.style.setProperty('--ox', (-x * 1.2).toFixed(1) + 'px');
        orbit.style.setProperty('--oy', (y * 1.2).toFixed(1) + 'px');
      }
      if (Math.abs(tx - x) > 0.01 || Math.abs(ty - y) > 0.01) requestAnimationFrame(step);
      else running = false;
    };
    const go = () => { if (!running) { running = true; requestAnimationFrame(step); } };
    hero.addEventListener('pointermove', e => {
      const r = hero.getBoundingClientRect();
      // Over the phone it all but stops: it has turned to face the reader.
      const k = phone.classList.contains('facing') ? 0.2 : 1;
      tx = ((e.clientX - r.left) / r.width - 0.5) * 12 * k;
      ty = -((e.clientY - r.top) / r.height - 0.5) * 8 * k;
      go();
    });
    hero.addEventListener('pointerleave', () => { tx = 0; ty = 0; go(); });
  }
  // The drift is for the page in two columns, where the phone is in the
  // first screen; lower down a narrow page it would only pull the cards off
  // their places.
  const wide = window.matchMedia('(min-width: 1120px)');
  if (orbit && hero && !still) {
    let queued = false;
    const drift = () => {
      queued = false;
      const y = wide.matches ? window.scrollY : 0;
      if (y < hero.offsetHeight) orbit.style.setProperty('--sy', (y * 0.09).toFixed(1) + 'px');
    };
    window.addEventListener('scroll', () => { if (!queued) { queued = true; requestAnimationFrame(drift); } }, { passive: true });
  }
  // Where there is no pointer to hover with, a tap turns a card round.
  if (!finePointer) $$('.orb').forEach(orb => orb.addEventListener('click', () => orb.classList.toggle('turned')));

  // Every card's question is set as the app's cards set theirs: in the middle
  // of the room under the subject, as large as that room holds between the
  // two sizes the card allows (data-fit="min max"), with the tracking
  // tightening as it grows (the CSS, from --fs). The page carries the size
  // measured for each at the width it was measured at (--fs, data-fit-w), so
  // it reads right before this runs and without it; this checks each once
  // the fonts are in and measures again any that do not fit, or whose card
  // is now another size. A question that will not fit even at the smallest
  // size lets its card grow where the card can, and is never clipped. A card
  // with no room at all (hidden) is left until it has some.
  const fitted = new Map();
  const fitQuestion = el => {
    const text = el.firstElementChild;
    if (!text || !text.textContent) return;
    el.classList.remove('spill');
    const w = el.clientWidth, h = el.clientHeight;
    if (!w || !h) return;
    const fits = () => text.offsetHeight <= el.clientHeight + 0.5 && text.scrollWidth <= text.clientWidth + 1;
    if (!el.dataset.fitted && Math.abs(w - Number(el.dataset.fitW || -9)) <= 2 && fits()) return;
    el.dataset.fitted = '1';
    const key = el.dataset.fit + '|' + w + '|' + h + '|' + text.textContent;
    if (!fitted.has(key)) {
      const [min, max] = el.dataset.fit.split(' ').map(Number);
      const at = s => { el.style.setProperty('--fs', s + 'px'); return fits(); };
      let lo = min, hi = max;
      if (at(max)) lo = max;
      else while (hi - lo > 0.25) { const mid = (lo + hi) / 2; if (at(mid)) lo = mid; else hi = mid; }
      fitted.set(key, lo);
    }
    el.style.setProperty('--fs', fitted.get(key) + 'px');
    el.classList.toggle('spill', !fits());
  };
  // The two rows of twenty subjects (tool/site/subjects_rows.py) start somewhere new on
  // every visit, and each subject shows one of its two questions in one row and the other
  // in the other. The order round the colour wheel is kept, so neighbours stay apart.
  const subjectRows = $$('.marquee[data-row]');
  if (subjectRows.length) {
    const swap = {};
    subjectRows.forEach(row => {
      const tracks = $$('.marquee-track', row);
      const n = tracks[0] ? tracks[0].children.length : 0;
      const turn = Math.floor(Math.random() * n);
      tracks.forEach(t => { for (let k = 0; k < turn; k++) t.appendChild(t.firstElementChild); });
      $$('.deck-card[data-qs]', row).forEach(card => {
        const subject = $('.label span', card).textContent;
        if (!(subject in swap)) swap[subject] = Math.random() < .5;
        let qs = [];
        try { qs = JSON.parse(card.dataset.qs); } catch (e) { return; }
        const q = qs[(+row.dataset.row + (swap[subject] ? 1 : 0)) % 2];
        const span = $('.deck-q span', card);
        if (span && q) span.textContent = q;
      });
    });
  }
  const fitQuestions = () => $$('[data-fit]').forEach(fitQuestion);
  // Measured with the fonts in; anything measured before they came is
  // measured again.
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(() => { fitted.clear(); fitQuestions(); });
  else window.addEventListener('load', fitQuestions);
  // Cards that change width with the window (the two that flip, today's)
  // are measured again when it settles.
  let refit = 0;
  window.addEventListener('resize', () => { cancelAnimationFrame(refit); refit = requestAnimationFrame(fitQuestions); });

  const demo = $('[data-demo]');
  // The phone turns to face whoever reaches for it: under the pointer, and
  // for good once a finger has touched it.
  if (demo && phone && !still) {
    demo.addEventListener('pointerenter', e => { if (e.pointerType === 'mouse') phone.classList.add('facing'); });
    demo.addEventListener('pointerleave', e => { if (e.pointerType === 'mouse') phone.classList.remove('facing'); });
    demo.addEventListener('pointerdown', e => { if (e.pointerType !== 'mouse') phone.classList.add('facing'); });
    demo.addEventListener('focusin', () => phone.classList.add('facing'));
    demo.addEventListener('focusout', e => { if (!demo.contains(e.relatedTarget) && !demo.matches(':hover')) phone.classList.remove('facing'); });
  }
  // The phone's shelf: today's five cards, dealt by the page's own script
  // (index.html) from the bank's most beautiful drawings, one in front and
  // the next showing at each edge. It goes on by itself, as the app's shelf
  // goes on under a thumb: a card every few seconds, its bar filling the
  // while, the light behind the phone taking its colour. It waits while it is
  // out of sight, while its page is hidden, while the pointer is on the phone
  // and while a card is being played; the button under it stops it, and
  // back and on step by hand. Asked for less motion, it stands still and
  // steps only by hand. Where there is a pointer, the card in front is its
  // own page from the site, live, put in once it has come to rest; on a
  // touch screen, once it is tapped.
  const shelf = demo && $('[data-shelf]', demo);
  const shelfCards = shelf ? $$('.shelf-card', shelf) : [];
  if (shelf && shelfCards.length > 1) {
    const n = shelfCards.length;
    const DWELL = 6500;
    const bars = $$('.app-bars i', demo).slice(0, n);
    const stage = demo.closest('.hero-stage');
    const playBtn = $('[data-shelf-play]');
    const holds = new Set();
    let at = 0, elapsed = 0, last = 0, raf = 0, stopped = still;
    let live = null, liveTimer = 0, idleTimer = 0;

    const glow = hex => {
      const h = parseInt(String(hex).slice(1), 16) || 0x2B5CFF;
      return ((h >> 16) & 255) + ' ' + ((h >> 8) & 255) + ' ' + (h & 255) + ' / .42';
    };
    const fill = p => {
      const bar = bars[at] && bars[at].firstElementChild;
      if (bar) bar.style.setProperty('--p', p.toFixed(4));
    };
    // Each card at its place from the one in front: the one just gone at -1,
    // the rest waiting off to the right. A card that would cross the screen
    // to get to its place (the one gone, coming round to the back) goes
    // there at once, unseen.
    const place = all => {
      shelfCards.forEach((card, i) => {
        let o = (i - at + n) % n;
        if (o === n - 1) o = -1;
        const was = parseFloat(card.style.getPropertyValue('--o'));
        card.classList.toggle('jump', all || !(Math.abs(o - was) <= 1));
        card.style.setProperty('--o', o);
        card.classList.toggle('front', o === 0);
        card.setAttribute('aria-hidden', String(o !== 0));
      });
      void shelf.offsetWidth;
      shelfCards.forEach(card => card.classList.remove('jump'));
      bars.forEach((bar, i) => {
        bar.classList.toggle('done', i < at);
        if (bar.firstElementChild) bar.firstElementChild.style.setProperty('--p', i < at ? 1 : 0);
      });
      if (stopped && still) fill(1);
      if (stage) stage.style.setProperty('--glow', glow(shelfCards[at].dataset.colour));
    };

    const running = () => !stopped && holds.size === 0;
    const tick = now => {
      raf = 0;
      if (!running()) { last = 0; return; }
      if (last) elapsed += Math.min(now - last, 100);
      last = now;
      fill(Math.min(1, elapsed / DWELL));
      if (elapsed >= DWELL) go(at + 1);
      raf = requestAnimationFrame(tick);
    };
    const kick = () => { if (running() && !raf) { last = 0; raf = requestAnimationFrame(tick); } };
    const hold = why => holds.add(why);
    const release = why => { holds.delete(why); kick(); };

    // The page of the card in front, over its picture: laid out at the app's
    // size, shown once its drawing has come in, so that it takes the
    // picture's place without being seen to. Played with, it holds the
    // shelf until it has been left alone for a while.
    const dropLive = () => {
      clearTimeout(liveTimer);
      clearTimeout(idleTimer);
      holds.delete('play');
      shelfCards.forEach(card => card.classList.remove('live'));
      if (!live) return;
      const frame = live;
      live = null;
      frame.classList.remove('on');
      setTimeout(() => frame.remove(), 450);
    };
    // Asked for with a tap, it shows at once, coming in as it does in the app.
    const makeLive = asked => {
      const card = shelfCards[at];
      if (!card || live) return;
      const frame = document.createElement('iframe');
      frame.className = 'shelf-live';
      frame.title = (card.querySelector('img') || {}).alt || 'A card from Astute';
      frame.src = '/cards/pages/' + encodeURIComponent(card.dataset.id) + '.html';
      frame.addEventListener('load', () => {
        if (live !== frame) return;
        // The page draws on its card's colour, as the app's frame gives it:
        // its picture goes as the page comes.
        setTimeout(() => {
          if (live !== frame) return;
          frame.classList.add('on');
          card.classList.add('live');
        }, still || asked === true ? 0 : 1300);
        try {
          const played = () => {
            hold('play');
            clearTimeout(idleTimer);
            idleTimer = setTimeout(() => release('play'), 15000);
          };
          ['pointerdown', 'keydown', 'wheel'].forEach(t => frame.contentDocument.addEventListener(t, played, { passive: true }));
        } catch (e) { /* a page that is not the site's own says nothing */ }
      });
      live = frame;
      shelf.appendChild(frame);
    };
    const soonLive = () => {
      clearTimeout(liveTimer);
      if (finePointer) liveTimer = setTimeout(makeLive, still ? 0 : 1100);
    };

    function go(to) {
      dropLive();
      at = ((to % n) + n) % n;
      elapsed = 0;
      place(still);
      soonLive();
    }

    const say = () => {
      if (!playBtn) return;
      playBtn.setAttribute('aria-pressed', String(stopped));
      playBtn.setAttribute('aria-label', stopped ? 'Play the cards' : 'Pause the cards');
      shelf.setAttribute('aria-live', stopped ? 'polite' : 'off');
    };
    if (playBtn) playBtn.addEventListener('click', () => {
      stopped = !stopped;
      say();
      kick();
    });
    $$('[data-shelf-go]').forEach(b => b.addEventListener('click', () => go(at + Number(b.dataset.shelfGo))));

    // A card at the edge brings itself to the front; a tap on the one in
    // front, on a touch screen, puts its page in to be played; a swipe goes
    // back or on.
    let down = null;
    shelf.addEventListener('pointerdown', e => { down = { x: e.clientX, y: e.clientY, id: e.pointerId }; });
    shelf.addEventListener('pointerup', e => {
      if (!down || down.id !== e.pointerId) return;
      const dx = e.clientX - down.x, dy = e.clientY - down.y;
      down = null;
      if (Math.abs(dx) > 36 && Math.abs(dx) > Math.abs(dy) * 1.2) { go(at + (dx < 0 ? 1 : -1)); return; }
      if (Math.abs(dx) > 8 || Math.abs(dy) > 8) return;
      const card = e.target.closest && e.target.closest('.shelf-card');
      if (!card) return;
      const o = parseFloat(card.style.getPropertyValue('--o'));
      if (o === 1 || o === -1) go(at + o);
      else if (o === 0 && !live) {
        makeLive(true);
        hold('play');
        idleTimer = setTimeout(() => release('play'), 15000);
      }
    });
    shelf.addEventListener('pointercancel', () => { down = null; });

    demo.addEventListener('pointerenter', e => { if (e.pointerType === 'mouse') hold('hover'); });
    demo.addEventListener('pointerleave', e => { if (e.pointerType === 'mouse') release('hover'); });
    document.addEventListener('visibilitychange', () => (document.hidden ? hold('hidden') : release('hidden')));
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(entries => entries.forEach(en => (en.isIntersecting ? release('away') : hold('away'))), { threshold: 0.25 }).observe(demo);
    }

    place(true);
    say();
    // The clock starts once the phone has risen into place.
    hold('rising');
    setTimeout(() => release('rising'), still ? 0 : 1300);
    soonLive();
  }

  // A row that scrolls sideways: arrows on a wide screen, soft edges where
  // there is more, dots that say where in it the reader is, and dragging
  // with a mouse.
  const scrollRow = row => {
    const scope = row.closest('section') || document;
    const prev = $('[data-row="prev"]', scope);
    const next = $('[data-row="next"]', scope);
    const dots = $('[data-row-dots]', scope);
    const items = $$(':scope > *', row);
    if (dots) items.forEach(() => dots.appendChild(document.createElement('i')));
    const edges = () => {
      const max = row.scrollWidth - row.clientWidth;
      row.style.setProperty('--fl', row.scrollLeft > 4 ? '56px' : '0px');
      row.style.setProperty('--fr', row.scrollLeft < max - 4 ? '56px' : '0px');
      // A row that fits has nowhere to go: no arrows, no dots.
      if (prev && prev.parentElement.classList.contains('row-nav')) prev.parentElement.style.visibility = max > 4 ? '' : 'hidden';
      if (prev) prev.disabled = row.scrollLeft <= 4;
      if (next) next.disabled = row.scrollLeft >= max - 4;
      if (dots) dots.hidden = max <= 4;
      if (dots) {
        const left = row.getBoundingClientRect().left + parseFloat(getComputedStyle(row).paddingLeft);
        let at = 0, best = Infinity;
        items.forEach((it, i) => {
          const d = Math.abs(it.getBoundingClientRect().left - left);
          if (d < best) { best = d; at = i; }
        });
        if (max > 4 && row.scrollLeft >= max - 4) at = items.length - 1;
        $$('i', dots).forEach((d, i) => d.classList.toggle('on', i === at));
      }
    };
    const stepBy = dir => {
      const item = items[0];
      const gap = parseFloat(getComputedStyle(row).columnGap) || 16;
      row.scrollBy({ left: dir * ((item ? item.offsetWidth : 272) + gap), behavior: still ? 'auto' : 'smooth' });
    };
    if (prev) prev.addEventListener('click', () => stepBy(-1));
    if (next) next.addEventListener('click', () => stepBy(1));
    row.addEventListener('scroll', edges, { passive: true });
    window.addEventListener('resize', edges);
    edges();
    if (finePointer) {
      let startX = 0, startLeft = 0, down = false, moved = false;
      row.addEventListener('pointerdown', e => {
        if (e.pointerType !== 'mouse' || e.button !== 0) return;
        down = true; moved = false; startX = e.clientX; startLeft = row.scrollLeft;
      });
      window.addEventListener('pointermove', e => {
        if (!down) return;
        const dx = e.clientX - startX;
        if (!moved && Math.abs(dx) > 4) { moved = true; row.classList.add('dragging'); }
        if (moved) row.scrollLeft = startLeft - dx;
      });
      window.addEventListener('pointerup', () => {
        if (!down) return;
        down = false;
        if (moved) {
          // Let the snap settle on the nearest card once the drag has let go.
          const left = row.scrollLeft;
          row.classList.remove('dragging');
          row.scrollLeft = left;
        }
      });
    }
  };
  $$('[data-scroll-row]').forEach(scrollRow);

  // Today's five: the five questions at the top of Explore in the app, the
  // same on every phone today. The deploy deals them with the app's own deal
  // for the next four hundred days (tool/todays_five.dart): five/days.json
  // names each day's five, and each card's own file says what to show of
  // it. The day is the reader's own and turns at their midnight; each card
  // opens its page (/c/<id>), where it can be answered. Until it has all
  // five, the section stays hidden.
  const five = $('#today');
  const fiveRow = $('#five-row');
  if (five && fiveRow && window.fetch) {
    const now = new Date();
    const key = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0');
    const json = url => fetch(url).then(r => (r.ok ? r.json() : null));
    const triplet = hex => (/^#[0-9a-f]{6}$/i.test(hex) ? [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16)).join(' ') : '16 16 12');
    const esc = s => String(s).replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch]);
    json('/five/days.json')
      .then(data => {
        const day = data && data.days && data.days[key];
        if (!day || !Array.isArray(day.five) || day.five.length !== 5) return null;
        return Promise.all(day.five.map(id => json('/five/cards/' + encodeURIComponent(id) + '.json'))).then(cards => ({ day, cards }));
      })
      .then(got => {
        if (!got || got.cards.some(c => !c || !c.id || !c.question)) return;
        fiveRow.innerHTML = got.cards.map((c, i) => {
          const mark = 'subject-' + String(c.topic || '').toLowerCase().replace(/[^a-z]+/g, '-');
          return '<li class="five-item">'
            + '<a class="five-card paper" href="/c/' + encodeURIComponent(c.id) + '" style="--c:' + esc(c.color) + '; --ink:' + triplet(c.ink) + '">'
            + '<span class="label"><svg class="mark" aria-hidden="true"><use href="#' + esc(mark) + '"/></svg><span>' + esc(c.topic) + '</span><span class="five-n">' + (i + 1) + '/5</span></span>'
            + '<span class="five-q" data-fit="26 44"><span>' + esc(c.question) + '</span></span>'
            + '<span class="five-go">Answer it <b aria-hidden="true">&rarr;</b></span>'
            + '</a></li>';
        }).join('');
        const date = $('#five-date');
        if (date) date.textContent = new Intl.DateTimeFormat('en-GB', { weekday: 'long', day: 'numeric', month: 'long' }).format(now);
        const next = $('#five-next');
        if (next) {
          const tick = () => {
            const t = new Date();
            const midnight = new Date(t);
            midnight.setHours(24, 0, 0, 0);
            const ms = midnight - t;
            const h = Math.floor(ms / 3600000), m = Math.floor((ms % 3600000) / 60000);
            next.textContent = ms < 60000 ? 'New five any minute' : 'New five in ' + (h ? h + 'h ' : '') + m + 'm';
          };
          tick();
          setInterval(tick, 30000);
        }
        five.hidden = false;
        scrollRow(fiveRow);
        $$('[data-fit]', fiveRow).forEach(fitQuestion);
        if (still || !('IntersectionObserver' in window)) $$('[data-reveal]', five).forEach(reveal);
      })
      .catch(() => {});
  }

  // Calibration: how sure you said you were, against how often you were
  // right at that number. The numbers are an example, and the page says so;
  // they are no one's measured month.
  const ACC = { 50: 54, 60: 58, 70: 63, 80: 69, 90: 77 };
  const px = x => 64 + (x - 50) / 40 * 432;
  const py = y => 350 - (y - 40) / 60 * 320;
  const track = $('#conf-track');
  const thumb = $('#conf-thumb');
  if (track && thumb) {
    const steps = $$('[data-conf]');
    let conf = +thumb.getAttribute('aria-valuenow') || 70;
    const set = (el, attrs) => Object.entries(attrs).forEach(([k, v]) => el.setAttribute(k, v));
    const touched = () => thumb.classList.remove('hint');
    const show = c => {
      conf = c;
      const acc = ACC[c];
      const left = (c - 50) / 40 * 100 + '%';
      $('#conf-fill').style.width = left;
      thumb.style.left = left;
      set(thumb, { 'aria-valuenow': c, 'aria-valuetext': c + ' per cent sure' });
      steps.forEach(b => b.setAttribute('aria-pressed', String(+b.dataset.conf === c)));
      $('#read-said').textContent = 'You said ' + c + '%.';
      $('#read-rest').textContent = 'You were right ' + acc + '% of the time. ' + (c - acc) + ' points overconfident.';
      const gap = $('#gap-fill');
      if (gap) gap.style.setProperty('--g', c - acc);
      const x = px(c);
      const yc = py(acc);
      const yd = py(c);
      set($('#sel-line'), { x1: x, x2: x, y1: yd, y2: yc });
      set($('#sel-said'), { cx: x, cy: yd });
      set($('#sel-right'), { cx: x, cy: yc });
      const label = $('#sel-label');
      set(label, { x: x, y: yc + 26 });
      label.textContent = acc + '%';
    };
    const fromPointer = e => {
      const r = track.getBoundingClientRect();
      const p = Math.min(1, Math.max(0, (e.clientX - r.left) / r.width));
      const c = 50 + Math.round(p * 4) * 10;
      if (c !== conf) show(c);
    };
    let dragging = false;
    if (!still) thumb.classList.add('hint');
    track.addEventListener('pointerdown', e => {
      dragging = true;
      touched();
      try { track.setPointerCapture(e.pointerId); } catch (err) { /* older browsers */ }
      fromPointer(e);
    });
    track.addEventListener('pointermove', e => { if (dragging) fromPointer(e); });
    ['pointerup', 'pointercancel'].forEach(t => track.addEventListener(t, () => { dragging = false; }));
    thumb.addEventListener('keydown', e => {
      const d = { ArrowLeft: -10, ArrowDown: -10, ArrowRight: 10, ArrowUp: 10, Home: -100, End: 100 }[e.key];
      if (d === undefined) return;
      e.preventDefault();
      touched();
      show(Math.min(90, Math.max(50, conf + d)));
    });
    steps.forEach(b => b.addEventListener('click', () => { touched(); show(+b.dataset.conf); }));
  }

  // The reader's curve draws itself the first time the chart is in view.
  const chart = $('#calibration-chart');
  if (chart) {
    if ('IntersectionObserver' in window) {
      const io = new IntersectionObserver(entries => {
        if (entries.some(e => e.isIntersecting)) { chart.classList.add('seen'); io.disconnect(); }
      }, { threshold: 0.3 });
      io.observe(chart);
    } else {
      chart.classList.add('seen');
    }
  }

  // Cards that flip.
  $$('[data-flip]').forEach(card => {
    const flip = () => card.setAttribute('aria-pressed', String(card.getAttribute('aria-pressed') !== 'true'));
    card.addEventListener('click', e => { if (!e.target.closest('a')) flip(); });
    card.addEventListener('keydown', e => {
      if ((e.key === 'Enter' || e.key === ' ') && !e.target.closest('a')) { e.preventDefault(); flip(); }
    });
  });

  // Astute+: yearly or monthly.
  const plans = $$('[data-plan]');
  const cta = $('#plus-cta');
  plans.forEach(b => b.addEventListener('click', () => {
    plans.forEach(p => p.setAttribute('aria-pressed', String(p === b)));
    if (cta) {
      cta.textContent = b.dataset.plan === 'yearly'
        ? 'Try 14 days free, then €29.99/yr'
        : 'Start monthly · €3.99/mo';
    }
  }));

  // Questions: one open at a time.
  const faqs = $$('[data-faq]');
  faqs.forEach(b => b.addEventListener('click', () => {
    const open = b.getAttribute('aria-expanded') !== 'true';
    faqs.forEach(o => {
      const on = o === b && open;
      o.setAttribute('aria-expanded', String(on));
      o.closest('[data-faq-item]').classList.toggle('open', on);
    });
  }));

  // A long page gets a rail of its sections beside it on a wide screen,
  // from the headings of its first language, with the one being read
  // marked.
  const doc = $('.doc');
  if (doc && 'IntersectionObserver' in window) {
    const first = $('section[lang]', doc) || doc;
    const heads = $$('h2', first);
    if (heads.length > 2) {
      const prefix = first.id ? first.id + '-' : '';
      const toc = document.createElement('nav');
      toc.className = 'toc';
      toc.setAttribute('aria-label', 'On this page');
      const title = document.createElement('p');
      title.textContent = 'On this page';
      toc.appendChild(title);
      const ul = document.createElement('ul');
      const entries = new Map();
      heads.forEach((h, i) => {
        if (!h.id) h.id = prefix + (h.textContent.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || i);
        const li = document.createElement('li');
        const a = document.createElement('a');
        a.href = '#' + h.id;
        a.textContent = h.textContent;
        li.appendChild(a);
        ul.appendChild(li);
        entries.set(h, a);
      });
      toc.appendChild(ul);
      const body = document.createElement('div');
      body.className = 'doc-body';
      while (doc.firstChild) body.appendChild(doc.firstChild);
      doc.appendChild(toc);
      doc.appendChild(body);
      doc.classList.add('has-toc');
      const spy = new IntersectionObserver(es => {
        es.forEach(e => {
          if (!e.isIntersecting) return;
          entries.forEach((a, h) => a.classList.toggle('active', h === e.target));
        });
      }, { rootMargin: '-20% 0px -70% 0px' });
      heads.forEach(h => spy.observe(h));
    }
  }
})();
