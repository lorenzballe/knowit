"""Where a card belongs and where a reader lives, for the tools.

The Python twin of `placeFit` and `distanceKm` in lib/models/place.dart,
held to the same cases (tool/places/fit_cases.json) as the phone and the
server, so a place counts as covered here exactly when the dealers would
deal its reader a card.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BANK = ROOT / "tool" / "cards" / "bank"

EARTH_KM = 6371.0


def distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """The distance along the ground between two points, in kilometres."""
    rad = math.radians
    d_lat = rad(lat2 - lat1)
    d_lon = rad(lon2 - lon1)
    a = (math.sin(d_lat / 2) ** 2
         + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(d_lon / 2) ** 2)
    return 2 * EARTH_KM * math.asin(min(1.0, math.sqrt(a)))


def place_fit(card: dict, reader: dict | None) -> str:
    """How a card's `place` fits a reader's: 'city', 'region', 'country' or 'none'.

    A city card fits a reader within its `km` of its point, and never one
    without a point; a region card, a reader in the same region; a country
    card, anyone in the country. Nothing fits across a border.
    """
    if not reader or card.get("country") != reader.get("country"):
        return "none"
    if card.get("city"):
        lat, lon, km = card.get("lat"), card.get("lon"), card.get("km")
        r_lat, r_lon = reader.get("lat"), reader.get("lon")
        if None in (lat, lon, km, r_lat, r_lon):
            return "none"
        return "city" if distance_km(lat, lon, r_lat, r_lon) <= km else "none"
    if card.get("region"):
        return "region" if card["region"] == reader.get("region") else "none"
    return "country"


def place_cards(bank: Path = BANK) -> list[dict]:
    """Every live card in the bank that belongs to a place, with its id."""
    cards = []
    for path in sorted(bank.glob("*/*.json")):
        card = json.loads(path.read_text(encoding="utf-8"))
        if card.get("disabled") or not isinstance(card.get("place"), dict):
            continue
        cards.append({"id": card["id"], **card["place"]})
    return cards
