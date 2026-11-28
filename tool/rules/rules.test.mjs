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

await check('a total: one at a time, to one card, in its own shard', async () => {
  const db = reader();
  await assertSucceeds(db.doc('totals/science').set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
  await assertSucceeds(db.doc('totals/science').set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
  await assertSucceeds(db.doc('totals/weird_facts').set({ k: 'weird_facts-names-1', n: { 'weird_facts-names-1': inc(1) } }, { merge: true }));
  assert.deepEqual((await db.doc('totals/science').get()).data().n, { 'science-1': 2 });
  await assertSucceeds(db.collection('totals').get());
  await assertFails(db.doc('totals/space').set({ k: 'science-1', n: { 'science-1': inc(1) } }, { merge: true }));
  await assertFails(db.doc('totals/science').set({ k: 'science-1', n: { 'science-1': inc(3) } }, { merge: true }));
  await assertFails(db.doc('totals/science').set({ k: 'science-1', n: { 'science-1': inc(1), 'science-2': inc(1) } }, { merge: true }));
  await assertFails(db.doc('totals/science').set({ k: 'science-1', n: { 'science-1': inc(-1) } }, { merge: true }));
  await assertFails(db.doc('totals/science').delete());
  await assertFails(stranger().doc('totals/science').get());
});

await check('the trace: the reader writes and reads their own days, nobody else', async () => {
  const me = env.authenticatedContext('alice').firestore();
  const ev = [{ t: 1, e: 'view', c: 'science-1' }];
  await assertSucceeds(me.doc('readers/alice/activity/2026-10-03').set({ ev, n: 1, at: new Date() }, { merge: true }));
  await assertSucceeds(me.doc('readers/alice/activity/2026-10-03').get());
  await assertFails(env.authenticatedContext('bob').firestore().doc('readers/alice/activity/2026-10-03').get());
  await assertFails(env.authenticatedContext('bob').firestore().doc('readers/alice/activity/2026-10-03').set({ ev, n: 1, at: new Date() }));
  await assertFails(me.doc('readers/alice/activity/notaday').set({ ev, n: 1, at: new Date() }));
  await assertFails(me.doc('readers/alice/activity/2026-10-03').set({ ev, n: 1, at: new Date(), who: 'x' }));
  await assertSucceeds(me.doc('presence/alice').set({ uid: 'alice', tz: 120, lastSeen: 1, at: new Date() }));
  await assertFails(env.authenticatedContext('bob').firestore().doc('presence/alice').get());
});

await check('what the server dealt is read by its reader and written by nobody', async () => {
  const me = env.authenticatedContext('alice').firestore();
  await assertFails(me.doc('readers/alice/days/2026-10-04').set({ cards: [] }));
  await assertFails(me.doc('readers/alice/profile/current').set({ a: 1 }));
  await assertFails(me.doc('readers/alice/explore/current').set({ a: 1 }));
  await assertFails(me.doc('explore/latest').set({ a: 1 }));
  await env.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('readers/alice/days/2026-10-04').set({ cards: [] });
    await ctx.firestore().doc('explore/latest').set({ shelves: [] });
  });
  await assertSucceeds(me.doc('readers/alice/days/2026-10-04').get());
  await assertFails(env.authenticatedContext('bob').firestore().doc('readers/alice/days/2026-10-04').get());
  await assertSucceeds(me.doc('explore/latest').get());
  await assertSucceeds(env.authenticatedContext('bob').firestore().doc('explore/latest').get());
  await assertFails(stranger().doc('explore/latest').get());
});

const now = () => firebase.firestore.FieldValue.serverTimestamp();
const report = (extra = {}) => ({ card: 'science-1', reason: 'fact', note: 'The date is wrong.', locale: 'it', bank: 42, os: 'iOS', at: now(), ...extra });

await check('a reader reports a card, says it again, and reads it back', async () => {
  const me = env.authenticatedContext('alice').firestore();
  await assertSucceeds(me.doc('readers/alice/reports/science-1').set(report()));
  await assertSucceeds(me.doc('readers/alice/reports/science-1').set(report({ reason: 'answer', note: '' })));
  await assertSucceeds(me.doc('readers/alice/reports/thinking-d14').set({ card: 'thinking-d14', reason: 'other', note: '', at: now() }));
  await assertSucceeds(me.doc('readers/alice/reports/science-1').get());
  await assertSucceeds(me.doc('readers/alice/reports/science-1').delete());
});

await check('nobody else reads or writes a reader\'s reports', async () => {
  await env.authenticatedContext('alice').firestore().doc('readers/alice/reports/science-1').set(report());
  await assertFails(env.authenticatedContext('bob').firestore().doc('readers/alice/reports/science-1').get());
  await assertFails(env.authenticatedContext('bob').firestore().doc('readers/alice/reports/science-1').set(report()));
  await assertFails(stranger().doc('readers/alice/reports/science-1').get());
});

