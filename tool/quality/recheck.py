"""The cards already out, checked again.

A card is true the day it is written. A figure that moves — a population,
a price, a record — stops being true on its own, and a card readers say is
wrong may be. Once a month this takes the cards that most need it and puts
each one in front of the critic again, told it is checking a card that is
live rather than a new one:

1. cards in quarantine — readers said they are untrue, and the dealer has
   stopped dealing them (functions/src/scorecard.ts);
2. cards readers dispute or report, or whose marked answer the crowd
   overwhelmingly rejects, not checked in the last month;
3. cards whose answer can change, by their shelf life: within months,
   checked more than three months ago; within years, more than a year ago.

What it does with each verdict:

- pass: the card gets today as its `checked` date, which also answers the
  reports made before it and lets it out of quarantine;
- fix: the corrected card waits in tool/cards/review/ for a person, beside
  the card that stays live until then (review.py);
- reject: the card is retired (`disabled`), and the pull request says why.

Nothing here is merged by itself: the run opens a pull request a person
reads, as they would read any change to cards that are already out.

With --sources it takes instead the cards whose only source is a retelling
(a video, a post) and asks the critic for the primary source behind them:
the study, the institution, the data. A correction that changes nothing but
the source goes into the bank (the pull request still shows it); one that
would change what the card says waits for a person, as every correction
does; a claim the critic doubts is listed for a person and never retired
here. A card for which nothing better was found is stamped checked, and
asked about again only after half a year.

    python3 tool/quality/recheck.py --limit 20 --batch --report recheck.md
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
import urllib.request
from dataclasses import dataclass
from pathlib import Path

import common

# How long a card's answer is trusted before it is checked again, by shelf
# life. An evergreen card is checked again only when readers say so.
INTERVAL_DAYS = {"months": 90, "years": 365}

# A card readers flagged is not checked again within this many days of the
# last check, so one stubborn flag cannot cost a check every month.
FLAG_REST_DAYS = 30

# A source that is a retelling rather than the thing itself: the claim may
# well be right, but the reader is sent to a video about the study instead
# of the study.
WEAK_SOURCE = re.compile(r"youtube|youtu\.be|geopop|tiktok|instagram|facebook|reddit", re.I)

# A card whose source was looked for and not bettered rests this long.
SOURCE_REST_DAYS = 180

# What a correction may touch and still go straight in: the citation only.
CITATION = {"source", "reference", "source_kind", "checked", "quote"}

SOURCES = """This card's only source is a retelling: {source}. Find the primary
source its claims come from (the paper, the institution's own page, the
official statistics, the book) and open it with the fetch tool.
- If a page you opened states every claim and figure on the card, the
  verdict is fix: the same card, word for word, with only `source` (author or
  body, title, year), `reference` (the address you opened) and `source_kind`
  changed. Change nothing else.
- If the claims hold but you could not open a primary source that states
  them, the verdict is pass.
- If a claim does not hold, the verdict is reject, and the reason says which
  claim and what the source says instead."""

RECHECK = """This card is already live: readers have been reading it since {written}{checked}. You
are checking that it still holds today, not judging it as a new card.

Why it is being checked: {why}.

