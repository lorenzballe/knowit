# Astut

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

**Free** — first run (the five-scene intro, then the subject run), Today with
the card stack and, once the five are done, the shelf, Explore (shelves of
cards nobody dealt you, with a search over the whole pool), Saved with its
empty state, Profile (record, appearance, topics, coverage, calibration,
daily nudge), the come-back screen after a lapsed streak, and the disclosure
page on how pills are written.

**Astut+** — three perks, all delivered: the searchable **Archive**, the
**topic picker**, and a **second set of five pills** handed over from the shelf
once the first five are done. On the free plan the first two carry a lock chip
and open the paywall instead.

## Today, done

The finished day is artboard 66a. The tab at rest is a shelf: the day's five
come back as a real carousel — swipe through them, tap one to turn it over
and read the whole reveal again — so "review" is the screen itself rather
than a button. The glow behind everything, the dot in the header and the
long dot under the carousel all take the colour of the card at the front.
Under the dots the app names what opens tomorrow: the deck is dealt from
the date and the reading history, both settled by tonight, so the subject
it names is the one that will actually be on top in the morning. A card
that came due and found no room in the five waits here too. The way on is
**Your journey** — the day just went somewhere on the ladder, and that is
the one thing worth a button at the end of it; Explore is a tab already.
The second set sits under the button as a quiet line.

## Your journey

Artboard 83a, and the order is the argument: the numbers first, the card
to say last.

`JourneyScreen` opens on the headline — cards read, as a pill — then the
**level**: the rung in words ("Level 3 · Answering"), the one thing
between the reader and the next one, and a bar. Then **four numbers**,
two by two: how much of what was answered is still with them, how far off
their confidence runs, the streak, and how many moves they can spot — a
principle met in at least two contexts and got right more often than not,
which is what "something you can explain" means here, counted rather than
claimed. Then **what it is about**: the pile of cards in non-fiction
books, hours of documentary and lectures, with the hours it took at forty
seconds a card. It waits until twenty-five cards, because "five cards is
about zero books" is worse than not asking yet. Then **by subject**: how
much of each shelf has been read, most-read first, and tapping one opens
what was read of it.

And at the foot, the one thing on the page that is not a number: a card
**to say tonight** — the question, the answer and the line to bring it up
with — with *Another one* and *Said it*. What has been said is written
down (`saidIds`, in the snapshot), because saying a card out loud is the
only proof it left the phone, and the only thing the app cannot check for
itself.

The **path** — the seven rungs one under the other on a trail, each with
the day it was first reached, the one the reader stands on with the bar
and the single next step, the ones ahead faint — is one tap under the
level, in `PathScreen`. The rung dates are written the moment a rung is
cleared (`rungDates`, in the snapshot, earliest date winning in a merge)
and never moved.

The header is the same one line whether the day is running or done — a dot
in the day's colour, "Day 6 · five read" (or "2 of 5 read"), and at the far
end what has been liked — so finishing the day changes what the tab holds
and not what it looks like.

## Explore, and the archive

The middle tab is called Explore rather than Search, after what is on it
rather than after the field at the top of it, and it carries a compass. The
finished day's button puts it back the way it opens, whatever it was left on.

What was on it was a leaderboard — a ranked list, two rows of chips, and
every card reduced to a thin grey row. Nothing about it looked like this
app: the colour, the card as an object and the question are the product,
and a ranked list throws all three away. It is artboard 72a now, which is
shelves, each with a reason for existing written under its name, and the
cards on them are cards. A subject row across the top narrows every shelf at
once.

Two of the three shelves say what the canvas said. The middle one does not:
the canvas ranks it by what everyone saved, and nothing counts saves — there
is no server to count them on — so it is "the ones that ask the most", which
is the order it was always in and a claim the app can stand behind. The
third one the app can say for real, because the mix is the reader's own:
**Because Space sits at full**, from the subject they pushed furthest up.

The **Archive** is artboard 70e — its head too: the name, the lens on the
right and the count under it, with the way back beside the title, which is
the one thing the canvas had no need for and a screen reached from the
profile does. Under the subject chips that were already there and are
untouched, left alone it is the days — every day the reader has finished, most
recent first, five cards each, today already open. Ask it something, by
typing or by picking a subject, and it becomes the list of what matched. A
search field over an empty screen is a question with no reason to be asked;
the days give it one. Only days the reader was here for: a run of empty rows
back to the launch date would be a longer list saying less. Today's five are
the real deck; an earlier day is dealt again from its own date, which is
deterministic, because a finished day's cards have never been stored.

