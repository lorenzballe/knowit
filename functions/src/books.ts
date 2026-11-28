// Books read aloud: a book's summary heard a part at a time (bookClip in
// index.ts; the phone's side is lib/books/). A summary is the longer way into
// a book of Books in pills, about fifteen minutes in five to eight parts
// (tool/cards/summaries.py), and each part is one clip: its title, then its
// paragraphs, read by ElevenLabs once for every reader alike and kept in
// Storage under the hash of its words and how they were read (bookClipKey).
// A summary whose words change is read anew, part by part, and only the
// parts that changed: nobody pays twice for the same words.
//
// What is read is the summary the bank names. The bank lists each summary
// with the hash of its bytes (`summaries` in the bank, SummaryRef); the
// functions are deployed with a copy of every summary (data/summaries/,
// `npm run data`), and a summary revised since the deploy is fetched from
// the site and read only when its hash is the one the bank names. What the
// phone sends is a book and a part, never words.
//
// Who hears what, as for reading. The week's free book is free to read and
// to hear, worked out as every phone works it out (lib/data/books.dart,
// bookOfTheWeek), and so is the first part of any book. The rest is
// Astute+, the plan read from the presence as askCard and listenCard read it.
//
// What it may cost. ElevenLabs charges by the character, and the book audio
// keeps to its own month (BOOK_AUDIO_MONTH_CHARS, limits.ts), counted in
// bookSpend/{yyyy-mm}: a clip is read only when every part of its book still
// to be read fits in what the month has left, so a book is skipped rather
// than left half read, and once the month is spent nothing new is read until
// it turns. What was read before still plays.
//
// The voice is Listen's (listen.ts): Finley, "Articulate Anchor", on Eleven
// v4 Turbo, which reads long passages naturally at half the price of v4. The
// key is Listen's too: without it every call says "not configured", and the
// phone hides listening; with a key but no credit, it is calmly "not
// available right now".

