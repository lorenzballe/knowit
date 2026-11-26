// The day's games, counted across readers: Today's five at the top of
// Explore for every subject, and each subject's Today's three at the top of
// its page (lib/explore/blocks/bets/three.dart), dealt on the phone from the
// date alone (daily_deal.dart).
//
// A phone sends its play once it is over (playDaily, index.ts): the day on
// its calendar, the game, and each card with what was said on it. Every
// answer is judged here by the card's own test and scored as the phone
// scores it, and the play is added, once, to the counts of everybody who
// played the same cards that day: how many played, how many came to each
// score, and for each card how many got it right, which option each picked
// or where the guesses fell. Nothing about who: a mark under the reader's
// own record, which no phone reads or writes, is all that stops a play being
// counted twice, and a play counted already gets the counts back all the
// same.
//
// The counts are daily/{key}, the key naming the day, the game and the
// cards, so two phones dealt different cards (one a bank behind, or a page
// that names its own) are never counted as one game. Every signed-in phone
// reads them; only this writes them (firestore.rules).

import type { Firestore } from 'firebase-admin/firestore';
import { FieldValue } from 'firebase-admin/firestore';

import { Bank, Card, isPlaceCard, localDate, parseDate, shiftDate } from './bank.js';

/** The two games: the five on Explore for every subject, and a subject's three. */
export type DailyGame = 'five' | 'three';

/** How many cards each game asks: a hundred points a card. */
export const SIZE: Readonly<Record<DailyGame, number>> = { five: 5, three: 3 };

/** How a card is played: a pick of two or three options, or a share from 0 to 100% set on a track. */
export type DailyKind = 'pick' | 'share';

/** The units that make a number a share of a whole (the phone's BetAnswer). */
const SHARE_UNITS: ReadonlySet<string> = new Set(['%', 'percent', 'per cent']);

/**
 * How [c] is played among the day's games, or null when it is not one they
 * can ask: the phone's dailyKindOf. Not a card for grown-ups, a page, a card
 * about a place or an idea of a book; a pick of two or three options; a
 * typed number or an estimate whose answer is a share.
 */
export function dailyKind(c: Card): DailyKind | null {
  if (c.mature === true || c.web != null || isPlaceCard(c) || c.book != null) return null;
  switch (c.kind) {
    case 'pickOne': {
      const n = Array.isArray(c.options) ? c.options.length : 0;
      const correct = c.correct;
      return n >= 2 && n <= 3 && typeof correct === 'number' && correct >= 0 && correct < n ? 'pick' : null;
    }
    case 'number':
    case 'estimate': {
      const v = c.value;
      if (typeof v !== 'number' || !Number.isFinite(v)) return null;
      if (c.kind === 'estimate' && v <= 0) return null;
      const unit = typeof c.unit === 'string' ? c.unit.trim().toLowerCase() : '';
      return SHARE_UNITS.has(unit) && v >= 0 && v <= 100 ? 'share' : null;
    }
    default:
      return null;
  }
}

/**
 * What a guess is worth: a hundred for the answer itself, three fewer for
 * every point off, nothing past thirty-three; in tens. The phone's
 * threePoints, step for step, so both come to the same score.
 */
export function sharePoints(guess: number, answer: number): number {
  const raw = Math.min(100, Math.max(0, 100 - 3 * Math.abs(guess - answer)));
  return Math.min(100, Math.max(0, Math.round(raw / 10) * 10));
}

/** An answer as judged: right by the card's own test, the points it won, and the option picked or the guess. */
export interface Judged {
  right: boolean;
  points: number;
  pick?: number;
  guess?: number;
}

/** A pick as the phone sends it: the option's index. */
const PICK = /^[0-9]$/;

/** A share as the phone sends it (plainResponse): a plain number, at most six decimals. */
const SHARE = /^[0-9]{1,3}(\.[0-9]{1,6})?$/;

/**
 * [said] on [c], judged as the phone judges it (the card's `accepts`) and
 * scored as it scores it (dailyPoints); null when it is not an answer [c]
 * could be given: no option of the card's, or no share from 0 to 100.
 */
