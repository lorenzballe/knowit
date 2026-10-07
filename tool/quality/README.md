# How good the cards are

Five thousand cards written with a model's help will have mistakes in them.
The generator stops most of them before they ship (`tool/cards`: a page that
was read, a quote found on it by a program, the gate, the critic), and this
folder is everything after that: knowing how good the critic is, deciding
which new cards a person reads, hearing from the readers, and checking the
cards that are already out.

    confidence.py   how far a new card can be trusted without a person, and why not more
    route.py        after the night: the doubtful cards and a sample of the rest to a person
    review.py       the cards waiting for a person, as an issue checklist, and what a tick does
    mutate.py       errors planted in good cards: a figure off by ten, the wrong option marked right
    evalset.py      the set the critic is measured on, and how its answers are scored
    evals.py        the critic asked about that set, exactly as the night asks it
    recheck.py      the cards already out, checked again: the reported, the disputed, the stale
    stats.py        the readers' scorecard, for a person
    test_quality.py all of it, without a key

## The loop

1. **The night writes** (`.github/workflows/cards.yml`, 02:17 UTC). The
   generator files every card that passed the gate and the critic, and
   writes down how each one got through (`generate.py --outcomes`).
2. **Each card is scored** (`confidence.py`), out of a hundred: the critic
   passing it on the first read, the quote found on the page word for word,
   the first source holding, a fact that will not change — or not. A card
   the critic had to correct, written from the third site tried, whose quote
   could not be checked because the page was a PDF, on a figure that moves
   every year, is a different bet, and the score says so and says why.
3. **The doubtful go to a person** (`route.py`): under 75, and one in ten of
   the rest as a spot check, leave the bank for `tool/cards/review/`. The
   rest go out with the night's pull request — merged by hand, or by itself
   when the repository variable `CARDS_AUTOMERGE` is `true`.
4. **A person reads them** in the issue labelled `cards-review`, each card
   shown whole with **Publish** and **Drop** under it. A tick runs
   `.github/workflows/review.yml`: Publish puts the card in the bank with
   today as its `checked` date, Drop deletes it, the bank is gated again,
   and the site deploys.
5. **The readers say** (`lib/sync/reports.dart`): *Report a problem* under
   every card's source — a fact is wrong, the answer marked right is wrong,
   the source does not say it, it is confusing, a typo, something else, and
   a line if they want.
6. **The server counts** (`functions/src/scorecard.ts`, daily): every card's
   answers, right and wrong and how surely, the options picked, the time on
   it, the likes, saves, shares and throws, the reports. A card answered
   right far more or less often than its label says is flagged; so is one
   whose marked answer the crowd overwhelmingly rejects, one readers throw
   down, one they keep. Three readers saying a card is untrue take it out of
   the deal until somebody has checked it.
7. **Once a month the cards that are out are checked again**
   (`recheck.py`, `.github/workflows/recheck.yml`): the quarantined first,
   then the disputed and reported, then the ones whose answer can change —
   shelf life *months*, last checked three months ago; *years*, a year ago.
   The critic is told it is checking a live card. A card that holds gets
   today as its `checked` date, which also answers the reports made before
   it and lets it back into the deal; a correction waits in the review
   issue; a card that no longer holds is retired. A person merges it.
8. **The critic is measured** (`evals.py`, `.github/workflows/evals.yml`,
   monthly and whenever `RULES.md` changes): good cards from the bank, and
   the same kind of card with one error planted, every kind equally often.
   It says how many planted errors the critic stopped and how many good
   cards it threw out, by kind of error, with every miss listed. That is the
   number that should move the weights in `confidence.py` and decide whether
   `CARDS_AUTOMERGE` is safe to turn on.

## The knobs

Repository variables (Settings → Secrets and variables → Actions → Variables):

| Variable | What it does | Unset |
|---|---|---|
| `CARDS_PER_NIGHT` | how many cards the night asks for | the nightly run is off; it still runs by hand |
| `CARDS_BUDGET` | dollars a night may spend; past it the run stops before the next stage and files nothing half-checked | a dollar and a half a card |
| `CARDS_AUTOMERGE` | `true`: the confident cards merge and deploy themselves | a person merges the night's pull request |

All three runs need the `ANTHROPIC_API_KEY` secret; without it each says so
in its summary and stops. A card costs roughly half a dollar to a dollar on
Opus at batch prices, most of it searches; a re-check of twenty cards and
an eval of forty-eight a few dollars each.

## Running it here

    python3 -m unittest discover -s tool/quality -p "test_*.py"
    python3 tool/quality/evals.py --fake --per-kind 2          # the plumbing, a canned critic
    python3 tool/quality/evals.py --per-kind 4 --batch         # the real thing, with a key
    python3 tool/quality/recheck.py --dry-run                  # which cards are due, and why
    python3 tool/quality/stats.py                              # the readers' scorecard

## What stays private

The scorecard the tools read is numbers per card and nothing about who. A
reader's note is kept with their account and copied into `quality/notes`
in Firestore, which no phone may read: it is for the person fixing cards,
in the Firebase console, and it never goes into an issue, a pull request or
a model's prompt — this repository is public.
