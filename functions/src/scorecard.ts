// How every card does with the readers, added up once a day.
//
// A card is checked before it ships — the gate, the critic, a quote found
// on the page it cites — and still the readers are the only people who
// read all of the bank. This is where what they do comes back to the
// cards. Once a day the server takes a closed day of everybody's trace
// (the phone files an event under the UTC day it happened, and one that
// was offline sends it late, so a day is counted two days on), adds it to
// each card's running totals, reads what readers reported, and works out:
//
// - the flags: a card answered right far more or far less often than its
//   label says, one whose marked answer the crowd overwhelmingly rejects,
//   one readers throw down, one they keep, one they report;
// - the quarantine: cards enough readers say are untrue, which the dealer
//   stops dealing until somebody has checked them. A card's `checked` date,
//   set when a person or the monthly re-check confirms it, answers every
//   report made before it, and the card comes back;
// - the scorecard the tools read (tool/quality/): numbers per card, and
//   nothing about who.
//
// The thinking is here without a database and is tested without one; the
// reading and the writing are at the bottom, and thin.

import type { Firestore } from 'firebase-admin/firestore';
import { Bank, Card, Difficulty, graded, shiftDate } from './bank.js';
import type { Event } from './profile.js';

// ── What is counted ──────────────────────────────────────────────────────

/**
 * What readers did with one card, added up. Every number but the answers is
 * a count of reader-days — a reader who opens a card three times in a day
 * opened it once that day — so a card that is shown often is not a card
 * that is liked often.
 */
export interface CardTally {
  /** Reader-days on which anything at all happened to the card. */
  readers: number;
  /** Reader-days it was in front of the reader: dealt and come up, opened, or read elsewhere. */
  exposures: number;
  /** Reader-days it sat on an Explore shelf. */
  seen: number;
  flips: number;
  hints: number;
  /** First answers — reviews are counted apart — and of those, the right ones. */
  answers: number;
  right: number;
  /** First answers given at [SURE] or more, and of those, the wrong ones. */
  sure: number;
  sureWrong: number;
  reviews: number;
  reviewsRight: number;
  /** Time on the card, summed, over [dwells] readings of it. */
  dwellMs: number;
  dwells: number;
  likes: number;
  unlikes: number;
  saves: number;
  unsaves: number;
  dislikes: number;
  undislikes: number;
  shares: number;
  said: number;
}

/** The order the numbers are stored in: one short array a card, so a shard stays small. */
export const TALLY_FIELDS = [
  'readers', 'exposures', 'seen', 'flips', 'hints', 'answers', 'right', 'sure', 'sureWrong',
  'reviews', 'reviewsRight', 'dwellMs', 'dwells', 'likes', 'unlikes', 'saves', 'unsaves',
  'dislikes', 'undislikes', 'shares', 'said',
] as const satisfies readonly (keyof CardTally)[];

/** A tally, and the first answers by option on a card with options. */
export interface Counted {
  tally: CardTally;
  picks: number[];
}

/** The confidence from which a reader is sure: the top two of the app's steps. */
export const SURE = 80;

export function emptyTally(): CardTally {
  return Object.fromEntries(TALLY_FIELDS.map((f) => [f, 0])) as unknown as CardTally;
}