export function judge(c: Card, said: string): Judged | null {
  switch (dailyKind(c)) {
    case 'pick': {
      if (!PICK.test(said)) return null;
      const pick = Number(said);
      if (pick >= (c.options as unknown[]).length) return null;
      const right = pick === c.correct;
      return { right, points: right ? 100 : 0, pick };
    }
    case 'share': {
      if (!SHARE.test(said)) return null;
      const guess = Number(said);
      if (guess > 100) return null;
      const value = c.value as number;
      let right: boolean;
      if (c.kind === 'number') {
        const tolerance = typeof c.tolerance === 'number' ? c.tolerance : 0;
        right = Math.abs(guess - value) <= tolerance;
      } else {
        const factor = typeof c.withinFactor === 'number' ? c.withinFactor : 3;
        right = guess > 0 && guess >= value / factor && guess <= value * factor;
      }
      return { right, points: sharePoints(guess, value), guess };
    }
    default:
      return null;
  }
}

/**
 * The name the counts of everybody who played [ids] on [day] are kept
 * under: the day, the game and the cards in order, whatever order they were
 * played in. The phone's DailyGame.keyFor, character for character.
 */
export function gameKey(day: string, game: DailyGame, ids: readonly string[]): string {
  return `${day}~${game}~${[...ids].sort().join(',')}`;
}

/**
 * Whether a play of [day] may be counted at [nowMs]: today on the phone's
 * clock, [tz] minutes from UTC, or yesterday there, for a play locked in
 * before midnight that arrives after it.
 */
export function playableDay(day: string, tz: number, nowMs: number): boolean {
  if (!parseDate(day)) return false;
  const today = localDate(nowMs, tz);
  return day === today || day === shiftDate(today, -1);
}

/** One card of a play: what was said on it, and how it was judged. */
export interface PlayedCard {
  id: string;
  said: string;
  judged: Judged;
}

/** A play as it is counted. */
export interface Play {
  day: string;
  game: DailyGame;
  /** The subject's key, for a subject's three; null for the five. */
  subject: string | null;
  /** In the order played. */
  cards: PlayedCard[];
  /** What the answers came to, a hundred a card at most. */
  score: number;
  /** Where the counts are kept: daily/{key}. */
  key: string;
  /** The reader's mark, readers/{uid}/daily/{mark}: the day and the game as the phone keeps its score, `2026-11-25~five`, `2026-11-25~three-art`. */
  mark: string;
}

/** A card's id as the bank writes them (firestore.rules, isCardId). */
const CARD_ID = /^[a-z0-9_-]{1,64}$/;

/**
 * [data] as a play of the day's games, every answer judged against [bank];
 * otherwise, what is wrong with it. The five is five cards of five subjects,
 * a three three cards of one, each a card the day's games ask, each once;
 * and the day is today on the phone's clock.
 */
export function readPlay(data: unknown, bank: Bank, nowMs: number): Play | string {
  const d = (data ?? {}) as { date?: unknown; game?: unknown; cards?: unknown; tz?: unknown };
  const game = d.game === 'five' || d.game === 'three' ? d.game : null;
  if (!game) return 'A game: five or three.';
  const tz = typeof d.tz === 'number' && Number.isFinite(d.tz) && Math.abs(d.tz) <= 14 * 60 ? d.tz : 0;
  const day = typeof d.date === 'string' ? d.date : '';
  if (!playableDay(day, tz, nowMs)) return 'A day that is today on the phone\'s clock.';
  if (!Array.isArray(d.cards) || d.cards.length !== SIZE[game]) return `${SIZE[game]} cards.`;
  const cards: PlayedCard[] = [];
  const subjects = new Set<string>();
  for (const raw of d.cards) {
    const { id, said } = (raw ?? {}) as { id?: unknown; said?: unknown };
    if (typeof id !== 'string' || !CARD_ID.test(id) || typeof said !== 'string') return 'Each card, with what was said on it.';
    if (cards.some((c) => c.id === id)) return 'Each card once.';
    // A card newer than the server's bank: the phone tries again at its next run.
    const card = bank.byId.get(id);
    if (!card) return `No card ${id} in bank ${bank.version}.`;
    const judged = judge(card, said);
    if (!judged) return `Not an answer the day's games take on ${id}.`;
    subjects.add(card.topic);
    cards.push({ id, said, judged });
  }
  if (subjects.size !== (game === 'five' ? SIZE.five : 1)) {
    return game === 'five' ? 'Five subjects, a card each.' : 'Three cards of one subject.';
  }
  const subject = game === 'three' ? [...subjects][0] : null;
  return {
    day,
    game,
    subject,
    cards,
    score: cards.reduce((s, c) => s + c.judged.points, 0),
    key: gameKey(day, game, cards.map((c) => c.id)),
    mark: `${day}~${subject === null ? 'five' : `three-${subject}`}`,
  };
}

