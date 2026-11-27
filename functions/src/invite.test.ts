// Invita un amico (invite.ts), without a project: the code, the rules a
// code is used by, the weeks and where each starts, the cap, RevenueCat
// asked as its API v1 says (a fetch that records), and nothing asked at all
// when there is no key. Firestore is a map here, with the few calls
// invite.ts makes; invite.emulator.test.ts runs the same against the
// emulator.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { Firestore } from 'firebase-admin/firestore';

import {
  CODE_ALPHABET,
  CODE_LENGTH,
  ENTITLEMENT,
  Held,
  NEW_FOR_DAYS,
  Reader,
  RevenueCatError,
  Store,
  WEEK_MS,
  WEEKS_A_YEAR,
  YEAR_MS,
  configured,
  forgetInvites,
  giveCode,
  heldOf,
  inviteState,
  makeCode,
  planWeeks,
  readCode,
  redeem,
  refusal,
  revenueCat,
  settle,
  storeFor,
} from './invite.js';

const DAY = 86_400_000;
const NOW = Date.parse('2026-11-27T18:00:00Z');

// ── Firestore, as a map ──────────────────────────────────────────────────

type Data = Record<string, unknown>;

class Snap {
  constructor(private readonly value: Data | undefined) {}
  get exists(): boolean {
    return this.value !== undefined;
  }
  data(): Data | undefined {
    return this.value === undefined ? undefined : structuredClone(this.value);
  }
  get(field: string): unknown {
    return this.value?.[field];
  }
}

class Ref {
  constructor(
    private readonly db: MemoryDb,
    readonly path: string,
  ) {}
  async get(): Promise<Snap> {
    return new Snap(this.db.docs.get(this.path));
  }
  async set(data: Data, opts?: { merge?: boolean }): Promise<void> {
    this.db.write(this.path, data, opts?.merge === true);
  }
}

class MemoryDb {
  readonly docs = new Map<string, Data>();
  collection(name: string) {
    return { doc: (id: string) => new Ref(this, `${name}/${id}`) };
  }
  write(path: string, data: Data, merge: boolean): void {
    const before = merge ? (this.docs.get(path) ?? {}) : {};
    this.docs.set(path, structuredClone({ ...before, ...data }));
  }
  async runTransaction<T>(fn: (t: unknown) => Promise<T>): Promise<T> {
    const writes: (() => void)[] = [];
    let wrote = false;
    const t = {
      get: async (ref: Ref) => {
        assert.ok(!wrote, 'a transaction reads before it writes');
        return ref.get();
      },
      set: (ref: Ref, data: Data, opts?: { merge?: boolean }) => {
        wrote = true;
        writes.push(() => this.write(ref.path, data, opts?.merge === true));
      },
    };
    const out = await fn(t);
    for (const w of writes) w();
    return out;
  }
  batch() {
    const gone: string[] = [];
    return {
      delete: (ref: Ref) => gone.push(ref.path),
      commit: async () => gone.forEach((p) => this.docs.delete(p)),
    };
  }
  doc(path: string): Data | undefined {
    return this.docs.get(path);
  }
}

// ── RevenueCat, as a ledger ──────────────────────────────────────────────

const NEVER: Held = { ever: false, until: null, lifetime: false };

class FakeStore implements Store {
  readonly held_ = new Map<string, Held>();
  readonly grants: [string, number][] = [];
  fail = 0;
  asked = 0;
  async held(uid: string): Promise<Held> {
    this.asked++;
    return this.held_.get(uid) ?? NEVER;
  }
  async grant(uid: string, untilMs: number): Promise<void> {
    if (this.fail > 0) {
      this.fail--;
      throw new RevenueCatError(503, 'down');
    }
    this.grants.push([uid, untilMs]);
    // RevenueCat itself: an end within two hours of the one running is the same.
    const had = this.held_.get(uid);
    if (had?.until && Math.abs(had.until - untilMs) < 2 * 3_600_000) return;
    this.held_.set(uid, { ever: true, until: Math.max(untilMs, had?.until ?? 0), lifetime: false });
  }
}

