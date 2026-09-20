#!/usr/bin/env python3
"""Writes cards: the model drafts, the gate refuses, the critic doubts.

    python3 tool/cards/generate.py --plan --count 20        # what the bank is short of
    python3 tool/cards/generate.py --topic space --kind pickOne --principle baseRate
    python3 tool/cards/generate.py --plan --count 20 --dry-run   # the briefs, no call
    python3 tool/cards/generate.py --plan --count 3 --fake       # a canned model, for the plumbing

One card per request. The rules (RULES.md) go in the system prompt with the
blacklist and a few cards from the bank as examples of the house style, all
of it cached across the run; the brief — topic, genre and strand, kind,
principle, and every question the topic already asks — goes in the user
turn. The draft comes back as JSON in the card schema, tags included. Then:

1. the gate (check.py, strict) refuses anything mis-shaped, and the model
   gets one round to fix what it named;
2. the critic — a second call with the opposite brief and web search — opens
   the reference, redoes the numbers, tries to defend the wrong options, and
   returns pass, fix or reject;
3. what survives is given an id and a date and written into the bank, one
   file, for the pull request a person reads.

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
from collections import Counter
from pathlib import Path
from typing import Literal

from pydantic import BaseModel, Field

import check
import genres

HERE = Path(__file__).resolve().parent
RULES = HERE / "RULES.md"

MODEL = "claude-opus-5"
# A declined request is re-run server-side on Anthropic's recommended
# fallback for the refusal category, inside the same call.
FALLBACK_BETA = "server-side-fallback-2026-07-01"

# Dollars per million tokens, for the run's own receipt.
PRICE = {"input": 5.0, "output": 25.0, "cache_read": 0.5, "cache_write": 6.25}

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

# The bank's own best, one or two per kind, shown to the model as the style.
EXEMPLARS = ["space-2", "thinking-1", "thinking-2", "thinking-n1", "thinking-e1", "thinking-d1"]

PRINCIPLES = [p for p in check.load_schema()["properties"]["principle"]["enum"] if p != "none"]
TOPICS = check.load_schema()["properties"]["topic"]["enum"]


# --------------------------------------------------------------------------
# What the model returns

# The vocabularies are the schema's, through check.py, so a value the gate
# would refuse cannot be produced in the first place.
Era = Literal[tuple(check.TAGS["era"])]
Region = Literal[tuple(check.TAGS["region"])]
Hook = Literal[tuple(check.TAGS["hook"])]
Mood = Literal[tuple(check.TAGS["mood"])]
Abstraction = Literal[tuple(check.TAGS["abstraction"])]
ShelfLife = Literal[tuple(check.TAGS["shelf_life"])]
Figure = Literal[tuple(check.TAGS["figure"])]


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
    source: str
    reference: str = Field(description="A URL, a DOI, an ISBN, or author and year.")


class Verdict(BaseModel):
    verdict: Literal["pass", "fix", "reject"]
    reason: str = Field(description="One line: what is wrong, or what was checked and held.")
    fixed: Draft | None = Field(description="On fix only: the card with the correction made, nothing else changed.")


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

    def __str__(self) -> str:
        where = f" · {genres.describe(self.strand)}" if self.strand else ""
        tail = ""
        if len(self.principles) > 1:
            tail = " · one of " + "/".join(self.principles)
        elif self.principle != "none":
            tail = f" · {self.principle}"
        return f"{self.topic}{where} · {self.kind} · {self.difficulty}{tail}"


def for_strand(strand: genres.Strand | None, topic: str, **rest) -> Request:
    """A request placed on a strand — or on none, for Thinking."""
    if strand is None:
        return Request(topic=topic, **rest)
    return Request(topic=strand.topic, genre=strand.genre, strand=strand.id, **rest)


def plan(bank: list[dict], count: int, *, topics: list[str] | None = None, seed: int = 0) -> list[Request]:
    """The next [count] cards to ask for, biggest gap first, subjects interleaved.

    Inside a subject the card lands on its thinnest strand: every strand
    towards STRAND_TARGET before any has a third. So a night's twenty
    reach twenty strands across as many subjects as are short, and the
    mix a reader set has something under every name on it as soon as the
    bank can manage."""
    live = [c for c in bank if not c.get("disabled")]
    by_topic: dict[str, Counter] = {t: Counter() for t in (topics or TOPICS)}
    for c in live:
        if c["topic"] in by_topic:
            by_topic[c["topic"]][c["kind"]] += 1
    per_strand = strand_counts(live)
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
            if (short_ask >= short_read and short_ask >= short_debate and short_ask > 0) or deficit(t) == 0:
                kind = _ask_kind(k)
                choice = _principles_for(t, principle_count, per_topic_principles[t], rng, kind)
                hard = (asks(t) + 1) % int(round(1 / HARD_SHARE)) == 0
                req = for_strand(strand, t, kind=kind, difficulty="hard" if hard else "medium",
                                 principle=choice[0], principles=choice)
                principle_count[choice[0]] += 1
                per_topic_principles[t][choice[0]] += 1
            elif short_read >= short_debate and short_read > 0:
                req = for_strand(strand, t, kind="read", difficulty="easy", principle="none")
            else:
                req = for_strand(strand, t, kind="debate", difficulty="medium", principle="none")
            by_topic[t][req.kind] += 1
            if strand is not None:
                per_strand[strand.id] += 1
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


def _ask_kind(k: Counter) -> str:
    total = sum(k[x] for x in ASK_MIX) + 1
    short = {x: ASK_MIX[x] * total - k[x] for x in ASK_MIX}
    return max(short, key=lambda x: (short[x], x == "pickOne"))


PRINCIPLE_CHOICE = 3


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
# The briefs

def system_prompt(bank: list[dict]) -> str:
    rules = RULES.read_text(encoding="utf-8")
    banned = [b for b in check.load_banned()]
    by_id = {c["id"]: c for c in bank}
    examples = [check.public(by_id[i]) for i in EXEMPLARS if i in by_id]
    return (
        rules
        + "\n\n## The blacklist\n\nNothing built on any of these, in any wording:\n\n"
        + "\n".join(f"- {b}" for b in banned)
        + "\n\n## Cards from the bank, as the house writes them\n\n"
        + "\n\n".join("```json\n" + json.dumps(e, ensure_ascii=False, indent=1) + "\n```" for e in examples)
    )


def brief(req: Request, bank: list[dict]) -> str:
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


CRITIC = """You are the critic. You are given one card written for Astute and the rules it
was written under. Your only task is to find why it must be rejected. Never
improve it for the sake of it.

