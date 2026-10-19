"""Checks for the shapes blocks of Explore: Shelf shapes and signatures: one shape for every kind of card, and one confident graphic per kind of shelf (docs/explore, rounds 131 and 132).

What each block reads is in shapes.json beside this file, which the app's
own test holds to the blocks as they are drawn (test/explore/
shapes_words_test.dart), so a section this passes is one the app can draw
as written, and a field it does not know is a typo rather than a wish.
"""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Callable

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
WORDS = json.loads((HERE / "shapes.json").read_text(encoding="utf-8"))

# What every section says, read by Explore itself rather than by its block:
# its source and audience are checked by the explore part and the engine.
SECTION_FIELDS = {"id", "block", "source", "audience", "title", "subtitle"}

# What every shape reads, beside its own fields.
SHAPE_FIELDS = {"size", "limit", "min", "kind", "variant", "subject", "signature", "style"}

# Kinds that come in three forms, and the form's numbers.
VARIANT_KINDS = {"past": "0 the ancient world, 1 the 1600s to the 1800s, 2 the last century",
                 "place": "0 Asia and the Middle East, 1 the Americas, 2 Europe"}

ORDERS = ("given", "years")
CODE = re.compile(r"^[A-Z]{2,3}$")

_bank: set[str] | None = None


def bank_ids() -> set[str]:
    """Every card id in the bank, read once, for the codes a section names."""
    global _bank
    if _bank is None:
        _bank = set()
        for path in (ROOT / "tool" / "cards" / "bank").glob("*/*.json"):
            card = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(card.get("id"), str):
                _bank.add(card["id"])
    return _bank


def check_words(value, field: str) -> list[str]:
    """A title or a line: one string for every language, or one per language,
    English among them so a reader in any language gets one."""
    if isinstance(value, str):
        return [] if value.strip() else [f"{field} is empty: give it words or leave it out"]
    if not isinstance(value, dict):
        return [f"{field} is not a string or {{\"en\": ..., \"it\": ...}}"]
    problems = []
    languages = WORDS["languages"]
    for lang, text in value.items():
        if lang not in languages:
            problems.append(f"{field} has {lang!r}, which is not a language the app speaks: {', '.join(languages)}")
        elif not isinstance(text, str) or not text.strip():
            problems.append(f"{field}[{lang!r}] is empty: give it words or leave it out")
    if "en" not in value:
        problems.append(f"{field} has no English, which a reader in a language it does not name is shown")
    return problems


def check_style(style, spec: dict, name: str) -> list[str]:
    if not isinstance(style, dict):
        return ["style is not an object"]
    keys = spec["style"]
    problems = []
    for key, value in style.items():
        rule = keys.get(key)
        if rule is None:
            have = ", ".join(keys) or "none"
            problems.append(f"style key {key!r} is not one {name} reads (it reads: {have})")
        elif "flag" in rule and not isinstance(value, bool):
            problems.append(f"style {key!r} is true or false, not {value!r}")
        elif "oneOf" in rule and value not in rule["oneOf"]:
            problems.append(f"style {key!r} is one of {', '.join(rule['oneOf'])}, not {value!r}")
        elif "count" in rule:
            least, most = rule["count"]
            if isinstance(value, bool) or not isinstance(value, int) or not least <= value <= most:
                problems.append(f"style {key!r} is a whole number from {least} to {most}, not {value!r}")
    return problems


def check_codes(codes) -> list[str]:
    if not isinstance(codes, dict):
        return ['codes is not {"<card id>": "HU", ...}']
    problems = []
    ids = bank_ids()
    for card, code in codes.items():
        if card not in ids:
            problems.append(f"codes names {card!r}, which is not a card in the bank")
        if not isinstance(code, str) or not CODE.match(code):
            problems.append(f"codes gives {card!r} {code!r}: a country is two or three capital letters, HU, UK")
    return problems


def checker(name: str) -> Callable[[dict], list[str]]:
    """The check for one block, from what shapes.json says it reads."""
    spec = WORDS["blocks"][name]
    own = set(spec["fields"])
    known = SECTION_FIELDS | SHAPE_FIELDS | own

    def check(section: dict) -> list[str]:
        problems: list[str] = []
        for key in section:
            if key not in known:
                problems.append(f"field {key!r} is not one {name} reads")
        size = section.get("size")
        if "size" in section and size not in spec["sizes"]:
            problems.append(f"size {size!r} is not one {name} comes in: {', '.join(spec['sizes'])}")
        default_limit, most = spec["limit"]
        limit = section.get("limit", default_limit)
        if "limit" in section and (isinstance(limit, bool) or not isinstance(limit, int) or not 1 <= limit <= most):
            problems.append(f"limit is a whole number from 1 to {most}, not {limit!r}")
            limit = default_limit
        least = section.get("min")
        if "min" in section and (
            isinstance(least, bool) or not isinstance(least, int) or not 1 <= least <= min(limit, most)
        ):
            problems.append(f"min is a whole number from 1 to the limit ({limit}), not {least!r}")
        kind = section.get("kind", spec["kind"])
        if "kind" in section and kind not in WORDS["kinds"]:
            problems.append(f"kind {kind!r} is not one a shape keeps to: {', '.join(WORDS['kinds'])}")
        if "variant" in section:
            variant = section["variant"]
            if kind not in VARIANT_KINDS:
                problems.append(f"variant means something only for the past and a place, not for {kind!r}")
            elif isinstance(variant, bool) or variant not in (0, 1, 2):
                problems.append(f"variant is 0, 1 or 2 ({VARIANT_KINDS[kind]}), not {variant!r}")
        if "subject" in section:
            if kind != "month":
                problems.append(f"subject means something only for a month, not for {kind!r}")
            elif section["subject"] not in WORDS["subjects"]:
                problems.append(f"subject {section['subject']!r} is not one a month can be: {', '.join(WORDS['subjects'])}")
        if "signature" in section and section["signature"] not in spec["signatures"]:
            problems.append(f"signature {section['signature']!r} is not one {name} carries: {', '.join(spec['signatures'])}")
        if "style" in section:
            problems += check_style(section["style"], spec, name)
        if "codes" in own and "codes" in section:
            problems += check_codes(section["codes"])
        if "order" in own and "order" in section and section["order"] not in ORDERS:
            problems.append(f"order is {' or '.join(ORDERS)}, not {section['order']!r}")
        for field in ("title", "subtitle"):
            if field in section:
                problems += check_words(section[field], field)
        if kind == "any" and "title" not in section:
            problems.append("a shelf of any kind of card has no name of its own: give it a title")
        return problems

    return check


# block name -> check(section) returning a list of problems, each a line a
# person can act on. A block listed here is a block the app can draw.
BLOCKS: dict[str, Callable[[dict], list[str]]] = {name: checker(name) for name in WORDS["blocks"]}