Open the reference, or the newest edition of the same source, and check
every claim and figure in the answer, the steps and the options against it.
A figure that has since changed is a fix: give today's figure, and set the
reference to the page that states it. A claim that no longer holds, or that
you cannot find stated anywhere you would cite, is a reject. Everything else
about the card stood when it was written: do not reopen its style, its trap
or its tags unless they make it untrue."""


@dataclass
class Due:
    card: dict
    why: str
    rank: int


def last_checked(card: dict) -> dt.date:
    for key in ("checked", "written"):
        value = card.get(key)
        if isinstance(value, str):
            try:
                return dt.date.fromisoformat(value)
            except ValueError:
                pass
    return dt.date(2026, 9, 1)


def fetch_stats(url: str = common.STATS_URL, timeout: int = 20) -> dict | None:
    """The scorecard the server keeps, or None when it cannot be read."""
    try:
        with urllib.request.urlopen(url, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))
    except Exception as error:  # the re-check by age still runs without it
        print(f"the scorecard could not be read ({error}); checking by age only", file=sys.stderr)
        return None


def due(bank: list[dict], stats: dict | None, today: dt.date, limit: int) -> list[Due]:
    """The cards most in need of a check, most needed first, at most [limit]."""
    flags: dict[str, list[str]] = (stats or {}).get("flags") or {}
    quarantined = set((stats or {}).get("quarantined") or [])
    reports: dict[str, dict] = (stats or {}).get("reports") or {}
    out: list[Due] = []
    for card in bank:
        if card.get("disabled"):
            continue
        cid = card["id"]
        f = flags.get(cid, [])
        since = (today - last_checked(card)).days
        said = ", ".join(f"{reason} ×{n}" for reason, n in sorted(reports.get(cid, {}).items()))
        if cid in quarantined:
            out.append(Due(card, f"readers say it is untrue ({said}), and it is out of the deal until checked", 0))
        elif ("disputed" in f or "keySuspect" in f) and since >= FLAG_REST_DAYS:
            what = []
            if "disputed" in f:
                what.append(f"readers dispute it ({said})")
            if "keySuspect" in f:
                what.append("almost every reader picks one other option over the one marked right")
            out.append(Due(card, " and ".join(what), 1))
        elif "reported" in f and since >= FLAG_REST_DAYS:
            out.append(Due(card, f"readers reported it ({said})", 2))
        else:
            interval = INTERVAL_DAYS.get(card.get("shelf_life", ""))
            if interval is not None and since >= interval:
                out.append(Due(card, f"its answer can change within {card['shelf_life']}, and it was last checked {last_checked(card).isoformat()}", 3))
    out.sort(key=lambda d: (d.rank, last_checked(d.card), d.card["id"]))
    return out[:limit]


def due_sources(bank: list[dict], today: dt.date, limit: int) -> list[Due]:
    """The cards whose only source is a retelling, not looked at in the last
    half year, at most [limit], in the order of their ids."""
    out: list[Due] = []
    for card in bank:
        if card.get("disabled"):
            continue
        if not WEAK_SOURCE.search(f"{card.get('source', '')} {card.get('reference', '')}"):
            continue
        if card.get("checked") and (today - last_checked(card)).days < SOURCE_REST_DAYS:
            continue
        out.append(Due(card, "its only source is a video or a post, not the study, the institution or the data behind it", 4))
    out.sort(key=lambda d: d.card["id"])
    return out[:limit]


def brief(d: Due, *, sources: bool = False) -> str:
    import generate

    card = d.card
    reading = None
    if card.get("quote"):
        reading = generate.Reading(supported=True, quote=card["quote"], figures="", note="")
    checked = f", and it was last checked {card['checked']}" if card.get("checked") else ""
    text = generate.critic_brief(card, reading) + "\n\n" + RECHECK.format(
        written=card.get("written", "before the records began"), checked=checked, why=d.why)
    if sources:
        text += "\n\n" + SOURCES.format(source=card.get("source", ""))
    return text


def only_citation(original: dict, proposal: dict) -> bool:
    """Whether [proposal] differs from [original] in the citation alone."""
    keys = (set(original) | set(proposal)) - CITATION - {k for k in set(original) | set(proposal) if k.startswith("_")}
    return all(original.get(k) == proposal.get(k) for k in keys)


@dataclass
class Result:
    id: str
    verdict: str
    reason: str
    action: str


IDENTITY = ("id", "topic", "genre", "strand", "also", "kind", "language", "written", "builds_on", "scene", "diagram", "figure")


def corrected(original: dict, fixed: dict, today: dt.date) -> dict:
    """The critic's correction on top of the live card: what the card is stays."""
    card = {k: v for k, v in original.items() if not k.startswith("_")}
    for key, value in fixed.items():
        if key in IDENTITY:
            continue
        card[key] = value
    if card.get("reference") != original.get("reference"):
        # The quote was copied from the old page; the new one has not been read.
        card.pop("quote", None)
    card["checked"] = today.isoformat()
    return card


def apply(verdicts: list[tuple[Due, object]], *, today: dt.date, bank_root: Path = common.BANK,
          review: Path = common.REVIEW, sources: bool = False) -> list[Result]:
    """Does what each verdict says, to the files. Looking for sources, a
    correction to the citation alone goes straight in, and a doubt is left
    for a person rather than retired."""
    import check
    import generate

    schema = check.load_schema()
    banned = check.load_banned()
    queue_path = review / "queue.json"
    queue = common.read_queue(queue_path)
    out: list[Result] = []
    for d, result in verdicts:
        card = {k: v for k, v in d.card.items() if not k.startswith("_")}
        path = bank_root / card["topic"] / f"{card['id']}.json"
        if result is None or getattr(result, "error", None) or getattr(result, "parsed", None) is None:
            out.append(Result(card["id"], "none", getattr(result, "error", None) or "no verdict came back", "left as it was"))
            continue
        verdict = result.parsed
        if verdict.verdict == "pass":
            card["checked"] = today.isoformat()
            common.write_card(card, path)
            out.append(Result(card["id"], "pass", verdict.reason, f"checked {today.isoformat()}"))
        elif verdict.verdict == "fix" and verdict.fixed is not None:
            proposal = corrected(card, generate.to_card(verdict.fixed), today)
            problems = check.check_card(proposal, strict=True, schema=schema, banned=banned)
            # A new citation and nothing else goes straight in, so long as
            # it brings the card no problem it did not have: an old card
            # held to a rule written after it is no reason to keep citing a
            # video.
            if sources and only_citation(card, proposal) and proposal.get("reference") and not WEAK_SOURCE.search(
                    f"{proposal.get('source', '')} {proposal.get('reference', '')}"):
                before = set(check.check_card(card, strict=True, schema=schema, banned=banned))
                if set(problems) <= before:
                    common.write_card(proposal, path)
                    out.append(Result(card["id"], "source", verdict.reason, f"now cites {proposal.get('source', '')}"))
                    continue
            if problems:
                out.append(Result(card["id"], "fix", verdict.reason, "the correction did not pass the gate, so the card is left for a person: " + "; ".join(problems)))
                continue
            common.write_card(proposal, review / f"{card['id']}.json")
            queue = [e for e in queue if e["id"] != card["id"]] + [{
                "id": card["id"], "topic": card["topic"], "question": proposal.get("question", ""),
                "score": 0, "why": [f"the re-check proposes a correction: {verdict.reason}"], "audit": False,
                "since": today.isoformat(), "from": "recheck",
            }]
            out.append(Result(card["id"], "fix", verdict.reason, "a correction waits for a person in the review issue"))
        elif verdict.verdict == "reject" and sources:
            out.append(Result(card["id"], "doubt", verdict.reason, "left live, for a person to look at"))
        elif verdict.verdict == "reject":
            card["disabled"] = True
            common.write_card(card, path)
            out.append(Result(card["id"], "reject", verdict.reason, "retired"))
        else:
            out.append(Result(card["id"], verdict.verdict, verdict.reason, "left as it was"))
    common.write_queue(queue, queue_path)
    return out


