# Bets: estimate it before you open it

Round 139 of the canvas (`prototypes.html`, already unpacked in
`prototypes-unpacked.html`, anchors `#139a`–`#139e`) is one idea in five
designs: say what the number is **before** the card tells you, and see how
far off you were. Every piece of it is here as a block of the `bets` family
(`lib/explore/blocks/bets/`, listed in `lib/explore/blocks/bets_blocks.dart`),
which the server places on Explore as a section of `remote/explore.json`
(docs/REMOTE.md, `explore`).

A bet is not a game beside the cards: it **is** the card's answer, given on
the shelf. So it can only be laid on a card whose answer is a number, it is
judged by the card's own test and nothing else, and it is recorded the way
the card records an answer, with how sure the reader was where the card asks
it. The cards come from the bank, never from the canvas, whose questions and
figures are there for the prototype.

- [The pieces](#the-pieces)
- [How a bet is judged and recorded](#how-a-bet-is-judged-and-recorded)
- [The day's hundred points](#the-days-hundred-points)
- [Bet a friend](#bet-a-friend)
- [The crowd, left out](#the-crowd-left-out)
- [The blocks: fields and examples](#the-blocks-fields-and-examples)
- [What a block asks of Explore](#what-a-block-asks-of-explore)
- [Look and feel](#look-and-feel)
- [Checks and tests](#checks-and-tests)

## The pieces

Every piece the canvas draws, where it is, what it needs, and the block that
draws it. The canvas's own caption over each design (“Bet a range (live ·
drag, pick a width, bet)”) is a note for the reader of the canvas, not part
of the app.

| Anchor | Piece | What it needs | Block |
|---|---|---|---|
| `#139a` | Shelf head: “Bet a range”, “The narrower you go, the more it pays, if you're right” | the section's `title`/`subtitle`, or the block's own words | `bets-range` |
| `#139a` | A share to bet on: subject, question, the guess in large figures, the range it covers (“40–60%”) | a card whose answer is a share from 0 to 100%, typed or estimated | `bets-range` |
| `#139a` | The track: drag or tap the guess, the band of the range either side | a track that snaps to whole points | `bets-range` |
| `#139a` | Three widths, “±5 · 30 pts”, “±10 · 20 pts”, “±20 · 10 pts” | `widths`, or the canvas's | `bets-range` |
| `#139a` | “Bet”, then “In range: +30 points. It is 25%.” or “Missed: it is 0.2%.”, the answer marked on the track, the first lines of the card's why | the card's answer and why | `bets-range` |
| `#139a` | The bet slip: “+0 today”, “No bets yet…”, a row a bet (name, range, points), “Go narrow when you're sure: it pays three times as much”, “Narrow bets right: 1 of 1.” | the day's bets on the phone | `bets-range` (`slip`), or on its own `bets-slip` |
| `#139b` | Shelf head: “Place your bet”, “100 points a day. Win and you double your stake”, the points left in a pill | the day's points on the phone | `bets-stake` (`wallet`) |
| `#139b` | Three answers to stake on, “STAKE 10 20 30”, “Pick one first”, “Bet 20” | a pick whose options are all amounts (“About 28”, “40 cm”, “1 in 1,000”) | `bets-stake` |
| `#139b` | “You win 20.” or “You lose 10.”, the right answer filled, a wrong pick ringed, the why | the card's answer and why; how sure, asked as the card asks it | `bets-stake` |
| `#139b` | “Bet a friend”: the card as a message bubble with its options, a line under it, “Send to a friend”, “Copy link” | the app's share sheet; nothing on a server | `bets-friend` |
| `#139c` | Shelf head: “Your number”, “Set it, lock it, see how far off you were” | | `bets-number` |
| `#139c` | A number in large figures with its unit, steppers −10 −1 +1 +10 (or −50 −10 +10 +50, −5 −1 +1 +5), “Lock” | a typed number the steppers reach within the card's tolerance | `bets-number` |
| `#139c` | After the lock: a scale from nought with ○ you and ▮ answer, “Off by 23 studies.”, the why | | `bets-number` |
| `#139c` | “Which is bigger?”: two figures hidden as “?”, what each is, “TAP IF BIGGER”, an “or” between them; after the tap the figures, “BIGGER · YOU GOT IT”; the foot “Each figure comes from a card on these shelves.” | two cards whose answers are shares, from two subjects, far enough apart | `bets-bigger` |
| `#139d` | Shelf head: “Closer, closer”, “Three steps of more or less to close in on the number” | | `bets-closer` |
| `#139d` | A bar from 0% to 100%, “More or less than 50%?”, “STEP 1 OF 3”, Less and More; the bar halves at every step; “It is 51%. You got 2 of 3.” and the why | a share | `bets-closer` |
| `#139d` | “Orders of magnitude”, “Is it 1 in 100, or 1 in a million?”: a staircase of six sizes, “1 IN” over them, “Off by 1 order of magnitude.” | an estimate judged on its order of magnitude, or a pick of odds | `bets-magnitude` |
| `#139e` | Shelf head: “Most people get these wrong”, “Lock in your guess to see everyone else's” | the crowd's guesses, which the app does not have: the block's head says what it does instead, “The bet of the day”, “Lock in your guess, then see how far off you were” | `bets-day` |
| `#139e` | The tag “BET OF THE DAY · THE SAME FOR EVERYONE”, a guess on a filled track, “Lock in” | a share; one card the same for everyone given the section that day | `bets-day` (`tag`, `same`) |
| `#139e` | After the lock: “It is 9%. You were 11 percentage points off.”, the why | | `bets-day` |
| `#139e` | The crowd: where everyone else guessed, “The most common guess was 90–100%”, “You were closer than 93% of players” | real figures from every reader | left out: [why](#the-crowd-left-out) |

Two pieces are drawn a little differently from the canvas, on purpose:

- **Orders of magnitude for odds.** The canvas offers six sizes, 1 in 10 to
  1 in a million, for a card with three options of odds. A bet is the card's
  answer, and “1 in 10,000” is not one of that card's answers, so a pick of
  odds is played on its own three, smallest first. An estimate, judged within
  a factor, has the canvas's six powers of ten, the right one placed by the
  card so it is not always the same stair.
- **Copy link.** A link to a card opens the card, answer and all, and there
  is no server to carry a bet between two phones. The second button copies
  the question and its options on their own, with a link to the app, so a
  friend can be asked without being told. The line under the bubble says so.

## How a bet is judged and recorded

A bet is a response in the form the card keeps one, judged by
`Challenge.accepts` of the card, recorded through the host the way the
Explore screen records an answer given on a shelf.

| Block | The card | The response | Judged | Recorded |
|---|---|---|---|---|
| `bets-range` | number or estimate, a share | the guess at the middle of the range, in plain form (`25`, `0.5`) | by the card: within its tolerance, or its factor. The range's points are the range's own: paid if the answer falls inside it | `commit`, without how sure: the width chosen is how sure |
| `bets-stake` | pick of amounts or odds | the option's index (`2`) | by the card: the option it names | `commitSure` with how sure (50–90, the card's own step); `commit` where the section says `"sure": false` |
| `bets-number` | number | the number set, in plain form | by the card: within its tolerance | `commitSure` / `commit` as above |
| `bets-magnitude` | estimate; pick of odds | the power of ten picked, in plain form (`1000`); for odds the option's index | by the card: within its factor; the option it names | `commitSure` / `commit` as above |
| `bets-day` | number or estimate, a share | the guess, in plain form | by the card | `commitSure` / `commit` as above |
| `bets-closer` | any share | none: a share closed in on by halves is a game played toward the answer, not an answer given | each step: more or less than the middle | nothing is answered; the card is counted read (`revealed`), its answer having been shown |
| `bets-bigger` | two shares | none: which of two figures is bigger is neither card's answer | the two figures compared | nothing is answered; both cards are counted read |

The plain form is `plainResponse` (`answers.dart`): no grouping, a point for
the decimal, no trailing noughts, the form `TypeNumber.read` puts a typed
answer into. So a bet and the same number typed on the card can never be
judged differently: `25.0` is kept as `25`, a third as `0.333333`.

How each block reads a card's answer as a number (`BetAnswer.of`):

- a **number** card is its value and unit; a share when the unit is `%`,
  `percent` or `per cent` and the value is between 0 and 100;
- an **estimate** is its value (above nought) and unit, a share likewise;
- a **pick** of two or three options is a number only when every option is
  one amount — a qualifier (“About”, “Nearly”, “Just over” …), a currency
  sign, one number with or without thousands commas, an optional `%`,
  `per cent`, `thousand` … `quadrillion`, `bn` or `k`, and a few words of
  unit (“About £45,000”, “40 cm”, “Nearly 10%”) — or every option is odds,
  “1 in 1,000”; no two options the same. A range (“10–20%”), words, or one
  option that is not an amount, and the card is not one to bet on.

What each block plays: the range and the bet of the day a share the card
has typed or estimated; the stake any pick of amounts; the steppers a typed
number that is not a share and that steps of a tenth or a twentieth of its
size reach exactly within its tolerance (457 to the unit is left to the
card); the magnitudes an estimate a power of ten is close enough to for the
card to count right, or a pick of odds; the bigger of two and closer any
share; the friend and the slip any card with a number for an answer. Across
the bank today that is 54 cards for the range and the bet of the day, 133
for stakes, 193 for steppers, 108 for the bigger of two and closer, 39 for
magnitudes, 438 for the friend and the slip.

The first answer stands. A card already answered, here or anywhere, shows
“Answered already” and opens on a tap; a bet laid is never laid again on the
same card that day (`BetsDay.place`), and the app's state keeps the first
answer unless the card is due for review, as it does for every answer.

Every bet is also noted through `host.note`, so a shelf's numbers can be
read on their own:

| Event | When | Facts |
|---|---|---|
| `bet laid` | a bet of any block | `kind`, `pill_id`, `other_id` (bigger), `right`, `points`, `wallet`, `confidence` (where asked), and the block's own numbers: the range's `w`, `half`, `pays`, `lo`, `hi`, `hit`; the stake; the number's `places`, `off`; the magnitude's `at`, `value`, `off`; the day's `off` and, on its own card, `of_the_day`; the closer's `right`, `steps`; the bigger's `a`, `b`, `gap` |
| `bet revealed` | a card's answer shown without being given (closer, bigger) | `pill_id` |
| `bet sent` | Send to a friend | `pill_id` |
| `bet copied` | Copy the question | `pill_id` |

## The day's hundred points

The points live on the phone, in `SharedPreferences`, under keys that all
start `knowit.explore.bets.`:

| Key | Holds |
|---|---|
| `knowit.explore.bets.day` | the day they belong to, `yyyy-mm-dd` on the phone's own calendar |
| `knowit.explore.bets.points` | the points left |
| `knowit.explore.bets.slip` | the day's bets, as JSON |
| `knowit.explore.bets.play` | bets half laid: a thumb where it was let go, a width, a stake, the steps taken |
| `knowit.explore.bets.deals` | the cards each shelf of bets was dealt |

A day starts with 100. A stake won adds the stake, a stake lost takes it, a
range in range adds what it pays; a stake is offered only up to the points
left. The first time anything is asked on a new day — after midnight on the
phone's calendar, whatever the time zone — the day starts clean: 100 points,
nothing bet, the shelves dealt afresh. One wallet for every shelf of bets.
What is worth keeping for good is not kept here: an answer is the app's,
recorded like any other.

The shelves are dealt once a day and kept: a shelf does not change under the
reader as cards are read elsewhere. A card is dealt to one shelf of bets
only; a shelf deals cards neither read nor answered, each subject once
before any twice, in an order drawn from the day, the section and the block.
The bet of the day's own card is the exception: drawn without looking at the
reader's history, so it is the same for everyone given the same section that
day (with Explore not narrowed to a subject).

## Bet a friend

`bets-friend` sends the card through the app's own share sheet
(`lib/widgets/share_sheet.dart`), the same one every card has, with no new
backend. The card goes as it always does, with its answer, so the panel says
so and asks the reader to get their friend's guess first; “Copy the question”
copies the question and its options alone, with “What do you say?” and a
link to the app. The card offered is the latest one staked on today, or the
section's `card`, or one dealt for the day.

## The crowd, left out

`#139e` shows where everyone else guessed. The app has no such figures:
`lib/sync/tally.dart` counts, per card, how many readers hold it, and nothing
of what anyone answered. A crowd drawn from anything else would be made up,
so it is left out, and the bet of the day shows how far off the reader was
instead. If the tally comes to hold guesses, the crowd is a row under the
verdict of `DayTile`.

## The blocks: fields and examples

Every section has an `id` and a `block`; `{"id": "x", "block": "bets-range"}`
alone draws the canvas's design. Besides its own fields below, a section of
bets may give:

| Field | |
|---|---|
| `title`, `subtitle` | the shelf's name and the line under it, as text or `{"en": …, "it": …}`; the block's own words otherwise |
| `source` | where the cards come from; `{"ids": [...]}` names them, and each must be one the block bets on |
| `size` | `s`, `m` (the default) or `l` |
| `style` | `{"tone": "subject"}` (tiles in their card's colour, the default) or `{"tone": "page"}` (on the page, as the canvas draws its panels) |
| `limit` | how many: cards, pairs or rows, as each block says |
| `audience` | who and when (docs/REMOTE.md) |

Sizes: `s` is a row of narrow tiles (264 wide) to swipe, `m` a row of the
app's tiles (300), `l` the tiles one under another, the width of the page.

### `bets-range` — bet a range (139a)

A row of shares, a range on each, the day's slip under it.

| Field | Default | |
|---|---|---|
| `limit` | 4 | cards, 1–12 |
| `widths` | `[[5, 30], [10, 20], [20, 10]]` | two to four `[half, pays]`: how far the range reaches either side of the guess, and what it pays; the halves rising from 1 to 50, the pays falling from 1000 to 1 |
| `slip` | `true` | the day's slip of this shelf under it |
| `wallet` | `false` | the points left beside the shelf's name |

```json
{"id": "bets-range", "block": "bets-range", "size": "m", "limit": 4,
 "widths": [[5, 30], [10, 20], [20, 10]], "slip": true,
 "source": {"ids": ["art-detection-9", "economics-taxes-1", "maths-percentages-4", "medicine-placebo-9"]}}
```

### `bets-slip` — the bet slip (139a)

The day's bets from every shelf, anywhere on Explore. Left out while there
are no bets and nothing to bet on.

| Field | Default | |
|---|---|---|
| `size` | `m` | `s` the points and the latest bet, `m` the latest few, `l` all of them |
| `limit` | 5 | rows at size `m`, 1–50 |
| `kinds` | all | the kinds of bet it lists: `range`, `stake`, `number`, `closer`, `magnitude`, `day`, `bigger` |
| `title` | “Your bet slip” | it has no line under the title and no tone |

```json
{"id": "slip", "block": "bets-slip", "size": "m", "limit": 5, "kinds": ["range", "stake"],
 "title": {"en": "Your bets today", "it": "Le tue scommesse di oggi"}}
```

### `bets-stake` — place your bet (139b)

A row of picks to stake on, the points left beside the name.

| Field | Default | |
|---|---|---|
| `limit` | 4 | cards, 1–12 |
| `stakes` | `[10, 20, 30]` | one to four, rising, 1–100 |
| `wallet` | `true` | the points left beside the shelf's name |
| `sure` | `true` | ask how sure before the answer shows, as the card does |

```json
{"id": "stakes", "block": "bets-stake", "stakes": [10, 20, 30], "wallet": true, "sure": true,
 "source": {"ids": ["art-motives-2", "food-water-use-2", "thinking-h13"]}}
```

### `bets-friend` — bet a friend (139b)

One card as a message about to go.

| Field | Default | |
|---|---|---|
| `size` | `m` | `s` the note and the buttons, `m` the card as a bubble, `l` the bubble the width of the panel |
| `card` | the latest staked today, or one dealt | a card with a number for an answer |

It shows one card, so it takes no `limit`, and has one look, so no `style`.

```json
{"id": "friend", "block": "bets-friend", "size": "m", "card": "art-motives-2"}
```

### `bets-number` — your number (139c)

Steppers to set a number, a lock, a scale of how far off.

| Field | Default | |
|---|---|---|
| `limit` | 3 | cards, 1–12 |
| `sure` | `true` | ask how sure after the lock |

```json
{"id": "number", "block": "bets-number", "size": "s", "limit": 3, "style": {"tone": "page"},
 "source": {"ids": ["art-art-and-money-3", "language-jargon-1", "medicine-resistance-7"]}}
```

### `bets-bigger` — which is bigger? (139c)

Pairs of shares, one under another; the bigger is tapped, both figures show.

| Field | Default | |
|---|---|---|
| `limit` | 3 | pairs, 1–6 |
| `pairs` | dealt | `[[id, id], …]`: two shares whose figures differ |
| `gap` | 8 | when dealt, how many points apart the two figures are at the least, 1–50 |
| `labels` | the card's question | `{id: text}` or `{id: {"en": …}}`: what a figure is, short |
| `style` | `{"tone": "page"}` | on the page, as the canvas draws it |

```json
{"id": "bigger", "block": "bets-bigger", "size": "m", "limit": 2,
 "pairs": [["art-detection-9", "maths-percentages-4"], ["economics-taxes-1", "science-risk-in-numbers-3"]],
 "labels": {"art-detection-9": {"en": "Fakes among the paintings a test flags", "it": "Falsi tra i quadri segnalati da un test"},
            "maths-percentages-4": {"en": "Total discount: 40% off, then 25% more", "it": "Sconto totale: 40%, poi un altro 25%"}}}
```

### `bets-closer` — closer, closer (139d)

More or less than the middle, the bar halving at every step.

| Field | Default | |
|---|---|---|
| `limit` | 3 | cards, 1–12 |
| `steps` | 3 | 2–5 |

```json
{"id": "closer", "block": "bets-closer", "steps": 3, "limit": 3,
 "source": {"ids": ["medicine-placebo-9", "science-insulation-9", "pop_culture-then-and-now-3"]}}
```

### `bets-magnitude` — orders of magnitude (139d)

A staircase of sizes: six powers of ten, or a pick's own odds.

| Field | Default | |
|---|---|---|
| `limit` | 3 | cards, 1–12 |
| `sure` | `true` | ask how sure after the pick |

```json
{"id": "magnitude", "block": "bets-magnitude", "limit": 3,
 "source": {"ids": ["art-marble-3", "maths-fermi-8", "thinking-h13"]}}
```

### `bets-day` — the bet of the day (139e)

The day's bet, the same for everyone given the section, then more.

| Field | Default | |
|---|---|---|
| `size` | `m` | `s` a row of tiles, `m` one under another, `l` the day's bet alone, its question larger |
| `limit` | 3 | cards, the day's own among them, 1–12; not at size `l` |
| `tag` | `true` | the tag over the day's bet |
| `same` | `false` | the tag says the bet is the same for everyone |
| `sure` | `true` | ask how sure after the lock |

```json
{"id": "day", "block": "bets-day", "size": "m", "limit": 3, "tag": true, "same": true,
 "source": {"ids": ["psychology-streaks-6", "art-detection-9", "medicine-placebo-9"]}}
```

A whole round, as one document:

```json
{"sections": [
  {"id": "bet-of-the-day", "block": "bets-day", "size": "l", "same": true},
  {"id": "ranges", "block": "bets-range", "slip": false},
  {"id": "stakes", "block": "bets-stake"},
  {"id": "friend", "block": "bets-friend", "size": "s"},
  {"id": "numbers", "block": "bets-number", "size": "s"},
  {"id": "bigger", "block": "bets-bigger"},
  {"id": "closer", "block": "bets-closer", "steps": 3},
  {"id": "sizes", "block": "bets-magnitude"},
  {"id": "slip", "block": "bets-slip", "size": "l",
   "audience": {"weekdays": [6, 7]}}
]}
```

## What a block asks of Explore

Through `ExploreHost` only: `cardsFor` (with a pool of up to 6000, so a
shelf can deal the day's from every card the source allows), `open`,
`commit`, `seen`, `note`, `isRead`, `app.answerFor`, `watch`. A bet asks two
things more, in `BetHost` (`lib/explore/blocks/bets/bet_host.dart`):

- `commitSure(pill, response, confidence)`: record an answer with how sure,
  as `AppState.recordAnswer(id, response, confidence: …)` does, and count the
  card read, as `commit` does;
- `revealed(section, pill)`: a card's answer was shown without being given,
  so count it read and never deal it again with its answer known.

The Explore screen implements both by declaring `implements BetHost` and
calling what it already calls for `commit`. Until it does, a bet is recorded
through `commit` without how sure, and both are in the `bet laid` and
`bet revealed` notes, so nothing is lost but the card's own count of how
sure against how right.

## Look and feel

The family draws with the app's own parts (`lib/widgets/explore/parts.dart`:
the card head, the flat button, the fills and hairlines) and its own in
`parts.dart`:

- **Shelf head** as every shelf's: the name in Figtree 16/600, the line in
  12 at 42% ink, 20 from the edges; the points left in a pill in the page's
  reverse.
- **Tiles** as the app's cards: radius 22, in the card's subject colour
  (`tone: subject`) or on the page at 6% ink (`tone: page`), the subject
  over the question in Fraunces (16, 18 or 19.5 by size), the game under
  it. Tiles in a row are as tall as the tallest; a question takes its first
  four lines' room so the games line up.
- **Chips** of 42 by default, radius 12, filled when picked, ringed when
  picked wrong, faded when out of play. A row of chips is as wide as one
  another; where a label would break a word or take more than two lines,
  the row becomes rows of fewer, as even as the count allows.
- **The track** snaps to whole points and clicks at every tenth; the thumb
  swells while held and glides to a tap. Steppers repeat while held. Every
  choice is a selection click, a bet laid or a number locked a firmer
  impact.
- **Reduced motion**: every move — the thumb's glide, the bar halving, the
  figures turning over, a chip filling — happens at once, the same
  otherwise.
- **Text size**: up to twice the size, every piece reflows rather than
  clips: chips into rows, the stake's line under its stakes, the steppers
  over the lock, the stairs into two flights, the pairs of figures one over
  the other, the slip's name over its numbers. Checked on 375, 402 and 430
  points wide, dark and light, at 1, 1.3 and 2.
- **Screen readers**: the track is a slider that steps by one; every chip
  says what it is and whether it is picked; a verdict is announced when it
  comes; the points left are said in words.
- Numbers in the reader's language: “21,5 %” in French, “%21,5” in Turkish,
  the short forms (“1K”, “10 Mio.”) the language's own.

## Checks and tests

- `tool/remote/parts/explore_blocks/bets.py` checks every section of bets
  in `remote/explore.json`: sizes, limits, looks, words, every field, and
  that every card a section names is in the bank, live, and one its block
  can bet on. It refuses, one by one, what the app would quietly put right
  or leave out. Its reading of a card is the app's, written again: both are
  held to `test/explore/bets_cases.json`, and a run over the whole bank
  found them agreeing on every card. Tests:
  `python3 tool/remote/test_explore_bets.py`, which also checks every
  example in this page.
- `test/explore/bets_*_test.dart`: the answers, the day's points and its
  reset, every block right and wrong, null with no cards to bet on, every
  size, both themes and large text.
- `tool/bets_shots.dart`: the camera, every block at every size and state
  on three phones, dark and light, and at large text.
