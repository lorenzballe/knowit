# The app, from the server

Almost everything a reader sees can change without a release: the words, the
shelves of Explore and their sizes, which switches are on and for whom, and
the cards themselves — whose insides can be anything at all. This page is
how that works, and the rules every part keeps.

## The road

```
remote/                     the sources, reviewed like code
  app.json                  update gate, switches, tunables, experiments
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

### `app` — the gate, switches, numbers and experiments

`remote/app.json`, every key optional, null or `{}` for none:

```json
{
 "gate": {
  "minBuild": {"ios": 7, "android": 7},
  "blocked": [5, 6],
  "suggestBuild": {"ios": 8, "android": 8},
  "pause": {"on": false, "audience": {"platforms": ["android"]}},
  "message": {"pause": {"it": "Torniamo entro un'ora.", "en": "Back within the hour."}}
 },
 "flags": {"review.ask": {"on": false, "audience": {"maxBuild": 9}}},
 "tunables": {"push.askGapDays": 2, "push.times": ["07:45", "13:00", "21:30"]},
 "experiments": {
  "push.firstAsk": {"variants": ["cameBack", "firstDay"], "weights": [1, 1], "audience": {"rollout": 20}}
 }
}
```

The build number every rule is measured by (`Remote.build`, the `+n` of the
version: CFBundleVersion, versionCode) is read in `main()` before anything
else, by `lib/remote/build_number.dart`; a phone that cannot say is build 0,
which no `minBuild` lets in and no gate sends to the store.

#### The update gate (`gate`)

`lib/remote/gate.dart` decides it; `lib/screens/gate_screen.dart` shows it.

- **Update** — `minBuild` per store (`ios`, `android`) and `blocked`, a list
  of builds for every store or one per store (`{"android": [12]}`): a build
  below the one or named in the other gets a full screen, "Update Astute",
  with one button to its store page (`lib/store_links.dart`, the site's own
  addresses, held to `tool/site/chrome.py` by `tool/remote/test_app.py`).
  Nothing of the app is built under it.
- **Suggest** — `suggestBuild` per store: a sheet, "A new version of Astute
  is ready", Update or Later, once for each build suggested (the phone keeps
  the highest it was shown, `knowit.updateSuggested`), at a moment that costs
  the reader nothing: the tabs on top, nothing else asked in the sitting,
  before the first card is thrown or once the day is done. Nothing else is
  asked in the sitting it rises in.
- **Pause** — `{"on": true, "audience": {…}}`: a full screen, "Astute is
  taking a short break", for an emergency the app cannot ride out (a backend
  that is down, a release that does damage), with Try again, which asks the
  server at once. A pause aimed by the plan or the days since the install
  waits for the app's state to be read; any other holds from the first frame.
- **Message** — the server's own line for a screen (`hard`, `soft`,
  `pause`), by language, in place of the build's line under the title; plain
  text, 300 characters at most. A language it leaves out keeps the build's
  line. Titles and buttons are words like any other (`strings`).

An update goes before a pause: it is the one thing the reader can do about
either. The gate is decided before the first frame — `main()` restores the
document kept from the last run and reads the build before `runApp` — so it
holds on a phone that is offline and on one whose state never finishes
loading, and it sits above the navigator, so nothing the app pushes is
drawn over it. A newer document takes effect the moment it arrives: a gate
closing over a running app keeps it alive underneath and asks it nothing;
every return to the app asks the server again, so a gate lifted there lifts
on the phones. The web app has no store and is never sent to update; a pause
can reach it.

**Careful:** a `minBuild` above the newest build in the store locks every
reader out until the document is put right, and no checker can know which
build the store has. Check it against App Store Connect and the Play Console.

Changing it from the server:

- builds before 7 can no longer be used: `"gate": {"minBuild": {"ios": 7, "android": 7}}`;
- Android build 12 loses a day of reading, say why:
  `"gate": {"blocked": {"android": [12]}, "message": {"hard": {"it": "La 12 perde un giorno di lettura: la nuova lo tiene.", "en": "Build 12 loses a day of reading: the new one keeps it."}}}`;
- the backend is down on Android for an hour:
  `"gate": {"pause": {"on": true, "audience": {"platforms": ["android"]}}}`, and
  `"on": false` (or no gate at all) to lift it.

#### Switches, numbers, experiments (`flags`, `tunables`, `experiments`)

`lib/remote/knobs.dart`. Every knob is declared where it is read, as a
constant naming it with the build's own value and range — a `RemoteFlag`,
`RemoteNumber`, `RemoteTimes` or `RemoteExperiment` — read through
`Flags.on`, `Tunables.number` (`.string`, `.list`) and `Experiments.variant`.
A document that says nothing of a knob, or something this build cannot take
(the wrong type, out of its range, a variant it cannot show), leaves it as
built, one knob at a time.

- **Switches** — `{"name": false}` for everybody, or `{"name": {"on": false,
  "audience": {…}}}` for the readers the audience allows (split by the
  switch's own name); everybody else keeps the build's.
- **Numbers** — `{"push.askGapDays": 2}`, inside the knob's range.
- **Experiments** — `{"name": {"variants": [...], "weights": [...],
  "audience": {…}}}`: each reader the audience allows (split by the
  experiment's name) is given a variant by `Audience.variantOf`, the same one
  every time; weights are equal when left out, and one variant alone gives it
  to the whole audience. The variant is read at the moment the variants part
  ways, and only then; the first time in a sitting it says so to PostHog —
  `experiment exposed`, and `experiment_<name>` on every later event and on
  the profile (docs/TRACKING.md, §6.13).

The knobs this build reads:

| Name | Kind | Build's own | Range | What it changes | Read in |
|---|---|---|---|---|---|
| `push.ask` | switch | on | — | the reminder sheet, and the system's prompt behind it | `AppState.shouldAskForPush` |
| `account.offer` | switch | on | — | the account's sheet after a finished day | `AppState.shouldOfferAccount` |
| `place.ask` | switch | on | — | the place's sheet after a finished day (Explore and Profile still ask when the reader asks them to) | `AppState.shouldAskForPlace` |
| `review.ask` | switch | on | — | the store's rating prompt | `AppState.shouldAskForReview` |
| `push.askGapDays` | number | 3 | 1 to 30 | the days a "Not now" holds the reminder sheet back | `AppState.shouldAskForPush` |
| `push.deferralsAllowed` | number | 3 | 1 to 10 | how many "Not now"s the sheet takes before it stops coming | `AppState.shouldAskForPush` |
| `push.times` | three times | 08:30, 12:30, 19:00 | 05:00–11:00, 11:00–15:00, 17:00–23:00 (the last minute out) | the times the reminder sheet offers, each where its word ("Morning", "Lunchtime", "Evening") stays true | `lib/widgets/reminder_ask.dart` |
| `place.firstAskDay` | number | 2 | 1 to 20 | the finished days before the place's sheet first asks | `AppState.shouldAskForPlace` |
| `place.lastAskDay` | number | 7 | 2 to 30, after `place.firstAskDay` | the finished days before it asks the second and last time (a phone keeps thirty) | `AppState.shouldAskForPlace` |
| `review.streakDays` | number | 7 | 3 to 60 | the days in a row that end in the rating prompt | `AppState.shouldAskForReview` |
| `push.firstAsk` | experiment | `cameBack` | `cameBack`, `firstDay` | whether the reminder sheet comes at the end of the very first finished day, or waits for a reader who came back | `AppState.shouldAskForPush` |

Changing them from the server:

- no rating prompt on Android builds up to 9: `"flags": {"review.ask": {"on": false, "audience": {"platforms": ["android"], "maxBuild": 9}}}`;
- ask about reminders again two days after a "Not now", at 07:45 rather than 08:30:
  `"tunables": {"push.askGapDays": 2, "push.times": ["07:45", "12:30", "19:00"]}`;
- the first-evening reminder for a fifth of readers, half and half:
  `"experiments": {"push.firstAsk": {"variants": ["cameBack", "firstDay"], "audience": {"rollout": 20}}}`.

A new knob is declared beside the code that reads it, and listed in
`tool/remote/parts/app_knobs.json` (what the checker holds documents to), in
`test/remote_knobs_test.dart` (which fails, naming it, while the two differ)
and in the table above (`tool/remote/test_app.py` checks). A knob a newer
build stops reading stays in `app_knobs.json` with `"retired": true` while
older builds still read it.

`tool/remote/parts/app.py` checks the part: known keys only, builds that are
builds, a suggestion above the floor, numbers in range, `place.lastAskDay`
after `place.firstAskDay`, experiments well formed, and audiences whose
every key is one `Audience.allows` knows, holding what it asks for.

### `strings` — words

`remote/strings/<language>.json`, one file for each of the app's thirteen
languages that has any, each the words for some of `lib/l10n/app_en.arb`'s
keys:

```json
{
 "reminderAskTitle": "A che ora te lo ricordiamo?",
 "streakDays": "{n, plural, =1{Un giorno di fila} other{{n} giorni di fila}}",
 "gatePauseTitle": "Astute fa una pausa breve"
}
```

Any string the app shows can be replaced, without a release.
`context.l10n` (`lib/l10n/l10n.dart`) hands out the build's strings with
the server's words in their place — one wrapper per document and language,
`lib/l10n/remote_localizations.dart` — and the strings said with no screen,
the reminders, the trial's warning and the widgets, go through the same one
whenever they are armed again: at every launch and every return. A newer
document redraws every screen that reads a word (`RemoteWordsScope`).

The words are written as the arb files write theirs, and read as
`flutter gen-l10n` reads those (`lib/remote/remote_strings.dart`): `{name}`,
`{n, plural, …}` with the cases gen-l10n knows, mapped as it maps them (`=1`
is `one`), `{x, select, …}`, nested as deep as they go, quotes as plain
quotes; each placeholder is formatted as the build's own code formats it,
numbers through the very NumberFormat the arb names. That is every piece of
ICU the arb files use. The one they do not, a date or time argument
(`{d, date, ::yMd}`), is refused by the checker rather than said differently
from the build.

`tool/remote/parts/strings.py` checks the part: a file per language, named
for one of the thirteen; keys of the template only; no empty words; the very
placeholders the build's string has, every one and no other; a plural on a
number, a select on a string, each with `other` and no case twice. Every
word the build itself ships, in all thirteen languages, passes it. Words
that slip past it and do not read are refused on the phone, one string at a
time: that string is the build's own, every other still the server's.

**Adding an arb key** means three steps, in order: the arb files, then
`flutter gen-l10n`, then `python3 tool/remote/gen_strings.py`, which writes
the wrapper from the template and gen-l10n's class and says when the two
disagree. CI runs it with `--check`, and the wrapper does not compile
without the new key anyway.

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
section. A section with no `source` at all draws from the whole bank, in an
order that turns with the day and is the same on every phone: the families'
blocks pick what they need from it (numbers for a bet, debates for two
halves, a theme for a set).

| `source` | The cards |
|---|---|
| none | the whole bank, in the day's order |
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
bank like every card. There are no blocks to choose from: the page is the
card, made the way the prototypes are made (the `astute-cards` skill,
`docs/cards/CRITERI.md`), and the app keeps only its frame — the shape, the
shadow, the save and share in the corner, the throw.

**What a free card is in the bank.** Two files side by side in
`tool/cards/bank/<topic>/`: the card, `<id>.json`, with every field a card
has, and its page, `<id>.html`. The JSON says what the page needs in `web`:

| key | |
|---|---|
| `kit` | the kit version the page was made with (today 1). |
| `touch` | `taps` or `drags`, below. |
| `label` | what the page shows, in words, for screen readers (20–400 characters). |
| `graded` | `false` for a page that marks nothing. |
| `ground` | `#rrggbb` when the page's ground is not the subject's colour (a night card). |

