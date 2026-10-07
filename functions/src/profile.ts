// What the server knows about a reader, worked out from what they did.
//
// Three sources, in order of how much they say:
//
// 1. **The backup** (`readers/{uid}`): the mix and what was pruned under it,
//    what was liked, thrown down, saved and said, every card seen, every
//    answer with its confidence, the days finished. This is the phone's own
//    copy of the reader, and it is enough to deal a day the way the phone
//    would (lib/data/reader_profile.dart, lib/state/app_state.dart).
// 2. **The trace** (`readers/{uid}/activity/{day}`): every gesture of the
//    last weeks, with how long each card held them — which is what the
//    backup cannot say. A card read slowly is a card that took; a card
//    thrown on in a second, on a subject the reader asked for, is a card
//    that did not; a card shown on a shelf and never opened is a small
//    vote against its kind. The phone never used any of this. The server
//    does, and it is the reason the server deals rather than the phone.
// 3. **Presence**: their clock, and whether they hold Astute+.
//
// Out of it comes the same three things the phone's own reading produces,
// only sharper: a level per subject, a taste over every tag the cards
// carry, and the mix as leaned by what they did — plus what to keep out,
// what came due, and which day of theirs this is.

import { Bank, Card, GENRES, TOPICS, Genre, genreOf, graded, asks, traitsOf } from './bank.js';
import { seedOf } from './rng.js';

/** An answer as the phone backs it up (lib/models/pill.dart, Answer.toJson). */
export interface AnswerJson { r: string; c?: number; w?: string; s?: number; d?: string }

/** A judgement as backed up (Judgement.toJson): confidence, correct, card, day. */
export interface JudgementJson { c: number; k: boolean; p?: string; d?: string }

/** The backup, as far as the server reads it (lib/sync/reader_snapshot.dart). */
export interface Snapshot {
  likedIds?: string[];
  dislikedIds?: string[];
  savedIds?: string[];
  saidIds?: string[];
  seenIds?: string[];
  answers?: Record<string, AnswerJson>;
  judgements?: JudgementJson[];
  topicWeights?: Record<string, number>;
  topicLevels?: Record<string, number>;
  genresOff?: string[];
  strandsOff?: string[];
  pickedTopics?: string[];
  completedDates?: string[];
  streak?: number;
  lastCompletionDate?: string;
}

/** One event of the trace (lib/sync/trace.dart): the short names. */
export interface Event {
  t: number;
  e: string;
  c?: string;
  ms?: number;
  ok?: boolean;
  cf?: number;
  sh?: string;
  s?: string;
  [key: string]: unknown;
}

export interface Presence { tz?: number; lastSeen?: number; plus?: boolean }

export type Shape = 'untold' | 'specialist' | 'generalist' | 'curious';

export interface Profile {
  /** The reader's level on each subject: 0 curious, 1 some, 2 solid. */
  levels: Record<string, number>;
  /** The lean on every trait, in the currency a like moves it by. */
  taste: Record<string, number>;
  /** The mix as the dealer uses it, leaned by likes and throws. */
  weights: Record<string, number>;
  /** The mix as the reader set it, for the cards a free day deals at random. Empty spreads them evenly. */
  mix: Record<string, number>;
  shape: Shape;
  claimed: string[];
  genresOff: Set<string>;
  strandsOff: Set<string>;
  topics: Set<string>;
  seen: Set<string>;
  answers: Record<string, AnswerJson>;
  completedDates: string[];
  streak: number;
  lastCompletionDate?: string;
  plus: boolean;
  tz: number;
  recentStrands: Set<string>;
  met: Set<string>;
  /** Every strand the reader has met at all, by a card seen on the phone or in the trace: the explorer avoids these. */
  metStrands: Set<string>;
  /** How the trace was read, for the record. */
  signals: { events: number; days: number; medianMs: number };
}

// ── The onboarding, read (lib/data/reader_profile.dart) ─────────────────