The three tabs slide under the finger, the way they do in every app with
three of them side by side; the bar is the other way to the same place.
Each tab is clipped to its own page: a screen is free to paint past its
edges — the shelf lets a card's glow bleed — and without the clip the bleed
lands on the tab beside it and rides there until the next repaint.

Tapping the tab beside this one slides, because there is nothing in between
to drag across. Two tabs apart the page cuts instead, because a slide would
haul the middle screen over the glass on its way past. The bar carries that
move on its own, crossing from the tab you left to the tab you asked for
without lighting the one between them. It follows a number per tab rather
than the page index — the index changes once, in the middle of a move, and
two tabs apart that meant two overlapping animations, which is what read as
a stutter. Nothing else on the screen rebuilds while that number changes,
and the tab is only written down once a move has settled: doing it
mid-gesture swapped the page physics under a finger that was still dragging.

The body runs the whole height, under the tab bar, and each screen puts the
bar's height back as padding — so nothing moves, and a card thrown downward
is not sliced off at the top of a bar that has already faded out of its
way. Behind the card being read there is one other card and no more: a
stack that fades everything it holds shows four questions at once, which is
three more than anybody asked for and a spoiler of the rest of the day.

Except while the day is running. Today is then a screen with one thing on
it, and every sideways drag on it belongs to the card being thrown — a page
that slid instead, depending on where the finger landed, was the worst of
both. The five are a screen you finish, not one you slide off, so the page
is locked until they are read. The bar still goes anywhere, so nobody is
held there. Once the day is done the shelf slides like every other screen,
and the carousel keeps the drags that land on it.

What the shelf takes from the canvas and what it does not: the card is
324 × 452 with its 28-point padding, the eyebrow, the dots and the two
lines under them sit at the canvas's own margins, and the button is the
canvas's flat one rather than the app's chunky one — a door out of a
finished screen is not a commitment. The type stays Fraunces, because the
canvas's Outfit would have made this the one screen in the app set in
another face. The back of a card is the canvas's four things — the question
again small, the answer, a hairline, the line to bring it up with — and not
the deck's full reveal, which belongs to the card being answered for the
first time. Real answers run longer than the ones the canvas was drawn
around, so the block is set down a size or two until it fits rather than
having its last line sliced in half.

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
`astuto-3d398.firebaseapp.com` rather than Astut, opening a session that
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
  data/        topic palette, the pill pool, the question of the day, the dealer
  models/      Pill, Reminder
  state/       AppState — streak, shelves, history, the ladder (persisted)
  sync/        the account, the snapshot and its merge, boards
  utils/       reminders, the widget channel, sharing — each web-safe
  widgets/     card stack, share sheet, shared UI, the Astut+ gate
  screens/     the screens listed above
tool/
  icons/         the supplied artwork, and the script that resizes it
  illustrations/ the figures a card can carry — Python, run on a server
