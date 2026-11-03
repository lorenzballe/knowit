"""The pipeline without the model: the gate, the plan, the plumbing.

    python3 -m unittest discover tool/cards
"""
from __future__ import annotations

import contextlib
import datetime as dt
import io
import json
import tempfile
import unittest
from pathlib import Path

import bundle
import check
import generate
import genres
import sources
import tag

TODAY = dt.date(2026, 9, 18)


def read_card(**over) -> dict:
    card = {
        "id": "space-20260918-1",
        "topic": "space",
        "kind": "read",
        "difficulty": "easy",
        "principle": "none",
        "question": "Why does the catalogue of known planets lean so heavily one way?",
        "answer": " ".join(["Because two methods found nearly all of them and both see big planets close in, so the list is a census of what the instruments detect rather than of planets."]),
        "move": "A catalogue is a list of what the instrument can see.",
        "source": "NASA Exoplanet Archive",
        "reference": "https://exoplanetarchive.ipac.caltech.edu/",
        "written": "2026-09-18",
        "genre": "space.stars_and_light",
        "strand": "space.stars_and_light.colours_of_stars",
        "keywords": ["exoplanets", "transit method", "selection effect"],
        "era": "recent",
        "region": "none",
        "hook": "mechanism",
        "mood": "wonder",
        "numeracy": 1,
        "abstraction": "mixed",
        "shelf_life": "years",
        "mature": False,
        "language": "en",
        "source_kind": "institution",
    }
    card.update(over)
    return card


def lead(**over) -> dict:
    """A lead as the chain that watched the video hands it over."""
    item = {
        "id": "yt-tides-1",
        "video": "https://www.youtube.com/watch?v=tides000001",
        "title": "Why the sea comes in twice a day",
        "channel": "Sea Science",
        "idea": "The Moon raises two bulges of water, one facing it and one on the far side, so most coasts see two high tides a day.",
        "figures": ["12 hours 25 minutes between high tides"],
        "links": ["https://tidesandcurrents.noaa.gov/restles1.html", "https://www.instagram.com/seascience"],
        "language": "en",
    }
    item.update(over)
    return item


def thinking_card(**over) -> dict:
    card = read_card(id="thinking-20260918-1", kind="pickOne", difficulty="medium", principle="baseRate", options=["A", "B"], correct=0,
                     trap="Taking B, which feels like the safer answer.", topic="thinking", numeracy=3, source_kind="arithmetic",
                     reference="The conjunction rule, Tversky and Kahneman 1983")
    for key in ("genre", "strand"):
        card.pop(key, None)
    card.update(over)
    return card


class TheGenres(unittest.TestCase):
    def test_the_tree_is_read_off_the_app(self):
        tree = genres.by_topic()
        self.assertEqual(len(tree), 20)
        self.assertNotIn("thinking", tree)
        for topic, gs in tree.items():
            self.assertGreaterEqual(len(gs), 6, topic)
            for g in gs:
                self.assertGreaterEqual(len(g.strands), 3, g.id)
                self.assertEqual(g.topic, topic)
                for s in g.strands:
                    self.assertEqual(s.genre, g.id)
                    self.assertTrue(s.id.startswith(g.id + "."))
        self.assertEqual(len(genres.strands_by_id()), sum(len(g.strands) for gs in tree.values() for g in gs))
        self.assertEqual(genres.describe("space.black_holes.event_horizons"), "Black holes · Event horizons")
        self.assertEqual(genres.strands_of("thinking"), [])

    def test_a_label_is_read_whole_or_not_at_all(self):
        # A Dart string to its closing quote, escapes and all. Cut at an
        # escaped apostrophe, a strand used to fall out of the tree without
        # a word, and the gate turned away every card written under it.
        with tempfile.TemporaryDirectory() as tmp:
            dart = Path(tmp) / "genres.dart"
            dart.write_text(
                "const kGenres = {\n"
                "  'medicine': [\n"
                "    Genre('medicine.myths', 'Myths', [\n"
                "      Strand('medicine.myths.tales', 'Old wives\\' tales'),\n"
                "      Strand('medicine.myths.detox', \"Detox, 'cleanses'\"),\n"
                "      Strand('medicine.myths.online', 'Online'),\n"
                "    ]),\n"
                "  ],\n"
                "};\n",
                encoding="utf-8",
            )
            (genre,) = genres.load(dart)
            self.assertEqual([s.label for s in genre.strands], ["Old wives' tales", "Detox, 'cleanses'", "Online"])
            # One it cannot read stops the gate rather than shrinking the tree.
            # Another file, because the tree is read once per path.
            bad = Path(tmp) / "unreadable.dart"
            bad.write_text(dart.read_text(encoding="utf-8").replace("'Online'", "kOnline"), encoding="utf-8")
            with self.assertRaises(ValueError):
                genres.load(bad)


