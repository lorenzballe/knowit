"""The quality layer, without a key: python3 -m unittest discover -s tool/quality"""
from __future__ import annotations

import contextlib
import datetime as dt
import io
import json
import random
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import common  # noqa: E402  (puts tool/cards on the path)
import check  # noqa: E402
import generate  # noqa: E402

import confidence  # noqa: E402
import evalset  # noqa: E402
import mutate  # noqa: E402
import recheck  # noqa: E402
import review  # noqa: E402
import route  # noqa: E402

BANK = check.load_bank()
LIVE = [c for c in BANK if not c.get("disabled")]
TODAY = dt.date(2026, 10, 8)


def first(where) -> dict:
    return next(c for c in LIVE if where(c))


def draft_of(card: dict, **change) -> generate.Draft:
    """A bank card as the model would write it back."""
    values = {}
    for name, f in generate.Draft.model_fields.items():
        if name in card:
            values[name] = card[name]
        elif f.annotation in (str,):
            values[name] = ""
        elif name in ("steps", "options", "sides", "also", "keywords", "builds_on"):
            values[name] = []
        elif name in ("correct", "numeracy"):
            values[name] = 0
        elif name in ("value", "tolerance", "withinFactor"):
            values[name] = 0.0
        elif name == "mature":
            values[name] = False
        elif name == "figure":
            values[name] = "none"
        else:
            values[name] = ""
    values.update(change)
    return generate.Draft(**values)


def outcome(**over) -> dict:
    """A written card's outcome, as generate.py --outcomes writes it."""
    base = dict(
        request={"topic": "space", "kind": "read", "difficulty": "easy", "principle": "none",
                 "genre": "space.the_moon", "strand": "space.the_moon.tides", "source_kind": "institution"},
        status="written", stage="", id="space-20261008-1", question="Why are there two tides a day?",
        note="", domain="nasa.gov", source_kind="institution", checked=True, kind="read",
        shelf_life="evergreen", asked_source_kind="institution", tried=1, repaired=False,
        verdict="pass", critic_reason="held", fix_refused=False,
    )
    base.update(over)
    return base


def usual(topic: str) -> list[str]:
    return ["nasa.gov", "esa.int"]


def under(domain: str, pattern: str) -> bool:
    return domain == pattern or domain.endswith("." + pattern)


# --------------------------------------------------------------------------

class TheMutations(unittest.TestCase):
    def test_each_kind_plants_one_error_where_it_fits(self):
        rng = random.Random(3)
        for kind, fn in mutate.MUTATIONS.items():
            planted = None
            for card in LIVE:
                planted = mutate.plant(card, rng, donors=LIVE, kinds=[kind])
                if planted:
                    break
            self.assertIsNotNone(planted, kind)
            self.assertEqual(planted.kind, kind)
            changed = {k for k in set(planted.card) | set(card) if planted.card.get(k) != card.get(k)}
            allowed = {"reference", "source", "quote"} if kind == "borrowed_source" else {"answer", "correct", "value"}
            self.assertTrue(changed and changed <= allowed, (kind, changed))

    def test_a_figure_keeps_its_shape(self):
        self.assertEqual(mutate._format_like("1,500", 15000), "15,000")
        self.assertEqual(mutate._format_like("2.5", 25), "25.0")
        self.assertEqual(mutate._format_like("40", 4), "4")

    def test_nothing_is_planted_where_nothing_fits(self):
        card = first(lambda c: c["kind"] == "read")
        self.assertIsNone(mutate.plant(card, random.Random(1), kinds=["wrong_key"]))


