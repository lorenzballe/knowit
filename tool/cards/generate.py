#!/usr/bin/env python3
"""Writes cards: a scout searches, a reader opens the page, the writer
writes from it, the gate refuses, the critic doubts.

    python3 tool/cards/generate.py --plan --count 20             # what the bank is short of
    python3 tool/cards/generate.py --plan --count 20 --batch     # the same, at half price, overnight
    python3 tool/cards/generate.py --strand space.the_moon.tides --kind read
    python3 tool/cards/generate.py --plan --count 20 --dry-run   # the briefs, no call
    python3 tool/cards/generate.py --plan --count 3 --fake       # a canned model, for the plumbing

One card per request, in stages, every request through a stage together:

1. the **scout** searches the open web for three finds the card could be
   built on — a claim, its figures, the page that states it — from
   different sites and different kinds of source, never a list site,
   never Wikipedia as the source;
2. the **reader** opens the first find's page and copies the passage that
   states the claim, verbatim; a program then checks the passage is on
   the page. A find that does not hold is dropped and the next is read;
3. the **writer** gets RULES.md, the blacklist, the house style, the brief
   and the verified find, and writes the card from it — every figure in
   the card is in the quoted passage;
4. the **gate** (check.py, strict) refuses anything mis-shaped, and the
   writer gets one round to fix what it named;
5. the **critic** — the opposite brief, with search and the page — redoes
   the numbers against the quote, defends the wrong options, looks for
   the textbook instance, and returns pass, fix or reject;
6. what survives is given an id and a date and written into the bank, one
   file, for the pull request a person reads.

Thinking cards are arithmetic and skip the scout and the reader. With
--batch every stage goes through the Message Batches API at half the
token price, and the run waits for each batch to end.

Needs ANTHROPIC_API_KEY in the environment. Never runs on a phone; the app
only ever downloads the bank this produces.
"""
from __future__ import annotations

import argparse
import datetime as dt
import itertools
import json
import os
import random
import sys
import time
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path
from typing import Literal

from pydantic import BaseModel, Field, ValidationError

import check
import genres
import sources

HERE = Path(__file__).resolve().parent
RULES = HERE / "RULES.md"

MODEL = "claude-opus-5"
# A declined request is re-run server-side on Anthropic's recommended
# fallback for the refusal category, inside the same call.
FALLBACK_BETA = "server-side-fallback-2026-07-01"

# Dollars per million tokens, and per web search, for the run's own receipt.
PRICE = {"input": 5.0, "output": 25.0, "cache_read": 0.5, "cache_write": 6.25}
SEARCH_PRICE = 0.01

# How hard each stage may search, and how long a batch may take.
SCOUT_SEARCHES = 8
CRITIC_SEARCHES = 4
FINDS = 3
BATCH_POLL_SECONDS = 30
BATCH_WAIT_SECONDS = 5 * 3600
MAX_TOKENS = 16000

# What a subject should hold before the plan stops asking for it.
TARGET_READS = 40
TARGET_ASKS = 20
TARGET_DEBATES = 3
PRINCIPLE_FLOOR = 8
ASK_MIX = {"pickOne": 0.70, "number": 0.15, "estimate": 0.15}
HARD_SHARE = 0.15
# How many cards a strand should hold before the plan stops reaching for
# it by name. Two: one a reader meets, and one for the day they ask for
# more of the same. Coverage comes before depth — a strand with nothing in
# it is a strand a reader turned on and is never dealt from.
STRAND_TARGET = 2
PRINCIPLE_CHOICE = 3

# The bank's own best, one or two per kind, shown to the model as the style.
EXEMPLARS = ["space-2", "thinking-1", "thinking-2", "thinking-n1", "thinking-e1", "thinking-d1"]

PRINCIPLES = [p for p in check.load_schema()["properties"]["principle"]["enum"] if p != "none"]
TOPICS = check.load_schema()["properties"]["topic"]["enum"]


# --------------------------------------------------------------------------
# What the model returns

# The vocabularies are the schema's, through check.py and sources.py, so a
# value the gate would refuse cannot be produced in the first place.
Era = Literal[tuple(check.TAGS["era"])]
Region = Literal[tuple(check.TAGS["region"])]
Hook = Literal[tuple(check.TAGS["hook"])]
Mood = Literal[tuple(check.TAGS["mood"])]
Abstraction = Literal[tuple(check.TAGS["abstraction"])]
ShelfLife = Literal[tuple(check.TAGS["shelf_life"])]
Figure = Literal[tuple(check.TAGS["figure"])]
SourceKind = Literal[tuple(sources.KINDS)]


class Described(BaseModel):
    """What a card is about and like: the tags the writer describes it with.

    The genre and strand are not here — they are asked for, not described —
    and neither is the language, which the run sets.
    """
    keywords: list[str] = Field(description="Three to six lowercase handles, one to four words each: the things, people, places and ideas in the card.")
    era: Era = Field(description="When the matter is set; timeless for a mechanism or a principle.")
    region: Region = Field(description="Where it is set; none when the card has no place in it.")
    hook: Hook = Field(description="What pulls the reader in. One, the strongest.")
    mood: Mood = Field(description="The register the card is read in.")
    numeracy: int = Field(description="0 no number, 1 a figure to take in, 2 a comparison or a ratio, 3 a calculation.")
    abstraction: Abstraction
    shelf_life: ShelfLife = Field(description="evergreen unless the answer could differ in a few years, or within the year.")
    mature: bool = Field(description="Sex, drugs, violence, gambling or death in detail.")
    builds_on: list[str] = Field(description="Ids from the brief a reader is better off having met first. Usually empty.")
    figure: Figure = Field(description="The picture that would help, or none.")


class Tags(Described):
    """The tags alone, for a card that was written before there were tags."""
    genre: str = Field(description="The genre id from the list given; empty on a thinking card.")
    strand: str = Field(description="The strand id under that genre; empty on a thinking card.")


class Draft(Described):
    """A card as the model writes it: every field present, empty when unused.

    Structured outputs want every property required and no numeric or
    length constraints, so the shape is loose here and check.py is strict.
    """
    topic: str
    kind: Literal["read", "pickOne", "number", "estimate", "debate"]
    difficulty: Literal["easy", "medium", "hard"]
    principle: str
    question: str
    answer: str
    move: str
    trap: str = Field(description="Empty on a read or a debate.")
    hint: str = Field(description="Number and estimate only; empty otherwise.")
    simply: str = Field(description="Empty unless there is a genuinely second way in.")
    counterpoint: str = Field(description="Debate only; empty otherwise.")
    steps: list[str] = Field(description="Number and estimate only; empty otherwise.")
    options: list[str] = Field(description="pickOne only; empty otherwise.")
    correct: int = Field(description="Index into options; 0 when there are none.")
    value: float = Field(description="Number and estimate only; 0 otherwise.")
    unit: str = Field(description="Number and estimate only; empty otherwise.")
    tolerance: float = Field(description="Number only, 0 unless the answer has decimals.")
    withinFactor: float = Field(description="Estimate only; 3 is the norm. 0 otherwise.")
    sides: list[str] = Field(description="Debate only, exactly two; empty otherwise.")
    source: str = Field(description="Institution and document, two to eight words, as the reader sees it.")
    reference: str = Field(description="The URL of the page the card was written from; on a thinking card, the name of the result, a DOI or author and year.")
    source_kind: SourceKind = Field(description="What kind of thing the reference is (§20). arithmetic on a thinking card.")
    also: list[str] = Field(description="Up to three other strand ids the card is genuinely about, from the list of strands. Usually empty.")


