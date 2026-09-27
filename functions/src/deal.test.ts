import { test } from 'node:test';
import assert from 'node:assert/strict';

import { Bank, asks, graded, editionOf, localDate, localHour, shiftDate } from './bank.js';
import { keyed, unit } from './rng.js';
import { buildProfile, readOnboarding, readTrace, weightsOn, dayNumberOf, Event, Snapshot, TASTE_LEAN } from './profile.js';
import { arrangeDay, commonOfEdition, dealDay, questionOfEdition, OWN_WELCOME, OWN_FREE, PILLS_PER_DAY, WELCOME_DAYS } from './deal.js';
import { ALL_TIME_SEED, buildGlobalExplore, buildPersonalExplore, pickedCards, popularity, topList } from './explore.js';
import { search } from './search.js';
import { askableDate, datesToPrepare } from './serve.js';

const bank = Bank.bundled();
const NOW = Date.UTC(2026, 9, 3, 9, 30);
const DAY = '2026-10-03';

function even(at = 1): Record<string, number> {
  return Object.fromEntries(Object.keys(bank.live.reduce((m, c) => ({ ...m, [c.topic]: 1 }), {})).filter((t) => t !== 'thinking').map((t) => [t, at]));
}

function profileOf(snapshot: Snapshot, events: Event[] = [], plus = false) {
  const activity = new Map<string, Event[]>();
  for (const e of events) {
    const day = new Date(e.t).toISOString().slice(0, 10);
    activity.set(day, [...(activity.get(day) ?? []), e]);
  }
  return buildProfile(snapshot, activity, { tz: 120, plus }, bank, NOW);
}

// ── The same numbers as the phone ────────────────────────────────────────

test('the hashes are the phone\'s, bit for bit', () => {
  // Reference values printed by lib/sync/tally.dart and pills_repository.dart.
  assert.equal(unit('seed:science-1'), 0.9956654456909746);
  assert.equal(unit('2026-10:space-2'), 0.31467695790342987);
  assert.equal(unit('2026-10-03:space-2'), 0.5869718969333917);
  assert.equal(unit('seed:thinking-4'), 0.10241766786202788);
  assert.ok(Math.abs(popularity('science-1') - 4.481920005585856) < 1e-12);
  assert.ok(Math.abs(popularity('weird_facts-local-bans-4') - 4.751586858388467) < 1e-12);
  assert.equal(keyed('astuto-all-time') >= 0, true);
});

test('the shelves that turn over are the phone\'s, card for card', () => {
  assert.deepEqual(pickedCards(bank, DAY, 6).map((c) => c.id), [
    'space-supermassive-ones-1', 'sport-altitude-5', 'economics-interest-4', 'weird_facts-tallest-5', 'technology-factories-5', 'thinking-10',
  ]);
  assert.deepEqual(pickedCards(bank, ALL_TIME_SEED, 6).map((c) => c.id), [
    'language-double-negatives-3', 'economics-interest-4', 'nature-clouds-5', 'technology-limits-5', 'thinking-h13', 'medicine-painkillers-5',
  ]);
});

test('the calendar is read, and chained past its end', () => {
  const e = editionOf(DAY);
  assert.equal(e, 33);
  assert.equal(questionOfEdition(bank, e)?.id, bank.editions.get(e));
  assert.deepEqual(commonOfEdition(bank, e).map((c) => c.id), bank.commons.get(e));
  const beyond = Math.max(...bank.editions.keys()) + 1;
  const q = questionOfEdition(bank, beyond);
  assert.ok(q && graded(q) && q.topic === 'thinking');
  const c = commonOfEdition(bank, beyond);
  assert.equal(c.length, 8);
  assert.equal(new Set(c.map((x) => x.topic)).size, 8);
  assert.ok(c.every((x) => !asks(x)));
});

// ── Reading the reader ───────────────────────────────────────────────────

