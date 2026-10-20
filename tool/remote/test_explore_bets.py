"""The checks for the bets blocks of Explore: the sections the app draws as
they were meant pass, and every way of saying something the app would
quietly put right or leave out is refused, item by item."""
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
from parts.explore_blocks import bets  # noqa: E402

CASES = json.loads((ROOT / "test" / "explore" / "bets_cases.json").read_text(encoding="utf-8"))

# Cards the bank holds, one of each way a card can be bet on (and not).
SHARE_TYPED = "art-detection-9"        # range, day, bigger, closer
SHARE_PICK = "art-who-gets-in-museums-1"  # stake, bigger, closer
AMOUNTS_PICK = "art-motives-2"         # stake
ODDS_PICK = "language-spin-2"          # stake, magnitude
ESTIMATE = "art-marble-3"              # magnitude
STEPPED = "art-art-and-money-3"        # number
WORDS_PICK = "art-abstraction-1"       # nothing: its options are words
READ = "art-abstraction-4"             # nothing: no question to answer


def check(section: dict) -> list[str]:
    return bets.BLOCKS[section["block"]](section)


def section(block: str, **fields) -> dict:
    return {"id": "x", "block": block, **fields}


class SameAsTheApp(unittest.TestCase):
    """The checker's reading of a card is the app's: both are held to the
    cases in test/explore/bets_cases.json."""

    def test_amounts(self):
        for option, value, percent in CASES["amounts"]:
            got = bets.amount(option)
            if value is None:
                self.assertIsNone(got, option)
            else:
                self.assertIsNotNone(got, option)
                self.assertAlmostEqual(got[0], value, msg=option)
                self.assertEqual(got[1], percent, option)

    def test_odds(self):
        for option, n in CASES["odds"]:
            self.assertEqual(bets.odds_of(option), n, option)

    def test_which_blocks_bet_on_which_cards(self):
        for cid, blocks in CASES["cards"].items():
            card = bets.bank()[cid]
            self.assertEqual(sorted(b for b in bets.BLOCKS if bets.fits(b, card)), blocks, cid)

    def test_the_plain_form_an_answer_is_kept_in(self):
        for v, plain in CASES["plain"]:
            self.assertEqual(bets.plain_response(v), plain, v)

    def test_the_numbers_cards_are_placed_by(self):
        for text, unit in CASES["units"]:
            self.assertEqual(bets.bet_unit(text), unit, text)

    def test_dart_rounds_halves_away_from_nought(self):
        self.assertEqual([bets.dart_round(x) for x in (0.5, 1.5, 2.5, -2.5, 2.4999)], [1, 2, 3, -3, 2])

    def test_the_right_notch_is_one_the_card_counts_right(self):
        card = bets.bank()[ESTIMATE]
        a = bets.answer_of(card)
        values = bets.notches(card, a)
        right = [v for v in values if bets.accepts(card, bets.plain_response(v))]
        self.assertEqual(len(values), 6)
        self.assertEqual(len(right), 1)


class TheBlocks(unittest.TestCase):
    def test_every_bets_block_is_one_the_app_can_draw(self):
        self.assertEqual(set(bets.BLOCKS), {
            "bets-range", "bets-slip", "bets-stake", "bets-friend", "bets-number",
            "bets-bigger", "bets-closer", "bets-magnitude", "bets-day",
        })
        self.assertTrue(set(bets.BLOCKS) <= set(explore.blocks()))

    def test_a_section_with_only_its_block_passes(self):
        for name in bets.BLOCKS:
            self.assertEqual(check(section(name)), [], name)

    def test_every_example_in_the_doc_passes(self):
        doc = (ROOT / "docs" / "explore" / "bets.md").read_text(encoding="utf-8")
        examples = [json.loads(m) for m in re.findall(r"```json\n(.*?)```", doc, re.S)]
        self.assertGreaterEqual(len(examples), len(bets.BLOCKS))
        named = set()
        for example in examples:
            sections = example["sections"] if "sections" in example else [example]
            self.assertEqual(explore.check({"sections": sections}), [], example)
            named |= {s["block"] for s in sections}
        self.assertTrue(set(bets.BLOCKS) <= named)


