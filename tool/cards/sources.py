"""Where a card's claim comes from: the domains, the kinds, the quote.

A card written from memory cites what it remembers; a card written from a
page it has read cites the page. Everything here serves the second kind:
which domains the tools may not open at all, which may never be the
reference, which a subject's readers would trust first, what kinds of
source there are, and whether a passage the reader claims to have copied
from a page is actually on it.
"""
from __future__ import annotations

import json
import re
import unicodedata
from functools import lru_cache
from pathlib import Path
from urllib.parse import urlparse

HERE = Path(__file__).resolve().parent
DOMAINS = HERE / "domains.txt"

KINDS: list[str] = list(json.loads((HERE / "schema.json").read_text(encoding="utf-8"))["properties"]["source_kind"]["enum"])

# What each kind means, for the model. The vocabulary is the schema's.
KIND_MEANS = {
    "paper": "a peer-reviewed article, or a preprint with the data",
    "statistics": "an official statistical release or a dataset from the body that collects it",
    "primary_document": "the thing itself: a law, a treaty, a letter, a transcript, a patent, a court record, a filing",
    "institution": "the page of the agency, university, observatory, museum or laboratory that did or holds the thing",
    "reference_work": "a dictionary, an encyclopaedia of record, a handbook, a catalogue",
    "book": "a monograph, with the page",
    "standard": "a specification from the body that sets it",
    "news_archive": "a newspaper's own archive, for an event on the day it happened",
    "company": "the maker's own filing, report or technical note",
    "arithmetic": "no source but the reader: a number they can redo from the card",
}

# Registrable-domain suffixes that take one more label: co.uk, not uk.
_TWO_LEVEL = {"co", "ac", "gov", "org", "edu", "net", "com", "gv", "or", "ne"}


@lru_cache(maxsize=None)
def load_domains(path: Path = DOMAINS) -> dict[str, list[str]]:
    """The sections of domains.txt, by header, in file order."""
    out: dict[str, list[str]] = {}
    section = ""
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1].strip()
            out.setdefault(section, [])
            continue
        out.setdefault(section, []).append(line.lower())
    return out


def blocked() -> list[str]:
    return list(load_domains().get("blocked", []))


def never_a_reference() -> list[str]:
    return list(load_domains().get("never a reference", []))


def preferred(topic: str) -> list[str]:
    return list(load_domains().get(f"preferred {topic}", []))


def kinds_for(topic: str) -> list[str]:
    """The kinds of source a subject's cards are built from, from
    domains.txt; every kind but arithmetic when the file does not say."""
    listed = [k for k in load_domains().get(f"kinds {topic}", []) if k in KINDS]
    return listed or [k for k in KINDS if k != "arithmetic"]


def domain_of(url: str) -> str:
    """The registrable domain of a URL, lowercase, without www: the thing
    two cards must not share within one strand."""
    host = (urlparse(url.strip()).hostname or "").lower()
    if host.startswith("www."):
        host = host[4:]
    parts = host.split(".")
    if len(parts) >= 3 and parts[-2] in _TWO_LEVEL and len(parts[-1]) == 2:
        return ".".join(parts[-3:])
    return ".".join(parts[-2:]) if len(parts) >= 2 else host


def is_under(domain: str, pattern: str) -> bool:
    return domain == pattern or domain.endswith("." + pattern)


def is_url(text: str) -> bool:
    return text.strip().lower().startswith(("http://", "https://"))


def fold(text: str) -> str:
    """Text reduced to what survives copying: lowercase letters and digits,
    accents stripped, nothing else. A quote and a page are compared this
    way, so a curly quote, a soft hyphen, a line break or a non-breaking
    space cannot make an honest quote look invented."""
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    return re.sub(r"[^a-z0-9]", "", text.lower())


def same_quote(quote: str, page: str, *, min_words: int = 6) -> bool:
    """Whether [quote] is on [page], verbatim, allowing only for the
    accidents of copying. A quote shorter than [min_words] is not a quote."""
    if len(quote.split()) < min_words:
        return False
    needle = fold(quote)
    return bool(needle) and needle in fold(page)
