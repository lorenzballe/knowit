# The content pipeline

Sixty cards that tell is twenty days of reading. The pipeline is what stands
between that and a product, and this is the shape it takes.

> **Where it is now.** The brief below is built here. Write, gate, sign-off
> and emit are built in `tool/cards/` — the bank is one JSON file per card
> there, not Dart, so *emit* writes a file and a pull request rather than
> Dart through the helpers; `tool/cards/README.md` has the loop as it runs.
> The brief reads that bank.

## The order, and why it is this order

    brief  →  write  →  gate  →  sign-off  →  emit

**Brief** (`brief.py`, built) works out what to write next from what is
already there. It is arithmetic over the pool and the genre tree, and it
talks to no model. Two things come out of it:

- **What runs out first.** A day is three tells and two asks; the pool is
  60 tells and 110 asks. The shapes do not match, so the tells end the
  runway on day 20 with about seventy asks nobody will ever reach. Until the
  two runways meet, a brief that commissions anything but tells is
  commissioning cards the app cannot deal.
- **Which genres.** The six subjects offered on the wheel with nothing
  written for them come first — a reader can pick Cinema today and be handed
  somebody else's subject all week — then the ones too thin to fill a day on
  their own. Inside a tier the brief is dealt round-robin: a half-written
  brief should leave every empty subject equally served, not one of them
  finished and five untouched.

**Write** is one card per request. Claude Opus 5 with adaptive thinking, and
structured outputs (`output_config.format`) so a card is schema-valid by
construction rather than by parsing. Nothing here is latency-sensitive, so it
goes through the Batch API at half the price. The card-writing constitution —
the voice, the rules below, the worked examples — is the stable prefix and
takes the cache breakpoint; the slot brief and the anti-duplication list go
after it, because they change every request.

**Gate** is three checks, cheapest first, and a card has to pass all three.

1. *Mechanical.* The pool's own tests already encode most of the bar and they
   run against a candidate unchanged: a unique id, a question, an answer or
   worked steps, a bar move, a source, sixty words unless it has steps, and
   no other card asking the same thing (content-word overlap under half).
   There is also a blocklist of material every "did you know" account has
   already run — a card has to earn its place against what people scroll past
   for free.
2. *Factual.* The one an LLM cannot do alone, and the one that matters most:
   web search, and a real source URL that says what the card says. **A card
   with an invented source is worse than no card**, because it is the claim
   the whole app rests on.
3. *Editorial.* A second pass as judge, against the voice rules, scoring on a
   rubric rather than answering yes or no — so a near miss comes back with
   what to fix instead of being thrown away.

**Sign-off** is a person. A generated card lands in a review queue, never in
the pool. This is cheap — accept, reject, edit — and it is what keeps the
quality claim honest; the day it is skipped is the day the app ships
something it would be embarrassed by.

**Emit** writes Dart through the pool's existing five helpers, so the tests
that guard the pool guard the generated cards too, with nothing to change.

## What personalisation means here, and what it does not

There are two readings of "the AI tracks the reader", and they lead to
different apps.

**Cards written per reader, on demand.** It breaks more than it gives. The
question of the day is the one card everybody meets on the same day — it is
what friends compare and what the shared board is made of. Calibration only
means something if two readers answering the same card can be compared. A
card has to exist before the review ladder can bring it back. And nobody can
review what is written once, for one person, at the moment they open the app.

**One catalogue, commissioned from aggregate demand; the personalisation in
the dealer.** Everything above survives, and it is where the 108 genres
point. This is the shape assumed here.

So the split is:

- **On the phone, per reader:** which subjects and genres they asked for,
  what they got right, how sure they said they were, what they kept, what
  they said out loud. The dealer reads all of it. It never leaves.
- **Off the phone, in aggregate:** how many readers asked for a genre, and
  how fast each genre is being consumed. Counts, by genre, over everybody.

That line is not a nicety. The app's own rule is that measurement carries no
prose — not the name, not the email, not the reason written beside an answer.
A pipeline that uploaded reader profiles to steer a model would break that
promise for a result it can get from counts.

## The bar a card has to clear

From the pool's tests and the README's own rules, which is what the writing
prompt is built from:

- A question worth asking, an answer under sixty words unless it is worked
  through as steps, a bar move, and a source that exists.
- Off the listicle. If a reader has met it before, it teaches nothing.
- Not another card in different words.
- Either it tells or it asks, and if it asks it grades itself: options with
  one right index, a number with a tolerance, an estimate within a factor —
  or a debate, which is **never** graded, because scoring an opinion is
  telling the reader theirs is wrong.
- A card that asks names the trap before it explains, because getting it
  wrong on purpose is the part that teaches.
- Where it is an instance of a reasoning move, it says which one. Cards
  sharing a principle are the varied contexts that make it stick, and that
  is the claim the app is built on.

## What is here

`brief.py` — the brief. No dependencies beyond the standard library, because
it reads two Dart files and does arithmetic.

    python3 tool/content/brief.py --want 30
    python3 tool/content/brief.py --want 30 --json brief.json
    python3 tool/content/brief.py --demand demand.json   # counts by genre id

It stops rather than guesses. It reads Dart with regular expressions, which
holds exactly as long as those files keep their shape, so an unfamiliar
shape is an error and not a warning — a silent miscount would commission the
wrong cards for a month. It has already earned that twice: once on subjects
whose display name is not their key (`human_body` is "Human body", and
title-casing made two subjects with a dozen cards between them look empty),
and once on Thinking, which is written by hand in `topics.dart`, is more than
half the pool, and is deliberately not in the genre tree.

## What is not here yet

The writer, the gate and the emitter. They are the next three, in that order,
and the brief is what feeds them. The existing 170 cards also carry no genre
tag, so per-genre coverage is counted per subject for now — tagging the pool
is a one-off classification pass and it is what makes the genres real for the
dealer as well as for this.
