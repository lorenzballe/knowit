"""The rules a card's `scene` has to keep, checked before the app sees it.

A scene is something the reader plays with before the answer
(lib/models/scene.dart, lib/widgets/scene_view.dart). Today there is one
kind, `slider`: the reader moves one quantity and watches another follow it
along measured points, with a line that changes at the moments that matter.

What this cannot check is whether the numbers are true. That is the writer's
rule and the critic's: every point is measured or worked out from the card's
own facts, and the source says where.

    python3 tool/cards/scenes.py            # every scene in the bank
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

KINDS = ("slider",)
LABEL_CHARS = 34   # control and readout, on one line at phone width
UNIT_CHARS = 14
NOTE_CHARS = 90    # two lines under the slider
POINTS = (2, 40)
NOTES = (1, 5)


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def check_scene(scene) -> list[str]:
    if not isinstance(scene, dict):
        return ["scene: not an object"]
    kind = scene.get("type")
    if kind not in KINDS:
        return [f"scene: unknown type {kind!r}"]
    p: list[str] = []
    for key in ("control", "readout"):
        v = scene.get(key)
        if not isinstance(v, str) or not v.strip():
            p.append(f"scene.{key}: missing")
        elif len(v) > LABEL_CHARS:
            p.append(f"scene.{key}: {len(v)} chars, over {LABEL_CHARS}")
    for key in ("controlUnit", "readoutUnit"):
        v = scene.get(key, "")
        if not isinstance(v, str) or len(v) > UNIT_CHARS:
            p.append(f"scene.{key}: not a short string")
    pts = scene.get("points")
    if not isinstance(pts, list) or not (POINTS[0] <= len(pts) <= POINTS[1]):
        return p + [f"scene.points: between {POINTS[0]} and {POINTS[1]} [x, y] pairs"]
    if not all(isinstance(q, list) and len(q) == 2 and _num(q[0]) and _num(q[1]) for q in pts):
        return p + ["scene.points: every point is [x, y], both numbers"]
    xs = [q[0] for q in pts]
    if any(b <= a for a, b in zip(xs, xs[1:])):
        p.append("scene.points: x must rise strictly")
    lo, hi = xs[0], xs[-1]
    for key in ("start", "step"):
        if key in scene and not _num(scene[key]):
            p.append(f"scene.{key}: not a number")
    if _num(scene.get("start", lo)) and not lo <= scene.get("start", lo) <= hi:
        p.append("scene.start: outside the points")
    if _num(scene.get("step", 1)) and scene.get("step", 1) <= 0:
        p.append("scene.step: must be positive")
    notes = scene.get("notes", [])
    if not isinstance(notes, list) or not (NOTES[0] <= len(notes) <= NOTES[1]):
        p.append(f"scene.notes: between {NOTES[0]} and {NOTES[1]}")
    else:
        for n in notes:
            if not isinstance(n, dict) or not _num(n.get("at")) or not isinstance(n.get("text"), str):
                p.append("scene.notes: each is {at, text}")
                continue
            if not lo <= n["at"] <= hi:
                p.append(f"scene.notes: at {n['at']} is outside the points")
            if len(n["text"]) > NOTE_CHARS:
                p.append(f"scene.notes: {len(n['text'])} chars, over {NOTE_CHARS}")
    if "decimals" in scene and scene["decimals"] not in (0, 1, 2):
        p.append("scene.decimals: 0, 1 or 2")
    return p


def main() -> int:
    bad = 0
    for f in sorted(Path(__file__).parent.joinpath("bank").glob("*/*.json")):
        card = json.loads(f.read_text())
        if "scene" in card:
            for problem in check_scene(card["scene"]):
                bad += 1
                print(f"{card['id']}: {problem}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