def report(results: list[Result], due_cards: list[Due], receipt: str, today: dt.date) -> str:
    why = {d.card["id"]: d.why for d in due_cards}
    lines = [f"## The re-check · {today:%-d %B %Y}", "", f"{len(results)} card{'s' if len(results) != 1 else ''} checked again.", ""]
    for heading, verdict in (("A primary source found", "source"), ("Still true", "pass"), ("A correction proposed", "fix"),
                             ("Doubted, for a person", "doubt"), ("Retired", "reject"), ("No verdict", "none")):
        some = [r for r in results if r.verdict == verdict]
        if not some:
            continue
        lines += [f"### {heading} ({len(some)})", ""]
        for r in some:
            lines.append(f"- `{r.id}` — {r.reason} *({r.action}; checked because {why.get(r.id, '?')})*")
        lines.append("")
    lines += ["Receipt:", "", "```", receipt, "```", "",
              "Merging stamps the cards that held, retires the ones that did not, and publishes both; "
              "the corrections wait in the issue labelled `cards-review`."]
    return "\n".join(lines) + "\n"


def run(due_cards: list[Due], model, *, sources: bool = False) -> list[tuple[Due, object]]:
    import generate

    rules = generate.RULES.read_text(encoding="utf-8")
    specs = [generate.Spec(generate.critic_system(rules), [{"role": "user", "content": brief(d, sources=sources)}], generate.Verdict,
                           tools=[generate._web_search(generate.CRITIC_SEARCHES), generate._web_fetch(2)]) for d in due_cards]
    return list(zip(due_cards, generate.calls(model, specs, "recheck")))


def main(argv: list[str] | None = None) -> int:
    import check
    import generate

    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--limit", type=int, default=20, help="at most this many cards (default: %(default)s)")
    ap.add_argument("--today", help="YYYY-MM-DD")
    ap.add_argument("--model", choices=sorted(generate.PRICES), default=generate.MODEL)
    ap.add_argument("--batch", action="store_true")
    ap.add_argument("--fake", action="store_true", help="a canned critic that passes everything: proves the plumbing")
    ap.add_argument("--stats", help="a scorecard JSON file instead of the server's")
    ap.add_argument("--dry-run", action="store_true", help="say which cards are due; call nothing")
    ap.add_argument("--report", type=Path)
    ap.add_argument("--sources", action="store_true", help="the cards whose only source is a video or a post: find the primary one")
    args = ap.parse_args(argv)

    today = dt.date.fromisoformat(args.today) if args.today else dt.date.today()
    bank = check.load_bank()
    if args.sources:
        due_cards = due_sources(bank, today, args.limit)
    else:
        stats = json.loads(Path(args.stats).read_text(encoding="utf-8")) if args.stats else fetch_stats()
        due_cards = due(bank, stats, today, args.limit)
    if args.dry_run or not due_cards:
        print(f"{len(due_cards)} card{'s' if len(due_cards) != 1 else ''} due:")
        for d in due_cards:
            print(f"  {d.card['id']}: {d.why}")
        return 0
    if args.fake:
        model = generate.Fake()
    else:
        if not os.environ.get("ANTHROPIC_API_KEY"):
            print("ANTHROPIC_API_KEY is not set; nothing was checked. Use --dry-run to see what is due.", file=sys.stderr)
            return 2
        model = generate.Claude(args.model, batch=args.batch)
    results = apply(run(due_cards, model, sources=args.sources), today=today, sources=args.sources)
    text = report(results, due_cards, model.receipt(), today)
    if args.report:
        args.report.write_text(text, encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
