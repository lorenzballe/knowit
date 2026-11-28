// Listen: the day's five read aloud (listenCard and listenAhead in index.ts;
// the phone's side is lib/listen/). A card is heard as two clips, its
// question and then, after the phone's own pause to think, its answer: the
// card's own words from the bank, as the back of the card has them. Each
// clip is made once, by ElevenLabs, for every reader alike, and kept in
// Storage under the hash of what it says and how it was said (clipKey): a
// card whose words change is heard anew, and nothing else is ever made twice.
//
// What a card says aloud (spokenOf). A drawn card's words live in its page,
// and its answer in the bank sometimes speaks of that page ("Drag the slider
// to zero..."), which means nothing heard: those sentences are left out, and
// a drawn card left with less than a sentence is not read at all. A debate is
// read with its other side. No card the dealer would not deal (retired, or
// held in quarantine) is read.
//
// Who hears what. Everybody hears one card a day, the first that can be
// heard: on the free plan the server notes which (readers/{uid}/listen/
// {date}) and refuses any other that day. Astute+ hears all five, the plan
// read from the presence as askCard reads it, and no reader more than
// LISTEN_CARDS_PER_DAY cards a day (limits.ts), which bounds a phone that
// says it holds Astute+ and does not.
//
// What it may cost. ElevenLabs charges by the character: every clip to be
// made holds back its length from the day's and the month's characters
// (limits.ts) before it is asked for, in one transaction, and is counted after
// (listenSpend/{yyyy-mm} and listenSpend/{yyyy-mm-dd}); once either is spent
// nothing new is made until it turns, and what was made still plays.
//
// Without a key (the Actions secret ELEVENLABS_API_KEY not set, so the deploy
// kept a stand-in in its place), every call says "not configured" and the
// phone hides Listen.

import { createHash, randomUUID } from 'node:crypto';

import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { type Bank, type Card, parseDate } from './bank.js';
import { LISTEN_CARDS_PER_DAY, LISTEN_DAY_CHARS, LISTEN_MONTH_CHARS } from './limits.js';

export { LISTEN_CARDS_PER_DAY, LISTEN_DAY_CHARS, LISTEN_MONTH_CHARS };

// ── The voice ────────────────────────────────────────────────────────────

/**
 * Finley, "Articulate Anchor": one of ElevenLabs' own voices (Infinity, ∞ in
 * the Voice Library), a British man, deep, crisp and unflappable, made for
 * explainers. Chosen for a calm, editorial reading. The old default voices
 * (George, Daniel) end on 31 December 2026 and were never open to accounts
 * made after March 2026; Finley is what ElevenLabs names in Daniel's place.
 */
export const VOICE_ID = 'fnYMz3F5gMEDGMWcH1ex';

/** Eleven v4, ElevenLabs' newest model, the one it recommends for long-form narration. */
export const MODEL_ID = 'eleven_v4';

/** The two settings v4 takes, at their defaults: steady, and the voice's own. */
export const VOICE_SETTINGS = { stability: 0.5, similarity_boost: 0.75 } as const;

/** What comes back: MP3 at 44.1 kHz and 128 kbps, which every phone plays. */
export const OUTPUT_FORMAT = 'mp3_44100_128';

/** Where a card is read aloud. */
export const ELEVENLABS_TTS = 'https://api.elevenlabs.io/v1/text-to-speech';

/** What the deploy keeps in the secret's place while there is no key. */
export const NOT_CONFIGURED = 'not-configured';

/** Whether [key] is a key at all, and not the stand-in. */
export function configured(key: string | undefined | null): boolean {
  const k = (key ?? '').trim();
  return k.length >= 20 && k !== NOT_CONFIGURED;
}

/** Everything a clip is made with besides its words: a new voice, model or
 * setting is a new clip. */
const MADE_WITH = [
  MODEL_ID,
  VOICE_ID,
  OUTPUT_FORMAT,
  `stability ${VOICE_SETTINGS.stability}`,
  `similarity ${VOICE_SETTINGS.similarity_boost}`,
  'en',
].join('|');

/** The name a clip is kept under: the hash of how it is said and what. */
export function clipKey(text: string): string {
  return createHash('sha256').update(`${MADE_WITH}\n${text}`).digest('hex');
}

