// Astute's server: what it does for a reader, and when.
//
// What it does, in europe-west1, where the readers are:
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
// - `playDaily` (callable): a play of Today's five or a subject's three,
//   judged here and added once to the counts of everybody who played the
//   same cards that day (daily.ts), which the phone shows on the result.
// - `listenCard` (callable): a card of the reader's day read aloud by
//   ElevenLabs (listen.ts): its question and its answer as two clips in
//   Storage, made once for everybody and kept under the hash of their
//   words. The first card of a day for everyone, the rest for Astute+.
// - `listenAhead` (twice a day, 03:35 and 18:35 UTC): the next days' cards
//   of the readers who listen, made before they ask, so playing is instant.
//
// Every call to the model (the news, the questions, the coach's notes) is
// held to one budget, so much a month and so much a day (limits.ts), counted
// in ai/spend-{month} and ai/spend-{day} (budget.ts): once either is spent,
// nothing asks the model until it turns. What the voice reads is held to
// characters the same way, in listenSpend/{month} and listenSpend/{day}.
//
// The rules (firestore.rules) let no phone write a day, a profile,
// Explore or the day's games' counts: what the server dealt is what the
// server dealt, and what it counted is what it judged.

import Anthropic from '@anthropic-ai/sdk';
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { defineSecret } from 'firebase-functions/params';
import { setGlobalOptions } from 'firebase-functions/v2';
import { HttpsError, onCall, onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';

import { ALL_PER_DAY, MODEL, PER_DAY, SHARED, answer as answerAsk, askWorst, cacheKey, readAsk } from './ask.js';
import { Bank, currentBank, dateKey, localDate, parseDate, shiftDate } from './bank.js';
import { BudgetSpent, firestoreLedger, spendDay, withinBudget, type Usage } from './budget.js';
import { coachNote, coachWorst, readCoach } from './coach.js';
import { countPlay, readPlay } from './daily.js';
import { Tallies, buildGlobalExplore, CLOSED_AFTER, MONTH_DAYS } from './explore.js';
import {
  AHEAD_DAYS,
  type Ahead,
  type Shelf,
  aheadCards,
  configured,
  elevenLabs,
  firestoreCharLedger,
  firestoreClaims,
  listenTo,
  makeAhead,
  readListen,
  storageShelf,
} from './listen.js';
import { NEWS_LATEST_DAYS, NEWS_MODEL, askModel, fetchText, makePaper } from './news.js';
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

/** What the AI may spend: one budget, so much a month and a day (limits.ts),
 * for every call to the model, the news, the questions and the coach's notes. */
const ledger = firestoreLedger(db);

/** [call] asked within the budget, if the day and the month have room for
 * [worst], the most the call can cost; null, and nothing asked, when not. */
async function budgeted<T extends { usage: Usage | null }>(what: string, worst: number, call: () => Promise<T>): Promise<T | null> {
  try {
    return await withinBudget(ledger, spendDay(Date.now()), worst, what, call);
  } catch (e) {
    if (!(e instanceof BudgetSpent)) throw e;
    logger.warn("the AI's budget is spent", { what, day: e.day });
    return null;
  }
}

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
    const allowed = await db.runTransaction(async (t) => {
      const [m, e] = await Promise.all([t.get(mine), t.get(everyone)]);
      if ((m.get('n') ?? 0) >= PER_DAY || (e.get('n') ?? 0) >= ALL_PER_DAY) return false;
      t.set(mine, { n: FieldValue.increment(1) }, { merge: true });
      t.set(everyone, { n: FieldValue.increment(1) }, { merge: true });
      return true;
    });
    if (!allowed) throw new HttpsError('resource-exhausted', 'Enough for today.');
    try {
      const out = await budgeted('ask', askWorst(card, ask), () =>
        answerAsk(new Anthropic({ apiKey: anthropicKey.value() }), card, ask),
      );
      if (!out) {
        // Not the reader's doing: the question is given back, and the phone
        // says the answers are not available right now.
        await Promise.all([
          mine.set({ n: FieldValue.increment(-1) }, { merge: true }),
          everyone.set({ n: FieldValue.increment(-1) }, { merge: true }),
        ]);
        return { none: 'unavailable' };
      }
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

// ── The coach's note, for Astute+ ────────────────────────────────────────

export const coachWeek = onCall(
  { enforceAppCheck: false, secrets: [anthropicKey], maxInstances: 5, timeoutSeconds: 60 },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in, even anonymously.');
    const ask = readCoach(request.data);
    if (!ask) throw new HttpsError('invalid-argument', 'A week, and its numbers.');
    const presence = await db.collection('presence').doc(uid).get();
    if (presence.get('plus') !== true) throw new HttpsError('permission-denied', 'Astute+ only.');
    // Written once a week, then given again as it was.
    const kept = db.collection('readers').doc(uid).collection('coach').doc(`${ask.week}~${ask.lang}`);
    const before = (await kept.get()).get('text');
    if (typeof before === 'string' && before) return { text: before };
    const day = today(Date.now());
    const mine = db.collection('readers').doc(uid).collection('ai').doc(day);
    const everyone = db.collection('ai').doc(day);
    const allowed = await db.runTransaction(async (t) => {
      const [m, e] = await Promise.all([t.get(mine), t.get(everyone)]);
      if ((m.get('n') ?? 0) >= PER_DAY || (e.get('n') ?? 0) >= ALL_PER_DAY) return false;
      t.set(mine, { n: FieldValue.increment(1) }, { merge: true });
      t.set(everyone, { n: FieldValue.increment(1) }, { merge: true });
      return true;
    });
    if (!allowed) throw new HttpsError('resource-exhausted', 'Enough for today.');
    try {
      const out = await budgeted('coach', coachWorst(ask), () => coachNote(new Anthropic({ apiKey: anthropicKey.value() }), ask));
      if (!out) {
        // As with a question: the note is given back, not available right now.
        await Promise.all([
          mine.set({ n: FieldValue.increment(-1) }, { merge: true }),
          everyone.set({ n: FieldValue.increment(-1) }, { merge: true }),
        ]);
        return { none: 'unavailable' };
      }
      logger.info('coached', { week: ask.week, lang: ask.lang, answered: 'text' in out, cost: out.cost });
      if ('text' in out) {
        await kept.set({ text: out.text, model: MODEL, at: FieldValue.serverTimestamp() });
        return { text: out.text };
      }
      return { none: out.none };
    } catch (e) {
      logger.error('coach failed', { week: ask.week, error: String(e) });
      throw new HttpsError('unavailable', 'Try again in a moment.');
    }
  },
);

// ── The news, reasoned ───────────────────────────────────────────────────

/** The day and the hour in Rome, where most readers are: the paper is that
 * morning's. */
function romeNow(nowMs: number): { day: string; hour: number } {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Europe/Rome',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(new Date(nowMs));
  const part = (type: string) => parts.find((p) => p.type === type)?.value ?? '';
  return { day: `${part('year')}-${part('month')}-${part('day')}`, hour: Number(part('hour')) };
}

// Every hour from six in the morning, Rome time, until the day has its paper
// (news.ts): the first run after six makes it, and a run that fails or
// finds nothing to keep is tried again the next hour, three times at most.
// A day's paper is made once, whatever the hour.
export const newsMorning = onSchedule(
  { schedule: 'every 60 minutes', timeoutSeconds: 540, memory: '512MiB', maxInstances: 1, secrets: [anthropicKey] },
  async () => {
    const now = Date.now();
    const { day, hour } = romeNow(now);
    if (hour < 6) return;
    const paper = db.collection('news').doc(day);
    const before = await paper.get();
    const made = before.get('cards');
    if ((Array.isArray(made) && made.length > 0) || (before.get('tries') ?? 0) >= 3) return;
    await paper.set({ date: day, tries: FieldValue.increment(1) }, { merge: true });
    try {
      const client = new Anthropic({ apiKey: anthropicKey.value() });
      const out = await makePaper(askModel(client, { ledger, day: spendDay(now) }), fetchText, now, day);
      await paper.set(
        {
          cards: out.cards,
          model: NEWS_MODEL,
          cost: FieldValue.increment(out.cost),
          log: out.log,
          at: FieldValue.serverTimestamp(),
          // A morning the AI's budget stopped before any story is not
          // counted: the phones keep yesterday's paper, and the next hour
          // tries again.
          ...(out.spent && out.cards.length === 0 ? { tries: FieldValue.increment(-1) } : {}),
        },
        { merge: true },
      );
      logger.info('news', { day, cards: out.cards.length, cost: out.cost, spent: out.spent, log: out.log });
    } catch (e) {
      // A key the API turns away spends nothing and says nothing about the
      // day: the hour is not counted, so a key put right makes the day's
      // paper at the next run.
      const status = (e as { status?: unknown }).status;
      if (status === 401 || status === 403) {
        await paper.set({ tries: FieldValue.increment(-1) }, { merge: true });
      }
      logger.error('news failed', { day, status, error: String(e) });
    }
  },
);

/** The latest news, for the phone: the stories of the last week's papers,
 * the newest paper first, each story once, in the bank's own shape, with the
 * day of the newest paper that has any. Explore shows the newest paper's
 * front page as its latest news, each subject's page its own stories; a build
 * that knows only the morning's paper keeps showing the cards still dealt.
 * Open to every reader. */
export const newsToday = onCall({ enforceAppCheck: false, maxInstances: 10, memory: '256MiB' }, async () => {
  const recent = await db.collection('news').orderBy('date', 'desc').limit(NEWS_LATEST_DAYS).get();
  let date: string | null = null;
  const seen = new Set<string>();
  const cards: unknown[] = [];
  for (const doc of recent.docs) {
    const list = doc.get('cards');
    if (!Array.isArray(list) || list.length === 0) continue;
    date ??= doc.get('date') ?? null;
    for (const card of list) {
      const id = (card as { id?: unknown })?.id;
      if (typeof id === 'string') {
        if (seen.has(id)) continue;
        seen.add(id);
      }
      cards.push(card);
    }
  }
  return { date, cards };
});

// ── The day's games, counted ─────────────────────────────────────────────

export const playDaily = onCall({ enforceAppCheck: false, maxInstances: 10 }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in, even anonymously.');
  // The bank as written, quarantine and all: a card held out of the deal
  // since the phone dealt it is judged all the same.
  const play = readPlay(request.data, await currentBank(), Date.now());
  if (typeof play === 'string') {
    logger.warn('daily refused', { why: play });
    throw new HttpsError('invalid-argument', play);
  }
  try {
    const out = await countPlay(db, uid, play);
    logger.info('daily', { day: play.day, game: play.game, subject: play.subject, score: play.score, counted: out.counted, players: out.counts?.players });
    return out;
  } catch (e) {
    logger.error('daily failed', { day: play.day, game: play.game, error: String(e) });
    throw new HttpsError('unavailable', 'Try again in a moment.');
  }
});

