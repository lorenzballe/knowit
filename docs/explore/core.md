# The core blocks

The engine's own family (`lib/explore/blocks/core/`): every shelf Explore had
before it came from the server, each a block of its own name; blocks that show
any cards, from any source, at every size; and blocks that are not cards. Any
of them can be placed, sized, aimed and scheduled from the server, in
`remote/explore.json` (docs/REMOTE.md, `explore`).

Every block reads the fields every section has — `id`, `block`, `title`,
`subtitle`, `source`, `size`, `style`, `limit`, `audience`, `gap` (see
docs/REMOTE.md) — and the fields its entry below names; the checker
(`tool/remote/parts/explore_blocks/core.py`) refuses any other, so a misspelt
field is caught before it reaches a phone. A key that starts with `_` is a note
for whoever reads the document and is passed over everywhere.

A block with nothing to show — no cards from its source, a date gone by, a
reader it is not for — is not drawn at all, title and room above it included.

`remote/examples/explore-gallery.json` shows every block below at every size;
`tool/explore_shots.dart` photographs it (`--plain-name gallery`).

## How a card is drawn

Every tile draws a card as the app does: the subject's colour, its mark (and,
from 150 points wide, its name), the question set as large as its box takes
with the app's own `ScaledText`, and a foot that says how long it takes — once
read, the line to keep, and a tick by the mark. A tap opens the card in the
viewer among the section's cards, and the card counts as read, as from any
shelf. A card with a web face has its question and subject too, and is drawn
the same way.

**A question is never cut.** Each tile has a smallest size it sets a question
at (9.5 points in the smallest boxes, 14 in the largest), and a card whose
question cannot be set whole at that size, in that box, at the reader's own
text size, is not put in it: the block asks its source for six times as
many cards as it has boxes and takes the ones that fit, the smallest boxes
choosing first. A small box gets a short question; a long one waits for a
bigger box.

So a layout whose boxes are too small for most questions would come out
nearly empty, and the checker refuses it: on a 375-point phone, the narrowest
the app is drawn for, every box must be able to hold the shortest quarter of
the bank's questions, reckoned from its area. Two columns hold every question
in every shape; three columns square or portrait; four columns portrait only,
and only just (set in the app's own fonts, the shortest fifth of the bank at
375 points wide, most of it at 430). Three columns of landscape tiles, and four of
square or landscape, are refused; so is a 1×1 item of a four-column mosaic
unless its rows are taller (`ratio`).

## Cards, at every size

### `carousel`

A row of cards that scrolls sideways, at one of five steps. `m` and `l` are the
two tiles Explore always had: the small one of the shelves further down and the
big one of today's shelf.

| `size` | Tile, points | Question |
|---|---|---|
| `xs` | 120 × 140 | 9.5–12.5, from the top |
| `s` | 140 × 158 | 10–13.5, from the top |
| `m` (default) | 158 × 172 | 10.5–15, from the top |
| `l` | 214 × 236, with a foot | 12–19, centred |
| `xl` | 280 × 300, with a foot | 14–26, centred |

Fields: `source` (required), `size`, `limit` (10).

```json
{"id": "space-row", "block": "carousel", "size": "s",
 "title": {"en": "Space this week", "it": "Lo spazio questa settimana"},
 "source": {"query": {"subjects": ["space"], "seed": "week"}}}
```

### `grid`

Cards in rows and columns, ending on whole rows once there is more than one.

Fields: `source` (required), `columns` (2, 3 or 4; 2), `shape` (`square`,
`portrait` — half again as tall as wide, the default — or `landscape`, 0.72 as
tall), `limit` (two rows).

```json
{"id": "numbers-grid", "block": "grid", "columns": 3, "shape": "portrait",
 "title": "Numbers to work out",
 "source": {"query": {"formats": ["number", "estimate"]}}}
```

### `bento`

A mosaic: each item spans 1 to 4 columns and 1 to 3 rows of a grid of 2 to 4
columns, laid in order, each in the first place it fits, so the mosaic has no
hole it could fill. A row is as tall as a column is wide, times `ratio`. The
smallest boxes get the shortest questions; a box no card fits is left out and
the mosaic packs up without it.

