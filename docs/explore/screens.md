# Explore's whole screens: the `screens` family

Rounds 140 and 141 of the canvas (`prototypes.html`) are eleven whole
Explore screens, each built on one idea: think like an expert, your mood and
your minutes, connect the dots, sixty seconds then a series, ask first, keep
asking why, did you know, through time, change your mind, say it tonight and
the front page. This page breaks each screen into its pieces and says where
each piece is in the app now: a block the server can place, a field or a
switch of one, a shelf the `core` family draws, or the Explore screen's own.

| | Where |
|---|---|
| The blocks | `lib/explore/blocks/screens/`, one file per idea, listed in `lib/explore/blocks/screens_blocks.dart` |
| What they share | `parts.dart` (sizes, words, shelf head, chips, panels, tiles, haptics), `memory.dart` (what the phone keeps), `ask_search.dart` (the search for typed questions) |
| The checker | `tool/remote/parts/explore_blocks/screens.py`, tested by `tool/remote/test_explore_screens.py` |
| Whole screens | `remote/examples/explore-<screen>.json`, one per screen this family draws (not bundled) |
| Tests | `test/explore/screens_*_test.dart`, with `screens_harness.dart` |
| Camera | `tool/screens_shots.dart`: every block and every whole screen on three phones, at night and on paper, played states and a large text size |

Every screen of the canvas sits under Explore's title, its search and the
subject chips, over the tab bar. Those are the Explore screen's own
(`lib/screens/explore_screen.dart`), not blocks, and are left out below.

## The pieces

**core** marks a piece the `core` family draws: a shelf the app already had
before Explore came from the server. Everything else is a block of this
family, or a field or a style switch of one.

### 140a Think like an expert

| Piece | In the app | Needs |
|---|---|---|
| "Think like an expert" and its line | `expert`: `title`, `subtitle`, `style.head` | |
| The chips: statistician, economist, historian, doctor, scientist | `expert`: `experts`, `expert`; the pick is remembered | The five experts, built in, in every language |
| The question panel: the expert's mark, "THINK LIKE A …", the question in quotation marks | `expert`: each expert's `as`, `question`, `mark` | |
| The large card | `expert`: the first card; left out at size `s` | |
| The row of cards | `expert`: the rest, `limit` | Cards that need the question: by principle, subject, age and hook (below), or named per expert |

### 140b Your mood, your minutes — core

Tone chips, the time you have, "For you, right now" with each card's
minutes: the core family's Mood minutes shelf.

### 140c Connect the dots

| Piece | In the app | Needs |
|---|---|---|
| "Connect the dots" and its line | `connect-dots`: `title`, `subtitle`, `style.head` | |
| The subject chips, each with its dot | `connect-dots`: `subjects`, `subject`; the pick is remembered; Explore's own subject chip narrows it to that subject | |
| The subject's name and "Meets 5 subjects in 12 cards" | `connect-dots` | The bank's `also` tags: a card of one subject about a strand of another |
| The map: the subject in the middle, the ones it meets around it, dashed spokes | `connect-dots`: `style.map`; left out at size `s`; a subject round it is a button | |
| "Where they meet", each card headed "ECONOMICS × FOOD" in the colour of the subject it leads to | `connect-dots`: `limit`; `pairs` adds meetings by hand | |

### 140d Sixty seconds, then a series — core

The sixty-second round of eight true or false (start, running, the end with
what was missed) and "In a few cards", the series: the core family's Sixty
seconds and Series shelves.

### 140e Ask first

| Piece | In the app | Needs |
|---|---|---|
| "What do you want to understand?" | `ask-first`: `title` | |
| The field, its hint, the clear button | `ask-first`: `hint` | |
| "TRY" and the words to try | `ask-first`: `try` (per language), `style.try` | |
| "3 cards answer it" and the cards | `ask-first`: `limit` | A search that answers a question: a ranked word search of the cards on the phone (`ask_search.dart`), or the host's own (`ScreensSearchHost`) |
| "No card on that yet" and its button | `ask-first`: "Keep the question" | The phone's memory |
| "Questions you asked", each with the card that answered it, "SUBJECT · ANSWERED" | `questions-asked`, or `style.asked` on `ask-first` to show them under the field | The phone's memory |

### 141a Keep asking why

