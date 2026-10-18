"""Checks for the bets blocks of Explore: Bets: estimate it before you open it (docs/explore, round 139)."""
from __future__ import annotations

from typing import Callable

# block name -> check(section) returning a list of problems, each a line a
# person can act on. A block listed here is a block the app can draw.
BLOCKS: dict[str, Callable[[dict], list[str]]] = {}