Fields: `source` (required), `columns` (2–4; 3), `items` (a list of `"CxR"`,
one to twelve; by default `2x1 1x2 1x1 1x1` at two columns,
`2x2 1x1 1x1 1x1 2x1` at three and `2x2 2x1 2x1 4x1` at four, where a 1×1 is
too small for a question unless `ratio` makes its rows taller), `ratio`
(0.5–2; 1).

```json
{"id": "history-mosaic", "block": "bento", "columns": 4,
 "items": ["2x2", "2x1", "2x1", "4x1", "1x2", "3x2"],
 "source": {"query": {"subjects": ["history"], "unread": true}}}
```

### `hero`

One card across the page, big: the question set up to 38 points.

Fields: `source` (required), `size` (`m` 260, `l` 340 — the default — or `xl`
420 points tall).

```json
{"id": "card-of-the-day", "block": "hero", "size": "xl",
 "title": {"en": "One to read slowly", "it": "Una da leggere con calma"},
 "source": {"ids": ["space-moon-dust-3"]}}
```

### `banner`

A card as a strip across the page: its mark at one end, level with its
question, which is set to the rest.

Fields: `source` (required), `size` (`s` 96, `m` 120 — the default — or `l`
148 points tall), `limit` (1; up to 3 strips, one under the other).

```json
{"id": "one-strip", "block": "banner", "size": "s",
 "source": {"query": {"subjects": ["technology"]}}}
```

### `pair`

Two cards side by side; without two to show, not shown.

Fields: `source` (required), `size` (`s` 160, `m` 200 — the default — or `l`
250 points tall).

```json
{"id": "two-sides", "block": "pair", "size": "l",
 "source": {"query": {"formats": ["debate"]}}}
```

### `list`

Rows: a small tile of the card's colour with its mark, and the whole question
beside it, however many lines it takes, with the subject under it.

Fields: `source` (required), `size` (`s`, `m` — the default — or `l`: tiles of
40, 52 and 64 points beside questions of 13.5, 14.5 and 16), `limit` (5).

```json
{"id": "saved-list", "block": "list", "size": "s", "limit": 3,
 "title": {"en": "You kept these", "it": "Le hai tenute"},
 "source": {"mine": "saved"}}
```

### `stack`

A small deck: the card on top, two more showing beside it, a swipe either way
for the next or the one before, a tap to open the one on top. A reader who
asked for less motion gets the next card at once; a screen reader gets "next"
and "previous" as actions, and "card 2 of 8".

Fields: `source` (required), `size` (`s` 200 × 236, `m` 240 × 284 — the
default — or `l` 276 × 326), `limit` (8).

```json
{"id": "maths-deck", "block": "stack", "size": "m",
 "source": {"query": {"subjects": ["maths"], "seed": "day"}}}
```

### `ticker`

A row that moves on by itself at a walking pace (18 points a second), round and
round. Still for a reader who asked for less motion, still while a finger is on
it and for two seconds after, and still while it is off screen or Explore is
not in front.

Fields: `source` (required), `size` (`xs`, `s` — the default — or `m`),
`limit` (12).

```json
{"id": "procession", "block": "ticker", "size": "xs",
 "source": {"query": {"formats": ["trueOrFalse"]}}}
```

### `single`

One card at the deck's own size, its face as the deck shows it on Today
(`PillCard`): a tap opens it to be read and answered.

Fields: `source` (required).

```json
{"id": "one-card", "block": "single",
 "source": {"ids": ["psychology-streaks-1"]}}
```

### `cover`

The top of the page, and the first thing a reader sees of Explore: the
section's cards in a mosaic, as a magazine lays its cover. Two cards large,
each three fifths of the width, their questions set big; beside each, two
small ones, one above the other; every one in words, in its subject's
colour. The large one stands on the left and then on the right, so the eye
goes down the page in a zigzag. The large tiles take the longest questions
of the first cards dealt, every card is of a subject of its own where the
source gives enough, a small tile takes only a question it holds whole, and
a group that cannot be laid whole is left out. The first time
Explore opens it comes up a tile at a time (still for a reader who asked
for less motion); after that it is simply there.