await check('a report is a card, a reason from the list and a short note', async () => {
  const me = env.authenticatedContext('alice').firestore();
  await assertFails(me.doc('readers/alice/reports/science-1').set(report({ card: 'science-2' })));
  await assertFails(me.doc('readers/alice/reports/science-1').set(report({ reason: 'boring' })));
  await assertFails(me.doc('readers/alice/reports/science-1').set(report({ note: 'x'.repeat(501) })));
  await assertSucceeds(me.doc('readers/alice/reports/science-1').set(report({ note: 'x'.repeat(500) })));
  await assertFails(me.doc('readers/alice/reports/science-1').set(report({ note: 7 })));
  await assertFails(me.doc('readers/alice/reports/science-1').set(report({ email: 'a@b.c' })));
  await assertFails(me.doc('readers/alice/reports/science-1').set(report({ at: new Date(2020, 0, 1) })));
  await assertFails(me.doc('readers/alice/reports/science-1').set(report({ bank: 'forty' })));
  await assertFails(me.doc('readers/alice/reports/Science%201').set(report({ card: 'Science%201' })));
});

await check('the day\'s games: counts every signed-in phone reads and no phone writes', async () => {
  const key = `daily/${today}~five~art-1,history-1,maths-1,science-1,space-1`;
  await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc(key).set({ players: 3, scores: { '27': 3 }, items: {} }));
  await assertSucceeds(reader().doc(key).get());
  await assertFails(stranger().doc(key).get());
  await assertFails(reader().doc(key).set({ players: inc(1), scores: { '50': inc(1) } }, { merge: true }));
  await assertFails(reader().doc(key).update({ players: 4 }));
  await assertFails(reader().doc(key).delete());
  await assertFails(reader().doc(`daily/${today}~three~art-1,art-2,art-3`).set({ players: 1 }));
});

await check('the marks of the games a reader played are the server\'s alone, even to their reader', async () => {
  const mark = `readers/anon-reader/daily/${today}~five`;
  await assertFails(reader().doc(mark).set({ at: 1 }));
  await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc(mark).set({ at: 1 }));
  await assertFails(reader().doc(mark).get());
  await assertFails(reader().doc(mark).delete());
  await assertFails(reader().collection('readers/anon-reader/daily').get());
});

await check('what a reader heard read aloud, and the clips, are the server\'s alone', async () => {
  // The day's free card is what stops a second one: a phone that could
  // write it could hear every card free.
  const heard = `readers/anon-reader/listen/${today}`;
  await assertFails(reader().doc(heard).set({ free: 'science-1', cards: ['science-1'] }));
  await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc(heard).set({ free: 'science-1', cards: ['science-1'] }));
  await assertFails(reader().doc(heard).get());
  await assertFails(reader().doc(heard).delete());
  await assertFails(reader().doc('listeners/anon-reader').set({ at: 1, plus: true }));
  await assertFails(reader().doc(`listenSpend/${today}`).set({ chars: 0 }));
  await assertFails(reader().doc(`listenSpend/${today}`).get());
  await assertFails(reader().doc('listen/0a1b').set({ url: 'https://example.com/clip.mp3' }));
  await assertFails(reader().doc('listen/0a1b').get());
});

await check('invitations are the server\'s alone: no phone reads or writes a code, a week or a friend\'s, its own included', async () => {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().doc('invites/alice').set({ code: 'K7MQ2P', at: 1, weeks: [2], friends: 1, until: 3 });
    await ctx.firestore().doc('inviteCodes/K7MQ2P').set({ uid: 'alice', at: 1 });
    await ctx.firestore().doc('invited/bob').set({ code: 'K7MQ2P', at: 2, state: 'waiting' });
  });
  const alice = env.authenticatedContext('alice').firestore();
  const bob = env.authenticatedContext('bob').firestore();
  // Not one's own side, not one's own code, not the code one came with.
  await assertFails(alice.doc('invites/alice').get());
  await assertFails(alice.doc('inviteCodes/K7MQ2P').get());
  await assertFails(bob.doc('invited/bob').get());
  await assertFails(bob.doc('inviteCodes/K7MQ2P').get());
  await assertFails(bob.collection('inviteCodes').get());
  await assertFails(bob.collection('invites').where('code', '==', 'K7MQ2P').get());
  await assertFails(stranger().doc('inviteCodes/K7MQ2P').get());
  // Nor written: a week given to oneself, a code taken, a use undone.
  await assertFails(alice.doc('invites/alice').set({ weeks: [] }, { merge: true }));
  await assertFails(alice.doc('invites/alice').update({ until: 9e12 }));
  await assertFails(bob.doc('inviteCodes/BBBBBB').set({ uid: 'bob', at: 1 }));
  await assertFails(bob.doc('invited/bob').delete());
  await assertFails(bob.doc('invited/bob').set({ code: 'K7MQ2P', at: 2, state: 'granted' }));
  await assertFails(env.authenticatedContext('carl').firestore().doc('invited/carl').set({ code: 'K7MQ2P', at: 2, state: 'waiting' }));
});

