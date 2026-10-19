"""Checks for the purpose blocks of Explore: Shelves built on what Astute is for, and the bottom of Explore (docs/explore, rounds 133 and 138).

Each block's fields are in docs/explore/purpose.md, and the app reads them
in lib/explore/blocks/purpose/. A check says what this build would pass
over or misread, field by field, so a section reaches a phone the way it
was meant: a size the block has, a theme or a move the app knows, words in
English at least, card ids that are in the bank.
"""
from __future__ import annotations

import datetime
import json
from functools import lru_cache
from pathlib import Path
from typing import Callable, Iterable

ROOT = Path(__file__).resolve().parents[4]
BANK = ROOT / "tool" / "cards" / "bank"

# The languages the app is written in (lib/l10n/): a field in words is
# {"en": "…", "it": "…"}, English required, or one string for all.
LANGUAGES = frozenset({"en", "de", "es", "fr", "it", "ja", "ko", "nl", "pl", "pt", "ru", "tr", "zh"})

# What any section may say, whatever its block: the engine's fields, and
# `fit`, which every block of this family reads.
COMMON = frozenset({"id", "block", "title", "subtitle", "source", "size", "style", "limit", "audience", "fit"})

# The most cards a block of the family lays out (kPurposeMost).
MOST = 24

# The themes the app turns (ShelfTheme, lib/data/themed_shelves.dart); the
# two with forms take one: `past-1`, `place-2`.
THEMES = (
    "myths", "past", "numbers", "debates", "place", "practical", "paradoxes",
    "stories", "seen", "workItOut", "origins", "sharpest", "trueOrFalse",
    "reasoning", "ideas", "curious", "moving", "howItWorks", "puzzles",
)
FORMS = frozenset({"past", "place"})

# The moves (Principle in lib/models/pill.dart), every one but none.
MOVES = (
    "baseRate", "survivorship", "regression", "confirmation", "anchoring",
    "sampling", "confounding", "counterfactual", "multipleComparisons",
    "availability", "sunkCost", "conjunction", "conditional", "independence",
    "coincidence", "exponential", "reflection", "simpson", "estimation",
    "computation",
)

# The subjects, by key (kTopics in lib/data/topics.dart).
SUBJECTS = frozenset({
    "space", "technology", "language", "nature", "economics", "pop_culture",
    "science", "maths", "history", "psychology", "weird_facts", "human_body",
    "thinking", "philosophy", "sport", "cinema", "music", "art", "medicine",
    "food", "life",
})

# The parts of life a question can be about (kLifeTopics, life.dart).
LIFE = ("money", "work", "time", "body", "relationships", "belief")

# What a commit shelf asks (CommitKind, commit.dart).
KINDS = ("true-false", "side", "pick", "any")

SML = ("s", "m", "l")

# Each block's sizes, as lib/explore/blocks/purpose/ draws them; () for a
# block that has one size only.
SIZES: dict[str, tuple[str, ...]] = {
    "purpose.read-or-do": SML,
    "purpose.commit-note": (),
    "purpose.commit": SML,
    "purpose.move": SML,
    "purpose.step-above": SML,
    "purpose.thin-subject": SML,
    "purpose.other-side": SML,
    "purpose.in-your-head": SML,
    "purpose.seen": SML,
    "purpose.mechanism": SML,
    "purpose.curious": SML,
    "purpose.moving": SML,
    "purpose.why": SML,
    "purpose.thats-me": SML,
    "purpose.about-you": SML,
    "purpose.headline": SML,
    "purpose.out-of-what": SML,
    "purpose.price-tag": SML,
    "purpose.argument": SML,
    "purpose.keep": (),
    "purpose.life-question": ("s", "m", "wide", "l"),
    "purpose.life-topics": SML,
    "purpose.spot-trick": SML,
    "purpose.played": (),
    "purpose.set": SML,
    "purpose.stamps": SML,
    "purpose.sets": (),
    "purpose.tomorrow": (),
    "purpose.end": (),
}

# A stamp's word fits the stamp at three letters.
STAMP_LETTERS = 3

# The most questions a box of what to keep holds (KeepBlock.most).
KEEP_MOST = 5


@lru_cache(maxsize=1)
def bank_ids() -> frozenset[str]:
    """Every card id in the bank."""
    ids = set()
    for path in BANK.glob("*/*.json"):
        try:
            card = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if isinstance(card, dict) and isinstance(card.get("id"), str):
            ids.add(card["id"])
    return frozenset(ids)


# ── Pieces every block checks ─────────────────────────────────────────────


