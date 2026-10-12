---
name: astute-places
description: Write Astute cards about the places where real readers live (their city, region, country) — find who is real and where from PostHog, work out which places still lack cards, research them from primary sources, write, check and ship. Use for the daily places concierge, and whenever making or reviewing cards with a `place`.
---

# Cards about where readers live

The design and the contract are in `docs/PLACES.md`; read it first. This skill is the
method. Cards are written **only for places where real readers live**, as they arrive,
never in advance for places nobody reads from.

## 0. Rules that never bend
- **Only real readers.** A place earns cards only through a reader whose verdict in
  PostHog starts with "vero". Test devices, reviewers, robots, VPNs and "sconosciuto"
  earn nothing.
- **The repository is public.** A card's existence says that someone lives near it. So:
  - City cards go to the **nearest town of at least 20,000 inhabitants** whose radius
    (15 km for a town, 20–30 km for a city) still reaches the reader. Never a smaller
    village. If no such town is within 30 km, write region cards instead.
  - No reader, person id, count of readers or "a reader lives here" in any file,
    commit message, pull request or comment. The pull request says only which places
    got cards. The readers' list for a run (`readers.json`) lives in the session's
    scratch directory and is never committed.
- **PostHog never holds a coordinate**, and nothing you do puts one there.
- **The same bar as every card:** `tool/cards/RULES.md` and `docs/cards/CRITERI.md`.
  A place does not lower it.

## 1. Who is real, and where
1. In PostHog (EU, project 283593) run the saved insight **"Lettori: dove sono e se
   sono veri"** (short id `OskfXFGf`).
2. Keep the rows whose `verdetto` starts with `vero`. Each gives:
   - `paese`, the country;
   - `regione_telefono`, an ISO 3166-2 code like `IT-45`, or else the region's name;
   - `citta_telefono`, the city.

   Only the phone's place counts. The IP city (`citta_ip`) is the carrier's, never
   the reader's: never write a city card from it.
3. For each distinct city, look up its centre (lat/lon to 3 decimals) from what you
   know or one search. Write the list to the scratch directory as `readers.json`:
   `[{"country": "IT", "region": "IT-45", "city": "Formigine", "lat": 44.574, "lon": 10.848}]`.
   Readers with a country only are `{"country": "IT"}`.

## 2. What is missing
```
python3 tool/places/missing.py <scratch>/readers.json
```
It counts the cards that already reach each reader, matched the way the app deals them
(`tool/places/places.py`, held to `tool/places/fit_cases.json`). It lists the gaps
nearest first: city (6 cards), then region (8), then country (10), and takes at most
three places a run (`--max`). A city already covered by a bigger town's radius does
not appear: Formigine is covered by Modena's cards.

For each city gap, pick the anchor town by the rule in §0. The anchor is usually the
city itself, or the bigger town next door.

## 3. Research a place
**What makes a local card.** Something a person from there would *not* know, or would
get wrong while feeling sure. Home ground is where people are most confidently wrong.
Look for:
- the name: where it comes from, and the story everyone tells that is false;
- a belief about the place that is wrong (a famous "first", a founding date, a
  legend taught as history);
- a number to estimate: how old, how deep, how far, how many, how much;
- the land and the water: rivers moved by people, ground that sinks, earthquakes,
  fog, climate records;
- the food and *why* it is so (the law, the chemistry, the trade), never a recipe;
- a person or an invention from there that changed something elsewhere;
- a mechanism visible from the street: why the porticoes, why the towers lean, why
  the canals.

**Never** a brochure, a list of sights, a ranking, a superlative without a source, or a
fact any local schoolchild knows.

**Where to look.** Primary and official sources first:
- **Italy:**
  - the comune's own site and the Region's;
  - ISTAT for people and numbers;
  - the Treccani encyclopedia and its Dizionario Biografico;
  - UNESCO WHC;
  - INGV for earthquakes, ISPRA and ARPA for land and air;
  - the Accademia della Crusca for words;
  - the DOP and IGP consortia for food;
  - state archives, museums and universities.
- **Elsewhere:** the national statistics office, the municipality, the national
  encyclopedia, UNESCO, universities, museums and archives.

Wikipedia is a map to sources, never the source.

**The quote.** The gate wants `quote`: at most 40 words copied verbatim from the page
in `reference`, containing the card's figures.
- When you can open pages (WebFetch), open the page and copy the passage.
- When you cannot (this cloud environment has blocked direct fetches; the owner was
  asked to open Network access), search for the exact claim on the source's domain,
  for example `"rifugio" site:comune.modena.it`. Quote only words the search result
  shows verbatim. Never paraphrase into a quote. If no source shows the passage
  verbatim, change the claim or drop the card.
- Keep to about 20 searches a place.

## 4. Write
- One file per card: `tool/cards/bank/<topic>/<topic>-<place-slug>-<n>.json`, with
  every field `tool/cards/schema.json` asks for. Take the genre and strand from
  `lib/data/genres.dart`. Language `en`. `written` is today.
- `place`:
  - country card: `{"country": "IT"}`;
  - region card: `{"country": "IT", "region": "IT-45"}`;
  - city card: country, region, city, `lat` and `lon` of the centre (3 decimals), and
    `km`.
- Six city cards, mixed:
  - at most two history cards;
  - at least one `number` or `estimate`;
  - at least one misconception (`pickOne`, or a true-or-false);
  - at most one `debate`;
  - more than one topic: history, food, nature, language, science, economics,
    medicine, art…
- The model is the 18 cards on Modena, Reggio Emilia and Bologna (`*-modena-*`,
  `*-reggio-emilia-*`, `*-bologna-*`): a pigeon post in a siege, a tricolour that was
  horizontal, a bank holding cheese as collateral.

## 5. Check
1. `python3 tool/cards/check.py`: green.
2. A critic pass on every card, by a second agent or with the `ct-fact-check-cards`
   skill. Check:
   - the claim against its quote;
   - the bar in §3;
   - no brochure;
   - the trap is really what people think.

   Fix the card or drop it.
3. `python3 tool/cards/bundle.py`, then:
   - `python3 -m unittest discover -s tool/cards -p "test_*.py"`
   - `python3 -m unittest discover -s tool/places -p "test_*.py"`
   - `cd functions && npm test`

## 6. Ship
- Branch `claude/places-<YYYY-MM-DD>` from main. Commit, push, and open a pull request
  titled `Place cards: <places>`. The body lists the places and the cards' one-line
  stories, and nothing about readers.
- Merge it with a merge commit once the checks pass. The site carries the cards to
  every phone within minutes.
- If a check fails twice, leave the pull request open and stop. Never merge a red one.
- Report in two lines: the places that got cards and how many, and anything that went
  wrong.
