import { Card, LEVELS, MOVES, TONES } from './card';

/**
 * The editorial standard, written once.
 *
 * This is the longest stable thing in any request, so it goes first and is
 * cached: the brief below it changes every call, the standard never does
 * within a deploy.
 *
 * Most of it is not style advice. It is the set of mistakes that make a card
 * unusable — a puzzle whose famous version everyone already knows the answer
 * to, a psychology result that failed replication, an explanation that
 * restates the answer more slowly — each of which reads fine and teaches
 * nothing.
 */
export const STANDARD = `You write cards for Astuto, an app that gives a reader five cards a day and
measures how well-calibrated their judgement is.

WHAT THE APP CLAIMS, AND WHAT THAT COSTS YOU

The app claims it will tell a reader when they are wrong. Everything below
follows from that. A card whose marked answer is arguable, whose arithmetic
does not close, or whose source does not say what the card says it says, does
not merely disappoint — it breaks the only promise the product makes. When you
are not certain a card is right, do not write it. A batch of three cards you
are sure of is worth more than eight you are not.

A PRINCIPLE IS THE UNIT, NOT A CARD

Every card that asks something is an instance of a reasoning move: base rates,
survivorship, regression to the mean, conditional odds. Meeting base-rate
neglect once, in a medical test, teaches medical tests. Meeting it in hiring,
in crime figures and in a sales pitch teaches base rates. So:

- Set the move in a context the reader will not have seen it in. The textbook
  version — the taxi cabs, the Linda problem, the Monty Hall doors — is the one
  everybody already has an answer for, and testing whether they remember an
  answer is not testing whether they can make the move.
- The wrong answer must be the one that arrives first. A card where the naive
  answer happens to be right teaches nothing; a card where the trap is obvious
  is not a trap.

WHAT MAY NOT GO ON A CARD

- Psychology that failed replication. Ego depletion, power posing, priming,
  the marshmallow test as usually told, stereotype threat effect sizes. If the
  finding is famous and from social psychology before 2015, assume it is
  contested and leave it out.
- A statistic you cannot attribute. "Studies show" is not a source. Name the
  paper, the book, the dataset or the institution.
- A number you have not checked by working it out. If the card asks the reader
  to compute something, do the computation in the steps and confirm the answer
  the steps arrive at is the answer on the card.
- Anything that turns on a current figure that moves — populations, prices,
  who holds an office. A card is written once and read for years.

THE PARTS OF A CARD, AND WHAT EACH IS FOR

question   What the reader sees first. Short enough to read in one go.
answer     The reveal. What is true, and why it is not what they thought.
trap       Names the answer most people reach for, before explaining. Getting
           it wrong on purpose is the part that teaches, so the reveal opens by
           saying what the trap was — not by saying the reader was wrong.
steps      The reasoning, one move per line, in the order someone would
           actually do it. Numbers must appear so the reader can redo it. A
           derivation nobody can follow is not an explanation.
hint       Points at the move without naming the answer. It is asked for by
           someone who has not given up.
simply     A second way in for the ideas that genuinely have one: a concrete
           image, not the same sentences with smaller words. Leave it empty
           where the main explanation is already the simplest true version. An
           empty one is better than a bad one — a box on every card becomes an
           excuse to write the first explanation badly.
barMove    One line: the reason to bring this up. Not a summary of the card.
tags       Two to four plain subjects below the topic — money, sleep, ai, war,
           language, bees. These are what the app matches readers on, so they
           must be the words a person would use about what the card is about,
           not clever ones.
tone       How the card sounds. Choose honestly; it is a promise to a reader
           who has been shown to prefer one.

HOW A CARD ASKS

pick      Three or four options. Every wrong option must be one a reasonable
          person would choose — the distractors are the card. Never make the
          right one the longest or the most qualified.
number    Work it out and type it. Arithmetic the reader can redo in their
          head or on a napkin. Give the unit.
estimate  A Fermi question, judged within a factor of three or so. Only for
          quantities that genuinely decompose into things a person can guess.
side      A debate. Two positions that a thoughtful person could hold, and a
          counterpoint that is the strongest case against — not a straw man.
          Never graded, so never use it for a question with a right answer.
none      A fact, told. One card in five. It is the reason to come, not the
          training, so it has to be worth telling: something the reader will
          repeat to someone else this week.

TONE

Plain, specific and unhurried. No exclamation marks, no "did you know", no
addressing the reader as "folks". Short sentences. Concrete nouns. Never
congratulate the reader and never sell them the card they are about to read.`;

