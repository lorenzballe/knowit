# Astute

Five AI-written "pills" a day — bite-size facts across science, history, psychology,
economics, tech, weird facts, the human body, philosophy, pop culture, nature and
language — each with a **Bar move** line (the reason to bring it up) and a source.
Swipe sideways to move to the next pill, tap to flip and reveal the answer.

Today is the full-bleed treatment from the original mockups — dark chrome, the
card filling the screen. Saved and Profile keep the light editorial chrome.
Type is Fraunces over Figtree, both bundled with the app rather than fetched
from Google at runtime.

## The site, and the live preview

Every push to `main` builds and publishes **https://astutetheapp.com** from
GitHub Pages (`.github/workflows/deploy.yml`):

- `/` is the landing page, designed in Claude Design and written out as
  plain HTML in `site/index.html`: the design's own inline styles, the app's
  screenshots in `site/assets/`, and `site/assets/main.js` for the few parts
  that move (the menu, the calibration chart you can drag, the cards that
  flip, the plan picker, the questions). It presents Astute on both stores,
  with Apple's and Google's own badges: a phone's Download goes straight to
  its own store, a computer's to a code to scan with the phone, which opens
  `/get` and from there the right store. Today's question is shown live from
  `/widget/days.json`, the file the widget reads. On top of the design:
  words that rise, sections that come into view as they are reached, a
  phone that turns towards the pointer and turns its card over when tapped,
  a progress line in the three lights' colours, grain on the paper, and the
  name large at the foot. It reads fully without JavaScript, and without
  motion for anyone who has asked their system for less.
- `/privacy`, `/terms` and `/support` — the pages the stores ask for — share
  its nav, footer and `site/assets/site.css`: night paper, cream ink,
  Fraunces and Figtree served from the site itself. Astute is published by
  TheBaleCompany, and every page says so.
- `robots.txt`, `sitemap.xml`, `manifest.webmanifest` (which names both
  store listings) and `assets/og.png`, the picture a shared link shows.
- `/app/` is the app, built for the web: the live preview.
- `/cards/cards.json` is the card bank the app refreshes from, and
  `/widget/days.json` the question of the day the iPhone widget falls back
  on. Both stay at the paths the app reads, and the old
  `lorenzballe.github.io/knowit/` addresses redirect to the domain.

The domain is set in the repository's Settings → Pages → Custom domain, and
at the registrar with four `A` records for `@` — 185.199.108.153,
185.199.109.153, 185.199.110.153 and 185.199.111.153 — and a `CNAME` for
`www` to `lorenzballe.github.io`. HTTPS is enforced there once GitHub has
issued the certificate.

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

**Free** — first run (the five-scene intro, then the subject run, and the
genres under it, which is where the onboarding ends), Today with
the card stack and, once the five are done, the shelf, Explore (shelves of
cards nobody dealt you, with a search over the whole pool), Saved with its
empty state, Profile (record, appearance, topics, coverage, calibration,
daily nudge), the come-back screen after a lapsed streak, and the disclosure
page on how pills are written.

**Astute+** — three things, all delivered, and everything else the same on
both plans. **Five cards a day, all yours**: on the free plan one of the
five is dealt from the reader's mix and four are everybody's — the
question of the day and three more from the day's edition — and with Astute+
all five are the reader's own, at the level the app has measured, with a
card that came due for review. **Your journey**: the level and the numbers,
every subject opened strand by strand, what stayed when a card came back,
and the card to say tonight — the screen is Astute+; the profile keeps the
record itself free. **Your whole archive**: the free plan keeps a week. €3,99 a month, €29,99 a year with
seven days free, offered once at the end of the onboarding with "continue
free" written under it. The paywall is sheet 111a, with the app's own three
icon tiles; its button promises the free week only where the store's
introductory offer gives one, and says "charged today" otherwise. The mix, the streak, the freezes, the friends, the
sharing and the search are free: they are how the app spreads.

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
The evening a week is kept, the line about tomorrow says that three of
tomorrow's five are the reader's own instead of two.

## The sixth card

The one card in the app that is not a card. On the free plan it is the
last card in the deck: it peeks from under the fifth like any next card,
comes to the top when the fifth is thrown, and is thrown the same way — a
rim of every colour the deck has, turning, with its light spilling onto
the table, and one offer: "the other three, yours". The button is the
paywall. Nothing times out and nothing says skip; a throw is the way past
it, as it is past every other card. Then it is the last card on the shelf
too, after the five, with the counter giving way to the plan's name and a
dot of every colour under it. With Astute+ there is no sixth card at all:
the five were all the reader's own, and there is nothing left to sell.

