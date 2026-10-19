"""The update gate, the switches, the numbers the app tunes by and its
experiments (remote/app.json).

    {
     "gate": {"minBuild": {"ios": 7, "android": 7}, "blocked": [5, 6],
              "suggestBuild": {"ios": 8},
              "pause": {"on": true, "audience": {"platforms": ["android"]}},
              "message": {"pause": {"it": "…", "en": "…"}}},
     "flags": {"review.ask": {"on": false, "audience": {"maxBuild": 9}}},
     "tunables": {"push.askGapDays": 5},
     "experiments": {"push.firstAsk": {"variants": ["cameBack", "firstDay"],
                                        "weights": [1, 1]}}
    }

Every switch, number and experiment must be one the app reads: they are
listed in app_knobs.json beside this file, with the build's own value and
the range it takes, and test/remote_knobs_test.dart holds that list to the
declarations in the app's code. A knob a newer build stops reading stays
there, marked `"retired": true`, for as long as older builds still read it.
docs/REMOTE.md says what each one does.
"""
from __future__ import annotations

import datetime
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent
KNOBS = HERE / "app_knobs.json"
LANGUAGES = sorted(p.stem[len("app_"):] for p in (ROOT / "lib" / "l10n").glob("app_*.arb"))

PARTS = ("gate", "flags", "tunables", "experiments")
GATE_KEYS = ("minBuild", "blocked", "suggestBuild", "pause", "message")
PAUSE_KEYS = ("on", "audience")
FLAG_KEYS = ("on", "audience")
EXPERIMENT_KEYS = ("variants", "weights", "audience")
SCREENS = ("hard", "soft", "pause")

# Where a build can be sent to update: a store. The web app is always the
# newest one there is.
STORE_PLATFORMS = ("ios", "android")
PLATFORMS = ("ios", "android", "web")

# Long enough for two or three sentences under a title; past that, the
# screen should be a different screen.
MESSAGE_MAX = 300

AUDIENCE_KEYS = (
    "platforms", "minBuild", "maxBuild", "languages", "plus", "minDays", "maxDays",
    "from", "until", "weekdays", "hours", "rollout", "salt", "all", "any", "not",
)

_TIME = re.compile(r"^(\d{2}):(\d{2})$")


def knobs() -> dict:
    """What the app reads: the switches, numbers and experiments, by name."""
    return json.loads(KNOBS.read_text(encoding="utf-8"))