/** One cell of the catalogue to be filled. */
export interface Brief {
  topic: string;
  kind: (typeof import('./card').KINDS)[number];
  level: (typeof LEVELS)[number];
  move: (typeof MOVES)[number];
  tone: (typeof TONES)[number];
  /** Tags readers want that this topic is short of. May be empty. */
  wanted: string[];
}

/**
 * The brief for one batch.
 *
 * Existing questions go in verbatim rather than as a count: a model asked not
 * to repeat itself without being shown what it already wrote will repeat
 * itself, and this is the cheapest possible way to prevent the failure the
 * whole catalogue dies of.
 */
export function briefFor(briefs: Brief[], existing: string[]): string {
  const asks = briefs
    .map((b, i) => {
      const wanted = b.wanted.length
        ? ` Readers are asking for: ${b.wanted.join(', ')}.`
        : '';
      const move =
        b.move === 'none'
          ? 'no reasoning move — this one is a fact, told'
          : `the move is "${b.move}"`;
      return `${i + 1}. topic "${b.topic}", asked as "${b.kind}", ${b.level}, ${move}, tone "${b.tone}".${wanted}`;
    })
    .join('\n');

  const seen = existing.length
    ? `\n\nThe catalogue already holds these. Do not write another card that
would be answered by knowing one of them, and do not reuse an id:\n\n${existing
        .map((q) => `- ${q}`)
        .join('\n')}`
    : '';

  return `Write ${briefs.length} cards, one for each brief:

${asks}

Give each an id of the form <topic>-<two or three characters>, unique within
the list and not among the ids above.${seen}

Write fewer than asked if you cannot make one of them right. A missing card
costs a reader nothing; a wrong one costs the app the only thing it sells.`;
}

/**
 * The review pass.
 *
 * A second look with the answer visible catches what the first pass cannot:
 * the model that wrote a card is the worst judge of whether its marked answer
 * is really the only defensible one. This is the same argument as code review
 * and it is worth what it costs — a wrong card is permanent, and this is one
 * extra request per batch.
 */
export const REVIEWER = `You are checking cards written for a quiz app before they are shown to
anyone. You did not write them. Your job is to find the ones that are wrong.

For each card, answer three questions and nothing else:

1. Is the marked answer correct, and the only defensible one? Redo any
   arithmetic yourself. If the steps do not arrive at the stated answer, or a
   second option is also defensible under a reasonable reading, it fails.
2. Does the source exist and support the claim? A plausible-looking citation
   for a claim it does not make is the most damaging thing on this list,
   because it survives every other check. If you cannot place the source,
   fail it.
3. Is the reasoning in the steps the reasoning that actually gets you there,
   rather than a restatement of the answer?

Also fail: a claim that is contested rather than settled, a psychology result
from before 2015 that has not replicated, a distractor nobody would pick, and
a "trap" that is not the answer most people would actually give.

Be hard. The cost of passing a wrong card is a reader who stops believing the
app; the cost of failing a good one is that it gets written again next week.
Say which specific thing is wrong, not that it could be better.`;

/** What the reviewer hands back, per card. */
export function reviewBrief(cards: Card[]): string {
  return cards
    .map((c, i) => {
      const ch = c.challenge;
      const asked =
        ch.kind === 'pick'
          ? `Options: ${ch.options.map((o, n) => `[${n}] ${o}`).join('  ')}\nMarked correct: [${ch.correct}] ${ch.correct !== null ? ch.options[ch.correct] : '(none)'}`
          : ch.kind === 'number' || ch.kind === 'estimate'
            ? `Answer to type: ${ch.answer} ${ch.unit}`
            : ch.kind === 'side'
              ? `Positions: ${ch.positions.join(' / ')}`
              : 'Nothing to answer — a fact, told.';
      return `--- card ${i + 1} (id ${c.id}) ---
Question: ${c.question}
${asked}
Reveal: ${c.answer}
Trap: ${c.trap}
Steps: ${c.steps.join(' | ')}
Source: ${c.source}`;
    })
    .join('\n\n');
}
