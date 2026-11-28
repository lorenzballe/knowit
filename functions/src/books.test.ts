import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { mkdtempSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';

import { Bank, type Card } from './bank.js';
import {
  BOOK_AUDIO_MONTH_CHARS,
  BOOK_MODEL_ID,
  MOST_PART,
  type BookAsk,
  type BookListening,
  type Summary,
  bookClipFor,
  bookClipKey,
  bookOfTheWeek,
  freeBooks,
  hearBook,
  matches,
  mayHear,
  memoryBookLedger,
  memoryBookShelf,
  memoryLibrary,
  parseSummary,
  readBookAsk,
  secondsOf,
  siteLibrary,
  spokenPart,
} from './books.js';
import { MODEL_ID, VoiceRefused, clipKey, elevenLabs, type Voice } from './listen.js';

const DAY = '2026-11-27';
const MONTH = '2026-11';

/** A book of the bank: five cards naming it. */
function bookCards(id: string, over: Partial<Card> = {}): Card[] {
  return [1, 2, 3, 4, 5].map((part) => ({
    id: `${id}-${part}`,
    topic: 'thinking',
    kind: 'read' as const,
    difficulty: 'easy' as const,
    principle: 'none',
    question: `Idea ${part} of ${id}?`,
    answer: 'Because.',
    book: { id, title: id, author: 'Someone', year: 2000, part },
    ...over,
  }));
}

/** A summary of [book] in [n] parts, each a few sentences. */
function summary(book: string, n = 6, word = 'idea'): Summary {
  return {
    book,
    title: `The ${book}`,
    author: 'An Author',
    parts: Array.from({ length: n }, (_, i) => ({
      title: `Part ${i + 1} of the ${word}`,
      text: [`The first paragraph of part ${i + 1} explains one ${word}.`, `The second paragraph gives its example, ${i + 1} times over.`],
    })),
  };
}

/** A bank with these books, each summarised. */
function bankOf(books: string[], summarised = books): Bank {
  return new Bank({
    version: 1,
    cards: books.flatMap((b) => bookCards(b)),
    summaries: Object.fromEntries(summarised.map((b) => [b, { file: `summaries/${b}.json?v=abc`, parts: 6 }])),
  });
}

/** A voice that reads anything, counting what it was asked. */
function fakeVoice(): Voice & { asked: string[] } {
  const asked: string[] = [];
  return {
    asked,
    async speak(text) {
      asked.push(text);
      // Sixteen kilobytes a second at 128 kbps: so many seconds of sound.
      return { audio: Buffer.alloc(16_000 * 3), chars: text.length };
    },
  };
}

/** A voice that always refuses, as ElevenLabs does for [why]. */
function refusingVoice(why: 'key' | 'credit' | 'busy'): Voice & { asked: number } {
  const v = {
    asked: 0,
    async speak(): Promise<{ audio: Buffer; chars: number }> {
      v.asked++;
      throw new VoiceRefused(why, why === 'credit' ? 402 : why === 'key' ? 401 : 429, '{}');
    },
  };
  return v;
}

type Hearing = BookListening & {
  voice: ReturnType<typeof fakeVoice>;
  shelf: ReturnType<typeof memoryBookShelf>;
  ledger: ReturnType<typeof memoryBookLedger>;
};

function hearing(summaries: Summary[], over: Partial<BookListening> = {}): Hearing {
  return {
    configured: true,
    library: memoryLibrary(summaries),
    shelf: memoryBookShelf(),
    ledger: memoryBookLedger(),
    voice: fakeVoice(),
    month: MONTH,
    pause: async () => {},
    ...over,
  } as Hearing;
}

const ask = (book: string, part: number, date = DAY): BookAsk => ({ book, part, date, tz: 60 });

/** Whether a reply is a clip to play. */
const heard = (r: Awaited<ReturnType<typeof hearBook>>): r is { url: string; seconds: number; part: number; parts: number } =>
  typeof r === 'object' && 'url' in r;

test('a part is named by the hash of how it is read and what: the same words the same name, other words another, and never a name of Listen\'s', () => {
  const text = 'The Structure of Scientific Revolutions, by Thomas S. Kuhn.\n\nScience that moves in jumps.';
  assert.equal(bookClipKey(text), bookClipKey(text));
  assert.notEqual(bookClipKey(text), bookClipKey(`${text} Again.`));
  // Read on another model, the same words are another clip.
  assert.notEqual(bookClipKey(text), clipKey(text));
  assert.notEqual(BOOK_MODEL_ID, MODEL_ID);
  assert.match(bookClipKey(text), /^[0-9a-f]{64}$/);
});

test('what a part says aloud: the book and its author before the first, then the title and the paragraphs, signs in words', () => {
  const s = summary('a-book');
  s.parts[1].text = ['Twice 3 × 4 is 24.'];
  const first = spokenPart(s, 0)!;
  assert.ok(first.startsWith('The a-book, by An Author.\n\nPart 1 of the idea.\n\nThe first paragraph'));
  assert.equal(spokenPart(s, 1), 'Part 2 of the idea.\n\nTwice 3 times 4 is 24.');
  assert.equal(spokenPart(s, 6), null);
  // A part longer than any the gate allows is cut at a sentence.
  s.parts[2].text = [Array.from({ length: 800 }, () => 'A sentence of words.').join(' ')];
  const long = spokenPart(s, 2)!;
  assert.ok(long.length <= MOST_PART && long.endsWith('.'));
});

test('a part never read is read, kept and counted; asked again it is the one kept, and nothing is read or counted', async () => {
  const s = summary('a-book');
  const l = hearing([s]);
  const bank = bankOf(['a-book']);
  const first = await hearBook(true, bank, ask('a-book', 2), l);
  assert.ok(heard(first) && first.part === 2 && first.parts === 6 && first.seconds === 3);
  assert.equal(l.voice.asked.length, 1);
  assert.equal(l.ledger.spend.get(MONTH)!.chars, spokenPart(s, 2)!.length);
  assert.equal(l.ledger.spend.get(MONTH)!.held, 0);
  const again = await hearBook(true, bank, ask('a-book', 2), l);
  assert.deepEqual(again, first);
  assert.equal(l.voice.asked.length, 1);
  assert.equal(l.ledger.spend.get(MONTH)!.clips, 1);
});

test('a summary whose words change is read anew, and only the parts that changed', async () => {
  const before = summary('a-book');
  const l = hearing([before]);
  for (let p = 0; p < 6; p++) await bookClipFor(before, p, l);
  assert.equal(l.voice.asked.length, 6);
  const after = structuredClone(before);
  after.parts[4].text[1] = 'The second paragraph, rewritten.';
  for (let p = 0; p < 6; p++) {
    const { made } = await bookClipFor(after, p, l);
    assert.equal(made, p === 4, `part ${p + 1}`);
  }
  assert.equal(l.voice.asked.length, 7);
});

test('a book is begun only when everything of it still to be read fits in the month; past it nothing is read, and what was read still plays', async () => {
  const s = summary('a-book');
  const whole = s.parts.reduce((n, _, i) => n + spokenPart(s, i)!.length, 0);
  // A month with room for one part but not the book: the book is skipped.
  const tight = hearing([s], { ledger: memoryBookLedger(whole - 1) });
  const bank = bankOf(['a-book']);
  assert.deepEqual(await hearBook(false, bank, ask('a-book', 0), tight), { none: 'unavailable', why: 'spent' });
  assert.equal(tight.voice.asked.length, 0);
  assert.equal(tight.ledger.spend.get(MONTH)!.refused, 1);
  assert.equal(tight.ledger.spend.get(MONTH)!.held, 0);
  assert.equal(tight.shelf.making.size, 0);
  // Room for exactly the book: every part is read, and then the month is spent.
  const exact = hearing([s], { ledger: memoryBookLedger(whole) });
  for (let p = 0; p < 6; p++) assert.ok(heard(await hearBook(true, bank, ask('a-book', p), exact)));
  assert.equal(exact.ledger.spend.get(MONTH)!.chars, whole);
  const other = summary('b-book', 6, 'other');
  const both = bankOf(['a-book', 'b-book']);
  const spent = { ...exact, library: memoryLibrary([s, other]) };
  assert.deepEqual(await hearBook(true, both, ask('b-book', 0), spent), { none: 'unavailable', why: 'spent' });
  // What was read before still plays, at no cost.
  assert.ok(heard(await hearBook(true, both, ask('a-book', 3), spent)));
  assert.equal(exact.voice.asked.length, 6);
});

test('the month counts what is left of a book: a book half read is finished while the rest fits', async () => {
  const s = summary('a-book');
  const lengths = s.parts.map((_, i) => spokenPart(s, i)!.length);
  const l = hearing([s]);
  for (let p = 0; p < 3; p++) await bookClipFor(s, p, l);
  const read = lengths.slice(0, 3).reduce((a, b) => a + b, 0);
  const rest = lengths.slice(3).reduce((a, b) => a + b, 0);
  const later = { ...l, ledger: memoryBookLedger(rest) };
  assert.equal((await bookClipFor(s, 3, later)).made, true);
  assert.ok(read > 0 && later.ledger.spend.get(MONTH)!.chars === lengths[3]);
  assert.equal(BOOK_AUDIO_MONTH_CHARS, 120_000);
});

test('the week\'s free book is the one every phone works out, and the day the week turns both books are free', () => {
  // The bank as the deploy carries it, as the phones hold it.
  const shipped = Bank.bundled();
  assert.equal(bookOfTheWeek(shipped, '2026-11-27'), 'the-structure-of-scientific-revolutions');
  assert.equal(bookOfTheWeek(shipped, '2026-12-03'), 'thinking-fast-and-slow');
  assert.deepEqual(
    [...freeBooks(shipped, '2026-12-03')].sort(),
    ['the-structure-of-scientific-revolutions', 'thinking-fast-and-slow'],
  );
  assert.deepEqual([...freeBooks(shipped, '2026-11-27')], ['the-structure-of-scientific-revolutions']);
  // The books in the order of their ids, turned one place a week.
  const bank = bankOf(['b', 'a', 'c']);
  assert.equal(bookOfTheWeek(bank, '2026-01-01'), 'a');
  assert.equal(bookOfTheWeek(bank, '2026-01-08'), 'b');
  assert.equal(bookOfTheWeek(bank, '2026-01-22'), 'a');
  // A book with fewer than four ideas still dealt is not a book yet.
  const thin = new Bank({ version: 1, cards: [...bookCards('a'), ...bookCards('b').map((c, i) => (i < 2 ? { ...c, disabled: true } : c))] });
  assert.equal(bookOfTheWeek(thin, '2026-01-08'), 'a');
});

test('who hears what: the first part of any book and the week\'s book whole for everybody, the rest with Astute+', async () => {
  const week = bookOfTheWeek(bankOf(['a-book', 'b-book']), DAY)!;
  const other = week === 'a-book' ? 'b-book' : 'a-book';
  const l = hearing([summary('a-book'), summary('b-book')]);
  const bank = bankOf(['a-book', 'b-book']);
  assert.ok(heard(await hearBook(false, bank, ask(other, 0), l)));
  assert.equal(await hearBook(false, bank, ask(other, 1), l), 'plus');
  for (let p = 0; p < 6; p++) assert.ok(heard(await hearBook(false, bank, ask(week, p), l)), `week part ${p + 1}`);
  assert.ok(heard(await hearBook(true, bank, ask(other, 5), l)));
  assert.equal(mayHear(false, 'x', 0, new Set()), true);
  assert.equal(mayHear(false, 'x', 1, new Set(['x'])), true);
  assert.equal(mayHear(false, 'x', 1, new Set(['y'])), false);
  assert.equal(mayHear(true, 'x', 7, new Set()), true);
  // No summary, or no such part: nothing to hear.
  assert.deepEqual(await hearBook(true, bankOf(['a-book'], []), ask('a-book', 0), l), { none: 'nothing' });
  assert.deepEqual(await hearBook(true, bank, ask('a-book', 6), l), { none: 'nothing' });
});

test('without a key the call says it is not configured, and reads, keeps and spends nothing', async () => {
  const l = hearing([summary('a-book')], { configured: false });
  assert.deepEqual(await hearBook(true, bankOf(['a-book']), ask('a-book', 0), l), { none: 'not-configured' });
  assert.equal(l.voice.asked.length, 0);
  assert.equal(l.shelf.kept.size, 0);
  assert.equal(l.ledger.spend.size, 0);
});

test('a key ElevenLabs turns away is not configured; an account with no credit, or a busy voice, is calmly unavailable, and nothing is counted or left claimed', async () => {
  const bank = bankOf(['a-book']);
  for (const [why, reply] of [
    ['key', { none: 'not-configured' }],
    ['credit', { none: 'unavailable', why: 'credit' }],
    ['busy', { none: 'unavailable', why: 'busy' }],
  ] as const) {
    const voice = refusingVoice(why);
    const l = hearing([summary('a-book')], { voice });
    assert.deepEqual(await hearBook(true, bank, ask('a-book', 1), l), reply, why);
    assert.equal(voice.asked, 1);
    assert.equal(l.shelf.kept.size, 0);
    assert.equal(l.shelf.making.size, 0);
    const spend = l.ledger.spend.get(MONTH)!;
    assert.equal(spend.chars, 0);
    assert.equal(spend.held, 0);
    assert.equal(spend.clips, 0);
  }
});

test('with nowhere to keep a clip (Storage never set up), nothing is read or paid for, and the part is not available', async () => {
  const l = hearing([summary('a-book')], { shelf: memoryBookShelf('test-bucket', false) });
  assert.deepEqual(await hearBook(true, bankOf(['a-book']), ask('a-book', 0), l), { none: 'unavailable', why: 'storage' });
  assert.equal(l.voice.asked.length, 0);
  assert.equal(l.ledger.spend.size, 0);
});

test('two readers asking for the same part at once: one reads it, the other waits for it, and it is paid for once', async () => {
  const s = summary('a-book');
  const shelf = memoryBookShelf();
  const key = bookClipKey(spokenPart(s, 0)!);
  // Another ask holds the claim, and keeps the clip while this one waits.
  assert.equal(await shelf.claim(key), true);
  const voice = fakeVoice();
  let waits = 0;
  const l = hearing([s], {
    shelf,
    voice,
    pause: async () => {
      waits++;
      if (waits === 2) await shelf.keep(key, Buffer.alloc(16_000), { book: 'a-book', part: 0, chars: 10, seconds: 1 });
    },
  });
  const got = await bookClipFor(s, 0, l);
  assert.equal(got.made, false);
  assert.equal(voice.asked.length, 0);
  // A claim that never ends in a clip: the ask gives up, and says busy.
  const stuck = memoryBookShelf();
  await stuck.claim(bookClipKey(spokenPart(s, 1)!));
  const l2 = hearing([s], { shelf: stuck });
  assert.deepEqual(await hearBook(true, bankOf(['a-book']), ask('a-book', 1), l2), { none: 'unavailable', why: 'busy' });
  assert.equal(l2.voice.asked.length, 0);
});

test('the summaries as the deploy carries them: the copy whose hash the bank names, or the site\'s, never one that is not', async () => {
  const dir = mkdtempSync(join(tmpdir(), 'summaries-'));
  const text = JSON.stringify({ book: 'a-book', title: 'A', author: 'B', parts: [{ title: 'One', text: ['Words.'] }] });
  const hash = createHash('sha256').update(text).digest('hex').slice(0, 12);
  writeFileSync(join(dir, 'a-book.json'), text);
  const asked: string[] = [];
  const site = (body: string): typeof fetch =>
    (async (url: string) => {
      asked.push(String(url));
      return new Response(body, { status: 200 });
    }) as typeof fetch;
  const bank = (v: string) => new Bank({ version: 1, cards: [], summaries: { 'a-book': { file: `summaries/a-book.json?v=${v}`, parts: 1 } } });
  // The deploy's copy is the one named: read from the disk, nothing fetched.
  assert.equal((await siteLibrary(dir, site('')).summaryOf(bank(hash), 'a-book'))?.title, 'A');
  assert.equal(asked.length, 0);
  // Revised since the deploy: the site's, when it is the one named.
  const revised = text.replace('Words.', 'Other words.');
  const v2 = createHash('sha256').update(revised).digest('hex').slice(0, 12);
  const fresh = await siteLibrary(dir, site(revised)).summaryOf(bank(v2), 'a-book');
  assert.equal(fresh?.parts[0].text[0], 'Other words.');
  assert.equal(asked.at(-1), 'https://astutetheapp.com/cards/summaries/a-book.json?v=' + v2);
  // A copy on the way that is not the one named is never read aloud.
  assert.equal(await siteLibrary(dir, site(text)).summaryOf(bank(v2), 'a-book'), null);
  // A book the bank names no summary for has none.
  assert.equal(await siteLibrary(dir, site(text)).summaryOf(bank(hash), 'b-book'), null);
  assert.equal(matches(`summaries/a-book.json?v=${hash}`, text), true);
  assert.equal(parseSummary('{"book": 1}'), null);
});

test('every summary the bank names is in the deploy, the very bytes it names, and every part is read in one clip', async () => {
  const shipped = Bank.bundled();
  const dir = join(import.meta.dirname, '..', 'data', 'summaries');
  const files = readdirSync(dir).filter((f) => f.endsWith('.json'));
  assert.ok(shipped.summaries.size >= 5);
  assert.equal(files.length, shipped.summaries.size);
  for (const [book, ref] of shipped.summaries) {
    const text = readFileSync(join(dir, `${book}.json`), 'utf8');
    assert.ok(matches(ref.file, text), book);
    const s = (await siteLibrary(dir, (async () => new Response('', { status: 404 })) as unknown as typeof fetch).summaryOf(shipped, book))!;
    assert.equal(s.parts.length, ref.parts);
    for (let i = 0; i < s.parts.length; i++) {
      const spoken = spokenPart(s, i)!;
      assert.ok(spoken.length > 1000 && spoken.length < MOST_PART, `${book} part ${i + 1}`);
    }
  }
});

test('ElevenLabs is asked for the books\' model, with the voice and English', async () => {
  let body: Record<string, unknown> = {};
  const voice = elevenLabs(
    'k'.repeat(32),
    (async (_url: string, init: RequestInit) => {
      body = JSON.parse(String(init.body));
      return new Response(Buffer.alloc(32_000), { status: 200, headers: { 'x-character-count': '12' } });
    }) as typeof fetch,
    async () => {},
    BOOK_MODEL_ID,
  );
  const read = await voice.speak('Part one.');
  assert.equal(body.model_id, 'eleven_v4_turbo');
  assert.equal(body.language_code, 'en');
  assert.equal(read.chars, 12);
  assert.equal(secondsOf(read.audio), 2);
});

test('a phone asks with a book, one of its parts, its day and its clock', () => {
  assert.deepEqual(readBookAsk({ book: 'sapiens', part: 2, date: DAY, tz: 60 }), { book: 'sapiens', part: 2, date: DAY, tz: 60 });
  assert.equal(readBookAsk({ book: 'Sapiens!', part: 2, date: DAY }), null);
  assert.equal(readBookAsk({ book: 'sapiens', part: -1, date: DAY }), null);
  assert.equal(readBookAsk({ book: 'sapiens', part: 1.5, date: DAY }), null);
  assert.equal(readBookAsk({ book: 'sapiens', part: 1, date: '27/11/2026' }), null);
  assert.equal(readBookAsk({ book: 'sapiens', part: 1, date: DAY, tz: 99999 })!.tz, 0);
});
