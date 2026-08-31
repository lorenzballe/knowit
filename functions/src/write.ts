import Anthropic from '@anthropic-ai/sdk';
import { zodOutputFormat } from '@anthropic-ai/sdk/helpers/zod';
import { z } from 'zod';
import { logger } from 'firebase-functions';
import { BatchSchema, Card, CardSchema, checkCard } from './card';
import { Brief, REVIEWER, STANDARD, briefFor, reviewBrief } from './prompt';

/**
 * The two calls that write the catalogue.
 *
 * The API key never leaves this process. It is a Cloud Functions secret,
 * mounted into the environment at run time and read here — never in the
 * Flutter app, never in a build, never in a config file the client fetches.
 * That is the whole reason the writer is a server and not a screen: a key
 * shipped inside an app is a key that has been given away, and the bill for
 * one that has been given away is unbounded.
 */

export const MODEL = 'claude-opus-5';

/**
 * A batch is small on purpose.
 *
 * Asking for thirty cards at once gets thirty cards that resemble each other,
 * because everything after the tenth is written in the shadow of the first
 * ten. Six at a time, several times, costs slightly more and is the
 * difference between a catalogue and a list.
 */
export const kBatch = 6;

const VerdictSchema = z.object({
  verdicts: z.array(
    z.object({
      id: z.string(),
      passes: z.boolean(),
      wrong: z
        .string()
        .describe('what specifically is wrong, empty when it passes'),
    }),
  ),
});

export function client(apiKey: string): Anthropic {
  return new Anthropic({ apiKey });
}

/** Cards as written, before anything has checked them. */
export async function draft(
  anthropic: Anthropic,
  briefs: Brief[],
  existing: string[],
): Promise<Card[]> {
  const response = await anthropic.messages.parse({
    model: MODEL,
    max_tokens: 16000,
    // The standard is the same on every call and the brief never is, so the
    // long half goes in `system` where it caches and the short half does not.
    system: [
      { type: 'text', text: STANDARD, cache_control: { type: 'ephemeral' } },
    ],
    thinking: { type: 'adaptive' },
    output_config: {
      effort: 'high',
      format: zodOutputFormat(BatchSchema),
    },
    messages: [{ role: 'user', content: briefFor(briefs, existing) }],
  });

  if (response.stop_reason === 'refusal') {
    logger.warn('the writer declined this brief', {
      category: response.stop_details?.category,
    });
    return [];
  }
  return response.parsed_output?.cards ?? [];
}

/**
 * A second opinion, with the answers visible.
 *
 * Separate call, no memory of having written them: a model shown its own
 * reasoning will defend it, and the failure being looked for here — an answer
 * that is defensible rather than right — is exactly the one the first pass
 * cannot see.
 */
export async function review(
  anthropic: Anthropic,
  cards: Card[],
): Promise<Map<string, string>> {
  if (cards.length === 0) return new Map();
  const response = await anthropic.messages.parse({
    model: MODEL,
    max_tokens: 16000,
    system: [
      { type: 'text', text: REVIEWER, cache_control: { type: 'ephemeral' } },
    ],
    thinking: { type: 'adaptive' },
    output_config: { effort: 'high', format: zodOutputFormat(VerdictSchema) },
    messages: [{ role: 'user', content: reviewBrief(cards) }],
  });

  const failed = new Map<string, string>();
  if (response.stop_reason === 'refusal') {
    // Nothing was checked, so nothing may be published. Failing closed is the
    // only safe direction: an unreviewed card is not a reviewed one.
    for (const card of cards) failed.set(card.id, 'review did not run');
    return failed;
  }

  const seen = new Set<string>();
  for (const verdict of response.parsed_output?.verdicts ?? []) {
    seen.add(verdict.id);
    if (!verdict.passes) {
      failed.set(verdict.id, verdict.wrong || 'the reviewer failed it');
    }
  }
  // A card the reviewer skipped has not passed review.
  for (const card of cards) {
    if (!seen.has(card.id)) failed.set(card.id, 'the reviewer did not reach it');
  }
  return failed;
}

/**
 * Reads a card back from the model's own output.
 *
 * The parse is done again here rather than trusted from `parsed_output`
 * because a card can also arrive from the manual endpoint, where a person
 * typed it.
 */
export function readCard(raw: unknown): { card?: Card; reasons: string[] } {
  const parsed = CardSchema.safeParse(raw);
  if (!parsed.success) {
    return { reasons: parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`) };
  }
  const reasons = checkCard(parsed.data);
  return reasons.length ? { reasons } : { card: parsed.data, reasons: [] };
}
