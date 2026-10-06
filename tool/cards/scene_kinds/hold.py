"""Rules for a `hold` scene: hold for as long as you think something lasts.

The reader presses, holds, lets go; their hold is laid on a ruler beside the
true duration and up to three others (lib/models/scenes/hold.dart documents
the fields). The limits keep every label on one line at phone width and every
duration something a finger can hold and a replay can play in real time.

What this cannot check is whether the durations are true: every one is
measured or worked out from the card's own facts, and the source says where.
"""
from __future__ import annotations

import math

WHAT_CHARS = 34        # one line of small caps above the timecode
LABEL_CHARS = 26       # one line above a bar
SECONDS = (0.01, 60)   # the truth: a tap at the short end, a minute at most
COMPARE_SECONDS = (0.001, 60)
COMPARISONS = 3        # with "you" and the truth, five rows fit at 270 px
DISPLAYS = ("seconds", "ms", "timecode")
KEYS = {"type", "what", "seconds", "low", "high", "display", "comparisons"}


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def check(scene: dict) -> list[str]:
    p: list[str] = []
    for k in sorted(set(scene) - KEYS):
        p.append(f"scene.{k}: not a field of a hold scene")
    what = scene.get("what")
    if not isinstance(what, str) or not what.strip():
        p.append("scene.what: missing")
    elif len(what) > WHAT_CHARS:
        p.append(f"scene.what: {len(what)} chars, over {WHAT_CHARS}")

    s = scene.get("seconds")
    if not _num(s):
        p.append("scene.seconds: missing or not a number")
        s = None
    elif not SECONDS[0] <= s <= SECONDS[1]:
        p.append(f"scene.seconds: {s} outside {SECONDS[0]}–{SECONDS[1]}")

    if ("low" in scene) != ("high" in scene):
        p.append("scene.low/high: give both or neither")
    elif "low" in scene:
        lo, hi = scene["low"], scene["high"]
        if not (_num(lo) and _num(hi)):
            p.append("scene.low/high: not numbers")
        elif s is not None and not lo <= s <= hi:
            p.append(f"scene.seconds: {s} is not within {lo}–{hi}")
        elif lo == hi:
            p.append("scene.low/high: equal; leave them out for one value")
        elif lo <= 0 or hi > SECONDS[1]:
            p.append(f"scene.low/high: outside 0–{SECONDS[1]}")

    if scene.get("display", "seconds") not in DISPLAYS:
        p.append(f"scene.display: one of {', '.join(DISPLAYS)}")
    if scene.get("display") == "ms" and s is not None and s > 10:
        p.append("scene.display: ms is for durations under 10 s")

    comps = scene.get("comparisons", [])
    if not isinstance(comps, list) or len(comps) > COMPARISONS:
        p.append(f"scene.comparisons: a list of at most {COMPARISONS}")
        return p
    labels = set()
    for c in comps:
        if not isinstance(c, dict) or set(c) != {"label", "seconds"}:
            p.append("scene.comparisons: each is {label, seconds}")
            continue
        label, cs = c["label"], c["seconds"]
        if not isinstance(label, str) or not label.strip():
            p.append("scene.comparisons: a label is missing")
        elif len(label) > LABEL_CHARS:
            p.append(f"scene.comparisons: {label!r} is {len(label)} chars, over {LABEL_CHARS}")
        elif label in labels:
            p.append(f"scene.comparisons: {label!r} twice")
        else:
            labels.add(label)
        if not _num(cs) or not COMPARE_SECONDS[0] <= cs <= COMPARE_SECONDS[1]:
            p.append(f"scene.comparisons: {label!r} needs seconds in "
                     f"{COMPARE_SECONDS[0]}–{COMPARE_SECONDS[1]}")
        elif s is not None and cs == s:
            p.append(f"scene.comparisons: {label!r} is the truth again")
    return p
