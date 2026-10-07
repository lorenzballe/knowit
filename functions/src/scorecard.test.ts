import { test } from 'node:test';
import assert from 'node:assert/strict';

import { Bank, Card, graded, shiftDate } from './bank.js';
import { Event, buildProfile, reviewsDue } from './profile.js';
import { dealDay } from './deal.js';
import { topList } from './explore.js';
import { search } from './search.js';
import {
  Counted, MIN_ANSWERS, QUARANTINE_REPORTERS, Report, TALLY_FIELDS, addCounted, assess, daysToCount, decode, emptyTally,
  encode, fit, keySuspect, notesOf, shardOf, standing, tallyDay, wilson, withheld,
} from './scorecard.js';

const bank = Bank.bundled();
const NOW = Date.UTC(2026, 9, 7, 4, 20);
const DAY = '2026-10-07';

function ev(e: string, c: string, extra: Partial<Event> = {}, t = 1000): Event {
  return { t, e, c, ...extra };
}

/** A card's totals as if [n] readers had each done [each] once. */
function crowd(n: number, each: (i: number) => Partial<Record<keyof Counted['tally'], number>>, picks: number[] = []): Counted {
  const tally = emptyTally();
  for (let i = 0; i < n; i++) {
    for (const [k, v] of Object.entries(each(i))) tally[k as keyof typeof tally] += v as number;
  }
  return { tally, picks };
}

function report(card: string, reason: Report['reason'], at = NOW - 86_400_000): Report {
  return { card, reason, note: '', at };
}

const pick = bank.live.find((c) => c.kind === 'pickOne' && Array.isArray(c.options) && (c.options as unknown[]).length === 3) as Card;
const hard = bank.live.find((c) => graded(c) && c.difficulty === 'hard') as Card;
// Every card that asks is at least medium (tool/cards/check.py).
const medium = bank.live.find((c) => graded(c) && c.difficulty === 'medium') as Card;
const fact = bank.live.find((c) => c.kind === 'read') as Card;

// ── Counting a day ───────────────────────────────────────────────────────

test('a reader\'s day counts each gesture once, the first answer only, reviews apart', () => {
  const day = tallyDay([
    ev('view', 'science-1', {}, 1),
    ev('view', 'science-1', {}, 2),
    ev('flip', 'science-1', {}, 3),
    ev('ans', 'science-1', { ok: false, cf: 95, a: 2 }, 4),
    ev('ans', 'science-1', { ok: true, cf: 50, a: 0 }, 5),
    ev('next', 'science-1', { ms: 12_000 }, 6),
    ev('next', 'science-1', { ms: 8_000 }, 7),
    ev('like', 'science-1', {}, 8),
    ev('like', 'science-1', {}, 9),
    ev('ans', 'space-2', { ok: true, rv: true, cf: 80 }, 10),
    ev('seen', 'space-3', { sh: 'loved' }, 11),
    ev('tab', '', {}, 12),
    { t: 13, e: 'app' },
  ]);
  assert.deepEqual([...day.keys()].sort(), ['science-1', 'space-2', 'space-3']);
  const s = day.get('science-1') as Counted;
  assert.equal(s.tally.readers, 1);
  assert.equal(s.tally.exposures, 1);
  assert.equal(s.tally.flips, 1);
  assert.equal(s.tally.answers, 1);
  assert.equal(s.tally.right, 0, 'the first answer is the one counted');
  assert.equal(s.tally.sure, 1);
  assert.equal(s.tally.sureWrong, 1);
  assert.deepEqual(s.picks, [0, 0, 1]);
  assert.equal(s.tally.dwellMs, 20_000);
  assert.equal(s.tally.dwells, 2);
  assert.equal(s.tally.likes, 1, 'a reader-day, not a tap');
  const r = day.get('space-2') as Counted;
  assert.equal(r.tally.answers, 0);
  assert.equal(r.tally.reviews, 1);
  assert.equal(r.tally.reviewsRight, 1);
  const shelf = day.get('space-3') as Counted;
  assert.equal(shelf.tally.seen, 1);
  assert.equal(shelf.tally.exposures, 0, 'on a shelf is not in front of the reader');
});

