"""What to write next, worked out from what is already there.

Nothing here talks to a model. It reads the pool and the genre tree, works
out what the app runs out of first, and prints an ordered list of slots to
fill. That order is the whole argument: a pipeline that writes whatever is
easy to write produces a catalogue nobody can deal a day from.

The numbers it reports are not opinions:

  * A day is five cards, three that tell and two that ask (`kAskShare`).
  * The pool is 60 tells and 110 asks. Those two shapes do not match: the
    day eats tells half again as fast, and the pool holds fewer of them.
  * So the tells run out on day 20 with 72 asks still unread. Every scenario
    gives the same answer, because the dealer falls back to off-topic cards
    before it repeats one.

The brief is therefore dominated by tells until the two runways meet, and
inside that by the genres the readers actually asked for.

Run it:

    python3 tool/content/brief.py                # the table
    python3 tool/content/brief.py --json brief.json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
POOL = ROOT / "lib" / "data" / "pills_data.dart"
GENRES = ROOT / "lib" / "data" / "genres.dart"
REPOSITORY = ROOT / "lib" / "data" / "pills_repository.dart"
TOPICS = ROOT / "lib" / "data" / "topics.dart"

# How each card is built in the pool, and whether that kind asks anything.
# The pool is written through these five helpers and nothing else, which is
# what makes it readable from here without a Dart runtime.
KINDS = {
    "_p": ("tells", False),
    "_q": ("pick one", True),
    "_n": ("type a number", True),
    "_e": ("estimate", True),
    "_d": ("take a side", True),
}


@dataclass
class Card:
    """One card in the pool, as much of it as this needs to know."""

    id: str
    # The topic *key* — 'human_body', not 'Human body'. The helpers take the
    # key and look the style up themselves, so this is what the file holds.
    topic_key: str
    kind: str
    asks: bool
    question: str


@dataclass
class Slot:
    """One card asked for: a genre, a way of asking, and why it is wanted."""

    genre_id: str
    genre_label: str
    topic: str
    kind: str
    reason: str
    rank: float
    # Filled in by the writer, not here: the strand it lands on is the
    # writer's choice among the three, because which of them has a card
    # worth writing is not a thing arithmetic knows.
    strands: list[str] = field(default_factory=list)

    def as_json(self) -> dict:
        return {
            "genre": self.genre_id,
            "label": self.genre_label,
            "topic": self.topic,
            "kind": self.kind,
            "strands": self.strands,
            "reason": self.reason,
        }


def _fail(message: str) -> None:
    """Stops rather than guesses.

    Everything below reads Dart with regular expressions, which is fine
    exactly as long as the files keep the shape they have. A silent
    miscount here would produce a brief that commissions the wrong cards
    for a month, so a surprise is an error and not a warning.
    """
    sys.exit(f"tool/content/brief.py: {message}")


def read_pool() -> list[Card]:
    src = POOL.read_text(encoding="utf-8")
    cards: list[Card] = []
    openers = 0
    for helper, (kind, asks) in KINDS.items():
        for match in re.finditer(rf"\n  {re.escape(helper)}\(\s*\n", src):
            openers += 1
            chunk = src[match.end() : match.end() + 1200]
            strings = re.findall(r"'((?:[^'\\]|\\.)*)'", chunk)
            if len(strings) < 3:
                _fail(f"a {helper} card near offset {match.start()} has no id")
            cards.append(
                Card(
                    id=strings[0],
                    topic_key=strings[1],
                    kind=kind,
                    asks=asks,
                    question=strings[2],
                )
            )
    # Every `_x(` opener in the file has to have become a card. If the pool
    # gains a sixth helper, this is where it gets noticed.
    every = len(re.findall(r"\n  _[a-z]\(\s*\n", src))
    if every != openers:
        _fail(f"read {openers} cards but the file holds {every} — a new helper?")
    if not cards:
        _fail("the pool came back empty")
    return cards


def read_genres() -> dict[str, list[tuple[str, str, list[str]]]]:
    """The genre tree, by topic key: (id, label, strand labels)."""
    src = GENRES.read_text(encoding="utf-8")
    body = src[src.index("const Map<String, List<Genre>> kGenres") :]
    tree: dict[str, list[tuple[str, str, list[str]]]] = {}
    for topic_match in re.finditer(r"\n  '([a-z_]+)': \[", body):
        topic = topic_match.group(1)
        end = body.index("\n  ],", topic_match.end())
        chunk = body[topic_match.end() : end]
        genres = []
        for g in re.finditer(r"Genre\(\s*'([^']+)',\s*'([^']+)',\s*\[", chunk):
            g_end = chunk.index("]),", g.end())
            strands = re.findall(r"Strand\(\s*'[^']+',\s*'([^']+)'", chunk[g.end() : g_end])
            genres.append((g.group(1), g.group(2), strands))
        if len(genres) != 6:
            _fail(f"{topic} has {len(genres)} genres, expected six")
        tree[topic] = genres
    if not tree:
        _fail("the genre tree came back empty")
    return tree


def read_topic_names() -> dict[str, str]:
    """Topic key to the name the pool writes on a card.

    Read rather than derived. Title-casing the key gives "Human Body" and
    "Pop Culture", which match nothing, and a subject that matches nothing
    counts as empty — so the brief would have commissioned first cards for
    two subjects that already hold seven and five.
    """
    src = TOPICS.read_text(encoding="utf-8")
    body = src[src.index("final Map<String, TopicStyle> kTopics") :]
    names = dict(re.findall(r"'([a-z_]+)': _topic\(\s*'([^']+)'", body))
    if len(names) != 18:
        _fail(f"read {len(names)} subjects off the wheel, expected eighteen")
    # Thinking is built by hand in topics.dart rather than through _topic,
    # because it carries no hue. It is in the pool — more than half of it —
    # and it is deliberately not in the genre tree: it is not a subject, it
    # is not on the wheel, and it is never off the deck. So it is named here
    # and commissioned nowhere.
    names["thinking"] = "Thinking"
    return names


def day_shape() -> tuple[int, float]:
    """How many cards a day holds, and how much of it asks."""
    src = REPOSITORY.read_text(encoding="utf-8")
    per_day = re.search(r"const int kPillsPerDay = (\d+);", src)
    ask_share = re.search(r"const double kAskShare = ([\d.]+);", src)
    if not per_day or not ask_share:
        _fail("could not read the day's shape from pills_repository.dart")
    return int(per_day.group(1)), float(ask_share.group(1))


def runway(cards: list[Card], per_day: int, ask_share: float) -> dict:
    """How many days of new reading the pool holds, and what ends it.

    Two runways, because a day is two appetites. Whichever is shorter is the
    day the app starts repeating itself, and the other one is the pile of
    cards nobody will reach.
    """
    asks = sum(1 for c in cards if c.asks)
    tells = len(cards) - asks
    asks_per_day = round(per_day * ask_share)
    tells_per_day = per_day - asks_per_day
    tell_days = tells // tells_per_day if tells_per_day else 0
    ask_days = asks // asks_per_day if asks_per_day else 0
    short, long_ = sorted((("tells", tell_days), ("asks", ask_days)), key=lambda t: t[1])
    stranded = (
        (long_[1] - short[1]) * (asks_per_day if long_[0] == "asks" else tells_per_day)
    )
    return {
        "tells": tells,
        "asks": asks,
        "tells_per_day": tells_per_day,
        "asks_per_day": asks_per_day,
        "tell_days": tell_days,
        "ask_days": ask_days,
        "days": short[1],
        "ends_on": short[0],
        "stranded": stranded,
        # What the pool would give if the two ran out together — the runway
        # that is already paid for and not reachable.
        "balanced_days": len(cards) // per_day,
    }


def build(demand: dict[str, float] | None, want: int) -> tuple[dict, list[Slot]]:
    cards = read_pool()
    tree = read_genres()
    per_day, ask_share = day_shape()
    run = runway(cards, per_day, ask_share)

    by_topic = Counter(c.topic_key for c in cards)
    # The pool writes a card's subject as a display name and the genre tree
    # keys by topic key, so the names come from the one file that holds both.
    label_of = read_topic_names()
    missing = [k for k in tree if k not in label_of]
    if missing:
        _fail(f"the genre tree has subjects topics.dart does not: {missing}")
    stray = [k for k in by_topic if k not in label_of]
    if stray:
        _fail(f"the pool holds subjects topics.dart does not: {stray}")

    # What the readers asked for. Absent a demand file, every genre counts
    # the same — which is the right default for a pool this early, where
    # nothing has enough coverage for demand to be the deciding voice.
    demand = demand or {}

    slots: list[Slot] = []
    for topic_key, genres in tree.items():
        label = label_of[topic_key]
        have = by_topic.get(topic_key, 0)
        for genre_id, genre_label, strands in genres:
            # A subject with nothing written is the loudest thing in the
            # brief: it is offered on the wheel, so a reader can pick it and
            # be handed somebody else's subject all week.
            empty = 1.0 if have == 0 else 0.0
            thin = max(0.0, (per_day - have) / per_day) if have else 1.0
            asked = demand.get(genre_id, 0.0)
            rank = empty * 3 + thin * 2 + asked
            slots.append(
                Slot(
                    genre_id=genre_id,
                    genre_label=genre_label,
                    topic=label,
                    kind="tells" if run["ends_on"] == "tells" else "asks",
                    reason=(
                        "nothing written for this subject"
                        if have == 0
                        else f"{have} cards in {label}, a day needs {per_day}"
                    ),
                    rank=rank,
                    strands=strands,
                )
            )

    # Ordered by want, then dealt round-robin across subjects inside each
    # tier. Sorting alone would have the first thirty cards finish Art and
    # never reach Cinema, which is the same hole one subject deeper: a brief
    # half-written should leave every empty subject equally served, not one
    # of them done and five untouched.
    slots.sort(key=lambda s: (-s.rank, s.topic, s.genre_id))
    return (
        {"pool": len(cards), "runway": run, "by_topic": dict(by_topic)},
        _interleave(slots)[:want],
    )


def _interleave(slots: list[Slot]) -> list[Slot]:
    """Deals one subject at a time round the table, tier by tier."""
    out: list[Slot] = []
    for rank in sorted({s.rank for s in slots}, reverse=True):
        tier = [s for s in slots if s.rank == rank]
        queues: dict[str, list[Slot]] = {}
        for s in tier:
            queues.setdefault(s.topic, []).append(s)
        while any(queues.values()):
            for topic in list(queues):
                if queues[topic]:
                    out.append(queues[topic].pop(0))
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--want", type=int, default=30, help="how many slots to ask for")
    ap.add_argument("--json", type=Path, help="write the brief here as well")
    ap.add_argument(
        "--demand",
        type=Path,
        help="JSON of {genre id: 0..1}, how much each was asked for",
    )
    args = ap.parse_args()

    demand = json.loads(args.demand.read_text()) if args.demand else None
    facts, slots = build(demand, args.want)
    run = facts["runway"]

    print(f"pool           {facts['pool']} cards · {run['tells']} tell · {run['asks']} ask")
    print(
        f"a day          {run['tells_per_day']} tell + {run['asks_per_day']} ask"
        f"  ·  {run['tells_per_day'] + run['asks_per_day']} cards"
    )
    print(
        f"runway         {run['days']} days of new reading, ended by {run['ends_on']}"
    )
    print(
        f"               {run['stranded']} {'asks' if run['ends_on'] == 'tells' else 'tells'}"
        f" never reached · {run['balanced_days']} days if the two balanced"
    )
    print()
    print(f"write {len(slots)} of these next, {slots[0].kind if slots else '—'} first:")
    print()
    for i, s in enumerate(slots, 1):
        print(f"{i:3}. {s.topic:13} {s.genre_label:22} {s.reason}")
        print(f"     {' · '.join(s.strands)}")

    if args.json:
        args.json.write_text(
            json.dumps(
                {
                    "facts": facts,
                    "want": [s.as_json() for s in slots],
                },
                indent=2,
            )
            + "\n",
            encoding="utf-8",
        )
        print(f"\nwritten to {args.json}")


if __name__ == "__main__":
    main()
