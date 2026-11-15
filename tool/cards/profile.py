"""Everything known about a card, in one place: what it is, where it came from,
and how readers take it — for deciding what to remake, cut or keep.

The owner: every card should carry its properties and its numbers, kept up
to date, so it can be changed later knowing how it does. The card's own JSON
says what it is (subject, genre, kind, difficulty, era, hook, mood and the
rest); its page, if it has one, how it is drawn; the repository's history,
when it was written and how often it was changed; and the scorecard the
server adds up every night (functions/src/scorecard.ts, served at
`cardStats`), how readers take it: how many met it, answered it, got it
right, kept it, threw it down, and how long they stayed. Nothing about who.

The numbers are read live, so a profile is always today's.

    python3 tool/cards/profile.py space-aerogel-comet-catch     # one card
    python3 tool/cards/profile.py --worst 20                    # the cards readers take worst
    python3 tool/cards/profile.py --all --out profiles.json     # every card, for a spreadsheet
    python3 tool/cards/profile.py --all --stats saved.json ...  # from a saved scorecard
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))

import check  # noqa: E402

STATS_URL = "https://europe-west1-astuto-3d398.cloudfunctions.net/cardStats"

# The cards whose pages have been photographed for the small pictures the app
# shows outside the deck (tool/cards/thumbs.cjs).
_INDEX = ROOT / "web" / "cards" / "thumbs" / "index.json"
PICTURED = set(json.loads(_INDEX.read_text(encoding="utf-8"))) if _INDEX.exists() else set()

# What a card's JSON says it is, in the order a person reads it.
PROPERTIES = [
    "topic", "genre", "strand", "kind", "difficulty", "principle", "era", "region",
    "hook", "mood", "numeracy", "abstraction", "shelf_life", "mature", "figure",
    "source_kind", "place", "checked",
]


def fetch_stats(url: str = STATS_URL) -> dict:
    """The scorecard the server keeps; empty when it cannot be read."""
    try:
        with urllib.request.urlopen(url, timeout=20) as response:
            return json.loads(response.read().decode("utf-8"))
    except Exception as error:
        print(f"the scorecard could not be read ({error}); profiles without numbers", file=sys.stderr)
        return {}


def history() -> dict[str, dict]:
    """When each card was first written and last changed, and how many times,
    from one pass over the repository's history of the bank."""
    out: dict[str, dict] = {}
    try:
        log = subprocess.run(
            ["git", "log", "--format=@%ad", "--date=short", "--name-only", "--", "tool/cards/bank"],
            cwd=ROOT, capture_output=True, text=True, timeout=300, check=True,
        ).stdout
    except Exception:
        return out
    day = None
    for line in log.splitlines():
        if line.startswith("@"):
            day = line[1:]
            continue
        m = re.match(r"tool/cards/bank/[^/]+/(.+)\.(json|html)$", line)
        if not m or day is None:
            continue
        h = out.setdefault(m.group(1), {"written": day, "changed": day, "changes": 0})
        # The log runs newest first: the last day seen is the first written.
        h["written"] = day
        h["changes"] += 1
    return out


def words(text: str) -> int:
    return len(re.findall(r"\w+", text or ""))


