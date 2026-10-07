"""Errors planted in good cards, for measuring the critic.

A critic that passes everything looks the same, in a night's pull request,
as a critic that is right: both send good cards through. The only way to
know which one runs at night is to hand it cards that are known to be wrong
and count how many it stops. These are those cards: a real card from the
bank with one error put in it, of a kind the critic is there to catch —
a figure off by ten, the wrong option marked right, a year moved, a number
card whose value no longer follows from its own working, a reference that
belongs to another card.

Every mutation is deterministic for a given seed and changes exactly one
thing, so a miss can be read: the report says which error, on which card,
and what the critic said about it.
"""
from __future__ import annotations

import copy
import random
import re
from dataclasses import dataclass

# A figure in prose: 1,500 / 2.3 / 40,000 / 18 — not a year, which has its
# own mutation, and not part of a word (CO2, H2O, Covid-19).
_FIGURE = re.compile(r"(?<![\w.,])(\d{1,3}(?:,\d{3})+|\d+(?:\.\d+)?)(?![\w%]|[.,]\d)")
_YEAR = re.compile(r"(?<!\d)(1[0-9]{3}|20[0-2][0-9])(?!\d)")


@dataclass(frozen=True)
class Planted:
    """A card with one error in it, and what the error is."""

    card: dict
    kind: str
    detail: str


def _numbers_in(text: str) -> list[re.Match]:
    out = []
    for m in _FIGURE.finditer(text):
        raw = m.group(1)
        value = float(raw.replace(",", ""))
        # Years are moved by their own mutation; a lone 1 or 2 is usually
        # a count in a sentence ("one of two"), too small to plant on.
        if _YEAR.fullmatch(raw) or value < 3:
            continue
        out.append(m)
    return out


def _format_like(original: str, value: float) -> str:
    """The new figure written the way the old one was."""
    if "." in original:
        decimals = len(original.split(".")[1])
        return f"{value:.{decimals}f}"
    if "," in original:
        return f"{int(round(value)):,}"
    return str(int(round(value)))


def wrong_figure(card: dict, rng: random.Random) -> Planted | None:
    """One figure in the answer, ten times too big or too small."""
    answer = card.get("answer", "")
    found = _numbers_in(answer)
    if not found:
        return None
    m = rng.choice(found)
    raw = m.group(1)
    value = float(raw.replace(",", ""))
    factor = 10 if rng.random() < 0.5 else 0.1
    new_value = value * factor
    if new_value < 1:
        new_value = value * 10
    new = _format_like(raw, new_value)
    if new == raw:
        return None
    out = copy.deepcopy(card)
    out["answer"] = answer[: m.start(1)] + new + answer[m.end(1):]
    return Planted(out, "wrong_figure", f"answer: {raw} → {new}")


def wrong_year(card: dict, rng: random.Random) -> Planted | None:
    """A year in the answer moved by decades."""
    answer = card.get("answer", "")
    found = list(_YEAR.finditer(answer))
    if not found:
        return None
    m = rng.choice(found)
    year = int(m.group(1))
    shift = rng.choice([-1, 1]) * rng.choice([30, 47, 60, 85, 120])
    new = year + shift
    if new > 2025 or new < 1000:
        new = year - abs(shift)
    out = copy.deepcopy(card)
    out["answer"] = answer[: m.start(1)] + str(new) + answer[m.end(1):]
    return Planted(out, "wrong_year", f"answer: {year} → {new}")


def wrong_key(card: dict, rng: random.Random) -> Planted | None:
    """A three-option card with another option marked right."""
    options = card.get("options")
    if card.get("kind") != "pickOne" or not options or options == ["True", "False"]:
        return None
    others = [i for i in range(len(options)) if i != card.get("correct")]
    if not others:
        return None
    new = rng.choice(others)
    out = copy.deepcopy(card)
    out["correct"] = new
    return Planted(out, "wrong_key", f"correct: {options[card['correct']]!r} → {options[new]!r}")


def flipped_truth(card: dict, rng: random.Random) -> Planted | None:
    """A true-or-false card with its verdict turned round."""
    if card.get("options") != ["True", "False"]:
        return None
    out = copy.deepcopy(card)
    out["correct"] = 1 - int(card["correct"])
    return Planted(out, "flipped_truth", f"correct: {card['options'][card['correct']]} → {card['options'][out['correct']]}")


def wrong_value(card: dict, rng: random.Random) -> Planted | None:
    """A number or estimate card whose value no longer follows from its steps."""
    if card.get("kind") not in ("number", "estimate") or not isinstance(card.get("value"), (int, float)):
        return None
    value = card["value"]
    factor = rng.choice([3, 4, 0.25, 1 / 3]) if card.get("kind") == "number" else rng.choice([20, 0.05])
    new = value * factor
    new = int(round(new)) if float(value).is_integer() and abs(new) >= 1 else round(new, 3)
    if new == value:
        return None
    out = copy.deepcopy(card)
    out["value"] = new
    return Planted(out, "wrong_value", f"value: {value} → {new}")


def borrowed_source(card: dict, rng: random.Random, *, donors: list[dict]) -> Planted | None:
    """The reference of a card on another subject, put on this one."""
    if not card.get("reference") or not donors:
        return None
    pool = [d for d in donors if d.get("topic") != card.get("topic") and d.get("reference") and d.get("reference") != card.get("reference")]
    if not pool:
        return None
    donor = rng.choice(pool)
    out = copy.deepcopy(card)
    out["reference"] = donor["reference"]
    if donor.get("source"):
        out["source"] = donor["source"]
    out.pop("quote", None)
    return Planted(out, "borrowed_source", f"reference from {donor['id']}")


MUTATIONS = {
    "wrong_figure": wrong_figure,
    "wrong_year": wrong_year,
    "wrong_key": wrong_key,
    "flipped_truth": flipped_truth,
    "wrong_value": wrong_value,
    "borrowed_source": borrowed_source,
}


def plant(card: dict, rng: random.Random, *, donors: list[dict] | None = None, kinds: list[str] | None = None) -> Planted | None:
    """One error in [card], of a kind that fits it, or None if none fits."""
    order = list(kinds or MUTATIONS)
    rng.shuffle(order)
    for kind in order:
        fn = MUTATIONS[kind]
        planted = fn(card, rng, donors=donors or []) if kind == "borrowed_source" else fn(card, rng)
        if planted is not None:
            return planted
    return None
