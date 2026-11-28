"""Book summaries: the gate a summary passes, and how the bundle names it.

    python3 -m unittest discover -s tool/cards -p "test_summaries.py"
"""
from __future__ import annotations

import copy
import hashlib
import json
import unittest

import bundle
import summaries

BOOKS = {"a-book": {"id": "a-book", "title": "A Book", "author": "An Author", "year": 2001, "part": 1,
                    "isbn": "9780000000001"}}
SENTENCE = "Kuhn noticed that a field shares one way of working for a long time."


def paragraph(n: int = 8) -> str:
    """[n] sentences of plain words, fourteen words each."""
    return " ".join([SENTENCE] * n)


def summary(**over) -> dict:
    s = {
        "book": "a-book",
        "title": "A Book",
        "author": "An Author",
        "year": 2001,
        "language": "en",
        "parts": [{"title": f"Part number {i}", "text": [paragraph(), paragraph(), paragraph(9)]}
                  for i in range(1, 7)],
        "sources": ["An Author, A Book (A Press, 2001), ISBN 9780000000001, https://openlibrary.org/isbn/9780000000001"],
        "written": "2026-11-27",
    }
    s.update(over)
    return s


class Gate(unittest.TestCase):
    def test_a_good_summary_passes(self):
        self.assertEqual(summaries.check(summary(), BOOKS), [])

    def test_the_shipped_summaries_pass(self):
        import check as card_check

        report = summaries.check_all(summaries.load_all(), card_check.load_bank())
        self.assertEqual(report, {})

    def test_five_to_eight_parts(self):
        s = summary()
        s["parts"] = s["parts"][:4]
        self.assertTrue(any("5 to 8" in p for p in summaries.check(s, BOOKS)))

    def test_the_house_style(self):
        for bad, said in (
            ("It was a long road — and a hard one.", "dash"),
            ("It worked!", "exclamation"),
            ("It's not a theory, it's a way of seeing.", "not-X-but-Y"),
            ("This is not just a book.", "'not just'"),
            ("He said “so”.", "curly"),
        ):
            s = summary()
            s["parts"][0]["text"][0] = paragraph(6) + " " + bad
            problems = " ".join(summaries.check(s, BOOKS))
            self.assertIn(said, problems, bad)

    def test_the_edition_is_the_one_on_the_cover(self):
        s = summary(sources=["An Author, A Book (A Press, 2001), ISBN 9781111111111, https://example.org"])
        self.assertTrue(any("cover" in p for p in summaries.check(s, BOOKS)))
        s = summary(sources=["An Author, A Book (A Press, 2001), https://example.org"])
        self.assertTrue(any("ISBN" in p for p in summaries.check(s, BOOKS)))

    def test_the_book_agrees_with_its_cards(self):
        self.assertTrue(any("author" in p for p in summaries.check(summary(author="Someone"), BOOKS)))
        self.assertTrue(any("not a book of the bank" in p for p in summaries.check(summary(book="b-book"), BOOKS)))

    def test_quotations_stay_short(self):
        s = summary()
        s["parts"][1]["text"][0] = paragraph(6) + ' He wrote "' + " ".join(["word"] * 14) + '".'
        self.assertTrue(any("quotation" in p for p in summaries.check(s, BOOKS)))


class Published(unittest.TestCase):
    def test_the_name_carries_the_hash_of_the_bytes(self):
        s = summary()
        text = summaries.published_text(s)
        v = hashlib.sha256(text.encode("utf-8")).hexdigest()[:12]
        self.assertEqual(summaries.ref_of(s), f"summaries/a-book.json?v={v}")
        doc = json.loads(text)
        self.assertNotIn("written", doc)
        self.assertEqual(doc["words"], summaries.word_count(s))
        self.assertEqual(doc["minutes"], summaries.minutes(s))

    def test_a_changed_word_is_a_new_name(self):
        s = summary()
        t = copy.deepcopy(s)
        t["parts"][2]["text"][1] += " Again."
        self.assertNotEqual(summaries.ref_of(s), summaries.ref_of(t))

    def test_the_bank_lists_each_summary(self):
        index = summaries.index_of([summary()])
        self.assertEqual(set(index["a-book"]), {"file", "minutes", "parts", "words"})
        self.assertEqual(index["a-book"]["parts"], 6)

    def test_the_bundle_carries_the_index_and_not_for_old_builds(self):
        index = summaries.index_of([summary()])
        new = bundle.build([], {}, {}, version=1, built="", summaries=index)
        old = bundle.build([], {}, {}, version=1, built="", inline=True, summaries=index)
        self.assertEqual(new["summaries"], index)
        self.assertNotIn("summaries", old)

    def test_the_app_is_built_with_the_published_bytes(self):
        s = summary()
        dart = bundle.render_summaries_dart([s])
        self.assertIn(f"'{summaries.ref_of(s)}': r'''\n{summaries.published_text(s)}''',", dart)


if __name__ == "__main__":
    unittest.main()
