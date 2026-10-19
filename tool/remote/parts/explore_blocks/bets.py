"""Checks for the bets blocks of Explore: estimate it before you open it
(docs/explore/bets.md, round 139 of the canvas).

The app reads a section of bets defensively: a size it does not draw, a field
of the wrong type or out of range, a card it cannot bet on, are quietly put
right or left out, so a phone never breaks on one. That is exactly why they
are refused here, one by one: what the app would quietly put right is what
the person writing the section did not mean.

A bet is a card's own answer given before the card is opened, so a bet can
only be laid on a card whose answer is a number, and each block plays some of
those and not others. The rules below are the app's own
(lib/explore/blocks/bets/answers.dart and each block's `fits`), written again
here so a section naming a card the block cannot play is refused before it
reaches a phone; test/explore/bets_cases.json holds cases both sides are
tested against, so the two cannot drift apart unnoticed.
"""
from __future__ import annotations

import functools
import json
import math
import re
from pathlib import Path
from typing import Callable, Optional

ROOT = Path(__file__).resolve().parents[4]
BANK = ROOT / "tool" / "cards" / "bank"
L10N = ROOT / "lib" / "l10n"

# What every section may say, whatever its block (lib/explore/explore_block.dart).
COMMON = {"id", "block", "title", "subtitle", "source", "size", "style", "limit", "audience"}

# The kinds of bet a shelf lays, as the slip's `kinds` names them.
KINDS = ("range", "stake", "number", "closer", "magnitude", "day", "bigger")


# ── The bank ──────────────────────────────────────────────────────────────


@functools.lru_cache(maxsize=1)
def bank() -> dict[str, dict]:
    """Every card in the bank by id, as tool/cards/bundle.py publishes it."""
    out: dict[str, dict] = {}
    for path in sorted(BANK.glob("*/*.json")):
        card = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(card, dict) and isinstance(card.get("id"), str):
            out[card["id"]] = card
    return out


@functools.lru_cache(maxsize=1)
def languages() -> frozenset[str]:
    """The languages the app is written in: one arb file each."""
    return frozenset(p.stem[len("app_"):] for p in L10N.glob("app_*.arb"))


# ── Numbers as Dart rounds and writes them ───────────────────────────────


def dart_round(x: float) -> int:
    """`double.round()`: to the nearest whole number, halves away from nought
    (Python's round() takes halves to the even one)."""
    if x < 0:
        return -dart_round(-x)
    whole = math.floor(x)
    return int(whole) + (1 if x - whole >= 0.5 else 0)


def log10(x: float) -> float:
    """`math.log(x) / math.ln10`, as the app computes it: not math.log10,
    which is exact at powers of ten where the app's quotient is not."""
    return math.log(x) / math.log(10)


def pow10(e: int) -> float:
    """`math.pow(10, e).toDouble()`."""
    return float(10 ** e) if e >= 0 else math.pow(10.0, e)


def plain_response(v: float) -> str:
    """The plain form a card keeps an answer in (plainResponse)."""
    if v == float(dart_round(v)) and abs(v) < 1e15:
        return str(dart_round(v))
    s = f"{v:.6f}".rstrip("0")
    return s[:-1] if s.endswith(".") else s


def bet_unit(text: str) -> float:
    """A number from 0 to 1 for [text], the same as the app's betUnit: FNV-1a
    over the UTF-16 code units, then the murmur finaliser."""
    h = 0x811C9DC5
    units = text.encode("utf-16-le")
    for i in range(0, len(units), 2):
        c = units[i] | (units[i + 1] << 8)
        h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF
    h ^= h >> 16
    h = (h * 0x85EBCA6B) & 0xFFFFFFFF
    h ^= h >> 13
    h = (h * 0xC2B2AE35) & 0xFFFFFFFF
    h ^= h >> 16
    return h / 0x100000000


# ── Amounts, as the bank writes them (Amount.parse, oddsOf) ──────────────

# Dart's expressions run with JavaScript's rules: \d is 0-9, \s is
# JavaScript's own set of spaces, and \b is a boundary of ASCII letters,
# digits and underscores. All three are spelled out, and the end is \Z,
# which unlike $ will not match before a final newline. String.trim() takes
# off Unicode's spaces and the byte order mark.
_SPACE = "\t\n\x0b\x0c\r \u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000\ufeff"
_S = f"[{_SPACE}]"
_TRIM = "\t\n\x0b\x0c\r \x85\xa0\u1680" + "".join(chr(c) for c in range(0x2000, 0x200B)) + (
    "\u2028\u2029\u202f\u205f\u3000\ufeff")
