"""Rules for a `draw` scene: draw the line you expect, then see the real one.

The fields are documented in lib/models/scenes/draw.dart. The limits here are
what fits a 360-point phone: the YOU and TRUTH numbers side by side over the
chart, column labels under it, two or three lines of verdict beside the
button.

What this cannot check is whether the line is true, and whether the range
gives it away: a `max` that sits right on the last value tells the reader
where to draw. Leave headroom.
"""
from __future__ import annotations

import math

LABEL_CHARS = 34    # small caps across the top of the chart
UNIT_CHARS = 8
COLUMN_CHARS = 8    # under a column, thinned when they crowd
COLUMNS = (3, 10)
VERDICT_CHARS = 100  # three lines beside the button
NOTE_CHARS = 40      # a two-line tag inside the chart
NOTES = (0, 3)
NUMBER_CHARS = 9     # "×1,845", "414 ppm": one big number in half the width


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def _whole(v) -> bool:
    return _num(v) and float(v).is_integer()


def _shown(v: float, decimals: int, unit: str) -> str:
    """The number as the app writes it, to measure it."""
    if abs(v) >= 1e6:
        n = f"{abs(v) / 1e6:.1f} million"
    else:
        n = f"{abs(v):,.{decimals}f}"
    if unit in ("€", "$", "£", "¥", "×"):
        return unit + n
    if unit in ("%",) or unit.startswith("°"):
        return n + unit
    return f"{n} {unit}" if unit else n


def check(scene: dict) -> list[str]:
    p: list[str] = []

    label = scene.get("label")
    if not isinstance(label, str) or not label.strip():
        p.append("scene.label: missing")
    elif len(label) > LABEL_CHARS:
        p.append(f"scene.label: {len(label)} chars, over {LABEL_CHARS}")
    unit = scene.get("unit", "")
    if not isinstance(unit, str) or len(unit) > UNIT_CHARS:
        p.append(f"scene.unit: a string of up to {UNIT_CHARS} chars")
        unit = ""

    cols = scene.get("columns")
    if not isinstance(cols, list) or not (COLUMNS[0] <= len(cols) <= COLUMNS[1]):
        return p + [f"scene.columns: between {COLUMNS[0]} and {COLUMNS[1]} labels"]
    for c in cols:
        if not isinstance(c, str) or not c.strip():
            p.append("scene.columns: every column is a label")
        elif len(c) > COLUMN_CHARS:
            p.append(f"scene.columns: {c!r} is {len(c)} chars, over {COLUMN_CHARS}")
    n = len(cols)

    vals = scene.get("values")
    if not isinstance(vals, list) or len(vals) != n or not all(_num(v) for v in vals):
        return p + ["scene.values: one number per column"]

    given = scene.get("given", 1)
    if not _whole(given) or not 0 <= given <= n - 2:
        p.append(f"scene.given: a whole number from 0 to {n - 2}")
        given = 1
    given = int(given)
    first = given if given > 0 else 0
    if n - first < 2:
        p.append("scene.given: leave at least two columns to draw")

    log = scene.get("log", False)
    if not isinstance(log, bool):
        p.append("scene.log: true or false")
        log = False
    for key in ("min", "max"):
        if key not in scene:
            p.append(f"scene.{key}: set it; the range is part of the question")
        elif not _num(scene[key]):
            p.append(f"scene.{key}: not a number")
    lo, hi = scene.get("min"), scene.get("max")
    if _num(lo) and _num(hi):
        if hi <= lo:
            p.append("scene.max: must be above min")
        elif log and lo <= 0:
            p.append("scene.min: a log chart starts above 0")
        else:
            if min(vals) < lo or max(vals) > hi:
                p.append("scene.values: every value between min and max")
            elif not log and lo < hi:
                # The truth should not touch the ceiling: that is the answer.
                top = (max(vals[first:]) - lo) / (hi - lo)
                if top > 0.97:
                    p.append("scene.max: the real line touches the top; leave headroom")
    if log and any(v <= 0 for v in vals):
        p.append("scene.values: a log chart needs every value above 0")

    decimals = scene.get("decimals", 0)
    if decimals not in (0, 1, 2):
        p.append("scene.decimals: 0, 1 or 2")
        decimals = 0

    judge = scene.get("judge", n - 1)
    if not _whole(judge) or not first <= judge <= n - 1:
        p.append(f"scene.judge: a column the reader draws, {first} to {n - 1}")
        judge = n - 1
    judge = int(judge)
    near = scene.get("near", 0.1)
    if not _num(near) or not 0 < near < 0.5:
        p.append("scene.near: a share of the chart's height, above 0 and below 0.5")

    shown = _shown(vals[judge], decimals, unit)
    if _num(lo) and _num(hi):
        widest = max(len(_shown(lo, decimals, unit)), len(_shown(hi, decimals, unit)), len(shown))
        if widest > NUMBER_CHARS:
            p.append(f"scene: numbers like {shown!r} run to {widest} chars, over {NUMBER_CHARS}")

    verdict = scene.get("verdict")
    if not isinstance(verdict, dict):
        p.append("scene.verdict: {under, near, over}")
    else:
        for key in ("under", "near", "over"):
            v = verdict.get(key)
            if not isinstance(v, str) or not v.strip():
                p.append(f"scene.verdict.{key}: missing")
            elif len(v) > VERDICT_CHARS:
                p.append(f"scene.verdict.{key}: {len(v)} chars, over {VERDICT_CHARS}")
        extra = set(verdict) - {"under", "near", "over"}
        if extra:
            p.append(f"scene.verdict: unknown {sorted(extra)}")

    notes = scene.get("notes", [])
    if not isinstance(notes, list) or not (NOTES[0] <= len(notes) <= NOTES[1]):
        return p + [f"scene.notes: between {NOTES[0]} and {NOTES[1]}"]
    ats = []
    for m in notes:
        if not isinstance(m, dict) or not _whole(m.get("at")) or not isinstance(m.get("text"), str):
            p.append("scene.notes: each is {at, text}, at a column index")
            continue
        at = int(m["at"])
        if not 0 <= at < n:
            p.append(f"scene.notes: at {at} is not a column")
        elif at == judge:
            p.append(f"scene.notes: at {at} is the judged column, which carries YOU and TRUTH")
        if not m["text"].strip() or len(m["text"]) > NOTE_CHARS:
            p.append(f"scene.notes: {len(m['text'])} chars, keep 1 to {NOTE_CHARS}")
        ats.append(at)
    ats.sort()
    if any(b - a < 2 for a, b in zip(ats, ats[1:])):
        p.append("scene.notes: at least two columns apart, or the tags collide")

    known = {"type", "label", "unit", "columns", "values", "given", "min", "max", "log",
             "decimals", "judge", "near", "verdict", "notes"}
    extra = set(scene) - known
    if extra:
        p.append(f"scene: unknown fields {sorted(extra)}")
    return p
