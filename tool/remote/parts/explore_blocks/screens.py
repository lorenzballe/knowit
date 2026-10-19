"""Checks for the screens blocks of Explore: Whole Explore screens, one idea each (docs/explore, rounds 140 and 141).

Every block of the family is described in docs/explore/screens.md, with the
fields it reads. What is checked here is what the app would otherwise pass
over in silence, a section at a time: a field of the wrong shape, words with
no English, a chain of whys that names no source, a card that is not in the
bank or cannot be drawn the way the block draws it — a claim that is not a
true-or-false card, a figure with no number in its question. A problem names
the field and says what to change.

The cards are read from the bank as it is in the repository
(tool/cards/bank/), which is the bank the next bundle ships.
"""
from __future__ import annotations

import functools
import json
import re
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parents[4]
BANK = ROOT / "tool" / "cards" / "bank"

# The languages the app is shown in (lib/l10n/), and the subjects it draws
# (kTopics, lib/data/topics.dart), by key.
LANGUAGES = {"en", "it", "de", "es", "fr", "ja", "ko", "nl", "pl", "pt", "ru", "tr", "zh"}
SUBJECTS = {
    "space", "technology", "language", "nature", "economics", "pop_culture",
    "science", "maths", "history", "psychology", "weird_facts", "human_body",
    "thinking", "philosophy", "sport", "cinema", "music", "art", "medicine",
    "food", "life",
}
# The ages the bank tags its cards with (`era`), oldest first.
ERAS = ["ancient", "medieval", "early_modern", "nineteenth", "twentieth", "recent"]
# The principles a card can train (Principle in lib/models/pill.dart).
PRINCIPLES = {
    "baseRate", "survivorship", "regression", "confirmation", "anchoring",
    "sampling", "confounding", "counterfactual", "multipleComparisons",
    "availability", "sunkCost", "conjunction", "conditional", "independence",
    "coincidence", "exponential", "reflection", "simpson", "estimation",
    "computation",
}
HOOKS = {"misconception", "mechanism", "story", "number", "puzzle", "paradox", "practical", "origin"}
# The experts the build carries, and the marks a screen draws besides the
# subjects' own.
EXPERTS = {"statistician", "economist", "historian", "doctor", "scientist"}
MARKS = {"chart"} | SUBJECTS
SIZES = {"xs", "s", "m", "l", "xl"}

# The fields every block of the family reads; each block adds its own.
COMMON = {"id", "block", "title", "subtitle", "source", "size", "style", "limit", "audience"}


# ── The bank ──────────────────────────────────────────────────────────────


@functools.lru_cache(maxsize=1)
def bank() -> dict:
    """Every card in the repository's bank, by id."""
    cards = {}
    for path in BANK.rglob("*.json"):
        try:
            card = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            continue
        if isinstance(card, dict) and isinstance(card.get("id"), str):
            cards[card["id"]] = card
    return cards


def is_true_or_false(card: dict) -> bool:
    options = card.get("options")
    return (
        isinstance(options, list)
        and len(options) == 2
        and {str(o).lower() for o in options} == {"true", "false"}
    )


def says_true(card: dict) -> bool:
    options, correct = card.get("options") or [], card.get("correct")
    return is_true_or_false(card) and isinstance(correct, int) and str(options[correct]).lower() == "true"


# shelfFigure in lib/data/themed_shelves.dart, word for word: the figure a
# numbers card is about, the first number in its question that is not a year.
_FIGURE = re.compile(
    r"([$€£])?(?<![\w.^/])(\d{1,3}(?:,\d{3})+|\d+(?:\.\d+)?)(\s?%|/\d+)?"
    r"(?:\s(thousand|million|billion|trillion)\b)?(?![\w^])",
    re.ASCII,
)


def shelf_figure(question: str):
    for m in _FIGURE.finditer(question):
        money, digits = m.group(1) or "", m.group(2)
        try:
            n = float(digits.replace(",", ""))
        except ValueError:
            continue
        suffix, scale = (m.group(3) or "").strip(), m.group(4)
        if not money and not suffix and scale is None and "," not in digits and 1000 <= n <= 2100 and n == round(n):
            continue
        body = digits
        if scale is not None:
            body = digits + {"thousand": "k", "million": "M", "billion": "B", "trillion": "T"}[scale]
        elif n >= 1e6:
            v, unit = (n / 1e9, "B") if n >= 1e9 else (n / 1e6, "M")
            body = (f"{v:.0f}" if v >= 10 else f"{v:.2f}".rstrip("0").rstrip(".")) + unit
        figure = money + body + suffix
        if len(figure) > 7:
            continue
        return figure
    return None


