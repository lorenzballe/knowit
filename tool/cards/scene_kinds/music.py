"""Rules for a `music` scene: build a sound and hear what changed.

Three modes (lib/models/scenes/music.dart documents the fields): `chord`, a
small keyboard whose chord is read as a whole-number ratio; `harmonics`, one
tone built from bars the reader switches on and off; `layers`, a short loop
of two to five tracks switched on and off under a playhead. The limits keep
every label on one line and every line in two or three at phone width, the
keyboard's keys wide enough for a thumb, and the loop short enough to be
synthesized on a tap.

What this cannot check is whether the music theory is true: the ratios the
lines quote are worked out by the app from the notes, but a line that says
"the wave repeats every 15 ms" is the writer's sum, and the source says why.
"""
from __future__ import annotations

import math
import re

MODES = ("chord", "harmonics", "layers")
SOUNDS = ("kick", "snare", "clap", "hat", "bass", "keys", "lead")
DRUMS = ("kick", "snare", "clap", "hat")
HINT_CHARS = 90        # the line under the picture: three lines, two on the back
TEXT_CHARS = 90
NAME_CHARS = 24        # beside the big readout, one line
READOUT_CHARS = 34     # small caps over the readout
BUTTON_CHARS = 14      # the play button's label
TRACK_CHARS = 10       # inside a chip a third of the width
MOMENTS = 8
WHITE_KEYS = (5, 10)   # under 10, a key is a thumb wide on a small phone
CHORD_NOTES = 6
HARMONICS = (2, 8)
FUNDAMENTAL = (55, 600)
TRACKS = (2, 5)
STEPS = (8, 32)
BPM = (60, 180)
LOOP_SECONDS = 8

COMMON = {"type", "mode", "hint", "listen", "stop", "moments"}
KEYS = {
    "chord": COMMON | {"readout", "keys", "start", "tuning"},
    "harmonics": COMMON | {"readout", "fundamental", "harmonics", "start"},
    "layers": COMMON | {"bpm", "steps", "tracks"},
}

_NOTE = re.compile(r"^([A-G])([#b♯♭]?)(-?\d)$")
_BASE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def _midi(name) -> int | None:
    m = _NOTE.match(name) if isinstance(name, str) else None
    if not m:
        return None
    acc = {"#": 1, "♯": 1, "b": -1, "♭": -1}.get(m[2], 0)
    return 12 * (int(m[3]) + 1) + _BASE[m[1]] + acc


def _black(midi: int) -> bool:
    return midi % 12 in (1, 3, 6, 8, 10)


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def _int(v) -> bool:
    return isinstance(v, int) and not isinstance(v, bool)


def _text(scene: dict, key: str, limit: int, p: list[str], required=True) -> None:
    v = scene.get(key)
    if v is None and not required:
        return
    if not isinstance(v, str) or not v.strip():
        p.append(f"scene.{key}: missing")
    elif len(v) > limit:
        p.append(f"scene.{key}: {len(v)} chars, over {limit}")


def check(scene: dict) -> list[str]:
    p: list[str] = []
    mode = scene.get("mode")
    if mode not in MODES:
        return [f"scene.mode: one of {', '.join(MODES)}"]
    for k in sorted(set(scene) - KEYS[mode]):
        p.append(f"scene.{k}: not a field of a {mode} music scene")
    _text(scene, "hint", HINT_CHARS, p)
    _text(scene, "listen", BUTTON_CHARS, p, required=False)
    _text(scene, "stop", BUTTON_CHARS, p, required=False)

    moments = scene.get("moments", [])
    if not isinstance(moments, list) or len(moments) > MOMENTS:
        p.append(f"scene.moments: a list of at most {MOMENTS}")
        moments = []
    set_key = "notes" if mode == "chord" else "on"
    sets: list[list] = []
    for m in moments:
        if not isinstance(m, dict) or not isinstance(m.get(set_key), list) \
                or set(m) - {set_key, "name", "text"}:
            p.append(f"scene.moments: each is {{{set_key}, name, text}}")
            continue
        name, text = m.get("name", ""), m.get("text")
        if not isinstance(name, str) or len(name) > NAME_CHARS:
            p.append(f"scene.moments: name {name!r} over {NAME_CHARS} chars")
        if not isinstance(text, str) or not text.strip():
            p.append("scene.moments: a text is missing")
        elif len(text) > TEXT_CHARS:
            p.append(f"scene.moments: {len(text)} chars, over {TEXT_CHARS}: {text[:30]!r}…")
        sets.append(m[set_key])

    if mode == "chord":
        p += _chord(scene, sets)
    elif mode == "harmonics":
        p += _harmonics(scene, sets)
    else:
        p += _layers(scene, sets)
    return p


def _chord(scene: dict, sets: list[list]) -> list[str]:
    p: list[str] = []
    _text(scene, "readout", READOUT_CHARS, p)
    if scene.get("tuning", "equal") not in ("equal", "just"):
        p.append("scene.tuning: equal or just")
    keys = scene.get("keys")
    lo = hi = None
    if isinstance(keys, list) and len(keys) == 2:
        lo, hi = _midi(keys[0]), _midi(keys[1])
    if lo is None or hi is None:
        return p + ["scene.keys: [from, to], two note names such as \"C4\""]
    if _black(lo) or _black(hi):
        p.append("scene.keys: start and end on white keys")
    whites = sum(1 for m in range(lo, hi + 1) if not _black(m))
    if not WHITE_KEYS[0] <= whites <= WHITE_KEYS[1]:
        p.append(f"scene.keys: {whites} white keys, want {WHITE_KEYS[0]}–{WHITE_KEYS[1]}")

    def notes(lst, where: str) -> set[int]:
        out: set[int] = set()
        if not isinstance(lst, list) or not 1 <= len(lst) <= CHORD_NOTES:
            p.append(f"scene.{where}: 1 to {CHORD_NOTES} notes")
            return out
        for n in lst:
            m = _midi(n)
            if m is None:
                p.append(f"scene.{where}: {n!r} is not a note name")
            elif not lo <= m <= hi:
                p.append(f"scene.{where}: {n} is not on the keyboard")
            elif m in out:
                p.append(f"scene.{where}: {n} twice")
            else:
                out.add(m)
        return out

    start = notes(scene.get("start"), "start")
    seen = []
    for s in sets:
        got = notes(s, "moments")
        if got in seen:
            p.append("scene.moments: the same notes twice")
        seen.append(got)
    del start  # starting on a moment is fine: its line greets the reader
    return p