_QUALIFIER = (
    r"(?:about|around|roughly|nearly|almost|approximately|close to|"
    r"just over|just under|well over|well under|over|under|less than|"
    r"more than|fewer than|up to|at least|at most|only|exactly|barely|some)"
)
_NUMBER = r"([−-]?[0-9]{1,3}(?:,[0-9]{3})+(?:\.[0-9]+)?|[−-]?[0-9]+(?:\.[0-9]+)?)"
_END = r"(?![A-Za-z0-9_])"
_AMOUNT = re.compile(
    rf"^(?:{_QUALIFIER}{_S}+)?[€$£¥]?{_S}?{_NUMBER}{_S}?"
    rf"(%|per ?cent{_END}|thousand{_END}|million{_END}|billion{_END}|trillion{_END}|"
    rf"quadrillion{_END}|bn{_END}|k{_END})?"
    rf"(?:{_S}*[^0-9{_SPACE}][^0-9]{{0,31}})?\Z",
    re.IGNORECASE,
)
_ODDS = re.compile(
    rf"^(?:{_QUALIFIER}{_S}+)?1{_S}+in{_S}+{_NUMBER}(?:{_S}+(thousand|million|billion))?\Z",
    re.IGNORECASE,
)
_SCALE = {"k": 1e3, "thousand": 1e3, "million": 1e6, "bn": 1e9, "billion": 1e9,
          "trillion": 1e12, "quadrillion": 1e15}


def _read(digits: str) -> Optional[float]:
    try:
        return float(digits.replace(",", "").replace("−", "-"))
    except ValueError:
        return None


def amount(option: str) -> Optional[tuple[float, bool]]:
    """The amount an option names and whether it is said in per cent, or
    None when it names words, a range, or anything but one amount."""
    m = _AMOUNT.match(option.strip(_TRIM))
    if m is None:
        return None
    n = _read(m.group(1))
    if n is None:
        return None
    size = (m.group(2) or "").lower().replace(" ", "")
    return n * _SCALE.get(size, 1), size in ("%", "percent")


def odds_of(option: str) -> Optional[float]:
    """The n of odds of "1 in n" an option names, or None."""
    m = _ODDS.match(option.strip(_TRIM))
    if m is None:
        return None
    n = _read(m.group(1))
    if n is None or n < 1:
        return None
    return n * _SCALE.get((m.group(2) or "").lower(), 1)


# ── A card's answer as a number (BetAnswer.of) ───────────────────────────


def _is_share(unit: str, value: float) -> bool:
    return unit.strip().lower() in ("%", "percent", "per cent") and 0 <= value <= 100


def _number(card: dict, key: str, fallback: Optional[float] = None) -> Optional[float]:
    v = card.get(key, fallback)
    return float(v) if isinstance(v, (int, float)) and not isinstance(v, bool) else None


def answer_of(card: dict) -> Optional[dict]:
    """The card's answer as a number to bet on, or None when it is not one.

    `kind` is typed, estimate or amounts; `value` the number (for odds, the n
    of "1 in n"); `share` whether it is a share from 0 to 100 per cent;
    `pick` whether it is picked from options; `odds` whether those are odds.
    """
    kind = card.get("kind", "read")
    unit = card.get("unit") if isinstance(card.get("unit"), str) else ""
    if kind == "number":
        v = _number(card, "value")
        if v is None or not math.isfinite(v):
            return None
        return {"kind": "typed", "value": v, "unit": unit.strip(), "share": _is_share(unit, v),
                "pick": False, "odds": False, "tolerance": _number(card, "tolerance", 0)}
    if kind == "estimate":
        v = _number(card, "value")
        if v is None or not math.isfinite(v) or v <= 0:
            return None
        return {"kind": "estimate", "value": v, "unit": unit.strip(), "share": _is_share(unit, v),
                "pick": False, "odds": False, "factor": _number(card, "withinFactor", 3)}
    if kind == "pickOne":
        options = card.get("options")
        correct = card.get("correct")
        if (not isinstance(options, list) or not 2 <= len(options) <= 3
                or not isinstance(correct, int) or not 0 <= correct < len(options)):
            return None
        options = [str(o) for o in options]
        odds = [odds_of(o) for o in options]
        if all(o is not None for o in odds):
            if len(set(odds)) != len(odds):
                return None
            return {"kind": "amounts", "value": odds[correct], "unit": "", "share": False,
                    "pick": True, "odds": True, "amounts": odds, "correct": correct}
        parsed = [amount(o) for o in options]
        if any(p is None for p in parsed):
            return None
        values = [p[0] for p in parsed]
        if len(set(values)) != len(values):
            return None
        shares = all(p[1] and 0 <= p[0] <= 100 for p in parsed)
        return {"kind": "amounts", "value": values[correct], "unit": "", "share": shares,
                "pick": True, "odds": False, "amounts": values, "correct": correct}
    return None


