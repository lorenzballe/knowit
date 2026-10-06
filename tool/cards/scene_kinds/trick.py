"""Rules for a `trick` scene: spot the trick in a chart, then see it honest.

The reader sees a chart as it was published, taps the part they think is
lying (headline, label, value axis, columns, the marks themselves), is told
why a wrong part is innocent, and once the trick is found the same numbers
redraw themselves honestly (lib/models/scenes/trick.dart has the fields,
the tricks and an example). The lengths are what fits a 360 px phone: the
headline in two lines of the clipping, the label on one, the lines under the
clipping in three or four.

What this cannot check is whether the chart is the one that ran, and the
numbers true. That is the writer's rule: the source shows the published
chart or its data, and the honest view follows from the same numbers.
"""
from __future__ import annotations

import math

TRICKS = ("truncated", "stretched", "window", "totals", "flipped", "dual", "pie")
REGIONS = ("headline", "label", "yaxis", "xaxis", "marks", "yaxis2")
FIELDS = {
    "type", "trick", "chart", "outlet", "headline", "honest", "label",
    "honestLabel", "unit", "honestUnit", "decimals", "honestDecimals",
    "columns", "values", "from", "to", "honestFrom", "honestTo", "window",
    "per", "perScale", "values2", "from2", "to2", "series", "spot", "ask",
    "found", "miss", "misses", "name", "lesson",
}

OUTLET_CHARS = 28     # one line of small caps over the headline
HEADLINE_CHARS = 48   # two lines of the clipping's headline
LABEL_CHARS = 34      # one line of small caps over the chart
UNIT_CHARS = 6        # printed with every value
SERIES_CHARS = 14     # a series' name beside its line
ASK_CHARS = 40        # two large lines under the clipping
FOUND_CHARS = 70      # two or three large lines under the clipping
MISS_CHARS = 80       # four lines beside "Show me"
NAME_CHARS = 24       # one large line
LESSON_CHARS = 100    # three lines under the name
COLUMNS = {"bars": (2, 8), "line": (2, 60), "pie": (2, 6)}
COLUMN_CHARS = {"bars": 12, "line": 6, "pie": 18}
BAR_LABEL_TOTAL = 40  # every bar's label side by side across the plot

DEFAULT_SPOT = {
    "truncated": ["yaxis"], "stretched": ["yaxis"], "flipped": ["yaxis"],
    "window": ["xaxis"], "totals": ["label"], "dual": ["yaxis", "yaxis2"],
    "pie": ["marks"],
}


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def _text(v) -> bool:
    return isinstance(v, str) and bool(v.strip())


def _nums(v) -> bool:
    return isinstance(v, list) and all(_num(x) for x in v)


