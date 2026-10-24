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
  bundle.py                bank → lib/data/embedded_bank.dart + web/cards/cards.json + version.json
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
3. The **scout** (`claude-opus-5`, web search, ten searches) is given the
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
   workflow then publishes `web/cards/cards.json` and `version.json`; the
   app asks the version at start, downloads the bank only when it is newer,
   keeps it, and deals from it the next morning.

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
| `shelf_life` | evergreen, years, months | the monthly re-check (`tool/quality/recheck.py`): months, after three months; years, after a year |
| `mature` | sex, drugs, violence, gambling, death in detail | a family setting, when there is one |
| `language` | what the card is written in | the translation pass, when there is one |
| `builds_on` | ids a reader should meet first | the dealer, which holds the card back until they have |
| `figure` | dots, nested circles, doubling, bars, timeline, map | `tool/illustrations` |
| `also` | other strands the card is about, in any subject | the mix's switches, through any of them; the taste |
| `source_kind` | paper, statistics, primary document, institution, reference work, book, standard, news archive, company, arithmetic | the plan, which asks for the kind a subject has least of |
| `quote` | the passage of the reference that states the claim, verbatim | the critic; a program, against the page |
| `place` | the country, the region or the city (with its point and reach) a card is about, for a card about where readers live | the dealers, which give it only to readers who live there: one a day, and Explore's "Where you live" (docs/PLACES.md); the calendar never names one |

`check.py` holds a place to what the schema cannot say: a country ISO 3166-1
assigns, in capitals; a region whose code starts with its country, and for a
card about a region one the app can find readers in (`lib/models/place.dart`);
a city with its region, `lat`, `lon` and `km`; and the card's own `region`
the part of the world its country is in.

Thinking cards have no genre or strand: Thinking is the principle in the
open, and it is never off anybody's deck. Everything else has both, and
`genres.py` reads the tree off `lib/data/genres.dart` so the two cannot
disagree. The 170 cards written before the tags existed were tagged by hand
and sit under the nearest strand; `tag.py --missing` asks the model to tag
whatever has none, one cheap call a card, no critic.

## The first hand-written set

In September 2026 the bank was grown by hand, before the nightly run, to at
least five cards on every strand: 1,643 new cards (`"written":
"2026-09-26"`), written strand by strand to the rules in `RULES.md` and held
to `check.py --strict`. Each subject was written in two halves, and every
half then went through a critic who fact-checked each card and fixed,
softened or rewrote it, and a verifier who searched the claims the critic
could not confirm. Reads are a little under half of the new cards; the rest
ask: three-option, True/False (a `pickOne` whose options are exactly
`["True", "False"]`), number or estimate, and a debate or so per strand.
Hard cards are 7% of those that ask.

The same pass went over the first 170. Twenty-three banal ones were retired
(`"disabled": true`), eleven moved to the strand they are really about, a
handful corrected, and every one kept was given a `source_kind`, a
`reference` and a `figure`. Twenty-one Thinking cards were added so every
principle has at least five of them.

## Running it by hand

```
pip install -r tool/cards/requirements.txt
export ANTHROPIC_API_KEY=...            # never in the repo, never in the app

python3 tool/cards/check.py                          # the bank passes its gate
python3 tool/cards/generate.py --plan --count 20 --dry-run     # what would be asked
python3 tool/cards/generate.py --topic space --kind pickOne --principle baseRate
python3 tool/cards/generate.py --strand space.the_moon.tides --kind read
python3 tool/cards/generate.py --genre history.middle_ages --kind pickOne   # its thinnest strand
python3 tool/cards/generate.py --plan --count 5 --fake         # the plumbing, no model, no key
python3 tool/cards/generate.py --plan --count 30 --batch       # the nightly run, at half price
python3 tool/cards/generate.py --plan --count 5 --batch --model claude-sonnet-5   # a trial night, cheaper
python3 tool/cards/generate.py --strand space.the_moon.tides --kind read --no-research   # from memory, as before
python3 tool/cards/tag.py --missing --dry-run                  # cards without tags
python3 tool/cards/bundle.py                         # after any change to the bank
python3 -m unittest discover tool/cards              # the pipeline's own tests
```

