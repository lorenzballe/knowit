#!/usr/bin/env python3
"""Book summaries: a book of Books in pills read whole, in about a quarter of an hour.

    python3 tool/cards/summaries.py              # check every summary, words by part
    python3 tool/cards/summaries.py a.json ...   # check these files against the bank

A summary is one file per book, `tool/cards/summaries/<book>.json`, named for
the book of the bank it summarises: the `book.id` its cards share. It is the
longer way into the book, beside its four to eight cards: its real argument
and its real examples, about 2,000 to 2,500 words, in five to eight parts
with a title each. The app reads it a part at a time, keeping the reader's
place (lib/books/summary_reader.dart), and reads it aloud a part a clip
(functions/src/books.ts): each part is one clip, made once for every reader.

What a file holds, and nothing else:

    book, title, author, year   the book, exactly as its cards name it
    language                    "en": summaries are written in English, like the cards
    parts                       5 to 8 of {"title", "text": [paragraphs]}
    sources                     the edition first (title, publisher, year, its ISBN, the
                                one its cards' cover is of), then any study named that is
                                not in the book; each with the link that opens it
    written                     YYYY-MM-DD

The rules a program can hold a summary to are held here: the lengths, the
parts, the fields, the book agreeing with its cards, quotations kept to a few
words, and the house style: no dash joining two clauses, no exclamation
mark, none of the stock phrases of machine prose, no "it's not X, it's Y".
Whether a summary is true, fair to the book and in its own words is the
writer's job, and then the reviewer's: every figure as the book gives it,
nothing invented, a fact left out when it cannot be checked, no passage of
the book copied, a phrase of the author's at most, in double quotes.

A summary is published by bundle.py like a free card's page: a file of its
own (`web/cards/summaries/<book>.json`), named in the bank with the hash of
its bytes, fetched by the phone when the book is opened and kept; and built
into the app (`lib/data/embedded_summaries.dart`) so the books that ship with
it open on a phone that has never been online. The server reads the same
file to make the clips, so what is heard is what is read.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SUMMARIES = HERE / "summaries"

# The lengths. A part is one movement of the book's argument, told with its
# evidence, and one clip of the voice; the whole is a quarter of an hour.
PARTS = (5, 8)
PART_WORDS = (200, 520)
TOTAL_WORDS = (2000, 2500)
# A paragraph a phone shows in a screen or so: longer is a wall of text.
PARAGRAPH_WORDS = (5, 130)
TITLE_WORDS = (2, 9)
TITLE_CHARS = 48
# Words a minute, read with attention or heard: what the book's page says
# the summary takes. The same in lib/models/book_summary.dart (kSummaryPace).
READING_PACE = 150

# A quotation of the book's own words: in double quotes, a phrase at most.
QUOTE_WORDS = 10
QUOTED_WORDS = 45

KEYS = ("book", "title", "author", "year", "language", "parts", "sources", "written")

# The house style. A dash used to join two clauses, an exclamation, and the
# phrases a model reaches for first (the ct-humanizer skill lists them).
DASHES = ("—", "–", " -- ", " - ")
STOCK = (
    "did you know", "fun fact", "mind-blowing", "let's dive", "dive into", "delve", "tapestry",
    "testament to", "pivotal", "crucial", "game-changer", "game changer", "in today's world",
    "in a world where", "at its core", "the real question", "here's the thing", "it's important to note",
    "it is important to note", "needless to say", "in conclusion", "unlock", "unleash", "embark",
    "navigate the", "landscape of", "realm of", "plays a key role", "plays a crucial role", "underscores",
    "showcases", "vibrant", "nestled", "groundbreaking", "ever-changing", "not only",
    "not just", "not merely", "the power of", "a deep dive", "buckle up", "spoiler", "fascinating",
    "incredible", "amazing", "interestingly", "in essence", "ultimately,", "at the end of the day",
)
# "It's not X, it's Y" and its cousins: the reveal machine prose leans on.
NOT_X_BUT_Y = (
    re.compile(r"\b(?:it|this|that)(?:'s| is| was) not\b[^.;:?]{1,70}[,;:] (?:it|this|that)(?:'s| is| was)\b", re.I),
    re.compile(r"\b(?:isn't|wasn't|aren't|weren't) (?:about|just|really)\b[^.;:?]{1,70}[,;:] (?:it's|it is|it was|they're|they are)\b", re.I),
)
EMOJI = re.compile("[\U0001F300-\U0001FAFF☀-➿]")
# A quotation opened with a single quote: the house quotes in double quotes,
# so a single one is only ever an apostrophe.
SINGLE_QUOTE = re.compile(r"(^|[\s(\[])'(?=\w)")
CURLY = re.compile("[‘’“”]")
LINK = re.compile(r"(https?://\S+|doi:10\.\S+)")
ISBN = re.compile(r"ISBN (97[89]\d{10})")


def words(text: str) -> int:
    text = text.strip()
    return len(re.split(r"\s+", text)) if text else 0


def part_words(part: dict) -> int:
    return sum(words(t) for t in part.get("text") or [] if isinstance(t, str))


def word_count(summary: dict) -> int:
    """The words a reader reads: every paragraph of every part; titles aside."""
    return sum(part_words(p) for p in summary.get("parts") or [] if isinstance(p, dict))


def minutes(summary: dict) -> int:
    return max(1, round(word_count(summary) / READING_PACE))


def load(path: Path) -> dict:
    summary = json.loads(path.read_text(encoding="utf-8"))
    summary["_path"] = str(path)
    return summary


def load_all(root: Path = SUMMARIES) -> list[dict]:
    """Every summary, by book."""
    if not root.exists():
        return []
    return sorted((load(p) for p in root.glob("*.json")), key=lambda s: str(s.get("book")))


def public(summary: dict) -> dict:
    return {k: v for k, v in summary.items() if not k.startswith("_")}


def books_of(cards: list[dict]) -> dict[str, dict]:
    """The books of the bank, as their first card names them."""
    out: dict[str, dict] = {}
    for c in cards:
        b = c.get("book")
        if isinstance(b, dict) and isinstance(b.get("id"), str) and not c.get("disabled"):
            if b["id"] not in out or b.get("part", 99) < out[b["id"]].get("part", 99):
                out[b["id"]] = b
    return out


def _check_text(where: str, text: object, low: int, high: int) -> list[str]:
    if not isinstance(text, str) or not text.strip():
        return [f"{where}: empty"]
    problems = []
    n = words(text)
    if not low <= n <= high:
        problems.append(f"{where}: {n} words, not {low} to {high}")
    if text != text.strip() or "  " in text or "\n" in text:
        problems.append(f"{where}: stray spaces or a line break")
    for d in DASHES:
        if d in text:
            problems.append(f"{where}: a dash ({d.strip()!r}) joins two clauses; use a comma, a colon or a full stop")
    if "!" in text:
        problems.append(f"{where}: an exclamation mark")
    if EMOJI.search(text):
        problems.append(f"{where}: an emoji")
    if CURLY.search(text):
        problems.append(f"{where}: curly quotes; write straight ones, the app sets them")
    if SINGLE_QUOTE.search(text):
        problems.append(f"{where}: a quotation in single quotes; quote in double quotes")
    if text.count('"') % 2:
        problems.append(f"{where}: a quotation left open")
    lower = text.lower()
    for phrase in STOCK:
        if re.search(r"(?<![a-z])" + re.escape(phrase) + r"(?![a-z])", lower):
            problems.append(f"{where}: {phrase!r}")
    for pattern in NOT_X_BUT_Y:
        m = pattern.search(text)
        if m:
            problems.append(f"{where}: \"{m.group(0)}\" is the not-X-but-Y reveal; say what it is")
    return problems


def _check_title(where: str, title: object) -> list[str]:
    if not isinstance(title, str) or not title.strip():
        return [f"{where}: no title"]
    problems = []
    if not TITLE_WORDS[0] <= words(title) <= TITLE_WORDS[1] or len(title) > TITLE_CHARS:
        problems.append(f"{where}: the title {title!r} is not {TITLE_WORDS[0]} to {TITLE_WORDS[1]} words"
                        f" within {TITLE_CHARS} characters")
    if title.rstrip()[-1:] in ".:;!?":
        problems.append(f"{where}: the title ends in punctuation")
    for d in DASHES:
        if d in title:
            problems.append(f"{where}: a dash in the title")
    if CURLY.search(title):
        problems.append(f"{where}: curly quotes in the title")
    return problems


def check(summary: dict, books: dict[str, dict] | None = None) -> list[str]:
    """Everything wrong with one summary, as short sentences. Empty means fine.
    [books] are the bank's books (books_of); the summary must be of one of them."""
    problems: list[str] = []
    unknown = set(public(summary)) - set(KEYS)
    if unknown:
        problems.append(f"unknown keys {sorted(unknown)}")
    missing = [k for k in KEYS if k not in summary]
    if missing:
        problems.append(f"missing {missing}")
        return problems

    bid = summary["book"]
    path = summary.get("_path")
    card_book: dict | None = None
    if not isinstance(bid, str) or not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", bid):
        problems.append("book: an id in lowercase words and hyphens")
    elif path and Path(path).stem != bid:
        problems.append(f"book: the file is {Path(path).name}, not {bid}.json")
    if books is not None and isinstance(bid, str):
        card_book = books.get(bid)
        if card_book is None:
            problems.append(f"book: {bid} is not a book of the bank")
        else:
            for key in ("title", "author", "year"):
                if summary.get(key) != card_book.get(key):
                    problems.append(f"{key}: {summary.get(key)!r}, where its cards say {card_book.get(key)!r}")
    if not isinstance(summary["year"], int):
        problems.append("year: a whole number")
    if summary["language"] != "en":
        problems.append("language: summaries are written in English")
    try:
        dt.date.fromisoformat(summary["written"])
    except (TypeError, ValueError):
        problems.append("written: a date, YYYY-MM-DD")

    parts = summary["parts"]
    if not isinstance(parts, list) or not PARTS[0] <= len(parts) <= PARTS[1]:
        problems.append(f"parts: {PARTS[0]} to {PARTS[1]} of them")
        parts = parts if isinstance(parts, list) else []
    titles = set()
    for n, part in enumerate(parts, 1):
        if not isinstance(part, dict) or set(part) != {"title", "text"} or not isinstance(part.get("text"), list) \
                or not part["text"]:
            problems.append(f"part {n}: {{\"title\", \"text\": [paragraphs]}}")
            continue
        problems += _check_title(f"part {n}", part["title"])
        if isinstance(part["title"], str):
            if part["title"].lower() in titles:
                problems.append(f"part {n}: the same title as another part")
            titles.add(part["title"].lower())
        for i, t in enumerate(part["text"], 1):
            problems += _check_text(f"part {n} ¶{i}", t, *PARAGRAPH_WORDS)
        count = part_words(part)
        if not PART_WORDS[0] <= count <= PART_WORDS[1]:
            problems.append(f"part {n}: {count} words, not {PART_WORDS[0]} to {PART_WORDS[1]}")

    total = word_count(summary)
    if not TOTAL_WORDS[0] <= total <= TOTAL_WORDS[1]:
        problems.append(f"{total} words in all, not {TOTAL_WORDS[0]} to {TOTAL_WORDS[1]}")

    # A phrase of the book's own at most, and not many of them.
    quoted = [q for p in parts if isinstance(p, dict) for t in p.get("text") or [] if isinstance(t, str)
              for q in re.findall(r'"([^"]*)"', t)]
    for q in quoted:
        if words(q) > QUOTE_WORDS:
            problems.append(f"a quotation of {words(q)} words, more than {QUOTE_WORDS}: \"{q[:40]}...\"")
    if sum(words(q) for q in quoted) > QUOTED_WORDS:
        problems.append(f"{sum(words(q) for q in quoted)} words quoted in all, more than {QUOTED_WORDS}")

    sources = summary["sources"]
    if not isinstance(sources, list) or not sources or not all(isinstance(s, str) and s.strip() for s in sources):
        problems.append("sources: the edition first, then the studies named that are not in the book")
    else:
        first = sources[0]
        if isinstance(summary.get("title"), str) and summary["title"] not in first:
            problems.append("sources: the first is the book itself")
        m = ISBN.search(first)
        if not m:
            problems.append("sources: the first names its edition by ISBN (\"ISBN 978...\")")
        elif card_book is not None and card_book.get("isbn") and m.group(1) != card_book["isbn"]:
            problems.append(f"sources: the edition is ISBN {m.group(1)}, where its cards' cover is {card_book['isbn']}")
        for i, s in enumerate(sources, 1):
            if not LINK.search(s):
                problems.append(f"source {i}: no link that opens it (a URL or a doi:)")
    return problems


