// The day, dealt on the server.
//
// The same day the phone deals for itself (lib/data/daily.dart and
// lib/data/pills_repository.dart), card for card in its rules — five cards,
// two that ask, one debate at most, a fresh strand before a second card of
// one, the hardest early, a debate to close, the welcome week, the question
// of the day and the edition's common cards from the frozen calendar — but
// dealt from a profile the phone never had: what held the reader and what
// they threw on, read off the trace. Where the phone's draw and this one
// differ, this one is the reader's; where they must agree — everything
// that is everybody's — both read the calendar.

import { Bank, Card, asks, graded, isDebate, editionOf, genreOf, strandsOf, traitsOf } from './bank.js';
import { Profile, dayNumberOf, reviewsDue, streakOn, weightsOn, readOnboarding } from './profile.js';
import { rng, seedOf, shuffle } from './rng.js';

export const PILLS_PER_DAY = 5;
export const ASK_SHARE = 0.4;
export const OWN_FREE = 1;
export const OWN_REWARDED = 2;
export const WELCOME_DAYS = 7;
export const OWN_WELCOME = 4;
export const COMMON_SPARES = 8;

export const asksInADay = (count: number): number => Math.round(count * ASK_SHARE);

export function ownCardsFor(plus: boolean, streak: number, day: number): number {
  if (plus) return PILLS_PER_DAY;
  if (day >= 0 && day < WELCOME_DAYS) return OWN_WELCOME;
  return streak > 0 && streak % 7 === 0 ? OWN_REWARDED : OWN_FREE;
}

export const inWelcomeWeek = (day: number): boolean => day >= 0 && day < WELCOME_DAYS;

// ── The calendar ─────────────────────────────────────────────────────────

/** The question of the day: the calendar's, or chained past its end. */
export function questionOfEdition(bank: Bank, edition: number): Card | null {
  const frozen = bank.editions.get(edition);
  const card = frozen ? bank.byId.get(frozen) : undefined;
  if (card && graded(card) && !card.disabled) return card;
  const pool = bank.live.filter((c) => c.topic === 'thinking' && graded(c));
  if (pool.length === 0) return null;
  // Past the calendar: a Thinking question clear of the ones the calendar
  // ended on, seeded by the edition so every server agrees with itself.
  const window = Math.floor(pool.length * 0.75);
  const recent = new Set<string>();
  for (let e = edition - window; e < edition; e++) {
    const id = bank.editions.get(e);
    if (id) recent.add(id);
  }
  const fresh = shuffle(pool.filter((c) => !recent.has(c.id)), rng(edition * 7919 + 104729));
  return fresh[0] ?? shuffle([...pool], rng(edition * 7919 + 104729))[0];
}

/** The edition's common cards: the calendar's, or chained past its end. */
export function commonOfEdition(bank: Bank, edition: number): Card[] {
  const frozen = bank.commons.get(edition);
  if (frozen) {
    const cards = frozen.map((id) => bank.byId.get(id)).filter((c): c is Card => !!c && !asks(c) && !c.disabled);
    if (cards.length > 0) return cards;
  }
  const pool = bank.live.filter((c) => !asks(c));
  if (pool.length === 0) return [];
  const window = Math.floor((pool.length * 0.75) / COMMON_SPARES);
  const recent = new Set<string>();
  for (let e = edition - window; e < edition; e++) {
    for (const id of bank.commons.get(e) ?? []) recent.add(id);
  }
  const next = rng(edition * 6007 + 91);
  const fresh = shuffle(pool.filter((c) => !recent.has(c.id)), next);
  const stale = shuffle(pool.filter((c) => recent.has(c.id)), next);
  const picked: Card[] = [];
  const topics = new Set<string>();
  for (const c of [...fresh, ...stale]) {
    if (picked.length >= COMMON_SPARES) break;
    if (topics.has(c.topic)) continue;
    topics.add(c.topic);
    picked.push(c);
  }
  return picked;
}

// ── The reader's own ─────────────────────────────────────────────────────

