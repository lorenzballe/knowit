// astutetheapp.com/account — a reader's Astute on the web: the same account
// as the app, signed in with Apple or Google through the same Firebase
// project; the record from its backup; the plan from RevenueCat; and
// Astute+ bought here through Web Billing, which the app then sees as its
// own, since it identifies readers to RevenueCat by the same uid.
//
// Everything the page needs to know is in keys.js. With either key empty it
// says accounts on the site are not connected yet, and stops there.
import { FIREBASE, REVENUECAT_WEB_KEY } from './keys.js';

const FIREBASE_JS = 'https://www.gstatic.com/firebasejs/12.19.0/';
const PURCHASES_JS = './vendor/purchases-js-1.65.0.es.js';
const ENTITLEMENT = 'astuto_pro'; // kPlusEntitlement, lib/sync/subscription.dart
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // kCodeAlphabet, lib/sync/board.dart
const APP_STORE = 'https://apps.apple.com/app/id6806852300';
const PLAY = 'https://play.google.com/store/apps/details?id=com.astuto.app';

const $ = (s, root = document) => root.querySelector(s);
const $$ = (s, root = document) => Array.from(root.querySelectorAll(s));
const text = (id, value) => { const el = document.getElementById(id); if (el) el.textContent = value; };
const show = id => $$('[data-state]').forEach(s => { s.hidden = s.id !== id; });
const longDate = d => new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'long', year: 'numeric' }).format(d);
const money = (amountMicros, currency) => {
  try { return new Intl.NumberFormat('en-GB', { style: 'currency', currency }).format(amountMicros / 1e6); } catch (e) { return (amountMicros / 1e6).toFixed(2) + ' ' + currency; }
};

// The six letters a friend types: the same hash of the uid the app uses
// (friendCodeOf in lib/sync/board.dart), so the board is at the same address.
function friendCodeOf(uid) {
  let hash = 0x811c9dc5;
  for (let i = 0; i < uid.length; i++) {
    hash ^= uid.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }
  let bits = (hash ^ (hash >>> 30)) >>> 0;
  let out = '';
  for (let i = 0; i < 6; i++) { out += CODE_ALPHABET[bits & 31]; bits >>>= 5; }
  return out;
}

const errorBox = $('#acc-error');
const fail = message => { if (errorBox) { errorBox.textContent = message; errorBox.hidden = false; } };
const clearError = () => { if (errorBox) errorBox.hidden = true; };
const isCancel = e => e && /popup-closed-by-user|cancelled-popup-request|user-cancelled/.test(String(e.code || e.message || ''));

let A, F, auth, db, Purchases, ErrorCode, PurchasesError, purchases = null, current = null, chosen = 'yearly';

async function main() {
  if (!FIREBASE.apiKey || !FIREBASE.appId || !REVENUECAT_WEB_KEY) { show('acc-unconfigured'); return; }
  show('acc-loading');
  try {
    const [app, authMod, fsMod] = await Promise.all([
      import(FIREBASE_JS + 'firebase-app.js'),
      import(FIREBASE_JS + 'firebase-auth.js'),
      import(FIREBASE_JS + 'firebase-firestore.js'),
    ]);
    A = authMod;
    F = fsMod;
    const instance = app.initializeApp(FIREBASE);
    auth = A.getAuth(instance);
    db = F.getFirestore(instance);
  } catch (e) {
    show('acc-out');
    fail('The sign-in service could not be reached. Try again in a moment.');
    return;
  }
  const plan = new URLSearchParams(location.search).get('plan');
  if (plan === 'monthly' || plan === 'yearly') chosen = plan;
  // A sign-in that went through a redirect, when a popup was not allowed,
  // comes back here with its result or its error.
  try { await A.getRedirectResult(auth); } catch (e) { fail(signInMessage(e)); }
  A.onAuthStateChanged(auth, user => {
    current = user;
    if (user) signedIn(user); else show('acc-out');
  });
  $$('[data-sign]').forEach(b => b.addEventListener('click', () => signIn(b.dataset.sign)));
  $('#acc-signout').addEventListener('click', async () => { await A.signOut(auth); });
  $('#acc-delete').addEventListener('click', deleteAccount);
  $('#plan-refresh').addEventListener('click', () => renderPlan(current, true));
  $$('[data-plan]').forEach(b => b.addEventListener('click', () => pick(b.dataset.plan)));
  $('#plan-cta').addEventListener('click', buy);
}

