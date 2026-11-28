"""Holds the store listing (store/listing.md) to the stores' own limits, and
to the app as it is.

Each field is the text under its heading, in each language. App Store
Connect and the Play Console refuse a field over its limit, and the App
Store gives no weight to a keyword the name or subtitle already holds, so
those are caught here rather than at upload.

Then every number the listing says is held to the app's own, read from the
code, not written down here: how many subjects there are, how many cards a
day and how many of a free day's are chosen for the reader, the trial's
free days, the minutes a day, the languages, the cards in a path, the
levels of how sure, how many cards are drawn. Each Google Play description
has to say the first six, and that the cards are in English while they
are. A feature behind a switch that is off where it is set live
(remote/app.json) may not be named at all; neither may a lock screen,
which Android's widgets do not reach, nor a price, which the store says in
the reader's own money. Google Play's rules for the title and the short
description are held too: no price or ranking words, no call to press
anything, no emoji, no words in capitals.

Last, store/play_it_en.md, the page the Play Console is filled from, has to
carry every Google Play field word for word.

    python3 store/check_listing.py
"""
from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
LISTING = HERE / "listing.md"
PLAY_PAGE = HERE / "play_it_en.md"

# Heading (as written, before any parenthesis) to its limit, per language.
LIMITS = {
    "en": {"App name": 30, "Subtitle": 30, "Keywords": 100, "Promotional text": 170,
           "Short description": 80, "Description": 4000},
    "it": {"Nome dell'app": 30, "Sottotitolo": 30, "Parole chiave": 100, "Testo promozionale": 170,
           "Descrizione breve": 80, "Descrizione": 4000},
}
NAME = {"en": ("App name", "Subtitle", "Keywords"), "it": ("Nome dell'app", "Sottotitolo", "Parole chiave")}
# What Google Play shows: the title, the short description and the description.
PLAY = {"en": ("App name", "Short description", "Description"),
        "it": ("Nome dell'app", "Descrizione breve", "Descrizione")}

WORDS = {
    "en": ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven",
           "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"],
    "it": ["zero", "uno", "due", "tre", "quattro", "cinque", "sei", "sette", "otto", "nove", "dieci", "undici",
           "dodici", "tredici", "quattordici", "quindici", "sedici", "diciassette", "diciotto", "diciannove", "venti"],
}


def number(word: str, lang: str) -> int | None:
    """[word] as a whole number, in figures or in [lang]'s words; None
    when it is no number ("a few", "the")."""
    w = word.strip().lower()
    if re.fullmatch(r"\d{1,3}([.,]\d{3})+|\d+", w):
        return int(re.sub(r"[.,]", "", w))
    if lang == "it" and w in ("un", "una"):
        return 1
    return WORDS[lang].index(w) if w in WORDS[lang] else None


def app_facts(root: Path = ROOT) -> dict[str, object]:
    """The numbers the listing may say, as the app's code has them."""
    def read(rel: str) -> str:
        return (root / rel).read_text(encoding="utf-8")

    def const(rel: str, name: str) -> int:
        return int(re.search(rf"const int {name} = (\d+);", read(rel)).group(1))

    order = re.search(r"const List<String> kTopicOrder = \[(.*?)\];", read("lib/data/topics.dart"), re.S).group(1)
    # Thinking is the app's own voice, not a subject (lib/data/topics.dart):
    # the app counts twenty, beside it.
    subjects = [k for k in re.findall(r"'([a-z_]+)'", order) if k != "thinking"]
    per_day = const("lib/data/pills_repository.dart", "kPillsPerDay")
    own_free = const("lib/data/daily.dart", "kOwnCardsFree")
    en = json.loads(read("lib/l10n/app_en.arb"))
    minutes = number(re.match(r"(\w+) minutes?", en["introThirtyTitle"], re.I).group(1), "en")
    levels = [int(v) for v in re.search(r"const List<int> kConfidenceLevels = \[([^\]]*)\]",
                                        read("lib/models/pill.dart")).group(1).split(",")]
    cards = drawn = 0
    languages = set()
    for meta in (root / "tool/cards/bank").glob("*/*.json"):
        cards += 1
        languages.add(json.loads(meta.read_text(encoding="utf-8")).get("language", "en"))
        page = meta.with_suffix(".html")
        if page.exists() and "Kit.single()" in page.read_text(encoding="utf-8"):
            drawn += 1
    return {
        "subjects": len(subjects),
        "per_day": per_day,
        "own_free": own_free,
        "at_random": per_day - own_free,
        "trial_days": const("lib/sync/subscription.dart", "kTrialDays"),
        "minutes": minutes,
        "languages": len(list((root / "lib/l10n").glob("app_*.arb"))),
        "path_cards": const("lib/explore/blocks/core/paths_block.dart", "kPathLength"),
        "sure": (min(levels), max(levels)),
        "score": per_day * 100,
        "cards": cards,
        "drawn": drawn,
        "card_languages": languages,
        "flags": live_flags(root),
    }


