"""Checks for the core blocks of Explore: The engine's own blocks: every shelf the app had before Explore came from the server, and the generic ones that show any cards at any size (carousels, grids, bento, hero, banner…), plus text, countdown, subjects, promo, spacer, divider and web."""
from __future__ import annotations

from typing import Callable

# block name -> check(section) returning a list of problems, each a line a
# person can act on. A block listed here is a block the app can draw.
BLOCKS: dict[str, Callable[[dict], list[str]]] = {}
