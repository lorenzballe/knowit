import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

import type Anthropic from '@anthropic-ai/sdk';

import { memoryLedger } from './budget.js';
import {
  CHECK_SYSTEM,
  FEEDS,
  FRONT,
  PICK_SYSTEM,
  STEPS,
  STORIES,
  WRITE_SYSTEM,
  articleText,
  askModel,
  cardProblems,
  dayAfter,
  makePaper,
  readArticles,
  readCheck,
  readFeed,
  readPapers,
  readPicks,
  toCard,
  type Ask,
  type FetchText,
  type Item,
  type NewsCard,
  type Story,
} from './news.js';

const NOW = Date.parse('2026-11-18T07:00:00Z');
const HOUR = 3_600_000;

function rss(items: Array<{ title: string; link: string; summary?: string; at?: number }>): string {
  const body = items
    .map(
      (it) => `<item>
  <title><![CDATA[${it.title}]]></title>
  <description><![CDATA[${it.summary ?? ''}]]></description>
  <link>${it.link}</link>
  ${it.at ? `<pubDate>${new Date(it.at).toUTCString()}</pubDate>` : ''}
</item>`,
    )
    .join('\n');
  return `<?xml version="1.0"?><rss version="2.0"><channel><title>Feed</title><link>https://example.org/</link>${body}</channel></rss>`;
}

test('a feed is read in RSS 2.0 and in RDF: titles opened, entities read, the link from rdf:about when there is no other', () => {
  const two = readFeed(
    `<rss><channel><link>https://news.example/</link>
      <item><title><![CDATA[Rates &amp; prices: a cut]]></title>
        <description>&lt;p&gt;The bank cut rates &#8212; again.&lt;/p&gt;</description>
        <link>https://news.example/a?at_medium=RSS&amp;at_campaign=rss</link>
        <pubDate>Wed, 18 Nov 2026 06:00:00 GMT</pubDate></item>
      <item><title>No link here</title></item>
    </channel></rss>`,
    'BBC News',
  );
  assert.equal(two.length, 1);
  assert.equal(two[0].title, 'Rates & prices: a cut');
  assert.equal(two[0].summary, 'The bank cut rates — again.');
  assert.equal(two[0].link, 'https://news.example/a?at_medium=RSS&at_campaign=rss');
  assert.equal(two[0].at, Date.parse('2026-11-18T06:00:00Z'));

  const rdf = readFeed(
    `<rdf:RDF><channel><items><rdf:Seq><rdf:li rdf:resource="https://dw.example/x"/></rdf:Seq></items></channel>
      <item rdf:about="https://dw.example/x"><title>Glaciers in the Alps lose a tenth</title>
        <dc:date>2026-11-18T05:00:00Z</dc:date></item></rdf:RDF>`,
    'DW',
  );
  assert.deepEqual(
    rdf.map((i) => [i.outlet, i.title, i.link, i.at]),
    [['DW', 'Glaciers in the Alps lose a tenth', 'https://dw.example/x', Date.parse('2026-11-18T05:00:00Z')]],
  );
});

test("an article is its own paragraphs: the page's scripts, menus, footers, cookie notices and one-liners left out", () => {
  const html = `<html><head><script>var p = "<p>not this</p>";</script><style>p{}</style></head><body>
    <nav><p>Home, News, Sport, Weather, and the rest of the menu</p></nav>
    <article><p class="lead">The central bank of Freedonia cut its main rate by half a point, to 2%.</p>
    <p>Short.</p>
    <p>We use cookies to give you the best experience on our website, as you know.</p>
    <p>Inflation fell to 1.8% in October, <a href="/x">below the target</a> of 2%.</p></article>
    <footer><p>All rights reserved, and other words that close a page.</p></footer></body></html>`;
  assert.equal(
    articleText(html),
    'The central bank of Freedonia cut its main rate by half a point, to 2%.\nInflation fell to 1.8% in October, below the target of 2%.',
  );
  assert.ok(articleText(html, 30).length <= 30);
});

