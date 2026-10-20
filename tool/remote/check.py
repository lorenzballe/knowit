#!/usr/bin/env python3
"""Checks `remote/` before anything of it reaches a phone.

    python3 tool/remote/check.py

A bad document reaches every reader at once, which is the whole point of
it and its whole danger, so it is held to the standard of the bank: what
does not pass is not bundled. The document is in parts, and each part is
checked by its own module in `tool/remote/parts/` — `check(doc)` returns a
list of problems, each a line a person can act on. The part's module also
says where its sources live, if not in `remote/<part>.json`. The examples
in `remote/examples/` are checked by the same modules, and never bundled.
"""
from __future__ import annotations

import importlib
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
REMOTE = ROOT / "remote"

# Documents written to show what a part can do — remote/examples/<part>-<name>.json
# — checked like the part they are an example of, and never bundled: an
# example the docs point at is one the app could take as it is.
EXAMPLES = REMOTE / "examples"

if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

# The parts of the document, in the order the document lists them.
PARTS = ("app", "strings", "explore", "looks")


def load_part(name: str):
    """A part's sources, as one JSON value: `remote/<part>.json`, or for the
    strings one object per language from `remote/strings/<language>.json`."""
    if name == "strings":
        out = {}
        for path in sorted((REMOTE / "strings").glob("*.json")):
            out[path.stem] = json.loads(path.read_text(encoding="utf-8"))
        return out
    path = REMOTE / f"{name}.json"
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def load_and_check() -> tuple[dict, list[str]]:
    parts: dict = {}
    problems: list[str] = []
    for name in PARTS:
        try:
            parts[name] = load_part(name)
        except json.JSONDecodeError as e:
            problems.append(f"{name}: not JSON: {e}")
            continue
        module = importlib.import_module(f"parts.{name}")
        problems.extend(f"{name}: {p}" for p in module.check(parts[name]))
    problems.extend(check_examples())
    return parts, problems


def check_examples() -> list[str]:
    """The problems with the examples, each under its file's name."""
    problems: list[str] = []
    for path in sorted(EXAMPLES.glob("*.json")) if EXAMPLES.is_dir() else []:
        where = f"examples/{path.name}"
        part = path.stem.split("-", 1)[0]
        if part not in PARTS:
            problems.append(f"{where}: is named for no part of the document ({', '.join(PARTS)})")
            continue
        try:
            doc = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            problems.append(f"{where}: not JSON: {e}")
            continue
        module = importlib.import_module(f"parts.{part}")
        problems.extend(f"{where}: {p}" for p in module.check(doc))
    return problems


def main() -> int:
    _, problems = load_and_check()
    if problems:
        for p in problems:
            print(p)
        return 1
    print("remote: all clear")
    return 0


if __name__ == "__main__":
    sys.exit(main())
