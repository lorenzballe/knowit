"""The Explore part's checker: the fields every section shares, where its
cards come from, and every block of the core family — what passes, and that
what does not says what to change.

    python3 tool/remote/test_explore.py
"""
from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import check  # noqa: E402
from parts import explore  # noqa: E402
from parts.explore_blocks import core  # noqa: E402

ROOT = HERE.parent.parent


def problems(*sections) -> list[str]:
    return explore.check({"sections": list(sections)})


def one(problems_: list[str], fragment: str) -> bool:
    return any(fragment in p for p in problems_)


def a_card(**want) -> str:
    """The id of a dealt card of the bank that has what [want] says."""
    for cid, card in explore.bank().items():
        if card["disabled"] or card["place"]:
            continue
        if all(card.get(k) == v for k, v in want.items()):
            return cid
    raise LookupError(want)


class CommonFieldsTest(unittest.TestCase):
    def test_null_is_the_builds_own(self):
        self.assertEqual(explore.check(None), [])

    def test_the_document_is_a_list_of_sections(self):
        self.assertEqual(explore.check({"sections": "no"}), ['is not {"sections": [...]}'])
        self.assertEqual(explore.check([]), ['is not {"sections": [...]}'])

    def test_each_section_has_its_own_id_and_a_known_block(self):
        got = problems(
            {"block": "today"},
            {"id": "a", "block": "today"},
            {"id": "a", "block": "top"},
            {"id": "b", "block": "no-such-block"},
        )
        self.assertTrue(one(got, "sections[0]: has no id"))
        self.assertTrue(one(got, "section 'a': the id is used twice"))
        self.assertTrue(one(got, "block 'no-such-block' is not one the app can draw"))

    def test_words_are_one_string_or_one_per_language_with_english(self):
        self.assertEqual(problems({"id": "a", "block": "top", "title": "Top"}), [])
        self.assertEqual(problems({"id": "a", "block": "top", "title": {"en": "Top", "it": "In cima"}}), [])
        got = problems({"id": "a", "block": "top", "title": {"it": "In cima"}, "subtitle": {"en": "x", "xx": "y"}})
        self.assertTrue(one(got, "`title` has no English"))
        self.assertTrue(one(got, "`subtitle` has 'xx', which is not a language of the app"))
        self.assertTrue(one(problems({"id": "a", "block": "top", "title": " "}), "`title` is empty"))

    def test_limit_gap_size_and_style_are_what_they_say(self):
        got = problems(
            {"id": "a", "block": "today", "limit": 0},
            {"id": "b", "block": "today", "limit": True},
            {"id": "c", "block": "today", "gap": 121},
            {"id": "d", "block": "carousel", "size": 3, "source": {"shelf": "today"}},
        )
        self.assertTrue(one(got, "section 'a': `limit` is a whole number"))
        self.assertTrue(one(got, "section 'b': `limit` is a whole number"))
        self.assertTrue(one(got, "section 'c': `gap` is the room above the section"))
        self.assertTrue(one(got, "section 'd': `size` is a name"))
        self.assertEqual(problems({"id": "e", "block": "today", "gap": 0, "limit": 12}), [])

    def test_an_audience_key_the_app_does_not_know_is_refused(self):
        got = problems({"id": "a", "block": "top", "audience": {"all": [{"plus": False}, {"moon": "full"}]}})
        self.assertTrue(one(got, "audience key 'moon' is not one the app knows"))
        self.assertEqual(problems({"id": "a", "block": "top", "audience": {"weekdays": [6, 7], "rollout": 50}}), [])

    def test_a_note_for_whoever_reads_the_document_is_passed_over(self):
        self.assertEqual(problems({"id": "a", "block": "top", "_why": "kept for the launch"}), [])


class SourceTest(unittest.TestCase):
    def section(self, source, block="carousel"):
        return {"id": "s", "block": block, "source": source}

    def test_a_shelf_of_the_servers_explore(self):
        self.assertEqual(problems(self.section({"shelf": "topWeek"})), [])
        self.assertTrue(one(problems(self.section({"shelf": "best"})), "shelf 'best' is not one of the server's Explore"))

    def test_cards_by_id_are_in_the_bank_and_dealt(self):
        good = a_card(topic="space")
        self.assertEqual(problems(self.section({"ids": [good]})), [])
        got = problems(self.section({"ids": [good, good, "no-such-card", 3]}))
        self.assertTrue(one(got, f"card {good} is named twice"))
        self.assertTrue(one(got, "card no-such-card is not in tool/cards/bank/"))
        self.assertTrue(one(got, "ids has 3, which is not a card id"))
        retired = next((cid for cid, c in explore.bank().items() if c["disabled"]), None)
        if retired:
            self.assertTrue(one(problems(self.section({"ids": [retired]})), "is retired"))
        place = next(cid for cid, c in explore.bank().items() if c["place"])
        self.assertTrue(one(problems(self.section({"ids": [place]})), "is about a place"))

    def test_a_query_of_the_bank(self):
        self.assertEqual(problems(self.section({"query": {
            "subjects": ["space", "history"], "formats": ["pickOne", "story"], "difficulty": ["hard", "medium"],
            "unread": True, "perSubject": 3, "limit": 12, "seed": "week",
        }})), [])
        got = problems(self.section({"query": {"subjects": ["astrology"], "formats": ["quiz"], "seed": "hour", "limit": 0, "moon": 1}}))
        self.assertTrue(one(got, "query key 'moon' is not one the app reads"))
        self.assertTrue(one(got, "'astrology', which is not a subject of the bank"))
        self.assertTrue(one(got, "'quiz', which is not a kind of card or of scene"))
        self.assertTrue(one(got, "query `seed` is day, week or fixed"))
        self.assertTrue(one(got, "query `limit` is a whole number"))

    def test_a_query_that_finds_nothing_is_refused(self):
        got = problems(self.section({"query": {"subjects": ["thinking"], "formats": ["music"]}}))
        self.assertTrue(one(got, "the query finds no card in the bank"))

    def test_the_readers_own(self):
        self.assertEqual(problems(self.section({"mine": "saved"})), [])
        self.assertTrue(one(problems(self.section({"mine": "starred"})), "mine 'starred' is not one of"))

    def test_one_kind_of_source_at_a_time(self):
        got = problems(self.section({"shelf": "today", "mine": "saved"}))
        self.assertTrue(one(got, "`source` names one of shelf, ids, query or mine"))


