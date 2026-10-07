"""The set the critic is measured on, and how its answers are scored.

Half the set is cards from the bank as they are; half is the same kind of
card with one error planted (mutate.py), every kind of error equally often,
so a critic that only catches swapped keys cannot hide behind them. The
set is drawn with a seed, so two runs on the same bank ask the same
questions and a change to the rules or the critic's prompt shows as a
change in the score rather than in the luck of the draw.
"""
from __future__ import annotations

import random
from dataclasses import dataclass, field

import mutate


@dataclass
class Item:
    """One card the critic is shown, and what it should do with it."""

    id: str
    card: dict
    planted: str | None = None  # the error's kind; None for a card as it is
    detail: str = ""


@dataclass
class Score:
    """How the critic did, overall and by kind of error."""

    planted: int = 0
    caught: int = 0
    clean: int = 0
    false_alarms: int = 0
    by_kind: dict[str, list[int]] = field(default_factory=dict)  # kind → [caught, planted]
    misses: list[dict] = field(default_factory=list)
    alarms: list[dict] = field(default_factory=list)

    @property
    def catch_rate(self) -> float:
        return self.caught / self.planted if self.planted else 0.0

    @property
    def false_alarm_rate(self) -> float:
        return self.false_alarms / self.clean if self.clean else 0.0


def live(cards: list[dict]) -> list[dict]:
    """Cards a reader can meet: not disabled, and with an answer to check."""
    return [c for c in cards if not c.get("disabled") and c.get("answer")]


def build(cards: list[dict], *, per_kind: int = 6, clean: int | None = None, seed: int = 1) -> list[Item]:
    """[per_kind] planted cards for every kind of error, and as many clean ones.

    A card is planted at most once and never also appears clean, so the
    critic cannot recognise one half of the set from the other.
    """
    rng = random.Random(seed)
    pool = live(cards)
    rng.shuffle(pool)
    used: set[str] = set()
    items: list[Item] = []
    for kind in mutate.MUTATIONS:
        found = 0
        for card in pool:
            if found >= per_kind:
                break
            if card["id"] in used:
                continue
            planted = mutate.plant(card, rng, donors=pool, kinds=[kind])
            if planted is None:
                continue
            used.add(card["id"])
            items.append(Item(f"{card['id']}~{kind}", planted.card, kind, planted.detail))
            found += 1
    n_clean = clean if clean is not None else sum(1 for i in items if i.planted)
    for card in pool:
        if n_clean <= 0:
            break
        if card["id"] in used:
            continue
        used.add(card["id"])
        items.append(Item(card["id"], card))
        n_clean -= 1
    rng.shuffle(items)
    return items


def stopped(verdict: str) -> bool:
    """Whether a critic's verdict keeps the card out as it stands."""
    return verdict in ("fix", "reject")


def score(items: list[Item], verdicts: dict[str, dict]) -> Score:
    """[verdicts] maps an item's id to the critic's answer: {"verdict": …, "why": …}."""
    out = Score()
    for item in items:
        answer = verdicts.get(item.id) or {}
        verdict = answer.get("verdict", "")
        if item.planted:
            out.planted += 1
            tally = out.by_kind.setdefault(item.planted, [0, 0])
            tally[1] += 1
            if stopped(verdict):
                out.caught += 1
                tally[0] += 1
            else:
                out.misses.append({"id": item.id, "error": item.planted, "detail": item.detail, "verdict": verdict, "why": answer.get("why", "")})
        else:
            out.clean += 1
            if verdict == "reject":
                out.false_alarms += 1
                out.alarms.append({"id": item.id, "verdict": verdict, "why": answer.get("why", "")})
    return out


def report(s: Score) -> str:
    """The score as the pull request or the run's summary shows it."""
    lines = [
        "## How the critic did",
        "",
        f"- Planted errors caught: **{s.caught} of {s.planted}** ({s.catch_rate:.0%})",
        f"- Good cards rejected: **{s.false_alarms} of {s.clean}** ({s.false_alarm_rate:.0%})",
        "",
        "| Error | Caught |",
        "|---|---|",
    ]
    for kind, (caught, planted) in sorted(s.by_kind.items()):
        lines.append(f"| {kind} | {caught} of {planted} |")
    if s.misses:
        lines += ["", "### Missed", ""]
        lines += [f"- `{m['id']}` — {m['detail']} (said *{m['verdict'] or 'nothing'}*)" for m in s.misses]
    if s.alarms:
        lines += ["", "### Good cards it rejected", ""]
        lines += [f"- `{a['id']}` — {a['why'][:160]}" for a in s.alarms]
    return "\n".join(lines) + "\n"
