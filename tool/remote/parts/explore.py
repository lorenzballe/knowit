"""The shelves of Explore: which, in what order, at what size, for whom and
when (remote/explore.json). Null keeps the build's own Explore.

The document is {"sections": [...]}. Every section has an id and a block;
the block must be one the app can draw, which is one some family in
explore_blocks/ lists, and that family's own check reads the rest of it.

What every section may say whatever its block is checked here, so a family
only checks its own fields: the words (`title`, `subtitle`: one string, or
one per language with English among them), `limit`, `gap`, `size`, `style`,
the `audience`, and where its cards come from (`source`), against the bank
in tool/cards/bank/.
"""
from __future__ import annotations

import ast
import importlib
import json
import pkgutil
from functools import lru_cache
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent
BANK = ROOT / "tool" / "cards" / "bank"

AUDIENCE_KEYS = {
    "platforms", "minBuild", "maxBuild", "languages", "plus", "minDays", "maxDays",
    "from", "until", "weekdays", "hours", "rollout", "salt", "all", "any", "not",
}

# The languages the app is shown in (lib/l10n/).
LANGUAGES = {"en", "it", "de", "es", "fr", "ja", "ko", "nl", "pl", "pt", "ru", "tr", "zh"}

# What every section may say, whatever its block (lib/explore/explore_block.dart,
# and `gap`, read by the engine). A key starting with "_" is a note for whoever
# reads the document, and the app passes over it.
COMMON = {"id", "block", "title", "subtitle", "source", "size", "style", "limit", "audience", "gap"}

# Where a section's cards can come from (ExploreHost.cardsFor).
SHELVES = {"today", "asking", "topWeek", "topMonth", "loved", "mine", "forYou", "local"}
MINE = {"saved", "liked", "due"}
QUERY_KEYS = {"subjects", "formats", "difficulty", "unread", "perSubject", "limit", "seed"}
SEEDS = {"day", "week", "fixed"}
DIFFICULTY = {"easy", "medium", "hard"}
KINDS = {"read", "pickOne", "number", "estimate", "debate", "trueOrFalse", "diagram"}

# The most cards a section may ask for: past this a shelf is a list nobody
# reaches the end of, and the phone deals more than it shows.
MOST_CARDS = 60


def blocks() -> dict:
    out = {}
    for info in pkgutil.iter_modules([str(HERE / "explore_blocks")]):
        module = importlib.import_module(f"parts.explore_blocks.{info.name}")
        for name, fn in getattr(module, "BLOCKS", {}).items():
            out[name] = fn
    return out


@lru_cache(maxsize=1)
def bank() -> dict:
    """Every card in tool/cards/bank/, by id: its subject, kind, scene, and
    whether it is retired or about a place."""
    out = {}
    for path in sorted(BANK.glob("*/*.json")):
        card = json.loads(path.read_text(encoding="utf-8"))
        scene = card.get("scene")
        options = [str(o).lower() for o in card.get("options") or []]
        kinds = {card.get("kind")}
        if isinstance(scene, dict):
            kinds.add(scene.get("type"))
        if card.get("kind") == "pickOne" and len(options) == 2 and set(options) == {"true", "false"}:
            kinds.add("trueOrFalse")
        if card.get("diagram"):
            kinds.add("diagram")
        out[card["id"]] = {
            "topic": card.get("topic"),
            "difficulty": card.get("difficulty"),
            "formats": kinds,
            "disabled": bool(card.get("disabled")),
            "place": bool(card.get("place")),
            "question": card.get("question", ""),
        }
    return out


@lru_cache(maxsize=1)
def subjects() -> set[str]:
    """The subjects of the bank, by key: its folders."""
    return {p.name for p in BANK.iterdir() if p.is_dir()}


