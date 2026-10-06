"""Rules for a `sample` scene: grow a random sample and watch a pattern go.

The reader taps (or drags) to grow a simulated sample in steps, say 20, 200,
2,000, 20,000, and watches a rate that swings at small sizes settle on the
truth built into the simulation (lib/models/scenes/sample.dart documents the
fields). The draws are seeded, so this file can run the very same simulation
the app runs and check what the notes claim about it: a note that says "65%"
at a step must be what the reader sees there.

    python3 tool/cards/scene_kinds/sample.py card.json [...]   # the numbers per step
    python3 tool/cards/scene_kinds/sample.py --seeds card.json # seeds worth a look
"""
from __future__ import annotations

import json
import math
import re
import sys

DOTS_CHARS = 26      # under the big count, two short lines at most
HIT_CHARS = 26       # under the big rate, two short lines at most
GROUP_CHARS = 14     # over each half of a compared sample
BUTTON_CHARS = 20    # one line on the button at phone width
NOTE_CHARS = 96      # two lines under the gauge
STEPS = (2, 5)
FIRST_STEP = 4
LAST_STEP = 1_000_000
MODULUS = 2147483647


def _num(v) -> bool:
    return isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v)


def _text(scene, key, limit, p, need=True):
    v = scene.get(key)
    if v is None and not need:
        return
    if not isinstance(v, str) or not v.strip():
        p.append(f"scene.{key}: missing")
    elif len(v) > limit:
        p.append(f"scene.{key}: {len(v)} chars, over {limit}")


def rates(scene) -> list[float]:
    if "groups" in scene:
        return [g["rate"] for g in scene["groups"]]
    return [scene["rate"]]


