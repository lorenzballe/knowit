// astutetheapp.com — the few things on the site that move, without a
// framework. Every page works without it; this adds the menu, the frosted
// nav and its progress line, things coming into view, the phone that turns
// and reveals, today's question, the day's row, the calibration chart, the
// cards that flip, the plan picker and the questions that open.
(() => {
  const $ = (s, root = document) => root.querySelector(s);
  const $$ = (s, root = document) => Array.from(root.querySelectorAll(s));
  const still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const finePointer = window.matchMedia('(hover: hover) and (pointer: fine)').matches;

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

  // The nav frosts once the page has moved; a line along its top shows how
  // far down the page is.
  const nav = $('.site-nav');
  const progress = $('.progress');
  if (nav) {
    let queued = false;
    const onScroll = () => {
      queued = false;
      nav.classList.toggle('scrolled', window.scrollY > 16);
      if (progress) {
        const max = document.documentElement.scrollHeight - window.innerHeight;
        progress.style.setProperty('--p', max > 0 ? Math.min(1, window.scrollY / max).toFixed(4) : 0);
      }
    };
    window.addEventListener('scroll', () => { if (!queued) { queued = true; requestAnimationFrame(onScroll); } }, { passive: true });
    onScroll();
  }

  // The menu on a phone.
  const toggle = $('#menu-toggle');
  const menu = $('#mobile-menu');
  if (toggle && menu) {
    $$('a', menu).forEach((a, i) => a.style.setProperty('--i', i));
    const show = open => {
      menu.hidden = !open;
      toggle.setAttribute('aria-expanded', String(open));
      toggle.textContent = open ? 'Close' : 'Menu';
    };
    toggle.addEventListener('click', () => show(menu.hidden));
    $$('a', menu).forEach(a => a.addEventListener('click', () => show(false)));
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

  // Today's question, from the same file the home-screen widget reads.
  const today = $('#today');
  if (today && window.fetch) {
    fetch('/widget/days.json', { cache: 'no-cache' })
      .then(r => (r.ok ? r.json() : null))
      .then(data => {
        const now = new Date();
        const key = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0');
        const day = data && data.days && data.days[key];
        if (!day || !day.question) return;
        const card = $('#today-card');
        if (/^#[0-9a-f]{6}$/i.test(day.color)) card.style.setProperty('--bg', day.color);
        if (/^#[0-9a-f]{6}$/i.test(day.ink)) card.style.setProperty('--ink', day.ink);
        $('#today-topic').textContent = day.topic || '';
        $('#today-question').textContent = day.question;
        $('#today-edition').textContent = day.edition ? 'Edition ' + day.edition : '';
        $('#today-date').textContent = new Intl.DateTimeFormat('en-GB', { weekday: 'long', day: 'numeric', month: 'long' }).format(now);
        today.hidden = false;
      })
      .catch(() => {});
  }

  // The day's row: arrows on a wide screen, soft edges where there is more,
  // and dragging with a mouse.
  const row = $('#day-row');
  if (row) {
    const prev = $('[data-row="prev"]');
    const next = $('[data-row="next"]');
    const edges = () => {
      const max = row.scrollWidth - row.clientWidth;
      row.style.setProperty('--fl', row.scrollLeft > 4 ? '56px' : '0px');
      row.style.setProperty('--fr', row.scrollLeft < max - 4 ? '56px' : '0px');
      if (prev) prev.disabled = row.scrollLeft <= 4;
      if (next) next.disabled = row.scrollLeft >= max - 4;
    };
    const stepBy = dir => {
      const card = row.querySelector('article');
      const gap = parseFloat(getComputedStyle(row).columnGap) || 16;
      row.scrollBy({ left: dir * ((card ? card.offsetWidth : 272) + gap), behavior: still ? 'auto' : 'smooth' });
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
  }

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
      steps.forEach(b => {
        const on = +b.dataset.conf === c;
        b.setAttribute('aria-pressed', String(on));
        b.style.background = on ? '#141416' : 'rgba(20,20,22,.06)';
        b.style.color = on ? '#F2F1EC' : '#141416';
      });
      $('#read-said').textContent = 'You said ' + c + '%.';
      $('#read-rest').textContent = 'You were right ' + acc + '% of the time. ' + (c - acc) + ' points overconfident.';
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
    const inner = card.firstElementChild;
    const flip = () => {
      const on = card.getAttribute('aria-pressed') !== 'true';
      card.setAttribute('aria-pressed', String(on));
      inner.style.transform = on ? 'rotateY(180deg)' : 'rotateY(0deg)';
    };
    card.addEventListener('click', e => { if (!e.target.closest('a')) flip(); });
    card.addEventListener('keydown', e => {
      if ((e.key === 'Enter' || e.key === ' ') && !e.target.closest('a')) { e.preventDefault(); flip(); }
    });
  });

  // Astute+: yearly or monthly.
  const plans = $$('[data-plan]');
  const cta = $('#plus-cta');
  plans.forEach(b => b.addEventListener('click', () => {
    plans.forEach(p => {
      const on = p === b;
      const dot = $('[data-dot]', p);
      p.setAttribute('aria-pressed', String(on));
      p.style.borderColor = on ? '#F2F1EC' : 'rgba(242,241,236,.14)';
      dot.style.background = on ? '#F2F1EC' : 'transparent';
      dot.style.borderColor = on ? '#F2F1EC' : 'rgba(242,241,236,.35)';
      dot.textContent = on ? '✓' : '';
    });
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
})();
