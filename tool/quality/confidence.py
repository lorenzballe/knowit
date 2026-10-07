"""How far a card the night wrote can be trusted without a person.

Every card that reaches the files has passed the gate and the critic. That
is a floor, not a measure: a card the critic passed on the first read,
written from a page whose quoted passage the program found word for word,
on a fact that will not change, is not the same bet as one the critic had
to correct, from the third site tried, whose quote could not be checked
because the page was a PDF, on a figure that moves every year. This puts a
number on the difference, from what the generator kept of how each card
got through (generate.py, Outcome), and says why it is not a hundred.

A card under CONFIDENT goes to a person (route.py); so does a sample of the
rest, because a score nobody checks drifts. The weights are a judgement,
written down so it can be argued with: the evals (evals.py) say how often
the critic misses, and that is what should move them.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Callable

# At or above: published with the night's batch. Below: a person first.
CONFIDENT = 75

# The share of the confident cards a person reads anyway.
AUDIT_SHARE = 0.1

# What each doubt costs, out of a hundred.
COST = {
    "no critic": 40,
    "critic corrected": 20,
    "fix refused": 15,
    "quote unchecked": 25,
    "first source failed": 10,
    "unusual site": 5,
    "other source kind": 5,
    "gate sent back": 10,
    "changes in months": 15,
    "changes in years": 5,
    "worked number": 5,
}


@dataclass
class Trust:
    score: int
    doubts: list[str] = field(default_factory=list)

    @property
    def confident(self) -> bool:
        return self.score >= CONFIDENT


def trust(outcome: dict, preferred: Callable[[str], list[str]] | None = None,
          domain_under: Callable[[str, str], bool] | None = None) -> Trust:
    """The score for one written card's outcome (generate.Outcome as a dict).

    [preferred] gives a subject's usual sites, and [domain_under] says whether
    a domain is one of them; both default to tool/cards/sources.py.
    """
    if preferred is None or domain_under is None:
        import common  # noqa: F401  (puts tool/cards on the path)
        import sources

        preferred = preferred or sources.preferred
        domain_under = domain_under or sources.is_under

    score = 100
    doubts: list[str] = []

    def doubt(key: str, words: str) -> None:
        nonlocal score
        score -= COST[key]
        doubts.append(words)

    request = outcome.get("request") or {}
    researched = bool(request.get("strand"))
    verdict = outcome.get("verdict") or ""
    if not verdict:
        doubt("no critic", "no critic read it")
    elif verdict == "fix":
        reason = (outcome.get("critic_reason") or "").strip()
        doubt("critic corrected", "the critic corrected it" + (f": {reason}" if reason else ""))
    if outcome.get("fix_refused"):
        doubt("fix refused", "the critic asked for a change the gate would not take, so the draft stands")
    if researched:
        if not outcome.get("checked"):
            doubt("quote unchecked", "its quote could not be found on the page by machine")
        if (outcome.get("tried") or 1) > 1:
            doubt("first source failed", "the first source did not hold up; it was written from another")
        domain = outcome.get("domain") or ""
        topic = request.get("topic") or ""
        usual = preferred(topic) if topic else []
        if domain and usual and not any(domain_under(domain, d) for d in usual):
            doubt("unusual site", f"{domain} is not among the subject's usual sources")
        asked = outcome.get("asked_source_kind") or ""
        got = outcome.get("source_kind") or ""
        if asked and got and asked != got:
            doubt("other source kind", f"a {got} where a {asked} was asked for")
    if outcome.get("repaired"):
        doubt("gate sent back", "the gate sent it back once")
    shelf = outcome.get("shelf_life") or ""
    if shelf == "months":
        doubt("changes in months", "its answer can change within months")
    elif shelf == "years":
        doubt("changes in years", "its answer can change within years")
    if outcome.get("kind") in ("number", "estimate"):
        doubt("worked number", "a worked number, where one slip is the whole card")
    return Trust(max(0, score), doubts)