test('totals add up, and survive the trip through the store', () => {
  const a = tallyDay([ev('ans', 'science-1', { ok: true, a: 1 }), ev('view', 'science-1')]).get('science-1') as Counted;
  const b = tallyDay([ev('ans', 'science-1', { ok: false, a: 2 }), ev('skip', 'science-1')]).get('science-1') as Counted;
  const sum = addCounted(decode(encode(a), a.picks), b);
  assert.equal(sum.tally.readers, 2);
  assert.equal(sum.tally.answers, 2);
  assert.equal(sum.tally.right, 1);
  assert.equal(sum.tally.dislikes, 1);
  assert.deepEqual(sum.picks, [0, 1, 1]);
  const back = decode(encode(sum), sum.picks);
  assert.deepEqual(back, sum);
  assert.equal(encode(sum).length, TALLY_FIELDS.length);
  assert.deepEqual(decode('nonsense', null), { tally: emptyTally(), picks: [] });
  assert.equal(shardOf('weird_facts-local-bans-4'), 'weird_facts');
  assert.equal(shardOf('thinking'), 'thinking');
});

test('the days counted are closed ones, a week of them, oldest first', () => {
  const days = daysToCount(NOW);
  assert.equal(days.length, 7);
  assert.equal(days[6], shiftDate(DAY, -2));
  assert.equal(days[0], shiftDate(DAY, -8));
});

// ── What it says ─────────────────────────────────────────────────────────

test('a rate is only as sure as the readers it rests on', () => {
  assert.deepEqual(wilson(0, 0), [0, 1]);
  const [lo, hi] = wilson(5, 10);
  assert.ok(Math.abs(lo - 0.2366) < 0.001 && Math.abs(hi - 0.7634) < 0.001, `${lo} ${hi}`);
  const few = wilson(3, 3);
  const many = wilson(300, 300);
  assert.ok(few[0] < 0.5 && many[0] > 0.98, 'three out of three is not a certainty');
});

test('a card far outside its label is flagged, and only on enough answers', () => {
  const counted = new Map<string, Counted>([
    [hard.id, crowd(40, () => ({ answers: 1, right: 1, exposures: 1, readers: 1 }))],
    [medium.id, crowd(40, (i) => ({ answers: 1, right: i < 1 ? 1 : 0, exposures: 1, readers: 1 }))],
  ]);
  const a = assess(bank, counted, []);
  assert.deepEqual(a.flags[hard.id], ['tooEasy']);
  assert.deepEqual(a.flags[medium.id], ['tooHard']);
  const few = assess(bank, new Map([[hard.id, crowd(MIN_ANSWERS - 1, () => ({ answers: 1, right: 1 }))]]), []);
  assert.equal(few.flags[hard.id], undefined);
});

test('a marked answer the crowd rejects is suspect, not a trap', () => {
  const correct = pick.correct as number;
  const other = [0, 1, 2].find((i) => i !== correct) as number;
  const picks = [0, 0, 0];
  picks[other] = 36;
  picks[correct] = 1;
  picks[3 - other - correct] = 3;
  const wrongKey = crowd(40, (i) => ({ answers: 1, right: i === 0 ? 1 : 0, exposures: 1 }), picks);
  assert.ok(keySuspect(pick, wrongKey));
  // A trap: most fall for one option, but a fair share get it right.
  const trapPicks = [0, 0, 0];
  trapPicks[other] = 26;
  trapPicks[correct] = 14;
  const trap = crowd(40, (i) => ({ answers: 1, right: i < 14 ? 1 : 0, exposures: 1 }), trapPicks);
  assert.ok(!keySuspect(pick, trap));
  // Suspect alone is a flag; suspect and one reader saying so is quarantine.
  assert.deepEqual(assess(bank, new Map([[pick.id, wrongKey]]), []).quarantined, []);
  const said = assess(bank, new Map([[pick.id, wrongKey]]), [report(pick.id, 'answer')]);
  assert.deepEqual(said.quarantined, [pick.id]);
  assert.ok(said.flags[pick.id].includes('keySuspect'));
});