class Verdict(BaseModel):
    verdict: Literal["pass", "fix", "reject"]
    reason: str = Field(description="One line: what is wrong, or what was checked and held.")
    fixed: Draft | None = Field(description="On fix only: the card with the correction made, nothing else changed.")


class Find(BaseModel):
    """One thing a card could be built on, and where it is stated."""
    claim: str = Field(description="One line: the specific, checkable thing.")
    figures: str = Field(description="Every figure in the claim with its unit and year; empty when there is none.")
    source: str = Field(description="Institution and document, two to eight words, as a card would name it.")
    url: str = Field(description="The one page that states it. Never a search page, never an encyclopaedia entry.")
    source_kind: SourceKind
    why_not_textbook: str = Field(description="One line: why this is not the instance every reader has already met.")


class Finds(BaseModel):
    finds: list[Find] = Field(description="Three, best first, each from a different site and, where possible, a different kind of source.")


class Reading(BaseModel):
    """What one page, opened and read, actually says about one claim."""
    supported: bool = Field(description="Whether the page states the claim as given, with the same figures.")
    quote: str = Field(description="The passage that states it, verbatim from the page, at most forty words. Empty when unsupported.")
    figures: str = Field(description="Every figure in the passage, with unit and year.")
    note: str = Field(description="When unsupported: one line on what the page actually says, or that it could not be read.")


def to_card(draft: Draft) -> dict:
    """The draft as a bank card: only the fields its kind has."""
    d = draft.model_dump()
    card = {k: d[k] for k in ("topic", "kind", "difficulty", "principle", "question")}
    kind = d["kind"]
    if kind == "pickOne":
        card["options"] = d["options"]
        card["correct"] = d["correct"]
    elif kind in ("number", "estimate"):
        card["value"] = _tidy(d["value"])
        card["unit"] = d["unit"]
        if kind == "number" and d["tolerance"]:
            card["tolerance"] = _tidy(d["tolerance"])
        if kind == "estimate":
            card["withinFactor"] = _tidy(d["withinFactor"] or 3)
    elif kind == "debate":
        card["sides"] = d["sides"]
    card["answer"] = d["answer"].strip()
    if kind in ("number", "estimate") and d["steps"] and not card["answer"]:
        card["answer"] = d["steps"][-1]
    card["move"] = d["move"].strip()
    for key in ("trap", "hint", "simply", "counterpoint"):
        if d[key].strip() and not (kind == "debate" and key == "trap") and not (kind == "read" and key in ("hint", "counterpoint")):
            card[key] = d[key].strip()
    if d["steps"] and kind in ("number", "estimate"):
        card["steps"] = [s.strip() for s in d["steps"] if s.strip()]
    card["source"] = d["source"].strip()
    card["reference"] = d["reference"].strip()
    card["source_kind"] = d["source_kind"]
    if d["also"]:
        card["also"] = [a.strip() for a in d["also"] if a.strip()]
    card.update(described(draft))
    return card


def described(tags: Described) -> dict:
    """The tag fields as the bank keeps them: cleaned, and absent when empty."""
    d = tags.model_dump()
    out = {
        "keywords": [k.strip().lower() for k in d["keywords"] if k.strip()],
        "era": d["era"], "region": d["region"], "hook": d["hook"], "mood": d["mood"],
        "numeracy": int(d["numeracy"]), "abstraction": d["abstraction"],
        "shelf_life": d["shelf_life"], "mature": bool(d["mature"]),
    }
    if d["builds_on"]:
        out["builds_on"] = [b.strip() for b in d["builds_on"] if b.strip()]
    if d["figure"] != "none":
        out["figure"] = d["figure"]
    return out


def _tidy(x: float) -> int | float:
    return int(x) if float(x).is_integer() else x


# --------------------------------------------------------------------------
# The plan: what the bank is short of

class Request(BaseModel):
    topic: str
    kind: str
    difficulty: str
    principle: str
    # The genre and the strand under it, by id; empty on a thinking card.
    genre: str = ""
    strand: str = ""
    language: str = "en"
    # On a graded card, the principles the writer may choose between: the
    # thinnest few, so that the one that fits the strand is taken rather
    # than one forced onto it. `principle` is the first of them until the
    # card is written, and then whichever the writer chose.
    principles: list[str] = []
    # The kind of source the strand has least of; the scout is asked for
    # it and may bring others.
    source_kind: str = ""

    def __str__(self) -> str:
        where = f" · {genres.describe(self.strand)}" if self.strand else ""
        tail = ""
        if len(self.principles) > 1:
            tail = " · one of " + "/".join(self.principles)
        elif self.principle != "none":
            tail = f" · {self.principle}"
        kind = f" · {self.source_kind}" if self.source_kind and self.source_kind != "arithmetic" else ""
        return f"{self.topic}{where} · {self.kind} · {self.difficulty}{tail}{kind}"


def for_strand(strand: genres.Strand | None, topic: str, **rest) -> Request:
    """A request placed on a strand — or on none, for Thinking."""
    if strand is None:
        return Request(topic=topic, **{**rest, "source_kind": "arithmetic"})
    return Request(topic=strand.topic, genre=strand.genre, strand=strand.id, **rest)


def plan(bank: list[dict], count: int, *, topics: list[str] | None = None, seed: int = 0) -> list[Request]:
    """The next [count] cards to ask for, biggest gap first, subjects interleaved.

    Inside a subject the card lands on its thinnest strand: every strand
    towards STRAND_TARGET before any has a third. So a night's twenty
    reach twenty strands across as many subjects as are short, and the
    mix a reader set has something under every name on it as soon as the
    bank can manage. The kind of source asked for is the one the subject
    has least of, for the same reason."""
    live = [c for c in bank if not c.get("disabled")]
    by_topic: dict[str, Counter] = {t: Counter() for t in (topics or TOPICS)}
    for c in live:
        if c["topic"] in by_topic:
            by_topic[c["topic"]][c["kind"]] += 1
    per_strand = strand_counts(live)
    kinds_by_topic = {t: Counter(c.get("source_kind") for c in live if c["topic"] == t and c.get("source_kind")) for t in by_topic}
    principle_count = Counter(c["principle"] for c in live if c["principle"] != "none")
    for p in PRINCIPLES:
        principle_count.setdefault(p, 0)
    per_topic_principles = {t: Counter(c["principle"] for c in live if c["topic"] == t) for t in by_topic}
    rng = random.Random(seed)

    def asks(t: str) -> int:
        return sum(by_topic[t][k] for k in check.GRADED)

    def deficit(t: str) -> int:
        k = by_topic[t]
        return (max(0, TARGET_READS - k["read"]) + max(0, TARGET_ASKS - asks(t))
                + max(0, TARGET_DEBATES - k["debate"])
                + sum(max(0, STRAND_TARGET - per_strand[s.id]) for s in genres.strands_of(t)))

    out: list[Request] = []
    while len(out) < count:
        order = sorted(by_topic, key=lambda t: (-deficit(t), t))
        if deficit(order[0]) == 0:
            # Every subject is full: keep going on the thinnest principles.
            order = [t for t in order if t != "thinking"] or order
            rng.shuffle(order)
        progressed = False
        for t in order:
            if len(out) >= count:
                break
            k = by_topic[t]
            # Shortfalls relative to their targets: a subject with no graded
            # question gets one before its thirty-sixth read.
            short_read = max(0, TARGET_READS - k["read"]) / TARGET_READS
            short_ask = max(0, TARGET_ASKS - asks(t)) / TARGET_ASKS
            short_debate = max(0, TARGET_DEBATES - k["debate"]) / TARGET_DEBATES
            strand = thinnest_strand(t, per_strand, rng)
            source_kind = thinnest_source_kind(t, kinds_by_topic[t], rng)
            if (short_ask >= short_read and short_ask >= short_debate and short_ask > 0) or deficit(t) == 0:
                kind = _ask_kind(k)
                choice = _principles_for(t, principle_count, per_topic_principles[t], rng, kind)
                hard = (asks(t) + 1) % int(round(1 / HARD_SHARE)) == 0
                req = for_strand(strand, t, kind=kind, difficulty="hard" if hard else "medium",
                                 principle=choice[0], principles=choice, source_kind=source_kind)
                principle_count[choice[0]] += 1
                per_topic_principles[t][choice[0]] += 1
            elif short_read >= short_debate and short_read > 0:
                req = for_strand(strand, t, kind="read", difficulty="easy", principle="none", source_kind=source_kind)
            else:
                req = for_strand(strand, t, kind="debate", difficulty="medium", principle="none", source_kind=source_kind)
            by_topic[t][req.kind] += 1
            if strand is not None:
                per_strand[strand.id] += 1
                kinds_by_topic[t][req.source_kind] += 1
            out.append(req)
            progressed = True
        if not progressed:
            break
    return out