# ── Fields ───────────────────────────────────────────────────────────────


def text_problems(value, where: str, *, required: bool = False, most: int | None = None) -> list[str]:
    """Words written per language — {"en": "…", "it": "…"} — or once for all."""
    if value is None:
        return [f"{where} is missing: give it words, {{\"en\": \"…\"}}"] if required else []
    if isinstance(value, str):
        if not value.strip():
            return [f"{where} is empty: give it words, or leave it out"]
        return [f"{where} is {len(value)} characters; keep it to {most}"] if most and len(value) > most else []
    if not isinstance(value, dict):
        return [f"{where} is neither words nor words by language ({{\"en\": \"…\"}})"]
    problems = []
    if not isinstance(value.get("en"), str) or not value["en"].strip():
        problems.append(f"{where} has no English: every text needs \"en\", the words any language falls back to")
    for lang, words in value.items():
        if lang not in LANGUAGES:
            problems.append(f"{where}: {lang!r} is not a language the app is shown in ({', '.join(sorted(LANGUAGES))})")
        elif not isinstance(words, str) or not words.strip():
            problems.append(f"{where}.{lang} is not words")
        elif most and len(words) > most:
            problems.append(f"{where}.{lang} is {len(words)} characters; keep it to {most}")
    return problems


def word_list_problems(value, where: str) -> list[str]:
    """A list of words, or lists by language with English among them."""
    def one(items, at):
        if not isinstance(items, list) or not items:
            return [f"{at} is not a list of words"]
        return [f"{at}[{i}] is not words" for i, w in enumerate(items) if not isinstance(w, str) or not w.strip()]

    if value is None:
        return []
    if isinstance(value, list):
        return one(value, where)
    if not isinstance(value, dict):
        return [f"{where} is neither a list of words nor lists by language"]
    problems = [] if "en" in value else [f"{where} has no English list (\"en\")"]
    for lang, items in value.items():
        if lang not in LANGUAGES:
            problems.append(f"{where}: {lang!r} is not a language the app is shown in")
        else:
            problems += one(items, f"{where}.{lang}")
    return problems


def style_problems(section: dict, keys: set[str]) -> list[str]:
    style = section.get("style")
    if style is None:
        return []
    if not isinstance(style, dict):
        return ["style is not an object"]
    problems = []
    for key, value in style.items():
        if key not in keys:
            known = ", ".join(sorted(keys)) or "none"
            problems.append(f"style.{key} is not one this block reads (it reads: {known})")
        elif not isinstance(value, bool):
            problems.append(f"style.{key} is a switch: true or false")
    return problems


def limit_problems(section: dict, low: int | None, high: int | None) -> list[str]:
    if "limit" not in section:
        return []
    if low is None:
        return ["limit is not read by this block: take it out"]
    value = section["limit"]
    if not isinstance(value, int) or isinstance(value, bool) or not low <= value <= high:
        return [f"limit is how many it shows: a whole number from {low} to {high}"]
    return []


def size_problems(section: dict) -> list[str]:
    size = section.get("size")
    if size is None or size in SIZES:
        return []
    return [f"size {size!r} is not one of {', '.join(sorted(SIZES))}"]


def unknown_fields(item: dict, known: set[str], where: str) -> list[str]:
    return [f"{where}: {key!r} is not a field it reads (it reads: {', '.join(sorted(known))})" for key in item if key not in known]


def source_ids(source, where: str) -> tuple[list[dict], list[str]]:
    """The cards a source names one by one, and what is wrong with them: each
    must be in the bank, still dealt, and not about a place, which only the
    readers who live there are ever shown. A source of another shape is the
    engine's to check."""
    if not isinstance(source, dict) or "ids" not in source:
        return [], []
    ids = source["ids"]
    if not isinstance(ids, list) or not ids:
        return [], [f"{where}.ids is not a list of card ids"]
    cards, problems, seen = [], [], set()
    for i, card_id in enumerate(ids):
        at = f"{where}.ids[{i}]"
        if not isinstance(card_id, str):
            problems.append(f"{at} is not a card id")
            continue
        if card_id in seen:
            problems.append(f"{at}: {card_id} is named twice")
            continue
        seen.add(card_id)
        card = bank().get(card_id)
        if card is None:
            problems.append(f"{at}: no card {card_id} in the bank")
        elif card.get("disabled"):
            problems.append(f"{at}: {card_id} is retired and is dealt to nobody")
        elif card.get("place"):
            problems.append(f"{at}: {card_id} is about a place, and goes only to the readers who live there")
        else:
            cards.append(card)
    return cards, problems