def _whole(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _number(value) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _listed(names) -> str:
    return ", ".join(sorted(names))


def _minute(at) -> int | None:
    if not isinstance(at, str):
        return None
    m = _TIME.match(at)
    if not m:
        return None
    h, mins = int(m.group(1)), int(m.group(2))
    return h * 60 + mins if h < 24 and mins < 60 else None


def _day(value) -> datetime.date | None:
    if not isinstance(value, str) or not re.match(r"^\d{4}-\d{2}-\d{2}$", value):
        return None
    try:
        return datetime.date.fromisoformat(value)
    except ValueError:
        return None


def check_audience(rule, where: str) -> list[str]:
    """The problems with an audience: keys the app knows (Audience.allows in
    lib/remote/remote.dart), each holding what it asks for."""
    if rule is None:
        return []
    if not isinstance(rule, dict):
        return [f"{where}: an audience is an object, like {{\"platforms\": [\"ios\"]}}"]
    problems: list[str] = []
    for key, value in rule.items():
        at = f"{where}.{key}"
        if key not in AUDIENCE_KEYS:
            problems.append(f"{where}: {key!r} is not an audience key the app knows ({_listed(AUDIENCE_KEYS)})")
        elif key == "platforms":
            if not isinstance(value, list) or not value or any(v not in PLATFORMS for v in value):
                problems.append(f"{at}: is a list of {_listed(PLATFORMS)}")
        elif key == "languages":
            if not isinstance(value, list) or not value or any(v not in LANGUAGES for v in value):
                problems.append(f"{at}: is a list of the app's languages ({_listed(LANGUAGES)})")
        elif key in ("minBuild", "maxBuild", "minDays", "maxDays"):
            if not _whole(value) or value < 0:
                problems.append(f"{at}: is a whole number, 0 or more")
        elif key == "plus":
            if not isinstance(value, bool):
                problems.append(f"{at}: is true (Astute+ only) or false (the free plan only)")
        elif key in ("from", "until"):
            if _day(value) is None:
                problems.append(f"{at}: is a date, like \"2026-10-20\"")
        elif key == "weekdays":
            if not isinstance(value, list) or not value or any(not _whole(d) or not 1 <= d <= 7 for d in value):
                problems.append(f"{at}: is a list of weekdays, Monday 1 to Sunday 7")
        elif key == "hours":
            if (not isinstance(value, list) or len(value) != 2
                    or any(not _whole(h) or not 0 <= h <= 24 for h in value) or value[0] == value[1]):
                problems.append(f"{at}: is [from, to], two different hours 0 to 24; [22, 3] runs across midnight")
        elif key == "rollout":
            if not _number(value) or not 0 <= value <= 100:
                problems.append(f"{at}: is a share of phones, 0 to 100")
        elif key == "salt":
            if not isinstance(value, str) or not value:
                problems.append(f"{at}: is a word that names the split")
        elif key in ("all", "any"):
            if not isinstance(value, list) or not value:
                problems.append(f"{at}: is a list of audiences")
            else:
                for i, sub in enumerate(value):
                    problems += check_audience(sub, f"{at}[{i}]")
        elif key == "not":
            if not isinstance(value, dict):
                problems.append(f"{at}: is one audience")
            else:
                problems += check_audience(value, at)
    for low, high in (("minBuild", "maxBuild"), ("minDays", "maxDays")):
        a, b = rule.get(low), rule.get(high)
        if _whole(a) and _whole(b) and a > b:
            problems.append(f"{where}: {low} {a} is above {high} {b}, so nobody is in it")
    start, end = _day(rule.get("from")), _day(rule.get("until"))
    if start and end and start > end:
        problems.append(f"{where}: from {rule['from']} is after until {rule['until']}, so nobody is in it")
    return problems


def _builds(value, where: str, problems: list[str]) -> dict[str, int]:
    """A build number per store platform, `{"ios": 7, "android": 7}`."""
    if value is None:
        return {}
    if not isinstance(value, dict):
        problems.append(f"{where}: is a build per platform, like {{\"ios\": 7, \"android\": 7}}")
        return {}
    out = {}
    for platform, build in value.items():
        if platform not in STORE_PLATFORMS:
            problems.append(f"{where}.{platform}: only {_listed(STORE_PLATFORMS)} have a store to update from")
        elif not _whole(build) or build < 1:
            problems.append(f"{where}.{platform}: is a build number, 1 or more")
        else:
            out[platform] = build
    return out


def _build_list(value, where: str, problems: list[str]) -> None:
    if not isinstance(value, list) or not value:
        problems.append(f"{where}: is a list of build numbers")
        return
    bad = [b for b in value if not _whole(b) or b < 1]
    if bad:
        problems.append(f"{where}: {bad} are not build numbers")
    if len(set(map(repr, value))) != len(value):
        problems.append(f"{where}: names a build twice")


def check_gate(gate) -> list[str]:
    if gate is None:
        return []
    if not isinstance(gate, dict):
        return ["gate: is an object, or null for none"]
    problems = [f"gate: {k!r} is not part of the gate ({_listed(GATE_KEYS)})" for k in gate if k not in GATE_KEYS]
    mins = _builds(gate.get("minBuild"), "gate.minBuild", problems)
    suggested = _builds(gate.get("suggestBuild"), "gate.suggestBuild", problems)
    for platform, build in suggested.items():
        if platform in mins and build <= mins[platform]:
            problems.append(
                f"gate.suggestBuild.{platform}: {build} is not above gate.minBuild.{platform} "
                f"({mins[platform]}), so no reader would ever be shown it"
            )
    if "blocked" in gate:
        blocked = gate["blocked"]
        if isinstance(blocked, dict):
            for platform, builds in blocked.items():
                if platform not in STORE_PLATFORMS:
                    problems.append(f"gate.blocked.{platform}: only {_listed(STORE_PLATFORMS)} have a store to update from")
                else:
                    _build_list(builds, f"gate.blocked.{platform}", problems)
        else:
            _build_list(blocked, "gate.blocked", problems)
    if "pause" in gate:
        pause = gate["pause"]
        if not isinstance(pause, dict):
            problems.append("gate.pause: is {\"on\": true, \"audience\": {…}}")
        else:
            problems += [f"gate.pause: {k!r} is not part of a pause ({_listed(PAUSE_KEYS)})" for k in pause if k not in PAUSE_KEYS]
            if not isinstance(pause.get("on"), bool):
                problems.append("gate.pause.on: is true or false")
            problems += check_audience(pause.get("audience"), "gate.pause.audience")
    if "message" in gate:
        message = gate["message"]
        if not isinstance(message, dict):
            problems.append("gate.message: is the words per screen and language, like {\"pause\": {\"en\": \"…\"}}")
        else:
            for screen, words in message.items():
                where = f"gate.message.{screen}"
                if screen not in SCREENS:
                    problems.append(f"{where}: is not one of the gate's screens ({_listed(SCREENS)})")
                    continue
                if not isinstance(words, dict):
                    problems.append(f"{where}: is the words by language, like {{\"en\": \"…\"}}")
                    continue
                for language, text in words.items():
                    at = f"{where}.{language}"
                    if language not in LANGUAGES:
                        problems.append(f"{at}: is not one of the app's languages ({_listed(LANGUAGES)})")
                    elif not isinstance(text, str) or not text.strip():
                        problems.append(f"{at}: is empty")
                    elif len(text) > MESSAGE_MAX:
                        problems.append(f"{at}: is {len(text)} characters; a screen's line takes {MESSAGE_MAX} at most")
                    elif "{" in text or "}" in text:
                        problems.append(f"{at}: is said as it is written, so a brace would show")
    return problems


def check_flags(flags, known: dict) -> list[str]:
    if flags is None:
        return []
    if not isinstance(flags, dict):
        return ["flags: is an object of switches by name"]
    problems: list[str] = []
    for name, flag in flags.items():
        where = f"flags.{name}"
        if name not in known:
            problems.append(f"{where}: is not a switch the app has ({_listed(known)})")
            continue
        if isinstance(flag, bool):
            continue
        if not isinstance(flag, dict):
            problems.append(f"{where}: is true, false, or {{\"on\": …, \"audience\": {{…}}}}")
            continue
        problems += [f"{where}: {k!r} is not part of a switch ({_listed(FLAG_KEYS)})" for k in flag if k not in FLAG_KEYS]
        if not isinstance(flag.get("on"), bool):
            problems.append(f"{where}.on: is true or false")
        problems += check_audience(flag.get("audience"), f"{where}.audience")
    return problems


def _times_problem(value, spec: dict) -> str | None:
    windows = spec["windows"]
    if not isinstance(value, list) or len(value) != len(windows):
        return f"is {len(windows)} times of day, like {json.dumps(spec['default'])}"
    for i, (at, (start, end)) in enumerate(zip(value, windows)):
        minute = _minute(at)
        if minute is None:
            return f"{at!r} is not a time of day, \"HH:mm\""
        if not _minute(start) <= minute < _minute(end):
            return f"{at} is not between {start} and {end}, where time {i + 1} of {len(windows)} must be"
    return None


def check_tunables(tunables, known: dict) -> list[str]:
    if tunables is None:
        return []
    if not isinstance(tunables, dict):
        return ["tunables: is an object of numbers by name"]
    problems: list[str] = []
    for name, value in tunables.items():
        where = f"tunables.{name}"
        spec = known.get(name)
        if spec is None:
            problems.append(f"{where}: is not a number the app tunes by ({_listed(known)})")
            continue
        kind = spec["type"]
        if kind == "count":
            if not _whole(value):
                problems.append(f"{where}: is a whole number, {spec['min']} to {spec['max']}")
            elif not spec["min"] <= value <= spec["max"]:
                problems.append(f"{where}: {value} is out of its range, {spec['min']} to {spec['max']}")
        elif kind == "times":
            said = _times_problem(value, spec)
            if said:
                problems.append(f"{where}: {said}")
        else:
            problems.append(f"{where}: app_knobs.json gives it the type {kind!r}, which this checker does not know")
    # A number that must come after another, each as the document sets it
    # or as built.
    for name, spec in known.items():
        other = spec.get("after")
        if not other or (name not in tunables and other not in tunables):
            continue
        mine = tunables.get(name, spec["default"])
        theirs = tunables.get(other, known[other]["default"])
        if _whole(mine) and _whole(theirs) and mine <= theirs:
            problems.append(f"tunables.{name}: {mine} must be after {other} ({theirs})")
    return problems


def check_experiments(experiments, known: dict) -> list[str]:
    if experiments is None:
        return []
    if not isinstance(experiments, dict):
        return ["experiments: is an object of experiments by name"]
    problems: list[str] = []
    for name, experiment in experiments.items():
        where = f"experiments.{name}"
        spec = known.get(name)
        if spec is None:
            problems.append(f"{where}: is not an experiment the app can run ({_listed(known)})")
            continue
        if not isinstance(experiment, dict):
            problems.append(f"{where}: is {{\"variants\": […], \"weights\": […], \"audience\": {{…}}}}")
            continue
        problems += [
            f"{where}: {k!r} is not part of an experiment ({_listed(EXPERIMENT_KEYS)})"
            for k in experiment if k not in EXPERIMENT_KEYS
        ]
        variants = experiment.get("variants")
        if not isinstance(variants, list) or not variants or any(not isinstance(v, str) or not v for v in variants):
            problems.append(f"{where}.variants: is a list of the variants to give, from {_listed(spec['variants'])}")
            variants = None
        else:
            unknown = [v for v in variants if v not in spec["variants"]]
            if unknown:
                problems.append(f"{where}.variants: {unknown} the app cannot show; it knows {_listed(spec['variants'])}")
            if len(set(variants)) != len(variants):
                problems.append(f"{where}.variants: names a variant twice")
        if "weights" in experiment:
            weights = experiment["weights"]
            if not isinstance(weights, list) or any(not _number(w) or w < 0 for w in weights):
                problems.append(f"{where}.weights: is a list of numbers, 0 or more")
            elif variants is not None and len(weights) != len(variants):
                problems.append(f"{where}.weights: has {len(weights)} weights for {len(variants)} variants")
            elif sum(weights) <= 0:
                problems.append(f"{where}.weights: add up to nothing, so nobody would be in it")
        problems += check_audience(experiment.get("audience"), f"{where}.audience")
    return problems


def check(doc) -> list[str]:
    """The problems with this part, each a line a person can act on."""
    if doc is None:
        return []
    if not isinstance(doc, dict):
        return ["is an object: the gate, the flags, the tunables and the experiments"]
    spec = knobs()
    problems = [f"{k!r} is not part of app ({_listed(PARTS)})" for k in doc if k not in PARTS]
    problems += check_gate(doc.get("gate"))
    problems += check_flags(doc.get("flags"), spec["flags"])
    problems += check_tunables(doc.get("tunables"), spec["tunables"])
    problems += check_experiments(doc.get("experiments"), spec["experiments"])
    return problems
