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

## Deploying it

Once, in the Firebase console, put the project on the **Blaze** plan —
functions do not run on Spark — and enable Cloud Functions, Cloud Build and
Artifact Registry when the first deploy asks. Then, from the repository:

    npm --prefix functions run build
    firebase deploy --only functions,firestore:rules,firestore:indexes

`firebase.json` at the root names the codebase, the runtime and the rules.
The first deploy of a scheduled function also creates its Cloud Scheduler
job. To deploy from CI, add a service account key as a repository secret
and run the same command with `FIREBASE_TOKEN` or `GOOGLE_APPLICATION_CREDENTIALS`
set; the workflow `cloud-check.yml` runs the tests but does not deploy.

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
