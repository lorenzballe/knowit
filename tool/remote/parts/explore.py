"""The shelves of Explore: which, in what order, at what size, for whom and when (remote/explore.json). Null keeps the build's own Explore."""
from __future__ import annotations


def check(doc) -> list[str]:
    """The problems with this part, each a line a person can act on."""
    if doc is not None and not isinstance(doc, (dict, list)):
        return ["is neither an object nor a list"]
    return []
