"""The cards waiting for a person, as a checklist, and what the ticks do.

The night sends a card to a person when its score is under the bar or it
falls in the sample (route.py); the re-check sends one when it proposes a
correction (recheck.py). Either way the card waits in tool/cards/review/,
outside the bank, and is listed in one GitHub issue labelled `cards-review`,
each card shown whole with two boxes under it: Publish and Drop.

Ticking a box edits the issue, which runs .github/workflows/review.yml:

    python3 tool/quality/review.py apply --body issue.md --today 2026-10-08
    python3 tool/cards/check.py && python3 tool/cards/bundle.py
    python3 tool/quality/review.py body > issue.md

Publish puts the card in the bank with today as its `checked` date — a
person looked — and Drop deletes it. The bank is gated again before
anything is committed, and the issue is rewritten with what is left.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import common

MARK = "<!-- astute-review -->"

_HEADER = re.compile(r"^###\s+`?([a-z0-9_-]+)`?")
_TICK = re.compile(r"^\s*[-*]\s+\[([ xX])\]\s+(Publish|Drop)\b")


def _letter(i: int) -> str:
    return "ABCDEFGH"[i] if i < 8 else str(i + 1)


def render_card(card: dict) -> list[str]:
    """One card as the issue shows it: enough to judge it without opening a file."""
    lines = [f"> **{card.get('question', '').strip()}**", ">"]
    kind = card.get("kind")
    if kind == "pickOne" and card.get("options"):
        for i, option in enumerate(card["options"]):
            mark = " ✓" if i == card.get("correct") else ""
            lines.append(f"> {_letter(i)}) {option}{mark}  ")
        lines.append(">")
    elif kind in ("number", "estimate") and "value" in card:
        unit = f" {card['unit']}" if card.get("unit") else ""
        lines.append(f"> **{card['value']}{unit}**" + (f" (within ×{card['withinFactor']})" if kind == "estimate" and card.get("withinFactor") else ""))
        lines.append(">")
        for i, step in enumerate(card.get("steps") or [], 1):
            lines.append(f"> {i}. {step}")
        lines.append(">")
    elif kind == "debate" and card.get("sides"):
        lines.append("> " + " · ".join(card["sides"]))
        lines.append(">")
    if card.get("answer"):
        lines.append(f"> {card['answer'].strip()}")
        lines.append(">")
    if card.get("move"):
        lines.append(f"> *The move:* {card['move'].strip()}")
        lines.append(">")
    source = card.get("source", "")
    ref = card.get("reference", "")
    if ref.startswith("http"):
        lines.append(f"> Source: {source} · [the page]({ref})")
    elif source or ref:
        lines.append(f"> Source: {source}" + (f" · {ref}" if ref else ""))
    if card.get("quote"):
        lines.append(f"> “{card['quote'].strip()}”")
    return lines


# The most cards one issue shows: GitHub stops an issue's text at 65,536
# characters, and a list longer than this is not read in one sitting anyway.
SHOWN = 25


def body(queue: list[dict], review: Path = common.REVIEW, shown: int = SHOWN) -> str:
    """The issue's text for the cards waiting now."""
    out = [
        MARK,
        "Cards waiting for a person before they go out. Read each one, then tick **Publish** to put it in the bank "
        "or **Drop** to delete it. A minute later the change is on main, the site and the phones pick it up, "
        "and the card leaves this list.",
        "",
    ]
    if not queue:
        out.append("Nothing is waiting.")
        return "\n".join(out) + "\n"
    waiting = [e for e in queue if (review / f"{e['id']}.json").exists()]
    for entry in waiting[:shown]:
        path = review / f"{entry['id']}.json"
        card = json.loads(path.read_text(encoding="utf-8"))
        why = "; ".join(entry.get("why") or []) or "no reason recorded"
        origin = "the re-check" if entry.get("from") == "recheck" else "the night"
        out += [
            f"### `{entry['id']}`",
            f"From {origin} of {entry.get('since', '?')} · score {entry.get('score', '?')}/100 · {why}",
            "",
            *render_card(card),
            "",
            "- [ ] Publish",
            "- [ ] Drop",
            "",
        ]
    if len(waiting) > shown:
        out.append(f"…and {len(waiting) - shown} more, which come up here as these are done.")
    return "\n".join(out) + "\n"


def ticks(text: str) -> dict[str, set[str]]:
    """Which boxes are ticked, card by card: {id: {"Publish"} | {"Drop"} | both}."""
    out: dict[str, set[str]] = {}
    current: str | None = None
    for line in text.splitlines():
        header = _HEADER.match(line)
        if header:
            current = header.group(1)
            continue
        tick = _TICK.match(line)
        if tick and current and tick.group(1) in "xX":
            out.setdefault(current, set()).add(tick.group(2))
    return out


@dataclass
class Applied:
    published: list[str] = field(default_factory=list)
    dropped: list[str] = field(default_factory=list)
    both: list[str] = field(default_factory=list)
    missing: list[str] = field(default_factory=list)

    def summary(self) -> str:
        parts = []
        if self.published:
            parts.append("Published: " + ", ".join(f"`{i}`" for i in self.published))
        if self.dropped:
            parts.append("Dropped: " + ", ".join(f"`{i}`" for i in self.dropped))
        if self.both:
            parts.append("Both boxes ticked, so nothing was done (tick one): " + ", ".join(f"`{i}`" for i in self.both))
        if self.missing:
            parts.append("No longer waiting: " + ", ".join(f"`{i}`" for i in self.missing))
        return "\n".join(parts) or "Nothing ticked."


def apply(text: str, *, today: dt.date, review: Path = common.REVIEW, bank: Path = common.BANK,
          queue_path: Path | None = None) -> Applied:
    """Does what the ticks say."""
    queue_path = queue_path or review / "queue.json"
    queue = common.read_queue(queue_path)
    done = Applied()
    for card_id, boxes in ticks(text).items():
        path = review / f"{card_id}.json"
        if boxes == {"Publish", "Drop"}:
            done.both.append(card_id)
            continue
        if not path.exists():
            done.missing.append(card_id)
            queue = [e for e in queue if e["id"] != card_id]
            continue
        if "Publish" in boxes:
            card = json.loads(path.read_text(encoding="utf-8"))
            card["checked"] = today.isoformat()
            entry = next((e for e in queue if e["id"] == card_id), {})
            topic = card.get("topic") or entry.get("topic")
            common.write_card(card, bank / topic / f"{card_id}.json")
            done.published.append(card_id)
        else:
            # A correction the re-check proposed is dropped by dropping the
            # proposal: the card in the bank stays as it was.
            done.dropped.append(card_id)
        path.unlink()
        queue = [e for e in queue if e["id"] != card_id]
    common.write_queue(queue, queue_path)
    return done


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="command", required=True)
    sub.add_parser("body", help="print the issue's text for the cards waiting now")
    a = sub.add_parser("apply", help="publish or drop what the issue's ticks say")
    a.add_argument("--body", type=Path, required=True, help="the issue's text as it was edited")
    a.add_argument("--today", help="YYYY-MM-DD for the checked date")
    a.add_argument("--summary", type=Path, help="write what was done here, for the issue comment")
    args = ap.parse_args(argv)

    if args.command == "body":
        sys.stdout.write(body(common.read_queue()))
        return 0
    today = dt.date.fromisoformat(args.today) if args.today else dt.date.today()
    done = apply(args.body.read_text(encoding="utf-8"), today=today)
    text = done.summary()
    if args.summary:
        args.summary.write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