def live_flags(root: Path = ROOT) -> dict[str, bool]:
    """Each switch the app declares, and whether it is on for every reader
    where it is set live: remote/app.json, or the build's own value where
    that says nothing. A switch on only for some readers is not shipped to
    the ones reading the listing."""
    declared = json.loads((root / "tool/remote/parts/app_knobs.json").read_text(encoding="utf-8"))["flags"]
    live = (json.loads((root / "remote/app.json").read_text(encoding="utf-8")).get("flags") or {})
    out = {}
    for name, spec in declared.items():
        value = live.get(name, spec.get("default", False))
        if isinstance(value, dict):
            value = value.get("on", spec.get("default", False)) is True and not value.get("audience")
        out[name] = value is True
    return out


# What the listing may say, as patterns per language: the number each
# captures, and the fact it has to be. A pattern that captures a word that
# is no number ("a few minutes") says nothing.
CLAIMS = {
    "en": [
        (r"\b(\w+) subjects\b", "subjects"),
        (r"\bsubjects you (?:choose|pick), out of (\w+)\b", "subjects"),
        (r"\b(\w+) cards (?:a day|every morning|every day|each morning|each day)\b", "per_day"),
        (r"\b(?:gives you|you get) (\w+) cards\b", "per_day"),
        (r"\b(\w+) cards and you are done\b", "per_day"),
        (r"\b(\w+) cards:", "per_day"),
        (r"\ball (\w+) cards\b", "per_day"),
        (r"\b(\w+) chosen for you\b", "own_free"),
        (r"\b(\w+) at random\b", "at_random"),
        (r"\b(\w+) days free\b", "trial_days"),
        (r"\b(\w+)[- ]day free trial\b", "trial_days"),
        (r"\bfree for (\w+) days\b", "trial_days"),
        (r"\b(\w+) minutes?\b", "minutes"),
        (r"\b(\w+) languages\b", "languages"),
        (r"\b(\w+)-card paths?\b", "path_cards"),
        (r"\bpaths? of (\w+) cards\b", "path_cards"),
        (r"\bscore out of (\d+)\b", "score"),
    ],
    "it": [
        (r"\b(\w+) materie\b", "subjects"),
        (r"\bmaterie che scegli(?: tu)?, tra (\w+)\b", "subjects"),
        (r"\b(\w+) carte (?:al giorno|ogni mattina|ogni giorno)\b", "per_day"),
        (r"\b(?:ti dà|hai) (\w+) carte\b", "per_day"),
        (r"\b(\w+) carte e per oggi\b", "per_day"),
        (r"\bogni giorno: (\w+) carte\b", "per_day"),
        (r"\btutte e (\w+) le carte\b", "per_day"),
        (r"\b(\w+) scelte per te\b", "own_free"),
        (r"\b(\w+) a caso\b", "at_random"),
        (r"\b(\w+) giorni gratis\b", "trial_days"),
        (r"\bprova gratuita di (\w+) giorni\b", "trial_days"),
        (r"\b(\w+) minuti\b", "minutes"),
        (r"(?<!altre )\b(\w+) lingue\b", "languages"),
        (r"\baltre (\w+) lingue\b", "languages-1"),
        (r"\bpercorsi da (\w+) carte\b", "path_cards"),
        (r"\bpunteggio su (\d+)\b", "score"),
    ],
}
# Said with "more than": a floor the app has to reach.
FLOORS = {
    "en": [(r"\bmore than ([\d,.]+) cards are drawn\b", "drawn"), (r"\bmore than ([\d,.]+) cards(?! are drawn)\b", "cards")],
    "it": [(r"\bpiù di ([\d,.]+) carte sono disegnate\b", "drawn"), (r"\bpiù di ([\d,.]+) carte(?! sono disegnate)\b", "cards")],
}
SURE = {"en": r"\bfrom (\d+)% to (\d+)%", "it": r"\bdal (\d+)% al (\d+)%"}
# What each Google Play description has to say.
REQUIRED = ("subjects", "per_day", "own_free", "at_random", "trial_days", "minutes")
IN_ENGLISH = {"en": r"\bcards are in English\b", "it": r"\bcarte[^.]{0,20}\bsono in inglese\b"}

