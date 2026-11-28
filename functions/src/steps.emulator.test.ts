// The first run's steps counted against the Firestore emulator (steps.ts):
// every step added to its own day's total, the totals of every phone in one
// number, and nothing kept beside the numbers.
//
// Skipped unless an emulator is up (FIRESTORE_EMULATOR_HOST), so the plain
// `npm test` stays a test of the thinking. To run it:
//
//   cd tool/rules && npx firebase emulators:exec --only firestore \
//     --project astuto-steps-test "node --test ../../functions/lib/steps.emulator.test.js"

import { test } from 'node:test';
import assert from 'node:assert/strict';

import { countStep, readStep, totalsOf, type Taken } from './steps.js';

const up = !!process.env.FIRESTORE_EMULATOR_HOST;

const NOW = Date.parse('2026-11-28T11:00:00Z');

function taken(step: string, day = '2026-11-28'): Taken {
  const out = readStep({ step, day }, NOW);
  assert.ok(typeof out !== 'string', String(out));
  return out;
}

test('every step adds one to its own day, and the day holds numbers and nothing else', { skip: !up && 'no emulator' }, async () => {
  const { initializeApp } = await import('firebase-admin/app');
  const { getFirestore } = await import('firebase-admin/firestore');
  initializeApp({ projectId: 'astuto-steps-test' });
  const db = getFirestore();

  // Three phones open the app; two finish the first run; one its first day.
  for (let i = 0; i < 3; i++) await countStep(db, taken('first_open'));
  for (let i = 0; i < 2; i++) await countStep(db, taken('first_run_done'));
  await countStep(db, taken('first_day_done'));
  // One phone from yesterday comes back.
  await countStep(db, taken('next_day'));
  // A step taken before midnight that arrives after it goes to its own day.
  await countStep(db, taken('first_open', '2026-11-27'));

  const today = await db.collection('steps').doc('2026-11-28').get();
  assert.deepEqual(totalsOf(today.data()), { first_open: 3, first_run_done: 2, first_day_done: 1, next_day: 1 });
  assert.deepEqual(Object.keys(today.data() ?? {}).sort(), ['first_day_done', 'first_open', 'first_run_done', 'next_day']);

  const yesterday = await db.collection('steps').doc('2026-11-27').get();
  assert.deepEqual(yesterday.data(), { first_open: 1 });

  // Nothing else was written anywhere.
  const all = await db.collection('steps').get();
  assert.deepEqual(all.docs.map((d) => d.id).sort(), ['2026-11-27', '2026-11-28']);
});