| Piece | In the app | Needs |
|---|---|---|
| "Keep asking why" and its line | `keep-asking`: `title`, `subtitle`, `style.head` | |
| The meter of how deep the chain is open | `keep-asking`: `style.meter` | |
| The chain: question, answer, "Why?" between them | `keep-asking`: `chains[].steps`, the section's own words | Words written and checked like a card's, with a source |
| The "Why?" button | `keep-asking`; how deep is remembered | |
| "Four whys deep. That's the bottom of this one." and "Start again" | `keep-asking`, with "Source: …" and the cards that go further (`chains[].cards`) | |
| "More rabbit holes" | `keep-asking`: the other chains, `style.holes`, `chain` for the first | |

### 141b Did you know? — core

The card to swipe, "Knew it" and "New to me" with their counts, the end:
the core family's Did you know shelf.

### 141c Through time

| Piece | In the app | Needs |
|---|---|---|
| "Through time" and its line | `through-time`: `title`, `subtitle`, `style.head` | |
| The age and its years, large, with the two arrows | `through-time`: each stop's `label` and `when` | The bank's six ages (`era`), or the section's stops |
| The ruler: a tick for every power of ten, from the far end to "Now", dragged, tapped or moved with a screen reader | `through-time`: each stop's `ago`; `stop` for the first; the stop is remembered | |
| "Years ago. Each tick is ten times further back." | `through-time`: `style.caption` | |
| The cards of the age, with the year a card names | `through-time`: `limit` (1 or 2), a stop's `source` | The year a question names (`questionYear`) |

### 141d Change your mind

| Piece | In the app | Needs |
|---|---|---|
| "Change your mind" and its line | `change-your-mind`: `title`, `subtitle`, `style.head` | |
| "SUBJECT · CLAIM" and the claim | `change-your-mind`: a true-or-false card's claim; it opens the card | The bank's true-or-false cards |
| "BEFORE YOU READ", five places from disagree to agree | `change-your-mind`; taken once and remembered | The phone's memory |
| "WHAT WE KNOW" | `change-your-mind`: the card's own explanation | |
| "AND NOW?" and what moved | `change-your-mind` | |
| The summary: "You changed your mind on 1 of 2." | `change-your-mind`: `style.summary` | |

### 141e Say it tonight

| Piece | In the app | Needs |
|---|---|---|
| "Say it tonight" and its line | `say-it-tonight`: `title`, `subtitle`, `style.head` | |
| Tonight's line: the quotation mark, "TONIGHT'S LINE · SUBJECT", the line, why it is true, "I said it", "Share" | `say-it-tonight`: the first card | A claim that is true; the said that Top of the week counts; the share sheet |
| More lines, each with "I said it" | `say-it-tonight`: the rest, `limit` | |
| "You said 2 lines this week." and "Every line you say also counts toward Top of the week." | `say-it-tonight`: `style.counter` | The day each line was said |

### 141f The front page

| Piece | In the app | Needs |
|---|---|---|
| "EXPLORE · THURSDAY 8 OCTOBER", "The Astute" between rules, "TODAY'S EDITION", "THE SAME FOR EVERYONE" | `masthead`: `kicker`, `title`, `left`, `right` | The date in the reader's language |
| The lead: the banner, "SUBJECT · THE LEAD", the headline, the standfirst | `front-lead`: `headline`, `deck` | |
| Two columns | `front-columns` | A side to pick and a thing to use |
| "IN NUMBERS" | `front-numbers`: `title`, `limit` | The figure in a question (`shelfFigure`) |
| "CORRECTIONS" and "What almost everyone believes, and why it is wrong" | `front-correction`: `title`, `subtitle` | |
| "PUZZLE OF THE DAY" and "Work it out" | `front-puzzle`: `title`, `button` | |
| "That's today's edition", "Tomorrow's is out in the morning" | `edition-end`: `title`, `subtitle` | |

## What the app already had, and what it did not

