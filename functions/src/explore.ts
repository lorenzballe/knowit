// Explore, assembled on the server.
//
// The shelves the phone used to compute for itself, put together once for
// everybody — today's shelf, the ones that ask the most, the top of the
// week and the month, loved since the start — and once per reader, from
// their profile, the shelf that is theirs. Every card on a shelf travels
// whole, so a phone reads one document and draws, and a card the phone's
// own bank has not got yet still shows.

import { Bank, Card, asks, isDebate, dateKey, topicName } from './bank.js';
import { Profile } from './profile.js';
import { fit, leanOf } from './deal.js';
import { keyed, unit } from './rng.js';

// ── The launch crowd (lib/sync/tally.dart, TopSeed) ──────────────────────

export const LAUNCHED_UTC = Date.UTC(2026, 8, 1);

/** How much readers take to a card, around 1: the same tilt as main.dart's launchCrowd. */
export function appeal(c: Card): number {
  let a = 1;
  if (isDebate(c)) a *= 1.3;
  else if (asks(c)) a *= 1.2;
  if (c.difficulty === 'hard') a *= 1.2;
  if (['weird_facts', 'psychology', 'space', 'human_body'].includes(c.topic)) a *= 1.2;
  return a;
}

export function popularity(id: string): number {
  const u = unit(`seed:${id}`);
  if (u < 0.85) return 0;
  return 0.3 + 4.5 * Math.pow((u - 0.85) / 0.15, 2.5);
}

/** The seeded counts for a UTC day. */
export function seededDay(bank: Bank, day: string): Map<string, number> {
  const month = day.slice(0, 7);
  const out = new Map<string, number>();
  for (const c of bank.live) {
    const p = popularity(c.id);
    if (p === 0) continue;
    const season = 0.4 + 1.2 * unit(`${month}:${c.id}`);
    const today = 0.5 + unit(`${day}:${c.id}`);
    const n = Math.floor(p * season * today * appeal(c));
    if (n > 0) out.set(c.id, n);
  }
  return out;
}

/** A card's seeded count for good at [nowMs]. */
export function seededTotal(c: Card, nowMs: number): number {
  const p = popularity(c.id);
  if (p === 0) return 0;
  const days = Math.floor((nowMs - LAUNCHED_UTC) / 86_400_000);
  if (days <= 0) return 0;
  return Math.floor(p * appeal(c) * days);
}

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

export const WEEK_DAYS = 7;
export const MONTH_DAYS = 30;
export const CLOSED_AFTER = 2;

export interface Ranked { id: string; readers: number }

/** The counts the store holds, day by day. */
export type Tallies = Map<string, Map<string, number>>;

/** The list for the [days] days that closed most recently, at [todayUtc]: real counts over the crowd's. */
export function topList(bank: Bank, tallies: Tallies, todayUtc: string, days: number, limit = 10, where?: (c: Card) => boolean): Ranked[] {
  const readers = new Map<string, number>();
  const latest = new Map<string, number>();
  for (let i = CLOSED_AFTER; i < CLOSED_AFTER + days; i++) {
    const day = shift(todayUtc, -i);
    const merged = new Map(seededDay(bank, day));
    for (const [id, n] of tallies.get(day) ?? []) merged.set(id, (merged.get(id) ?? 0) + n);
    for (const [id, n] of merged) {
      const c = bank.byId.get(id);
      if (!c || c.disabled || (where && !where(c))) continue;
      readers.set(id, (readers.get(id) ?? 0) + n);
      if (!latest.has(id)) latest.set(id, i);
    }
  }
  return [...readers.entries()]
    .sort((a, b) => b[1] - a[1] || (latest.get(a[0]) as number) - (latest.get(b[0]) as number) || a[0].localeCompare(b[0]))
    .slice(0, limit)
    .map(([id, n]) => ({ id, readers: n }));
}

/** Loved since the start: the totals kept for good, over the crowd's. */
export function allTime(bank: Bank, totals: Map<string, number>, nowMs: number, limit = 40, where?: (c: Card) => boolean): Ranked[] {
  const readers = new Map<string, number>();
  for (const c of bank.live) {
    if (where && !where(c)) continue;
    const n = (totals.get(c.id) ?? 0) + seededTotal(c, nowMs);
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
    bySubject[s] = {
      week: topList(bank, tallies, todayUtc, WEEK_DAYS, 10, where),
      month: topList(bank, tallies, todayUtc, MONTH_DAYS, 10, where),
      loved: allTime(bank, totals, nowMs, 12, where),
    };
  }
  return {
    day: todayUtc,
    version: bank.version,
    at: nowMs,
    today: pickedCards(bank, daySeed(todayUtc), 24),
    asking: pickedCards(bank, ALL_TIME_SEED, 40),
    topWeek: topList(bank, tallies, todayUtc, WEEK_DAYS, 10).map(card),
    topMonth: topList(bank, tallies, todayUtc, MONTH_DAYS, 10).map(card),
    loved: allTime(bank, totals, nowMs, 40).map(card),
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
  return { at: nowMs, version: bank.version, because, mine, forYou };
}