function providerFor(kind) {
  if (kind === 'google') {
    const p = new A.GoogleAuthProvider();
    p.setCustomParameters({ prompt: 'select_account' });
    return p;
  }
  const p = new A.OAuthProvider('apple.com');
  p.addScope('email');
  p.addScope('name');
  return p;
}

function signInMessage(e) {
  const code = String((e && e.code) || '');
  if (code.includes('account-exists-with-different-credential')) return 'This email is already signed in another way. Use the same button you used in the app.';
  if (code.includes('unauthorized-domain') || code.includes('operation-not-allowed')) return 'Signing in on the site is not set up yet.';
  if (code.includes('network-request-failed')) return 'No connection. Try again in a moment.';
  return 'Signing in did not go through. Try again.';
}

async function signIn(kind) {
  clearError();
  const buttons = $$('[data-sign]');
  buttons.forEach(b => { b.disabled = true; });
  try {
    await A.signInWithPopup(auth, providerFor(kind));
  } catch (e) {
    if (isCancel(e)) return;
    if (String(e.code || '').includes('popup-blocked')) {
      try { await A.signInWithRedirect(auth, providerFor(kind)); return; } catch (e2) { fail(signInMessage(e2)); return; }
    }
    fail(signInMessage(e));
  } finally {
    buttons.forEach(b => { b.disabled = false; });
  }
}

async function signedIn(user) {
  clearError();
  show('acc-in');
  const via = (user.providerData[0] || {}).providerId === 'google.com' ? 'Google' : 'Apple';
  text('acc-name', user.displayName || 'Your Astute');
  text('acc-who', (user.email ? user.email + ' · ' : '') + 'signed in with ' + via);
  $('#acc-flash').hidden = true;
  await Promise.all([renderRecord(user), renderPlan(user, false)]);
}

// The record, from the backup the app keeps at readers/{uid}, and the gap
// from the board it publishes for friends.
async function renderRecord(user) {
  const uid = user.uid;
  const code = friendCodeOf(uid);
  let reader = null, board = null;
  try {
    const [r, b] = await Promise.all([
      F.getDoc(F.doc(db, 'readers', uid)),
      F.getDoc(F.doc(db, 'boards', code)),
    ]);
    reader = r.exists() ? r.data() : null;
    board = b.exists() ? b.data() : null;
  } catch (e) {
    reader = null;
  }
  const n = v => (typeof v === 'number' ? v : 0);
  const days = Array.isArray(reader && reader.completedDates) ? reader.completedDates.length : 0;
  text('st-streak', String(n(reader && reader.streak)));
  text('st-best', String(n(reader && reader.bestStreak)));
  text('st-days', String(days));
  text('st-read', String(n(reader && reader.pillsRead)));
  const gap = board && typeof board.gap === 'number' ? Math.round(board.gap) : null;
  text('st-gap', gap === null ? '–' : (gap > 0 ? '+' : gap < 0 ? '−' : '') + Math.abs(gap));
  if (reader && reader.name && !user.displayName) text('acc-name', reader.name);
  const note = $('#acc-record-note');
  if (reader) {
    note.innerHTML = 'Your friend code is <b class="code">' + code + '</b>. Friends type it in the app to see your board.';
  } else {
    note.textContent = 'No record here yet. On your phone, sign in to Astute with this same account and it is kept here from then on.';
  }
}

