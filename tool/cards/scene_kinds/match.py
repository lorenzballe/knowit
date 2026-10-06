"""Rules for a `match` scene: join each idea on the left to what it explains.

The reader draws a line from every left item to a right item, locks it in,
and the right column slides until each item sits beside its true partner,
with a tick or a cross on every rung and the pair most people miss turned
over first (lib/models/scenes/match.dart has the fields and an example).

The limits are what fits on a 360 px phone, where the scene is about 276 px
wide and, on the back of an asking card, 270 px tall: the left word set
large in a column under half the width, the right text in two or three
lines beside it, a note in two lines under the ladder.

What this cannot check is whether each pair is true, and whether the
pairing takes thought: two right items that both fit one idea make the card
a coin toss. That is the writer's rule, and the source backs every note.
"""
from __future__ import annotations

TITLE_CHARS = {"leftTitle": 16, "rightTitle": 18}
LEFT_CHARS = 22       # the idea, at most two lines in the narrow column
LEFT_WORD_CHARS = 12  # a single word must fit the column whole
RIGHT_CHARS = 48      # two lines at the smallest size, three at most
RIGHT_CHARS_FIVE = 40  # five rungs leave each one only two lines
NOTE_CHARS = 76       # two lines under the ladder
PAIRS = (3, 5)
PAIR_KEYS = ("left", "right", "note", "missed")


def _text(v) -> bool:
    return isinstance(v, str) and bool(v.strip())


def check(scene: dict) -> list[str]:
    p: list[str] = []
    for key, limit in TITLE_CHARS.items():
        v = scene.get(key)
        if not _text(v):
            p.append(f"scene.{key}: missing")
        elif len(v) > limit:
            p.append(f"scene.{key}: {len(v)} chars, over {limit}")
    for key in scene:
        if key not in ("type", "leftTitle", "rightTitle", "pairs", "order"):
            p.append(f"scene: unknown field {key!r}")

    pairs = scene.get("pairs")
    if not isinstance(pairs, list) or not (PAIRS[0] <= len(pairs) <= PAIRS[1]):
        return p + [f"scene.pairs: between {PAIRS[0]} and {PAIRS[1]}"]
    n = len(pairs)
    right_limit = RIGHT_CHARS_FIVE if n == 5 else RIGHT_CHARS
    lefts: list[str] = []
    rights: list[str] = []
    missed = 0
    for i, it in enumerate(pairs):
        where = f"scene.pairs[{i}]"
        if not isinstance(it, dict):
            p.append(f"{where}: not an object")
            continue
        left, right, note = it.get("left"), it.get("right"), it.get("note")
        if not _text(left):
            p.append(f"{where}.left: missing")
        else:
            lefts.append(left.strip().lower())
            if len(left) > LEFT_CHARS:
                p.append(f"{where}.left: {len(left)} chars, over {LEFT_CHARS}")
            long = [w for w in left.split() if len(w) > LEFT_WORD_CHARS]
            if long:
                p.append(f"{where}.left: {long[0]!r} is over {LEFT_WORD_CHARS} "
                         "chars and would not fit the column whole")
        if not _text(right):
            p.append(f"{where}.right: missing")
        else:
            rights.append(right.strip().lower())
            if len(right) > right_limit:
                p.append(f"{where}.right: {len(right)} chars, over {right_limit}"
                         + (" with five pairs" if n == 5 else ""))
        if not _text(note):
            p.append(f"{where}.note: missing; every rung explains itself")
        elif len(note) > NOTE_CHARS:
            p.append(f"{where}.note: {len(note)} chars, over {NOTE_CHARS}")
        m = it.get("missed", False)
        if not isinstance(m, bool):
            p.append(f"{where}.missed: true or false")
        elif m:
            missed += 1
        for key in it:
            if key not in PAIR_KEYS:
                p.append(f"{where}: unknown field {key!r}")
    if len(set(lefts)) != len(lefts) or len(set(rights)) != len(rights):
        p.append("scene.pairs: two items share a text")
    if missed != 1:
        p.append(f"scene.pairs: {missed} marked missed; mark the one pair most "
                 "people get wrong, which the reveal opens on")

    order = scene.get("order")
    if order is not None:
        if (not isinstance(order, list) or len(order) != n
                or not all(isinstance(v, int) and not isinstance(v, bool) for v in order)
                or sorted(order) != list(range(n))):
            p.append(f"scene.order: a reordering of 0..{n - 1}")
        else:
            fixed = sum(1 for k, v in enumerate(order) if k == v)
            if fixed > 1:
                p.append(f"scene.order: {fixed} items start beside their partner; "
                         "at most one, or the reader starts half done")
    return p
