#!/usr/bin/env python3
"""Tags cards that have none, or names ones again.

    python3 tool/cards/tag.py --missing              # every card without tags
    python3 tool/cards/tag.py space-2 thinking-7     # these cards, again
    python3 tool/cards/tag.py --missing --dry-run    # who would be asked about
    python3 tool/cards/tag.py --missing --fake       # the plumbing, no model

The model reads one card and the strands its subject has, and returns the
tags of RULES.md §19. The gate checks them like any other field, the model
gets one round to fix what it named, and a card whose tags still fail is
left as it was and listed. Nothing else in the card is touched; the file is
rewritten in the house order.

Needs ANTHROPIC_API_KEY in the environment, like generate.py.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import check
import generate
import genres

HERE = Path(__file__).resolve().parent


def untagged(card: dict) -> bool:
    return any(k not in card for k in check.TAG_KEYS)


def rules_for_tags() -> str:
    """Section 19 of the rules, and the topics, which is all a tagger needs."""
    rules = generate.RULES.read_text(encoding="utf-8")
    start = rules.index("## 19. The tags")
    end = rules.find("\n## ", start + 1)
    section = rules[start:] if end < 0 else rules[start:end]
    return (
        "You tag cards for Astute. You are given one card, already written and checked; "
        "you only say what it is about and like, in the vocabulary below. Change nothing else.\n\n"
        + section
    )


def brief(card: dict) -> str:
    lines = []
    strands = genres.strands_of(card["topic"])
    if strands:
        lines.append(f"The strands under {card['topic']}, by genre — choose the one the card is about:")
        for g in genres.by_topic()[card["topic"]]:
            lines.append(f"- {g.label} ({g.id}): " + "; ".join(f"{s.label} ({s.id})" for s in g.strands))
    else:
        lines.append("This is a thinking card: it has no genre and no strand; leave both empty.")
    lines += ["", "The card:", "", "```json", json.dumps(check.public(card), ensure_ascii=False, indent=1), "```"]
    return "\n".join(lines)


def apply(card: dict, tags: generate.Tags) -> dict:
    out = dict(card)
    for key in ("genre", "strand"):
        out.pop(key, None)
    if card["topic"] != "thinking":
        out["genre"], out["strand"] = tags.genre.strip(), tags.strand.strip()
    out.update(generate.described(tags))
    out.setdefault("language", "en")
    return out


def tag_cards(cards: list[dict], model, bank: list[dict], *, write: bool = True, log=print) -> list[tuple[dict, list[str]]]:
    """Tags each of [cards]; returns what was left untagged, with why."""
    system = rules_for_tags()
    schema, banned = check.load_schema(), check.load_banned()
    failed: list[tuple[dict, list[str]]] = []
    for card in cards:
        log(f"· {card['id']}")
        try:
            tagged = apply(card, model.tag(system, brief(card)))
            problems = check.check_card(tagged, schema=schema, banned=banned) + check.check_links([tagged], against=bank)
            if problems:
                log("  gate: " + "; ".join(problems))
                again = brief(card) + "\n\nThe gate refused those tags:\n" + "\n".join(f"- {p}" for p in problems) + "\n\nReturn the tags again, corrected."
                tagged = apply(card, model.tag(system, again))
                problems = check.check_card(tagged, schema=schema, banned=banned) + check.check_links([tagged], against=bank)
            if problems:
                failed.append((card, problems))
                log("  left as it was")
                continue
            if write:
                path = check.BANK / card["topic"] / f"{card['id']}.json"
                path.write_text(json.dumps(check.ordered(tagged), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            log("  " + (genres.describe(tagged["strand"]) if tagged.get("strand") else "thinking") + " · " + ", ".join(tagged["keywords"]))
        except Exception as error:  # one card must not end the run
            failed.append((card, [f"{type(error).__name__}: {error}"]))
            log(f"  failed: {type(error).__name__}: {error}")
    return failed


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ids", nargs="*", help="cards to tag again")
    ap.add_argument("--missing", action="store_true", help="every card without tags")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--fake", action="store_true", help="a canned model: exercises everything but the judgement")
    args = ap.parse_args(argv)

    bank = check.load_bank()
    wanted = [c for c in bank if c["id"] in set(args.ids)] if args.ids else []
    if args.missing:
        wanted += [c for c in bank if untagged(c) and c not in wanted]
    if not wanted:
        print("nothing to tag")
        return 0
    if args.dry_run:
        for c in wanted:
            print(f"  {c['id']}  {c['question']}")
        print(f"{len(wanted)} card{'s' if len(wanted) != 1 else ''}")
        return 0
    if args.fake:
        model = generate.Fake()
    else:
        if not os.environ.get("ANTHROPIC_API_KEY"):
            print("ANTHROPIC_API_KEY is not set; nothing was tagged.", file=sys.stderr)
            return 2
        model = generate.Claude()
    failed = tag_cards(wanted, model, bank)
    print()
    print(f"{len(wanted) - len(failed)} of {len(wanted)} tagged · {model.receipt()}")
    for card, problems in failed:
        print(f"  {card['id']}: " + "; ".join(problems))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
