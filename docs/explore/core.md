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
