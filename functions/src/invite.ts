// Invita un amico: a reader sends a friend a link with a code of their own
// (astutetheapp.com/invito?c=K7MQ2P), and the friend, on an account that is
// new and has never held Astute+, uses it: from the link, which the app
// takes when the phone hands it over, or typed in the profile. When the
// friend finishes their first day, the five cards, each of the two is given
// a week of Astute+ through RevenueCat, as a promotional entitlement
// (inviteState and redeemInvite, index.ts).
//
// The rules a week keeps:
//
// - a friend uses one code, ever, and never their own;
// - the friend's account was made in the last NEW_FOR_DAYS days, and has
//   never held Astute+ in RevenueCat (a trial, a plan or a week);
// - nothing is given before the friend's first day is finished, as their
//   backup says it is (readers/{uid}, completedDates): an account made only
//   to use a code gains nothing until it has read a day;
// - an inviter is given at most WEEKS_A_YEAR weeks in any 365 days; past
//   that the friend still has theirs, and the inviter is told why they had
//   none;
// - each week starts where the Astute+ the reader already holds ends — a
//   week given while another runs is a week more, not the same days twice —
//   and a reader who holds it for life is given nothing.
//
// What is kept, all of it written only here (firestore.rules lets no phone
// read or write any of it; the phone hears through the two functions):
//
//   invites/{uid}       the reader's code, the weeks friends have earned them
//                       this year, how many friends finished a first day with
//                       it, and when the last week given them ends
//   inviteCodes/{code}  whose code it is
//   invited/{uid}       the code the reader came with, and where its week is:
//                       waiting for the first day, being given, given
//
// All three go with the account (forgetInvites, from serve.ts forgetReader).
// The code says nothing about anyone: six characters drawn at random from
// an alphabet with no vowels, so it spells no word, and none of the
// characters that read as another (0 and O, 1, I and L, U and V).
//
// RevenueCat is asked through its REST API v1 with the project's secret key
// (REVENUECAT_SECRET_KEY, index.ts). Without one, or with the stand-in the
// deploy keeps in its place, nothing here is asked and every phone hides the
// invitation (`{ none: 'unconfigured' }`).

import { randomInt } from 'node:crypto';
import type { Firestore } from 'firebase-admin/firestore';
import { FieldPath } from 'firebase-admin/firestore';

/** The entitlement Astute+ is, as RevenueCat names it (lib/sync/subscription.dart, kPlusEntitlement). */
export const ENTITLEMENT = 'astuto_pro';

/** What a code is drawn from: the digits from 2 and the consonants but L, so no word and nothing that reads as another. */
export const CODE_ALPHABET = '23456789BCDFGHJKMNPQRSTVWXYZ';

/** Six of them: 28⁶, some 480 million codes, short enough to read out. */
export const CODE_LENGTH = 6;

const DAY_MS = 86_400_000;

/** A friend's account is new for a week from the day it was made: a code is for someone just arriving. */
export const NEW_FOR_DAYS = 7;

/** What a code gives each of the two. */
export const WEEK_MS = 7 * DAY_MS;

/** The most weeks an inviter is given in any 365 days. */
export const WEEKS_A_YEAR = 8;

export const YEAR_MS = 365 * DAY_MS;

/** [raw] as a code, the way a reader may type it — any case, spaces and dashes anywhere — or null when it is not one. */
export function readCode(raw: unknown): string | null {
  if (typeof raw !== 'string' || raw.length > 40) return null;
  const code = raw.toUpperCase().replace(/[\s-]+/g, '');
  if (code.length !== CODE_LENGTH) return null;
  for (const ch of code) if (!CODE_ALPHABET.includes(ch)) return null;
  return code;
}

/** A code drawn at random; [pick] is a test's stand-in for the draw. */
export function makeCode(pick: (n: number) => number = randomInt): string {
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) code += CODE_ALPHABET[pick(CODE_ALPHABET.length)];
  return code;
}

// ── RevenueCat ───────────────────────────────────────────────────────────

/** What RevenueCat holds for a customer, as far as an invitation asks. */
export interface Held {
  /** Astute+ ever: a trial, a plan or a week, running or long over. */
  ever: boolean;
  /** When the Astute+ held now runs out; null when none is held now, or it is held for life. */
  until: number | null;
  /** Held for life: there is nothing to add to it. */
  lifetime: boolean;
}