// The plan, from RevenueCat: the same customer the app talks to, so a
// subscription from either store shows here, and one bought here shows
// there. The store module is only started once the page has someone to
// start it for.
async function renderPlan(user, fresh) {
  const card = $('#acc-plan');
  card.classList.add('busy');
  try {
    if (!Purchases) {
      const mod = await import(PURCHASES_JS);
      Purchases = mod.Purchases;
      ErrorCode = mod.ErrorCode;
      PurchasesError = mod.PurchasesError;
    }
    if (Purchases.isConfigured()) {
      purchases = Purchases.getSharedInstance();
      if (purchases.getAppUserId() !== user.uid) await purchases.changeUser(user.uid);
    } else {
      purchases = Purchases.configure({ apiKey: REVENUECAT_WEB_KEY, appUserId: user.uid });
    }
    $('#acc-test').hidden = !purchases.isSandbox();
    const info = await purchases.getCustomerInfo();
    showPlan(info);
    if (fresh) flash('Your plan was read again just now.');
  } catch (e) {
    text('plan-status', 'Unknown');
    $('#plan-note').textContent = 'Your plan could not be read. Try again in a moment.';
    $('#plan-buy').hidden = true;
    $('#plan-actions').hidden = true;
  } finally {
    card.classList.remove('busy');
  }
}

const STORE_NAMES = { app_store: 'the App Store', mac_app_store: 'the App Store', play_store: 'Google Play', rc_billing: 'this site', stripe: 'this site', promotional: 'a gift', amazon: 'Amazon' };

function showPlan(info) {
  const ent = info.entitlements.active[ENTITLEMENT];
  const status = $('#plan-status');
  const note = $('#plan-note');
  const manage = $('#plan-manage');
  if (ent) {
    status.innerHTML = '<span>Astute<span class="plus-sign">+</span></span>' + (ent.periodType === 'trial' ? '<span class="badge soft">Free week</span>' : '');
    const where = STORE_NAMES[ent.store] || 'a store';
    const when = ent.expirationDate ? (ent.willRenew ? 'Renews on ' : 'Ends on ') + longDate(ent.expirationDate) + '. ' : '';
    note.textContent = when + 'Bought on ' + where + '. All five cards are yours, on every phone signed in with this account.';
    $('#plan-buy').hidden = true;
    $('#plan-actions').hidden = false;
    if (ent.store === 'app_store' || ent.store === 'mac_app_store') {
      manage.hidden = false; manage.href = 'https://apps.apple.com/account/subscriptions'; manage.textContent = 'Manage on the App Store';
    } else if (ent.store === 'play_store') {
      manage.hidden = false; manage.href = 'https://play.google.com/store/account/subscriptions'; manage.textContent = 'Manage on Google Play';
    } else if (info.managementURL) {
      manage.hidden = false; manage.href = info.managementURL; manage.textContent = 'Manage subscription';
    } else {
      manage.hidden = true;
    }
  } else {
    status.textContent = 'Free';
    note.textContent = 'Astute is free every morning. Astute+ makes all five cards yours, on every phone signed in with this account.';
    $('#plan-actions').hidden = false;
    manage.hidden = true;
    offer();
  }
}

// What Web Billing has on sale, priced as it priced it, on the two tiles.
let offering = null;
async function offer() {
  const buy = $('#plan-buy');
  try {
    const offerings = await purchases.getOfferings();
    offering = offerings.current;
    if (!offering || (!offering.annual && !offering.monthly)) throw new Error('nothing on sale');
  } catch (e) {
    buy.hidden = true;
    $('#plan-note').textContent += ' Nothing is on sale here yet: Astute+ is in the app, from its store.';
    return;
  }
  const tile = (pkg, id) => {
    const el = $('[data-plan="' + id + '"]');
    if (!pkg) { el.hidden = true; return; }
    el.hidden = false;
    const p = pkg.webBillingProduct;
    $('.amount b', el).textContent = p.currentPrice.formattedPrice;
    const trial = p.freeTrialPhase;
    const per = $('.per', el);
    if (id === 'yearly') {
      per.textContent = money(p.currentPrice.amountMicros / 12, p.currentPrice.currency) + ' a month' + (trial ? ' · ' + trialText(trial) + ' free' : '');
    } else {
      per.textContent = trial ? trialText(trial) + ' free, then monthly' : 'billed monthly';
    }
  };
  tile(offering.annual, 'yearly');
  tile(offering.monthly, 'monthly');
  if (chosen === 'yearly' && !offering.annual) chosen = 'monthly';
  if (chosen === 'monthly' && !offering.monthly) chosen = 'yearly';
  pick(chosen);
  buy.hidden = false;
}