// ── What a card says aloud ───────────────────────────────────────────────

/** The two clips of a card: its question, then its answer. */
export type Part = 'question' | 'answer';

export interface Spoken {
  question: string;
  answer: string;
}

/** The fewest characters a drawn card's answer may be left with and still
 * be read: less than a sentence is nothing to hear. */
export const LEAST_ANSWER = 40;

/** The most one clip reads: far past any card's words, and a stop for a card
 * that is not one. */
export const MOST_CLIP = 2000;

/** Where a sentence ends, as the phone's firstLines splits an answer, but
 * never after an initial or a title (F. Périer, Dr. Who). */
const SENTENCE_END = /(?<=[.!?])(?<!\b(?:[A-Z]|Dr|Mr|Mrs|Ms|St|vs|al|No|Fig|e\.g|i\.e)\.)\s+(?=[A-Z0-9"“‘(])/;

/** A sentence that names where it came from: the card says so elsewhere. */
const SOURCE_LINE = /^(?:sources?\s*:|the sources? (?:is|are)\b)/i;

/** A sentence that speaks of a drawn card's page, and means nothing heard. */
const OF_THE_PAGE: RegExp[] = [
  /\b(?:the|this) (?:page|card|slider|drawing|picture|chart|map|figure|game|timeline|animation|grid)(?:'s)?\b/i,
  /\bthe reader\b|\breaders? (?:taps?|drags?|picks?|chooses?|slides?|sets?)\b|\byour (?:slider|tap|drag)\b|\bon (?:the|this) (?:page|card|screen)\b|\bon screen\b|\bkeep-note\b/i,
  /^(?:Drag|Dragging|Tap|Tapping|Swipe|Slide|Sliding|Flip|Flipping|Press|Pick|Choose|Move|Pound|Click|Hold|Watch|Switching|Zooming)\b/,
];
const GESTURE = /\b(?:drag|dragging|drags|tap|taps|tapping|swipe|swiping|slide|sliding|flip|flipping|press|pressing|toggle|scroll|scrolling|pound|pounding|click|clicking)\b/i;
const THING = /\b(?:page|card|slider|switch|drawing|picture|token|pearl|rail|marker|dots?|timeline|glass|button|bar|dial|grid|map|ring|arrow|handle|screen|chart|figure|track|tiles?|patch(?:es)?)\b/i;

/** What a drawn card says of itself and can be said without it: "The card
 * says that X" is X. */
const SAID_BY_THE_CARD: [RegExp, string][] = [
  [/^(?:the|this) card says,? (?:that )?/i, ''],
  [/^(?:its|the|this card's) keep-note says,? (?:that )?/i, ''],
  [/^the card's (point|lesson|message) is/i, 'The $1 is'],
];

/** Signs a voice reads badly, as words. */
const AS_WORDS: [RegExp, string][] = [
  [/\*\*|__/g, ''],
  [/\s*≈\s*/g, ' about '],
  [/\s*×\s*/g, ' times '],
  [/\s*÷\s*/g, ' divided by '],
  [/\s*±\s*/g, ' plus or minus '],
  [/\s*→\s*/g, ' to '],
  [/\s*\^\s*/g, ' to the power of '],
];

function sentencesOf(text: string): string[] {
  return text.replace(/\s+/g, ' ').trim().split(SENTENCE_END).filter((s) => s.length > 0);
}

function ofThePage(sentence: string): boolean {
  if (OF_THE_PAGE.some((re) => re.test(sentence))) return true;
  return GESTURE.test(sentence) && THING.test(sentence);
}

function unsaidByTheCard(sentence: string): string {
  for (const [re, said] of SAID_BY_THE_CARD) {
    if (!re.test(sentence)) continue;
    const out = sentence.replace(re, said);
    return out.charAt(0).toUpperCase() + out.slice(1);
  }
  return sentence;
}

/** [text] with the signs a voice reads badly put into words. Books read
 * aloud use it too (books.ts). */
export function asWords(text: string): string {
  let out = text;
  for (const [re, word] of AS_WORDS) out = out.replace(re, word);
  return out.replace(/[ \t]+/g, ' ').trim();
}

/** [text] cut to [MOST_CLIP] at the last sentence that fits. */
function within(text: string): string {
  if (text.length <= MOST_CLIP) return text;
  const head = text.slice(0, MOST_CLIP);
  const end = Math.max(head.lastIndexOf('. '), head.lastIndexOf('? '), head.lastIndexOf('! '));
  return end > 0 ? head.slice(0, end + 1) : head;
}

/**
 * What [card] says aloud: its question, and its answer as the back of the
 * card has it, with a debate's other side after it. A drawn card loses the
 * sentences about its page. Null for a card with nothing sensible to read,
 * and for one the dealer would not deal.
 */
export function spokenOf(card: Card): Spoken | null {
  if (card.disabled) return null;
  const question = asWords(card.question ?? '');
  if (question.length < 8) return null;
  const drawn = card.web != null;
  let sentences = sentencesOf(card.answer ?? '');
  if (drawn) sentences = sentences.map(unsaidByTheCard).filter((s) => !ofThePage(s));
  sentences = sentences.filter((s) => !SOURCE_LINE.test(s));
  let answer = asWords(sentences.join(' '));
  if (answer.length < (drawn ? LEAST_ANSWER : 1)) return null;
  const other = card.kind === 'debate' && typeof card.counterpoint === 'string' ? asWords(card.counterpoint) : '';
  if (other) answer = `${answer}\n\nThe other side. ${other}`;
  return { question: within(question), answer: within(answer) };
}

// ── ElevenLabs ───────────────────────────────────────────────────────────

/** What reads a text aloud. */
export interface Voice {
  /** [text] read: the audio, and the characters it was charged. */
  speak(text: string): Promise<{ audio: Buffer; chars: number }>;
}

/**
 * Why the voice did not read:
 *
 * - `key`: the key is not one ElevenLabs takes (wrong, revoked, or made
 *   without Text to Speech): Listen is not configured;
 * - `credit`: the key is fine but the account cannot pay for it: no credits
 *   bought, its characters spent, or a plan that does not reach the voice
 *   (Voice Library voices are closed to the API on the free plan): not
 *   available, until the owner buys a plan;
 * - `busy`: too many requests at once, or ElevenLabs down: not available now;
 * - `refused`: anything else it would not read.
 */
export type Refusal = 'key' | 'credit' | 'busy' | 'refused';

export class VoiceRefused extends Error {
  constructor(
    readonly why: Refusal,
    readonly status: number,
    message: string,
  ) {
    super(message);
    this.name = 'VoiceRefused';
  }
}

/** The request for [text]: the model (Listen's, unless a caller names
 * another, as the books do), English, the settings. */
export function speechBody(text: string, model: string = MODEL_ID): Record<string, unknown> {
  return { text, model_id: model, language_code: 'en', voice_settings: { ...VOICE_SETTINGS } };
}

/** What ElevenLabs says when the account cannot pay: its codes (402
 * `insufficient_credits`, 403 `subscription_required` and the like), the
 * older `quota_exceeded`, and the words of its messages ("upgrade your
 * subscription", "free users cannot use library voices"). */
const NO_CREDIT = /insufficient_credits|payment_required|quota_exceeded|subscription_required|feature_not_available|voice_access_denied|model_access_denied|credit|quota|upgrade|paid plan|subscription|free (?:users|tier|plan)/i;

/** What a refusal means, from its status and ElevenLabs' own words for it:
 * `detail.code` and `detail.type` in its errors, `detail.status` in older
 * ones, and the message. */
export function refusalOf(status: number, body: string): Refusal {
  let words = '';
  try {
    const detail = (JSON.parse(body) as { detail?: unknown })?.detail;
    words = typeof detail === 'object' && detail !== null && !Array.isArray(detail)
      ? ['code', 'type', 'status', 'message'].map((k) => String((detail as Record<string, unknown>)[k] ?? '')).join(' ')
      : String(detail ?? '');
  } catch {
    // Not JSON: the status says it.
  }
  if (status === 402 || ((status === 401 || status === 403) && NO_CREDIT.test(words))) return 'credit';
  if (status === 429 || status >= 500) return 'busy';
  if (status === 401 || status === 403) return 'key';
  return 'refused';
}

/** ElevenLabs, with [key], reading with [model] (Listen's, unless the
 * books name theirs). A busy answer is tried once more after a breath. */
export function elevenLabs(
  key: string,
  fetcher: typeof fetch = fetch,
  pause: (ms: number) => Promise<void> = (ms) => new Promise((done) => setTimeout(done, ms)),
  model: string = MODEL_ID,
): Voice {
  return {
    async speak(text) {
      for (let attempt = 0; ; attempt++) {
        const res = await fetcher(`${ELEVENLABS_TTS}/${VOICE_ID}?output_format=${OUTPUT_FORMAT}`, {
          method: 'POST',
          headers: { 'xi-api-key': key, 'content-type': 'application/json', accept: 'audio/mpeg' },
          body: JSON.stringify(speechBody(text, model)),
        });
        if (res.ok) {
          const audio = Buffer.from(await res.arrayBuffer());
          const counted = Number(res.headers.get('x-character-count'));
          return { audio, chars: Number.isFinite(counted) && counted > 0 ? counted : text.length };
        }
        const said = await res.text().catch(() => '');
        const why = refusalOf(res.status, said);
        if (why === 'busy' && attempt === 0) {
          await pause(1500);
          continue;
        }
        throw new VoiceRefused(why, res.status, said.slice(0, 300));
      }
    },
  };
}

/** What the deploy tells the owner of a key (checkKey). */
export interface KeyCheck {
  /** Whether to keep the key in Secret Manager: every key but one that
   * ElevenLabs says is not a key, so that a key added before its plan was
   * bought works the moment the plan is, with no deploy. */
  keep: boolean;
  /** `works`; or why not, as the voice says it (Refusal); or `unreachable`. */
  verdict: 'works' | Refusal | 'unreachable';
  status: number;
  /** ElevenLabs' own words, for the deploy's summary. */
  said: string;
}

/**
 * The deploy's check of [key] (.github/workflows/cloud-deploy.yml): three
 * characters read in Listen's own voice and model, so the answer is about
 * exactly what Listen will ask for: the key, its permissions, the plan's
 * credit, and the voice.
 */
export async function checkKey(key: string, fetcher: typeof fetch = fetch): Promise<KeyCheck> {
  try {
    await elevenLabs(key, fetcher, async () => {}).speak('Ok.');
    return { keep: true, verdict: 'works', status: 200, said: '' };
  } catch (e) {
    if (!(e instanceof VoiceRefused)) return { keep: true, verdict: 'unreachable', status: 0, said: String(e).slice(0, 300) };
    let said = e.message;
    try {
      const detail = (JSON.parse(e.message) as { detail?: { message?: unknown } | string })?.detail;
      said = typeof detail === 'string' ? detail : String(detail?.message ?? e.message);
    } catch {
      // Not JSON: as it came.
    }
    return { keep: e.why !== 'key', verdict: e.why, status: e.status, said };
  }
}

// ── Where the clips are kept ─────────────────────────────────────────────

/** A clip as the phone gets it: where it is, and what it cost to make. */
export interface Clip {
  url: string;
  chars: number;
}

/** What a clip is kept with, for a person reading the index. */
export interface ClipMeta {
  card: string;
  part: Part;
  chars: number;
}

/** The clips made so far, by their key. */
export interface Shelf {
  find(key: string): Promise<Clip | null>;
  keep(key: string, audio: Buffer, meta: ClipMeta): Promise<Clip>;
  /** Whether a new clip can be kept at all: asked before one is read, so no
   * character is paid for a clip with nowhere to go. */
  ready(): Promise<boolean>;
}

/** Nothing was read: there is nowhere to keep a clip (Storage was never set
 * up on the project, in the Firebase console). */
export class ShelfMissing extends Error {
  constructor() {
    super('Storage has no bucket for the clips');
    this.name = 'ShelfMissing';
  }
}

/** What of a Storage bucket the shelf uses (firebase-admin's getStorage().bucket()). */
export interface BucketLike {
  name: string;
  exists(): Promise<[boolean]>;
  file(path: string): { save(data: Buffer, options: Record<string, unknown>): Promise<unknown> };
}

/** Where a clip lives in Storage: listen/{key}.mp3, which storage.rules lets
 * signed-in readers read and nobody but the functions write. */
export function clipPath(key: string): string {
  return `listen/${key}.mp3`;
}

/** The address a phone plays a clip from: Firebase Storage's own, with the
 * clip's token, so nothing on the phone needs the Storage SDK. */
export function clipUrl(bucket: string, path: string, token: string): string {
  return `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

/** The clips in Storage, with their index in Firestore (listen/{key}: the
 * address, the card and part, what it cost), so a clip already made is one
 * read away. */
export function storageShelf(db: Firestore, bucket: BucketLike, token: () => string = randomUUID, now: () => number = Date.now): Shelf {
  const index = db.collection('listen');
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
      const snap = await index.doc(key).get();
      const url = snap.get('url');
      return typeof url === 'string' && url ? { url, chars: Number(snap.get('chars')) || 0 } : null;
    },
    async keep(key, audio, meta) {
      const path = clipPath(key);
      const t = token();
      await bucket.file(path).save(audio, {
        resumable: false,
        metadata: {
          contentType: 'audio/mpeg',
          cacheControl: 'public, max-age=31536000',
          metadata: { firebaseStorageDownloadTokens: t, card: meta.card, part: meta.part },
        },
      });
      const url = clipUrl(bucket.name, path, t);
      await index.doc(key).set({
        url,
        path,
        card: meta.card,
        part: meta.part,
        chars: meta.chars,
        voice: VOICE_ID,
        model: MODEL_ID,
        at: FieldValue.serverTimestamp(),
      });
      return { url, chars: meta.chars };
    },
  };
}

/** The clips in memory, for the tests. */
export function memoryShelf(bucket = 'test-bucket', ready = true): Shelf & { kept: Map<string, { audio: Buffer; meta: ClipMeta; url: string }> } {
  const kept = new Map<string, { audio: Buffer; meta: ClipMeta; url: string }>();
  return {
    kept,
    async ready() {
      return ready;
    },
    async find(key) {
      const k = kept.get(key);
      return k ? { url: k.url, chars: k.meta.chars } : null;
    },
    async keep(key, audio, meta) {
      const url = clipUrl(bucket, clipPath(key), `token-${kept.size + 1}`);
      kept.set(key, { audio, meta, url });
      return { url, chars: meta.chars };
    },
  };
}

// ── What it may cost ─────────────────────────────────────────────────────

/** The characters a ledger keeps to. */
export interface CharLimits {
  day: number;
  month: number;
}

export const CHAR_LIMITS: CharLimits = { day: LISTEN_DAY_CHARS, month: LISTEN_MONTH_CHARS };

/** Where the characters read are counted, as budget.ts counts dollars. */
export interface CharLedger {
  /** Holds back [chars] of [day]'s characters and its month's for a clip
   * about to be made. False, and nothing held, when that would pass either. */
  reserve(day: string, chars: number): Promise<boolean>;
  /** Clips are made or failed: the [held] characters are let go, and the
   * [used] ones and the [clips] made counted, in the day and in its month. */
  settle(day: string, held: number, used: number, clips: number): Promise<void>;
}

/** Nothing was read: the day's characters or the month's are spent. */
export class ListenSpent extends Error {
  constructor(readonly day: string) {
    super(`the characters of ${day} or its month are spent`);
    this.name = 'ListenSpent';
  }
}

/** A day's or a month's characters as they are kept. */
export interface CharSpend {
  chars: number;
  held: number;
  clips: number;
  refused: number;
}

/** The characters in Firestore, listenSpend/{yyyy-mm-dd} and
 * listenSpend/{yyyy-mm}, written by the server alone. */
export function firestoreCharLedger(db: Firestore, limits: CharLimits = CHAR_LIMITS): CharLedger {
  const docs = (day: string) => [db.collection('listenSpend').doc(day), db.collection('listenSpend').doc(day.slice(0, 7))];
  return {
    reserve: (day, chars) =>
      db.runTransaction(async (t) => {
        const [dayRef, monthRef] = docs(day);
        const [d, m] = await Promise.all([t.get(dayRef), t.get(monthRef)]);
        const used = (s: typeof d) => (s.get('chars') ?? 0) + Math.max(0, s.get('held') ?? 0);
        if (used(d) + chars > limits.day || used(m) + chars > limits.month) {
          t.set(dayRef, { refused: FieldValue.increment(1) }, { merge: true });
          t.set(monthRef, { refused: FieldValue.increment(1) }, { merge: true });
          return false;
        }
        t.set(dayRef, { held: FieldValue.increment(chars) }, { merge: true });
        t.set(monthRef, { held: FieldValue.increment(chars) }, { merge: true });
        return true;
      }),
    settle: async (day, held, used, clips) => {
      const batch = db.batch();
      for (const ref of docs(day)) {
        batch.set(
          ref,
          { held: FieldValue.increment(-held), chars: FieldValue.increment(used), clips: FieldValue.increment(clips) },
          { merge: true },
        );
      }
      await batch.commit();
    },
  };
}

/** The characters in memory, for the tests: days under yyyy-mm-dd, months
 * under yyyy-mm. */
export function memoryCharLedger(limits: Partial<CharLimits> = {}): CharLedger & { spend: Map<string, CharSpend> } {
  const { day: dayLimit, month: monthLimit } = { ...CHAR_LIMITS, ...limits };
  const spend = new Map<string, CharSpend>();
  const of = (key: string): CharSpend => {
    let s = spend.get(key);
    if (!s) {
      s = { chars: 0, held: 0, clips: 0, refused: 0 };
      spend.set(key, s);
    }
    return s;
  };
  const used = (s: CharSpend) => s.chars + Math.max(0, s.held);
  return {
    spend,
    async reserve(day, chars) {
      const d = of(day);
      const m = of(day.slice(0, 7));
      if (used(d) + chars > dayLimit || used(m) + chars > monthLimit) {
        d.refused++;
        m.refused++;
        return false;
      }
      d.held += chars;
      m.held += chars;
      return true;
    },
    async settle(day, held, chars, clips) {
      for (const s of [of(day), of(day.slice(0, 7))]) {
        s.held -= held;
        s.chars += chars;
        s.clips += clips;
      }
    },
  };
}

// ── A clip, made once ────────────────────────────────────────────────────

/** What making a clip needs: where clips are kept, the characters, the
 * voice, and the UTC day it is counted under. */
export interface Making {
  shelf: Shelf;
  ledger: CharLedger;
  voice: Voice;
  day: string;
}

/** A card's two clips, and what making them took: how many were new, and
 * the characters they were charged. */
export interface Clips {
  question: Clip;
  answer: Clip;
  made: number;
  chars: number;
}

const PARTS: readonly Part[] = ['question', 'answer'];

/**
 * The two clips of a card that says [spoken]: the ones kept, at no cost, and
 * those never made read now, within the day's and the month's characters,
 * and kept for every reader after. Both or neither: what the missing ones
 * may cost is held back at once, so a question is never made without room
 * for its answer. Throws [ListenSpent], having asked nothing, when there is
 * no room, [ShelfMissing] when there is nowhere to keep them, and
 * [VoiceRefused] when ElevenLabs will not read.
 */
export async function clipsFor(card: string, spoken: Spoken, m: Making): Promise<Clips> {
  const keys = PARTS.map((p) => clipKey(spoken[p]));
  const kept = await Promise.all(keys.map((k) => m.shelf.find(k)));
  const missing = PARTS.filter((_, i) => kept[i] === null);
  const out: Partial<Record<Part, Clip>> = {};
  PARTS.forEach((p, i) => {
    if (kept[i]) out[p] = kept[i]!;
  });
  if (missing.length === 0) return { question: out.question!, answer: out.answer!, made: 0, chars: 0 };
  if (!(await m.shelf.ready())) throw new ShelfMissing();
  // A character is charged once: the texts' length is the most they can cost.
  const worst = missing.reduce((n, p) => n + spoken[p].length, 0);
  if (!(await m.ledger.reserve(m.day, worst))) throw new ListenSpent(m.day);
  let used = 0;
  let made = 0;
  try {
    await Promise.all(
      missing.map(async (part) => {
        const read = await m.voice.speak(spoken[part]);
        used += read.chars;
        out[part] = await m.shelf.keep(keys[PARTS.indexOf(part)], read.audio, { card, part, chars: read.chars });
        made++;
      }),
    );
  } finally {
    await m.ledger.settle(m.day, worst, used, made);
  }
  return { question: out.question!, answer: out.answer!, made, chars: used };
}

// ── Who hears what ───────────────────────────────────────────────────────

/** What a reader may hear: the card, past the free one on the free plan
 * ("plus"), or past the day's cards on any ("enough"). */
export type Claim = 'ok' | 'plus' | 'enough';

/** A reader's day of listening as it is kept: the free card, and every card
 * asked for. */
export interface ListenDay {
  free?: unknown;
  cards?: unknown;
}

/** Whether [card] may be heard, given the reader's day so far: the free
 * plan's one card, the first asked for, then nothing else; on either plan no
 * more than [perDay] cards. And the day as it is kept after. */
export function claimOf(had: ListenDay | undefined, card: string, plus: boolean, perDay = LISTEN_CARDS_PER_DAY): { claim: Claim; free: string | null; cards: string[] } {
  const cards = Array.isArray(had?.cards) ? had.cards.filter((c): c is string => typeof c === 'string') : [];
  const free = typeof had?.free === 'string' ? had.free : null;
  if (!plus && free !== null && free !== card) return { claim: 'plus', free, cards };
  if (!cards.includes(card) && cards.length >= perDay) return { claim: 'enough', free, cards };
  return {
    claim: 'ok',
    free: free ?? (plus ? null : card),
    cards: cards.includes(card) ? cards : [...cards, card],
  };
}

/** Where a reader's days of listening are kept. */
export interface Claims {
  claim(uid: string, date: string, card: string, plus: boolean): Promise<Claim>;
}

/** The days in Firestore: readers/{uid}/listen/{date}, which no phone may
 * read or write, and listeners/{uid}, when the reader last listened and on
 * which plan, which is how listenAhead knows whose next days to make. Both
 * go with the account. */
export function firestoreClaims(db: Firestore, perDay = LISTEN_CARDS_PER_DAY, now: () => number = Date.now): Claims {
  return {
    claim: (uid, date, card, plus) =>
      db.runTransaction(async (t) => {
        const ref = db.collection('readers').doc(uid).collection('listen').doc(date);
        const had = await t.get(ref);
        const out = claimOf(had.data() as ListenDay | undefined, card, plus, perDay);
        if (out.claim !== 'ok') return out.claim;
        t.set(ref, { free: out.free, cards: out.cards, at: now() });
        t.set(db.collection('listeners').doc(uid), { at: now(), plus }, { merge: true });
        return 'ok';
      }),
  };
}

/** The days in memory, for the tests. */
export function memoryClaims(perDay = LISTEN_CARDS_PER_DAY): Claims & { days: Map<string, ListenDay> } {
  const days = new Map<string, ListenDay>();
  return {
    days,
    async claim(uid, date, card, plus) {
      const key = `${uid}/${date}`;
      const out = claimOf(days.get(key), card, plus, perDay);
      if (out.claim === 'ok') days.set(key, { free: out.free, cards: out.cards });
      return out.claim;
    },
  };
}

// ── The call ─────────────────────────────────────────────────────────────

/** What a phone asks: a card of its day, the day, and its clock's offset. */
export interface ListenAsk {
  card: string;
  date: string;
  tz: number;
}

export function readListen(data: unknown): ListenAsk | null {
  const d = (data ?? {}) as { card?: unknown; date?: unknown; tz?: unknown };
  if (typeof d.card !== 'string' || !/^[a-z0-9_-]{1,64}$/.test(d.card)) return null;
  if (typeof d.date !== 'string' || !parseDate(d.date)) return null;
  const tz = typeof d.tz === 'number' && Number.isFinite(d.tz) && Math.abs(d.tz) <= 14 * 60 ? Math.round(d.tz) : 0;
  return { card: d.card, date: d.date, tz };
}

/** Why a card is not available right now: the characters of the day or the
 * month are spent (limits.ts), the ElevenLabs account has no credit for it,
 * ElevenLabs is busy, it would not read this card, or Storage was never set
 * up to keep the clips. */
export type Unavailable = 'spent' | 'credit' | 'busy' | 'refused' | 'storage';

/** What the phone is answered: the two clips' addresses, or why there are
 * none. Only "not configured" hides Listen; "unavailable" is said calmly on
 * the card, and the clips already made still play. */
export type ListenReply =
  | { question: string; answer: string }
  | { none: 'not-configured' | 'nothing' }
  | { none: 'unavailable'; why: Unavailable };

/** What answering a phone needs, besides making clips. */
export interface Listening extends Making {
  configured: boolean;
  claims: Claims;
}

/**
 * [card], asked for by [uid] on [ask]'s day: "not configured" without a key,
 * or with one ElevenLabs turns away; "nothing" for a card with nothing to
 * hear (which is not the reader's one free card); "plus" or "enough" when the
 * reader may not hear it; else its two clips, made now if they never were,
 * or "unavailable", and why, when they cannot be made now: the characters
 * spent, or an ElevenLabs account with no credit (a key the owner has added
 * before buying a plan), busy, or refusing. Never a crash: what ElevenLabs
 * says is read, not thrown at the phone.
 */
export async function listenTo(uid: string, plus: boolean, card: Card | undefined, ask: ListenAsk, l: Listening): Promise<ListenReply | 'plus' | 'enough'> {
  if (!l.configured) return { none: 'not-configured' };
  const spoken = card ? spokenOf(card) : null;
  if (!card || !spoken) return { none: 'nothing' };
  const claim = await l.claims.claim(uid, ask.date, card.id, plus);
  if (claim !== 'ok') return claim;
  try {
    const clips = await clipsFor(card.id, spoken, l);
    return { question: clips.question.url, answer: clips.answer.url };
  } catch (e) {
    if (e instanceof ListenSpent) return { none: 'unavailable', why: 'spent' };
    if (e instanceof ShelfMissing) return { none: 'unavailable', why: 'storage' };
    if (e instanceof VoiceRefused) {
      return e.why === 'key' ? { none: 'not-configured' } : { none: 'unavailable', why: e.why };
    }
    throw e;
  }
}

// ── Ahead of the reader ──────────────────────────────────────────────────

/** Listeners are made for ahead while they listened within this many days. */
export const AHEAD_DAYS = 7;

/** The most characters one run ahead may read: a quarter of the day's, so
 * what is asked for on the spot always has room. */
export const AHEAD_CHARS = Math.floor(LISTEN_DAY_CHARS / 4);

/** A listener, as listenAhead finds them: their plan, and the cards of the
 * days dealt them that are still to come (today, tomorrow), in order. */
export interface Ahead {
  plus: boolean;
  days: string[][];
}

/**
 * The cards to make ahead, each once, the soonest first: every card of an
 * Astute+ listener's days, and of a free listener's the one they hear, the
 * first that can be heard. Never a card with nothing to hear.
 */
export function aheadCards(readers: Ahead[], bank: Bank): Card[] {
  const out: Card[] = [];
  const seen = new Set<string>();
  const longest = Math.max(0, ...readers.map((r) => r.days.length));
  for (let d = 0; d < longest; d++) {
    for (const r of readers) {
      const ids = r.days[d] ?? [];
      let heard = 0;
      for (const id of ids) {
        const card = bank.byId.get(id);
        if (!card || !spokenOf(card)) continue;
        heard++;
        if (!seen.has(id)) {
          seen.add(id);
          out.push(card);
        }
        if (!r.plus && heard === 1) break;
      }
    }
  }
  return out;
}

/** What a run ahead did. */
export interface AheadRun {
  made: number;
  kept: number;
  chars: number;
  spent: boolean;
  failed: number;
}

/**
 * Makes the clips of [cards] that were never made, a card at a time (the
 * voice takes only a few requests at once, and the phones come first), until
 * [most] characters are read or the budget says no.
 */
export async function makeAhead(cards: Card[], m: Making, most = AHEAD_CHARS): Promise<AheadRun> {
  const run: AheadRun = { made: 0, kept: 0, chars: 0, spent: false, failed: 0 };
  for (const card of cards) {
    if (run.chars >= most) break;
    const spoken = spokenOf(card);
    if (!spoken) continue;
    try {
      const clips = await clipsFor(card.id, spoken, m);
      run.made += clips.made;
      run.kept += 2 - clips.made;
      run.chars += clips.chars;
    } catch (e) {
      if (e instanceof ListenSpent) {
        run.spent = true;
        break;
      }
      run.failed++;
      // A key turned away, an account with no credit, or nowhere to keep a
      // clip turns every card away: stop. Anything else is this card's own.
      if (e instanceof ShelfMissing || (e instanceof VoiceRefused && (e.why === 'key' || e.why === 'credit'))) break;
    }
  }
  return run;
}
