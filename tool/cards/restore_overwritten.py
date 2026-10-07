"""Brings back cards whose story was overwritten by a new one.

When a writer gives an existing card a completely different story (to host a
scene, say), the old story is lost. This compares every card with its text at
a base commit; where the question shares too few words with the old one, the
old card is written back under a new id at the end of its strand, so both
stories stay in the bank.

    python3 tool/cards/restore_overwritten.py <base-commit> [--dry-run]
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
BANK = HERE / "bank"
STOP = set("the a an of to in and or is are was were for on at by with from as that this it its be how what why who which when does do did".split())


def words(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z]+", text.lower()) if w not in STOP and len(w) > 2}


def old_version(base: str, path: Path) -> dict | None:
    rel = path.relative_to(HERE.parent.parent)
    try:
        out = subprocess.run(["git", "show", f"{base}:{rel}"], capture_output=True, text=True, check=True).stdout
    except subprocess.CalledProcessError:
        return None
    return json.loads(out)


def next_id(card_id: str) -> str:
    stem = re.sub(r"-\d+$", "", card_id)
    used = {p.stem for p in BANK.glob("*/*.json")}
    n = 1
    while f"{stem}-{n}" in used:
        n += 1
    return f"{stem}-{n}"


def main() -> int:
    base, dry = sys.argv[1], "--dry-run" in sys.argv
    restored = 0
    for path in sorted(BANK.glob("*/*.json")):
        now = json.loads(path.read_text())
        old = old_version(base, path)
        if not old or old.get("disabled"):
            continue
        a, b = words(old["question"]), words(now["question"])
        overlap = len(a & b) / max(1, min(len(a), len(b)))
        if overlap >= 0.3:
            continue
        new_id = next_id(old["id"])
        print(f"{now['id']}: story replaced; old one back as {new_id}")
        print(f"   was: {old['question'][:90]}")
        print(f"   now: {now['question'][:90]}")
        if not dry:
            old["id"] = new_id
            text = path.read_text()
            indent = 1 if text.startswith('{\n "') else 2
            (path.parent / f"{new_id}.json").write_text(json.dumps(old, indent=indent, ensure_ascii=False) + "\n")
        restored += 1
    print(f"{restored} stories {'would be ' if dry else ''}restored")
    return 0


if __name__ == "__main__":
    sys.exit(main())
