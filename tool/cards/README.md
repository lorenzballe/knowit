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
  genres.py                the genres and strands, read off lib/data/genres.dart
  sources.py               domains, source kinds, and the verbatim check on a quote
  domains.txt              sites blocked, sites never a reference, sites trusted per subject
  generate.py              scout, reader, writer, gate, critic, files
  tag.py                   tags for cards that have none
  bundle.py                bank → lib/data/embedded_bank.dart + web/cards/cards.json
  test_cards.py            the pipeline without the model
```

## The loop

1. **03:00, GitHub Actions** (`.github/workflows/cards.yml`) borrows a
   machine and runs `generate.py --plan --count 20`.
2. The **plan** reads the bank and asks for what it is short of: every subject
   towards 40 reads, 20 graded questions and 3 debates; every principle
   towards 8 cards; hard cards at most 15% of the ones that ask. Inside a
   subject the card lands on its thinnest **strand** — every strand towards
   two cards before any has a third — and a graded card is offered the three
   thinnest principles rather than one, so the writer takes the one the
   strand has a real instance of.
3. The **scout** (`claude-opus-5`, web search, eight searches) is given the
   strand, the kind of card, the principles on offer, the kind of source
   the subject has least of and the sites its readers trust first, and
   returns three finds: a claim, its figures, the page that states it, the
   kind of source, and why it is not the textbook instance. Three sites,
   three kinds. List sites are blocked at the tool; Wikipedia may lead to a
   source and is never one.
4. The **reader** (web fetch, that one site) opens the first find's page
   and copies the passage that states the claim, verbatim, at most forty
   words. A program then looks for the passage on the page the tool
   brought back: not there, and the find is dropped and the next is read.
   A page that is not plain text (a PDF) cannot be checked this way and the
   pull request says so.
5. The **writer** gets `RULES.md`, the blacklist, the house style and every
   strand — one cached system prompt — the brief, and the verified find:
   claim, source, page, kind, passage. It writes the card from the passage
   and nothing else, tags included. Every figure in the card is in the
   passage or follows from it by arithmetic shown in the steps.
6. The **gate** (`check.py --strict`) refuses anything mis-shaped: word
   counts, options, the listicle, a twin of a card already in the bank, a
   tag outside its vocabulary, a strand that is not under the subject, a
   reference that is not the page, a site cited twice on one strand. The
   writer gets one round to fix what the gate named.
7. The **critic** is the opposite brief, with search and the page: redo
   the numbers against the passage, defend the wrong options, look for the
   textbook instance, read the tags. `pass`, `fix` (one correction,
   returned whole) or `reject`.
8. What survives is written to `bank/<topic>/<topic>-<date>-<n>.json` with
   the date, the source kind and the quote, the bank is gated again,
   `bundle.py` extends the calendar and regenerates both copies, and a
   **pull request** opens with the cards, their strands, their sites and
   the receipt in its body.
9. A person reads the pull request. **Merging is the review.** The deploy
   workflow then publishes `web/cards/cards.json`; the app downloads it at
   start, keeps it, and deals from it the next morning.

Thinking cards are arithmetic: they skip the scout and the reader, and the
critic redoes their numbers. With `--batch`, which the nightly run uses,
every stage goes through the Message Batches API at half the token price,
one batch per stage, and the run waits for each.

Nothing about a card is decided on a phone. The phone downloads a file.

## The tags

A card says what it is about and like, beyond what it asks, in fields the
gate holds to a vocabulary (`schema.json`; the rules for choosing are §19 of
`RULES.md`). Each one is read somewhere, or it would not be kept accurate:

| Tag | What it says | Who reads it |
|---|---|---|
| `genre`, `strand` | the six under the subject, the three under the genre, by id | the mix's switches; the plan's coverage; the taste |
| `keywords` | three to six lowercase handles | the archive search; the taste |
| `era`, `region` | when and where it is set | the taste |
| `hook` | what pulls: misconception, puzzle, story, number, mechanism, paradox, practical, origin | the taste |
| `mood` | wonder, practical, sober, dark, playful | the taste |
| `numeracy` | 0 none, 1 a figure, 2 a ratio, 3 a calculation | the taste; a `number` or `estimate` is at least 2 |
| `abstraction` | concrete, mixed, abstract | the taste |
| `shelf_life` | evergreen, years, months | the re-check, when there is one — nothing re-checks a card yet |
| `mature` | sex, drugs, violence, gambling, death in detail | a family setting, when there is one |
| `language` | what the card is written in | the translation pass, when there is one |
| `builds_on` | ids a reader should meet first | the dealer, which holds the card back until they have |
| `figure` | dots, nested circles, doubling, bars, timeline, map | `tool/illustrations` |
| `also` | other strands the card is about, in any subject | the mix's switches, through any of them; the taste |
| `source_kind` | paper, statistics, primary document, institution, reference work, book, standard, news archive, company, arithmetic | the plan, which asks for the kind a subject has least of |
| `quote` | the passage of the reference that states the claim, verbatim | the critic; a program, against the page |

Thinking cards have no genre or strand: Thinking is the principle in the
open, and it is never off anybody's deck. Everything else has both, and
`genres.py` reads the tree off `lib/data/genres.dart` so the two cannot
disagree. The 170 cards written before the tags existed were tagged by hand
and sit under the nearest strand; `tag.py --missing` asks the model to tag
whatever has none, one cheap call a card, no critic.

## Running it by hand

```
pip install -r tool/cards/requirements.txt
export ANTHROPIC_API_KEY=...            # never in the repo, never in the app

python3 tool/cards/check.py                          # the bank passes its gate
python3 tool/cards/generate.py --plan --count 20 --dry-run     # what would be asked
python3 tool/cards/generate.py --topic space --kind pickOne --principle baseRate
python3 tool/cards/generate.py --strand space.the_moon.tides --kind read
python3 tool/cards/generate.py --genre history.middle_ages --kind pickOne   # its thinnest strand
python3 tool/cards/generate.py --plan --count 5 --fake         # the plumbing, no model
python3 tool/cards/generate.py --plan --count 30 --batch       # the nightly run, at half price
python3 tool/cards/generate.py --strand space.the_moon.tides --kind read --no-research   # from memory, as before
python3 tool/cards/tag.py --missing --dry-run                  # cards without tags
python3 tool/cards/bundle.py                         # after any change to the bank
python3 -m unittest discover tool/cards              # the pipeline's own tests
```

`bundle.py --check` fails when either copy is stale, so a pull request that
edits a card by hand has to run the bundler too.

## What a card costs

One card is a scout with eight searches, a page read, a writing call and a
critic call, all against cached system prompts: about sixty cents at Claude
Opus 5 rates, thirty at batch prices, and a Thinking card a quarter of that.
The receipt at the end of every run and in the pull request body splits it
by stage. Thirty requests a night at batch prices is six to nine dollars,
before the cards the gate and the critic refuse; a card that is refused
costs its scout and its reading, not its writing.

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