Any kind may have a web face. A `pickOne` with a page keeps its options in
the JSON: the page sends the option's index, the app records it as it
records a native pick, and a build without the page draws the native card.
The kind `page` is for what options cannot say (a place on an orbit, a
drawing): the page marks the answer itself, and the app keeps it as
`1|what they said` (right), `0|…` (wrong) or `-|…` (nothing to mark), with
the reader's how-sure. A page card is never the question of the day.

**Making one.**

1. Copy `tool/cards/web/template.html`. A page is one `<article
   class="card">` with the card's `data-topic`, a `.q` holding the JSON's
   `question` word for word, and `Kit.single()` at the end. It links only
   the kit: `kit/astute-card.css`, `kit/fonts.css`, `kit/astute-card.js`,
   `kit/vendor/…` (CDN links to what the kit vendors are read as the kit's
   copy). Fraunces, Figtree, JetBrains Mono and Caveat are in `fonts.css`.
2. An asking card answers with `Kit.answer({choice, correct, sure})`; the
   kit's how-sure row (`Kit.sure`) gives the app's five levels. A page can
   also `Kit.flip()`, `Kit.done()` (move on), `Kit.haptic(kind)` and
   `Kit.open(url)` (the reader's browser, http and https only).
3. `Kit.play.card` plays it through as a reader would, for the checker.
   `Kit.onShow.card` draws (it runs again on every resize),
   `Kit.onEnter.card` starts the entrance once the card is on top.
   `Kit.calm` is true when the phone asks for less motion: the end state
   must be the same without it.
4. Leave the corner bottom right to the save and share (`.foot` already
   does). Nothing from the network: no fetch, no outside images, no
   iframes. At most 200 KB, the vendored libraries not counted.

**Checking it.**

- `python3 tool/cards/check.py` — the card and its page together
  (`tool/cards/pages.py`): the page is beside the card, links only the kit,
  asks nothing of the network, says the card's question, answers when the
  card asks, marks `data-drag` when it takes drags, is small enough.
- `node tool/cards/card_check.cjs tool/cards/bank/<topic>/<id>.html [out]`
  — the page as the app shows it, on the three phones' card sizes
  (339×475, 366×606, 394×667), at the start and played through, with
  motion and with less: ready said, the answer the app would record,
  nothing spilling, overlapping, scrolling, under the save and share,
  smaller than 9 px, no script errors, no network. Then look at every
  photograph. `BARE=1` photographs the page without the app's corners, for
  a camera that sets it in the native frame.

**Publishing it.** `python3 tool/cards/bundle.py` puts the page inside the
card as `web.html`, in the app's embedded bank and in `web/cards/cards.json`,
the bundle the phones download and the server deals from (`--today` with the
date of the last bundle keeps the calendar of questions as it was). Commit,
merge: the deploy publishes it, and the server deals it by id like any card.
A build whose kit is older than the card's `kit` keeps the card but never
deals it; `kCardKit` (`lib/models/pill.dart`) and `KIT_VERSION`
(`tool/cards/pages.py`) move together when the kit changes in a way an
older build cannot show.

**How the app shows it.** `CardKit` (`lib/widgets/web/card_kit.dart`) puts
the page together offline: the kit's files from the app's assets, inlined
(fonts and binaries as data URLs), a content policy that refuses the network,
the app's environment and the bridge first in the head. It is loaded into a
web view (`webview_flutter`: WKWebView on iOS, the Android WebView; an iframe
on the web build) behind `WebSurface` (`lib/widgets/web/`), with
`FakeWebSurface` for tests. A deck keeps two pages alive, the top card and
the next, so a card is ready before it comes up; under each page sits a
native poster of the card (its ground, subject, question) until the page
says it is ready, and after six seconds without that the card is shown as a
native read card. A page's clocks (GSAP, CSS animations,
requestAnimationFrame) are held until its card is on top.

