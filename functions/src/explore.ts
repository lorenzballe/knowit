// Explore, assembled on the server.
//
// The shelves the phone used to compute for itself, put together once for
// everybody — today's shelf, a question from every subject, the top of the
// week and the month and loved since the start, from real readers' counts
// alone — and once per reader, from
// their profile, the shelves that are theirs: their subject, what the
// profile puts first, and where they live. Every card on a shelf travels
// whole, so a phone reads one document and draws, and a card the phone's
// own bank has not got yet still shows. A card about a place is only ever
// on the last of these, for a reader who lives there.

import { Bank, Card, asks, graded, isPlaceCard, dateKey, topicName } from './bank.js';
import { Profile } from './profile.js';
import { fit, leanOf, placeCards } from './deal.js';
import { fitRank } from './place.js';
import { keyed } from './rng.js';

// ── The shelves that turn over (pickedPills) ─────────────────────────────

const rank = (c: Card) => (c.difficulty === 'hard' ? 0 : c.difficulty === 'medium' ? 1 : 2);

/** A rotating pick, the same for everybody: hardest first, then asking, then the seed's order, round the subjects. */
export function pickedCards(bank: Bank, seed: string, count: number, topic?: string): Card[] {
  const pool = (topic ? bank.live.filter((c) => c.topic === topic) : [...bank.live]).sort((a, b) => {
    const byRank = rank(a) - rank(b);
    if (byRank) return byRank;
    const byAsking = (asks(a) ? 0 : 1) - (asks(b) ? 0 : 1);
    if (byAsking) return byAsking;
    return keyed(`${seed}${a.id}`) - keyed(`${seed}${b.id}`);
  });
  if (topic) return pool.slice(0, count);
  return roundTheSubjects(pool, seed, count);
}

/**
 * A question from every subject, the same for everybody: the cards with a right answer to give, in the seed's
 * order, round the subjects. Not ranked by how hard they are — For the sharpest, on the phone, is the shelf for
 * that — so the rows are what their name says. The phone's `askingPills`, card for card.
 */
export function askingCards(bank: Bank, seed: string, count: number): Card[] {
  const pool = bank.live.filter(graded).sort((a, b) => {
    const byKey = keyed(`${seed}${a.id}`) - keyed(`${seed}${b.id}`);
    // Two ids can share a key; their own order settles it, by code unit, as Dart's compareTo does.
    return byKey || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0);
  });
  return roundTheSubjects(pool, seed, count);
}

/** [pool] dealt one subject at a time, round the subjects in the seed's order of them, until there are [count]. */
function roundTheSubjects(pool: Card[], seed: string, count: number): Card[] {
  const byTopic = new Map<string, Card[]>();
  for (const c of pool) {
    const list = byTopic.get(c.topic) ?? [];
    list.push(c);
    byTopic.set(c.topic, list);
  }
  // Keyed by the subject's shown name, as the phone keys it.
  const order = [...byTopic.keys()].sort((a, b) => keyed(`${seed}${topicName(a)}`) - keyed(`${seed}${topicName(b)}`));
  const picked: Card[] = [];
  for (let round = 0; picked.length < count; round++) {
    let took = false;
    for (const name of order) {
      const subject = byTopic.get(name) as Card[];
      if (round >= subject.length) continue;
      picked.push(subject[round]);
      took = true;
      if (picked.length === count) break;
    }
    if (!took) break;
  }
  return picked;
}

export const daySeed = (key: string): string => key;
export const monthSeed = (key: string): string => key.slice(0, 7);
export const ALL_TIME_SEED = 'astuto-all-time';

// ── The top lists ────────────────────────────────────────────────────────
//
// What real readers held on to, and nothing else. There was a launch crowd
// under these counts once — a made-up following, laid under the real one so
// the list was never empty — and a list that says it is what readers liked
// cannot be partly invented, however small the part. So a list is real counts
// only, and until real counts are enough to make one (LIST_READERS,
// LIST_CARDS) it goes out empty: the phone then puts Astute's own picks in
// its place, said to be Astute's, and an older phone leaves the shelf out.

export const WEEK_DAYS = 7;
export const MONTH_DAYS = 30;
export const CLOSED_AFTER = 2;

/**
 * How few readers a card can have and still be on a list for everybody. A
 * count is of readers — a phone adds one to a card the first time its reader
 * likes, saves or says it, and never again — and under three it is one
 * person's taste, or a household's, not what readers kept. The phone's
 * `Tallies.listReaders` (lib/sync/tally.dart).
 */
export const LIST_READERS = 3;