/** Readers whose account was made [age] ago, and who have finished a day when [readDays] has them. */
function readers(age: Record<string, number>, readDays: Set<string>): Reader {
  return {
    madeAt: async (uid) => (uid in age ? NOW - age[uid] : null),
    readADay: async (uid) => readDays.has(uid),
  };
}

function world() {
  const db = new MemoryDb();
  const store = new FakeStore();
  const days = new Set<string>();
  const reader = readers({ ana: 300 * DAY, ben: 2 * DAY, cyd: 1 * DAY, dan: 40 * DAY }, days);
  return { db, fs: db as unknown as Firestore, store, days, reader };
}

// ── The code ─────────────────────────────────────────────────────────────

test('a code is six characters with no vowel, and nothing that reads as another', () => {
  assert.equal(CODE_LENGTH, 6);
  for (const ch of 'AEIOU01L') assert.ok(!CODE_ALPHABET.includes(ch), ch);
  assert.equal(new Set(CODE_ALPHABET).size, CODE_ALPHABET.length);
  for (let i = 0; i < 200; i++) {
    const code = makeCode();
    assert.match(code, /^[23456789BCDFGHJKMNPQRSTVWXYZ]{6}$/);
    assert.equal(readCode(code), code);
  }
  // Drawn evenly from the whole alphabet.
  const seen = new Set<string>();
  let k = 0;
  for (let i = 0; i < 10; i++) for (const ch of makeCode(() => k++ % CODE_ALPHABET.length)) seen.add(ch);
  assert.equal(seen.size, CODE_ALPHABET.length);
});

test('a code is read as a reader types it: any case, with spaces or dashes, and nothing else', () => {
  assert.equal(readCode('K7MQ2P'), 'K7MQ2P');
  assert.equal(readCode(' k7m-q2p '), 'K7MQ2P');
  assert.equal(readCode('k7m q2p'), 'K7MQ2P');
  for (const bad of ['K7MQ2', 'K7MQ2PP', 'K7MQ2O', 'A7MQ2P', 'K1MQ2P', '', 'K7MQ2P!', 7, null, undefined, 'x'.repeat(100)]) {
    assert.equal(readCode(bad), null, String(bad));
  }
});

test("a reader's code is made once, however often it is asked for", async () => {
  const { fs, db } = world();
  const one = await giveCode(fs, 'ana', NOW);
  const two = await giveCode(fs, 'ana', NOW + 1000);
  assert.equal(one.code, two.code);
  assert.deepEqual(db.doc(`inviteCodes/${one.code}`), { uid: 'ana', at: NOW });
  assert.equal(db.doc('invites/ana')?.code, one.code);
  // A code already someone's is never given again: the next draw is.
  const draws = ['B', 'B', 'B', 'B', 'B', 'B', 'C', 'C', 'C', 'C', 'C', 'C'];
  let i = 0;
  db.docs.set('inviteCodes/BBBBBB', { uid: 'zed', at: 1 });
  const ben = await giveCode(fs, 'ben', NOW, () => CODE_ALPHABET.indexOf(draws[i++]));
  assert.equal(ben.code, 'CCCCCC');
  assert.equal(db.doc('inviteCodes/BBBBBB')?.uid, 'zed');
});

// ── Not set up ───────────────────────────────────────────────────────────

test('without a secret key, or with the stand-in the deploy keeps, nothing is asked of RevenueCat', async () => {
  let fetched = 0;
  const fetchFn = (async () => {
    fetched++;
    return new Response('{}');
  }) as typeof fetch;
  for (const key of [undefined, null, '', 'unset', 'appl_abcdefghij', 'goog_abcdefghij', 'sk_', 'sk_short', '   ']) {
    assert.equal(configured(key), false, String(key));
    assert.equal(storeFor(key, fetchFn), null, String(key));
  }
  assert.equal(fetched, 0);
  assert.equal(configured('sk_AbCdEf1234567890'), true);
  assert.ok(storeFor('sk_AbCdEf1234567890', fetchFn));
});

// ── RevenueCat, through its API v1 ───────────────────────────────────────

