# Astute's server

What the server does for a reader, and nothing else: reads what they did,
works out what they know and like, deals their day, assembles Explore. It
runs as Cloud Functions for Firebase (2nd gen, Node 22) in `europe-west1`,
against the same Firestore the app writes to.

    src/bank.ts      the bank as the phones download it, and the calendar
    src/rng.ts       the phone's hashes, bit for bit, and a seeded generator
    src/profile.ts   the reader: the backup, the trace and the presence read
                     into a level per subject, a taste, and the mix as leaned
    src/deal.ts      the day, by the phone's own rules, from that profile
    src/explore.ts   Explore for everybody, and the shelf that is one reader's
    src/search.ts    the pool asked a question
    src/serve.ts     one reader against Firestore: read, deal, write, forget
    src/index.ts     the functions themselves, and when they run
    src/*.test.ts    node:test, against the bundled bank; no project needed

## What runs

| Function          | When                     | What                                                                 |
|-------------------|--------------------------|----------------------------------------------------------------------|
| `dealDay`         | a phone asks (callable)  | deals `date` for the caller, writes `readers/{uid}/days/{date}`, returns it |
| `search`          | a phone asks (callable)  | the pool searched, up to 30 cards whole                              |
| `nightly`         | every hour               | every reader here in the last 14 days: their local today (and from 17:00 their tomorrow) dealt if missing; their own shelf once a day; the trace older than 21 days cleared |
| `buildExplore`    | every hour at :05        | `explore/latest` from the counts: today's shelf, the top of the week and month (closed days), loved since the start |
| `onReaderDeleted` | `readers/{uid}` deleted  | everything under it and `presence/{uid}` deleted                     |

The rules (`../firestore.rules`) let no phone write a day, a profile or
Explore. What the server dealt is what the server dealt.

## What it reads

- `readers/{uid}` — the backup the phone keeps (`lib/sync/reader_snapshot.dart`).
- `readers/{uid}/activity/{UTC day}` — the trace (`lib/sync/trace.dart`): the
  gestures, compacted. The last 21 days.
- `presence/{uid}` — when the reader was last here, their clock's offset,
  whether they hold Astute+.
- `tallies/{day}`, `totals/{shard}` — the counts, for Explore.
- The bank: `data/bank.json`, copied from `web/cards/cards.json` at build,
  and the site's newer one when `cards/version.json` names it.

## Running it

    npm install
    npm test                       # builds, then node --test
    npm run serve                  # the emulators, functions and Firestore

The tests need no project: `data/bank.json` is copied from the repository
by `npm run data`, and `data/genres.json` is dumped from
`lib/data/genres.dart` by `tool/cards/genres.py`.

## The numbers

Every constant is one line with its reason beside it, in the source. The
ones that shape a reader's day:

| Where        | Number                 | Why                                                                                    |
|--------------|------------------------|----------------------------------------------------------------------------------------|
| profile.ts   | `TASTE_LEAN` ±0.08     | a like or a throw on: one gesture moves a tag by less than a tenth, ten of them by most of the clamp |
| profile.ts   | save/said/share +0.05, open +0.03, read +0.02, flip +0.01 | the smaller the gesture, the smaller the move: a flip is curiosity, a save is a decision |
| profile.ts   | dwell +0.02 / −0.03    | a card held past twice the median took; one thrown on in under a third did not — and a throw says more |
| profile.ts   | unopened −0.01         | shown on a shelf and never opened: the weakest signal, but the most frequent            |
| profile.ts   | `DWELL_FLOOR` 5        | under five timed cards the median is a coin; dwell says nothing until then              |
| profile.ts   | `RECENT_MS` 14 days    | the second week of the trace counts half; the first week is what the reader is now      |
| profile.ts   | `CLAMP` 0.6            | no tag ever more than ±0.6: a hundred likes must not make one strand the whole deck     |
| profile.ts   | `RECENT_STRAND_DAYS` 7 | a strand looked at this week is met again later, not tomorrow                           |
| deal.ts      | `RECENT_STRAND_WEIGHT` 0.5 | ...at half its weight, not none: a liking is still a liking                          |
| deal.ts      | `EXPLORER_SHARE` 0.5   | about every other day one read is from a strand never met, on level alone; seeded by reader and date, so every server agrees |
| deal.ts      | fit 1.5/1.0/0.7, 0.5–3.0 | the phone's own ladder (`lib/data/pills_repository.dart`): a read below the level first, a hard ask only once the level is there |
| deal.ts      | `OWN_WELCOME` 4, `OWN_FREE` 2, `OWN_REWARDED` 3, `WELCOME_DAYS` 7 | the welcome week, the free day after it and the morning after a week kept; the rest of a free day at random (`dealRandom`, see the root README) |
| serve.ts     | `TRACE_DAYS` 21, `ACTIVE_DAYS` 14, `PREPARE_TOMORROW_FROM` 17 | three weeks of trace kept, two weeks of absence before a reader is left alone, tomorrow dealt from five in the afternoon |
| explore.ts   | the crowd, `popularity` | the launch crowd, the phone's numbers bit for bit (`lib/sync/tally.dart`)              |

The draw itself is an exponential race (`-ln(u) / weight`), so every card
keeps a chance in proportion to its weight and no two readers with the same
profile get the same day. Nothing is a hard rank.

## Deploying it

Once, in the Firebase console, put the project on the **Blaze** plan —
functions do not run on Spark — and enable Cloud Functions, Cloud Build and
Artifact Registry when the first deploy asks.

**From GitHub** (`.github/workflows/cloud-deploy.yml`): add one repository
secret, `FIREBASE_SERVICE_ACCOUNT`, holding the JSON key of a service
account on the project (Firebase console → Project settings → Service
accounts → *Generate new private key* gives the default one, which has
enough), then run *Cloud deploy* from the Actions tab. It runs the tests
first and deploys the functions, the rules and the indexes; nothing
deploys on a push.

**From a machine** that is logged in (`firebase login`):

    npm --prefix functions run build
    firebase deploy --only functions,firestore:rules,firestore:indexes

`firebase.json` at the root names the codebase, the runtime and the rules.
The first deploy of a scheduled function also creates its Cloud Scheduler
job. The workflow `cloud-check.yml` runs the tests on every push but does
not deploy.

## What it costs

Per active reader per day, roughly: three reads to build the profile plus
one per day of trace (about 15), one day written, one shelf written, and a
function invocation or two. At ten thousand daily readers that is well
inside the free quota for invocations and a few dollars a month for
Firestore; at a hundred thousand, a few hundred. Nothing here reads the
whole reader base except the hourly `presence` query, which is one query.

## What it does not do yet

- **Learn from everyone.** The profile is the reader's own doing. "Readers
  who kept this also kept that" needs co-occurrence over every reader's
  kept cards, which is a nightly aggregation into a `cokept/{card}`
  collection and a term in `ownCards`' weight. The trace and the totals
  already hold everything it needs; it is worth building once there are a
  few thousand readers to learn from.
- **Verify Astute+.** The phone says whether the reader holds it, in the
  presence. A RevenueCat webhook into `readers/{uid}/profile/entitlement`
  would make the server sure; until then a phone that lied would get four
  more of its own cards and nothing else.