// ── The day's five, read aloud ───────────────────────────────────────────

/** The key the cards are read aloud with, kept in Secret Manager. Without
 * one, the deploy keeps a stand-in there (cloud-deploy.yml) and Listen says
 * it is not configured. */
const elevenKey = defineSecret('ELEVENLABS_API_KEY');

/** The characters the voice may read, so many a month and a day (limits.ts). */
const listenLedger = firestoreCharLedger(db);
const listenClaims = firestoreClaims(db);

/** Where the clips are kept: the project's own bucket, once it is asked for. */
let shelf: Shelf | null = null;
const listenShelf = (): Shelf => (shelf ??= storageShelf(db, getStorage().bucket()));

export const listenCard = onCall(
  { enforceAppCheck: false, secrets: [elevenKey], maxInstances: 10, timeoutSeconds: 60, memory: '256MiB' },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in, even anonymously.');
    const ask = readListen(request.data);
    if (!ask) throw new HttpsError('invalid-argument', 'A card, and its day.');
    const key = elevenKey.value();
    if (!configured(key)) return { none: 'not-configured' };
    const nowMs = Date.now();
    // The reader's today, give or take a day: the free card is one a day,
    // and a phone may not make up days to hear more.
    if (!askableDate(ask.date, ask.tz, nowMs)) throw new HttpsError('invalid-argument', 'A day near today.');
    const [presence, bank] = await Promise.all([db.collection('presence').doc(uid).get(), dealingBank()]);
    // The plan as the phone last said it (presence), as askCard reads it:
    // the cards a reader may hear in a day bound what a phone that lied
    // could cost.
    const plus = presence.get('plus') === true;
    let out: Awaited<ReturnType<typeof listenTo>>;
    try {
      out = await listenTo(uid, plus, bank.byId.get(ask.card), ask, {
        configured: true,
        claims: listenClaims,
        shelf: listenShelf(),
        ledger: listenLedger,
        voice: elevenLabs(key),
        day: spendDay(nowMs),
      });
    } catch (e) {
      logger.error('listen failed', { card: ask.card, error: String(e) });
      throw new HttpsError('unavailable', 'Try again in a moment.');
    }
    if (out === 'plus') throw new HttpsError('permission-denied', 'Astute+ only.');
    if (out === 'enough') throw new HttpsError('resource-exhausted', 'Enough for today.');
    if ('none' in out && out.none !== 'nothing') {
      // Said once in the log with its reason: a key turned away, or an
      // account with no credit yet, is the owner's to put right.
      logger.warn('listen not available', { card: ask.card, none: out.none, why: 'why' in out ? out.why : undefined });
    } else {
      logger.info('listened', { card: ask.card, plus, heard: 'question' in out });
    }
    return out;
  },
);