```

**Figures.** `tool/illustrations` draws the picture that sometimes goes
with a question: a hundred dots with one of them filled, a circle inside
another circle, a curve that doubles. It is Python, it is not wired into
the app yet, and it exists now because the constraint it has to meet is
already fixed: the app paints a figure with `BlendMode.srcIn`, so a figure
has one colour and no background, and a library's default output has both.
Its README says which libraries were chosen and what manim actually costs.
The figures are checked from `test/figures_test.dart`, in this suite,
because a picture produced in another language by a program running
somewhere else is otherwise nobody's to break.

Today's deck is dealt deterministically from the date and the reading
history, so it does not reshuffle mid-day, and it is stored by id so a
restart resumes the same five. Pills already read are kept out of later
days until the pool runs dry.

## The question of the day

A day is five cards, four of them the reader's own and one that every
reader in the world meets on the same day. The four are dealt from the mix,
from what the reader said they know, and from what came due for review;
the fifth is the question of the day (`lib/data/daily.dart`) — one edition
a day from the first of September 2026, chained so the same question does
not come round again for months, and dealt from the first edition on every
phone that holds the same pool, which is what makes it the same question
everywhere.

It costs the mix nothing. Every card that asks and can be marked lives
under Thinking, and Thinking was never off anybody's deck: the three cards
that tell, and the second card that asks, are the mix's entirely. What the
shared question buys is a common object — the card a friend can be asked
about ("did you get it?"), the one the morning notification can quote a
fortnight ahead, the one square in the shared grid that means the same
thing on every phone.

**Two of five ask.** It was four, on the evidence that only answering
trains anything, and the evidence has not changed — but a day that is four
decisions long is a day that gets put off, and a day put off trains
nothing. Two questions is still two judgements with a confidence on each,
which is what the calibration record is made of; the other three are the
reason to open the app before coffee. The ladder is paced to that. The two
asking slots go first to the question of the day and then to a card that
came due for review, if one did; only when none did does the second go to
a fresh question from the mix. What came due and found no room waits after
the five, on the finished day.

**Share my day.** Five squares — read, right, wrong, a side taken, passed —
the edition, the streak, how the question of the day went ("right, 80%
sure"), and the day's line. Nothing a friend could be spoiled by, because
it names no card. On a phone it goes to the share sheet; in a browser it is
copied.

The archive keeps what each day was actually dealt: the calendar is
re-dealt from the start whenever the pool grows, and a day dealt again from
the same date is only most of the truth.

## Liked, saved, and less like this

The heart and the bookmark used to be one gesture doing two jobs. A card
held down is now *liked* — a shelf of its own on the profile, and the thing
the personal deals lean towards, one like or one throw moving its subject's
weight by fifteen percent. The bookmark on the card *saves* it, to find
again. And a card thrown straight down, hard, is *less like this*, said
once with the way back; a throw that drifts downward on its way sideways is
not it. Likes and throws travel with the account.

## Friends

What a friend sees of a reader is the shape of the habit — the streak, the
weeks kept, how far off the confidence runs, today's five as squares once
the day is done, and how the question of the day went — and never a
question's text or an answer. A board is
published with every backup, under six letters worked from the account id
(`friendCodeOf`, no O or 0, no I or 1) that nobody can read the id back
from; a friend types them and sees the board. The week is compared by
calibration, closest first: not who read the most, but whose confidence is
nearest their record, which is the one race this app is for. Boards live at
`boards/{code}` in Firestore, readable by anyone signed in and written only
by their owner.

## The home-screen widget

The question of the day, and the streak, on the home screen. The widget is
native — WidgetKit on iOS, an `AppWidgetProvider` on Android — and neither
can run Dart, so the app hands over what the widget will need through the
`astut/widget` channel: the question of the day, the streak, and the
question for each of the next fourteen mornings, so the widget turns over at midnight
whether or not the app is opened, and goes quiet after a fortnight rather
than lying.

Android is complete in the tree: `AstutWidget.kt`, its layout, and the
receiver in the manifest. (`MainActivity` also moved to `com.astuto.app`,
the package the manifest actually resolves it in.) iOS needs steps in
Xcode that a file cannot do, and they have to be done together, because
the provisioning profile Codemagic signs with has to carry the same
capabilities as the entitlements or the archive fails to sign:

1. Runner target → Signing & Capabilities → **+ App Groups** →
   `group.com.astuto.app`. Xcode adds the entitlement to
   `Runner.entitlements` and, with automatic signing, regenerates the
   profile; with a manual profile, add App Groups to the App ID in the
   developer portal and download the profile again.
2. File → New → Target → **Widget Extension**, named `AstutWidget`,
   without configuration intent. Replace its generated Swift with
   `ios/AstutWidget/AstutWidget.swift`, point it at
   `ios/AstutWidget/Info.plist`, and give it the same App Group
   (`ios/AstutWidget/AstutWidget.entitlements` is ready to attach).

Until then the app builds and signs as before: the channel handler in
`AppDelegate.swift` writes to the group's defaults, which without the
entitlement is a private container nobody reads, and WidgetKit is asked
to reload timelines that do not exist yet — both harmless.

## What is not real yet

These are declared in the UI rather than faked:

- **Notification delivery.** The permission is asked for and the token is
  registered, so a phone can be reached — but nothing sends yet. Deciding who
  gets what, and when in their own timezone, is the work that remains.
- **Email sign-in.** Apple and Google are wired; the email button says plainly
  that it is not connected. Firebase's email link needs a domain of ours with
  universal links, since Dynamic Links was retired.
- **The pool runs out.** Sixty cards that tell, at three a day, is twenty
  days of new reading; the ninety questions that can be marked, one of them
  everybody's each day, about three months. The app asks for a subscription that renews annually, so the content
  pipeline is the thing standing between this and a product.
- **The iOS widget target.** The Swift is written; the Xcode target has to be
  added by hand, as described under *The home-screen widget*.

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

## Thirteen languages

The app speaks the phone's language. Every string a screen shows lives in
`lib/l10n/app_<locale>.arb` — English is the template, and Italian,
Spanish, French, German, Portuguese, Dutch, Polish, Russian, Turkish,
Japanese, Korean and Chinese carry every key it has; a test refuses a
language that falls short. Plurals are real plurals (Polish and Russian
have their `few` and `many`), and the numbers the canvas spells out —
"five read" — are spelled in each language rather than pasted from
English. `flutter gen-l10n` turns the files into `AppLocalizations`, and
`context.l10n` is the way to it from any screen.

The cards are not translated here. They are content, written by the model,
and they will be translated where they are written; the same goes for the
subject names, which are data the dealer matches on. The debug panel and
the page on how pills are written stay English on purpose.

A phone set to a language the app does not have gets English. A string a
language has not translated yet gets English on its own, so a language can
arrive half done without a screen going blank.

## The path, and the week

Retention in an app that promises sharper thinking cannot be bought with
the usual machinery — a random reward, an infinite feed, a counter that
shames you. Those work on somebody who wants to be entertained, and this
app is for somebody who wants to be right more often. So the reasons to
come back are all evidence:

**The ladder.** Seven rungs, in `lib/state/progress.dart`, and not one of
them is about a subject. The five cards a day are mixed on purpose, so a
path made of chapters — fifteen cards on probability, then fifteen on
incentives — would have to break the deck to exist. Instead each rung is a
claim about the reader: *Reading*, *Answering* (you commit before turning
the card over), *Saying how sure*, *Calibrated* (what you say you know,
you know), *Holding* (it is still there weeks later), *Sharp*. Any five
cards at all carry somebody up it. The profile shows the rung, one bar
held to whichever requirement is furthest behind, and the single next
step — telling somebody four things at once is telling them nothing.

**Weeks kept.** Five days out of seven keeps a week, and the record counts
the weeks in a row. The daily streak is the sharper number and the crueller
one: a flight or a fever, and two months are gone. Both are shown; only one
of them survives a life.

**The week.** `WeekScreen` reads the week back: days kept, how sure against
how right, whether the gap closed on last week, and the cards the reader was
sure about and wrong about. That last list is the page in this app most
worth going back to. It is reachable from the record and from the profile,
and on Sunday the finished day offers it directly, which is the one moment
a reader is already looking at what a day came to.

**The nudge carries the question.** Not "three days in a row, keep it up" —
that is a message about the app's counter. The reminder is the first
question of the deck waiting, which is a message about the reader's own
head. And since the question of the day is everybody's, the app plans a
fortnight of them at a time (`reminderPlan`), each with the question of
the morning it lands on. On the days a lapse reaches it says something about the reader
instead of the app — day two, that the freeze is holding; day seven, the
card they were sure and wrong about; day fourteen, what two weeks came to —
never "we miss you", and after a fortnight it stops. Re-planned at every
launch, in the phone's language.

**The rung, where the day happened.** The ladder lives on the profile,
where nobody looks at the end of a day. So the finished day's one button
opens the journey, where the rung climbed today has today's date on it.

Judgements are dated and carry the card they were made on, so the week can
be read apart from the run, and a miss can be opened again. Both fields are
absent on judgements recorded before the app kept them, and everything that
reads them treats absent as unknown rather than as a reason to throw the
judgement away.

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

Two of the five ask, and at least one of those can be marked: a debate is
ungraded on purpose, so a day of opinions would measure nothing. The
reasoning is under *The question of the day*.

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
- **Astut+ sells depth, not volume.** More cards is the pitch every rival
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