It is dealt only when the day is finished *in this session* — opening the
app onto a day already done goes to the shelf. `MagicCard`
paints the rim itself, from the palette's own spectrum, so it takes the
card's size; a phone that asked for less motion gets the rim standing
still. `PillCardStack` takes it as `trailing`, one card after the deck
with no back and nothing to answer; the shell keeps the tabs locked while
any deck is on the table, the sixth card included, because a throw and a
swipe to the next tab are the same gesture and the deck has to win it.

## Your journey

Artboard 83a, and the order is the argument: the numbers first, the card
to say last.

`JourneyScreen` opens on **the score**, set large: the record as one
number, with the bar under it that says where it came from. Four things
are worth points and they are worth what they cost — a card read is one,
because reading is the easy part; a card still with you weeks later is
three, because that is the part that fails; a move you can spot in a
context you have not seen is ten, because that is the whole promise; and
a week kept is five, because the habit produces the other three. Nothing
in it is invented and nothing in it goes down. Beside it, what today has
added, exact: the score at the start of the day is written down with the
deck. Then the **level**: the rung in words ("Level 3 · Answering"), the one thing
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
`astuto-3d398.firebaseapp.com` rather than Astute, opening a session that
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
  analytics.dart  what is measured, and whether anything is
  data/        topic palette, the bank (embedded + downloaded), the calendar,
               the dealer, and the genres under each subject
  models/      Pill, Reminder
  state/       AppState — streak, shelves, history, the ladder (persisted)
  sync/        the account, the snapshot and its merge, boards
  utils/       reminders, the widget channel, sharing — each web-safe
  widgets/     card stack, share sheet, shared UI, the Astute+ gate
  screens/     the screens listed above
tool/
  cards/         the bank — one JSON file per card — and the generator that grows it
  content/       the brief: what to write next, by genre, worked out from the bank
  icons/         the supplied artwork, and the script that resizes it
  illustrations/ the figures a card can carry — Python, run on a server
