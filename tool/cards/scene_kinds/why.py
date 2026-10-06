"""Rules for a `why` scene: ask why, layer by layer, down to the root.

The reader starts from an everyday thing on the surface and taps the card's
own "And why?" to dig one layer at a time through 3 to 5 causes; the last is
the root, which lands on bedrock. Before it, an optional guess offers two or
three candidate roots (lib/models/scenes/why.dart,
lib/widgets/scenes/why_view.dart).

The lengths are what keeps one layer within about three lines beside the
plumb line on a 360 px phone, so that the layer above stays in view while
the new one rises. What this cannot check is whether each layer really is
the cause of the one above it, and not just another fact: that is the
writer's rule, and the source says where the chain comes from.
"""
from __future__ import annotations

ASK_CHARS = 16       # the button that digs, on one line
START_CHARS = 64     # the surface
LEVEL_CHARS = 72     # a cause, three lines beside the rope
ROOT_CHARS = 64      # the root, set larger on bedrock
FIGURE_CHARS = 9     # a number in its box ("10–20%", "2,400 m")
UNIT_CHARS = 26      # what the figure counts, two short lines beside it
OPTION_CHARS = 34    # a candidate root, on one chip
LEVELS = (3, 5)
OPTIONS = (2, 3)
FIGURES_MAX = 3      # a figure is a weight; on every layer it weighs nothing


def _step(p: list[str], step, where: str, limit: int) -> int:
    """Checks one layer; returns 1 if it carries a figure."""
    if not isinstance(step, dict):
        p.append(f"scene.{where}: not an object")
        return 0
    text = step.get("text")
    if not isinstance(text, str) or not text.strip():
        p.append(f"scene.{where}.text: missing")
    elif len(text) > limit:
        p.append(f"scene.{where}.text: {len(text)} chars, over {limit}")
    elif text.strip().endswith("?"):
        p.append(f"scene.{where}.text: a layer answers, it does not ask")
    figure, unit = step.get("figure", ""), step.get("unit", "")
    if not isinstance(figure, str) or len(figure) > FIGURE_CHARS:
        p.append(f"scene.{where}.figure: a string of at most {FIGURE_CHARS} chars")
        figure = ""
    if not isinstance(unit, str) or len(unit) > UNIT_CHARS:
        p.append(f"scene.{where}.unit: a string of at most {UNIT_CHARS} chars")
        unit = ""
    if unit.strip() and not figure.strip():
        p.append(f"scene.{where}.unit: a unit needs a figure")
    if figure.strip() and not any(c.isdigit() for c in figure):
        p.append(f"scene.{where}.figure: {figure!r} has no number in it")
    for key in step:
        if key not in ("text", "figure", "unit"):
            p.append(f"scene.{where}: unknown field {key!r}")
    return 1 if figure.strip() else 0


def check(scene: dict) -> list[str]:
    p: list[str] = []
    ask = scene.get("ask")
    if not isinstance(ask, str) or not ask.strip():
        p.append("scene.ask: missing")
    elif len(ask) > ASK_CHARS:
        p.append(f"scene.ask: {len(ask)} chars, over {ASK_CHARS}")

    figures = _step(p, scene.get("start"), "start", START_CHARS)
    levels = scene.get("levels")
    if not isinstance(levels, list) or not (LEVELS[0] <= len(levels) <= LEVELS[1]):
        return p + [f"scene.levels: between {LEVELS[0]} and {LEVELS[1]}"]
    for i, lv in enumerate(levels):
        root = i == len(levels) - 1
        figures += _step(p, lv, f"levels[{i}]", ROOT_CHARS if root else LEVEL_CHARS)
    if figures > FIGURES_MAX:
        p.append(f"scene: {figures} figures; at most {FIGURES_MAX}, or none stands out")
    texts = [lv.get("text", "").strip().lower() for lv in levels if isinstance(lv, dict)]
    if len(set(texts)) != len(texts):
        p.append("scene.levels: two layers say the same thing")

    guess = scene.get("guess")
    if guess is not None:
        if not isinstance(guess, dict):
            return p + ["scene.guess: {options, answer}"]
        options, answer = guess.get("options"), guess.get("answer")
        if not isinstance(options, list) or not (OPTIONS[0] <= len(options) <= OPTIONS[1]):
            p.append(f"scene.guess.options: between {OPTIONS[0]} and {OPTIONS[1]}")
            options = []
        for i, o in enumerate(options):
            if not isinstance(o, str) or not o.strip():
                p.append(f"scene.guess.options[{i}]: missing")
            elif len(o) > OPTION_CHARS:
                p.append(f"scene.guess.options[{i}]: {len(o)} chars, over {OPTION_CHARS}")
        clean = [o.strip().lower() for o in options if isinstance(o, str)]
        if len(set(clean)) != len(clean):
            p.append("scene.guess.options: two options are the same")
        if (not isinstance(answer, int) or isinstance(answer, bool)
                or not 0 <= answer < max(1, len(options))):
            p.append("scene.guess.answer: the index of one option")
        for key in guess:
            if key not in ("options", "answer"):
                p.append(f"scene.guess: unknown field {key!r}")

    for key in scene:
        if key not in ("type", "ask", "start", "levels", "guess"):
            p.append(f"scene: unknown field {key!r}")
    return p
