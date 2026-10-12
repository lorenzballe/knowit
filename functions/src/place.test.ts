import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

import { Bank, Card, asks, isDebate, isPlaceCard, isSunday, shiftDate } from './bank.js';
import { buildProfile, reviewsDue, Snapshot } from './profile.js';
import { commonOfEdition, dealDay, localCard, ownCardsFor, placeCards, questionOfEdition, OWN_FREE, PILLS_PER_DAY } from './deal.js';
import { LOCAL_SHELF, buildGlobalExplore, buildPersonalExplore, whereYouLive } from './explore.js';
import { cardPlaceFromJson, distanceKm, placeFit, placeFromJson } from './place.js';
import { search } from './search.js';

// ── The same fit as the phone ────────────────────────────────────────────

// The cases the phone is held to (test/place_test.dart), read from the
// repository: lib/ is two folders under it once compiled.
const here = dirname(fileURLToPath(import.meta.url));
const shared = JSON.parse(readFileSync(join(here, '..', '..', 'tool', 'places', 'fit_cases.json'), 'utf8')) as {
  cases: { name: string; card: unknown; reader: unknown; fit: string }[];
};

for (const c of shared.cases) {
  test(`the phone's fit: ${c.name}`, () => {
    assert.equal(placeFit(cardPlaceFromJson(c.card), placeFromJson(c.reader)), c.fit);
  });
}

test('the fit cases are all read', () => {
  assert.ok(shared.cases.length >= 10);
  assert.deepEqual(new Set(shared.cases.map((c) => c.fit)), new Set(['none', 'country', 'region', 'city']));
});

test('distance along the ground, as on the phone', () => {
  // Modena to Bologna, centre to centre: about 37 km.
  assert.ok(Math.abs(distanceKm(44.647, 10.925, 44.494, 11.343) - 37) < 2);
  assert.equal(distanceKm(45, 7, 45, 7), 0);
});

test('a place that is not one is no place: nothing is dealt on it', () => {
  assert.equal(placeFromJson(null), null);
  assert.equal(placeFromJson('IT'), null);
  assert.equal(placeFromJson({ city: 'Modena' }), null);
  assert.equal(placeFromJson({ country: 'Italy' }), null);
  assert.equal(placeFromJson({ country: 'it' }), null);
  assert.deepEqual(placeFromJson({ country: 'IT', region: 'IT-45', city: 'Formigine', lat: 44.6, lon: 10.8, at: '2026-10-12T09:00:00Z' }), {
    country: 'IT', region: 'IT-45', regionName: undefined, city: 'Formigine', lat: 44.6, lon: 10.8,
  });
  // A card whose place cannot be read fits nobody: it is kept from
  // everybody rather than given to everybody.
  assert.equal(cardPlaceFromJson({ region: 'IT-45' }), null);
  assert.equal(placeFit(cardPlaceFromJson({ region: 'IT-45' }), placeFromJson({ country: 'IT', region: 'IT-45' })), 'none');
});

// ── A bank with cards about places in it ─────────────────────────────────

const bank = Bank.bundled();
const DAY = '2026-10-05'; // a Monday: an ordinary day of the week
const NOW = Date.UTC(2026, 9, 5, 7, 0);

const MODENA = { country: 'IT', region: 'IT-45', city: 'Modena', lat: 44.647, lon: 10.925, km: 20 };
const BOLOGNA = { country: 'IT', region: 'IT-45', city: 'Bologna', lat: 44.494, lon: 11.343, km: 20 };
const EMILIA = { country: 'IT', region: 'IT-45' };
const LOMBARDY = { country: 'IT', region: 'IT-25' };
const ITALY = { country: 'IT' };
const FRANCE = { country: 'FR' };

/** A card of the bank, made a card about [place] under a new id: its kind, subject and strand stay. */
function placed(base: string, id: string, place: Record<string, unknown>, question?: string): Card {
  const card = bank.byId.get(base);
  if (!card) throw new Error(`no ${base}`);
  // A new id: one the bank already holds would be two cards under one name.
  if (bank.byId.has(id)) throw new Error(`${id} is in the bank already`);
  return { ...card, id, place, ...(question ? { question } : {}) };
}

const local: Card[] = [
  placed('history-1', 'history-modena-1', MODENA, 'Why does the Ghirlandina lean the way it does?'),
  placed('history-1848-5', 'history-modena-2', MODENA),
  placed('history-british-1', 'history-modena-3', MODENA),
  placed('food-beer-1', 'food-bologna-1', BOLOGNA),
  placed('history-2', 'history-emilia-1', EMILIA),
  placed('history-1848-9', 'history-emilia-2', EMILIA),
  placed('food-beer-2', 'food-lombardy-1', LOMBARDY),
  placed('history-6', 'history-italy-1', ITALY),
  placed('history-1848-10', 'history-italy-2', ITALY),
  // Tempting every shared path: a Thinking question (the question of the
  // day's pool), reads of every kind (the common cards'), a debate.
  placed('thinking-1', 'thinking-italy-1', ITALY),
  placed('food-beer-7', 'food-italy-1', ITALY),
  placed('history-clothes-10', 'history-italy-3', ITALY),
  placed('history-food-10', 'history-provence-1', FRANCE),
];
const localIds = new Set(local.map((c) => c.id));