/** One reader's day, card by card. */
export function tallyDay(events: Event[]): Map<string, Counted> {
  // Which gestures each card got that day, and the first answers.
  const did = new Map<string, Set<string>>();
  const first = new Map<string, Event>();
  const firstReview = new Map<string, Event>();
  const dwell = new Map<string, number[]>();
  for (const e of [...events].sort((a, b) => a.t - b.t)) {
    const id = e.c;
    if (typeof id !== 'string' || id.length === 0) continue;
    const gestures = did.get(id) ?? new Set<string>();
    did.set(id, gestures);
    gestures.add(e.e);
    if (e.e === 'ans') {
      const into = e.rv === true ? firstReview : first;
      if (!into.has(id)) into.set(id, e);
    }
    if (e.e === 'next' && typeof e.ms === 'number' && e.ms > 0 && e.ms < 30 * 60_000) {
      dwell.set(id, [...(dwell.get(id) ?? []), e.ms]);
    }
  }
  const out = new Map<string, Counted>();
  for (const [id, gestures] of did) {
    const t = emptyTally();
    const picks: number[] = [];
    t.readers = 1;
    const had = (code: string) => (gestures.has(code) ? 1 : 0);
    t.exposures = gestures.has('view') || gestures.has('open') || gestures.has('read') ? 1 : 0;
    t.seen = had('seen');
    t.flips = had('flip');
    t.hints = had('hint');
    t.likes = had('like');
    t.unlikes = had('unlike');
    t.saves = had('save');
    t.unsaves = had('unsave');
    t.dislikes = had('skip');
    t.undislikes = had('unskip');
    t.shares = had('share');
    t.said = had('said');
    const a = first.get(id);
    if (a) {
      t.answers = 1;
      if (a.ok === true) t.right = 1;
      if (typeof a.cf === 'number' && a.cf >= SURE) {
        t.sure = 1;
        if (a.ok === false) t.sureWrong = 1;
      }
      if (typeof a.a === 'number' && Number.isInteger(a.a) && a.a >= 0 && a.a < 12) {
        while (picks.length <= a.a) picks.push(0);
        picks[a.a] = 1;
      }
    }
    const r = firstReview.get(id);
    if (r) {
      t.reviews = 1;
      if (r.ok === true) t.reviewsRight = 1;
    }
    for (const ms of dwell.get(id) ?? []) {
      t.dwellMs += ms;
      t.dwells += 1;
    }
    out.set(id, { tally: t, picks });
  }
  return out;
}

/** Adds [from] into [into]. */
export function addCounted(into: Counted, from: Counted): Counted {
  for (const f of TALLY_FIELDS) into.tally[f] += from.tally[f];
  for (let i = 0; i < from.picks.length; i++) {
    while (into.picks.length <= i) into.picks.push(0);
    into.picks[i] += from.picks[i];
  }
  return into;
}

/** As stored: the numbers in [TALLY_FIELDS] order. */
export function encode(c: Counted): number[] {
  return TALLY_FIELDS.map((f) => c.tally[f]);
}

export function decode(numbers: unknown, picks: unknown): Counted {
  const tally = emptyTally();
  if (Array.isArray(numbers)) {
    TALLY_FIELDS.forEach((f, i) => {
      const v = numbers[i];
      if (typeof v === 'number' && Number.isFinite(v)) tally[f] = v;
    });
  }
  return { tally, picks: Array.isArray(picks) ? picks.map((v) => (typeof v === 'number' ? v : 0)) : [] };
}

/** Where a card's totals are kept: the part of its id before the first dash, as for the counts. */
export function shardOf(cardId: string): string {
  const dash = cardId.indexOf('-');
  return dash < 0 ? cardId : cardId.slice(0, dash);
}

// ── What it says ─────────────────────────────────────────────────────────

/** Why a reader says a card is wrong: lib/sync/reports.dart and firestore.rules. */
export const REASONS = ['fact', 'answer', 'source', 'unclear', 'typo', 'other'] as const;
export type Reason = (typeof REASONS)[number];

/** The reasons that say the card is untrue. */
export const FACTUAL: ReadonlySet<Reason> = new Set(['fact', 'answer', 'source']);

/** One reader's report, as the server reads it. */
export interface Report {
  card: string;
  reason: Reason;
  note: string;
  at: number;
  locale?: string;
}

/** Answers before a rate says anything about a card. */
export const MIN_ANSWERS = 30;
/** Readers in front of a card before a keep or a throw rate does. */
export const MIN_EXPOSURES = 30;
/** Readers saying a card is untrue that take it out of the deal. */
export const QUARANTINE_REPORTERS = 3;
/** Readers in front of a card before its numbers are published. */
export const MIN_PUBLIC = 5;