`bundle.py --check` fails when either copy is stale, so a pull request that
edits a card by hand has to run the bundler too.

## What a card costs

One card is a scout with ten searches, a page read, a writing call and a
critic call, all against cached system prompts: about sixty cents at Claude
Opus 5 rates, thirty at batch prices, and a Thinking card a quarter of that.
The receipt at the end of every run and in the pull request body splits it
by stage. Thirty requests a night at batch prices is six to nine dollars,
before the cards the gate and the critic refuse; a card that is refused
costs its scout and its reading, not its writing.

Most of that is the searches, which cost a cent each on any model. So a
cheaper model saves less than it seems: `--model claude-sonnet-5` takes the
same request as Opus at two and a half times less per token and brings a
card to roughly two thirds of the price, which is the way to run a trial
night. `--model claude-haiku-5-5` costs a fiftieth of Opus per token, so on
it the searches are most of a card's price; it gets the older search and
fetch tools and has no fallback, and it is meant for the cards from videos
below, which search three times rather than ten. A run with `--fake` costs
nothing at all and needs no key: it exercises everything but the writing,
and the nightly workflow takes it as an input, opening a pull request that
says in its title it is not to be merged.

## Cards from videos

A video that does well is often one surprising, checkable claim, and a
claim is a place to start. A chain outside this repository watches the
videos and hands over **leads**: a JSON list, one object each — `id`,
`video` (its address), `title`, `channel`, `idea` (the claim in one
paragraph, as the video states it), `figures`, `links` (the addresses in
its description) and `language`.

```
python3 tool/cards/generate.py --leads leads.json --dry-run    # the placer's brief, a lead's scout brief
python3 tool/cards/generate.py --leads leads.json --fake       # the plumbing, no model, no key
python3 tool/cards/generate.py --leads leads.json --batch --model claude-haiku-5-5
```

1. The **placer** (low effort, no tools) reads each lead against the
   strands, the kinds, the principles and the sections of `RULES.md` that
   say what is not worth a card, and keeps it or turns it down with a line
   of why. What it keeps it places: subject, strand, kind, principle,
   difficulty. A program then holds the place to the tree and the rules —
   a strand under its subject, no principle on a read or a debate, a read
   easy — and a lead turned down or placed where no card can go is in the
   report, never in the bank.
2. A placed lead is a request like any other and goes through the stages
   above, with two differences. Its **scout** starts from the claim, tries
   the description's links first and looks for the page that states the
   claim with its figures; when the claim does not hold, it brings what is
   true nearby or nothing. It searches three times and may open four
   pages: the fetch tool opens only an address already in the
   conversation, which is why the brief lists the links. Its **critic**
   searches once. The video is never the source; the card cites the page.
3. Every card written is then offered a **scene** (`scenes.py`,
   `scene_kinds/`, an example of each kind from `samples/`), or none. A
   scene that fails its check gets one round of repair, and the card is
   filed again with it only if the whole card still passes the gate; the
   pull request says how many got one. `--no-scenes` skips this.

On Haiku a card from a lead comes to a few cents, most of it the four
searches. The outcomes (`--outcomes`) carry each lead's `id`, so the chain
can tell which of its leads became cards.

## The calendar

`editions.json` maps an edition (day 1 = 1 September 2026) to the id of the
question of the day. An edition, once written, never changes; `bundle.py`
extends it 400 days past today, choosing a graded Thinking card that has
not been asked for three quarters of a lap of that pool and never less than
60 editions. The app draws from Thinking too when an edition is missing, and
falls back to every graded card only if Thinking has none. Before this file existed the app computed the calendar from the
pool on the fly, and a card added anywhere re-dealt every day since the
epoch.

## Retiring a card

Add `"disabled": true` to its file and run the bundler. It is never dealt
again but still opens in a deck that already holds it, and its id is never
reused.
