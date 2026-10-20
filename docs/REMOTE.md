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

`remote/explore.json`: the sections of Explore, in order, each with its
block, its size, its source of cards, its audience. Null keeps the build's own
Explore.

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