class TheGate(unittest.TestCase):
    def setUp(self):
        self.schema = check.load_schema()
        self.banned = check.load_banned()

    def check(self, card, strict=False):
        return check.check_card(card, strict=strict, schema=self.schema, banned=self.banned)

    def test_the_bank_passes(self):
        bank = check.load_bank()
        editions = json.loads(check.EDITIONS.read_text())
        self.assertEqual(check.check_bank(bank, editions), {})

    def test_a_good_card_passes_strict(self):
        self.assertEqual(self.check(read_card(), strict=True), [])

    def test_shape_by_kind(self):
        self.assertIn("a read card is a question", self.check(read_card(question="Planets are found by wobble.")))
        self.assertTrue(any("principle" in p for p in self.check(read_card(principle="baseRate"))))
        pick = read_card(kind="pickOne", difficulty="medium", principle="baseRate", options=["A", "B"], correct=1, trap="Taking A.")
        self.assertEqual(self.check(pick), [])
        self.assertTrue(any("correct" in p for p in self.check(dict(pick, correct=5))))
        self.assertTrue(any("trap" in p for p in self.check(dict(pick, trap=""))))
        self.assertTrue(any("two options" in p for p in self.check(dict(pick, options=["A", "a"]))))
        debate = read_card(kind="debate", difficulty="medium", sides=["Yes", "No"], counterpoint="The other side.")
        self.assertEqual(self.check(debate), [])
        self.assertTrue(any("two sides" in p for p in self.check({k: v for k, v in debate.items() if k != "sides"})))

    def test_the_back_ends_on_one_box_chosen_by_the_card(self):
        ask = "Where else would I count only the ones still standing?"
        self.assertEqual(self.check(read_card(ask=ask, end="ask")), [])
        self.assertEqual(self.check(read_card(ask=ask, both=True)), [])
        self.assertTrue(any("end is keep or ask" in p or "end" in p for p in self.check(read_card(ask=ask, end="both"))))
        self.assertTrue(any("needs an ask" in p for p in self.check(read_card(end="ask"))))
        self.assertTrue(any("needs an ask" in p for p in self.check(read_card(both=True))))

    def test_the_schema_refuses_unknowns(self):
        self.assertTrue(any("astrology" in p for p in self.check(read_card(topic="astrology"))))
        self.assertTrue(any("colour" in p for p in self.check(read_card(colour="red"))))

    def test_the_listicle_is_refused(self):
        card = read_card(answer="Honey never spoils, which is why it is found in tombs, and the rest of this answer is padding to reach the floor for a read.")
        self.assertTrue(any("banned" in p for p in self.check(card)))

    def test_strict_holds_the_rules(self):
        self.assertTrue(any("reference" in p for p in self.check(read_card(reference=""), strict=True)))
        self.assertTrue(any("exclamation" in p for p in self.check(read_card(move="A catalogue lists what the instrument can see!"), strict=True)))
        self.assertTrue(any("forbidden" in p for p in self.check(read_card(answer="Interestingly, " + read_card()["answer"]), strict=True)))
        self.assertTrue(any("6 to 25" in p for p in self.check(read_card(question="Why?"), strict=True)))
        self.assertTrue(any("30 to 55" in p for p in self.check(read_card(answer="Short."), strict=True)))
        self.assertTrue(any("does not start with its topic" in p for p in self.check(read_card(id="nature-1"), strict=True)))
        self.assertEqual(self.check(read_card(id="nature-1")), [], "the floor does not mind an old id")

    def test_the_tags_are_held_to_the_tree(self):
        self.assertTrue(any("keywords" in p for p in self.check({k: v for k, v in read_card().items() if k != "keywords"})))
        self.assertTrue(any("genre and strand" in p for p in self.check({k: v for k, v in read_card().items() if k != "strand"})))
        self.assertTrue(any("not under genre" in p for p in self.check(read_card(strand="space.the_moon.tides"))))
        self.assertTrue(any("belongs to" in p for p in self.check(read_card(genre="nature.oceans", strand="nature.oceans.coral"))))
        self.assertTrue(any("no strand is called" in p for p in self.check(read_card(strand="space.stars_and_light.pulsars"))))
        self.assertTrue(any("principle in the open" in p for p in self.check(thinking_card(genre="space.the_moon", strand="space.the_moon.tides"))))
        self.assertEqual(self.check(thinking_card()), [])
        self.assertTrue(any("lowercase" in p for p in self.check(read_card(keywords=["Exoplanets", "transit", "wobble"]))))
        self.assertTrue(any("four words" in p for p in self.check(read_card(keywords=["a very long keyword indeed here", "transit", "wobble"]))))
        self.assertTrue(any("numeracy" in p for p in self.check(read_card(kind="estimate", difficulty="medium", principle="estimation", value=3, unit="x", steps=["a", "b"], hint="h", numeracy=0))))
        self.assertTrue(any("itself" in p for p in self.check(read_card(builds_on=["space-20260918-1"]))))
        self.assertTrue(any("cabbage" in p for p in self.check(read_card(hook="cabbage"))))

    def test_the_sources_are_held_to_the_house(self):
        self.assertTrue(any("not a strand" in p for p in self.check(read_card(also=["space.nowhere.here"]))))
        self.assertTrue(any("own strand" in p for p in self.check(read_card(also=["space.stars_and_light.colours_of_stars"]))))
        self.assertEqual(self.check(read_card(also=["science.physics.gravity"])), [])
        self.assertTrue(any("passage, not a page" in p for p in self.check(read_card(quote=" ".join(["w"] * 70)))))
        self.assertTrue(any("quotes nobody" in p for p in self.check(thinking_card(quote="A quoted passage of six words here."))))
        strict = lambda **over: self.check(read_card(**over), strict=True)
        self.assertTrue(any("source_kind" in p for p in self.check({k: v for k, v in read_card().items() if k != "source_kind"}, strict=True)))
        self.assertEqual(strict(source_kind="institution"), [])
        self.assertTrue(any("is its URL" in p for p in strict(source_kind="paper", quote="A passage of six words at least.", reference="Author, 2020")))
        self.assertTrue(any("never the reference" in p for p in strict(source_kind="paper", reference="https://en.wikipedia.org/wiki/Exoplanet")))
        self.assertTrue(any("blocked" in p for p in strict(source_kind="paper", reference="https://www.buzzfeed.com/x")))
        self.assertTrue(any("thinking card's source" in p for p in self.check(thinking_card(source_kind="company"), strict=True)))
        self.assertEqual(self.check(thinking_card(source_kind="arithmetic"), strict=True), [])

    def test_two_cards_on_a_strand_do_not_cite_one_site(self):
        a = read_card(id="space-a", reference="https://www.nasa.gov/one")
        b = read_card(id="space-b", question="How many probes have left the solar system so far?", move="Count the probes, not the press releases about them.", reference="https://science.nasa.gov/two")
        c = dict(b, id="space-c", reference="https://www.esa.int/two")
        self.assertTrue(any("as space-a on the same strand" in p for p in check.check_sources([b], against=[a])))
        self.assertEqual(check.check_sources([c], against=[a]), [])
        self.assertEqual(check.check_sources([b], against=[dict(a, strand="space.the_moon.tides", genre="space.the_moon")]), [])

    def test_links_name_real_cards(self):
        a = read_card(id="space-a")
        b = read_card(id="space-b", question="How many probes have left the solar system so far?", move="Count the probes, not the press releases about them.", builds_on=["space-a"])
        self.assertEqual(check.check_links([a, b]), [])
        self.assertTrue(any("not in the bank" in p for p in check.check_links([b])))
        self.assertTrue(any("retired" in p for p in check.check_links([b], against=[dict(a, disabled=True)])))

    def test_the_house_order_of_keys(self):
        keys = list(check.ordered(read_card(reference="x", written="2026-09-18")))
        self.assertEqual(keys[:4], ["id", "topic", "genre", "strand"])
        self.assertEqual(keys[-4:], ["source", "source_kind", "reference", "written"])
        self.assertLess(keys.index("keywords"), keys.index("source"))
        self.assertGreater(keys.index("keywords"), keys.index("move"))

    def test_the_bank_is_fully_tagged(self):
        for card in check.load_bank():
            for key in check.TAG_KEYS:
                self.assertIn(key, card, card["id"])
            self.assertEqual(card["topic"] == "thinking", "strand" not in card, card["id"])

    def test_twins_are_caught(self):
        a = read_card(id="space-a", question="Why does the catalogue of known planets look so strange?")
        b = read_card(id="space-b", question="Why does the catalogue of known planets look strange today?")
        self.assertTrue(any("same thing" in p for p in check.check_twins([a, b])))
        c = read_card(id="space-c", question="How many probes have left the solar system so far?",
                      move="Count the probes, not the press releases about them.")
        self.assertEqual(check.check_twins([a, c]), [])
        d = read_card(id="space-d", question="What limits a probe?", move=a["move"])
        self.assertTrue(any("repeats the move" in p for p in check.check_twins([a, d])))

    def test_editions_must_name_graded_cards_and_keep_their_distance(self):
        cards = [
            thinking_card(id="thinking-a"),
            thinking_card(id="thinking-b"),
            read_card(id="space-r"),
        ]
        self.assertEqual(check.check_commons({"1": ["space-r"], "2": []}, cards), [])
        self.assertTrue(any("asks" in p for p in check.check_commons({"1": ["thinking-a"]}, cards)))
        self.assertTrue(any("comes back" in p for p in check.check_commons({"1": ["space-r"], "2": ["space-r"]}, cards)))
        self.assertEqual(check.check_editions({"1": "thinking-a", "2": "thinking-b"}, cards), [])
        self.assertTrue(any("cannot be marked" in p for p in check.check_editions({"1": "space-r"}, cards)))
        self.assertTrue(any("comes back" in p for p in check.check_editions({"1": "thinking-a", "2": "thinking-a"}, cards)))
        self.assertTrue(any("not in the bank" in p for p in check.check_editions({"1": "nobody"}, cards)))
        self.assertTrue(any("consecutive" in p for p in check.check_editions({"1": "thinking-a", "3": "thinking-b"}, cards)))


