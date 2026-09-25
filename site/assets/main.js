// astutetheapp.com — the few things on the site that move, without a
// framework. Every page works without it; this only adds the menu, the
// frosted nav, the calibration chart, the cards that flip, the plan picker
// and the questions that open.
(() => {
  const $ = (s, root = document) => root.querySelector(s);
  const $$ = (s, root = document) => Array.from(root.querySelectorAll(s));

  // Download links go to Google Play on Android, to the App Store elsewhere.
  const PLAY = 'https://play.google.com/store/apps/details?id=com.astuto.app';
  if (/android/i.test(navigator.userAgent)) {
    $$('[data-store]').forEach(a => { a.href = PLAY; });
  }

  // The nav frosts once the page has moved.
  const nav = $('.site-nav');
  if (nav) {
    const onScroll = () => nav.classList.toggle('scrolled', window.scrollY > 16);
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
  }

  // The menu on a phone.
  const toggle = $('#menu-toggle');
  const menu = $('#mobile-menu');
  if (toggle && menu) {
    const show = open => {
      menu.hidden = !open;
      toggle.setAttribute('aria-expanded', String(open));
      toggle.textContent = open ? 'Close' : 'Menu';
    };
    toggle.addEventListener('click', () => show(menu.hidden));
    $$('a', menu).forEach(a => a.addEventListener('click', () => show(false)));
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
    track.addEventListener('pointerdown', e => {
      dragging = true;
      try { track.setPointerCapture(e.pointerId); } catch (err) { /* older browsers */ }
      fromPointer(e);
    });
    track.addEventListener('pointermove', e => { if (dragging) fromPointer(e); });
    ['pointerup', 'pointercancel'].forEach(t => track.addEventListener(t, () => { dragging = false; }));
    thumb.addEventListener('keydown', e => {
      const d = { ArrowLeft: -10, ArrowDown: -10, ArrowRight: 10, ArrowUp: 10, Home: -100, End: 100 }[e.key];
      if (d === undefined) return;
      e.preventDefault();
      show(Math.min(90, Math.max(50, conf + d)));
    });
    steps.forEach(b => b.addEventListener('click', () => show(+b.dataset.conf)));
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
    card.addEventListener('click', flip);
    card.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); flip(); }
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
