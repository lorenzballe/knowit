// What the AI may spend, shared by every function that asks the model: the
// news each morning (news.ts), a question about a card (ask.ts) and the
// coach's note (coach.ts). One budget for all of them, set in limits.ts: so
// much a month and so much a day (UTC), counted in Firestore (ai/spend-{month}
// and ai/spend-{day}). Once either is spent nothing asks the model until it
// turns: the news keeps the paper it has, and a question or a note is "not
// available right now".
//
// Hard, not hopeful: before a call, the most it could cost (its prompt and
// every token it may write) is held back from the day's and the month's
// budget, in one transaction, so calls side by side cannot each find room
// that is no longer there. After it, what it really cost is counted from the
// tokens the API says it used, with the tokens themselves, and what was held
// is let go.

import { FieldValue, type Firestore } from 'firebase-admin/firestore';

import { DAY_BUDGET_USD, MONTH_BUDGET_USD } from './limits.js';

export { DAY_BUDGET_USD, MONTH_BUDGET_USD };

/**
 * The model's price, dollars per million tokens: Claude Haiku 5.5 for a
 * prompt of up to 100,000 tokens. A longer prompt costs five times as much,
 * on what it reads and what it writes.
 */
export const PRICE = { input: 0.1, output: 0.5, long: 100_000, longTimes: 5 } as const;

/** The tokens of one call, as the API reports them (Anthropic.Usage). */
export interface Usage {
  input_tokens?: number | null;
  output_tokens?: number | null;
  cache_creation_input_tokens?: number | null;
  cache_read_input_tokens?: number | null;
}

/** What one call cost, from the tokens the API says it used. */
export function costOf(usage: Usage): number {
  const fresh = usage.input_tokens ?? 0;
  const written = usage.cache_creation_input_tokens ?? 0;
  const read = usage.cache_read_input_tokens ?? 0;
  const times = fresh + written + read > PRICE.long ? PRICE.longTimes : 1;
  const input = (fresh + written * 1.25 + read * 0.1) * PRICE.input;
  const output = (usage.output_tokens ?? 0) * PRICE.output;
  return ((input + output) * times) / 1e6;
}

/**
 * The most a call can cost: a prompt of [promptChars] characters, counted
 * generously at a token for every two, and every one of the [maxTokens] it
 * may write.
 */
export function worstCost(promptChars: number, maxTokens: number): number {
  return costOf({ input_tokens: Math.ceil(promptChars / 2), output_tokens: maxTokens });
}

/** The day a call is counted under, yyyy-mm-dd in UTC; its month is the first seven. */
export function spendDay(nowMs: number): string {
  return new Date(nowMs).toISOString().slice(0, 10);
}

/** The budgets a ledger keeps to, in dollars. */
export interface Limits {
  day: number;
  month: number;
}

export const LIMITS: Limits = { day: DAY_BUDGET_USD, month: MONTH_BUDGET_USD };

/** Where the spending is kept. */
export interface Ledger {
  /**
   * Holds back [usd] of [day]'s budget and its month's for a call about to
   * be made. False, and nothing held, when that would pass either.
   */
  reserve(day: string, usd: number): Promise<boolean>;
  /**
   * A call is over: the [held] amount is let go, and what it cost, from
   * [usage], is counted with its tokens under [what] ("news", "ask",
   * "coach"), in the day and in its month. A call that never reached the
   * model has no usage.
   */
  settle(day: string, held: number, usage: Usage | null, what: string): Promise<void>;
}

/** The model was not asked: the day's or the month's budget is spent. */
export class BudgetSpent extends Error {
  constructor(readonly day: string) {
    super(`the AI budget of ${day} or its month is spent`);
    this.name = 'BudgetSpent';
  }
}

/**
 * Asks the model through [call] if [day] and its month have room for
 * [worst], the most the call can cost, and counts what it cost. Throws
 * [BudgetSpent], having asked nothing, when they have not.
 */