const withPlaces = new Bank({
  version: bank.version,
  built: bank.built,
  cards: [...bank.cards, ...local],
  editions: Object.fromEntries([...bank.editions].map(([k, v]) => [String(k), v])),
  commons: Object.fromEntries([...bank.commons].map(([k, v]) => [String(k), v])),
});

const IN_MODENA = { country: 'IT', region: 'IT-45', regionName: 'Emilia-Romagna', city: 'Formigine', lat: 44.6, lon: 10.8 };
const IN_PIACENZA = { country: 'IT', region: 'IT-45', city: 'Piacenza', lat: 45.1, lon: 9.7 };
const IN_PALERMO = { country: 'IT', region: 'IT-82', city: 'Palermo', lat: 38.1, lon: 13.4 };
const IN_PARIS = { country: 'FR', city: 'Paris', lat: 48.9, lon: 2.4 };
const IN_BERLIN = { country: 'DE', region: 'DE-BE', city: 'Berlin', lat: 52.5, lon: 13.4 };

function reader(place: unknown, more: Snapshot = {}, plus = false) {
  return buildProfile({ topicWeights: { history: 1, food: 0.6, space: 0.4 }, ...more, place }, new Map(), { tz: 120, plus }, withPlaces, NOW);
}

const days = Array.from({ length: 30 }, (_, i) => shiftDate(DAY, i));

test('a place card is never dealt at random or as anybody\'s own, and to nobody who does not live there', () => {
  for (const place of [undefined, IN_PALERMO, IN_PARIS, IN_MODENA, { country: 'Italy' }]) {
    for (const plus of [false, true]) {
      const p = reader(place, {}, plus);
      for (const date of days) {
        const d = dealDay(withPlaces, p, date, 'r');
        assert.equal(d.cards.length, PILLS_PER_DAY);
        const about = d.cards.filter(isPlaceCard);
        assert.ok(about.length <= 1, 'one card about a place a day at most');
        for (const c of about) {
          assert.equal(c.id, d.local, `${c.id} is the day's local card`);
          assert.notEqual(placeFit(cardPlaceFromJson(c.place), p.place), 'none', `${c.id} reached a reader who does not live there`);
          assert.ok(!d.own.includes(c.id), 'never one of the reader\'s own');
        }
        if (d.local === null) assert.equal(about.length, 0);
      }
    }
  }
});

test('the calendar never names one: not the question of the day, not a common card, even past its end', () => {
  const beyond = Math.max(...bank.editions.keys()) + 1;
  for (let e = 1; e < beyond + 120; e++) {
    const q = questionOfEdition(withPlaces, e);
    assert.ok(q && !isPlaceCard(q), `edition ${e}`);
    for (const c of commonOfEdition(withPlaces, e)) assert.ok(!isPlaceCard(c), `edition ${e}: ${c.id}`);
  }
  // Past the calendar the chain is what it was without them, card for card.
  for (let e = beyond; e < beyond + 30; e++) {
    assert.equal(questionOfEdition(withPlaces, e)?.id, questionOfEdition(bank, e)?.id);
    assert.deepEqual(commonOfEdition(withPlaces, e).map((c) => c.id), commonOfEdition(bank, e).map((c) => c.id));
  }
});

test('Explore for everybody never shows one, however many readers kept it', () => {
  const counts = new Map(local.map((c) => [c.id, 100_000]));
  const tallies = new Map(Array.from({ length: 40 }, (_, i) => [shiftDate(DAY, -i), counts]));
  const doc = buildGlobalExplore(withPlaces, tallies, counts, DAY, NOW);
  const everywhere = [
    ...doc.today, ...doc.asking,
    ...doc.topWeek.map((r) => r.card), ...doc.topMonth.map((r) => r.card), ...doc.loved.map((r) => r.card),
  ];
  assert.ok(everywhere.length > 0);
  for (const c of everywhere) assert.ok(!localIds.has(c.id), c.id);
  for (const lists of Object.values(doc.bySubject)) {
    for (const r of [...lists.week, ...lists.month, ...lists.loved]) assert.ok(!localIds.has(r.id), r.id);
  }
  // And the shelves are the ones a bank without them builds.
  const plain = buildGlobalExplore(bank, new Map(), new Map(), DAY, NOW);
  assert.deepEqual(doc.today.map((c) => c.id), plain.today.map((c) => c.id));
  assert.deepEqual(doc.asking.map((c) => c.id), plain.asking.map((c) => c.id));
});