/** RevenueCat, as an invitation uses it. Replaced in the tests. */
export interface Store {
  /** What [uid] holds. */
  held(uid: string, nowMs: number): Promise<Held>;
  /**
   * Astute+ for [uid] until [untilMs], from now. Sent again with the same
   * end, it changes nothing: RevenueCat takes an end within two hours of the
   * promotional one running as the same, which is what makes a retry safe.
   */
  grant(uid: string, untilMs: number): Promise<void>;
}

export const REVENUECAT_API = 'https://api.revenuecat.com/v1';

/** A key RevenueCat could take: a secret key, `sk_`. The deploy's stand-in, or nothing, is not one. */
export function configured(key: string | null | undefined): key is string {
  return typeof key === 'string' && /^sk_\S{8,}$/.test(key.trim());
}

/** What RevenueCat said went wrong, with its status, so a log says which. */
export class RevenueCatError extends Error {
  constructor(
    readonly status: number,
    detail: string,
  ) {
    super(`RevenueCat answered ${status}: ${detail.slice(0, 200)}`);
  }
}

/** The customer RevenueCat sends back (GET /subscribers/{id}), read for Astute+. */
export function heldOf(body: unknown, nowMs: number): Held {
  const all = (body as { subscriber?: { entitlements?: Record<string, unknown> } } | null)?.subscriber?.entitlements;
  const plus = all && typeof all === 'object' ? (all[ENTITLEMENT] as Record<string, unknown> | undefined) : undefined;
  if (!plus || typeof plus !== 'object') return { ever: false, until: null, lifetime: false };
  if (plus.expires_date === null) return { ever: true, until: null, lifetime: true };
  const ends = [plus.expires_date, plus.grace_period_expires_date]
    .map((d) => (typeof d === 'string' ? Date.parse(d) : NaN))
    .filter((ms) => Number.isFinite(ms));
  const until = ends.length ? Math.max(...ends) : NaN;
  return { ever: true, until: Number.isFinite(until) && until > nowMs ? until : null, lifetime: false };
}

/** RevenueCat's REST API v1, with the project's secret key. */
export function revenueCat(key: string, fetchFn: typeof fetch = fetch): Store {
  const headers = { Authorization: `Bearer ${key.trim()}`, 'Content-Type': 'application/json', Accept: 'application/json' };
  const customer = (uid: string) => `${REVENUECAT_API}/subscribers/${encodeURIComponent(uid)}`;
  const answered = async (res: Response): Promise<void> => {
    if (!res.ok) throw new RevenueCatError(res.status, await res.text().catch(() => ''));
  };
  return {
    async held(uid, nowMs) {
      const res = await fetchFn(customer(uid), { headers });
      await answered(res);
      return heldOf(await res.json(), nowMs);
    },
    async grant(uid, untilMs) {
      const res = await fetchFn(`${customer(uid)}/entitlements/${ENTITLEMENT}/promotional`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ end_time_ms: Math.round(untilMs) }),
      });
      await answered(res);
    },
  };
}

/** RevenueCat with [key], or null when the key is not one it could take: invitations are not set up. */
export function storeFor(key: string | null | undefined, fetchFn: typeof fetch = fetch): Store | null {
  return configured(key) ? revenueCat(key, fetchFn) : null;
}

// ── What is decided, without a database ──────────────────────────────────

/** Why a code was not taken. */
export type Refusal =
  /** No such code. */
  | 'unknown'
  /** The reader's own. */
  | 'own'
  /** The reader used a code already. */
  | 'used'
  /** The account is older than a week. */
  | 'late'
  /** The account has held Astute+. */
  | 'plus';

/** The reader's side of invitations, at invites/{uid}. */
export interface Mine {
  code?: string;
  at?: number;
  /** When each week a friend earned them was given, the last year's. */
  weeks?: number[];
  /** The friends who finished a first day with the code, ever. */
  friends?: number;
  /** When the last week given them ends, either way: the next starts there. */
  until?: number;
}