def strand_counts(cards: list[dict]) -> Counter:
    """How many live cards each strand holds."""
    return Counter(c["strand"] for c in cards if c.get("strand") and not c.get("disabled"))


def thinnest_strand(topic: str, per_strand: Counter, rng: random.Random) -> genres.Strand | None:
    """The strand under [topic] with the fewest cards; None for Thinking.
    Ties go by the seed, so the same bank plans the same night."""
    strands = genres.strands_of(topic)
    if not strands:
        return None
    low = min(per_strand[s.id] for s in strands)
    return rng.choice([s for s in strands if per_strand[s.id] == low])


def thinnest_source_kind(topic: str, counts: Counter, rng: random.Random) -> str:
    """The kind of source the subject has least of, among the kinds that
    suit it — a standards body is not where the history of photography
    lives. Arithmetic for Thinking."""
    if topic == "thinking":
        return "arithmetic"
    kinds = sources.kinds_for(topic)
    low = min(counts[k] for k in kinds)
    return rng.choice([k for k in kinds if counts[k] == low])


def _ask_kind(k: Counter) -> str:
    total = sum(k[x] for x in ASK_MIX) + 1
    short = {x: ASK_MIX[x] * total - k[x] for x in ASK_MIX}
    return max(short, key=lambda x: (short[x], x == "pickOne"))


def _principles_for(topic: str, overall: Counter, in_topic: Counter, rng: random.Random, kind: str) -> list[str]:
    """The thinnest few principles, first the ones this subject has never
    met, in a stable order. An estimate is always estimation."""
    if kind == "estimate":
        return ["estimation"]
    pool = [p for p in PRINCIPLES if p not in ("estimation", "computation")] if kind == "pickOne" else PRINCIPLES
    unused_here = [p for p in pool if in_topic[p] == 0]
    candidates = unused_here or pool
    rng.shuffle(candidates)
    candidates.sort(key=lambda p: overall[p])
    return candidates[:PRINCIPLE_CHOICE]


# --------------------------------------------------------------------------
# The briefs: what each stage is told

def rules_section(number: int) -> str:
    """One numbered section of RULES.md, header included."""
    text = RULES.read_text(encoding="utf-8")
    start = text.index(f"\n## {number}. ") + 1
    end = text.find("\n## ", start)
    return text[start:] if end < 0 else text[start:end]


def blacklist_section() -> str:
    return ("## The blacklist\n\nNothing built on any of these, in any wording:\n\n"
            + "\n".join(f"- {b}" for b in check.load_banned()))


def strands_section() -> str:
    """Every strand there is, by subject, for `also`."""
    lines = ["## The strands", "", "Every strand there is, by subject — the ids `also` may name:", ""]
    for topic, gs in genres.by_topic().items():
        lines.append(f"- {topic}: " + ", ".join(s.id for g in gs for s in g.strands))
    return "\n".join(lines)


def system_prompt(bank: list[dict]) -> str:
    """The writer's system prompt: the rules, the blacklist, the house
    style, the strands. Cached across the run."""
    by_id = {c["id"]: c for c in bank}
    examples = [check.public(by_id[i]) for i in EXEMPLARS if i in by_id]
    return (
        RULES.read_text(encoding="utf-8")
        + "\n\n" + blacklist_section()
        + "\n\n" + strands_section()
        + "\n\n## Cards from the bank, as the house writes them\n\n"
        + "\n\n".join("```json\n" + json.dumps(e, ensure_ascii=False, indent=1) + "\n```" for e in examples)
    )


SCOUT = """You scout material for Astute cards. You never write a card: you find what
one could be built on, and you find it on the open web, on pages a careful
reader could open and check.

A find is one specific, checkable thing: a figure with its unit and year, a
documented event, a mechanism as a named source describes it. Search as a
researcher does — the body that collects the statistic, the archive that
holds the document, the journal that published the result — and give the
page that states the thing, not a page that repeats it. An encyclopaedia
may lead you to the source; it is never the source. A search-results page,
a list of facts, a forum or a feed is never a find.

Refuse the textbook instance of the strand — the example every reader has
met — and anything on the blacklist. Prefer what a curious reader has not
met: the second-best-known figure, the document behind the famous claim,
the number that surprises. Three finds, best first, each from a different
site and, where you can, a different kind of source."""

KIND_WANTS = {
    "read": "a card that tells: something worth turning the card over for, with the figure that makes it true",
    "pickOne": "a card that asks: a question with one defensible answer among two or three options, and a trap a competent reader falls into",
    "number": "a card the reader works out: a number reached in two to five steps from figures the page gives",
    "estimate": "a card the reader estimates: a quantity to guess within a factor of three, with the true figure on the page",
    "debate": "a card that takes a side: a live disagreement with two defensible positions and a strongest case each way",
}


def scout_system(topic: str) -> str:
    return "\n\n".join([SCOUT, rules_section(13), rules_section(15), rules_section(20), blacklist_section()])


def scout_brief(req: Request, bank: list[dict]) -> str:
    strand = genres.strands_by_id()[req.strand]
    genre = genres.genres_by_id()[req.genre]
    live = [c for c in bank if not c.get("disabled")]
    in_strand = [c for c in live if c.get("strand") == req.strand]
    lines = [
        "Find three finds for one card.",
        "",
        f"topic: {req.topic}",
        f"genre: {genre.label} ({genre.id})",
        f"strand: {strand.label} ({strand.id})",
        f"kind: {req.kind} — {KIND_WANTS[req.kind]}",
    ]
    if req.principles:
        lines.append("principle: one of " + ", ".join(req.principles) + " — the find must be a real instance of one of them, in this strand")
    elif req.principle != "none":
        lines.append(f"principle: {req.principle} — the find must be a real instance of it, in this strand")
    if req.source_kind:
        lines.append(f"source kind wanted: {req.source_kind} — {sources.KIND_MEANS.get(req.source_kind, '')}; at least one of the three, the others may differ")
    preferred = sources.preferred(req.topic)
    if preferred:
        lines.append("Sites readers of this subject trust first, a preference and not a fence: " + ", ".join(preferred))
    lines.append("")
    others = ", ".join(s.label for s in genre.strands if s.id != strand.id)
    lines.append(f"The card is about {strand.label} and nothing beside it. The genre's other strands, which are not this card: {others}.")
    if in_strand:
        lines.append(f"Already on this strand — the finds are about something none of these says:")
        lines += [f"- {c['question']}" for c in in_strand]
    lines.append("")
    lines.append("For each find: claim, figures, source, url, source_kind, why_not_textbook. Best first.")
    return "\n".join(lines)