Fields: `title`, `subtitle` (neither by default: the cards are the cover),
and a `source`.

```json
{"id": "cover", "block": "cover", "gap": 6,
 "source": {"query": {"unread": true, "perSubject": 1, "limit": 40}}}
```

### `feed`

Explore without an end. After the shelves, the whole bank in the day's
order — the same on every phone, turning with the day, never chosen for the
reader — in a mosaic of two columns that goes on for as long as the reader
scrolls: one card across, two side by side, a tall one beside two, two, two
beside a tall one, two, and round again. A card read already is left out,
and one about a place reaches only the readers who live there, as on every
shelf. It is built a band at a time as each band comes near the screen, so
the whole bank costs what the screen shows; a tap opens a card among the
ones laid so far.

It stands last: the checker refuses a section after it, which could never be
reached. A build that meets a feed anywhere else draws its first round of
bands, thirteen cards.

Fields: `title`, `subtitle`. No `source`: it is the whole bank.

```json
{"id": "feed", "block": "feed",
 "title": {"en": "Keep exploring", "it": "Continua a esplorare"},
 "subtitle": {"en": "The same for everyone. Nothing here is picked for you.",
              "it": "Uguale per tutti. Niente qui è scelto per te."}}
```

## Not cards

### `text`

Words of the section's own: a `headline` (against a rule of `subject`'s
colour), a `paragraph` (the default) or a `quote` (with its mark in
`subject`'s colour and who said it under it).

Fields: `text` (required, one string or one per language), `kind`, `by` (a
quote's), `subject` (a subject's key), `style.align` (`start` or `center`).

```json
{"id": "sunday-quote", "block": "text", "kind": "quote", "subject": "science",
 "text": {"en": "The first principle is that you must not fool yourself, and you are the easiest person to fool.",
          "it": "Il primo principio è che non devi ingannare te stesso, e tu sei la persona più facile da ingannare."},
 "by": "Richard Feynman, 1974", "audience": {"weekdays": [7]}}
```

### `countdown`

The days to a date on the phone's own calendar, set large — "287 days to the
total eclipse over southern Spain". On the day it says today (`today`, if the
section gives it); after the day, `after`, or nothing at all. A `source` puts a
row of its cards under it.

Fields: `to` (required, `2027-08-02`), `label` (required: what the days are
to), `today`, `after`, `subject` (its colour), `source`, `size` (`xs`, `s` —
the default — or `m`, for the row), `limit` (8).

```json
{"id": "eclipse", "block": "countdown", "to": "2027-08-02", "subject": "space",
 "label": {"en": "to the total eclipse over southern Spain", "it": "all'eclissi totale sul sud della Spagna"},
 "today": {"en": "The total eclipse over southern Spain is today", "it": "Oggi l'eclissi totale sul sud della Spagna"},
 "source": {"ids": ["science-relativity-2", "space-moon-dust-3"]},
 "audience": {"until": "2027-08-02"}}
```

### `subjects`

A strip of subjects, each narrowing Explore to it as its chip at the top does —
the lit one again clears it — and taking the page back to its top.

