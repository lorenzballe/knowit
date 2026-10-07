"""Rules for a `beauty` scene: something beautiful, and the rule that makes it.

A living drawing fills the card (a flock, a sunflower, two orbits, waves, a
tree), with one line under it saying what simple rule governs it and one way
for the hand to play: touch the drawing, or drag the one number the rule
depends on (lib/models/scenes/beauty.dart documents the fields). What this
cannot check is that the rule is true and is the rule the drawing obeys; the
caption must say what the code draws, and the source must say where it comes
from.

    python3 tool/cards/scene_kinds/beauty.py card.json [...]
"""
from __future__ import annotations

import json
import math
import re
import sys

PIECES = ("flock", "phyllotaxis", "orbits", "waves", "fractal")
DIALLED = ("phyllotaxis", "orbits", "fractal")

CAPTION_CHARS = 90   # three lines under the drawing, two on the back of a card
HINT_CHARS = 34      # one line, small
REVEAL_CHARS = 90    # two lines, small
LABEL_CHARS = 24     # beside the dial's big figure
UNIT_CHARS = 8
COLOUR = re.compile(r"^#[0-9A-Fa-f]{6}$")

# What each piece may be given, and the range each setting must lie in.
PARAMS = {
    "flock": {"birds": (40, 400)},
    "phyllotaxis": {"seeds": (150, 1500)},
    "orbits": {"outer": (0, math.inf), "every": (1, 30), "span": (0, math.inf), "radii": None},
    "waves": {"wavelength": (0.04, 0.3), "gap": (0.05, 0.8)},
    "fractal": {"ratio": (0.5, 0.8), "depth": (5, 11)},
}
MAX_LINES = 1500     # orbits: lines kept on show at once


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def _text(obj, key, limit, p, where="scene", need=True):
    v = obj.get(key)
    if v is None and not need:
        return
    if not isinstance(v, str) or not v.strip():
        p.append(f"{where}.{key}: missing")
    elif len(v) > limit:
        p.append(f"{where}.{key}: {len(v)} chars, over {limit}")


def _dial(scene, piece, p) -> dict | None:
    d = scene.get("dial")
    if piece not in DIALLED:
        if d is not None:
            p.append(f"scene.dial: a {piece} is touched, not dialled")
        return None
    if not isinstance(d, dict):
        p.append(f"scene.dial: a {piece} needs one")
        return None
    _text(d, "label", LABEL_CHARS, p, "scene.dial")
    _text(d, "unit", UNIT_CHARS, p, "scene.dial", need=False)
    if not all(_num(d.get(k)) for k in ("value", "from", "to")):
        p.append("scene.dial: value, from and to are numbers")
        return None
    if not d["from"] < d["value"] < d["to"]:
        p.append("scene.dial: value must lie between from and to")
    if d.get("decimals", 1) not in (0, 1, 2):
        p.append("scene.dial.decimals: 0, 1 or 2")
    if piece == "phyllotaxis" and not (0 < d["from"] and d["to"] < 360):
        p.append("scene.dial: a turn between seeds lies inside 0° to 360°")
    if piece == "fractal" and not (0 <= d["from"] and d["to"] <= 180):
        p.append("scene.dial: a branching angle lies inside 0° to 180°")
    if piece == "orbits" and d["from"] <= 0:
        p.append("scene.dial: an orbital period must be positive")
    # The true value should sit well inside the range, so the reader can
    # drag away from it both ways and see what it is not.
    span = d["to"] - d["from"]
    if span > 0 and min(d["value"] - d["from"], d["to"] - d["value"]) < span * 0.15:
        p.append("scene.dial: value too near an end; leave room to drag both ways")
    return d


def check(scene: dict) -> list[str]:
    p: list[str] = []
    piece = scene.get("piece")
    if piece not in PIECES:
        return [f"scene.piece: one of {', '.join(PIECES)}"]
    _text(scene, "caption", CAPTION_CHARS, p)
    _text(scene, "hint", HINT_CHARS, p)
    _text(scene, "reveal", REVEAL_CHARS, p, need=False)
    if "reveal" in scene and scene.get("reveal") == scene.get("caption"):
        p.append("scene.reveal: says the caption again")
    dial = _dial(scene, piece, p)

    if "accent" in scene and not (isinstance(scene["accent"], str) and COLOUR.match(scene["accent"])):
        p.append("scene.accent: a colour written #RRGGBB")
    seed = scene.get("seed", 1)
    if not (isinstance(seed, int) and not isinstance(seed, bool) and 1 <= seed <= 0x7FFFFFFF):
        p.append("scene.seed: a whole number from 1")

    params = scene.get("params", {})
    if not isinstance(params, dict):
        return p + ["scene.params: an object"]
    allowed = PARAMS[piece]
    for key, v in params.items():
        if key not in allowed:
            p.append(f"scene.params.{key}: not a setting of a {piece}")
            continue
        rng = allowed[key]
        if rng is None:
            continue
        lo, hi = rng
        if not _num(v) or not lo <= v <= hi:
            p.append(f"scene.params.{key}: a number from {lo} to {hi}")

    if piece == "orbits" and dial is not None:
        outer = params.get("outer")
        if not _num(outer):
            p.append("scene.params.outer: the outer planet's year, in the dial's unit")
        elif outer <= dial["to"]:
            p.append("scene.params.outer: must be longer than the dial reaches")
        radii = params.get("radii", [0.723, 1.0])
        if not (isinstance(radii, list) and len(radii) == 2 and all(_num(r) for r in radii)
                and 0 < radii[0] < radii[1]):
            p.append("scene.params.radii: [inner, outer], inner smaller")
        every = params.get("every", 3)
        span = params.get("span", (outer if _num(outer) else 0) * 8)
        if _num(every) and _num(span) and every > 0:
            if span < every * 10:
                p.append("scene.params.span: at least ten lines' worth")
            if span / every > MAX_LINES:
                p.append(f"scene.params.span: {span / every:.0f} lines on show, over {MAX_LINES}")
    return p


if __name__ == "__main__":
    bad = 0
    for path in sys.argv[1:]:
        data = json.load(open(path))
        for card in data if isinstance(data, list) else [data]:
            scene = card.get("scene", card)
            if scene.get("type") != "beauty":
                continue
            problems = check(scene)
            print(card.get("id", path), "ok" if not problems else "")
            for problem in problems:
                bad += 1
                print("  !", problem)
    sys.exit(1 if bad else 0)
