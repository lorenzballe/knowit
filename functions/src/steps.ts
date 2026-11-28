// The first run's four steps, counted across every phone and nothing about
// who: how many phones opened the app for the first time on a day, how many
// finished the first run, how many finished a first day, and how many came
// back the day after their first open (lib/measure/first_steps.dart).
//
// Those four say whether the first run works, and they are asked before a
// reader has been asked about usage data, which comes at the end of their
// first day: so they are counted here, as the day's games are (daily.ts),
// and not in PostHog. A phone sends the step's name and the day it took it
// on its own calendar, and nothing else: no account, no token, no identifier
// of the phone. The count keeps even less: a total per step per day, in
// steps/{day}, which no phone reads or writes (firestore.rules). The phone
// keeps a flag of its own so that each step is counted once per phone; the
// server could not tell a second count from a second phone, and is not
// meant to.

import type { Firestore } from 'firebase-admin/firestore';
import { FieldValue } from 'firebase-admin/firestore';

import { localDate, parseDate, shiftDate } from './bank.js';

/** The steps there are, in the order a reader takes them: the only names counted. */
export const STEPS = ['first_open', 'first_run_done', 'first_day_done', 'next_day'] as const;

export type Step = (typeof STEPS)[number];

/** A step as it is counted: which, and the day it was taken on the phone's calendar. */
export interface Taken {
  step: Step;
  day: string;
}

/** The clocks a phone can be on, in minutes from UTC: from Baker Island to Kiribati. */
const WEST = -12 * 60;
const EAST = 14 * 60;

/**
 * Whether [day] may be counted at [nowMs]: today on some clock on Earth, or
 * yesterday on one, for a step taken before midnight that arrives after it.
 * The phone's offset is not asked for, so it is not sent.
 */
export function countableDay(day: string, nowMs: number): boolean {
  if (!parseDate(day)) return false;
  const first = shiftDate(localDate(nowMs, WEST), -1);
  const last = localDate(nowMs, EAST);
  return day >= first && day <= last;
}

/**
 * [data] as a step to count, or what is wrong with it: one of [STEPS], and
 * a day that is today or yesterday somewhere. Anything else the body holds
 * is not read.
 */
export function readStep(data: unknown, nowMs: number): Taken | string {
  const d = (data ?? {}) as { step?: unknown; day?: unknown };
  const step = typeof d.step === 'string' && (STEPS as readonly string[]).includes(d.step) ? (d.step as Step) : null;
  if (!step) return `A step: ${STEPS.join(', ')}.`;
  const day = typeof d.day === 'string' ? d.day : '';
  if (!countableDay(day, nowMs)) return 'A day that is today on some clock, or yesterday.';
  return { step, day };
}

/** Adds [taken] to its day's totals: steps/{day}, the step's own number one more. */
export async function countStep(db: Firestore, taken: Taken): Promise<void> {
  await db
    .collection('steps')
    .doc(taken.day)
    .set({ [taken.step]: FieldValue.increment(1) }, { merge: true });
}

/** A day's totals as they are kept: every step, nought where nothing was counted. */
export function totalsOf(data: Record<string, unknown> | undefined): Record<Step, number> {
  return Object.fromEntries(
    STEPS.map((s) => {
      const n = data?.[s];
      return [s, typeof n === 'number' && Number.isFinite(n) && n > 0 ? n : 0];
    }),
  ) as Record<Step, number>;
}