def accepts(card: dict, response: str) -> bool:
    """Whether the card itself counts [response] right (Challenge.accepts)."""
    kind = card.get("kind", "read")
    if kind == "pickOne":
        try:
            return int(response) == card.get("correct")
        except ValueError:
            return False
    cleaned = response.strip(_TRIM).replace(" ", "").replace(",", ".")
    try:
        given = float(cleaned)
    except ValueError:
        return False
    answer = _number(card, "value")
    if answer is None:
        return False
    if kind == "number":
        tolerance = _number(card, "tolerance", 0)
        return tolerance is not None and abs(given - answer) <= tolerance
    if kind == "estimate":
        factor = _number(card, "withinFactor", 3)
        if factor is None or given <= 0:
            return False
        try:
            return answer / factor <= given <= answer * factor
        except ZeroDivisionError:
            return False
    return False


def step_scale(card: dict, a: dict) -> Optional[dict]:
    """The steppers' steps for the card (StepScale.around), or None when its
    answer cannot be reached on them within its tolerance."""
    v = a["value"]
    if v < 0 or v > 1e9:
        return None
    magnitude = 1.0 if v < 1e-9 else pow10(math.floor(log10(v)))
    small = None
    for step in (magnitude / 10, magnitude / 20):
        if step < 0.01 - 1e-12:
            break
        nearest = dart_round(v / step) * step
        if abs(nearest - v) <= (a.get("tolerance") or 0.0) + 1e-9:
            small = step
            break
    if small is None:
        return None
    big = small * (10 if bet_unit(f"big:{card['id']}") < 0.5 else 5)
    return {"small": small, "big": big}


def notches(card: dict, a: dict) -> Optional[list[float]]:
    """The sizes the card is picked from by order of magnitude (Notches.of),
    smallest first, or None when it is not judged on one."""
    if a["pick"]:
        return sorted(a["amounts"]) if a["odds"] else None
    if a["kind"] != "estimate":
        return None
    decade = dart_round(log10(a["value"]))
    if not accepts(card, plain_response(pow10(decade))):
        return None
    at = 1 + math.floor(bet_unit(f"notch:{card['id']}") * 4)
    values = [pow10(decade - at + i) for i in range(6)]
    if values[0] < 1e-6 or values[-1] > 1e15:
        return None
    return values


# ── What each block bets on (each block's `fits`) ────────────────────────


def _share_set(card: dict, a: dict) -> bool:
    return a["share"] and not a["pick"]


FITS: dict[str, tuple[Callable[[dict, dict], bool], str]] = {
    "bets-range": (_share_set, "a share from 0 to 100% the card has typed or estimated"),
    "bets-slip": (lambda c, a: True, "an answer that is a number"),
    "bets-stake": (lambda c, a: a["pick"], "a pick whose options are all amounts or all odds"),
    "bets-friend": (lambda c, a: True, "an answer that is a number"),
    "bets-number": (
        lambda c, a: a["kind"] == "typed" and not a["share"] and step_scale(c, a) is not None,
        "a typed number, not a share, that steps of a tenth or a twentieth of its size reach",
    ),
    "bets-bigger": (lambda c, a: a["share"], "a share from 0 to 100%"),
    "bets-closer": (lambda c, a: a["share"], "a share from 0 to 100%"),
    "bets-magnitude": (
        lambda c, a: notches(c, a) is not None,
        "an estimate a power of ten counts right, or a pick of odds",
    ),
    "bets-day": (_share_set, "a share from 0 to 100% the card has typed or estimated"),
}


def fits(block: str, card: dict) -> bool:
    """Whether [block] can lay a bet on [card]."""
    a = answer_of(card)
    return a is not None and FITS[block][0](card, a)


# ── Reading a section ────────────────────────────────────────────────────


def _is_int(v) -> bool:
    """A whole number as JSON writes one: 3 or 3.0, never true or 2.5."""
    return isinstance(v, (int, float)) and not isinstance(v, bool) and float(v).is_integer()