READER = """You read one page for Astute and report only what it says. Open the url
you are given, with the tool, and read it in full.

If the page states the claim: copy the passage that states it, verbatim,
at most forty words, exactly as the page prints it, and list every figure
in that passage with its unit and year.

If the page does not state it, states it with a different figure, could
not be opened, or is not the page it was said to be: report supported
false and say in one line what the page actually says.

Never infer a figure the page does not print. Never quote from memory:
only from the page you opened, and only words that are on it."""


def reading_brief(find: Find) -> str:
    return "\n".join([
        f"url: {find.url}",
        f"claim: {find.claim}",
        f"figures expected: {find.figures or 'none'}",
        f"source as named: {find.source}",
    ])


def brief(req: Request, bank: list[dict]) -> str:
    """The writer's brief: what to write, and what is already there."""
    live = [c for c in bank if not c.get("disabled")]
    in_topic = [c for c in live if c["topic"] == req.topic]
    same_principle = [c for c in live if req.principle != "none" and c["principle"] == req.principle]
    lines = ["Write one card.", "", f"topic: {req.topic}"]
    if req.strand:
        strand = genres.strands_by_id()[req.strand]
        genre = genres.genres_by_id()[req.genre]
        lines += [f"genre: {genre.label} ({genre.id})", f"strand: {strand.label} ({strand.id})"]
    principle = req.principle
    if len(req.principles) > 1:
        principle = "one of " + ", ".join(req.principles) + " — whichever the strand has a real instance of"
    lines += [f"kind: {req.kind}", f"difficulty: {req.difficulty}", f"principle: {principle}", ""]
    if req.strand:
        others = ", ".join(s.label for s in genre.strands if s.id != strand.id)
        lines.append(f"The card is about {strand.label} and nothing beside it. The genre's other strands, which are not this card: {others}.")
        in_strand = [c for c in in_topic if c.get("strand") == req.strand]
        if in_strand:
            lines.append(f"Cards already in {strand.label} — the new one sits beside these and says something none of them says:")
            lines += [f"- [{c['id']}] {c['question']}" for c in in_strand]
        lines.append("")
    if same_principle:
        lines.append(f"Contexts already used for {req.principle} — do not reuse their domain or their example:")
        lines += [f"- {c['question']}" for c in same_principle[-12:]]
        lines.append("")
    if in_topic:
        lines.append(f"Every question already in {req.topic} — a twin of any of these is refused:")
        lines += [f"- [{c['id']}] {c['question']}" for c in in_topic]
        lines.append("")
    moves = [c["move"] for c in (same_principle or in_topic)]
    if moves:
        lines.append("Moves already in the bank — do not repeat one, even reworded:")
        lines += [f"- {m}" for m in moves[-20:]]
        lines.append("")
    lines.append("Return the card as JSON in the schema, tags included (§19). Leave a field empty when the kind has no use for it. builds_on may name only ids listed above, and is usually empty.")
    return "\n".join(lines)


def from_find(find: Find, reading: Reading) -> str:
    """What the writer writes from, and the rule that it writes from nothing else."""
    return "\n".join([
        "",
        "Write the card from this find and from nothing else:",
        "",
        f"claim: {find.claim}",
        f"source: {find.source}",
        f"reference: {find.url}",
        f"source kind: {find.source_kind}",
        f'passage from the page, verbatim: "{reading.quote}"',
        f"figures in the passage: {reading.figures or 'none'}",
        "",
        "Every figure in the card is in that passage, or follows from it by arithmetic shown in the steps. If the card needs a figure the passage does not give, write a card that does not need it. The source and the reference are these; set source_kind to the kind above. Set also to the other strands, up to three, the card is genuinely about, from the list of strands, or leave it empty.",
    ])


CRITIC = """You are the critic. You are given one card written for Astute and the rules it
was written under. Your only task is to find why it must be rejected. Never
improve it for the sake of it.

Do all of this:
1. Open the reference and say whether it supports every figure and claim in
   the answer. When a quoted passage is given, every figure in the card is
   in it or follows from it by arithmetic shown in the steps; a figure in
   neither is a reject. A figure you cannot verify is a reject.
2. Redo every number in the steps and the answer.
3. On a pickOne, try to defend each wrong option as a competent reader would.
   If one can be defended, reject: the card is ambiguous.
4. Look for the textbook instance of the principle and for anything on the
   blacklist.
5. Check that the trap is the principle going wrong, and that the move stands
   without the card.
6. Read the tags against the card: the strand is what the card is about,
   the era and region are where it is set, the hook is what pulls, the
   numeracy is what the reader has to do with numbers, the shelf life is
   how soon the answer could change, mature is honest, source_kind is what
   the reference is. A tag that is not true of the card is a fix.

Return pass when everything held; fix when one thing is wrong and you can
correct it without rewriting the card (a figure, a reference, a unit, one
option, a tag) — then return the whole card in `fixed` with only that
change; reject otherwise. One line of reason."""


def critic_system(rules: str) -> str:
    return rules + "\n\n---\n\n" + CRITIC


def critic_brief(card: dict, reading: Reading | None) -> str:
    text = "The card:\n\n```json\n" + json.dumps(check.public(card), ensure_ascii=False, indent=1) + "\n```"
    if reading is not None and reading.quote:
        text += f'\n\nThe reader opened the reference and copied this passage from it, verbatim:\n"{reading.quote}"\nFigures in the passage: {reading.figures or "none"}'
    return text


# --------------------------------------------------------------------------
# The model

@dataclass
class Spec:
    """One call: what the model is told, and the shape it answers in."""
    system: str
    messages: list
    output_format: type[BaseModel]
    tools: list | None = None
    effort: str = "high"
    max_tokens: int = MAX_TOKENS


@dataclass
class Result:
    parsed: BaseModel | None
    message: object | None
    error: str | None


def _web_search(max_uses: int) -> dict:
    return {"type": "web_search_20260209", "name": "web_search", "max_uses": max_uses, "blocked_domains": sources.blocked()}


def _web_fetch(max_uses: int, *, only: str | None = None) -> dict:
    tool = {"type": "web_fetch_20260209", "name": "web_fetch", "max_uses": max_uses, "max_content_tokens": 40000}
    if only:
        tool["allowed_domains"] = [only]
    else:
        tool["blocked_domains"] = sources.blocked()
    return tool


def output_schema(model: type[BaseModel]) -> dict:
    """The model's JSON schema as the API takes it: every property
    required, no numeric or length constraints, nothing extra."""
    try:
        from anthropic.lib._parse._transform import transform_schema
        return transform_schema(model.model_json_schema())
    except ImportError:  # pragma: no cover - an older SDK
        return _strict_schema(model.model_json_schema())


def _strict_schema(node):
    if isinstance(node, dict):
        node = {k: _strict_schema(v) for k, v in node.items() if k not in ("title", "minimum", "maximum", "minItems", "maxItems", "minLength", "maxLength")}
        if node.get("type") == "object":
            node["additionalProperties"] = False
            if "properties" in node:
                node["required"] = list(node["properties"])
        return node
    if isinstance(node, list):
        return [_strict_schema(v) for v in node]
    return node


