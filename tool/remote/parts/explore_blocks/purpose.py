"""Checks for the purpose blocks of Explore: Shelves built on what Astute is for, and the bottom of Explore (docs/explore, rounds 133 and 138)."""
from __future__ import annotations

from typing import Callable

# block name -> check(section) returning a list of problems, each a line a
# person can act on. A block listed here is a block the app can draw.
BLOCKS: dict[str, Callable[[dict], list[str]]] = {}