function trialText(phase) {
  const p = phase.period;
  if (!p) return 'a while';
  const n = p.number, u = p.unit;
  if (u === 'week' && n === 1) return '7 days';
  return n + ' ' + u + (n === 1 ? '' : 's');
}

function pick(id) {
  chosen = id;
  $$('[data-plan]').forEach(b => b.setAttribute('aria-pressed', String(b.dataset.plan === id)));
  const pkg = offering && (id === 'yearly' ? offering.annual : offering.monthly);
  const cta = $('#plan-cta');
  if (!pkg) { cta.disabled = true; cta.textContent = 'Not on sale'; return; }
  cta.disabled = false;
  const p = pkg.webBillingProduct;
  const price = p.currentPrice.formattedPrice + (id === 'yearly' ? '/yr' : '/mo');
  cta.textContent = p.freeTrialPhase
    ? 'Try ' + trialText(p.freeTrialPhase) + ' free, then ' + price
    : 'Start ' + id + ' · ' + price;
}

// The purchase itself is RevenueCat's sheet, over this page, charging
// through Stripe; what comes back is the customer as they now are.
async function buy() {
  const pkg = offering && (chosen === 'yearly' ? offering.annual : offering.monthly);
  if (!pkg || !current) return;
  const cta = $('#plan-cta');
  cta.disabled = true;
  try {
    const result = await purchases.purchase({ rcPackage: pkg, customerEmail: current.email || undefined });
    showPlan(result.customerInfo);
    flash('Astute+ is on. Open Astute on your phone: from the next edition, all five cards are yours.');
  } catch (e) {
    if (PurchasesError && e instanceof PurchasesError && e.errorCode === ErrorCode.UserCancelledError) return;
    flash('The purchase did not go through. Nothing was charged. Try again in a moment.');
  } finally {
    cta.disabled = false;
  }
}

function flash(message) {
  const el = $('#acc-flash');
  el.textContent = message;
  el.hidden = false;
}

// Deleting: a fresh sign-in first, since Firebase deletes a sign-in only on
// a fresh session and, for Apple, the fresh authorisation is what revokes
// the app's access to the Apple ID; then the backup and the board; then the
// account. As in the app, an Astute+ subscription is not cancelled by this.
async function deleteAccount() {
  const user = current;
  if (!user) return;
  if (!window.confirm('Delete your account, its backup and your board for friends? The app on your phone starts again from the beginning. This cannot be undone.')) return;
  const button = $('#acc-delete');
  button.disabled = true;
  clearError();
  try {
    const kind = (user.providerData[0] || {}).providerId === 'google.com' ? 'google' : 'apple';
    const provider = providerFor(kind);
    let result;
    try {
      result = await A.reauthenticateWithPopup(user, provider);
    } catch (e) {
      if (!isCancel(e)) fail('Signing in again did not go through, so nothing was deleted.');
      return;
    }
    if (kind === 'apple') {
      try {
        const credential = A.OAuthProvider.credentialFromResult(result);
        if (credential && credential.accessToken) await A.revokeAccessToken(auth, credential.accessToken);
      } catch (e) { /* the account is deleted without it */ }
    }
    const uid = user.uid;
    try { await F.deleteDoc(F.doc(db, 'readers', uid)); } catch (e) { /* no backup, or none we may delete */ }
    const board = F.doc(db, 'boards', friendCodeOf(uid));
    try { await F.deleteDoc(board); } catch (e) { try { await F.setDoc(board, { uid }); } catch (e2) { /* emptied as far as the rules allow */ } }
    await A.deleteUser(user);
    show('acc-done');
  } catch (e) {
    fail('The account could not be deleted. Try again, or write to thebalecompany@gmail.com.');
  } finally {
    button.disabled = false;
  }
}

main();
