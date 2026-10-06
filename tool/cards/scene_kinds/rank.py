"""Rules for a `rank` scene: put a few things in order by one quantity.

The reader drags 3 to 5 rows into the order they believe, locks it in, and
the rows slide to their true places as bars grow to the real values
(lib/models/scenes/rank.dart, lib/widgets/scenes/rank_view.dart).

The lengths are what fits one line of a row, or of the heading, on a 360 px
phone. What this cannot check is whether the values are true and measured
the same way for every item: that is the writer's rule, and the source says
where they come from.
"""
from __future__ import annotations

import math

QUANTITY_CHARS = 34   # the small heading over the list
MOST_CHARS = 16       # the word for the top of the list
UNIT_CHARS = 10       # printed beside every value in a row
LABEL_CHARS = 22      # one line of a row, beside its value
NOTE_CHARS = 90       # two lines under the list
ITEMS = (3, 5)
LOG_SPAN = 2.0        # decades between smallest and largest that call for a log scale


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def check(scene: dict) -> list[str]:
    p: list[str] = []
    for key, limit in (("quantity", QUANTITY_CHARS), ("most", MOST_CHARS)):
        v = scene.get(key)
        if not isinstance(v, str) or not v.strip():
            p.append(f"scene.{key}: missing")
        elif len(v) > limit:
            p.append(f"scene.{key}: {len(v)} chars, over {limit}")
    unit = scene.get("unit", "")
    if not isinstance(unit, str) or len(unit) > UNIT_CHARS:
        p.append(f"scene.unit: a string of at most {UNIT_CHARS} chars")
    log = scene.get("log", False)
    if not isinstance(log, bool):
        p.append("scene.log: true or false")
        log = False

    items = scene.get("items")
    if not isinstance(items, list) or not (ITEMS[0] <= len(items) <= ITEMS[1]):
        return p + [f"scene.items: between {ITEMS[0]} and {ITEMS[1]}"]
    values: list[float] = []
    labels: list[str] = []
    for i, it in enumerate(items):
        if not isinstance(it, dict):
            p.append(f"scene.items[{i}]: not an object")
            continue
        label, value, note = it.get("label"), it.get("value"), it.get("note", "")
        if not isinstance(label, str) or not label.strip():
            p.append(f"scene.items[{i}].label: missing")
        elif len(label) > LABEL_CHARS:
            p.append(f"scene.items[{i}].label: {len(label)} chars, over {LABEL_CHARS}")
        else:
            labels.append(label.strip().lower())
        if not _num(value) or value < 0:
            p.append(f"scene.items[{i}].value: a number, zero or more")
        elif log and value <= 0:
            p.append(f"scene.items[{i}].value: a log scale needs it above zero")
        else:
            values.append(float(value))
        if not isinstance(note, str):
            p.append(f"scene.items[{i}].note: not a string")
        elif len(note) > NOTE_CHARS:
            p.append(f"scene.items[{i}].note: {len(note)} chars, over {NOTE_CHARS}")
        for key in it:
            if key not in ("label", "value", "note"):
                p.append(f"scene.items[{i}]: unknown field {key!r}")
    if len(set(labels)) != len(labels):
        p.append("scene.items: two items share a label")
    if len(values) != len(items):
        return p
    if len(set(values)) != len(values):
        p.append("scene.items: values must all differ, or the order is not one answer")
    elif values == sorted(values, reverse=True):
        p.append("scene.items: already in the right order; the reader starts from it")
    if not any(isinstance(it.get("note"), str) and it["note"].strip() for it in items):
        p.append("scene.items: no item has a note; the surprise has nothing to say")
    lo, hi = min(values), max(values)
    if hi <= 0:
        p.append("scene.items: every value is zero")
    elif lo > 0:
        span = math.log10(hi / lo)
        if not log and span > LOG_SPAN + 1:
            p.append(f"scene.log: values span {span:.1f} decades; the smallest bars "
                     "would vanish, set log: true")
        if log and span < 1:
            p.append(f"scene.log: values span only {span:.1f} decades; bars read "
                     "truer on a plain scale")
    return p
