import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  BudgetSpent,
  DAY_BUDGET_USD,
  LIMITS,
  MONTH_BUDGET_USD,
  PRICE,
  costOf,
  memoryLedger,
  spendDay,
  withinBudget,
  worstCost,
} from './budget.js';

test('a call costs what its tokens cost: Haiku 5.5 up to 100,000 tokens read, five times that beyond', () => {
  assert.ok(Math.abs(costOf({ input_tokens: 800, output_tokens: 400 }) - 0.00028) < 1e-12);
  assert.equal(costOf({}), 0);
  // Read from the cache at a tenth, written to it at a quarter more.
  assert.ok(Math.abs(costOf({ input_tokens: 0, cache_read_input_tokens: 1000 }) - 0.00001) < 1e-12);
  assert.ok(Math.abs(costOf({ input_tokens: 0, cache_creation_input_tokens: 1000 }) - 0.000125) < 1e-12);
  assert.ok(Math.abs(costOf({ input_tokens: 200_000, output_tokens: 1000 }) - (200_000 * 0.5 + 1000 * 2.5) / 1e6) < 1e-12);
  assert.equal(PRICE.input, 0.1);
  assert.equal(PRICE.output, 0.5);
});

test("one budget for all the AI: $90 a month of the owner's $100, at most $3 a day", () => {
  assert.equal(MONTH_BUDGET_USD, 90);
  assert.equal(DAY_BUDGET_USD, 3);
  assert.deepEqual(LIMITS, { day: 3, month: 90 });
  assert.ok(MONTH_BUDGET_USD < 100);
});

test('the most a call can cost is never less than what a call of that size costs', () => {
  // A prompt of 8,000 characters is never more than 4,000 tokens.
  assert.ok(worstCost(8000, 2000) >= costOf({ input_tokens: 4000, output_tokens: 2000 }));
  assert.ok(worstCost(0, 800) >= costOf({ output_tokens: 800 }));
});

test('the day is counted in UTC, and its month is its first seven', () => {
  assert.equal(spendDay(Date.parse('2026-11-25T23:30:00-02:00')), '2026-11-26');
  assert.equal(spendDay(Date.parse('2026-12-01T00:30:00+01:00')), '2026-11-30');
});

test('calls are made while the day has room for the most each can cost, counted with their tokens by what asked, and refused after', async () => {
  const ledger = memoryLedger({ day: 0.01 });
  const usage = { input_tokens: 4000, output_tokens: 1000 };
  const call = async () => ({ text: 'ok', usage });
  const one = costOf(usage);
  let made = 0;
  for (let i = 0; i < 20; i++) {
    try {
      await withinBudget(ledger, '2026-11-26', 0.002, i % 2 ? 'ask' : 'news', call);
      made++;
    } catch (e) {
      assert.ok(e instanceof BudgetSpent);
      assert.equal(e.day, '2026-11-26');
    }
  }
  const day = ledger.spend.get('2026-11-26')!;
  // Each call costs 0.0009 and holds 0.002 while it runs: calls go on while 0.002 more still fits.
  assert.equal(made, Math.floor((0.01 - 0.002) / one) + 1);
  assert.ok(day.usd <= 0.01);
  assert.equal(day.calls, made);
  assert.equal(day.input, 4000 * made);
  assert.equal(day.output, 1000 * made);
  assert.equal(day.refused, 20 - made);
  assert.equal(day.by.news.calls + day.by.ask.calls, made);
  assert.ok(Math.abs(day.held) < 1e-12);
  // The month counts the same calls.
  assert.equal(ledger.spend.get('2026-11')!.calls, made);
  // The next day has a ceiling of its own.
  await withinBudget(ledger, '2026-11-27', 0.002, 'coach', call);
  assert.equal(ledger.spend.get('2026-11-27')!.by.coach.calls, 1);
});

test("once the month is spent nothing more is asked, whatever room a day has left, until the month turns", async () => {
  const ledger = memoryLedger({ day: 1, month: 0.005 });
  const call = async () => ({ usage: { input_tokens: 4000, output_tokens: 1000 } });
  let made = 0;
  for (const day of ['2026-11-28', '2026-11-29', '2026-11-30']) {
    for (let i = 0; i < 4; i++) {
      try {
        await withinBudget(ledger, day, 0.001, 'ask', call);
        made++;
      } catch (e) {
        assert.ok(e instanceof BudgetSpent);
      }
    }
  }
  const month = ledger.spend.get('2026-11')!;
  assert.ok(month.usd <= 0.005);
  assert.equal(month.calls, made);
  assert.equal(made, Math.floor((0.005 - 0.001) / costOf({ input_tokens: 4000, output_tokens: 1000 })) + 1);
  // A new month starts with all its room.
  await withinBudget(ledger, '2026-12-01', 0.001, 'ask', call);
  assert.equal(ledger.spend.get('2026-12')!.calls, 1);
});

test('calls side by side cannot share room that only one has; a call that fails lets its room go and counts nothing', async () => {
  const ledger = memoryLedger({ day: 0.003 });
  const slow = async () => {
    await new Promise((r) => setTimeout(r, 5));
    return { usage: { input_tokens: 1000, output_tokens: 100 } };
  };
  const out = await Promise.allSettled([
    withinBudget(ledger, '2026-11-26', 0.002, 'ask', slow),
    withinBudget(ledger, '2026-11-26', 0.002, 'ask', slow),
  ]);
  assert.deepEqual(
    out.map((o) => o.status),
    ['fulfilled', 'rejected'],
  );
  await assert.rejects(
    withinBudget(ledger, '2026-11-26', 0.001, 'news', async () => {
      throw new Error('the API is down');
    }),
    /the API is down/,
  );
  for (const key of ['2026-11-26', '2026-11']) {
    const s = ledger.spend.get(key)!;
    assert.equal(s.calls, 1);
    assert.ok(Math.abs(s.held) < 1e-12);
    assert.equal(s.by.news.calls, 0);
  }
});
