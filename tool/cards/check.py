#!/usr/bin/env python3
"""The gate: what a card has to be before it may go in the bank.

    python3 tool/cards/check.py                 # the whole bank
    python3 tool/cards/check.py --strict a.json # generated cards, held higher

Two levels. The bank is checked against the floor every card must clear:
shape, limits, the listicle, no two cards asking the same thing, and a
calendar that names real questions. A *generated* card is also checked
against the rules the model was given — the tighter word counts, a real
reference, the forbidden words — because those are the rules of the house
and the house was built after the first hundred and seventy.

Everything here is deterministic. Whether the answer is *true* is not a
thing a regex can know; that is the critic's job, in generate.py, and then
the reviewer's.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

try:
    import jsonschema
except ImportError:  # pragma: no cover - the workflow installs it
    jsonschema = None

HERE = Path(__file__).resolve().parent
BANK = HERE / "bank"
SCHEMA = HERE / "schema.json"
BANNED = HERE / "banned.txt"
EDITIONS = HERE / "editions.json"

GRADED = {"pickOne", "number", "estimate"}
ASKS = GRADED | {"debate"}

# A question of the day may not come round again within this many editions.
# Two months, whatever the pool: the calendar is frozen, so the window it was
# built with is what it is judged by, not the pool it happens to sit over.
EDITION_GAP = 60

# Words that carry nothing, for telling two questions apart. The same list
# the app's own test uses, so the two never disagree about what a twin is.
NOISE = {
    "the", "a", "an", "is", "are", "was", "were", "do", "does", "did",
    "you", "your", "we", "it", "its", "of", "in", "on", "to", "for", "why",
    "how", "what", "when", "where", "which", "who", "and", "or", "but",
    "so", "that", "this", "than", "then", "from", "at", "by", "with", "as",
    "be", "can", "could", "would", "should", "have", "has", "not", "no",
    "if", "there", "their", "they", "one", "about", "up", "out", "get",
    "got", "make", "made", "much", "many", "more", "most", "actually",
    "really", "ever", "still", "own",
}

# Not banned material; banned *voice*. A generated card with one of these
# is sent back — the pool was written without them and reads better for it.
FORBIDDEN_STRICT = [
    "did you know",
    "interestingly",
    "fascinating",
    "surprisingly",
    "it's important to",
    "it is important to",
    "in conclusion",
    "remember that",
    "you might think",
    "you probably think",
    "fun fact",
    "mind-blowing",
    "mind blowing",
]


def words(text: str) -> int:
    text = text.strip()
    return len(re.split(r"\s+", text)) if text else 0


def content_words(question: str) -> set[str]:
    cleaned = re.sub(r"[^a-z0-9 ]", " ", question.lower())
    return {w for w in cleaned.split() if len(w) > 2 and w not in NOISE}


def load_banned(path: Path = BANNED) -> list[str]:
    out = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            out.append(line.lower())
    return out


def load_schema(path: Path = SCHEMA) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_bank(root: Path = BANK) -> list[dict]:
    """Every card in the bank, in a stable order: by topic, then by id."""
    cards = []
    for path in sorted(root.glob("*/*.json")):
        card = json.loads(path.read_text(encoding="utf-8"))
        card["_path"] = str(path.relative_to(root.parent))
        cards.append(card)
    cards.sort(key=lambda c: (c.get("topic", ""), natural(c.get("id", ""))))
    return cards


def natural(s: str) -> list:
    return [int(t) if t.isdigit() else t for t in re.split(r"(\d+)", s)]


def public(card: dict) -> dict:
    """The card without the bookkeeping keys this module adds."""
    return {k: v for k, v in card.items() if not k.startswith("_")}


# --------------------------------------------------------------------------
# One card

def check_card(card: dict, *, strict: bool = False, schema: dict | None = None,
               banned: list[str] | None = None) -> list[str]:
    """Everything wrong with one card, as short sentences. Empty means fine."""
    problems: list[str] = []
    card = public(card)

    if schema is not None and jsonschema is not None:
        validator = jsonschema.Draft202012Validator(schema)
        for err in sorted(validator.iter_errors(card), key=lambda e: list(e.path)):
            where = "/".join(str(p) for p in err.path) or "card"
            problems.append(f"{where}: {err.message}")
        if problems:
            return problems  # the rest assumes the shape is right

    cid = card["id"]
    topic = card["topic"]
    kind = card["kind"]
    q = card["question"].strip()
    a = card.get("answer", "").strip()
    move = card["move"].strip()
    trap = card.get("trap", "").strip()
    steps = card.get("steps", [])
    principle = card["principle"]
    difficulty = card["difficulty"]

    # The shape each kind has to have.
    if kind == "read":
        for key in ("options", "correct", "value", "unit", "sides", "steps", "hint", "counterpoint"):
            if key in card:
                problems.append(f"a read card has no {key}")
        if principle != "none":
            problems.append("a read card carries no principle; the principle is what a card *asks*")
        if difficulty != "easy":
            problems.append("a read card is easy: nothing to work out")
        if not q.endswith("?"):
            problems.append("a read card is a question")
    elif kind == "pickOne":
        if "options" not in card or "correct" not in card:
            problems.append("a pickOne card has options and a correct index")
        else:
            if not 0 <= card["correct"] < len(card["options"]):
                problems.append("correct is not one of the options")
            if len({o.strip().lower() for o in card["options"]}) != len(card["options"]):
                problems.append("two options are the same option")
            for o in card["options"]:
                if words(o) > 12:
                    problems.append(f"an option runs past twelve words: {o!r}")
        if not trap:
            problems.append("a pickOne card names its trap")
        if principle == "none":
            problems.append("a graded card carries a principle")
        for key in ("value", "unit", "sides"):
            if key in card:
                problems.append(f"a pickOne card has no {key}")
    elif kind in ("number", "estimate"):
        if "value" not in card:
            problems.append(f"a {kind} card has a value")
        if not steps:
            problems.append(f"a {kind} card shows its steps")
        if not card.get("hint", "").strip():
            problems.append(f"a {kind} card has a hint")
        if principle == "none":
            problems.append("a graded card carries a principle")
        if kind == "estimate" and card.get("value", 1) <= 0:
            problems.append("an estimate is of something positive")
        for key in ("options", "correct", "sides"):
            if key in card:
                problems.append(f"a {kind} card has no {key}")
    elif kind == "debate":
        if "sides" not in card:
            problems.append("a debate has two sides")
        if not card.get("counterpoint", "").strip():
            problems.append("a debate carries the other side's strongest case")
        if principle != "none":
            problems.append("a debate is ungraded and carries no principle")
        for key in ("options", "correct", "value", "unit", "steps", "trap"):
            if key in card:
                problems.append(f"a debate has no {key}")

    if kind in ASKS and difficulty == "easy":
        problems.append("a card that asks is at least medium")
    if kind in ASKS and not (q.endswith("?") or q.endswith(".")):
        problems.append("a question ends with ? or a full stop")

    # The floor on words, which the first pool set.
    if not 3 <= words(q) <= 40:
        problems.append(f"question is {words(q)} words; 3 to 40")
    if not a and not steps:
        problems.append("neither an answer nor a worked solution")
    if a and not steps and words(a) > 60:
        problems.append(f"answer runs past sixty words ({words(a)})")
    if not 4 <= words(move) <= 24:
        problems.append(f"move is {words(move)} words; 4 to 24")
    if trap and words(trap) > 20:
        problems.append(f"trap runs past twenty words ({words(trap)})")
    if card.get("counterpoint") and words(card["counterpoint"]) > 70:
        problems.append("counterpoint runs past seventy words")
    if not card.get("source", "").strip():
        problems.append("no source")

    # The listicle.
    hay = f"{q} {a}".lower()
    for phrase in banned or []:
        if phrase in hay:
            problems.append(f"built on banned material: {phrase!r}")

    if strict:
        problems.extend(check_strict(card))
    return problems


def check_strict(card: dict) -> list[str]:
    """The rules the model was given, held to the letter."""
    problems: list[str] = []
    kind = card["kind"]
    q = card["question"].strip()
    a = card.get("answer", "").strip()
    move = card["move"].strip()
    trap = card.get("trap", "").strip()
    steps = card.get("steps", [])

    if not card["id"].startswith(card["topic"] + "-"):
        problems.append(f"id {card['id']!r} does not start with its topic {card['topic']!r}")
    if not 6 <= words(q) <= 25:
        problems.append(f"question is {words(q)} words; the rule is 6 to 25")
    if kind in ("read", "pickOne", "debate") and not 30 <= words(a) <= 55:
        problems.append(f"answer is {words(a)} words; the rule is 30 to 55")
    if not 8 <= words(move) <= 15:
        problems.append(f"move is {words(move)} words; the rule is 8 to 15")
    if '"' in move or "“" in move:
        problems.append("the move carries no quotation marks")
    if trap and not 6 <= words(trap) <= 14:
        problems.append(f"trap is {words(trap)} words; the rule is 6 to 14")
    if kind == "pickOne":
        for o in card["options"]:
            if words(o) > 8:
                problems.append(f"option past eight words: {o!r}")
    if kind in ("number", "estimate") and not 2 <= len(steps) <= 5:
        problems.append(f"{len(steps)} steps; the rule is 2 to 5")
    if kind == "debate" and not 40 <= words(card.get("counterpoint", "")) <= 60:
        problems.append("counterpoint is outside 40 to 60 words")
    if kind == "debate" and not 40 <= words(a) <= 60:
        problems.append("the case is outside 40 to 60 words")
    ref = card.get("reference", "").strip()
    if not ref:
        problems.append("no reference: a generated card says where it can be checked")
    elif not (ref.startswith("http://") or ref.startswith("https://")
              or ref.lower().startswith("doi:") or ref.lower().startswith("isbn")
              or re.search(r"\b(19|20)\d{2}\b", ref)):
        problems.append("reference is not a URL, a DOI, an ISBN or a dated citation")
    if not card.get("written"):
        problems.append("no written date")
    if kind == "read" and card["principle"] != "none":
        problems.append("a read card has no principle")

    every_text = " ".join(
        str(v) for k, v in card.items()
        if isinstance(v, str) and k not in ("id", "topic", "kind", "reference", "written")
    )
    if "!" in every_text:
        problems.append("no exclamation marks")
    if any(ord(ch) > 0xFFFF for ch in every_text):
        problems.append("no emoji")
    low = every_text.lower()
    for phrase in FORBIDDEN_STRICT:
        if phrase in low:
            problems.append(f"forbidden phrase: {phrase!r}")
    return problems


# --------------------------------------------------------------------------
# The bank as a whole

def check_twins(cards: list[dict], against: list[dict] | None = None) -> list[str]:
    """Cards asking the same thing, by content words — the app's own test."""
    problems = []
    pool = against if against is not None else cards
    sets = {c["id"]: content_words(c["question"]) for c in pool}
    for c in cards:
        sets.setdefault(c["id"], content_words(c["question"]))
    ids = [c["id"] for c in cards]
    others = [c["id"] for c in pool]
    seen_pairs = set()
    for i in ids:
        a = sets[i]
        if len(a) < 4:
            continue
        for j in others:
            if i == j or (j, i) in seen_pairs:
                continue
            seen_pairs.add((i, j))
            b = sets[j]
            if len(b) < 4:
                continue
            overlap = len(a & b) / len(a | b)
            if overlap >= 0.5:
                problems.append(f"{i} and {j} are asking the same thing")
    moves = {}
    for c in pool + [c for c in cards if c not in pool]:
        key = re.sub(r"[^a-z0-9 ]", "", c["move"].lower()).strip()
        if key in moves and moves[key] != c["id"]:
            problems.append(f"{c['id']} repeats the move of {moves[key]}")
        moves.setdefault(key, c["id"])
    return problems