/** A count, or counts by place: by score in tens, by option, by ten of the guess. */
type Counted = { [k: string]: number | Counted };

/**
 * What one play adds to its game's counts: one player, and one at its score
 * in tens; for each card one answer, one right if it was, and one on the
 * option picked, or on the ten the guess fell in (0–9% up to 100%) with the
 * guess added to the sum, for the average.
 */
export function tallyOf(play: Play): Counted {
  const items: Counted = {};
  for (const { id, judged } of play.cards) {
    const right = judged.right ? 1 : 0;
    items[id] = judged.guess === undefined
      ? { n: 1, right, picks: { [String(judged.pick)]: 1 } }
      : { n: 1, right, guesses: { [String(Math.min(10, Math.floor(judged.guess / 10)))]: 1 }, sum: judged.guess };
  }
  return { players: 1, scores: { [String(Math.round(play.score / 10))]: 1 }, items };
}

/** [c] with every number an increment by it, to be merged into what is kept. */
function increments(c: Counted): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(c)) out[k] = typeof v === 'number' ? FieldValue.increment(v) : increments(v);
  return out;
}

/** A game's counts as the phone reads them (lib/sync/daily_crowd.dart, DailyCounts): the counts kept, and nothing else of the document. */
export interface Counts {
  players: number;
  scores: Record<string, number>;
  items: Record<string, unknown>;
}

/** [data], a document of daily/, as its counts; null before anybody played. */
export function countsOf(data: Record<string, unknown> | undefined): Counts | null {
  if (!data || typeof data.players !== 'number') return null;
  const map = (v: unknown): Record<string, unknown> =>
    v !== null && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : {};
  return { players: data.players, scores: map(data.scores) as Record<string, number>, items: map(data.items) };
}

/** What a create comes back with when its document is there already. */
const ALREADY_EXISTS = 6;

/**
 * Counts [play] for [uid], once: the reader's mark made and the counts
 * added to in one write, which fails whole when the mark is there already.
 * The counts after it, either way.
 */
export async function countPlay(db: Firestore, uid: string, play: Play): Promise<{ counted: boolean; counts: Counts | null }> {
  const counts = db.collection('daily').doc(play.key);
  const mark = db.collection('readers').doc(uid).collection('daily').doc(play.mark);
  let counted = true;
  try {
    await db
      .batch()
      .create(mark, { at: FieldValue.serverTimestamp() })
      .set(
        counts,
        {
          day: play.day,
          game: play.game,
          ...(play.subject === null ? {} : { subject: play.subject }),
          cards: play.cards.map((c) => c.id).sort(),
          at: FieldValue.serverTimestamp(),
          ...increments(tallyOf(play)),
        },
        { merge: true },
      )
      .commit();
  } catch (e) {
    if ((e as { code?: unknown }).code !== ALREADY_EXISTS) throw e;
    counted = false;
  }
  return { counted, counts: countsOf((await counts.get()).data()) };
}

/** How long a reader's marks are kept: a play is counted only on its day or the next, so a mark older than that stops nothing. */
export const KEEP_MARK_DAYS = 3;
