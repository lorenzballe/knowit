import tempfile
import unittest
from pathlib import Path

import challenge_pages as cp

BANK = {
    "cards": [
        {"id": "space-x", "topic": "space", "kind": "page", "question": 'Is "dark" <really> dark?',
         "web": {"page": "pages/space-x.html?v=abc", "thumbs": {"front": "thumbs/space-x-front.webp?v=abc"}}},
        {"id": "maths-y", "topic": "maths", "kind": "page", "question": "No picture yet?",
         "web": {"page": "pages/maths-y.html?v=def"}},
        {"id": "art-pick", "topic": "art", "kind": "pickOne", "question": "Which one?",
         "options": ["First", "Second <b>", "Third"], "correct": 1,
         "answer": "The second, because.", "move": "Keep this.", "source": "A book, 1970"},
        {"id": "history-read", "topic": "history", "kind": "read", "question": "Why so?",
         "answer": "Because of that.", "move": "Remember it."},
        {"id": "art-side", "topic": "art", "kind": "debate", "question": "Did it?",
         "sides": ["Yes", "No"], "answer": "One side.", "counterpoint": "The other.", "move": "Either way."},
        {"id": "art-sum", "topic": "art", "kind": "number", "question": "How much?",
         "hint": "Add them up.", "steps": ["One plus one", "Two"], "answer": "Two."},
        {"id": "no-question", "topic": "art", "kind": "read"},
    ]
}


def card(cid: str) -> dict:
    return next(c for c in BANK["cards"] if c["id"] == cid)


class CardPages(unittest.TestCase):
    def test_a_page_for_every_card_and_the_shared_style(self):
        with tempfile.TemporaryDirectory() as d:
            n = cp.write(Path(d), BANK)
            self.assertEqual(n, 6, "every card with a question")
            for cid in ("space-x", "maths-y", "art-pick", "history-read", "art-side", "art-sum"):
                self.assertTrue((Path(d) / "c" / f"{cid}.html").exists(), cid)
            self.assertFalse((Path(d) / "c" / "no-question.html").exists())
            self.assertIn(".card.words", (Path(d) / "c" / "card.css").read_text())
            self.assertIn("Not quite.", (Path(d) / "c" / "card.js").read_text())

    def test_a_drawn_card_plays_inside_and_its_drawing_is_the_preview(self):
        page = cp.render(card("space-x"))
        self.assertIn('<iframe src="/cards/pages/space-x.html?v=abc"', page)
        self.assertIn('content="Is &quot;dark&quot; &lt;really&gt; dark?"', page)
        self.assertIn('og:image" content="https://astutetheapp.com/cards/thumbs/space-x-front.webp?v=abc"', page)
        self.assertIn("summary_large_image", page)
        self.assertIn("--c:#2B5CFF", page)
        self.assertIn("ct=challenge", page)
        self.assertNotIn("card.js", page, "a page plays itself")

    def test_a_drawn_card_without_its_picture_shows_its_subject(self):
        page = cp.render(card("maths-y"))
        self.assertIn('og:image" content="https://astutetheapp.com/cards/og/maths.png"', page)

    def test_a_card_in_words_asks_first_and_answers_behind_a_tap(self):
        page = cp.render(card("art-pick"))
        self.assertIn('<h1 class="q">Which one?</h1>', page)
        self.assertIn('data-right="1">Second &lt;b&gt;</button>', page)
        self.assertEqual(page.count('data-right="0"'), 2)
        self.assertIn('<section class="answer" hidden>', page)
        self.assertIn("The second, because.", page)
        self.assertIn("WHAT TO KEEP", page)
        self.assertIn("Source · A book, 1970", page)
        self.assertIn('og:image" content="https://astutetheapp.com/cards/og/art.png"', page)
        self.assertIn("Can you get it?", page)
        self.assertIn('<script src="/c/card.js?v=', page)
        self.assertIn("--c:#FF00A8;--ink:#FFFFFF", page)

    def test_a_read_shows_its_answer_on_a_tap(self):
        page = cp.render(card("history-read"))
        self.assertIn('class="reveal">Show the answer</button>', page)
        self.assertNotIn('class="choices"', page)
        self.assertIn("--ink:#10100C", page, "dark words on history's yellow")

    def test_a_debate_takes_a_side_then_shows_both(self):
        page = cp.render(card("art-side"))
        self.assertEqual(page.count('data-right="side"'), 2)
        self.assertIn("The other side.", page)
        self.assertIn('<p class="verdict"></p>', page)

    def test_a_number_gives_its_hint_and_its_working(self):
        page = cp.render(card("art-sum"))
        self.assertIn("Hint · Add them up.", page)
        self.assertIn("<li>One plus one</li>", page)
        self.assertNotIn("<li>Two</li>", page, "the last step is the answer, said once")


if __name__ == "__main__":
    unittest.main()
