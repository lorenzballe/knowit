"""The shapes family's checker: every block it knows, every field each reads,
and a problem for everything else, said so a person can fix it."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from parts import explore  # noqa: E402
from parts.explore_blocks import shapes  # noqa: E402


def check(block: str, **fields) -> list[str]:
    return shapes.BLOCKS[block]({"id": "x", "block": block, **fields})


class WordsTest(unittest.TestCase):
    def test_every_block_in_the_words_has_a_check_and_a_name_of_the_family(self):
        self.assertEqual(set(shapes.BLOCKS), set(shapes.WORDS["blocks"]))
        self.assertEqual(len(shapes.BLOCKS), 34)
        for name in shapes.BLOCKS:
            self.assertTrue(name.startswith("shape-"), name)

    def test_every_block_says_where_on_the_canvas_it_was_drawn(self):
        for name, spec in shapes.WORDS["blocks"].items():
            self.assertTrue(spec["canvas"], name)
            for anchor in spec["canvas"]:
                self.assertRegex(anchor, r"^13[12][a-f]$", name)
            self.assertIn(spec["kind"], shapes.WORDS["kinds"], name)
            self.assertEqual(spec["sizes"], ["s", "m", "l"], name)
            self.assertTrue(spec["signatures"], name)
            for signature, kind in spec["signatureKinds"].items():
                self.assertIn(signature, spec["signatures"], name)
                self.assertIn(kind, shapes.WORDS["kinds"], name)

    def test_the_explore_part_knows_every_block(self):
        known = explore.blocks()
        for name in shapes.BLOCKS:
            self.assertIn(name, known)


class SectionTest(unittest.TestCase):
    def test_a_bare_section_passes_for_every_block(self):
        for name in shapes.BLOCKS:
            self.assertEqual(check(name), [], name)

    def test_every_size_and_signature_a_block_has_passes(self):
        for name, spec in shapes.WORDS["blocks"].items():
            for size in spec["sizes"]:
                self.assertEqual(check(name, size=size), [], name)
            for signature in spec["signatures"]:
                self.assertEqual(check(name, signature=signature), [], name)

    def test_a_field_no_shape_reads_is_named(self):
        problems = check("shape-fold", sise="m")
        self.assertEqual(len(problems), 1)
        self.assertIn("'sise'", problems[0])
        self.assertIn("shape-fold", problems[0])

    def test_a_field_of_another_shape_is_not_this_ones(self):
        self.assertTrue(check("shape-fold", codes={}))
        self.assertTrue(check("shape-fold", order="years"))
        self.assertEqual(check("shape-stamp", codes={}), [])
        self.assertEqual(check("shape-timeline", order="given"), [])

    def test_sizes_signatures_and_limits_are_the_blocks_own(self):
        self.assertIn("s, m, l", check("shape-fold", size="xl")[0])
        self.assertIn("quote", check("shape-quote", signature="mark")[0])
        self.assertEqual(check("shape-deck", signature="quote"), [])
        self.assertTrue(check("shape-hand", limit=6))
        self.assertTrue(check("shape-fold", limit=0))
        self.assertTrue(check("shape-fold", limit=True))
        self.assertTrue(check("shape-fold", limit="8"))
        self.assertEqual(check("shape-fold", limit=12), [])

    def test_min_is_within_the_limit(self):
        self.assertEqual(check("shape-fold", min=2), [])
        self.assertTrue(check("shape-fold", min=0))
        self.assertTrue(check("shape-fold", limit=4, min=5))
        self.assertEqual(check("shape-fold", limit=4, min=4), [])

    def test_a_kind_is_one_a_shape_keeps_to(self):
        self.assertEqual(check("shape-fold", kind="paradoxes"), [])
        self.assertIn("kind 'legends'", check("shape-fold", kind="legends")[0])

    def test_a_variant_is_for_the_past_and_a_place(self):
        self.assertEqual(check("shape-years", variant=2), [])
        self.assertEqual(check("shape-stamp", variant=0), [])
        self.assertTrue(check("shape-years", variant=3))
        self.assertTrue(check("shape-years", variant=True))
        self.assertIn("only for the past", check("shape-fold", variant=1)[0])
        self.assertEqual(check("shape-fold", kind="past", variant=1), [])

    def test_a_subject_is_for_a_month(self):
        self.assertEqual(check("shape-grid", subject="space"), [])
        self.assertTrue(check("shape-grid", subject="thinking"))
        self.assertIn("only for a month", check("shape-fold", subject="space")[0])

    def test_a_signature_can_make_the_shelf_another_kind(self):
        # A grid of figures keeps to numbers, as the app reads it: a month's
        # subject means nothing to it unless the section says it is a month.
        self.assertEqual(shapes.WORDS["blocks"]["shape-grid"]["signatureKinds"], {"figure": "numbers"})
        self.assertIn("only for a month", check("shape-grid", signature="figure", subject="space")[0])
        self.assertEqual(check("shape-grid", signature="figure", kind="month", subject="space"), [])
        self.assertEqual(check("shape-grid", signature="none", subject="space"), [])
        # A signature the block does not carry is refused, and the kind is
        # the one the app falls back to.
        problems = check("shape-grid", signature="quote", subject="space")
        self.assertEqual(len(problems), 1)
        self.assertIn("signature 'quote'", problems[0])

    def test_style_keys_are_the_blocks_own_and_of_their_kind(self):
        self.assertEqual(check("shape-stamp", style={"tilt": True}), [])
        self.assertTrue(check("shape-stamp", style={"tilt": "yes"}))
        self.assertEqual(check("shape-checklist", style={"rings": "all", "shown": 4}), [])
        self.assertTrue(check("shape-checklist", style={"rings": "some"}))
        self.assertTrue(check("shape-checklist", style={"shown": 9}))
        self.assertTrue(check("shape-checklist", style={"shown": True}))
        self.assertIn("'tilt'", check("shape-fold", style={"tilt": True})[0])
        self.assertTrue(check("shape-fold", style=[]))

    def test_codes_name_cards_of_the_bank_and_countries_in_capitals(self):
        self.assertEqual(check("shape-stamp", codes={"sport-formations-3": "HU"}), [])
        self.assertTrue(check("shape-stamp", codes={"no-such-card": "HU"}))
        self.assertTrue(check("shape-stamp", codes={"sport-formations-3": "hu"}))
        self.assertTrue(check("shape-postcard", codes=["HU"]))

    def test_an_order_is_given_or_years(self):
        self.assertTrue(check("shape-ruler", order="alphabetical"))
        self.assertEqual(check("shape-ruler", order="years"), [])

    def test_titles_have_words_and_english(self):
        self.assertEqual(check("shape-fold", title="Legends"), [])
        self.assertEqual(check("shape-fold", title={"en": "Legends", "it": "Leggende"}), [])
        self.assertTrue(check("shape-fold", title=""))
        self.assertTrue(check("shape-fold", title={"it": "Leggende"}))
        self.assertTrue(check("shape-fold", title={"en": "Legends", "xx": "?"}))
        self.assertTrue(check("shape-fold", subtitle={"en": ""}))
        self.assertTrue(check("shape-fold", title=3))

    def test_a_shelf_of_any_kind_needs_a_name(self):
        self.assertIn("give it a title", check("shape-fold", kind="any")[0])
        self.assertEqual(check("shape-fold", kind="any", title="From the server"), [])


class DocumentTest(unittest.TestCase):
    def test_a_document_of_shapes_passes_the_explore_part(self):
        doc = {
            "sections": [
                {"id": "myths", "block": "shape-quote", "size": "m"},
                {"id": "past", "block": "shape-ruler", "variant": 2},
                {"id": "europe", "block": "shape-stamp", "style": {"tilt": True}},
                {"id": "paradoxes", "block": "shape-hand", "signature": "circles", "audience": {"minBuild": 2}},
            ]
        }
        self.assertEqual(explore.check(doc), [])

    def test_a_shapes_problem_names_its_section(self):
        doc = {"sections": [{"id": "myths", "block": "shape-quote", "size": "xl"}]}
        problems = explore.check(doc)
        self.assertEqual(len(problems), 1)
        self.assertTrue(problems[0].startswith("section 'myths': size 'xl'"))


if __name__ == "__main__":
    unittest.main()