web/cards/       cards.json, the bank as the site serves it
```

## Where the cards come from

Cards are not code. Each is a JSON file under `tool/cards/bank/<topic>/`,
and `lib/data/card_json.dart` is the one place the field names are decided —
the round trip is a test. The app holds the bank twice: baked in at build
time as `lib/data/embedded_bank.dart` (generated; `tool/cards/bundle.py`
writes it and CI checks it is current) so the first day works offline, and
downloaded as `cards.json` from the same site that serves the preview, kept
in the phone's own storage and adopted the next time the app starts — never
mid-day, so a deck on the table is not re-dealt under the reader. A phone
with no signal keeps what it has. `PillBank` is that one static.

The bank grows at night. `.github/workflows/cards.yml` borrows a machine at
03:00, and `tool/cards/generate.py` asks for what the bank is short of —
every strand towards two cards, every subject towards forty reads, twenty
graded questions and three debates, every principle towards eight — with
`tool/cards/RULES.md` as the whole of the writer's instructions. A card is
**written from a page that was read**, not from memory: a scout searches
the open web for three finds the card could be built on, from three sites
and three kinds of source; a reader opens the first find's page and copies
the passage that states the claim, verbatim, and a program checks the
passage is on the page; the writer writes from that passage and nothing
else, so every figure on the card is in it. A gate (`check.py`) refuses
anything mis-shaped, a twin of a card already there, anything on the
blacklist, a reference that is not the page, a site cited twice on one
strand; the critic, with the opposite brief, search and the page, redoes
the numbers against the passage and tries to defend the wrong options.
What survives arrives as a pull request, one file per card, with the
cards, their sites and the receipt in its body. **Merging is the review.**
The deploy then publishes the new `cards.json`, and every phone picks it
up. Every stage runs through the Batches API at half the token price.
`tool/cards/README.md` has the loop in full, the cost of a card, and how
to retire one.

**Tags.** Every card carries what it is about and like, beyond what it
asks: its genre and strand (`space.the_moon.tides`), three to six keywords,
an era, a region, a hook (a belief to overturn, a thing to work out, a
story, a figure, a mechanism, a paradox, something to use, an origin), a
mood, how much number-sense it wants, whether it is a thing or an idea, how
soon its answer could go stale, whether it is mature, its language, the
cards it builds on, and the picture that would help. The tags are the
levers the dealer pulls for one reader and not another, so each is a claim
about the card and is checked like one: the vocabulary lives in
`tool/cards/schema.json`, the gate holds every card to it, the writer
describes a new card with them and the critic reads them against it. The
plan reaches for the thinnest strand under each subject before any strand
gets a third card, and offers the writer the three thinnest principles
rather than one, so the principle fits the strand instead of being forced
onto it. The 170 cards written before the tags existed were tagged by hand
and sit under the nearest strand; `tool/cards/tag.py` asks the model to tag
whatever has none.

On the phone the tags are read three ways. A genre or strand the reader
turned off in the mix goes behind every card that is on, never out of the
pool. What they hold and what they throw down moves a **taste**, a lean on
every trait of that card — its genre, strand, era, hook, mood, numeracy —
and a card sharing several traits with what was liked is dealt sooner,
one like what was thrown down later, between a fifth and three times the
draw. And no two of a day's cards share a strand while the same tier of
the pool can help it; a card that builds on another waits for it.

The question of the day travels with the bank as a calendar, edition to
card id, frozen when written and extended a year ahead every night. Before
the calendar existed it was computed from the pool on the fly, and a card
added anywhere re-dealt every day since the epoch; now the app only
computes past the calendar's end.

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
restart resumes the same five — a card retired from the bank since still
opens in a deck that holds it. Pills already read are kept out of later
days until the pool runs dry.

## The day, and whose it is

A day is five cards on both plans. On the free plan one of them is the
reader's own — dealt from the mix, from the subjects and strands they kept
on, at the level they said they were — and four are everybody's: the
question of the day, and three more from the day's edition, the same for
every free reader in the world (`commonOfEdition`, chained so a card does
not come round for weeks, never two of one subject; a reader who has
already read one takes the edition's next spare). The morning after the
streak reaches a multiple of seven, two of the five are the reader's own
— nothing to redeem, the deck simply has one more (`ownCardsFor`). With
Astute+ all five are the reader's own: at the level the app has measured
rather than the one they said, leaned by what they held and threw down,
with a card that came due for review in an asking slot — and no question
of the day, because there is nothing left in the day that is not theirs.
`dealDay` returns a `Deal`: the cards, and which of them are the reader's
own, which the free day marks on the card ("FOR YOU") so the difference is
visible every morning rather than described once on a paywall.

The question of the day (`lib/data/daily.dart`) is one edition a day from
the first of September 2026, chained so the same question does not come
round again for months, and dealt from the first edition on every phone
that holds the same pool, which is what makes it the same question
everywhere. It costs the mix nothing. Every card that asks and can be
marked lives under Thinking, and Thinking was never off anybody's deck.
What the shared question buys is a common object — the card a friend can
be asked about ("did you get it?"), the one the morning notification can
quote a fortnight ahead, the one square in the shared grid that means the
same thing on every phone. A subscriber's morning opens on one of their
own instead, and the reminder and the widget quote that one (`leadOn`),
dealt the way the morning will deal it for a reader who has been away.

**Two of five ask.** It was four, on the evidence that only answering
trains anything, and the evidence has not changed — but a day that is four
decisions long is a day that gets put off, and a day put off trains
nothing. Two questions is still two judgements with a confidence on each,
which is what the calibration record is made of; the other three are the
reason to open the app before coffee. The ladder is paced to that. On the
free plan the question of the day takes the first asking slot and the
second is the reader's own. With Astute+ a card that came due for review
takes an asking slot before any fresh question does — one at most, so a
day always has one question it has never asked. What came due and found
no room waits after the five, on the finished day, on either plan.

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

## The home-screen widgets

Three, drawn in the app's own type and colours, and each opens the app when
tapped:

- **Today's card** — the card the morning opens on: the question of the day
  on the free plan, one of the reader's own with Astute+, on the subject's
  colour, with the subject as an eyebrow, the question set large and the
  streak in the foot. Small, medium, large (with a dot for each of the
  five), and the lock-screen rectangle on iOS 16+.
- **Streak** — the days in a row, large, and the week under it: seven dots,
  filled for a day read through, today's ringed. Small, and on the lock
  screen a ring for the week round the number, and a line.
- **Today's five** — the day's five cards in their colours, in the order
  they are read, solid with a tick once read, and how far the day has got.
  Medium.

The widgets are native — WidgetKit on iOS, `AppWidgetProvider`s on
Android — and neither can run Dart, so the app hands over what they will
need through the `astut/widget` channel (`homeWidgetData`), at launch, on
coming back to the foreground and after every card: today's card with its
colour and ink, the card, colour and subject for each of the next fourteen
mornings, the streak and the week, today's five and tomorrow's, and every
line they can say, already in the reader's language. So they turn over at
midnight whether or not the app is opened — the week rolls a dot on, the
five turn to tomorrow's, all still to read — and go quiet after a
fortnight rather than lying.

On iOS, before the app has ever handed anything over — or while the App
Group below is missing — today's card is not blank: it reads the question
of the day from `widget/days.json`, which the web deploy publishes beside
the app (`tool/widget_days.dart`, two months of editions), and keeps the
last copy for when the phone is offline.

**Android** is `AstutWidget.kt`, `AstutStreakWidget.kt` and
`AstutFiveWidget.kt`, their layouts (grounds drawn white and tinted by the
provider, since `RemoteViews` cannot recolour a shape), and the receivers in
the manifest, named in the widget picker in all thirteen languages.
`.github/workflows/android-check.yml` builds a debug APK on every push that
touches them.

**iOS** is the `AstutWidgetExtension` target in `Runner.xcodeproj`, built
from `ios/AstutWidget/`: the three widgets in one `WidgetBundle`
(`AstutWidget.swift`), the views they draw (`AstutWidgetViews.swift`),
their names in the widget gallery in every language
(`Localizable.xcstrings`), the fonts, taken from `assets/fonts/`, its
`Info.plist`, its entitlements, and an xcconfig that reads Flutter's
`Generated.xcconfig` so the extension carries the same version and build
number as the app — App Store Connect refuses an upload where they differ.
The target was written into the project file by hand, and Runner embeds it
as a foundation extension and depends on it, so `flutter build ios` builds
both. Both the app and the widget carry the App Group
`group.com.astuto.app` in their entitlements: `AppDelegate.swift` writes
the hand-over into the group's defaults and asks WidgetKit to reload; the
widgets' timeline providers read them back.

**Seeing them without a phone.** `tool/widget_previews/Render.swift` draws
every widget, home screen and lock screen, in Italian and in English, from
the very views the extension uses, and
`.github/workflows/widget-previews.yml` runs it on a Mac on every change
and publishes the pictures on the `widget-previews` branch
(`widgets-it.png`, `widgets-en.png`).

Two things the tree cannot do by itself:

- **The group has to exist.** The App Store Connect API can turn the App
  Groups capability on — `codemagic.yaml` does, on both App IDs, before it
  mints the profiles — but has no call that registers a group or ticks it
  on an App ID. That is done once at developer.apple.com → Certificates,
  Identifiers & Profiles → Identifiers: register the App Group
  `group.com.astuto.app`, then on each of `com.astuto.app` and
  `com.astuto.app.AstutWidget` (the build registers the second if it is
  missing) open App Groups → Configure and tick it. Until then the build
  checks the profiles, leaves the group out of both entitlements instead of
  failing at signing: today's card shows the question of the day from the
  web, and the streak and the five ask for the app to be opened.
- **Compiling it needs a Mac**, so `.github/workflows/ios-check.yml` runs
  `flutter build ios --release --no-codesign` on a GitHub macOS runner on
  every push to `main` that touches `ios/` or `lib/`, and lists what was
  embedded. It signs nothing and uploads nothing; it only says whether the
  project as checked in still compiles, which a phone cannot.

## Selling Astute+

The app sells one entitlement through RevenueCat and knows nothing about
product ids: it asks the current offering for a yearly and a monthly package
and believes the store about who has paid. So the whole setup lives in two
dashboards, and has to agree with three names here.

- **App Store Connect**, app Astute: a subscription group *Astute+* with
  two auto-renewable subscriptions, `com.astuto.app.plus.yearly` (a year,
  €29,99, an introductory offer of one free week) and
  `com.astuto.app.plus.monthly` (a month, €3,99, no offer). The ids carry
  the bundle id so they can never meet another app's in the same account.
  The week has to be seven days: the paywall says "Try 7 days free" when
  the store reports a free introductory offer, and nothing else.
- **RevenueCat**, in a project of Astute's own: the App Store app with
  bundle `com.astuto.app` (its public key is `REVENUECAT_IOS_KEY` in
  `codemagic.yaml`), the account's In-App Purchase key uploaded to it, both
  products imported, one entitlement named exactly `astuto_pro`
  (`kPlusEntitlement`) with both attached, and the `default` offering, set
  as current, holding an *Annual* package for the year and a *Monthly* one
  for the month.
- **Beside the price**, Apple wants a way to restore and links to the terms
  of use and the privacy policy, in the app and in the listing (3.1.2). The
  paywall's last line carries all three; the terms are Apple's standard
  licence and the privacy policy is `site/privacy.html` on this site
  (`lib/legal.dart`), in English and Italian, naming every service that
  handles a reader's data — a test holds it to that list. The listing's
  description needs the terms link too.
- **Google Play's reviewers** must see what is sold, may not pay and may
  not use a free trial, and Astute has no sign-in to lend them. So the
  Android app takes one code, written only into Play Console → App content
  → App access: long-press the ASTUTE+ badge on the Astute+ screen, type it,
  and Astute+ is on for that phone (`lib/sync/review_access.dart`). Only
  its SHA-256 ships; the code is in Play Console and not in this
  repository. An iPhone never asks — Apple's reviewers buy in the sandbox,
  and Apple does not allow codes that open what the app sells.
- **Nothing to sell is not Astute+ for nothing.** When the store has put no
  plan on sale, the buy button unlocks locally only on the web preview and
  in debug builds, so their gated screens can be seen; a store build says
  the purchase did not go through. And the developer tools at the foot of
  the profile, which can switch Astute+ on, stay out of any build that goes
  to review or to readers: build it with `--dart-define=DEBUG_TOOLS=false`.
- **A way out of the account**, which Apple requires inside any app that
  makes accounts (5.1.1(v)): *Delete account* at the foot of the profile's
  account rows. Whoever signed in with Apple or Google confirms with the
  same sheet — Firebase deletes a sign-in only on a fresh session, and
  Apple's fresh authorisation is what revokes the app's access to the Apple
  ID (that needs Apple's key on Firebase's Apple provider; without it the
  account is still deleted). Then the backup and the board go, the sign-in,
  the store's hold on the account, and everything on the phone. A board the
  deployed rules will not let its owner delete is emptied instead.

**Checking it from the phone.** The debug section at the foot of the
profile reads back what the store answered: whether it did, the offering,
the product, price and free week of each plan as the store priced them, and
whether the entitlement is active. A plan that reads "not in the offering"
is a RevenueCat package missing; one whose price never arrives is an App
Store product not yet *Ready to Submit*. The first subscriptions go to App
Review with an app version, attached on the version's page.

## What the app measures

Nothing, unless a key was built into it. `lib/analytics.dart` is the one place
that decides, the way `lib/cloud.dart` is for Firebase: no `POSTHOG_KEY`, no
measurement — not "measurement into a project that does not exist", but every
call returning without doing anything. That is what a fork gets, what a
checkout gets, and what all 266 tests run under, which is why none of them
reaches the network.

    flutter build ipa      --dart-define=POSTHOG_KEY=phc_xxx
    flutter build appbundle --dart-define=POSTHOG_KEY=phc_xxx

The key is public in the same way the RevenueCat keys are: it names the
project to write into and reads nothing back. `POSTHOG_HOST` picks the region
and defaults to the EU one; a project made in the other region and pointed at
from here accepts nothing and says nothing, which is a long afternoon. The
TestFlight build takes it from `codemagic.yaml`, beside the RevenueCat keys;
a build made anywhere else has none. Astute's project sits in a PostHog
organization of its own: the free plan allows one project per organization,
and the account's other app has the first.

**Three rules hold at every call site.** It never throws and never blocks —
measurement is not a feature the reader asked for, so it may not cost them a
frame. It is off until told otherwise. And it carries no prose: ids, counts
and enums go out; the name the reader typed, their email, their friend code,
the text of an answer and the reason they wrote beside it do not. A card is a
pill id and a subject. What a reader *said* is theirs, and there is a test
that types a sentence into an answer and fails if it appears anywhere in what
was sent.

**The funnel is the app's own shape.** A day dealt, with how much of it is a
re-asking. A card advanced, with its place in the five, so the drop-off inside
a day reads as a curve rather than one completion rate. A card answered, with
the confidence but never the reason. The day finished, with what it was worth
rather than what the reader now holds. Then the things that decide whether
there is a second week: a rung reached, a freeze earned and spent, a plan
changed — and `pill said`, a card that left the phone and was said to
somebody, which is the one number this app is actually for.

The paywall takes the gate that opened it as a required argument rather than a
defaulted one, so `onboarding`, `sixth card`, `journey`, `archive` and
`calibration` can be told apart. A default is how a fifth of the traffic ends
up labelled `unknown` by the end of the first week.

**Screens are named by hand.** The three tabs are one route and the rest are
unnamed pushes, so a navigator observer would report `/` and call it a
session. `ScreenView` in `lib/widgets/ui.dart` names each one where it is
built, which means a screen reachable from two places is still one name.

**The reader's switch** sits at the foot of the settings, above the debug
section, on by default and off in one tap, in all thirteen languages. It is
applied to PostHog the moment it moves, and written back after a sign-out —
sign-out clears every key the app holds, and a choice a wipe undoes is a delay
rather than a choice. It turns off everything below as well.

**Replays, with every word hidden.** Session replay is on, because PostHog's
self-driving loop reads replays, errors and rage taps to find where readers
get stuck and to propose fixes — but with `maskAllTexts`, so every word on
the screen is a grey bar in the recording. The screen carries the reader's
own written reasons, and a recording of them is not worth any finding;
layout, taps and scrolls are what is left, and they are what a stuck reader
looks like. `PostHogWidget` wraps the app for it, only where measurement is
running.

**Errors.** Every error the app does not catch — Flutter's, Dart's, the
isolate's and the phone's own — goes to PostHog's error tracking with the
steps that led to it. The ones the app catches and carries on from (a backup
that failed, a store that would not answer, a sign-in or a purchase that
broke, an account that would not delete) are sent with `Analytics.error` and
where they happened.

**What else is measured, and how finely.** Every card event carries the
card's own tags (`AppState.cardFacts`): its subject, genre and strand, the
principle it teaches, its difficulty and kind of question, era, region, hook,
mood, numeracy, abstraction and shelf life — and, when it is one of today's,
its place in the five and why it was dealt (the question of the day, the
reader's own, the edition's, or a review). A card is *viewed* when it comes
up and *advanced* with how long it held the reader; answered with how long it
took. The day says which slot each card fills; the end of the day how many
were right and wrong. A streak that breaks is said once, milestones and
records when they happen. The first run is measured step by step and scene by
scene, with how long each held the reader and where it was skipped. The
paywall says which plan was picked, how long it was open, how it was left and
which link was opened; the store says what it put on sale and every change to
the subscription — trial, renewal switched off, billing issue, expiry. Then
the health of the app: the time to the first frame, Firebase starting, the
store answering, the cards refreshing from the site, backups failing, and
which reminder or widget brought the reader in, and which widgets they have
placed. The profile in PostHog is kept to counts and choices — plan, streak,
rung, what is set up — and a handful of them ride on every event.

On the web the plugin brings no library of its own, so
`lib/utils/analytics_boot_web.dart` puts posthog-js on the page and starts it.
Nothing waits on it: a blocked CDN or a dead network costs the preview its
numbers and not its first paint.

## The mix, one layer down

Artboard 86a, and the third screen of the onboarding. A subject is too coarse
to pick with: two readers both ask for Space and one of them means rockets
while the other means how big the thing is. The wheel before it cannot tell
them apart, and a day dealt from "Space" serves neither.

So every subject carries six **genres**, and every genre three **strands**
under it — 108 and 324 of them, in `lib/data/genres.dart`. They are in
English, like the cards: these are names of things to write about rather than
words the app says for itself, so the chrome around them is translated
thirteen ways and a genre is content.

The screen is a reading of the wheel rather than a second, unrelated list.
The subjects are in the order the reader just put them in, and one asked for
more is **drawn larger** — the planet runs from 26 to 61 points across, off
the same number the wheel wrote down. A subject dragged to nothing keeps a
dimmed line at the foot of the list rather than vanishing, because a subject
that disappears reads as one the app does not have.

Everything starts on, as the wheel does: the reader is turning things down,
not building a deck out of nothing. A tap skips a genre. A **hold** opens its
three strands *in place*, on a line under the row rather than in a sheet over
it — there is no backdrop and no Done button, and the list keeps its position,
so the six a reader is comparing against stay on screen. A genre with some of
its three turned off carries a small count; one with all three carries
nothing, because a badge on every genre says nothing at all.

It is also the last thing the onboarding asks. There used to be a third
screen after it — *what you already know*, three answers a subject — and it
has gone. It asked the reader to rate themselves before they had seen a
single card, at the one moment they had least to go on, and then never asked
again: the answer aged from the first morning and nothing updated it. The
app already knows what it was trying to find out, and knows it from what
actually happened — which subjects the reader gets right, and how sure they
said they were. `topicLevels` still reaches the dealer and still travels in
the backup, so a reader who set it keeps it; what is gone is the screen that
asked. And the measurement now fills it: `measuredLevels` takes a subject's
last eight judgements, once there are four, and sets its level from them —
three in four right is solid, two in five or fewer is curious — over
whatever the reader said. A subject they have never been asked about keeps
what they said, or the middle.

The choice is stored as what was turned **off**, not what was left on. A genre
added in a later build then reaches everybody, instead of being hidden from
every reader who chose before it existed. It travels in the backup under the
same rule as the mix — the decision made most recently wins — because a union
would quietly resurrect a genre this phone turned off.

## What is not real yet

These are declared in the UI rather than faked:

- **Notification delivery.** The permission is asked for and the token is
  registered, so a phone can be reached — but nothing sends yet. Deciding who
  gets what, and when in their own timezone, is the work that remains.
- **Email sign-in.** Apple and Google are wired; the email button says plainly
  that it is not connected. Firebase's email link needs a domain of ours with
  universal links, since Dynamic Links was retired.
- **The bank is still the first hundred and seventy.** The pipeline that
  grows it is built and tested against a canned model; the first real night
  needs an `ANTHROPIC_API_KEY` in the repository's secrets and Actions
  allowed to open pull requests. Until then sixty cards that tell, at three
  a day, is twenty days of new reading.
- **The kept signing key.** Optional. Without it `codemagic.yaml` signs as it
  always has: it revokes every distribution certificate in the account and
  mints a new one, which needs nothing set up but fails, with ITMS-90035,
  any build of any app in the account that is still waiting for App Review
  (Improvy 1.16.0 (40) and 1.17.0 (49) were refused that way). With a key
  kept in Codemagic as `CERTIFICATE_PRIVATE_KEY`, group `signing`, Secret,
  the same certificate is reused and nothing is revoked.
- **The App Group in the developer portal.** The widget target, its
  entitlements and the signing are all in the tree, but the group
  `group.com.astuto.app` has to be registered and ticked on both App IDs
  by hand, as described under *The home-screen widgets*. Until it is, the
  build leaves the group out rather than failing at signing: today's card
  shows the question of the day from the web instead of the reader's own,
  and the streak and the five ask for the app to be opened.
- **Depth under every strand.** Every card is tagged with a strand and the
  dealer honours the switches, but 170 cards over 324 strands is a card
  under half of them and nothing under the rest; a reader who turns
  everything off but *Space · Rockets* is dealt those cards and then
  whatever is nearest. The generator writes towards the thinnest strands
  first, so this closes at the pace of the nightly run.

Since the sections above were first written, three of the things listed here
stopped being true and are now real: accounts (anonymous, Apple, Google, with
the merge described above), the backup, and the plan, which comes from the
store through RevenueCat rather than from a bool the app wrote to itself.

**Debug tools.** The foot of the profile carries a temporary section — wipe
and restart, toggle the plan, and a readout of what the app knows about
itself: whether Firebase started and why not, the account id, the last auth
error, whether the store answered, and whether PostHog is sending, opted out
or not running at all. It is on in release builds on purpose,
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
head. The app plans a fortnight of them at a time (`reminderPlan`), each
with the question of the morning it lands on: the question of the day,
which is everybody's, or with Astute+ the reader's own lead, dealt the way
that morning will deal it for a reader who has been away. On the days a lapse reaches it says something about the reader
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
- **Astute+ sells the reader's own day, not more of it.** More cards is
  the pitch every rival makes better, and the day stays five cards on both
  plans. What is sold is whose they are — five from the reader's mix at the
  level the app has measured, against two — and then what the app knows
  about the reader: the journey — the level, the numbers, every subject
  opened strand by strand, what stayed — and whether the gap is closing
  over time (`Trend`). The measurement itself stays free on the profile,
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
