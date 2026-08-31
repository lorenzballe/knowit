import { getFirestore } from 'firebase-admin/firestore';
import { Card, kSameCard, overlap, shingle } from './card';

/**
 * Where written cards live, and what the app is allowed to see.
 *
 * One document per card at cards/{id}. Readable by any signed-in reader,
 * writable by nobody but this code — see firestore.rules. That asymmetry is
 * the point of putting the writer on a server at all: a card is the app's
 * claim about the world, and a claim anyone can edit is not one.
 */

export interface StoredCard extends Card {
  /** When it was written. The app fetches only what is newer than its cache. */
  writtenAt: number;
  /** Which model wrote it, for tracing a bad card back to a prompt change. */
  writtenBy: string;
}

const CARDS = 'cards';
const REJECTS = 'rejected';

export async function liveCards(): Promise<StoredCard[]> {
  const snap = await getFirestore().collection(CARDS).get();
  return snap.docs.map((d) => d.data() as StoredCard);
}

/**
 * The questions already asked, for the brief.
 *
 * Capped, and biased toward the topics being written for: the whole catalogue
 * in every prompt would grow without bound, and a card about bees is not made
 * more original by having seen every card about Rome.
 */
export function questionsFor(
  existing: StoredCard[],
  topics: Set<string>,
  cap = 120,
): string[] {
  const near = existing.filter((c) => topics.has(c.topic));
  const rest = existing.filter((c) => !topics.has(c.topic));
  return [...near, ...rest].slice(0, cap).map((c) => `${c.id}: ${c.question}`);
}

/**
 * Whether this card is one the catalogue already holds.
 *
 * Compared on the question rather than on the answer, because the reader
 * meets the question — two cards that arrive at the same fact by genuinely
 * different routes are two cards, and two ways of phrasing one question are
 * one card.
 */
export function isDuplicate(card: Card, existing: StoredCard[]): string | null {
  if (existing.some((c) => c.id === card.id)) return 'id already taken';
  const mine = shingle(card.question);
  for (const other of existing) {
    if (other.topic !== card.topic) continue;
    if (overlap(mine, shingle(other.question)) >= kSameCard) {
      return `too close to ${other.id}`;
    }
  }
  return null;
}

/** Writes accepted cards. Batched: a day's output is one round trip. */
export async function publish(cards: StoredCard[]): Promise<void> {
  if (cards.length === 0) return;
  const db = getFirestore();
  const batch = db.batch();
  for (const card of cards) {
    batch.set(db.collection(CARDS).doc(card.id), card);
  }
  await batch.commit();
}

/**
 * Keeps what was thrown away, and why.
 *
 * A generator whose failures are invisible cannot be improved: the only way
 * to tell a prompt that is too vague from one that is too strict is to read
 * what it produced and what the check said about it. Nothing here is ever
 * served to a reader.
 */
export async function recordReject(
  card: Partial<Card> & { id?: string },
  reasons: string[],
): Promise<void> {
  const db = getFirestore();
  const id = card.id ?? `unnamed-${Date.now()}`;
  await db
    .collection(REJECTS)
    .doc(`${id}-${Date.now()}`)
    .set({ card, reasons, at: Date.now() });
}