MODENA = {"country": "IT", "region": "IT-45", "city": "Modena", "lat": 44.647, "lon": 10.925, "km": 20}


def place_card(place: dict, **over) -> dict:
    """A card about a place: a good read card, set in Europe, with [place]."""
    return read_card(**{"id": "space-modena-1", "region": "europe", "place": place, **over})


class ThePlaces(unittest.TestCase):
    """A card about a place: what the schema cannot say about where it belongs."""

    def setUp(self):
        self.schema = check.load_schema()
        self.banned = check.load_banned()

    def check(self, card, strict=False):
        return check.check_card(card, strict=strict, schema=self.schema, banned=self.banned)

    def test_a_city_a_region_and_a_country_pass(self):
        for place in (MODENA, {"country": "IT", "region": "IT-45"}, {"country": "IT"}):
            self.assertEqual(self.check(place_card(place), strict=True), [], place)
        # A city abroad: its region has a code even where the app cannot
        # name it yet, because a city card reaches readers by the point.
        paris = {"country": "FR", "region": "FR-IDF", "city": "Paris", "lat": 48.857, "lon": 2.352, "km": 25}
        self.assertEqual(self.check(place_card(paris)), [])

    def test_a_city_card_has_its_region_its_point_and_its_reach(self):
        for missing in ("region", "lat", "lon", "km"):
            place = {k: v for k, v in MODENA.items() if k != missing}
            self.assertIn(f"a city card has region, lat, lon and km: no {missing}", self.check(place_card(place)), missing)
        # A point without a city reaches nobody it would not reach anyway.
        self.assertTrue(any("belong to a city" in p for p in self.check(place_card({"country": "IT", "region": "IT-45", "km": 20}))))

    def test_a_region_is_inside_its_country(self):
        self.assertTrue(any("starts with 'IT-'" in p for p in self.check(place_card({"country": "IT", "region": "FR-IDF"}))))
        self.assertTrue(any("starts with 'IT-'" in p for p in self.check(place_card(dict(MODENA, region="SM-01")))))

    def test_a_region_card_names_a_region_a_reader_can_be_found_in(self):
        # A province is not a region, and the app names no French region yet:
        # either card would be written for nobody.
        self.assertTrue(any("reach nobody" in p for p in self.check(place_card({"country": "IT", "region": "IT-MO"}))))
        self.assertTrue(any("reach nobody" in p for p in self.check(place_card({"country": "FR", "region": "FR-IDF"}))))
        regions = check.known_regions()
        self.assertEqual(len(regions), 20, "Italy's twenty, as lib/models/place.dart names them")
        self.assertTrue(all(code.startswith("IT-") for code in regions))
        self.assertIn("IT-45", regions)

    def test_the_country_is_iso_alpha_2_in_capitals(self):
        # The schema says the shape; the gate says it again for a machine
        # without jsonschema, and says which codes are countries at all.
        self.assertTrue(any("place/country" in p for p in self.check(place_card({"country": "it"}))))
        self.assertTrue(any("in capitals" in p for p in check.check_place(place_card({"country": "it"}))))
        self.assertTrue(any("in capitals" in p for p in check.check_place(place_card({"country": "ITA"}))))
        self.assertTrue(any("not a country" in p for p in self.check(place_card({"country": "UK"}))))
        self.assertTrue(any("not a country" in p for p in self.check(place_card({"country": "XX"}))))
        self.assertEqual(check.check_place(place_card("IT")), ["place is an object with a country"])
        self.assertTrue(any("place" in p for p in self.check(place_card({"region": "IT-45"}))))
        self.assertTrue(any("additional" in p.lower() for p in self.check(place_card({"country": "IT", "province": "MO"}))))

    def test_the_card_is_set_in_its_place_s_part_of_the_world(self):
        self.assertIn("a card about IT is set in europe, not 'asia'", self.check(place_card({"country": "IT"}, region="asia")))
        self.assertTrue(any("set in europe" in p for p in self.check(place_card({"country": "IT"}, region="none"))))
        self.assertTrue(any("set in europe" in p for p in self.check(place_card({"country": "IT"}, region="world"))))
        # A country on two continents may be tagged with either.
        for region in ("europe", "middle_east"):
            self.assertEqual(self.check(place_card({"country": "TR"}, region=region)), [], region)
        self.assertEqual(self.check(place_card({"country": "JP"}, region="asia")), [])
        self.assertEqual(self.check(place_card({"country": "US"}, region="americas")), [])

    def test_every_country_has_its_part_of_the_world(self):
        self.assertEqual(len(check.COUNTRIES), 249, "every code ISO 3166-1 assigns")
        for code, continents in check.CONTINENTS_OF.items():
            self.assertTrue(continents <= set(check.TAGS["region"]), code)
        self.assertEqual(check.CONTINENTS_OF["IT"], {"europe"})

    def test_place_sits_after_the_tags_in_a_file(self):
        keys = list(check.ordered(place_card({"country": "IT"}, reference="x", written="2026-09-18")))
        self.assertEqual(keys.index("place"), keys.index("language") + 1)
        self.assertLess(keys.index("place"), keys.index("source"))

    def test_the_bundle_carries_the_place(self):
        out = bundle.build([place_card(MODENA)], {}, {}, version=1, built="2026-10-12T00:00:00Z")
        self.assertEqual(out["cards"][0]["place"], MODENA)
        self.assertEqual(json.loads(json.dumps(out))["cards"][0]["place"], MODENA)


class TheCalendar(unittest.TestCase):
    def test_a_card_about_a_place_never_joins_the_calendar(self):
        bank = check.load_bank()
        editions = json.loads(check.EDITIONS.read_text())
        commons = json.loads(check.COMMONS.read_text())
        # Cards about a place of every kind the calendar draws from: Thinking
        # questions for the question of the day, reads for the common cards.
        thinking = [c for c in bank if c["topic"] == "thinking" and c["kind"] in check.GRADED and not c.get("disabled")]
        reads = [c for c in bank if c["kind"] == "read" and not c.get("disabled")]
        places = [dict(check.public(c), id=f"{c['id']}-in-modena", place=MODENA, region="europe") for c in thinking[:40] + reads[:200]]
        placed = {c["id"] for c in places}
        until = len(editions) + 120
        with_places = bundle.extend_editions(editions, bank + places, until=until)
        self.assertFalse(placed & set(with_places.values()))
        # The pool left as it was, the calendar is the one a bank without
        # them writes, edition for edition: adding them changes nothing.
        self.assertEqual(with_places, bundle.extend_editions(editions, bank, until=until))
        self.assertEqual(json.dumps(with_places, indent=2), json.dumps(bundle.extend_editions(editions, bank, until=until), indent=2))
        with_commons = bundle.extend_commons(commons, bank + places, until=until)
        self.assertFalse(placed & {cid for ids in with_commons.values() for cid in ids})
        self.assertEqual(with_commons, bundle.extend_commons(commons, bank, until=until))
        # What is written already stays written, byte for byte.
        for k, v in editions.items():
            self.assertEqual(with_places[k], v)
        for k, v in commons.items():
            self.assertEqual(with_commons[k], v)
        # And a calendar that names one is refused.
        cards = [thinking_card(id="thinking-a"), thinking_card(id="thinking-b", place={"country": "IT"}, region="europe"),
                 read_card(id="space-r"), read_card(id="space-p", place={"country": "IT"}, region="europe")]
        self.assertEqual(check.check_editions({"1": "thinking-a"}, cards), [])
        self.assertTrue(any("about a place" in p for p in check.check_editions({"1": "thinking-b"}, cards)))
        self.assertEqual(check.check_commons({"1": ["space-r"]}, cards), [])
        self.assertTrue(any("about a place" in p for p in check.check_commons({"1": ["space-p"]}, cards)))

    def test_extends_deterministically_and_keeps_its_distance(self):
        bank = check.load_bank()
        editions = json.loads(check.EDITIONS.read_text())
        a = bundle.extend_editions(editions, bank, until=len(editions) + 90)
        b = bundle.extend_editions(editions, bank, until=len(editions) + 90)
        self.assertEqual(a, b)
        self.assertEqual(len(a), len(editions) + 90)
        self.assertEqual(check.check_editions(a, bank), [])
        for k, v in editions.items():
            self.assertEqual(a[k], v, "an edition once written never changes")


