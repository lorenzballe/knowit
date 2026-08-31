# Astuto

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

## The mark

The icon is the A with the two cards behind it, in two versions — cream ground
and near-black. The mark carries its own background rather than being a
transparent glyph, so which one is shown matters: the light one on a dark
screen is a pale tile. `BrandMark` picks from the theme, and the web favicon
swaps on `prefers-color-scheme`.

A home-screen icon does not follow the phone's theme on either platform, so the
launcher icon is the light one everywhere. `tool/icons/` holds the supplied
artwork and the script that resizes it to all 25 sizes.

## Running locally

```sh
flutter pub get
flutter run -d chrome   # web
flutter run              # any connected device/simulator
```

## Motion

Three pieces in `widgets/motion.dart`, used everywhere something appears:
`RiseIn` (fade and lift, with a staggered constructor for lists), `CountUp`
(a number climbs rather than landing) and `PopIn` (an overshoot for the
instant something lands — a verdict, a finished day).

Their delays are intervals inside one animation controller, not
`Future.delayed`. A pending timer outlives a disposed widget and hangs
`pumpAndSettle`, and anything that only works outside tests is a thing nobody
can check — so there is a test that asserts the entrances settle and leave
nothing running.

All of it defers to the reduce-motion setting: whoever asked for less gets
the finished state.

## One palette

The app used to paint Today dark and the other tabs on paper, which meant it
changed skin between tabs — the sort of thing that reads as unfinished.

There is now a single semantic `Palette` (a `ThemeExtension`) with light and
dark values, named for the job each colour does rather than what it looks
like: `surface`, `surfaceRaised`, `ink` / `inkMuted` / `inkFaint`, `line`,
`inverse` / `onInverse`. Every screen reads from it through `context.p`, and
the only raw colours left outside `theme.dart` are on a pill card, which is
the same lime whichever ground it sits on.

Light, dark or system is one choice, made once, under **Appearance** in the
profile. It is stored, it is read above `MaterialApp` so the whole tree
repaints at once, and the status bar follows it.

## Screens

**Free** — first run (the five-scene intro, then the subject run), Today with the card stack,
the end-of-day recap, Saved with its empty state, Profile (stats, daily nudge,
topic chips), the come-back screen after a lapsed streak, and the disclosure
page on how pills are written.

**Astuto+** — three perks, all delivered: the searchable **Archive**, the
**topic picker**, and a **second set of five pills** handed over from the recap
once the first five are done. On the free plan the first two carry a lock chip
and open the paywall instead.

Sharing is deliberately *not* a paid perk. A card in someone's chat or story is
the only free distribution the app has, so charging for it would mean charging
readers to advertise it.

## Accounts, and what crosses to a new phone

The app works signed out and always did. An account only decides whether the
phone's work also lives somewhere that survives the phone.

Every phone is given an anonymous account the first time it opens, because
the app asks for a real one late on purpose — and until there is one, a
reader has nowhere to keep a backup and no address a notification could be
sent to. Signing in with Apple or Google **links** that account rather than
opening a second one, so the uid does not move and nothing has to be carried.
Where the identity already has an account of its own, the uid does change,
and the merge below is what brings this phone's week across.

Signing in asks the phone, not a browser. Firebase will run the whole flow
itself, and for a while this app let it: a browser sheet titled
`astuto-3d398.firebaseapp.com` rather than Astuto, opening a session that
knows none of the accounts the phone is signed into, so it asks someone to
type an email address and a password on the second screen of an app they have
not decided to keep. Nobody finishes that. Apple's own sheet is a glance at
Face ID and Google's lists the accounts the phone already holds, so those are
asked first, and Firebase's browser flow is kept for the places with no sheet
of their own — Apple on Android, a phone the Google sheet cannot run on, a
build whose signing fingerprint was never registered. Apple's token is bound
to a nonce we draw per attempt: Apple is handed the hash and Firebase the
string it was made from, so a token lifted off the wire is no use to whoever
has it.

On an iPhone there is **no** browser fallback, deliberately. Both sheets exist
there, so landing in Safari means the build is wrong — and falling back would
hide that behind the exact experience the sheets were brought in to replace.
It says what went wrong instead. The profile's debug section names the
sign-in implementation the build carries and which road the last attempt took,
because working out whether a build even contained the new code cost two
rounds of TestFlight once.