def _check_text(field: str, raw) -> list[str]:
    """A field written per language or once for all of them."""
    if isinstance(raw, str):
        return [] if raw.strip() else [f"{field} is empty"]
    if not isinstance(raw, dict) or not raw:
        return [f"{field} is neither text nor {{language: text}}"]
    problems = []
    for lang, text in raw.items():
        if lang not in languages():
            problems.append(f"{field}: {lang!r} is not a language the app is written in "
                            f"({', '.join(sorted(languages()))})")
        if not isinstance(text, str) or not text.strip():
            problems.append(f"{field}.{lang} is not text")
    return problems


def _check_card(block: str, cid, where: str) -> list[str]:
    """A card a section names: in the bank, live, and one [block] can bet on."""
    if not isinstance(cid, str) or not cid:
        return [f"{where}: {cid!r} is not a card id"]
    card = bank().get(cid)
    if card is None:
        return [f"{where}: no card {cid!r} in the bank"]
    if card.get("disabled"):
        return [f"{where}: card {cid!r} is retired"]
    if answer_of(card) is None:
        return [f"{where}: card {cid!r} has no number for an answer to bet on"]
    if not fits(block, card):
        return [f"{where}: card {cid!r} is not one {block} bets on: it takes {FITS[block][1]}"]
    return []


def _check_flag(section: dict, key: str) -> list[str]:
    if key in section and not isinstance(section[key], bool):
        return [f"{key} is not true or false"]
    return []


def _check_count(section: dict, key: str, lo: int, hi: int) -> list[str]:
    if key not in section:
        return []
    v = section[key]
    if not _is_int(v) or not lo <= v <= hi:
        return [f"{key} is not a whole number from {lo} to {hi}"]
    return []


def _check_widths(section: dict) -> list[str]:
    raw = section.get("widths")
    if raw is None:
        return []
    rule = ("widths is not two to four [half, pays], the halves rising from 1 to 50 "
            "and the pays falling from 1000 to 1, as whole numbers")
    if not isinstance(raw, list) or not 2 <= len(raw) <= 4:
        return [rule]
    last = None
    for w in raw:
        # The app reads each as an int: 5.0 is not one there.
        if (not isinstance(w, list) or len(w) != 2
                or any(isinstance(x, bool) or not isinstance(x, int) for x in w)):
            return [rule]
        half, pays = w
        if not 1 <= half <= 50 or not 1 <= pays <= 1000:
            return [rule]
        if last is not None and (half <= last[0] or pays >= last[1]):
            return [rule]
        last = (half, pays)
    return []


def _check_stakes(section: dict) -> list[str]:
    raw = section.get("stakes")
    if raw is None:
        return []
    if (not isinstance(raw, list) or not 1 <= len(raw) <= 4
            or not all(_is_int(v) and 1 <= v <= 100 for v in raw)
            or any(b <= a for a, b in zip(raw, raw[1:]))):
        return ["stakes is not one to four whole numbers rising from 1 to 100"]
    return []


def _check_kinds(section: dict) -> list[str]:
    raw = section.get("kinds")
    if raw is None:
        return []
    if not isinstance(raw, list) or not raw:
        return [f"kinds is not a list of the kinds of bet ({', '.join(KINDS)})"]
    return [f"kinds: {k!r} is not a kind of bet ({', '.join(KINDS)})" for k in raw if k not in KINDS]


def _check_pairs(section: dict) -> list[str]:
    raw = section.get("pairs")
    if raw is None:
        return []
    if not isinstance(raw, list) or not raw:
        return ["pairs is not a list of [id, id]"]
    problems = []
    for i, pair in enumerate(raw):
        where = f"pairs[{i}]"
        if not isinstance(pair, list) or len(pair) != 2:
            problems.append(f"{where} is not [id, id]")
            continue
        found = [_check_card("bets-bigger", cid, where) for cid in pair]
        problems += [p for ps in found for p in ps]
        if any(found):
            continue
        a, b = (answer_of(bank()[cid])["value"] for cid in pair)
        if pair[0] == pair[1] or a == b:
            problems.append(f"{where}: the two figures are the same, so neither is bigger")
    return problems


def _check_labels(section: dict) -> list[str]:
    raw = section.get("labels")
    if raw is None:
        return []
    if not isinstance(raw, dict) or not raw:
        return ["labels is not {card id: text}"]
    problems = []
    for cid, text in raw.items():
        problems += _check_card("bets-bigger", cid, "labels")
        problems += _check_text(f"labels.{cid}", text)
    return problems


