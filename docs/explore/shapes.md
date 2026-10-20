# Shapes: rounds 131 and 132

Round 131 of the canvas gives every kind of card a shape of its own, so a
reader can tell what a shelf holds before reading a word of it: a folded
corner is a myth, a ruler of years is the past, a stamp is a place. Round 132
gives every kind of shelf one signature, a graphic drawn in a darker tone of
the card's own colour so it never fights the text: a quote struck out for a
myth, two circles that overlap for a paradox, a sun going down for something
to try before tonight.

This page takes both rounds apart: every piece of every design, where it is
on the canvas, what it needs, and the block that draws it. Pieces that are in
the app already belong to the `core` family and are not drawn again here.

- Blocks: `lib/explore/blocks/shapes/`, listed in
  `lib/explore/blocks/shapes_blocks.dart`.
- What each block reads, said once: `ShapeVocabulary` in
  `lib/explore/blocks/shapes/vocabulary.dart`, and the same words for the
  checker in `tool/remote/parts/explore_blocks/shapes.json`.
- Checker: `tool/remote/parts/explore_blocks/shapes.py` (`BLOCKS`), tested
  by `tool/remote/test_shapes.py`.
- Tests: `test/explore/shapes_*_test.dart`. Camera: `tool/shapes_shots.dart`.

## Every piece of the canvas

Anchors open the design in `prototypes-unpacked.html`. Every design but 131a
and 131f puts the same eight shelves in a new form: a month of one subject,
Myths busted, the last century, Numbers that surprise, Pick a side, Europe,
Use it today and Paradoxes.

### [131a](prototypes-unpacked.html#131a) · Now, copied from the app

The screen as it shipped, every themed shelf the same 158 × 172 card. All of
it is the app's own: Today's shelf, Top of the week, The ones that ask the
most, and the themed shelves. **Core**; nothing here.

### [131b](prototypes-unpacked.html#131b) · Shaped by kind