test("RevenueCat is asked as its API v1 says: the customer read, and the week granted to an end", async () => {
  const calls: { url: string; init?: RequestInit }[] = [];
  const fetchFn = (async (url: string | URL | Request, init?: RequestInit) => {
    calls.push({ url: String(url), init });
    if (init?.method === 'POST') return new Response('{"subscriber":{}}', { status: 201 });
    return new Response(
      JSON.stringify({ subscriber: { entitlements: { [ENTITLEMENT]: { expires_date: '2026-11-30T18:00:00Z', product_identifier: 'rc_promo_astuto_pro_custom' } } } }),
      { status: 200 },
    );
  }) as typeof fetch;
  const rc = revenueCat(' sk_AbCdEf1234567890 ', fetchFn);
  const held = await rc.held('uid/with space', NOW);
  assert.deepEqual(held, { ever: true, until: Date.parse('2026-11-30T18:00:00Z'), lifetime: false });
  await rc.grant('uid/with space', NOW + WEEK_MS + 0.4);
  assert.equal(calls[0].url, 'https://api.revenuecat.com/v1/subscribers/uid%2Fwith%20space');
  assert.equal(calls[0].init?.method, undefined);
  assert.equal(calls[1].url, 'https://api.revenuecat.com/v1/subscribers/uid%2Fwith%20space/entitlements/astuto_pro/promotional');
  assert.equal(calls[1].init?.method, 'POST');
  assert.deepEqual(JSON.parse(String(calls[1].init?.body)), { end_time_ms: NOW + WEEK_MS });
  for (const c of calls) {
    const headers = c.init?.headers as Record<string, string>;
    assert.equal(headers.Authorization, 'Bearer sk_AbCdEf1234567890');
  }
});

test('a key RevenueCat turns away is said, with its status', async () => {
  const fetchFn = (async () => new Response('{"code":7225,"message":"Invalid API Key."}', { status: 401 })) as typeof fetch;
  const rc = revenueCat('sk_AbCdEf1234567890', fetchFn);
  await assert.rejects(rc.held('ana', NOW), (e: unknown) => e instanceof RevenueCatError && e.status === 401);
  await assert.rejects(rc.grant('ana', NOW + WEEK_MS), (e: unknown) => e instanceof RevenueCatError && e.status === 401);
});

test('what a customer holds, as RevenueCat writes it', () => {
  const said = (plus: unknown) => heldOf({ subscriber: { entitlements: plus === undefined ? {} : { [ENTITLEMENT]: plus } } }, NOW);
  assert.deepEqual(said(undefined), { ever: false, until: null, lifetime: false });
  assert.deepEqual(heldOf(null, NOW), { ever: false, until: null, lifetime: false });
  assert.deepEqual(heldOf({ subscriber: { entitlements: { other: { expires_date: null } } } }, NOW), { ever: false, until: null, lifetime: false });
  // A trial or a week long over: held once, not now.
  assert.deepEqual(said({ expires_date: '2026-10-01T00:00:00Z' }), { ever: true, until: null, lifetime: false });
  assert.deepEqual(said({ expires_date: '2026-12-10T00:00:00Z' }), { ever: true, until: Date.parse('2026-12-10T00:00:00Z'), lifetime: false });
  // A billing problem in its grace period still holds it.
  assert.deepEqual(said({ expires_date: '2026-11-26T00:00:00Z', grace_period_expires_date: '2026-12-02T00:00:00Z' }), { ever: true, until: Date.parse('2026-12-02T00:00:00Z'), lifetime: false });
  assert.deepEqual(said({ expires_date: null }), { ever: true, until: null, lifetime: true });
});

// ── The rules ────────────────────────────────────────────────────────────

test('a code is refused when there is no such code, it is your own, you used one, your account is not new, or it has held Astute+', () => {
  const base = { uid: 'ben', owner: 'ana', came: false, madeAt: NOW - DAY, nowMs: NOW, held: NEVER };
  assert.equal(refusal(base), null);
  assert.equal(refusal({ ...base, owner: null }), 'unknown');
  assert.equal(refusal({ ...base, owner: 'ben' }), 'own');
  assert.equal(refusal({ ...base, came: true }), 'used');
  assert.equal(refusal({ ...base, madeAt: NOW - NEW_FOR_DAYS * DAY }), null);
  assert.equal(refusal({ ...base, madeAt: NOW - NEW_FOR_DAYS * DAY - 1 }), 'late');
  assert.equal(refusal({ ...base, madeAt: null }), 'late');
  assert.equal(refusal({ ...base, held: { ever: true, until: null, lifetime: false } }), 'plus');
  // In that order: what needs RevenueCat is asked last.
  assert.equal(refusal({ ...base, owner: 'ben', came: true, madeAt: null }), 'own');
  assert.equal(refusal({ ...base, came: true, madeAt: null, held: { ever: true, until: null, lifetime: false } }), 'used');
  assert.equal(refusal({ ...base, held: null }), null);
});

