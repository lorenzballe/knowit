# Places: cards about where a reader lives

Astute deals each reader cards about the place they live: their country,
their region, their city and the towns around it. This file is the design,
and the contract every part of it keeps.

## In breve (per il proprietario)

- **Perché.** All'inizio i lettori sono pochi: ognuno deve sentire che
  Astute parla di lui. Una carta su Modena a chi vive a Modena (o a
  Formigine, dieci chilometri più in là) è la personalizzazione più forte
  che c'è.
- **La posizione.** L'app chiede la posizione al telefono una volta, con
  un foglio suo che spiega perché (dopo il secondo giorno finito, mai prima
  delle carte). Il telefono la dà precisa o approssimata, come sceglie il
  lettore. L'app ne ricava la città **sul telefono stesso** e tiene solo:
  paese, regione, città e un punto arrotondato a circa 10 km. La posizione
  esatta non esce mai dal telefono e non arriva mai a PostHog.
- **Perché non basta l'indirizzo IP.** PostHog stima la città dall'IP, ma
  sul telefono è la città dell'operatore, non del lettore: il proprietario
  risulta in dodici città diverse in un mese (Modena, Reggio Emilia,
  Milano, Palermo, Trieste…). L'IP serve per capire chi è vero, non dove
  vive.
- **Chi è vero.** Ogni lettore viene controllato: fuso orario del
  telefono contro paese dell'IP, canale di installazione, posti famosi dei
  test (Cupertino = revisione Apple; Mountain View e i datacenter USA con
  fusi orari di mezzo mondo = robot di Google), la fattoria del test chiuso
  in Marocco. Le carte si scrivono solo per luoghi di lettori veri.
- **Le carte.** Ogni carta ha un `place`: un paese, una regione o una
  città con un raggio. Esce solo a chi vive lì: al massimo una al giorno
  tra le cinque, più uno scaffale di Esplora, "Dove vivi". Mai come
  domanda del giorno per tutti.
- **Chi le scrive.** Le prime (Italia, le 20 regioni, le città principali
  e la zona del proprietario) subito. Poi, ogni mattina, un giro
  automatico guarda i lettori nuovi in PostHog e scrive le carte dei luoghi
  che ancora non ne hanno, con le stesse regole e lo stesso controllo dei
  fatti di tutte le altre.
- **Il controllo resta al lettore.** In Profilo vede la sua città, può
  cambiarla o toglierla; senza posizione l'app funziona uguale.

## 1. What is kept, and where

`lib/models/place.dart` is the shape (`Place`), the matching (`placeFit`)
and the region names (`regionCode`). `functions/src/place.ts` is its twin
on the server. Both are held to `tool/places/fit_cases.json`.

| Field | What | Example |
| --- | --- | --- |
| `country` | ISO 3166-1 alpha-2 | `IT` |
| `region` | ISO 3166-2, where the app knows the country's regions (Italy now) | `IT-45` |
| `regionName` | the region as the phone named it, in English | `Emilia-Romagna` |
| `city` | city, town or village, in English | `Formigine` |
| `lat`, `lon` | the point, **rounded to one decimal** (about 11 km) | `44.6`, `10.8` |
| `at` | when the phone said so | |

- **On the phone:** with the reader's other settings, and in the backup.
- **In Firestore:** `readers/{uid}.place`, in the reader's own document,
  which only they and the functions read. It is deleted with the account.
- **In the trace:** `place` when it is set or changes (country, region and
  city only).
- **In PostHog:** person properties `place_country`, `place_region`,
  `place_city` and `location_permission` (`granted`, `denied`, `not_asked`,
  `off`). **Never coordinates.**

The exact position is read once, turned into a place on the phone
(the system geocoder, asked in English so that names match across phones),
and dropped. The phone is asked again at most once a week, so that a move
is noticed; a reader can change or remove the place in Profile at any time.

## 2. Asking

- **When.** After the reader's second finished day: the reminder is asked
  after the first, and two system prompts in one sitting is one too many.
  A reader who says "not now" is asked once more, after the seventh day,
  and never again. Profile always has the switch.
- **How.** The app's own sheet first (like the reminder's), with what a
  local card looks like and the promise in plain words: only the city is
  kept, never the exact position. The system prompt comes only after a yes.
- **What is asked for.** "While using the app", never "always". iOS lets
  the reader choose precise or approximate; either is enough.
- **Without it.** Nothing breaks. No local cards, and Explore's "Where you
  live" shelf offers to switch it on.

## 3. Is this a real person in a real place?

The cards are written for real readers' places only. Every reader is
checked against what PostHog and the phone say, and the verdict decides
whether their place counts.