def last_text(message) -> str:
    """The JSON the model returned: the last text block, after any tool blocks."""
    texts = [b.text for b in message.content if getattr(b, "type", "") == "text"]
    return texts[-1] if texts else ""


def page_text(message) -> str | None:
    """Everything the fetch tool brought back as plain text, or None when
    nothing was fetched or it was not text (a PDF)."""
    texts = []
    for block in getattr(message, "content", []) or []:
        if getattr(block, "type", "") != "web_fetch_tool_result":
            continue
        result = getattr(block, "content", None)
        if getattr(result, "type", "") != "web_fetch_result":
            continue
        source = getattr(getattr(result, "content", None), "source", None)
        if getattr(source, "type", "") == "text":
            texts.append(source.data)
    return "\n".join(texts) if texts else None


class Claude:
    """Every stage, over the Anthropic API — one call at a time, or a
    stage at a time through the Message Batches API at half the price."""

    def __init__(self, model: str = MODEL, *, batch: bool = False):
        import anthropic

        self.anthropic = anthropic
        self.client = anthropic.Anthropic()
        self.model = model
        self.batch = batch
        self.usage: dict[str, Counter] = {}

    # -- one call ----------------------------------------------------------

    def _params(self, spec: Spec) -> dict:
        params = dict(
            model=self.model,
            max_tokens=spec.max_tokens,
            system=[{"type": "text", "text": spec.system, "cache_control": {"type": "ephemeral"}}],
            messages=spec.messages,
            output_config={"effort": spec.effort, "format": {"type": "json_schema", "schema": output_schema(spec.output_format)}},
            fallbacks="default",
        )
        if spec.tools:
            params["tools"] = spec.tools
        return params

    def _finish(self, spec: Spec, message) -> Result:
        if message.stop_reason == "refusal":
            return Result(None, message, "the model declined: " + str(getattr(getattr(message, "stop_details", None), "explanation", "") or ""))
        if message.stop_reason == "max_tokens":
            return Result(None, message, "the reply ran past max_tokens")
        if message.stop_reason == "pause_turn":
            return Result(None, message, "the turn paused on a tool and was not resumed")
        text = last_text(message)
        if not text.strip():
            return Result(None, message, "no JSON came back")
        try:
            return Result(spec.output_format.model_validate_json(text), message, None)
        except ValidationError as error:
            return Result(None, message, "the reply was not the JSON asked for: " + str(error).splitlines()[0])

    def call(self, spec: Spec, stage: str = "call") -> Result:
        params = self._params(spec)
        messages = list(spec.messages)
        for _ in range(6):
            message = self.client.beta.messages.create(**{**params, "messages": messages}, betas=[FALLBACK_BETA])
            self._count(message.usage, stage)
            if message.stop_reason == "pause_turn":
                # A server tool ran out of turns; hand the turn back and it resumes.
                messages = messages + [{"role": "assistant", "content": message.content}]
                continue
            return self._finish(spec, message)
        return Result(None, None, "the turn kept pausing")

    # -- a stage at a time -------------------------------------------------

    def calls(self, specs: list[Spec], stage: str) -> list[Result]:
        if not specs:
            return []
        if not self.batch or len(specs) == 1:
            return [self._safe(spec, stage) for spec in specs]
        return self._batched(specs, stage)

    def _safe(self, spec: Spec, stage: str) -> Result:
        try:
            return self.call(spec, stage)
        except Exception as error:  # one bad call must not end the night
            return Result(None, None, f"{type(error).__name__}: {error}")

    def _batched(self, specs: list[Spec], stage: str) -> list[Result]:
        requests = [{"custom_id": f"{stage}-{i}", "params": self._params(spec)} for i, spec in enumerate(specs)]
        batch = self.client.beta.messages.batches.create(requests=requests, betas=[FALLBACK_BETA])
        deadline = time.time() + BATCH_WAIT_SECONDS
        while batch.processing_status != "ended":
            if time.time() > deadline:
                raise RuntimeError(f"batch {batch.id} for {stage} did not end within {BATCH_WAIT_SECONDS // 3600} hours")
            time.sleep(BATCH_POLL_SECONDS)
            batch = self.client.beta.messages.batches.retrieve(batch.id, betas=[FALLBACK_BETA])
        results = {r.custom_id: r for r in self.client.beta.messages.batches.results(batch.id, betas=[FALLBACK_BETA])}
        out: list[Result] = []
        for i, spec in enumerate(specs):
            r = results.get(f"{stage}-{i}")
            if r is None:
                out.append(Result(None, None, "no result came back from the batch"))
            elif r.result.type != "succeeded":
                detail = f": {getattr(r.result, 'error', '')}" if r.result.type == "errored" else ""
                out.append(Result(None, None, f"the batch request {r.result.type}{detail}"))
            else:
                self._count(r.result.message.usage, stage)
                out.append(self._finish(spec, r.result.message))
        return out

    # -- the receipt -------------------------------------------------------

    def _count(self, usage, stage: str) -> None:
        u = self.usage.setdefault(stage, Counter())
        u["input"] += getattr(usage, "input_tokens", 0) or 0
        u["output"] += getattr(usage, "output_tokens", 0) or 0
        u["cache_read"] += getattr(usage, "cache_read_input_tokens", 0) or 0
        u["cache_write"] += getattr(usage, "cache_creation_input_tokens", 0) or 0
        tools = getattr(usage, "server_tool_use", None)
        u["searches"] += getattr(tools, "web_search_requests", 0) or 0
        u["fetches"] += getattr(tools, "web_fetch_requests", 0) or 0

    def cost(self, u: Counter) -> float:
        discount = 0.5 if self.batch else 1.0
        return sum(u[k] * PRICE[k] / 1e6 for k in PRICE) * discount + u["searches"] * SEARCH_PRICE

    def receipt(self) -> str:
        if not self.usage:
            return "no tokens"
        lines = []
        for stage, u in self.usage.items():
            lines.append(f"{stage}: {u['input']:,} in · {u['output']:,} out · {u['cache_read']:,} cached"
                         + (f" · {u['searches']} searches" if u["searches"] else "")
                         + (f" · {u['fetches']} pages" if u["fetches"] else "")
                         + f" · ${self.cost(u):.2f}")
        total = sum(self.cost(u) for u in self.usage.values())
        lines.append(f"total ${total:.2f}" + (" at batch prices" if self.batch else ""))
        return "\n".join(lines)

    def tag(self, system: str, card_text: str) -> Tags:
        result = self.call(Spec(system=system, messages=[{"role": "user", "content": card_text}], output_format=Tags, effort="medium"), "tag")
        if result.error:
            raise RuntimeError(result.error)
        return result.parsed


