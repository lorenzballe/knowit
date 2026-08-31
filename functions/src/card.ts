import { z } from 'zod';

/**
 * What a card is, on the wire.
 *
 * This file is the contract between the model that writes cards and the app
 * that shows them. It is deliberately the strictest thing in the repository:
 * a card that reaches a reader with the wrong option marked correct is worse
 * than no card at all, because the app's whole claim is that it will tell you
 * when you are wrong.
 *
 * The Dart side of the same contract is `lib/data/card_codec.dart`. The two
 * are checked against each other by `npm run typecheck` and by the Dart tests
 * respectively — neither can prove the other, so both validate on arrival.
 */

/** Subject keys. Must match `kTopics` in lib/data/topics.dart. */
export const TOPICS = [
  'thinking',
  'science',
  'space',
  'psychology',
  'economics',
  'technology',
  'history',
  'human_body',
  'philosophy',
  'pop_culture',
  'nature',
  'language',
  'weird_facts',
] as const;

/** Must match `Principle` in lib/models/pill.dart. */
export const MOVES = [
  'none',
  'baseRate',
  'survivorship',
  'regression',
  'confirmation',
  'anchoring',
  'sampling',
  'confounding',
  'counterfactual',
  'multipleComparisons',
  'availability',
  'sunkCost',
  'conjunction',
  'conditional',
  'independence',
  'coincidence',
  'exponential',
  'reflection',
  'simpson',
  'estimation',
  'computation',
] as const;

/** Must match `Tone` in lib/models/pill.dart. */
export const TONES = ['playful', 'startling', 'practical', 'sober'] as const;

/** Must match `Difficulty` in lib/models/pill.dart. */
export const LEVELS = ['easy', 'medium', 'hard'] as const;

/** Must match the `kind` switch in `Challenge.fromJson`. */
export const KINDS = ['none', 'pick', 'number', 'estimate', 'side'] as const;

/**
 * The challenge, flattened.
 *
 * A union would model this better and structured outputs are happiest with a
 * flat object whose every field is required, so the unused fields are
 * explicitly null and `checkCard` is what enforces which of them may be.
 */
const ChallengeSchema = z.object({
  kind: z.enum(KINDS),
  options: z.array(z.string()).describe('pick: 3 or 4 options, all plausible'),
  correct: z.number().int().nullable().describe('pick: index into options'),
  answer: z.number().nullable().describe('number/estimate: the right answer'),
  unit: z.string().describe('number/estimate: what the number counts'),
  tolerance: z.number().nullable().describe('number: allowed slack, usually 0'),
  factor: z
    .number()
    .nullable()
    .describe('estimate: anything within this factor counts, usually 3'),
  positions: z.array(z.string()).describe('side: exactly two positions'),
});

export const CardSchema = z.object({
  id: z
    .string()
    .describe('the topic key, a dash, then 1-6 lowercase characters: space-g7'),
  topic: z.enum(TOPICS),
  tags: z
    .array(z.string())
    .describe('2 to 4 lowercase subjects below the topic, e.g. money, sleep'),
  tone: z.enum(TONES),
  difficulty: z.enum(LEVELS),
  move: z.enum(MOVES).describe('the reasoning move, or none for a plain fact'),
  question: z.string().describe('the front of the card, under 160 characters'),
  answer: z.string().describe('the reveal, 1 to 3 sentences'),
  barMove: z.string().describe('one line: the reason to bring this up'),
  source: z.string().describe('a real, checkable citation'),
  hint: z.string().describe('points at the idea without giving it away'),
  trap: z.string().describe('names the answer most people reach for first'),
  steps: z
    .array(z.string())
    .describe('the reasoning worked through, one move per line'),
  simply: z
    .string()
    .describe('a concrete second way in, or empty where there is not one'),
  counterpoint: z
    .string()
    .describe('debate only: the strongest case against, otherwise empty'),
  seconds: z.number().int().describe('how long the card takes to get through'),
  challenge: ChallengeSchema,
});

export type Card = z.infer<typeof CardSchema>;

export const BatchSchema = z.object({ cards: z.array(CardSchema) });

/**
 * Everything about a card that can be checked without knowing anything about
 * the world.
 *
 * Structured output guarantees the shape, and none of the below: a schema
 * cannot say that the option marked correct must not be the only one with a
 * number in it, or that a graded card owes the reader an explanation. Those
 * are the mistakes a card writer actually makes, so they are checked here.
 *
 * Returns the reasons it fails; an empty list is a pass.
 */