test('a week starts where the Astute+ already held ends, and an inviter has eight a year at most', () => {
  const free = { held: NEVER, mine: {} };
  assert.deepEqual(planWeeks(NOW, free, free), { until: NOW + WEEK_MS, inviterUntil: NOW + WEEK_MS });
  // A week running, from RevenueCat or as this last gave it: the next one after it.
  const running = { held: { ever: true, until: NOW + 3 * DAY, lifetime: false }, mine: {} };
  assert.equal(planWeeks(NOW, running, null).until, NOW + 3 * DAY + WEEK_MS);
  assert.equal(planWeeks(NOW, { held: NEVER, mine: { until: NOW + 5 * DAY } }, null).until, NOW + 5 * DAY + WEEK_MS);
  assert.equal(planWeeks(NOW, { held: NEVER, mine: { until: NOW - 5 * DAY } }, null).until, NOW + WEEK_MS);
  // A plan from the store: the week after it, should it stop.
  assert.equal(planWeeks(NOW, free, { held: { ever: true, until: NOW + 20 * DAY, lifetime: false }, mine: {} }).inviterUntil, NOW + 27 * DAY);
  // For life: nothing to add.
  assert.equal(planWeeks(NOW, { held: { ever: true, until: null, lifetime: true }, mine: {} }, null).until, null);
  // Eight weeks in the last 365 days, and no ninth; one older than a year does not count.
  const eight = Array.from({ length: WEEKS_A_YEAR }, (_, i) => NOW - (i + 1) * 30 * DAY);
  assert.equal(planWeeks(NOW, free, { held: NEVER, mine: { weeks: eight } }).inviterUntil, null);
  const sevenAndOld = [...eight.slice(0, 7), NOW - YEAR_MS - DAY];
  assert.equal(planWeeks(NOW, free, { held: NEVER, mine: { weeks: sevenAndOld } }).inviterUntil, NOW + WEEK_MS);
  // The friend's week either way.
  assert.equal(planWeeks(NOW, free, { held: NEVER, mine: { weeks: eight } }).until, NOW + WEEK_MS);
});

// ── A friend, from the code to the week ──────────────────────────────────

test('a friend uses the code, finishes the first day, and the two are each given a week', async () => {
  const { fs, db, store, days, reader } = world();
  const { code } = await giveCode(fs, 'ana', NOW - 10 * DAY);

  // Ben, two days in, uses it: taken, the week waiting on his first day.
  assert.deepEqual(await redeem(fs, store, 'ben', ` ${code!.toLowerCase()} `, NOW, reader), { state: 'waiting' });
  assert.deepEqual(db.doc('invited/ben'), { code, at: NOW, state: 'waiting' });
  assert.equal(store.grants.length, 0);

  // Asked before the day is done: still waiting, nothing given.
  const before = await inviteState(fs, store, 'ben', NOW + 60_000, reader);
  assert.equal(before.redeem, 'waiting');
  assert.equal(before.granted, undefined);
  assert.equal(store.grants.length, 0);

  // The five read: both weeks given, from now.
  days.add('ben');
  const at = NOW + 3_600_000;
  const after = await inviteState(fs, store, 'ben', at, reader);
  assert.equal(after.redeem, 'granted');
  assert.equal(after.granted, true);
  assert.equal(after.until, at + WEEK_MS);
  assert.deepEqual(store.grants, [['ben', at + WEEK_MS], ['ana', at + WEEK_MS]]);

  // Written down: the inviter's week and friend, the friend's code given, the inviter no longer named.
  assert.deepEqual(db.doc('invites/ana'), { code, at: NOW - 10 * DAY, friends: 1, weeks: [at], until: at + WEEK_MS });
  assert.deepEqual(db.doc('invited/ben'), { code, at: NOW, state: 'granted', until: at + WEEK_MS, inviterToo: true, grantedAt: at });
  assert.equal(db.doc('invites/ben')?.until, at + WEEK_MS);

  // Asked again: nothing more is given.
  const again = await inviteState(fs, store, 'ben', at + 60_000, reader);
  assert.equal(again.granted, undefined);
  assert.equal(again.redeem, 'granted');
  assert.equal(store.grants.length, 2);

  // What Ana sees: her code, one week of eight, one friend.
  const ana = await inviteState(fs, store, 'ana', at + 60_000, reader);
  assert.deepEqual({ ...ana }, { code, weeks: 1, cap: WEEKS_A_YEAR, friends: 1, redeem: 'closed' });
});