test('the onboarding is read as the phone reads it', () => {
  const untold = readOnboarding(even(), new Set(), new Set());
  assert.equal(untold.shape, 'untold');
  assert.ok(Object.values(untold.levels).every((l) => l === 1));
  const fan = readOnboarding({ ...even(0.4), space: 1, history: 0.9 }, new Set(), new Set());
  assert.equal(fan.shape, 'generalist');
  assert.deepEqual(fan.claimed.sort(), ['history', 'space']);
  assert.equal(fan.levels.space, 2);
  assert.equal(fan.levels.economics, 1);
  const pruned = readOnboarding(even(0.8), new Set(), new Set(['space.the_moon.moon_dust']));
  assert.ok(pruned.claimed.includes('space'));
  assert.equal(pruned.lean['strand:space.the_moon.tides'], 0.3);
  const w = weightsOn(fan, 0, fan.weights);
  assert.ok(w.space / w.economics > fan.weights.space / fan.weights.economics);
  assert.deepEqual(weightsOn(fan, 3, fan.weights), fan.weights);
});

test('the trace moves the taste: what held the reader, what they threw on, what they never opened', () => {
  const slow = bank.live.find((c) => c.strand === 'space.black_holes.event_horizons' && !asks(c)) as typeof bank.live[0];
  const fast = bank.live.find((c) => c.strand === 'sport.rules_and_why.offside' && !asks(c)) as typeof bank.live[0];
  const shown = bank.live.find((c) => c.strand === 'food.spices.chilli') as typeof bank.live[0];
  const events: Event[] = [
    ...Array.from({ length: 6 }, (_, i) => ({ t: NOW - 3_600_000 * (i + 1), e: 'next', c: 'science-1', ms: 8000 })),
    { t: NOW - 1000, e: 'next', c: slow.id, ms: 30_000 },
    { t: NOW - 2000, e: 'next', c: fast.id, ms: 900 },
    { t: NOW - 3000, e: 'seen', c: shown.id, sh: 'today' },
    { t: NOW - 4000, e: 'like', c: slow.id },
  ];
  const activity = new Map<string, Event[]>([[DAY, events]]);
  const read = readTrace(activity, bank, NOW);
  assert.equal(read.medianMs, 8000);
  assert.ok(read.taste['strand:space.black_holes.event_horizons'] > TASTE_LEAN);
  assert.ok(read.taste['strand:sport.rules_and_why.offside'] < 0);
  assert.ok(read.taste['strand:food.spices.chilli'] < 0);
  assert.ok(Object.values(read.taste).every((v) => Math.abs(v) <= 0.6));
});

test('the level is measured once there is something to measure', () => {
  const ids = bank.live.filter((c) => c.topic === 'history' && graded(c)).slice(0, 8).map((c) => c.id);
  const p = profileOf({ topicWeights: even(), judgements: ids.map((id, i) => ({ c: 80, k: i < 7, p: id, d: DAY })) });
  assert.equal(p.levels.history, 2);
  const q = profileOf({ topicWeights: even(), judgements: ids.map((id) => ({ c: 80, k: false, p: id, d: DAY })) });
  assert.equal(q.levels.history, 0);
  assert.equal(profileOf({ topicWeights: even() }).levels.history, 1);
});

// ── The day ──────────────────────────────────────────────────────────────

test('a free reader\'s first day is a welcome day: four of their own and the question of the day', () => {
  const p = profileOf({ topicWeights: { space: 1, science: 0.5 }, pickedTopics: ['space', 'science', 'thinking'] });
  const d = dealDay(bank, p, DAY, 'reader-1');
  assert.equal(d.cards.length, PILLS_PER_DAY);
  assert.equal(new Set(d.cards.map((c) => c.id)).size, PILLS_PER_DAY);
  assert.equal(d.own.length, OWN_WELCOME);
  assert.equal(d.welcome, true);
  assert.equal(d.question, questionOfEdition(bank, editionOf(DAY))?.id);
  assert.equal(d.cards.filter(asks).length, 2);
  assert.equal(asks(d.cards[0]), false, 'opens on a read');
  for (const id of d.own) {
    const c = bank.byId.get(id) as typeof bank.live[0];
    assert.ok(['space', 'science', 'thinking'].includes(c.topic), `${id} is on the mix`);
  }
  // The same again: deterministic in the reader and the date.
  assert.deepEqual(dealDay(bank, p, DAY, 'reader-1').cards.map((c) => c.id), d.cards.map((c) => c.id));
  assert.notDeepEqual(dealDay(bank, p, DAY, 'reader-2').own, d.own);
});

