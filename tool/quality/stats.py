"""The scorecard, for a person: which cards readers are telling us about.

The server adds up every day how each card does (functions/src/scorecard.ts)
and serves it at `cardStats`. This prints it the way somebody fixing cards
wants to read it: what is out of the deal and why, what readers dispute,
which cards are labelled harder or easier than they are, which ones readers
throw down, and which they keep.

    python3 tool/quality/stats.py               # from the server
    python3 tool/quality/stats.py --file x.json # from a saved copy
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import common  # noqa: F401  (puts tool/cards on the path)
import recheck

SECTIONS = [
    ("quarantined", "Out of the deal until checked", "readers say these are untrue"),
    ("disputed", "Disputed", "two or more readers say these are untrue"),
    ("keySuspect", "Marked answer in doubt", "almost every reader picks one other option over the one marked right"),
    ("reported", "Reported", "a reader said something is wrong"),
    ("tooHard", "Harder than labelled", "answered right far less often than the label says"),
    ("tooEasy", "Easier than labelled", "answered right far more often than the label says"),
    ("thrown", "Thrown down", "readers set these aside far more than most"),
    ("kept", "Kept", "readers like, save, share and say these far more than most"),
]


def summary(stats: dict, bank: list[dict]) -> str:
    by_id = {c["id"]: c for c in bank}
    flags: dict[str, list[str]] = stats.get("flags") or {}
    reports: dict[str, dict] = stats.get("reports") or {}
    cards: dict[str, dict] = stats.get("cards") or {}
    days = stats.get("days") or []
    lines = ["# How the cards are doing", ""]
    lines.append(f"{len(days)} day{'s' if len(days) != 1 else ''} counted"
                 + (f", {days[0]} to {days[-1]}" if days else "") + f"; {len(cards)} cards with enough readers to say anything.")
    lines.append("")
    for flag, title, meaning in SECTIONS:
        ids = [cid for cid, f in flags.items() if flag in f]
        if not ids:
            continue
        lines += [f"## {title} ({len(ids)})", "", f"*{meaning}*", ""]
        for cid in sorted(ids, key=lambda i: -(cards.get(i, {}).get("exposures") or 0))[:25]:
            card = by_id.get(cid, {})
            c = cards.get(cid, {})
            bits = []
            if c.get("answers"):
                bits.append(f"{round(100 * c['right'] / c['answers'])}% right of {c['answers']}")
            if c.get("exposures"):
                bits.append(f"{c['exposures']} readers")
            if reports.get(cid):
                bits.append("reports: " + ", ".join(f"{r} ×{n}" for r, n in sorted(reports[cid].items())))
            lines.append(f"- `{cid}` — {card.get('question', '(not in the bank)')} · " + " · ".join(bits))
        lines.append("")
    if not flags:
        lines.append("Nothing flagged yet.")
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    import check

    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--file", type=Path, help="a saved scorecard instead of the server's")
    ap.add_argument("--json", action="store_true", help="print the scorecard as it came")
    args = ap.parse_args(argv)
    stats = json.loads(args.file.read_text(encoding="utf-8")) if args.file else recheck.fetch_stats()
    if stats is None:
        print("The scorecard could not be read: is the cardStats function deployed?", file=sys.stderr)
        return 1
    if args.json:
        print(json.dumps(stats, ensure_ascii=False, indent=1))
        return 0
    sys.stdout.write(summary(stats, check.load_bank()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