test('a code used after the first day is finished gives the weeks at once', async () => {
  const { fs, store, days, reader } = world();
  const { code } = await giveCode(fs, 'ana', NOW);
  days.add('cyd');
  const out = await redeem(fs, store, 'cyd', code, NOW, reader);
  assert.deepEqual(out, { state: 'granted', until: NOW + WEEK_MS, granted: true });
  assert.deepEqual(store.grants.map(([uid]) => uid), ['cyd', 'ana']);
});

test('your own code, a second code, an old account and one that held Astute+ are refused, and a code sent again is where it stands', async () => {
  const { fs, db, store, reader } = world();
  const ana = (await giveCode(fs, 'ana', NOW)).code!;
  const ben = (await giveCode(fs, 'ben', NOW)).code!;
  assert.deepEqual(await redeem(fs, store, 'ana', ana, NOW, reader), { refused: 'own' });
  assert.deepEqual(await redeem(fs, store, 'ben', 'ZZZZZZ', NOW, reader), { refused: 'unknown' });
  assert.deepEqual(await redeem(fs, store, 'ben', 'not a code', NOW, reader), { refused: 'unknown' });
  // Dan's account is forty days old.
  assert.deepEqual(await redeem(fs, store, 'dan', ana, NOW, reader), { refused: 'late' });
  // An account nobody can say the age of is not new.
  assert.deepEqual(await redeem(fs, store, 'eve', ana, NOW, reader), { refused: 'late' });
  // Cyd had a trial.
  store.held_.set('cyd', { ever: true, until: null, lifetime: false });
  assert.deepEqual(await redeem(fs, store, 'cyd', ana, NOW, reader), { refused: 'plus' });
  assert.equal(db.doc('invited/cyd'), undefined);
  // Ben uses Ana's; then Cyd's would be a second.
  assert.deepEqual(await redeem(fs, store, 'ben', ana, NOW, reader), { state: 'waiting' });
  const cyd = (await giveCode(fs, 'cyd', NOW)).code!;
  assert.deepEqual(await redeem(fs, store, 'ben', cyd, NOW, reader), { refused: 'used' });
  // Ana's again, from a phone that did not hear: as it stands.
  assert.deepEqual(await redeem(fs, store, 'ben', ana, NOW + 1000, reader), { state: 'waiting' });
  assert.equal(db.doc('invited/ben')?.code, ana);
  assert.ok(ben);
});

test("past eight weeks in a year the inviter is given none, and the friend still has theirs", async () => {
  const { fs, db, store, days, reader } = world();
  const { code } = await giveCode(fs, 'ana', NOW - 300 * DAY);
  const eight = Array.from({ length: WEEKS_A_YEAR }, (_, i) => NOW - (i + 1) * 20 * DAY);
  db.write('invites/ana', { weeks: eight, friends: 8 }, true);
  days.add('ben');
  const out = await redeem(fs, store, 'ben', code, NOW, reader);
  assert.deepEqual(out, { state: 'granted', until: NOW + WEEK_MS, granted: true });
  assert.deepEqual(store.grants, [['ben', NOW + WEEK_MS]]);
  assert.equal(db.doc('invites/ana')?.friends, 9);
  assert.deepEqual(db.doc('invites/ana')?.weeks, eight);
  assert.equal(db.doc('invited/ben')?.inviterToo, false);
  const ana = await inviteState(fs, store, 'ana', NOW, reader);
  assert.equal(ana.weeks, WEEKS_A_YEAR);
});

