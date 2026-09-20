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
    }
    card.update(over)
    return card


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
            read_card(id="thinking-a", topic="thinking", kind="pickOne", difficulty="medium", principle="baseRate", options=["A", "B"], correct=0, trap="B."),
            read_card(id="thinking-b", topic="thinking", kind="pickOne", difficulty="medium", principle="baseRate", options=["A", "B"], correct=0, trap="B."),
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

    def test_a_rejected_card_is_not_written_and_a_bad_one_is_repaired_once(self):
        bank = check.load_bank()
        req = generate.Request(topic="space", kind="read", difficulty="easy", principle="none")
        bad = generate.canned("topic: space\nkind: read\ndifficulty: easy\nprinciple: none")
        bad = bad.model_copy(update={"move": "Short move."})
        good = generate.canned("topic: space\nkind: read\ndifficulty: easy\nprinciple: none")
        with tempfile.TemporaryDirectory() as tmp:
            model = generate.Fake(drafts=[bad, good], verdicts=[generate.Verdict(verdict="reject", reason="made up", fixed=None)])
            outcomes = generate.run([req], model, bank, out=Path(tmp), today=TODAY, log=lambda *_: None)
            self.assertEqual(model.calls, ["write", "repair", "critique"])
            self.assertEqual(outcomes[0].status, "rejected")
            self.assertEqual(list(Path(tmp).glob("*/*.json")), [])

    def test_ids_never_collide(self):
        taken = {"space-20260918-1", "space-20260918-2"}
        self.assertEqual(generate.next_id("space", TODAY, taken), "space-20260918-3")

    def test_the_report_reads_as_a_pull_request(self):
        req = generate.Request(topic="space", kind="read", difficulty="easy", principle="none")
        text = generate.report(
            [generate.Outcome(request=req, status="written", id="space-20260918-1", question="Why?"),
             generate.Outcome(request=req, status="rejected", question="Why not?", note="made up")],
            "0 tokens", TODAY)
        self.assertIn("1 new card", text)
        self.assertIn("space-20260918-1", text)
        self.assertIn("Not written (1)", text)


if __name__ == "__main__":
    unittest.main()
