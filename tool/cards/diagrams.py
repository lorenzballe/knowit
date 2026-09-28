"""The rules a card's `diagram` has to keep, checked before the app ever sees it.

A diagram is data the app draws and animates (lib/models/diagram.dart and
lib/widgets/diagram_view.dart). The app refuses a malformed one of a kind it
knows, so every rule the painter relies on is checked here first: what each
kind needs, how many things it can hold before labels collide, how long a
label can run before it is cut, and that the numbers are the kind of numbers
the kind is for (a logarithmic scale is for things at least ten times apart;
a split is a whole, so its percentages add up to a hundred).

What this cannot check is whether the numbers are the card's. That is the
writer's rule, and the critic's: every value in a diagram is one the card
states or one its steps work out, never a new fact.

    python3 tool/cards/diagrams.py            # every diagram in the bank
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

KINDS = ("dots", "bars", "scale", "area", "split", "line", "timeline")

# Room on a phone-width card, measured on the rendered previews.
CAPTION_WORDS = 18
LABEL_CHARS = {"dots": 34, "bars": 40, "scale": 26, "area": 26, "split": 22, "line": 30, "timeline": 34, "span": 22, "mark": 30}
UNIT_CHARS = 24

ITEMS = {"bars": (2, 6), "scale": (2, 5), "area": (2, 3), "split": (2, 5)}


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def _text(v) -> bool:
    return isinstance(v, str)


def check_diagram(d) -> list[str]:
    """Everything wrong with one diagram object, as short sentences."""
    out: list[str] = []
    if not isinstance(d, dict):
        return ["diagram is not an object"]
    kind = d.get("type")
    if kind not in KINDS:
        return [f"diagram type {kind!r} is not one of {', '.join(KINDS)}"]

    known = {"type", "caption"} | {
        "dots": {"total", "groups"},
        "bars": {"unit", "log", "items"},
        "scale": {"unit", "items"},
        "area": {"unit", "items"},
        "split": {"unit", "parts"},
        "line": {"x", "y", "series", "marks"},
        "timeline": {"from", "to", "events", "spans"},
    }[kind]
    for key in d:
        if key not in known:
            out.append(f"diagram: {kind} has no field {key!r}")

    caption = d.get("caption", "")
    if not _text(caption):
        out.append("diagram caption is not text")
    elif len(caption.split()) > CAPTION_WORDS:
        out.append(f"diagram caption runs past {CAPTION_WORDS} words")
    elif caption and caption.rstrip()[-1] not in ".?)":
        out.append("diagram caption is a sentence and ends like one")

    def label(v, where, limit):
        if not _text(v) or not v.strip():
            out.append(f"diagram: {where} needs a label")
        elif len(v) > limit:
            out.append(f"diagram: {where} label runs past {limit} characters: {v!r}")

    def unit_ok(u):
        if u is not None and (not _text(u) or len(u) > UNIT_CHARS):
            out.append(f"diagram unit is text of at most {UNIT_CHARS} characters")

    if kind == "dots":
        total = d.get("total")
        if total not in (100, 1000):
            out.append("dots: total is 100 or 1000")
        groups = d.get("groups")
        if not isinstance(groups, list) or not 1 <= len(groups) <= 3:
            out.append("dots: one to three groups")
        else:
            s = 0
            for i, g in enumerate(groups):
                if not isinstance(g, dict) or not isinstance(g.get("n"), int) or isinstance(g.get("n"), bool) or g["n"] < 1:
                    out.append(f"dots: group {i + 1} has a whole number n of at least 1")
                    continue
                s += g["n"]
                label(g.get("label"), f"group {i + 1}", LABEL_CHARS["dots"])
                for key in g:
                    if key not in ("n", "label", "hi", "spread"):
                        out.append(f"dots: a group has no field {key!r}")
            if isinstance(total, int) and s > total:
                out.append(f"dots: the groups hold {s}, more than the {total} there are")
            if isinstance(total, int) and s == total:
                out.append("dots: the groups fill every dot; leave the rest of the crowd showing")

    elif kind in ITEMS:
        key = "parts" if kind == "split" else "items"
        lo, hi = ITEMS[kind]
        items = d.get(key)
        unit_ok(d.get("unit"))
        if not isinstance(items, list) or not lo <= len(items) <= hi:
            out.append(f"{kind}: {lo} to {hi} {key}")
        else:
            values = []
            for i, it in enumerate(items):
                if not isinstance(it, dict) or not _num(it.get("value")) or it["value"] <= 0:
                    out.append(f"{kind}: {key[:-1]} {i + 1} has a positive value")
                    continue
                values.append(it["value"])
                label(it.get("label"), f"{key[:-1]} {i + 1}", LABEL_CHARS[kind])
                for k in it:
                    if k not in ("label", "value", "hi"):
                        out.append(f"{kind}: an item has no field {k!r}")
            if len(values) == len(items) and values:
                spread = max(values) / min(values)
                if kind == "scale" and spread < 10:
                    out.append("scale: for things under ten times apart, use bars")
                if kind == "bars" and not d.get("log") and spread > 60:
                    out.append("bars: over sixty times apart the small bars vanish; use a scale, or log")
                if kind == "area" and spread > 2500:
                    out.append("area: over 2,500 times apart the small circle is a speck; use a scale")
                if kind == "split" and d.get("unit") == "%" and not 97 <= sum(values) <= 103:
                    out.append(f"split: the percentages add up to {sum(values):g}, not 100")
        if kind == "bars" and "log" in d and not isinstance(d["log"], bool):
            out.append("bars: log is true or false")

    elif kind == "line":
        axes = {}
        for name in ("x", "y"):
            a = d.get(name)
            if not isinstance(a, dict) or not _num(a.get("min")) or not _num(a.get("max")) or a["min"] >= a["max"]:
                out.append(f"line: axis {name} has a min below its max")
                continue
            if a.get("log") and a["min"] <= 0:
                out.append(f"line: a logarithmic axis {name} starts above zero")
            if a.get("label") is not None and (not _text(a["label"]) or len(a["label"]) > 32):
                out.append(f"line: axis {name} label is text of at most 32 characters")
            for k in a:
                if k not in ("label", "min", "max", "log"):
                    out.append(f"line: an axis has no field {k!r}")
            axes[name] = a

        def inside(name, v):
            a = axes.get(name)
            if a is None or not _num(v):
                return False
            span = a["max"] - a["min"]
            return a["min"] - 0.02 * span <= v <= a["max"] + 0.02 * span

        series = d.get("series")
        if not isinstance(series, list) or not 1 <= len(series) <= 3:
            out.append("line: one to three series")
        else:
            for i, s in enumerate(series):
                pts = s.get("points") if isinstance(s, dict) else None
                if not isinstance(pts, list) or not 2 <= len(pts) <= 80:
                    out.append(f"line: series {i + 1} has 2 to 80 points")
                    continue
                if not all(isinstance(p, list) and len(p) == 2 and _num(p[0]) and _num(p[1]) for p in pts):
                    out.append(f"line: series {i + 1} has points written as [x, y]")
                    continue
                xs = [p[0] for p in pts]
                if xs != sorted(xs):
                    out.append(f"line: series {i + 1} runs left to right")
                bad = [p for p in pts if not (inside("x", p[0]) and inside("y", p[1]))]
                if bad and axes.keys() == {"x", "y"}:
                    out.append(f"line: series {i + 1} leaves the axes at {bad[0]}")
                if s.get("label"):
                    label(s["label"], f"series {i + 1}", LABEL_CHARS["line"])
        marks = d.get("marks", [])
        if not isinstance(marks, list) or len(marks) > 3:
            out.append("line: at most three marks")
        else:
            for i, m in enumerate(marks):
                if not isinstance(m, dict) or not (inside("x", m.get("x")) and inside("y", m.get("y"))):
                    out.append(f"line: mark {i + 1} sits on the axes")
                    continue
                label(m.get("label"), f"mark {i + 1}", LABEL_CHARS["mark"])

    elif kind == "timeline":
        a, b = d.get("from"), d.get("to")
        if not (_num(a) and _num(b)) or a >= b:
            out.append("timeline: from comes before to")
            return out
        events = d.get("events", [])
        spans = d.get("spans", [])
        if not events and not spans:
            out.append("timeline: at least one event or span")
        if not isinstance(events, list) or len(events) > 5:
            out.append("timeline: at most five events")
        else:
            for i, e in enumerate(events):
                if not isinstance(e, dict) or not _num(e.get("at")) or not a <= e["at"] <= b:
                    out.append(f"timeline: event {i + 1} falls between from and to")
                    continue
                label(e.get("label"), f"event {i + 1}", LABEL_CHARS["timeline"])
        if not isinstance(spans, list) or len(spans) > 3:
            out.append("timeline: at most three spans")
        else:
            for i, s in enumerate(spans):
                if not isinstance(s, dict) or not (_num(s.get("from")) and _num(s.get("to"))) or not a <= s["from"] < s["to"] <= b:
                    out.append(f"timeline: span {i + 1} runs forwards inside the line")
                    continue
                label(s.get("label"), f"span {i + 1}", LABEL_CHARS["span"])
    return out


def main(argv: list[str]) -> int:
    root = Path(__file__).resolve().parent / "bank"
    n = bad = 0
    for path in sorted(root.glob("*/*.json")):
        card = json.loads(path.read_text(encoding="utf-8"))
        if "diagram" not in card:
            continue
        n += 1
        for p in check_diagram(card["diagram"]):
            print(f"{card['id']}: {p}")
            bad += 1
    print(f"{n} diagrams, {bad} problems")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