def words(value, field: str, required: bool = False) -> list[str]:
    """A field in words: one string for every language, or an object of
    strings by language with English among them."""
    if value is None:
        return [f"{field} is missing"] if required else []
    if isinstance(value, str):
        return [] if value.strip() else [f"{field} is empty"]
    if not isinstance(value, dict):
        return [f"{field} is neither words nor words by language"]
    problems = []
    if "en" not in value:
        problems.append(f"{field} has no English (\"en\"), which every language falls back to")
    for lang, text in value.items():
        if lang not in LANGUAGES:
            problems.append(f"{field}: {lang!r} is not a language the app is written in")
        elif not isinstance(text, str) or not text.strip():
            problems.append(f"{field}.{lang} is not words")
    return problems


def theme(value, field: str = "theme") -> list[str]:
    """A theme the app turns, by name, with its form where it has forms."""
    if not isinstance(value, str) or not value:
        return [f"{field} is not a theme's name"]
    name, _, form = value.partition("-")
    if name not in THEMES:
        return [f"{field} {value!r} is not a theme; the app knows {', '.join(THEMES)}"]
    if not form:
        return []
    if not form.isdigit() or int(form) > (2 if name in FORMS else 0):
        allowed = f"{name}-0, {name}-1 or {name}-2" if name in FORMS else f"{name} (it has one form)"
        return [f"{field} {value!r} has no such form: use {allowed}"]
    return []


def move(value, field: str = "move") -> list[str]:
    if value not in MOVES:
        return [f"{field} {value!r} is not a move; the app knows {', '.join(MOVES)}"]
    return []


def card_id(value, field: str) -> list[str]:
    if not isinstance(value, str) or value not in bank_ids():
        return [f"{field}: {value!r} is not a card in the bank"]
    return []


def objects(value, field: str) -> tuple[list[dict], list[str]]:
    """A list of objects, and a problem for anything else in it."""
    if value is None:
        return [], []
    if not isinstance(value, list):
        return [], [f"{field} is not a list"]
    problems = [f"{field}[{i}] is not an object" for i, v in enumerate(value) if not isinstance(v, dict)]
    return [v for v in value if isinstance(v, dict)], problems


def section_basics(section: dict, own: Iterable[str] = (), style: dict | None = None) -> list[str]:
    """What every section of the family is checked for: its fields, its
    words, its size, its limit, `fit` and its style."""
    block = section.get("block")
    problems: list[str] = []
    known = COMMON | set(own)
    for key in section:
        if key not in known:
            problems.append(f"the block reads no field {key!r}")
    problems += words(section.get("title"), "title")
    problems += words(section.get("subtitle"), "subtitle")
    sizes = SIZES.get(block, ())
    if "size" in section:
        size = section["size"]
        if not sizes:
            problems.append("the block has one size only: leave size out")
        elif size not in sizes:
            problems.append(f"size {size!r} is not one of the block's: {', '.join(sizes)}")
    if "limit" in section:
        limit = section["limit"]
        if not isinstance(limit, int) or isinstance(limit, bool) or not 1 <= limit <= MOST:
            problems.append(f"limit {limit!r} is not a whole number from 1 to {MOST}")
    if "fit" in section and not isinstance(section["fit"], bool):
        problems.append("fit is not true or false")
    if "style" in section:
        given = section["style"]
        if not isinstance(given, dict):
            problems.append("style is not an object")
        else:
            reads = style or {}
            for key, value in given.items():
                if key not in reads:
                    problems.append(f"the block reads no style {key!r}")
                else:
                    problems += reads[key](value, f"style.{key}")
    return problems


def boolean(value, field: str) -> list[str]:
    return [] if isinstance(value, bool) else [f"{field} is not true or false"]


def whole(low: int, high: int) -> Callable[[object, str], list[str]]:
    def check(value, field: str) -> list[str]:
        if not isinstance(value, int) or isinstance(value, bool) or not low <= value <= high:
            return [f"{field} {value!r} is not a whole number from {low} to {high}"]
        return []

    return check


def plain(section: dict) -> list[str]:
    """A block that reads nothing beyond what every section says."""
    return section_basics(section)


def with_words(*fields: str) -> Callable[[dict], list[str]]:
    """A block that reads, besides, words of its own."""

    def check(section: dict) -> list[str]:
        problems = section_basics(section, own=fields)
        for field in fields:
            problems += words(section.get(field), field)
        return problems

    return check


# ── 133 ───────────────────────────────────────────────────────────────────


