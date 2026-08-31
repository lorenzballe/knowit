# The card writer

Everything that must not run on a phone.

The app used to be its content: 170 cards compiled into the binary, five a
day, about eight weeks of material and then nothing. This is what replaces
that — a generator that writes cards into Firestore, which the app reads.

## Why it is a server

Two reasons, and only the first is about money.

**The key.** An API key inside a shipped app has been given away. It can be
pulled out of the binary by anyone who wants it, and the bill for a key
somebody else is holding has no ceiling. `ANTHROPIC_API_KEY` is a Cloud
Functions secret; it is mounted into two functions and exists nowhere else.
Not in this repository, not in a build, not in anything the client fetches.

**The claim.** A card says which answer is right. The app's whole promise is
that it will tell a reader when they are wrong, so a card that any client
could write is a claim that anyone could plant. `firestore.rules` lets every
signed-in reader read `cards/` and nobody write it; this code writes with the
Admin SDK, which is not subject to those rules.

## What a run does

```
demand  ×  supply   →  briefs  →  draft  →  check  →  review  →  publish
```

**Demand** is the sum of what readers' own taste models say they like —
`topic:space, +0.6` and so on, read off the `taste` field of each reader
document. Each reader is normalised to contribute the same total, so somebody
who has used the app for a year does not outvote a hundred people who joined
last week. Nothing a reader wrote or answered is read: a taste model is
already an aggregate, and only facet totals leave the function.

**Supply** is how many cards the catalogue already holds of each kind. The gap
between the two is what gets written, so the catalogue grows toward what
readers have been shown to want rather than toward what somebody guessed.

**Draft** asks for six cards at a time. Thirty at once produces thirty cards
that resemble each other, because everything after the tenth is written in the
shadow of the first ten.

**Check** is `checkCard` — everything that can be decided without knowing
anything about the world. A graded card with no worked solution, an option
index that is not an option, the right answer being conspicuously the longest,
"all of the above", a question that contains its own answer. These are the
mistakes a card writer actually makes.

**Review** is a second call, with the answers visible and no memory of having
written them. It re-does the arithmetic and checks the source. The model that
wrote a card is the worst judge of whether its marked answer is the only
defensible one, which is the same argument as code review and worth the same
money. A review that does not run fails the whole batch closed: an unreviewed
card is not a reviewed one.

**Publish** writes what survived. What did not is kept in `rejected/` with the
reason — a generator whose failures are invisible cannot be improved, and
nothing in there is ever served.

## Setting it up

```sh
cd functions
npm install
npm test          # the checks and the planner, no network, no key needed

firebase functions:secrets:set ANTHROPIC_API_KEY
firebase deploy --only functions,firestore:rules
```

`growCatalogue` then runs at 03:00 UTC daily. To run it by hand, give
yourself the claim the callable checks for:

```js
await admin.auth().setCustomUserClaims(uid, { editor: true });
```

and call `writeCards({ count: 6 })`. It is gated on that claim rather than on
being signed in because every reader has an account, so "signed in" is not an
authorisation — and this endpoint spends money.

## Costs

A run of twelve cards is two drafting calls and two review calls. The
editorial standard is the long half of every request and never changes within
a deploy, so it is cached; the brief is the short half and is not.

## Keeping both sides of the contract

`src/card.ts` and `lib/data/card_codec.dart` describe the same card. Neither
can prove the other, so both validate on arrival: the server refuses to
publish a card that fails, and the app refuses to show one — a cache is
written by an older build than the one reading it, and a card that reaches a
reader with no explanation behind it is the one failure this whole pipeline
exists to prevent.