/**
 * How often a card of each label is answered right, roughly: a card well
 * outside its band is labelled wrong. Wide on purpose — a trap card is meant
 * to catch most readers, and its label says hard.
 */
export const EXPECTED_RIGHT: Record<Difficulty, [number, number]> = {
  easy: [0.55, 1],
  medium: [0.3, 0.9],
  hard: [0, 0.7],
};

/** The 95% Wilson interval of [k] in [n]: what a rate can be, given how few it rests on. */
export function wilson(k: number, n: number, z = 1.96): [number, number] {
  if (n <= 0) return [0, 1];
  const p = Math.min(1, Math.max(0, k / n));
  const z2 = z * z;
  const denom = 1 + z2 / n;
  const centre = (p + z2 / (2 * n)) / denom;
  const half = (z * Math.sqrt((p * (1 - p)) / n + z2 / (4 * n * n))) / denom;
  return [Math.max(0, centre - half), Math.min(1, centre + half)];
}

export type Flag =
  | 'keySuspect'
  | 'tooEasy'
  | 'tooHard'
  | 'thrown'
  | 'kept'
  | 'reported'
  | 'disputed'
  | 'quarantined';

/** The numbers a tool gets for one card. */
export interface PublicCard {
  exposures: number;
  answers: number;
  right: number;
  sure: number;
  sureWrong: number;
  kept: number;
  thrown: number;
  dwellMs: number;
  picks?: number[];
}

export interface Assessment {
  flags: Record<string, Flag[]>;
  quarantined: string[];
  /** Reports that still stand, by card and reason: none made before the card was last checked. */
  reports: Record<string, Partial<Record<Reason, number>>>;
  cards: Record<string, PublicCard>;
}

/** When a card was last confirmed by a person or the re-check, if it was. */
export function checkedAt(card: Card): number | null {
  const v = card.checked;
  if (typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(v)) return null;
  const t = Date.parse(`${v}T00:00:00Z`);
  return Number.isFinite(t) ? t : null;
}

/** Reports still standing: on a card in the bank, made after it was last checked. */
export function standing(bank: Bank, reports: Report[]): Report[] {
  return reports.filter((r) => {
    const card = bank.byId.get(r.card);
    if (!card) return false;
    const checked = checkedAt(card);
    return checked === null || r.at >= checked;
  });
}

/** Whether the crowd overwhelmingly picks one other option, and almost nobody the marked one. */
export function keySuspect(card: Card, c: Counted): boolean {
  const correct = card.correct;
  if (card.kind !== 'pickOne' || typeof correct !== 'number') return false;
  const n = c.tally.answers;
  if (n < MIN_ANSWERS) return false;
  const [, upper] = wilson(c.tally.right, n);
  const topOther = Math.max(0, ...c.picks.map((v, i) => (i === correct ? 0 : v)));
  return upper < 0.15 && topOther / n >= 0.6;
}