class TheEvalSet(unittest.TestCase):
    def test_every_error_as_often_as_the_others_and_as_many_clean_cards(self):
        items = evalset.build(BANK, per_kind=3, seed=2)
        planted = Counter(i.planted for i in items if i.planted)
        self.assertEqual(set(planted.values()), {3})
        self.assertEqual(set(planted), set(mutate.MUTATIONS))
        clean = [i for i in items if not i.planted]
        self.assertEqual(len(clean), sum(planted.values()))
        bases = [i.id.split("~")[0] for i in items]
        self.assertEqual(len(bases), len(set(bases)), "no card twice")

    def test_the_same_seed_asks_the_same_questions(self):
        a = [i.id for i in evalset.build(BANK, per_kind=2, seed=5)]
        b = [i.id for i in evalset.build(BANK, per_kind=2, seed=5)]
        self.assertEqual(a, b)

    def test_a_catch_is_a_stop_and_a_false_alarm_is_a_reject(self):
        items = evalset.build(BANK, per_kind=2, seed=4)
        planted = [i for i in items if i.planted]
        clean = [i for i in items if not i.planted]
        verdicts = {i.id: {"verdict": "reject" if n % 2 == 0 else "pass", "why": "x"} for n, i in enumerate(planted)}
        verdicts[planted[1].id] = {"verdict": "fix", "why": "figure"}
        verdicts.update({i.id: {"verdict": "pass"} for i in clean})
        verdicts[clean[0].id] = {"verdict": "reject", "why": "too easy"}
        verdicts[clean[1].id] = {"verdict": "fix", "why": "a tag"}
        s = evalset.score(items, verdicts)
        self.assertEqual(s.planted, len(planted))
        self.assertEqual(s.caught, len(planted) // 2 + 1)
        self.assertEqual(s.false_alarms, 1, "a fix on a good card is not a false alarm")
        text = evalset.report(s)
        self.assertIn("Planted errors caught", text)
        self.assertIn("Good cards it rejected", text)

    def test_the_runner_asks_the_critic_as_the_night_does(self):
        import evals

        items = evalset.build(BANK, per_kind=1, seed=1)
        model = generate.Fake()
        verdicts = evals.ask(items, model)
        self.assertEqual(set(verdicts), {i.id for i in items})
        self.assertEqual(model.calls, ["eval"] * len(items))
        self.assertTrue(all(v["verdict"] == "pass" for v in verdicts.values()), "the canned critic passes everything")


class TheConfidence(unittest.TestCase):
    def test_a_clean_run_is_trusted(self):
        t = confidence.trust(outcome(), usual, under)
        self.assertEqual((t.score, t.doubts), (100, []))
        self.assertTrue(t.confident)

    def test_every_doubt_costs_and_says_why(self):
        t = confidence.trust(outcome(verdict="fix", critic_reason="the year was 1969", checked=False, tried=2,
                                     shelf_life="months", kind="number", repaired=True, domain="someblog.net",
                                     source_kind="news"), usual, under)
        self.assertLess(t.score, confidence.CONFIDENT)
        self.assertEqual(t.score, max(0, 100 - 20 - 25 - 10 - 5 - 5 - 10 - 15 - 5))
        joined = " | ".join(t.doubts)
        for words in ("1969", "could not be found on the page", "first source", "someblog.net", "a news where a institution",
                      "sent it back", "within months", "worked number"):
            self.assertIn(words, joined)

    def test_no_critic_is_never_confident(self):
        self.assertFalse(confidence.trust(outcome(verdict=""), usual, under).confident)

    def test_a_thinking_card_is_not_asked_for_a_page(self):
        thinking = outcome(request={"topic": "thinking", "kind": "pickOne", "strand": ""}, checked=False, domain="", kind="pickOne")
        self.assertEqual(confidence.trust(thinking, usual, under).score, 100)

    def test_the_real_sources_list_is_used_by_default(self):
        t = confidence.trust(outcome(domain="nowhere-anyone-cites.example"))
        self.assertTrue(any("usual sources" in d for d in t.doubts))


class TheRouting(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.bank, self.review = root / "bank", root / "review"
        self.outcomes = []
        source = first(lambda c: c["topic"] == "space" and c["kind"] == "read")
        for n in range(1, 13):
            cid = f"space-20261008-{n}"
            common.write_card({**check.public(source), "id": cid}, self.bank / "space" / f"{cid}.json")
            doubtful = n in (4, 9)
            self.outcomes.append(outcome(id=cid, checked=not doubtful, verdict="fix" if doubtful else "pass"))
        self.outcomes.append(outcome(id="", status="rejected"))

    def tearDown(self):
        self.tmp.cleanup()

    def test_the_doubtful_and_a_sample_go_to_a_person(self):
        trust = lambda o: confidence.trust(o, usual, under)  # noqa: E731
        published, reviewing = route.split(self.outcomes, today=TODAY, trust=trust)
        self.assertEqual(len(published) + len(reviewing), 12)
        doubtful = [r for r in reviewing if not r.audit]
        self.assertEqual(sorted(r.id for r in doubtful), ["space-20261008-4", "space-20261008-9"])
        self.assertEqual(len([r for r in reviewing if r.audit]), 1, "one in ten of the confident")
        again = route.split(self.outcomes, today=TODAY, trust=trust)[1]
        self.assertEqual([r.id for r in again], [r.id for r in reviewing], "the same night draws the same sample")

        moved = route.send_to_review(reviewing, bank=self.bank, review=self.review, queue=self.review / "queue.json", today=TODAY)
        self.assertEqual(len(moved), 3)
        for cid in moved:
            self.assertFalse((self.bank / "space" / f"{cid}.json").exists())
            self.assertTrue((self.review / f"{cid}.json").exists())
        queue = common.read_queue(self.review / "queue.json")
        self.assertEqual([q["id"] for q in queue], moved)
        self.assertTrue(all(q["since"] == "2026-10-08" and q["from"] == "generator" for q in queue))
        text = route.section(published, reviewing)
        self.assertIn("Published with this batch (9)", text)
        self.assertIn("Waiting for a person (3)", text)

    def test_the_command_routes_and_writes_the_report(self):
        path = Path(self.tmp.name) / "outcomes.json"
        path.write_text(json.dumps(self.outcomes))
        report = Path(self.tmp.name) / "report.md"
        report.write_text("## 12 new cards\n")
        with contextlib.redirect_stdout(io.StringIO()):
            route.main(["--outcomes", str(path), "--report", str(report), "--today", "2026-10-08",
                        "--bank", str(self.bank), "--review", str(self.review)])
        self.assertIn("Who reads what", report.read_text())
        self.assertGreaterEqual(len(list(self.review.glob("space-*.json"))), 2)


class TheReview(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.bank, self.review = root / "bank", root / "review"
        self.pick = {**check.public(first(lambda c: c["kind"] == "pickOne")), "id": "art-20261008-1", "topic": "art"}
        self.read = {**check.public(first(lambda c: c["kind"] == "read")), "id": "art-20261008-2", "topic": "art"}
        self.other = {**check.public(first(lambda c: c["kind"] == "read")), "id": "art-20261008-3", "topic": "art"}
        queue = []
        for card in (self.pick, self.read, self.other):
            common.write_card(card, self.review / f"{card['id']}.json")
            queue.append({"id": card["id"], "topic": "art", "question": card["question"], "score": 50,
                          "why": ["its quote could not be found on the page by machine"], "since": "2026-10-08", "from": "generator"})
        common.write_queue(queue, self.review / "queue.json")

    def tearDown(self):
        self.tmp.cleanup()

    def test_the_issue_shows_each_card_whole_with_two_boxes(self):
        text = review.body(common.read_queue(self.review / "queue.json"), self.review)
        self.assertTrue(text.startswith(review.MARK))
        self.assertEqual(text.count("- [ ] Publish"), 3)
        self.assertEqual(text.count("- [ ] Drop"), 3)
        self.assertIn(self.pick["question"].strip(), text)
        right = self.pick["options"][self.pick["correct"]]
        self.assertIn(f"{right} ✓", text)
        self.assertEqual(review.ticks(text), {})

    def test_the_ticks_publish_drop_or_wait(self):
        text = review.body(common.read_queue(self.review / "queue.json"), self.review)
        lines = text.splitlines()
        def tick(card_id: str, box: str):
            at = lines.index(f"### `{card_id}`")
            i = next(n for n in range(at, len(lines)) if lines[n] == f"- [ ] {box}")
            lines[i] = f"- [x] {box}"
        tick(self.pick["id"], "Publish")
        tick(self.read["id"], "Drop")
        tick(self.other["id"], "Publish")
        tick(self.other["id"], "Drop")
        edited = "\n".join(lines)
        self.assertEqual(review.ticks(edited), {self.pick["id"]: {"Publish"}, self.read["id"]: {"Drop"}, self.other["id"]: {"Publish", "Drop"}})
        done = review.apply(edited, today=TODAY, review=self.review, bank=self.bank)
        self.assertEqual(done.published, [self.pick["id"]])
        self.assertEqual(done.dropped, [self.read["id"]])
        self.assertEqual(done.both, [self.other["id"]])
        published = json.loads((self.bank / "art" / f"{self.pick['id']}.json").read_text())
        self.assertEqual(published["checked"], "2026-10-08")
        self.assertEqual(check.check_card(published, schema=check.load_schema()), [], "the checked date is a field the schema knows")
        self.assertFalse((self.review / f"{self.pick['id']}.json").exists())
        self.assertFalse((self.review / f"{self.read['id']}.json").exists())
        self.assertFalse((self.bank / "art" / f"{self.read['id']}.json").exists())
        left = common.read_queue(self.review / "queue.json")
        self.assertEqual([q["id"] for q in left], [self.other["id"]])
        again = review.body(left, self.review)
        self.assertEqual(again.count("- [ ] Publish"), 1)
        self.assertIn("Both boxes ticked", done.summary())


class TheRecheck(unittest.TestCase):
    def test_what_is_due_comes_in_order_of_need(self):
        quarantined = first(lambda c: c.get("shelf_life") == "evergreen")
        disputed = first(lambda c: c.get("shelf_life") == "evergreen" and c["id"] != quarantined["id"])
        moving = first(lambda c: c.get("shelf_life") == "months" and not c.get("checked"))
        stats = {"quarantined": [quarantined["id"]], "flags": {quarantined["id"]: ["reported", "disputed", "quarantined"],
                                                              disputed["id"]: ["reported", "disputed"]},
                 "reports": {quarantined["id"]: {"fact": 3}, disputed["id"]: {"source": 2}}}
        due = recheck.due(BANK, stats, dt.date(2027, 6, 1), limit=500)
        ids = [d.card["id"] for d in due]
        self.assertEqual(ids[0], quarantined["id"])
        self.assertEqual(ids[1], disputed["id"])
        self.assertIn("fact ×3", due[0].why)
        self.assertIn(moving["id"], ids, "a moving answer checked long ago")
        self.assertTrue(all(d.card.get("shelf_life") != "evergreen" for d in due[2:]), "evergreen only when readers say so")
        self.assertEqual(len(recheck.due(BANK, stats, dt.date(2027, 6, 1), limit=3)), 3)

    def test_a_card_checked_lately_rests(self):
        card = {**first(lambda c: c.get("shelf_life") == "months"), "checked": "2027-05-20"}
        self.assertEqual(recheck.due([card], None, dt.date(2027, 6, 1), limit=5), [])
        flagged = {"flags": {card["id"]: ["disputed"]}}
        self.assertEqual(recheck.due([card], flagged, dt.date(2027, 6, 1), limit=5), [])
        self.assertEqual(len(recheck.due([card], flagged, dt.date(2027, 7, 1), limit=5)), 1)

    def test_what_each_verdict_does_to_the_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            bank, rev = root / "bank", root / "review"
            cards = [check.public(c) for c in [c for c in LIVE if c["kind"] == "read"][:4]]
            for c in cards:
                common.write_card(c, bank / c["topic"] / f"{c['id']}.json")
            held, wrong, outdated, silent = (recheck.Due(c, "its answer can change", 3) for c in cards)
            Verdict = generate.Verdict
            fixed = draft_of(cards[2], move=cards[2]["move"] + " Twice.")
            results = [
                (held, generate.Result(Verdict(verdict="pass", reason="still true", fixed=None), None, None)),
                (wrong, generate.Result(Verdict(verdict="reject", reason="the record fell in 2027", fixed=None), None, None)),
                (outdated, generate.Result(Verdict(verdict="fix", reason="the figure moved", fixed=fixed), None, None)),
                (silent, generate.Result(None, None, "the batch request expired")),
            ]
            done = recheck.apply(results, today=TODAY, bank_root=bank, review=rev)
            self.assertEqual([r.verdict for r in done], ["pass", "reject", "fix", "none"])
            path = lambda c: bank / c["topic"] / f"{c['id']}.json"  # noqa: E731
            self.assertEqual(json.loads(path(cards[0]).read_text())["checked"], "2026-10-08")
            self.assertTrue(json.loads(path(cards[1]).read_text())["disabled"])
            self.assertEqual(json.loads(path(cards[2]).read_text()), cards[2], "the live card stays until a person says")
            proposal = json.loads((rev / f"{cards[2]['id']}.json").read_text())
            self.assertTrue(proposal["move"].endswith("Twice."))
            self.assertEqual(proposal["id"], cards[2]["id"])
            self.assertEqual(proposal["checked"], "2026-10-08")
            queue = common.read_queue(rev / "queue.json")
            self.assertEqual([(q["id"], q["from"]) for q in queue], [(cards[2]["id"], "recheck")])
            self.assertEqual(json.loads(path(cards[3]).read_text()), cards[3])
            text = recheck.report(done, [held, wrong, outdated, silent], "no tokens", TODAY)
            for heading in ("Still true (1)", "A correction proposed (1)", "Retired (1)", "No verdict (1)"):
                self.assertIn(heading, text)

    def test_the_critic_is_told_it_is_checking_a_live_card(self):
        card = {**first(lambda c: c["kind"] == "read"), "quote": "A passage copied from the page, word for word, by the reader."}
        text = recheck.brief(recheck.Due(card, "readers dispute it", 1))
        self.assertIn("already live", text)
        self.assertIn("readers dispute it", text)
        self.assertIn(card["quote"].strip()[:30], text)


class TheGenerator(unittest.TestCase):
    def test_the_budget_stops_the_night_before_anything_is_filed(self):
        class Costly(generate.Fake):
            usage = {"scout": Counter(input=1)}

            def cost(self, u):
                return 50.0

        bank = check.load_bank()
        requests = generate.plan(bank, 2)
        with tempfile.TemporaryDirectory() as tmp:
            outcomes = generate.run(requests, Costly(), bank, out=Path(tmp), today=TODAY, budget=10, log=lambda *_: None)
            self.assertEqual([o.status for o in outcomes], ["failed", "failed"])
            self.assertTrue(all("budget" in o.note for o in outcomes))
            self.assertEqual(list(Path(tmp).glob("*/*.json")), [])
            # And a night within it runs as before.
            outcomes = generate.run(requests, generate.Fake(), bank, out=Path(tmp), today=TODAY, budget=10, log=lambda *_: None)
            self.assertEqual([o.status for o in outcomes], ["written", "written"])

    def test_the_outcome_keeps_how_the_card_got_through(self):
        bank = check.load_bank()
        req = generate.for_strand(None, "thinking", kind="pickOne", difficulty="medium", principle="baseRate", principles=["baseRate"])
        model = generate.Fake(verdicts=[generate.Verdict(verdict="fix", reason="one option was defensible", fixed=None)])
        with tempfile.TemporaryDirectory() as tmp:
            o = generate.run([req], model, bank, out=Path(tmp), today=TODAY, log=lambda *_: None)[0]
        self.assertEqual(o.status, "written")
        self.assertEqual((o.verdict, o.critic_reason, o.kind), ("fix", "one option was defensible", "pickOne"))
        self.assertEqual(o.shelf_life, "evergreen")
        self.assertFalse(o.repaired)
        dumped = json.loads(json.dumps(o.model_dump()))
        self.assertEqual(confidence.trust(dumped).score, 100 - confidence.COST["critic corrected"])


if __name__ == "__main__":
    unittest.main()
