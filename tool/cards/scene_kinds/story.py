"""Rules for a `story` scene: what happens next? (lib/models/scenes/story.dart).

The reader taps through a real case in a few scenes, stops, commits to an
outcome, then sees what happened and the line that names why. What this
cannot check is whether the story is true, whether the options are a fair
fork (the wrong ones should be what a sensible person would predict), or
whether `why` names a mechanism rather than repeating the outcome: that is
the writer's rule and the critic's.

The limits are set by a 360-wide phone and by the 270-high band on the back
of asking cards: a line is three lines of big type at most, a fact one line
of small capitals, a button label one line, the last line three lines of
body text.
"""
from __future__ import annotations

SCENES = (3, 5)
OPTIONS = (2, 3)
LINE_CHARS = 64     # three lines of display type on a 360 phone
FACT_CHARS = 32     # one line of spaced capitals
ASK_CHARS = 56      # two lines of display type above the buttons
LABEL_CHARS = 26    # one line on a button
WHY_CHARS = 100     # three lines of body text under the outcome
WORD_CHARS = 14     # a longer word breaks badly at display size

# The drawings the app knows, by name (StoryGlyph in story.dart).
# `question` is the app's own, for the stop.
GLYPHS = (
    "pin", "lights", "car", "walker", "crowd", "family", "house", "clock",
    "calendar", "coin", "ticket", "rat", "drain", "eye", "rise", "fall",
    "ban", "check", "cross", "book", "phone",
)


def _text(v, where: str, limit: int, p: list[str], required: bool = True) -> str:
    if v is None and not required:
        return ""
    if not isinstance(v, str) or not v.strip():
        p.append(f"{where}: missing" if required else f"{where}: not text")
        return ""
    if len(v) > limit:
        p.append(f"{where}: {len(v)} chars, over {limit}")
    return v


def _words(v: str, where: str, p: list[str]) -> None:
    long = [w for w in v.split() if len(w) > WORD_CHARS]
    if long:
        p.append(f"{where}: {long[0]!r} is over {WORD_CHARS} chars; it breaks badly at display size")


def _beat(b, where: str, p: list[str]) -> None:
    if not isinstance(b, dict):
        p.append(f"{where}: not an object {{line, fact, glyph}}")
        return
    line = _text(b.get("line"), f"{where}.line", LINE_CHARS, p)
    _words(line, f"{where}.line", p)
    _text(b.get("fact"), f"{where}.fact", FACT_CHARS, p, required=False)
    if b.get("glyph") not in GLYPHS:
        p.append(f"{where}.glyph: {b.get('glyph')!r} is not one of {', '.join(GLYPHS)}")
    extra = set(b) - {"line", "fact", "glyph"}
    if extra:
        p.append(f"{where}: unknown fields {sorted(extra)}")


def check(scene: dict) -> list[str]:
    p: list[str] = []
    scenes = scene.get("scenes")
    if not isinstance(scenes, list) or not SCENES[0] <= len(scenes) <= SCENES[1]:
        p.append(f"scene.scenes: {SCENES[0]} to {SCENES[1]} scenes")
    else:
        for i, b in enumerate(scenes):
            _beat(b, f"scene.scenes[{i}]", p)
        glyphs = [b.get("glyph") for b in scenes if isinstance(b, dict)]
        for a, b in zip(glyphs, glyphs[1:]):
            if a == b:
                p.append(f"scene.scenes: two scenes in a row draw {a!r}; the drawing should move the story on")
                break

    ask = _text(scene.get("ask"), "scene.ask", ASK_CHARS, p)
    _words(ask, "scene.ask", p)

    opts = scene.get("options")
    if not isinstance(opts, list) or not OPTIONS[0] <= len(opts) <= OPTIONS[1]:
        p.append(f"scene.options: {OPTIONS[0]} or {OPTIONS[1]} outcomes")
        opts = None
    else:
        labels = []
        for i, o in enumerate(opts):
            if not isinstance(o, dict):
                p.append(f"scene.options[{i}]: not an object {{label}}")
                continue
            labels.append(_text(o.get("label"), f"scene.options[{i}].label", LABEL_CHARS, p).strip().lower())
        if len(set(labels)) != len(labels):
            p.append("scene.options: two labels are the same")

    answer = scene.get("answer")
    if not isinstance(answer, int) or isinstance(answer, bool):
        p.append("scene.answer: the index of the option that came true")
    elif opts is not None and not 0 <= answer < len(opts):
        p.append(f"scene.answer: {answer} is not an option")

    _beat(scene.get("outcome"), "scene.outcome", p)
    _text(scene.get("why"), "scene.why", WHY_CHARS, p)
    outcome = scene.get("outcome")
    if isinstance(outcome, dict) and isinstance(outcome.get("line"), str) and outcome.get("line") == scene.get("why"):
        p.append("scene.why: repeats the outcome; it should name the mechanism")

    extra = set(scene) - {"type", "scenes", "ask", "options", "answer", "outcome", "why"}
    if extra:
        p.append(f"scene: unknown fields {sorted(extra)}")
    return p