test('readers throwing a card down, or keeping it, is flagged on enough of them', () => {
  const counted = new Map<string, Counted>([
    [fact.id, crowd(40, (i) => ({ exposures: 1, readers: 1, dislikes: i < 15 ? 1 : 0 }))],
    [hard.id, crowd(40, (i) => ({ exposures: 1, readers: 1, likes: i < 16 ? 1 : 0, saves: i < 6 ? 1 : 0 }))],
  ]);
  const a = assess(bank, counted, []);
  assert.deepEqual(a.flags[fact.id], ['thrown']);
  assert.deepEqual(a.flags[hard.id], ['kept']);
  assert.equal(a.cards[fact.id].thrown, 15);
  assert.equal(a.cards[hard.id].kept, 22);
  // Taken back is not thrown.
  const undone = assess(bank, new Map([[fact.id, crowd(40, (i) => ({ exposures: 1, dislikes: i < 15 ? 1 : 0, undislikes: i < 15 ? 1 : 0 }))]]), []);
  assert.equal(undone.flags[fact.id], undefined);
});

test('enough readers saying a card is untrue take it out of the deal', () => {
  const untrue = Array.from({ length: QUARANTINE_REPORTERS }, (_, i) => report(fact.id, i === 0 ? 'source' : 'fact'));
  const a = assess(bank, new Map(), untrue);
  assert.deepEqual(a.quarantined, [fact.id]);
  assert.deepEqual(a.flags[fact.id], ['reported', 'disputed', 'quarantined']);
  assert.deepEqual(a.reports[fact.id], { source: 1, fact: 2 });
  // Two is a dispute; typos and confusion are worth reading, not a quarantine.
  assert.deepEqual(assess(bank, new Map(), untrue.slice(1)).flags[fact.id], ['reported', 'disputed']);
  const style = assess(bank, new Map(), [report(fact.id, 'typo'), report(fact.id, 'unclear'), report(fact.id, 'other'), report(fact.id, 'typo')]);
  assert.deepEqual(style.flags[fact.id], ['reported']);
  assert.deepEqual(style.quarantined, []);
  // A card nobody has heard of is not flagged.
  assert.deepEqual(assess(bank, new Map(), [report('nowhere-1', 'fact')]).flags, {});
});

test('a card checked since answers the reports made before it', () => {
  const checked = { ...fact, checked: '2026-10-06' };
  const fixed = new Bank({ version: bank.version, cards: bank.cards.map((c) => (c.id === fact.id ? checked : c)) });
  const before = Date.UTC(2026, 9, 5);
  const after = Date.UTC(2026, 9, 6, 12);
  const old = Array.from({ length: 3 }, () => report(fact.id, 'fact', before));
  assert.deepEqual(assess(fixed, new Map(), old).quarantined, []);
  assert.equal(standing(fixed, old).length, 0);
  const since = [...old, report(fact.id, 'fact', after)];
  assert.deepEqual(assess(fixed, new Map(), since).flags[fact.id], ['reported']);
});

test('only cards enough readers met are published, and nothing about who', () => {
  const counted = new Map<string, Counted>([
    [hard.id, crowd(4, () => ({ exposures: 1, readers: 1 }))],
    [medium.id, crowd(6, () => ({ exposures: 1, readers: 1, answers: 1, right: 1, dwellMs: 5000, dwells: 1 }), [6, 0, 0])],
  ]);
  const a = assess(bank, counted, []);
  assert.equal(a.cards[hard.id], undefined);
  assert.deepEqual(a.cards[medium.id], { exposures: 6, answers: 6, right: 6, sure: 0, sureWrong: 0, kept: 0, thrown: 0, dwellMs: 5000, picks: [6, 0, 0] });
  assert.ok(!JSON.stringify(a).includes('note'));
});