test('search finds one only for a reader who lives there', () => {
  const asked = 'ghirlandina';
  assert.deepEqual(search(withPlaces, asked, 30, placeFromJson(IN_MODENA)).map((c) => c.id), ['history-modena-1']);
  assert.deepEqual(search(withPlaces, asked, 30, placeFromJson(IN_PALERMO)), []);
  assert.deepEqual(search(withPlaces, asked), []);
  // A reader with no place finds what they always found.
  assert.deepEqual(search(withPlaces, 'black hole').map((c) => c.id), search(bank, 'black hole').map((c) => c.id));
});

// ── The local slot ───────────────────────────────────────────────────────

test('nearest first: the city, then the region, then the country, never one read, then an ordinary day', () => {
  const seen: string[] = [];
  const order: string[] = [];
  for (let i = 0; i < 12; i++) {
    const p = reader(IN_MODENA, { seenIds: seen });
    const d = dealDay(withPlaces, p, DAY, 'r');
    if (!d.local) break;
    assert.ok(!seen.includes(d.local), 'never a card already read');
    order.push(d.local);
    seen.push(d.local);
  }
  const fitOf = (id: string) => placeFit(cardPlaceFromJson(withPlaces.byId.get(id)?.place), placeFromJson(IN_MODENA));
  // Formigine is within Modena's reach and not Bologna's.
  assert.deepEqual(order.slice(0, 3).map(fitOf), ['city', 'city', 'city']);
  assert.deepEqual(new Set(order.slice(0, 3)), new Set(['history-modena-1', 'history-modena-2', 'history-modena-3']));
  assert.deepEqual(order.slice(3, 5).map(fitOf), ['region', 'region']);
  assert.deepEqual(order.slice(5).map(fitOf), ['country', 'country', 'country', 'country', 'country']);
  assert.ok(!order.some((id) => ['food-bologna-1', 'food-lombardy-1', 'history-provence-1'].includes(id)));
  // Everything read: an ordinary day, card for card the day a bank without
  // them deals.
  const done = reader(IN_MODENA, { seenIds: seen });
  const d = dealDay(withPlaces, done, DAY, 'r');
  assert.equal(d.local, null);
  assert.deepEqual(d.cards.map((c) => c.id), dealDay(bank, done, DAY, 'r').cards.map((c) => c.id));
});

test('no place, one that cannot be read, or one with no cards yet is an ordinary day: the same day as without the cards', () => {
  for (const place of [undefined, { country: 'Italy' }, 'IT', IN_BERLIN]) {
    const p = reader(place);
    for (const date of days.slice(0, 10)) {
      const d = dealDay(withPlaces, p, date, 'r');
      assert.equal(d.local, null);
      assert.deepEqual(d.cards.map((c) => c.id), dealDay(bank, p, date, 'r').cards.map((c) => c.id), `${String(place)} ${date}`);
    }
  }
  // A reader in a city with no card of its own still has their region's.
  const piacenza = dealDay(withPlaces, reader(IN_PIACENZA), DAY, 'r');
  assert.ok(['history-emilia-1', 'history-emilia-2'].includes(piacenza.local as string));
});

test('it takes a slot that would have come at random, never one of the reader\'s own; on Astute+ the last of theirs', () => {
  for (const date of days) {
    const free = dealDay(withPlaces, reader(IN_MODENA), date, 'r');
    assert.ok(free.local);
    assert.equal(free.own.length, ownCardsFor(false, 0, isSunday(date)));
    const atRandom = free.cards.filter((c) => !free.own.includes(c.id) && c.id !== free.local);
    assert.equal(atRandom.length, PILLS_PER_DAY - free.own.length - 1);
    // Still a day's shape: two that ask, a debate at most, and it closes on the debate.
    assert.equal(free.cards.filter(asks).length, 2, date);
    assert.ok(free.cards.filter(isDebate).length <= 1, date);
    if (free.cards.some(isDebate)) assert.ok(isDebate(free.cards[free.cards.length - 1]), date);

    const plus = dealDay(withPlaces, reader(IN_MODENA, {}, true), date, 'r');
    assert.ok(plus.local);
    assert.equal(plus.own.length, PILLS_PER_DAY - 1, 'Astute+: four of their own and the card about home');
    assert.deepEqual(new Set(plus.cards.map((c) => c.id)), new Set([...plus.own, plus.local]));
    assert.equal(plus.cards.filter(asks).length, 2, date);
    assert.ok(plus.cards.filter(isDebate).length <= 1, date);
  }
});

