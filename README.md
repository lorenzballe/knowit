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
  plain HTML in `site/index.html`, on classes rather than inline styles,
  with its sections laid out in `site/assets/landing.css`: the first screen
  with its phone — an iPhone drawn in CSS, island, status bar and titanium,
  with the app's Today screen laid out in the app's own points rather than
  pictured — and four hard cards from the bank around it, today's question,
  the day's row, the two cream sheets laid on the night paper (calibration,
  the science), the cards that flip, the subjects going by both ways, the
  app's five screens in a row, the widgets, friends, the plans, the
  questions and the last word. `site/assets/main.js` adds what moves: the
  menu, the nav that floats and frosts and its progress line in the three
  lights' colours, things that come into view as they are reached, numbers
  that count up, a light that follows the pointer across a card, the phone
  that turns towards the pointer and faces whoever reaches for it, five hard
  cards on it that play as in the app (an answer, how sure, the card turned
  over with the answer arriving word by word, and after the fifth how sure
  against how right), the first of them playing itself once for anyone who
  has not touched it, the cards around it that turn over under the pointer,
  the rows that scroll with their dots, the calibration chart you can drag,
  the cards that flip, the plan picker and the questions. Today's question
  is shown live from `/widget/days.json`, the file the widget reads, with
  the edition in the first screen's kicker and the time to the next one. It
  presents Astute on both stores, with Apple's and Google's own badges: a
  phone's Download goes straight to its own store, a computer's to a code to
  scan with the phone, which opens `/get` and from there the right store. It
  reads fully without JavaScript, and without motion for anyone who has
  asked their system for less. The screens in `site/assets/` are
  `tool/shots/` at 840×1826, as WebP.
- `/privacy`, `/terms` and `/support` — the pages the stores ask for — share
  its nav, footer and `site/assets/site.css`: night paper, cream ink,
  Fraunces and Figtree served from the site itself, and on a wide screen a
  rail of the page's sections beside it. The nav and the footer are written
  once, in `tool/site/chrome.py`, and stamped onto every page between the
  markers each page carries; the deploy stops if a page has drifted. Astute
  is published by TheBaleCompany, and every page says so.
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
empty state, Profile (record, appearance, topics, how well you know
yourself, the button into the journey, daily nudge), the come-back screen
after a lapsed streak, and the disclosure page on how pills are written.

**Astute+** — three things, all delivered, and everything else the same on
both plans. **Five cards a day, all yours**: on the free plan two of the
five are chosen for the reader and three are dealt at random from the
subjects they kept on, and with Astute+
all five are the reader's own, at the level the app has measured, with a
card that came due for review. **Your journey**: the level and the numbers,
every subject opened strand by strand, what stayed when a card came back,
and the moves you keep missing — the screen is Astute+; the profile keeps
the record itself free. **Your whole archive**: the free plan keeps a week. €3,99 a month, €29,99 a year with
fourteen days free, the only free trial there is, offered once at the end
of the onboarding with "continue free" written under it — to a reader who
set their mix. That is where most trials start, on the first day, and a
trial asks for nothing today. One who skips the subjects goes straight to
their first day: they have said nothing about what they want and seen no
card. The card after the fifth offers it every evening, and the profile
keeps the plans.
The paywall is sheet 111a, with the app's own three icon tiles; its button
says the free days the store gives this reader (`Subscription.trialDays`):
as many as the year's introductory offer holds, none for a reader Apple
says has had them, and "charged today" otherwise. The card after the fifth
says them the same way, and plainly *Get Astute+* to a reader past the
trial. The mix, the streak, the freezes, the friends, the sharing and the
search are free: they are how the app spreads.

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
The evenings there is something to say about the plan, it is said on the
card after the fifth rather than on this screen (see *The sixth card*):
the shelf is the day's five, and a line added over them would take room
from the cards. The cards on the shelf keep the mark they carried in the
deck, beside the subject: *For you* on the free plan's own, *Again* on a
card back for another go. One card, marked one way, whether it is being
answered or read again.

## The sixth card

The one card in the app that is not a card. On the free plan it is the
last card in the deck: it peeks from under the fifth like any next card,
comes to the top when the fifth is thrown, and is thrown the same way — a
rim of every colour the deck has, turning, with its light spilling onto
the table, and one offer: "all five, yours". The button is the
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

