"""Holds the store listing (store/listing.md) to the stores' own limits.

Each field is the text under its heading, in each language. App Store
Connect and the Play Console refuse a field over its limit, and the App
Store gives no weight to a keyword the name or subtitle already holds, so
those are caught here rather than at upload.

    python3 store/check_listing.py
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

LISTING = Path(__file__).with_name("listing.md")

# Heading (as written, before any parenthesis) to its limit, per language.
LIMITS = {
    "en": {"App name": 30, "Subtitle": 30, "Keywords": 100, "Promotional text": 170,
           "Short description": 80, "Description": 4000},
    "it": {"Nome dell'app": 30, "Sottotitolo": 30, "Parole chiave": 100, "Testo promozionale": 170,
           "Descrizione breve": 80, "Descrizione": 4000},
}
NAME = {"en": ("App name", "Subtitle", "Keywords"), "it": ("Nome dell'app", "Sottotitolo", "Parole chiave")}


def fields(text: str) -> dict[str, dict[str, str]]:
    """{language: {heading: text}} from the listing's sections."""
    out: dict[str, dict[str, str]] = {}
    lang = None
    for part in re.split(r"^## ", text, flags=re.M)[1:]:
        title, _, body = part.partition("\n")
        lang = "en" if title.strip().lower().startswith("english") else "it" if title.strip().lower().startswith("italiano") else None
        if not lang:
            continue
        for sub in re.split(r"^### ", body, flags=re.M)[1:]:
            head, _, value = sub.partition("\n")
            head = head.split(" (")[0].strip()
            out.setdefault(lang, {})[head] = value.strip()
    return out


def problems(text: str) -> list[str]:
    found = []
    all_fields = fields(text)
    for lang, limits in LIMITS.items():
        got = all_fields.get(lang, {})
        for head, limit in limits.items():
            value = got.get(head)
            if value is None:
                found.append(f"[{lang}] {head}: missing")
                continue
            if len(value) > limit:
                found.append(f"[{lang}] {head}: {len(value)} characters, the limit is {limit}")
        name, subtitle, keywords = (got.get(h, "") for h in NAME[lang])
        words = keywords.split(",")
        if " " in keywords.replace(", ", ","):
            pass
        if any(w != w.strip() or not w for w in words):
            found.append(f"[{lang}] keywords: one is empty or has spaces round it")
        if len(set(words)) != len(words):
            found.append(f"[{lang}] keywords: a keyword is there twice")
        said = set(re.findall(r"\w+", (name + " " + subtitle).lower()))
        repeated = [w for w in words if w.lower() in said]
        if repeated:
            found.append(f"[{lang}] keywords already in the name or subtitle: {', '.join(repeated)}")
    return found


def main() -> int:
    found = problems(LISTING.read_text(encoding="utf-8"))
    for p in found:
        print(p)
    if not found:
        counts = {lang: {h: len(v) for h, v in f.items()} for lang, f in fields(LISTING.read_text(encoding="utf-8")).items()}
        for lang, c in counts.items():
            print(lang, ", ".join(f"{h} {n}" for h, n in c.items()))
        print("store listing: all within the limits")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
