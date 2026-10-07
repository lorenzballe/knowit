// The bank, as the server sees it.
//
// The same document the phones download — web/cards/cards.json, built by
// tool/cards/bundle.py — read here from the copy bundled at deploy, and
// refreshed from the site when it has something newer, so a card written
// last night is in the server's hands by the time it deals the morning.
// Nothing here knows the cards' meaning: it knows their tags, their kinds,
// and the calendar frozen beside them.

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

export type Kind = 'read' | 'pickOne' | 'number' | 'estimate' | 'debate';
export type Difficulty = 'easy' | 'medium' | 'hard';

/** A card, as it is written in the bank. Only what the dealer reads is typed. */
export interface Card {
  id: string;
  topic: string;
  genre?: string;
  strand?: string;
  also?: string[];
  kind: Kind;
  difficulty: Difficulty;
  principle: string;
  question: string;
  answer: string;
  move?: string;
  keywords?: string[];
  era?: string;
  region?: string;
  hook?: string;
  mood?: string;
  numeracy?: number;
  abstraction?: string;
  shelf_life?: string;
  builds_on?: string[];
  disabled?: boolean;
  /** The day a person or the re-check last confirmed the card against its source: reports from before it are answered. */
  checked?: string;
  [key: string]: unknown;
}

export interface Strand { id: string; label: string }
export interface Genre { id: string; label: string; strands: Strand[] }

const here = dirname(fileURLToPath(import.meta.url));

/** The subject tree, one layer down and one below that: lib/data/genres.dart, dumped at build. */
export const GENRES: Record<string, Genre[]> = JSON.parse(
  readFileSync(join(here, '..', 'data', 'genres.json'), 'utf8'),
);

/** Every subject key, in the app's own order of the wheel. */
export const TOPICS: string[] = Object.keys(GENRES);

/** A subject's name as the phone shows it and keys its shelves by: `weird_facts` is `Weird facts`. */
export function topicName(key: string): string {
  const words = key.split('_').join(' ');
  return words.charAt(0).toUpperCase() + words.slice(1);
}

export function genreOf(strandId: string): string {
  return strandId.slice(0, strandId.lastIndexOf('.'));
}

/** The cards that can be marked: a right answer exists. */
export const GRADED: ReadonlySet<Kind> = new Set(['pickOne', 'number', 'estimate']);

export const asks = (c: Card): boolean => c.kind !== 'read';
export const graded = (c: Card): boolean => GRADED.has(c.kind);
export const isDebate = (c: Card): boolean => c.kind === 'debate';

/** Every strand a card is about: its own, and the ones it is also about. */
export function strandsOf(c: Card): string[] {
  return [c.strand ?? '', ...(c.also ?? [])].filter((s) => s.length > 0);
}

/**
 * Whether a card is stale on [date] (`yyyy-mm-dd`): a card about the news
 * carries the last day it is current in its scene's `expires`
 * (lib/models/scenes/news.dart), and from the day after it is never dealt.
 * Date keys compare as strings.
 */
export function expiredOn(c: Card, date: string): boolean {
  const scene = c.scene as { type?: unknown; expires?: unknown } | undefined;
  return scene?.type === 'news' && typeof scene.expires === 'string' && scene.expires < date;
}

/** The card's traits as the taste is keyed: the same list as Pill.traits. */
export function traitsOf(c: Card): string[] {
  const out: string[] = [];
  if (c.genre) out.push(`genre:${c.genre}`);
  for (const s of strandsOf(c)) out.push(`strand:${s}`);
  if (c.era) out.push(`era:${c.era}`);
  if (c.region && c.region !== 'none') out.push(`region:${c.region}`);
  if (c.hook) out.push(`hook:${c.hook}`);
  if (c.mood) out.push(`mood:${c.mood}`);
  if (c.era) out.push(`numeracy:${c.numeracy ?? 0}`);
  if (c.abstraction) out.push(`abstraction:${c.abstraction}`);
  return out;
}

/** A bank: the cards, indexed, and the calendar. */
export class Bank {
  readonly version: number;
  readonly built: string;
  readonly cards: Card[];
  readonly byId: Map<string, Card>;
  readonly editions: Map<number, string>;
  readonly commons: Map<number, string[]>;