test('after the welcome week the shared day: the question, three of the edition\'s on the mix first, one own', () => {
  const done = Array.from({ length: WELCOME_DAYS }, (_, i) => shiftDate('2026-09-20', i));
  const p = profileOf({ topicWeights: { space: 1, science: 0.5 }, pickedTopics: ['space', 'science', 'thinking'], completedDates: done });
  assert.equal(dayNumberOf(p, DAY), WELCOME_DAYS);
  const d = dealDay(bank, p, DAY, 'reader-1');
  assert.equal(d.own.length, OWN_FREE);
  assert.equal(d.welcome, false);
  const commons = d.cards.filter((c) => !d.own.includes(c.id) && c.id !== d.question).map((c) => c.id);
  assert.equal(commons.length, 3);
  const spares = bank.commons.get(editionOf(DAY)) as string[];
  for (const id of commons) assert.ok(spares.includes(id), `${id} is the edition's`);
});

test('a week kept is rewarded after the welcome, never during; Astute+ has five own and a review', () => {
  const done = Array.from({ length: 14 }, (_, i) => shiftDate('2026-09-19', i));
  const kept = profileOf({ topicWeights: even(), completedDates: done, streak: 14, lastCompletionDate: '2026-10-02' });
  assert.equal(dealDay(bank, kept, DAY, 'r').own.length, 2);
  const due = bank.live.find((c) => c.topic === 'thinking' && graded(c)) as typeof bank.live[0];
  const plus = profileOf({ topicWeights: even(), completedDates: done, answers: { [due.id]: { r: '1', c: 60, s: 0, d: '2026-10-01' } } }, [], true);
  const d = dealDay(bank, plus, DAY, 'r');
  assert.equal(d.own.length, 5);
  assert.equal(d.question, null);
  assert.equal(d.reviews.length, 1);
  const review = bank.byId.get(d.reviews[0]) as typeof bank.live[0];
  assert.equal(review.principle, due.principle, 'a fresh card of the same principle');
});

test('what was seen is never dealt again; the taste leans the draw', () => {
  const p = profileOf({ topicWeights: { space: 1 }, pickedTopics: ['space', 'thinking'] });
  const first = dealDay(bank, p, DAY, 'r');
  const seen = profileOf({ topicWeights: { space: 1 }, pickedTopics: ['space', 'thinking'], seenIds: first.own });
  const second = dealDay(bank, seen, DAY, 'r');
  for (const id of second.own) assert.ok(!first.own.includes(id));
  // A reader who loves black holes gets them first.
  const holes = Object.fromEntries(['strand:space.black_holes.event_horizons', 'strand:space.black_holes.hawking_radiation', 'strand:space.black_holes.supermassive_ones', 'genre:space.black_holes'].map((k) => [k, 0.6]));
  let withHoles = 0, without = 0;
  for (let i = 0; i < 20; i++) {
    const date = shiftDate(DAY, i);
    const lover = { ...profileOf({ topicWeights: { space: 1 }, pickedTopics: ['space', 'thinking'] }), taste: holes };
    withHoles += dealDay(bank, lover, date, 'r').own.filter((id) => bank.byId.get(id)?.genre === 'space.black_holes').length;
    without += dealDay(bank, profileOf({ topicWeights: { space: 1 }, pickedTopics: ['space', 'thinking'] }), date, 'r').own.filter((id) => bank.byId.get(id)?.genre === 'space.black_holes').length;
  }
  assert.ok(withHoles > without, `${withHoles} > ${without}`);
});

