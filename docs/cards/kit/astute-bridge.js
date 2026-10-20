// The app's side of a free card: window.Astute, what the page may say to the app and what the app
// says to it. The app puts this file at the top of every card page, after one line that sets
// window.ASTUTE_ENV, before the kit and any library (lib/widgets/web/card_kit.dart); the checker
// does the same with a stand-in for the app (tool/cards/card_check.cjs). A card never calls it by
// hand: astute-card.js does, through Kit.answer, Kit.flip, Kit.done, Kit.haptic and Kit.open.
//
// Page to app, one JSON object a message:
//   {t:'ready'}                                the first frame is drawn: the poster can go
//   {t:'answer', choice, correct, sure}        what the reader committed to, recorded like a native answer
//   {t:'flip'}  {t:'tap'}                      turn the card over: asked for, or a tap the page left alone
//   {t:'done'}                                 send the card on, as a throw would
//   {t:'haptic', kind}                         light, medium, heavy, selection, success, warning, error
//   {t:'open', url}                            a link, opened outside the app
//   {t:'zones', rects}                         where the page wants every touch, [[x, y, w, h], ...]
//   {t:'pan', phase, dx, dy, vx, vy}           on the web build only: a drag that is the deck's, not the page's
//   {t:'error', message}                       something on the page broke
// App to page: {t:'env', env} when something about the reader changes (theme, language, reduced
// motion, sound, size), {t:'show'} when the card comes in front of the reader, {t:'hide'} when it goes.
(() => {
  if (window.Astute) return;
  const env = Object.assign({mode: 'app', theme: 'dark', lang: 'en', calm: false, sound: false, touch: 'taps', platform: 'ios',
    shown: false, size: {w: innerWidth, h: innerHeight}, safe: {top: 0, right: 0, bottom: 0, left: 0}, corner: null}, window.ASTUTE_ENV || {});
  const listeners = [];

  // Out: a channel on a phone (webview_flutter's JavaScriptChannel), the parent window on the web
  // build, whatever the checker hands in when it stands in for the app.
  function send(msg) {
    const text = JSON.stringify(msg);
    try {
      if (typeof window.ASTUTE_SEND === 'function') return window.ASTUTE_SEND(text);
      if (window.AstuteBridge && typeof window.AstuteBridge.postMessage === 'function') return window.AstuteBridge.postMessage(text);
      if (window.parent && window.parent !== window) window.parent.postMessage({astute: text}, '*');
    } catch (e) { /* an app that has gone away has nothing to hear */ }
  }
  // In: runJavaScript on a phone, postMessage from the parent window on the web build.
  function receive(msg) {
    if (!msg || typeof msg !== 'object') return;
    if (msg.t === 'env' && msg.env && typeof msg.env === 'object') { Object.assign(env, msg.env); media.forEach(m => m.update()); }
    if (msg.t === 'show') env.shown = true;
    if (msg.t === 'hide') env.shown = false;
    listeners.slice().forEach(fn => { try { fn(msg); } catch (e) { report(e); } });
  }
  addEventListener('message', e => { if (e.source === window.parent && e.data && typeof e.data.astuteApp === 'string') { try { receive(JSON.parse(e.data.astuteApp)); } catch (err) { report(err); } } });

  // The reader's settings answer the page's own questions: a card written for a browser asks
  // matchMedia whether motion is reduced, and here the app's answer is the one it gets.
  const media = [], ownMatch = window.matchMedia ? window.matchMedia.bind(window) : null;
  const ANSWERS = [
    [/prefers-reduced-motion\s*:\s*reduce/, () => !!env.calm], [/prefers-reduced-motion\s*:\s*no-preference/, () => !env.calm],
    [/prefers-color-scheme\s*:\s*dark/, () => env.theme === 'dark'], [/prefers-color-scheme\s*:\s*light/, () => env.theme !== 'dark']
  ];
  window.matchMedia = query => {
    const known = ANSWERS.find(([re]) => re.test(String(query)));
    if (!known && ownMatch) return ownMatch(query);
    const fns = new Set(), list = {media: String(query), matches: known ? known[1]() : false, onchange: null,
      addListener: fn => fns.add(fn), removeListener: fn => fns.delete(fn),
      addEventListener: (type, fn) => type === 'change' && fns.add(fn), removeEventListener: (type, fn) => fns.delete(fn), dispatchEvent: () => true,
      update() { const now = known ? known[1]() : false; if (now === list.matches) return; list.matches = now; const ev = {matches: now, media: list.media}; list.onchange?.(ev); fns.forEach(fn => fn(ev)); }};
    media.push(list); return list;
  };

  // Nothing leaves the card. A link opens outside the app; nothing else navigates.
  document.addEventListener('click', e => {
    const a = e.target && e.target.closest ? e.target.closest('a[href]') : null;
    if (!a) return;
    const href = a.getAttribute('href') || '';
    if (href.startsWith('#')) return;
    e.preventDefault();
    if (/^https?:\/\//i.test(a.href)) send({t: 'open', url: a.href});
  }, true);
  window.open = url => { if (url && /^https?:\/\//i.test(String(url))) send({t: 'open', url: String(url)}); return null; };

  // What broke, once each, so a card that fails on some phone is known about.
  const said = new Set();
  function report(e) { const m = String((e && (e.message || e.reason)) || e).slice(0, 300); if (said.has(m) || said.size > 20) return; said.add(m); send({t: 'error', message: m}); }
  addEventListener('error', e => report(e.error || e.message));
  addEventListener('unhandledrejection', e => report(e.reason));

  // requestAnimationFrame, held while the card is not in front of the reader (see Kit's clock).
  const frame = window.requestAnimationFrame.bind(window), unframe = window.cancelAnimationFrame.bind(window);
  const held = []; let holding = false, heldId = 0;
  window.requestAnimationFrame = fn => { if (!holding) return frame(fn); const id = -(++heldId); held.push([id, fn]); return id; };
  window.cancelAnimationFrame = id => { if (id < 0) { const i = held.findIndex(h => h[0] === id); if (i >= 0) held.splice(i, 1); } else unframe(id); };

  window.Astute = {
    env, send, receive, frame,
    on: fn => listeners.push(fn),
    ready: () => send({t: 'ready'}),
    answer: a => send({t: 'answer', choice: String(a.choice ?? ''), correct: typeof a.correct === 'boolean' ? a.correct : null, sure: typeof a.sure === 'number' ? Math.round(a.sure) : null}),
    flip: () => send({t: 'flip'}),
    tap: () => send({t: 'tap'}),
    done: () => send({t: 'done'}),
    haptic: kind => send({t: 'haptic', kind: String(kind || 'light')}),
    open: url => send({t: 'open', url: String(url)}),
    zones: rects => send({t: 'zones', rects}),
    hold: () => { holding = true; },
    release: () => { if (!holding) return; holding = false; const queued = held.splice(0); if (queued.length) frame(t => queued.forEach(([, fn]) => { try { fn(t); } catch (e) { report(e); } })); }
  };
})();