class Fake:
    """A model that returns what it is told to, or a canned answer of the
    right shape. For tests and --fake."""

    def __init__(self, drafts: list[Draft] | None = None, verdicts: list[Verdict] | None = None,
                 tags: list[Tags] | None = None, finds: list[Finds] | None = None,
                 readings: list[Reading] | None = None):
        self.drafts = list(drafts or [])
        self.verdicts = list(verdicts or [])
        self.tags = list(tags or [])
        self.finds = list(finds or [])
        self.readings = list(readings or [])
        self.calls: list[str] = []
        self.batch = False

    def call(self, spec: Spec, stage: str = "call") -> Result:
        self.calls.append(stage)
        asked = spec.messages[-1]["content"] if spec.messages else ""
        asked = asked if isinstance(asked, str) else ""
        shape = spec.output_format
        if shape is Finds:
            return Result(self.finds.pop(0) if self.finds else canned_finds(asked), None, None)
        if shape is Reading:
            return Result(self.readings.pop(0) if self.readings else canned_reading(), None, None)
        if shape is Draft:
            return Result(self.drafts.pop(0) if self.drafts else canned(asked), None, None)
        if shape is Verdict:
            return Result(self.verdicts.pop(0) if self.verdicts else Verdict(verdict="pass", reason="canned", fixed=None), None, None)
        if shape is Tags:
            return Result(self.tags.pop(0) if self.tags else canned_tags_for(asked), None, None)
        raise TypeError(f"nothing canned for {shape.__name__}")

    def run_calls(self, specs: list[Spec], stage: str) -> list[Result]:
        return [self.call(spec, stage) for spec in specs]

    def tag(self, system: str, card_text: str) -> Tags:
        return self.call(Spec(system=system, messages=[{"role": "user", "content": card_text}], output_format=Tags), "tag").parsed

    def receipt(self) -> str:
        return "no tokens: the model was canned"


def calls(model, specs: list[Spec], stage: str) -> list[Result]:
    """A stage of calls on whichever model, real or canned. The Fake keeps
    `calls` as its log of stages, as the tests read it, so its runner has
    another name."""
    if isinstance(model, Fake):
        return model.run_calls(specs, stage)
    return model.calls(specs, stage)


_canned = itertools.count()


def canned(brief_text: str) -> Draft:
    """A card that passes the strict gate, for exercising the plumbing."""
    fields = dict(line.split(": ", 1) for line in brief_text.splitlines() if ": " in line and not line.startswith("-"))
    kind = fields.get("kind", "read")
    topic = fields.get("topic", "space")
    principle = fields.get("principle", "none")
    if principle.startswith("one of "):
        principle = principle[len("one of "):].split(",")[0].strip()
    stamp = next(_canned)
    # Each canned question takes the next six words off one list, so no two
    # of them share enough to be twins - the gate would be right to say so.
    vocabulary = ["copper", "brass", "valve", "meter", "gauge", "socket", "flange", "gasket", "solder",
                  "thread", "washer", "elbow", "coupling", "manifold", "cistern", "spigot", "ballcock",
                  "grommet", "ferrule", "nipple", "bib", "tee", "union", "reducer", "bushing", "clamp",
                  "hanger", "strainer", "bleeder", "riser", "stack", "vent", "sleeve", "collar", "seal",
                  "float", "overflow", "waste", "drain", "pump", "boiler", "header"]
    picked = [vocabulary[(stamp * 6 + i) % len(vocabulary)] for i in range(6)]
    base = dict(
        topic=topic, kind=kind, difficulty=fields.get("difficulty", "easy"), principle=principle,
        **canned_tags(kind, picked[:3]),
        question=f"Which {picked[0]} {picked[1]} {picked[2]} {picked[3]} {picked[4]} {picked[5]} was tried?",
        answer=" ".join(["The plumbing handed it a canned card, and the gate read it the same way it reads a real one:"] + ["word"] * 22) + ".",
        move=f"A canned card proves the pipes, never the water {stamp}.",
        trap="", hint="", simply="", counterpoint="", steps=[], options=[], correct=0,
        value=0, unit="", tolerance=0, withinFactor=0, sides=[],
        source="The plumbing test", reference=f"https://example{stamp}.org/plumbing/2026",
        source_kind="arithmetic" if topic == "thinking" else "institution", also=[],
    )
    if kind == "pickOne":
        base.update(trap="Reading the pipe as the water it carries.", options=[f"Line {stamp}", "The water", "Neither"], correct=0)
    elif kind in ("number", "estimate"):
        base.update(hint="Count the pipes first.", steps=["Two pipes, three joints each.", "2 x 3 = 6."], value=6, unit="joints", withinFactor=3 if kind == "estimate" else 0, answer="")
        base["answer"] = ""
    elif kind == "debate":
        base.update(sides=["Yes, cap it", "No, let it run"], counterpoint=" ".join(["The other side says the pipes were never the point and that a cap on them solves nothing for anyone who was not already counting:"] + ["word"] * 20) + ".")
        base["answer"] = " ".join(["The case for a cap is that pipes cost what they cost and somebody has to say when the bill is enough for this street this year:"] + ["word"] * 20) + "."
    return Draft(**base)


def canned_tags(kind: str, keywords: list[str]) -> dict:
    """Tags that pass the gate, for a card that only has to exist."""
    return dict(
        keywords=keywords, era="timeless", region="none", hook="mechanism", mood="sober",
        numeracy=2 if kind in ("number", "estimate") else 0, abstraction="concrete",
        shelf_life="evergreen", mature=False, builds_on=[], figure="none",
    )


def canned_tags_for(card_text: str) -> Tags:
    card = json.loads(card_text[card_text.index("{"):card_text.rindex("}") + 1])
    strands = genres.strands_of(card["topic"])
    first = strands[0] if strands else None
    return Tags(**canned_tags(card["kind"], ["canned", "plumbing", "pipes"]),
                genre=first.genre if first else "", strand=first.id if first else "")


def canned_finds(brief_text: str) -> Finds:
    """Three finds on three sites, for exercising the plumbing."""
    stamp = next(_canned)
    kinds = ["statistics", "paper", "institution"]
    return Finds(finds=[
        Find(claim=f"Two pipes carry three joints each, counted in 2026, sample {stamp}-{i}.",
             figures="6 joints, 2026", source=f"The plumbing office, count {stamp}",
             url=f"https://example{stamp}{i}.org/plumbing/{i}", source_kind=kinds[i],
             why_not_textbook="Nobody has met this pipe.")
        for i in range(3)
    ])


def canned_reading() -> Reading:
    return Reading(supported=True,
                   quote="The plumbing handed the reader a canned page and the reader copied this line from it.",
                   figures="6 joints, 2026", note="")


# --------------------------------------------------------------------------
# Verification: what a program can check about a reading

def verify_reading(reading: Reading, message) -> tuple[str, str]:
    """Whether a reading holds. `checked` means the quote was found on the
    page the tool brought back; `unchecked` that the page was not plain
    text (a PDF) and the reader's word stands; anything else is a reason
    the find is dropped."""
    if not reading.supported:
        return "unsupported", reading.note or "the page does not state the claim"
    n = len(reading.quote.split())
    if n < 6:
        return "no quote", "the passage is shorter than a sentence"
    if n > check.QUOTE_WORDS:
        return "no quote", f"the passage runs to {n} words"
    text = page_text(message)
    if text is None:
        return "unchecked", "the page was not plain text"
    if sources.same_quote(reading.quote, text):
        return "checked", ""
    return "not on page", "the quoted passage is not on the page"


# --------------------------------------------------------------------------
# The pipeline

class Outcome(BaseModel):
    request: Request
    status: Literal["written", "unsourced", "refused", "rejected", "failed"]
    stage: str = ""
    id: str = ""
    question: str = ""
    note: str = ""
    domain: str = ""
    source_kind: str = ""
    checked: bool = False