import { createHash, randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { type DocumentSnapshot, FieldValue, type Firestore } from 'firebase-admin/firestore';

import { type Bank, parseDate } from './bank.js';
import { BOOK_AUDIO_MONTH_CHARS } from './limits.js';
import {
  type BucketLike,
  type CharSpend,
  OUTPUT_FORMAT,
  ShelfMissing,
  VOICE_ID,
  VOICE_SETTINGS,
  type Voice,
  VoiceRefused,
  asWords,
  clipUrl,
} from './listen.js';

export { BOOK_AUDIO_MONTH_CHARS };

// ── The voice ────────────────────────────────────────────────────────────

/**
 * Eleven v4 Turbo: the cheaper half of ElevenLabs' newest family, $0.04 for
 * a thousand characters where v4 is $0.08, as cheap as Flash and far more
 * natural over a quarter of an hour. Listen reads a card's few lines on v4;
 * a book is read on this.
 */
export const BOOK_MODEL_ID = 'eleven_v4_turbo';

/** Everything a part is read with besides its words: a new voice, model or
 * setting is a new clip. */
const MADE_WITH = [
  BOOK_MODEL_ID,
  VOICE_ID,
  OUTPUT_FORMAT,
  `stability ${VOICE_SETTINGS.stability}`,
  `similarity ${VOICE_SETTINGS.similarity_boost}`,
  'en',
].join('|');

/** The name a part's clip is kept under: the hash of how it is read and what. */
export function bookClipKey(text: string): string {
  return createHash('sha256').update(`${MADE_WITH}\n${text}`).digest('hex');
}

/** The most one clip reads: well past any part the gate lets through (520
 * words), and a stop for one that is not a part. */
export const MOST_PART = 6000;

/** About how long a clip plays: the audio is MP3 at a steady 128 kbps. */
export function secondsOf(audio: Buffer): number {
  return Math.round((audio.length * 8) / 128_000);
}

// ── The summary ──────────────────────────────────────────────────────────

/** A summary as published (web/cards/summaries/<book>.json), what of it is read aloud. */
export interface Summary {
  book: string;
  title: string;
  author: string;
  parts: { title: string; text: string[] }[];
}

/** [text] read as a summary, or null for anything that is not one. */
export function parseSummary(text: string): Summary | null {
  try {
    const doc = JSON.parse(text) as Record<string, unknown>;
    const parts = doc.parts;
    if (typeof doc.book !== 'string' || typeof doc.title !== 'string' || typeof doc.author !== 'string') return null;
    if (!Array.isArray(parts) || parts.length === 0) return null;
    const out: Summary['parts'] = [];
    for (const p of parts as unknown[]) {
      const part = p as { title?: unknown; text?: unknown } | null;
      if (typeof part?.title !== 'string' || !Array.isArray(part.text)) return null;
      const paragraphs = part.text.filter((t): t is string => typeof t === 'string' && t.trim().length > 0);
      if (paragraphs.length === 0) return null;
      out.push({ title: part.title, text: paragraphs });
    }
    return { book: doc.book, title: doc.title, author: doc.author, parts: out };
  } catch {
    return null;
  }
}

/** Whether [text] is the summary [ref] names: its hash begins with the `v`
 * the name carries (lib/data/card_pages.dart, CardPages.matches). */
export function matches(ref: string, text: string): boolean {
  const v = new URL(ref, 'https://astutetheapp.com/cards/').searchParams.get('v');
  if (!v) return true;
  return createHash('sha256').update(text, 'utf8').digest('hex').startsWith(v);
}

/**
 * What part [i] of [summary] says aloud: the book and its author before the
 * first, then the part's title and its paragraphs, a pause between each, and
 * the signs a voice reads badly in words. Null past the last part.
 */
export function spokenPart(summary: Summary, i: number): string | null {
  const part = summary.parts[i];
  if (!part) return null;
  const head = i === 0 ? `${summary.title}, by ${summary.author}.\n\n` : '';
  const text = asWords(`${head}${part.title}.\n\n${part.text.join('\n\n')}`).replace(/ *\n */g, '\n');
  if (text.length <= MOST_PART) return text;
  const cut = text.slice(0, MOST_PART);
  return cut.slice(0, Math.max(cut.lastIndexOf('. ') + 1, 1));
}

/** Where summaries are published, and read from when the deploy's copy is older. */
export const SUMMARIES_BASE = 'https://astutetheapp.com/cards/';

/** Where the functions find the summaries they were deployed with. */
const BUNDLED = join(dirname(fileURLToPath(import.meta.url)), '..', 'data', 'summaries');

/** The summaries, as the bank names them. */
export interface Library {
  /** [book]'s summary as the bank names it, or null: no summary, or none
   * whose bytes are the ones named. */
  summaryOf(bank: Bank, book: string): Promise<Summary | null>;
}

/**
 * The summaries the deploy carries, and the site's for one revised since:
 * read once, kept by the name the bank gives them. A copy whose hash is not
 * the one named (a cache on the way not yet caught up) is never read aloud.
 */
export function siteLibrary(dir: string = BUNDLED, fetcher: typeof fetch = fetch): Library {
  const held = new Map<string, Summary>();
  return {
    async summaryOf(bank, book) {
      const ref = bank.summaries.get(book);
      if (!ref || !/^[a-z0-9-]{1,80}$/.test(book)) return null;
      const kept = held.get(ref.file);
      if (kept) return kept;
      let text: string | null = null;
      try {
        const local = readFileSync(join(dir, `${book}.json`), 'utf8');
        if (matches(ref.file, local)) text = local;
      } catch {
        // Not in the deploy: a book summarised since.
      }
      if (text === null) {
        try {
          const res = await fetcher(new URL(ref.file, SUMMARIES_BASE).toString());
          const body = res.ok ? await res.text() : '';
          if (body && matches(ref.file, body)) text = body;
        } catch {
          // The site did not answer: nothing to read this time.
        }
      }
      const summary = text === null ? null : parseSummary(text);
      if (!summary || summary.book !== book) return null;
      held.set(ref.file, summary);
      return summary;
    },
  };
}

/** The summaries in memory, for the tests. */
export function memoryLibrary(summaries: Summary[]): Library {
  const byBook = new Map(summaries.map((s) => [s.book, s]));
  return {
    async summaryOf(bank, book) {
      return bank.summaries.has(book) ? (byBook.get(book) ?? null) : null;
    },
  };
}

// ── Who hears what ───────────────────────────────────────────────────────

/** The day the weeks of books are counted from, as the phones count them. */
const WEEK_ZERO = Date.UTC(2026, 0, 1);

/**
 * The book every reader reads and hears whole in the week of [date] (the
 * reader's own day, yyyy-mm-dd), as every phone works it out
 * (lib/data/books.dart, booksOf and bookOfTheWeek): the books of the bank
 * with four ideas or more among the cards still dealt, in the order of their
 * ids, turned one place a week from the first week of 2026.
 */
export function bookOfTheWeek(bank: Bank, date: string): string | null {
  const p = parseDate(date);
  if (!p) return null;
  const counts = new Map<string, number>();
  for (const c of bank.cards) {
    const id = (c.book as { id?: unknown } | undefined)?.id;
    if (c.disabled || typeof id !== 'string') continue;
    counts.set(id, (counts.get(id) ?? 0) + 1);
  }
  const books = [...counts.entries()].filter(([, n]) => n >= 4).map(([id]) => id).sort();
  if (books.length === 0) return null;
  const days = Math.floor((Date.UTC(p.y, p.m - 1, p.d) - WEEK_ZERO) / 86_400_000);
  const week = Math.floor(days / 7);
  return books[((week % books.length) + books.length) % books.length];
}

/**
 * The books free this week for a reader whose day is [date]: the week's, and
 * the one before it on the day the week turns. A phone counts its days in
 * its own time, and in summer, where clocks go forward, it turns to the next
 * book a day later than the calendar; a day's grace means no phone is ever
 * told a book is free that the server then refuses.
 */
export function freeBooks(bank: Bank, date: string): Set<string> {
  const p = parseDate(date);
  const out = new Set<string>();
  if (!p) return out;
  const before = new Date(Date.UTC(p.y, p.m - 1, p.d - 1));
  const yesterday = `${before.getUTCFullYear()}-${String(before.getUTCMonth() + 1).padStart(2, '0')}-${String(before.getUTCDate()).padStart(2, '0')}`;
  for (const d of [date, yesterday]) {
    const book = bookOfTheWeek(bank, d);
    if (book) out.add(book);
  }
  return out;
}

/** Whether a reader may hear part [part] of [book]: with Astute+, every
 * part; otherwise the first part of any book, and the week's book whole. */
export function mayHear(plus: boolean, book: string, part: number, free: ReadonlySet<string>): boolean {
  return plus || part === 0 || free.has(book);
}

// ── Where the clips are kept ─────────────────────────────────────────────

/** A part's clip as the phone gets it: where it is, how long it plays, and
 * what it cost to make. */
export interface BookClip {
  url: string;
  seconds: number;
  chars: number;
}

/** What a clip is kept with, for a person reading the index. */
export interface BookClipMeta {
  book: string;
  part: number;
  chars: number;
  seconds: number;
}

/** The clips made so far, by their key. */
export interface BookShelf {
  find(key: string): Promise<BookClip | null>;
  /** Every key's clip, or null, in one read: what of a book is still to be read. */
  findAll(keys: string[]): Promise<(BookClip | null)[]>;
  /** Takes the making of [key]'s clip, so two readers asking at once do not
   * pay for it twice: false while another is making it. */
  claim(key: string): Promise<boolean>;
  /** Lets go of a claim that made nothing. */
  release(key: string): Promise<void>;
  keep(key: string, audio: Buffer, meta: BookClipMeta): Promise<BookClip>;
  /** Whether a new clip can be kept at all: asked before one is read, so no
   * character is paid for a clip with nowhere to go. */
  ready(): Promise<boolean>;
}

/** Where a clip lives in Storage: books/{key}.mp3, which storage.rules lets
 * signed-in readers read and nobody but the functions write. */
export function bookClipPath(key: string): string {
  return `books/${key}.mp3`;
}

/** How long a claim on a clip being made holds: past any one reading. */
export const CLAIM_MS = 120_000;

/** The clips in Storage, with their index in Firestore (bookClips/{key}: the
 * address, the book and part, how long, what it cost), so a clip already made
 * is one read away. */
export function storageBookShelf(
  db: Firestore,
  bucket: BucketLike,
  token: () => string = randomUUID,
  now: () => number = Date.now,
): BookShelf {
  const index = db.collection('bookClips');
  const clipOf = (snap: DocumentSnapshot): BookClip | null => {
    const url = snap.get('url');
    return typeof url === 'string' && url
      ? { url, seconds: Number(snap.get('seconds')) || 0, chars: Number(snap.get('chars')) || 0 }
      : null;
  };
  // A bucket found is found for good; one missing is asked about again
  // after a few minutes, so setting Storage up needs no deploy.
  let found = false;
  let missingAt = Number.NEGATIVE_INFINITY;
  return {
    async ready() {
      if (found) return true;
      if (now() - missingAt < 5 * 60_000) return false;
      try {
        [found] = await bucket.exists();
      } catch {
        found = false;
      }
      if (!found) missingAt = now();
      return found;
    },
    async find(key) {
      return clipOf(await index.doc(key).get());
    },
    async findAll(keys) {
      if (keys.length === 0) return [];
      const snaps = await db.getAll(...keys.map((k) => index.doc(k)));
      return snaps.map(clipOf);
    },
    claim: (key) =>
      db.runTransaction(async (t) => {
        const ref = index.doc(key);
        const snap = await t.get(ref);
        if (clipOf(snap)) return false;
        const at = Number(snap.get('making')) || 0;
        if (at > now() - CLAIM_MS) return false;
        t.set(ref, { making: now() }, { merge: true });
        return true;
      }),
    async release(key) {
      await index.doc(key).set({ making: FieldValue.delete() }, { merge: true });
    },
    async keep(key, audio, meta) {
      const path = bookClipPath(key);
      const t = token();
      await bucket.file(path).save(audio, {
        resumable: false,
        metadata: {
          contentType: 'audio/mpeg',
          cacheControl: 'public, max-age=31536000',
          metadata: { firebaseStorageDownloadTokens: t, book: meta.book, part: String(meta.part) },
        },
      });
      const url = clipUrl(bucket.name, path, t);
      await index.doc(key).set({
        url,
        path,
        book: meta.book,
        part: meta.part,
        chars: meta.chars,
        seconds: meta.seconds,
        voice: VOICE_ID,
        model: BOOK_MODEL_ID,
        at: FieldValue.serverTimestamp(),
        making: FieldValue.delete(),
      });
      return { url, seconds: meta.seconds, chars: meta.chars };
    },
  };
}

/** The clips in memory, for the tests. */
export function memoryBookShelf(
  bucket = 'test-bucket',
  ready = true,
): BookShelf & { kept: Map<string, { audio: Buffer; meta: BookClipMeta; url: string }>; making: Set<string> } {
  const kept = new Map<string, { audio: Buffer; meta: BookClipMeta; url: string }>();
  const making = new Set<string>();
  const clipOf = (key: string): BookClip | null => {
    const k = kept.get(key);
    return k ? { url: k.url, seconds: k.meta.seconds, chars: k.meta.chars } : null;
  };
  return {
    kept,
    making,
    async ready() {
      return ready;
    },
    async find(key) {
      return clipOf(key);
    },
    async findAll(keys) {
      return keys.map(clipOf);
    },
    async claim(key) {
      if (kept.has(key) || making.has(key)) return false;
      making.add(key);
      return true;
    },
    async release(key) {
      making.delete(key);
    },
    async keep(key, audio, meta) {
      const url = clipUrl(bucket, bookClipPath(key), `token-${kept.size + 1}`);
      kept.set(key, { audio, meta, url });
      making.delete(key);
      return { url, seconds: meta.seconds, chars: meta.chars };
    },
  };
}

// ── What it may cost ─────────────────────────────────────────────────────

/** Where the characters read for books are counted, as budget.ts counts dollars. */
export interface BookLedger {
  /** Holds back [chars] of [month]'s characters for a clip about to be made,
   * when [whole], every part of its book still to be read, this one with
   * them, fits in what the month has left. False, and nothing held, when it
   * would not: the book is skipped this month. */
  reserve(month: string, chars: number, whole: number): Promise<boolean>;
  /** A clip is made or failed: the [held] characters let go, and the [used]
   * ones and the [clips] made counted. */
  settle(month: string, held: number, used: number, clips: number): Promise<void>;
}

/** The characters in Firestore, bookSpend/{yyyy-mm}, written by the server alone. */
export function firestoreBookLedger(db: Firestore, limit: number = BOOK_AUDIO_MONTH_CHARS): BookLedger {
  const doc = (month: string) => db.collection('bookSpend').doc(month);
  return {
    reserve: (month, chars, whole) =>
      db.runTransaction(async (t) => {
        const ref = doc(month);
        const s = await t.get(ref);
        const used = (s.get('chars') ?? 0) + Math.max(0, s.get('held') ?? 0);
        if (used + Math.max(chars, whole) > limit) {
          t.set(ref, { refused: FieldValue.increment(1) }, { merge: true });
          return false;
        }
        t.set(ref, { held: FieldValue.increment(chars) }, { merge: true });
        return true;
      }),
    settle: async (month, held, used, clips) => {
      await doc(month).set(
        { held: FieldValue.increment(-held), chars: FieldValue.increment(used), clips: FieldValue.increment(clips) },
        { merge: true },
      );
    },
  };
}

/** The characters in memory, for the tests: months under yyyy-mm. */
export function memoryBookLedger(limit: number = BOOK_AUDIO_MONTH_CHARS): BookLedger & { spend: Map<string, CharSpend> } {
  const spend = new Map<string, CharSpend>();
  const of = (month: string): CharSpend => {
    let s = spend.get(month);
    if (!s) {
      s = { chars: 0, held: 0, clips: 0, refused: 0 };
      spend.set(month, s);
    }
    return s;
  };
  return {
    spend,
    async reserve(month, chars, whole) {
      const s = of(month);
      if (s.chars + Math.max(0, s.held) + Math.max(chars, whole) > limit) {
        s.refused++;
        return false;
      }
      s.held += chars;
      return true;
    },
    async settle(month, held, used, clips) {
      const s = of(month);
      s.held -= held;
      s.chars += used;
      s.clips += clips;
    },
  };
}

// ── A clip, made once ────────────────────────────────────────────────────

/** Nothing was read: the month's characters for books cannot hold the book. */
export class BookSpent extends Error {
  constructor(readonly month: string) {
    super(`the book audio's characters of ${month} cannot hold this book`);
    this.name = 'BookSpent';
  }
}

/** Nothing was read: another reader's ask is making this clip, and it did
 * not come in time. */
export class BookBusy extends Error {
  constructor() {
    super('another ask is making this clip');
    this.name = 'BookBusy';
  }
}

/** What making a clip needs: where clips are kept, the characters, the
 * voice, the UTC month it is counted under, and how to wait for a clip
 * another ask is making. */
export interface BookMaking {
  shelf: BookShelf;
  ledger: BookLedger;
  voice: Voice;
  month: string;
  pause?: (ms: number) => Promise<void>;
}

/** How long, at the most, an ask waits for a clip another ask is making. */
export const WAIT_MS = 30_000;
const WAIT_STEP_MS = 1_500;

/**
 * Part [part] of [summary] as a clip: the one kept, at no cost; else one
 * read now, within the month's characters for books, and kept for every
 * reader after. A book is begun only when everything of it still to be read
 * fits in the month ([BookSpent] otherwise, having asked nothing). Throws
 * [ShelfMissing] when there is nowhere to keep it, [VoiceRefused] when
 * ElevenLabs will not read, and [BookBusy] when another ask is making the
 * same clip and it does not come within [WAIT_MS].
 */
export async function bookClipFor(summary: Summary, part: number, m: BookMaking): Promise<{ clip: BookClip; made: boolean }> {
  const texts = summary.parts.map((_, i) => spokenPart(summary, i) ?? '');
  const keys = texts.map(bookClipKey);
  const key = keys[part];
  const text = texts[part];
  if (key === undefined || !text) throw new RangeError(`no part ${part} in ${summary.book}`);
  const kept = await m.shelf.find(key);
  if (kept) return { clip: kept, made: false };
  if (!(await m.shelf.ready())) throw new ShelfMissing();
  const found = await m.shelf.findAll(keys);
  const whole = texts.reduce((n, t, i) => n + (found[i] ? 0 : t.length), 0);
  if (!(await m.shelf.claim(key))) {
    // Another reader's ask is reading it: wait for it rather than pay twice.
    const pause = m.pause ?? ((ms: number) => new Promise<void>((done) => setTimeout(done, ms)));
    for (let waited = 0; waited < WAIT_MS; waited += WAIT_STEP_MS) {
      await pause(WAIT_STEP_MS);
      const made = await m.shelf.find(key);
      if (made) return { clip: made, made: false };
    }
    throw new BookBusy();
  }
  let reserved = false;
  let used = 0;
  let made = 0;
  try {
    // A character is charged once: the text's length is the most it can cost.
    reserved = await m.ledger.reserve(m.month, text.length, whole);
    if (!reserved) throw new BookSpent(m.month);
    const read = await m.voice.speak(text);
    used = read.chars;
    const clip = await m.shelf.keep(key, read.audio, {
      book: summary.book,
      part,
      chars: read.chars,
      seconds: secondsOf(read.audio),
    });
    made = 1;
    return { clip, made: true };
  } finally {
    if (reserved) await m.ledger.settle(m.month, text.length, used, made);
    if (!made) await m.shelf.release(key);
  }
}

// ── The call ─────────────────────────────────────────────────────────────

/** What a phone asks: a book, one of its parts, the reader's day and clock. */
export interface BookAsk {
  book: string;
  part: number;
  date: string;
  tz: number;
}

export function readBookAsk(data: unknown): BookAsk | null {
  const d = (data ?? {}) as { book?: unknown; part?: unknown; date?: unknown; tz?: unknown };
  if (typeof d.book !== 'string' || !/^[a-z0-9-]{1,80}$/.test(d.book)) return null;
  if (typeof d.part !== 'number' || !Number.isInteger(d.part) || d.part < 0 || d.part > 20) return null;
  if (typeof d.date !== 'string' || !parseDate(d.date)) return null;
  const tz = typeof d.tz === 'number' && Number.isFinite(d.tz) && Math.abs(d.tz) <= 14 * 60 ? Math.round(d.tz) : 0;
  return { book: d.book, part: d.part, date: d.date, tz };
}

/** Why a part is not available right now: the month's characters cannot
 * hold the book, the ElevenLabs account has no credit for it, ElevenLabs is
 * busy or another ask is still reading it, it would not read this part, or
 * Storage was never set up to keep the clips. */
export type BookUnavailable = 'spent' | 'credit' | 'busy' | 'refused' | 'storage';

/** What the phone is answered: the clip, or why there is none. Only "not
 * configured" hides listening; "unavailable" is said calmly in the player,
 * and the clips already made still play. */
export type BookReply =
  | { url: string; seconds: number; part: number; parts: number }
  | { none: 'not-configured' | 'nothing' }
  | { none: 'unavailable'; why: BookUnavailable };

/** What answering a phone needs, besides making clips. */
export interface BookListening extends BookMaking {
  configured: boolean;
  library: Library;
}

/**
 * Part [ask.part] of [ask.book], asked for by a reader on [plus] or not:
 * "not configured" without a key, or with one ElevenLabs turns away;
 * "nothing" for a book with no summary or a part it does not have; "plus"
 * for a part past the free ones; else the part's clip, made now if it never
 * was, or "unavailable", and why, when it cannot be made now. Never a
 * crash: what ElevenLabs says is read, not thrown at the phone.
 */
export async function hearBook(plus: boolean, bank: Bank, ask: BookAsk, l: BookListening): Promise<BookReply | 'plus'> {
  if (!l.configured) return { none: 'not-configured' };
  const summary = await l.library.summaryOf(bank, ask.book);
  if (!summary || ask.part >= summary.parts.length) return { none: 'nothing' };
  if (!mayHear(plus, ask.book, ask.part, freeBooks(bank, ask.date))) return 'plus';
  try {
    const { clip } = await bookClipFor(summary, ask.part, l);
    return { url: clip.url, seconds: clip.seconds, part: ask.part, parts: summary.parts.length };
  } catch (e) {
    if (e instanceof BookSpent) return { none: 'unavailable', why: 'spent' };
    if (e instanceof BookBusy) return { none: 'unavailable', why: 'busy' };
    if (e instanceof ShelfMissing) return { none: 'unavailable', why: 'storage' };
    if (e instanceof VoiceRefused) {
      return e.why === 'key' ? { none: 'not-configured' } : { none: 'unavailable', why: e.why };
    }
    throw e;
  }
}
