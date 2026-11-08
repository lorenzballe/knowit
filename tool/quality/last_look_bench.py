"""How good the last look's questions are, measured on cards spoiled on purpose.

Every flaw the last look throws a card away for (last_look.FLAWS) is planted,
in several different wordings, in real cards from the bank, and each question
is asked in a few wordings side by side over the same card, the way TypeSafe
advises comparing them. Each wording is then scored on the cards it was
chosen on and, separately, on cards it never saw:

    caught      the share of spoiled cards it flags (≥ YES): higher is better
    thrown      the share of untouched cards it flags (≥ YES): a good card lost
    unsure      the share of untouched cards it leaves in the middle: kept out
    crosstalk   the share of cards spoiled another way that it flags

    python3 tool/quality/last_look_bench.py --cards 40            # the whole bench
    python3 tool/quality/last_look_bench.py --cards 6 --dry-run   # what it would send

Run it again whenever the questions change or TypeSafe releases a new Jev:
the wording that wins on one model may not win on the next.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import random
import re
import sys
from dataclasses import dataclass
from pathlib import Path

import common
import last_look as L

# ── How each flaw is planted, in more than one wording ─────────────────────

FILLERS = ["Interestingly, ", "In fact, ", "It turns out that ", "Surprisingly, ",
           "Believe it or not, ", "As it happens, ", "Fun fact: "]
PRAISE = [
    "This is one of the most fascinating facts in {subject}.",
    "It is a truly remarkable story.",
    "The result is nothing short of incredible.",
    "Few things in {subject} are as mind-blowing as this.",
    "What happens next is genuinely astonishing.",
]
CLICHES = ["Knowledge is power.", "Every cloud has a silver lining.", "Slow and steady wins the race.",
           "The journey matters more than the destination.", "Less is more.",
           "Never judge a book by its cover.", "Curiosity is the key to everything.", "Think outside the box."]
VAGUE = [
    "It all comes down to a clever process that changes how things behave, which is why the outcome "
    "surprises so many people.",
    "The explanation lies in a subtle mechanism that most people overlook, and once you see it the "
    "result makes perfect sense.",
    "Experts point to a combination of factors working together, and the effect turned out to be far "
    "bigger than anyone expected.",
]


def _fact(text: str) -> str:
    """The first sentence of an answer that says something: past a bare "False." or "Yes"."""
    sentences = [s.strip() for s in re.split(r"(?<=[.!?])\s+", text.strip()) if s.strip()]
    for s in sentences:
        if len(s.split()) >= 6:
            return s.rstrip(".!?")
    return (sentences[0] if sentences else text).rstrip(".!?")


def _lower_first(text: str) -> str:
    return text[:1].lower() + text[1:] if text[:2] != text[:2].upper() else text


def plant(card: dict, flaw: str, rand: random.Random) -> dict:
    """The card with one flaw planted, in one of several wordings."""
    c = json.loads(json.dumps(card))
    subject = L._subject(c.get("topic", ""))
    answer = c.get("answer", "").strip()
    if flaw == "filler_opening":
        c["answer"] = rand.choice(FILLERS) + _lower_first(answer)
    elif flaw == "self_praise":
        line = rand.choice(PRAISE).format(subject=subject.lower())
        c["answer"] = f"{line} {answer}" if rand.random() < 0.5 else f"{answer} {line}"
    elif flaw == "cliche_ending":
        c["move"] = rand.choice(CLICHES)
        c.pop("end", None)
        c.pop("both", None)
    elif flaw == "answer_in_question":
        fact = _lower_first(_fact(answer))
        c["question"] = (f"Is it true that {fact}?" if rand.random() < 0.5
                         else f"{c['question'].strip().rstrip('?')}, given that {fact}?")
        c.pop("options", None)
    elif flaw == "nothing_concrete":
        c["answer"] = rand.choice(VAGUE)
        c.pop("steps", None)
    else:
        raise ValueError(flaw)
    return c


# ── Each question, in the wordings being compared ──────────────────────────
# The first wording of each is the one the last look uses now.

VARIANTS: dict[str, dict[str, dict]] = {
    "filler_opening": {
        "now": L.FLAWS["filler_opening"],
        "named": L.noul(
            "Does `card.answer` open with a filler phrase such as \"Interestingly\", \"In fact\", "
            "\"It turns out\" or \"Surprisingly\"?",
        ),
    },
    "self_praise": {
        "now": L.FLAWS["self_praise"],
        "tells": L.noul(
            "Does `card` tell the reader how amazing its own fact is?",
            yes="It calls its content fascinating, remarkable, incredible, astonishing, mind-blowing or the like.",
            no="It states what happened and lets the reader judge.",
        ),
    },
    "cliche_ending": {
        "now": L.FLAWS["cliche_ending"],
        "proverb": L.noul(
            "Is `card.ending` a familiar proverb or saying that people knew before reading the card?",
        ),
    },
    "answer_in_question": {
        "now": L.FLAWS["answer_in_question"],
        "contains": L.noul(
            "Does `card.question` contain the answer that `card.answer` gives?",
        ),
        "already_says": L.noul(
            "Does `card.question` already say the fact that `card.answer` reveals?",
            yes="The fact the back of the card reveals is written in the question itself, so turning the "
                "card over teaches nothing new.",
            no="The question asks about something only the back of the card reveals.",
        ),
    },
    "nothing_concrete": {
        "now": L.FLAWS["nothing_concrete"],
        "named": L.noul(
            "Does `card.answer` explain without a single concrete number, name, place, object or date?",
        ),
    },
}


def questions() -> dict[str, dict]:
    return {f"{flaw}__{name}": q for flaw, ws in VARIANTS.items() for name, q in ws.items()}


# ── The bench ──────────────────────────────────────────────────────────────

@dataclass
class Item:
    card: str
    planted: str | None  # None for the untouched card
    held_out: bool
    answers: dict[str, float]
    state: dict | None = None


def held_out(card_id: str) -> bool:
    """Half the cards are never used to choose a wording: decided by the id."""
    return int(hashlib.sha1(card_id.encode()).hexdigest(), 16) % 2 == 1


def sample(n: int, seed: int) -> list[dict]:
    import check

    bank = [check.public(c) for c in check.load_bank(common.BANK) if not c.get("disabled")]
    clean = []
    for c in bank:
        a = c.get("answer", "")
        if not a or len(a.split()) < 15 or not c.get("move"):
            continue
        if re.match(r"(interestingly|in fact|it turns out|surprisingly|believe it or not|fun fact)", a.lower()):
            continue
        clean.append(c)
    rand = random.Random(seed)
    by_topic: dict[str, list[dict]] = {}
    for c in clean:
        by_topic.setdefault(c["topic"], []).append(c)
    for cards in by_topic.values():
        rand.shuffle(cards)
    out: list[dict] = []
    while len(out) < n and any(by_topic.values()):
        for topic in sorted(by_topic):
            if by_topic[topic] and len(out) < n:
                out.append(by_topic[topic].pop())
    return out


def run(cards: list[dict], *, seed: int, workers: int, transport: L.Transport = L.http) -> list[Item]:
    qs = questions()
    jobs = []
    for card in cards:
        rand = random.Random(f"{seed}:{card['id']}")
        jobs.append((card["id"], None, card))
        for flaw in VARIANTS:
            jobs.append((card["id"], flaw, plant(card, flaw, rand)))

    def ask(job):
        cid, flaw, card = job
        body = {"model": L.MODEL, "state": L.card_state(card), "questions": qs}
        answer = L.send(body, transport)
        return Item(cid, flaw, held_out(cid), {k: float(v["noul"]) for k, v in answer["answers"].items()},
                    body["state"]["card"])

    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        return list(pool.map(ask, jobs))


def score(items: list[Item], *, held: bool) -> dict[str, dict[str, float]]:
    """caught, thrown, unsure and crosstalk for every question wording."""
    pool = [i for i in items if i.held_out == held]
    out = {}
    for qid in questions():
        flaw = qid.split("__")[0]
        spoiled = [i.answers[qid] for i in pool if i.planted == flaw]
        clean = [i.answers[qid] for i in pool if i.planted is None]
        other = [i.answers[qid] for i in pool if i.planted not in (None, flaw)]
        share = lambda xs, f: sum(1 for x in xs if f(x)) / len(xs) if xs else 0.0  # noqa: E731
        out[qid] = {
            "caught": share(spoiled, lambda p: p >= L.YES),
            "thrown": share(clean, lambda p: p >= L.YES),
            "unsure": share(clean, lambda p: L.NO < p < L.YES),
            "crosstalk": share(other, lambda p: p >= L.YES),
            "n": len(spoiled),
        }
    return out


def merit(s: dict[str, float]) -> float:
    """What a wording is worth: cards caught, less twice the good cards lost, less those kept out."""
    return s["caught"] - 2 * s["thrown"] - s["unsure"]


def table(tuned: dict, held: dict) -> str:
    lines = ["| question | wording | caught | thrown | unsure | crosstalk | on unseen cards: caught / thrown / unsure |",
             "|---|---|---|---|---|---|---|"]
    best = {}
    for qid, s in tuned.items():
        flaw, name = qid.split("__")
        if flaw not in best or merit(s) > merit(tuned[best[flaw]]):
            best[flaw] = qid
    for qid, s in tuned.items():
        flaw, name = qid.split("__")
        h = held[qid]
        star = " **best**" if best[flaw] == qid else ""
        lines.append(
            f"| {flaw} | {name}{star} | {s['caught']:.0%} | {s['thrown']:.0%} | {s['unsure']:.0%} | "
            f"{s['crosstalk']:.0%} | {h['caught']:.0%} / {h['thrown']:.0%} / {h['unsure']:.0%} |"
        )
    return "\n".join(lines)


# ── The pictures ───────────────────────────────────────────────────────────
#
# The same, for the questions asked of a card's photograph: a jewel from the
# bank is spoiled with a line of CSS, photographed by tool/cards/card_check.cjs
# exactly as the app shows it, and asked about, untouched and spoiled.

DEFECTS = {
    "cut_text": ".q{white-space:nowrap!important;text-wrap:nowrap!important}",
    "overlapping_text": ".q{position:relative!important;top:24cqh!important;z-index:9!important}",
    "empty_card": ".stagebox,.say{visibility:hidden!important}",
    "tiny_text": ".q{font-size:1.2cqh!important}.say,.body{font-size:1cqh!important}",
}

PICTURE_VARIANTS: dict[str, dict[str, dict]] = {
    "cut_text": {
        "now": L.PICTURE_FLAWS["cut_text"],
        "letters": L.noul(
            "Does a line of text in `front` run past the edge of the card, so that some of its letters are missing?",
        ),
    },
    "overlapping_text": {
        "now": L.PICTURE_FLAWS["overlapping_text"],
        "on_top": L.noul(
            "In `front`, is text printed on top of other text or on top of a drawing?",
        ),
    },
    "empty_card": {
        "now": L.PICTURE_FLAWS["empty_card"],
        "unfinished": L.noul(
            "Does the card in `front` look unfinished, with a big area left blank?",
        ),
    },
    # Not asked by the last look: on 16 jewels the first caught none of the
    # spoiled photographs and the second 22%, throwing away 11% of the good
    # ones. tool/cards/card_check.cjs measures the type instead.
    "tiny_text": {
        "phone": L.noul(
            "Is any text in `front` too small to read on a phone held at a normal distance?",
        ),
        "squint": L.noul(
            "Would a reader have to squint to read some of the text in `front`?",
        ),
    },
}

ROOT = Path(__file__).resolve().parents[2]


def spoil_page(html: str, css: str) -> str:
    """The page with a style that spoils it, last, so the doctype stays first."""
    return html.rstrip() + f"\n<style>{css}</style>\n"


def jewels(n: int, seed: int) -> list[dict]:
    import check

    bank = [check.public(c) for c in check.load_bank(common.BANK)
            if not c.get("disabled") and (common.BANK / c["topic"] / f"{c['id']}.html").exists()]
    rand = random.Random(seed)
    rand.shuffle(bank)
    seen, out = set(), []
    for c in bank:  # one per topic first, then the rest
        if c["topic"] not in seen:
            seen.add(c["topic"])
            out.append(c)
    out += [c for c in bank if c not in out]
    return out[:n]


def photograph(page: Path, shots: Path) -> None:
    import subprocess

    subprocess.run(["node", str(ROOT / "tool/cards/card_check.cjs"), str(page), str(shots)],
                   capture_output=True, timeout=600)


def pictures(n: int, seed: int, workers: int, work: Path, transport: L.Transport = L.http) -> list[Item]:
    pages, shots = work / "pages", work / "shots"
    pages.mkdir(parents=True, exist_ok=True)
    shots.mkdir(parents=True, exist_ok=True)
    versions = []
    for card in jewels(n, seed):
        html = (common.BANK / card["topic"] / f"{card['id']}.html").read_text(encoding="utf-8")
        for defect in [None, *DEFECTS]:
            name = f"{card['id']}~{defect or 'clean'}"
            (pages / f"{name}.html").write_text(spoil_page(html, DEFECTS[defect]) if defect else html, encoding="utf-8")
            (pages / f"{name}.json").write_text(json.dumps(card, ensure_ascii=False), encoding="utf-8")
            versions.append((card, defect, name))
    todo = [pages / f"{name}.html" for _, _, name in versions if not (shots / f"{name}-{L.PHONE}-start.png").exists()]
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(lambda p: photograph(p, shots), todo))

    qs = {f"{flaw}__{name}": q for flaw, ws in PICTURE_VARIANTS.items() for name, q in ws.items()}

    def ask(version):
        card, defect, name = version
        front = shots / f"{name}-{L.PHONE}-start.png"
        if not front.exists():
            return None
        ref = f"img-{name}"
        body = {"model": L.MODEL, "state": {**L.card_state(card), "front": ref},
                "assets": {ref: L.image_asset(front)}, "questions": qs}
        answer = L.send(body, transport)
        return Item(card["id"], defect, held_out(card["id"]),
                    {k: float(v["noul"]) for k, v in answer["answers"].items()})

    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        return [i for i in pool.map(ask, versions) if i is not None]


def score_pictures(items: list[Item], *, held: bool | None) -> dict[str, dict[str, float]]:
    pool = [i for i in items if held is None or i.held_out == held]
    out = {}
    for flaw, ws in PICTURE_VARIANTS.items():
        for name in ws:
            qid = f"{flaw}__{name}"
            spoiled = [i.answers[qid] for i in pool if i.planted == flaw]
            clean = [i.answers[qid] for i in pool if i.planted is None]
            other = [i.answers[qid] for i in pool if i.planted not in (None, flaw)]
            share = lambda xs, f: sum(1 for x in xs if f(x)) / len(xs) if xs else 0.0  # noqa: E731
            out[qid] = {"caught": share(spoiled, lambda p: p >= L.YES), "thrown": share(clean, lambda p: p >= L.YES),
                        "unsure": share(clean, lambda p: L.NO < p < L.YES),
                        "crosstalk": share(other, lambda p: p >= L.YES), "n": len(spoiled)}
    return out


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--cards", type=int, default=40, help="how many cards from the bank, across the topics")
    ap.add_argument("--seed", type=int, default=3)
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--out", type=Path, help="every answer, as JSON lines, to read or rescore")
    ap.add_argument("--dry-run", action="store_true", help="print one card's spoiled versions and send nothing")
    ap.add_argument("--pictures", type=int, help="bench the picture questions on this many jewels instead")
    ap.add_argument("--work", type=Path, default=Path("/tmp/last-look-bench"),
                    help="with --pictures: where the spoiled pages and their photographs go")
    args = ap.parse_args(argv)

    if args.pictures:
        items = pictures(args.pictures, args.seed, args.workers, args.work)
        if args.out:
            with args.out.open("w", encoding="utf-8") as f:
                for i in items:
                    f.write(json.dumps(i.__dict__, ensure_ascii=False) + "\n")
        print(f"{args.pictures} jewels, {len(items)} photographs\n")
        print(table(score_pictures(items, held=False), score_pictures(items, held=True)))
        return 0

    cards = sample(args.cards, args.seed)
    if args.dry_run:
        rand = random.Random(f"{args.seed}:{cards[0]['id']}")
        for flaw in VARIANTS:
            print(f"--- {flaw}")
            print(json.dumps(L.card_state(plant(cards[0], flaw, rand))["card"], ensure_ascii=False, indent=1))
        return 0
    items = run(cards, seed=args.seed, workers=args.workers)
    if args.out:
        with args.out.open("w", encoding="utf-8") as f:
            for i in items:
                f.write(json.dumps(i.__dict__, ensure_ascii=False) + "\n")
    print(f"{len(cards)} cards, {len(items)} versions; chosen on {sum(not held_out(c['id']) for c in cards)} cards, "
          f"checked on {sum(held_out(c['id']) for c in cards)}\n")
    print(table(score(items, held=False), score(items, held=True)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