class ThePlan(unittest.TestCase):
    def test_asks_for_what_is_short(self):
        bank = check.load_bank()
        requests = generate.plan(bank, 26)
        self.assertEqual(len(requests), 26)
        topics = {r.topic for r in requests}
        self.assertGreater(len(topics), 8, "the gaps are spread across subjects")
        self.assertLess(sum(r.topic == "thinking" for r in requests), 4, "thinking is the one subject that is not short")
        asks = [r for r in requests if r.kind in check.GRADED]
        self.assertTrue(asks, "the subjects have no graded questions yet, so the plan asks for them")
        for r in asks:
            self.assertNotEqual(r.principle, "none")
        for r in requests:
            if r.kind in ("read", "debate"):
                self.assertEqual(r.principle, "none")
            if r.topic == "thinking":
                self.assertEqual(r.strand, "")
            else:
                self.assertIn(r.strand, genres.strands_by_id(), str(r))
                self.assertEqual(r.genre, genres.strands_by_id()[r.strand].genre)
        for r in asks:
            self.assertIn(r.principle, r.principles)
            self.assertLessEqual(len(r.principles), generate.PRINCIPLE_CHOICE)
        for r in requests:
            if r.topic == "thinking":
                self.assertEqual(r.source_kind, "arithmetic")
            else:
                self.assertIn(r.source_kind, sources.kinds_for(r.topic), str(r))

    def test_reaches_for_the_thinnest_strand_first(self):
        bank = check.load_bank()
        counts = generate.strand_counts(bank)
        for r in generate.plan(bank, 40):
            if not r.strand:
                continue
            siblings = genres.strands_of(r.topic)
            self.assertEqual(counts[r.strand], min(counts[s.id] for s in siblings), str(r))
            counts[r.strand] += 1

    def test_a_full_strand_is_left_alone(self):
        bank = check.load_bank()
        full = [dict(read_card(id=f"space-full-{i}", question=f"Why is the moon dust number {i} sharp and grey?", move=f"Moon dust is sharp in its own way, number {i}."), genre="space.the_moon", strand="space.the_moon.moon_dust") for i in range(generate.STRAND_TARGET + 1)]
        for r in generate.plan(bank + full, 60):
            self.assertNotEqual(r.strand, "space.the_moon.moon_dust")

    def test_is_stable_for_the_same_bank(self):
        bank = check.load_bank()
        self.assertEqual(generate.plan(bank, 10), generate.plan(bank, 10))


class TheSources(unittest.TestCase):
    def test_a_domain_is_the_registrable_one(self):
        self.assertEqual(sources.domain_of("https://www.nasa.gov/mission/x"), "nasa.gov")
        self.assertEqual(sources.domain_of("https://data.ons.gov.uk/a/b"), "ons.gov.uk")
        self.assertEqual(sources.domain_of("http://en.wikipedia.org/wiki/Tide"), "wikipedia.org")
        self.assertEqual(sources.domain_of("https://plato.stanford.edu/entries/zeno"), "stanford.edu")
        self.assertTrue(sources.is_under("en.wikipedia.org", "wikipedia.org"))
        self.assertFalse(sources.is_under("notwikipedia.org", "wikipedia.org"))

    def test_a_quote_is_found_through_the_accidents_of_copying(self):
        page = "The Moon’s gravity raises two bulges — one on each side of the Earth.\nA line break, a soft\u00adhyphen and “curly quotes” change nothing."
        self.assertTrue(sources.same_quote("The Moon's gravity raises two bulges, one on each side", page))
        self.assertTrue(sources.same_quote('a soft-hyphen and "curly quotes" change nothing', page))
        self.assertFalse(sources.same_quote("The Moon's gravity raises three bulges on each side", page))
        self.assertFalse(sources.same_quote("two bulges", page), "shorter than a sentence")

    def test_the_lists_are_read_and_a_find_is_held_to_them(self):
        self.assertIn("buzzfeed.com", sources.blocked())
        self.assertIn("wikipedia.org", sources.never_a_reference())
        self.assertIn("nasa.gov", sources.preferred("space"))
        self.assertEqual(sources.preferred("thinking"), [])
        self.assertNotIn("arithmetic", sources.kinds_for("art"))
        self.assertNotIn("standard", sources.kinds_for("art"))
        ok = generate.Find(claim="c", figures="", source="s", url="https://www.nasa.gov/x", source_kind="institution", why_not_textbook="w")
        self.assertTrue(generate.usable_find(ok))
        self.assertFalse(generate.usable_find(ok.model_copy(update={"url": "https://en.wikipedia.org/wiki/X"})))
        self.assertFalse(generate.usable_find(ok.model_copy(update={"url": "https://www.reddit.com/r/x"})))
        self.assertFalse(generate.usable_find(ok.model_copy(update={"url": "NASA, 2020"})))


def _fetched(page: str | None):
    """A message as the API returns it after a fetch, or with no fetch at all."""
    from types import SimpleNamespace as NS
    if page is None:
        return NS(content=[NS(type="text", text="{}")])
    doc = NS(source=NS(type="text", data=page))
    return NS(content=[NS(type="web_fetch_tool_result", content=NS(type="web_fetch_result", content=doc)), NS(type="text", text="{}")])


class TheReader(unittest.TestCase):
    def test_a_quote_has_to_be_on_the_page(self):
        page = "Tides on Earth are raised mostly by the Moon, and the Sun adds about half as much again."
        good = generate.Reading(supported=True, quote="Tides on Earth are raised mostly by the Moon", figures="", note="")
        self.assertEqual(generate.verify_reading(good, _fetched(page)), ("checked", ""))
        invented = good.model_copy(update={"quote": "Tides on Earth are raised entirely by the Sun alone"})
        self.assertEqual(generate.verify_reading(invented, _fetched(page))[0], "not on page")
        self.assertEqual(generate.verify_reading(good, _fetched(None))[0], "unchecked", "a PDF: the reader's word stands, and the report says so")
        self.assertEqual(generate.verify_reading(good.model_copy(update={"supported": False, "note": "no"}), _fetched(page)), ("unsupported", "no"))
        self.assertEqual(generate.verify_reading(good.model_copy(update={"quote": "the Moon"}), _fetched(page))[0], "no quote")
        self.assertEqual(generate.verify_reading(good.model_copy(update={"quote": " ".join(["word"] * 70)}), _fetched(page))[0], "no quote")