# The words that name a feature behind each switch.
FEATURES = {
    "listen": {"en": [r"\blisten", r"\bread aloud\b", r"\baudio\b"], "it": [r"\bascolt", r"\bad alta voce\b", r"\baudio\b"]},
    "invite": {"en": [r"\binvit(?:e|ation)"], "it": [r"\binvit[ao]\b", r"\binvita un amico\b"]},
    "share.challenge": {"en": [r"\bchallenge a friend\b"], "it": [r"\bsfid(?:a|are) un amico\b"]},
    "cardAi": {"en": [r"\bassistant\b", r"\bcoach\b"], "it": [r"\bassistente\b", r"\bcoach\b"]},
}
LOCK_SCREEN = {"en": r"\block ?screen\b", "it": r"\bschermata di blocco\b"}
PRICE = r"[€$£]\s?\d|\d\s?[€$£]|\bEUR\b|\bUSD\b"
# Google Play's metadata rules, for the title and the short description.
PLAY_WORDS = {
    "en": r"\b(?:free|best|top|#1|number one|download|install|sale|discount|no ads)\b",
    "it": r"\b(?:gratis|gratuit\w*|migliore|miglior|top|#1|scarica|installa|sconto|offerta|senza pubblicità)\b",
}


def fields(text: str) -> dict[str, dict[str, str]]:
    """{language: {heading: text}} from the listing's sections."""
    out: dict[str, dict[str, str]] = {}
    for part in re.split(r"^## ", text, flags=re.M)[1:]:
        title, _, body = part.partition("\n")
        name = title.strip().lower()
        lang = "en" if name.startswith("english") else "it" if name.startswith("italiano") else None
        if not lang:
            continue
        for sub in re.split(r"^### ", body, flags=re.M)[1:]:
            head, _, value = sub.partition("\n")
            head = head.split(" (")[0].strip()
            out.setdefault(lang, {})[head] = value.strip()
    return out


def limits(all_fields: dict[str, dict[str, str]]) -> list[str]:
    found = []
    for lang, caps in LIMITS.items():
        got = all_fields.get(lang, {})
        for head, limit in caps.items():
            value = got.get(head)
            if value is None:
                found.append(f"[{lang}] {head}: missing")
            elif len(value) > limit:
                found.append(f"[{lang}] {head}: {len(value)} characters, the limit is {limit}")
        name, subtitle, keywords = (got.get(h, "") for h in NAME[lang])
        words = keywords.split(",")
        if any(w != w.strip() or not w for w in words):
            found.append(f"[{lang}] keywords: one is empty or has spaces round it")
        if len(set(words)) != len(words):
            found.append(f"[{lang}] keywords: a keyword is there twice")
        said = set(re.findall(r"\w+", (name + " " + subtitle).lower()))
        repeated = [w for w in words if w.lower() in said]
        if repeated:
            found.append(f"[{lang}] keywords already in the name or subtitle: {', '.join(repeated)}")
    return found


