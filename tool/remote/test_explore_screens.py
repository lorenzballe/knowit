"""The checker of the whole-screen blocks (parts/explore_blocks/screens.py):
it knows the blocks the app draws, passes the screens of remote/examples/
and every bare section the app draws well, and refuses, with a line that
says what to change, what the app would pass over in silence."""
from __future__ import annotations

import json
import re
import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))

from parts import explore  # noqa: E402
from parts.explore_blocks import screens  # noqa: E402


def card_where(test) -> dict:
    """The first live card of the bank, not about a place, that passes."""
    for card in sorted(screens.bank().values(), key=lambda c: c["id"]):
        if not card.get("disabled") and not card.get("place") and test(card):
            return card
    raise AssertionError("no such card in the bank")


def problems(section: dict) -> list[str]:
    return explore.check({"sections": [{"id": "x", **section}]})


class ScreensBlocksTest(unittest.TestCase):
    def assertRefused(self, section: dict, *fragments: str):
        found = problems(section)
        for fragment in fragments:
            self.assertTrue(any(fragment in p for p in found), f"{fragment!r} not in {found}")

    def test_the_blocks_are_the_ones_the_app_draws(self):
        names = set()
        for path in (ROOT / "lib" / "explore" / "blocks" / "screens").glob("*.dart"):
            names |= set(re.findall(r"String get name => '([a-z-]+)';", path.read_text(encoding="utf-8")))
        self.assertEqual(set(screens.BLOCKS), names)

    def test_the_subjects_and_languages_are_the_apps(self):
        topics = (ROOT / "lib" / "data" / "topics.dart").read_text(encoding="utf-8")
        table = topics[topics.index("final Map<String, TopicStyle> kTopics"):topics.index("const List<Color> kLateSubjects")]
        self.assertEqual(screens.SUBJECTS, set(re.findall(r"^\s+'([a-z_]+)': ", table, re.M)))
        arbs = {p.stem[len("app_"):] for p in (ROOT / "lib" / "l10n").glob("app_*.arb")}
        self.assertEqual(screens.LANGUAGES, arbs)

    def test_the_example_screens_pass(self):
        examples = sorted((ROOT / "remote" / "examples").glob("explore-*.json"))
        checked = 0
        for path in examples:
            doc = json.loads(path.read_text(encoding="utf-8"))
            ours = [s for s in doc["sections"] if s.get("block") in screens.BLOCKS]
            if not ours:
                continue
            checked += 1
            self.assertEqual(explore.check({"sections": ours}), [], path.name)
        self.assertGreaterEqual(checked, 8)

    def test_a_bare_section_of_every_block_passes(self):
        for name in screens.BLOCKS:
            if name == "keep-asking":
                continue
            self.assertEqual(problems({"block": name}), [], name)

    def test_words_need_english_and_a_language_the_app_has(self):
        self.assertRefused({"block": "masthead", "title": {"it": "L'Astuto"}}, "title has no English")
        self.assertRefused({"block": "masthead", "title": {"en": "A", "xx": "B"}}, "'xx' is not a language")
        self.assertRefused({"block": "masthead", "kicker": "   "}, "kicker is empty")
        self.assertRefused({"block": "masthead", "title": ["A"]}, "title is neither words")
        self.assertRefused({"block": "masthead", "title": "x" * 81}, "keep it to 80")

    def test_style_size_limit_and_fields_are_the_blocks_own(self):
        self.assertRefused({"block": "expert", "style": {"map": True}}, "style.map is not one this block reads")
        self.assertRefused({"block": "connect-dots", "style": {"map": "no"}}, "style.map is a switch")
        self.assertRefused({"block": "expert", "size": "huge"}, "size 'huge'")
        self.assertRefused({"block": "expert", "limit": 1}, "from 2 to 8")
        self.assertRefused({"block": "masthead", "limit": 2}, "limit is not read")
        self.assertRefused({"block": "masthead", "colour": "red"}, "'colour' is not a field it reads")

    def test_named_cards_must_be_in_the_bank_and_dealt(self):
        retired = next((c for c in screens.bank().values() if c.get("disabled")), None)
        place = next((c for c in screens.bank().values() if c.get("place")), None)
        ids = ["no-such-card"] + ([retired["id"]] if retired else []) + ([place["id"]] if place else [])
        found = problems({"block": "change-your-mind", "source": {"ids": ids}})
        self.assertTrue(any("no card no-such-card" in p for p in found), found)
        if retired:
            self.assertTrue(any("is retired" in p for p in found), found)
        if place:
            self.assertTrue(any("is about a place" in p for p in found), found)
        claim = card_where(screens.is_true_or_false)
        self.assertRefused({"block": "change-your-mind", "source": {"ids": [claim["id"], claim["id"]]}}, "named twice")

    def test_a_card_must_be_one_the_block_can_draw(self):
        not_a_claim = card_where(lambda c: not screens.is_true_or_false(c))
        false_claim = card_where(lambda c: screens.is_true_or_false(c) and not screens.says_true(c))
        no_figure = card_where(lambda c: screens.shelf_figure(c["question"]) is None)
        self.assertRefused({"block": "change-your-mind", "source": {"ids": [not_a_claim["id"]]}}, "is not a true-or-false card")
        self.assertRefused({"block": "say-it-tonight", "source": {"ids": [false_claim["id"]]}}, "no line to say")
        self.assertRefused({"block": "front-numbers", "source": {"ids": [no_figure["id"], no_figure["id"] + "x"]}}, "has no figure")
        three = [c["id"] for c in sorted(screens.bank().values(), key=lambda c: c["id"]) if not c.get("disabled") and not c.get("place")][:3]
        self.assertRefused({"block": "front-columns", "source": {"ids": three}}, "the columns shows 2")
        self.assertRefused({"block": "front-lead", "source": {"ids": three[:2]}}, "the lead shows 1")

    def test_experts(self):
        self.assertRefused({"block": "expert", "experts": ["astrologer"]}, "not an expert the app carries")
        self.assertRefused({"block": "expert", "experts": [{"id": "chef", "name": "Chef", "as": "Think like a chef"}]}, "experts[0].question is missing")
        self.assertRefused({"block": "expert", "experts": ["doctor", {"id": "doctor"}]}, "'doctor' is there twice")
        self.assertRefused({"block": "expert", "experts": ["doctor"], "expert": "historian"}, "not one of the section's experts")
        self.assertRefused({"block": "expert", "experts": [{"id": "doctor", "mark": "skull"}]}, "not a mark the app draws")
        self.assertRefused({"block": "expert", "experts": [{"id": "doctor", "principles": ["luck"]}]}, "'luck' is not one the bank uses")
        self.assertEqual(problems({"block": "expert", "experts": ["doctor", {"id": "statistician", "question": {"en": "Out of how many?"}}]}), [])

    def test_connect_the_dots(self):
        food = card_where(lambda c: c["topic"] == "food")
        self.assertRefused({"block": "connect-dots", "subjects": ["economics", "astrology"]}, "'astrology' is not a subject")
        self.assertRefused({"block": "connect-dots", "subjects": ["economics"], "subject": "food"}, "not one of the section's subjects")
        self.assertRefused({"block": "connect-dots", "pairs": [{"card": food["id"], "with": "food"}]}, "a meeting is with another subject")
        self.assertEqual(problems({"block": "connect-dots", "pairs": [{"card": food["id"], "with": "economics"}]}), [])

    def test_chains_of_whys(self):
        step = {"q": {"en": "Why?"}, "a": {"en": "Because."}}
        chain = {"id": "a", "subject": "science", "source": "Somebody, Somewhere, 2001", "steps": [step, step]}
        self.assertEqual(problems({"block": "keep-asking", "chains": [chain]}), [])
        self.assertRefused({"block": "keep-asking"}, "chains is missing")
        self.assertRefused({"block": "keep-asking", "chains": [{**chain, "source": ""}]}, "name where its answers come from")
        self.assertRefused({"block": "keep-asking", "chains": [{**chain, "steps": [step]}]}, "2 to 8 questions")
        self.assertRefused({"block": "keep-asking", "chains": [{**chain, "steps": [step] * 9}]}, "2 to 8 questions")
        self.assertRefused({"block": "keep-asking", "chains": [{**chain, "steps": [{"q": {"it": "Perché?"}, "a": "Così."}, step]}]}, "steps[0].q has no English")
        self.assertRefused({"block": "keep-asking", "chains": [{**chain, "steps": [{"q": "Why?", "a": "x" * 321}, step]}]}, "keep it to 320")
        self.assertRefused({"block": "keep-asking", "chains": [chain, chain]}, "'a' is there twice")
        self.assertRefused({"block": "keep-asking", "chains": [chain], "chain": "b"}, "not one of the section's chains")
        self.assertRefused({"block": "keep-asking", "chains": [{**chain, "subject": "astrology"}]}, "is not a subject")
        self.assertRefused({"block": "keep-asking", "chains": [chain], "source": {"ids": []}}, "each chain names its own cards")

    def test_the_ruler_of_time(self):
        light = {"id": "light", "ago": 13.8e9, "label": "The first light", "when": "13.8 billion years ago", "source": {"ids": [card_where(lambda c: True)["id"]]}}
        self.assertEqual(problems({"block": "through-time", "stops": [light, {"id": "now", "era": "recent", "ago": 14}]}), [])
        self.assertRefused({"block": "through-time", "stops": [light]}, "2 to 12 stops")
        self.assertRefused({"block": "through-time", "stops": [{**light, "ago": -1}, {"id": "b", "era": "recent", "ago": 1}]}, "a number from 0")
        self.assertRefused({"block": "through-time", "stops": [{"id": "a", "ago": 5, "label": "A", "when": "B"}, {"id": "b", "era": "recent", "ago": 1}]}, "give it an era of the bank, or a source")
        self.assertRefused({"block": "through-time", "stops": [{"id": "a", "era": "jurassic", "ago": 5}, {"id": "b", "era": "recent", "ago": 1}]}, "'jurassic' is not an age")
        self.assertRefused({"block": "through-time", "stops": [{**light, "label": None}, {"id": "b", "era": "recent", "ago": 1}]}, "stops[0].label is missing")
        self.assertRefused({"block": "through-time", "stops": [{"id": "a", "era": "medieval", "ago": 5}, {"id": "b", "era": "recent", "ago": 5}]}, "sits where stops[0] does")
        self.assertRefused({"block": "through-time", "stops": [{"id": "b", "era": "recent", "ago": 1}, light]}, "oldest first")
        self.assertRefused({"block": "through-time", "stop": "jurassic"}, "not one of the ruler's stops")
        self.assertEqual(problems({"block": "through-time", "stop": "medieval"}), [])
        self.assertRefused({"block": "through-time", "limit": 3}, "from 1 to 2")

    def test_parts_with_no_cards_take_no_source(self):
        for name in ("masthead", "edition-end", "questions-asked", "keep-asking"):
            self.assertRefused({"block": name, "source": {"ids": []}}, "source is not read")

    def test_words_a_part_draws_nothing_from_are_refused(self):
        self.assertRefused({"block": "front-lead", "title": "The lead"}, "title is not read: the lead's words are its headline and deck")
        self.assertRefused({"block": "front-columns", "subtitle": "Two views"}, "subtitle is not read")
        self.assertRefused({"block": "front-columns", "limit": 2}, "limit is not read")
        self.assertRefused({"block": "front-puzzle", "subtitle": "Think"}, "subtitle is not read")
        self.assertRefused({"block": "front-numbers", "subtitle": "Three figures"}, "subtitle is not read")
        self.assertRefused({"block": "masthead", "subtitle": "Daily"}, "its lines are the kicker, left and right")
        self.assertRefused({"block": "ask-first", "subtitle": "Ask"}, "subtitle is not read")
        # What the parts do read passes.
        for section in (
            {"block": "front-numbers", "title": "By the numbers", "limit": 4},
            {"block": "front-correction", "title": "Corrected", "subtitle": "What we got wrong"},
            {"block": "front-puzzle", "title": "Sunday puzzle", "button": "Solve it"},
            {"block": "edition-end", "title": "That was Sunday", "subtitle": "Monday at seven", "size": "s"},
            {"block": "ask-first", "title": "What puzzles you?", "hint": "A word will do"},
        ):
            self.assertEqual(problems(section), [], section["block"])

    def test_the_figure_is_found_as_the_app_finds_it(self):
        self.assertEqual(screens.shelf_figure("Of 76 highly cited animal studies, how many?"), "76")
        self.assertEqual(screens.shelf_figure("A test is over 99% accurate. Why?"), "99%")
        self.assertEqual(screens.shelf_figure("In 1529 the siege lasted three weeks."), None)
        self.assertEqual(screens.shelf_figure("A €300,000 flat costs 1% a year."), "1%")
        self.assertEqual(screens.shelf_figure("It sold 1,250,000 copies."), "1.25M")
        self.assertEqual(screens.shelf_figure("About 3 billion people."), "3B")
        self.assertEqual(screens.shelf_figure("One in 1/10 of cases."), "1/10")


if __name__ == "__main__":
    unittest.main()