class TheBatch(unittest.TestCase):
    """The Message Batches path, against a client that answers at once."""

    def _client(self, replies):
        from types import SimpleNamespace as NS
        calls = {}

        class Batches:
            def create(self_, *, requests, **kw):
                calls["requests"] = requests
                calls["kw"] = kw
                return NS(id="b1", processing_status="ended")

            def retrieve(self_, batch_id, **kw):
                return NS(id=batch_id, processing_status="ended")

            def results(self_, batch_id, **kw):
                out = []
                for i, reply in enumerate(replies):
                    custom_id = f"write-{i}"
                    if reply is None:
                        out.append(NS(custom_id=custom_id, result=NS(type="errored", error="boom")))
                    else:
                        message = NS(stop_reason="end_turn", content=[NS(type="text", text=reply)],
                                     usage=NS(input_tokens=100, output_tokens=50, cache_read_input_tokens=1000,
                                              cache_creation_input_tokens=0, server_tool_use=NS(web_search_requests=2, web_fetch_requests=0)))
                        out.append(NS(custom_id=custom_id, result=NS(type="succeeded", message=message)))
                return out

        return NS(beta=NS(messages=NS(batches=Batches()))), calls

    def test_a_stage_goes_through_one_batch_and_comes_back_in_order(self):
        good = generate.canned("topic: space\nkind: read\ndifficulty: easy\nprinciple: none").model_dump_json()
        client, calls = self._client([good, None, "not json"])
        model = object.__new__(generate.Claude)
        model.client, model.model, model.batch, model.usage = client, generate.MODEL, True, {}
        specs = [generate.Spec("s", [{"role": "user", "content": f"card {i}"}], generate.Draft) for i in range(3)]
        results = model.calls(specs, "write")
        self.assertEqual(len(calls["requests"]), 3)
        self.assertEqual(calls["requests"][0]["custom_id"], "write-0")
        self.assertEqual(calls["requests"][0]["params"]["output_config"]["format"]["type"], "json_schema")
        self.assertFalse(calls["requests"][0]["params"]["output_config"]["format"]["schema"]["additionalProperties"])
        # No fallbacks in a batch: the API refuses the whole batch over the
        # parameter, so it stays a single-call thing.
        self.assertNotIn("fallbacks", calls["requests"][0]["params"])
        self.assertNotIn("betas", calls["kw"])
        self.assertIsInstance(results[0].parsed, generate.Draft)
        self.assertIsNone(results[0].error)
        self.assertIn("errored", results[1].error)
        self.assertIn("not the JSON", results[2].error)
        self.assertEqual(model.usage["write"]["searches"], 4)
        self.assertIn("at batch prices", model.receipt())
        self.assertIn("4 searches", model.receipt())

    def test_a_refusal_and_a_pause_are_errors_not_cards(self):
        from types import SimpleNamespace as NS
        model = object.__new__(generate.Claude)
        model.client, model.model, model.batch, model.usage = None, generate.MODEL, False, {}
        spec = generate.Spec("s", [], generate.Draft)
        refused = NS(stop_reason="refusal", stop_details=NS(explanation="no"), content=[])
        self.assertIn("declined", model._finish(spec, refused).error)
        paused = NS(stop_reason="pause_turn", content=[])
        self.assertIn("paused", model._finish(spec, paused).error)


class TheModel(unittest.TestCase):
    """Which model the stages run on, and what the receipt charges for it."""

    def _model(self, name, batch=False):
        model = object.__new__(generate.Claude)
        model.client, model.model, model.batch, model.usage = None, name, batch, {}
        return model

    def test_the_receipt_charges_each_model_its_own_price(self):
        from collections import Counter
        u = Counter(input=1_000_000, output=0, cache_read=0, cache_write=0, searches=10)
        self.assertAlmostEqual(self._model("claude-opus-5").cost(u), 5.0 + 0.10)
        self.assertAlmostEqual(self._model("claude-sonnet-5").cost(u), 2.0 + 0.10)
        # The batch halves the tokens and never the searches.
        self.assertAlmostEqual(self._model("claude-sonnet-5", batch=True).cost(u), 1.0 + 0.10)
        # On Haiku the ten searches cost as much as the million tokens.
        self.assertAlmostEqual(self._model("claude-haiku-5-5").cost(u), 0.10 + 0.10)

    def test_the_stages_ask_the_model_they_were_given(self):
        model = self._model("claude-sonnet-5")
        spec = generate.Spec("s", [{"role": "user", "content": "x"}], generate.Draft)
        self.assertEqual(model._params(spec)["model"], "claude-sonnet-5")

    def _client(self):
        """A client that answers every call at once with a reading, and keeps what it was sent."""
        from types import SimpleNamespace as NS
        sent = []
        reply = generate.canned_reading().model_dump_json()

        def create(**kw):
            sent.append(kw)
            return NS(stop_reason="end_turn", content=[NS(type="text", text=reply)],
                      usage=NS(input_tokens=10, output_tokens=5, cache_read_input_tokens=0, cache_creation_input_tokens=0, server_tool_use=None))

        return NS(beta=NS(messages=NS(create=create))), sent

    def test_haiku_takes_the_older_tools_and_no_fallback(self):
        spec = generate.Spec("s", [{"role": "user", "content": "x"}], generate.Reading,
                             tools=[generate._web_search(generate.LEAD_SEARCHES), generate._web_fetch(generate.LEAD_FETCHES)])
        haiku = self._model("claude-haiku-5-5")
        params = haiku._params(spec)
        self.assertEqual([(t["type"], t["name"]) for t in params["tools"]], [("web_search_20250305", "web_search"), ("web_fetch_20250910", "web_fetch")])
        self.assertEqual([t["max_uses"] for t in params["tools"]], [generate.LEAD_SEARCHES, generate.LEAD_FETCHES])
        self.assertEqual(params["tools"][0]["blocked_domains"], sources.blocked(), "the same settings, under the older version")
        self.assertEqual(params["tools"][1]["max_content_tokens"], generate.HAIKU_PAGE_TOKENS,
                         "a page is cut short on Haiku, so a request stays under the price step at 100,000 tokens")
        self.assertGreater(spec.tools[1]["max_content_tokens"], generate.HAIKU_PAGE_TOKENS)
        self.assertNotIn("fallbacks", params)
        self.assertEqual(params["output_config"]["effort"], "high")
        self.assertEqual(spec.tools[0]["type"], "web_search_20260209", "the spec is left as it was")
        opus = self._model("claude-opus-5")
        self.assertEqual(opus._params(spec)["fallbacks"], "default")
        self.assertEqual([t["type"] for t in opus._params(spec)["tools"]], ["web_search_20260209", "web_fetch_20260209"])
        # The call: no beta for a fallback Haiku does not have, and never a sampling setting.
        haiku.client, sent = self._client()
        self.assertIsNone(haiku.call(spec, "read").error)
        self.assertNotIn("betas", sent[0])
        self.assertEqual(sent[0]["tools"][0]["type"], "web_search_20250305")
        opus.client, sent = self._client()
        self.assertIsNone(opus.call(spec, "read").error)
        self.assertEqual(sent[0]["betas"], [generate.FALLBACK_BETA])
        for key in ("temperature", "top_p", "top_k"):
            self.assertNotIn(key, sent[0])
        self.assertEqual(haiku.usage["read"]["input"], 10)

    def test_a_model_the_generator_does_not_run_on_is_refused(self):
        # Before any client is built, so no key is needed to be told.
        with self.assertRaises(ValueError):
            generate.Claude("claude-haiku-4-5")


