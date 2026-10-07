"""Rules for a `count` scene: bet the number (lib/models/scenes/count.dart).

The reader bets on an order of magnitude, then the true number counts up
while dots fill a field. What this cannot check is whether the number is
true, or whether each note tells the truth about how far off its bet is:
that is the writer's rule and the critic's.

The limits are set by a 360-wide phone: chips share one row, so their
labels are short and wrap at most once; the spaced label under the number
runs to two lines; a note is two lines of body text.
"""
from __future__ import annotations

import math

UNIT_CHARS = 40       # spaced capitals under the number, two lines
PREFIX_CHARS = 3      # "$", "€", "CHF"
EACH_LABEL_CHARS = 34 # the key to the dots, one line
COMPARE_CHARS = 40    # one line of body text on a 360 phone
LABEL_CHARS = 14      # a chip, two lines at most
LINE_CHARS = 9        # either line of a chip, broken at the first space
NOTE_CHARS = 90       # two lines under the chips
OPTIONS = (3, 4)
DOTS = (1, 2500)      # past 2,500 a dot is a speck of grey
MIN_RATIO = 3         # neighbouring bets at least this far apart


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def _text(scene: dict, key: str, limit: int, p: list[str], required: bool) -> None:
    v = scene.get(key)
    if v is None and not required:
        return
    if not isinstance(v, str) or not v.strip():
        p.append(f"scene.{key}: missing" if required else f"scene.{key}: not text")
    elif len(v) > limit:
        p.append(f"scene.{key}: {len(v)} chars, over {limit}")


def check(scene: dict) -> list[str]:
    p: list[str] = []
    _text(scene, "unit", UNIT_CHARS, p, True)
    _text(scene, "eachLabel", EACH_LABEL_CHARS, p, True)
    _text(scene, "prefix", PREFIX_CHARS, p, False)
    _text(scene, "compare", COMPARE_CHARS, p, False)
    if scene.get("arrange", "cloud") not in ("cloud", "grid"):
        p.append("scene.arrange: cloud or grid")
    if "decimals" in scene and scene["decimals"] not in (0, 1, 2):
        p.append("scene.decimals: 0, 1 or 2")

    answer, each = scene.get("answer"), scene.get("each")
    if not _num(answer) or answer <= 0:
        p.append("scene.answer: a number above 0")
        answer = None
    if not _num(each) or each <= 0:
        p.append("scene.each: a number above 0")
        each = None
    if answer is not None and each is not None:
        dots = round(answer / each)
        if not DOTS[0] <= dots <= DOTS[1]:
            p.append(f"scene.each: answer / each makes {dots} dots, keep it {DOTS[0]} to {DOTS[1]}")
        if scene.get("arrange") == "grid" and dots > 200:
            p.append(f"scene.arrange: grid is for counting one by one, {dots} dots is a cloud")

    opts = scene.get("options")
    if not isinstance(opts, list) or not OPTIONS[0] <= len(opts) <= OPTIONS[1]:
        return p + [f"scene.options: {OPTIONS[0]} or {OPTIONS[1]} bets"]
    values = []
    for i, o in enumerate(opts):
        where = f"scene.options[{i}]"
        if not isinstance(o, dict):
            p.append(f"{where}: not an object")
            continue
        label, value, note = o.get("label"), o.get("value"), o.get("note")
        if not isinstance(label, str) or not label.strip():
            p.append(f"{where}.label: missing")
        else:
            if len(label) > LABEL_CHARS:
                p.append(f"{where}.label: {len(label)} chars, over {LABEL_CHARS}")
            # The chip breaks the label at its first space, nowhere else.
            if any(len(line) > LINE_CHARS for line in label.split(" ", 1)):
                p.append(f"{where}.label: a line over {LINE_CHARS} chars; the chip breaks at the first space")
        if not isinstance(note, str) or not note.strip():
            p.append(f"{where}.note: missing")
        elif len(note) > NOTE_CHARS:
            p.append(f"{where}.note: {len(note)} chars, over {NOTE_CHARS}")
        if not _num(value) or value < 0:
            p.append(f"{where}.value: a number, 0 or more")
        else:
            values.append(value)
    if len(values) == len(opts):
        for a, b in zip(values, values[1:]):
            if b <= a:
                p.append("scene.options: values must rise")
                break
            if a > 0 and b / a < MIN_RATIO:
                p.append(f"scene.options: {a} and {b} are too close to bet between; keep them {MIN_RATIO}x apart")
        if answer is not None:
            pos = [v for v in values if v > 0]
            if pos and not pos[0] / 10 <= answer <= pos[-1] * 10:
                p.append("scene.answer: more than a zero outside every bet; widen the bets")
    return p