def check_all(summaries: list[dict], cards: list[dict]) -> dict[str, list[str]]:
    """Every problem, keyed by `summaries/<book>`."""
    books = books_of(cards)
    out: dict[str, list[str]] = {}
    seen: set = set()
    for s in summaries:
        key = f"summaries/{s.get('book')}"
        problems = check(s, books)
        if s.get("book") in seen:
            problems.append("a second summary of the same book")
        seen.add(s.get("book"))
        if problems:
            out[key] = problems
    return out


# --------------------------------------------------------------------------
# Published

# What the app and the server read: the file as written, without its
# bookkeeping, and the words and minutes reckoned once here.
FORMAT = 1
PUBLISHED_ORDER = ("format", "book", "title", "author", "year", "language", "words", "minutes", "parts", "sources")


def published(summary: dict) -> dict:
    out = {"format": FORMAT, **{k: v for k, v in public(summary).items() if k != "written"},
           "words": word_count(summary), "minutes": minutes(summary)}
    return {k: out[k] for k in PUBLISHED_ORDER if k in out}


def published_text(summary: dict) -> str:
    return json.dumps(published(summary), ensure_ascii=False, indent=1) + "\n"


def file_of(summary: dict) -> str:
    """Where a summary is published, under web/cards/."""
    return f"summaries/{summary['book']}.json"