Sign in with Apple also needs the entitlement in `ios/Runner/Runner.entitlements`
and the matching capability on the App ID, or the sheet comes back with error
1000 and nothing to explain itself. The Codemagic workflow enables the
capability before it mints a profile, because a profile that predates it will
not sign the build.

Signing in is not a restore. It happens after the reader has used the app, so
both sides are real and neither may be dropped:

- streaks and counts take the better of the two — losing a streak for owning
  a second phone would be the app punishing someone for its own design;
- completed days, saved pills, seen cards and push tokens are unions: a day
  either was done or was not, and a reader with two phones should be
  reachable on both;
- a card both sides know keeps the answer that climbed further up the review
  ladder, which is "your first answer stands" seen from the other end;
- the mix is a decision rather than a score, so the one made on this phone
  wins;
- and the judgement log is never cut. It carries no id and no timestamp, so
  two lists cannot honestly be interleaved — the longer one is the more
  complete record, because on one device it only grows. Ids would let this be
  exact, and should come before anyone runs two phones in earnest.

Not synced, deliberately: the theme, the reminder, today's deck and how far
through it the reader is. Those describe a device, and copying them would
have a phone pick up half of another phone's day. Nor the plan — a
subscription the client writes to itself is a wish, not an entitlement.

Backing up runs four seconds after the app goes quiet, so five cards are one
write, and flushes when the app leaves the screen, which is the last moment
anything is certain to run.

Notifications are asked for once, after a first day is finished. iOS gives an
app one prompt and no second chance, so spending it on a launch screen throws
the channel away on someone who does not yet know what the app is.

## Project structure

```
lib/
  data/        topic palette, the pill pool, and the daily dealer
  models/      Pill
  state/       AppState — streak, saved pills, reading history, plan (persisted)
  utils/       PNG download, web-only with a no-op elsewhere
  widgets/     card stack, share sheet, shared UI, the Astuto+ gate
  screens/     the screens listed above
```

Today's deck is dealt deterministically from the date, so it does not reshuffle
mid-day, and it is stored by id so a restart resumes the same five. Pills
already read are kept out of later days until the pool runs dry.

## What is not real yet

These are declared in the UI rather than faked:

- **Notification delivery.** The permission is asked for and the token is
  registered, so a phone can be reached — but nothing sends yet. Deciding who
  gets what, and when in their own timezone, is the work that remains.
- **Email sign-in.** Apple and Google are wired; the email button says plainly
  that it is not connected. Firebase's email link needs a domain of ours with
  universal links, since Dynamic Links was retired.
- **The pool runs out.** 170 cards at five a day, two of which are reviews, is
  about eight weeks of new material. The app asks for a subscription that
  renews annually, so the content pipeline is the thing standing between this
  and a product.

Since the sections above were first written, three of the things listed here
stopped being true and are now real: accounts (anonymous, Apple, Google, with
the merge described above), the backup, and the plan, which comes from the
store through RevenueCat rather than from a bool the app wrote to itself.

**Debug tools.** The foot of the profile carries a temporary section — wipe
and restart, toggle the plan, and a readout of what the app knows about
itself: whether Firebase started and why not, the account id, the last auth
error, whether the store answered. It is on in release builds on purpose,
because TestFlight builds are release builds and that is where it is needed.
One line in `lib/debug_flags.dart`, or `--dart-define=DEBUG_TOOLS=false`,
turns it off.

## What the evidence says, and what follows from it

The app is built on three findings, not on a hunch about what feels useful.

