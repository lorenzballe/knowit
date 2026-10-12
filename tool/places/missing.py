"""Which places where real readers live still lack cards.

    python3 tool/places/missing.py readers.json          # a table
    python3 tool/places/missing.py readers.json --json   # for the concierge

`readers.json` lists the places of the readers PostHog judges real (the
insight "Lettori: dove sono e se sono veri", rows whose verdict starts with
"vero"), one object per reader:

    {"country": "IT", "region": "IT-45", "city": "Formigine",
     "lat": 44.574, "lon": 10.848}

`region` and `city` may be missing. PostHog never holds a coordinate, so
`lat` and `lon` are the city's centre, looked up by whoever runs this; a
city without them is reported as needing its centre rather than guessed.
The file names where readers live and the repository is public: it is
working material for one run, never committed (docs/PLACES.md §6).

What a place needs, nearest first: a reader's city wants CITY cards that
reach them, their region REGION cards, their country COUNTRY cards. Places
with more readers come first within each kind, and a run takes at most
--max places.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from places import BANK, place_cards, place_fit  # noqa: E402

TARGETS = {"city": 6, "region": 8, "country": 10}
ORDER = {"city": 0, "region": 1, "country": 2}
REGION_CODE = re.compile(r"^[A-Z]{2}-[A-Z0-9]{1,3}$")


def gaps(readers: list[dict], cards: list[dict],
         targets: dict[str, int] = TARGETS) -> list[dict]:
    """The places the readers' cards fall short at, nearest and fullest first."""
    found: dict[tuple, dict] = {}

    def note(kind: str, key: tuple, have: int, extra: dict) -> None:
        entry = found.setdefault(key, {"kind": kind, "have": have,
                                       "need": max(0, targets[kind] - have),
                                       "readers": 0, **extra})
        entry["readers"] += 1

    for reader in readers:
        country = (reader.get("country") or "").upper()
        if not re.fullmatch(r"[A-Z]{2}", country):
            continue
        reader = {**reader, "country": country}
        fits = [place_fit(card, reader) for card in cards]
        city = (reader.get("city") or "").strip()
        region = reader.get("region") or ""
        if city:
            has_point = reader.get("lat") is not None and reader.get("lon") is not None
            note("city", ("city", country, region, city.lower()), fits.count("city"),
                 {"country": country, "region": region or None, "city": city,
                  "lat": reader.get("lat"), "lon": reader.get("lon"),
                  "needs_centre": not has_point})
        if REGION_CODE.match(region):
            note("region", ("region", country, region), fits.count("region"),
                 {"country": country, "region": region})
        note("country", ("country", country), fits.count("country"),
             {"country": country})

    wanted = [e for e in found.values() if e["need"] > 0]
    wanted.sort(key=lambda e: (ORDER[e["kind"]], -e["readers"], -e["need"]))
    return wanted


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("readers", type=Path, help="the readers' places, as JSON")
    parser.add_argument("--bank", type=Path, default=BANK)
    parser.add_argument("--max", type=int, default=3, help="places to take this run")
    parser.add_argument("--json", action="store_true", help="print JSON")
    args = parser.parse_args(argv)

    readers = json.loads(args.readers.read_text(encoding="utf-8"))
    if not isinstance(readers, list):
        parser.error("readers.json must be a list of places")
    todo = gaps(readers, place_cards(args.bank))[: args.max]

    if args.json:
        print(json.dumps(todo, ensure_ascii=False, indent=2))
        return 0
    if not todo:
        print("Every real reader's place has its cards.")
        return 0
    for e in todo:
        if e["kind"] == "city":
            where = f"{e['city']} ({e.get('region') or e['country']})"
        else:
            where = e.get("region") or e["country"]
        note = "  needs the city's centre" if e.get("needs_centre") else ""
        print(f"{e['kind']:<8} {where:<32} has {e['have']:>2}, write {e['need']:>2}{note}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
