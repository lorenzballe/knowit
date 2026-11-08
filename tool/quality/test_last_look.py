"""The last look, without a key: a stand-in for TypeSafe answers every question."""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import common  # noqa: E402
import last_look as L  # noqa: E402

CARD = {
    "id": "space-test-card",
    "topic": "space",
    "kind": "pickOne",
    "question": "Why does a probe swing past Jupiter on its way to Saturn?",
    "options": ["To steal speed from Jupiter", "To take photographs"],
    "correct": 0,
    "answer": "Falling past Jupiter, the probe picks up some of the planet's orbital speed.",
    "trap": "Taking photographs on the way.",
    "move": "Borrow speed from what is already moving.",
    "ask": "What fast thing could I borrow from today?",
    "source": "NASA",
    "keywords": ["gravity assist"],
    "era": "recent",
}


def answering(values: dict[str, float] | None = None, default: float = 0.05, strengths: float = 0.9):
    """A transport that answers every question: flaws `default`, notes
    `strengths`, and anything in `values` as given. It keeps what it was sent."""
    sent: list[tuple[dict, dict]] = []

    def transport(body: dict, headers: dict) -> dict:
        sent.append((body, headers))
        answers = {}
        for qid in body["questions"]:
            p = (values or {}).get(qid, strengths if qid in L.NOTES else default)
            answers[qid] = {"type": "noul", "noul": p}
        return {"model": L.MODEL, "answers": answers, "usage": {"input_tokens": 100}}

    transport.sent = sent  # type: ignore[attr-defined]
    return transport


class TheEnding(unittest.TestCase):
    def test_the_back_ends_as_the_app_ends_it(self):
        self.assertEqual(L.ending(CARD), [CARD["move"]])
        self.assertEqual(L.ending({**CARD, "end": "ask"}), [CARD["ask"]])
        self.assertEqual(L.ending({**CARD, "both": True}), [CARD["move"], CARD["ask"]])
        self.assertEqual(L.ending({**CARD, "move": ""}), [CARD["ask"]])
        self.assertEqual(L.ending({**CARD, "end": "ask", "ask": ""}), [CARD["move"]])

    def test_the_state_is_what_the_reader_meets(self):
        state = L.card_state(CARD)["card"]
        self.assertEqual(state["subject"], "Space")
        self.assertEqual(state["ending"], CARD["move"])
        for hidden in ("source", "keywords", "era", "correct", "ask", "id"):
            self.assertNotIn(hidden, state)


class TheTable(unittest.TestCase):
    def test_a_clear_flaw_throws_the_card_away(self):
        lk = L.decide("c", {"filler_opening": 0.95, "self_praise": 0.1, "surprise": 0.9})
        self.assertEqual((lk.verdict, lk.reasons), ("thrown", ["filler_opening"]))
        self.assertFalse(lk.passes)

    def test_a_flaw_in_the_words_not_settled_keeps_it_out(self):
        lk = L.decide("c", {"filler_opening": 0.1, "answer_in_question": 0.5})
        self.assertEqual((lk.verdict, lk.reasons), ("unsure", ["answer_in_question"]))
        self.assertFalse(lk.passes)

    def test_a_flaw_in_the_picture_counts_only_as_a_clear_yes(self):
        self.assertEqual(L.decide("c", {"filler_opening": 0.1, "overlapping_text": 0.5}).verdict, "clean")
        self.assertEqual(L.decide("c", {"filler_opening": 0.1, "empty_card": 0.8}).verdict, "thrown")

    def test_the_notes_decide_nothing(self):
        lk = L.decide("c", {"filler_opening": 0.1, "surprise": 0.05, "stock_art": 0.99})
        self.assertEqual(lk.verdict, "clean")
        self.assertEqual(lk.notes, {"surprise": 0.05, "stock_art": 0.99})

    def test_every_question_is_a_flaw_or_a_note(self):
        every = {**L.FLAWS, **L.STRENGTHS, **L.PICTURE_FLAWS, **L.PICTURE_NOTES}
        self.assertEqual(len(every), len(L.FLAWS) + len(L.STRENGTHS) + len(L.PICTURE_FLAWS) + len(L.PICTURE_NOTES))
        for q in every.values():
            self.assertEqual(q["type"], "noul")
            self.assertTrue(q["instructions"].endswith("?"))


