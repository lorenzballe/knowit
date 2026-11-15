import tempfile
import unittest
from pathlib import Path

import challenge_pages as cp

BANK = {
    "cards": [
        {"id": "space-x", "topic": "space", "question": 'Is "dark" <really> dark?',
         "web": {"page": "pages/space-x.html?v=abc", "thumbs": {"front": "thumbs/space-x-front.webp?v=abc"}}},
        {"id": "maths-y", "topic": "maths", "question": "No picture yet?",
         "web": {"page": "pages/maths-y.html?v=def"}},
        {"id": "native-z", "topic": "history", "question": "No page at all"},
    ]
}


class ChallengePages(unittest.TestCase):
    def test_one_page_for_every_card_with_a_page(self):
        with tempfile.TemporaryDirectory() as d:
            n = cp.write(Path(d), BANK)
            self.assertEqual(n, 2)
            self.assertTrue((Path(d) / "c" / "space-x.html").exists())
            self.assertFalse((Path(d) / "c" / "native-z.html").exists())

    def test_the_card_plays_inside_and_its_question_is_the_preview(self):
        page = cp.render(*cp.pages(BANK)[0])
        self.assertIn('<iframe src="/cards/pages/space-x.html?v=abc"', page)
        self.assertIn('content="Is &quot;dark&quot; &lt;really&gt; dark?"', page)
        self.assertIn('og:image" content="https://astutetheapp.com/cards/thumbs/space-x-front.webp?v=abc"', page)
        self.assertIn("summary_large_image", page)
        self.assertIn("--c:#2B5CFF", page)
        self.assertIn("ct=challenge", page)

    def test_without_a_picture_the_preview_is_the_words(self):
        page = cp.render(*cp.pages(BANK)[1])
        self.assertNotIn("og:image", page)
        self.assertIn('name="twitter:card" content="summary"', page)


if __name__ == "__main__":
    unittest.main()
