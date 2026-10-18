"""Words that replace the build's own, one object per language (remote/strings/<language>.json)."""
from __future__ import annotations


def check(doc) -> list[str]:
    """The problems with this part, each a line a person can act on."""
    if doc is not None and not isinstance(doc, (dict, list)):
        return ["is neither an object nor a list"]
    return []
