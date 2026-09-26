import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import firebase from 'firebase/compat/app';
import 'firebase/compat/firestore';

const inc = (n) => firebase.firestore.FieldValue.increment(n);
const day = (offsetDays) => {
  const d = new Date(Date.now() + offsetDays * 86400000);
  return d.toISOString().slice(0, 10);
};

const env = await initializeTestEnvironment({
  projectId: 'astuto-rules-test',
  firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'), host: '127.0.0.1', port: 8080 },
});

let passed = 0;
async function check(name, fn) {
  await env.clearFirestore();
  try { await fn(); passed++; console.log('ok   ', name); }
  catch (e) { console.log('FAIL ', name, '\n     ', e.message); process.exitCode = 1; }
}

const reader = () => env.authenticatedContext('anon-reader').firestore();
const stranger = () => env.unauthenticatedContext().firestore();
const today = day(0);

await check('a signed-in reader adds one to a card today', async () => {
  const db = reader();
  await assertSucceeds(db.doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
  await assertSucceeds(db.doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
  await assertSucceeds(db.doc(`tallies/${today}`).set({ k: 'thinking-d14', n: { 'thinking-d14': inc(1) } }, { merge: true }));
  const snap = await db.doc(`tallies/${today}`).get();
  assert.deepEqual(snap.data().n, { 'science-1': 2, 'thinking-d14': 1 });
});

await check('and reads the days', async () => {
  await reader().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true });
  await assertSucceeds(reader().collection('tallies').where(firebase.firestore.FieldPath.documentId(), 'in', [today, day(-1)]).get());
});

await check('nobody signed out reads or adds', async () => {
  await assertFails(stranger().doc(`tallies/${today}`).get());
  await assertFails(stranger().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
});

await check('never more than one at a time', async () => {
  await assertFails(reader().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': inc(2) } }, { merge: true }));
  await reader().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true });
  await assertFails(reader().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': inc(5) } }, { merge: true }));
  await assertFails(reader().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': 40 } }, { merge: true }));
});

await check('never two cards at once, nor a card other than k', async () => {
  await assertFails(reader().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': inc(1), 'science-2': inc(1) } }, { merge: true }));
  await assertFails(reader().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-2': inc(1) } }, { merge: true }));
});

await check('never anything taken back', async () => {
  await reader().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true });
  await reader().doc(`tallies/${today}`).set({ k: 'science-2', n: { 'science-2': inc(1) } }, { merge: true });
  await assertFails(reader().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': inc(-1) } }, { merge: true }));
  await assertFails(reader().doc(`tallies/${today}`).update({ k: 'science-1', 'n.science-2': firebase.firestore.FieldValue.delete() }));
  await assertFails(reader().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': 1 } }));
  await assertFails(reader().doc(`tallies/${today}`).delete());
});

await check('nothing else on the document', async () => {
  await assertFails(reader().doc(`tallies/${today}`).set({ k: 'science-1', n: { 'science-1': inc(1) }, who: 'me' }, { merge: true }));
});

await check('only a card id as the bank writes one', async () => {
  await assertFails(reader().doc(`tallies/${today}`).set({ k: 'Science 1', n: { 'Science 1': inc(1) } }, { merge: true }));
  await assertFails(reader().doc(`tallies/${today}`).set({ k: 7, n: { '7': inc(1) } }, { merge: true }));
});

await check('only a day that is today on some clock', async () => {
  await assertSucceeds(reader().doc(`tallies/${day(-1)}`).set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
  await assertSucceeds(reader().doc(`tallies/${day(1)}`).set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
  await assertFails(reader().doc(`tallies/${day(-3)}`).set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
  await assertFails(reader().doc(`tallies/${day(-10)}`).set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
  await assertFails(reader().doc(`tallies/${day(4)}`).set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
  await assertFails(reader().doc('tallies/yesterday').set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
  await assertFails(reader().doc('tallies/2026-13-40').set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
});

await check('the rest of the rules still stand', async () => {
  await assertSucceeds(env.authenticatedContext('alice').firestore().doc('readers/alice').set({ a: 1 }));
  await assertFails(env.authenticatedContext('bob').firestore().doc('readers/alice').get());
  await assertSucceeds(env.authenticatedContext('alice').firestore().doc('boards/ABCDEF').set({ uid: 'alice' }));
  await assertSucceeds(env.authenticatedContext('bob').firestore().doc('boards/ABCDEF').get());
  await assertFails(env.authenticatedContext('alice').firestore().doc('elsewhere/x').set({ a: 1 }));
});

console.log(`\n${passed} passed`);
await env.cleanup();
