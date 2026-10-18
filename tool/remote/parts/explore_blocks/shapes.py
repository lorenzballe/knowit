"""Checks for the shapes blocks of Explore: Shelf shapes and signatures: one shape for every kind of card, and one confident graphic per kind of shelf (docs/explore, rounds 131 and 132)."""
from __future__ import annotations

from typing import Callable

# block name -> check(section) returning a list of problems, each a line a
# person can act on. A block listed here is a block the app can draw.
BLOCKS: dict[str, Callable[[dict], list[str]]] = {}
