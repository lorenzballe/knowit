"""The pipeline without the model: the gate, the plan, the plumbing.

    python3 -m unittest discover tool/cards
"""
from __future__ import annotations

import datetime as dt
import json
import tempfile
import unittest
from pathlib import Path

import bundle
import check
import generate
import genres
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
    }
    card.update(over)
    return card


def thinking_card(**over) -> dict:
    card = read_card(kind="pickOne", difficulty="medium", principle="baseRate", options=["A", "B"], correct=0, trap="Taking B.", topic="thinking", numeracy=3)
    for key in ("genre", "strand"):
        card.pop(key, None)
    card.update(over)
    return card


class TheGenres(unittest.TestCase):
    def test_the_tree_is_read_off_the_app(self):
        tree = genres.by_topic()
        self.assertEqual(len(tree), 18)
        self.assertNotIn("thinking", tree)
        for topic, gs in tree.items():
            self.assertEqual(len(gs), 6, topic)
            for g in gs:
                self.assertEqual(len(g.strands), 3, g.id)
                self.assertEqual(g.topic, topic)
                for s in g.strands:
                    self.assertEqual(s.genre, g.id)
                    self.assertTrue(s.id.startswith(g.id + "."))
        self.assertEqual(len(genres.strands_by_id()), 324)
        self.assertEqual(genres.describe("space.black_holes.event_horizons"), "Black holes · Event horizons")
        self.assertEqual(genres.strands_of("thinking"), [])


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

    def test_links_name_real_cards(self):
        a = read_card(id="space-a")
        b = read_card(id="space-b", question="How many probes have left the solar system so far?", move="Count the probes, not the press releases about them.", builds_on=["space-a"])
        self.assertEqual(check.check_links([a, b]), [])
        self.assertTrue(any("not in the bank" in p for p in check.check_links([b])))
        self.assertTrue(any("retired" in p for p in check.check_links([b], against=[dict(a, disabled=True)])))

    def test_the_house_order_of_keys(self):
        keys = list(check.ordered(read_card(reference="x", written="2026-09-18")))
        self.assertEqual(keys[:4], ["id", "topic", "genre", "strand"])
        self.assertEqual(keys[-3:], ["source", "reference", "written"])
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
        self.assertEqual(check.check_editions({"1": "thinking-a", "2": "thinking-b"}, cards), [])
        self.assertTrue(any("cannot be marked" in p for p in check.check_editions({"1": "space-r"}, cards)))
        self.assertTrue(any("comes back" in p for p in check.check_editions({"1": "thinking-a", "2": "thinking-a"}, cards)))
        self.assertTrue(any("not in the bank" in p for p in check.check_editions({"1": "nobody"}, cards)))
        self.assertTrue(any("consecutive" in p for p in check.check_editions({"1": "thinking-a", "3": "thinking-b"}, cards)))


class TheCalendar(unittest.TestCase):
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

    def test_a_rejected_card_is_not_written_and_a_bad_one_is_repaired_once(self):
        bank = check.load_bank()
        req = generate.for_strand(genres.strands_by_id()["space.the_moon.tides"], "space", kind="read", difficulty="easy", principle="none")
        bad = generate.canned("topic: space\nkind: read\ndifficulty: easy\nprinciple: none")
        bad = bad.model_copy(update={"move": "Short move."})
        good = generate.canned("topic: space\nkind: read\ndifficulty: easy\nprinciple: none")
        with tempfile.TemporaryDirectory() as tmp:
            model = generate.Fake(drafts=[bad, good], verdicts=[generate.Verdict(verdict="reject", reason="made up", fixed=None)])
            outcomes = generate.run([req], model, bank, out=Path(tmp), today=TODAY, log=lambda *_: None)
            self.assertEqual(model.calls, ["write", "repair", "critique"])
            self.assertEqual(outcomes[0].status, "rejected")
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
        self.assertIn("Not written (1)", text)


if __name__ == "__main__":
    unittest.main()
