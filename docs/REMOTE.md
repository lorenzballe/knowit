# The app, from the server

Almost everything a reader sees can change without a release: the words, the
shelves of Explore and their sizes, which switches are on and for whom, and
the cards themselves — whose insides can be anything at all. This page is
how that works, and the rules every part keeps.

## The road

```
remote/                     the sources, reviewed like code
  app.json                  update gate, switches, tunables
  strings/<language>.json   words that replace the build's own
  explore.json              the shelves of Explore (null: the build's own)
  looks.json                how cards look (null: as built)
tool/remote/check.py        every part checked by tool/remote/parts/<part>.py
tool/remote/bundle.py       one document, written twice from the same bytes:
  lib/remote/embedded_config.dart   baked into the build (offline, first run)
  web/remote/config.json            published with the site, beside
  web/remote/version.json           a note naming it by hash
```

The deploy (`.github/workflows/deploy.yml`) checks the sources, refuses a stale
copy, and publishes `web/remote/` at `https://astutetheapp.com/remote/`. A
change merged to `main` reaches the site with the next deploy.

The phone (`lib/remote/remote.dart`):

- **restores** the last document it downloaded, before anything reads a part;
- **refreshes** at every launch and every return to the app — never more than
  twice a minute — asking the note first and the document only when the note
  names another;
- **takes a newer document up the moment it arrives**, and bumps
  `Remote.revision`; the app's root listens and redraws everything.

The cards travel the bank's road instead (`tool/cards/`, `web/cards/`), and are
adopted at the next start: a deck on the table is never re-dealt.

## The rules every part keeps

1. **The build's own app is the floor.** With no document, a broken one, or
   none of a part, the app is exactly what the build shipped. A part the
   server sends as null means "as built".
2. **Refuse item by item, never whole.** A shelf, a look, a string, a switch
   this build cannot read is skipped; the rest of its part still applies.
3. **An older build skips what it does not know.** A block type, a look, a
   rule key it has never heard of is passed over silently. Anything that needs
   a newer build says so with `{"minBuild": n}` in its audience.
4. **Checked before it ships.** Every part has a checker in
   `tool/remote/parts/`; nothing is bundled while one fails. A checker's
   problems name the file, the item and what to change.
5. **Seen before it ships.** Anything a reader will look at is rendered on
   three phones (`tool/*_shots.dart`, `tool/cards/card_check.cjs`) and looked
   at, as with the cards.

## Who a thing is for, and when

Anything in the document can carry an `audience`, read by `Audience.allows`
(`lib/remote/remote.dart`). Every key must hold; a key this build does not
know makes the rule false.

| Key | Holds when |
|---|---|
| `platforms` | the platform is listed: `ios`, `android`, `web` |
| `minBuild`, `maxBuild` | the build number is in range, inclusive |
| `languages` | the app's language is listed: `it`, `en`, … |
| `plus` | `true`: Astute+ only; `false`: free plan only |
| `minDays`, `maxDays` | days since the install are in range, inclusive |
| `from`, `until` | today, on the phone's calendar, is in range: `2026-10-20` |
| `weekdays` | today is listed; Monday is 1, Sunday 7 |
| `hours` | the hour is in `[from, to)`; `[22, 3]` runs across midnight |
| `rollout` | the phone is in the first n% (0–100), split by `salt` or the thing's own name |
| `all`, `any`, `not` | lists of rules, and one rule negated |

Experiments: `Audience.variantOf(name, variants, weights)` gives each phone
one variant, the same every time.

## The parts

### `app` — gate, switches, tunables

Owned by the gate and switches work (see its section once merged).

### `strings` — words

`remote/strings/it.json` is `{ "arbKey": "Testo" }`. Keys and placeholders
must match `lib/l10n/app_en.arb`.

### `explore` — the shelves

`remote/explore.json` is `{"sections": [...]}`: Explore from top to bottom,
each section drawn by a block (`lib/explore/`). Null, as committed, keeps the
build's own Explore — which is the same kind of list, drawn by the same engine
(`lib/explore/blocks/core/own_explore.dart`), and the same list as a document
in `remote/examples/explore-today.json`. Copied to `remote/explore.json`, that
example draws exactly what null draws: it is where changing Explore starts.
`remote/examples/explore-gallery.json` shows every core block at every size;
docs/explore/core.md is their catalogue.