@lru_cache(maxsize=1)
def scene_kinds() -> set[str]:
    """The kinds of scene a card can carry, as tool/cards/scenes.py lists them."""
    tree = ast.parse((ROOT / "tool" / "cards" / "scenes.py").read_text(encoding="utf-8"))
    for node in tree.body:
        if isinstance(node, ast.Assign) and any(getattr(t, "id", None) == "KINDS" for t in node.targets):
            return set(ast.literal_eval(node.value))
    return set()


def formats() -> set[str]:
    """What `formats` in a query may name (isFormat in lib/explore/blocks/core/shelves.dart)."""
    return KINDS | scene_kinds()


def check_words(value, where: str, field: str, required: bool = False) -> list[str]:
    """Words a section gives: one non-empty string for every language, or one
    per language, with English, which every other language falls back on."""
    if value is None:
        return [f"{where}: needs `{field}`"] if required else []
    if isinstance(value, str):
        return [] if value.strip() else [f"{where}: `{field}` is empty"]
    if not isinstance(value, dict):
        return [f"{where}: `{field}` is neither a string nor one per language"]
    problems = []
    if "en" not in value:
        problems.append(f"{where}: `{field}` has no English, which every other language falls back on")
    for lang, text in value.items():
        if lang not in LANGUAGES:
            problems.append(f"{where}: `{field}` has {lang!r}, which is not a language of the app ({', '.join(sorted(LANGUAGES))})")
        elif not isinstance(text, str) or not text.strip():
            problems.append(f"{where}: `{field}` in {lang!r} is empty")
    return problems


def check_source(source, where: str) -> list[str]:
    """Where a section's cards come from, and that it resolves: a shelf of
    the server's Explore, cards by id that are in the bank and dealt, a
    query of the bank, or the reader's own."""
    if not isinstance(source, dict):
        return [f"{where}: `source` is not an object"]
    keys = [k for k in ("shelf", "ids", "query", "mine") if k in source]
    if len(keys) != 1 or len(source) != 1:
        return [f"{where}: `source` names one of shelf, ids, query or mine, and nothing else"]
    kind = keys[0]
    value = source[kind]
    if kind == "shelf":
        if value not in SHELVES:
            return [f"{where}: shelf {value!r} is not one of the server's Explore ({', '.join(sorted(SHELVES))})"]
        return []
    if kind == "mine":
        if value not in MINE:
            return [f"{where}: mine {value!r} is not one of {', '.join(sorted(MINE))}"]
        return []
    if kind == "ids":
        if not isinstance(value, list) or not value:
            return [f"{where}: ids is not a list of card ids"]
        problems = []
        cards = bank()
        seen = set()
        for cid in value:
            if not isinstance(cid, str):
                problems.append(f"{where}: ids has {cid!r}, which is not a card id")
                continue
            if cid in seen:
                problems.append(f"{where}: card {cid} is named twice")
            seen.add(cid)
            card = cards.get(cid)
            if card is None:
                problems.append(f"{where}: card {cid} is not in tool/cards/bank/")
            elif card["disabled"]:
                problems.append(f"{where}: card {cid} is retired, and no phone deals it")
            elif card["place"]:
                problems.append(f"{where}: card {cid} is about a place: only the shelf of where the reader lives shows one")
        return problems
    # A query of the bank.
    if not isinstance(value, dict):
        return [f"{where}: query is not an object"]
    problems = [f"{where}: query key {k!r} is not one the app reads ({', '.join(sorted(QUERY_KEYS))})" for k in value if k not in QUERY_KEYS]

    def names(key, known, label):
        raw = value.get(key)
        if raw is None:
            return []
        if not isinstance(raw, list) or not raw or not all(isinstance(x, str) for x in raw):
            return [f"{where}: query `{key}` is not a list of names"]
        return [f"{where}: query `{key}` has {x!r}, which is not {label}" for x in raw if x not in known]

    problems += names("subjects", subjects(), "a subject of the bank")
    problems += names("formats", formats(), "a kind of card or of scene")
    problems += names("difficulty", DIFFICULTY, "easy, medium or hard")
    if "unread" in value and not isinstance(value["unread"], bool):
        problems.append(f"{where}: query `unread` is true or false")
    for key in ("limit", "perSubject"):
        n = value.get(key)
        if n is not None and (not isinstance(n, int) or isinstance(n, bool) or not 1 <= n <= MOST_CARDS):
            problems.append(f"{where}: query `{key}` is a whole number from 1 to {MOST_CARDS}")
    if "seed" in value and value["seed"] not in SEEDS:
        problems.append(f"{where}: query `seed` is day, week or fixed")
    if not problems and not query_cards(value):
        problems.append(f"{where}: the query finds no card in the bank")
    return problems