def read_or_do(section: dict) -> list[str]:
    problems = section_basics(
        section,
        own=("shelves",),
        style={"filter": boolean, "count": boolean, "shelves": whole(1, 7)},
    )
    shelves, bad = objects(section.get("shelves"), "shelves")
    problems += bad
    ids = set()
    for i, shelf in enumerate(shelves):
        where = f"shelves[{i}]"
        for key in shelf:
            if key not in ("id", "theme", "title", "subtitle", "source", "limit", "fit"):
                problems.append(f"{where}: a shelf reads no field {key!r}")
        if "theme" in shelf:
            problems += [f"{where}: {p}" for p in theme(shelf["theme"])]
        elif "title" not in shelf:
            problems.append(f"{where}: has neither a theme nor a title, so it has no name and is passed over")
        problems += [f"{where}: {p}" for p in words(shelf.get("title"), "title")]
        problems += [f"{where}: {p}" for p in words(shelf.get("subtitle"), "subtitle")]
        own = shelf.get("id", shelf.get("theme"))
        if own in ids:
            problems.append(f"{where}: two shelves are called {own!r}; their cards would be noted together")
        ids.add(own)
    if "shelves" in section and "shelves" in (section.get("style") or {}):
        problems.append("style.shelves counts the day's themes, and the section names its own shelves")
    return problems


def commit(section: dict) -> list[str]:
    problems = section_basics(section, own=("kind",))
    if "kind" in section and section["kind"] not in KINDS:
        problems.append(f"kind {section['kind']!r} is not one of {', '.join(KINDS)}")
    return problems


def move_box(section: dict) -> list[str]:
    problems = section_basics(section, own=("move", "name", "line"))
    if "move" in section:
        problems += move(section["move"])
    problems += words(section.get("name"), "name")
    problems += words(section.get("line"), "line")
    if ("name" in section or "line" in section) and "move" not in section:
        problems.append("name and line say a move, and the section names none: the day's move would get them")
    return problems


def thin_subject(section: dict) -> list[str]:
    problems = section_basics(section, own=("subject",))
    if "subject" in section and section["subject"] not in SUBJECTS:
        problems.append(f"subject {section['subject']!r} is not a subject's key, like human_body")
    return problems


def moving(section: dict) -> list[str]:
    problems = section_basics(section, own=("updated",))
    updated = section.get("updated")
    if updated is None:
        return problems
    if not isinstance(updated, dict):
        return problems + ["updated is not an object of card ids and dates"]
    for card, day in updated.items():
        problems += card_id(card, "updated")
        try:
            datetime.date.fromisoformat(day if isinstance(day, str) else "")
        except ValueError:
            problems.append(f"updated[{card!r}]: {day!r} is not a date like 2026-10-04")
    return problems


# ── 138 ───────────────────────────────────────────────────────────────────


def keep(section: dict) -> list[str]:
    problems = section_basics(section, own=("moves", "items", "heading"))
    problems += words(section.get("heading"), "heading")
    items, bad = objects(section.get("items"), "items")
    problems += bad
    for i, item in enumerate(items):
        for key in item:
            if key not in ("ask", "line"):
                problems.append(f"items[{i}]: a question reads no field {key!r}")
        problems += [f"items[{i}]: {p}" for p in words(item.get("ask"), "ask", required=True)]
        problems += [f"items[{i}]: {p}" for p in words(item.get("line"), "line")]
    moves = section.get("moves")
    if moves is not None:
        if not isinstance(moves, list) or not moves:
            problems.append("moves is not a list of moves")
        else:
            for i, m in enumerate(moves):
                problems += move(m, f"moves[{i}]")
            if len(set(map(str, moves))) != len(moves):
                problems.append("moves names a move twice")
    if items and moves is not None:
        problems.append("items and moves are both given: the items are shown and the moves passed over")
    count = len(items) if items else len(moves) if isinstance(moves, list) else 3
    if count > KEEP_MOST:
        problems.append(f"a box holds {KEEP_MOST} questions at most; the rest are passed over")
    return problems


def life_question(section: dict) -> list[str]:
    problems = section_basics(section, own=("topic", "about", "question"))
    problems += words(section.get("about"), "about")
    problems += words(section.get("question"), "question")
    if "topic" in section and section["topic"] not in LIFE:
        problems.append(
            f"topic {section['topic']!r} is not one of {', '.join(LIFE)}"
            + ("" if "question" in section else ", and with no question of its own the section is left out")
        )
    if "question" in section and "topic" not in section and "source" not in section:
        problems.append("a question of the section's own wants a source of cards that ask it, or a topic")
    return problems


