// Astute's server: what it does for a reader, and when.
//
// Five things, in europe-west1, where the readers are:
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
//   not hold it.
// - `onReaderDeleted`: when a reader deletes their account and the phone
//   removes readers/{uid}, everything under it — the trace, the days, the
//   profile, the shelf — and their presence go with it.
//
// The rules (firestore.rules) let no phone write a day, a profile or
// Explore: what the server dealt is what the server dealt.

import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentDeleted } from 'firebase-functions/v2/firestore';
import { logger } from 'firebase-functions';

import { Bank, currentBank, dateKey, parseDate } from './bank.js';
import { Tallies, buildGlobalExplore, CLOSED_AFTER, MONTH_DAYS } from './explore.js';
import { search as searchBank } from './search.js';
import { ACTIVE_DAYS, askableDate, datesToPrepare, forgetReader, pruneReader, readReader, serveDay, serveExplore } from './serve.js';

initializeApp();
setGlobalOptions({ region: 'europe-west1', maxInstances: 20, memory: '512MiB' });

const db = getFirestore();

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
  const bank = await currentBank();
  const reader = await readReader(db, uid, nowMs);
  if (typeof reader.presence.tz !== 'number') reader.presence.tz = tz;
  const doc = await serveDay(db, bank, reader, date, nowMs, data.force === true);
  logger.info('dealt', { uid, date, cards: (doc.cards as unknown[]).length, own: (doc.own as unknown[]).length });
  return doc;
});

// ── The pool, asked a question ───────────────────────────────────────────

export const search = onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in, even anonymously.');
  const data = (request.data ?? {}) as { q?: unknown };
  const q = typeof data.q === 'string' ? data.q.slice(0, 80) : '';
  const bank = await currentBank();
  const cards = searchBank(bank, q);
  return { q, cards, version: bank.version };
});

// ── Every reader's day, ahead of them ────────────────────────────────────

export const nightly = onSchedule({ schedule: 'every 60 minutes', timeoutSeconds: 540 }, async () => {
  const nowMs = Date.now();
  const bank = await currentBank();
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
  await db.collection('explore').doc('latest').set(doc);
  logger.info('explore assembled', { day, bank: bank.version, week: doc.topWeek.length, loved: doc.loved.length });
}

export const buildExplore = onSchedule({ schedule: '5 * * * *', timeoutSeconds: 300 }, async () => {
  await assembleExplore(await currentBank(), Date.now());
});

// ── Gone with the account ────────────────────────────────────────────────

export const onReaderDeleted = onDocumentDeleted('readers/{uid}', async (event) => {
  const uid = event.params.uid;
  await forgetReader(db, uid);
  logger.info('reader forgotten', { uid });
});
