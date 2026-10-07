"""Rules for a `poll` scene: answer for yourself, then see everyone.

The reader taps one of 2 to 4 options before seeing anything, then the
options become bars of how a named study's people answered, the reader's
row marked, with one line about people who chose like them and one on why
people split (lib/models/scenes/poll.dart, lib/widgets/scenes/poll_view.dart).
With two questions, the same choice is put twice in different words and the
line says whether the reader held steady or switched.

The lengths are what fits on a 360 px phone with the card's question above
and the scene squeezed to 270 px on the back of an asking card. What this
cannot check is whether the shares are the study's real figures, or whether
option i of the second question really is the same choice as option i of
the first: those are the writer's rules, and the source says where.
"""
from __future__ import annotations

import math

WHO_CHARS = 40       # the small heading over the bars, one line
PROMPT_CHARS = 80    # up to three lines over the slabs
TAG_CHARS = 30       # one line over a wording's bars
LABEL_CHARS = 24     # one line of a bar, beside its share and the YOU tag
LINE_CHARS = 100     # mirror, why, same, switched: three lines each
OPTIONS_ONE = (2, 4)
OPTIONS_TWO = (2, 2)
SUM_SLACK = 2        # rounding in the paper's percentages


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def _text(p: list[str], where: str, v, limit: int, required: bool = True) -> None:
    if v is None and not required:
        return
    if not isinstance(v, str) or not v.strip():
        p.append(f"{where}: missing")
    elif len(v) > limit:
        p.append(f"{where}: {len(v)} chars, over {limit}")


def check(scene: dict) -> list[str]:
    p: list[str] = []
    for key in scene:
        if key not in ("type", "who", "questions", "why", "same", "switched"):
            p.append(f"scene: unknown field {key!r}")
    _text(p, "scene.who", scene.get("who"), WHO_CHARS)
    _text(p, "scene.why", scene.get("why"), LINE_CHARS)

    qs = scene.get("questions")
    if not isinstance(qs, list) or not 1 <= len(qs) <= 2:
        return p + ["scene.questions: one or two"]
    twice = len(qs) == 2
    for key in ("same", "switched"):
        if twice:
            _text(p, f"scene.{key}", scene.get(key), LINE_CHARS)
        elif key in scene:
            p.append(f"scene.{key}: only with two questions")
    if twice and scene.get("same") == scene.get("switched"):
        p.append("scene.same and scene.switched: the same line for both outcomes")

    lo, hi = OPTIONS_TWO if twice else OPTIONS_ONE
    for q, question in enumerate(qs):
        at = f"scene.questions[{q}]"
        if not isinstance(question, dict):
            p.append(f"{at}: not an object")
            continue
        for key in question:
            if key not in ("prompt", "tag", "options"):
                p.append(f"{at}: unknown field {key!r}")
        _text(p, f"{at}.prompt", question.get("prompt"), PROMPT_CHARS, required=twice)
        if twice:
            _text(p, f"{at}.tag", question.get("tag"), TAG_CHARS)
        elif "tag" in question:
            p.append(f"{at}.tag: only with two questions")
        opts = question.get("options")
        if not isinstance(opts, list) or not lo <= len(opts) <= hi:
            p.append(f"{at}.options: between {lo} and {hi}")
            continue
        total = 0.0
        labels: list[str] = []
        for i, o in enumerate(opts):
            where = f"{at}.options[{i}]"
            if not isinstance(o, dict):
                p.append(f"{where}: not an object")
                continue
            for key in o:
                if key not in ("label", "share", "mirror"):
                    p.append(f"{where}: unknown field {key!r}")
            _text(p, f"{where}.label", o.get("label"), LABEL_CHARS)
            if isinstance(o.get("label"), str):
                labels.append(o["label"].strip().lower())
            share = o.get("share")
            if not _num(share) or not 0 <= share <= 100:
                p.append(f"{where}.share: a percentage, 0 to 100")
            else:
                total += share
            if twice:
                if "mirror" in o:
                    p.append(f"{where}.mirror: unused with two questions; "
                             "write scene.same and scene.switched")
            else:
                _text(p, f"{where}.mirror", o.get("mirror"), LINE_CHARS)
        if len(set(labels)) != len(labels):
            p.append(f"{at}.options: two options share a label")
        if abs(total - 100) > SUM_SLACK:
            p.append(f"{at}.options: shares add up to {total:g}, not 100")
    if twice and all(isinstance(q, dict) for q in qs):
        a, b = (q.get("prompt") for q in qs)
        if isinstance(a, str) and a == b:
            p.append("scene.questions: the two prompts are the same; the second "
                     "must read as a new question")
        t1, t2 = (q.get("tag") for q in qs)
        if isinstance(t1, str) and t1 == t2:
            p.append("scene.questions: the two tags are the same; they name the difference")
    return p