// The list for the iPhone (site/assets/notify.js): the site has no sign-in,
// so a stranger adds to it, and the one place anyone at all can write is
// held to exactly what the page sends.
const listed = (extra = {}) => ({ email: 'reader@example.com', lang: 'it', at: now(), ...extra });
const listId = 'Ab3dEf6hIj9kLm2nOp5q';

await check('anyone, signed in or not, joins the iPhone list once, with an address, a language and the moment', async () => {
  await assertSucceeds(stranger().doc(`waitlist/${listId}`).set(listed()));
  await assertSucceeds(stranger().doc('waitlist/Zz0aaaaaaaaaaaaaaaaa').set(listed({ email: 'x@y.co', lang: 'en' })));
  await assertSucceeds(reader().doc('waitlist/Qq1aaaaaaaaaaaaaaaaa').set(listed()));
  await assertSucceeds(stranger().doc('waitlist/Ww2aaaaaaaaaaaaaaaaa').set(listed({ email: 'a'.repeat(242) + '@example.com' })));
});

await check('and nobody reads the list, not even what they wrote', async () => {
  await stranger().doc(`waitlist/${listId}`).set(listed());
  await assertFails(stranger().doc(`waitlist/${listId}`).get());
  await assertFails(stranger().collection('waitlist').get());
  await assertFails(reader().doc(`waitlist/${listId}`).get());
  await assertFails(reader().collection('waitlist').where('email', '==', 'reader@example.com').get());
});

await check('nor changes or takes away a name on it', async () => {
  await stranger().doc(`waitlist/${listId}`).set(listed());
  await assertFails(stranger().doc(`waitlist/${listId}`).set(listed({ email: 'other@example.com' })));
  await assertFails(stranger().doc(`waitlist/${listId}`).update({ lang: 'en' }));
  await assertFails(stranger().doc(`waitlist/${listId}`).delete());
  await assertFails(reader().doc(`waitlist/${listId}`).delete());
});

await check('only an email\'s shape, never anything else beside it', async () => {
  const db = stranger();
  await assertFails(db.doc(`waitlist/${listId}`).set(listed({ email: 'not an address' })));
  await assertFails(db.doc(`waitlist/${listId}`).set(listed({ email: 'reader@example' })));
  await assertFails(db.doc(`waitlist/${listId}`).set(listed({ email: 'reader @example.com' })));
  await assertFails(db.doc(`waitlist/${listId}`).set(listed({ email: '@example.com' })));
  await assertFails(db.doc(`waitlist/${listId}`).set(listed({ email: 'a'.repeat(243) + '@example.com' })));
  await assertFails(db.doc(`waitlist/${listId}`).set(listed({ email: 7 })));
  await assertFails(db.doc(`waitlist/${listId}`).set(listed({ lang: 'Italiano' })));
  await assertFails(db.doc(`waitlist/${listId}`).set(listed({ lang: 3 })));
  await assertFails(db.doc(`waitlist/${listId}`).set(listed({ at: new Date(2026, 0, 1) })));
  await assertFails(db.doc(`waitlist/${listId}`).set(listed({ name: 'Lorenzo' })));
  await assertFails(db.doc(`waitlist/${listId}`).set({ email: 'reader@example.com', lang: 'it' }));
  await assertFails(db.doc(`waitlist/${listId}`).set({ email: 'reader@example.com', at: now() }));
  await assertFails(db.doc('waitlist/short').set(listed()));
  await assertFails(db.doc('waitlist/Ab3dEf6hIj9kLm2nOp5q-').set(listed()));
  await assertFails(db.doc('waitlist/reader@example.com').set(listed()));
});

await check('the rest of the rules still stand', async () => {
  await assertSucceeds(env.authenticatedContext('alice').firestore().doc('readers/alice').set({ a: 1 }));
  await assertFails(env.authenticatedContext('bob').firestore().doc('readers/alice').get());
  await assertSucceeds(env.authenticatedContext('alice').firestore().doc('boards/ABCDEF').set({ uid: 'alice' }));
  // Friends are gone: a board is its owner's alone.
  await assertSucceeds(env.authenticatedContext('alice').firestore().doc('boards/ABCDEF').get());
  await assertFails(env.authenticatedContext('bob').firestore().doc('boards/ABCDEF').get());
  await assertFails(env.authenticatedContext('alice').firestore().doc('elsewhere/x').set({ a: 1 }));
});

console.log(`\n${passed} passed`);
await env.cleanup();