test('the papers are the last day and a half, each story once, whatever feed fails', async () => {
  const feeds = [
    { outlet: 'BBC News', url: 'https://feeds.example/bbc' },
    { outlet: 'The Guardian', url: 'https://feeds.example/guardian' },
    { outlet: 'NPR', url: 'https://feeds.example/down' },
  ];
  const get: FetchText = async (url) =>
    url.endsWith('/bbc')
      ? rss([
          { title: 'Fresh', link: 'https://bbc.example/1?at=rss', at: NOW - 2 * HOUR },
          { title: 'Stale', link: 'https://bbc.example/2', at: NOW - 40 * HOUR },
          { title: 'Undated', link: 'https://bbc.example/3' },
        ])
      : url.endsWith('/guardian')
        ? rss([{ title: 'Fresh again', link: 'https://bbc.example/1?at=other', at: NOW - HOUR }])
        : null;
  const items = await readPapers(get, NOW, feeds);
  assert.deepEqual(
    items.map((i) => i.title),
    ['Fresh', 'Undated'],
  );
});

const ITEMS: Item[] = [
  { outlet: 'BBC News', title: 'Freedonia cuts rates to 2%', summary: '', link: 'https://bbc.example/rates', at: NOW },
  { outlet: 'The Guardian', title: 'Freedonia cuts rates as inflation falls', summary: '', link: 'https://guardian.example/rates', at: NOW },
  { outlet: 'BBC News', title: 'A comet passes', summary: '', link: 'https://bbc.example/comet', at: NOW },
  { outlet: 'BBC News', title: 'Comet seen from Europe', summary: '', link: 'https://bbc.example/comet2', at: NOW },
  { outlet: 'NPR', title: 'Chip prices rise', summary: '', link: 'https://npr.example/chips', at: NOW },
];

test('a story the editor picks needs two outlets, a subject the app has, and items no other story took', () => {
  const stories = readPicks(
    JSON.stringify({
      stories: [
        { items: [0, 1, 1, 99], topic: 'economics', world: true, question: 'Why cut rates now?' },
        { items: [2, 3], topic: 'space', world: false, question: 'One outlet only' },
        { items: [4, 0], topic: 'technology', world: false, question: 'Item 0 is taken' },
        { items: [4, 1], topic: 'gossip', world: false, question: 'Not a subject' },
      ],
    }),
    ITEMS,
  );
  assert.deepEqual(
    stories.map((s) => [s.topic, s.world, s.items.map((i) => i.link), s.question]),
    [['economics', true, ['https://bbc.example/rates', 'https://guardian.example/rates'], 'Why cut rates now?']],
  );
  assert.deepEqual(readPicks('not json', ITEMS), []);
});

test('the front page comes first, the world desk only on it, five at most, and eight stories in all', () => {
  // Twenty outlets, each with two reports of every story, so any pair is two outlets.
  const many: Item[] = Array.from({ length: 40 }, (_, i) => ({
    outlet: `Outlet ${i % 2}`,
    title: `Story ${Math.floor(i / 2)}`,
    summary: '',
    link: `https://news.example/${i}`,
    at: NOW,
  }));
  const pick = (n: number, world: boolean, topic = 'science') => ({ items: [2 * n, 2 * n + 1], topic, world, question: `Q${n}?` });
  const stories = readPicks(
    JSON.stringify({
      stories: [
        pick(0, false, 'space'),
        pick(1, true, 'world'),
        pick(2, false, 'world'),
        pick(3, true, 'economics'),
        pick(4, true),
        pick(5, true),
        pick(6, true),
        pick(7, true),
        pick(8, false),
        pick(9, false),
        pick(10, false),
        pick(11, false),
      ],
    }),
    many,
  );
  // A world story off the front page has nowhere to go; a sixth front-page story waits for none.
  assert.deepEqual(
    stories.map((s) => [s.question, s.world, s.topic]),
    [
      ['Q1?', true, 'world'],
      ['Q3?', true, 'economics'],
      ['Q4?', true, 'science'],
      ['Q5?', true, 'science'],
      ['Q6?', true, 'science'],
      ['Q0?', false, 'space'],
      ['Q8?', false, 'science'],
      ['Q9?', false, 'science'],
    ],
  );
  assert.equal(stories.filter((s) => s.world).length, FRONT);
  assert.equal(stories.length, STORIES);
});

