import { getFirestore } from 'firebase-admin/firestore';
import { KINDS, LEVELS, MOVES, TONES, TOPICS } from './card';
import { StoredCard } from './catalogue';
import { Brief } from './prompt';

/**
 * What to write next.
 *
 * The app learns what each reader likes; this is the other half of that loop —
 * the catalogue grows toward what readers have been shown to want, rather than
 * toward what someone guessed they would. Without it the ranking algorithm is
 * choosing from a fixed pool, and however good the choosing is, five cards a
 * day against a fixed pool runs out.
 *
 * Two inputs, and the gap between them decides:
 *
 *   demand  what readers' own taste models say they like, summed
 *   supply  how many cards the catalogue already holds of that kind
 *
 * Nothing here reads anything a reader wrote or answered. A taste model is
 * already an aggregate — 'topic:space, +0.6' — and only the facet totals leave
 * this function, so what comes out the far end is "people want more space",
 * never anything about a person.
 */

/** How many readers to look at. Enough to be a signal, few enough to be cheap. */
const kSample = 500;

/** Facets with less evidence than this behind them are noise, not taste. */
const kMinEvidence = 3;

/** A pull has to be positive by this much before it counts as wanting. */
const kWanting = 0.15;

export type Demand = Map<string, number>;

/**
 * Sums what readers like, facet by facet.
 *
 * Each reader is normalised to contribute the same total, so somebody who has
 * used the app for a year does not outvote a hundred people who joined last
 * week. What is being measured is how many people want a thing, not how badly
 * one person does.
 */
export async function readDemand(): Promise<Demand> {
  const snap = await getFirestore()
    .collection('readers')
    .orderBy('at', 'desc')
    .limit(kSample)
    .get();

  const demand: Demand = new Map();
  for (const doc of snap.docs) {
    const traits = doc.get('taste.t');
    if (!traits || typeof traits !== 'object') continue;

    const mine = new Map<string, number>();
    let total = 0;
    for (const [facet, value] of Object.entries(traits)) {
      if (!Array.isArray(value) || value.length < 2) continue;
      const [pull, met] = value as [number, number];
      if (typeof pull !== 'number' || typeof met !== 'number') continue;
      if (met < kMinEvidence || pull <= kWanting) continue;
      mine.set(facet, pull);
      total += pull;
    }
    if (total === 0) continue;
    for (const [facet, pull] of mine) {
      demand.set(facet, (demand.get(facet) ?? 0) + pull / total);
    }
  }
  return demand;
}

/** How many cards the catalogue holds of each facet. */
export function readSupply(cards: StoredCard[]): Demand {
  const supply: Demand = new Map();
  const add = (facet: string) => supply.set(facet, (supply.get(facet) ?? 0) + 1);
  for (const card of cards) {
    add(`topic:${card.topic}`);
    add(`tone:${card.tone}`);
    add(`level:${card.difficulty}`);
    add(`format:${card.challenge.kind}`);
    if (card.move !== 'none') add(`move:${card.move}`);
    for (const tag of card.tags) add(`tag:${tag}`);
  }
  return supply;
}

/** Turns counts into shares that can be compared with each other. */
function shares(counts: Demand, family: string): Map<string, number> {
  const mine = [...counts].filter(([f]) => f.startsWith(`${family}:`));
  const total = mine.reduce((a, [, v]) => a + v, 0);
  const out = new Map<string, number>();
  for (const [facet, value] of mine) {
    out.set(facet.slice(family.length + 1), total === 0 ? 0 : value / total);
  }
  return out;
}

/**
 * Orders the values of one family by how much readers want them against how
 * much of them there already is.
 *
 * The `+ 0.02` keeps a subject nobody has asked for from being written about
 * for ever once its supply reaches zero — and, more importantly, keeps a brand
 * new install's empty demand from producing no briefs at all.
 */
function byGap(
  demand: Demand,
  supply: Demand,
  family: string,
  values: readonly string[],
): string[] {
  const want = shares(demand, family);
  const have = shares(supply, family);
  return [...values].sort((a, b) => {
    const ga = (want.get(a) ?? 0) + 0.02 - (have.get(a) ?? 0);
    const gb = (want.get(b) ?? 0) + 0.02 - (have.get(b) ?? 0);
    return gb - ga;
  });
}

/**
 * The tags readers want that the catalogue is short of.
 *
 * Only tags that already exist in someone's taste model, so this can only
 * amplify subjects the catalogue has already touched — a generator that
 * invented its own tags would drift somewhere nobody asked for and the tag
 * space would never converge.
 */
function wantedTags(demand: Demand, supply: Demand, topic: string): string[] {
  // Thinking is the one subject where the reasoning move already says what
  // the card is about, so a tag on top of it is noise.
  if (topic === 'thinking') return [];
  const out: Array<[string, number]> = [];
  for (const [facet, want] of demand) {
    if (!facet.startsWith('tag:')) continue;
    const tag = facet.slice(4);
    const have = supply.get(facet) ?? 0;
    // A tag with a hundred cards is not short of them however popular it is.
    const gap = want - have / 20;
    if (gap > 0) out.push([tag, gap]);
  }
  return out
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([tag]) => tag);
}

/**
 * How much of a batch asks the reader something.
 *
 * The same four in five the app deals, for the same reason — reading facts is
 * not the training. It is enforced here as well as in the deck because a
 * catalogue that is four fifths facts cannot be dealt as four fifths
 * questions however good the ranking is.
 */
const kAskShare = 0.8;

/**
 * The briefs for one run.
 *
 * Deliberately spread across topics rather than piled onto the single largest
 * gap: a day's cards come from many subjects, so a generator that writes
 * eight cards about the biggest gap leaves the next-biggest untouched for a
 * week.
 */
export function planBriefs(
  demand: Demand,
  supply: Demand,
  count: number,
): Brief[] {
  const topics = byGap(demand, supply, 'topic', TOPICS);
  const tones = byGap(demand, supply, 'tone', TONES);
  const levels = byGap(demand, supply, 'level', LEVELS);
  const moves = byGap(demand, supply, 'move', MOVES.filter((m) => m !== 'none'));
  const asking = byGap(
    demand,
    supply,
    'format',
    KINDS.filter((k) => k !== 'none' && k !== 'side'),
  );

  const wantAsks = Math.round(count * kAskShare);
  const briefs: Brief[] = [];
  for (let i = 0; i < count; i += 1) {
    const topic = topics[i % topics.length];
    const asks = i < wantAsks;
    // One debate per run at most, for the reason the deck holds one a day:
    // a debate is ungraded, so it measures nothing.
    // A debate closes a run, but only a run big enough for one to be worth
    // a slot: a debate is ungraded, so a two-card batch with one in it has
    // measured nothing.
    const closesOnDebate = wantAsks >= 3 && i === wantAsks - 1;
    const kind: Brief['kind'] = !asks
      ? 'none'
      : closesOnDebate
        ? 'side'
        : (asking[i % asking.length] as Brief['kind']);
    briefs.push({
      topic,
      kind,
      level: (asks ? levels[i % levels.length] : 'easy') as Brief['level'],
      move: (kind === 'none' || kind === 'side'
        ? 'none'
        : moves[i % moves.length]) as Brief['move'],
      tone: tones[i % tones.length] as Brief['tone'],
      wanted: wantedTags(demand, supply, topic),
    });
  }
  return briefs;
}
