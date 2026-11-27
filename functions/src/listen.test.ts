import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

import { Bank, type Card } from './bank.js';
import {
  AHEAD_CHARS,
  CHAR_LIMITS,
  LISTEN_CARDS_PER_DAY,
  LISTEN_DAY_CHARS,
  LISTEN_MONTH_CHARS,
  MODEL_ID,
  NOT_CONFIGURED,
  OUTPUT_FORMAT,
  VOICE_ID,
  aheadCards,
  checkKey,
  claimOf,
  clipsFor,
  clipKey,
  configured,
  elevenLabs,
  listenTo,
  makeAhead,
  memoryCharLedger,
  memoryClaims,
  memoryShelf,
  readListen,
  refusalOf,
  spokenOf,
  storageShelf,
  type ListenAsk,
  type Listening,
  type Voice,
  VoiceRefused,
} from './listen.js';

const DAY = '2026-11-27';

function card(id: string, over: Partial<Card> = {}): Card {
  return {
    id,
    topic: 'science',
    kind: 'read',
    difficulty: 'easy',
    principle: 'none',
    question: `Why does ${id} matter so much?`,
    answer: `Because ${id} is the reason. It explains the rest of the story well enough.`,
    ...over,
  };
}

/** A voice that reads anything, counting what it was asked. */
function fakeVoice(): Voice & { asked: string[] } {
  const asked: string[] = [];
  return {
    asked,
    async speak(text) {
      asked.push(text);
      return { audio: Buffer.from(`mp3:${text}`), chars: text.length };
    },
  };
}

function listening(over: Partial<Listening> = {}): Listening & { voice: ReturnType<typeof fakeVoice>; shelf: ReturnType<typeof memoryShelf>; ledger: ReturnType<typeof memoryCharLedger>; claims: ReturnType<typeof memoryClaims> } {
  return {
    configured: true,
    shelf: memoryShelf(),
    ledger: memoryCharLedger(),
    voice: fakeVoice(),
    claims: memoryClaims(),
    day: DAY,
    ...over,
  } as never;
}

const ask = (id: string): ListenAsk => ({ card: id, date: DAY, tz: 60 });

/** Whether a reply is the two clips. */
const heard = (out: Awaited<ReturnType<typeof listenTo>>): out is { question: string; answer: string } =>
  typeof out === 'object' && 'question' in out;

test('a clip is named by the hash of how it is said and what: the same words the same name, other words another', () => {
  const a = clipKey('Why is the sky blue?');
  assert.match(a, /^[0-9a-f]{64}$/);
  assert.equal(clipKey('Why is the sky blue?'), a);
  assert.notEqual(clipKey('Why is the sky blue ?'), a);
  // The voice, the model and the format are in it: the words alone hash
  // otherwise, so a new voice is a new clip for every card.
  assert.notEqual(createHash('sha256').update('Why is the sky blue?').digest('hex'), a);
  // Pinned: a change here (a new voice, model or setting) makes every clip
  // again, at the price of the whole bank read aloud. Change it knowingly.
  assert.equal(VOICE_ID, 'fnYMz3F5gMEDGMWcH1ex');
  assert.equal(MODEL_ID, 'eleven_v4');
  assert.equal(OUTPUT_FORMAT, 'mp3_44100_128');
});

test('a clip never made is read, kept and counted; asked again it is the one kept, and nothing is read or counted', async () => {
  const l = listening();
  const c = card('science-sky');
  const first = await listenTo('reader-1', true, c, ask(c.id), l);
  assert.ok(heard(first));
  assert.equal(l.voice.asked.length, 2);
  assert.deepEqual(l.voice.asked, [spokenOf(c)!.question, spokenOf(c)!.answer]);
  assert.equal(l.shelf.kept.size, 2);
  const chars = spokenOf(c)!.question.length + spokenOf(c)!.answer.length;
  assert.equal(l.ledger.spend.get(DAY)!.chars, chars);
  assert.equal(l.ledger.spend.get(DAY)!.held, 0);
  assert.equal(l.ledger.spend.get('2026-11')!.clips, 2);

  // Another reader, another day: the same clips, at no cost.
  const again = await listenTo('reader-2', true, c, { ...ask(c.id), date: '2026-11-28' }, { ...l, day: '2026-11-28' });
  assert.deepEqual(again, first);
  assert.equal(l.voice.asked.length, 2);
  assert.equal(l.ledger.spend.get('2026-11-28'), undefined);
});

