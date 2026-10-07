"""After the night: which of its cards a person reads first.

The generator files every card that passed into the bank. This takes the
night's outcomes (generate.py --outcomes), scores each written card
(confidence.py), and moves out of the bank, into tool/cards/review/, the
ones under the bar and a sample of the rest. What stays is published with
the night's batch; what moved waits in the review queue for a person, who
publishes or drops each one from a checklist (review.py).

    python3 tool/quality/route.py --outcomes cards-outcomes.json \\
        --report cards-report.md --today 2026-10-08
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import random
import sys
from dataclasses import dataclass
from pathlib import Path

import common
import confidence


@dataclass
class Routed:
    outcome: dict
    trust: confidence.Trust
    audit: bool = False

    @property
    def id(self) -> str:
        return self.outcome["id"]

    @property
    def topic(self) -> str:
        return self.outcome["request"]["topic"]


def split(outcomes: list[dict], *, today: dt.date, audit: float = confidence.AUDIT_SHARE,
          trust=confidence.trust) -> tuple[list[Routed], list[Routed]]:
    """The written cards as (published with the batch, sent to a person)."""
    written = [Routed(o, trust(o)) for o in outcomes if o.get("status") == "written" and o.get("id")]
    confident = [r for r in written if r.trust.confident]
    doubtful = [r for r in written if not r.trust.confident]
    # A sample of the confident ones too, the same sample for the same night.
    k = round(len(confident) * audit)
    if k == 0 and len(confident) >= 3 and audit > 0:
        k = 1
    sample = random.Random(today.isoformat()).sample(confident, k) if k else []
    for r in sample:
        r.audit = True
    picked = {r.id for r in sample}
    return [r for r in confident if r.id not in picked], doubtful + sample


def send_to_review(routed: list[Routed], *, bank: Path, review: Path, queue: Path, today: dt.date) -> list[str]:
    """Moves each card's file out of the bank into the review folder, and queues it."""
    waiting = common.read_queue(queue)
    known = {c["id"] for c in waiting}
    moved: list[str] = []
    for r in routed:
        source = bank / r.topic / f"{r.id}.json"
        if not source.exists():
            continue
        card = json.loads(source.read_text(encoding="utf-8"))
        common.write_card(card, review / f"{r.id}.json")
        source.unlink()
        if r.id not in known:
            waiting.append({
                "id": r.id,
                "topic": r.topic,
                "question": card.get("question", ""),
                "score": r.trust.score,
                "why": ["a spot check: the score was fine, and a person reads a share of those anyway"] if r.audit else r.trust.doubts,
                "audit": r.audit,
                "since": today.isoformat(),
                "from": "generator",
            })
        moved.append(r.id)
    common.write_queue(waiting, queue)
    return moved


def section(published: list[Routed], reviewing: list[Routed]) -> str:
    """What the pull request says about the routing."""
    lines = ["", "## Who reads what", ""]
    if published:
        lines.append(f"**Published with this batch ({len(published)})**, trusted on the record of how each got through:")
        lines.append("")
        for r in published:
            lines.append(f"- `{r.id}` · {r.trust.score}/100" + (f" — {'; '.join(r.trust.doubts)}" if r.trust.doubts else ""))
        lines.append("")
    if reviewing:
        lines.append(f"**Waiting for a person ({len(reviewing)})** in `tool/cards/review/`, not in the bank: "
                     "once this is merged they are listed in the issue labelled `cards-review`, to publish or drop.")
        lines.append("")
        for r in reviewing:
            why = "a spot check" if r.audit else "; ".join(r.trust.doubts)
            lines.append(f"- `{r.id}` · {r.trust.score}/100 — {why}")
        lines.append("")
    if not published and not reviewing:
        lines.append("Nothing was written, so nothing to route.")
        lines.append("")
    lines.append(f"A card scoring under {confidence.CONFIDENT} goes to a person, and so does one in "
                 f"{round(1 / confidence.AUDIT_SHARE)} of the rest (tool/quality/confidence.py).")
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--outcomes", type=Path, required=True)
    ap.add_argument("--report", type=Path, help="append the routing to this pull request body")
    ap.add_argument("--today", help="YYYY-MM-DD; the sample is drawn from it")
    ap.add_argument("--bank", type=Path, default=common.BANK)
    ap.add_argument("--review", type=Path, default=common.REVIEW)
    ap.add_argument("--audit", type=float, default=confidence.AUDIT_SHARE)
    args = ap.parse_args(argv)

    today = dt.date.fromisoformat(args.today) if args.today else dt.date.today()
    if not args.outcomes.exists():
        print(f"{args.outcomes} does not exist: nothing to route", file=sys.stderr)
        return 0
    outcomes = json.loads(args.outcomes.read_text(encoding="utf-8"))
    published, reviewing = split(outcomes, today=today, audit=args.audit)
    send_to_review(reviewing, bank=args.bank, review=args.review, queue=args.review / "queue.json", today=today)
    text = section(published, reviewing)
    if args.report:
        with args.report.open("a", encoding="utf-8") as f:
            f.write(text)
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