**You cannot train general intelligence.** The large review of brain training
([Simons et al., 2016](https://journals.sagepub.com/doi/abs/10.1177/1529100616661983))
found gains only on the exact tasks practised. So the app does not claim it,
and reading facts is not treated as training.

**You can train away specific biases, and it transfers.** A single
interactive session reduced confirmation bias, the bias blind spot and the
fundamental attribution error for 8–12 weeks
([Morewedge et al., 2015](https://journals.sagepub.com/doi/abs/10.1177/2372732215600886)),
and trained students were 19% less likely to take the hypothesis-confirming
answer on an unannounced business case
([Sellier, Scopelliti & Morewedge, 2019](https://journals.sagepub.com/doi/abs/10.1177/0956797619861429)).
The interactive version beat the video. The ingredients that carried were
naming the bias, practice in varied contexts, and feedback on your own
errors.

**You can train calibration.** An hour of probabilistic-reasoning training
improved forecasting accuracy by around 10% on Brier score, sustained across
four years of tournament
([Mellers et al., Good Judgment Project](https://www.cambridge.org/core/journals/judgment-and-decision-making/article/developing-expert-political-judgment-the-impact-of-training-and-practice-on-judgmental-accuracy-in-geopolitical-forecasting-tournaments/123EB18425391D05FA6581FDBB3F309F)).

### Three things that follow

**A day is mostly asking.** Four of the five cards ask something. One fact
opens it — a fact is a reason to come and it opens up a subject, but it is
not the training.

**A principle, not a card, is the unit.** `Principle` is what a card is an
instance of. Meeting base-rate neglect once, in a medical test, teaches
medical tests; meeting it in facial recognition and in hiring teaches base
rates. New contexts deliberately avoid the textbook version — the famous one
is the one people already have an answer for.

**A review is a new context, not the same card.** When a card comes due, the
deck brings back a *different instance of the same principle* where one
exists. Repeating the identical card tests whether you remember that card.

The profile reports **the moves you keep missing** — per principle, across
every context of it you have met — because naming the move and showing your
own record on it is the part that carried to a real decision.

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

Every puzzle is either arithmetic the reader can redo or a result that has held
up under repeated testing. Famous psychology that failed replication — ego
depletion, power posing, priming — is deliberately absent, and so are the
textbook instances people already have an answer for: the principle is met in
a context you did not expect it in, because that is what transfer means.

## Who else is in this market, and what that changed

The direction of this app was set by looking at what already ships, not by
reasoning about it. Three findings mattered.

**The concept is not a moat.** [Fallacy][fallacy] does almost exactly this —
cognitive biases, thirty logical fallacies, a debate mode, real headlines. It
is rated 4.5 stars and has roughly [500 Android downloads][fallacy-play].
Shipping the idea first protects nobody, so nothing here is built on being the
only one to have thought of it.

**The money in this category is in daily content, not in judgement.**
[Imprint][imprint] takes about 300k downloads and $400k a month for
illustrated two-minute lessons. [Blinkist][blinkist] does roughly $2M a month
on book summaries. Neither promises better reasoning. Meanwhile the platforms
with real rigour — [Metaculus][metaculus], Manifold, Good Judgment Open — are
free, and Metaculus runs on [philanthropy][metaculus-funding].

**Its users named the gap.** The most common complaint about Fallacy's debate
mode is that it is multiple choice and never lets you build your own
reasoning.

### What follows

The daily cards are the reason to open the app; the record is the reason to
keep it and the only thing here that a better-funded competitor cannot copy.
So:

- **Sharing is the record, not a card.** A fact posted into a chat competes
  with apps that spend far more on illustration. `RecordSummary` — what you
  said, what actually happened, and the distance between them — is the one
  asset this app owns. It leaves as a lime card, in the app's own colour,
  because a near-black square is what everything else in a feed already looks
  like.
- **Debates ask you to write first.** Taking a side now opens a one-line
  "why?" before the counter-argument can be read. Committing to a reason in
  your own words is what stops the other side being explained away on sight.
  Skipping is allowed: a reader made to type before they may read on stops
  reading on.
- **Astuto+ sells depth, not volume.** More cards is the pitch every rival
  makes better. What is gated instead is whether the gap is closing over time
  (`Trend`) and the full principle board; the measurement itself stays free,
  because a reader has to see it before they will pay to keep it.

The promise on the welcome screen changed with it. "Five a day" was a claim
about volume. What the evidence actually supports is narrower and more
useful: most people are more sure than they are right, and this can be
measured.

[fallacy]: https://apps.apple.com/us/app/fallacy-brain-training-logic/id6743923575
[fallacy-play]: https://play.google.com/store/apps/details?id=com.spotthefallacy.fallacygame
[imprint]: https://app.sensortower.com/overview/1482780647?country=US
[blinkist]: https://app.sensortower.com/overview/568839295?country=US
[metaculus]: https://predictionmarketsreviews.com/reviews/metaculus
[metaculus-funding]: https://ea-crux-project.vercel.app/knowledge-base/organizations/metaculus/