def check(scene: dict) -> list[str]:
    p: list[str] = []
    for key in scene:
        if key not in FIELDS:
            p.append(f"scene: unknown field {key!r}")

    trick = scene.get("trick")
    if trick not in TRICKS:
        return p + [f"scene.trick: one of {', '.join(TRICKS)}"]

    chart = scene.get("chart")
    if trick == "pie":
        form = "pie"
        if chart not in (None, "pie"):
            p.append("scene.chart: a pie trick is a pie")
    elif trick == "dual":
        form = "line"
        if chart not in (None, "line"):
            p.append("scene.chart: a dual chart is two lines")
    elif chart in ("bars", "line"):
        form = chart
    elif chart is None:
        form = "bars" if trick in ("truncated", "totals") else "line"
    else:
        return p + ["scene.chart: bars or line"]

    def text(key: str, limit: int, need: bool = True) -> None:
        v = scene.get(key)
        if v is None and not need:
            return
        if not _text(v):
            p.append(f"scene.{key}: missing")
        elif len(v) > limit:
            p.append(f"scene.{key}: {len(v)} chars, over {limit}")

    text("outlet", OUTLET_CHARS, need=False)
    text("headline", HEADLINE_CHARS)
    text("honest", HEADLINE_CHARS)
    text("label", LABEL_CHARS)
    text("honestLabel", LABEL_CHARS, need=trick == "totals")
    text("ask", ASK_CHARS, need=False)
    text("found", FOUND_CHARS)
    text("miss", MISS_CHARS)
    text("name", NAME_CHARS)
    text("lesson", LESSON_CHARS)
    if _text(scene.get("headline")) and scene.get("headline") == scene.get("honest"):
        p.append("scene.honest: the same as the headline; the honest chart says something else")
    for key in ("unit", "honestUnit"):
        v = scene.get(key, "")
        if not isinstance(v, str) or len(v) > UNIT_CHARS:
            p.append(f"scene.{key}: a string of at most {UNIT_CHARS} chars")
    for key in ("decimals", "honestDecimals"):
        if key in scene and scene[key] not in (0, 1, 2):
            p.append(f"scene.{key}: 0, 1 or 2")

    cols, vals = scene.get("columns"), scene.get("values")
    lo, hi = COLUMNS[form]
    if not isinstance(cols, list) or not all(_text(c) for c in cols):
        return p + ["scene.columns: a list of labels"]
    if not lo <= len(cols) <= hi:
        return p + [f"scene.columns: between {lo} and {hi} for a {form} chart"]
    for c in cols:
        if len(c) > COLUMN_CHARS[form]:
            p.append(f"scene.columns: {c!r} is over {COLUMN_CHARS[form]} chars")
    if form == "bars" and sum(len(c) for c in cols) > BAR_LABEL_TOTAL:
        p.append(f"scene.columns: {sum(len(c) for c in cols)} chars in all, over "
                 f"{BAR_LABEL_TOTAL} side by side under the bars")
    if not _nums(vals) or len(vals) != len(cols):
        return p + ["scene.values: one number per column"]

    frm, to = scene.get("from"), scene.get("to")
    for key in ("from", "to", "honestFrom", "honestTo", "from2", "to2", "perScale"):
        if key in scene and not _num(scene[key]):
            p.append(f"scene.{key}: not a number")
    vlo, vhi = min(vals), max(vals)

    if trick == "truncated":
        if not _num(frm):
            p.append("scene.from: where the cut axis starts")
        elif not 0 < frm <= vlo:
            p.append("scene.from: above zero and at or below the smallest value")
        elif _num(to) and to > frm and vhi > 0:
            # The trick has to show: the drawn ratio of the bars must be far
            # from the true one, or there is nothing to spot.
            drawn = (vhi - frm) / max(vlo - frm, (to - frm) * 0.02)
            true = vhi / vlo if vlo > 0 else math.inf
            if drawn < true * 1.5:
                p.append("scene.from: cuts too little off; the bars look almost fair")
        if form == "line":
            p.append("scene.chart: a line need not start at zero; a truncated "
                     "axis is a trick on bars")
    elif trick == "stretched":
        need = ("from", "to", "honestFrom", "honestTo")
        if not all(_num(scene.get(k)) for k in need):
            p.append("scene: stretched needs from, to, honestFrom and honestTo")
        else:
            span, fair = to - frm, scene["honestTo"] - scene["honestFrom"]
            if span <= 0 or fair <= 0:
                p.append("scene: to must be above from, honestTo above honestFrom")
            elif 0.4 < span / fair < 2.5:
                p.append("scene.from/to: barely different from the honest range; "
                         "nothing is stretched")
            if not scene["honestFrom"] <= vlo or not vhi <= scene["honestTo"]:
                p.append("scene.honestFrom/honestTo: must hold every value")
    elif trick == "window":
        w = scene.get("window")
        if not (isinstance(w, list) and len(w) == 2 and all(isinstance(x, int) for x in w)):
            p.append("scene.window: [first, last] column")
        elif not 0 <= w[0] < w[1] < len(cols):
            p.append("scene.window: two columns or more, inside the series")
        elif w == [0, len(cols) - 1]:
            p.append("scene.window: keeps every column, so hides nothing")
        elif (w[1] - w[0] + 1) * 2 > len(cols) + 1:
            p.append("scene.window: keeps more than half the series; the hidden "
                     "part should be the bigger story")
    elif trick == "totals":
        per = scene.get("per")
        if not _nums(per) or len(per) != len(cols) or any(x <= 0 for x in per):
            p.append("scene.per: one base above zero per column")
        else:
            scale = scene.get("perScale", 1)
            rates = [v / b * scale for v, b in zip(vals, per)]
            if sorted(range(len(vals)), key=lambda i: vals[i]) == \
                    sorted(range(len(rates)), key=lambda i: rates[i]):
                p.append("scene.per: the rates come out in the same order as the "
                         "totals; dividing changes nothing to see")
        if form != "bars":
            p.append("scene.chart: totals are compared as bars")
    elif trick == "dual":
        v2 = scene.get("values2")
        if not _nums(v2) or len(v2) != len(cols):
            p.append("scene.values2: one number per column")
        need = ("from", "to", "from2", "to2")
        if not all(_num(scene.get(k)) for k in need):
            p.append("scene: dual needs from, to, from2 and to2")
        elif _nums(v2) and not all(scene["from2"] <= v <= scene["to2"] for v in v2):
            p.append("scene.values2: must lie between from2 and to2")
        s = scene.get("series")
        if not (isinstance(s, list) and len(s) == 2 and all(_text(x) for x in s)):
            p.append("scene.series: the two series' names")
        elif any(len(x) > SERIES_CHARS for x in s):
            p.append(f"scene.series: a name over {SERIES_CHARS} chars")
    elif trick == "pie":
        if any(v <= 0 or v > 100 for v in vals):
            p.append("scene.values: a pie's are percentages, above 0 and up to 100")
        elif sum(vals) <= 100:
            p.append("scene.values: they add up to 100% or less; the pie plays no trick")

    if trick in ("truncated", "stretched", "window", "flipped", "dual") and \
            _num(frm) and _num(to):
        if to <= frm:
            p.append("scene.to: must be above from")
        else:
            kept = vals
            w = scene.get("window")
            if trick == "window" and isinstance(w, list) and len(w) == 2:
                kept = vals[w[0]:w[1] + 1]
            if any(v < frm or v > to for v in kept):
                p.append("scene.values: must lie between from and to")

    # Where the trick is, and the lines for the parts that are not it.
    regions = ["headline", "label", "marks"]
    if form != "pie":
        regions += ["yaxis", "xaxis"]
    if trick == "dual":
        regions.append("yaxis2")
    spot = scene.get("spot", DEFAULT_SPOT[trick])
    spots = spot if isinstance(spot, list) else [spot]
    if not spots or any(s not in regions for s in spots):
        p.append(f"scene.spot: one or more of {', '.join(regions)}")
    misses = scene.get("misses", {})
    if not isinstance(misses, dict):
        p.append("scene.misses: {region: line}")
    else:
        for k, v in misses.items():
            if k not in regions:
                p.append(f"scene.misses: {k!r} is not a region of this chart")
            elif k in spots:
                p.append(f"scene.misses: {k!r} is where the trick is, it is never a miss")
            if not _text(v):
                p.append(f"scene.misses.{k}: missing")
            elif len(v) > MISS_CHARS:
                p.append(f"scene.misses.{k}: {len(v)} chars, over {MISS_CHARS}")
    return p
