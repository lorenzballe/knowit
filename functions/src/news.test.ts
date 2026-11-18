import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  CHECK_SYSTEM,
  FEEDS,
  PICK_SYSTEM,
  WRITE_SYSTEM,
  articleText,
  cardProblems,
  dayAfter,
  makePaper,
  readCheck,
  readFeed,
  readPapers,
  readPicks,
  toCard,
  type Ask,
  type FetchText,
  type Item,
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
        { items: [0, 1, 1, 99], topic: 'economics', question: 'Why cut rates now?' },
        { items: [2, 3], topic: 'space', question: 'One outlet only' },
        { items: [4, 0], topic: 'technology', question: 'Item 0 is taken' },
        { items: [4, 1], topic: 'gossip', question: 'Not a subject' },
      ],
    }),
    ITEMS,
  );
  assert.deepEqual(
    stories.map((s) => [s.topic, s.items.map((i) => i.link), s.question]),
    [['economics', ['https://bbc.example/rates', 'https://guardian.example/rates'], 'Why cut rates now?']],
  );
  assert.deepEqual(readPicks('not json', ITEMS), []);
});

const STORY: Story = { items: ITEMS.slice(0, 2), topic: 'economics', question: 'Why would a bank make borrowing cheaper now?' };
const ARTICLES = [{ outlet: 'BBC News', title: 'Freedonia cuts rates to 2%', link: 'https://bbc.example/rates', text: 'x'.repeat(500) }];

const GOOD = {
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
  assert.deepEqual(cardProblems(card), []);
  assert.equal(toCard('{', STORY, ARTICLES, '2026-11-18'), null);
  assert.equal(dayAfter('2026-12-30', 3), '2027-01-02');
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
  if (url === FEEDS[5].url) {
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
  const ask: Ask = async (system, user) => {
    if (system === PICK_SYSTEM) {
      calls.push('pick');
      assert.match(user, /<papers>/);
      const lines = user.split('\n');
      const bbc = lines.findIndex((l) => l.includes('Freedonia cuts rates to 2%')) - 1;
      const guardian = lines.findIndex((l) => l.includes('Freedonia cuts rates as inflation falls')) - 1;
      return { text: JSON.stringify({ stories: [{ items: [bbc, guardian], topic: 'economics', question: 'Why cut rates now?' }] }), cost: 0.001 };
    }
    if (system === WRITE_SYSTEM) {
      calls.push(user.includes('turned back') ? 'rewrite' : 'write');
      assert.match(user, /<article outlet="BBC News"/);
      return { text: JSON.stringify(GOOD), cost: 0.002 };
    }
    assert.equal(system, CHECK_SYSTEM);
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
  assert.ok(Math.abs(paper.cost - 0.004) < 1e-9);
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