test('the reporter reads three outlets at most, passing over a page with no article on it', async () => {
  const items: Item[] = ['Paywalled', 'One', 'Two', 'Three', 'Four'].map((outlet, i) => ({
    outlet,
    title: `${outlet} report`,
    summary: '',
    link: `https://${outlet.toLowerCase()}.example/story`,
    at: NOW,
  }));
  const asked: string[] = [];
  const get: FetchText = async (url) => {
    asked.push(url);
    if (url.includes('paywalled')) return '<p>Subscribe to read the rest of this article, today only.</p>';
    return `<article>${'<p>The central bank cut its main rate by half a point, to 2%, its first cut in two years.</p>'.repeat(6)}</article>`;
  };
  const read = await readArticles({ items, topic: 'economics', world: true, question: 'Why?' }, get);
  assert.deepEqual(
    read.map((a) => a.outlet),
    ['One', 'Two', 'Three'],
  );
  assert.equal(asked.length, 4);
});

const STORY: Story = { items: ITEMS.slice(0, 2), topic: 'economics', world: true, question: 'Why would a bank make borrowing cheaper now?' };
const ARTICLES = [{ outlet: 'BBC News', title: 'Freedonia cuts rates to 2%', link: 'https://bbc.example/rates', text: 'x'.repeat(500) }];

const GOOD = {
  summary: 'Its first cut in two years, as inflation fell to 1.8%, under its goal of 2%.',
  points: [
    'The central bank cut its main rate by half a point, to 2%.',
    'Inflation fell to 1.8% in October, under the 2% goal.',
    'Shops report fewer customers.',
  ],
  sides: [],
  question: "Freedonia's central bank cut its interest rate to 2% this week. Why would a bank make borrowing cheaper now?",
  answer:
    "Because prices have stopped rising fast. Inflation fell to 1.8%, under the bank's 2% goal, and shops report fewer customers. A lower rate makes loans and mortgages cheaper, so people and firms spend more, which supports jobs before a slowdown takes hold.",
  move: 'A price of money that falls is meant to make spending rise.',
  ask: 'What would I buy sooner if borrowing got cheaper, and what would I put off?',
  keywords: ['Interest rates', 'inflation', 'central bank'],
  headline: 'Freedonia cuts interest rates as inflation falls under its goal',
  outlet: 'BBC News',
  panels: [
    { label: 'What happened', figure: '2%', text: 'The central bank cut its main rate by half a point, to 2%. It is the first cut in two years.' },
    { label: 'Why', figure: '', text: 'Inflation fell to 1.8%, under the 2% goal, and shops report fewer customers. A cheaper loan is meant to bring spending back.' },
    { label: 'What it means for you', figure: '', text: "Mortgages that follow the bank's rate get cheaper within weeks. Savings accounts pay less." },
  ],
  then: { use: false, label: '', year: 0, headline: '', line: '' },
  region: 'europe',
  mood: 'practical',
  numeracy: 1,
  abstraction: 'mixed',
  source: 'BBC News and The Guardian',
};

test("the writer's card comes out in the bank's shape, dealt for three days after the news, and within the bank's rules", () => {
  const card = toCard(JSON.stringify(GOOD), STORY, ARTICLES, '2026-11-18');
  assert.ok(card);
  assert.equal(card.id, 'news-2026-11-18-freedonia-cuts-interest-rates-as-inflation');
  assert.equal(card.topic, 'economics');
  assert.equal(card.kind, 'read');
  assert.equal(card.scene.type, 'news');
  assert.deepEqual(card.scene.reported, [...new Set(STORY.items.map((it) => it.outlet))]);
  assert.ok(card.scene.reported.length >= 2);
  assert.equal(card.scene.date, '2026-11-18');
  assert.equal(card.scene.expires, '2026-11-21');
  assert.equal(card.scene.then, undefined);
  assert.equal(card.scene.panels[1].figure, undefined);
  assert.deepEqual(card.keywords, ['interest rates', 'inflation', 'central bank']);
  assert.equal(card.reference, 'https://bbc.example/rates');
  assert.equal(card.source_kind, 'news_archive');
  // The story page: its lines, its points, no sides, and the reports it was
  // made from, outlet by outlet, the newest report's time, its desk.
  assert.equal(card.scene.summary, GOOD.summary);
  assert.deepEqual(card.scene.points, GOOD.points);
  assert.deepEqual(card.scene.sides, []);
  assert.deepEqual(
    card.scene.sources.map((s) => [s.outlet, s.link]),
    [
      ['BBC News', 'https://bbc.example/rates'],
      ['The Guardian', 'https://guardian.example/rates'],
    ],
  );
  assert.equal(card.scene.at, new Date(NOW).toISOString());
  assert.equal(card.scene.world, true);
  assert.deepEqual(cardProblems(card), []);
  assert.equal(toCard('{', STORY, ARTICLES, '2026-11-18'), null);
  assert.equal(dayAfter('2026-12-30', 3), '2027-01-02');
});