/** How a reader came, at invited/{uid}. */
export interface Came {
  code: string;
  at: number;
  state: 'waiting' | 'granting' | 'granted';
  /** The end of the reader's own week, once planned; null when they hold Astute+ for life. */
  until?: number | null;
  /** While it is being given: the inviter, when their week is due too, and its end. */
  inviter?: string | null;
  inviterUntil?: number | null;
  /** Once given: whether the inviter had theirs. */
  inviterToo?: boolean;
  grantedAt?: number;
}

/**
 * Whether [uid] may use a code that is [owner]'s, and why not: no such
 * code, their own, one used already, an account made more than a week
 * before [nowMs] (or whose making nobody can say), or one that has held
 * Astute+. In that order, so that what costs a call to RevenueCat is asked
 * last ([held] null: not asked yet).
 */
export function refusal(o: {
  uid: string;
  owner: string | null;
  came: boolean;
  madeAt: number | null;
  nowMs: number;
  held: Held | null;
}): Refusal | null {
  if (o.owner === null) return 'unknown';
  if (o.owner === o.uid) return 'own';
  if (o.came) return 'used';
  if (o.madeAt === null || o.nowMs - o.madeAt > NEW_FOR_DAYS * DAY_MS) return 'late';
  if (o.held?.ever) return 'plus';
  return null;
}

/** The weeks among [weeks] given in the 365 days to [nowMs]. */
export function recentWeeks(weeks: unknown, nowMs: number): number[] {
  if (!Array.isArray(weeks)) return [];
  return weeks.filter((w): w is number => typeof w === 'number' && w > nowMs - YEAR_MS && w <= nowMs);
}

/** When the next week for a reader holding [held], whom this has last given up to [given], ends; null for life. */
export function weekAfter(nowMs: number, held: Held, given: number | undefined): number | null {
  if (held.lifetime) return null;
  return Math.max(nowMs, held.until ?? 0, typeof given === 'number' ? given : 0) + WEEK_MS;
}

/** The ends of the two weeks: the friend's, and the inviter's while their year has room (null when it has none). */
export function planWeeks(
  nowMs: number,
  friend: { held: Held; mine: Mine },
  inviter: { held: Held; mine: Mine } | null,
): { until: number | null; inviterUntil: number | null } {
  const until = weekAfter(nowMs, friend.held, friend.mine.until);
  const room = inviter !== null && recentWeeks(inviter.mine.weeks, nowMs).length < WEEKS_A_YEAR;
  return { until, inviterUntil: room ? weekAfter(nowMs, inviter.held, inviter.mine.until) : null };
}

// ── Against Firestore ────────────────────────────────────────────────────

/** What the functions need to know about a reader beyond Firestore. Replaced in the tests. */
export interface Reader {
  /** When the account was made, as Firebase Auth has it; null when it cannot say. */
  madeAt(uid: string): Promise<number | null>;
  /** Whether the reader has finished a day, as their backup says. */
  readADay(uid: string): Promise<boolean>;
}

/** Whether the backup at readers/{uid} has a finished day: its completedDates, the one field read. */
export async function backupHasADay(db: Firestore, uid: string): Promise<boolean> {
  const snap = await db.collection('readers').where(FieldPath.documentId(), '==', uid).select('completedDates').limit(1).get();
  const dates = snap.empty ? null : snap.docs[0].get('completedDates');
  return Array.isArray(dates) && dates.some((d) => typeof d === 'string' && d.length > 0);
}

/** Where a reader's use of a code stands, for the phone. */
export type Redeem = 'open' | 'closed' | Came['state'];

/** What the phone hears of invitations. */
export interface InviteState {
  /** The reader's own code, once asked for. */
  code: string | null;
  /** The weeks friends earned them in the last 365 days, and the most there may be. */
  weeks: number;
  cap: number;
  /** The friends who finished a first day with the code. */
  friends: number;
  /** Whether a code of a friend's may still be used ('open'), may not ('closed'), or where the one used stands. */
  redeem: Redeem;
  /** The end of the reader's own week, once given. */
  until?: number | null;
  /** Given by this very call: the moment to say so. */
  granted?: boolean;
}

/**
 * The reader's code, made if they have none: drawn until one is free, and
 * written with its owner in one transaction, so two taps make one code.
 */
