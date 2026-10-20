"""Free cards on the bank's road: the page's gate, the card around it, the bundle.

    python3 -m unittest discover tool/cards
"""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

import bundle
import check
import pages

TEMPLATE = (Path(__file__).resolve().parent / "web" / "template.html").read_text(encoding="utf-8")
QUESTION = "A bat and a ball cost 1.10 together. The bat costs 1.00 more than the ball. What does the ball cost?"


def page_card(**over) -> dict:
    card = {
        "id": "thinking-free-bat",
        "topic": "thinking",
        "kind": "page",
        "difficulty": "medium",
        "principle": "reflection",
        "question": QUESTION,
        "answer": "Five cents. Then the bat is 1.05 and together they are 1.10; ten cents comes first because 1.10 splits so neatly.",
        "move": "The answer that arrives first is the one to check.",
        "web": {"kit": 1, "touch": "taps", "label": "Three answers to pick from, then how sure you are, then the working."},
        "source": "Frederick, Journal of Economic Perspectives, 2005",
        "keywords": ["cognitive reflection", "bat and ball", "intuition"],
        "era": "recent",
        "region": "none",
        "hook": "puzzle",
        "mood": "playful",
        "numeracy": 2,
        "abstraction": "concrete",
        "shelf_life": "evergreen",
        "mature": False,
        "language": "en",
        "_html": TEMPLATE,
    }
    card.update(over)
    return card


class ThePage(unittest.TestCase):
    def setUp(self):
        self.files = pages.kit_files()

    def problems(self, page: str | None = TEMPLATE, **over) -> list[str]:
        card = page_card(**over)
        return pages.check_page(card, page, files=self.files)

    def test_the_template_is_a_page_the_app_can_show(self):
        self.assertEqual(self.problems(), [])

    def test_a_link_stands_for_a_kit_file_or_nothing(self):
        f = self.files
        self.assertEqual(pages.resolve("kit/astute-card.css", f), "astute-card.css")
        self.assertEqual(pages.resolve("../../kit/vendor/gsap.min.js", f), "vendor/gsap.min.js")
        self.assertEqual(pages.resolve("https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js", f), "vendor/gsap.min.js")
        self.assertEqual(pages.resolve("https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/SplitText.min.js", f), "vendor/gsap-plugins/SplitText.min.js")
        self.assertEqual(pages.resolve("https://fonts.googleapis.com/css2?family=Fraunces", f), "fonts.css")
        self.assertIsNone(pages.resolve("https://example.org/x.js", f))
        self.assertIsNone(pages.resolve("kit/vendor/jquery.js", f))

    def test_the_kit_the_app_ships_is_whole(self):
        for name in ("astute-card.css", "astute-card.js", "astute-bridge.js", "fonts.css", "fonts/Fraunces.woff2", "fonts/Figtree.woff2", "vendor/gsap.min.js"):
            self.assertIn(name, self.files)

    def test_the_page_lives_beside_the_card(self):
        self.assertIn("a free card keeps its page beside it: thinking-free-bat.html", self.problems(page=None))
        web = dict(page_card()["web"], html="<p>")
        self.assertTrue(any("web.html is the bundle's" in p for p in self.problems(web=web)))

    def test_what_the_app_needs_from_the_face(self):
        self.assertTrue(any("web.label" in p for p in self.problems(web={"kit": 1})))
        self.assertTrue(any("no build could show it" in p for p in self.problems(web=dict(page_card()["web"], kit=2))))
        self.assertTrue(any("taps or drags" in p for p in self.problems(web=dict(page_card()["web"], touch="all"))))

    def test_one_card_in_the_kit_s_single_mode_played_through(self):
        self.assertTrue(any("Kit.single()" in p for p in self.problems(page=TEMPLATE.replace("Kit.single();", ""))))
        self.assertTrue(any("Kit.play.card" in p for p in self.problems(page=TEMPLATE.replace("Kit.play.card =", "Kit.later ="))))
        two = TEMPLATE.replace("</article>", '</article><article class="card" id="two"></article>')
        self.assertTrue(any("one <article" in p for p in self.problems(page=two)))
        self.assertTrue(any("dressed as thinking" in p for p in self.problems(topic="space")))

    def test_its_question_is_the_card_s(self):
        self.assertTrue(any("the same words" in p for p in self.problems(question="What does the ball cost, really?")))

    def test_it_answers_where_the_card_asks_and_only_there(self):
        self.assertTrue(any("answers through Kit.answer" in p for p in self.problems(page=TEMPLATE.replace("Kit.answer(", "Kit.say("))))
        self.assertTrue(any("records nothing" in p for p in self.problems(kind="read", principle="none", difficulty="easy")))
        drags = dict(page_card()["web"], touch="drags")
        self.assertTrue(any("data-drag" in p for p in self.problems(web=drags)))

    def test_nothing_from_anywhere_but_the_kit(self):
        cases = {
            '<link rel="stylesheet" href="https://example.org/a.css">': "not in the kit",
            '<script src="https://example.org/a.js"></script>': "not in the kit",
            '<script type="importmap">{"imports":{"x":"https://example.org/x.js"}}</script>': "import map",
            '<script type="module">import x from "https://example.org/x.js"</script>': "from the network",
            '<img src="https://example.org/a.png">': "from outside the page",
            '<style>.a{background:url(https://example.org/a.png)}</style>': "a stylesheet points at",
            '<script>fetch("https://example.org")</script>': "asks the network",
            '<script>new WebSocket("wss://example.org")</script>': "asks the network",
            '<iframe src="https://example.org"></iframe>': "<iframe>",
            '<link rel="prefetch" href="https://example.org/next">': "only stylesheets",
        }
        for extra, said in cases.items():
            page = TEMPLATE.replace("</style>", "</style>" + extra, 1)
            self.assertTrue(any(said in p for p in self.problems(page=page)), extra)
        # A blob it made itself, and a picture it carries, are its own.
        own = '<script>fetch(Kit.url("vendor/rive.wasm"))</script><img src="data:image/png;base64,AAAA">'
        self.assertEqual(self.problems(page=TEMPLATE.replace("</style>", "</style>" + own, 1)), [])

    def test_small_enough_to_travel_and_for_the_embedded_bank_to_hold(self):
        heavy = TEMPLATE.replace("</style>", "</style><!--" + "x" * pages.MAX_BYTES + "-->", 1)
        self.assertTrue(any("KB; at most" in p for p in self.problems(page=heavy)))
        self.assertTrue(any("three quotes" in p for p in self.problems(page=TEMPLATE + "'''")))