/**
 * How few cards make a list worth showing: a top of one or two is not a top.
 * The phone's `Tallies.listCards`.
 */
export const LIST_CARDS = 5;

export interface Ranked { id: string; readers: number }

/** The counts the store holds, day by day. */
export type Tallies = Map<string, Map<string, number>>;

/**
 * [ranked] as it may be shown to everybody: the cards fewer than LIST_READERS
 * readers held left off, and nothing at all while fewer than LIST_CARDS are
 * left. The phone's `Tallies.worthShowing`, card for card.
 */
export function worthShowing(ranked: Ranked[]): Ranked[] {
  const held = ranked.filter((r) => r.readers >= LIST_READERS);
  return held.length >= LIST_CARDS ? held : [];
}

/**
 * Whether a card may be on a list for everybody: one still dealt to everybody.
 * The counts are everybody's, and a card about a place is counted when the
 * readers who live there keep it; a retired card is never shown again; and an
 * idea of a book is read whole, from its own row, never one idea alone.
 */
const listable = (c: Card | undefined): c is Card => !!c && !c.disabled && !isPlaceCard(c) && !c.book;

/** The list for the [days] days that closed most recently, at [todayUtc]: what real readers held, most first. */
export function topList(bank: Bank, tallies: Tallies, todayUtc: string, days: number, limit = 10, where?: (c: Card) => boolean): Ranked[] {
  const readers = new Map<string, number>();
  const latest = new Map<string, number>();
  for (let i = CLOSED_AFTER; i < CLOSED_AFTER + days; i++) {
    const day = shift(todayUtc, -i);
    for (const [id, n] of tallies.get(day) ?? []) {
      const c = bank.byId.get(id);
      if (!listable(c) || (where && !where(c))) continue;
      readers.set(id, (readers.get(id) ?? 0) + n);
      if (!latest.has(id)) latest.set(id, i);
    }
  }
  return [...readers.entries()]
    .sort((a, b) => b[1] - a[1] || (latest.get(a[0]) as number) - (latest.get(b[0]) as number) || a[0].localeCompare(b[0]))
    .slice(0, limit)
    .map(([id, n]) => ({ id, readers: n }));
}

/** Loved since the start: what real readers kept, in the totals kept for good, most first. */
export function allTime(bank: Bank, totals: Map<string, number>, limit = 40, where?: (c: Card) => boolean): Ranked[] {
  const readers = new Map<string, number>();
  for (const c of bank.live) {
    if (where && !where(c)) continue;
    const n = totals.get(c.id) ?? 0;
    if (n > 0) readers.set(c.id, n);
  }
  return [...readers.entries()]
    .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))
    .slice(0, limit)
    .map(([id, n]) => ({ id, readers: n }));
}

function shift(key: string, days: number): string {
  const t = new Date(Date.parse(key + 'T00:00:00Z') + days * 86_400_000);
  return dateKey(t.getUTCFullYear(), t.getUTCMonth() + 1, t.getUTCDate());
}

// ── The documents ────────────────────────────────────────────────────────

/** Explore as everybody sees it, for the UTC day [todayUtc]. */
export interface GlobalExplore {
  day: string;
  version: number;
  at: number;
  /**
   * The lists below count real readers only, each held to LIST_READERS and
   * LIST_CARDS, and are empty until real counts can carry them. A phone that
   * knows this field trusts the lists only from a document that says so: one
   * assembled before had the launch crowd under its counts. A phone that does
   * not know it reads the same lists, and leaves out a shelf that is empty.
   */
  readersOnly: true;
  today: Card[];
  asking: Card[];
  topWeek: { id: string; readers: number; card: Card }[];
  topMonth: { id: string; readers: number; card: Card }[];
  loved: { id: string; readers: number; card: Card }[];
  /** Per subject, the ids on its top of the week and month and its loved, so the subject row narrows without another read. */
  bySubject: Record<string, { week: Ranked[]; month: Ranked[]; loved: Ranked[] }>;
}

