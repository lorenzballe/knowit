# The purpose family

Rounds 133 and 138 of the canvas (`prototypes.html`, anchors `#133a` to
`#133e` and `#138a` to `#138f`) turned into blocks the server can place
anywhere in Explore. Round 133 builds shelves on what Astute is for
(`docs/cards/SCOPO.md`): what you will do with a card, committing before
you open it, one thinking move met in many subjects, shelves picked for
the reader, a form for more of the themes the app rotates. Round 138 is
the bottom of Explore: shelves by the feeling a card gives, by where the
trick hides, by the questions to ask about your own life, cards played on
the shelf, every shelf a set to finish, and the very end.

The code is `lib/explore/blocks/purpose/`, listed in
`lib/explore/blocks/purpose_blocks.dart`; each block's checker is in
`tool/remote/parts/explore_blocks/purpose.py`. Every block is named
`purpose.<name>`, so the family's names can never meet another family's.

## Every piece, and whose it is

A design often holds several pieces, and designs share pieces. Each row is
one piece: where the canvas draws it, what it needs, and the block that
draws it, or `core` when the app already has it as a shelf and the canvas
draws nothing different.

| Piece | Where | What it needs | Block |
|---|---|---|---|
| The read-or-do filter: how many to do and to read, All · To read · To do | 133a | the shelves under it | `purpose.read-or-do` |
| A card that ends on what you will do with it: bet, call it, answer first, read and how long | 133a | the card's challenge and scene | `purpose.read-or-do` |
| A shelf's own count, "3 to do · 1 to read" | 133a | its cards | `purpose.read-or-do` |
| The lock note: answer here, then open the card | 133b | words (the app's, or the section's) | `purpose.commit-note` |
| True or false as two buttons on the card | 133b | true-or-false cards; the reader's answers | `purpose.commit` |
| Pick a side as Yes and No on the card | 133b | debates; the reader's answers | `purpose.commit` |
| Three amounts to pick from | 133b | pick-one cards; the reader's answers | `purpose.commit` |
| A move set large in a box of its own: A MOVE, its name, its line, how often you met it | 133c | the card's principle; the reader's mastery | `purpose.move` |
| A card that says where the move hides, "In a test result" | 133c | the card's genre | `purpose.move` |
| Came back: after how long, right or wrong last time | 133d | the reviews waiting | core (Came back) |
| A step above: dark card ringed in its colour, the difficulty in bars | 133d | the card's difficulty; the reader's measured level per subject | `purpose.step-above` |
| Thin for you: the subject read least, and how much of it | 133d | the reader's read cards; the subjects in the pool | `purpose.thin-subject` |
| The other side: the card in two tones, YOU SAID, the case for the other side | 133d | debates the reader answered | `purpose.other-side` |
| True or false split corner to corner, a question mark behind | 133e | true-or-false cards | core (True or false) |
| True stories with their beats | 133e | story cards | core (Story player) |
| Work it out in your head: an answer box under the question | 133e | number and estimate cards; the reader's answers | `purpose.in-your-head` |
| Seen, not read: the card's own picture in miniature | 133e | cards with a diagram | `purpose.seen` |
| How it really works: graph paper and THE MECHANISM | 133e | mechanism cards | `purpose.mechanism` |
| Where it came from: FIRST, the year, a dashed line to TODAY | 133e | origin cards | core (Where it came from) |
| For the sharpest: dark, ringed, HARD | 133e | hard cards | core (For the sharpest) |
| Just curious: the card as a circle | 133e | cards read for wonder | `purpose.curious` |
| Still moving: a band that says when it was updated | 133e | cards that can go stale; dates from the section | `purpose.moving` |
| Ah, so that's why: a band at the foot, THE WHY and how long | 138a | mechanism cards | `purpose.why` |
| That's me: cards as wide rows, each with a That's me to mark, and the count | 138a | cards about habits, attention, decisions; the day's marks | `purpose.thats-me` |
| News to me, and about me: two by two, the subject's mark large behind | 138a | cards about the body and health | `purpose.about-you` |
| What if it's true? with COMES BACK IN 3 DAYS | 138a | ideas that keep working | core (What if it's true?): the card does not come back unless it was answered, so core's foot, the question it leaves you, is the true one |
| In a headline: a paper's rules, THE CLAIM and the subject | 138b | cards on studies and claims | `purpose.headline` |
| In a number: the figure large, OUT OF WHAT? | 138b | cards whose question holds a figure, about odds and shares | `purpose.out-of-what` |
| In an offer: the card as a price tag | 138b | cards on prices, deals and who pays | `purpose.price-tag` |
| In an argument: the card as a speech bubble | 138b | cards on arguments and persuasion | `purpose.argument` |
| What to keep: three questions that catch most of these | 138b | the moves' questions (the app's, or the section's) | `purpose.keep` |
| A question for your own life, set large over its cards | 138c | the question and what it is about (the app's four, or the section's); cards for it | `purpose.life-question` |
| What do you want better questions about? and its chips | 138c | the topics; the day's picks | `purpose.life-topics` |
| Move it, then check: a slider set and checked | 138d | cards whose answer is a share | core (Work it out's slider) |
| Spot the trick: which move would catch it | 138d | cards with a move; the day's picks | `purpose.spot-trick` |
| Unmask the chart: the axis started at zero | 138d | cards with a chart trick | core (Unmask the chart) |
| What you played: points off, tricks spotted, and more | 138d | the day's play | `purpose.played` |
| A shelf as a set: n of m read, a bar in segments, READ on the cards read | 138e | the set's cards; what the reader read | `purpose.set` |
| A finished set: the cards fanned, a tick, all read | 138e | the same | `purpose.set` |
| Stamps that fill as you read | 138e | the set's cards; labels from the section | `purpose.stamps` |
| Your sets: a ring for each | 138e | the sets (the app's themes, or the section's) | `purpose.sets` |
| The last shelf: small cards, the mark alone | 138f | any cards | core (any shelf of cards) |
| Not sure where to start? Surprise me | 138f | any cards | core (Surprise me) |
| Tomorrow on the shelves | 138f | tomorrow's themes (the app's rotation, or the section's list) | `purpose.tomorrow` |
| Every subject | 138f | the subjects | core (subjects) |
| That's the bottom of Explore | 138f | words (the app's, or the section's) | `purpose.end` |

## What the app already knows

Nothing here asks the reader anything new. The blocks read what the app
writes down already, through `host.app` (lib/state/app_state.dart):

- **What was read**: `seenIds`, and what a block's host says through
  `isRead`. A set's progress and the thinnest subject are counted from it.
- **What was answered**: `answers` — the side taken on every debate (the
  other side), and the answer given on any card, on Today or on a shelf
  (commit, in your head).
- **Levels**: `measuredLevels`, each subject's level measured from the
  reader's last judgements over what they said and what the onboarding
  read into their mix (lib/data/reader_profile.dart). A step above is one
  difficulty past it.
- **Moves**: `masteryOf(principle)`, how often the reader met a move and
  how often they were right. A move is worth `Score.perMove` once it is
  down.
- **The themes**: lib/data/themed_shelves.dart, the nineteen themes the
  app rotates, and the test each one deals by. The read-or-do shelves, the
  sets and tomorrow's shelves are the themes; the themes' names and lines
  are the app's own strings.
- **The card**: its challenge (true or false, pick one, a number, an
  estimate, a side), its scene (a slider, a story, a trick…), its
  principle, difficulty, genre and strand (lib/data/genres.dart), hook,
  mood, how soon it may go stale, its diagram.
- **The day's play**: lib/state/explore_play.dart, where Explore's shelves
  keep what was played today — core's slider guesses, and this family's
  tricks spotted, That's me marks and topics picked.

What the reader does here that the app had no record of — a card marked
That's me, a topic picked, a trick spotted — is noted with `host.note`,
and kept for the day in the day's play like every game on a shelf.

## Every section, whatever its block

```json
{
  "id": "why-1",
  "block": "purpose.why",
  "title": {"en": "Ah, so that's why", "it": "Ah, ecco perché"},
  "subtitle": {"en": "One mechanism, explained until it clicks"},
  "source": {"…": "the engine's"},
  "size": "m",
  "limit": 8,
  "fit": true,
  "audience": {"…": "docs/REMOTE.md"}
}
```

- `title`, `subtitle`: per language with `en` required, or one string for
  all; without them the block's own, in the app's strings.
- `source`: where the cards come from, the engine's to read. A block asks
  its host for a pool of them (`cardsFor(section, limit: …)`), keeps the
  ones its form is for, and shows at most `limit`. Blocks that pick for the
  reader (a step above, thin for you, the other side, sets) want a wide
  source: they choose from it.
- `size`: the block's own sizes, below; `m` is the canvas. A size the
  build does not know is drawn at `m`.
- `limit`: the most cards shown.
- `fit`: `true` (the default) keeps only the cards the form is for — the
  mechanisms on How it really works; `false` takes the source's cards as
  they come, for a shelf curated by hand. A form that cannot draw a card
  (true-or-false buttons on a card that asks for a number) never takes it.

Every block wraps itself once in `host.watch(section, …)`, says each card
it builds with `host.seen`, and opens a card with `host.open`. It returns
null — and Explore leaves the section out — when it has nothing to show.

## The blocks

### `purpose.read-or-do` (133a)

Every card ends on what you will do with it: a chip with its mark and the
verb (Bet the number, True or false, Pick one, Type a number, Pick a side,
You first, Move it and watch, What happens next?, Spot the trick, Draw it,
Sort them, Put them in order, Hold it, Grow a sample, Ask why, Say it
plainly, Pair them up, Follow the clues), or Read and how long. A card to
do carries the chip in its ink; a card to read, in a tenth of it. Over the
shelves, how many there are of each, and All · To read · To do, which
narrows every shelf of the block at once.

- `shelves`: a list of shelves, each `{"id", "title", "subtitle", "theme"
  or "source", "limit"}`. Without it, the day's turning themes the pool can
  fill (the app's rotation, `style.shelves` of them, 4 by default).
- `theme`: one of the app's themes by name (`myths`, `numbers`,
  `paradoxes`, `practical`, `origins`, `stories`, `debates`, `workItOut`,
  `seen`, `sharpest`, `trueOrFalse`, `reasoning`, `ideas`, `curious`,
  `moving`, `howItWorks`, `puzzles`, `past`, `place`; `past-1` for a form).
- `style.filter`: show the filter (default: when there are two shelves or
  more). `style.count`: each shelf's count (default true).
- sizes `s` 176×212, `m` 206×244, `l` 240×280.

```json
{"id": "read-or-do", "block": "purpose.read-or-do",
 "shelves": [{"id": "numbers", "theme": "numbers"},
             {"id": "myths", "theme": "myths"},
             {"id": "today", "theme": "practical"}]}
```

### `purpose.commit-note` (133b)

The lock, and the line that says why the shelves under it ask first.

- `text`: per language; default the app's.

```json
{"id": "commit-note", "block": "purpose.commit-note"}
```

### `purpose.commit` (133b)

The answer given on the shelf, before the card opens: true or false as two
buttons, a debate as its two sides, three amounts as three rows. It is
recorded as the card would record it (`host.commit`), and the card says at
once whether it was right; the why, or the other side, is the card.

- `kind`: `true-false`, `side`, `pick` or `any` (the default: each card
  as it asks). The default title follows it.
- sizes `s`, `m`, `l` (true or false 206×236, a side 290×214, three
  amounts 236×268 at `m`).

```json
{"id": "commit-tf", "block": "purpose.commit", "kind": "true-false"}
```

### `purpose.move` (133c)

One thinking move, set large in a box of its own — A MOVE, its name, the
line that says it, and how often the reader has met it, or New and what it
is worth — and under it the cards where it hides, each saying where.

- `move`: the principle (`baseRate`, `sampling`, `counterfactual`, …).
  Default: the reader's weakest move that has cards here, or the day's.
- `name`, `line`: the move's words, per language; default the app's.
- sizes `s` 172×196, `m` 196×216, `l` 224×244.

```json
{"id": "move-base-rates", "block": "purpose.move", "move": "baseRate"}
```

### `purpose.step-above` (133d)

Cards one difficulty past the reader's measured level in their subject:
dark, ringed in the subject's colour, the difficulty drawn in bars.

- sizes `s` 180×204, `m` 204×226, `l` 232×252.

```json
{"id": "step-above", "block": "purpose.step-above"}
```

### `purpose.thin-subject` (133d)

The subject in the pool the reader has read least of, by share, with a
bar of how much, and its cards not yet read. Shown once the reader has
read something, since before that every subject is as thin as the next.

- `subject`: a subject to show instead (`medicine`), still with its share.
- sizes `s` 176×188, `m` 200×208, `l` 228×232.

```json
{"id": "thin", "block": "purpose.thin-subject"}
```

### `purpose.other-side` (133d)

Debates the reader took a side on: the card in two tones, YOU SAID and
their side, and the way to the best case against it, which is the card.

- sizes `s` 256×184, `m` 290×204, `l` 320×224.

```json
{"id": "other-side", "block": "purpose.other-side"}
```

### `purpose.in-your-head` (133e)

A number to reach in your head: under the question, an answer box with
its unit, which takes the answer on the shelf and records it as the card
would; then the verdict, and the card for the working.

- sizes `s` 200×212, `m` 222×228, `l` 250×252.

```json
{"id": "in-your-head", "block": "purpose.in-your-head"}
```

### `purpose.seen` (133e)

Cards that draw their point, each with its own picture in miniature at its
foot: its bars, its line, its dots, its split, in a darker tone of its
colour with the part that matters in its ink.

- sizes `s` 176×224, `m` 200×248, `l` 228×276.

```json
{"id": "seen", "block": "purpose.seen"}
```

### `purpose.mechanism` (133e)

How it really works: graph paper in a darker tone of the card, THE
MECHANISM at its foot.

- sizes `s` 180×212, `m` 206×236, `l` 236×262.

```json
{"id": "mechanism", "block": "purpose.mechanism"}
```

### `purpose.curious` (133e)

Just curious: each card a circle, its mark over the question.

- sizes `s` 184, `m` 216, `l` 248 across.

```json
{"id": "curious", "block": "purpose.curious"}
```

### `purpose.moving` (133e)

Still moving: a band across the top that says when the card was last
brought up to date, or, without a date, how soon it could change.

- `updated`: card id to a date (`"2026-10-04"`), when the server has one.
- sizes `s` 204×196, `m` 232×214, `l` 262×236.

```json
{"id": "moving", "block": "purpose.moving",
 "updated": {"economics-subscriptions-10": "2026-10-04"}}
```

### `purpose.why` (138a)

Ah, so that's why: a band at the foot in the card's darker tone, THE WHY
and how long, and an arrow.

- sizes `s` 180×240, `m` 206×268, `l` 236×296.

```json
{"id": "why", "block": "purpose.why"}
```

### `purpose.thats-me` (138a)

Cards as wide rows, each with That's me to mark it, and under them how
many the reader marked. A mark is noted (`thats me`) and kept for the day.

- `footer`: the line beside the count, per language; default the app's.
- sizes `s`, `m`, `l`: how large the questions are set. `limit` 3.

```json
{"id": "thats-me", "block": "purpose.thats-me", "limit": 3}
```

### `purpose.about-you` (138a)

News to me, and about me: two by two, the subject's mark drawn large
behind each card.

- sizes `s`, `m`, `l` (184 high at `m`). `limit` 4.

```json
{"id": "about-you", "block": "purpose.about-you"}
```

### `purpose.headline` (138b)

The claim as a paper prints it: a double rule, THE CLAIM and the subject,
then the headline.

- sizes `s` 210×212, `m` 240×236, `l` 270×262.

```json
{"id": "headline", "block": "purpose.headline"}
```

### `purpose.out-of-what` (138b)

The figure the question rests on, large, and OUT OF WHAT? under it; the
question at the foot.

- sizes `s` 172×208, `m` 194×228, `l` 220×252.

```json
{"id": "out-of-what", "block": "purpose.out-of-what"}
```

### `purpose.price-tag` (138b)

The card as a price tag: the point, the hole, the dashed line.

- sizes `s` 240×146, `m` 270×160, `l` 300×178.

```json
{"id": "offer", "block": "purpose.price-tag"}
```

### `purpose.argument` (138b)

The card as a speech bubble, its tail at the foot.

- sizes `s` 228×152, `m` 258×168, `l` 288×186.

```json
{"id": "argument", "block": "purpose.argument"}
```

### `purpose.keep` (138b)

What to keep: the questions that catch most of the tricks above it, each
the question a move asks and the line that says the move.

- `moves`: principles, in order (default `counterfactual`, `sampling`,
  `baseRate`), with the app's words.
- `items`: or the questions themselves, `[{"ask": {...}, "line": {...}}]`.
- `heading`: per language; default "Three questions that catch most of
  these", counted.

```json
{"id": "keep", "block": "purpose.keep",
 "moves": ["counterfactual", "sampling", "baseRate"]}
```

### `purpose.life-question` (138c)

A question to ask of your own life, set large under what it is about, and
the cards that ask it in other words.

- `topic`: `money`, `work`, `time`, `body`, `relationships` or `belief`,
  with the app's words and the cards for it. Default: one a day.
- `about`, `question`: the words instead, per language.
- sizes `s` 176×200, `m` 200×226, `wide` 250×176, `l` 290×196; each topic
  has the canvas's as its default.

```json
{"id": "life-money", "block": "purpose.life-question", "topic": "money"}
```

### `purpose.life-topics` (138c)

What do you want better questions about? — chips to pick, and under them,
the cards that ask about what was picked. A pick is noted (`life topics`)
and kept for the day.

- `topics`: which, in order (default all six).
- `question`, `footer`: per language; default the app's.

```json
{"id": "life-topics", "block": "purpose.life-topics"}
```

### `purpose.spot-trick` (138d)

Which move would catch it: three moves to pick from, the card's own and
two others; the pick says whether it was the one, and the card says why.
Noted (`trick spotted`) and kept for the day.

- sizes `s` 270, `m` 300, `l` 330 wide.

```json
{"id": "spot-trick", "block": "purpose.spot-trick"}
```

### `purpose.played` (138d)

What was played on the shelves today, as the day's play holds it: how far
off the sliders were on average, how many tricks were spotted, how many
cards were answered on a shelf of this family.

```json
{"id": "played", "block": "purpose.played"}
```

### `purpose.set` (138e)

A shelf as a set to finish: n of m read, a bar in as many segments as it
has cards, READ on each card read — reading counts as much as answering.
Once every card is read, the set is a fan of its cards, a tick, and the
line that says new ones join when it comes round.

- `theme`: the set is that theme's cards, in an order that does not turn
  with the day. Default: the source's cards, or the week's theme.
- sizes `s` 156×180, `m` 180×204, `l` 206×232. `limit` 12.

```json
{"id": "set-myths", "block": "purpose.set", "theme": "myths"}
```

### `purpose.stamps` (138e)

A set as stamps: one for each card, in its colour once read, dashed
until then, a tap from its card.

- `labels`: card id to the stamp's word (`"HU"`); without one, the
  subject's mark.
- `theme`: as for a set. Default: the week's place.
- sizes `s` (7 a row), `m` (6), `l` (5). `limit` 12.

```json
{"id": "stamps-europe", "block": "purpose.stamps", "theme": "place-2"}
```

### `purpose.sets` (138e)

Every set, with a ring for how far along it is, green once complete; a tap
opens the first card of the set not yet read.

- `sets`: `[{"id", "title", "theme" or "source"}]`. Default: every theme
  the pool can make a set of.

```json
{"id": "your-sets", "block": "purpose.sets"}
```

### `purpose.tomorrow` (138f)

What the shelves bring tomorrow.

- `shelves`: `[{"title": {...}, "subtitle": {...}}]`, what the server
  will show. Default: tomorrow's turn of the app's themes that the pool
  can fill, three of them.

```json
{"id": "tomorrow", "block": "purpose.tomorrow"}
```

### `purpose.end` (138f)

That's the bottom of Explore, and See you tomorrow.

- `line`, `subline`: per language; default the app's.

```json
{"id": "end", "block": "purpose.end"}
```
