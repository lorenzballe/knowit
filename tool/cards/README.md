# The cards

Where the app's content comes from, and how it grows without a release.

```
tool/cards/
  bank/<topic>/<id>.json   one file per card — the source of truth
  editions.json            the question of the day, by edition, frozen
  RULES.md                 the system prompt: how a card is written
  schema.json              the card's shape
  banned.txt               material a card may not be built on
  check.py                 the gate
  generate.py              the model, the gate, the critic, the files
  bundle.py                bank → lib/data/embedded_bank.dart + web/cards/cards.json
  test_cards.py            the pipeline without the model
```

## The loop

1. **03:00, GitHub Actions** (`.github/workflows/cards.yml`) borrows a
   machine and runs `generate.py --plan --count 20`.
2. The **plan** reads the bank and asks for what it is short of: every subject
   towards 40 reads, 20 graded questions and 3 debates; every principle
   towards 8 cards; hard cards at most 15% of the ones that ask.
3. For each request the **model** (`claude-opus-5`) gets `RULES.md`, the
   blacklist and six cards from the bank as the house style — one cached
   system prompt — and a brief: topic, kind, principle, every question the
   topic already asks, every context the principle has been met in. It
   returns JSON in the card schema.
4. The **gate** (`check.py --strict`) refuses anything mis-shaped: word
   counts, options, a real reference, the listicle, a twin of a card already
   in the bank. The model gets one round to fix what the gate named.
5. The **critic** is a second call with the opposite brief and web search:
   open the reference, redo the numbers, defend the wrong options, look for
   the textbook instance. `pass`, `fix` (one correction, returned whole) or
   `reject`.
6. What survives is written to `bank/<topic>/<topic>-<date>-<n>.json` with
   the date it was written, the bank is gated again, `bundle.py` extends the
   calendar and regenerates both copies, and a **pull request** opens with
   the cards listed in its body.
7. A person reads the pull request. **Merging is the review.** The deploy
   workflow then publishes `web/cards/cards.json`; the app downloads it at
   start, keeps it, and deals from it the next morning.

Nothing about a card is decided on a phone. The phone downloads a file.

## Running it by hand

```
pip install -r tool/cards/requirements.txt
export ANTHROPIC_API_KEY=...            # never in the repo, never in the app

python3 tool/cards/check.py                          # the bank passes its gate
python3 tool/cards/generate.py --plan --count 20 --dry-run     # what would be asked
python3 tool/cards/generate.py --topic space --kind pickOne --principle baseRate
python3 tool/cards/generate.py --plan --count 5 --fake         # the plumbing, no model
python3 tool/cards/bundle.py                         # after any change to the bank
python3 -m unittest discover tool/cards              # the pipeline's own tests
```

`bundle.py --check` fails when either copy is stale, so a pull request that
edits a card by hand has to run the bundler too.

## What a card costs

One card is roughly a writing call and a critic call, both against a cached
system prompt: about 15–25 cents at Claude Opus 5 rates, printed as a receipt
at the end of every run and in the pull request body. Twenty a night is
three to five dollars.

## The calendar

`editions.json` maps an edition (day 1 = 1 September 2026) to the id of the
question of the day. An edition, once written, never changes; `bundle.py`
extends it 400 days past today, choosing a graded card that has not been
asked for three quarters of a lap of the graded pool and never less than 60
editions. Before this file existed the app computed the calendar from the
pool on the fly, and a card added anywhere re-dealt every day since the
epoch.

## Retiring a card

Add `"disabled": true` to its file and run the bundler. It is never dealt
again but still opens in a deck that already holds it, and its id is never
reused.