A section:

| Field | What it says |
|---|---|
| `id` | its own name, once in the list: what its shelf and its cards are measured under (`explore shelf seen`, `card shown`, `explore noted`) |
| `block` | which block draws it (docs/explore/README.md, core.md) |
| `title`, `subtitle` | its words: one string for every language, or one per language with `en`, which every other falls back on |
| `source` | where its cards come from (below) |
| `size`, `style`, `limit` | what its block reads: the catalogue says which |
| `audience` | who it is for, and when (above), split by the section's id |
| `gap` | the room above it, 0 to 120 points; 24 unless its block says otherwise |

Kept item by item: a section that cannot be read, whose id is taken already,
aimed at somebody else, drawn by a block this build does not know, or with
nothing to show for this reader is left out — the room above it too — and the
list stands; a block that fails is left out and reported. A part that is not a
list of sections is the build's own Explore.

A card block takes its cards from `source`, narrowed to the subject chip in
view; an unknown source, or one with nothing in it, gives no cards and no
section:

| `source` | The cards |
|---|---|
| `{"shelf": "today"}` | a shelf of the server's Explore as Explore deals it — `today`, `asking`, `topWeek`, `topMonth`, `loved`, `mine`, `forYou`, `local` — and the phone's own before the server has answered (`forYou` only from the server) |
| `{"ids": ["space-moon-dust-3"]}` | those cards, in that order |
| `{"query": {…}}` | the bank, worked out on the phone: `subjects` (keys), `formats` (`read`, `pickOne`, `number`, `estimate`, `debate`, `trueOrFalse`, `diagram`, or a scene's kind: `slider`, `story`…), `difficulty`, `unread`, `perSubject` (2), `limit` (12), `seed` — `day` (the default), `week` or `fixed`: the same pick on every phone for the same seed and section, apart from what each reader has read |
| `{"mine": "saved"}` | the reader's own: `saved`, `liked` (newest first), `due` (came back to be answered) |

One thing on weekdays and another at the weekend, the top list moved under the
questions, half the readers given one card across the page instead of today's
shelf, a count of the days to an eclipse that is gone the day after:

```json
{"sections": [
  {"id": "today", "block": "today", "gap": 0,
   "audience": {"not": {"rollout": 50, "salt": "hero-test"}}},
  {"id": "today-hero", "block": "hero", "size": "xl", "gap": 0,
   "source": {"shelf": "today"},
   "audience": {"rollout": 50, "salt": "hero-test"}},
  {"id": "asking", "block": "asking"},
  {"id": "top", "block": "top"},
  {"id": "weekday-quote", "block": "text", "kind": "quote", "text": {"en": "Look twice.", "it": "Guarda due volte."},
   "audience": {"weekdays": [1, 2, 3, 4, 5]}},
  {"id": "weekend-mosaic", "block": "bento", "source": {"query": {"seed": "week"}},
   "audience": {"weekdays": [6, 7]}},
  {"id": "eclipse", "block": "countdown", "to": "2027-08-02", "subject": "space",
   "label": {"en": "to the total eclipse over southern Spain", "it": "all'eclissi totale sul sud della Spagna"},
   "audience": {"until": "2027-08-02"}},
  {"id": "offer", "block": "promo", "audience": {"minDays": 3}}
]}
```

A newer document is drawn the moment it is taken up, and each section is kept
by its id, so what is on screen stays where it is. The checker reads every
section (`tool/remote/parts/explore.py`) and each family its own blocks
(`explore_blocks/`): sources against the bank — a card that is not there, is
retired or is about a place; a query that finds nothing — and, for the core
blocks, a box too small to set a question whole on a 375-point phone.
`flutter test tool/explore_shots.dart` photographs today's Explore and the
gallery on three phones, at night and on paper.

### `looks` — how native cards look

Reserved; null today.

### Free cards

A card whose inside is a web page made with the card kit
(`docs/cards/kit/`), shown inside the native card frame. It travels in the
bank like every card.

## Changing something

1. Edit the sources under `remote/` (or the card in `tool/cards/bank/`).
2. `python3 tool/remote/check.py`, then `python3 tool/remote/bundle.py`.
3. Render what changed on three phones and look at it.
4. Commit, open the pull request, merge: the deploy publishes it, and phones
   take it up at their next launch or return.