Fields: `subjects` (keys of the subjects of the row at the top; all of them by
default), `size` (`s`: chips like the row at the top; `m`, the default, and
`l`: tiles of the subject's colour).

```json
{"id": "pick-one", "block": "subjects", "size": "m",
 "subjects": ["space", "history", "art", "music"],
 "title": {"en": "Where to start", "it": "Da dove cominciare"}}
```

### `promo`

The offer of Astute+, opening the plans through the paywall's own door: on the
free plan only, unless `plan` is `all`. Its words are the paywall's own unless
the section gives its own.

Fields: `kicker`, `headline`, `line`, `button` (words), `from` (the door's name
in the paywall's numbers; `explore`), `plan` (`free`, the default, or `all`).

```json
{"id": "offer", "block": "promo", "from": "explore promo",
 "audience": {"minDays": 3}}
```

### `spacer`

Room, and nothing else. Its own `gap` is 0, so the room is its `height`.

Fields: `height` (0–240; 24).

```json
{"id": "breath", "block": "spacer", "height": 40}
```

### `divider`

A rule across the page between the margins, with a word in the middle when the
section gives one.

Fields: `label` (words).

```json
{"id": "and-then", "block": "divider", "label": {"en": "and further", "it": "e più in là"}}
```

### `web`

A free section: a page made with the card kit (`docs/cards/kit/`), shown
`height` points tall between the margins, in a card's corner. It is drawn on
the same surface as a free card's face (`lib/widgets/web/`), with the kit, the
reader's theme and language inside it: a page that keeps a drag for itself
marks it (`data-drag`), and every other drag scrolls Explore. Where the phone
has no WebView, the section is passed over, as a block the build does not know
would be.

Fields: `html` (required, one page or one per language, at most 200 KB each),
`height` (required, 40–1200).

```json
{"id": "kit-page", "block": "web", "height": 220,
 "html": {"en": "<!doctype html>…", "it": "<!doctype html>…"}}
```

## The reader's own

Four blocks that work out what they show from the reader alone — their day,
their play, their reading, their saves — and so read no `source`. They open
the build's own Explore since the strategic Explore, between the day's
challenge (`bets-day`) and the set the reader is filling (`purpose.set`). A
build older than them passes over all four (docs/REMOTE.md, rule 3).

### `your-day`

The reader's day in a panel: "Today: 3 of 5 read · 2 left", a bar for each of
the five (the read ones filled), the week from Monday to Sunday as dots — a day
finished lit in the streak's orange, today ringed until it is — and the streak
("12 days") by a flame. A tap goes to Today. A second set dealt after the five
does not lengthen the day: the panel counts the five. Not drawn while Explore
is narrowed to a subject, nor before a day has been dealt.

Fields: `title`, `subtitle` (none by default: the panel says what it is).

```json
{"id": "your-day", "block": "your-day", "gap": 4}
```

### `your-five`

"Your five from today" ("Le tue cinque di oggi"): once the day's five are
read, a small row — the five in small, each a card in its own colour, the
name, their subjects — and a tap opens them again at full size, the way they
first came, always from the first card: not the one at the front of Today's
shelf, nor the one the last re-read stopped on (the owner's rule; the
`your-day` panel's "See again" opens them the same way). Subjects that do
not fit the line are counted ("+2"), never cut in the middle of a name. It
is where Today's "See again" went: the
finished day on Today is the five already, on its shelf. The reader's own
cards, never the day's challenge that is the same for everyone, which opens
Explore above it. Not drawn before the five are read, nor while Explore is
narrowed to a subject. A build older than it passes over it.

Fields: `title` (in place of the name), `subtitle` (in place of the
subjects).

```json
{"id": "your-five", "block": "your-five", "gap": 12}
```

### `quick-games` — the challenges

Explore's games, called Challenges ("Sfide"): tiles four to a page, two by
two, the pages side by side, a swipe from one to the next and dots under them
that say how many pages there are and which is showing (a tap on a dot goes to
its page; to a screen reader they are the pages' control, adjusted up and
down). First the four games the section always had — Sixty seconds, Spot the
false one, True or false and Which is bigger — then the games of bets that are
a whole game on their own: Closer, closer; Orders of magnitude; Bet a range;
Place your bet; Your number; then the three games of time: In order, What
year? and Before or after?. Three full pages. Not among them: the slip and Bet
a friend, which play nothing; Today's three, which opens Explore and whose
three cards and crowd belong to its own section; and the bet of the day,
Today's three with one card.

Every tile is one size on every page, at any text size (the largest any
challenge's words need, up to nearly half as large again; what it asks is
left out above 1.3x). The look is Go deeper's magazine: the app's own
surfaces, no pictures or icons, hairlines. A tile is set like an index
entry on the raised surface: a short rule in the challenge's tone (a deep
tone of its old colour, lifted a little at night), the skill it trains in
small capitals ("Intuition", "Chronology"), the name in Fraunces, what it
asks in a quiet line, and the reader's own figure in tabular figures — the
best of Sixty seconds ("Best 6/8"), today's score of a game of time once
its round is over. Never broken in the middle of a word. A page not full
keeps its empty places.

Every challenge is taken on a screen of its own
(`lib/widgets/explore/challenge_screen.dart`, one screen for all): the
tile's panel grows into the page and back, calmly, and the challenge is
taken there in three moments — what it is (the rule and the skill, the
name, a sentence or two on what it measures and why it matters, the
reader's figures between hairlines, Begin in the challenge's tone — or
Continue on a round begun), the round (a running head in small capitals,
a fine rule under it, the content set as a page, precise flat controls,
each answer told by a calm colour and a word), and a short report (the
score, accuracy and the time where it counts, a measured line read
against chance, "Personal best" in words, the cards again, the next
challenge, another round or when the next comes, and the score to send).
No confetti, no exclamation marks; motion is fades and short slides of
150 to 250 ms; haptics light and rare. Sixty seconds and In order are set
this way in full; the other challenges' rounds still deal their cards of
paper on the new page, until they are restyled.

- Sixty seconds (`sixty_game.dart`): the claim set in Fraunces, False and
  True, or a swipe; the minute a fine rule in its tone running down, the
  eight as short rules over the answers.
- Spot the false one (`spot_game.dart`): the four claims one under another, a
  tap and "That's the false one"; then each says what it is, the false one
  struck out, the pick stamped. One pick a day.
- True or false (`true_false_game.dart`): the shelf's claims on a deck, one at
  a time, no clock; each told with the first lines of why.
- The games of bets (`lib/explore/blocks/bets/bet_games.dart`): the cards the
  shelf deals today, one at a time — two figures to tap, a track halving with
  Less and More, a staircase, a track and its widths, the amounts and the
  stakes, a counter and its steppers — then how sure, where the shelf asks it,
  and the bet told on the card with the first lines of why. Closer, closer
  scores every step.
- The games of time (`time_games.dart`), on moments from the cards: cards
  whose question names, once, the year something happened, the year a gap
  until it is told (`lib/data/dated_lines.dart`). In order: four moments
  tapped in the order they happened, then sliding into their true order,
  years and all. What year?: three moments, each year dialled on a ruler of
  the centuries, ten points for the year itself and fewer the further off,
  as fair for the Middle Ages as for last decade. Before or after?: six
  moments one after another, each before or after the one above it, whose
  year is shown.

It is each game's own reckoning that is played: the day's round of Sixty
seconds and its record; the pick of Spot the false one, kept for the day and
recorded as that card's answer, the other three counted read; the claims of
True or false answered as the cards' own; every bet laid exactly as its tile
lays it — the same function, the same drafts kept for the day, the same how
sure — so a card half played on its shelf goes on on the screen where it was
left. The games of time have a round a day that is the same for everybody
(the same subject in view), each game other moments than the others, and
play again with the day's next round; a round is kept for the day as it is
played (`ExplorePlay`, `in-order`, `what-year`, `before-after`), and playing
one never counts a card read. Cards are noted under the section's id and the
game's (`quick-games-sixty`, `quick-games-in-order`). A game with nothing to
play today has no tile; with none, there is no section.

Fields: `title`, `subtitle` (Challenges and "Short exercises in judgement
and estimation, a few minutes each." by default, in the reader's language), `games` (any of `sixty`,
`spot-false`, `true-false`, `bets-bigger`, `bets-closer`, `bets-magnitude`,
`bets-range`, `bets-stake`, `bets-number`, `in-order`, `what-year`,
`before-after`, each once, in the order shown; all of them by default).

```json
{"id": "quick-games", "block": "quick-games",
 "title": {"en": "Challenges", "it": "Sfide"},
 "games": ["sixty", "spot-false", "true-false", "bets-bigger",
           "bets-closer", "bets-magnitude", "bets-range", "bets-stake"]}
```

### `subject-levels`

The subjects the reader has read anything of, four to a row, each a ring in the
subject's colour round a level from 1 to 10, the subject's name under it, the
furthest on first. A tap narrows Explore to the subject, as its chip does; the
subject in view sits on its tint. A reader who has read nothing has no section.

The level is reckoned from points: a card of the subject read is 1, a card
answered right 2 more. Level n is reached at 3 × (n − 1)² points — 3 for level
2, 12 for 3, 27 for 4, 48 for 5, 75 for 6, 108 for 7, 147 for 8, 192 for 9, 243
for 10 — so the first levels come in a day or two and the tenth takes most of a
subject's few hundred cards. Points only grow, so a level never goes down; the
ring fills toward the next level.

Fields: `title`, `subtitle`, `limit` (subjects shown, 8 by default, at most
20).

```json
{"id": "subject-levels", "block": "subject-levels", "limit": 8,
 "title": {"en": "Your subjects", "it": "Le tue materie"}}
```

### `like-saved`

A row of medium tiles of cards like one the reader saved, not read yet, under
a chip that says which: "Because you saved ‘How far away is the Moon…’". The row
follows the most recent save (of the last six) that has any; a card is alike by
points — the same strand 4, one also about the other's strand 3, the same genre
2, each keyword shared 1 — and needs 3. Drawn from the whole bank in the day's
order, narrowed to the subject in view. With nothing saved, or nothing like it
left unread, there is no section.

Fields: `title`, `subtitle`, `limit` (cards, 8 by default).

```json
{"id": "like-saved", "block": "like-saved",
 "title": {"en": "More like what you saved", "it": "Altre come quelle che hai salvato"}}
```

### `continue`

What the reader started and left, the latest first: a part of a path they
opened and read partway, a book stopped at one of its ideas. Each is a tile
with its mark (the subject's, or the book's cover), its name, a bar of how
far, the card that comes next ("5/10 · What deal finally got workers to
save?") and the way on. A tap goes on at that card.
Where that card is past what the free plan opens (a path's third card, or a
book's when it is not the book of the week), the tile shows a lock and
opens the path's or the book's own page instead, where the way on is.

A path counts once it has been opened (the phone keeps the last six opened)
and one of its cards read; a book counts once one of its ideas is read.
Either is gone once it is read whole, except that a part of a path read
whole hands on to the theme's next part, deeper ("Part 2: go deeper"),
while there is one. One tile fills the row; with more,
the next one's edge stays in sight. Nothing started, no section: a new
reader never sees it. Narrowed to a subject, it shows that subject's only.

Fields: `title` ("Continue" by default, in the reader's language),
`subtitle`, `limit` (tiles, 3 by default).

```json
{"id": "continue", "block": "continue", "gap": 20,
 "title": {"en": "Continue", "it": "Continua"}}
```

### `paths`

Paths of ten cards on one theme, a row of them: each a genre of the bank
(lib/data/genres.dart) with ten cards or more, its cards easy before hard and
a card with a drawing before one without. A theme with twenty cards or more
goes on, deeper, in a second part of ten, and with thirty in a third
(`partsOf`, three parts at most): the row shows each theme at the part the
reader has got to, the first not read through, and the tile says which
(`ECONOMICS · 2/3`). A tile is the subject's colour and mark, the genre's
name, the subject's, and ten steps with the ones read filled.

A tap opens the path's own page (lib/screens/card_path_screen.dart): its
subject, ten cards and about fifteen minutes; its name and part; the moves
its cards train; how far along; the ten in order, read ones ticked, the one
to go on with set apart; and at the foot, always in sight, the way on: start,
go on from card N, the next part, or read it again. Astute+, with a way in:
on the free plan the first two cards of every part are marked free and the
rest locked; the foot says so, and a locked card or "Unlock every path"
opens the plans, which speak of paths (paywall variant `E`). In the viewer,
the card after the two free ones says how many are left and opens the plans
too. The row turns over once a week, the same for every reader, and follows
the subject Explore is narrowed to. With no genre of ten, there is no section.

A path is also reached from an area's own page (lib/screens/area_screen.dart:
the paths of its themes, the moves it trains, more of its cards; opened from
the search before anything is typed and from the area's shelf) and from a
subject's own home in Your journey (lib/screens/subject_home_screen.dart).

Fields: `title`, `subtitle`, `limit` (paths shown, 8 by default).

```json
{"id": "paths", "block": "paths",
 "title": {"en": "Ten-card paths", "it": "Percorsi da 10 carte"}}
```

### `founder-books`

The books in pills that the people who built the companies everyone knows
recommended in public (lib/data/book_picks.dart): a row like the books'
own, in the same weekly turn and with the same way in, each tile under the
names of who recommended it. A book's own page says each pick: who, what
they built, their words quoted exactly, and where they said it, which a tap
opens. Every pick is checked against that page; a pick nobody can check is
left out. Fewer than three such books (two on a subject's page), no
section.

Fields: `title`, `subtitle`.

```json
{"id": "founder-books", "block": "founder-books",
 "title": {"en": "What the founders read", "it": "Cosa leggono i grandi imprenditori"}}
```

### `line-of-day`

One sentence worth keeping a day, the same for every reader
(lib/data/day_lines.dart): the words large, who wrote them, and where and
when ("On Liberty, 1859"; the translator for a line first written in
another language), which a tap opens where it was written. A button sends
it on, with where it is from. On Explore for every subject any line; on a
subject's page a line of its themes (thinking, science, life, decisions,
people, money), and none on a page with none. Each line is checked against
the book, letter or talk it comes from, never a line passed around under a
famous name.

Fields: `title`, `subtitle`.

```json
{"id": "line-of-day", "block": "line-of-day",
 "title": {"en": "Line of the day", "it": "La frase del giorno"}}
```

## The shelves Explore always had

Each draws its shelf exactly as Explore drew it, from the same reckoning
(`ExploreShelves`): the server's Explore when it has answered, the phone's own
before it, narrowed to the subject chip, dealt once a day from what the reader
had not read. They deal their own cards and read no `source`; most take the
section's `title` and `subtitle` in place of their own. The build's own list
(`own_explore.dart`, and `remote/examples/explore-today.json`) gives them ids
that are the names their shelves have always been measured under.

| `block` | The shelf | Its own fields |
|---|---|---|
| `nothing-here` | "Nothing in Cinema yet", when today's shelf and the question from every subject have nothing for the reader. Not a shelf; no gap of its own | — |
| `offline` | "You are offline", while Explore is the copy kept from the last time the phone had signal. Not a shelf; no gap of its own | — |
| `today` | Today's shelf, the same for everyone and only today, at the big tile | `title`, `subtitle`, `limit` (8) |
| `top` | The readers' top of the week or of the month, each card on its number, empty places until there are counts | `title`, `subtitle` |
| `loved` | Loved since the start, not read yet | `title`, `subtitle` |
| `asking` | A question from every subject, as rows | `title`, `subtitle`, `limit` (6) |
| `mine` | The reader's own subject: the one they pushed up, or read most of | `title`, `subtitle` |
| `where-you-live` | The cards about the reader's place, or the tile that offers to switch it on | `title`, `subtitle` |
| `month` | A month of one subject | `title`, `subtitle` |
| `numbers` | Numbers that surprise, the figure set large | `title`, `subtitle` |
| `debates` | Pick a side, with the "or" to slide | `title`, `subtitle` |
| `sharpest` | For the sharpest | `title`, `subtitle` |
| `origins` | Where it came from | `title`, `subtitle` |
| `stories` | True stories, played a beat at a time | `title`, `subtitle` |
| `true-false` | True or false, decided on the shelf, with spot the false one under it | `title`, `subtitle`, `spot` (true) |
| `spot-false` | Spot the false one, on its own | — |
| `came-back` | The cards that came back, to answer again | `title`, `subtitle` |
| `move-sampling`, `move-compared` | The two questions to ask of a number | `title`, `subtitle` |
| `work` | Work it out: every way to play a number, with the points left | `title`, `subtitle` |
| `unmask` | Unmask the chart | `title`, `subtitle` |
| `how-sure` | How sure am I, and why (its own frame) | — |
| `what-if` | What if it's true | `title`, `subtitle` |
| `series` | A few cards that only make the point together | `title`, `subtitle` |
| `sixty` | Sixty seconds: eight claims against the clock | `title`, `subtitle` |
| `mood` | Your mood, your minutes (its own frame) | — |
| `did-you-know` | Did you know (its own frame) | — |
| `surprise` | Not sure where to start: one card from anywhere | `title`, `subtitle` |
| `practical` | Something to use before tonight | `title`, `subtitle` |

```json
{"id": "today", "block": "today", "gap": 0,
 "title": {"en": "Today's shelf", "it": "Lo scaffale di oggi"}, "limit": 10}
```