class ThePlumbing(unittest.TestCase):
    def test_a_canned_model_flows_into_the_bank(self):
        bank = check.load_bank()
        requests = generate.plan(bank, 4)
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            outcomes = generate.run(requests, generate.Fake(), bank, out=out, today=TODAY, log=lambda *_: None)
            self.assertEqual([o.status for o in outcomes], ["written"] * 4)
            files = sorted(out.glob("*/*.json"))
            self.assertEqual(len(files), 4)
            for f in files:
                card = json.loads(f.read_text())
                self.assertEqual(card["written"], "2026-09-18")
                self.assertTrue(card["id"].startswith(card["topic"] + "-20260918-"))
                self.assertEqual(f.parent.name, card["topic"])
                self.assertEqual(check.check_card(card, strict=True, schema=check.load_schema(), banned=check.load_banned()), [])
                self.assertEqual(card["language"], "en")
                self.assertEqual("strand" in card, card["topic"] != "thinking")
                self.assertEqual(list(card)[:2], ["id", "topic"])
                # Written from a page: the reference is the page, the quote is on the card.
                self.assertTrue(card["reference"].startswith("https://example"), card["reference"])
                self.assertIn(card["source_kind"], sources.KINDS)
                self.assertTrue(card["quote"])
            # The outcome names the site of its own card, whichever file that is:
            # the plan's order follows the bank, and the files' order is the alphabet.
            first = next(f for f in files if f.stem == outcomes[0].id)
            self.assertEqual(outcomes[0].domain, sources.domain_of(json.loads(first.read_text())["reference"]))

    def test_a_thinking_card_is_arithmetic_and_skips_the_scout(self):
        bank = check.load_bank()
        req = generate.for_strand(None, "thinking", kind="pickOne", difficulty="medium", principle="baseRate", principles=["baseRate"])
        model = generate.Fake()
        with tempfile.TemporaryDirectory() as tmp:
            outcomes = generate.run([req], model, bank, out=Path(tmp), today=TODAY, log=lambda *_: None)
            self.assertEqual(model.calls, ["write", "critic"])
            self.assertEqual(outcomes[0].status, "written")
            card = json.loads(next(Path(tmp).glob("*/*.json")).read_text())
            self.assertEqual(card["source_kind"], "arithmetic")
            self.assertNotIn("quote", card)
            self.assertNotIn("strand", card)

    def test_a_find_that_does_not_hold_is_dropped_for_the_next(self):
        bank = check.load_bank()
        req = generate.for_strand(genres.strands_by_id()["space.the_moon.tides"], "space", kind="read", difficulty="easy", principle="none", source_kind="institution")
        unsupported = generate.Reading(supported=False, quote="", figures="", note="the page says nothing of the kind")
        model = generate.Fake(readings=[unsupported, generate.canned_reading()])
        with tempfile.TemporaryDirectory() as tmp:
            outcomes = generate.run([req], model, bank, out=Path(tmp), today=TODAY, critic=False, log=lambda *_: None)
            self.assertEqual(model.calls, ["scout", "read", "read", "write"])
            self.assertEqual(outcomes[0].status, "written")
            self.assertTrue(outcomes[0].domain.endswith("1.org"), "the second find's site")

    def test_no_find_holding_leaves_the_card_unsourced(self):
        bank = check.load_bank()
        req = generate.for_strand(genres.strands_by_id()["space.the_moon.tides"], "space", kind="read", difficulty="easy", principle="none")
        nothing = generate.Reading(supported=False, quote="", figures="", note="no")
        model = generate.Fake(readings=[nothing, nothing, nothing])
        with tempfile.TemporaryDirectory() as tmp:
            outcomes = generate.run([req], model, bank, out=Path(tmp), today=TODAY, log=lambda *_: None)
            self.assertEqual(outcomes[0].status, "unsourced")
            self.assertEqual(outcomes[0].stage, "read")
            self.assertEqual(model.calls, ["scout", "read", "read", "read"])
            self.assertEqual(list(Path(tmp).glob("*/*.json")), [])

    def test_without_research_the_writer_writes_from_memory(self):
        bank = check.load_bank()
        req = generate.for_strand(genres.strands_by_id()["space.the_moon.tides"], "space", kind="read", difficulty="easy", principle="none")
        model = generate.Fake()
        with tempfile.TemporaryDirectory() as tmp:
            outcomes = generate.run([req], model, bank, out=Path(tmp), today=TODAY, research=False, critic=False, log=lambda *_: None)
            self.assertEqual(model.calls, ["write"])
            self.assertEqual(outcomes[0].status, "written")
            card = json.loads(next(Path(tmp).glob("*/*.json")).read_text())
            self.assertNotIn("quote", card)
            self.assertEqual(card["source_kind"], "institution", "the canned draft's own")

    def test_a_rejected_card_is_not_written_and_a_bad_one_is_repaired_once(self):
        bank = check.load_bank()
        req = generate.for_strand(genres.strands_by_id()["space.the_moon.tides"], "space", kind="read", difficulty="easy", principle="none")
        bad = generate.canned("topic: space\nkind: read\ndifficulty: easy\nprinciple: none")
        bad = bad.model_copy(update={"move": "Short move."})
        good = generate.canned("topic: space\nkind: read\ndifficulty: easy\nprinciple: none")
        with tempfile.TemporaryDirectory() as tmp:
            model = generate.Fake(drafts=[bad, good], verdicts=[generate.Verdict(verdict="reject", reason="made up", fixed=None)])
            outcomes = generate.run([req], model, bank, out=Path(tmp), today=TODAY, log=lambda *_: None)
            self.assertEqual(model.calls, ["scout", "read", "write", "repair", "critic"])
            self.assertEqual(outcomes[0].status, "rejected")
            self.assertEqual(outcomes[0].stage, "critic")
            self.assertEqual(list(Path(tmp).glob("*/*.json")), [])

    def test_the_writer_keeps_the_strand_it_was_given(self):
        req = generate.for_strand(genres.strands_by_id()["space.the_moon.tides"], "space", kind="pickOne", difficulty="medium", principle="baseRate", principles=["baseRate", "sampling"])
        draft = generate.canned("topic: space\nkind: pickOne\ndifficulty: medium\nprinciple: sampling")
        card = generate.conform(generate.to_card(draft), req)
        self.assertEqual((card["genre"], card["strand"]), ("space.the_moon", "space.the_moon.tides"))
        self.assertEqual(card["principle"], "sampling", "the writer chose among the principles offered")
        other = generate.conform(generate.to_card(draft.model_copy(update={"principle": "anchoring"})), req)
        self.assertEqual(other["principle"], "baseRate", "a principle that was not offered is not kept")
        self.assertIn("The card is about Tides", generate.brief(req, []))
        self.assertIn("one of baseRate, sampling", generate.brief(req, []))
        find = generate.canned_finds("strand: Tides").finds[0]
        reading = generate.canned_reading()
        sourced = generate.conform(generate.to_card(draft.model_copy(update={"also": ["science.physics.gravity", "space.the_moon.tides", "nowhere.at.all"]})), req, find, reading)
        self.assertEqual(sourced["reference"], find.url)
        self.assertEqual(sourced["source_kind"], find.source_kind)
        self.assertEqual(sourced["quote"], reading.quote)
        self.assertEqual(sourced["also"], ["science.physics.gravity"], "its own strand and an unknown one are dropped")
        self.assertIn("passage from the page, verbatim", generate.from_find(find, reading))

    def test_the_tagger_fills_a_card_that_has_none(self):
        bank = check.load_bank()
        bare = {k: v for k, v in check.public(bank[0]).items() if k not in check.TAG_KEYS and k not in ("genre", "strand", "figure")}
        self.assertTrue(tag.untagged(bare))
        failed = tag.tag_cards([bare], generate.Fake(), bank, write=False, log=lambda *_: None)
        self.assertEqual(failed, [])
        tagged = tag.apply(bare, generate.Fake().tag("", json.dumps(bare)))
        self.assertFalse(tag.untagged(tagged))
        self.assertEqual(check.check_card(tagged, schema=check.load_schema(), banned=check.load_banned()), [])
        self.assertIn("The strands under", tag.brief(bare))

    def test_ids_never_collide(self):
        taken = {"space-20260918-1", "space-20260918-2"}
        self.assertEqual(generate.next_id("space", TODAY, taken), "space-20260918-3")

    def test_the_report_reads_as_a_pull_request(self):
        req = generate.for_strand(genres.strands_by_id()["space.the_moon.tides"], "space", kind="read", difficulty="easy", principle="none")
        text = generate.report(
            [generate.Outcome(request=req, status="written", id="space-20260918-1", question="Why?"),
             generate.Outcome(request=req, status="rejected", question="Why not?", note="made up")],
            "0 tokens", TODAY)
        self.assertIn("1 new card", text)
        self.assertIn("space-20260918-1", text)
        self.assertIn("The Moon · Tides", text)
        sourced = generate.Outcome(request=req, status="written", id="space-20260918-2", question="How?", domain="nasa.gov", source_kind="institution", checked=False)
        unsourced = generate.Outcome(request=req, status="unsourced", stage="read", note="no find held up")
        text = generate.report([sourced, unsourced], "0 tokens", TODAY)
        self.assertIn("nasa.gov (quote not machine-checked)", text)
        self.assertIn("*unsourced at the read*", text)
        self.assertIn("Not written (1)", text)


