"""Rules for a `timeline` scene: place it in time (lib/models/scenes/timeline.dart).

The reader drags each event to the year they believe, one lane per event
over a shared axis, then the true positions slide in with the gap drawn.
What this cannot check is whether the years are true, or whether a note
names the event people really misplace: that is the writer's rule and the
critic's, and the source says where the dates come from.

The limits are set by a 360-wide phone: a label shares its lane's line with
the year ("2560 BC", "66 million years ago"), so it is short; a note is
said under the lanes in at most three lines beside the try-again button; and
on the back of an asking card the lanes get 270 points between them, which
holds five.
"""
from __future__ import annotations

import math

EVENTS = (3, 5)
LABEL_CHARS = 26        # beside its year, one line, on a 360 phone
LABEL_AGO_CHARS = 20    # beside "300,000 years ago", which is wider
NOTE_CHARS = 90         # three lines under the lanes, beside the button
UNIT_CHARS = 12         # "years ago"
YEARS_SPAN = (10, 20000)
AGO_DECADES = (1, 9)    # powers of ten across a deep-time axis
CROWD = 0.03            # two truths this close look like one mark


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def _astro(y: float) -> float:
    """BC years counted with a zero, so differences are real durations."""
    return y + 1 if y < 0 else y


def check(scene: dict) -> list[str]:
    p: list[str] = []
    axis = scene.get("axis", "years")
    if axis not in ("years", "ago"):
        return ['scene.axis: "years" or "ago"']
    years = axis == "years"
    lo, hi = scene.get("from"), scene.get("to")
    if not (_num(lo) and _num(hi)):
        return p + ["scene.from / scene.to: both numbers"]
    if years:
        if not (isinstance(lo, int) and isinstance(hi, int)):
            p.append("scene.from / scene.to: whole years")
        if lo == 0 or hi == 0:
            p.append("scene.from / scene.to: there is no year 0")
        span = _astro(hi) - _astro(lo)
        if not YEARS_SPAN[0] <= span <= YEARS_SPAN[1]:
            p.append(f"scene: the axis spans {span:g} years, outside {YEARS_SPAN}")
        if "unit" in scene:
            p.append("scene.unit: only for an \"ago\" axis; a calendar says BC and AD itself")
    else:
        if not (hi > 0 and lo > hi):
            return p + ["scene.from / scene.to: years ago, from older to newer, both above 0"]
        decades = math.log10(lo / hi)
        if not AGO_DECADES[0] <= decades <= AGO_DECADES[1]:
            p.append(f"scene: {decades:.1f} powers of ten, outside {AGO_DECADES}")
        unit = scene.get("unit")
        if not isinstance(unit, str) or not unit.strip():
            p.append('scene.unit: missing (e.g. "years ago")')
        elif len(unit) > UNIT_CHARS:
            p.append(f"scene.unit: {len(unit)} chars, over {UNIT_CHARS}")
    if p and any("numbers" in x for x in p):
        return p

    def t(v: float) -> float:
        if years:
            a, b = _astro(lo), _astro(hi)
            return (_astro(v) - a) / (b - a)
        return (math.log10(lo) - math.log10(v)) / (math.log10(lo) - math.log10(hi))

    events = scene.get("events")
    if not isinstance(events, list) or not EVENTS[0] <= len(events) <= EVENTS[1]:
        return p + [f"scene.events: between {EVENTS[0]} and {EVENTS[1]}"]
    key = "year" if years else "ago"
    limit = LABEL_CHARS if years else LABEL_AGO_CHARS
    seen: set[str] = set()
    ts: list[tuple[float, str]] = []
    notes = 0
    for e in events:
        if not isinstance(e, dict):
            p.append("scene.events: each is {label, %s, note?}" % key)
            continue
        label = e.get("label")
        if not isinstance(label, str) or not label.strip():
            p.append("scene.events: a label is missing")
            continue
        if len(label) > limit:
            p.append(f"scene.events: {label!r} is {len(label)} chars, over {limit}")
        if label in seen:
            p.append(f"scene.events: {label!r} twice")
        seen.add(label)
        other = "ago" if years else "year"
        if other in e:
            p.append(f"scene.events: {label!r} gives {other!r} on a {axis!r} axis")
        v = e.get(key)
        if not _num(v) or (years and not isinstance(v, int)):
            p.append(f"scene.events: {label!r} needs a whole {key!r}" if years
                     else f"scene.events: {label!r} needs a number {key!r}")
            continue
        if years and v == 0:
            p.append(f"scene.events: {label!r}: there is no year 0")
            continue
        if not years and v <= 0:
            p.append(f"scene.events: {label!r}: ago must be above 0")
            continue
        at = t(v)
        if not 0 <= at <= 1:
            p.append(f"scene.events: {label!r} is off the axis")
            continue
        ts.append((at, label))
        note = e.get("note")
        if note is not None:
            if not isinstance(note, str) or not note.strip():
                p.append(f"scene.events: {label!r} has an empty note")
            elif len(note) > NOTE_CHARS:
                p.append(f"scene.events: {label!r} note is {len(note)} chars, over {NOTE_CHARS}")
            else:
                notes += 1
    if notes == 0:
        p.append("scene.events: give the event people misplace most a note")
    ts.sort()
    for (a, la), (b, lb) in zip(ts, ts[1:]):
        if b - a < CROWD:
            p.append(f"scene.events: {la!r} and {lb!r} land on one spot; nothing to place")
    if ts and max(abs(a - 0.5) for a, _ in ts) < 0.1:
        p.append("scene.events: all near the middle, where the knobs start; widen or shift the axis")
    return p