Do all of this:
1. Open the reference (web search) and say whether it supports every figure
   and claim in the answer. A figure you cannot verify is a reject.
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
   how soon the answer could change, mature is honest. A tag that is not
   true of the card is a fix.

Return pass when everything held; fix when one thing is wrong and you can
correct it without rewriting the card (a figure, a reference, a unit, one
option) — then return the whole card in `fixed` with only that change; reject
otherwise. One line of reason."""


# --------------------------------------------------------------------------
# The model

class Claude:
    """The writer and the critic, over the Anthropic API."""

    def __init__(self, model: str = MODEL):
        import anthropic

        self.anthropic = anthropic
        self.client = anthropic.Anthropic()
        self.model = model
        self.usage = Counter()

    def _parse(self, *, system: str, messages: list, output_format, tools=None, effort="high"):
        kwargs = dict(
            model=self.model,
            max_tokens=16000,
            betas=[FALLBACK_BETA],
            fallbacks="default",
            system=[{"type": "text", "text": system, "cache_control": {"type": "ephemeral"}}],
            messages=messages,
            output_format=output_format,
            output_config={"effort": effort},
        )
        if tools:
            kwargs["tools"] = tools
        for _ in range(6):
            response = self.client.beta.messages.parse(**kwargs)
            self._count(response.usage)
            if response.stop_reason == "pause_turn":
                # A server tool ran out of turns; hand the turn back and it resumes.
                messages = messages + [{"role": "assistant", "content": response.content}]
                kwargs["messages"] = messages
                continue
            if response.stop_reason == "refusal":
                raise RuntimeError("the model declined: " + str(getattr(response.stop_details, "explanation", "")))
            if response.stop_reason == "max_tokens":
                raise RuntimeError("the reply ran past max_tokens")
            if response.parsed_output is None:
                raise RuntimeError("no JSON came back")
            return response.parsed_output, messages + [{"role": "assistant", "content": response.content}]
        raise RuntimeError("the turn kept pausing")

    def _count(self, usage) -> None:
        self.usage["input"] += usage.input_tokens or 0
        self.usage["output"] += usage.output_tokens or 0
        self.usage["cache_read"] += getattr(usage, "cache_read_input_tokens", 0) or 0
        self.usage["cache_write"] += getattr(usage, "cache_creation_input_tokens", 0) or 0

    def write(self, system: str, brief_text: str) -> tuple[Draft, list]:
        return self._parse(system=system, messages=[{"role": "user", "content": brief_text}], output_format=Draft)

    def repair(self, system: str, history: list, problems: list[str]) -> tuple[Draft, list]:
        ask = "The gate refused the card:\n" + "\n".join(f"- {p}" for p in problems) + "\n\nReturn the corrected card as JSON. Change only what those lines need."
        return self._parse(system=system, messages=history + [{"role": "user", "content": ask}], output_format=Draft)

    def critique(self, rules: str, card: dict) -> Verdict:
        system = rules + "\n\n---\n\n" + CRITIC
        text = "The card:\n\n```json\n" + json.dumps(card, ensure_ascii=False, indent=1) + "\n```"
        verdict, _ = self._parse(
            system=system,
            messages=[{"role": "user", "content": text}],
            output_format=Verdict,
            tools=[{"type": "web_search_20260209", "name": "web_search", "max_uses": 6}],
        )
        return verdict

    def tag(self, system: str, card_text: str) -> Tags:
        tags, _ = self._parse(
            system=system,
            messages=[{"role": "user", "content": card_text}],
            output_format=Tags,
            effort="medium",
        )
        return tags

    def receipt(self) -> str:
        u = self.usage
        cost = sum(u[k] * PRICE[k] / 1e6 for k in PRICE)
        return (f"{u['input']:,} in · {u['output']:,} out · {u['cache_read']:,} cached · "
                f"{u['cache_write']:,} cache writes · ${cost:.2f}")


class Fake:
    """A model that returns what it is told to. For tests and --fake."""

    def __init__(self, drafts: list[Draft] | None = None, verdicts: list[Verdict] | None = None,
                 tags: list[Tags] | None = None):
        self.drafts = list(drafts or [])
        self.verdicts = list(verdicts or [])
        self.tags = list(tags or [])
        self.calls: list[str] = []

    def write(self, system: str, brief_text: str):
        self.calls.append("write")
        return (self.drafts.pop(0) if self.drafts else canned(brief_text)), []

    def repair(self, system: str, history: list, problems: list[str]):
        self.calls.append("repair")
        return (self.drafts.pop(0) if self.drafts else canned("")), []

    def critique(self, rules: str, card: dict) -> Verdict:
        self.calls.append("critique")
        return self.verdicts.pop(0) if self.verdicts else Verdict(verdict="pass", reason="canned", fixed=None)

    def tag(self, system: str, card_text: str) -> Tags:
        self.calls.append("tag")
        if self.tags:
            return self.tags.pop(0)
        card = json.loads(card_text[card_text.index("{"):card_text.rindex("}") + 1])
        strands = genres.strands_of(card["topic"])
        first = strands[0] if strands else None
        return Tags(
            **canned_tags(card["kind"], ["canned", "plumbing", "pipes"]),
            genre=first.genre if first else "",
            strand=first.id if first else "",
        )

    def receipt(self) -> str:
        return "no tokens: the model was canned"


_canned = itertools.count()


def canned(brief_text: str) -> Draft:
    """A card that passes the strict gate, for exercising the plumbing."""
    fields = dict(line.split(": ", 1) for line in brief_text.splitlines() if ": " in line and not line.startswith("-"))
    kind = fields.get("kind", "read")
    topic = fields.get("topic", "space")
    principle = fields.get("principle", "none")
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
        source="The plumbing test", reference="https://example.org/plumbing/2026",
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


# --------------------------------------------------------------------------
# The pipeline

class Outcome(BaseModel):
    request: Request
    status: Literal["written", "refused", "rejected", "failed"]
    id: str = ""
    question: str = ""
    note: str = ""


def conform(card: dict, req: Request) -> dict:
    """The card as an answer to [req]: the model does not get to change the
    subject, the strand, the kind, the principle or the language it was
    asked for."""
    card["topic"], card["kind"] = req.topic, req.kind
    card["principle"] = card.get("principle") if card.get("principle") in req.principles else req.principle
    if req.strand:
        card["genre"], card["strand"] = req.genre, req.strand
    else:
        card.pop("genre", None)
        card.pop("strand", None)
    card["language"] = req.language
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


def run(requests: list[Request], model, bank: list[dict], *, out: Path, today: dt.date,
        critic: bool = True, log=print) -> list[Outcome]:
    schema = check.load_schema()
    banned = check.load_banned()
    rules = RULES.read_text(encoding="utf-8")
    system = system_prompt(bank)
    taken = {c["id"] for c in bank}
    written: list[dict] = []
    outcomes: list[Outcome] = []

    def gate(card: dict) -> list[str]:
        card = dict(card, id=next_id(card["topic"], today, taken), written=today.isoformat())
        return (check.check_card(card, strict=True, schema=schema, banned=banned)
                + check.check_twins([card], against=bank + written)
                + check.check_links([card], against=bank + written))

    for req in requests:
        log(f"· {req}")
        try:
            draft, history = model.write(system, brief(req, bank + written))
            card = conform(to_card(draft), req)
            problems = gate(card)
            if problems:
                log("  gate: " + "; ".join(problems))
                draft, _ = model.repair(system, history, problems)
                card = conform(to_card(draft), req)
                problems = gate(card)
            if problems:
                outcomes.append(Outcome(request=req, status="refused", question=card.get("question", ""), note="; ".join(problems)))
                log("  refused")
                continue
            if critic:
                verdict = model.critique(rules, card)
                log(f"  critic: {verdict.verdict} — {verdict.reason}")
                if verdict.verdict == "reject":
                    outcomes.append(Outcome(request=req, status="rejected", question=card["question"], note=verdict.reason))
                    continue
                if verdict.verdict == "fix" and verdict.fixed is not None:
                    fixed = conform(to_card(verdict.fixed), req)
                    if not gate(fixed):
                        card = fixed
                    else:
                        log("  the fix did not pass the gate; keeping the draft")
            card["id"] = next_id(req.topic, today, taken)
            card["written"] = today.isoformat()
            taken.add(card["id"])
            folder = out / req.topic
            folder.mkdir(parents=True, exist_ok=True)
            (folder / f"{card['id']}.json").write_text(json.dumps(check.ordered(card), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            written.append(card)
            outcomes.append(Outcome(request=req, status="written", id=card["id"], question=card["question"]))
            log(f"  wrote {card['id']}")
        except Exception as error:  # one bad card must not end the night
            outcomes.append(Outcome(request=req, status="failed", note=f"{type(error).__name__}: {error}"))
            log(f"  failed: {type(error).__name__}: {error}")
    return outcomes


def report(outcomes: list[Outcome], receipt: str, today: dt.date) -> str:
    """The pull request body: what was written, what was not, and the bill."""
    written = [o for o in outcomes if o.status == "written"]
    lines = [f"## {len(written)} new card{'s' if len(written) != 1 else ''} · {today:%-d %B %Y}", ""]
    for o in written:
        where = f" · *{genres.describe(o.request.strand)}*" if o.request.strand else ""
        lines.append(f"- **{o.id}** — {o.question}{where}")
    rest = [o for o in outcomes if o.status != "written"]
    if rest:
        lines += ["", f"### Not written ({len(rest)})", ""]
        for o in rest:
            lines.append(f"- {o.request} — *{o.status}*: {o.note or o.question}")
    lines += ["", f"Tokens: {receipt}", "",
              "Every card above passed the gate and the critic. Read each one before merging; "
              "the merge is the review."]
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
        requests = [for_strand(strand, topic, kind=kind, difficulty=difficulty, principle=principle)] * args.count

    if args.dry_run:
        print(f"{len(requests)} request{'s' if len(requests) != 1 else ''}:")
        for r in requests:
            print(f"  {r}")
        if requests:
            print("\n--- system prompt: %d characters\n--- first brief:\n" % len(system_prompt(bank)))
            print(brief(requests[0], bank))
        return 0

    if args.fake:
        model = Fake()
    else:
        if not os.environ.get("ANTHROPIC_API_KEY"):
            print("ANTHROPIC_API_KEY is not set; nothing was written. Use --dry-run to see the plan.", file=sys.stderr)
            return 2
        model = Claude()

    outcomes = run(requests, model, bank, out=args.out, today=today, critic=not args.no_critic)
    text = report(outcomes, model.receipt(), today)
    if args.report:
        args.report.write_text(text, encoding="utf-8")
    print()
    print(text)
    return 0 if any(o.status == "written" for o in outcomes) or not requests else 1


if __name__ == "__main__":
    sys.exit(main())