/** How much the reader's taste favours a card: one plus the sum of their lean on its traits, held between a fifth and three times. */
export function leanOf(card: Card, taste: Record<string, number>): number {
  let lean = 0;
  for (const t of traitsOf(card)) lean += taste[t] ?? 0;
  return Math.max(0.2, Math.min(3, 1 + lean));
}

/** How well a card suits the reader's level on its subject, pitched a notch above. */
export function fit(card: Card, level: number | undefined): number {
  const l = level ?? 1;
  if (!asks(card)) return l === 0 ? 1.5 : l === 1 ? 1.0 : 0.7;
  const hard = card.difficulty === 'hard';
  if (l === 0) return hard ? 0.5 : 1.0;
  if (l === 1) return hard ? 1.5 : 1.3;
  return hard ? 3.0 : 1.2;
}

export interface OwnOptions {
  seed: string;
  count: number;
  asking: number;
  exclude: Set<string>;
  strandsDealt: Set<string>;
}

/**
 * The reader's own cards for a day: [count] of them, [asking] that ask,
 * from the pool as the profile orders it. The same tiers as the phone's
 * dealer — unread before read, on the mix before off it, ready before
 * waiting for a card it builds on — and inside a tier the exponential race
 * over subject weight, level fit and taste.
 */
export function ownCards(bank: Bank, profile: Profile, weights: Record<string, number>, o: OwnOptions): Card[] {
  const next = rng(seedOf(o.seed));
  const pool = shuffle([...bank.live], next);
  const wanted = new Set(profile.topics);
  const onTopic = (c: Card) => wanted.size === 0 || wanted.has(c.topic);
  const strandOn = (s: string) => !profile.strandsOff.has(s) && !profile.genresOff.has(genreOf(s));
  const onMix = (c: Card) => onTopic(c) && (strandsOf(c).length === 0 || strandsOf(c).some(strandOn));
  const ready = (c: Card) => (c.builds_on ?? []).every((id) => o.exclude.has(id));
  const tierOf = (c: Card): number => {
    const read = o.exclude.has(c.id) ? 4 : 0;
    if (onMix(c)) return read + (ready(c) ? 0 : 1);
    if (onTopic(c)) return read + 2;
    return read + 3;
  };
  const tiers: Card[][] = Array.from({ length: 8 }, () => []);
  for (const c of pool) tiers[tierOf(c)].push(c);

  const ordered = tiers.map((tier) => {
    const keyedCards = tier.map((c) => {
      const w = (weights[c.topic] ?? (Object.keys(weights).length === 0 ? 1 : 0)) * fit(c, profile.levels[c.topic]) * leanOf(c, profile.taste);
      const weight = w <= 0 ? 1e-6 : w;
      const u = Math.max(1e-12, Math.min(1, next()));
      return { key: -Math.log(u) / weight, c };
    });
    keyedCards.sort((a, b) => a.key - b.key);
    return keyedCards.map((k) => k.c);
  });

  let debates = 0;
  const strands = new Set(o.strandsDealt);
  const picked: Card[] = [];
  const take = (n: number, wants: (c: Card) => boolean): Card[] => {
    const got: Card[] = [];
    const admit = (c: Card): boolean => {
      if (isDebate(c)) {
        if (debates >= 1) return false;
        debates++;
      }
      got.push(c);
      picked.push(c);
      if (c.strand) strands.add(c.strand);
      return true;
    };
    for (const tier of ordered) {
      const held: Card[] = [];
      for (const c of tier) {
        if (got.length >= n) break;
        if (!wants(c) || picked.includes(c)) continue;
        if (c.strand && strands.has(c.strand)) { held.push(c); continue; }
        admit(c);
      }
      for (const c of held) {
        if (got.length >= n) break;
        admit(c);
      }
      if (got.length >= n) break;
    }
    return got;
  };
  const asking = take(o.asking, asks);
  const reads = take(o.count - asking.length, (c) => !asks(c));
  const deck = [...asking, ...reads];
  if (deck.length < o.count) {
    for (const c of ordered.flat()) {
      if (deck.length >= o.count) break;
      if (!deck.includes(c)) deck.push(c);
    }
  }
  return deck;
}