It is also where the week is said, under its eyebrow, once the day is done
(`weekNoteOf`): the evening a week is kept, that tomorrow three of the five
are the reader's own instead of two, said once, the night before, where it
reads as a reward rather than a rule. The offer and where the week has got
to are the same subject, so they share a card, and a test holds the
longest of it to fitting in every language on a small phone.

## Your journey

Artboard 137a: tiles, two to a row, the score first.

`JourneyScreen` opens on **the score** — the record as one number, where
four things are worth what they cost: a card read is one, a card still with
you weeks later three, a move you can spot ten, a week kept five — with
what the last four weeks added to it in green, and a **line of weeks**: the
score at the end of each week since the first day, a point a week. Tapping
a point moves the pink ring to it and the sentence under the chart says
what that week earned and how many cards were first read in it ("This week
so far, you earned 27 points."). Then **the level**: its name set large,
how far the next one is ("2 points from Sharp") and the ladder as seven
bars that grow, the next one dashed; it opens the path.

Then the tiles. **Worth**: the cards read as books, fifty to a book, and
hours of documentary, with the book under way drawn as far as it has got.
**In a row**: the streak, the best run, the days read of the days since the
first, and the last two weeks as squares; it opens the week read back in
full. **The subjects**: every subject round a wheel in the order of its
colour, the shape the cards read in each make, and the same at the end of
the first month dashed under it; a subject's mark opens the cards read of
it. **How hard** the cards opened are, easy one to hard three, and **reading
time** as far as the app has timed it, with minutes a week lately against
the start. **Points off**: how far the reader's confidence runs off their
results, week by week, against the green band the top level asks for
(until twelve answers are said how sure, a dash and how many more).
**Right when sure** — at 80% or more, over the last four weeks — and the
**moves** they can spot, with the newest. **What stayed**: the cards still
with them, and how the cards went when they came back after each wait on
the review ladder — two days after a miss, a week after the first right
answer, three weeks after the second — now, against four weeks ago. **The
days**: thirteen weeks, a square a day, as dark as the cards read on it,
and when most are read. And how far it reaches: **in time** (from the
oldest era a card read is set in to this year), **in place** (the regions
of the world), **topics** (the strands inside the subjects) and **words**
(the terms the bank uses on three cards or more, the three met last).
Once the day is done, the day as five squares to send sits at the foot.

Everything is counted from what the app writes down, with a date where it
has one (`JourneyRecord`, in `lib/state/journey_record.dart`):
`readDays`, the cards first read each day, and `dayLog`, what each day came
to — the score at its end, the seconds on its cards (a card counts for five
minutes at most) and the cards read in each part of the day. Both travel in
the snapshot: a card was first read on whichever phone read it first, and a
day's counts are the larger of each. A phone that read before this was
written down gets its days from what each day dealt (`deckHistory`), and the
cards no record dates count as older than any that are. A day before the
log is counted again from the dated record — the cards read by then, the
dated answers replayed for the cards held and the moves, the weeks kept —
and what nothing recorded is not worked out: it shows as a dash and says
why ("Counted from today").

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
the canvas ranks it by what everyone saved, and saving is counted now, but
by the top list. Its rows were "the ones that ask the most", hardest first,
which nobody could read and which For the sharpest already is further
down; they are **a question from every subject** now — cards with a right
answer, one subject after another, the same for everyone and for good, so
a row read is the only thing that moves it. The third one the app can say
for real, because the mix is the reader's own: **Because Space sits at
full**, from the subject they pushed furthest up.

**Read or not.** A card read anywhere is read: a card opened in Explore
and turned past, or open when the viewer closes, counts like one read in
the day (`markReadElsewhere`), so the day never hands it back as a daily
card months later. Explore then treats its shelves by what they are for.
The top list is one list for everybody, so a card the reader has read stays
on its place, with a tick and *Read* under it. The shelves for finding
things — today's, *loved since the start*, a question from every subject,
*because Space* — hold only cards the reader has not read, because a card
already read is not a find. Somebody who arrived late finds the best of
what came before them; somebody who has been here two years finds the next
one they missed, never a list of old news.

**Loved since the start** sits under the top list: the cards readers held
on to most over all time — the counts kept for good at `totals/{shard}`
(the part of a card's id before its first dash), plus the launch crowd's
average since the first of September 2026 — minus what the reader has
read. It is not closed day by day like the top list: it is a shelf for
finding what you missed, not a ranking to quote.

**The top of the week and of the month** sit under today's shelf: the cards
readers liked, saved and said most in the last 7 or 30 days, with a Week /
Month switch level with the name, narrowed by the subject row like every
other shelf ("Top in Economics"). It is the one ranking that came back,
because it is the one with something true to rank by. It is numbered — a
top that does not say which is first is not one — but the cards stay cards,
each standing over the edge of its number, cut out of it by a ring of the
page's colour, the number fading down behind it; each says how many readers
kept it.

How it counts (`lib/sync/tally.dart`): the first time a reader likes, saves
or says a card, their phone adds one to that card's count for the day, at
`tallies/{UTC day}` in Firestore — a number per card and nothing about who.
Once per card per phone, ever, so a count is a count of readers, and
liking, unliking and liking again is not a way up the list. Explore reads
the last 30 days, at most every ten minutes; days older than three are
settled and read once, then kept on the phone. Without the launch crowd
below, until the counts have been read — or where they cannot be, offline,
on the web preview, or before the rules are published — nothing is ranked: the shelf shows its first three
places numbered and empty, the first saying what puts a card there, at the
list's own height so nothing jumps when the cards arrive. A first version
hid the shelf until the counts were read, and so on every phone where they
could not be it was a feature nobody could find.

**One list, fixed for the day.** The list counts closed days only: the
rules take a count for a day until two days after it began, so from
midnight UTC the day before yesterday is final, and the week is the seven
days up to it. That makes it the same list on every phone, and one that
does not move from one midnight UTC to the next — a list that counted today
would shift under the reader all day, and differently on each phone, since
a phone sees its own like at once and everybody else's only on its next
reading. Two days of lag is the price, and a top of the week can pay it.

**The launch crowd.** A top list opened as three empty places, on every
phone, for the weeks before anybody had held on to anything — so for now
it is seeded (`TopSeed`, installed in `main.dart`). About one card in seven
is given a believable daily following, heavy-tailed the way real lists are
and turning over month by month, tilted to what readers keep (a question
over a fact, a debate over both, the hard ones); the real counts are added
on top and rank above it as they come. It is the same list on every phone,
because it is computed from the card ids and the day. It is a stand-in and
says nothing true about readers: construct `Tallies.instance` without a seed
to retire it once the real counts can carry the list alone.

`firestore.rules` holds every write to one card, plus one, on a day that is
today on some clock, and lets nothing be taken back. **The rules have to be
published for the list to fill**: Firebase console → Firestore Database →
Rules → paste `firestore.rules` → Publish (or `firebase deploy --only
firestore:rules`). The write is anonymous but not unforgeable — someone with
a script could add to a card over and over — which at this scale is a risk
the list can carry; per-reader limits would need a server.

**What is online, and what is on the phone.** The way the apps that feel
like they know you do it, in proportion. *The server decides.* What the
reader does is written down with their account (the trace, below), the
server reads it and deals their day and their Explore shelf from it, and
the phone reads one document for each. *Only what is needed travels.* A day
is five cards whole; Explore is the shelves whole; the search is asked on
the server. The phone still carries a bank, but downloads a new one only
when `cards/version.json` names it, and uses it for the one thing the
server cannot do — deal a day when it is not there. *Offline shows what
was last read.* The server's day is kept on the phone the evening it
arrives; Explore as last read is shown with a line saying so, and the
counts the phone keeps are the closed days only, so nothing offline is a
guess. What the server cannot do in time, the phone does as it always did:
the morning waits four seconds for the day, eight for one dealt on the
spot, and then deals from the same calendar. See *The server*, below.

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

### The mix: a form for every kind of card

Under the shelves that were always there (today's, the top list, loved since
the start, a question from every subject, the reader's own), Explore used to
turn over themes that all looked the same: a name, a line, a row of small
cards. They are gone. In their place each kind of card has a shelf laid out
like what it holds, from artboards 131–141 (`lib/data/explore_mix.dart`
deals them, `lib/widgets/explore/` draws them), dealt for the day from what
the reader has not read, each card on one shelf only.

The order is fixed, and reads in three movements.

**Cards to read.**

1. **A month of one subject** (131f's bento). The subject's mark is drawn
   large on the lead cards: a star for Pop culture, a planet for Space. The
   subject turns on the first of the month, through every subject but
   Thinking before one comes back.
2. **Myths, busted** (131e's deck, thrown aside one by one).
3. **Numbers that surprise** (the figure itself).
4. **Use it today** (131's list): something to try, or to drop into a
   conversation, before tonight. Each row is the thing itself and opens its
   card. The rings to tick one off as tried are gone: nobody could tell what
   they were for.
5. **Pick a side** (two halves).
6. **For the sharpest**, **Where it came from**, **Seen, not read** and
   **True stories** (133e).

**Cards to play.**

7. **True or false** (133e), answered on the shelf. The answer is kept like
   any other, and the card counts as read.
8. **Do you still remember?** (133d): the cards answered days ago, back to
   see if the answer stuck, each saying how long it waited and how it went
   last time. Only there when something is due.
9. **Who got counted?** and **Compared to what?**: two of the questions that
   catch a trick in a number (138b), named like every other shelf, with what
   the reader has done with the move level with the name. Who got counted
   asks who ended up in a study, since that decides what it can tell you;
   Compared to what asks for something to set a change against. They were a
   move's name set large in a box of its own, which took more room than the
   cards and still did not say what it meant.
10. **Work it out** (133b). Every way of putting a number on something, on
    one row: pick one, move it and check (138d), closer and closer (139d),
    which is bigger (139c), bet a range (139a), place your bet (139b). Two
    of each, in an order drawn for the day — a round of every way, then
    another, never two of a kind side by side — every card the same size and
    saying in its corner which game it is. There is no choosing a way first.
    Bets come out of a hundred points a day. The figures are the cards' own
    answers.
11. **Unmask the chart** (138d). A real chart from a card plays its trick,
    and then is redrawn honestly.
12. **How sure am I, and why** (138c) and **What if it's true?** (138a).

**Ways in by time.**

13. **In a few cards** (140d's series, odds that lie among them).
14. **Sixty seconds** (140d): eight claims against the clock, the same
    eight for everybody that day, and the score and the misses at the end.
15. **Your mood, your minutes** (140b). Pick a tone and the time you have;
    the cards are from the bank, not the reader's own.
16. **Today's edition** (141f): the same front page for everybody, the lead,
    two columns, the day in numbers, a correction and a puzzle.
17. **Through time** (141c's ruler). Pick an age and get its cards; they
    change every day.
18. **Did you know?** (141b): a pile to turn over, new to me or knew it.
19. **Not sure where to start** (138f), at the very bottom: one card from
    anywhere.

The whole of Explore is free. It is what brings a reader back every day.
The paid perks stay the three they are: five cards all the reader's own,
the journey and the whole archive.

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
02:17 UTC, once a nightly count is set (`CARDS_PER_NIGHT`, with a budget
in dollars beside it), and `tool/cards/generate.py` asks for what the bank is short of —
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
cards, their sites and the receipt in its body. The deploy then publishes
the new `cards.json`, and every phone picks it up. Every stage runs through
the Batches API at half the token price. `tool/cards/README.md` has the
loop in full, the cost of a card, and how to retire one.

**How good they are** (`tool/quality/`). Not every card waits for a
person, and not every card goes out without one. Each new card is scored on
how it got through — the critic passing it first time, the quote found on
the page by a program, a fact that will not change — and the doubtful ones,
with one in ten of the rest, leave the bank for `tool/cards/review/`, listed
in an issue with **Publish** and **Drop** under each; a tick does the rest.
Readers can say a card is wrong (*Report a problem*, under every card's
source); the server adds up every day how each card does — right and wrong
and how surely, the options picked, likes, throws, reports — flags a card
far easier or harder than its label, or whose marked answer the crowd
overwhelmingly rejects, and takes a card three readers say is untrue out of
the deal until it is checked. Once a month the cards that are out are
checked again, the reported ones first and then the ones whose answer can
change; and the critic itself is measured on good cards and cards with an
error planted in them. `tool/quality/README.md` has the loop and the knobs.

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
whatever has none. In September 2026 the bank was grown by hand to at least
five cards on every strand (see *The first hand-written set* in
`tool/cards/README.md`).

On the phone the tags are read three ways. A genre or strand the reader
turned off in the mix goes behind every card that is on, never out of the
pool. What they hold and what they throw down moves a **taste**, a lean on
every trait of that card — its genre, strand, era, hook, mood, numeracy —
and a card sharing several traits with what was liked is dealt sooner,
one like what was thrown down later, between a fifth and three times the
draw. And no two of a day's cards share a strand while the same tier of
the pool can help it; a card that builds on another waits for it.

The question of the day travels with the bank as a calendar, edition to
card id, with the edition's eight reads beside it, frozen when written and
extended a year ahead every night. No day deals them any more (see *The
day, and whose it is*); the site and the widget's fallback read the
question, and the phone and the server keep reading the same calendar. Before
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

**Diagrams.** A handful of cards, the ones whose point is a quantity the
eye grasps faster than the sentence, carry a `diagram`: a few numbers and
labels, never pixels, that the reveal draws live in the card's own ink
and animates the way someone at a whiteboard would explain it — the frame,
then the thing, then the comparison that is the point, with strokes laid
down by a pen and figures counting up as the shapes that carry them grow.
Tap it to watch again; with reduced motion it shows the last frame. There
are eight kinds (`dots`, `bars`, `scale`, `area`, `split`, `line`,
`timeline`, `tree`), in `lib/models/diagram.dart` and
`lib/widgets/diagram_view.dart`, and every layout decision (where a label
goes so that no label, leader or curve crosses another) is made in the
painter, not by whoever writes the card. They are deliberately few: each
was chosen because it shows the thing intuition gets wrong, and each
number in it is the card's own. `tool/cards/diagrams.py` is the gate for
them, run by `check.py`, and `test/diagram_preview_test.dart` renders them
for a person to look at (three moments side by side, or every frame with
`DIAGRAM_FPS` for a video). A native painter rather than rendered video:
it follows the theme, stays sharp at any size, costs a few hundred bytes a
card and works offline.

Today's deck is dealt deterministically from the date and the reading
history, so it does not reshuffle mid-day, and it is stored by id so a
restart resumes the same five — a card retired from the bank since still
opens in a deck that holds it. Pills already read are kept out of later
days until the pool runs dry.

## The day, and whose it is

A day is five cards on both plans.

**No welcome.** The first days read used to be a welcome, four of the
five the reader's own with no card asked for. Beside Astute+'s free trial
it was a second free thing, and two free things read as one too many: the
one way to try all five is now the trial, and the free day is the same
from the first morning, so what Astute+ adds is there to see from the start.

On the free plan two of the five are the reader's own —
dealt from the mix, from the subjects and strands they kept on, at the
level the onboarding was read to start them at (see *Reading the
onboarding*) — and three are dealt at random (`pillsAtRandom`): from the
subjects they kept on, as much of each as the mix as they set it asks for,
never a genre or a strand they turned off, never a card already read, and
a subject the day already holds only when every other subject on the mix
is in it too. Nothing else about the reader goes into those three: no
level, no taste, no review. The morning after the streak reaches a
multiple of seven, three of the five are the reader's own — nothing to
redeem, the deck simply has one more (`ownCardsFor`). With Astute+ all
five are the reader's own: at the level the app has measured rather than
the one they said, leaned by what they held and threw down, with a card
that came due for review in an asking slot. `dealDay` returns a `Deal`:
the cards, and which of them are the reader's own, which the free day
marks on the card ("FOR YOU") so the difference is visible every morning
rather than described once on a paywall.

Nothing in a day is everybody's any more. There used to be a question of
the day, the same Thinking question on every free phone, and three reads
from the day's edition beside it; with Astute+ all five were the reader's
own, so the one card two friends could compare was the one a subscriber
never saw, and the free plan had a feature that paying took away. The
calendar is still kept — `editions.json` and `commons.json`, frozen by
`bundle.py`, read the same way on the phone and the server — because the
site shows its question, the widget falls back on it before the app has
spoken to it, and a card of the day may come back in Explore. No day deals
it. The reminder and the widget quote the first question of the reader's
own day instead (`leadOn`), dealt the way the morning will deal it for a
reader who has been away.

**Two of five ask.** It was four, on the evidence that only answering
trains anything, and the evidence has not changed — but a day that is four
decisions long is a day that gets put off, and a day put off trains
nothing. Two questions is still two judgements with a confidence on each,
which is what the calibration record is made of; the other three are the
reason to open the app before coffee. The ladder is paced to that. The
asking slots go to the reader's own before they go to chance, on both
plans: a question at the reader's level trains, and one drawn at random
only quizzes. So on the free plan both questions are the reader's own and
the three at random are reads. With Astute+ a card that came due for review
takes an asking slot before any fresh question does — one at most, so a
day always has one question it has never asked. What came due and found
no room waits after the five, on the finished day, on either plan.

**Share my day.** Five squares — read, right, wrong, a side taken, passed —
the edition, the streak, how the questions went and how sure the reader
was, and the day's line. Nothing a friend could be spoiled by, because
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
weeks kept, how far off the confidence runs, and today's five as squares
once the day is done — and never a question's text or an answer. A board
published by a build that still dealt the question of the day carries how
it went, and the friends screen still shows it; this build publishes none. A board is
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

- **Today's card** — the card the morning opens on: the first question of
  the reader's own day, on either plan, on the subject's
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
  €29,99, an introductory offer of two free weeks) and
  `com.astuto.app.plus.monthly` (a month, €3,99, no offer). The ids carry
  the bundle id so they can never meet another app's in the same account.
  The app says the free days the store reports, so a trial changed here is
  said right without a new build; before the store answers it says
  `kTrialDays`, fourteen, which is what the offer should be set to. Google
  Play's year carries the same two weeks as an offer on its base plan, for
  new customers.
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
the product, price and free days of each plan as the store priced them, and
whether the entitlement is active. A plan that reads "not in the offering"
is a RevenueCat package missing; one whose price never arrives is an App
Store product not yet *Ready to Submit*. The first subscriptions go to App
Review with an app version, attached on the version's page.

## Astute+ on the web, and the account page

`/account` is a reader's Astute on the web: the same account as the app,
signed in with Apple or Google through the same Firebase project; the
record from the backup the app keeps at `readers/{uid}`, and the gap from
the board it publishes; the plan from RevenueCat; and Astute+ for sale
through RevenueCat's **Web Billing**, which charges through Stripe and
writes the same entitlement, `astuto_pro`, to the same customer. The app
identifies readers to RevenueCat by their uid, so a subscription bought on
the site is the app's own at its next launch, and one bought in a store
shows on the site. Apple lets an app honour what was bought elsewhere as
long as the same thing is sold in-app and the app never sends anyone
elsewhere to buy it (3.1.3(b)); Play is the same in spirit. So the site
sells, and the app does not mention it.

The page is `site/account.html`, `site/assets/account.css` and
`site/assets/account.js`; Firebase's SDK comes from Google's CDN, and
RevenueCat's is vendored under `site/assets/vendor/` (MIT), served from the
site like the fonts. The two public keys it needs are in
`site/assets/keys.js`, and with either empty the page says accounts on the
site are not connected yet. There is no server: RevenueCat's SDK talks to
RevenueCat, Firebase's to Firebase, and Stripe's webhooks are RevenueCat's
to answer. Deleting an account from the page does what the app does — a
fresh sign-in, Apple's token revoked, the backup and the board removed, then
the account — and, like the app, does not cancel a subscription.

The page reads the same without a script, and is `noindex` until the first
purchase has gone through end to end; then the pricing section's Download
links on a computer can point at `/account?plan=yearly` instead of the code
to scan.

**Setting it up**, in the dashboards, once:

- **Stripe**: an account for TheBaleCompany, activated (business details,
  IBAN), with Stripe Tax on so VAT is collected where it is due.
- **RevenueCat**, project Astute: *Apps & providers → + New → Web Billing*,
  connected to that Stripe account. Two products, `plus_yearly` (a year,
  €29.99, fourteen days free; a Web Billing product's trial cannot be
  changed once it is made, so a new length is a new product) and
  `plus_monthly` (a month, €3.99), both
  attached to the `astuto_pro` entitlement, and packaged as *Annual* and
  *Monthly* in the offering the web app sees as current. The web app's
  public API key goes into `keys.js` as `REVENUECAT_WEB_KEY`: the sandbox
  one (`rcb_sb_…`) first, which charges Stripe's test card 4242 4242 4242
  4242 and makes the page say *Test mode*; the production one when it is
  time.
- **Firebase**, project `astuto-3d398`: *Project settings → Your apps → Add
  app → Web*, named *Astute site* — its `apiKey` and `appId` go into
  `keys.js`. *Authentication → Settings → Authorized domains* gains
  `astutetheapp.com`. *Sign-in method → Google* wants a web client, which
  Firebase makes. *Sign-in method → Apple* wants, in the Apple developer
  portal, a Services ID (say `com.astuto.app.web`) with Sign in with Apple
  on for the domain `astutetheapp.com` and the return URL
  `https://astuto-3d398.firebaseapp.com/__/auth/handler`, entered on the
  provider beside the key it already has.
- **The app**, to be complete: an entitlement whose store is `rc_billing`
  is managed on the site, and the Astute+ screen should say so instead of
  pointing at the App Store or Play. Nothing else changes.

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
its place in the five and why it was dealt (the reader's own, at random, or
a review). A card is *viewed* when it comes
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
- **The nightly pipeline has not run for real.** The pipeline that grows
  the bank is built and tested against a canned model; the first real night
  needs an `ANTHROPIC_API_KEY` in the repository's secrets and Actions
  allowed to open pull requests. The bank itself no longer waits on it: in
  September 2026 it was grown by hand to 3,410 live cards, at least ten on
  every one of the 324 strands — five from a first round, and five from a
  second, harder one written for a reader who has already read the first
  five (ids `-6` to `-10`, written 2026-09-27; 40% of its cards that ask are
  `hard`). Every half-subject of the second round was checked by a critic;
  the claims nobody could confirm from a source are listed in
  `tool/cards/UNVERIFIED.md`, to be checked first.
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
- **Depth under every strand.** Every strand now holds at least ten live
  cards, so a reader who turns everything off but *Space · Rockets* is dealt
  ten of their own before the dealer reaches for whatever is nearest. Ten
  is a floor, not a library: a strand that narrow still runs dry in a
  couple of weeks, and the generator writes towards the thinnest strands
  first.

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

The journey reports **the moves you keep missing** — per principle, across
every context of it you have met, only the ones missed at least once —
because naming the move and showing your own record on it is the part that
carried to a real decision.

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
cards at all carry somebody up it. The journey shows the rung, one bar
held to whichever requirement is furthest behind, and the single next
step — telling somebody four things at once is telling them nothing.
The profile keeps only how well you know yourself, and a button into the
journey with the Astute+ lock on it for the free plan: the level, the moves
you keep missing, whether the gap is closing and the week in questions are
all the journey's.

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
with the first question of the morning it lands on, which on either plan is
the reader's own, dealt the way that morning will deal it for a reader who
has been away. On the days a lapse reaches it says something about the reader
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

## Reading the onboarding

The onboarding asks two things — how much of each subject (a handle per
subject, pushed up or down) and, one layer down, which genres and strands
to leave out — and never what the reader knows. `ReaderProfile`
(`lib/data/reader_profile.dart`) reads those two answers the way a person
would, rather than at face value:

- **The gap, not the number.** A mix left at the top everywhere says
  nothing. One subject held at the top while others came down says *this
  one is mine*: the subject is **claimed**.
- **Pruning is expertise.** Somebody who opens Space, turns off the Moon and
  keeps black holes knows the field well enough to have an opinion inside
  it. A subject pruned from inside is claimed too, and the strands left on
  in a pruned genre are the most precise thing the reader has said.
- **How many stayed.** Four subjects or fewer is a specialist, who wants
  depth, and every one of them counts as chosen; twelve or more is a
  generalist, who wants range.
- **Whether anything moved.** A reader who walked straight through told the
  app nothing, and it does not pretend they did.

Three things follow, on both plans:

1. **Everybody starts a notch above.** Nobody starts as a beginner: every
   subject in the mix starts at *some*, and a claimed one at *solid*. The
   dealer pitches each level above itself (`_fit`): at *some* a hard
   question is as welcome as a medium one; at *solid* hard comes well
   before medium; only a subject measured *curious* is mostly told and
   asked at medium. The first card an app puts in front of somebody decides
   whether it is taken seriously — a stretch reads as respect, an easy
   quiz as a toy. The measured level (`measuredLevels`) replaces the start
   as soon as a subject has four judgements.
2. **Hand-picked strands lean the draw** — the strands kept in a pruned
   genre by as much as about four likes, the genres kept whole in a pruned
   subject a little — from the first card, not the tenth.
3. **The first week opens on what they came for.** The first three days
   sharpen the mix towards its top (the weights cubed, squared, then to the
   power 1.5); from the fourth day the mix is exactly what was set, and the
   range they asked for arrives. A reader who said nothing opens instead on
   the subjects that hook most people — the mind, space, the body, the
   strange, the past — then gets the whole spread. That list is a
   judgement; replace it with what `mix set` shows readers push up.

The cards a free day deals at random follow the mix too: from the subjects
kept on, as much of each as the mix as it was set asks for, so somebody who
dragged Sport to nothing is not handed a Sport card at random, and somebody
who turned it down meets it less.

`onboarding completed` carries the reading's shape — how many subjects were
claimed and started solid, how many strands were picked by hand — never
which.

## The server

The phone dealt its own day from what the reader *said* — the mix, what
was pruned, what they liked — and read Explore off the bank it carried. It
never used what the reader *did*: how long a card held them, what they
threw on in a second, what a shelf showed them that they never opened. The
apps that feel like they know you are built on exactly that record, kept
where the thing that decides can read it. So:

**The trace** (`lib/sync/trace.dart`). Every gesture the app already
measures passes through `Analytics.capture` with its facts; the trace keeps
the ones that matter — card shown, opened, turned (and how long the front
held them first), a hint asked for, answered with its confidence, its time
and *which* option or number (the shape of the wrong answers tells a trap
from a slip), liked, saved, said, shared, thrown down, the shelves looked
at and how far down, the day started and finished, how long the app was
open — compacts them, and writes them in
batches to `readers/{uid}/activity/{UTC day}`, with the reader's presence
(their clock, whether they hold Astute+) at `presence/{uid}`. It is
batched (25 events or 20 seconds, and when the app leaves the screen), it
waits offline, and it carries no prose: never a reason typed on a card, never
a search. It is the reader's: nobody else may read it, it is cleared after
three weeks, and it goes with the account.

**The profile and the day** (`functions/`, Cloud Functions in
europe-west1). The server reads the backup, the trace and the presence into
the same three things the phone's own reading produced, only sharper: a
level per subject, measured where there is something to measure; a taste
over every tag, moved by likes and throws and — new — by dwell (a card that
held the reader twice their median is a card that took; one thrown on in a
third of it did not) and by cards shown and never opened; and the mix as
leaned. Two things keep that taste honest. A strand looked at within the
week is dealt at half its weight, so a liking is met again later rather
than tomorrow; and on about every other day (a coin seeded by reader and
date, the same on every server) one of the day's reads is an *explorer*: a
card from a strand the reader has never met, chosen on level alone with
the taste set aside, and named in the day (`explorer`), so the next
morning's trace says whether it took. A taste that only confirms itself
narrows to nothing; the server can only learn from what it showed. Every
number in this is one line with its reason beside it — the dwell signals
are trusted only from five timed cards, the taste never moves past 0.6 on
one tag, the trace of the last three weeks with the second week at half —
and `functions/README.md` lists them. From that it deals the day by the
phone's own rules — the reader's own first, then on the free plan the rest
at random from the mix as it was set, seeded by reader and date so every
server agrees with itself — and writes it whole to `readers/{uid}/days/{date}`. A phone asks for
tomorrow the evening it finishes today, and the nightly pass deals every
active reader's local today and tomorrow ahead of them; the morning reads
one document, from the phone's own cache in milliseconds. `dealt_by` on
`day started` says who dealt it.

**Explore** is assembled once an hour for everybody (`explore/latest`:
today's shelf, a question from every subject, the top of the week and the
month over closed days, loved since the start, per subject) and once a day
for each reader (`readers/{uid}/explore/current`: the subject that is theirs,
and *For you* — what the profile puts first, one card per strand, at most
two per subject). The search runs on the server over the newest bank; the
phone answers from its own first and swaps in the server's.

**The scorecard** (`functions/src/scorecard.ts`). Once a day the server
adds a closed day of everybody's trace to each card's totals — answers right
and wrong and how surely, the options picked, the time on it, kept and
thrown — reads the reports readers made (`readers/{uid}/reports/{card}`),
and writes the flags and the quarantine to `quality/latest`: a card three
readers say is untrue is dealt, searched and listed by nobody until a
person or the monthly re-check has checked it. The numbers go to the tools
through `cardStats`, per card and nothing about who; readers' notes stay in
Firestore. `functions/README.md` has every threshold.

**The hashes are the phone's, bit for bit.** The crowd under the top list
and the order the shelves turn in are computed on both sides from the
same functions (`functions/src/rng.ts` against `lib/sync/tally.dart` and
`lib/data/pills_repository.dart`), and a test holds the server to numbers
the phone printed.

**What is not built yet** is in `functions/README.md`: learning from
everyone ("readers who kept this also kept that"), which the trace and the
totals already hold everything for, and a store webhook so the server is
sure of Astute+ rather than told.

**To turn it on:** with the Firebase project on the Blaze plan, run the
*Cloud deploy* workflow from the Actions tab (it needs one repository
secret, `FIREBASE_SERVICE_ACCOUNT`, the JSON key of a service account on
the project — `functions/README.md` says which), or `firebase deploy
--only functions,firestore:rules,firestore:indexes` from a machine that is
logged in. The privacy policy is already updated for it. Until then every phone deals for itself, as it did,
and writes its trace for the day the server reads it.

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
reasoning is under *The day, and whose it is*.

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