test('a card whose words change is heard anew, and only the part that changed is read again', async () => {
  const l = listening();
  const before = card('science-tides');
  const was = await listenTo('r', true, before, ask(before.id), l);
  const after = { ...before, answer: 'The Moon pulls the near side of the sea harder than the far side.' };
  const now = await listenTo('r', true, after, ask(after.id), l);
  assert.ok(heard(was) && heard(now));
  assert.equal(now.question, was.question);
  assert.notEqual(now.answer, was.answer);
  assert.equal(l.voice.asked.length, 3);
  assert.equal(l.voice.asked[2], after.answer);
});

test('the characters have a hard stop: so many a day and a month, held before a clip is read, and nothing read past them', async () => {
  assert.deepEqual(CHAR_LIMITS, { day: LISTEN_DAY_CHARS, month: LISTEN_MONTH_CHARS });
  // Under the Creator plan's 275,000 a month, so the plan is never overdrawn.
  assert.ok(LISTEN_MONTH_CHARS <= 275_000);
  assert.ok(LISTEN_DAY_CHARS <= LISTEN_MONTH_CHARS / 10);

  const l = listening({ ledger: memoryCharLedger({ day: 1_000_000, month: 300 }) });
  let said = 0;
  let unavailable = 0;
  for (let i = 0; i < 6; i++) {
    const c = card(`science-${i}`);
    const out = await listenTo('r', true, c, ask(c.id), l);
    if (heard(out)) said++;
    else if (typeof out === 'object' && out.none === 'unavailable') {
      assert.equal(out.why, 'spent');
      unavailable++;
    }
  }
  const month = l.ledger.spend.get('2026-11')!;
  assert.ok(said >= 1 && unavailable >= 1, `${said} heard, ${unavailable} not`);
  assert.ok(month.chars <= 300);
  assert.equal(month.held, 0);
  assert.ok(month.refused >= 1);
  // Nothing refused was read.
  assert.equal(l.voice.asked.reduce((n, t) => n + t.length, 0), month.chars);
  // A new month has room again.
  const next = card('science-next');
  assert.ok(heard(await listenTo('r', true, next, { ...ask(next.id), date: '2026-12-01' }, { ...l, day: '2026-12-01' })));
});

test('a clip that fails is not counted, and what it held is let go', async () => {
  const ledger = memoryCharLedger();
  const voice: Voice = {
    async speak() {
      throw new VoiceRefused('busy', 503, 'down');
    },
  };
  const spoken = { question: 'Hello there, reader?', answer: 'Hello again, reader.' };
  await assert.rejects(clipsFor('c', spoken, { shelf: memoryShelf(), ledger, voice, day: DAY }), VoiceRefused);
  assert.deepEqual(ledger.spend.get(DAY), { chars: 0, held: 0, clips: 0, refused: 0 });
});

test('on the free plan the first card heard is free and any other that day is Astute+; with Astute+ the five, and never more than so many a day', async () => {
  const l = listening();
  const five = [1, 2, 3, 4, 5].map((i) => card(`history-${i}`));
  assert.ok(heard(await listenTo('free', false, five[0], ask(five[0].id), l)));
  // Heard again, the same card is still the free one.
  assert.ok(heard(await listenTo('free', false, five[0], ask(five[0].id), l)));
  assert.equal(await listenTo('free', false, five[1], ask(five[1].id), l), 'plus');
  // The next day has a free card of its own.
  assert.ok(heard(await listenTo('free', false, five[1], { ...ask(five[1].id), date: '2026-11-28' }, l)));
  assert.equal(l.claims.days.get('free/2026-11-27')!.free, five[0].id);

  for (const c of five) assert.ok(heard(await listenTo('plus', true, c, ask(c.id), l)));
  assert.equal(l.claims.days.get('plus/2026-11-27')!.free, null);

  // A phone that says Astute+ and is not still stops at the day's cards.
  assert.equal(LISTEN_CARDS_PER_DAY, 15);
  const many = Array.from({ length: LISTEN_CARDS_PER_DAY + 1 }, (_, i) => card(`maths-${i}`));
  const said = [];
  for (const c of many) said.push(await listenTo('liar', true, c, ask(c.id), l));
  assert.equal(said.filter((s) => s === 'enough').length, 1);
  assert.equal(said.at(-1), 'enough');
});