  constructor(doc: { version: number; built?: string; cards: Card[]; editions?: Record<string, string>; commons?: Record<string, string[]> }) {
    this.version = doc.version;
    this.built = doc.built ?? '';
    this.cards = doc.cards;
    this.byId = new Map(doc.cards.map((c) => [c.id, c]));
    this.editions = new Map(Object.entries(doc.editions ?? {}).map(([k, v]) => [Number(k), v]));
    this.commons = new Map(Object.entries(doc.commons ?? {}).map(([k, v]) => [Number(k), v]));
  }

  /** The cards still dealt: a retired card answers by id but is never dealt again. */
  get live(): Card[] {
    return this.cards.filter((c) => !c.disabled);
  }

  /** The cards that may be dealt on [date]: live, and not past their expiry. */
  liveOn(date: string): Card[] {
    return this.live.filter((c) => !expiredOn(c, date));
  }

  static parse(text: string): Bank {
    const doc = JSON.parse(text);
    if (typeof doc !== 'object' || doc === null || typeof doc.version !== 'number' || !Array.isArray(doc.cards)) {
      throw new Error('not a bank');
    }
    return new Bank(doc);
  }

  /** The copy bundled at deploy. */
  static bundled(): Bank {
    return Bank.parse(readFileSync(join(here, '..', 'data', 'bank.json'), 'utf8'));
  }
}

/** Where the phones download the bank from, and the note that names its version. */
export const BANK_URL = 'https://astutetheapp.com/cards/cards.json';
export const VERSION_URL = 'https://astutetheapp.com/cards/version.json';

let current: Bank | null = null;
let checkedAt = 0;
const FRESH_MS = 10 * 60 * 1000;

/**
 * The newest bank the server can get: the site's when it names a newer
 * version than the one in hand, asked at most every ten minutes, and the
 * bundled copy otherwise. Never throws: a site that does not answer leaves
 * the bank in hand exactly as it was.
 */
export async function currentBank(fetcher: typeof fetch = fetch): Promise<Bank> {
  current ??= Bank.bundled();
  const now = Date.now();
  if (now - checkedAt < FRESH_MS) return current;
  checkedAt = now;
  try {
    const note = await fetcher(VERSION_URL);
    if (!note.ok) return current;
    const { version } = (await note.json()) as { version?: number };
    if (typeof version !== 'number' || version <= current.version) return current;
    const body = await fetcher(BANK_URL);
    if (!body.ok) return current;
    current = Bank.parse(await body.text());
  } catch {
    // The bundled copy, or the last one fetched, stands.
  }
  return current;
}

/** For the tests: a bank other than the bundled one. */
export function useBank(bank: Bank | null): void {
  current = bank;
  checkedAt = bank ? Number.MAX_SAFE_INTEGER : 0;
}

// ── Days and editions ────────────────────────────────────────────────────

/** The day the calendar began: edition 1. */
export const EPOCH_UTC = Date.UTC(2026, 8, 1);

/** A date key, `yyyy-mm-dd`, from a UTC-noon timestamp or a key. */
export function dateKey(y: number, m: number, d: number): string {
  return `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
}

export function parseDate(key: string): { y: number; m: number; d: number } | null {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(key);
  if (!m) return null;
  const y = Number(m[1]), mo = Number(m[2]), d = Number(m[3]);
  const t = new Date(Date.UTC(y, mo - 1, d));
  if (t.getUTCFullYear() !== y || t.getUTCMonth() !== mo - 1 || t.getUTCDate() !== d) return null;
  return { y, m: mo, d };
}

/** Which edition a date key is: the first day is 1, every day after one more. */
export function editionOf(key: string): number {
  const p = parseDate(key);
  if (!p) throw new Error(`not a date: ${key}`);
  return Math.round((Date.UTC(p.y, p.m - 1, p.d) - EPOCH_UTC) / 86_400_000) + 1;
}

/** The date key [days] after [key]. */
export function shiftDate(key: string, days: number): string {
  const p = parseDate(key);
  if (!p) throw new Error(`not a date: ${key}`);
  const t = new Date(Date.UTC(p.y, p.m - 1, p.d + days));
  return dateKey(t.getUTCFullYear(), t.getUTCMonth() + 1, t.getUTCDate());
}

/** The reader's local date key at [nowMs], their clock [tzMinutes] from UTC. */
export function localDate(nowMs: number, tzMinutes: number): string {
  const t = new Date(nowMs + tzMinutes * 60_000);
  return dateKey(t.getUTCFullYear(), t.getUTCMonth() + 1, t.getUTCDate());
}

/** The reader's local hour at [nowMs]. */
export function localHour(nowMs: number, tzMinutes: number): number {
  return new Date(nowMs + tzMinutes * 60_000).getUTCHours();
}