def _harmonics(scene: dict, sets: list[list]) -> list[str]:
    p: list[str] = []
    _text(scene, "readout", READOUT_CHARS, p)
    f0 = scene.get("fundamental")
    if not _num(f0) or not FUNDAMENTAL[0] <= f0 <= FUNDAMENTAL[1]:
        p.append(f"scene.fundamental: {FUNDAMENTAL[0]}–{FUNDAMENTAL[1]} Hz")
    n = scene.get("harmonics")
    if not _int(n) or not HARMONICS[0] <= n <= HARMONICS[1]:
        return p + [f"scene.harmonics: {HARMONICS[0]} to {HARMONICS[1]}"]

    def harmonics(lst, where: str) -> set[int]:
        if not isinstance(lst, list) or not lst:
            p.append(f"scene.{where}: a list of harmonic numbers")
            return set()
        if not all(_int(h) and 1 <= h <= n for h in lst):
            p.append(f"scene.{where}: harmonic numbers from 1 to {n}")
            return set()
        if len(set(lst)) != len(lst):
            p.append(f"scene.{where}: a harmonic twice")
        return set(lst)

    start = harmonics(scene.get("start"), "start")
    seen = []
    for s in sets:
        got = harmonics(s, "moments")
        if got in seen:
            p.append("scene.moments: the same harmonics twice")
        seen.append(got)
    if start and start in seen:
        p.append("scene.start: is a moment, so the hint is never read")
    return p


def _layers(scene: dict, sets: list[list]) -> list[str]:
    p: list[str] = []
    bpm, steps = scene.get("bpm"), scene.get("steps")
    if not _num(bpm) or not BPM[0] <= bpm <= BPM[1]:
        p.append(f"scene.bpm: {BPM[0]}–{BPM[1]}")
        bpm = None
    if not _int(steps) or not STEPS[0] <= steps <= STEPS[1] or steps % 4:
        return p + [f"scene.steps: {STEPS[0]}–{STEPS[1]}, a multiple of 4"]
    if bpm and steps * 15 / bpm > LOOP_SECONDS + 1e-9:
        p.append(f"scene: the loop lasts {steps * 15 / bpm:.1f} s, over {LOOP_SECONDS}")
    tracks = scene.get("tracks")
    if not isinstance(tracks, list) or not TRACKS[0] <= len(tracks) <= TRACKS[1]:
        return p + [f"scene.tracks: {TRACKS[0]} to {TRACKS[1]}"]
    names: list[str] = []
    for t in tracks:
        if not isinstance(t, dict) or set(t) - {"name", "sound", "pattern", "on", "text"}:
            p.append("scene.tracks: each is {name, sound, pattern, on, text}")
            continue
        name = t.get("name")
        if not isinstance(name, str) or not name.strip() or len(name) > TRACK_CHARS:
            p.append(f"scene.tracks: name {name!r} must be 1 to {TRACK_CHARS} chars")
            continue
        if name in names:
            p.append(f"scene.tracks: {name!r} twice")
        names.append(name)
        sound = t.get("sound")
        if sound not in SOUNDS:
            p.append(f"scene.tracks: {name}: sound is one of {', '.join(SOUNDS)}")
        if "on" in t and not isinstance(t["on"], bool):
            p.append(f"scene.tracks: {name}: on is true or false")
        text = t.get("text", "")
        if not isinstance(text, str) or len(text) > TEXT_CHARS:
            p.append(f"scene.tracks: {name}: text over {TEXT_CHARS} chars")
        pat = t.get("pattern")
        if not isinstance(pat, str):
            p.append(f"scene.tracks: {name}: pattern missing")
            continue
        tokens = pat.split()
        if len(tokens) != steps:
            p.append(f"scene.tracks: {name}: {len(tokens)} steps, not {steps}")
            continue
        hits = 0
        prev = "."
        for tok in tokens:
            if tok == ".":
                prev = tok
                continue
            if sound in DRUMS:
                if tok not in ("x", "X"):
                    p.append(f"scene.tracks: {name}: drums are x, X or ., not {tok!r}")
                    break
            elif tok == "-":
                if prev == ".":
                    p.append(f"scene.tracks: {name}: '-' holds nothing")
                    break
            else:
                bad = [n for n in tok.split("+") if (_midi(n) or 0) not in range(21, 97)]
                if bad:
                    p.append(f"scene.tracks: {name}: {bad[0]!r} is not a note A0–C7")
                    break
            hits += tok != "-"
            prev = tok
        if hits == 0:
            p.append(f"scene.tracks: {name}: plays nothing")
    seen = []
    for s in sets:
        if not s or not all(isinstance(n, str) and n in names for n in s):
            p.append("scene.moments: on names tracks of this scene")
            continue
        if set(s) in seen:
            p.append("scene.moments: the same tracks twice")
        seen.append(set(s))
    return p