test('a contested story gives two sides or none; the lines under the headline and the points keep to a small phone', () => {
  const card = (over: Record<string, unknown>) => toCard(JSON.stringify({ ...GOOD, ...over }), STORY, ARTICLES, '2026-11-18')!;
  const two = card({
    sides: [
      { who: 'The bank', view: 'Prices have stopped rising fast, so borrowing can be cheaper.' },
      { who: 'Its critics', view: 'A cut this soon risks prices rising again next year.' },
    ],
  });
  assert.deepEqual(cardProblems(two), []);
  const problems = cardProblems(
    card({
      summary: 'A summary that runs on and on and on, far past the two short lines that a story keeps under its headline on a small phone.',
      points: ['Only one point.'],
      sides: [{ who: 'One side, held by somebody with a long name', view: 'Alone.' }],
    }),
  );
  for (const expected of ['summary:', 'points: 1, not three or four', 'sides: 1, not two or none', 'sides[0].who']) {
    assert.ok(problems.some((p) => p.includes(expected)), `${expected} in ${problems.join(' | ')}`);
  }
});

test('the paper the shots photograph (tool/news/paper.json) is one this pipeline could have written', () => {
  const paper = JSON.parse(readFileSync(new URL('../../tool/news/paper.json', import.meta.url), 'utf8')) as {
    date: string;
    cards: NewsCard[];
  };
  assert.ok(paper.cards.length >= 5 && paper.cards.length <= STORIES);
  const front = paper.cards.filter((c) => c.scene.world);
  assert.ok(front.length >= 1 && front.length <= FRONT);
  paper.cards.forEach((c, i) => {
    assert.deepEqual(cardProblems(c), [], c.id);
    assert.equal(c.scene.rank, i + 1, c.id);
    assert.ok(c.id.startsWith(`news-${paper.date}-`), c.id);
    assert.ok(new Set(c.scene.reported).size >= 2, c.id);
    assert.ok(c.scene.sources.every((s) => c.scene.reported.includes(s.outlet)), c.id);
  });
  // The front page first.
  assert.deepEqual(
    paper.cards.map((c) => c.scene.world),
    [...front.map(() => true), ...paper.cards.slice(front.length).map(() => false)],
  );
});

test('a card out of the rules is turned back: lengths, steps, figures and the year of the past case', () => {
  const bad = toCard(
    JSON.stringify({
      ...GOOD,
      question: 'Why?',
      headline: 'A headline that runs on and on and on, far past the line that a small phone can ever hold',
      panels: [
        { label: 'What happened', figure: 'many', text: 'Something.' },
        { label: 'Why', figure: '', text: 'Because.' },
        { label: 'Why', figure: '', text: 'Again.' },
      ],
      then: { use: true, label: 'It happened before', year: 2026, headline: 'Same year', line: 'Not before the news.' },
    }),
    STORY,
    ARTICLES,
    '2026-11-18',
  );
  assert.ok(bad);
  const problems = cardProblems(bad);
  for (const expected of ['question: 1 words', 'characters, over 72', 'panels: three steps', 'no number in it', 'then.year: 2026', 'same label']) {
    assert.ok(problems.some((p) => p.includes(expected)), `${expected} in ${problems.join(' | ')}`);
  }
});