def _check_card_field(block: str, section: dict) -> list[str]:
    if "card" not in section:
        return []
    return _check_card(block, section["card"], "card")


# Each block: the sizes it draws, the most `limit` may be (None where it reads
# no limit), whether it reads `style.tone` and `subtitle`, and its own fields.
SPEC: dict[str, dict] = {
    "bets-range": {"limit": 12, "fields": {
        "wallet": lambda s: _check_flag(s, "wallet"),
        "slip": lambda s: _check_flag(s, "slip"),
        "widths": _check_widths,
    }},
    "bets-slip": {"limit": 50, "tone": False, "subtitle": False, "fields": {
        "kinds": _check_kinds,
    }},
    "bets-stake": {"limit": 12, "fields": {
        "wallet": lambda s: _check_flag(s, "wallet"),
        "stakes": _check_stakes,
        "sure": lambda s: _check_flag(s, "sure"),
    }},
    "bets-friend": {"limit": None, "tone": False, "fields": {
        "card": lambda s: _check_card_field("bets-friend", s),
    }},
    "bets-number": {"limit": 12, "fields": {
        "sure": lambda s: _check_flag(s, "sure"),
    }},
    "bets-bigger": {"limit": 6, "fields": {
        "pairs": _check_pairs,
        "gap": lambda s: _check_count(s, "gap", 1, 50),
        "labels": _check_labels,
    }},
    "bets-closer": {"limit": 12, "fields": {
        "steps": lambda s: _check_count(s, "steps", 2, 5),
    }},
    "bets-magnitude": {"limit": 12, "fields": {
        "sure": lambda s: _check_flag(s, "sure"),
    }},
    "bets-day": {"limit": 12, "fields": {
        "tag": lambda s: _check_flag(s, "tag"),
        "same": lambda s: _check_flag(s, "same"),
        "sure": lambda s: _check_flag(s, "sure"),
    }},
}

SIZES = ("s", "m", "l")


def _checker(block: str) -> Callable[[dict], list[str]]:
    spec = SPEC[block]

    def check(section: dict) -> list[str]:
        problems: list[str] = []
        own = spec["fields"]
        for key in section:
            if key in COMMON or key in own:
                continue
            problems.append(f"{key!r} is not a field {block} reads (its own are: "
                            f"{', '.join(sorted(own)) or 'none'})")
        if "size" in section and section["size"] not in SIZES:
            problems.append(f"size {section['size']!r} is not one {block} draws (s, m or l)")
        if "limit" in section:
            most = spec["limit"]
            size = section.get("size", "m")
            if most is None:
                problems.append(f"limit: {block} shows one card, so it has none")
            elif not _is_int(section["limit"]) or not 1 <= section["limit"] <= most:
                problems.append(f"limit is not a whole number from 1 to {most}")
            elif block == "bets-slip" and size in ("s", "l"):
                problems.append("limit: the slip reads it only at size m (s shows the latest "
                                "bet, l all of them)")
            elif block == "bets-day" and size == "l":
                problems.append("limit: at size l the bet of the day stands alone")
        if "style" in section:
            style = section["style"]
            if not spec.get("tone", True):
                problems.append(f"style: {block} has one look, so it has none")
            elif not isinstance(style, dict):
                problems.append("style is not an object")
            else:
                for key, value in style.items():
                    if key != "tone":
                        problems.append(f"style.{key} is not one {block} reads (only tone)")
                    elif value not in ("subject", "page"):
                        problems.append("style.tone is not 'subject' or 'page'")
        for field in ("title", "subtitle"):
            if field not in section:
                continue
            if field == "subtitle" and not spec.get("subtitle", True):
                problems.append(f"subtitle: {block} has no line under its title")
                continue
            problems += _check_text(field, section[field])
        source = section.get("source")
        if isinstance(source, dict) and "ids" in source:
            ids = source["ids"]
            if not isinstance(ids, list) or not ids:
                problems.append("source.ids is not a list of card ids")
            else:
                for cid in ids:
                    problems += _check_card(block, cid, "source.ids")
                if len(set(map(str, ids))) != len(ids):
                    problems.append("source.ids names a card twice")
        for key, check_field in own.items():
            if key in section:
                problems += check_field(section)
        return problems

    return check


# block name -> check(section) returning a list of problems, each a line a
# person can act on. A block listed here is a block the app can draw.
BLOCKS: dict[str, Callable[[dict], list[str]]] = {name: _checker(name) for name in SPEC}