// ── The dealer, around the quarantine ────────────────────────────────────

test('a card in quarantine is never dealt, searched or listed, and the bank is left as it was', () => {
  const ids = new Set(bank.live.filter((c) => c.topic === 'science').map((c) => c.id));
  const dealing = withheld(bank, ids);
  assert.equal(withheld(bank, new Set()), bank);
  assert.ok(dealing.live.every((c) => !ids.has(c.id)));
  assert.equal(dealing.live.length, bank.live.length - ids.size);
  assert.equal(dealing.byId.get([...ids][0])?.disabled, true, 'still known by id');
  assert.ok(bank.live.some((c) => ids.has(c.id)), 'the bank in hand is not touched');
  assert.equal(dealing.version, bank.version);
  assert.deepEqual([...dealing.editions], [...bank.editions]);

  const profile = buildProfile({ topicWeights: { science: 1, space: 1 }, pickedTopics: ['science', 'space'] }, new Map(), { tz: 0, plus: true }, dealing, NOW);
  for (let i = 0; i < 10; i++) {
    const d = dealDay(dealing, profile, shiftDate(DAY, i), 'r');
    assert.ok(d.cards.every((c) => !ids.has(c.id)), d.cards.map((c) => c.id).join(' '));
  }
  assert.ok(search(dealing, 'science').every((c) => !ids.has(c.id)));
  const tallies = new Map([[shiftDate(DAY, -2), new Map([...ids].slice(0, 5).map((id) => [id, 900] as [string, number]))]]);
  assert.ok(topList(dealing, tallies, DAY, 7, 10).every((r) => !ids.has(r.id)));
});

test('a card taken out of the deal is not brought back as a review', () => {
  const retired = bank.live.find((c) => c.kind === 'read') as Card;
  const dealing = withheld(bank, new Set([retired.id]));
  const answers = { [retired.id]: { r: '0', c: 60, s: 0, d: '2026-10-01' } };
  const profile = buildProfile({ answers }, new Map(), { tz: 0, plus: true }, dealing, NOW);
  assert.deepEqual(reviewsDue(profile, dealing, DAY).map((c) => c.id), []);
  const before = buildProfile({ answers }, new Map(), { tz: 0, plus: true }, bank, NOW);
  assert.deepEqual(reviewsDue(before, bank, DAY).map((c) => c.id), [retired.id]);
});

test('what is stored fits a document: the least-met cards give way, never a flag', () => {
  const counted = new Map<string, Counted>();
  for (const c of bank.live.slice(0, 400)) counted.set(c.id, crowd(10 + (c.id.length % 7), () => ({ exposures: 1, readers: 1 })));
  counted.set(fact.id, crowd(40, (i) => ({ exposures: 1, dislikes: i < 15 ? 1 : 0 })));
  const a = assess(bank, counted, []);
  const small = fit(a, 6000);
  assert.ok(JSON.stringify(small).length <= 6000);
  assert.ok(Object.keys(small.cards).length < Object.keys(a.cards).length);
  assert.ok(small.cards[fact.id], 'a flagged card keeps its numbers');
  assert.deepEqual(small.flags, a.flags);
  assert.equal(fit(a), a, 'untouched when it fits');
  const notes = notesOf([
    ...Array.from({ length: 30 }, (_, i) => ({ ...report(fact.id, 'fact', NOW - i), note: `note ${i}` })),
    { ...report(hard.id, 'typo'), note: '' },
  ]);
  assert.equal(notes[fact.id].length, 20);
  assert.equal(notes[fact.id][0].note, 'note 0', 'newest first');
  assert.equal(notes[hard.id], undefined, 'a report with no note has nothing to read');
});