class CoreBlocksTest(unittest.TestCase):
    """The names here are the app's: test/explore/core_blocks_test.dart holds
    this list to the blocks lib/explore/blocks/core_blocks.dart draws."""

    def test_a_shelf_deals_its_own_cards(self):
        got = problems({"id": "a", "block": "today", "source": {"shelf": "today"}})
        self.assertTrue(one(got, "deals its own cards and reads no `source`"))

    def test_a_shelf_with_a_frame_of_its_own_takes_no_words(self):
        got = problems({"id": "a", "block": "mood", "title": "Your minutes"})
        self.assertTrue(one(got, "`title` is not a field this block reads"))

    def test_a_misspelt_field_is_caught(self):
        got = problems({"id": "a", "block": "carousel", "sise": "xl", "source": {"shelf": "today"}})
        self.assertTrue(one(got, "`sise` is not a field this block reads"))

    def test_card_blocks_need_a_source_and_a_size_they_have(self):
        got = problems(
            {"id": "a", "block": "carousel"},
            {"id": "b", "block": "carousel", "size": "xxl", "source": {"shelf": "today"}},
            {"id": "c", "block": "hero", "size": "s", "source": {"shelf": "today"}},
            {"id": "d", "block": "ticker", "size": "l", "source": {"shelf": "today"}},
        )
        self.assertTrue(one(got, "section 'a': needs a `source`"))
        self.assertTrue(one(got, "section 'b': size 'xxl' is not one of xs, s, m, l, xl"))
        self.assertTrue(one(got, "section 'c': size 's' is not one of m, l, xl"))
        self.assertTrue(one(got, "section 'd': size 'l' is not one of xs, s, m"))

    def test_every_size_of_every_card_block_passes(self):
        sizes = {
            "carousel": ["xs", "s", "m", "l", "xl"], "hero": ["m", "l", "xl"], "banner": ["s", "m", "l"],
            "pair": ["s", "m", "l"], "list": ["s", "m", "l"], "stack": ["s", "m", "l"], "ticker": ["xs", "s", "m"],
        }
        for block, names in sizes.items():
            for size in names:
                with self.subTest(block=block, size=size):
                    self.assertEqual(problems({"id": "a", "block": block, "size": size, "source": {"shelf": "today"}}), [])

    def test_a_grid_too_small_to_hold_a_question_is_refused(self):
        def grid(columns, shape):
            return problems({"id": "g", "block": "grid", "columns": columns, "shape": shape, "source": {"shelf": "today"}})

        for columns, shape in [(2, "square"), (2, "portrait"), (2, "landscape"), (3, "square"), (3, "portrait"), (4, "portrait")]:
            with self.subTest(columns=columns, shape=shape):
                self.assertEqual(grid(columns, shape), [])
        for columns, shape in [(3, "landscape"), (4, "square"), (4, "landscape")]:
            with self.subTest(columns=columns, shape=shape):
                self.assertTrue(one(grid(columns, shape), "too small to set a quarter of the bank's questions whole"))
        self.assertTrue(one(grid(5, "square"), "`columns` is 2, 3 or 4"))
        self.assertTrue(one(grid(2, "round"), "`shape` is square, portrait or landscape"))

    def test_a_mosaic_spans_what_it_has_and_holds_its_questions(self):
        def bento(**fields):
            return problems({"id": "b", "block": "bento", "source": {"shelf": "today"}, **fields})

        self.assertEqual(bento(), [])
        self.assertEqual(bento(columns=4, items=["2x2", "2x1", "1x2", "4x1"]), [])
        self.assertTrue(one(bento(columns=2, items=["3x1"]), "spans 3 columns of a mosaic of 2"))
        self.assertTrue(one(bento(items=["2x4"]), "a span is \"CxR\""))
        self.assertTrue(one(bento(columns=4, items=["1x1"]), "items[0] (1x1) is 78 by 78 points"))
        self.assertEqual(bento(columns=4, ratio=2, items=["1x1"]), [])
        self.assertTrue(one(bento(ratio=3), "how tall a row is for its width"))
        self.assertTrue(one(bento(items=[]), "`items` is a list of one to twelve spans"))

    def test_text_countdown_subjects_promo_spacer_divider_web(self):
        self.assertEqual(problems(
            {"id": "t", "block": "text", "kind": "quote", "text": {"en": "Look twice."}, "by": "A reader", "subject": "space", "style": {"align": "center"}},
            {"id": "c", "block": "countdown", "to": "2027-08-02", "label": {"en": "to the eclipse"}, "subject": "space", "source": {"shelf": "today"}, "size": "xs"},
            {"id": "s", "block": "subjects", "subjects": ["space", "art"], "size": "l"},
            {"id": "p", "block": "promo", "from": "explore", "plan": "all", "headline": {"en": "Five of your own"}},
            {"id": "sp", "block": "spacer", "height": 40},
            {"id": "d", "block": "divider", "label": {"en": "and"}},
            {"id": "w", "block": "web", "html": {"en": "<p>Hi</p>"}, "height": 200},
        ), [])
        got = problems(
            {"id": "t", "block": "text", "kind": "poem", "by": "Nobody"},
            {"id": "c", "block": "countdown", "to": "2027-02-30"},
            {"id": "s", "block": "subjects", "subjects": ["thinking", "space", "space"]},
            {"id": "p", "block": "promo", "plan": "plus", "from": "Explore!"},
            {"id": "sp", "block": "spacer", "height": 500},
            {"id": "w", "block": "web", "html": "<p>Hi</p>"},
        )
        for fragment in [
            "section 't': needs `text`", "section 't': `kind` is headline, paragraph or quote",
            "section 't': `by` says who said a quote", "section 'c': needs `to`", "section 'c': needs `label`",
            "subjects has 'thinking'", "subjects names one twice", "section 'p': `plan` is free",
            "section 'p': `from` names the door", "section 'sp': `height` is the room",
            "section 'w': needs `height`",
        ]:
            with self.subTest(fragment=fragment):
                self.assertTrue(one(got, fragment), got)