const FLOOR = 0.06;
const TOP = 0.85;
const APART = 0.6;
const SPECIALIST_AT = 4;
const GENERALIST_AT = 12;
export const PICKED_STRAND = 0.3;
export const KEPT_GENRE = 0.1;
export const FOCUS = [3.0, 2.0, 1.5];
export const HOOKS: Record<string, number> = {
  psychology: 1.0, space: 1.0, human_body: 0.95, weird_facts: 0.95, history: 0.9, science: 0.85,
};

export interface Reading {
  shape: Shape;
  levels: Record<string, number>;
  lean: Record<string, number>;
  claimed: string[];
  weights: Record<string, number>;
}

/** The onboarding's answers, read the way a person would. */
export function readOnboarding(weights: Record<string, number>, genresOff: Set<string>, strandsOff: Set<string>): Reading {
  const mix: Record<string, number> = {};
  for (const [k, v] of Object.entries(weights)) {
    if (v > FLOOR && k in GENRES) mix[k] = v;
  }
  const keys = Object.keys(mix);
  const pruned = genresOff.size > 0 || strandsOff.size > 0;
  const moved = keys.length < TOPICS.length || keys.some((k) => mix[k] < 0.99);
  if (keys.length === 0 || (!pruned && !moved)) {
    return {
      shape: 'untold',
      levels: Object.fromEntries(TOPICS.map((t) => [t, 1])),
      lean: {},
      claimed: [],
      weights: mix,
    };
  }
  const highest = Math.max(...Object.values(mix));
  const share = (k: string) => (mix[k] ?? 0) / highest;
  const toldApart = keys.some((k) => share(k) <= APART);
  const shape: Shape = keys.length <= SPECIALIST_AT ? 'specialist' : keys.length >= GENERALIST_AT ? 'generalist' : 'curious';

  const strandsOffIn = (key: string): number => {
    let off = 0;
    for (const g of GENRES[key]) {
      if (genresOff.has(g.id)) { off += g.strands.length; continue; }
      off += g.strands.filter((s) => strandsOff.has(s.id)).length;
    }
    return off;
  };

  const claimed: string[] = [];
  const levels: Record<string, number> = {};
  for (const key of keys) {
    const atTop = share(key) >= TOP;
    const curated = strandsOffIn(key) > 0 && share(key) >= APART;
    const claim = curated || (atTop && (toldApart || shape === 'specialist'));
    if (claim) claimed.push(key);
    levels[key] = claim ? 2 : 1;
  }

  const lean: Record<string, number> = {};
  for (const key of keys) {
    const subjectPruned = strandsOffIn(key) > 0;
    for (const g of GENRES[key] as Genre[]) {
      if (genresOff.has(g.id)) continue;
      const on = g.strands.filter((s) => !strandsOff.has(s.id));
      if (on.length < g.strands.length) {
        for (const s of on) lean[`strand:${s.id}`] = PICKED_STRAND;
      } else if (subjectPruned) {
        lean[`genre:${g.id}`] = KEPT_GENRE;
      }
    }
  }
  return { shape, levels, lean, claimed, weights: mix };
}

/** The mix for the reader's [day]th day (0 the first): sharpened towards its top on the first three. */
export function weightsOn(reading: Reading, day: number, weights: Record<string, number>): Record<string, number> {
  if (day < 0 || day >= FOCUS.length) return weights;
  const power = FOCUS[day];
  if (reading.shape === 'untold') {
    const keys = Object.keys(weights).length === 0 ? TOPICS : Object.keys(weights);
    return Object.fromEntries(keys.map((k) => [k, (Object.keys(weights).length === 0 ? 1 : weights[k]) * Math.pow(HOOKS[k] ?? 0.7, power)]));
  }
  if (Object.keys(weights).length === 0) return weights;
  return Object.fromEntries(Object.entries(weights).map(([k, v]) => [k, Math.pow(v, power)]));
}