export async function giveCode(db: Firestore, uid: string, nowMs: number, pick?: (n: number) => number): Promise<Mine> {
  const mineRef = db.collection('invites').doc(uid);
  for (let draw = 0; draw < 8; draw++) {
    const code = makeCode(pick);
    const codeRef = db.collection('inviteCodes').doc(code);
    const made = await db.runTransaction(async (t) => {
      const [m, c] = await Promise.all([t.get(mineRef), t.get(codeRef)]);
      const mine = (m.data() ?? {}) as Mine;
      if (mine.code) return mine;
      if (c.exists) return null;
      t.set(codeRef, { uid, at: nowMs });
      t.set(mineRef, { code, at: nowMs }, { merge: true });
      return { ...mine, code, at: nowMs };
    });
    if (made) return made;
  }
  throw new Error('no free code in eight draws');
}

/**
 * Gives the week of a reader who came with a code, once their first day is
 * finished, and the inviter's with it while their year has room. Planned in
 * one transaction — the ends of both weeks written down before RevenueCat is
 * asked — then given; a call that fails between the two leaves it being
 * given, and the next gives the same ends again, which RevenueCat takes as
 * the same. Returns where it stands, and whether this call gave it.
 */
export async function settle(db: Firestore, store: Store, uid: string, nowMs: number, reader: Reader): Promise<{ came: Came | null; granted: boolean }> {
  const ref = db.collection('invited').doc(uid);
  const snap = await ref.get();
  if (!snap.exists) return { came: null, granted: false };
  let came = snap.data() as Came;
  if (came.state === 'granted') return { came, granted: false };
  if (came.state === 'waiting') {
    if (!(await reader.readADay(uid))) return { came, granted: false };
    const owner = (await db.collection('inviteCodes').doc(came.code).get()).get('uid');
    // The inviter's account may have gone since: the friend keeps their week.
    const inviter = typeof owner === 'string' && owner !== uid ? owner : null;
    const [friendHeld, inviterHeld] = await Promise.all([store.held(uid, nowMs), inviter ? store.held(inviter, nowMs) : null]);
    const mineRef = db.collection('invites').doc(uid);
    const theirsRef = inviter ? db.collection('invites').doc(inviter) : null;
    const planned = await db.runTransaction(async (t) => {
      const [c, m, th] = await Promise.all([t.get(ref), t.get(mineRef), theirsRef ? t.get(theirsRef) : null]);
      const now = c.data() as Came | undefined;
      if (!now || now.state !== 'waiting') return now ?? null;
      const mine = (m.data() ?? {}) as Mine;
      const theirs = (th?.data() ?? {}) as Mine;
      const plan = planWeeks(nowMs, { held: friendHeld, mine }, inviter && inviterHeld ? { held: inviterHeld, mine: theirs } : null);
      const next: Came = {
        code: now.code,
        at: now.at,
        state: 'granting',
        until: plan.until,
        inviter: plan.inviterUntil !== null ? inviter : null,
        inviterUntil: plan.inviterUntil,
      };
      t.set(ref, next);
      if (plan.until !== null) t.set(mineRef, { until: plan.until }, { merge: true });
      if (theirsRef) {
        const friends = (theirs.friends ?? 0) + 1;
        t.set(
          theirsRef,
          plan.inviterUntil !== null
            ? { friends, weeks: [...recentWeeks(theirs.weeks, nowMs), nowMs], until: plan.inviterUntil }
            : { friends },
          { merge: true },
        );
      }
      return next;
    });
    if (!planned) return { came: null, granted: false };
    came = planned;
  }
  if (came.state !== 'granting') return { came, granted: false };
  if (typeof came.until === 'number') await store.grant(uid, came.until);
  if (came.inviter && typeof came.inviterUntil === 'number') await store.grant(came.inviter, came.inviterUntil);
  // Given: the inviter is no longer named, only whether they had theirs.
  const done: Came = { code: came.code, at: came.at, state: 'granted', until: came.until ?? null, inviterToo: !!came.inviter, grantedAt: nowMs };
  await ref.set(done);
  return { came: done, granted: true };
}