**The bridge.** One JSON message at a time each way
(`docs/cards/kit/astute-bridge.js`, `lib/widgets/web/page_messages.dart`).
The page says `ready`, `answer`, `flip`, `tap` (a tap the page did not use:
the card turns over, as a native one does), `done`, `haptic`, `open`,
`zones` (where it wants the finger), `pan` (web build only: a drag that is
not its own) and `error`. The app says `env` (dark, language, less motion,
sound, touch, platform, size, the corner to leave, the subject, the line and
the chip a native card carries), `show` and `hide`.

**Touch.** With `taps`, a tap goes to the page; a drag anywhere throws the
card and a long press keeps it, as on any card. With `drags`, a touch that
starts inside one of the page's zones (anything marked `data-drag`, or held
with `touch-action: none`) is the page's; everywhere else the deck keeps
its throw. A page that has taken the finger lets the reader move on with
`Kit.done()`, or with the native affordance outside its zones; after the
answer a page usually gives its zones back (`data-drag="off"`).

**Before launch, and after.** A build older than free cards refuses a
bundle that holds a `page` card as a whole (a bundle is refused whole when a
card cannot be drawn), and keeps the bank it had. Once there are readers on
such builds, publish free cards as native kinds with a web face, or teach
the bank to skip a card it cannot read.

## Changing something

1. Edit the sources under `remote/` (or the card in `tool/cards/bank/`).
2. `python3 tool/remote/check.py`, then `python3 tool/remote/bundle.py`.
3. Render what changed on three phones and look at it.
4. Commit, open the pull request, merge: the deploy publishes it, and phones
   take it up at their next launch or return.