// ── The measurement (AppState.measuredLevels, leanedWeights, taste) ──────

const LEVEL_SAMPLE = 8;
const LEVEL_FLOOR = 4;
export const LEAN = 0.15;
export const TASTE_LEAN = 0.08;

/** A subject's level from its last eight judgements, once there are four. */
export function measuredLevels(judgements: JudgementJson[], bank: Bank, start: Record<string, number>): Record<string, number> {
  const out = { ...start };
  const recent = new Map<string, boolean[]>();
  for (let i = judgements.length - 1; i >= 0; i--) {
    const j = judgements[i];
    const card = j.p ? bank.byId.get(j.p) : undefined;
    if (!card) continue;
    const list = recent.get(card.topic) ?? [];
    if (list.length < LEVEL_SAMPLE) list.push(j.k);
    recent.set(card.topic, list);
  }
  for (const [topic, list] of recent) {
    if (list.length < LEVEL_FLOOR) continue;
    const share = list.filter(Boolean).length / list.length;
    out[topic] = share >= 0.75 ? 2 : share <= 0.4 ? 0 : 1;
  }
  return out;
}

// ── The trace, read ──────────────────────────────────────────────────────

/** How much each gesture moves the traits of its card, in the like's currency. */
const MOVES: Record<string, number> = {
  flip: 0.01,
  like: TASTE_LEAN,
  unlike: -TASTE_LEAN,
  skip: -TASTE_LEAN,
  unskip: TASTE_LEAN,
  save: 0.05,
  unsave: -0.05,
  said: 0.05,
  share: 0.05,
  open: 0.03,
  xo: 0.03,
  read: 0.02,
};

/** Older than this, a gesture counts half. */
const RECENT_MS = 14 * 86_400_000;

/** A card that held the reader this many times the median is a card that took; this fraction, one they threw on. */
const LONG = 2.0;
const SHORT = 0.35;
const DWELL_LONG = 0.02;
const DWELL_SHORT = -0.03;
/** Shown on a shelf and never opened that day: a small vote against its kind. */
const UNOPENED = -0.01;

/** Never more than this, either way, on one trait: a hundred likes should not make one strand the whole deck. */
const CLAMP = 0.6;

/** Under this many timed cards, "long" and "short" mean nothing yet: the median of three is a coin. */
const DWELL_FLOOR = 5;

/** A card looked at within the last week: its strand is met again later, not tomorrow. */
export const RECENT_STRAND_DAYS = 7;

export interface TraceReading {
  taste: Record<string, number>;
  events: number;
  days: number;
  medianMs: number;
  /** The strands of the cards looked at in the last week, for the day to steer round. */
  recentStrands: Set<string>;
  /** Every card the trace shows the reader met, on the day or on a shelf, for the explorer to steer round. */
  met: Set<string>;
}