def ids_problems(ids, where: str) -> tuple[list[dict], list[str]]:
    """A plain list of card ids, checked like a source's."""
    if ids is None:
        return [], []
    return source_ids({"ids": ids}, where)


def card_count_problems(cards: list[dict], low: int, high: int, what: str) -> list[str]:
    if not cards or low <= len(cards) <= high:
        return []
    want = f"{low}" if low == high else f"{low} to {high}"
    return [f"source.ids names {len(cards)} cards; {what} shows {want}"]


def subject_problems(value, where: str) -> list[str]:
    if isinstance(value, str) and value in SUBJECTS:
        return []
    return [f"{where} {value!r} is not a subject the app knows ({', '.join(sorted(SUBJECTS))})"]


def common(section: dict, extra: set[str], styles: set[str], limit: tuple[int | None, int | None]) -> list[str]:
    problems = unknown_fields(section, COMMON | extra, "the section")
    problems += text_problems(section.get("title"), "title", most=80)
    problems += text_problems(section.get("subtitle"), "subtitle", most=140)
    problems += size_problems(section)
    problems += style_problems(section, styles)
    problems += limit_problems(section, *limit)
    return problems


# ── The blocks ───────────────────────────────────────────────────────────


def check_expert(section: dict) -> list[str]:
    problems = common(section, {"experts", "expert"}, {"head"}, (2, 8))
    _, bad = source_ids(section.get("source"), "source")
    problems += bad
    experts = section.get("experts")
    ids = []
    if experts is not None:
        if not isinstance(experts, list) or not experts:
            return problems + ["experts is not a list: name built-in experts, or give your own"]
        for i, expert in enumerate(experts):
            at = f"experts[{i}]"
            if isinstance(expert, str):
                if expert not in EXPERTS:
                    problems.append(f"{at}: {expert!r} is not an expert the app carries ({', '.join(sorted(EXPERTS))}); give an object to bring your own")
                ids.append(expert)
                continue
            if not isinstance(expert, dict):
                problems.append(f"{at} is neither an expert's id nor an expert")
                continue
            problems += unknown_fields(expert, {"id", "name", "as", "question", "mark", "source", "subjects", "principles", "hooks"}, at)
            eid = expert.get("id")
            if not isinstance(eid, str) or not eid:
                problems.append(f"{at} has no id")
                continue
            own = eid not in EXPERTS
            problems += text_problems(expert.get("name"), f"{at}.name", required=own, most=24)
            problems += text_problems(expert.get("as"), f"{at}.as", required=own, most=48)
            problems += text_problems(expert.get("question"), f"{at}.question", required=own, most=90)
            if "mark" in expert and expert["mark"] not in MARKS:
                problems.append(f"{at}.mark {expert['mark']!r} is not a mark the app draws: 'chart' or a subject")
            for key, known in (("subjects", SUBJECTS), ("principles", PRINCIPLES), ("hooks", HOOKS)):
                value = expert.get(key)
                if value is None:
                    continue
                if not isinstance(value, list) or not value:
                    problems.append(f"{at}.{key} is not a list")
                    continue
                problems += [f"{at}.{key}: {v!r} is not one the bank uses" for v in value if v not in known]
            cards, bad = source_ids(expert.get("source"), f"{at}.source")
            problems += bad
            if cards and len(cards) < 2:
                problems.append(f"{at}.source names one card: an expert shows two or more")
            ids.append(eid)
        problems += [f"experts: {e!r} is there twice" for e in sorted({e for e in ids if ids.count(e) > 1})]
    first = section.get("expert")
    if first is not None and first not in (ids or EXPERTS):
        problems.append(f"expert {first!r} is not one of the section's experts")
    return problems


def check_connect_dots(section: dict) -> list[str]:
    problems = common(section, {"subjects", "subject", "pairs"}, {"head", "map"}, (1, 12))
    _, bad = source_ids(section.get("source"), "source")
    problems += bad
    subjects = section.get("subjects")
    if subjects is not None:
        if not isinstance(subjects, list) or not subjects:
            problems.append("subjects is not a list of subjects")
            subjects = None
        else:
            for i, s in enumerate(subjects):
                problems += subject_problems(s, f"subjects[{i}]")
    first = section.get("subject")
    if first is not None:
        problems += subject_problems(first, "subject")
        if subjects and first not in subjects:
            problems.append(f"subject {first!r} is not one of the section's subjects")
    pairs = section.get("pairs")
    if pairs is not None:
        if not isinstance(pairs, list) or not pairs:
            return problems + ["pairs is not a list of {\"card\": id, \"with\": subject}"]
        for i, pair in enumerate(pairs):
            at = f"pairs[{i}]"
            if not isinstance(pair, dict):
                problems.append(f"{at} is not {{\"card\": id, \"with\": subject}}")
                continue
            problems += unknown_fields(pair, {"card", "with"}, at)
            cards, bad = ids_problems([pair.get("card")], f"{at}.card")
            problems += bad
            problems += subject_problems(pair.get("with"), f"{at}.with")
            if cards and cards[0].get("topic") == pair.get("with"):
                problems.append(f"{at}: {pair['card']} is a {pair['with']} card already; a meeting is with another subject")
    return problems


