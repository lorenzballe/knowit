"""The genres and their strands, read off the app's own list.

`lib/data/genres.dart` is the one place the tree lives: eighteen subjects,
six genres each, three strands under every genre, the names a reader would
give for what they want to read about. This reads that file rather than
copying it, so a strand renamed in the app is renamed here in the same
commit, and a card tagged with a strand the app no longer has fails the
gate instead of being a card the phone quietly cannot deal.

Thinking has no genres: it is not a subject, it is the principle in the
open, and it is never off anybody's deck.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

HERE = Path(__file__).resolve().parent
DART = HERE.parent.parent / "lib" / "data" / "genres.dart"


@dataclass(frozen=True)
class Strand:
    id: str
    label: str

    @property
    def genre(self) -> str:
        return self.id.rsplit(".", 1)[0]

    @property
    def topic(self) -> str:
        return self.id.split(".", 1)[0]


@dataclass(frozen=True)
class Genre:
    id: str
    label: str
    strands: tuple[Strand, ...]

    @property
    def topic(self) -> str:
        return self.id.split(".", 1)[0]


def _closing_bracket(text: str, start: int) -> int:
    """The index of the `]` that closes the `[` just before [start]."""
    depth = 1
    for i in range(start, len(text)):
        if text[i] == "[":
            depth += 1
        elif text[i] == "]":
            depth -= 1
            if depth == 0:
                return i
    raise ValueError("an unclosed list in genres.dart")


@lru_cache(maxsize=None)
def load(path: Path = DART) -> tuple[Genre, ...]:
    """Every genre, in the order the app lists them."""
    src = path.read_text(encoding="utf-8")
    body = src[src.index("kGenres = {"):]
    out: list[Genre] = []
    for g in re.finditer(r"Genre\(\s*'([^']+)',\s*'([^']+)',\s*\[", body):
        end = _closing_bracket(body, g.end())
        chunk = body[g.end():end]
        strands = tuple(
            Strand(sid, label)
            for sid, label in re.findall(r"Strand\(\s*'([^']+)',\s*'([^']+)',?\s*\)", chunk)
        )
        out.append(Genre(g.group(1), g.group(2), strands))
    if not out:
        raise ValueError("no genres found in genres.dart")
    return tuple(out)


def by_topic() -> dict[str, list[Genre]]:
    grouped: dict[str, list[Genre]] = {}
    for g in load():
        grouped.setdefault(g.topic, []).append(g)
    return grouped


def genres_by_id() -> dict[str, Genre]:
    return {g.id: g for g in load()}


def strands_by_id() -> dict[str, Strand]:
    return {s.id: s for g in load() for s in g.strands}


def strands_of(topic: str) -> list[Strand]:
    """The strands under a subject, in the app's order; empty for Thinking."""
    return [s for g in by_topic().get(topic, []) for s in g.strands]


def describe(strand_id: str) -> str:
    """`Space · Black holes · Event horizons`, for a person reading a report."""
    s = strands_by_id().get(strand_id)
    if s is None:
        return strand_id
    g = genres_by_id()[s.genre]
    return f"{g.label} · {s.label}"