test('a card with nothing to hear is said so, and does not take the free card', async () => {
  const l = listening();
  const silent = card('art-silent', { web: { kit: 1, page: 'pages/art-silent.html' }, answer: 'Drag the slider to see it. The page shows the rest.' });
  assert.equal(spokenOf(silent), null);
  assert.deepEqual(await listenTo('free', false, silent, ask(silent.id), l), { none: 'nothing' });
  const next = card('art-next');
  assert.ok(heard(await listenTo('free', false, next, ask(next.id), l)));
  assert.deepEqual(await listenTo('free', false, undefined, ask('art-gone'), l), { none: 'nothing' });
  assert.equal(l.voice.asked.length, 2);
});

test('without a key the call says it is not configured, and asks, claims and spends nothing', async () => {
  assert.equal(configured(undefined), false);
  assert.equal(configured(''), false);
  assert.equal(configured(NOT_CONFIGURED), false);
  assert.equal(configured(`  ${NOT_CONFIGURED}\n`), false);
  assert.equal(configured(`sk_${'0a'.repeat(24)}`), true);

  const l = listening({ configured: false });
  const c = card('science-sky');
  assert.deepEqual(await listenTo('r', false, c, ask(c.id), l), { none: 'not-configured' });
  assert.equal(l.voice.asked.length, 0);
  assert.equal(l.claims.days.size, 0);
  assert.equal(l.ledger.spend.size, 0);
});

test('a key ElevenLabs turns away is not configured; spent characters or a busy voice are unavailable', async () => {
  const err = (type: string, code: string, message = '') => JSON.stringify({ detail: { type, code, message, request_id: 'r1' } });
  assert.equal(refusalOf(401, err('authentication_error', 'invalid_api_key', 'Invalid API key')), 'key');
  assert.equal(refusalOf(401, '{"detail":{"status":"invalid_api_key","message":"Invalid API key"}}'), 'key');
  // A key made without Text to Speech is a key to make again.
  assert.equal(refusalOf(403, err('authorization_error', 'insufficient_permissions', 'The API key is missing the permission text_to_speech')), 'key');
  assert.equal(refusalOf(429, err('rate_limit_error', 'concurrent_limit_exceeded')), 'busy');
  assert.equal(refusalOf(429, '{"detail":{"status":"system_busy"}}'), 'busy');
  assert.equal(refusalOf(503, 'Service Unavailable'), 'busy');
  assert.equal(refusalOf(422, '{"detail":[{"msg":"bad"}]}'), 'refused');
  assert.equal(refusalOf(404, err('not_found', 'voice_not_found')), 'refused');

  const turnedAway = (why: 'key' | 'busy'): Voice => ({
    async speak() {
      throw new VoiceRefused(why, why === 'key' ? 401 : 503, why);
    },
  });
  const c = card('science-sky');
  assert.deepEqual(await listenTo('r', true, c, ask(c.id), listening({ voice: turnedAway('key') as never })), { none: 'not-configured' });
  assert.deepEqual(await listenTo('r', true, c, ask(c.id), listening({ voice: turnedAway('busy') as never })), { none: 'unavailable', why: 'busy' });
});