class ExamplesTest(unittest.TestCase):
    def test_the_examples_pass_and_are_never_bundled(self):
        self.assertEqual(check.check_examples(), [])
        bundled = json.loads((ROOT / "web" / "remote" / "config.json").read_text(encoding="utf-8"))
        self.assertNotIn("gallery-intro", json.dumps(bundled))

    def test_todays_explore_as_a_document_draws_every_shelf_once(self):
        doc = json.loads((ROOT / "remote" / "examples" / "explore-today.json").read_text(encoding="utf-8"))
        blocks = [s["block"] for s in doc["sections"]]
        self.assertEqual(len(blocks), len(set(blocks)))
        self.assertEqual(explore.check(doc), [])

    def test_the_gallery_shows_every_card_block_at_every_size(self):
        doc = json.loads((ROOT / "remote" / "examples" / "explore-gallery.json").read_text(encoding="utf-8"))
        shown = {(s["block"], s.get("size")) for s in doc["sections"]}
        for block, sizes in {
            "carousel": ["xs", "s", "m", "l", "xl"], "hero": ["m", "l", "xl"], "banner": ["s", "m", "l"],
            "pair": ["s", "m", "l"], "list": ["s", "m", "l"], "stack": ["s", "m", "l"], "ticker": ["xs", "s", "m"],
            "subjects": ["s", "m", "l"],
        }.items():
            for size in sizes:
                self.assertIn((block, size), shown)
        blocks = {s["block"] for s in doc["sections"]}
        self.assertTrue({"grid", "bento", "single", "text", "countdown", "promo", "spacer", "divider", "web"} <= blocks)

    def test_every_example_in_the_catalogue_passes(self):
        text = (ROOT / "docs" / "explore" / "core.md").read_text(encoding="utf-8")
        examples = re.findall(r"```json\n(.*?)\n```", text, re.S)
        self.assertGreaterEqual(len(examples), 18)
        for example in examples:
            section = json.loads(example)
            with self.subTest(section=section["id"]):
                self.assertEqual(explore.check({"sections": [section]}), [])

    def test_the_document_in_docs_remote_passes(self):
        text = (ROOT / "docs" / "REMOTE.md").read_text(encoding="utf-8")
        documents = [json.loads(d) for d in re.findall(r"```json\n(.*?)\n```", text, re.S)]
        self.assertTrue(any("sections" in d for d in documents))
        for doc in documents:
            if "sections" in doc:
                self.assertEqual(explore.check(doc), [])

    def test_an_example_of_no_part_is_refused(self):
        stray = check.EXAMPLES / "nothing-at-all.json"
        stray.write_text("{}", encoding="utf-8")
        try:
            self.assertTrue(one(check.check_examples(), "is named for no part of the document"))
        finally:
            stray.unlink()


if __name__ == "__main__":
    unittest.main()