def life_topics(section: dict) -> list[str]:
    problems = section_basics(section, own=("topics", "question", "footer"))
    problems += words(section.get("question"), "question")
    problems += words(section.get("footer"), "footer")
    topics = section.get("topics")
    if topics is not None:
        if not isinstance(topics, list) or not topics:
            problems.append("topics is not a list of parts of life")
        else:
            for i, t in enumerate(topics):
                if t not in LIFE:
                    problems.append(f"topics[{i}] {t!r} is not one of {', '.join(LIFE)}")
            if len(set(map(str, topics))) != len(topics):
                problems.append("topics names a part of life twice")
    return problems


def a_set(section: dict, own: Iterable[str] = ()) -> list[str]:
    """A set: a theme, or a source with a title to call it by."""
    problems = section_basics(section, own=("theme", *own))
    if "theme" in section:
        problems += theme(section["theme"])
        if "source" in section:
            problems.append("a set is a theme's cards or a source's, not both: the theme wins")
    elif "source" in section and "title" not in section:
        problems.append("a set from a source needs a title to call it by; without one it is left out")
    return problems


def stamps(section: dict) -> list[str]:
    problems = a_set(section, own=("labels", "footer"))
    problems += words(section.get("footer"), "footer")
    labels = section.get("labels")
    if labels is None:
        return problems
    if not isinstance(labels, dict):
        return problems + ["labels is not an object of card ids and words"]
    for card, label in labels.items():
        problems += card_id(card, "labels")
        if not isinstance(label, str) or not label.strip():
            problems.append(f"labels[{card!r}] is not words")
        elif len(label.strip()) > STAMP_LETTERS:
            problems.append(f"labels[{card!r}] {label!r} is longer than a stamp holds ({STAMP_LETTERS} letters)")
    return problems


def sets(section: dict) -> list[str]:
    problems = section_basics(section, own=("sets",))
    parts, bad = objects(section.get("sets"), "sets")
    problems += bad
    ids = set()
    for i, part in enumerate(parts):
        where = f"sets[{i}]"
        for key in part:
            if key not in ("id", "theme", "source", "title", "subtitle", "limit"):
                problems.append(f"{where}: a set reads no field {key!r}")
        problems += [f"{where}: {p}" for p in words(part.get("title"), "title")]
        if "theme" in part:
            problems += [f"{where}: {p}" for p in theme(part["theme"])]
        elif "source" not in part:
            problems.append(f"{where}: is neither a theme nor a source")
        elif "title" not in part:
            problems.append(f"{where}: a set from a source needs a title to call it by")
        if "limit" in part:
            problems += [f"{where}: {p}" for p in whole(1, MOST)(part["limit"], "limit")]
        own = part.get("id", part.get("theme"))
        if own is None:
            problems.append(f"{where}: has no id, so the cards opened from it cannot be told from another set's")
        elif own in ids:
            problems.append(f"{where}: two sets are called {own!r}")
        ids.add(own)
    return problems


def tomorrow(section: dict) -> list[str]:
    problems = section_basics(section, own=("shelves",))
    shelves, bad = objects(section.get("shelves"), "shelves")
    problems += bad
    for i, shelf in enumerate(shelves):
        for key in shelf:
            if key not in ("title", "subtitle"):
                problems.append(f"shelves[{i}]: a shelf of tomorrow's reads no field {key!r}")
        problems += [f"shelves[{i}]: {p}" for p in words(shelf.get("title"), "title", required=True)]
        problems += [f"shelves[{i}]: {p}" for p in words(shelf.get("subtitle"), "subtitle")]
    return problems


# block name -> check(section) returning a list of problems, each a line a
# person can act on. A block listed here is a block the app can draw.
BLOCKS: dict[str, Callable[[dict], list[str]]] = {
    "purpose.read-or-do": read_or_do,
    "purpose.commit-note": with_words("text"),
    "purpose.commit": commit,
    "purpose.move": move_box,
    "purpose.step-above": plain,
    "purpose.thin-subject": thin_subject,
    "purpose.other-side": plain,
    "purpose.in-your-head": plain,
    "purpose.seen": plain,
    "purpose.mechanism": plain,
    "purpose.curious": plain,
    "purpose.moving": moving,
    "purpose.why": plain,
    "purpose.thats-me": with_words("footer"),
    "purpose.about-you": plain,
    "purpose.headline": plain,
    "purpose.out-of-what": plain,
    "purpose.price-tag": plain,
    "purpose.argument": plain,
    "purpose.keep": keep,
    "purpose.life-question": life_question,
    "purpose.life-topics": life_topics,
    "purpose.spot-trick": plain,
    "purpose.played": with_words("footer"),
    "purpose.set": a_set,
    "purpose.stamps": stamps,
    "purpose.sets": sets,
    "purpose.tomorrow": tomorrow,
    "purpose.end": with_words("line", "subline"),
}