@dataclass
class Job:
    """One request on its way through the stages."""
    req: Request
    finds: list[Find] = field(default_factory=list)
    tried: int = 0
    find: Find | None = None
    reading: Reading | None = None
    checked: bool = False
    draft: Draft | None = None
    history: list = field(default_factory=list)
    card: dict | None = None
    problems: list[str] = field(default_factory=list)
    status: str = ""
    stage: str = ""
    note: str = ""

    @property
    def researched(self) -> bool:
        return bool(self.req.strand)

    def fail(self, status: str, stage: str, note: str) -> None:
        self.status, self.stage, self.note = status, stage, note

    def outcome(self) -> Outcome:
        return Outcome(
            request=self.req, status=self.status or "failed", stage=self.stage,
            id=(self.card or {}).get("id", ""), question=(self.card or {}).get("question", ""),
            note=self.note, domain=sources.domain_of(self.find.url) if self.find else "",
            source_kind=(self.card or {}).get("source_kind", ""), checked=self.checked,
        )


def conform(card: dict, req: Request, find: Find | None = None, reading: Reading | None = None) -> dict:
    """The card as an answer to [req]: the model does not get to change the
    subject, the strand, the kind, the principle or the language it was
    asked for — nor, when it wrote from a find, the source it wrote from."""
    card["topic"], card["kind"] = req.topic, req.kind
    card["principle"] = card.get("principle") if card.get("principle") in req.principles else req.principle
    if req.strand:
        card["genre"], card["strand"] = req.genre, req.strand
    else:
        card.pop("genre", None)
        card.pop("strand", None)
    card["language"] = req.language
    known = genres.strands_by_id()
    also = [a for a in dict.fromkeys(card.get("also", [])) if a in known and a != req.strand][:3]
    if also:
        card["also"] = also
    else:
        card.pop("also", None)
    if find is not None and reading is not None:
        card["reference"] = find.url
        card["source_kind"] = find.source_kind
        card["quote"] = reading.quote
        if not card.get("source", "").strip():
            card["source"] = find.source
    elif req.topic == "thinking":
        if card.get("source_kind") not in ("arithmetic", "paper", "book", "reference_work"):
            card["source_kind"] = "arithmetic"
        card.pop("quote", None)
    if req.kind == "read":
        card["difficulty"] = "easy"
    elif card["difficulty"] == "easy":
        card["difficulty"] = req.difficulty
    return card


def next_id(topic: str, today: dt.date, taken: set[str]) -> str:
    n = 1
    while f"{topic}-{today:%Y%m%d}-{n}" in taken:
        n += 1
    return f"{topic}-{today:%Y%m%d}-{n}"


def usable_find(find: Find) -> bool:
    """A find the reader may be sent to: a real page on a site the house cites."""
    if not sources.is_url(find.url):
        return False
    domain = sources.domain_of(find.url)
    for never in sources.never_a_reference() + sources.blocked():
        if sources.is_under(domain, never):
            return False
    return True