test('a key added before any credit was bought: every refusal for want of credit or plan is "not available", calmly, and nothing is counted', async () => {
  const err = (status: number, type: string, code: string, message: string) => ({ status, body: JSON.stringify({ detail: { type, code, message } }) });
  const noCredit = [
    err(402, 'payment_required', 'insufficient_credits', 'Your account does not have enough credits for this operation.'),
    err(403, 'authorization_error', 'subscription_required', 'A paid subscription is required.'),
    err(403, 'authorization_error', 'voice_access_denied', 'Free users cannot use library voices via the API. Please upgrade your subscription to use this voice.'),
    err(403, 'authorization_error', 'feature_not_available', 'Not included in your plan.'),
    // The older shape, which ElevenLabs answered with a 401.
    { status: 401, body: '{"detail":{"status":"quota_exceeded","message":"This request exceeds your quota of 10000. You have 0 credits remaining."}}' },
  ];
  for (const { status, body } of noCredit) {
    assert.equal(refusalOf(status, body), 'credit', body);
    const voice = elevenLabs(`sk_${'1'.repeat(40)}`, (async () => new Response(body, { status })) as unknown as typeof fetch, async () => {});
    const l = listening({ voice: voice as never });
    const c = card('science-credit');
    assert.deepEqual(await listenTo('free', false, c, ask(c.id), l), { none: 'unavailable', why: 'credit' }, body);
    assert.deepEqual(l.ledger.spend.get(DAY), { chars: 0, held: 0, clips: 0, refused: 0 });
    assert.equal(l.shelf.kept.size, 0);
  }
  // A clip made before the credit ran out still plays.
  const l = listening();
  const c = card('science-kept');
  const before = await listenTo('r', true, c, ask(c.id), l);
  const broke = elevenLabs(`sk_${'1'.repeat(40)}`, (async () => new Response(noCredit[0].body, { status: 402 })) as unknown as typeof fetch, async () => {});
  assert.deepEqual(await listenTo('r', true, c, ask(c.id), { ...l, voice: broke }), before);
  // And a run ahead stops at the first refusal rather than asking for every card.
  let asked = 0;
  const counting = elevenLabs(`sk_${'1'.repeat(40)}`, (async () => {
    asked++;
    return new Response(noCredit[0].body, { status: 402 });
  }) as unknown as typeof fetch, async () => {});
  const run = await makeAhead([card('space-1'), card('space-2'), card('space-3')], { shelf: memoryShelf(), ledger: memoryCharLedger(), voice: counting, day: DAY });
  assert.deepEqual({ made: run.made, failed: run.failed }, { made: 0, failed: 1 });
  assert.ok(asked <= 2, `${asked} asked`);
});

test('ElevenLabs is asked for the voice, the model and English, with the key, and a busy answer is tried once more', async () => {
  const calls: { url: string; init: RequestInit }[] = [];
  let busy = 1;
  const fetcher = (async (url: string, init: RequestInit) => {
    calls.push({ url, init });
    if (busy-- > 0) return new Response('{"detail":{"status":"system_busy"}}', { status: 429 });
    return new Response(new Uint8Array([0xff, 0xfb, 0x90]), { status: 200, headers: { 'x-character-count': '21' } });
  }) as unknown as typeof fetch;
  const waits: number[] = [];
  const voice = elevenLabs('sk_test_key_that_is_long_enough', fetcher, async (ms) => {
    waits.push(ms);
  });
  const read = await voice.speak('Why is the sky blue?');
  assert.equal(read.chars, 21);
  assert.deepEqual([...read.audio], [0xff, 0xfb, 0x90]);
  assert.equal(calls.length, 2);
  assert.deepEqual(waits, [1500]);
  assert.equal(calls[1].url, `https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}?output_format=${OUTPUT_FORMAT}`);
  assert.equal((calls[1].init.headers as Record<string, string>)['xi-api-key'], 'sk_test_key_that_is_long_enough');
  assert.deepEqual(JSON.parse(String(calls[1].init.body)), {
    text: 'Why is the sky blue?',
    model_id: 'eleven_v4',
    language_code: 'en',
    voice_settings: { stability: 0.5, similarity_boost: 0.75 },
  });

  // Turned away twice: said why, never a third time.
  let asked = 0;
  const always = elevenLabs('k'.repeat(30), (async () => {
    asked++;
    return new Response('{"detail":{"status":"invalid_api_key"}}', { status: 401 });
  }) as unknown as typeof fetch, async () => {});
  await assert.rejects(always.speak('Hello there.'), (e: unknown) => e instanceof VoiceRefused && e.why === 'key');
  assert.equal(asked, 1);
});

