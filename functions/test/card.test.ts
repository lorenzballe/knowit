import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { Card, checkCard, kSameCard, overlap, shingle } from '../src/card';
import { isDuplicate, questionsFor, StoredCard } from '../src/catalogue';
import { planBriefs, readSupply } from '../src/demand';

/** A card that passes everything, to be broken one field at a time. */
function good(over: Partial<Card> = {}): Card {
  return {
    id: 'space-g7',
    topic: 'space',
    tags: ['light', 'distance'],
    tone: 'startling',
    difficulty: 'medium',
    move: 'estimation',
    question: 'A star goes out tonight. When could you know?',
    answer: 'Not before its light has crossed the distance, which for the nearest one is over four years.',
    barMove: 'Nothing anyone sees in the sky is now.',
    source: 'NASA, Alpha Centauri fact sheet',
    hint: 'Distance over speed, in the units you already know.',
    trap: 'That the sky shows the present.',
    steps: ['Light does 300,000 km/s', 'The distance is 4.2 light years', 'So four years and change'],
    simply: '',
    counterpoint: '',
    seconds: 40,
    challenge: {
      kind: 'pick',
      options: ['At once', 'In four years', 'In four hours', 'Never'],
      correct: 1,
      answer: null,
      unit: '',
      tolerance: null,
      factor: null,
      positions: [],
    },
    ...over,
  };
}

describe('what a card has to be before anyone sees it', () => {
  it('passes one that is right', () => {
    assert.deepEqual(checkCard(good()), []);
  });

  it('refuses a graded card with no worked solution', () => {
    // The app's claim is that it tells you why you were wrong. This is the
    // one failure that breaks the claim rather than disappointing.
    assert.ok(checkCard(good({ steps: [] })).some((r) => r.includes('worked solution')));
    assert.ok(checkCard(good({ trap: '' })).some((r) => r.includes('trap')));
  });

  it('refuses an answer that is not one of the options', () => {
    const card = good();
    card.challenge.correct = 9;
    assert.ok(checkCard(card).some((r) => r.includes('correct is not one')));
  });

  it('refuses the giveaways every quiz writer produces', () => {
    const longest = good();
    longest.challenge.options = ['Yes', 'No', 'It depends on the distance to the star and how fast light travels'];
    longest.challenge.correct = 2;
    assert.ok(checkCard(longest).some((r) => r.includes('longest')));

    const above = good();
    above.challenge.options = ['At once', 'In four years', 'All of the above'];
    assert.ok(checkCard(above).some((r) => r.includes('above')));

    const twice = good();
    twice.challenge.options = ['At once', 'At once', 'In four years'];
    assert.ok(checkCard(twice).some((r) => r.includes('duplicate')));
  });

  it('refuses a card whose question contains its own answer', () => {
    const leaky = good({
      question: 'Would you know in four years, or at once?',
    });
    assert.ok(checkCard(leaky).some((r) => r.includes('contains the answer')));
  });

  it('refuses an id that does not match the pool convention', () => {
    assert.ok(checkCard(good({ id: 'g7' })).length > 0);
    assert.ok(checkCard(good({ id: 'science-g7' })).length > 0);
    assert.deepEqual(checkCard(good({ id: 'space-a' })), []);
  });

  it('refuses a card with nothing to match a reader on', () => {
    assert.ok(checkCard(good({ tags: [] })).some((r) => r.includes('never be matched')));
    assert.ok(checkCard(good({ tags: ['Money Stuff!'] })).length > 0);
  });

  it('refuses a debate with no case against', () => {
    const debate = good({
      steps: [],
      trap: '',
      hint: '',
      challenge: { ...good().challenge, kind: 'side', positions: ['yes', 'no'], correct: null },
    });
    assert.ok(checkCard(debate).some((r) => r.includes('no case against')));
    assert.deepEqual(
      checkCard({ ...debate, counterpoint: 'The strongest case the other way, at length enough to be one.' }),
      [],
    );
  });
});

describe('telling one card from another', () => {
  const held: StoredCard[] = [
    {
      ...good({ id: 'space-a1', question: 'How long does light from the sun take to reach the earth?' }),
      writtenAt: 1,
      writtenBy: 'test',
    },
  ];

  it('catches the same question asked again in other words', () => {
    const again = good({
      id: 'space-b2',
      question: 'How long does sunlight take to reach earth?',
    });
    assert.ok(isDuplicate(again, held));
  });

  it('lets a genuinely different card about the same thing through', () => {
    const different = good({
      id: 'space-b3',
      question: 'A star goes out tonight — when could anyone know?',
    });
    assert.equal(isDuplicate(different, held), null);
  });

  it('catches a reused id', () => {
    assert.ok(isDuplicate(good({ id: 'space-a1' }), held));
  });

  it('measures overlap the way the threshold assumes', () => {
    assert.equal(overlap(shingle('a a a'), shingle('')), 0);
    assert.ok(overlap(shingle('light sun earth'), shingle('light sun earth')) >= kSameCard);
  });

  it('shows the writer what it has already asked, nearest subject first', () => {
    const questions = questionsFor(held, new Set(['space']));
    assert.ok(questions[0].startsWith('space-a1:'));
  });
});

describe('deciding what to write next', () => {
  const held: StoredCard[] = Array.from({ length: 10 }, (_, i) => ({
    ...good({ id: `space-x${i}` }),
    writtenAt: 1,
    writtenBy: 'test',
  }));

  it('writes toward what readers want and away from what there is plenty of', () => {
    const supply = readSupply(held);
    const demand = new Map([['topic:history', 5]]);
    const briefs = planBriefs(demand, supply, 6);
    // Space has ten cards and nobody asking; history has none and demand.
    assert.equal(briefs[0].topic, 'history');
    assert.ok(!briefs.slice(0, 3).some((b) => b.topic === 'space'));
  });

  it('still has something to write for a catalogue nobody has read yet', () => {
    const briefs = planBriefs(new Map(), new Map(), 6);
    assert.equal(briefs.length, 6);
    assert.ok(new Set(briefs.map((b) => b.topic)).size > 1);
  });

  it('keeps a batch mostly asking, with at most one debate', () => {
    const briefs = planBriefs(new Map(), new Map(), 10);
    const asking = briefs.filter((b) => b.kind !== 'none');
    assert.equal(asking.length, 8);
    assert.ok(briefs.filter((b) => b.kind === 'side').length <= 1);
  });
});
