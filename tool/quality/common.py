"""Where things are, for the scripts in this folder.

Importing this puts tool/cards on the path, so the quality layer can use
the generator, the gate and the sources list exactly as the night does.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CARDS = ROOT / "tool" / "cards"
BANK = CARDS / "bank"

# Cards that wait for a person: written by the night, or proposed by the
# re-check, and not in the bank until somebody says so (review.py).
REVIEW = CARDS / "review"
QUEUE = REVIEW / "queue.json"

# The scorecard the server keeps (functions/src/scorecard.ts, `cardStats`).
STATS_URL = "https://europe-west1-astuto-3d398.cloudfunctions.net/cardStats"

REPO = "lorenzballe/knowit"

if str(CARDS) not in sys.path:
    sys.path.insert(0, str(CARDS))


def read_queue(path: Path = QUEUE) -> list[dict]:
    """The cards waiting for a person, oldest first."""
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    return list(data.get("cards", []))


def write_queue(cards: list[dict], path: Path = QUEUE) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"cards": cards}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def write_card(card: dict, path: Path) -> None:
    """A card file, in the house order, as everything else writes one."""
    import check

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(check.ordered(card), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