class TheLeads(unittest.TestCase):
    """Cards from videos: the placer, the scout that starts from a claim, the whole run."""

    def placement(self, **over) -> generate.Placement:
        p = dict(keep=True, why="Two bulges, and the far one is the surprise.", topic="space",
                 strand="space.the_moon.tides", kind="read", principle="none", difficulty="easy")
        return generate.Placement(**{**p, **over})

    def test_a_placement_is_held_to_the_tree_and_the_rules(self):
        problems = generate.placement_problems
        self.assertEqual(problems(self.placement()), [])
        self.assertEqual(problems(self.placement(kind="pickOne", principle="baseRate", difficulty="hard")), [])
        self.assertTrue(any("no strand is called" in p for p in problems(self.placement(strand="space.the_moon.cheese"))))
        self.assertTrue(any("not under" in p for p in problems(self.placement(strand="nature.oceans.coral"))))
        self.assertTrue(any("no strand is called" in p for p in problems(self.placement(topic="thinking", strand=""))), "a lead never goes to Thinking")
        self.assertTrue(any("not a subject" in p for p in problems(self.placement(topic="astrology"))))
        self.assertTrue(any("carries no principle" in p for p in problems(self.placement(principle="baseRate"))))
        self.assertTrue(any("carries no principle" in p for p in problems(self.placement(kind="debate", difficulty="medium", principle="anchoring"))))
        self.assertTrue(any("one of the principles" in p for p in problems(self.placement(kind="pickOne", difficulty="medium"))))
        self.assertTrue(any("one of the principles" in p for p in problems(self.placement(kind="number", difficulty="medium", principle="luck"))))
        self.assertTrue(any("is easy" in p for p in problems(self.placement(difficulty="medium"))))
        self.assertTrue(any("at least medium" in p for p in problems(self.placement(kind="number", principle="computation"))))

    def test_a_lead_turned_down_or_misplaced_is_an_outcome_and_never_asked_for(self):
        bank = check.load_bank()
        leads = [generate.Lead.model_validate(lead(id=f"yt-{i}")) for i in range(5)]
        model = generate.Fake(placements=[
            self.placement(),
            self.placement(kind="pickOne", principle="baseRate", difficulty="medium"),
            self.placement(keep=False, why="Advice about mornings, not a claim."),
            self.placement(strand="space.the_moon.cheese"),
            self.placement(kind="pickOne", difficulty="medium", principle="none"),
        ])
        placed = generate.place(leads, model, bank, log=lambda *_: None)
        self.assertEqual(model.calls, ["place"] * 5, "one stage, every lead in it")
        read, ask, turned_down, nowhere, mismatched = placed
        self.assertIsInstance(read, generate.Request)
        self.assertEqual((read.topic, read.genre, read.strand, read.kind, read.principle, read.principles),
                         ("space", "space.the_moon", "space.the_moon.tides", "read", "none", []))
        self.assertEqual((ask.kind, ask.principle, ask.principles), ("pickOne", "baseRate", ["baseRate"]))
        self.assertIn(read.source_kind, sources.kinds_for("space"))
        self.assertEqual(read.video, leads[0].video)
        self.assertIn("12 hours 25 minutes", read.lead)
        self.assertEqual(read.links, ["https://tidesandcurrents.noaa.gov/restles1.html"], "a link on a blocked site is no use to the tools")
        self.assertIn("from https://www.youtube.com", str(read))
        self.assertEqual((turned_down.status, turned_down.stage, turned_down.note, turned_down.lead),
                         ("rejected", "place", "Advice about mornings, not a claim.", "yt-2"))
        self.assertEqual((nowhere.status, mismatched.status), ("refused", "refused"))
        self.assertIn("space.the_moon.cheese", nowhere.note)
        self.assertIn("one of the principles", mismatched.note)
        self.assertEqual(str(turned_down.request), f"a lead from {leads[2].video}")
        text = generate.report([turned_down], "0 tokens", TODAY)
        self.assertIn("*rejected at the place*: Advice about mornings", text)

    def test_a_lead_s_scout_starts_from_the_claim_and_the_links(self):
        req = generate.for_strand(genres.strands_by_id()["space.the_moon.tides"], "space", kind="read", difficulty="easy",
                                  principle="none", **generate.lead_fields(generate.Lead.model_validate(lead())))
        text = generate.scout_brief(req, [])
        self.assertIn("a pointer, never a source", text)
        self.assertIn("claim, as the video states it: The Moon raises two bulges", text)
        self.assertIn("figures, as the video gives them: 12 hours 25 minutes", text)
        self.assertIn("- https://tidesandcurrents.noaa.gov/restles1.html", text)
        self.assertNotIn("instagram", text)
        self.assertEqual([(t["type"], t["max_uses"]) for t in generate.scout_tools(req)], [("web_search_20260209", 3), ("web_fetch_20260209", 4)])
        self.assertEqual([t["max_uses"] for t in generate.critic_tools(req)], [1, 2])
        plain = req.model_copy(update={"lead": "", "links": [], "video": ""})
        self.assertNotIn("pointer", generate.scout_brief(plain, []))
        self.assertEqual([t["max_uses"] for t in generate.scout_tools(plain)], [generate.SCOUT_SEARCHES])
        self.assertEqual([t["max_uses"] for t in generate.critic_tools(plain)], [generate.CRITIC_SEARCHES, 2])

    def test_a_lead_file_is_held_to_its_shape(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "leads.json"
            path.write_text(json.dumps([lead(), lead(id="yt-2", figures=None, links=[])]), encoding="utf-8")
            first, second = generate.load_leads(path)
            self.assertEqual(first.figures, "12 hours 25 minutes between high tides", "a list of figures is read as one line")
            self.assertEqual(second.figures, "")
            path.write_text(json.dumps([lead(), {k: v for k, v in lead().items() if k != "idea"}]), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "lead 1: idea"):
                generate.load_leads(path)
            path.write_text(json.dumps(lead()), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "a JSON list"):
                generate.load_leads(path)

    def test_leads_flow_into_the_bank_with_their_scenes(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            path = tmp / "leads.json"
            path.write_text(json.dumps([lead(id="yt-a"), lead(id="yt-b", video="https://youtu.be/b"), lead(id="yt-c", links=[])]), encoding="utf-8")
            with contextlib.redirect_stdout(io.StringIO()) as printed:
                self.assertEqual(generate.main(["--leads", str(path), "--dry-run"]), 0)
            self.assertIn("placer system prompt", printed.getvalue())
            self.assertIn("Start from this lead", printed.getvalue())
            with contextlib.redirect_stdout(io.StringIO()):
                code = generate.main(["--leads", str(path), "--fake", "--out", str(tmp / "bank"), "--today", "2026-10-24",
                                      "--outcomes", str(tmp / "outcomes.json"), "--report", str(tmp / "report.md")])
            self.assertEqual(code, 0)
            outcomes = json.loads((tmp / "outcomes.json").read_text())
            self.assertEqual([(o["lead"], o["status"], o["scene"]) for o in outcomes],
                             [("yt-a", "written", "count"), ("yt-b", "written", "count"), ("yt-c", "written", "count")])
            files = sorted((tmp / "bank").glob("*/*.json"))
            self.assertEqual(len(files), 3)
            schema, banned = check.load_schema(), check.load_banned()
            for f in files:
                card = json.loads(f.read_text())
                self.assertEqual(card["written"], "2026-10-24")
                self.assertEqual(check.check_card(card, strict=True, schema=schema, banned=banned), [])
                self.assertEqual(card["scene"]["type"], "count", "the canned scene, checked and filed")
                self.assertTrue(card["quote"])
                self.assertNotIn("youtu", card["reference"], "the video is never the source")
            report = (tmp / "report.md").read_text()
            self.assertIn("3 of 3 got a scene", report)
            self.assertIn("from [a video](https://youtu.be/b)", report)
            self.assertIn("never the video", report)

    def test_a_lead_goes_through_every_stage_once(self):
        bank = check.load_bank()
        model = generate.Fake(placements=[self.placement()])
        with tempfile.TemporaryDirectory() as tmp:
            outcomes = generate.run_leads([generate.Lead.model_validate(lead())], model, bank, out=Path(tmp), today=TODAY, log=lambda *_: None)
            self.assertEqual(model.calls, ["place", "scout", "read", "write", "critic", "scene"])
            self.assertEqual((outcomes[0].status, outcomes[0].lead, outcomes[0].request.strand), ("written", "yt-tides-1", "space.the_moon.tides"))
            model = generate.Fake(placements=[self.placement()], finds=[generate.Finds(finds=[])])
            outcomes = generate.run_leads([generate.Lead.model_validate(lead())], model, bank, out=Path(tmp), today=TODAY, scenes=False, log=lambda *_: None)
            self.assertEqual(model.calls, ["place", "scout"])
            self.assertEqual((outcomes[0].status, outcomes[0].note), ("unsourced", "the scout found nothing that holds"))


class TheScenes(unittest.TestCase):
    """The scene a card is offered once it is written: filed only when it passes."""

    def written(self, out: Path, n: int) -> tuple[list[dict], list]:
        bank = check.load_bank()
        strands = ["space.the_moon.tides", "space.the_moon.moon_dust", "space.black_holes.event_horizons"][:n]
        requests = [generate.for_strand(genres.strands_by_id()[s], "space", kind="read", difficulty="easy", principle="none") for s in strands]
        outcomes = generate.run(requests, generate.Fake(), bank, out=out, today=TODAY, critic=False, log=lambda *_: None)
        self.assertEqual([o.status for o in outcomes], ["written"] * n)
        return bank, outcomes

    def test_a_scene_that_passes_is_filed_and_one_that_does_not_is_dropped(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            bank, outcomes = self.written(out, 2)
            path = lambda o: out / o.request.topic / f"{o.id}.json"
            before = path(outcomes[1]).read_text()
            broken = generate.SceneChoice(type="rank", scene_json=json.dumps({"type": "rank", "quantity": "Dust", "items": []}))
            model = generate.Fake(scenes=[generate.canned_scene(""), broken, broken])
            self.assertEqual(generate.add_scenes(outcomes, model, bank, out=out, log=lambda *_: None), 1)
            self.assertEqual(model.calls, ["scene", "scene", "scene-repair"], "one round of repair, for the one that failed")
            kept = json.loads(path(outcomes[0]).read_text())
            self.assertEqual(kept["scene"]["type"], "count")
            self.assertLess(list(kept).index("scene"), list(kept).index("source"), "the house order of keys")
            self.assertEqual(check.check_card(kept, strict=True, schema=check.load_schema(), banned=check.load_banned()), [])
            self.assertEqual((outcomes[0].scene, outcomes[1].scene), ("count", ""))
            self.assertIn("did not pass its check", outcomes[1].scene_note)
            self.assertEqual(path(outcomes[1]).read_text(), before, "the card stays as it was written")
            self.assertIn("1 of 2 got a scene", generate.report(outcomes, "0 tokens", TODAY))

    def test_a_scene_is_repaired_once_and_none_is_an_answer(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            bank, outcomes = self.written(out, 3)
            fenced = generate.canned_scene("")
            fenced = fenced.model_copy(update={"scene_json": "```json\n" + fenced.scene_json + "\n```"})
            not_json = generate.SceneChoice(type="count", scene_json="{the scene")
            none = generate.SceneChoice(type="none", scene_json="")
            model = generate.Fake(scenes=[not_json, none, fenced, fenced])
            self.assertEqual(generate.add_scenes(outcomes, model, bank, out=out, log=lambda *_: None), 2)
            self.assertEqual([o.scene for o in outcomes], ["count", "", "count"])
            self.assertEqual(outcomes[1].scene_note, "no scene fits")
            self.assertNotIn("scene", json.loads((out / "space" / f"{outcomes[1].id}.json").read_text()))
            problems = generate.parse_scene(not_json, "2026-09-18")[1]
            self.assertTrue(problems and "not JSON" in problems[0])
            other = generate.SceneChoice(type="rank", scene_json=generate.canned_scene("").scene_json)
            self.assertIn("the scene says 'count'", generate.parse_scene(other, "2026-09-18")[1][0])


if __name__ == "__main__":
    unittest.main()