class TheCard(unittest.TestCase):
    def setUp(self):
        self.schema = check.load_schema()

    def check(self, **over) -> list[str]:
        return check.check_card(page_card(**over), schema=self.schema, banned=check.load_banned())

    def test_a_page_card_passes(self):
        self.assertEqual(self.check(), [])

    def test_a_page_card_is_shaped_by_what_its_page_marks(self):
        self.assertIn("a graded card carries a principle", self.check(principle="none"))
        self.assertIn("a card that asks is at least medium", self.check(difficulty="easy"))
        ungraded = dict(page_card()["web"], graded=False)
        self.assertIn("a page that marks nothing carries no principle", self.check(web=ungraded))
        self.assertEqual(self.check(web=ungraded, principle="none"), [])
        self.assertIn("a page card has no options: the page asks", self.check(options=["A", "B"]))
        no_face = page_card()
        no_face.pop("web")
        self.assertIn("a page card has a web face: its page asks, and marks the answer",
                      check.check_card(no_face, schema=self.schema))

    def test_any_kind_may_have_a_face(self):
        card = page_card(kind="pickOne", options=["10 cents", "5 cents", "1 cent"], correct=1,
                         trap="Ten cents, because 1.10 splits so neatly.")
        self.assertEqual(check.check_card(card, schema=self.schema), [])

    def test_a_page_beside_a_card_without_a_face_is_a_mistake(self):
        card = page_card()
        card.pop("web")
        card.update(kind="read", principle="none", difficulty="easy", question="Why does the ball cost five cents?")
        self.assertIn("a page sits beside a card that has no web face", check.check_card(card, schema=self.schema))

    def test_the_face_sits_after_the_scene_in_a_file(self):
        order = check.KEY_ORDER
        self.assertEqual(order.index("web"), order.index("scene") + 1)


class TheBundle(unittest.TestCase):
    def test_the_page_goes_inside_the_card_and_only_in_the_bundle(self):
        card = page_card()
        out = bundle.bundled(card)
        self.assertEqual(out["web"]["html"], TEMPLATE)
        self.assertNotIn("_html", out)
        self.assertNotIn("html", card["web"], "the bank's own file is left as it was")

    def test_the_bank_reads_the_page_beside_a_card_and_finds_one_alone(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "bank"
            (root / "thinking").mkdir(parents=True)
            card = {k: v for k, v in page_card().items() if not k.startswith("_")}
            (root / "thinking" / "thinking-free-bat.json").write_text(json.dumps(card), encoding="utf-8")
            (root / "thinking" / "thinking-free-bat.html").write_text(TEMPLATE, encoding="utf-8")
            (root / "thinking" / "thinking-alone.html").write_text(TEMPLATE, encoding="utf-8")
            [loaded] = check.load_bank(root)
            self.assertEqual(loaded["_html"], TEMPLATE)
            self.assertEqual(check.check_orphan_pages(root), ["bank/thinking/thinking-alone.html has no card beside it"])

    def test_a_page_card_never_becomes_the_question_of_the_day(self):
        self.assertNotIn("page", check.GRADED)


if __name__ == "__main__":
    unittest.main()
