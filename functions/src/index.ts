// Astute's server: what it does for a reader, and when.
//
// Seven things, in europe-west1, where the readers are:
//
// - `dealDay` (callable): a phone asks for its day and gets it, dealt from
//   the reader's profile and written to readers/{uid}/days/{date}, so the
//   next open reads it in one document. The evening before, the phone asks
//   for tomorrow, so the morning is instant.
// - `nightly` (every hour): for every reader here in the last fortnight,
//   their local today — and from the late afternoon their tomorrow — dealt
//   if not yet, Explore's shelf of their own refreshed once a day, and the
//   trace older than the profile reads cleared. So a reader who never asks
//   still finds the day waiting.
// - `buildExplore` (every hour, at :05): Explore as everybody sees it, from
//   the counts, written to explore/latest. Hourly for the crowd under the
//   top list and today's shelf, which turn with the UTC day.
// - `search` (callable): the whole pool asked a question, so a phone need
//   not hold it; a card about a place answers only a reader who lives there.
// - `onReaderDeleted`: when a reader deletes their account and the phone
//   removes readers/{uid}, everything under it — the trace, the days, the
//   profile, the shelf, the reports — and their presence go with it.
// - `scorecard` (every day, 04:20 UTC): how every card does with the
//   readers, added up from the trace and the reports (scorecard.ts). Cards
//   enough readers say are untrue go into quarantine, and everything above
//   deals around them until somebody has checked them.
// - `cardStats` (HTTPS GET): the scorecard as JSON, numbers per card and
//   nothing about who, for the tools that write and re-check cards.
// - `askCard` (callable, Astute+): a question about a card answered by
//   Claude (ask.ts): the card said simply, its two sides, the reader's own
//   reasoning looked at, or their question answered; so many a day.
//
// The rules (firestore.rules) let no phone write a day, a profile or
// Explore: what the server dealt is what the server dealt.

import Anthropic from '@anthropic-ai/sdk';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { defineSecret } from 'firebase-functions/params';
import { setGlobalOptions } from 'firebase-functions/v2';
import { HttpsError, onCall, onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';

import { ALL_PER_DAY, MODEL, MONTH_BUDGET_USD, PER_DAY, SHARED, answer as answerAsk, cacheKey, readAsk } from './ask.js';
import { Bank, currentBank, dateKey, parseDate } from './bank.js';
import { Tallies, buildGlobalExplore, CLOSED_AFTER, MONTH_DAYS } from './explore.js';
import { search as searchBank } from './search.js';
import { ACTIVE_DAYS, askableDate, datesToPrepare, forgetReader, pruneReader, readPlace, readReader, serveDay, serveExplore } from './serve.js';
import { currentWithheld, runScorecard, withheld } from './scorecard.js';

initializeApp();
setGlobalOptions({ region: 'europe-west1', maxInstances: 20, memory: '512MiB' });

const db = getFirestore();

// The bank the dealer deals from: the newest, less the cards in quarantine
// (scorecard.ts), built again only when either changes.
let dealing: { bank: Bank; ids: ReadonlySet<string>; out: Bank } | null = null;

async function dealingBank(): Promise<Bank> {
  const [bank, ids] = await Promise.all([currentBank(), currentWithheld(db)]);
  if (!dealing || dealing.bank !== bank || dealing.ids !== ids) dealing = { bank, ids, out: withheld(bank, ids) };
  return dealing.out;
}

function today(nowMs: number): string {
  const t = new Date(nowMs);
  return dateKey(t.getUTCFullYear(), t.getUTCMonth() + 1, t.getUTCDate());
}

// ── The reader's day, on request ─────────────────────────────────────────

export const dealDay = onCall({ enforceAppCheck: false }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in, even anonymously.');
  const data = (request.data ?? {}) as { date?: unknown; tz?: unknown; force?: unknown };
  const date = typeof data.date === 'string' && parseDate(data.date) ? data.date : null;
  if (!date) throw new HttpsError('invalid-argument', 'A date, yyyy-mm-dd.');
  const nowMs = Date.now();
  const tz = typeof data.tz === 'number' && Math.abs(data.tz) <= 14 * 60 ? data.tz : 0;
  if (!askableDate(date, tz, nowMs)) throw new HttpsError('invalid-argument', 'A day near today.');
  const bank = await dealingBank();
  const reader = await readReader(db, uid, nowMs);
  if (typeof reader.presence.tz !== 'number') reader.presence.tz = tz;
  const doc = await serveDay(db, bank, reader, date, nowMs, data.force === true);
  logger.info('dealt', { uid, date, cards: (doc.cards as unknown[]).length, own: (doc.own as unknown[]).length });
  return doc;
});

