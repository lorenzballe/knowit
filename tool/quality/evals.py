"""How good the critic is, measured.

The critic is the last thing between a card and the readers, and nothing
said how often it is right. This hands it a set it has not seen: cards from
the bank as they are, and the same kind of card with one error planted in
each (mutate.py) — a figure off by ten, the wrong option marked right, a
year moved, a source from another card. It asks the critic exactly as the
night does (the same rules, the same tools, the card's own quote as the
reader's passage) and counts how many planted errors it stopped and how
many good cards it threw out (evalset.py).

Run it when the rules or the critic's prompt change, and once a month: a
change that makes the night cheaper and the critic blinder shows up here
before it shows up in a reader's report.

    python3 tool/quality/evals.py --per-kind 4 --batch --report evals.md
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import common  # noqa: F401  (puts tool/cards on the path)
import evalset


def reading_of(card: dict):
    """The passage the critic is shown, as at night: the card's own quote."""
    import generate

    if not card.get("quote"):
        return None
    return generate.Reading(supported=True, quote=card["quote"], figures="", note="")


def ask(items: list[evalset.Item], model, *, offline: bool = False) -> dict[str, dict]:
    """The critic's verdict on every item, by item id."""
    import generate

    rules = generate.RULES.read_text(encoding="utf-8")
    tools = None if offline else [generate._web_search(generate.CRITIC_SEARCHES), generate._web_fetch(2)]
    specs = [generate.Spec(generate.critic_system(rules),
                           [{"role": "user", "content": generate.critic_brief(item.card, reading_of(item.card))}],
                           generate.Verdict, tools=tools) for item in items]
    out: dict[str, dict] = {}
    for item, result in zip(items, generate.calls(model, specs, "eval")):
        if result.error or result.parsed is None:
            out[item.id] = {"verdict": "", "why": result.error or "no verdict came back"}
        else:
            out[item.id] = {"verdict": result.parsed.verdict, "why": result.parsed.reason}
    return out


def main(argv: list[str] | None = None) -> int:
    import check
    import generate

    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--per-kind", type=int, default=4, help="planted cards per kind of error (default: %(default)s)")
    ap.add_argument("--seed", type=int, default=1, help="which set: the same seed asks the same questions")
    ap.add_argument("--model", choices=sorted(generate.PRICES), default=generate.MODEL)
    ap.add_argument("--batch", action="store_true")
    ap.add_argument("--offline", action="store_true", help="no web tools: what the critic catches from the card alone")
    ap.add_argument("--fake", action="store_true", help="a canned critic that passes everything: proves the plumbing")
    ap.add_argument("--report", type=Path, help="write the score as markdown here")
    ap.add_argument("--json", type=Path, help="write every item and verdict here")
    args = ap.parse_args(argv)

    items = evalset.build(check.load_bank(), per_kind=args.per_kind, seed=args.seed)
    if args.fake:
        model = generate.Fake()
    else:
        if not os.environ.get("ANTHROPIC_API_KEY"):
            print("ANTHROPIC_API_KEY is not set; the critic was not asked.", file=sys.stderr)
            return 2
        model = generate.Claude(args.model, batch=args.batch)
    verdicts = ask(items, model, offline=args.offline)
    score = evalset.score(items, verdicts)
    text = evalset.report(score) + f"\n{len(items)} cards, seed {args.seed}, {'offline' if args.offline else 'with the web tools'}.\n\nReceipt:\n\n```\n{model.receipt()}\n```\n"
    if args.report:
        args.report.write_text(text, encoding="utf-8")
    if args.json:
        args.json.write_text(json.dumps({
            "catch_rate": score.catch_rate,
            "false_alarm_rate": score.false_alarm_rate,
            "by_kind": score.by_kind,
            "items": [{"id": i.id, "planted": i.planted, "detail": i.detail, **verdicts.get(i.id, {})} for i in items],
        }, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
