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

`remote/explore.json`: the sections of Explore, in order, each with its
block, its size, its source of cards, its audience. Null keeps the build's own
Explore.

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