| Signal | From | What it gives away |
| --- | --- | --- |
| The phone's place | the app, with permission | where they live, to the city |
| Time zone | every event (`$timezone`) | the country, roughly; hard to fake by accident |
| IP country and city | PostHog GeoIP | the country; on a phone the city is the carrier's, not the reader's |
| Install channel | `install_channel` | `test_lab`, `debug`, `testflight` |
| Behaviour | events | one short session per build, no answers: a reviewer |

Verdicts, in this order:

1. **Test**: `install_channel` is `test_lab` or `debug`; or the person is in
   a review or test cohort; or the IP city is Cupertino with a
   `testflight` install (App Review); or the IP is in the US while the time
   zone is half a world away (Google's robots: Los Angeles, Lagos,
   Johannesburg, Sydney or Singapore time zones behind US addresses).
2. **VPN or proxy**: the IP's country and the time zone's country
   disagree, for a reader who otherwise behaves like a reader.
3. **Real, with a place**: the phone gave a place, and its country matches
   the time zone's. The place is trusted to the city.
4. **Real, region only**: no place from the phone, but IP country, time
   zone and app language agree, and the IP region is stable across days.
   Good for country and region cards, never for a city's.
5. **Unknown**: nothing else applies.

The live table is a PostHog insight, "Lettori: dove sono e se sono veri",
on the dashboard "Pronta per Apple?" and the routine below.

## 4. The cards

A card about a place is an ordinary card, with every field the bank
asks for (`tool/cards/RULES.md`), and a `place`
(`tool/cards/schema.json`):

```json
"place": {"country": "IT"}
"place": {"country": "IT", "region": "IT-45"}
"place": {"country": "IT", "region": "IT-45", "city": "Modena",
          "lat": 44.647, "lon": 10.925, "km": 20}
```

- **A city card** reaches a reader within `km` of the city's centre: about
  15 for a town, 20 to 30 for a city and the towns that live off it. Never
  on a guess: a reader with no point gets no city card.
- **A region card** reaches anyone in the region; **a country card**
  anyone in the country.
- **What makes one.** The same bar as every card, and more: something a
  person from there would *not* already know, or would get wrong while
  feeling sure — the calibration Astute is built on, with home ground as the
  hardest place to be honest. History, science, the land and the water,
  language and dialect, food and why it is so, numbers to estimate (how
  old, how far, how many), a famous belief about the place that is false.
  Never a brochure, never a list of sights. Every claim with a source.
- **Language.** English, like the rest of the bank, until the cards are
  translated.
- **Files.** `tool/cards/bank/<topic>/<topic>-<place>-<n>.json`, in the
  topic they belong to, with the genre and strand they fit.

## 5. Dealing

- **Today.** At most one card about the reader's place a day, inside the
  five, nearest first: their city, then their region, then their country.
  Never the same card twice. A day with none left is an ordinary day.
- **Explore.** A shelf, "Where you live", with the reader's place's cards,
  nearest first. Without a place, the shelf offers to switch one on.
- **Nowhere else.** A place card is never anyone's question of the day,
  never a common card of the edition, never on a shelf for everyone, never
  dealt at random or as one of a reader's own cards. Search finds it only
  for readers who live there.
- **On the card.** A small line says why it is there: "Near you · Modena",
  "Your region · Emilia-Romagna", "Your country · Italy".
- **On both dealers.** The server (`functions/src/deal.ts`, `explore.ts`)
  and the phone's own (`lib/state/app_state.dart`) deal it the same way.

## 6. Writing them

1. **Now: the seed.** Italy (country cards), its twenty regions, its
   largest cities and the owner's own area: enough that the first Italian
   readers find their home from day one.
2. **Every morning: the concierge.** A scheduled Claude Code routine reads
   the verdict table in PostHog. For every real reader whose place has no
   cards yet, it writes them — city first, then the region if it has none —
   through the same rules, gate and critic as every card. It opens a pull
   request, merges it once the gate and the tests pass, and the site
   publishes the cards to every phone within minutes, without a release.
3. **Later: context.** The calendar (a city's feast day, a region's
   anniversaries, the season), the land around (the sea, a river, the
   mountains within reach of the reader's point), the time of day. Each is
   a new field on the same `place`, dealt by the same slot.

## 7. Privacy

- The privacy policy (`site/privacy.html`, both languages) and the app's
  own copy (`lib/legal.dart`) say all of the above in plain words.
- `ios/Runner/PrivacyInfo.xcprivacy` declares coarse location, linked to
  the reader, for app functionality and personalisation; never tracking.
  App Store Connect's privacy answers must say the same (the owner's step).
- Coordinates are rounded before they leave the phone; nothing finer than
  a city is ever kept, logged or sent to PostHog; it is deleted with the
  account; Profile removes it at any time.