// Twice a day, after the evening's tomorrows are dealt in Europe (nightly,
// from 17:00 local) and after the Americas': every reader who listened in
// the last week, their days still to come, made before they ask for them.
// A quarter of the day's characters at most, so a reader asking on the spot
// always finds room.
export const listenAhead = onSchedule(
  { schedule: '35 3,18 * * *', timeZone: 'Etc/UTC', timeoutSeconds: 540, maxInstances: 1, memory: '512MiB', secrets: [elevenKey] },
  async () => {
    const key = elevenKey.value();
    if (!configured(key)) return;
    const nowMs = Date.now();
    const recent = await db.collection('listeners').where('at', '>=', nowMs - AHEAD_DAYS * 86_400_000).get();
    const readers: Ahead[] = [];
    const uids = recent.docs.map((d) => d.id);
    for (let i = 0; i < uids.length; i += 8) {
      await Promise.all(
        uids.slice(i, i + 8).map(async (uid) => {
          try {
            const presence = await db.collection('presence').doc(uid).get();
            const tz = typeof presence.get('tz') === 'number' ? (presence.get('tz') as number) : 0;
            const today = localDate(nowMs, tz);
            const days = db.collection('readers').doc(uid).collection('days');
            const dealt = await db.getAll(days.doc(today), days.doc(shiftDate(today, 1)));
            readers.push({
              plus: presence.get('plus') === true,
              days: dealt.map((d) => (Array.isArray(d.get('cards')) ? (d.get('cards') as unknown[]).filter((c): c is string => typeof c === 'string') : [])),
            });
          } catch (error) {
            logger.warn('could not read a listener', { uid, error: String(error) });
          }
        }),
      );
    }
    const bank = await dealingBank();
    const cards = aheadCards(readers, bank);
    const run = await makeAhead(cards, { shelf: listenShelf(), ledger: listenLedger, voice: elevenLabs(key), day: spendDay(nowMs) });
    logger.info('listen ahead', { listeners: uids.length, cards: cards.length, ...run });
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
