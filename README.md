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

The pool holds 75 cards: 60 facts, five per topic, plus 15 reasoning puzzles
under **Thinking** — about fifteen days for a free reader before anything
repeats.

A puzzle asks before it tells. The options are the front of the card, and
committing to one is what turns it over; a stray tap will not. Getting it wrong
on purpose is the part that teaches, so the reveal names the trap you fell into
before it explains the answer. Your first answer is the one that counts.

Every puzzle is either arithmetic the reader can redo (Monty Hall, base rates,
the birthday problem) or a result that has held up under repeated testing
(Wason, Tversky & Kahneman, the Berkeley admissions data). Famous psychology
that failed replication — ego depletion, power posing, priming — is
deliberately absent.