def check_editions(editions: dict, cards: list[dict]) -> list[str]:
    problems = []
    by_id = {c["id"]: c for c in cards}
    keys = sorted(int(k) for k in editions)
    if keys and keys != list(range(1, keys[-1] + 1)):
        problems.append("editions are not consecutive from 1")
    last_seen: dict[str, int] = {}
    for e in keys:
        cid = editions[str(e)]
        card = by_id.get(cid)
        if card is None:
            problems.append(f"edition {e} names {cid}, which is not in the bank")
            continue
        if card["kind"] not in GRADED:
            problems.append(f"edition {e} is {cid}, which cannot be marked")
        if card.get("disabled"):
            problems.append(f"edition {e} is {cid}, which is retired")
        if cid in last_seen and e - last_seen[cid] < EDITION_GAP:
            problems.append(f"{cid} comes back at edition {e}, {e - last_seen[cid]} days after {last_seen[cid]}")
        last_seen[cid] = e
    return problems


def check_bank(cards: list[dict], editions: dict | None = None, *, strict: bool = False) -> dict[str, list[str]]:
    """Every problem in the bank, keyed by card id (or '*' for the whole)."""
    schema = load_schema()
    banned = load_banned()
    out: dict[str, list[str]] = {}
    seen = set()
    for c in cards:
        problems = check_card(c, strict=strict, schema=schema, banned=banned)
        if c["id"] in seen:
            problems.append("id used twice")
        seen.add(c["id"])
        if problems:
            out[c["id"]] = problems
    whole = check_twins(cards)
    if editions is not None:
        whole += check_editions(editions, cards)
    if whole:
        out["*"] = whole
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="*", help="card files to check against the bank; none means the bank itself")
    ap.add_argument("--strict", action="store_true", help="hold the cards to the generation rules")
    args = ap.parse_args(argv)

    bank = load_bank()
    if args.files:
        schema, banned = load_schema(), load_banned()
        bad = 0
        fresh = [json.loads(Path(f).read_text(encoding="utf-8")) for f in args.files]
        for path, card in zip(args.files, fresh):
            problems = check_card(card, strict=args.strict, schema=schema, banned=banned)
            for p in problems:
                print(f"{path}: {p}")
            bad += bool(problems)
        for p in check_twins(fresh, against=bank):
            print(f"*: {p}")
            bad += 1
        print(f"{len(fresh) - bad} of {len(fresh)} pass" if bad else f"all {len(fresh)} pass")
        return 1 if bad else 0

    editions = json.loads(EDITIONS.read_text(encoding="utf-8")) if EDITIONS.exists() else None
    report = check_bank(bank, editions, strict=args.strict)
    for cid, problems in report.items():
        for p in problems:
            print(f"{cid}: {p}")
    if report:
        print(f"{len(report)} problem{'s' if len(report) != 1 else ''} in {len(bank)} cards")
        return 1
    print(f"{len(bank)} cards, {len(editions or {})} editions: all clear")
    return 0


if __name__ == "__main__":
    sys.exit(main())
