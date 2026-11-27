// Invita un amico against the Firestore emulator (invite.ts): the code made
// once in a transaction, a friend's code taken and its week waiting on the
// first day as the backup says it, the two weeks planned in one transaction
// and given through a RevenueCat that records, and all of it gone with the
// account. invite.test.ts holds the rules themselves, without a database.
//
// Skipped unless an emulator is up (FIRESTORE_EMULATOR_HOST), so the plain
// `npm test` stays a test of the thinking. To run it:
//
//   cd tool/rules && npx firebase emulators:exec --only firestore \
//     --project astuto-invite-test "node --test ../../functions/lib/invite.emulator.test.js"

import { test } from 'node:test';
import assert from 'node:assert/strict';

import { Held, Reader, Store, WEEK_MS, backupHasADay, giveCode, inviteState, redeem } from './invite.js';
import { forgetReader } from './serve.js';

const up = !!process.env.FIRESTORE_EMULATOR_HOST;

const DAY = 86_400_000;
const NOW = Date.parse('2026-11-27T18:00:00Z');

test('a code made once, a friend\'s week given after the first day, and all of it gone with the account', { skip: !up && 'no emulator' }, async () => {
  const { initializeApp } = await import('firebase-admin/app');
  const { getFirestore } = await import('firebase-admin/firestore');
  initializeApp({ projectId: 'astuto-invite-test' });
  const db = getFirestore();

  const grants: [string, number][] = [];
  const store: Store = {
    held: async (): Promise<Held> => ({ ever: false, until: null, lifetime: false }),
    grant: async (uid, until) => {
      grants.push([uid, until]);
    },
  };
  const reader: Reader = {
    madeAt: async (uid) => (uid === 'ana' ? NOW - 200 * DAY : NOW - DAY),
    readADay: (uid) => backupHasADay(db, uid),
  };

  // Two asks at once make one code.
  const [one, two] = await Promise.all([giveCode(db, 'ana', NOW), giveCode(db, 'ana', NOW)]);
  assert.equal(one.code, two.code);
  const code = one.code!;
  assert.deepEqual((await db.doc(`inviteCodes/${code}`).get()).data(), { uid: 'ana', at: NOW });

  // Ben's backup, before he has finished a day, and the code taken.
  await db.doc('readers/ben').set({ completedDates: [], streak: 0, seenIds: ['x'] });
  assert.equal(await backupHasADay(db, 'ben'), false);
  assert.equal(await backupHasADay(db, 'nobody'), false);
  assert.deepEqual(await redeem(db, store, 'ben', code, NOW, reader), { state: 'waiting' });
  assert.equal(grants.length, 0);

  // The day done, as the backup says: both weeks given, once.
  await db.doc('readers/ben').set({ completedDates: ['2026-11-27'] }, { merge: true });
  assert.equal(await backupHasADay(db, 'ben'), true);
  const after = await inviteState(db, store, 'ben', NOW + 1000, reader);
  assert.equal(after.granted, true);
  assert.equal(after.redeem, 'granted');
  assert.deepEqual(grants, [['ben', NOW + 1000 + WEEK_MS], ['ana', NOW + 1000 + WEEK_MS]]);
  assert.equal((await inviteState(db, store, 'ben', NOW + 2000, reader)).granted, undefined);
  assert.equal(grants.length, 2);
  const ana = await inviteState(db, store, 'ana', NOW + 2000, reader);
  assert.deepEqual({ code: ana.code, weeks: ana.weeks, friends: ana.friends, redeem: ana.redeem }, { code, weeks: 1, friends: 1, redeem: 'closed' });
  // The friend's record names no inviter.
  assert.equal((await db.doc('invited/ben').get()).get('inviter'), undefined);

  // Gone with the account, as the phone's delete of the backup sets off.
  await forgetReader(db, 'ana');
  assert.equal((await db.doc('invites/ana').get()).exists, false);
  assert.equal((await db.doc(`inviteCodes/${code}`).get()).exists, false);
  await forgetReader(db, 'ben');
  assert.equal((await db.doc('invited/ben').get()).exists, false);
  assert.equal((await db.doc('invites/ben').get()).exists, false);
  assert.equal((await db.doc('readers/ben').get()).exists, false);
});