class Refused(unittest.TestCase):
    def assertRefused(self, section: dict, *words: str):
        problems = check(section)
        self.assertTrue(problems, section)
        for w in words:
            self.assertTrue(any(w in p for p in problems), (w, problems))

    def test_sizes_limits_and_looks(self):
        self.assertRefused(section("bets-range", size="xl"), "size 'xl'")
        for bad in (0, 13, 2.5, True, "3"):
            self.assertRefused(section("bets-range", limit=bad), "limit")
        self.assertEqual(check(section("bets-range", limit=12.0)), [])
        self.assertRefused(section("bets-bigger", limit=7), "from 1 to 6")
        self.assertRefused(section("bets-friend", limit=2), "shows one card")
        self.assertRefused(section("bets-slip", size="s", limit=3), "only at size m")
        self.assertRefused(section("bets-day", size="l", limit=3), "stands alone")
        self.assertRefused(section("bets-stake", style="page"), "style is not an object")
        self.assertRefused(section("bets-stake", style={"tone": "dark"}), "style.tone")
        self.assertRefused(section("bets-stake", style={"colour": "red"}), "style.colour")
        self.assertRefused(section("bets-slip", style={"tone": "page"}), "one look")
        self.assertRefused(section("bets-friend", style={"tone": "page"}), "one look")
        self.assertEqual(check(section("bets-bigger", style={"tone": "subject"})), [])

    def test_words(self):
        self.assertRefused(section("bets-day", title=""), "title is empty")
        self.assertRefused(section("bets-day", title={"xx": "Hi"}), "'xx'")
        self.assertRefused(section("bets-day", title={"it": ""}), "title.it")
        self.assertRefused(section("bets-day", subtitle=3), "subtitle")
        self.assertRefused(section("bets-slip", subtitle="Today"), "no line under its title")
        self.assertEqual(check(section("bets-day", title={"en": "Bet", "it": "Scommessa"})), [])

    def test_a_field_the_block_does_not_read(self):
        self.assertRefused(section("bets-stake", walet=True), "'walet'")
        # The range is a bet of how sure in itself: it never asks.
        self.assertRefused(section("bets-range", sure=False), "'sure'")
        self.assertRefused(section("bets-closer", sure=False), "'sure'")

    def test_switches_and_counts(self):
        for key in ("wallet", "slip"):
            self.assertRefused(section("bets-range", **{key: "yes"}), key)
        for key in ("tag", "same", "sure"):
            self.assertRefused(section("bets-day", **{key: 1}), key)
        self.assertRefused(section("bets-closer", steps=6), "steps")
        self.assertRefused(section("bets-closer", steps=2.5), "steps")
        self.assertEqual(check(section("bets-closer", steps=2.0)), [])
        self.assertRefused(section("bets-bigger", gap=0), "gap")

    def test_widths(self):
        ok = section("bets-range", widths=[[2, 50], [8, 25], [15, 12], [25, 5]])
        self.assertEqual(check(ok), [])
        for bad in ([[5, 30]], [[5, 30], [5, 20]], [[5, 30], [10, 30]], [[5.0, 30], [10, 20]],
                    [[0, 30], [10, 20]], [[5, 1001], [10, 20]], [[5, 30, 1], [10, 20]],
                    [[5, 30], [10, 20], [15, 10], [20, 5], [25, 2]], "narrow"):
            self.assertRefused(section("bets-range", widths=bad), "widths")

    def test_stakes(self):
        self.assertEqual(check(section("bets-stake", stakes=[5, 25, 50, 100])), [])
        for bad in ([], [10, 10], [30, 20], [0, 10], [10, 200], [1, 2, 3, 4, 5], [10.5], "10"):
            self.assertRefused(section("bets-stake", stakes=bad), "stakes")

    def test_kinds(self):
        self.assertEqual(check(section("bets-slip", kinds=["range", "stake"])), [])
        self.assertRefused(section("bets-slip", kinds=["friend"]), "'friend'")
        self.assertRefused(section("bets-slip", kinds="range"), "kinds")

    def test_cards_a_block_cannot_bet_on(self):
        self.assertEqual(check(section("bets-range", source={"ids": [SHARE_TYPED]})), [])
        self.assertEqual(check(section("bets-stake", source={"ids": [SHARE_PICK, AMOUNTS_PICK, ODDS_PICK]})), [])
        self.assertEqual(check(section("bets-magnitude", source={"ids": [ESTIMATE, ODDS_PICK]})), [])
        self.assertEqual(check(section("bets-number", source={"ids": [STEPPED]})), [])
        self.assertRefused(section("bets-number", source={"ids": [SHARE_TYPED]}), "not one bets-number bets on")
        self.assertRefused(section("bets-range", source={"ids": [SHARE_PICK]}), "not one bets-range bets on")
        self.assertRefused(section("bets-stake", source={"ids": [WORDS_PICK]}), "no number for an answer")
        self.assertRefused(section("bets-slip", source={"ids": [READ]}), "no number for an answer")
        self.assertRefused(section("bets-day", source={"ids": ["no-such-card"]}), "no card 'no-such-card'")
        self.assertRefused(section("bets-day", source={"ids": [SHARE_TYPED, SHARE_TYPED]}), "twice")
        self.assertRefused(section("bets-day", source={"ids": []}), "source.ids")
        retired = next(cid for cid, c in sorted(bets.bank().items()) if c.get("disabled"))
        self.assertRefused(section("bets-friend", source={"ids": [retired]}), "retired")

    def test_the_card_to_send(self):
        self.assertEqual(check(section("bets-friend", card=AMOUNTS_PICK)), [])
        self.assertEqual(check(section("bets-friend", card=ESTIMATE)), [])
        self.assertRefused(section("bets-friend", card=READ), "no number for an answer")
        self.assertRefused(section("bets-friend", card=7), "not a card id")

    def test_pairs_and_their_labels(self):
        other = next(cid for cid, c in sorted(bets.bank().items())
                     if not c.get("disabled") and bets.fits("bets-bigger", c)
                     and bets.answer_of(c)["value"] != bets.answer_of(bets.bank()[SHARE_TYPED])["value"])
        good = section("bets-bigger", pairs=[[SHARE_TYPED, other]],
                       labels={SHARE_TYPED: {"en": "Fakes found", "it": "Falsi scoperti"}})
        self.assertEqual(check(good), [])
        self.assertRefused(section("bets-bigger", pairs=[[SHARE_TYPED]]), "pairs[0] is not [id, id]")
        self.assertRefused(section("bets-bigger", pairs=[[SHARE_TYPED, SHARE_TYPED]]), "the same")
        self.assertRefused(section("bets-bigger", pairs=[[SHARE_TYPED, ESTIMATE]]), "not one bets-bigger bets on")
        self.assertRefused(section("bets-bigger", labels={READ: "x"}), "labels")
        self.assertRefused(section("bets-bigger", labels={SHARE_TYPED: ""}), "labels.")

    def test_through_the_document(self):
        doc = {"sections": [
            {"id": "a", "block": "bets-range"},
            {"id": "b", "block": "bets-stake", "stakes": [50, 10]},
            {"id": "c", "block": "bets-nope"},
        ]}
        problems = explore.check(doc)
        self.assertEqual(len(problems), 2, problems)
        self.assertTrue(problems[0].startswith("section 'b': stakes"), problems)
        self.assertTrue(problems[1].startswith("section 'c': block 'bets-nope'"), problems)


if __name__ == "__main__":
    unittest.main()