def run(requests: list[Request], model, bank: list[dict], *, out: Path, today: dt.date,
        critic: bool = True, research: bool = True, log=print) -> list[Outcome]:
    schema = check.load_schema()
    banned = check.load_banned()
    rules = RULES.read_text(encoding="utf-8")
    system = system_prompt(bank)
    taken = {c["id"] for c in bank}
    jobs = [Job(req=r) for r in requests]

    def alive() -> list[Job]:
        return [j for j in jobs if not j.status]

    def gate(card: dict, against: list[dict]) -> list[str]:
        card = dict(card, id=next_id(card["topic"], today, taken), written=today.isoformat())
        return (check.check_card(card, strict=True, schema=schema, banned=banned)
                + check.check_twins([card], against=against)
                + check.check_links([card], against=against)
                + check.check_sources([card], against=against))

    # 1. The scout: three finds per card, for the cards that are written
    #    from a page. Thinking is arithmetic and skips to the writer.
    scouting = [j for j in alive() if j.researched and research]
    if scouting:
        log(f"scouting {len(scouting)} strand{'s' if len(scouting) != 1 else ''}")
        for j, r in zip(scouting, calls(model, [Spec(scout_system(j.req.topic), [{"role": "user", "content": scout_brief(j.req, bank)}], Finds, tools=[_web_search(SCOUT_SEARCHES)]) for j in scouting], "scout")):
            if r.error or r.parsed is None:
                j.fail("unsourced", "scout", r.error or "no finds came back")
                log(f"· {j.req}\n  scout: {j.note}")
                continue
            j.finds = [f for f in r.parsed.finds if usable_find(f)][:FINDS]
            if not j.finds:
                j.fail("unsourced", "scout", "every find was on a site the house does not cite")
            log(f"· {j.req}\n  finds: " + "; ".join(sources.domain_of(f.url) for f in j.finds))

        # 2. The reader: the first find's page, then the next while the
        #    first did not hold. A quote the program cannot find on the
        #    page is a find that did not hold.
        for _ in range(FINDS):
            reading = [j for j in alive() if j.researched and j.find is None and j.tried < len(j.finds)]
            if not reading:
                break
            specs = [Spec(READER, [{"role": "user", "content": reading_brief(j.finds[j.tried])}], Reading,
                          tools=[_web_fetch(2, only=sources.domain_of(j.finds[j.tried].url))], effort="medium") for j in reading]
            for j, r in zip(reading, calls(model, specs, "read")):
                candidate = j.finds[j.tried]
                j.tried += 1
                if r.error or r.parsed is None:
                    log(f"· {j.req}\n  read {candidate.url}: {r.error or 'nothing came back'}")
                    continue
                status, note = verify_reading(r.parsed, r.message)
                if status in ("checked", "unchecked"):
                    j.find, j.reading, j.checked = candidate, r.parsed, status == "checked"
                    log(f"· {j.req}\n  read {candidate.url}: holds" + ("" if j.checked else " (not machine-checked)"))
                else:
                    log(f"· {j.req}\n  read {candidate.url}: {status} — {note}")
        for j in alive():
            if j.researched and research and j.find is None:
                j.fail("unsourced", "read", "no find held up when its page was read")

    # 3. The writer.
    writing = alive()
    specs = []
    for j in writing:
        text = brief(j.req, bank)
        if j.find is not None and j.reading is not None:
            text += from_find(j.find, j.reading)
        specs.append(Spec(system, [{"role": "user", "content": text}], Draft))
    for j, spec, r in zip(writing, specs, calls(model, specs, "write")):
        if r.error or r.parsed is None:
            j.fail("failed", "write", r.error or "no card came back")
            log(f"· {j.req}\n  write: {j.note}")
            continue
        j.draft = r.parsed
        reply = r.message.content if r.message is not None else r.parsed.model_dump_json()
        j.history = spec.messages + [{"role": "assistant", "content": reply}]
        j.card = conform(to_card(j.draft), j.req, j.find, j.reading)
        j.problems = gate(j.card, bank)
        log(f"· {j.req}\n  wrote: {j.card['question']}" + (f"\n  gate: {'; '.join(j.problems)}" if j.problems else ""))

    # 4. One round of repair for what the gate named.
    repairing = [j for j in alive() if j.problems]
    if repairing:
        specs = [Spec(system, j.history + [{"role": "user", "content": "The gate refused the card:\n" + "\n".join(f"- {p}" for p in j.problems)
                                                     + "\n\nReturn the corrected card as JSON. Change only what those lines need."}], Draft) for j in repairing]
        for j, r in zip(repairing, calls(model, specs, "repair")):
            if r.error or r.parsed is None:
                log(f"· {j.req}\n  repair: {r.error or 'nothing came back'}")
                continue
            j.draft = r.parsed
            j.card = conform(to_card(j.draft), j.req, j.find, j.reading)
            j.problems = gate(j.card, bank)
    for j in alive():
        if j.problems:
            j.fail("refused", "gate", "; ".join(j.problems))
            log(f"· {j.req}\n  refused: {j.note}")

    # 5. The critic.
    if critic:
        judging = alive()
        specs = [Spec(critic_system(rules), [{"role": "user", "content": critic_brief(j.card, j.reading)}], Verdict,
                      tools=[_web_search(CRITIC_SEARCHES), _web_fetch(2)]) for j in judging]
        for j, r in zip(judging, calls(model, specs, "critic")):
            if r.error or r.parsed is None:
                j.fail("failed", "critic", r.error or "no verdict came back")
                log(f"· {j.req}\n  critic: {j.note}")
                continue
            verdict = r.parsed
            log(f"· {j.req}\n  critic: {verdict.verdict} — {verdict.reason}")
            if verdict.verdict == "reject":
                j.fail("rejected", "critic", verdict.reason)
            elif verdict.verdict == "fix" and verdict.fixed is not None:
                fixed = conform(to_card(verdict.fixed), j.req, j.find, j.reading)
                if not gate(fixed, bank):
                    j.card = fixed
                else:
                    log("  the fix did not pass the gate; keeping the draft")

    # 6. The files: tonight's cards are gated against each other too, in
    #    order, so two of them cannot be twins or cite one site on one strand.
    written: list[dict] = []
    for j in alive():
        problems = check.check_twins([dict(j.card, id="tonight")], against=written) + check.check_sources([dict(j.card, id="tonight")], against=written)
        if problems:
            j.fail("refused", "gate", "; ".join(problems))
            log(f"· {j.req}\n  refused against tonight's own cards: {j.note}")
            continue
        j.card["id"] = next_id(j.req.topic, today, taken)
        j.card["written"] = today.isoformat()
        taken.add(j.card["id"])
        folder = out / j.req.topic
        folder.mkdir(parents=True, exist_ok=True)
        (folder / f"{j.card['id']}.json").write_text(json.dumps(check.ordered(j.card), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        written.append(j.card)
        j.status = "written"
        log(f"· {j.req}\n  wrote {j.card['id']}")
    return [j.outcome() for j in jobs]


def report(outcomes: list[Outcome], receipt: str, today: dt.date) -> str:
    """The pull request body: what was written, from where, what was not, and the bill."""
    written = [o for o in outcomes if o.status == "written"]
    lines = [f"## {len(written)} new card{'s' if len(written) != 1 else ''} · {today:%-d %B %Y}", ""]
    for o in written:
        where = f" · *{genres.describe(o.request.strand)}*" if o.request.strand else ""
        source = f" · {o.source_kind}" if o.source_kind else ""
        domain = f" · {o.domain}" + ("" if o.checked or not o.domain else " (quote not machine-checked)") if o.domain else ""
        lines.append(f"- **{o.id}** — {o.question}{where}{source}{domain}")
    rest = [o for o in outcomes if o.status != "written"]
    if rest:
        lines += ["", f"### Not written ({len(rest)})", ""]
        for o in rest:
            at = f" at the {o.stage}" if o.stage else ""
            lines.append(f"- {o.request} — *{o.status}{at}*: {o.note or o.question}")
    lines += ["", "Receipt:", "", "```", receipt, "```", "",
              "Every card above was written from a page the reader opened, passed the gate and the critic. "
              "Read each one before merging; the merge is the review."]
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--plan", action="store_true", help="ask for what the bank is short of")
    ap.add_argument("--count", type=int, default=1)
    ap.add_argument("--topic", choices=TOPICS)
    ap.add_argument("--genre", choices=sorted(genres.genres_by_id()), metavar="GENRE", help="a genre id; the card lands on its thinnest strand")
    ap.add_argument("--strand", choices=sorted(genres.strands_by_id()), metavar="STRAND", help="a strand id")
    ap.add_argument("--kind", choices=["read", "pickOne", "number", "estimate", "debate"])
    ap.add_argument("--principle", choices=["none"] + PRINCIPLES)
    ap.add_argument("--difficulty", choices=["easy", "medium", "hard"])
    ap.add_argument("--only", nargs="*", choices=TOPICS, help="plan within these topics")
    ap.add_argument("--out", type=Path, default=check.BANK, help="where cards are written (default: the bank)")
    ap.add_argument("--report", type=Path, help="write the pull request body here")
    ap.add_argument("--no-critic", action="store_true")
    ap.add_argument("--no-research", action="store_true", help="write from memory, as before the scout and the reader")
    ap.add_argument("--batch", action="store_true", help="every stage through the Message Batches API, at half the token price")
    ap.add_argument("--dry-run", action="store_true", help="print the briefs; call nothing")
    ap.add_argument("--fake", action="store_true", help="a canned model: exercises everything but the writing")
    ap.add_argument("--today", help="YYYY-MM-DD for the ids and the written date")
    args = ap.parse_args(argv)

    bank = check.load_bank()
    today = dt.date.fromisoformat(args.today) if args.today else dt.date.today()
    if args.plan:
        requests = plan(bank, args.count, topics=args.only)
    else:
        if not ((args.topic or args.genre or args.strand) and args.kind):
            ap.error("give --plan, or --kind with one of --topic, --genre, --strand")
        per_strand = strand_counts(bank)
        if args.strand:
            strand = genres.strands_by_id()[args.strand]
        elif args.genre:
            genre = genres.genres_by_id()[args.genre]
            strand = min(genre.strands, key=lambda s: (per_strand[s.id], s.id))
        else:
            strand = thinnest_strand(args.topic, per_strand, random.Random(0))
        topic = strand.topic if strand else args.topic
        kind = args.kind
        principle = args.principle or ("none" if kind in ("read", "debate") else "computation" if kind == "number" else "estimation" if kind == "estimate" else "baseRate")
        difficulty = args.difficulty or ("easy" if kind == "read" else "medium")
        kinds = Counter(c.get("source_kind") for c in bank if c["topic"] == topic and c.get("source_kind"))
        source_kind = thinnest_source_kind(topic, kinds, random.Random(0))
        requests = [for_strand(strand, topic, kind=kind, difficulty=difficulty, principle=principle, source_kind=source_kind)] * args.count

    if args.dry_run:
        print(f"{len(requests)} request{'s' if len(requests) != 1 else ''}:")
        for r in requests:
            print(f"  {r}")
        first = next((r for r in requests if r.strand), None)
        if first is not None:
            print(f"\n--- scout system prompt: {len(scout_system(first.topic))} characters\n--- scout brief:\n")
            print(scout_brief(first, bank))
        if requests:
            print(f"\n--- writer system prompt: {len(system_prompt(bank))} characters\n--- writer brief:\n")
            print(brief(requests[0], bank))
        return 0

    if args.fake:
        model = Fake()
    else:
        if not os.environ.get("ANTHROPIC_API_KEY"):
            print("ANTHROPIC_API_KEY is not set; nothing was written. Use --dry-run to see the plan.", file=sys.stderr)
            return 2
        model = Claude(batch=args.batch)

    outcomes = run(requests, model, bank, out=args.out, today=today, critic=not args.no_critic, research=not args.no_research)
    text = report(outcomes, model.receipt(), today)
    if args.report:
        args.report.write_text(text, encoding="utf-8")
    print()
    print(text)
    return 0 if any(o.status == "written" for o in outcomes) or not requests else 1


if __name__ == "__main__":
    sys.exit(main())