test('what a card says aloud: its question, then its answer; a debate with its other side; a drawn card without the words about its page', () => {
  const plain = card('science-plain', { answer: 'About 5 tonnes: 1.9 × 2.7 ≈ 5. The source is Smith, 2020.' });
  assert.deepEqual(spokenOf(plain), { question: plain.question, answer: 'About 5 tonnes: 1.9 times 2.7 about 5.' });

  const debate = card('art-debate', { kind: 'debate', answer: 'Yes: the money came first.', counterpoint: 'No: it was famous before.' });
  assert.equal(spokenOf(debate)!.answer, 'Yes: the money came first.\n\nThe other side. No: it was famous before.');

  const drawn = card('science-drawn', {
    kind: 'page',
    web: { kit: 1, page: 'pages/science-drawn.html' },
    answer:
      'The surface got colder than –78 °C, which is CO₂’s sublimation point. Drag the thermometer down to chill it. '
      + 'The card says that F. Périer wrote it down in 1648. Its keep-note says a flash like that means the blast is still coming. '
      + 'The page shows a drop of water against the Pacific. Sources: Popova et al., Science, 2013.',
  });
  assert.equal(
    spokenOf(drawn)!.answer,
    'The surface got colder than –78 °C, which is CO₂’s sublimation point. F. Périer wrote it down in 1648. A flash like that means the blast is still coming.',
  );
  // Tap water is not a tap on the page: a card in words is read whole.
  const words = card('human_body-pfas', { answer: 'Tap water with trace PFAS adds up over years. The body keeps it.' });
  assert.equal(spokenOf(words)!.answer, 'Tap water with trace PFAS adds up over years. The body keeps it.');

  assert.equal(spokenOf(card('science-gone', { disabled: true })), null);
  assert.equal(spokenOf(card('science-mute', { question: '?' })), null);
});

test('the bank as it ships: every card in words is heard, and no drawn card is heard speaking of its page', () => {
  const bank = Bank.bundled();
  const live = bank.cards.filter((c) => !c.disabled);
  const drawn = live.filter((c) => c.web != null);
  let skipped = 0;
  for (const c of live) {
    const spoken = spokenOf(c);
    if (c.web == null) {
      assert.ok(spoken, c.id);
      continue;
    }
    if (!spoken) {
      skipped++;
      continue;
    }
    for (const s of spoken.answer.split(/(?<=[.!?])\s+/)) {
      assert.doesNotMatch(s, /^(Drag|Tap|Swipe|Slide|Flip)\b|\bthe (page|slider)\b|keep-note/i, `${c.id}: ${s}`);
    }
  }
  // Said for the owner: how many drawn cards have nothing to hear.
  console.log(`listen: ${drawn.length} drawn cards live, ${skipped} with nothing to hear`);
  assert.ok(skipped <= drawn.length / 20, `${skipped} of ${drawn.length} drawn cards skipped`);
});

test('a phone asks with a card of its day, the day, and its clock', () => {
  assert.deepEqual(readListen({ card: 'science-2', date: '2026-11-27', tz: 60 }), { card: 'science-2', date: '2026-11-27', tz: 60 });
  assert.equal(readListen({ card: '../etc', date: '2026-11-27' }), null);
  assert.equal(readListen({ card: 'science-2', date: 'tomorrow' }), null);
  assert.equal(readListen({ card: 'science-2', date: '2026-11-27', tz: 99_999 })!.tz, 0);
  assert.equal(readListen(null), null);
});

test('the claim is the free plan\'s one card, kept for the day', () => {
  assert.deepEqual(claimOf(undefined, 'a', false), { claim: 'ok', free: 'a', cards: ['a'] });
  assert.deepEqual(claimOf({ free: 'a', cards: ['a'] }, 'b', false), { claim: 'plus', free: 'a', cards: ['a'] });
  assert.deepEqual(claimOf({ free: 'a', cards: ['a'] }, 'b', true), { claim: 'ok', free: 'a', cards: ['a', 'b'] });
  assert.deepEqual(claimOf({ cards: ['a', 'b'] }, 'c', true, 2), { claim: 'enough', free: null, cards: ['a', 'b'] });
});

test('ahead of the reader: every card of an Astute+ listener\'s next days, the free one of a free listener\'s, each once, the soonest first', () => {
  const silent = card('art-silent', { web: { kit: 1 }, answer: 'Tap the drawing.' });
  const cards = [silent, ...['a', 'b', 'c', 'd', 'e', 'f', 'g'].map((x) => card(`science-${x}`))];
  const bank = new Bank({ version: 1, cards });
  const out = aheadCards(
    [
      { plus: false, days: [['art-silent', 'science-a', 'science-b'], ['science-f', 'science-g']] },
      { plus: true, days: [['science-a', 'science-c', 'science-d'], ['science-e']] },
    ],
    bank,
  );
  assert.deepEqual(
    out.map((c) => c.id),
    ['science-a', 'science-c', 'science-d', 'science-f', 'science-e'],
  );
});