export async function withinBudget<T extends { usage: Usage | null }>(
  ledger: Ledger,
  day: string,
  worst: number,
  what: string,
  call: () => Promise<T>,
): Promise<T> {
  if (!(await ledger.reserve(day, worst))) throw new BudgetSpent(day);
  let usage: Usage | null = null;
  try {
    const out = await call();
    usage = out.usage;
    return out;
  } finally {
    await ledger.settle(day, worst, usage, what);
  }
}

/** A day's or a month's spending as it is kept. */
export interface Spend {
  /** Dollars spent, and dollars held back for calls under way. */
  usd: number;
  held: number;
  /** Tokens read and written, and the calls made. */
  input: number;
  output: number;
  calls: number;
  /** Calls turned away because a budget was spent. */
  refused: number;
  /** Dollars and calls by what asked. */
  by: Record<string, { usd: number; calls: number }>;
}

/** The spending in Firestore, ai/spend-{yyyy-mm-dd} and ai/spend-{yyyy-mm},
 * written by the server alone. */
export function firestoreLedger(db: Firestore, limits: Limits = LIMITS): Ledger {
  const docs = (day: string) => [db.collection('ai').doc(`spend-${day}`), db.collection('ai').doc(`spend-${day.slice(0, 7)}`)];
  return {
    reserve: (day, usd) =>
      db.runTransaction(async (t) => {
        const [dayRef, monthRef] = docs(day);
        const [d, m] = await Promise.all([t.get(dayRef), t.get(monthRef)]);
        const used = (s: typeof d) => (s.get('usd') ?? 0) + Math.max(0, s.get('held') ?? 0);
        if (used(d) + usd > limits.day || used(m) + usd > limits.month) {
          t.set(dayRef, { refused: FieldValue.increment(1) }, { merge: true });
          t.set(monthRef, { refused: FieldValue.increment(1) }, { merge: true });
          return false;
        }
        t.set(dayRef, { held: FieldValue.increment(usd) }, { merge: true });
        t.set(monthRef, { held: FieldValue.increment(usd) }, { merge: true });
        return true;
      }),
    settle: async (day, held, usage, what) => {
      const usd = usage ? costOf(usage) : 0;
      const calls = usage ? 1 : 0;
      const counted = {
        held: FieldValue.increment(-held),
        usd: FieldValue.increment(usd),
        input: FieldValue.increment(usage?.input_tokens ?? 0),
        output: FieldValue.increment(usage?.output_tokens ?? 0),
        calls: FieldValue.increment(calls),
        by: { [what]: { usd: FieldValue.increment(usd), calls: FieldValue.increment(calls) } },
      };
      const batch = db.batch();
      for (const ref of docs(day)) batch.set(ref, counted, { merge: true });
      await batch.commit();
    },
  };
}

/** The spending in memory, for tests and for a run of the news on a laptop:
 * days under yyyy-mm-dd, months under yyyy-mm. */
export function memoryLedger(limits: Partial<Limits> = {}): Ledger & { spend: Map<string, Spend> } {
  const { day: dayLimit, month: monthLimit } = { ...LIMITS, ...limits };
  const spend = new Map<string, Spend>();
  const of = (key: string): Spend => {
    let s = spend.get(key);
    if (!s) {
      s = { usd: 0, held: 0, input: 0, output: 0, calls: 0, refused: 0, by: {} };
      spend.set(key, s);
    }
    return s;
  };
  const used = (s: Spend) => s.usd + Math.max(0, s.held);
  return {
    spend,
    async reserve(day, usd) {
      const d = of(day);
      const m = of(day.slice(0, 7));
      if (used(d) + usd > dayLimit || used(m) + usd > monthLimit) {
        d.refused++;
        m.refused++;
        return false;
      }
      d.held += usd;
      m.held += usd;
      return true;
    },
    async settle(day, held, usage, what) {
      const usd = usage ? costOf(usage) : 0;
      for (const s of [of(day), of(day.slice(0, 7))]) {
        s.held -= held;
        s.usd += usd;
        s.input += usage?.input_tokens ?? 0;
        s.output += usage?.output_tokens ?? 0;
        s.calls += usage ? 1 : 0;
        const w = (s.by[what] ??= { usd: 0, calls: 0 });
        w.usd += usd;
        w.calls += usage ? 1 : 0;
      }
    },
  };
}
