"""The shelves of Explore: which, in what order, at what size, for whom and
when (remote/explore.json). Null keeps the build's own Explore.

The document is {"sections": [...]}. Every section has an id and a block;
the block must be one the app can draw, which is one some family in
explore_blocks/ lists, and that family's own check reads the rest of it.
"""
from __future__ import annotations

import importlib
import pkgutil
from pathlib import Path

HERE = Path(__file__).resolve().parent

AUDIENCE_KEYS = {
    "platforms", "minBuild", "maxBuild", "languages", "plus", "minDays", "maxDays",
    "from", "until", "weekdays", "hours", "rollout", "salt", "all", "any", "not",
}


def blocks() -> dict:
    out = {}
    for info in pkgutil.iter_modules([str(HERE / "explore_blocks")]):
        module = importlib.import_module(f"parts.explore_blocks.{info.name}")
        for name, fn in getattr(module, "BLOCKS", {}).items():
            out[name] = fn
    return out


def check_audience(rule, where: str) -> list[str]:
    if rule is None:
        return []
    if not isinstance(rule, dict):
        return [f"{where}: audience is not an object"]
    problems = [f"{where}: audience key {k!r} is not one the app knows" for k in rule if k not in AUDIENCE_KEYS]
    for key in ("all", "any"):
        for i, sub in enumerate(rule.get(key) or []):
            problems += check_audience(sub, f"{where}.{key}[{i}]")
    if "not" in rule:
        problems += check_audience(rule["not"], f"{where}.not")
    return problems


def check(doc) -> list[str]:
    """The problems with this part, each a line a person can act on."""
    if doc is None:
        return []
    if not isinstance(doc, dict) or not isinstance(doc.get("sections"), list):
        return ['is not {"sections": [...]}']
    known = blocks()
    problems: list[str] = []
    seen: set[str] = set()
    for i, section in enumerate(doc["sections"]):
        where = f"sections[{i}]"
        if not isinstance(section, dict):
            problems.append(f"{where}: is not an object")
            continue
        sid, block = section.get("id"), section.get("block")
        if not isinstance(sid, str) or not sid:
            problems.append(f"{where}: has no id")
            continue
        where = f"section {sid!r}"
        if sid in seen:
            problems.append(f"{where}: the id is used twice")
        seen.add(sid)
        if block not in known:
            problems.append(f"{where}: block {block!r} is not one the app can draw")
            continue
        problems += check_audience(section.get("audience"), where)
        problems += [f"{where}: {p}" for p in known[block](section)]
    return problems