def numbers(all_fields: dict[str, dict[str, str]], facts: dict[str, object]) -> list[str]:
    """Every number said held to the app's, and what each Google Play
    description has to say."""
    found = []
    for lang, got in all_fields.items():
        if lang not in CLAIMS:
            continue
        for head, text in got.items():
            said = set()
            for pattern, fact in CLAIMS[lang]:
                for m in re.finditer(pattern, text, re.I):
                    value = number(m.group(1), lang)
                    if value is None:
                        continue
                    key = fact.removesuffix("-1")
                    want = facts[key] - (1 if fact.endswith("-1") else 0)
                    said.add(key)
                    if value != want:
                        found.append(f"[{lang}] {head}: \"{m.group(0)}\" says {value}, the app has {want} ({key})")
            for pattern, fact in FLOORS[lang]:
                for m in re.finditer(pattern, text, re.I):
                    value = number(m.group(1), lang)
                    if value is not None and value > facts[fact]:
                        found.append(f"[{lang}] {head}: \"{m.group(0)}\", the bank has {facts[fact]} ({fact})")
            for m in re.finditer(SURE[lang], text, re.I):
                if (int(m.group(1)), int(m.group(2))) != facts["sure"]:
                    found.append(f"[{lang}] {head}: \"{m.group(0)}\", the app asks from {facts['sure'][0]}% to {facts['sure'][1]}%")
            if head == PLAY[lang][2]:
                missing = [k for k in REQUIRED if k not in said]
                if missing:
                    found.append(f"[{lang}] {head}: does not say the app's {', '.join(missing)}")
                if facts["card_languages"] - {lang} and not re.search(IN_ENGLISH[lang], text, re.I):
                    found.append(f"[{lang}] {head}: does not say the cards are in English")
    return found


def features(all_fields: dict[str, dict[str, str]], facts: dict[str, object]) -> list[str]:
    """No switch that is off named, no lock screen, no price."""
    found = []
    off = [name for name, on in facts["flags"].items() if not on]
    for lang, got in all_fields.items():
        for head, text in got.items():
            for name in off:
                for pattern in FEATURES.get(name, {}).get(lang, []):
                    m = re.search(pattern, text, re.I)
                    if m:
                        found.append(f"[{lang}] {head}: \"{m.group(0)}\" names {name}, which is off for readers")
            if head in PLAY.get(lang, ()) and re.search(LOCK_SCREEN[lang], text, re.I):
                found.append(f"[{lang}] {head}: Android's widgets are on the home screen, not the lock screen")
            m = re.search(PRICE, text)
            if m:
                found.append(f"[{lang}] {head}: \"{m.group(0)}\": the store says the price, in the reader's money")
    return found


def play_rules(all_fields: dict[str, dict[str, str]]) -> list[str]:
    """Google Play's metadata rules for the title and the short description."""
    found = []
    for lang, (title, short, _) in PLAY.items():
        got = all_fields.get(lang, {})
        for head in (title, short):
            text = got.get(head, "")
            m = re.search(PLAY_WORDS[lang], text, re.I)
            if m:
                found.append(f"[{lang}] {head}: \"{m.group(0)}\" is a word Google Play refuses here")
            if any(unicodedata.category(c) == "So" for c in text):
                found.append(f"[{lang}] {head}: no emoji or symbols here")
            caps = [w for w in re.findall(r"[^\W\d_]{3,}", text) if w.isupper()]
            if caps:
                found.append(f"[{lang}] {head}: no words in capitals ({', '.join(caps)})")
    return found


def play_page(all_fields: dict[str, dict[str, str]], page: str) -> list[str]:
    """Every Google Play field, word for word, on the page it is copied from."""
    found = []
    for lang, heads in PLAY.items():
        for head in heads:
            value = all_fields.get(lang, {}).get(head)
            if value and value not in page:
                found.append(f"store/play_it_en.md: [{lang}] {head} is not the listing's, word for word")
    return found


def problems(text: str, facts: dict[str, object] | None = None, page: str | None = None) -> list[str]:
    facts = facts or app_facts()
    all_fields = fields(text)
    found = limits(all_fields) + numbers(all_fields, facts) + features(all_fields, facts) + play_rules(all_fields)
    if page is not None:
        found += play_page(all_fields, page)
    return found


def main() -> int:
    text = LISTING.read_text(encoding="utf-8")
    facts = app_facts()
    found = problems(text, facts, PLAY_PAGE.read_text(encoding="utf-8") if PLAY_PAGE.exists() else "")
    for p in found:
        print(p)
    if not found:
        for lang, f in fields(text).items():
            print(lang, ", ".join(f"{h} {len(v)}" for h, v in f.items()))
        print(f"the app: {facts['subjects']} subjects, {facts['per_day']} cards a day ({facts['own_free']} chosen on the "
              f"free plan), {facts['trial_days']} days free, {facts['minutes']} minutes, {facts['languages']} languages, "
              f"{facts['cards']} cards ({facts['drawn']} drawn); off: "
              f"{', '.join(n for n, on in facts['flags'].items() if not on) or 'nothing'}")
        print("store listing: within the limits, and every number the app's own")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