test('a day has a shape: never two debates, the debate last', () => {
  const debate = bank.live.filter((c) => c.kind === 'debate').slice(0, 2);
  const out = arrangeDay([...debate, ...bank.live.filter((c) => !asks(c)).slice(0, 3)]);
  assert.equal(out[out.length - 1].kind, 'debate');
  for (let i = 0; i < 40; i++) {
    const d = dealDay(bank, profileOf({ topicWeights: even() }, [], true), shiftDate(DAY, i), 'r');
    assert.ok(d.cards.filter((c) => c.kind === 'debate').length <= 1);
    assert.ok(d.cards.filter((c) => graded(c)).length >= 1);
  }
});

// ── Explore ──────────────────────────────────────────────────────────────

test('Explore for everybody: the closed days only, the crowd under the counts, a card whole on every shelf', () => {
  const tallies = new Map([[shiftDate(DAY, -2), new Map([['science-1', 500]])], [DAY, new Map([['space-2', 999]])]]);
  const totals = new Map([['thinking-4', 4000]]);
  const doc = buildGlobalExplore(bank, tallies, totals, DAY, NOW);
  assert.equal(doc.topWeek[0].id, 'science-1');
  assert.ok(!doc.topWeek.some((r) => r.id === 'space-2'), 'today is still open');
  assert.equal(doc.loved[0].id, 'thinking-4');
  assert.equal(doc.today.length, 24);
  assert.ok(doc.today.every((c) => typeof c.question === 'string'));
  assert.ok(doc.bySubject.space.week.length > 0);
  assert.equal(topList(bank, tallies, DAY, 7, 3).length, 3);
});

test('Explore for one reader: their subject, and what the profile puts first, unread', () => {
  const p = profileOf({ topicWeights: { ...even(0.4), food: 1 }, seenIds: ['food-salt-1'] });
  const doc = buildPersonalExplore(bank, p, DAY, NOW);
  assert.equal(doc.because, 'food');
  assert.ok(doc.mine.every((c) => c.topic === 'food' && c.id !== 'food-salt-1'));
  assert.equal(doc.forYou.length, 8);
  const strands = doc.forYou.map((c) => c.strand).filter(Boolean);
  assert.equal(new Set(strands).size, strands.length, 'one per strand');
  assert.ok(Object.values(doc.forYou.reduce((m, c) => ({ ...m, [c.topic]: (m[c.topic] ?? 0) + 1 }), {} as Record<string, number>)).every((n) => n <= 2));
});

test('the search is the phone\'s', () => {
  const hits = search(bank, 'Black Hole');
  assert.ok(hits.length > 0 && hits.length <= 30);
  assert.ok(hits.every((c) => `${c.question} ${c.answer} ${c.topic} ${c.move} ${(c.keywords ?? []).join(' ')}`.toLowerCase().includes('black hole')));
  assert.deepEqual(search(bank, '   '), []);
});

// ── When ─────────────────────────────────────────────────────────────────

test('the reader\'s day is the reader\'s clock\'s', () => {
  const rome = 120, tokyo = 540;
  const late = Date.UTC(2026, 9, 3, 22, 30);
  assert.equal(localDate(late, rome), '2026-10-04');
  assert.equal(localHour(late, rome), 0);
  assert.equal(localDate(late, -300), '2026-10-03');
  assert.deepEqual(datesToPrepare({ tz: tokyo }, Date.UTC(2026, 9, 3, 9, 0)), ['2026-10-03', '2026-10-04']);
  assert.deepEqual(datesToPrepare({ tz: rome }, Date.UTC(2026, 9, 3, 9, 0)), ['2026-10-03']);
  assert.equal(askableDate('2026-10-04', rome, Date.UTC(2026, 9, 3, 9, 0)), true);
  assert.equal(askableDate('2026-10-09', rome, Date.UTC(2026, 9, 3, 9, 0)), false);
});
