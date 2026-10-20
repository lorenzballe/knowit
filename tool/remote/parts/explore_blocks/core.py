"""Checks for the core blocks of Explore: The engine's own blocks: every shelf the app had before Explore came from the server, and the generic ones that show any cards at any size (carousels, grids, bento, hero, banner…), plus text, countdown, subjects, promo, spacer, divider and web.

The common fields of a section — its words, `limit`, `gap`, `audience` and
`source` — are checked in parts/explore.py for every block. This module
checks what each core block reads beyond them, and refuses a field it does
not read, so a misspelt one is caught here rather than passed over on every
phone. docs/explore/core.md is the catalogue.
"""
from __future__ import annotations

import datetime
import re
from typing import Callable

from parts import explore as common

# The narrowest phone the app is drawn for, which is where a tile is smallest.
PHONE = 375
ACROSS = PHONE - 40

# What every section may carry, whatever its block.
BASE = {"id", "block", "audience", "gap"}
WORDS = {"title", "subtitle"}


def _fields(section: dict, allowed: set[str]) -> list[str]:
    known = BASE | allowed
    return [
        f"`{k}` is not a field this block reads ({', '.join(sorted(known - BASE)) or 'none of its own'})"
        for k in section
        if k not in known and not k.startswith("_")
    ]


def _size(section: dict, sizes: tuple[str, ...]) -> list[str]:
    if "size" in section and section["size"] not in sizes:
        return [f"size {section['size']!r} is not one of {', '.join(sizes)}"]
    return []


def _needs_source(section: dict) -> list[str]:
    return [] if "source" in section else ["needs a `source` for its cards"]


def _words(section: dict, field: str, required: bool = False) -> list[str]:
    return [p.split(": ", 1)[1] for p in common.check_words(section.get(field), "x", field, required)]


def _choice(section: dict, field: str, choices: set, label: str) -> list[str]:
    if field in section and section[field] not in choices:
        return [f"`{field}` is {label}"]
    return []


def _number(section: dict, field: str, low: float, high: float, label: str, whole: bool = False) -> list[str]:
    if field not in section:
        return []
    v = section[field]
    ok = isinstance(v, (int, float)) and not isinstance(v, bool) and low <= v <= high
    if ok and whole:
        ok = isinstance(v, int)
    return [] if ok else [f"`{field}` is {label}"]


# ── Tiles: whether a box can hold a question ──────────────────────────────
#
# The app sets a question whole or not at all (lib/widgets/explore/card_tiles.dart):
# a box too small for a card's question takes the next card. A layout whose
# boxes are too small for most of the bank would come out nearly empty, so it
# is refused here. The box is worked out as TileLook.forBox works it out, and
# what it holds is reckoned from its area at the smallest size the tile sets
# a question in (a test in test/explore/ holds this reckoning to the real
# fonts).


def tile_look(width: float, height: float) -> dict:
    side = min(width, height)
    tiny = side < 100
    return {
        "padding": 7 if tiny else round(min(max(side * 0.085, 8), 24)),
        "icon": 11 if tiny else 12 if side < 110 else 14 if side < 170 else 15 if side < 260 else 18,
        "gap": 4 if tiny else round(min(max(side * 0.06, 5), 16)),
        "foot": height >= 200 and width >= 180,
        "min": 9.5 if side < 110 else 10 if side < 150 else 10.5 if side < 200 else 12 if side < 260 else 14,
    }


def question_box(width: float, height: float) -> tuple[float, float, float]:
    """The room a tile of [width] by [height] leaves its question, and the
    smallest size it sets one at."""
    look = tile_look(width, height)
    w = width - look["padding"] * 2
    h = height - look["padding"] * 2 - look["icon"] - look["gap"] * (2 if look["foot"] else 1) - (11 if look["foot"] else 0)
    return w, h, look["min"]


def holds(width: float, height: float) -> float:
    """About how many characters of a question a tile holds whole."""
    w, h, size = question_box(width, height)
    if w <= 0 or h <= 0:
        return 0
    return w * h / (0.638 * size * size)