def profile(card: dict, stats: dict, past: dict[str, dict]) -> dict:
    cid = card["id"]
    web = card.get("web") or {}
    html = card.get("_html") or ""
    p: dict = {"id": cid, "question": card.get("question", "")}
    p["properties"] = {k: card[k] for k in PROPERTIES if k in card}
    p["shape"] = {
        "drawn": "page" if html else "native",
        "touch": web.get("touch"),
        "pictures": cid in PICTURED,
        "question_words": words(card.get("question", "")),
        "answer_words": words(card.get("answer", "")),
        "page_kb": round(len(html.encode("utf-8")) / 1024, 1) if html else None,
        "slider": bool(re.search(r"type=[\"']?range", html)),
        "canvas": "<canvas" in html,
    }
    p["history"] = past.get(cid, {})
    n = (stats.get("cards") or {}).get(cid)
    readers: dict = {}
    if n:
        exposures = n.get("exposures") or 0
        answers = n.get("answers") or 0

        def rate(x: int, of: int) -> float | None:
            return round(x / of, 3) if of else None

        readers = {
            "met": exposures,
            "answered": answers,
            "right": n.get("right") or 0,
            "right_rate": rate(n.get("right") or 0, answers),
            "sure_and_wrong": n.get("sureWrong") or 0,
            "kept": n.get("kept") or 0,
            "keep_rate": rate(n.get("kept") or 0, exposures),
            "thrown": n.get("thrown") or 0,
            "throw_rate": rate(n.get("thrown") or 0, exposures),
            "seconds_per_reader": round((n.get("dwellMs") or 0) / 1000 / exposures, 1) if exposures else None,
        }
        if n.get("picks"):
            readers["picks"] = n["picks"]
    p["readers"] = readers
    p["flags"] = (stats.get("flags") or {}).get(cid, [])
    p["reports"] = (stats.get("reports") or {}).get(cid, {})
    p["quarantined"] = cid in set(stats.get("quarantined") or [])
    return p


def badness(p: dict) -> float:
    """How badly readers take a card, for ordering the ones to look at first:
    thrown down, reported, answered wrong far from its label, left quickly."""
    r = p["readers"]
    if not r:
        return -1.0
    score = (r.get("throw_rate") or 0) * 3 - (r.get("keep_rate") or 0) * 2
    score += len(p["reports"]) + (5 if p["quarantined"] else 0)
    score += 2 * sum(1 for f in p["flags"] if f in ("tooHard", "tooEasy", "keySuspect", "disputed", "thrown"))
    return round(score, 3)


def show(p: dict) -> str:
    lines = [f"# {p['id']}", "", p["question"], ""]
    for title, block in [("What it is", p["properties"]), ("How it is made", p["shape"]),
                         ("Its history", p["history"]), ("How readers take it", p["readers"])]:
        lines.append(f"## {title}")
        if not block:
            lines.append("- not enough readers yet" if title == "How readers take it" else "- nothing")
        for k, v in block.items():
            if v is not None:
                lines.append(f"- {k.replace('_', ' ')}: {v}")
        lines.append("")
    if p["flags"] or p["reports"] or p["quarantined"]:
        lines.append("## What the scorecard says")
        if p["quarantined"]:
            lines.append("- out of the deal until checked")
        for f in p["flags"]:
            lines.append(f"- flag: {f}")
        for reason, count in p["reports"].items():
            lines.append(f"- reported as {reason} ×{count}")
        lines.append("")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ids", nargs="*", help="the cards to profile")
    ap.add_argument("--all", action="store_true", help="every card in the bank")
    ap.add_argument("--worst", type=int, help="the N cards readers take worst")
    ap.add_argument("--out", type=Path, help="write the profiles as JSON here")
    ap.add_argument("--stats", type=Path, help="a saved scorecard instead of the server's")
    args = ap.parse_args(argv)

    bank = check.load_bank()
    by_id = {c["id"]: c for c in bank}
    stats = json.loads(args.stats.read_text(encoding="utf-8")) if args.stats else fetch_stats()
    past = history()
    if args.ids:
        unknown = [i for i in args.ids if i not in by_id]
        if unknown:
            print("not in the bank: " + ", ".join(unknown), file=sys.stderr)
            return 1
        chosen = [by_id[i] for i in args.ids]
    else:
        chosen = bank
    profiles = [profile(c, stats, past) for c in chosen]
    if args.worst:
        profiles = sorted((p for p in profiles if p["readers"]), key=badness, reverse=True)[: args.worst]
    if args.out:
        args.out.write_text(json.dumps({"at": stats.get("at"), "days": len(stats.get("days") or []),
                                        "cards": profiles}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        print(f"{len(profiles)} profiles written to {args.out}")
        return 0
    if args.all and not args.worst:
        print(json.dumps(profiles, ensure_ascii=False, indent=1))
        return 0
    if args.worst and not profiles:
        print("No card has enough readers yet for the scorecard to say how it is taken.")
        return 0
    print("\n\n".join(show(p) for p in profiles))
    return 0


if __name__ == "__main__":
    sys.exit(main())