export function assess(bank: Bank, counted: Map<string, Counted>, reports: Report[]): Assessment {
  const out: Assessment = { flags: {}, quarantined: [], reports: {}, cards: {} };
  const reporters = new Map<string, Partial<Record<Reason, number>>>();
  for (const r of standing(bank, reports)) {
    const by = reporters.get(r.card) ?? {};
    by[r.reason] = (by[r.reason] ?? 0) + 1;
    reporters.set(r.card, by);
  }
  const ids = new Set([...counted.keys(), ...reporters.keys()]);
  for (const id of [...ids].sort()) {
    const card = bank.byId.get(id);
    if (!card) continue;
    const c = counted.get(id) ?? { tally: emptyTally(), picks: [] };
    const t = c.tally;
    const flags: Flag[] = [];
    const reasons = reporters.get(id) ?? {};
    const factual = [...FACTUAL].reduce((n, r) => n + (reasons[r] ?? 0), 0);
    const suspect = keySuspect(card, c);
    if (suspect) flags.push('keySuspect');
    if (graded(card) && t.answers >= MIN_ANSWERS) {
      const [low, high] = wilson(t.right, t.answers);
      const [from, to] = EXPECTED_RIGHT[card.difficulty] ?? [0, 1];
      if (low > to) flags.push('tooEasy');
      if (high < from) flags.push('tooHard');
    }
    const thrown = Math.max(0, t.dislikes - t.undislikes);
    const kept = Math.max(0, t.likes - t.unlikes) + Math.max(0, t.saves - t.unsaves) + t.shares + t.said;
    if (t.exposures >= MIN_EXPOSURES) {
      if (wilson(Math.min(thrown, t.exposures), t.exposures)[0] >= 0.1) flags.push('thrown');
      if (wilson(Math.min(kept, t.exposures), t.exposures)[0] >= 0.2) flags.push('kept');
    }
    if (Object.keys(reasons).length > 0) {
      flags.push('reported');
      out.reports[id] = reasons;
    }
    if (factual >= 2) flags.push('disputed');
    if (factual >= QUARANTINE_REPORTERS || (suspect && factual >= 1)) {
      flags.push('quarantined');
      out.quarantined.push(id);
    }
    if (flags.length > 0) out.flags[id] = flags;
    if (t.exposures >= MIN_PUBLIC || flags.length > 0) {
      out.cards[id] = {
        exposures: t.exposures,
        answers: t.answers,
        right: t.right,
        sure: t.sure,
        sureWrong: t.sureWrong,
        kept,
        thrown,
        dwellMs: t.dwells > 0 ? Math.round(t.dwellMs / t.dwells) : 0,
        ...(c.picks.length > 0 ? { picks: c.picks } : {}),
      };
    }
  }
  return out;
}

/**
 * The bank as the dealer should see it: [ids] taken out of the deal, the way
 * a retired card is — still known by id, never dealt.
 */
export function withheld(bank: Bank, ids: ReadonlySet<string>): Bank {
  if (ids.size === 0) return bank;
  let touched = false;
  const cards = bank.cards.map((c) => {
    if (!ids.has(c.id) || c.disabled) return c;
    touched = true;
    return { ...c, disabled: true };
  });
  if (!touched) return bank;
  return new Bank({
    version: bank.version,
    built: bank.built,
    cards,
    editions: Object.fromEntries([...bank.editions].map(([k, v]) => [String(k), v])),
    commons: Object.fromEntries([...bank.commons].map(([k, v]) => [String(k), v])),
  });
}

// ── Against Firestore ────────────────────────────────────────────────────

/** A day is counted this many days after it began, when late phones have sent it. */
export const COUNT_AFTER = 2;
/** How far back a run looks for days it has not counted: well inside the 21 days of trace kept. */
export const CATCH_UP = 7;

const MS_DAY = 86_400_000;

function utcDay(ms: number): string {
  return new Date(ms).toISOString().slice(0, 10);
}

/** The closed days a run at [nowMs] should have counted, oldest first. */
export function daysToCount(nowMs: number): string[] {
  const last = shiftDate(utcDay(nowMs), -COUNT_AFTER);
  const out: string[] = [];
  for (let i = CATCH_UP - 1; i >= 0; i--) out.push(shiftDate(last, -i));
  return out;
}

function toMillis(v: unknown): number {
  if (typeof v === 'number') return v;
  if (v && typeof (v as { toMillis?: unknown }).toMillis === 'function') return (v as { toMillis: () => number }).toMillis();
  return 0;
}