test("an inviter's weeks follow one another, and a reader who invited and came has both", async () => {
  const { fs, db, store, days, reader } = world();
  const { code } = await giveCode(fs, 'ana', NOW - 30 * DAY);
  days.add('ben');
  days.add('cyd');
  await redeem(fs, store, 'ben', code, NOW, reader);
  // Cyd finishes an hour later: Ana's second week starts where her first ends.
  await redeem(fs, store, 'cyd', code, NOW + 3_600_000, reader);
  assert.deepEqual(store.grants.filter(([uid]) => uid === 'ana').map(([, until]) => until), [NOW + WEEK_MS, NOW + 2 * WEEK_MS]);
  assert.equal(db.doc('invites/ana')?.until, NOW + 2 * WEEK_MS);
  assert.equal(db.doc('invites/ana')?.friends, 2);
});

test('a week RevenueCat did not take is given again with the same end, and only once', async () => {
  const { fs, db, store, days, reader } = world();
  const { code } = await giveCode(fs, 'ana', NOW);
  days.add('ben');
  store.fail = 1;
  await assert.rejects(redeem(fs, store, 'ben', code, NOW, reader), RevenueCatError);
  assert.equal(db.doc('invited/ben')?.state, 'granting');
  assert.equal(db.doc('invited/ben')?.inviter, 'ana');
  // The next ask, later, gives the ends planned the first time.
  const later = NOW + 5 * 60_000;
  const out = await settle(fs, store, 'ben', later, reader);
  assert.equal(out.granted, true);
  assert.deepEqual(store.grants, [['ben', NOW + WEEK_MS], ['ana', NOW + WEEK_MS]]);
  assert.equal(db.doc('invited/ben')?.inviter, undefined);
  assert.equal((await settle(fs, store, 'ben', later, reader)).granted, false);
  assert.equal(store.grants.length, 2);
});

test("an inviter whose account has gone leaves the friend their week", async () => {
  const { fs, db, store, days, reader } = world();
  const { code } = await giveCode(fs, 'ana', NOW);
  await redeem(fs, store, 'ben', code, NOW, reader);
  await forgetInvites(fs, 'ana');
  assert.equal(db.doc(`inviteCodes/${code}`), undefined);
  assert.equal(db.doc('invites/ana'), undefined);
  days.add('ben');
  const out = await settle(fs, store, 'ben', NOW + 1000, reader);
  assert.equal(out.granted, true);
  assert.deepEqual(store.grants, [['ben', NOW + 1000 + WEEK_MS]]);
  // And a new reader can no longer use the code.
  assert.deepEqual(await redeem(fs, store, 'cyd', code, NOW, reader), { refused: 'unknown' });
});

test("a reader's invitations go with the account, and nobody else's", async () => {
  const { fs, db, store, reader } = world();
  const ana = (await giveCode(fs, 'ana', NOW)).code!;
  const ben = (await giveCode(fs, 'ben', NOW)).code!;
  await redeem(fs, store, 'cyd', ana, NOW, reader);
  await forgetInvites(fs, 'cyd');
  assert.equal(db.doc('invited/cyd'), undefined);
  assert.ok(db.doc(`inviteCodes/${ana}`));
  await forgetInvites(fs, 'ben');
  assert.equal(db.doc(`inviteCodes/${ben}`), undefined);
  assert.equal(db.doc('invites/ben'), undefined);
  assert.ok(db.doc('invites/ana'));
});

test('who may still use a code: a new account that has used none', async () => {
  const { fs, store, reader } = world();
  assert.equal((await inviteState(fs, store, 'ben', NOW, reader)).redeem, 'open');
  assert.equal((await inviteState(fs, store, 'dan', NOW, reader)).redeem, 'closed');
  assert.equal((await inviteState(fs, store, 'eve', NOW, reader)).redeem, 'closed');
  // Asking for the state makes no code; asking with make does.
  const plain = await inviteState(fs, store, 'ben', NOW, reader);
  assert.equal(plain.code, null);
  const made = await inviteState(fs, store, 'ben', NOW, reader, true);
  assert.equal(readCode(made.code), made.code);
  assert.equal(store.asked, 0);
});