/** Gives a day a shape rather than a sort order: opens on a read, alternates, the hardest early, a debate to close. */
export function arrangeDay(cards: Card[]): Card[] {
  if (cards.length < 3) return cards;
  const ease = (c: Card) => ({ easy: 0, medium: 1, hard: 2 }[c.difficulty] ?? 1);
  const reads = cards.filter((c) => !asks(c)).sort((a, b) => ease(a) - ease(b));
  const asking = cards.filter(asks).sort((a, b) => ease(a) - ease(b));
  let closer: Card | undefined;
  const debate = asking.findIndex(isDebate);
  if (debate >= 0) closer = asking.splice(debate, 1)[0];
  if (asking.length > 1) asking.unshift(asking.pop() as Card);
  const out: Card[] = [];
  let wantRead = true;
  while (reads.length || asking.length) {
    const from = wantRead ? (reads.length ? reads : asking) : asking.length ? asking : reads;
    out.push(from.shift() as Card);
    wantRead = !wantRead;
  }
  if (closer) out.push(closer);
  return out;
}

// ── The day ──────────────────────────────────────────────────────────────

export interface Deal {
  date: string;
  edition: number;
  cards: Card[];
  own: string[];
  question: string | null;
  reviews: string[];
  ownCount: number;
  welcome: boolean;
  day: number;
}

/** A day for the reader, as `dealDay` in daily.dart deals it, from the profile. */
export function dealDay(bank: Bank, profile: Profile, date: string, uid: string): Deal {
  const edition = editionOf(date);
  const day = dayNumberOf(profile, date);
  const own = ownCardsFor(profile.plus, streakOn(profile, date), day);
  const count = PILLS_PER_DAY;
  const asking = asksInADay(count);
  const whole = own >= count;
  const question = whole ? null : questionOfEdition(bank, edition);

  // A review is the reader's own, coming back: one at most, so a day always
  // has one question it has never asked. On Astute+ only, as on the phone.
  const reviews = profile.plus
    ? reviewsDue(profile, bank, date).filter((c) => c.id !== question?.id).slice(0, Math.max(0, asking - 1))
    : [];

  const taken = new Set<string>([...profile.seen, ...(question ? [question.id] : []), ...reviews.map((c) => c.id)]);
  const common: Card[] = [];
  if (!whole) {
    const wanted = Math.max(0, count - 1 - own);
    const mix = profile.topics;
    const onMix = (c: Card) => mix.size === 0 || mix.has(c.topic);
    const spares = commonOfEdition(bank, edition);
    for (const c of [...spares.filter(onMix), ...spares.filter((c) => !onMix(c))]) {
      if (common.length >= wanted) break;
      if (taken.has(c.id)) continue;
      taken.add(c.id);
      common.push(c);
    }
  }

  const dealt = (question ? 1 : 0) + common.length;
  const ownAsks = Math.max(0, asking - (question ? 1 : 0));
  const reading = readOnboarding(profile.weights, profile.genresOff, profile.strandsOff);
  const weights = weightsOn(reading, day, profile.weights);
  const rest = ownCards(bank, profile, weights, {
    seed: `${uid}:${date}`,
    count: Math.max(0, count - dealt - reviews.length),
    asking: Math.max(0, ownAsks - reviews.length),
    exclude: taken,
    strandsDealt: new Set([...(question ? [question] : []), ...common, ...reviews].map((c) => c.strand ?? '').filter(Boolean)),
  });
  const mine = [...reviews, ...rest];
  return {
    date,
    edition,
    cards: arrangeDay([...(question ? [question] : []), ...common, ...mine]),
    own: mine.map((c) => c.id),
    question: question?.id ?? null,
    reviews: reviews.map((c) => c.id),
    ownCount: own,
    welcome: !profile.plus && inWelcomeWeek(day),
    day,
  };
}