def check_ask_first(section: dict) -> list[str]:
    problems = common(section, {"hint", "try"}, {"try", "asked"}, (1, 10))
    problems += text_problems(section.get("hint"), "hint", most=60)
    problems += word_list_problems(section.get("try"), "try")
    return problems


def check_questions_asked(section: dict) -> list[str]:
    problems = common(section, set(), {"head"}, (1, 10))
    if "source" in section:
        problems.append("source is not read: the questions are the reader's own")
    return problems


def check_keep_asking(section: dict) -> list[str]:
    problems = common(section, {"chains", "chain"}, {"head", "holes", "meter"}, (None, None))
    if "source" in section:
        problems.append("source is not read: each chain names its own cards")
    chains = section.get("chains")
    if not isinstance(chains, list) or not chains:
        return problems + ["chains is missing: a chain of whys is the section's own words, at least one"]
    ids = []
    for i, chain in enumerate(chains):
        at = f"chains[{i}]"
        if not isinstance(chain, dict):
            problems.append(f"{at} is not a chain")
            continue
        problems += unknown_fields(chain, {"id", "subject", "source", "steps", "cards"}, at)
        cid = chain.get("id")
        if not isinstance(cid, str) or not cid:
            problems.append(f"{at} has no id")
        else:
            ids.append(cid)
        problems += subject_problems(chain.get("subject"), f"{at}.subject")
        source = chain.get("source")
        if not isinstance(source, str) or len(source.strip()) < 8:
            problems.append(f"{at}.source is missing: name where its answers come from, as a card names its source")
        steps = chain.get("steps")
        if not isinstance(steps, list) or not 2 <= len(steps) <= 8:
            problems.append(f"{at}.steps is a list of 2 to 8 questions, each with its answer")
        else:
            for j, step in enumerate(steps):
                sat = f"{at}.steps[{j}]"
                if not isinstance(step, dict):
                    problems.append(f"{sat} is not {{\"q\": …, \"a\": …}}")
                    continue
                problems += unknown_fields(step, {"q", "a"}, sat)
                problems += text_problems(step.get("q"), f"{sat}.q", required=True, most=110)
                problems += text_problems(step.get("a"), f"{sat}.a", required=True, most=320)
        cards, bad = ids_problems(chain.get("cards"), f"{at}.cards")
        problems += bad
        if len(cards) > 6:
            problems.append(f"{at}.cards names {len(cards)}; the chain ends on 6 at most")
    problems += [f"chains: {c!r} is there twice" for c in sorted({c for c in ids if ids.count(c) > 1})]
    first = section.get("chain")
    if first is not None and first not in ids:
        problems.append(f"chain {first!r} is not one of the section's chains")
    return problems


def check_through_time(section: dict) -> list[str]:
    problems = common(section, {"stops", "stop"}, {"head", "caption"}, (1, 2))
    _, bad = source_ids(section.get("source"), "source")
    problems += bad
    stops = section.get("stops")
    ids = []
    if stops is None:
        ids = list(ERAS)
    elif not isinstance(stops, list) or not 2 <= len(stops) <= 12:
        problems.append("stops is a list of 2 to 12 stops, or left out for the bank's ages")
    else:
        places = {}
        for i, stop in enumerate(stops):
            at = f"stops[{i}]"
            if not isinstance(stop, dict):
                problems.append(f"{at} is not a stop")
                continue
            problems += unknown_fields(stop, {"id", "ago", "era", "label", "when", "source"}, at)
            sid = stop.get("id")
            if not isinstance(sid, str) or not sid:
                problems.append(f"{at} has no id")
            else:
                ids.append(sid)
            ago = stop.get("ago")
            if not isinstance(ago, (int, float)) or isinstance(ago, bool) or ago < 0:
                problems.append(f"{at}.ago is how many years before now it is, a number from 0")
            elif round(float(ago), 6) in places:
                problems.append(f"{at} sits where {places[round(float(ago), 6)]} does on the ruler: give it its own ago")
            else:
                places[round(float(ago), 6)] = f"stops[{i}]"
            era = stop.get("era")
            if era is not None and era not in ERAS:
                problems.append(f"{at}.era {era!r} is not an age the bank tags ({', '.join(ERAS)})")
            if era is None and stop.get("source") is None:
                problems.append(f"{at} has no cards: give it an era of the bank, or a source")
            tagged = era in ERAS
            problems += text_problems(stop.get("label"), f"{at}.label", required=not tagged, most=40)
            problems += text_problems(stop.get("when"), f"{at}.when", required=not tagged, most=40)
            _, bad = source_ids(stop.get("source"), f"{at}.source")
            problems += bad
        problems += [f"stops: {s!r} is there twice" for s in sorted({s for s in ids if ids.count(s) > 1})]
        agos = [s.get("ago") for s in stops if isinstance(s, dict) and isinstance(s.get("ago"), (int, float))]
        if agos != sorted(agos, reverse=True):
            problems.append("stops go oldest first: the ruler runs from the far past to now")
    first = section.get("stop")
    if first is not None and first not in ids:
        problems.append(f"stop {first!r} is not one of the ruler's stops")
    return problems


