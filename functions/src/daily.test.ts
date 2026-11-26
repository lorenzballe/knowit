import assert from 'node:assert/strict';
import { test } from 'node:test';

import { Bank, Card, TOPICS } from './bank.js';
import { dailyKind, gameKey, judge, playableDay, readPlay, sharePoints, tallyOf } from './daily.js';

// Noon in Rome on a Sunday.
const NOW = Date.parse('2026-10-18T10:00:00Z');
const DAY = '2026-10-18';

function card(id: string, topic: string, over: Partial<Card> = {}): Card {
  return { id, topic, kind: 'pickOne', difficulty: 'easy', principle: 'none', question: '?', answer: '.', options: ['a', 'b', 'c'], correct: 1, ...over };
}

const share = (id: string, topic: string, value: number, over: Partial<Card> = {}) =>
  card(id, topic, { kind: 'number', value, unit: '%', options: undefined, correct: undefined, ...over });

// Five picks of five subjects, a share among them, and three of one subject.
const FIVE = [
  card('art-1', 'art'),
  card('history-1', 'history', { options: ['yes', 'no'], correct: 0 }),
  share('maths-1', 'maths', 55),
  card('science-1', 'science'),
  card('space-1', 'space'),
];
const SCIENCE = [card('science-2', 'science'), card('science-3', 'science', { correct: 2 }), share('science-4', 'science', 28, { tolerance: 2 })];
const bank = new Bank({
  version: 7,
  cards: [
    ...FIVE,
    ...SCIENCE,
    card('art-2', 'art'),
    card('art-read', 'art', { kind: 'read', options: undefined, correct: undefined }),
    card('art-four', 'art', { options: ['a', 'b', 'c', 'd'] }),
    card('art-mature', 'art', { mature: true }),
    card('art-page', 'art', { kind: 'page', web: { kit: 1 } }),
    card('art-place', 'art', { place: { country: 'IT' } }),
    card('art-book', 'art', { book: { id: 'b', title: 't', author: 'a', year: 1950, part: 1 } }),
    share('art-tonnes', 'art', 5.6, { kind: 'estimate', unit: 'tonnes' }),
    share('art-over', 'art', 140),
    share('psychology-dream', 'psychology', 5, { kind: 'estimate', unit: ' Percent ', withinFactor: 3 }),
  ],
});
const byId = (id: string) => bank.byId.get(id) as Card;

const said = (cards: Card[], answers: string[]) => cards.map((c, i) => ({ id: c.id, said: answers[i] }));

test('a share is a hundred on the answer, three fewer a point off, in tens: the phone\'s own table', () => {
  assert.equal(sharePoints(28, 28), 100);
  assert.equal(sharePoints(29.5, 28), 100); // 95.5
  assert.equal(sharePoints(30, 28), 90); // 94
  assert.equal(sharePoints(38, 28), 70);
  assert.equal(sharePoints(18, 28), 70);
  assert.equal(sharePoints(61, 28), 0);
  assert.equal(sharePoints(100, 0), 0);
});

test('the cards the day\'s games ask are the phone\'s: picks of two or three, and shares', () => {
  assert.equal(dailyKind(byId('art-1')), 'pick');
  assert.equal(dailyKind(byId('history-1')), 'pick');
  assert.equal(dailyKind(byId('maths-1')), 'share');
  assert.equal(dailyKind(byId('psychology-dream')), 'share');
  for (const id of ['art-read', 'art-four', 'art-mature', 'art-page', 'art-place', 'art-book', 'art-tonnes', 'art-over']) {
    assert.equal(dailyKind(byId(id)), null, id);
  }
});

test('every subject of the bundled bank has the cards for its three and a card for the five', () => {
  const bundled = Bank.bundled();
  for (const topic of TOPICS) {
    const n = bundled.live.filter((c) => c.topic === topic && dailyKind(c) !== null).length;
    assert.ok(n >= 4, `${topic}: ${n}`);
  }
});

test('an answer is judged by the card\'s own test and scored as the phone scores it', () => {
  assert.deepEqual(judge(byId('art-1'), '1'), { right: true, points: 100, pick: 1 });
  assert.deepEqual(judge(byId('art-1'), '2'), { right: false, points: 0, pick: 2 });
  assert.deepEqual(judge(byId('maths-1'), '55'), { right: true, points: 100, guess: 55 });
  assert.deepEqual(judge(byId('maths-1'), '65'), { right: false, points: 70, guess: 65 });
  // Within the card's own slack, right; a hundred only on the answer itself.
  assert.deepEqual(judge(byId('science-4'), '29.5'), { right: true, points: 100, guess: 29.5 });
  assert.deepEqual(judge(byId('science-4'), '30'), { right: true, points: 90, guess: 30 });
  assert.equal(judge(byId('science-4'), '31')?.right, false);
  // An estimate is right within its factor either way.
  assert.equal(judge(byId('psychology-dream'), '14')?.right, true);
  assert.equal(judge(byId('psychology-dream'), '16')?.right, false);
  assert.equal(judge(byId('psychology-dream'), '0')?.right, false);
});