/** Every reader's day [day], added up card by card. */
export async function countDay(db: Firestore, day: string): Promise<{ counted: Map<string, Counted>; readers: number }> {
  const start = Date.parse(`${day}T00:00:00Z`);
  // Everybody who was here on the day was here on or after it.
  const here = await db.collection('presence').where('lastSeen', '>=', start).select().get();
  const counted = new Map<string, Counted>();
  let readers = 0;
  const refs = here.docs.map((d) => db.collection('readers').doc(d.id).collection('activity').doc(day));
  for (let i = 0; i < refs.length; i += 100) {
    const snaps = await db.getAll(...refs.slice(i, i + 100), { fieldMask: ['ev'] });
    for (const snap of snaps) {
      const ev = snap.get('ev');
      if (!Array.isArray(ev) || ev.length === 0) continue;
      readers++;
      const events = ev.filter((e): e is Event => !!e && typeof e.t === 'number' && typeof e.e === 'string');
      for (const [id, c] of tallyDay(events)) {
        const into = counted.get(id);
        counted.set(id, into ? addCounted(into, c) : c);
      }
    }
  }
  return { counted, readers };
}

/** Adds a day's counts into the running totals, once: a shard that has the day already is left alone. */
export async function addDay(db: Firestore, day: string, counted: Map<string, Counted>): Promise<number> {
  const byShard = new Map<string, Map<string, Counted>>();
  for (const [id, c] of counted) {
    const shard = shardOf(id);
    if (!byShard.has(shard)) byShard.set(shard, new Map());
    byShard.get(shard)!.set(id, c);
  }
  let written = 0;
  for (const [shard, cards] of byShard) {
    const ref = db.collection('scorecard').doc(shard);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const days: string[] = Array.isArray(snap.get('days')) ? snap.get('days') : [];
      if (days.includes(day)) return;
      const stored = (snap.get('cards') ?? {}) as Record<string, unknown>;
      const picks = (snap.get('picks') ?? {}) as Record<string, unknown>;
      for (const [id, c] of cards) {
        const total = addCounted(decode(stored[id], picks[id]), c);
        stored[id] = encode(total);
        if (total.picks.length > 0) picks[id] = total.picks;
      }
      tx.set(ref, {
        fields: [...TALLY_FIELDS],
        cards: stored,
        picks,
        days: [...days, day].sort().slice(-60),
      });
      written++;
    });
  }
  return written;
}

/** Every card's running totals. */
export async function readTotals(db: Firestore): Promise<Map<string, Counted>> {
  const out = new Map<string, Counted>();
  const shards = await db.collection('scorecard').get();
  for (const d of shards.docs) {
    const cards = (d.get('cards') ?? {}) as Record<string, unknown>;
    const picks = (d.get('picks') ?? {}) as Record<string, unknown>;
    for (const [id, numbers] of Object.entries(cards)) out.set(id, decode(numbers, picks[id]));
  }
  return out;
}

/** Every report readers have made, as the server reads them. */
export async function readReports(db: Firestore): Promise<Report[]> {
  const snap = await db.collectionGroup('reports').get();
  const out: Report[] = [];
  for (const d of snap.docs) {
    const card = d.get('card');
    const reason = d.get('reason');
    if (typeof card !== 'string' || !(REASONS as readonly string[]).includes(reason)) continue;
    const note = d.get('note');
    const locale = d.get('locale');
    out.push({
      card,
      reason: reason as Reason,
      note: typeof note === 'string' ? note.slice(0, 500) : '',
      at: toMillis(d.get('at')),
      ...(typeof locale === 'string' ? { locale } : {}),
    });
  }
  return out;
}

/** The days the scorecard has counted, in full. */
async function ledger(db: Firestore): Promise<string[]> {
  const snap = await db.collection('quality').doc('ledger').get();
  const days = snap.get('days');
  return Array.isArray(days) ? days.filter((d): d is string => typeof d === 'string') : [];
}

/**
 * The run: the closed days not yet counted, added in; then the whole bank
 * assessed and written to quality/latest, which the dealer and the tools
 * read, and the notes readers wrote to quality/notes, which only the people
 * who fix cards read (in the Firebase console: the rules let no phone).
 */