/** Whether an account made at [madeAt] is new at [nowMs]. */
function isNew(madeAt: number | null, nowMs: number): boolean {
  return madeAt !== null && nowMs - madeAt <= NEW_FOR_DAYS * DAY_MS;
}

/**
 * Everything the phone shows of invitations, for [uid]: their code (made
 * now with [make]), the weeks friends earned them this year, and whether a
 * friend's code may still be used or where the one used stands — given here,
 * when the first day it waited for is finished.
 */
export async function inviteState(db: Firestore, store: Store, uid: string, nowMs: number, reader: Reader, make = false): Promise<InviteState> {
  const settled = await settle(db, store, uid, nowMs, reader);
  let mine = ((await db.collection('invites').doc(uid).get()).data() ?? {}) as Mine;
  if (make && !mine.code) mine = await giveCode(db, uid, nowMs);
  const came = settled.came;
  const redeem: Redeem = came ? came.state : isNew(await reader.madeAt(uid), nowMs) ? 'open' : 'closed';
  return {
    code: mine.code ?? null,
    weeks: recentWeeks(mine.weeks, nowMs).length,
    cap: WEEKS_A_YEAR,
    friends: mine.friends ?? 0,
    redeem,
    ...(came && came.until !== undefined ? { until: came.until } : {}),
    ...(settled.granted ? { granted: true } : {}),
  };
}

/** What a code used comes to: where its week stands, or why it was not taken. */
export type Redeemed = { state: Came['state']; until?: number | null; granted?: boolean } | { refused: Refusal };

/**
 * [uid] uses the code [raw]: refused, with the reason, or taken — and given
 * at once when their first day is already finished. The same code sent
 * again, from a phone that did not hear the answer, is where it stands.
 */
export async function redeem(db: Firestore, store: Store, uid: string, raw: unknown, nowMs: number, reader: Reader): Promise<Redeemed> {
  const code = readCode(raw);
  if (!code) return { refused: 'unknown' };
  const ref = db.collection('invited').doc(uid);
  const [codeSnap, cameSnap] = await Promise.all([db.collection('inviteCodes').doc(code).get(), ref.get()]);
  const came = cameSnap.exists ? (cameSnap.data() as Came) : null;
  if (came && came.code === code) return afterTaking(await settle(db, store, uid, nowMs, reader));
  const owner = codeSnap.exists && typeof codeSnap.get('uid') === 'string' ? (codeSnap.get('uid') as string) : null;
  const ask = { uid, owner, came: came !== null, nowMs, held: null };
  const before = refusal({ ...ask, madeAt: nowMs });
  if (before) return { refused: before };
  const madeAt = await reader.madeAt(uid);
  const late = refusal({ ...ask, madeAt });
  if (late) return { refused: late };
  const plus = refusal({ ...ask, madeAt, held: await store.held(uid, nowMs) });
  if (plus) return { refused: plus };
  const taken = await db.runTransaction(async (t) => {
    const now = await t.get(ref);
    if (now.exists) return (now.data() as Came).code === code;
    t.set(ref, { code, at: nowMs, state: 'waiting' } satisfies Came);
    return true;
  });
  if (!taken) return { refused: 'used' };
  return afterTaking(await settle(db, store, uid, nowMs, reader));
}

function afterTaking(settled: { came: Came | null; granted: boolean }): Redeemed {
  const came = settled.came;
  if (!came) return { refused: 'used' };
  return {
    state: came.state,
    ...(came.until !== undefined ? { until: came.until } : {}),
    ...(settled.granted ? { granted: true } : {}),
  };
}

/** The reader's invitations, gone with their account: their side, their code, and the code they came with. */
export async function forgetInvites(db: Firestore, uid: string): Promise<void> {
  const mineRef = db.collection('invites').doc(uid);
  const code = (await mineRef.get()).get('code');
  const batch = db.batch();
  if (typeof code === 'string' && code) {
    const codeRef = db.collection('inviteCodes').doc(code);
    // Only a code that is still theirs.
    if ((await codeRef.get()).get('uid') === uid) batch.delete(codeRef);
  }
  batch.delete(mineRef);
  batch.delete(db.collection('invited').doc(uid));
  await batch.commit();
}
