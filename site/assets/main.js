// astutetheapp.com — the few things on the site that move, without a
// framework. Every page reads without it; this adds the menu, the nav that
// frosts and its progress line, things coming into view, the numbers that
// count up, the light that follows the pointer across a card, the phone that
// turns and reveals, today's question and the time to the next one, the
// rows that scroll, the calibration chart, the cards that flip, the plan
// picker, the questions that open, and the rail beside a long page.
(() => {
  const $ = (s, root = document) => root.querySelector(s);
  const $$ = (s, root = document) => Array.from(root.querySelectorAll(s));
  const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const finePointer = window.matchMedia('(hover: hover) and (pointer: fine)').matches;
  const onChange = (mq, fn) => (mq.addEventListener ? mq.addEventListener('change', fn) : mq.addListener(fn));

  // Download links go to Google Play on Android and the App Store on an
  // iPhone or iPad; on a computer they go to the QR code at the foot of the
  // landing page, to be scanned with the phone.
  const PLAY = 'https://play.google.com/store/apps/details?id=com.astuto.app';
  const ua = navigator.userAgent;
  const android = /android/i.test(ua);
  const ios = /iphone|ipad|ipod/i.test(ua) || (/macintosh/i.test(ua) && navigator.maxTouchPoints > 1);
  $$('[data-store]').forEach(a => {
    if (android) a.href = PLAY;
    else if (!ios) a.href = '/#download';
  });

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
  // the fanned cards drift with the scroll, and tapping it turns the card
  // over, as in the app.
  const phone = $('#hero-phone');
  const hero = phone && phone.closest('section');
  if (phone && hero && finePointer && !still) {
    let tx = 0, ty = 0, x = 0, y = 0, running = false;
    const step = () => {
      x += (tx - x) * 0.08;
      y += (ty - y) * 0.08;
      phone.style.setProperty('--ry', x.toFixed(2) + 'deg');
      phone.style.setProperty('--rx', y.toFixed(2) + 'deg');
      if (Math.abs(tx - x) > 0.01 || Math.abs(ty - y) > 0.01) requestAnimationFrame(step);
      else running = false;
    };
    const go = () => { if (!running) { running = true; requestAnimationFrame(step); } };
    hero.addEventListener('pointermove', e => {
      const r = hero.getBoundingClientRect();
      tx = ((e.clientX - r.left) / r.width - 0.5) * 12;
      ty = -((e.clientY - r.top) / r.height - 0.5) * 8;
      go();
    });
    hero.addEventListener('pointerleave', () => { tx = 0; ty = 0; go(); });
  }
  const fan = $('.fan');
  if (fan && hero && !still) {
    let queued = false;
    const drift = () => {
      queued = false;
      const y = window.scrollY;
      if (y < hero.offsetHeight) fan.style.transform = 'translate3d(0,' + (y * 0.09).toFixed(1) + 'px,0)';
    };
    window.addEventListener('scroll', () => { if (!queued) { queued = true; requestAnimationFrame(drift); } }, { passive: true });
  }
  const screen = $('[data-phone]');
  if (screen) {
    const hint = $('.phone-hint');
    const turn = () => {
      screen.setAttribute('aria-pressed', String(screen.getAttribute('aria-pressed') !== 'true'));
      if (hint) hint.classList.add('gone');
    };
    screen.addEventListener('click', turn);
    screen.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); turn(); }
    });
  }

  // Today's question, from the same file the home-screen widget reads, and
  // the time until tomorrow's: the day turns at midnight, the phone's.
  const today = $('#today');
  if (today && window.fetch) {
    fetch('/widget/days.json', { cache: 'no-cache' })
      .then(r => (r.ok ? r.json() : null))
      .then(data => {
        const now = new Date();
        const key = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0');
        const day = data && data.days && data.days[key];
        if (!day || !day.question) return;
        if (/^#[0-9a-f]{6}$/i.test(day.color)) today.style.setProperty('--bg', day.color);
        if (/^#[0-9a-f]{6}$/i.test(day.ink)) today.style.setProperty('--ink', day.ink);
        $('#today-topic').textContent = day.topic || '';
        $('#today-question').textContent = day.question;
        $('#today-edition').textContent = day.edition ? 'Edition ' + day.edition : '';
        $('#today-date').textContent = new Intl.DateTimeFormat('en-GB', { weekday: 'long', day: 'numeric', month: 'long' }).format(now);
        const kicker = $('#hero-kicker');
        if (kicker && day.edition) kicker.textContent = 'Edition ' + day.edition + ' · out this morning';
        const next = $('#today-next');
        if (next) {
          const tick = () => {
            const t = new Date();
            const midnight = new Date(t);
            midnight.setHours(24, 0, 0, 0);
            const ms = midnight - t;
            const h = Math.floor(ms / 3600000), m = Math.floor((ms % 3600000) / 60000);
            next.textContent = ms < 60000 ? 'Next edition any minute' : 'Next edition in ' + (h ? h + 'h ' : '') + m + 'm';
          };
          tick();
          setInterval(tick, 30000);
        }
        today.hidden = false;
      })
      .catch(() => {});
  }

  // A row that scrolls sideways: arrows on a wide screen, soft edges where
  // there is more, dots that say where in it the reader is, and dragging
  // with a mouse.
  $$('[data-scroll-row]').forEach(row => {
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
      if (prev) prev.disabled = row.scrollLeft <= 4;
      if (next) next.disabled = row.scrollLeft >= max - 4;
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
  });

  // Calibration: how sure you said you were, against how often a typical
  // first month was right at that number.
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
        ? 'Try 7 days free, then €29.99/yr'
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
