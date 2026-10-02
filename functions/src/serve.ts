// What the server does for one reader, against Firestore.
//
// Thin on purpose: reading the reader, dealing, writing the day. The
// thinking is in profile.ts, deal.ts and explore.ts, which know nothing of
// a database and are tested without one.

import type { Firestore } from 'firebase-admin/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { Bank, Card, localDate, localHour, shiftDate } from './bank.js';
import { Deal, dealDay } from './deal.js';
import { Event, Presence, Profile, Snapshot, buildProfile, facts } from './profile.js';
import { PersonalExplore, buildPersonalExplore } from './explore.js';

/** How many days of the trace the profile is read from. */
export const TRACE_DAYS = 21;

/** A reader is dealt for while they were here within this many days. */
export const ACTIVE_DAYS = 14;

/** From this local hour on, tomorrow is dealt too, so the evening's prefetch and the morning find it. */
export const PREPARE_TOMORROW_FROM = 17;

export interface Reader {
  uid: string;
  snapshot: Snapshot;
  presence: Presence;
  activity: Map<string, Event[]>;
}

/** Everything the server needs to know about a reader, in three reads and a small query. */
export async function readReader(db: Firestore, uid: string, nowMs: number): Promise<Reader> {
  const ref = db.collection('readers').doc(uid);
  const since = new Date(nowMs - TRACE_DAYS * 86_400_000).toISOString().slice(0, 10);
  const [snap, presence, days] = await Promise.all([
    ref.get(),
    db.collection('presence').doc(uid).get(),
    ref.collection('activity').where('__name__', '>=', since).get(),
  ]);
  const activity = new Map<string, Event[]>();
  for (const d of days.docs) {
    const ev = d.get('ev');
    if (Array.isArray(ev)) activity.set(d.id, ev.filter((e) => e && typeof e.t === 'number' && typeof e.e === 'string'));
  }
  return {
    uid,
    snapshot: (snap.data() as Snapshot | undefined) ?? {},
    presence: (presence.data() as Presence | undefined) ?? {},
    activity,
  };
}

/** The document a phone reads at readers/{uid}/days/{date}. */
export function dayDocument(deal: Deal, bank: Bank, profile: Profile, nowMs: number): Record<string, unknown> {
  return {
    date: deal.date,
    edition: deal.edition,
    cards: deal.cards,
    own: deal.own,
    reviews: deal.reviews,
    ownCount: deal.ownCount,
    day: deal.day,
    bank: bank.version,
    dealtAt: nowMs,
    dealtBy: 'server',
    profile: facts(profile),
  };
}

/** Deals [date] for the reader and writes it, unless it is already there ([force] deals it again). */
export async function serveDay(db: Firestore, bank: Bank, reader: Reader, date: string, nowMs: number, force = false): Promise<Record<string, unknown>> {
  const ref = db.collection('readers').doc(reader.uid).collection('days').doc(date);
  if (!force) {
    const had = await ref.get();
    if (had.exists) return had.data() as Record<string, unknown>;
  }
  const profile = buildProfile(reader.snapshot, reader.activity, reader.presence, bank, nowMs);
  const deal = dealDay(bank, profile, date, reader.uid);
  const doc = dayDocument(deal, bank, profile, nowMs);
  await ref.set(doc);
  await db.collection('readers').doc(reader.uid).collection('profile').doc('current').set({
    ...facts(profile),
    levels: profile.levels,
    shape: profile.shape,
    at: nowMs,
  });
  return doc;
}

/** Explore as the reader sees it, written at readers/{uid}/explore/current. */
export async function serveExplore(db: Firestore, bank: Bank, reader: Reader, nowMs: number): Promise<PersonalExplore> {
  const profile = buildProfile(reader.snapshot, reader.activity, reader.presence, bank, nowMs);
  const doc = buildPersonalExplore(bank, profile, localDate(nowMs, profile.tz), nowMs);
  await db.collection('readers').doc(reader.uid).collection('explore').doc('current').set(doc);
  return doc;
}

/** The dates a reader should find dealt at [nowMs]: their today, and their tomorrow from the late afternoon. */
export function datesToPrepare(presence: Presence, nowMs: number): string[] {
  const tz = typeof presence.tz === 'number' ? presence.tz : 0;
  const today = localDate(nowMs, tz);
  return localHour(nowMs, tz) >= PREPARE_TOMORROW_FROM ? [today, shiftDate(today, 1)] : [today];
}

/** Whether a date a phone asks for is one the server will deal: their local yesterday to two days on. */
export function askableDate(date: string, tz: number, nowMs: number): boolean {
  const today = localDate(nowMs, tz);
  const allowed = new Set([shiftDate(today, -1), today, shiftDate(today, 1), shiftDate(today, 2)]);
  return allowed.has(date);
}

/** How long the trace is kept: what the profile reads, and nothing older. */
export const KEEP_TRACE_DAYS = TRACE_DAYS;

/**
 * Clears the reader's trace older than [KEEP_TRACE_DAYS], and the days dealt
 * more than a month ago: the profile reads three weeks, so nothing older
 * says anything, and the privacy policy promises it is cleared.
 */
export async function pruneReader(db: Firestore, uid: string, nowMs: number): Promise<number> {
  const ref = db.collection('readers').doc(uid);
  const traceBefore = new Date(nowMs - KEEP_TRACE_DAYS * 86_400_000).toISOString().slice(0, 10);
  const daysBefore = new Date(nowMs - 31 * 86_400_000).toISOString().slice(0, 10);
  const [oldTrace, oldDays] = await Promise.all([
    ref.collection('activity').where('__name__', '<', traceBefore).limit(60).get(),
    ref.collection('days').where('__name__', '<', daysBefore).limit(60).get(),
  ]);
  const docs = [...oldTrace.docs, ...oldDays.docs];
  if (docs.length === 0) return 0;
  const batch = db.batch();
  for (const d of docs) batch.delete(d.ref);
  await batch.commit();
  return docs.length;
}

/** Every trace, day, profile and shelf a reader had: gone with their account. */
export async function forgetReader(db: Firestore, uid: string): Promise<void> {
  await db.recursiveDelete(db.collection('readers').doc(uid));
  await db.collection('presence').doc(uid).delete().catch(() => undefined);
}

export { FieldValue };
export type { Card };
