// The day's games counted against the Firestore emulator (daily.ts): a play
// counted once whatever the phone sends after it, every reader added to the
// same counts, the counts in the shape the phone reads, and a reader's marks
// gone once they stop nothing.
//
// Skipped unless an emulator is up (FIRESTORE_EMULATOR_HOST), so the plain
// `npm test` stays a test of the thinking. To run it:
//
//   cd tool/rules && npx firebase emulators:exec --only firestore \
//     --project astuto-daily-test "node --test ../../functions/lib/daily.emulator.test.js"

import { test } from 'node:test';
import assert from 'node:assert/strict';

import { Bank, Card } from './bank.js';
import { Play, countPlay, gameKey, readPlay } from './daily.js';
import { pruneReader } from './serve.js';

const up = !!process.env.FIRESTORE_EMULATOR_HOST;

const NOW = Date.parse('2026-10-18T10:00:00Z');
const DAY = '2026-10-18';

const pick = (id: string, topic: string): Card =>
  ({ id, topic, kind: 'pickOne', difficulty: 'easy', principle: 'none', question: '?', answer: '.', options: ['a', 'b', 'c'], correct: 1 });
const share = (id: string, topic: string, value: number): Card =>
  ({ id, topic, kind: 'number', difficulty: 'easy', principle: 'none', question: '?', answer: '.', value, unit: '%' });

const FIVE = [pick('art-1', 'art'), pick('history-1', 'history'), share('maths-1', 'maths', 55), pick('science-1', 'science'), pick('space-1', 'space')];
const THREE = [pick('science-2', 'science'), pick('science-3', 'science'), share('science-4', 'science', 28)];
const bank = new Bank({ version: 1, cards: [...FIVE, ...THREE, pick('nature-1', 'nature')] });

function played(game: 'five' | 'three', cards: Card[], said: string[]): Play {
  const play = readPlay({ date: DAY, game, tz: 120, cards: cards.map((c, i) => ({ id: c.id, said: said[i] })) }, bank, NOW);
  assert.ok(typeof play !== 'string', String(play));
  return play;
}

test('a play is counted once, every reader into the same counts, and nothing about who', { skip: !up && 'no emulator' }, async () => {
  const { initializeApp } = await import('firebase-admin/app');
  const { getFirestore } = await import('firebase-admin/firestore');
  initializeApp({ projectId: 'astuto-daily-test' });
  const db = getFirestore();

  // Ana: three right picks, the share ten points off, one pick wrong.
  const ana = played('five', FIVE, ['1', '1', '65', '1', '0']);
  const first = await countPlay(db, 'ana', ana);
  assert.equal(first.counted, true);
  assert.deepEqual(first.counts, {
    players: 1,
    scores: { '37': 1 },
    items: {
      'art-1': { n: 1, right: 1, picks: { '1': 1 } },
      'history-1': { n: 1, right: 1, picks: { '1': 1 } },
      'maths-1': { n: 1, right: 0, guesses: { '6': 1 }, sum: 65 },
      'science-1': { n: 1, right: 1, picks: { '1': 1 } },
      'space-1': { n: 1, right: 0, picks: { '0': 1 } },
    },
  });

  // Sent again, or again with other answers: not counted, the counts as they were.
  for (const again of [ana, played('five', FIVE, ['1', '1', '55', '1', '1'])]) {
    const out = await countPlay(db, 'ana', again);
    assert.equal(out.counted, false);
    assert.deepEqual(out.counts, first.counts);
  }

  // Ben: everything right. Added to Ana's, option by option and ten by ten.
  const ben = await countPlay(db, 'ben', played('five', FIVE, ['1', '1', '55', '1', '1']));
  assert.equal(ben.counted, true);
  assert.equal(ben.counts?.players, 2);
  assert.deepEqual(ben.counts?.scores, { '37': 1, '50': 1 });
  assert.deepEqual(ben.counts?.items['maths-1'], { n: 2, right: 1, guesses: { '6': 1, '5': 1 }, sum: 120 });
  assert.deepEqual(ben.counts?.items['space-1'], { n: 2, right: 1, picks: { '0': 1, '1': 1 } });

  // A subject's three is another game, with counts of its own; so is a five of other cards.
  const three = await countPlay(db, 'ben', played('three', THREE, ['1', '0', '28']));
  assert.equal(three.counted, true);
  assert.equal(three.counts?.players, 1);
  const other = [...FIVE.slice(0, 3), pick('nature-1', 'nature'), FIVE[4]];
  const cyd = await countPlay(db, 'cyd', played('five', other, ['1', '1', '55', '1', '1']));
  assert.equal(cyd.counts?.players, 1);

  // The document: the day, the game, its cards in order and the counts; no reader in it.
  const doc = (await db.collection('daily').doc(gameKey(DAY, 'five', FIVE.map((c) => c.id))).get()).data() as Record<string, unknown>;
  assert.equal(doc.day, DAY);
  assert.equal(doc.game, 'five');
  assert.equal(doc.subject, undefined);
  assert.deepEqual(doc.cards, FIVE.map((c) => c.id).sort());
  assert.ok(!/ana|ben|cyd/.test(JSON.stringify(doc)));
  assert.equal((await db.doc(`daily/${gameKey(DAY, 'three', THREE.map((c) => c.id))}`).get()).get('subject'), 'science');

  // The marks: under the reader, by day and game; gone once the day is past playing.
  const marks = await db.collection('readers').doc('ben').collection('daily').get();
  assert.deepEqual(marks.docs.map((d) => d.id).sort(), ['2026-10-18~five', '2026-10-18~three-science']);
  await db.doc('readers/ben/daily/2026-10-22~five').set({ at: 1 });
  await pruneReader(db, 'ben', Date.parse('2026-10-22T10:00:00Z'));
  const left = await db.collection('readers').doc('ben').collection('daily').get();
  assert.deepEqual(left.docs.map((d) => d.id), ['2026-10-22~five']);
});