export async function runScorecard(db: Firestore, bank: Bank, nowMs: number): Promise<{ days: string[]; readers: number; assessment: Assessment }> {
  const done = new Set(await ledger(db));
  const counted: string[] = [];
  let readers = 0;
  for (const day of daysToCount(nowMs)) {
    if (done.has(day)) continue;
    const { counted: cards, readers: n } = await countDay(db, day);
    await addDay(db, day, cards);
    done.add(day);
    await db.collection('quality').doc('ledger').set({ days: [...done].sort().slice(-90) });
    counted.push(day);
    readers += n;
  }
  const totals = await readTotals(db);
  const reports = await readReports(db);
  const assessment = fit(assess(bank, totals, reports));
  await db.collection('quality').doc('latest').set({
    at: nowMs,
    bank: bank.version,
    days: [...done].sort().slice(-90),
    thresholds: {
      minAnswers: MIN_ANSWERS,
      minExposures: MIN_EXPOSURES,
      quarantineReporters: QUARANTINE_REPORTERS,
      minPublic: MIN_PUBLIC,
      sure: SURE,
    },
    ...assessment,
  });
  await db.collection('quality').doc('notes').set({ at: nowMs, cards: notesOf(standing(bank, reports)) });
  return { days: counted, readers, assessment };
}

/** A Firestore document holds a mebibyte; these stay well under it. */
const MAX_DOC_CHARS = 800_000;

/**
 * The assessment as it can be stored: when the numbers per card would not
 * fit one document, the cards fewest readers met are left out of them —
 * never out of the flags, the reports or the quarantine.
 */
export function fit(a: Assessment, limit = MAX_DOC_CHARS): Assessment {
  if (JSON.stringify(a).length <= limit) return a;
  const kept = Object.entries(a.cards).sort((x, y) => (a.flags[y[0]] ? 1 : 0) - (a.flags[x[0]] ? 1 : 0) || y[1].exposures - x[1].exposures);
  const cards: Record<string, PublicCard> = {};
  let size = JSON.stringify({ ...a, cards: {} }).length;
  for (const [id, c] of kept) {
    size += JSON.stringify(c).length + id.length + 4;
    if (size > limit) break;
    cards[id] = c;
  }
  return { ...a, cards };
}

/** Readers' notes by card, newest first, for the person fixing cards: twenty a card, and a document's worth in all. */
export function notesOf(reports: Report[], limit = MAX_DOC_CHARS): Record<string, { reason: Reason; note: string; at: number; locale?: string }[]> {
  const out: Record<string, { reason: Reason; note: string; at: number; locale?: string }[]> = {};
  let size = 0;
  for (const r of [...reports].filter((r) => r.note).sort((a, b) => b.at - a.at)) {
    const list = (out[r.card] ??= []);
    if (list.length >= 20) continue;
    size += r.note.length + 80;
    if (size > limit) break;
    list.push({ reason: r.reason, note: r.note, at: r.at, ...(r.locale ? { locale: r.locale } : {}) });
  }
  return out;
}

let withheldIds: ReadonlySet<string> = new Set();
let withheldAt = 0;
const WITHHELD_FRESH_MS = 10 * 60 * 1000;

/** The cards in quarantine, read at most every ten minutes. Never throws: none, when it cannot be read. */
export async function currentWithheld(db: Firestore, nowMs = Date.now()): Promise<ReadonlySet<string>> {
  if (nowMs - withheldAt < WITHHELD_FRESH_MS) return withheldIds;
  withheldAt = nowMs;
  try {
    // The list alone: the numbers beside it are most of the document.
    const [snap] = await db.getAll(db.collection('quality').doc('latest'), { fieldMask: ['quarantined'] });
    const ids = snap.get('quarantined');
    withheldIds = new Set(Array.isArray(ids) ? ids.filter((v): v is string => typeof v === 'string') : []);
  } catch {
    // The last list read stands.
  }
  return withheldIds;
}
