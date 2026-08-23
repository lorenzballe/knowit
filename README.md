# Knowit

Five AI-written "pills" a day — bite-size facts across science, history, psychology,
economics, tech, weird facts, the human body, philosophy, pop culture, nature and
language — each with a **Bar move** line (the reason to bring it up) and a source.
Swipe sideways to move to the next pill, tap to flip and reveal the answer.

Today is the full-bleed treatment from the original mockups — dark chrome, the
card filling the screen. Saved and Profile keep the light editorial chrome.
Type is Fraunces over Figtree, both bundled with the app rather than fetched
from Google at runtime.

## Live preview

Every push to `main` builds and deploys automatically to GitHub Pages:

**https://lorenzballe.github.io/knowit/**

(First deploy: in the repo, go to **Settings → Pages** and set **Source** to
**GitHub Actions** if it isn't already — after that every push publishes on its own.)

## Running locally

```sh
flutter pub get
flutter run -d chrome   # web
flutter run              # any connected device/simulator
```

## Screens

**Free** — first run (welcome, optional sign-in), Today with the card stack,
the end-of-day recap, Saved with its empty state, Profile (stats, daily nudge,
topic chips), the come-back screen after a lapsed streak, and the disclosure
page on how pills are written.

**Knowit+** — three perks, all delivered: the searchable **Archive**, the
**topic picker**, and a **second set of five pills** handed over from the recap
once the first five are done. On the free plan the first two carry a lock chip
and open the paywall instead.

Sharing is deliberately *not* a paid perk. A card in someone's chat or story is
the only free distribution the app has, so charging for it would mean charging
readers to advertise it.

## Project structure

```
lib/
  data/        topic palette, the pill pool, and the daily dealer
  models/      Pill
  state/       AppState — streak, saved pills, reading history, plan (persisted)
  utils/       PNG download, web-only with a no-op elsewhere
  widgets/     card stack, share sheet, shared UI, the Knowit+ gate
  screens/     the screens listed above
```

Today's deck is dealt deterministically from the date, so it does not reshuffle
mid-day, and it is stored by id so a restart resumes the same five. Pills
already read are kept out of later days until the pool runs dry.

## What is not real yet

These are declared in the UI rather than faked:

- **No billing.** The paywall's call to action starts the trial locally so the
  gated screens can be used, and says no payment was taken.
- **No account backend.** Sign-in keeps a profile on the device; the Apple and
  Google buttons say they are not connected.
- **No notification delivery.** The daily nudge is stored as a preference;
  actually scheduling it needs a local-notifications plugin and a mobile build.

The pool holds 95 cards: 60 facts plus 35 under **Thinking** — bias traps,
competition problems, Fermi estimates, spot-the-flaw and debates.

## How a card asks

A card either tells you something or asks you something first, and that is
modelled as a sealed `Challenge` rather than a kind flag with a drawer of
nullable fields:

| Challenge | The front of the card | Graded |
|---|---|---|
| `NoChallenge` | the question, tap to turn it over | — |
| `PickOne` | the options | index matches |
| `TypeNumber` | a number field and a unit | value within tolerance |
| `Estimate` | the same field, judged loosely | within a factor |
| `TakeASide` | two positions | **never** |

Each case carries only the data it needs and grades its own answers, so adding
a way to ask means a new subclass — and the switch that picks a card's face
stops compiling until that case is handled. Answers are stored as the raw
string the reader committed, so one store serves every kind.

`TakeASide` is ungraded on purpose. A debate card asks for an opinion, and
scoring an opinion would be telling the reader theirs is wrong; ungraded cards
stay out of the tally entirely.

Committing is what turns the card over; a stray tap will not, or the answer
could be reached without ever guessing. Getting it wrong on purpose is the part
that teaches, so the reveal names the trap before it explains. Your first
answer stands.

## What you got wrong comes back

An app that never re-asks what you missed is entertaining, not teaching.
Every graded answer schedules the card to return: wrong knocks it to the
bottom of a ladder — **2 days, 7, 21** — right moves it up one, and past the
top it retires. Two of the five cards a day are given over to cards coming
back, marked **AGAIN** so a repeat reads as deliberate. A card that has come
back has to be answered again; tapping will not open a reveal the reader has
to re-earn. Debates never return: there is nothing to get right.

## Calibration

After committing to a graded answer the card asks one more thing: how sure
are you? Five levels, 50 to 90. Each of those is appended to a judgement log
that is never rewritten — calibration is a track record, so answering a card
again months later is another data point, not a correction of the first. The
profile reports the only number in the app that says something about the
reader rather than the cards —

> You are overconfident by 17 points

— broken down by level: what you claimed against what actually happened.
Being right is a fact about one card. Knowing how often you are right is a
fact about you, and it is one of the few reasoning skills with evidence that
training transfers.

A debate card never asks, because an opinion is not something to be sure
about, and ungraded answers stay out of the buckets.

## What a card can offer on the reveal

- **A hint**, asked for without giving up and without turning the card.
- **A worked solution** as numbered steps, because a derivation nobody can
  follow is not an explanation.
- **Put simply** — a second way in for the ideas that genuinely have one: a
  concrete image, not the same words made smaller. Deliberately absent where
  the main explanation is already the simplest true version, since a button on
  every card becomes an excuse to write the first one badly.
- **What the other side says** — on a debate, the strongest case against
  whichever side you took.

## The shape of a day

Sorting the day by difficulty looked sensible and was not. Facts are easy and
anything that asks is not, so every day came out as all the reading first and
then a pile of work at the end, when attention is lowest.

A day is now arranged rather than sorted:

- it opens on something to read, so there is no cost to starting;
- reading and answering alternate, so attention is not spent three cards in a
  row and then asked for twice;
- the hardest card lands early, while there is attention to spend on it;
- a debate closes, because it is the one card meant to be carried away rather
  than finished.

There is also a floor on how much of a day asks something. Everything that
asks lives under one topic, and a deck that takes one card per topic was
dealing four facts and a single puzzle — an app that trains reasoning cannot
be four fifths reading.

## Project structure

```
lib/
  data/        topic palette, the pill pool, and the daily dealer
  models/      Pill
  state/       AppState — streak, saved pills, reading history, plan (persisted)
  utils/       PNG download, web-only with a no-op elsewhere
  widgets/     card stack, share sheet, shared UI, the Knowit+ gate
  screens/     the screens listed above
```

Today's deck is dealt deterministically from the date, so it does not reshuffle
mid-day, and it is stored by id so a restart resumes the same five. Pills
already read are kept out of later days until the pool runs dry.

## What is not real yet

These are declared in the UI rather than faked:

- **No billing.** The paywall's call to action starts the trial locally so the
  gated screens can be used, and says no payment was taken.
- **No account backend.** Sign-in keeps a profile on the device; the Apple and
  Google buttons say they are not connected.
- **No notification delivery.** The daily nudge is stored as a preference;
  actually scheduling it needs a local-notifications plugin and a mobile build.

The pool holds 81 cards: 60 facts, 15 reasoning puzzles and 6 competition
problems, the last two under **Thinking**.

## How a card asks

A card either tells you something or asks you something first, and that is
modelled as a sealed `Challenge` rather than a kind flag with a drawer of
nullable fields:

| Challenge | The front of the card | Graded by |
|---|---|---|
| `NoChallenge` | the question, tap to turn it over | — |
| `PickOne` | the options | index matches |
| `TypeNumber` | a number field and a unit | value within tolerance |

Each case carries only the data it needs and grades its own answers, so adding
a way to ask means a new subclass — and the switch that picks a card's face
stops compiling until that case is handled. Answers are stored as the raw
string the reader committed, so one store serves every kind.

Committing is what turns the card over; a stray tap will not, or the answer
could be reached without ever guessing. Getting it wrong on purpose is the part
that teaches, so the reveal names the trap before it explains. Competition
problems add a hint you can ask for without giving up, and a worked solution
shown as numbered steps rather than one paragraph. Your first answer stands.

Every puzzle is either arithmetic the reader can redo (Monty Hall, base rates,
the birthday problem) or a result that has held up under repeated testing
(Wason, Tversky & Kahneman, the Berkeley admissions data). Famous psychology
that failed replication — ego depletion, power posing, priming — is
deliberately absent.