// ── A question about a card, for Astute+ ─────────────────────────────────

/** The key the answers are asked with, kept in Secret Manager. */
const anthropicKey = defineSecret('ANTHROPIC_API_KEY');

export const askCard = onCall(
  { enforceAppCheck: false, secrets: [anthropicKey], maxInstances: 5, timeoutSeconds: 90 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in, even anonymously.');
    const ask = readAsk(request.data);
    if (!ask) throw new HttpsError('invalid-argument', 'A card, and what to ask of it.');
    // The plan as the phone last said it (presence): the counts below bound
    // what a phone that lied about it could cost.
    const presence = await db.collection('presence').doc(uid).get();
    if (presence.get('plus') !== true) throw new HttpsError('permission-denied', 'Astute+ only.');
    const card = (await dealingBank()).byId.get(ask.card);
    if (!card) throw new HttpsError('not-found', 'No such card.');
    // An answer every reader would get alike, asked before: given again, at
    // no cost and outside the day's counts.
    const kept = SHARED.includes(ask.mode) ? db.collection('askCache').doc(cacheKey(card, ask)) : null;
    if (kept) {
      const before = (await kept.get()).get('text');
      if (typeof before === 'string' && before) {
        logger.info('asked', { card: ask.card, mode: ask.mode, lang: ask.lang, answered: 'kept' });
        return { text: before };
      }
    }
    const day = today(Date.now());
    const mine = db.collection('readers').doc(uid).collection('ai').doc(day);
    const everyone = db.collection('ai').doc(day);
    // The month's spend, kept beside the days: past the budget, no model.
    const month = db.collection('ai').doc(`month-${day.slice(0, 7)}`);
    const allowed = await db.runTransaction(async (t) => {
      const [m, e, spent] = await Promise.all([t.get(mine), t.get(everyone), t.get(month)]);
      if ((spent.get('usd') ?? 0) >= MONTH_BUDGET_USD) return false;
      if ((m.get('n') ?? 0) >= PER_DAY || (e.get('n') ?? 0) >= ALL_PER_DAY) return false;
      t.set(mine, { n: FieldValue.increment(1) }, { merge: true });
      t.set(everyone, { n: FieldValue.increment(1) }, { merge: true });
      return true;
    });
    if (!allowed) throw new HttpsError('resource-exhausted', 'Enough for today.');
    try {
      const out = await answerAsk(new Anthropic({ apiKey: anthropicKey.value() }), card, ask);
      await month.set({ usd: FieldValue.increment(out.cost), n: FieldValue.increment(1) }, { merge: true });
      logger.info('asked', { card: ask.card, mode: ask.mode, lang: ask.lang, answered: 'text' in out, cost: out.cost });
      if (kept && 'text' in out) {
        await kept.set({ text: out.text, model: MODEL, at: FieldValue.serverTimestamp() });
      }
      return 'text' in out ? { text: out.text } : { none: out.none };
    } catch (e) {
      logger.error('ask failed', { card: ask.card, mode: ask.mode, error: String(e) });
      throw new HttpsError('unavailable', 'Try again in a moment.');
    }
  },
);

// ── The pool, asked a question ───────────────────────────────────────────

export const search = onCall({ enforceAppCheck: false }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in, even anonymously.');
  const data = (request.data ?? {}) as { q?: unknown };
  const q = typeof data.q === 'string' ? data.q.slice(0, 80) : '';
  // The reader's place, read beside the bank: a card about a place is found
  // only by the readers who live there.
  const [bank, place] = await Promise.all([dealingBank(), readPlace(db, uid).catch(() => null)]);
  const cards = searchBank(bank, q, 30, place);
  return { q, cards, version: bank.version };
});

// ── Every reader's day, ahead of them ────────────────────────────────────

