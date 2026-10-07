"""Rules for a `news` scene: a piece of news, explained in three taps.

A headline sits at the top as a clipping, with its outlet and date; three
taps open what happened, why, and either what it means for the reader or a
past case with the same mechanism (lib/models/scenes/news.dart,
lib/widgets/scenes/news_view.dart).

The lengths keep the clipping, the bars, the tallest step and the button
inside 270 px on a 360 px phone, the back of a card that asks. News goes
stale: `expires` is required, and no later than 120 days after the card was
written, so a card cannot outlive the week it explains by more than a season.
The dealer skips a card from the day after it expires (lib/data/
pills_repository.dart, functions/src/deal.ts).

What this cannot check is whether the "why" really is the cause and whether
it will still be true on the day it expires: that is the writer's rule, and
the reason to pick news whose explanation does not hang on what happens
tomorrow.
"""
from __future__ import annotations

from datetime import date

HEADLINE_CHARS = 72   # three lines at the clipping's smallest type
OUTLET_CHARS = 26     # one line on the masthead beside the date
LABEL_CHARS = 24      # a line of the contents, and the button's words
TEXT_CHARS = 140      # a step, four lines on a small phone
FIGURE_CHARS = 9      # a number set large ("$6.23", "×2")
THEN_HEADLINE_CHARS = 56  # beside the year, in the old clipping
THEN_LINE_CHARS = 120
STEPS = 3
EXPIRES_MAX_DAYS = 120


def _day(v) -> date | None:
    if not isinstance(v, str) or len(v) != 10:
        return None
    try:
        return date.fromisoformat(v)
    except ValueError:
        return None


def _text(p: list[str], obj: dict, key: str, where: str, limit: int) -> None:
    v = obj.get(key)
    if not isinstance(v, str) or not v.strip():
        p.append(f"scene.{where}{key}: missing")
    elif len(v) > limit:
        p.append(f"scene.{where}{key}: {len(v)} chars, over {limit}")


def check(scene: dict, written: str | None = None) -> list[str]:
    """The scene's rules; with the card's `written` date, the expiry too."""
    p: list[str] = []
    _text(p, scene, "headline", "", HEADLINE_CHARS)
    _text(p, scene, "outlet", "", OUTLET_CHARS)
    reported = _day(scene.get("date"))
    if reported is None:
        p.append("scene.date: a yyyy-mm-dd date")

    panels = scene.get("panels")
    if not isinstance(panels, list) or not 2 <= len(panels) <= 3:
        p.append("scene.panels: 2 or 3")
        panels = []
    labels = []
    figures = 0
    for i, panel in enumerate(panels):
        where = f"panels[{i}]."
        if not isinstance(panel, dict):
            p.append(f"scene.panels[{i}]: not an object")
            continue
        _text(p, panel, "label", where, LABEL_CHARS)
        _text(p, panel, "text", where, TEXT_CHARS)
        labels.append(str(panel.get("label", "")).strip().lower())
        figure = panel.get("figure", "")
        if not isinstance(figure, str) or len(figure) > FIGURE_CHARS:
            p.append(f"scene.{where}figure: a string of at most {FIGURE_CHARS} chars")
        elif figure.strip():
            figures += 1
            if not any(c.isdigit() for c in figure):
                p.append(f"scene.{where}figure: {figure!r} has no number in it")
        for key in panel:
            if key not in ("label", "text", "figure"):
                p.append(f"scene.{where[:-1]}: unknown field {key!r}")
    if figures > 2:
        p.append("scene.panels: at most two figures, or none stands out")

    then = scene.get("then")
    if then is not None:
        if not isinstance(then, dict):
            p.append("scene.then: {label, year, headline, line}")
        else:
            _text(p, then, "label", "then.", LABEL_CHARS)
            _text(p, then, "headline", "then.", THEN_HEADLINE_CHARS)
            _text(p, then, "line", "then.", THEN_LINE_CHARS)
            labels.append(str(then.get("label", "")).strip().lower())
            year = then.get("year")
            if not isinstance(year, int) or isinstance(year, bool):
                p.append("scene.then.year: a whole year")
            elif not 1000 <= year <= (reported.year if reported else 9999):
                p.append(f"scene.then.year: {year} is not before the news")
            elif reported and year == reported.year:
                p.append("scene.then.year: the past case is from the same year")
            for key in then:
                if key not in ("label", "year", "headline", "line"):
                    p.append(f"scene.then: unknown field {key!r}")
    steps = len(panels) + (1 if then is not None else 0)
    if panels and steps != STEPS:
        p.append(f"scene: {steps} steps; three taps, so three panels or two and `then`")
    if len(set(labels)) != len(labels):
        p.append("scene: two steps have the same label")

    expires = _day(scene.get("expires"))
    if expires is None:
        p.append("scene.expires: required, a yyyy-mm-dd date")
    else:
        if reported and expires < reported:
            p.append("scene.expires: before the news was reported")
        if written is not None:
            w = _day(written)
            if w is None:
                p.append("written: not a yyyy-mm-dd date, so expires cannot be checked")
            elif expires <= w:
                p.append(f"scene.expires: {expires} is not after written {w}")
            elif (expires - w).days > EXPIRES_MAX_DAYS:
                p.append(f"scene.expires: {(expires - w).days} days after written, "
                         f"over {EXPIRES_MAX_DAYS}")

    for key in scene:
        if key not in ("type", "headline", "outlet", "date", "panels", "then", "expires"):
            p.append(f"scene: unknown field {key!r}")
    return p
