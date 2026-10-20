"""The purpose blocks' checks: every block the app draws has one, each
knows what the app knows, and each refuses what this build would pass
over or misread, field by field."""
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
from parts.explore_blocks import purpose  # noqa: E402

BLOCKS_DIR = ROOT / "lib" / "explore" / "blocks" / "purpose"


def dart(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def drawn_blocks() -> dict[str, str]:
    """Every block the purpose family draws, by name, with the source of
    its class."""
    out = {}
    for path in sorted(BLOCKS_DIR.glob("*.dart")):
        text = path.read_text(encoding="utf-8")
        starts = [m.start() for m in re.finditer(r"^class ", text, re.M)] + [len(text)]
        for a, b in zip(starts, starts[1:]):
            body = text[a:b]
            m = re.search(r"String get name => '(purpose\.[a-z-]+)';", body)
            if m:
                out[m.group(1)] = body
    return out


def a_card_id() -> str:
    return sorted(purpose.bank_ids())[0]


class TheChecksKnowWhatTheAppKnows(unittest.TestCase):
    def test_every_block_the_app_draws_has_a_check_and_no_other(self):
        drawn = drawn_blocks()
        self.assertEqual(len(drawn), 29)
        self.assertEqual(set(purpose.BLOCKS), set(drawn))
        listed = dart("lib/explore/blocks/purpose_blocks.dart")
        for name, body in drawn.items():
            cls = re.match(r"class (\w+)", body).group(1)
            self.assertIn(f"{cls}()", listed, f"{cls} is not in the family's list")

    def test_each_block_has_the_sizes_the_app_draws(self):
        for name, body in drawn_blocks().items():
            m = re.search(r"static const Map<String, .*?> sizes = \{(.*?)\};", body, re.S)
            sizes = tuple(re.findall(r"'(\w+)':", m.group(1))) if m else ()
            self.assertEqual(set(purpose.SIZES[name]), set(sizes), name)

    def test_the_themes_are_the_apps(self):
        enum = re.search(r"enum ShelfTheme \{(.*?)\}", dart("lib/data/themed_shelves.dart"), re.S).group(1)
        self.assertEqual(set(purpose.THEMES), set(re.findall(r"(\w+),", enum)))

    def test_the_moves_are_the_apps(self):
        enum = re.search(r"enum Principle \{(.*?)const Principle\(", dart("lib/models/pill.dart"), re.S).group(1)
        names = set(re.findall(r"^\s+(\w+)\(", enum, re.M)) - {"none"}
        self.assertEqual(set(purpose.MOVES), names)

    def test_the_subjects_are_the_apps(self):
        topics = re.search(r"kTopics = \{(.*?)\n\};", dart("lib/data/topics.dart"), re.S).group(1)
        self.assertEqual(purpose.SUBJECTS, set(re.findall(r"^  '(\w+)':", topics, re.M)))

    def test_the_parts_of_life_are_the_apps(self):
        life = dart("lib/explore/blocks/purpose/life.dart")
        self.assertEqual(list(purpose.LIFE), re.findall(r"LifeTopic\(\s*'(\w+)'", life))

    def test_the_commit_kinds_are_the_apps(self):
        commit = dart("lib/explore/blocks/purpose/commit.dart")
        self.assertEqual(set(purpose.KINDS), set(re.findall(r"^  \w+\('([a-z-]+)'\)", commit, re.M)))

    def test_the_languages_are_the_apps(self):
        files = {p.stem.removeprefix("app_") for p in (ROOT / "lib" / "l10n").glob("app_*.arb")}
        self.assertEqual(purpose.LANGUAGES, files)


class EveryBlockAloneLooksRight(unittest.TestCase):
    def test_a_section_with_only_an_id_and_a_block_passes(self):
        for name, check in purpose.BLOCKS.items():
            self.assertEqual(check({"id": "x", "block": name}), [], name)

    def test_the_documented_sections_pass(self):
        doc = dart("docs/explore/purpose.md")
        found = 0
        for raw in re.findall(r"```json\n(.*?)```", doc, re.S):
            section = json.loads(raw)
            if not str(section.get("block", "")).startswith("purpose."):
                continue
            found += 1
            self.assertEqual(purpose.BLOCKS[section["block"]](section), [], raw)
        self.assertGreaterEqual(found, 29)

    def test_a_document_of_them_passes_the_explore_check(self):
        doc = {"sections": [{"id": f"s{i}", "block": name} for i, name in enumerate(purpose.BLOCKS)]}
        self.assertEqual(explore.check(doc), [])


class WhatEverySectionIsCheckedFor(unittest.TestCase):
    def problems(self, **fields):
        return purpose.BLOCKS["purpose.why"]({"id": "x", "block": "purpose.why", **fields})

    def test_a_field_the_block_does_not_read(self):
        self.assertEqual(self.problems(theme="myths"), ["the block reads no field 'theme'"])

    def test_words_want_english(self):
        self.assertEqual(self.problems(title={"en": "Why"}), [])
        self.assertEqual(self.problems(title="Why"), [])
        self.assertIn("title has no English", self.problems(title={"it": "Perché"})[0])
        self.assertIn("'xx' is not a language", self.problems(title={"en": "Why", "xx": "?"})[0])
        self.assertEqual(self.problems(subtitle={"en": ""}), ["subtitle.en is not words"])
        self.assertEqual(self.problems(title=3), ["title is neither words nor words by language"])

    def test_a_size_the_block_has(self):
        self.assertEqual(self.problems(size="l"), [])
        self.assertIn("size 'xl' is not one of the block's", self.problems(size="xl")[0])
        end = purpose.BLOCKS["purpose.end"]({"id": "x", "block": "purpose.end", "size": "m"})
        self.assertEqual(end, ["the block has one size only: leave size out"])

    def test_a_limit_the_family_lays_out(self):
        self.assertEqual(self.problems(limit=24), [])
        for bad in (0, 25, 2.5, True, "8"):
            self.assertEqual(len(self.problems(limit=bad)), 1, bad)

    def test_fit_and_style(self):
        self.assertEqual(self.problems(fit=False), [])
        self.assertEqual(self.problems(fit="no"), ["fit is not true or false"])
        self.assertEqual(self.problems(style={"tone": "dark"}), ["the block reads no style 'tone'"])
        self.assertEqual(self.problems(style=[]), ["style is not an object"])

    def test_the_engines_fields_are_left_to_the_engine(self):
        self.assertEqual(self.problems(source={"anything": True}, audience={"plus": True}), [])


class EachBlocksOwnFields(unittest.TestCase):
    def check(self, block, **fields):
        return purpose.BLOCKS[block]({"id": "x", "block": block, **fields})

    def test_read_or_do(self):
        good = {"shelves": [{"theme": "myths"}, {"id": "own", "title": {"en": "Mine"}, "source": {}}]}
        self.assertEqual(self.check("purpose.read-or-do", **good), [])
        self.assertEqual(self.check("purpose.read-or-do", style={"filter": False, "count": True, "shelves": 3}), [])
        self.assertIn("style.shelves 9", self.check("purpose.read-or-do", style={"shelves": 9})[0])
        self.assertIn("is not a theme", self.check("purpose.read-or-do", shelves=[{"theme": "dragons"}])[0])
        self.assertIn("neither a theme nor a title", self.check("purpose.read-or-do", shelves=[{"id": "a"}])[0])
        self.assertIn("called 'myths'", self.check("purpose.read-or-do", shelves=[{"theme": "myths"}, {"theme": "myths"}])[0])
        self.assertIn("is not an object", self.check("purpose.read-or-do", shelves=["myths"])[0])
        both = self.check("purpose.read-or-do", shelves=[{"theme": "myths"}], style={"shelves": 2})
        self.assertIn("style.shelves counts the day's themes", both[0])

    def test_themes_with_forms(self):
        for good in ("past", "past-0", "place-2", "myths-0"):
            self.assertEqual(purpose.theme(good), [], good)
        for bad in ("past-3", "myths-1", "place-x", ""):
            self.assertEqual(len(purpose.theme(bad)), 1, bad)

    def test_commit_note_and_commit(self):
        self.assertEqual(self.check("purpose.commit-note", text={"en": "Answer first."}), [])
        self.assertEqual(self.check("purpose.commit", kind="side"), [])
        self.assertIn("kind 'bet'", self.check("purpose.commit", kind="bet")[0])

    def test_move(self):
        self.assertEqual(self.check("purpose.move", move="baseRate", name={"en": "Base rates"}), [])
        self.assertIn("is not a move", self.check("purpose.move", move="luck")[0])
        self.assertIn("names none", self.check("purpose.move", name={"en": "Mine"})[0])

    def test_thin_subject(self):
        self.assertEqual(self.check("purpose.thin-subject", subject="human_body"), [])
        self.assertIn("subject's key", self.check("purpose.thin-subject", subject="Human body")[0])

    def test_moving(self):
        card = a_card_id()
        self.assertEqual(self.check("purpose.moving", updated={card: "2026-10-04"}), [])
        self.assertIn("not a date", self.check("purpose.moving", updated={card: "4 Oct"})[0])
        self.assertIn("not a card in the bank", self.check("purpose.moving", updated={"no-such-card": "2026-10-04"})[0])
        self.assertIn("not an object", self.check("purpose.moving", updated=[card])[0])

    def test_footers_and_lines(self):
        for block, field in (
            ("purpose.thats-me", "footer"),
            ("purpose.played", "footer"),
            ("purpose.end", "line"),
            ("purpose.end", "subline"),
        ):
            self.assertEqual(self.check(block, **{field: {"en": "Words"}}), [], block)
            self.assertIn("has no English", self.check(block, **{field: {"it": "Parole"}})[0], block)

    def test_keep(self):
        self.assertEqual(self.check("purpose.keep", moves=["baseRate", "sampling"]), [])
        items = [{"ask": {"en": "Per what?"}, "line": {"en": "Totals grow with people"}}]
        self.assertEqual(self.check("purpose.keep", items=items, heading={"en": "One question"}), [])
        self.assertIn("ask is missing", self.check("purpose.keep", items=[{"line": {"en": "x"}}])[0])
        self.assertIn("names a move twice", self.check("purpose.keep", moves=["baseRate", "baseRate"])[0])
        self.assertIn("is not a move", self.check("purpose.keep", moves=["luck"])[0])
        self.assertIn("5 questions at most", self.check("purpose.keep", moves=list(purpose.MOVES[:6]))[0])
        self.assertIn("are both given", self.check("purpose.keep", items=items, moves=["baseRate"])[0])

    def test_life_question(self):
        self.assertEqual(self.check("purpose.life-question", topic="time", size="wide"), [])
        self.assertEqual(self.check("purpose.life-question", topic="money", question={"en": "Mine?"}), [])
        self.assertIn("left out", self.check("purpose.life-question", topic="love")[0])
        self.assertIn("wants a source", self.check("purpose.life-question", question={"en": "Mine?"})[0])
        self.assertEqual(self.check("purpose.life-question", question={"en": "Mine?"}, source={}), [])

    def test_life_topics(self):
        self.assertEqual(self.check("purpose.life-topics", topics=["money", "body"]), [])
        self.assertIn("twice", self.check("purpose.life-topics", topics=["money", "money"])[0])
        self.assertIn("is not one of", self.check("purpose.life-topics", topics=["love"])[0])

    def test_set(self):
        self.assertEqual(self.check("purpose.set", theme="place-2", limit=12), [])
        self.assertEqual(self.check("purpose.set", source={}, title={"en": "Rome"}), [])
        self.assertIn("needs a title", self.check("purpose.set", source={})[0])
        self.assertIn("not both", self.check("purpose.set", theme="myths", source={})[0])

    def test_stamps(self):
        card = a_card_id()
        self.assertEqual(self.check("purpose.stamps", theme="place-2", labels={card: "HU"}), [])
        self.assertIn("longer than a stamp holds", self.check("purpose.stamps", labels={card: "HUNG"})[0])
        self.assertIn("not a card in the bank", self.check("purpose.stamps", labels={"no-such-card": "HU"})[0])

    def test_sets(self):
        good = [{"id": "a", "theme": "myths"}, {"id": "b", "source": {}, "title": {"en": "Rome"}}]
        self.assertEqual(self.check("purpose.sets", sets=good), [])
        self.assertIn("neither a theme nor a source", self.check("purpose.sets", sets=[{"id": "a"}])[0])
        self.assertIn("needs a title", self.check("purpose.sets", sets=[{"id": "a", "source": {}}])[0])
        self.assertIn("called 'myths'", self.check("purpose.sets", sets=[{"theme": "myths"}, {"theme": "myths"}])[0])
        self.assertIn("has no id", self.check("purpose.sets", sets=[{"source": {}, "title": "Rome"}])[0])

    def test_tomorrow(self):
        self.assertEqual(self.check("purpose.tomorrow", shelves=[{"title": {"en": "True stories"}}]), [])
        self.assertIn("title is missing", self.check("purpose.tomorrow", shelves=[{"subtitle": {"en": "x"}}])[0])
        self.assertIn("reads no field 'theme'", self.check("purpose.tomorrow", shelves=[{"title": "x", "theme": "myths"}])[0])


if __name__ == "__main__":
    unittest.main()