def query_cards(query: dict) -> list[str]:
    """The ids a query can find in the bank, read or not."""
    subj = set(query.get("subjects") or []) or None
    fmts = set(query.get("formats") or []) or None
    diff = set(query.get("difficulty") or []) or None
    return [
        cid
        for cid, card in bank().items()
        if not card["disabled"]
        and not card["place"]
        and (subj is None or card["topic"] in subj)
        and (fmts is None or card["formats"] & fmts)
        and (diff is None or card.get("difficulty") in diff)
    ]


def check_common(section: dict, where: str) -> list[str]:
    """The fields every section may have, whatever its block."""
    problems = check_audience(section.get("audience"), where)
    problems += check_words(section.get("title"), where, "title")
    problems += check_words(section.get("subtitle"), where, "subtitle")
    if "source" in section:
        problems += check_source(section["source"], where)
    if "limit" in section:
        n = section["limit"]
        if not isinstance(n, int) or isinstance(n, bool) or not 1 <= n <= MOST_CARDS:
            problems.append(f"{where}: `limit` is a whole number from 1 to {MOST_CARDS}")
    if "gap" in section:
        g = section["gap"]
        if not isinstance(g, (int, float)) or isinstance(g, bool) or not 0 <= g <= 120:
            problems.append(f"{where}: `gap` is the room above the section, 0 to 120 points")
    if "size" in section and not isinstance(section["size"], str):
        problems.append(f"{where}: `size` is a name, like m or xl")
    if "style" in section and not isinstance(section["style"], dict):
        problems.append(f"{where}: `style` is an object")
    return problems


def check_audience(rule, where: str) -> list[str]:
    if rule is None:
        return []
    if not isinstance(rule, dict):
        return [f"{where}: audience is not an object"]
    problems = [f"{where}: audience key {k!r} is not one the app knows" for k in rule if k not in AUDIENCE_KEYS]
    for key in ("all", "any"):
        for i, sub in enumerate(rule.get(key) or []):
            problems += check_audience(sub, f"{where}.{key}[{i}]")
    if "not" in rule:
        problems += check_audience(rule["not"], f"{where}.not")
    return problems


def check(doc) -> list[str]:
    """The problems with this part, each a line a person can act on."""
    if doc is None:
        return []
    if not isinstance(doc, dict) or not isinstance(doc.get("sections"), list):
        return ['is not {"sections": [...]}']
    known = blocks()
    problems: list[str] = []
    seen: set[str] = set()
    for i, section in enumerate(doc["sections"]):
        where = f"sections[{i}]"
        if not isinstance(section, dict):
            problems.append(f"{where}: is not an object")
            continue
        sid, block = section.get("id"), section.get("block")
        if not isinstance(sid, str) or not sid:
            problems.append(f"{where}: has no id")
            continue
        where = f"section {sid!r}"
        if sid in seen:
            problems.append(f"{where}: the id is used twice")
        seen.add(sid)
        if block not in known:
            problems.append(f"{where}: block {block!r} is not one the app can draw")
            continue
        problems += check_common(section, where)
        problems += [f"{where}: {p}" for p in known[block](section)]
    return problems