test('the checker passes a card only with nothing unsupported; a failed pass with no claim named is still a problem', () => {
  assert.deepEqual(readCheck(JSON.stringify({ claims: [{ claim: 'Rate is 2%', verdict: 'supported', note: '' }], pass: true })), {
    pass: true,
    problems: [],
  });
  const one = readCheck(
    JSON.stringify({ claims: [{ claim: 'First cut in ten years', verdict: 'unsupported', note: 'the article says two' }], pass: false }),
  );
  assert.equal(one.pass, false);
  assert.deepEqual(one.problems, ['First cut in ten years (the article says two)']);
  assert.deepEqual(readCheck(JSON.stringify({ claims: [], pass: false })).problems, ['the checker found the card misleading']);
  assert.equal(readCheck('nope').pass, false);
});

/** The papers and articles of a morning, offline. */
const MORNING: FetchText = async (url) => {
  if (url === FEEDS[0].url) {
    return rss([
      { title: 'Freedonia cuts rates to 2%', link: 'https://bbc.example/rates', at: NOW - HOUR },
      ...Array.from({ length: 6 }, (_, i) => ({ title: `BBC story ${i}`, link: `https://bbc.example/${i}`, at: NOW - HOUR })),
    ]);
  }
  if (url === FEEDS.find((f) => f.outlet === 'The Guardian')!.url) {
    return rss([
      { title: 'Freedonia cuts rates as inflation falls', link: 'https://guardian.example/rates', at: NOW - HOUR },
      ...Array.from({ length: 6 }, (_, i) => ({ title: `Guardian story ${i}`, link: `https://guardian.example/${i}`, at: NOW - HOUR })),
    ]);
  }
  if (url === 'https://bbc.example/rates' || url === 'https://guardian.example/rates') {
    const p = 'The central bank of Freedonia cut its main interest rate by half a percentage point, to 2%, its first cut in two years.';
    return `<html><body><article>${Array.from({ length: 5 }, () => `<p>${p}</p>`).join('')}</article></body></html>`;
  }
  return null;
};

function morningAsk(checks: boolean[]): { ask: Ask; calls: string[] } {
  const calls: string[] = [];
  const ask: Ask = async (system, user, _schema, step) => {
    if (system === PICK_SYSTEM) {
      calls.push('pick');
      assert.equal(step, STEPS.pick);
      assert.match(user, /<papers>/);
      const lines = user.split('\n');
      const bbc = lines.findIndex((l) => l.includes('Freedonia cuts rates to 2%')) - 1;
      const guardian = lines.findIndex((l) => l.includes('Freedonia cuts rates as inflation falls')) - 1;
      return {
        text: JSON.stringify({ stories: [{ items: [bbc, guardian], topic: 'economics', world: true, question: 'Why cut rates now?' }] }),
        cost: 0.001,
      };
    }
    if (system === WRITE_SYSTEM) {
      calls.push(user.includes('turned back') ? 'rewrite' : 'write');
      assert.equal(step, STEPS.write);
      assert.match(user, /<article outlet="BBC News"/);
      return { text: JSON.stringify(GOOD), cost: 0.002 };
    }
    assert.equal(system, CHECK_SYSTEM);
    assert.equal(step, STEPS.check);
    calls.push('check');
    const pass = checks.shift() ?? false;
    return {
      text: JSON.stringify({
        claims: pass ? [] : [{ claim: 'The first cut in two years', verdict: 'unsupported', note: '' }],
        pass,
      }),
      cost: 0.001,
    };
  };
  return { ask, calls };
}

test('a morning: the papers read, a story picked, its articles read, the card written and checked, and kept', async () => {
  const { ask, calls } = morningAsk([true]);
  const paper = await makePaper(ask, MORNING, NOW, '2026-11-18');
  assert.deepEqual(calls, ['pick', 'write', 'check']);
  assert.equal(paper.cards.length, 1);
  assert.equal(paper.cards[0].scene.headline, GOOD.headline);
  assert.equal(paper.cards[0].scene.rank, 1);
  assert.equal(paper.spent, false);
  assert.ok(Math.abs(paper.cost - 0.004) < 1e-9);
});

/** A client that answers every call with [text], and keeps what it was asked. */
function fakeClient(text: () => string, usage = { input_tokens: 4000, output_tokens: 900 }) {
  const asked: Array<Record<string, unknown>> = [];
  const client = {
    messages: {
      create: async (params: Record<string, unknown>) => {
        asked.push(params);
        return { content: [{ type: 'text', text: text() }], stop_reason: 'end_turn', usage };
      },
    },
  } as unknown as Anthropic;
  return { client, asked };
}