export function readTrace(days: Map<string, Event[]>, bank: Bank, now: number): TraceReading {
  const taste: Record<string, number> = {};
  const nudge = (id: string | undefined, by: number, at: number) => {
    const card = id ? bank.byId.get(id) : undefined;
    if (!card || by === 0) return;
    const weight = now - at > RECENT_MS ? 0.5 : 1;
    for (const trait of traitsOf(card)) {
      taste[trait] = (taste[trait] ?? 0) + by * weight;
    }
  };

  const all: Event[] = [];
  for (const list of days.values()) all.push(...list);
  all.sort((a, b) => a.t - b.t);

  // How long a card usually holds this reader, so long and short are theirs.
  const dwell = all.filter((e) => e.e === 'next' && typeof e.ms === 'number' && e.ms > 0).map((e) => e.ms as number).sort((a, b) => a - b);
  const medianMs = dwell.length >= DWELL_FLOOR ? dwell[Math.floor(dwell.length / 2)] : 0;

  const recentStrands = new Set<string>();
  const met = new Set<string>();
  const weekAgo = now - RECENT_STRAND_DAYS * 86_400_000;
  for (const e of all) {
    if (!e.c) continue;
    const card = bank.byId.get(e.c);
    if (!card) continue;
    if (e.e === 'view' || e.e === 'open' || e.e === 'read' || e.e === 'seen' || e.e === 'next') met.add(card.id);
    if ((e.e === 'view' || e.e === 'next' || e.e === 'open' || e.e === 'read') && e.t >= weekAgo && card.strand) recentStrands.add(card.strand);
  }

  const opened = new Set<string>();
  for (const e of all) {
    if ((e.e === 'open' || e.e === 'xo') && e.c) opened.add(`${dayOf(e.t)}:${e.c}`);
  }

  for (const e of all) {
    const move = MOVES[e.e];
    if (move !== undefined) nudge(e.c, move, e.t);
    if (e.e === 'next' && typeof e.ms === 'number' && medianMs > 0 && e.c) {
      const card = bank.byId.get(e.c);
      if (!card) continue;
      if (e.ms >= medianMs * LONG) nudge(e.c, DWELL_LONG, e.t);
      // A question answered takes longer by nature; only a card that tells
      // can be thrown on too fast to have been read.
      else if (!asks(card) && e.ms <= medianMs * SHORT) nudge(e.c, DWELL_SHORT, e.t);
    }
    if (e.e === 'seen' && e.c && !opened.has(`${dayOf(e.t)}:${e.c}`)) nudge(e.c, UNOPENED, e.t);
  }
  for (const k of Object.keys(taste)) {
    taste[k] = Math.max(-CLAMP, Math.min(CLAMP, taste[k]));
  }
  return { taste, events: all.length, days: days.size, medianMs, recentStrands, met };
}

function dayOf(t: number): string {
  return new Date(t).toISOString().slice(0, 10);
}

// ── The whole ────────────────────────────────────────────────────────────

export function buildProfile(snapshot: Snapshot, activity: Map<string, Event[]>, presence: Presence, bank: Bank, now: number): Profile {
  const weightsSaid = snapshot.topicWeights ?? {};
  const genresOff = new Set(snapshot.genresOff ?? []);
  const strandsOff = new Set(snapshot.strandsOff ?? []);
  const reading = readOnboarding(weightsSaid, genresOff, strandsOff);
  const liked = snapshot.likedIds ?? [];
  const disliked = snapshot.dislikedIds ?? [];

  // The mix, leaned by likes and throws (AppState.leanedWeights).
  const lean: Record<string, number> = {};
  const nudgeTopic = (ids: string[], by: number) => {
    for (const id of ids) {
      const card = bank.byId.get(id);
      if (card) lean[card.topic] = (lean[card.topic] ?? 0) + by;
    }
  };
  nudgeTopic(liked, LEAN);
  nudgeTopic(disliked, -LEAN);
  const base = Object.keys(weightsSaid).length === 0 ? Object.fromEntries(TOPICS.map((t) => [t, 1])) : weightsSaid;
  const weights: Record<string, number> = {};
  for (const [k, v] of Object.entries(base)) {
    weights[k] = Math.max(0.05, Math.min(3, v * (1 + (lean[k] ?? 0))));
  }

  // The taste: the onboarding's hand-picked strands, what was held and
  // thrown down, and then the trace on top.
  const taste: Record<string, number> = { ...reading.lean };
  const nudgeTraits = (ids: string[], by: number) => {
    for (const id of ids) {
      const card = bank.byId.get(id);
      if (!card) continue;
      for (const trait of traitsOf(card)) taste[trait] = (taste[trait] ?? 0) + by;
    }
  };
  nudgeTraits(liked, TASTE_LEAN);
  nudgeTraits(disliked, -TASTE_LEAN);
  const traced = readTrace(activity, bank, now);
  for (const [k, v] of Object.entries(traced.taste)) taste[k] = (taste[k] ?? 0) + v;

  // The level: measured where there is something to measure, the reading's
  // start elsewhere, and what the reader said underneath both.
  const levels = measuredLevels(snapshot.judgements ?? [], bank, { ...reading.levels, ...(snapshot.topicLevels ?? {}) });

  const picked = snapshot.pickedTopics ?? [];
  const topics = new Set(picked.length ? picked : [...TOPICS, 'thinking']);
  topics.add('thinking');

  return {
    levels,
    taste,
    weights,
    mix: { ...weightsSaid },
    shape: reading.shape,
    claimed: reading.claimed,
    genresOff,
    strandsOff,
    topics,
    seen: new Set(snapshot.seenIds ?? []),
    answers: snapshot.answers ?? {},
    completedDates: snapshot.completedDates ?? [],
    streak: snapshot.streak ?? 0,
    lastCompletionDate: snapshot.lastCompletionDate,
    plus: presence.plus === true,
    tz: typeof presence.tz === 'number' ? presence.tz : 0,
    recentStrands: traced.recentStrands,
    met: traced.met,
    metStrands: metStrandsOf(bank, [...(snapshot.seenIds ?? []), ...traced.met]),
    signals: { events: traced.events, days: traced.days, medianMs: traced.medianMs },
  };
}

