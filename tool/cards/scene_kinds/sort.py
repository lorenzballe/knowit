"""Rules for a `sort` scene: swipe a short deck of slips into two piles.

The reader throws each slip left or right, the slip turns over to say where
it belongs, and at the end the piles settle (lib/models/scenes/sort.dart has
the fields and an example). The limits are what fits on a small phone: the
word large on the slip, the note in two lines under it, the verdict in three
lines on the back, and every slip as a mini in a pile column at the end.

What this cannot check is whether each slip is in its true pile. That is the
writer's rule: every verdict is a fact the card's source supports.
"""
from __future__ import annotations

PILE_CHARS = 12      # a pile's name, large on a half-width tray
TAG_CHARS = 26       # the line at the head of every slip
TEXT_CHARS = 22      # the slip's word, also a mini at the end
NOTE_CHARS = 70      # two lines under the word
VERDICT_CHARS = 84   # three lines on the back of the slip
ITEMS = (4, 8)
SIDES = ("left", "right")


def _text(v) -> bool:
    return isinstance(v, str) and bool(v.strip())


def check(scene: dict) -> list[str]:
    p: list[str] = []
    names = []
    for key in SIDES:
        v = scene.get(key)
        if not _text(v):
            p.append(f"scene.{key}: missing")
        elif len(v) > PILE_CHARS:
            p.append(f"scene.{key}: {len(v)} chars, over {PILE_CHARS}")
        else:
            names.append(v.strip().lower())
    if len(names) == 2 and names[0] == names[1]:
        p.append("scene.left and scene.right: the two piles need different names")
    tag = scene.get("tag", "")
    if not isinstance(tag, str) or len(tag) > TAG_CHARS:
        p.append(f"scene.tag: a string of at most {TAG_CHARS} chars")

    items = scene.get("items")
    if not isinstance(items, list) or not (ITEMS[0] <= len(items) <= ITEMS[1]):
        return p + [f"scene.items: between {ITEMS[0]} and {ITEMS[1]} slips"]
    seen: set[str] = set()
    piles = {side: 0 for side in SIDES}
    for i, it in enumerate(items):
        where = f"scene.items[{i}]"
        if not isinstance(it, dict):
            p.append(f"{where}: not an object")
            continue
        for key, limit in (("text", TEXT_CHARS), ("verdict", VERDICT_CHARS)):
            v = it.get(key)
            if not _text(v):
                p.append(f"{where}.{key}: missing")
            elif len(v) > limit:
                p.append(f"{where}.{key}: {len(v)} chars, over {limit}")
        note = it.get("note", "")
        if not isinstance(note, str) or len(note) > NOTE_CHARS:
            p.append(f"{where}.note: a string of at most {NOTE_CHARS} chars")
        if it.get("pile") not in SIDES:
            p.append(f"{where}.pile: \"left\" or \"right\"")
        else:
            piles[it["pile"]] += 1
        if _text(it.get("text")):
            key = it["text"].strip().lower()
            if key in seen:
                p.append(f"{where}.text: {it['text']!r} is in the deck twice")
            seen.add(key)
    for side, n in piles.items():
        if n == 0:
            p.append(f"scene.items: no slip belongs on the {side} pile")
    return p