test('every step asks the cheapest model without thinking, at its own effort and cap, for JSON', async () => {
  const { client, asked } = fakeClient(() => '{"stories":[]}');
  const ask = askModel(client);
  for (const step of [STEPS.pick, STEPS.write, STEPS.check]) {
    const out = await ask('system', 'user', { type: 'object' }, step);
    assert.equal(out.text, '{"stories":[]}');
  }
  assert.deepEqual(
    asked.map((p) => [p.model, p.max_tokens, p.thinking, (p.output_config as { effort: string }).effort]),
    [
      ['claude-haiku-5-5', 1500, { type: 'disabled' }, 'medium'],
      ['claude-haiku-5-5', 2000, { type: 'disabled' }, 'low'],
      ['claude-haiku-5-5', 3000, { type: 'disabled' }, 'low'],
    ],
  );
  assert.deepEqual((asked[0].output_config as { format: unknown }).format, { type: 'json_schema', schema: { type: 'object' } });
  // Thinking off is accepted at effort high or below, and no step is above.
  assert.ok(Object.values(STEPS).every((s) => s.effort === 'low' || s.effort === 'medium'));
});

test("a morning within the AI's budget counts what it spent; once the budget is spent it asks nothing more, and keeps nothing unchecked", async () => {
  // Room for the pick and one story written, then none: its check is refused.
  const ledger = memoryLedger();
  let room = 2;
  const tight = { ...ledger, reserve: async (day: string, usd: number) => room-- > 0 && ledger.reserve(day, usd) };
  const { client, asked } = fakeClient(() =>
    asked.length === 1
      ? JSON.stringify({ stories: [{ items: [0, 7], topic: 'economics', world: true, question: 'Why cut rates now?' }] })
      : JSON.stringify(GOOD),
  );
  const paper = await makePaper(askModel(client, { ledger: tight, day: '2026-11-18' }), MORNING, NOW, '2026-11-18');
  const day = ledger.spend.get('2026-11-18')!;
  assert.equal(asked.length, 2);
  assert.equal(paper.cards.length, 0);
  assert.equal(paper.spent, true);
  assert.ok(paper.log.some((l) => l.includes('not checked')));
  // What the two calls cost is counted, with their tokens, under the news; nothing is left held.
  assert.equal(day.calls, 2);
  assert.equal(day.input, 8000);
  assert.equal(day.output, 1800);
  assert.ok(Math.abs(day.usd - 2 * (4000 * 0.1 + 900 * 0.5) / 1e6) < 1e-12);
  assert.ok(Math.abs(day.by.news.usd - day.usd) < 1e-12);
  assert.ok(Math.abs(day.held) < 1e-12);

  // A day or a month already spent: the editor is not even asked, and the
  // phones keep the paper they have.
  for (const limits of [{ day: 0 }, { month: 0 }]) {
    const none = fakeClient(() => '{}');
    const nothing = await makePaper(askModel(none.client, { ledger: memoryLedger(limits), day: '2026-11-18' }), MORNING, NOW, '2026-11-18');
    assert.equal(none.asked.length, 0);
    assert.deepEqual(nothing.cards, []);
    assert.equal(nothing.spent, true);
  }
});

test('a card the checker turns back is written once more from what was wrong, and dropped if it fails again', async () => {
  const again = morningAsk([false, true]);
  const kept = await makePaper(again.ask, MORNING, NOW, '2026-11-18');
  assert.deepEqual(again.calls, ['pick', 'write', 'check', 'rewrite', 'check']);
  assert.equal(kept.cards.length, 1);

  const twice = morningAsk([false, false]);
  const dropped = await makePaper(twice.ask, MORNING, NOW, '2026-11-18');
  assert.equal(dropped.cards.length, 0);
  assert.ok(dropped.log.some((l) => l.includes('dropped')));
});

test('a thin morning, with fewer than ten stories in the papers, asks the model nothing', async () => {
  const { ask, calls } = morningAsk([]);
  const paper = await makePaper(ask, async () => null, NOW, '2026-11-18');
  assert.deepEqual(calls, []);
  assert.deepEqual(paper.cards, []);
});
