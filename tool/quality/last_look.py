"""The last look: whether a card is beautiful, or AI-ish and to be thrown away.

TypeSafe's Jev answers typed questions about the card — its words and, when
there are photographs of it, its pictures — with calibrated probabilities.
Jev judges; this file decides. Every question asks one thing a person would
see at a glance (does the answer open on a filler phrase, is any text cut off
by the card's edge), and the decision is the table in `decide`: one clear flaw
and the card is thrown away, a flaw in its words not settled either way and it
does not go out, and only a card clear of every flaw passes.

Whether a card is beautiful is asked too, and written down, but it decides
nothing yet: measured on the bank, Jev gave a card and the same card spoiled
with a machine's phrases nearly the same marks for surprise and for being
worth telling, so those answers are kept to be measured against the owner's
own verdicts before they are allowed to throw anything away (`NOTES`).

    python3 tool/quality/last_look.py space-aerogel-comet-catch           # one card, words only
    python3 tool/quality/last_look.py --topic space --sample 8 --shots DIR # with its photographs
    python3 tool/quality/last_look.py --dry-run space-aerogel-comet-catch  # the request, unsent
    python3 tool/quality/last_look.py --night cards-outcomes.json --report cards-report.md

The photographs are the ones tool/cards/card_check.cjs and tool/card_shots.dart
take, named <id>-<phone>-<stage>.png: the medium phone is sent, the first and
the last stage. Pictures are a TypeSafe preview ("Dreamer-ready"): they are
sent with its opt-in header, and what they say is measured before it counts.

The key is TYPESAFE_API_KEY; in a Claude session the network proxy puts it in.
A call that fails is an error, never an answer: a card is not thrown, or let
through, because the API was down.
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import os
import random
import sys
import time
import urllib.error
import urllib.request
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable

import common

API = "https://api.typesafe.ai/v1/systemone"

# A version, not `jev-latest`: answers move between releases, and the table
# below was measured on this one.
MODEL = "jev-1.14.0"

# Above YES reads as yes, below NO as no; between, the question is not settled.
YES = 0.7
NO = 0.3

# The phone and the stages a card is looked at on.
PHONE = "medium"

# ── The questions ──────────────────────────────────────────────────────────
#
# All the wording is here, so it can be read and changed in one place. Each
# asks one thing, and a yes means what the name says. The card is in the state
# as the reader meets it: `card.question`, then `card.options` or `card.sides`,
# then `card.answer`, the `card.trap` it names, the `card.steps` of a worked
# answer, and `card.ending`, the box the back ends on.


def noul(instructions: str, yes: str | None = None, no: str | None = None) -> dict:
    q: dict = {"type": "noul", "instructions": instructions}
    if yes and no:
        q["criteria"] = {"true": yes, "false": no}
    return q


# What gives a card away as written by a machine, or written without care.
# A yes on any of these throws the card away. Not here on purpose: a line to
# keep that holds beyond the card (tool/cards/RULES.md §5 asks for exactly
# that), and the turn from what people believe to what is so — both are the
# house style, and asking about them threw good cards away.
FLAWS = {
    "filler_opening": noul(
        "Does `card.answer` begin with a throat-clearing phrase before it gets to the point?",
        yes="Its first words are an opener such as \"Interestingly\", \"In fact\", \"It turns out\", "
            "\"As it happens\", \"Surprisingly\", \"Believe it or not\" or \"Fun fact\".",
        no="Its first words already say something about the subject.",
    ),
    "self_praise": noul(
        "Does the text of `card` call its own content fascinating, incredible, remarkable or mind-blowing?",
    ),
    "cliche_ending": noul(
        "Is `card.ending` a well-worn saying, the kind of line printed on a motivational poster?",
    ),
    # Catches a question that gives its answer away only some of the time —
    # comparing the question with the answer is a weak spot of Jev's — but
    # it has never flagged a good card, so it stays.
    "answer_in_question": noul(
        "Does `card.question` already state the answer it asks for?",
        yes="Reading the question is enough to know its answer.",
        no="The answer is only on the back of the card.",
    ),
    "nothing_concrete": noul(
        "Is `card.answer` vague, with nothing specific in it that a reader could picture or check?",
        yes="General words only: a process, a mechanism, some factors, an effect.",
        no="It names at least one particular number, person, place, object or date.",
    ),
}

# Measured with last_look_bench.py on 40 cards across the topics, each also
# spoiled five ways, on jev-1.14.0 (November 2026): on the half of the cards
# the wordings were not chosen on, these caught 100%, 100%, 100%, 27% and
# 100% of the spoiled cards, threw away none of the untouched ones, and left
# 5% of them unsure.

# What a beautiful card has. Asked and written down; deciding nothing yet.
STRENGTHS = {
    "surprise": noul(
        "Would a curious adult learn something from `card` that they did not expect?",
    ),
    "worth_telling": noul(
        "Would a reader want to tell what `card` says to a friend tonight?",
    ),
    "pull": noul(
        "Does `card.question` make a reader want to answer it before reading on?",
    ),
}

# What the photographs show. Asked only when there are photographs.
PICTURE_FLAWS = {
    "cut_text": noul(
        "Is any text in `front` cut off by the edge of the card or of the box it sits in?",
    ),
    "overlapping_text": noul(
        "Does any text in `front` run over other text or over a drawing?",
    ),
    "empty_card": noul(
        "Is a large part of the card in `front` empty, with nothing on it?",
    ),
    "cut_text_after": noul(
        "Is any text in `back` cut off by the edge of the card or of the box it sits in?",
    ),
}

# Measured the same way on 16 jewels from the bank, each photographed as the
# app shows it and spoiled with a line of CSS: on the cards the wordings were
# not chosen on, these caught 89%, 89% and 100% of the spoiled photographs
# and threw away none of the untouched ones. Text too small to read is not
# asked: Jev caught it on no card at all, and tool/cards/card_check.cjs
# already measures every size of type on every phone.

# Asked of the photographs and written down, deciding nothing yet: a clean
# vector drawing on a card can read as stock art, and that is not a flaw until
# the owner's verdicts say it is.
PICTURE_NOTES = {
    "stock_art": noul(
        "Does the picture in `front` look like generic stock art or an AI-generated illustration?",
    ),
    "crafted": noul(
        "Does the card in `front` look carefully designed, like a page of a well-made illustrated book?",
    ),
}


# The answers that are only written down.
NOTES = (*STRENGTHS, *PICTURE_NOTES)


# ── The state ──────────────────────────────────────────────────────────────

def _subject(topic: str) -> str:
    return topic.replace("_", " ").capitalize()


def ending(card: dict) -> list[str]:
    """The box, or boxes, the back of the card ends on, as the app decides
    (lib/models/pill.dart: showsMove, showsAsk)."""
    move = (card.get("move") or "").strip()
    ask = (card.get("ask") or "").strip()
    both = card.get("both") is True
    on_ask = card.get("end") == "ask"
    out = []
    if move and (both or not on_ask or not ask):
        out.append(move)
    if ask and (both or on_ask or not move):
        out.append(ask)
    return out


def card_state(card: dict) -> dict:
    """The card as the reader meets it, and nothing they never see."""
    c: dict = {"subject": _subject(card.get("topic", "")), "question": card.get("question", "").strip()}
    if card.get("options"):
        c["options"] = card["options"]
    if card.get("sides"):
        c["sides"] = card["sides"]
    if card.get("answer"):
        c["answer"] = card["answer"].strip()
    if card.get("steps"):
        c["steps"] = card["steps"]
    if card.get("trap"):
        c["trap"] = card["trap"].strip()
    if card.get("counterpoint"):
        c["counterpoint"] = card["counterpoint"].strip()
    shown = ending(card)
    if shown:
        c["ending"] = shown[0] if len(shown) == 1 else shown
    return {"card": c}


# ── The pictures ───────────────────────────────────────────────────────────

# TypeSafe's limits, both ends included.
SIDE_MIN, SIDE_MAX = 280, 1568


# The stages the two cameras name: the card as it first appears, and once it
# has been played through or answered.
FRONT = ("start",)
BACK = ("end", "asked", "placed")


def photographs(card_id: str, shots: Path | None) -> dict[str, Path]:
    """The card before and after, on the medium phone, if it was photographed."""
    if shots is None:
        return {}
    out: dict[str, Path] = {}
    for name, stages in (("front", FRONT), ("back", BACK)):
        for stage in stages:
            path = shots / f"{card_id}-{PHONE}-{stage}.png"
            if path.exists():
                out[name] = path
                break
    return out if "front" in out else {}


def image_asset(path: Path) -> dict:
    """A photograph as TypeSafe takes it: PNG, each side within its limits."""
    from PIL import Image

    with Image.open(path) as original:
        img = original.convert("RGB")
    if max(img.size) > SIDE_MAX:
        img.thumbnail((SIDE_MAX, SIDE_MAX))
    if min(img.size) < SIDE_MIN:
        scale = SIDE_MIN / min(img.size)
        img = img.resize((round(img.size[0] * scale), round(img.size[1] * scale)))
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return {"type": "image", "format": "png", "data_base64": base64.b64encode(buf.getvalue()).decode("ascii")}


# ── The request ────────────────────────────────────────────────────────────

class TypeSafeError(RuntimeError):
    """The API did not answer. Never read as a yes or a no."""


def build(card: dict, shots: Path | None = None) -> tuple[dict, dict[str, str]]:
    """The request body for one card, and which image each reference stands for."""
    state = card_state(card)
    questions = {**FLAWS, **STRENGTHS}
    assets: dict[str, dict] = {}
    images: dict[str, str] = {}
    pics = photographs(card["id"], shots)
    for name, path in pics.items():
        ref = f"img-{uuid.uuid4()}"
        state[name] = ref
        assets[ref] = image_asset(path)
        images[ref] = str(path)
    if "front" in pics:
        questions.update({k: v for k, v in PICTURE_FLAWS.items() if "`back`" not in v["instructions"] or "back" in pics})
        questions.update(PICTURE_NOTES)
    body = {"model": MODEL, "state": state, "questions": questions}
    if assets:
        body["assets"] = assets
    return body, images


Transport = Callable[[dict, dict], dict]


def http(body: dict, headers: dict, *, attempts: int = 4) -> dict:
    """POST to the API, waiting out a rate limit or a passing failure."""
    data = json.dumps(body).encode("utf-8")
    for attempt in range(attempts):
        req = urllib.request.Request(API, data=data, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace")[:500]
            if e.code in (429, 500, 502, 503, 504) and attempt < attempts - 1:
                wait = float(e.headers.get("retry-after") or 2 ** attempt)
                time.sleep(min(wait, 30))
                continue
            raise TypeSafeError(f"TypeSafe answered {e.code}: {detail}") from e
        except (urllib.error.URLError, TimeoutError) as e:
            if attempt < attempts - 1:
                time.sleep(2 ** attempt)
                continue
            raise TypeSafeError(f"TypeSafe could not be reached: {e}") from e
    raise TypeSafeError("TypeSafe did not answer")


def send(body: dict, transport: Transport = http) -> dict:
    headers = {
        "Authorization": f"Bearer {os.environ.get('TYPESAFE_API_KEY') or 'proxy-injected'}",
        "Content-Type": "application/json",
    }
    if body.get("assets"):
        headers["TypeSafe-Danger-Zone-Images"] = "true"
    answer = transport(body, headers)
    if not isinstance(answer, dict) or "answers" not in answer:
        raise TypeSafeError(f"TypeSafe sent no answers: {str(answer)[:300]}")
    missing = set(body["questions"]) - set(answer["answers"])
    if missing:
        raise TypeSafeError(f"TypeSafe left questions unanswered: {sorted(missing)}")
    return answer


# ── The decision ───────────────────────────────────────────────────────────

@dataclass
class Look:
    card: str
    verdict: str  # "clean", "thrown" or "unsure"
    reasons: list[str] = field(default_factory=list)
    answers: dict[str, float] = field(default_factory=dict)
    tokens: int = 0
    pictures: bool = False

    @property
    def passes(self) -> bool:
        return self.verdict == "clean"

    @property
    def notes(self) -> dict[str, float]:
        return {k: v for k, v in self.answers.items() if k in NOTES}


def decide(card_id: str, answers: dict[str, float], *, pictures: bool = False) -> Look:
    """The table. Jev's answers in, what happens to the card out.

    | a flaw in the words or the picture is a clear yes (≥ YES) | thrown        |
    | a flaw in the words is not settled (between NO and YES)   | unsure: stays |
    |                                                           | out           |
    | otherwise                                                 | clean: passes |

    A flaw in the picture counts only as a clear yes. Asked of the jewels the
    bank already shows, which tool/cards/card_check.cjs had measured clear,
    Jev put cut, overlapping and small text in the middle more often than not:
    the measuring is the program's, and Jev is there for what it cannot
    measure, such as a card mostly empty. The notes (`NOTES`) change nothing.
    """
    words = [k for k in answers if k in FLAWS]
    picture = [k for k in answers if k in PICTURE_FLAWS]
    clear = [k for k in words + picture if answers[k] >= YES]
    open_ = [k for k in words if NO < answers[k] < YES]
    if clear:
        return Look(card_id, "thrown", clear, answers, pictures=pictures)
    if open_:
        return Look(card_id, "unsure", open_, answers, pictures=pictures)
    return Look(card_id, "clean", [], answers, pictures=pictures)


def look(card: dict, shots: Path | None = None, transport: Transport = http) -> Look:
    body, _ = build(card, shots)
    answer = send(body, transport)
    probs = {k: float(v["noul"]) for k, v in answer["answers"].items()}
    result = decide(card["id"], probs, pictures=bool(body.get("assets")))
    result.tokens = int(answer.get("usage", {}).get("input_tokens", 0))
    return result


# ── Running it ─────────────────────────────────────────────────────────────

def load_cards(ids: list[str], topic: str | None, sample: int | None, seed: int) -> list[dict]:
    import check

    bank = [check.public(c) for c in check.load_bank(common.BANK) if not c.get("disabled")]
    if ids:
        by_id = {c["id"]: c for c in bank}
        unknown = [i for i in ids if i not in by_id]
        if unknown:
            raise SystemExit(f"not in the bank: {', '.join(unknown)}")
        return [by_id[i] for i in ids]
    if topic:
        bank = [c for c in bank if c.get("topic") == topic]
    if sample:
        random.Random(seed).shuffle(bank)
        bank = bank[:sample]
    return bank


def report(looks: list[Look]) -> str:
    mark = {"clean": "✓", "thrown": "✗", "unsure": "?"}
    lines = []
    for lk in looks:
        why = ", ".join(f"{r} {lk.answers[r]:.2f}" for r in lk.reasons)
        notes = " ".join(f"{k} {v:.2f}" for k, v in lk.notes.items())
        lines.append(f"{mark[lk.verdict]} {lk.verdict:<6} {lk.card}" + (f"  ({why})" if why else "") + f"  · {notes}")
    counts = {v: sum(1 for lk in looks if lk.verdict == v) for v in ("clean", "unsure", "thrown")}
    tokens = sum(lk.tokens for lk in looks)
    lines.append(
        f"{len(looks)} cards: {counts['clean']} clean, {counts['unsure']} unsure, "
        f"{counts['thrown']} thrown · {tokens} tokens"
    )
    return "\n".join(lines)


# ── After the night ────────────────────────────────────────────────────────

def night(outcomes: list[dict], *, transport: Transport = http, bank: Path = common.BANK,
          review: Path = common.REVIEW, today: str = "") -> tuple[list[Look], list[str], str]:
    """Looks at every card the night wrote, wherever routing left it, and
    removes the ones that do not pass. A card the API could not look at
    is not passed and not thrown: it waits for a person in the review folder.
    Returns the looks, the cards moved to a person, and the pull request's
    section."""
    queue_path = review / "queue.json"
    queue = common.read_queue(queue_path)
    looks: list[Look] = []
    unlooked: list[str] = []
    gone: set[str] = set()
    for o in outcomes:
        if o.get("status") != "written" or not o.get("id"):
            continue
        cid, topic = o["id"], o.get("request", {}).get("topic", "")
        path = next((p for p in (bank / topic / f"{cid}.json", review / f"{cid}.json") if p.exists()), None)
        if path is None:
            continue
        card = json.loads(path.read_text(encoding="utf-8"))
        try:
            lk = look(card, None, transport)
        except TypeSafeError as e:
            print(f"{cid}: {e}", file=sys.stderr)
            if path.parent != review:
                review.mkdir(parents=True, exist_ok=True)
                path.rename(review / path.name)
                queue.append({"id": cid, "topic": topic, "since": today, "why": ["the last look could not run"]})
            unlooked.append(cid)
            continue
        looks.append(lk)
        if not lk.passes:
            path.unlink()
            gone.add(cid)
    queue = [e for e in queue if e.get("id") not in gone]
    common.write_queue(queue, queue_path)

    out = ["", "## The last look", ""]
    thrown = [lk for lk in looks if not lk.passes]
    out.append(
        f"TypeSafe looked at {len(looks)} of tonight's cards: {len(looks) - len(thrown)} clean, "
        f"{len(thrown)} thrown away."
    )
    if thrown:
        out.append("")
        for lk in thrown:
            why = ", ".join(f"{r} {lk.answers[r]:.2f}" for r in lk.reasons)
            out.append(f"- `{lk.card}` ({lk.verdict}): {why}")
    if unlooked:
        out += ["", "It could not look at these, so they wait for a person: "
                + ", ".join(f"`{c}`" for c in unlooked)]
    return looks, unlooked, "\n".join(out) + "\n"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("ids", nargs="*", help="cards in the bank, by id")
    ap.add_argument("--topic", help="cards of this topic")
    ap.add_argument("--sample", type=int, help="this many, at random")
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--shots", type=Path, help="a folder of photographs: <id>-<phone>-<stage>.png")
    ap.add_argument("--out", type=Path, help="write every answer here, as JSON lines, to read or rerun")
    ap.add_argument("--dry-run", action="store_true", help="print the request for the first card and send nothing")
    ap.add_argument("--night", type=Path, help="the night's outcomes: look at its cards and remove what fails")
    ap.add_argument("--report", type=Path, help="with --night: append the last look to this pull request body")
    ap.add_argument("--today", help="with --night: YYYY-MM-DD, for a card that waits for a person")
    args = ap.parse_args(argv)

    if args.night:
        if not os.environ.get("TYPESAFE_API_KEY"):
            note = "\n## The last look\n\nNo TYPESAFE_API_KEY secret is set, so TypeSafe did not look at tonight's cards.\n"
            if args.report:
                with args.report.open("a", encoding="utf-8") as f:
                    f.write(note)
            print(note)
            return 0
        if not args.night.exists():
            print(f"{args.night} does not exist: nothing to look at", file=sys.stderr)
            return 0
        _, _, text = night(json.loads(args.night.read_text(encoding="utf-8")), today=args.today or "")
        if args.report:
            with args.report.open("a", encoding="utf-8") as f:
                f.write(text)
        print(text)
        return 0

    cards = load_cards(args.ids, args.topic, args.sample, args.seed)
    if not cards:
        print("no cards")
        return 1
    if args.dry_run:
        body, images = build(cards[0], args.shots)
        for ref in body.get("assets", {}):
            body["assets"][ref] = {"photograph": images[ref]}
        print(json.dumps(body, ensure_ascii=False, indent=2))
        return 0
    looks = []
    sink = args.out.open("w", encoding="utf-8") if args.out else None
    try:
        for card in cards:
            lk = look(card, args.shots)
            looks.append(lk)
            if sink:
                sink.write(json.dumps(lk.__dict__, ensure_ascii=False) + "\n")
    finally:
        if sink:
            sink.close()
    print(report(looks))
    return 0


if __name__ == "__main__":
    sys.exit(main())
