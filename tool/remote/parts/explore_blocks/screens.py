"""Checks for the screens blocks of Explore: Whole Explore screens, one idea each (docs/explore, rounds 140 and 141)."""
from __future__ import annotations

from typing import Callable

# block name -> check(section) returning a list of problems, each a line a
# person can act on. A block listed here is a block the app can draw.
BLOCKS: dict[str, Callable[[dict], list[str]]] = {}
