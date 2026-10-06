"""Rules for a `clues` scene: guess from evidence laid down one card at a time.

The reader sees 3 to 5 suspects and turns clues over one by one; naming the
answer early keeps more points. At the end each wrong suspect is struck off
by the number of the clue that ruled it out, and the decisive clue (the one
that strikes the last rival) turns over with the `why` line beneath
(lib/models/scenes/clues.dart has the fields and an example).

The lengths are what fits on a 360 px phone: an option on half the row of
chips, a clue in three or four lines on the front card, its tag on the edge
of a card lying under another, and the `why` line in three lines at the
foot. The logic is checked too: every wrong option is ruled out exactly once,
the answer never, and the first clue alone never settles it.

What this cannot check is whether a clue truly rules out what it claims.
That is the writer's rule: a clue rules an option out only when the fact
makes that option impossible, not merely less likely, and the source says so.
"""
from __future__ import annotations

OPTION_CHARS = 16   # half a row of chips, set large
TEXT_CHARS = 84     # the front card, three or four lines
TAG_CHARS = 24      # one line on the edge of a covered card
WHY_CHARS = 100     # three lines at the foot after the reveal
OPTIONS = (3, 5)
CLUES = (3, 5)
FIELDS = ("text", "tag", "rulesOut")


def _text(v) -> bool:
    return isinstance(v, str) and bool(v.strip())


def check(scene: dict) -> list[str]:
    p: list[str] = []
    for key in scene:
        if key not in ("type", "options", "answer", "clues", "why"):
            p.append(f"scene: unknown field {key!r}")

    options = scene.get("options")
    if not isinstance(options, list) or not (OPTIONS[0] <= len(options) <= OPTIONS[1]):
        return p + [f"scene.options: between {OPTIONS[0]} and {OPTIONS[1]}"]
    names = []
    for i, o in enumerate(options):
        if not _text(o):
            p.append(f"scene.options[{i}]: missing")
        elif len(o) > OPTION_CHARS:
            p.append(f"scene.options[{i}]: {len(o)} chars, over {OPTION_CHARS}")
        else:
            names.append(o.strip().lower())
    if len(set(names)) != len(names):
        p.append("scene.options: two options are the same")

    answer = scene.get("answer")
    if not isinstance(answer, int) or isinstance(answer, bool) or not 0 <= answer < len(options):
        return p + ["scene.answer: an index into options"]

    why = scene.get("why")
    if not _text(why):
        p.append("scene.why: missing")
    elif len(why) > WHY_CHARS:
        p.append(f"scene.why: {len(why)} chars, over {WHY_CHARS}")

    clues = scene.get("clues")
    if not isinstance(clues, list) or not (CLUES[0] <= len(clues) <= CLUES[1]):
        return p + [f"scene.clues: between {CLUES[0]} and {CLUES[1]}"]
    struck: dict[int, int] = {}
    tags = []
    for i, c in enumerate(clues):
        if not isinstance(c, dict):
            p.append(f"scene.clues[{i}]: not an object")
            continue
        for key in c:
            if key not in FIELDS:
                p.append(f"scene.clues[{i}]: unknown field {key!r}")
        for key, limit in (("text", TEXT_CHARS), ("tag", TAG_CHARS)):
            v = c.get(key)
            if not _text(v):
                p.append(f"scene.clues[{i}].{key}: missing")
            elif len(v) > limit:
                p.append(f"scene.clues[{i}].{key}: {len(v)} chars, over {limit}")
        if _text(c.get("tag")):
            tags.append(c["tag"].strip().lower())
        out = c.get("rulesOut", [])
        if not isinstance(out, list):
            p.append(f"scene.clues[{i}].rulesOut: a list of option indices")
            continue
        for o in out:
            if not isinstance(o, int) or isinstance(o, bool) or not 0 <= o < len(options):
                p.append(f"scene.clues[{i}].rulesOut: {o!r} is not an option index")
            elif o == answer:
                p.append(f"scene.clues[{i}].rulesOut: rules out the answer")
            elif o in struck:
                p.append(f"scene.clues[{i}].rulesOut: option {o} already out at clue "
                         f"{struck[o] + 1}; list it only where it first goes")
            else:
                struck[o] = i
    if len(set(tags)) != len(tags):
        p.append("scene.clues: two clues share a tag")

    wrong = {o for o in range(len(options)) if o != answer}
    missing = sorted(wrong - set(struck))
    if missing:
        p.append(f"scene.clues: options {missing} are never ruled out; the reader "
                 "could not reason their way to the answer")
        return p
    decisive = max(struck.values())
    if decisive == 0:
        p.append("scene.clues: the first clue settles it alone; there is nothing to "
                 "gain by waiting and nothing to reason about")
    if len(clues) - 1 - decisive > 2:
        p.append("scene.clues: more than two clues come after the decisive one; "
                 "the reader turns cards that cannot change the answer")
    return p