- **Search.** Explore's search finds cards whose words contain what was
  typed. A typed question is mostly words no card contains ("why do onions
  make you cry"), so `ask_search.dart` reads a question for the words that
  mean something (stop words of every language the bank is written in left
  out, plurals and endings folded, six letters kept so that "accurate" meets
  "accuracy") and ranks the cards on the phone by how many of its rarest
  words each holds, in the question first. The cards are written in
  English, so it answers a question asked in English best; in another
  language, names and figures still find their cards. A host with a better
  search can answer instead by implementing `ScreensSearchHost`.
- **Typed questions.** The app kept none. They are kept now on the phone,
  thirty at most, and never sent: a note says how many words and answers a
  question had, never its words.
- **Said.** `AppState.markSaid` is the said that Top of the week already
  counts (`Tallies.held`); a line said here is that said, once and for good,
  as everywhere in the app. The day it was said is kept beside it so that
  the week can be counted.
- **Debates and leans.** A side to pick is a card whose challenge is
  `TakeASide`; the front page's columns take one.
- **Mood minutes, Sixty seconds, Series, Did you know.** Shelves of the
  app's, in `lib/widgets/explore/`, dealt by `explore_mix.dart`: the core
  family's.
- **Dates in the bank.** Every card carries the age it is about (`era`, six
  of them); `questionYear` finds the year a question names.
- **Tags the screens read.** `also` (a strand of another subject: Connect
  the dots), `principle` (the statistician, the economist, the scientist),
  `hook` (the historian; the parts of the front page), the challenge's kind
  (true or false, a number, an estimate, a side).

## The blocks

Every block reads the fields every section has (`id`, `block`, `title`,
`subtitle`, `source`, `size`, `style`, `limit`, `audience`) where it has a
use for them, and its own. Words are a string for every language or
`{"en": "…", "it": "…"}`, English required. `size` is `s`, `m` or `l` (`xs`
and `xl` draw as `s` and `l`). Every `style` key is a switch, on unless said.
A section of only `{"id": "x", "block": "<name>"}` looks right for every
block but `keep-asking`, whose chains are the section's own words (and
`questions-asked` waits for a question to be kept). A block with nothing to
show is left out, title and all; every card it draws is counted as seen on
its section; every card opens the way every shelf's does. The checker
refuses, field by field, what a block would pass over in silence: a field
it does not read, words with no English, a card it cannot draw.

When a section names no cards, a block asks Explore for a pool
(`cardsFor` with a limit of its own) and takes from it the kind of card it
draws; when it names them (`source.ids`), it shows those, in order, if they
are of its kind.

### `expert` — Think like an expert (140a)

The question an expert always asks, and the cards that need it.

| Field | |
|---|---|
| `experts` | The experts, in order: ids of the five the app carries (`statistician`, `economist`, `historian`, `doctor`, `scientist`), or objects. An object with a built-in id changes what it sets; with another id it is an expert of the section's own and needs `name` (24 at most), `as` (48) and `question` (90). `mark` is `chart` or a subject. `subjects`, `principles`, `hooks` say which cards fit; `source` names them (two at least). All five when left out. |
| `expert` | The one picked first. |
| `limit` | Cards per expert, 2 to 8; 4. |
| `style.head` | The shelf's head. |