test('a run ahead makes what was never made, keeps to its share of the day, and stops when the characters are spent', async () => {
  assert.equal(AHEAD_CHARS, Math.floor(LISTEN_DAY_CHARS / 4));
  const cards = Array.from({ length: 10 }, (_, i) => card(`space-${i}`));
  const m = { shelf: memoryShelf(), ledger: memoryCharLedger(), voice: fakeVoice(), day: DAY };
  await clipsFor(cards[0].id, spokenOf(cards[0])!, m);
  const run = await makeAhead(cards.slice(0, 2), m);
  assert.deepEqual({ made: run.made, kept: run.kept, spent: run.spent }, { made: 2, kept: 2, spent: false });

  // A card at a time, and no card begun past the run's share.
  const short = await makeAhead(cards.slice(2), { ...m, voice: fakeVoice() }, 100);
  assert.deepEqual({ made: short.made, spent: short.spent }, { made: 2, spent: false });
  assert.ok(short.chars >= 100 && short.chars < 200);

  // A card whose two clips cannot both be paid for is not begun.
  const broke = { ...m, ledger: memoryCharLedger({ day: 60 }), voice: fakeVoice() };
  const none = await makeAhead(cards.slice(5), broke);
  assert.deepEqual({ made: none.made, spent: none.spent }, { made: 0, spent: true });
  assert.equal(broke.voice.asked.length, 0);
});

test('with nowhere to keep a clip (Storage never set up), nothing is read or paid for, and the card is not available', async () => {
  const l = listening({ shelf: memoryShelf('b', false) as never });
  const c = card('science-nowhere');
  assert.deepEqual(await listenTo('r', true, c, ask(c.id), l), { none: 'unavailable', why: 'storage' });
  assert.equal(l.voice.asked.length, 0);
  assert.equal(l.ledger.spend.size, 0);

  // The bucket is asked once while it is there, and again a few minutes
  // after it was not, so setting Storage up needs no deploy.
  let asked = 0;
  let there = false;
  let clock = 0;
  const bucket = {
    name: 'astuto-3d398.firebasestorage.app',
    async exists(): Promise<[boolean]> {
      asked++;
      return [there];
    },
    file: () => ({ save: async () => undefined }),
  };
  const shelf = storageShelf({ collection: () => ({}) } as never, bucket, () => 't', () => clock);
  assert.equal(await shelf.ready(), false);
  clock += 60_000;
  assert.equal(await shelf.ready(), false);
  assert.equal(asked, 1);
  there = true;
  clock += 5 * 60_000;
  assert.equal(await shelf.ready(), true);
  assert.equal(await shelf.ready(), true);
  assert.equal(asked, 2);
});

test('the deploy\'s check of a key: kept when ElevenLabs takes it or only wants paying, dropped when it says it is no key', async () => {
  const answer = (status: number, body: string | Uint8Array<ArrayBuffer>) => (async () => new Response(body, { status })) as unknown as typeof fetch;
  assert.deepEqual(await checkKey('sk_x', answer(200, new Uint8Array([1, 2, 3]))), { keep: true, verdict: 'works', status: 200, said: '' });
  assert.deepEqual(
    await checkKey('sk_x', answer(402, JSON.stringify({ detail: { type: 'payment_required', code: 'insufficient_credits', message: 'Not enough credits.' } }))),
    { keep: true, verdict: 'credit', status: 402, said: 'Not enough credits.' },
  );
  assert.deepEqual(
    await checkKey('sk_x', answer(401, JSON.stringify({ detail: { type: 'authentication_error', code: 'invalid_api_key', message: 'Invalid API key' } }))),
    { keep: false, verdict: 'key', status: 401, said: 'Invalid API key' },
  );
  const down = await checkKey('sk_x', (async () => {
    throw new Error('getaddrinfo ENOTFOUND api.elevenlabs.io');
  }) as unknown as typeof fetch);
  assert.equal(down.keep, true);
  assert.equal(down.verdict, 'unreachable');

  // The workflow keeps the same stand-in the functions read as no key, and
  // asks the check, not its own guess.
  const workflow = readFileSync(new URL('../../.github/workflows/cloud-deploy.yml', import.meta.url), 'utf8');
  assert.ok(workflow.includes(`printf '%s' '${NOT_CONFIGURED}'`));
  assert.ok(workflow.includes('checkKey(process.env.ELEVENLABS)'));
  assert.ok(workflow.includes('ELEVENLABS: ${{ secrets.ELEVENLABS_API_KEY }}'));
});