def check_change_your_mind(section: dict) -> list[str]:
    problems = common(section, set(), {"head", "summary"}, (1, 6))
    cards, bad = source_ids(section.get("source"), "source")
    problems += bad
    for card in cards:
        if not is_true_or_false(card):
            problems.append(f"source: {card['id']} is not a true-or-false card, and has no claim to take a stance on")
    return problems


def check_say_it_tonight(section: dict) -> list[str]:
    problems = common(section, set(), {"head", "counter"}, (1, 8))
    cards, bad = source_ids(section.get("source"), "source")
    problems += bad
    for card in cards:
        if not says_true(card):
            problems.append(f"source: {card['id']} is not a true-or-false card whose claim is true, so it is no line to say")
    return problems


def check_masthead(section: dict) -> list[str]:
    problems = common(section, {"kicker", "left", "right"}, set(), (None, None))
    if "source" in section:
        problems.append("source is not read: the masthead shows no cards")
    for field in ("kicker", "left", "right"):
        problems += text_problems(section.get(field), field, most=40)
    return problems


def _front(section: dict, extra: set[str], low: int, high: int, what: str, fits: Callable[[dict], str | None] | None = None) -> list[str]:
    problems = common(section, extra, set(), (None, None) if high == 1 else (low, high))
    cards, bad = source_ids(section.get("source"), "source")
    problems += bad + card_count_problems(cards, low, high, what)
    if fits:
        for card in cards:
            why = fits(card)
            if why:
                problems.append(f"source: {card['id']} {why}")
    return problems


def check_front_lead(section: dict) -> list[str]:
    problems = _front(section, {"headline", "deck"}, 1, 1, "the lead")
    problems += text_problems(section.get("headline"), "headline", most=140)
    problems += text_problems(section.get("deck"), "deck", most=160)
    return problems


def check_front_columns(section: dict) -> list[str]:
    return _front(section, set(), 2, 2, "the columns")


def check_front_numbers(section: dict) -> list[str]:
    def fits(card):
        return None if shelf_figure(card.get("question", "")) else "has no figure in its question to set large"

    return _front(section, set(), 2, 4, "In numbers", fits)


def check_front_correction(section: dict) -> list[str]:
    return _front(section, set(), 1, 1, "the correction")


def check_front_puzzle(section: dict) -> list[str]:
    problems = _front(section, {"button"}, 1, 1, "the puzzle")
    problems += text_problems(section.get("button"), "button", most=24)
    return problems


def check_edition_end(section: dict) -> list[str]:
    problems = common(section, set(), set(), (None, None))
    if "source" in section:
        problems.append("source is not read: the end of the edition shows no cards")
    return problems


# block name -> check(section) returning a list of problems, each a line a
# person can act on. A block listed here is a block the app can draw.
BLOCKS: dict[str, Callable[[dict], list[str]]] = {
    "expert": check_expert,
    "connect-dots": check_connect_dots,
    "ask-first": check_ask_first,
    "questions-asked": check_questions_asked,
    "keep-asking": check_keep_asking,
    "through-time": check_through_time,
    "change-your-mind": check_change_your_mind,
    "say-it-tonight": check_say_it_tonight,
    "masthead": check_masthead,
    "front-lead": check_front_lead,
    "front-columns": check_front_columns,
    "front-numbers": check_front_numbers,
    "front-correction": check_front_correction,
    "front-puzzle": check_front_puzzle,
    "edition-end": check_edition_end,
}