The built-in experts take, from the pool of 240: the statistician, cards
that train a statistical principle (base rates, survivors, regression,
sampling, confounding, counterfactuals, many comparisons, conditionals,
independence, coincidence, Simpson's paradox, conjunctions); the economist,
economics, sunk costs and anchoring; the historian, history, and stories,
origins and myths of the ancient world to the nineteenth century; the
doctor, medicine and the human body; the scientist, science, space, nature
and confirmation. An expert with fewer than two cards is not shown.

```json
{"id": "experts", "block": "expert", "experts": ["statistician", "historian",
  {"id": "doctor", "source": {"ids": ["medicine-symptoms-7", "medicine-resistance-7"]}}]}
```

### `connect-dots` — Connect the dots (140c)

| Field | |
|---|---|
| `subjects` | The subjects to pick from, in order; when left out, every subject with two cards or more where it meets another, in Explore's order. |
| `subject` | The one in the middle first. |
| `pairs` | Meetings by hand: `[{"card": id, "with": subject}]`, for a card whose tags have not caught up with it. |
| `limit` | Cards where they meet, 1 to 12; 5. |
| `style.head`, `style.map` | The head; the map (never at size `s`). |

The meetings are looked for among 400 cards; the cards under a subject are
dealt round the subjects it meets, so five cards are not five of one pair.

```json
{"id": "dots", "block": "connect-dots", "subject": "economics",
 "subjects": ["economics", "music", "science", "history", "psychology", "food"]}
```

### `ask-first` — Ask first (140e)

| Field | |
|---|---|
| `title` | The question over the field; "What do you want to understand?". |
| `hint` | The field's hint (60 at most). |
| `try` | Words to try, a list or lists by language; when left out, words of the cards' own keywords. |
| `limit` | Answers shown, 1 to 10; 5. |
| `style.try`, `style.asked` | The words to try; the questions asked under the field (off). |

The answers come 280 ms after the typing settles. A question no card
answers can be kept; one whose answer is opened is kept with that card.
Nothing typed leaves the phone.

```json
{"id": "ask", "block": "ask-first", "style": {"asked": true},
 "try": {"en": ["accurate test", "pollinators", "Oscar"], "it": ["test accurato", "impollinatori", "Oscar"]}}
```

### `questions-asked` — Questions you asked (140e)

The questions the reader kept, newest first, each with the card that
answered it — the one they opened, or the first card that answers it now —
or a line that says none does yet. Held down, or from a screen reader, a
question is forgotten, with Undo. Left out when no question is kept.

| Field | |
|---|---|
| `limit` | Questions shown, 1 to 10; 3. |
| `style.head` | The head. |

```json
{"id": "asked", "block": "questions-asked", "limit": 4}
```

### `keep-asking` — Keep asking why (141a)

| Field | |
|---|---|
| `chains` | Required. Each: `id`, `subject` (its colour), `source` (where its answers come from, as a card names its own), `steps` (2 to 8 `{"q": words, "a": words}`, 110 and 320 at most), `cards` (up to 6 ids that go further, shown at the bottom). |
| `chain` | The chain shown first. |
| `style.head`, `style.holes`, `style.meter` | The head; the other chains as rabbit holes; the meter of how deep. |

The chain opens one answer at a time; how deep it is open, and the chain
picked, are remembered. At the bottom: how many whys deep, the source, the
cards that go further and "Start again".

```json
{"id": "whys", "block": "keep-asking", "chains": [{
  "id": "sky", "subject": "science",
  "source": "Bohren and Clothiaux, Fundamentals of Atmospheric Radiation, 2006",
  "steps": [{"q": {"en": "Why is the sky blue?", "it": "Perché il cielo è blu?"},
             "a": {"en": "…", "it": "…"}}, {"q": "…", "a": "…"}],
  "cards": ["space-martian-weather-10"]}]}
```

### `through-time` — Through time (141c)

| Field | |
|---|---|
| `stops` | 2 to 12, oldest first. Each: `id`, `ago` (years before now), and `era` (one of the bank's ages: its cards and its words) or `source` (cards of its own) or both; `label` and `when` (40 at most) required without an `era`. The bank's six ages when left out, each where its years are. |
| `stop` | The stop shown first. |
| `limit` | Cards per stop, 1 or 2; 2. |
| `style.head`, `style.caption` | The head; the caption under the ruler. |

The ruler is drawn in powers of ten, from the furthest stop to now; a stop
with no cards is left off it, and a ruler of one stop is not drawn.

```json
{"id": "time", "block": "through-time", "stops": [
  {"id": "first-light", "ago": 13.8e9, "label": {"en": "The first light"},
   "when": {"en": "13.8 billion years ago"}, "source": {"ids": ["space-cosmic-background-5"]}},
  {"id": "ancient", "era": "ancient", "ago": 2000},
  {"id": "recent", "era": "recent", "ago": 14}]}
```

### `change-your-mind` — Change your mind (141d)

| Field | |
|---|---|
| `source` | True-or-false cards only. |
| `limit` | Claims, 1 to 6; 3. |
| `style.head`, `style.summary` | The head; the summary under the claims. |

Myths come first. Where the reader stood before is taken once, before they
read; where they stand after, once, after. The claim's own card counts as
read once its evidence is shown.

```json
{"id": "mind", "block": "change-your-mind",
 "source": {"ids": ["science-cold-myths-1", "medicine-when-not-to-take-them-1"]}}
```

### `say-it-tonight` — Say it tonight (141e)

| Field | |
|---|---|
| `source` | True-or-false cards whose claim is true: a line to say is a true one. |
| `limit` | Lines, 1 to 8; 5. |
| `style.head`, `style.counter` | The head; the week's count. |

```json
{"id": "tonight", "block": "say-it-tonight", "limit": 4}
```

### The front page (141f): `masthead`, `front-lead`, `front-columns`, `front-numbers`, `front-correction`, `front-puzzle`, `edition-end`

Seven blocks, so that a day can be a whole front page and another day can
borrow its numbers or its puzzle. A part that names no cards deals them by
the day from all the cards Explore has for it, a card for one part at most:
the page is the same for everyone who opens it that day, read or not, which
is what the masthead says, and a page made only of defaults never prints a
card twice. A part that names its cards shows those.

| Block | Fields |
|---|---|
| `masthead` | `title` (the paper's name: "The Astute"), `kicker` (the day's date in the reader's language), `left`, `right` (40 at most each). |
| `front-lead` | `source` (1 card), `headline` (140; the card's question), `deck` (160). The standfirst never gives the answer away: until the card is read it says what kind of card it is. |
| `front-columns` | `source` (2 cards): a side to pick and a thing to use. |
| `front-numbers` | `source` (2 to 4 cards with a figure in their question), `title`, `limit` (2 to 4; 3). |
| `front-correction` | `source` (1 card), `title`, `subtitle`. A myth. |
| `front-puzzle` | `source` (1 card), `title`, `button` (24; "Work it out"). A sum, an estimate or a puzzle. |
| `edition-end` | `title`, `subtitle`. |

```json
{"id": "lead", "block": "front-lead", "source": {"ids": ["space-expansion-8"]}}
```

## Whole screens

| Screen | Example |
|---|---|
| 140a Think like an expert | `remote/examples/explore-expert.json` |
| 140b Your mood, your minutes | core |
| 140c Connect the dots | `remote/examples/explore-connect-dots.json` |
| 140d Sixty seconds, then a series | core |
| 140e Ask first | `remote/examples/explore-ask-first.json` |
| 141a Keep asking why | `remote/examples/explore-keep-asking.json` |
| 141b Did you know? | core |
| 141c Through time | `remote/examples/explore-through-time.json` |
| 141d Change your mind | `remote/examples/explore-change-your-mind.json` |
| 141e Say it tonight | `remote/examples/explore-say-it-tonight.json` |
| 141f The front page | `remote/examples/explore-front-page.json` |

Each example is a whole `explore` document, checked by
`tool/remote/test_explore_screens.py`. The facts written into the canvas
are the prototype's: the chains of whys in the example are written again
from their sources, which they name, and every card named is in the bank.

## What the phone keeps

In `SharedPreferences`, under `knowit.explore.screens.`, read through so
that signing out, which clears the phone, clears them at once:

| Key | What |
|---|---|
| `picks` | The expert, subject, chain or stop picked, by section. |
| `whys` | How deep each chain is open, by section and chain. |
| `stances` | Where the reader stood on a claim before (`b`) and after (`a`), with the day (`d`), by card. |
| `said` | The day each line was said, by card. |
| `asked` | The questions kept, newest first, thirty at most: the words (`q`), the card that answered (`c`), the day (`d`). |

## What the blocks note

Through `ExploreHost.note`, on the section: `expert picked` (`expert`),
`subject picked` (`subject`), `asked` (`words`, `results`, and `opened` with
the answer's place or `kept`), `asked forgotten`, `why` (`chain`, `depth`,
`of`), `why again` and `chain picked` (`chain`), `era picked` (`stop`),
`stance` (`pill_id`, `when`, `level`, and after: `before`, `moved`), `said`
(`pill_id`). Never a word the reader typed.

## Where the screens differ from the canvas, and why

- **140e** said a question no card answers "lands in your Today" when you
  "Ask Astute". Nothing in the app answers a question: the question is kept
  on the phone, and the first card that answers it shows under it in
  "Questions you asked".
- **141d** said every change of mind "shows in Your journey". It does not;
  the line under the summary is one that is true.
- **141a**'s chains were written for the prototype. A chain is the
  section's own words, with the source its answers come from, shown at the
  bottom with the cards that go further.
- **141c**'s ruler ran from the first light. By default it runs through the
  six ages the bank tags its cards with; a section adds stops further back
  with cards of their own, as the example does to the first light.
- **141f** and **141c** were shelves of the build's own Explore until
  17 October, when the owner had them taken out. They are back only as
  blocks that a server places, drawn anew; nothing in the build shows them.

## Open

- The core family names the blocks of 140b, 140d and 141b; those screens get
  their examples with them.
- A block asks Explore for a pool with a limit of its own and picks from
  it: what a section with no `source` gives, and that a limit passed wins
  over a section's own, are the engine's to keep.
- The notes above are new events for `TRACKING.md`.