def simulate(scene) -> list[list[tuple[int, int]]]:
    """Per step, per group, (draws, hits): the same numbers the app draws.

    Park and Miller's generator, three draws thrown away after the seed. In a
    compared sample draws alternate between the groups, first to the first.
    """
    x = int(scene["seed"])
    for _ in range(3):
        x = x * 16807 % MODULUS
    rs = rates(scene)
    k = len(rs)
    hits = [0] * k
    out = []
    n = 0
    for step in scene["steps"]:
        while n < step:
            x = x * 16807 % MODULUS
            g = n % k
            if x / MODULUS < rs[g]:
                hits[g] += 1
            n += 1
        out.append([((n + k - 1 - g) // k, hits[g]) for g in range(k)])
    return out


def decimals(scene) -> int:
    if "decimals" in scene:
        return scene["decimals"]
    return 0 if all(abs(r * 100 - round(r * 100)) < 1e-9 for r in rates(scene)) else 1


def shown(share: float, d: int) -> str:
    """A share as the app writes it, rounded half away from zero."""
    v = math.floor(share * 100 * 10**d + 0.5) / 10**d
    return f"{v:.{d}f}"


def check(scene: dict) -> list[str]:
    p: list[str] = []
    _text(scene, "dots", DOTS_CHARS, p)
    if isinstance(scene.get("dots"), str) and "simulat" not in scene["dots"].lower():
        p.append("scene.dots: must say the sample is simulated (\"Simulated deaths\")")
    _text(scene, "hit", HIT_CHARS, p)
    _text(scene, "button", BUTTON_CHARS, p)

    has_rate, has_groups = "rate" in scene, "groups" in scene
    if has_rate == has_groups:
        return p + ["scene: give either rate (one sample) or groups (two compared)"]
    if has_rate and not (_num(scene["rate"]) and 0 < scene["rate"] < 1):
        return p + ["scene.rate: a share between 0 and 1"]
    if has_groups:
        gs = scene["groups"]
        if not isinstance(gs, list) or len(gs) != 2:
            return p + ["scene.groups: exactly two"]
        for g in gs:
            if not isinstance(g, dict) or not (_num(g.get("rate")) and 0 < g["rate"] < 1):
                return p + ["scene.groups: each is {label, rate}, rate between 0 and 1"]
            if not isinstance(g.get("label"), str) or not g["label"].strip():
                p.append("scene.groups: a label is missing")
            elif len(g["label"]) > GROUP_CHARS:
                p.append(f"scene.groups: {g['label']!r} is over {GROUP_CHARS} chars")

    steps = scene.get("steps")
    if not isinstance(steps, list) or not (STEPS[0] <= len(steps) <= STEPS[1]):
        return p + [f"scene.steps: between {STEPS[0]} and {STEPS[1]} sample sizes"]
    if not all(isinstance(s, int) and not isinstance(s, bool) for s in steps):
        return p + ["scene.steps: whole numbers"]
    if steps[0] < FIRST_STEP * (2 if has_groups else 1):
        p.append(f"scene.steps: start at {FIRST_STEP} or more per group")
    if steps[-1] > LAST_STEP:
        p.append(f"scene.steps: at most {LAST_STEP:,}")
    if any(b < a * 2 for a, b in zip(steps, steps[1:])):
        p.append("scene.steps: each at least twice the one before")

    seed = scene.get("seed")
    if not (isinstance(seed, int) and not isinstance(seed, bool) and 1 <= seed < MODULUS):
        return p + [f"scene.seed: a whole number from 1 to {MODULUS - 1}"]
    if "decimals" in scene and scene["decimals"] not in (0, 1):
        p.append("scene.decimals: 0 or 1")
    if "max" in scene:
        top = scene["max"]
        if not (_num(top) and max(rates(scene)) < top <= 1):
            p.append("scene.max: above every rate, at most 1")

    notes = scene.get("notes")
    if not isinstance(notes, list) or len(notes) != len(steps):
        return p + ["scene.notes: one per step"]
    if not all(isinstance(n, str) and n.strip() for n in notes):
        return p + ["scene.notes: each is a line of text"]
    for n in notes:
        if len(n) > NOTE_CHARS:
            p.append(f"scene.notes: {len(n)} chars, over {NOTE_CHARS}")
    if p:
        return p

    # A share quoted in a note is either the truth or what the reader sees
    # at that step, as the app rounds it ("80%" will do for 80.0%).
    d = decimals(scene)
    truths = {float(shown(r, dd)) for r in rates(scene) for dd in (0, 1)}
    for i, (note, groups) in enumerate(zip(notes, simulate(scene))):
        seen = {shown(h / n, d) for n, h in groups if n}
        for m in re.findall(r"(\d+(?:\.\d+)?)%", note):
            if float(m) not in {float(v) for v in seen} | truths:
                p.append(
                    f"scene.notes[{i}]: says {m}% but step {steps[i]:,} shows "
                    + " and ".join(sorted(s + "%" for s in seen))
                )
    return p


def _report(scene) -> None:
    d = decimals(scene)
    labels = [g["label"] for g in scene["groups"]] if "groups" in scene else [scene["hit"]]
    for step, groups in zip(scene["steps"], simulate(scene)):
        parts = [f"{lab} {shown(h / n, d)}% ({h:,}/{n:,})" for lab, (n, h) in zip(labels, groups)]
        print(f"  {step:>9,}  " + "   ".join(parts))


def _seeds(scene, many=20000) -> None:
    """Seeds whose first step strays furthest from the truth, for a writer who
    wants the early fake pattern the card is about. Only first-step size."""
    rs = rates(scene)
    found = []
    for s in range(1, many):
        trial = dict(scene, seed=s, steps=scene["steps"][:2])
        sim = simulate(trial)
        if len(rs) == 1:
            n, h = sim[0][0]
            n2, h2 = sim[1][0]
            score = (h / n - rs[0], h2 / n2 - rs[0])
        else:
            (na, ha), (nb, hb) = sim[0]
            (na2, ha2), (nb2, hb2) = sim[1]
            score = ((hb / nb - ha / na) - (rs[1] - rs[0]), (hb2 / nb2 - ha2 / na2) - (rs[1] - rs[0]))
        found.append((score, s))
    found.sort(key=lambda t: -abs(t[0][0]) - abs(t[0][1]))
    for (a, b), s in found[:12]:
        print(f"  seed {s:>6}: off by {a * 100:+.1f} points, then {b * 100:+.1f}")


if __name__ == "__main__":
    args = sys.argv[1:]
    want_seeds = "--seeds" in args
    for path in [a for a in args if a != "--seeds"]:
        data = json.load(open(path))
        for card in data if isinstance(data, list) else [data]:
            scene = card.get("scene", card)
            if scene.get("type") != "sample":
                continue
            print(card.get("id", path))
            for problem in check(scene):
                print("  !", problem)
            if want_seeds:
                _seeds(scene)
            else:
                _report(scene)