| Shelf | Piece | What it needs | Block |
|---|---|---|---|
| A month of Pop culture | Bento: a lead card with the subject's mark, pairs of small ones | one subject's cards | **core** (`MonthShelf`) |
| Myths, busted | A page with its corner folded down | myths | `shape-fold` |
| The last century | Each card under its year on a line | the past; a year or an age for each card | `shape-years` |
| Numbers that surprise | The figure set large | numbers with a figure | **core** (`SignatureRow`'s number card) |
| Pick a side | The card in two halves, a side at the foot of each | debates with two sides | `shape-sides` |
| Europe | A postcard: subject, a stamp with the country, the postmark's waves, the question along the foot | places; a country where one is known | `shape-postcard` |
| Use it today | A band at the foot: a box, TRY TODAY, how long | things to try; minutes | `shape-try` |
| Paradoxes | A twin card tipped behind | paradoxes | `shape-twins` |

### [131c](prototypes-unpacked.html#131c) · Size only

No new details, only size and rhythm.

| Shelf | Piece | What it needs | Block |
|---|---|---|---|
| A month of Pop culture | A grid, two to a row, down the page | one subject's cards | `shape-grid` |
| Myths, busted | A hero card the width of the screen, its question the poster | myths | `shape-hero` |
| The last century | Spines of books on a shelf | the past | `shape-spines` |
| Numbers that surprise | Squares | numbers | `shape-squares` |
| Pick a side | Wide cards that name their subject | debates | `shape-wide` |
| Europe | One big card and two beside it, all on screen at once | places, of different lengths | `shape-bento` |
| Use it today | Rows the width of the page, in the cards' colours | things to try | `shape-rows` |
| Paradoxes | Medium cards, a size up from the app's | paradoxes | `shape-medium` |

### [131d](prototypes-unpacked.html#131d) · Silhouettes

The outline of the card changes per shelf.

| Shelf | Piece | What it needs | Block |
|---|---|---|---|
| A month of Pop culture | Folders with a tab | one subject's cards | `shape-tab` |
| Myths, busted | A page torn out | myths | `shape-torn` |
| The last century | Arches | the past | `shape-arch` |
| Numbers that surprise | Capsules, the figure set large inside | numbers with a figure | `shape-capsule` |
| Pick a side | Cut corner to corner in two tones | debates | `shape-diagonal` |
| Europe | Postage stamps, perforated, the country in the corner | places; a country where one is known | `shape-stamp` (signature `none`) |
| Use it today | A ticket, torn along a line, the stub saying the subject and how long | things to try; minutes | `shape-ticket` |
| Paradoxes | A leaf: two opposite corners drawn long | paradoxes | `shape-leaf` |

### [131e](prototypes-unpacked.html#131e) · Beyond the carousel

Each shelf lays its cards out differently.

| Shelf | Piece | What it needs | Block |
|---|---|---|---|
| A month of Pop culture | Masonry: two columns, tall and short out of step | one subject's cards, of different lengths | `shape-masonry` |
| Myths, busted | A deck turned a card at a time | myths | `shape-deck` |
| The last century | A line of time down the page | the past; a year or an age | `shape-timeline` |
| Numbers that surprise | A list of figures, hairlines between | numbers with a figure | `shape-figures` |
| Pick a side | One debate at a time, Yes and No at its foot | debates with two sides | `shape-pager` |
| Europe | Two rows that scroll together | places | `shape-two-rows` |
| Use it today | A checklist | things to try | **core** (`UseTodayList`); `shape-checklist` draws it too, with the signature `none` and `"rings": "all"` |
| Paradoxes | A hand of cards fanned out | paradoxes | `shape-hand` |

### [131f](prototypes-unpacked.html#131f) · Recommended

The strongest of b to e as one screen, no two neighbours alike. A document of
existing pieces, not a piece of its own: the app's top three shelves (core),
the month's bento (core), then `shape-fold`, `shape-timeline`,
`shape-capsule`, `shape-sides`, `shape-stamp`, `shape-checklist` and
`shape-twins`. It is written out as a document under
[Example documents](#example-documents).

### [132a](prototypes-unpacked.html#132a) · Signatures, every shelf sideways

| Shelf | Piece | What it needs | Block |
|---|---|---|---|
| Today's shelf, Top of the week, The ones that ask the most | As in the app | — | **core** |
| A month of Pop culture | The subject's mark (a star for pop culture) drawn large behind each card | one subject's cards | `shape-mark` |
| Myths, busted | The myth's opening quote struck out | myths | `shape-quote` |
| The last century | A ruler of years, ticked, the years set large | the past; a year or an age | `shape-ruler` |
| Numbers that surprise | The figure itself | numbers with a figure | **core** (`SignatureRow`'s number card) |
| Pick a side | Two halves, "or" between the sides, a lean to drag | debates | **core** (`SignatureRow`'s side card) |
| Europe | A stamp franked, its country set large | places; a country where one is known | `shape-stamp` (signature `postmark`, its own) |
| Use it today | A sun going down in the corner | things to try | **core** (`SignatureRow`'s try card) |
| Paradoxes | Two circles that overlap | paradoxes | `shape-circles` |

### [132b](prototypes-unpacked.html#132b) · Signatures in layouts

The same signatures, and each shelf also moves differently.

| Shelf | Piece | What it needs | Block |
|---|---|---|---|
| A month of Pop culture | Masonry, the mark behind the tall cards | one subject's cards | `shape-masonry` with `"signature": "mark"` |
| Myths, busted | A deck, the quote struck out | myths | `shape-deck` with `"signature": "quote"` |
| The last century | A line of time down the page, the years set large | the past | `shape-timeline` with `"size": "l"` |
| Numbers that surprise | A grid of figures, each in its tile's corner | numbers with a figure | `shape-grid` with `"signature": "figure"` |
| Pick a side | One debate at a time, in two halves, "or" between | debates with two sides | `shape-pager` with `"signature": "halves"` |
| Europe | Stamps stuck on by hand, each at its own angle | places | `shape-stamp` with `"style": {"tilt": true}` |
| Use it today | A checklist, a sun going down behind each, how long beside the subject | things to try; minutes | `shape-checklist` (signature `sunset`, its own) |
| Paradoxes | A hand, two circles at the foot of each card | paradoxes | `shape-hand` with `"signature": "circles"` |

## What every shape reads

Every block reads what every section says (`id`, `block`, `source`,
`audience`, `title`, `subtitle`), and these:

| Field | What it says | When it is left out |
|---|---|---|
| `kind` | The kind of card the shelf keeps to: a themed shelf's name (`myths`, `past`, `numbers`, `debates`, `place`, `practical`, `paradoxes`, `stories`, `seen`, `workItOut`, `origins`, `sharpest`, `trueOrFalse`, `reasoning`, `ideas`, `curious`, `moving`, `howItWorks`, `puzzles`), `month` for one subject's cards, or `any` for whatever the source gives | The block's own (the table below) |
| `variant` | For `past`: 0 the ancient world, 1 the 1600s to the 1800s, 2 the last century. For `place`: 0 Asia and the Middle East, 1 the Americas, 2 Europe | The day's, as the themed shelves turn |
| `subject` | For `month`: the subject (`pop_culture`, `space`, …) | The month's |
| `size` | `s`, `m` or `l`; `m` is the canvas's own | `m` |
| `signature` | One the block carries (the table below) | The block's first |
| `limit` | How many cards it shows, up to its most | The block's own |
| `min` | The fewest that still make its shape; with fewer the section is left out | The block's own |
| `style` | The keys the block reads (the table below) | The block's own look |

A shelf of a kind takes from what it is given only the cards of that kind, so
the promise of the shapes holds: a folded corner never holds anything but a
myth. To have enough to choose from, a block asks the host for six times what
it shows (at least 48) and keeps its own; `any` asks for exactly what it
shows.
The shelf is named for its kind, in the reader's language, unless the section
gives a `title` and `subtitle` (a string, or one per language with English
among them). A shelf of `any` kind has no name of its own, so the checker
asks for a title.

A section the block cannot read in part is drawn as far as it can be: a size
it does not have is `m`, a signature it does not carry is its own, a kind it
does not know is its own. The checker refuses each such field, so the server
never sends one; an older build that does not know a block skips it.

## The blocks

| Block | Canvas | Kind | Signatures | Limit (most) | Min | Own fields | Style |
|---|---|---|---|---|---|---|---|
| `shape-fold` | [131b](prototypes-unpacked.html#131b), [131f](prototypes-unpacked.html#131f) | `myths` | `none` | 8 (12) | 3 | — | — |
| `shape-torn` | [131d](prototypes-unpacked.html#131d) | `myths` | `none` | 8 (12) | 3 | — | — |
| `shape-tab` | [131d](prototypes-unpacked.html#131d) | `month` | `none` | 8 (12) | 3 | — | — |
| `shape-arch` | [131d](prototypes-unpacked.html#131d) | `past` | `none` | 8 (12) | 3 | — | — |
| `shape-capsule` | [131d](prototypes-unpacked.html#131d), [131f](prototypes-unpacked.html#131f) | `numbers` | `none` | 8 (12) | 3 | — | — |
| `shape-diagonal` | [131d](prototypes-unpacked.html#131d) | `debates` | `diagonal` | 8 (12) | 3 | — | — |
| `shape-leaf` | [131d](prototypes-unpacked.html#131d) | `paradoxes` | `none` | 8 (12) | 3 | — | — |
| `shape-hero` | [131c](prototypes-unpacked.html#131c) | `myths` | `none` | 8 (12) | 3 | — | — |
| `shape-spines` | [131c](prototypes-unpacked.html#131c) | `past` | `none` | 8 (12) | 3 | — | — |
| `shape-squares` | [131c](prototypes-unpacked.html#131c) | `numbers` | `none` | 8 (12) | 3 | — | — |
| `shape-wide` | [131c](prototypes-unpacked.html#131c) | `debates` | `none` | 8 (12) | 3 | — | — |
| `shape-medium` | [131c](prototypes-unpacked.html#131c) | `paradoxes` | `none` | 8 (12) | 3 | — | — |
| `shape-mark` | [132a](prototypes-unpacked.html#132a) | `month` | `mark` | 8 (12) | 3 | — | — |
| `shape-quote` | [132a](prototypes-unpacked.html#132a) | `myths` | `quote` | 8 (12) | 3 | — | — |
| `shape-circles` | [132a](prototypes-unpacked.html#132a) | `paradoxes` | `circles` | 8 (12) | 3 | — | — |
| `shape-stamp` | [131d](prototypes-unpacked.html#131d), [131f](prototypes-unpacked.html#131f), [132a](prototypes-unpacked.html#132a), [132b](prototypes-unpacked.html#132b) | `place` | `postmark`, `none` | 8 (12) | 3 | `codes` | `tilt`: true/false |
| `shape-postcard` | [131b](prototypes-unpacked.html#131b) | `place` | `none` | 8 (12) | 3 | `codes` | — |
| `shape-ticket` | [131d](prototypes-unpacked.html#131d) | `practical` | `none` | 8 (12) | 3 | — | — |
| `shape-try` | [131b](prototypes-unpacked.html#131b) | `practical` | `none` | 8 (12) | 3 | — | — |
| `shape-twins` | [131b](prototypes-unpacked.html#131b), [131f](prototypes-unpacked.html#131f) | `paradoxes` | `none` | 8 (12) | 3 | — | — |
| `shape-sides` | [131b](prototypes-unpacked.html#131b), [131f](prototypes-unpacked.html#131f) | `debates` | `halves` | 8 (12) | 3 | — | — |
| `shape-years` | [131b](prototypes-unpacked.html#131b) | `past` | `none` | 8 (12) | 3 | `order` | — |
| `shape-ruler` | [132a](prototypes-unpacked.html#132a) | `past` | `none` | 8 (12) | 3 | `order` | — |
| `shape-grid` | [131c](prototypes-unpacked.html#131c), [132b](prototypes-unpacked.html#132b) | `month` | `none`, `figure` (keeps to `numbers`) | 4 (8) | 2 | — | — |
| `shape-bento` | [131c](prototypes-unpacked.html#131c) | `place` | `none` | 3 (3) | 3 | — | — |
| `shape-two-rows` | [131e](prototypes-unpacked.html#131e) | `place` | `none` | 8 (12) | 4 | — | — |
| `shape-masonry` | [131e](prototypes-unpacked.html#131e), [132b](prototypes-unpacked.html#132b) | `month` | `none`, `mark` | 4 (8) | 4 | — | — |
| `shape-rows` | [131c](prototypes-unpacked.html#131c) | `practical` | `none` | 3 (8) | 2 | — | — |
| `shape-checklist` | [131e](prototypes-unpacked.html#131e), [131f](prototypes-unpacked.html#131f), [132b](prototypes-unpacked.html#132b) | `practical` | `sunset`, `none` | 8 (12) | 3 | — | `rings`: `read` / `all` / `none`; `shown`: 1–8 |
| `shape-figures` | [131e](prototypes-unpacked.html#131e) | `numbers` | `none` | 4 (8) | 3 | — | — |
| `shape-timeline` | [131e](prototypes-unpacked.html#131e), [131f](prototypes-unpacked.html#131f), [132b](prototypes-unpacked.html#132b) | `past` | `none` | 4 (8) | 3 | `order` | — |
| `shape-deck` | [131e](prototypes-unpacked.html#131e), [132b](prototypes-unpacked.html#132b) | `myths` | `none`, `quote` | 8 (12) | 2 | — | — |
| `shape-pager` | [131e](prototypes-unpacked.html#131e), [132b](prototypes-unpacked.html#132b) | `debates` | `none`, `halves` | 8 (12) | 1 | — | — |
| `shape-hand` | [131e](prototypes-unpacked.html#131e), [132b](prototypes-unpacked.html#132b) | `paradoxes` | `none`, `circles` | 4 (5) | 2 | — | — |

Every block comes in `s`, `m` and `l`. Each one alone, `{"id": "x", "block":
"shape-fold"}`, draws the canvas's shelf.

### Sideways rows of one tile

`shape-fold`, `shape-torn`, `shape-tab`, `shape-arch`, `shape-capsule`,
`shape-diagonal`, `shape-leaf`, `shape-hero`, `shape-spines`,
`shape-squares`, `shape-wide`, `shape-medium`, `shape-mark`, `shape-quote`,
`shape-circles`: a row that scrolls sideways like every shelf of the app,
each tile cut to its outline (the fold's flap, the torn foot, the tab, the
arch, the capsule, the leaf's long corners) and carrying its signature. The
capsule sets a number's figure large when the card has one.

```json
{"id": "myths", "block": "shape-fold"}
{"id": "myths", "block": "shape-torn", "size": "s"}
{"id": "myths", "block": "shape-hero"}
{"id": "myths", "block": "shape-quote", "size": "m"}
{"id": "month", "block": "shape-tab", "subject": "music"}
{"id": "space", "block": "shape-mark", "subject": "space"}
{"id": "past", "block": "shape-arch", "variant": 1}
{"id": "past", "block": "shape-spines", "variant": 0}
{"id": "numbers", "block": "shape-capsule", "size": "l", "limit": 6}
{"id": "numbers", "block": "shape-squares"}
{"id": "debates", "block": "shape-diagonal"}
{"id": "debates", "block": "shape-wide", "size": "s"}
{"id": "paradoxes", "block": "shape-medium"}
{"id": "paradoxes", "block": "shape-circles", "limit": 5}
{"id": "puzzles", "block": "shape-leaf", "kind": "puzzles"}
```

### A place: `shape-stamp`, `shape-postcard`

A stamp prints a country only when one is known: the card's own place, then
the section's word for the card, then the country its question names within
the part of the world it is set in (never an adjective, never a name that
only holds a country's, like Isaiah Berlin or the East India Company, and
none when the question names two parts of the world). Without one the stamp
is a stamp without a country; a card about not being fooled does not print a
guess. The stamp shows the cards whose country is known first.

- `codes`: `{"<card id>": "HU"}`, for the server to name what the bank does
  not; two or three capital letters, the United Kingdom as `UK`.
- `shape-stamp` `"signature": "postmark"` (its own) franks the stamp and sets
  the code large (132a); `"none"` is 131d's plain stamp. `"style": {"tilt":
  true}` lays the stamps at their own angles (132b).

```json
{"id": "europe", "block": "shape-stamp", "variant": 2, "style": {"tilt": true}}
{"id": "postcards", "block": "shape-postcard", "codes": {"sport-formations-3": "HU"}}
```

### Something to try: `shape-ticket`, `shape-try`, `shape-rows`, `shape-checklist`

How long each takes is the card's own estimate (the app's minutes). The try
card's box and the checklist's ring are the card's read mark and nothing
else: rings that ticked a row off as tried were taken off the app's own Use it
today because nobody could tell what they were for.

- `shape-checklist` `"style": {"rings": "read"}` (its own) rings only the
  cards read, ticked; `"all"` draws the canvas's empty ring on every row;
  `"none"` none. `"shown"` is how many rows show before "Show all".

```json
{"id": "today", "block": "shape-try"}
{"id": "today", "block": "shape-rows", "limit": 4}
{"id": "today", "block": "shape-checklist", "style": {"shown": 4}}
{"id": "today", "block": "shape-checklist", "signature": "none", "style": {"rings": "all"}}
{"id": "tickets", "block": "shape-ticket", "size": "s"}
```

### Debates: `shape-sides`, `shape-pager`

A tap on a side takes it, recorded as the card itself records a side
(`commit`, the side's number). Once a side is taken, the foot opens the card
like the rest of it; a side the reader took anywhere shows taken.

```json
{"id": "sides", "block": "shape-sides"}
{"id": "debates", "block": "shape-pager", "signature": "halves", "limit": 5}
```

### The past: `shape-years`, `shape-ruler`, `shape-timeline`

Each card under the year its question names, or the age it is set in, as the
app's own "where it came from" shelf says it. The cards are laid out earliest
first; `"order": "given"` keeps the order the source gives.

```json
{"id": "past", "block": "shape-years", "order": "given"}
{"id": "past", "block": "shape-ruler", "variant": 2}
{"id": "ancient", "block": "shape-timeline", "variant": 0, "size": "l", "limit": 6}
```

### Layouts: `shape-grid`, `shape-bento`, `shape-two-rows`, `shape-masonry`

The bento is dealt three spare cards and puts the two shortest questions in
its small places; the masonry puts the longest in its tall ones. The grid with
`"signature": "figure"` is a grid of figures and keeps to numbers when the
section names no kind.

```json
{"id": "month", "block": "shape-grid", "subject": "pop_culture"}
{"id": "numbers", "block": "shape-grid", "signature": "figure", "limit": 6}
{"id": "europe", "block": "shape-bento", "variant": 2}
{"id": "americas", "block": "shape-two-rows", "variant": 1, "limit": 10}
{"id": "month", "block": "shape-masonry", "signature": "mark"}
```

### Lists and piles: `shape-figures`, `shape-deck`, `shape-hand`

`shape-figures` takes only cards with a figure to set. The deck turns with a
swipe, or with the card's actions for a reader who cannot swipe; the hand
draws a card hidden in the fan up in front at a tap, and opens the one in
front.

```json
{"id": "figures", "block": "shape-figures"}
{"id": "myths", "block": "shape-deck", "signature": "quote"}
{"id": "paradoxes", "block": "shape-hand", "signature": "circles", "limit": 5}
```

### What the shapes note

Besides the cards each shows (`seen`), opens and answers, a shape notes what a
reader did that the app has no other record of (`ExploreHost.note`):
`turned` (deck: `pill`, `at`), `paged` (pager: `pill`, `at`), `raised`
(hand: `pill`, `at`), `expanded` and `collapsed` (checklist: `count`).

## How they are drawn

- **Type and spacing are Explore's own**: shelf titles at 16 in Figtree with
  their line at 12, questions in Fraunces fitted to their box by the app's
  fitting (ScaledText), labels in Figtree's small capitals, the 20-point
  margins, subject colours, the read tick, both papers.
- **No question scrolls in its tile, no label is cut.** A shape measures its
  questions as the fitting sets them and grows, all its tiles alike, when the
  longest it is dealt needs it; a label too long for its line takes a second
  one, or is set a little smaller. The tests hold this for the longest
  questions in the bank, on a 375-wide phone, at every size, at twice the
  text size and in all thirteen languages.
- **Signatures are painted**, never pictures: a darker tone of the card's
  colour (`Tones` in `signatures.dart`), under the words.
- **Cards are the bank's**: a block shows only what `host.cardsFor` gives it,
  never the canvas's text.

## Example documents

131f, the recommended screen, below the app's own top shelves and month:

```json
{"sections": [
  {"id": "myths", "block": "shape-fold"},
  {"id": "past", "block": "shape-timeline", "variant": 2},
  {"id": "numbers", "block": "shape-capsule"},
  {"id": "sides", "block": "shape-sides"},
  {"id": "europe", "block": "shape-stamp", "variant": 2, "signature": "none"},
  {"id": "today", "block": "shape-checklist", "signature": "none", "style": {"rings": "all"}},
  {"id": "paradoxes", "block": "shape-twins"}
]}
```

132a, every shelf sideways with its signature (the figure, the two halves
and the sunset are the core family's, between these):

```json
{"sections": [
  {"id": "month", "block": "shape-mark"},
  {"id": "myths", "block": "shape-quote"},
  {"id": "past", "block": "shape-ruler", "variant": 2},
  {"id": "europe", "block": "shape-stamp", "variant": 2},
  {"id": "paradoxes", "block": "shape-circles"}
]}
```

132b, the signatures in layouts:

```json
{"sections": [
  {"id": "month", "block": "shape-masonry", "signature": "mark"},
  {"id": "myths", "block": "shape-deck", "signature": "quote"},
  {"id": "past", "block": "shape-timeline", "variant": 2, "size": "l"},
  {"id": "numbers", "block": "shape-grid", "signature": "figure"},
  {"id": "debates", "block": "shape-pager", "signature": "halves"},
  {"id": "europe", "block": "shape-stamp", "variant": 2, "style": {"tilt": true}},
  {"id": "today", "block": "shape-checklist"},
  {"id": "paradoxes", "block": "shape-hand", "signature": "circles"}
]}
```

## Decisions

- **Names start with `shape-`.** The catalogue is one map, and a later family
  silently overrides an earlier one's name; `shape-grid` cannot collide with
  a generic grid of the core family.
- **The canvas's numbers, figures, countries and years are not drawn.** They
  were written for the prototype. A figure is the card's own
  (`shelfFigure`), a year is the one its question names or its age, a country
  is printed only when true, and how long something takes is the card's own
  estimate.
- **A line of time reads as years.** Most cards of an age carry only the
  age, so the years row, the ruler and the timeline show first the cards
  whose question names a year, as the canvas's lines do, and fall back to an
  age only when they must.
- **A figure on the grid is a signature, so it is a darker tone.** The canvas
  set 132b's figures in the card's ink; the app's own numbers shelf (132a's
  figure) sets its figure in the card's colour taken well down, as round 132
  asks of every signature, and the grid of figures does the same. The
  capsule (131d) and the list of figures (131e) set theirs as their own
  designs do: in the card's ink, and in the subject's colour.
- **Core pieces are not drawn twice.** The month's bento, the figure, the two
  halves with their lean, the sunset and the 131e checklist are the app's
  shelves today; the server places them through the core family.
- **No new strings.** Every word a shape says is the app's already: the
  themed shelves' names and lines, TRY TODAY, TODAY, the minutes, the read
  mark, Show all, Next and Previous.