/** Which of the reader's days [date] is: 0 for the first, counted by the days finished before it. */
export function dayNumberOf(profile: Profile, date: string): number {
  return profile.completedDates.filter((d) => d < date).length;
}

/** The streak as a morning sees it: kept if yesterday was finished, else nothing to reward. */
export function streakOn(profile: Profile, date: string): number {
  const last = profile.lastCompletionDate;
  if (!last) return 0;
  const y = new Date(Date.parse(date + 'T00:00:00Z') - 86_400_000).toISOString().slice(0, 10);
  return last === y ? profile.streak : 0;
}

/** What came due by [date], oldest first, each as a fresh card of the same principle where one exists. */
export function reviewsDue(profile: Profile, bank: Bank, date: string): Card[] {
  const due = Object.entries(profile.answers)
    .filter(([, a]) => typeof a.d === 'string' && a.d <= date)
    .sort((a, b) => (a[1].d as string).localeCompare(b[1].d as string));
  const claimed = new Set<string>();
  const out: Card[] = [];
  for (const [id] of due) {
    const original = bank.byId.get(id);
    if (!original) continue;
    const pick = freshInstanceOf(original, claimed, profile, bank, date);
    // A card taken out of the deal — retired, or in quarantine — is not
    // brought back as a review; a sibling of its principle still can be.
    if (pick.disabled) continue;
    claimed.add(pick.id);
    out.push(pick);
  }
  return out;
}

function freshInstanceOf(original: Card, claimed: Set<string>, profile: Profile, bank: Bank, date: string): Card {
  if (!original.principle || original.principle === 'none' || !graded(original)) return original;
  const siblings = bank.live
    .filter((p) => p.principle === original.principle && p.id !== original.id && !claimed.has(p.id) && !(p.id in profile.answers))
    .sort((a, b) => a.id.localeCompare(b.id));
  if (siblings.length === 0) return original;
  return siblings[seedOf(`${date}:${original.id}`) % siblings.length];
}

/** For the record and the debug section: the reading's shape, never its content. */
export function facts(profile: Profile): Record<string, unknown> {
  return {
    shape: profile.shape,
    claimed: profile.claimed.length,
    solid: Object.values(profile.levels).filter((l) => l >= 2).length,
    traits: Object.keys(profile.taste).length,
    events: profile.signals.events,
    days: profile.signals.days,
    medianMs: profile.signals.medianMs,
  };
}

export { genreOf };

/** The strands of the given cards, for what the reader has met. */
function metStrandsOf(bank: Bank, ids: Iterable<string>): Set<string> {
  const out = new Set<string>();
  for (const id of ids) {
    const strand = bank.byId.get(id)?.strand;
    if (strand) out.add(strand);
  }
  return out;
}
