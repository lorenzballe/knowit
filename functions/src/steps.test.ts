import assert from 'node:assert/strict';
import { test } from 'node:test';

import { STEPS, countableDay, readStep, totalsOf } from './steps.js';

// Noon in Rome on a Saturday: 28 November everywhere from London to
// Kiribati, still the 27th from the Azores westward.
const NOW = Date.parse('2026-11-28T11:00:00Z');

test('the four steps are the only names counted, in the order a reader takes them', () => {
  assert.deepEqual([...STEPS], ['first_open', 'first_run_done', 'first_day_done', 'next_day']);
  for (const step of STEPS) {
    assert.deepEqual(readStep({ step, day: '2026-11-28' }, NOW), { step, day: '2026-11-28' });
  }
  for (const step of ['FIRST_OPEN', 'first open', 'paywall_shown', '', 7, null, undefined, ['first_open'], { step: 'first_open' }]) {
    const out = readStep({ step, day: '2026-11-28' }, NOW);
    assert.equal(typeof out, 'string', `${JSON.stringify(step)} is not a step`);
  }
});

test('a step is counted on a day that is today somewhere, or yesterday there', () => {
  // Today in Rome, and in Kiribati, which is a day ahead of most of the world
  // from mid-morning UTC.
  assert.equal(countableDay('2026-11-28', NOW), true);
  assert.equal(countableDay('2026-11-29', NOW), true);
  // Yesterday on the clocks still on the 27th, and the 27th itself.
  assert.equal(countableDay('2026-11-27', NOW), true);
  assert.equal(countableDay('2026-11-26', NOW), true);
  // Not before, not after.
  assert.equal(countableDay('2026-11-25', NOW), false);
  assert.equal(countableDay('2026-11-30', NOW), false);
  // A day that does not exist, or is not a day.
  for (const day of ['2026-11-31', '2026-02-29', '28/11/2026', '2026-11-28T00:00', '', 'today']) {
    assert.equal(countableDay(day, NOW), false, day);
  }
  assert.equal(typeof readStep({ step: 'first_open', day: '2026-11-20' }, NOW), 'string');
  assert.equal(typeof readStep({ step: 'first_open' }, NOW), 'string');
  assert.equal(typeof readStep(null, NOW), 'string');
  assert.equal(typeof readStep('first_open', NOW), 'string');
});

test('nothing else in the request is read, so nothing else can be kept', () => {
  const out = readStep(
    { step: 'next_day', day: '2026-11-28', uid: 'reader-1', device: 'abc', ip: '10.0.0.1', tz: 60, at: NOW },
    NOW,
  );
  assert.deepEqual(out, { step: 'next_day', day: '2026-11-28' });
  assert.deepEqual(Object.keys(out as object).sort(), ['day', 'step']);
});

test('a day\'s totals read as every step, nought where nothing was counted', () => {
  assert.deepEqual(totalsOf(undefined), { first_open: 0, first_run_done: 0, first_day_done: 0, next_day: 0 });
  assert.deepEqual(totalsOf({ first_open: 12, first_day_done: 4, stray: 9, next_day: -2 }), {
    first_open: 12,
    first_run_done: 0,
    first_day_done: 4,
    next_day: 0,
  });
});