export function checkCard(card: Card): string[] {
  const bad: string[] = [];
  const c = card.challenge;

  // The pool's own convention, kept because ids are how a card is looked up
  // and a second convention would mean two: <topic key>-<short suffix>.
  if (!new RegExp(`^${card.topic}-[a-z0-9]{1,6}$`).test(card.id)) {
    bad.push(`id must read ${card.topic}-xx`);
  }
  if (card.question.length > 200) bad.push('question is too long for a card');
  if (card.answer.length < 20) bad.push('answer is too short to be one');
  if (card.source.trim().length < 4) bad.push('no source');
  if (card.seconds < 10 || card.seconds > 300) bad.push('implausible duration');
  if (card.tags.length < 1) bad.push('no tags, so it can never be matched');
  if (card.tags.some((t) => !/^[a-z0-9][a-z0-9 -]{1,24}$/.test(t))) {
    bad.push('a tag is not a plain lowercase subject');
  }

  const graded = c.kind === 'pick' || c.kind === 'number' || c.kind === 'estimate';
  if (graded) {
    // The reveal is the entire product on a card someone got wrong. A graded
    // card without one is the failure this pipeline exists to prevent.
    if (card.steps.length < 2) bad.push('graded card with no worked solution');
    if (card.trap.trim().length < 10) bad.push('graded card names no trap');
    if (card.hint.trim().length < 10) bad.push('graded card offers no hint');
  }

  switch (c.kind) {
    case 'pick': {
      if (c.options.length < 3 || c.options.length > 4) {
        bad.push('a pick needs three or four options');
      }
      if (c.correct === null || c.correct < 0 || c.correct >= c.options.length) {
        bad.push('correct is not one of the options');
      }
      const seen = new Set(c.options.map((o) => o.trim().toLowerCase()));
      if (seen.size !== c.options.length) bad.push('duplicate options');
      if (c.options.some((o) => /all|none of (the )?above/i.test(o))) {
        bad.push('an all-of-the-above option');
      }
      // The oldest giveaway in multiple choice: the true answer is the one
      // that had to be qualified, so it is the long one.
      if (c.correct !== null && c.options[c.correct]) {
        const right = c.options[c.correct].length;
        const others = c.options.filter((_, i) => i !== c.correct);
        if (others.every((o) => right > o.length * 1.6)) {
          bad.push('the right option is conspicuously the longest');
        }
      }
      break;
    }
    case 'number':
      if (c.answer === null) bad.push('no answer to type');
      if (c.tolerance !== null && c.tolerance < 0) bad.push('negative tolerance');
      break;
    case 'estimate':
      if (c.answer === null || c.answer <= 0) bad.push('estimate needs a positive answer');
      if (c.factor !== null && c.factor < 1.5) bad.push('estimate band is too tight');
      break;
    case 'side':
      if (c.positions.length !== 2) bad.push('a debate has exactly two sides');
      if (card.counterpoint.trim().length < 30) {
        bad.push('a debate with no case against');
      }
      break;
    case 'none':
      break;
  }

  // A question that contains its own answer.
  if (graded && c.kind === 'pick' && c.correct !== null) {
    const right = c.options[c.correct]?.trim().toLowerCase();
    if (right && right.length > 4 && card.question.toLowerCase().includes(right)) {
      bad.push('the question contains the answer');
    }
  }

  return bad;
}

/** Words that carry meaning, for telling two cards apart. */
export function shingle(text: string): Set<string> {
  const stop = new Set([
    'the', 'a', 'an', 'of', 'in', 'on', 'to', 'is', 'are', 'was', 'were',
    'and', 'or', 'but', 'for', 'with', 'that', 'this', 'it', 'as', 'by',
    'how', 'what', 'why', 'you', 'your', 'more', 'than', 'from', 'at',
  ]);
  return new Set(
    text
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, ' ')
      .split(/\s+/)
      .filter((w) => w.length > 2 && !stop.has(w)),
  );
}

/** How much two cards overlap, 0 to 1. */
export function overlap(a: Set<string>, b: Set<string>): number {
  if (a.size === 0 || b.size === 0) return 0;
  let shared = 0;
  for (const w of a) if (b.has(w)) shared += 1;
  return shared / Math.min(a.size, b.size);
}

/**
 * Above this, two cards are the same card. Set by hand against the existing
 * pool: genuinely different cards about the same subject land around 0.4.
 */
export const kSameCard = 0.6;