export const nightly = onSchedule({ schedule: 'every 60 minutes', timeoutSeconds: 540 }, async () => {
  const nowMs = Date.now();
  const bank = await dealingBank();
  const since = nowMs - ACTIVE_DAYS * 86_400_000;
  const active = await db.collection('presence').where('lastSeen', '>=', since).select('tz', 'lastSeen', 'plus').get();
  let dealt = 0, shelves = 0, failed = 0;
  // A handful at a time: the work is reads, and Firestore likes them spread.
  const uids = active.docs.map((d) => d.id);
  const width = 8;
  for (let i = 0; i < uids.length; i += width) {
    await Promise.all(
      uids.slice(i, i + width).map(async (uid) => {
        try {
          const reader = await readReader(db, uid, nowMs);
          const wanted = datesToPrepare(reader.presence, nowMs);
          const had = await db.collection('readers').doc(uid).collection('days').where('__name__', 'in', wanted).select().get();
          const have = new Set(had.docs.map((d) => d.id));
          for (const date of wanted) {
            if (have.has(date)) continue;
            await serveDay(db, bank, reader, date, nowMs);
            dealt++;
          }
          // The reader's own shelf, once a day.
          const shelf = await db.collection('readers').doc(uid).collection('explore').doc('current').get();
          const at = shelf.get('at');
          if (typeof at !== 'number' || nowMs - at > 20 * 3_600_000) {
            await serveExplore(db, bank, reader, nowMs);
            shelves++;
            // Once a day with the shelf: what is older than the profile
            // reads goes, as the privacy policy says it does.
            await pruneReader(db, uid, nowMs);
          }
        } catch (error) {
          failed++;
          logger.warn('could not deal for a reader', { uid, error: String(error) });
        }
      }),
    );
  }
  logger.info('nightly', { readers: uids.length, dealt, shelves, failed, bank: bank.version });
});

// ── Explore, for everybody ───────────────────────────────────────────────

export async function assembleExplore(bank: Bank, nowMs: number): Promise<void> {
  const day = today(nowMs);
  const days: string[] = [];
  for (let i = CLOSED_AFTER; i < CLOSED_AFTER + MONTH_DAYS; i++) {
    const t = new Date(nowMs - i * 86_400_000);
    days.push(dateKey(t.getUTCFullYear(), t.getUTCMonth() + 1, t.getUTCDate()));
  }
  const tallies: Tallies = new Map();
  for (let i = 0; i < days.length; i += 10) {
    const snap = await db.collection('tallies').where('__name__', 'in', days.slice(i, i + 10)).get();
    for (const d of snap.docs) {
      const n = d.get('n');
      if (n && typeof n === 'object') {
        tallies.set(d.id, new Map(Object.entries(n).filter(([, v]) => typeof v === 'number' && v > 0) as [string, number][]));
      }
    }
  }
  const totals = new Map<string, number>();
  const shards = await db.collection('totals').get();
  for (const d of shards.docs) {
    const n = d.get('n');
    if (n && typeof n === 'object') {
      for (const [id, v] of Object.entries(n)) if (typeof v === 'number' && v > 0) totals.set(id, v);
    }
  }
  const doc = buildGlobalExplore(bank, tallies, totals, day, nowMs);
  // How the crowd answers, as the scorecard last published it (scorecard.ts, crowdOf): counts
  // only, on cards enough readers answered. It rides on the lists every phone already reads.
  const crowd = (await db.collection('explore').doc('crowd').get()).get('cards');
  await db.collection('explore').doc('latest').set({ ...doc, crowd: crowd && typeof crowd === 'object' ? crowd : {} });
  logger.info('explore assembled', { day, bank: bank.version, week: doc.topWeek.length, loved: doc.loved.length });
}

export const buildExplore = onSchedule({ schedule: '5 * * * *', timeoutSeconds: 300 }, async () => {
  await assembleExplore(await dealingBank(), Date.now());
});

// ── How every card does ──────────────────────────────────────────────────

export const scorecard = onSchedule({ schedule: '20 4 * * *', timeZone: 'Etc/UTC', timeoutSeconds: 540, memory: '1GiB' }, async () => {
  const nowMs = Date.now();
  // The bank as written, quarantine and all: the scorecard is what decides it.
  const bank = await currentBank();
  const run = await runScorecard(db, bank, nowMs);
  logger.info('scorecard', {
    days: run.days,
    readers: run.readers,
    flagged: Object.keys(run.assessment.flags).length,
    reported: Object.keys(run.assessment.reports).length,
    quarantined: run.assessment.quarantined,
    bank: bank.version,
  });
});

export const cardStats = onRequest({ invoker: 'public', cors: true, maxInstances: 2, memory: '256MiB' }, async (req, res) => {
  if (req.method !== 'GET') {
    res.status(405).send('GET only');
    return;
  }
  const snap = await db.collection('quality').doc('latest').get();
  res.set('Cache-Control', 'public, max-age=600');
  if (!snap.exists) {
    res.status(404).json({ error: 'no scorecard yet' });
    return;
  }
  res.json(snap.data());
});

// ── Gone with the account ────────────────────────────────────────────────

export const onReaderDeleted = onDocumentDeleted('readers/{uid}', async (event) => {
  const uid = event.params.uid;
  await forgetReader(db, uid);
  logger.info('reader forgotten', { uid });
});
