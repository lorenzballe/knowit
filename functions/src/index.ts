import { initializeApp } from 'firebase-admin/app';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { defineSecret } from 'firebase-functions/params';

import { checkCard } from './card';
import {
  StoredCard,
  isDuplicate,
  liveCards,
  publish,
  questionsFor,
  recordReject,
} from './catalogue';
import { planBriefs, readDemand, readSupply } from './demand';
import { MODEL, client, draft, kBatch, review } from './write';

initializeApp();

/**
 * The key, and the only place it exists.
 *
 * Set once, out of band:
 *
 *   firebase functions:secrets:set ANTHROPIC_API_KEY
 *
 * It is mounted into these two functions and nothing else. It is not in the
 * repository, not in an environment file, and not reachable from the app: the
 * client's entire interface to the writer is reading cards that have already
 * been written.
 */
const ANTHROPIC_API_KEY = defineSecret('ANTHROPIC_API_KEY');

/** How many cards a scheduled run tries to add. */
const kPerRun = 12;

/**
 * Writes cards and publishes the ones that survive.
 *
 * Three gates, in increasing order of cost, so the expensive one runs on the
 * fewest cards: the schema, then the checks that need no knowledge of the
 * world, then a second model with the answers in front of it. A card that
 * fails any of them is kept with its reason and never served.
 */
async function grow(apiKey: string, wanted: number): Promise<{
  written: number;
  rejected: number;
}> {
  const existing = await liveCards();
  const [demand, supply] = [await readDemand(), readSupply(existing)];
  const briefs = planBriefs(demand, supply, wanted);
  const anthropic = client(apiKey);

  const accepted: StoredCard[] = [];
  let rejected = 0;

  for (let at = 0; at < briefs.length; at += kBatch) {
    const slice = briefs.slice(at, at + kBatch);
    const topics = new Set(slice.map((b) => b.topic));
    const drafted = await draft(
      anthropic,
      slice,
      questionsFor([...existing, ...accepted], topics),
    );

    // Everything cheap first: nothing is worth a review call until it is at
    // least a well-formed card that is not already in the catalogue.
    const worthReviewing = [];
    for (const card of drafted) {
      const reasons = checkCard(card);
      const duplicate = isDuplicate(card, [...existing, ...accepted]);
      if (duplicate) reasons.push(duplicate);
      if (reasons.length) {
        rejected += 1;
        await recordReject(card, reasons);
        continue;
      }
      worthReviewing.push(card);
    }

    const failed = await review(anthropic, worthReviewing);
    for (const card of worthReviewing) {
      const wrong = failed.get(card.id);
      if (wrong) {
        rejected += 1;
        await recordReject(card, [`review: ${wrong}`]);
        continue;
      }
      accepted.push({ ...card, writtenAt: Date.now(), writtenBy: MODEL });
    }
  }

  await publish(accepted);
  logger.info('catalogue grown', {
    written: accepted.length,
    rejected,
    asked: briefs.length,
  });
  return { written: accepted.length, rejected };
}

/**
 * The catalogue grows overnight.
 *
 * Daily rather than on demand: a reader who opens the app must never wait on
 * a model, and cards are worth having before anyone asks for them. It runs at
 * 03:00 UTC because a failure then is noticed before the morning nudge goes
 * out, not after.
 */
export const growCatalogue = onSchedule(
  {
    schedule: 'every day 03:00',
    timeZone: 'Etc/UTC',
    secrets: [ANTHROPIC_API_KEY],
    timeoutSeconds: 540,
    memory: '512MiB',
    retryCount: 1,
  },
  async () => {
    await grow(ANTHROPIC_API_KEY.value(), kPerRun);
  },
);

/**
 * The same thing, on demand, for whoever runs the app.
 *
 * Gated on a custom claim rather than on being signed in: every reader has an
 * account, so "signed in" is not an authorisation, and an endpoint that spends
 * money on the model has to be one that only its owner can call.
 *
 *   firebase auth:import, or the Admin SDK:
 *   admin.auth().setCustomUserClaims(uid, { editor: true })
 */
export const writeCards = onCall(
  { secrets: [ANTHROPIC_API_KEY], timeoutSeconds: 540, memory: '512MiB' },
  async (request) => {
    if (request.auth?.token?.editor !== true) {
      throw new HttpsError('permission-denied', 'Editors only.');
    }
    const asked = Number(request.data?.count ?? kBatch);
    if (!Number.isInteger(asked) || asked < 1 || asked > 30) {
      throw new HttpsError('invalid-argument', 'Ask for between 1 and 30.');
    }
    return grow(ANTHROPIC_API_KEY.value(), asked);
  },
);