class TheRequest(unittest.TestCase):
    def test_words_only_send_no_pictures_and_no_picture_questions(self):
        t = answering()
        lk = L.look(CARD, None, t)
        body, headers = t.sent[0]
        self.assertNotIn("assets", body)
        self.assertNotIn("TypeSafe-Danger-Zone-Images", headers)
        self.assertEqual(set(body["questions"]), set(L.FLAWS) | set(L.STRENGTHS))
        self.assertEqual(body["model"], L.MODEL)
        self.assertEqual(lk.verdict, "clean")
        self.assertEqual(lk.tokens, 100)

    def test_photographs_go_in_the_state_with_the_header(self):
        try:
            from PIL import Image
        except ImportError:
            self.skipTest("Pillow is not installed")
        with tempfile.TemporaryDirectory() as d:
            shots = Path(d)
            # Bigger than TypeSafe takes on one side, and smaller on the other.
            Image.new("RGB", (200, 2000), "white").save(shots / f"{CARD['id']}-medium-start.png")
            Image.new("RGB", (390, 844), "white").save(shots / f"{CARD['id']}-medium-end.png")
            Image.new("RGB", (390, 844), "white").save(shots / f"{CARD['id']}-small-start.png")
            t = answering()
            lk = L.look(CARD, shots, t)
            body, headers = t.sent[0]
        self.assertEqual(headers["TypeSafe-Danger-Zone-Images"], "true")
        self.assertEqual(len(body["assets"]), 2)
        self.assertIn(body["state"]["front"], body["assets"])
        self.assertIn(body["state"]["back"], body["assets"])
        self.assertIn("cut_text_after", body["questions"])
        self.assertTrue(lk.pictures)

    def test_a_failed_call_is_an_error_not_an_answer(self):
        def broken(body, headers):
            raise L.TypeSafeError("TypeSafe answered 503")

        with self.assertRaises(L.TypeSafeError):
            L.look(CARD, None, broken)

        def silent(body, headers):
            return {"answers": {}}

        with self.assertRaises(L.TypeSafeError):
            L.look(CARD, None, silent)


class TheNight(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        root = Path(self.dir.name)
        self.bank, self.review = root / "bank", root / "review"
        for cid in ("space-clean", "space-spoiled", "space-unlooked"):
            common.write_card({**CARD, "id": cid}, self.bank / "space" / f"{cid}.json")
        common.write_card({**CARD, "id": "space-queued"}, self.review / "space-queued.json")
        common.write_queue([{"id": "space-queued", "topic": "space"}], self.review / "queue.json")
        self.outcomes = [
            {"status": "written", "id": cid, "request": {"topic": "space"}}
            for cid in ("space-clean", "space-spoiled", "space-unlooked", "space-queued")
        ] + [{"status": "refused", "id": "space-never", "request": {"topic": "space"}}]

    def tearDown(self):
        self.dir.cleanup()

    def test_what_fails_is_removed_and_what_could_not_be_seen_waits(self):
        good = answering()

        def transport(body, headers):
            question = body["state"]["card"]["question"]
            if body["state"]["card"].get("answer", "").startswith("Interestingly"):
                return good(body, headers) | {"answers": {**good(body, headers)["answers"],
                                                          "filler_opening": {"type": "noul", "noul": 0.98}}}
            if question.endswith("unlooked?"):
                raise L.TypeSafeError("TypeSafe could not be reached")
            return good(body, headers)

        spoiled = self.bank / "space" / "space-spoiled.json"
        card = json.loads(spoiled.read_text())
        spoiled.write_text(json.dumps({**card, "answer": "Interestingly, " + card["answer"]}))
        unlooked = self.bank / "space" / "space-unlooked.json"
        card = json.loads(unlooked.read_text())
        unlooked.write_text(json.dumps({**card, "question": card["question"][:-1] + " unlooked?"}))

        looks, waiting, text = L.night(self.outcomes, transport=transport, bank=self.bank, review=self.review)

        self.assertTrue((self.bank / "space" / "space-clean.json").exists())
        self.assertFalse(spoiled.exists())
        self.assertFalse(unlooked.exists())
        self.assertTrue((self.review / "space-unlooked.json").exists())
        self.assertEqual(waiting, ["space-unlooked"])
        queue = {e["id"] for e in common.read_queue(self.review / "queue.json")}
        self.assertEqual(queue, {"space-queued", "space-unlooked"})
        self.assertEqual({lk.card: lk.verdict for lk in looks},
                         {"space-clean": "clean", "space-spoiled": "thrown", "space-queued": "clean"})
        self.assertIn("`space-spoiled` (thrown): filler_opening 0.98", text)
        self.assertIn("`space-unlooked`", text)


if __name__ == "__main__":
    unittest.main()