export function buildGlobalExplore(bank: Bank, tallies: Tallies, totals: Map<string, number>, todayUtc: string, nowMs: number): GlobalExplore {
  const card = (r: Ranked) => ({ ...r, card: bank.byId.get(r.id) as Card });
  const bySubject: GlobalExplore['bySubject'] = {};
  const subjects = new Set(bank.live.map((c) => c.topic));
  for (const s of subjects) {
    const where = (c: Card) => c.topic === s;
    // A subject's list is held to the same numbers on its own: Top in Economics
    // is Economics' readers, not the whole list's cards that happen to be Economics.
    bySubject[s] = {
      week: worthShowing(topList(bank, tallies, todayUtc, WEEK_DAYS, 10, where)),
      month: worthShowing(topList(bank, tallies, todayUtc, MONTH_DAYS, 10, where)),
      loved: worthShowing(allTime(bank, totals, 12, where)),
    };
  }
  return {
    day: todayUtc,
    version: bank.version,
    at: nowMs,
    readersOnly: true,
    today: pickedCards(bank, daySeed(todayUtc), 24),
    asking: askingCards(bank, ALL_TIME_SEED, 40),
    topWeek: worthShowing(topList(bank, tallies, todayUtc, WEEK_DAYS, 10)).map(card),
    topMonth: worthShowing(topList(bank, tallies, todayUtc, MONTH_DAYS, 10)).map(card),
    loved: worthShowing(allTime(bank, totals, 40)).map(card),
    bySubject,
  };
}

/** Explore as one reader sees it: the shelf that is theirs, and the cards their profile puts first. */
export interface PersonalExplore {
  at: number;
  version: number;
  /** The subject the reader pushed furthest up, or read most. */
  because: string | null;
  /** Cards of that subject the reader has not read, in the month's order. */
  mine: Card[];
  /** What the profile puts first across every subject, unread: what a feed would call "for you". */
  forYou: Card[];
  /** Where you live: the cards about the reader's place, nearest first. Empty without a place or before any is written for it. */
  local: Card[];
}

/** How many cards the shelf of where the reader lives holds. */
export const LOCAL_SHELF = 12;

/**
 * Where you live: the cards about the reader's place, nearest first —
 * their city's, then their region's, then their country's — and inside
 * each the ones not read yet before the ones read, in the month's order.
 * Read ones stay, marked on the phone: this shelf is the reader's home,
 * not a list of finds. Empty without a place, and before any card has been
 * written for it; the phone then shows no shelf, or without a place the
 * tile that offers to switch one on.
 */
export function whereYouLive(bank: Bank, profile: Profile, monthKey: string, limit = LOCAL_SHELF): Card[] {
  const seed = monthSeed(monthKey);
  return placeCards(bank, profile.place)
    .map(({ card, fit: f }) => ({ card, near: fitRank(f), read: profile.seen.has(card.id) ? 1 : 0, key: keyed(`${seed}${card.id}`) }))
    .sort((a, b) => b.near - a.near || a.read - b.read || a.key - b.key || (a.card.id < b.card.id ? -1 : a.card.id > b.card.id ? 1 : 0))
    .slice(0, limit)
    .map((k) => k.card);
}

export function buildPersonalExplore(bank: Bank, profile: Profile, monthKey: string, nowMs: number): PersonalExplore {
  const unread = (c: Card) => !profile.seen.has(c.id);
  const weights = Object.entries(profile.weights).sort((a, b) => b[1] - a[1]);
  let because: string | null = weights.length && weights[0][1] > 0.99 && (weights.length === 1 || weights[0][1] > weights[1][1]) ? weights[0][0] : null;
  if (!because) {
    const counted = new Map<string, number>();
    for (const id of profile.seen) {
      const c = bank.byId.get(id);
      if (c) counted.set(c.topic, (counted.get(c.topic) ?? 0) + 1);
    }
    because = [...counted.entries()].sort((a, b) => b[1] - a[1])[0]?.[0] ?? null;
  }
  const mine = because ? pickedCards(bank, monthSeed(monthKey), 120, because).filter(unread).slice(0, 8) : [];
  const scored = bank.live
    .filter((c) => unread(c) && profile.topics.has(c.topic))
    .map((c) => ({ c, s: (profile.weights[c.topic] ?? 1) * fit(c, profile.levels[c.topic]) * leanOf(c, profile.taste) }))
    .sort((a, b) => b.s - a.s || a.c.id.localeCompare(b.c.id));
  // One per strand and at most two per subject, so "for you" is a spread and not one strand eight times.
  const forYou: Card[] = [];
  const strands = new Set<string>();
  const perTopic = new Map<string, number>();
  for (const { c } of scored) {
    if (forYou.length >= 8) break;
    if (c.strand && strands.has(c.strand)) continue;
    if ((perTopic.get(c.topic) ?? 0) >= 2) continue;
    forYou.push(c);
    if (c.strand) strands.add(c.strand);
    perTopic.set(c.topic, (perTopic.get(c.topic) ?? 0) + 1);
  }
  return { at: nowMs, version: bank.version, because, mine, forYou, local: whereYouLive(bank, profile, monthKey) };
}