test('a debate about home is the day\'s only debate', () => {
  // A reader who has read every card about Modena but its debate.
  const p = reader(IN_MODENA, { seenIds: ['history-modena-1', 'history-modena-2'] }, true);
  for (const date of days) {
    const d = dealDay(withPlaces, p, date, 'r');
    assert.equal(d.local, 'history-modena-3');
    assert.equal(d.cards.filter(isDebate).length, 1, date);
    assert.equal(d.cards[d.cards.length - 1].id, 'history-modena-3', 'a debate to close');
  }
});

test('the reader and the date decide it, the same on every server', () => {
  const p = reader(IN_MODENA);
  const picks = new Set<string>();
  for (const date of days) {
    const a = localCard(withPlaces, p, { seed: `local:r:${date}`, date, exclude: p.seen });
    const b = localCard(withPlaces, reader(IN_MODENA), { seed: `local:r:${date}`, date, exclude: p.seen });
    assert.equal(a?.id, b?.id);
    assert.equal(dealDay(withPlaces, p, date, 'r').local, a?.id);
    picks.add(a?.id as string);
  }
  // Among Modena's three, the days are not all the same card.
  assert.ok(picks.size > 1, [...picks].join(','));
  assert.ok([...picks].every((id) => id.startsWith('history-modena-')));
});

test('the shelf of where you live: nearest first, read ones last in their fit, and nothing without a place', () => {
  const p = reader(IN_MODENA, { seenIds: ['history-modena-2'] });
  const shelf = whereYouLive(withPlaces, p, DAY);
  const fits = shelf.map((c) => placeFit(cardPlaceFromJson(c.place), p.place));
  assert.deepEqual(fits, ['city', 'city', 'city', 'region', 'region', 'country', 'country', 'country', 'country', 'country']);
  assert.equal(shelf[2].id, 'history-modena-2', 'the one read comes after its fit\'s unread');
  assert.ok(shelf.length <= LOCAL_SHELF);
  assert.deepEqual(whereYouLive(withPlaces, reader(undefined), DAY), []);
  assert.deepEqual(whereYouLive(withPlaces, reader(IN_PARIS), DAY).map((c) => c.id), ['history-provence-1']);
  assert.deepEqual(placeCards(withPlaces, null), []);

  // On the reader's own Explore, and on no other shelf of it.
  const doc = buildPersonalExplore(withPlaces, p, DAY, NOW);
  assert.deepEqual(doc.local.map((c) => c.id), shelf.map((c) => c.id));
  for (const c of [...doc.mine, ...doc.forYou]) assert.ok(!localIds.has(c.id), c.id);
  assert.deepEqual(buildPersonalExplore(withPlaces, reader(undefined), DAY, NOW).local, []);
  // A reader in Palermo has nothing of their city's or their region's yet,
  // and their country's all the same.
  const palermo = buildPersonalExplore(withPlaces, reader(IN_PALERMO), DAY, NOW).local;
  assert.deepEqual(new Set(palermo.map((c) => c.id)), new Set(['history-italy-1', 'history-italy-2', 'thinking-italy-1', 'food-italy-1', 'history-italy-3']));
  // A place the bank has nothing for yet: an empty shelf, which the phone hides.
  assert.deepEqual(buildPersonalExplore(withPlaces, reader(IN_BERLIN), DAY, NOW).local, []);
  assert.deepEqual(buildPersonalExplore(bank, reader(IN_MODENA), DAY, NOW).local, []);
});

test('a card about a place comes back as a review only to a reader who still lives there', () => {
  // A question about Modena whose principle no other card shares, so a
  // review of it can only be itself.
  const lonely: Card = { ...placed('history-1848-5', 'history-modena-lonely', MODENA), principle: 'onlyHere' };
  const lonelyBank = new Bank({ version: 1, cards: [...bank.cards, lonely] });
  const answers = { [lonely.id]: { r: '0', c: 70, s: 0, d: '2026-10-01' } };
  const at = (place: unknown) => buildProfile({ topicWeights: { history: 1 }, answers, place }, new Map(), { tz: 120, plus: true }, lonelyBank, NOW);
  assert.deepEqual(reviewsDue(at(IN_MODENA), lonelyBank, DAY).map((c) => c.id), [lonely.id]);
  assert.deepEqual(dealDay(lonelyBank, at(IN_MODENA), DAY, 'r').reviews, [lonely.id]);
  for (const elsewhere of [IN_PALERMO, IN_PARIS, undefined]) {
    assert.deepEqual(reviewsDue(at(elsewhere), lonelyBank, DAY), [], String(elsewhere));
    assert.ok(!dealDay(lonelyBank, at(elsewhere), DAY, 'r').cards.some((c) => c.id === lonely.id));
  }
});

test('a free day with its card about home still has the reader\'s own two', () => {
  const d = dealDay(withPlaces, reader(IN_MODENA), DAY, 'r');
  assert.equal(d.own.length, OWN_FREE);
  assert.ok(d.own.every((id) => !localIds.has(id)));
});