def ref_of(summary: dict) -> str:
    """How the bank names it: the file, and the hash of what is in it."""
    text = published_text(summary)
    return f"{file_of(summary)}?v={hashlib.sha256(text.encode('utf-8')).hexdigest()[:12]}"


def index_of(summaries: list[dict]) -> dict[str, dict]:
    """The bank's line on each summary, by book: where it is, and what the
    book's page says before it is fetched."""
    return {
        s["book"]: {"file": ref_of(s), "minutes": minutes(s), "parts": len(s["parts"]), "words": word_count(s)}
        for s in sorted(summaries, key=lambda s: s["book"])
    }


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="*", help="summary files; none means every one in tool/cards/summaries/")
    args = ap.parse_args(argv)
    import check as card_check  # the bank, for the books a summary must be of

    cards = card_check.load_bank()
    summaries = [load(Path(f)) for f in args.files] if args.files else load_all()
    report = check_all(summaries, cards)
    for s in summaries:
        counts = [part_words(p) for p in s.get("parts", []) if isinstance(p, dict)]
        print(f"{s.get('book')}: {word_count(s)} words, {minutes(s)} min, parts {counts}")
    for key, problems in report.items():
        for p in problems:
            print(f"{key}: {p}")
    if report:
        print(f"{len(report)} of {len(summaries)} summaries do not pass")
        return 1
    print(f"{len(summaries)} summar{'y' if len(summaries) == 1 else 'ies'}: all clear")
    return 0


if __name__ == "__main__":
    sys.exit(main())