def quarter_length() -> int:
    """A quarter of the bank's questions are this long or shorter."""
    lengths = sorted(len(c["question"]) for c in common.bank().values() if not c["disabled"] and not c["place"])
    return lengths[len(lengths) // 4] if lengths else 0


def _small(width: float, height: float, what: str, instead: str) -> list[str]:
    if holds(width, height) >= quarter_length():
        return []
    return [
        f"{what} is {width:.0f} by {height:.0f} points on a {PHONE}-wide phone, too small to set "
        f"a quarter of the bank's questions whole; {instead}"
    ]


GRID_SHAPES = {"square": 1.0, "portrait": 1.5, "landscape": 0.72}


def grid_tile(columns: int, shape: str) -> tuple[float, float]:
    gap = 10 if columns == 2 else 8
    width = (ACROSS - gap * (columns - 1)) / columns
    return width, width * GRID_SHAPES[shape]


BENTO_SPAN = re.compile(r"^([1-4])x([1-3])$")
BENTO_DEFAULTS = {
    2: ["2x1", "1x2", "1x1", "1x1"],
    3: ["2x2", "1x1", "1x1", "1x1", "2x1"],
    4: ["2x2", "2x1", "2x1", "4x1"],
}


def bento_box(columns: int, ratio: float, span: tuple[int, int]) -> tuple[float, float]:
    unit = (ACROSS - 8 * (columns - 1)) / columns
    c, r = span
    return unit * c + 8 * (c - 1), unit * ratio * r + 8 * (r - 1)


# ── The blocks ────────────────────────────────────────────────────────────


def shelf(*own: str, words: bool = True, source: bool = False) -> Callable[[dict], list[str]]:
    """A shelf Explore always had: its own name and line can be the
    section's, and it deals its own cards."""
    allowed = set(own) | (WORDS if words else set())

    def check(section: dict) -> list[str]:
        problems = _fields(section, allowed)
        if "source" in section and not source:
            problems.append("deals its own cards and reads no `source`: use a carousel, grid or list for cards of your choosing")
        return problems

    return check


def true_false(section: dict) -> list[str]:
    problems = shelf("spot")(section)
    if "spot" in section and not isinstance(section["spot"], bool):
        problems.append("`spot` is true or false: whether the game of spotting the false one sits under the row")
    return problems


def carousel(section: dict) -> list[str]:
    return (
        _fields(section, WORDS | {"source", "size", "limit"})
        + _needs_source(section)
        + _size(section, ("xs", "s", "m", "l", "xl"))
    )


def grid(section: dict) -> list[str]:
    problems = _fields(section, WORDS | {"source", "columns", "shape", "limit"}) + _needs_source(section)
    columns = section.get("columns", 2)
    shape = section.get("shape", "portrait")
    if columns not in (2, 3, 4) or isinstance(columns, bool):
        problems.append("`columns` is 2, 3 or 4")
        return problems
    if shape not in GRID_SHAPES:
        problems.append("`shape` is square, portrait or landscape")
        return problems
    width, height = grid_tile(columns, shape)
    problems += _small(width, height, f"a tile of {columns} {shape} columns", "use portrait tiles, or fewer columns")
    return problems


def bento(section: dict) -> list[str]:
    problems = _fields(section, WORDS | {"source", "columns", "items", "ratio"}) + _needs_source(section)
    columns = section.get("columns", 3)
    if columns not in (2, 3, 4) or isinstance(columns, bool):
        return problems + ["`columns` is 2, 3 or 4"]
    problems += _number(section, "ratio", 0.5, 2, "how tall a row is for its width, 0.5 to 2")
    ratio = section.get("ratio", 1)
    if not isinstance(ratio, (int, float)) or isinstance(ratio, bool) or not 0.5 <= ratio <= 2:
        return problems
    items = section.get("items", BENTO_DEFAULTS[columns])
    if not isinstance(items, list) or not 1 <= len(items) <= 12:
        return problems + ["`items` is a list of one to twelve spans, like \"2x1\""]
    for i, item in enumerate(items):
        m = BENTO_SPAN.match(item) if isinstance(item, str) else None
        if m is None:
            problems.append(f"items[{i}] is {item!r}: a span is \"CxR\", C columns of 1 to 4 and R rows of 1 to 3")
            continue
        span = (int(m.group(1)), int(m.group(2)))
        if span[0] > columns:
            problems.append(f"items[{i}] spans {span[0]} columns of a mosaic of {columns}")
            continue
        width, height = bento_box(columns, ratio, span)
        problems += _small(width, height, f"items[{i}] ({item})", "give it more columns or rows, or the mosaic a taller ratio")
    return problems


def sized(*sizes: str, limit: bool = True, needs: bool = True) -> Callable[[dict], list[str]]:
    def check(section: dict) -> list[str]:
        allowed = WORDS | {"source", "size"} | ({"limit"} if limit else set())
        return _fields(section, allowed) + (_needs_source(section) if needs else []) + _size(section, sizes)

    return check


def banner(section: dict) -> list[str]:
    problems = sized("s", "m", "l")(section)
    if "limit" in section and isinstance(section["limit"], int) and section["limit"] > 3:
        problems.append("`limit` is at most 3 strips")
    return problems


def single(section: dict) -> list[str]:
    return _fields(section, WORDS | {"source"}) + _needs_source(section)


def text(section: dict) -> list[str]:
    problems = _fields(section, WORDS | {"text", "kind", "by", "subject", "style"})
    problems += _words(section, "text", required=True)
    problems += _choice(section, "kind", {"headline", "paragraph", "quote"}, "headline, paragraph or quote")
    if "by" in section:
        problems += _words(section, "by")
        if section.get("kind") != "quote":
            problems.append("`by` says who said a quote, and the text is not one (`kind`: quote)")
    problems += _subject(section)
    style = section.get("style", {})
    if isinstance(style, dict):
        problems += [f"style key {k!r} is not one this block reads (align)" for k in style if k != "align"]
        if "align" in style and style["align"] not in ("start", "center"):
            problems.append("style `align` is start or center")
    return problems


def _subject(section: dict) -> list[str]:
    if "subject" in section and section["subject"] not in common.subjects():
        return [f"`subject` {section['subject']!r} is not a subject of the bank"]
    return []


def countdown(section: dict) -> list[str]:
    problems = _fields(section, WORDS | {"to", "label", "today", "after", "subject", "source", "size", "limit"})
    to = section.get("to")
    try:
        if not isinstance(to, str) or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", to):
            raise ValueError
        datetime.date.fromisoformat(to)
    except ValueError:
        problems.append("needs `to`, the day it counts to, like 2026-10-21")
    problems += _words(section, "label", required=True)
    problems += _words(section, "today") + _words(section, "after")
    problems += _subject(section)
    problems += _size(section, ("xs", "s", "m"))
    return problems


def subjects(section: dict) -> list[str]:
    problems = _fields(section, WORDS | {"subjects", "size"}) + _size(section, ("s", "m", "l"))
    offered = common.subjects() - {"thinking"}
    named = section.get("subjects")
    if named is not None:
        if not isinstance(named, list) or not named:
            problems.append("`subjects` is a list of subjects, by their keys")
        else:
            for key in named:
                if key not in offered:
                    problems.append(f"subjects has {key!r}, which is not a subject of the row at the top")
            if len(set(map(str, named))) != len(named):
                problems.append("subjects names one twice")
    return problems


def promo(section: dict) -> list[str]:
    problems = _fields(section, WORDS | {"kicker", "headline", "line", "button", "from", "plan"})
    for field in ("kicker", "headline", "line", "button"):
        problems += _words(section, field)
    problems += _choice(section, "plan", {"free", "all"}, "free (the default: not shown on Astute+) or all")
    if "from" in section and not (isinstance(section["from"], str) and re.fullmatch(r"[a-z][a-z0-9 -]{1,40}", section["from"])):
        problems.append("`from` names the door in the paywall's numbers, a few lower-case words")
    return problems


def spacer(section: dict) -> list[str]:
    return _fields(section, {"height"}) + _number(section, "height", 0, 240, "the room, 0 to 240 points")


def divider(section: dict) -> list[str]:
    return _fields(section, {"label"}) + _words(section, "label")


def web(section: dict) -> list[str]:
    problems = _fields(section, WORDS | {"html", "height"})
    problems += _words(section, "html", required=True)
    if "height" not in section:
        problems.append("needs `height`, how tall the page is shown, 40 to 1200 points")
    problems += _number(section, "height", 40, 1200, "how tall the page is shown, 40 to 1200 points")
    html = section.get("html")
    pages = html.values() if isinstance(html, dict) else [html] if isinstance(html, str) else []
    for page in pages:
        if isinstance(page, str) and len(page.encode("utf-8")) > 200_000:
            problems.append("a page is over 200 KB: the document reaches every phone, so keep a page to what it shows")
    return problems


# block name -> check(section) returning a list of problems, each a line a
# person can act on. A block listed here is a block the app can draw.
BLOCKS: dict[str, Callable[[dict], list[str]]] = {
    # The shelves Explore always had, and two lines that are not shelves.
    "nothing-here": shelf(words=False),
    "offline": shelf(words=False),
    "today": shelf("limit"),
    "top": shelf(),
    "loved": shelf(),
    "asking": shelf("limit"),
    "mine": shelf(),
    "where-you-live": shelf(),
    "month": shelf(),
    "numbers": shelf(),
    "debates": shelf(),
    "sharpest": shelf(),
    "origins": shelf(),
    "stories": shelf(),
    "true-false": true_false,
    "spot-false": shelf(words=False),
    "came-back": shelf(),
    "move-sampling": shelf(),
    "move-compared": shelf(),
    "work": shelf(),
    "unmask": shelf(),
    "how-sure": shelf(words=False),
    "what-if": shelf(),
    "series": shelf(),
    "sixty": shelf(),
    "mood": shelf(words=False),
    "did-you-know": shelf(words=False),
    "surprise": shelf(),
    "practical": shelf(),
    # Any cards, at any size.
    "carousel": carousel,
    "grid": grid,
    "bento": bento,
    "hero": sized("m", "l", "xl", limit=False),
    "banner": banner,
    "pair": sized("s", "m", "l", limit=False),
    "list": sized("s", "m", "l"),
    "stack": sized("s", "m", "l"),
    "ticker": sized("xs", "s", "m"),
    "single": single,
    # Not cards.
    "text": text,
    "countdown": countdown,
    "subjects": subjects,
    "promo": promo,
    "spacer": spacer,
    "divider": divider,
    "web": web,
}
