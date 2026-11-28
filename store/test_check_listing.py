"""The store listing's checker: the listing as it stands passes, and each of
the old listing's mistakes, put back, is caught — three minutes, eighteen
subjects, seven days free, two cards free — as is a feature that is off,
a lock screen, a price, a word Google Play refuses, and a copy page that
has drifted from the listing.

    python3 -m unittest store/test_check_listing.py
"""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import check_listing  # noqa: E402

LISTING = (HERE / "listing.md").read_text(encoding="utf-8")
FACTS = check_listing.app_facts()


def problems(text: str) -> list[str]:
    return check_listing.problems(text, FACTS)


def swapped(old: str, new: str, text: str = LISTING) -> str:
    """The listing with [old] said as [new], once; the test fails if the
    listing no longer says [old]."""
    assert text.count(old) >= 1, old
    return text.replace(old, new, 1)


class AppFactsTest(unittest.TestCase):
    def test_the_numbers_are_read_from_the_code(self):
        self.assertEqual(FACTS["subjects"], 20)
        self.assertEqual(FACTS["per_day"], 5)
        self.assertEqual(FACTS["own_free"], 2)
        self.assertEqual(FACTS["at_random"], 3)
        self.assertEqual(FACTS["trial_days"], 14)
        self.assertEqual(FACTS["minutes"], 2)
        self.assertEqual(FACTS["languages"], 13)
        self.assertEqual(FACTS["path_cards"], 10)
        self.assertEqual(FACTS["sure"], (50, 90))
        self.assertGreater(FACTS["drawn"], 0)
        self.assertGreater(FACTS["cards"], FACTS["drawn"])

    def test_a_switch_counts_as_shipped_only_when_on_for_everyone(self):
        flags = FACTS["flags"]
        self.assertIn("listen", flags)
        self.assertIsInstance(flags["listen"], bool)


class ListingTest(unittest.TestCase):
    def test_the_listing_as_it_stands_passes(self):
        self.assertEqual(problems(LISTING), [])

    def test_the_numbers_say_numbers_in_words_and_figures(self):
        self.assertEqual(check_listing.number("fourteen", "en"), 14)
        self.assertEqual(check_listing.number("venti", "it"), 20)
        self.assertEqual(check_listing.number("6.000", "it"), 6000)
        self.assertEqual(check_listing.number("6,000", "en"), 6000)
        self.assertIsNone(check_listing.number("few", "en"))


class OldMistakesTest(unittest.TestCase):
    """What the old Play listing said, put back into the new one."""

    def test_three_minutes(self):
        found = problems(swapped("in about two minutes", "in about three minutes"))
        self.assertTrue(any("minutes" in p and "says 3" in p for p in found), found)

    def test_eighteen_subjects(self):
        found = problems(swapped("tra venti:", "tra diciotto:"))
        self.assertTrue(any("subjects" in p and "says 18" in p for p in found), found)

    def test_seven_days_free(self):
        found = problems(swapped("starts with 14 days free", "starts with 7 days free"))
        self.assertTrue(any("trial_days" in p for p in found), found)

    def test_two_cards_free(self):
        found = problems(swapped("Every morning you get five cards", "Every morning you get two cards"))
        self.assertTrue(any("per_day" in p and "says 2" in p for p in found), found)

    def test_a_description_has_to_say_the_trial(self):
        found = problems(swapped("L'abbonamento annuale parte con 14 giorni gratis:", "L'abbonamento annuale parte con una prova:"))
        self.assertTrue(any("does not say" in p and "trial_days" in p for p in found), found)


class HonestyTest(unittest.TestCase):
    def test_a_feature_that_is_off_is_not_named(self):
        facts = dict(FACTS, flags=dict(FACTS["flags"], listen=False))
        text = swapped("A habit that stays small", "Listen to your five. A habit that stays small")
        found = check_listing.problems(text, facts)
        self.assertTrue(any("listen" in p for p in found), found)

    def test_a_feature_that_is_on_may_be_named(self):
        facts = dict(FACTS, flags=dict(FACTS["flags"], listen=True))
        text = swapped("A habit that stays small", "Listen to your five. A habit that stays small")
        self.assertEqual(check_listing.problems(text, facts), [])

    def test_the_cards_in_english_are_said(self):
        found = problems(swapped("Le carte, per ora, sono in inglese.", ""))
        self.assertTrue(any("in English" in p for p in found), found)

    def test_no_lock_screen_on_android(self):
        found = problems(swapped("widgets for your home screen", "widgets for your home and lock screen"))
        self.assertTrue(any("lock screen" in p for p in found), found)

    def test_no_price(self):
        found = problems(swapped("There are no ads.", "There are no ads. Astute+ is €29.99 a year."))
        self.assertTrue(any("price" in p for p in found), found)

    def test_more_drawn_cards_than_the_bank_has(self):
        found = problems(swapped("More than 900 cards are drawn", f"More than {FACTS['drawn'] + 100} cards are drawn"))
        self.assertTrue(any("drawn" in p for p in found), found)

    def test_the_levels_of_how_sure(self):
        found = problems(swapped("from 50% to 90%", "from 0% to 100%"))
        self.assertTrue(any("asks from 50% to 90%" in p for p in found), found)


class PlayRulesTest(unittest.TestCase):
    def test_free_in_the_title_is_refused(self):
        found = problems(swapped("Astute: Daily Facts & Quiz", "Astute: Free Daily Facts"))
        self.assertTrue(any("Google Play refuses" in p for p in found), found)

    def test_gratis_in_the_short_description_is_refused(self):
        found = problems(swapped("cinque carte, e di ognuna il perché.", "cinque carte gratis, col perché."))
        self.assertTrue(any("Google Play refuses" in p for p in found), found)

    def test_no_capitals_and_no_emoji(self):
        found = problems(swapped("Astute: Daily Facts & Quiz", "Astute: DAILY Facts ✨"))
        self.assertTrue(any("capitals" in p for p in found), found)
        self.assertTrue(any("emoji" in p for p in found), found)

    def test_limits_hold(self):
        found = problems(swapped("Astute: Daily Facts & Quiz", "Astute: Daily Facts & Quiz & Questions"))
        self.assertTrue(any("the limit is 30" in p for p in found), found)


class PlayPageTest(unittest.TestCase):
    def test_the_copy_page_carries_the_listing_word_for_word(self):
        page = (HERE / "play_it_en.md").read_text(encoding="utf-8")
        self.assertEqual(check_listing.play_page(check_listing.fields(LISTING), page), [])

    def test_a_page_that_has_drifted_is_caught(self):
        page = (HERE / "play_it_en.md").read_text(encoding="utf-8").replace("Five cards a day. A little sharper.", "Five cards a day.")
        self.assertTrue(check_listing.play_page(check_listing.fields(LISTING), page))


if __name__ == "__main__":
    unittest.main()