test('nothing is judged that the card could not have been given', () => {
  for (const s of ['3', '-1', '1.0', 'a', '', ' 1', '10']) assert.equal(judge(byId('art-1'), s), null, s);
  assert.equal(judge(byId('history-1'), '2'), null);
  for (const s of ['100.5', '101', '-5', '1e2', '50.1234567', '55,5', '']) assert.equal(judge(byId('maths-1'), s), null, s);
  assert.equal(judge(byId('art-read'), '0'), null);
});

test('the counts are kept under the day, the game and the cards in order: the phone\'s key', () => {
  assert.equal(gameKey(DAY, 'five', ['b-2', 'a-1']), '2026-10-18~five~a-1,b-2');
  assert.equal(gameKey(DAY, 'three', ['art-2', 'art-1']), '2026-10-18~three~art-1,art-2');
});

test('a play is today on the phone\'s clock, or yesterday there', () => {
  assert.ok(playableDay(DAY, 120, NOW));
  assert.ok(playableDay('2026-10-17', 120, NOW));
  assert.ok(!playableDay('2026-10-16', 120, NOW));
  assert.ok(!playableDay('2026-10-19', 120, NOW));
  // At half past eleven at night UTC it is tomorrow in Tokyo, still today in New York.
  const late = Date.parse('2026-10-18T23:30:00Z');
  assert.ok(playableDay('2026-10-19', 540, late));
  assert.ok(!playableDay('2026-10-19', -240, late));
  assert.ok(!playableDay('2026-02-30', 0, NOW));
});

test('the five: judged, scored, and named for its counts and the reader\'s mark', () => {
  const play = readPlay({ date: DAY, game: 'five', tz: 120, cards: said(FIVE, ['1', '1', '65', '1', '0']) }, bank, NOW);
  assert.ok(typeof play !== 'string', String(play));
  assert.equal(play.game, 'five');
  assert.equal(play.subject, null);
  assert.equal(play.score, 100 + 0 + 70 + 100 + 0);
  assert.deepEqual(play.cards.map((c) => c.id), FIVE.map((c) => c.id));
  assert.equal(play.key, gameKey(DAY, 'five', FIVE.map((c) => c.id)));
  assert.equal(play.mark, '2026-10-18~five');
  assert.deepEqual(tallyOf(play), {
    players: 1,
    scores: { '27': 1 },
    items: {
      'art-1': { n: 1, right: 1, picks: { '1': 1 } },
      'history-1': { n: 1, right: 0, picks: { '1': 1 } },
      'maths-1': { n: 1, right: 0, guesses: { '6': 1 }, sum: 65 },
      'science-1': { n: 1, right: 1, picks: { '1': 1 } },
      'space-1': { n: 1, right: 0, picks: { '0': 1 } },
    },
  });
});

test('a subject\'s three: its subject named in the mark; a guess of 100% in the last ten', () => {
  const play = readPlay({ date: DAY, game: 'three', tz: 120, cards: said(SCIENCE, ['1', '2', '100']) }, bank, NOW);
  assert.ok(typeof play !== 'string', String(play));
  assert.equal(play.subject, 'science');
  assert.equal(play.mark, '2026-10-18~three-science');
  assert.equal(play.score, 200);
  assert.deepEqual((tallyOf(play).items as Record<string, unknown>)['science-4'], { n: 1, right: 0, guesses: { '10': 1 }, sum: 100 });
  assert.deepEqual(tallyOf(play).scores, { '20': 1 });
});

test('a play that is not one is refused, saying why', () => {
  const five = said(FIVE, ['1', '1', '55', '1', '1']);
  const refused = (data: unknown) => {
    const out = readPlay(data, bank, NOW);
    assert.equal(typeof out, 'string', JSON.stringify(data));
  };
  refused({ date: DAY, game: 'six', cards: five });
  refused({ game: 'five', cards: five });
  refused({ date: '2026-10-16', game: 'five', cards: five });
  refused({ date: DAY, game: 'five', cards: five.slice(0, 4) });
  refused({ date: DAY, game: 'five', cards: [...five.slice(0, 4), five[0]] });
  // Two of one subject.
  refused({ date: DAY, game: 'five', cards: [...five.slice(0, 4), { id: 'art-2', said: '1' }] });
  refused({ date: DAY, game: 'three', cards: [...said(SCIENCE, ['1', '1', '28']).slice(0, 2), { id: 'art-2', said: '1' }] });
  refused({ date: DAY, game: 'five', cards: [...five.slice(0, 4), { id: 'nature-9', said: '1' }] });
  refused({ date: DAY, game: 'five', cards: [...five.slice(0, 4), { id: 'Space 1', said: '1' }] });
  refused({ date: DAY, game: 'five', cards: [...five.slice(0, 4), { id: 'space-1', said: '7' }] });
  refused({ date: DAY, game: 'five', cards: [...five.slice(0, 4), { id: 'space-1' }] });
  refused({ date: DAY, game: 'three', cards: [{ id: 'art-1', said: '1' }, { id: 'art-2', said: '1' }, { id: 'art-read', said: '1' }] });
  refused(null);
  // And a tz no clock has is no clock's: the day is UTC's.
  assert.equal(typeof readPlay({ date: DAY, game: 'five', tz: 9999, cards: five }, bank, NOW), 'object');
});
