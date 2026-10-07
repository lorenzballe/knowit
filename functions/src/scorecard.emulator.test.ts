// The scorecard's reads and writes, against the Firestore emulator.
//
// Skipped unless an emulator is up (FIRESTORE_EMULATOR_HOST), so the plain
// `npm test` stays a test of the thinking. To run it:
//
//   cd tool/rules && npx firebase emulators:exec --only firestore \
//     --project astuto-scorecard-test "node --test ../../functions/lib/scorecard.emulator.test.js"

import { test } from 'node:test';
import assert from 'node:assert/strict';

import { Bank, Card, graded, shiftDate } from './bank.js';
import { currentWithheld, daysToCount, readTotals, runScorecard } from './scorecard.js';

const up = !!process.env.FIRESTORE_EMULATOR_HOST;

test('a day is counted once, reports put a card in quarantine, and the dealer hears of it', { skip: !up && 'no emulator' }, async () => {
  const { initializeApp } = await import('firebase-admin/app');
  const { getFirestore, Timestamp } = await import('firebase-admin/firestore');
  initializeApp({ projectId: 'astuto-scorecard-test' });
  const db = getFirestore();

  const bank = Bank.bundled();
  const NOW = Date.UTC(2026, 9, 7, 4, 20);
  const day = daysToCount(NOW).at(-1) as string;
  const t = Date.parse(`${day}T09:00:00Z`);
  const card = bank.live.find((c) => c.kind === 'pickOne' && graded(c)) as Card;
  const other = bank.live.find((c) => c.kind === 'read') as Card;

  // Two readers here on the day, one who left before it.
  for (const [uid, lastSeen] of [['ana', t + 3_600_000], ['ben', t + 7_200_000], ['old', t - 10 * 86_400_000]] as const) {
    await db.collection('presence').doc(uid).set({ lastSeen, tz: 120, uid });
  }
  await db.doc(`readers/ana/activity/${day}`).set({
    ev: [
      { t, e: 'view', c: card.id },
      { t: t + 1, e: 'ans', c: card.id, ok: true, cf: 95, a: card.correct },
      { t: t + 2, e: 'like', c: card.id },
      { t: t + 3, e: 'view', c: other.id },
    ],
    n: 4,
  });
  await db.doc(`readers/ben/activity/${day}`).set({
    ev: [{ t, e: 'view', c: card.id }, { t: t + 1, e: 'ans', c: card.id, ok: false, cf: 80, a: 9 }],
    n: 2,
  });
  // The one who left has a day from before the week counted, and nothing since.
  await db.doc(`readers/old/activity/${shiftDate(day, -10)}`).set({ ev: [{ t: t - 10 * 86_400_000, e: 'view', c: card.id }], n: 1 });
  // Three readers say the other card is untrue; one only that it is confusing.
  for (const [uid, reason] of [['ana', 'fact'], ['ben', 'source'], ['cyd', 'fact'], ['dee', 'unclear']] as const) {
    await db.doc(`readers/${uid}/reports/${other.id}`).set({ card: other.id, reason, note: uid === 'ana' ? 'The date is 1912.' : '', at: Timestamp.fromMillis(NOW - 3_600_000) });
  }

  const first = await runScorecard(db, bank, NOW);
  assert.ok(first.days.includes(day));
  assert.equal(first.readers, 2);
  const totals = await readTotals(db);
  const c = totals.get(card.id);
  assert.ok(c);
  assert.equal(c.tally.readers, 2);
  assert.equal(c.tally.answers, 2);
  assert.equal(c.tally.right, 1);
  assert.equal(c.tally.sureWrong, 1);
  assert.equal(c.tally.likes, 1);
  assert.equal(c.picks[card.correct as number], 1);

  // Run again: nothing is counted twice.
  const again = await runScorecard(db, bank, NOW);
  assert.deepEqual(again.days, []);
  assert.equal((await readTotals(db)).get(card.id)?.tally.answers, 2);

  const latest = (await db.doc('quality/latest').get()).data() as Record<string, unknown>;
  assert.deepEqual(latest.quarantined, [other.id]);
  assert.deepEqual((latest.reports as Record<string, unknown>)[other.id], { fact: 2, source: 1, unclear: 1 });
  assert.ok(!JSON.stringify(latest).includes('1912'), 'no note in what the tools read');
  const notes = (await db.doc('quality/notes').get()).data() as { cards: Record<string, { note: string }[]> };
  assert.deepEqual(notes.cards[other.id].map((n) => n.note), ['The date is 1912.']);

  const withheld = await currentWithheld(db, NOW);
  assert.ok(withheld.has(other.id));
});
