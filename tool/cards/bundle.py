#!/usr/bin/env python3
"""Turns the bank into what the app reads.

    python3 tool/cards/bundle.py           # write both copies, extend the calendar
    python3 tool/cards/bundle.py --check   # fail if either copy is stale

The bank is one file per card, which is what a person reviews. The app
wants one document, twice: baked into the build as `lib/data/embedded_bank.dart`,
so the first day works offline, and published as `web/cards/v2/cards.json`,
which the deploy copies to the site and every phone downloads. Both are
written here, from the same bytes, so they cannot disagree.

A free card's page does not travel in that document. Each page is a file of
its own, `web/cards/pages/<id>.html`, and the card names it with the hash of
its bytes (`"page": "pages/<id>.html?v=<hash>"`): the phone fetches a page
when its card is about to be shown and keeps it, the way a feed fetches a
picture, so the document every phone downloads stays small however many
pages the bank holds. A changed page is a new hash, so no copy kept anywhere
outlives it.

Builds from before pages travelled alone read `web/cards/cards.json`, the
same bank with each page inside its card (format 1). That copy carries only
the pages those builds already knew (`legacy_pages.txt`); every free card
after them is for the builds that fetch pages, and an older build simply
never meets it.

The calendar of questions of the day travels in the same document. It is
frozen — an edition, once written, never changes, whatever the pool does
afterwards — and this extends it a year past today so the app is never
without one. (Before the calendar existed the app computed it from the pool
on the fly, and a card added anywhere re-dealt every day since the epoch.)

A card about a place travels like any other, its `place` with it, for the
phones and the server to deal only to the readers who live there; the
calendar never names one.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import random
import sys
from pathlib import Path

import check

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
EMBEDDED = ROOT / "lib" / "data" / "embedded_bank.dart"
# The bank as the app reads it, pages apart (format 2).
PUBLISHED = ROOT / "web" / "cards" / "v2" / "cards.json"
# What a phone asks first: the published bundle's version and nothing else,
# a few dozen bytes, so an app already holding it never downloads the whole
# bank again to find that out.
VERSION = PUBLISHED.parent / "version.json"
# One file per free card's page, fetched by the phone when it is wanted.
PAGES = ROOT / "web" / "cards" / "pages"
# The bank for builds that read every page inside its card (format 1), and
# its version note: where those builds look, and always will.
LEGACY = ROOT / "web" / "cards" / "cards.json"
LEGACY_VERSION = LEGACY.parent / "version.json"
# The free cards those builds already carry, page inside: no other is
# sent to them, so their bank never grows by a page.
LEGACY_PAGES = HERE / "legacy_pages.txt"

# Edition 1. The same date as kEpoch in lib/data/daily.dart.
EPOCH = dt.date(2026, 9, 1)
# How far ahead the calendar is kept.
AHEAD_DAYS = 400


def edition_of(day: dt.date) -> int:
    return (day - EPOCH).days + 1


def extend_editions(editions: dict[str, str], cards: list[dict], until: int) -> dict[str, str]:
    """Adds editions up to [until], keeping clear of what came before.

    A question stays out for three quarters of a lap of the graded pool, and
    never less than the gap check.py enforces; the pick is seeded by the
    edition so two machines extending the same calendar write the same thing.

    The pool is Thinking's graded cards only. The question of the day is
    everybody's, whatever their mix, and it costs nobody's mix anything only
    because Thinking is on every deck; a subject's graded cards are dealt
    from the mix, to the readers who kept that subject on. A card about a
    place is never in it: it goes to the readers who live there and nobody
    else (docs/PLACES.md). Left out of the pool, it leaves the pool's size
    alone too, so the editions it would have changed are the ones a bank
    without it writes.
    """
    graded = sorted(
        c["id"] for c in cards
        if c["kind"] in check.GRADED and c["topic"] == "thinking" and not c.get("disabled")
        and not check.is_place_card(c)
    )
    if not graded:
        raise SystemExit("no graded card to make a question of the day from")
    window = max(check.EDITION_GAP, int(len(graded) * 0.75))
    out = dict(editions)
    last = max((int(k) for k in out), default=0)
    for e in range(last + 1, until + 1):
        recent = {out[str(x)] for x in range(e - window, e) if str(x) in out}
        fresh = [cid for cid in graded if cid not in recent]
        rng = random.Random(e * 7919 + 104729)
        out[str(e)] = rng.choice(fresh or graded)
    return out


def extend_commons(commons: dict[str, list[str]], cards: list[dict], until: int) -> dict[str, list[str]]:
    """Adds each edition's common cards up to [until], keeping clear of what came before.

    The cards everybody meets on a day besides its question: COMMON_SPARES
    reading cards, never two of one subject, out for three quarters of a lap
    of the reading pool at COMMON_SPARES an edition. Frozen here, like the
    question, so a phone dealing its own day and a server dealing it for
    the reader hand out the same three. A card about a place is never one:
    a common card is everybody's.
    """
    pool = sorted(
        c["id"] for c in cards
        if c["kind"] == "read" and not c.get("disabled") and not check.is_place_card(c)
    )
    if len(pool) < check.COMMON_SPARES:
        raise SystemExit("too few reading cards to make an edition's common cards from")
    topic_of = {c["id"]: c["topic"] for c in cards}
    window = max(check.COMMON_GAP, int(len(pool) * 0.75) // check.COMMON_SPARES)
    out = {k: list(v) for k, v in commons.items()}
    last = max((int(k) for k in out), default=0)
    for e in range(last + 1, until + 1):
        recent = {cid for x in range(e - window, e) for cid in out.get(str(x), [])}
        rng = random.Random(e * 6007 + 91)
        fresh = [cid for cid in pool if cid not in recent]
        stale = [cid for cid in pool if cid in recent]
        rng.shuffle(fresh)
        rng.shuffle(stale)
        picked, topics = [], set()
        for cid in fresh + stale:
            if len(picked) >= check.COMMON_SPARES:
                break
            if topic_of[cid] in topics:
                continue
            topics.add(topic_of[cid])
            picked.append(cid)
        out[str(e)] = picked
    return out


def page_hash(html: str) -> str:
    """The first twelve hex digits of the page's SHA-256: what changes when it does."""
    return hashlib.sha256(html.encode("utf-8")).hexdigest()[:12]


def page_file(card: dict) -> str:
    """Where a free card's page is published, under web/cards/."""
    return f"pages/{card['id']}.html"


def page_ref(card: dict) -> str:
    """How the card names its page: the file, and the hash of what is in it."""
    return f"{page_file(card)}?v={page_hash(card['_html'])}"


def bundled(card: dict, *, inline: bool = False) -> dict:
    """A card as the app reads it. A free card's face names its page, which
    travels as a file of its own; with [inline], for the builds that came
    before, the page is inside the face instead."""
    out = check.public(card)
    if isinstance(out.get("web"), dict) and card.get("_html") is not None:
        if inline:
            out["web"] = {**out["web"], "html": card["_html"]}
        else:
            out["web"] = {**out["web"], "page": page_ref(card),
                          "bytes": len(card["_html"].encode("utf-8"))}
    return out


def build(cards: list[dict], editions: dict[str, str], commons: dict[str, list[str]], *, version: int, built: str,
          inline: bool = False) -> dict:
    return {
        "format": 1 if inline else 2,
        "version": version,
        "built": built,
        "cards": [bundled(c, inline=inline) for c in cards],
        "editions": editions,
        "commons": commons,
    }


def legacy_ids() -> set[str]:
    if not LEGACY_PAGES.exists():
        return set()
    return {line.strip() for line in LEGACY_PAGES.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.startswith("#")}


def build_legacy(cards: list[dict], editions: dict[str, str], commons: dict[str, list[str]], *, version: int,
                 built: str, keep: set[str]) -> dict:
    """The bank for the builds that read pages inside their cards: every card
    but the free cards they never knew, and a calendar that never names one."""
    kept = [c for c in cards if c.get("_html") is None or c["id"] in keep]
    ids = {c["id"] for c in kept}
    return build(
        kept,
        {k: v for k, v in editions.items() if v in ids},
        {k: [cid for cid in v if cid in ids] for k, v in commons.items()},
        version=version, built=built, inline=True,
    )


def pages_of(cards: list[dict]) -> dict[str, str]:
    """Every page to publish, by its file under web/cards/."""
    return {page_file(c): c["_html"] for c in cards if c.get("_html") is not None}


def pages_current(pages: dict[str, str]) -> bool:
    """Whether web/cards/pages/ holds exactly these pages."""
    root = PAGES.parent
    on_disk = {f"pages/{f.name}" for f in PAGES.glob("*.html")} if PAGES.exists() else set()
    if on_disk != set(pages):
        return False
    return all((root / name).read_text(encoding="utf-8") == html for name, html in pages.items())


def write_pages(pages: dict[str, str]) -> None:
    root = PAGES.parent
    PAGES.mkdir(parents=True, exist_ok=True)
    for name, html in pages.items():
        path = root / name
        if not path.exists() or path.read_text(encoding="utf-8") != html:
            path.write_text(html, encoding="utf-8")
    for f in PAGES.glob("*.html"):
        if f"pages/{f.name}" not in pages:
            f.unlink()


def render_dart(text: str) -> str:
    if "'''" in text:
        raise SystemExit("a card contains three quotes in a row, which a Dart raw string cannot hold")
    return (
        "// GENERATED by tool/cards/bundle.py from tool/cards/bank/. Do not edit:\n"
        "// change a card in the bank and run the bundler. CI checks this is current.\n"
        "\n"
        "/// The bank the app ships with, as the JSON the site also serves.\n"
        "/// Parsed once, by PillBank.embedded.\n"
        "const String kEmbeddedBank = r'''\n"
        f"{text}"
        "''';\n"
    )


def same_content(a: dict | None, b: dict) -> bool:
    """Whether two bundles hold the same cards and calendar, whatever the stamp."""
    if a is None:
        return False
    return (a.get("cards") == b.get("cards") and a.get("editions") == b.get("editions")
            and a.get("commons", {}) == b.get("commons", {}))


def version_note(bundle: dict) -> str:
    return json.dumps({"version": bundle["version"], "cards": len(bundle["cards"])}) + "\n"


def version_current(published: Path = PUBLISHED, version: Path = VERSION) -> bool:
    """Whether a version note names the version its cards.json holds."""
    if not (published.exists() and version.exists()):
        return False
    try:
        return json.loads(version.read_text(encoding="utf-8")) == json.loads(
            version_note(json.loads(published.read_text(encoding="utf-8"))))
    except (json.JSONDecodeError, KeyError):
        return False


def read_json(path: Path) -> dict | None:
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None


def read_embedded() -> dict | None:
    if not EMBEDDED.exists():
        return None
    text = EMBEDDED.read_text(encoding="utf-8")
    start, end = text.find("r'''\n"), text.rfind("''';")
    if start < 0 or end < 0:
        return None
    try:
        return json.loads(text[start + 5:end])
    except json.JSONDecodeError:
        return None


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="only report whether the copies are current")
    ap.add_argument("--today", help="YYYY-MM-DD, for a reproducible calendar (default: today)")
    args = ap.parse_args(argv)

    cards = check.load_bank()
    report = check.check_bank(cards)
    if report:
        for cid, problems in report.items():
            for p in problems:
                print(f"{cid}: {p}")
        print("the bank does not pass; nothing written")
        return 1

    today = dt.date.fromisoformat(args.today) if args.today else dt.date.today()
    editions = json.loads(check.EDITIONS.read_text(encoding="utf-8")) if check.EDITIONS.exists() else {}
    commons = json.loads(check.COMMONS.read_text(encoding="utf-8")) if check.COMMONS.exists() else {}
    # A check holds the copies to the calendar as it is; only a write extends
    # it, or a bundle would go stale every midnight.
    if not args.check:
        editions = extend_editions(editions, cards, until=edition_of(today) + AHEAD_DAYS)
        commons = extend_commons(commons, cards, until=edition_of(today) + AHEAD_DAYS)
    problems = check.check_editions(editions, cards) + check.check_commons(commons, cards)
    if problems:
        for p in problems:
            print(p)
        return 1

    now = dt.datetime.now(dt.timezone.utc)
    stamp, built = int(now.strftime("%Y%m%d%H%M")), now.strftime("%Y-%m-%dT%H:%M:%SZ")
    bundle = build(cards, editions, commons, version=stamp, built=built)
    old = build_legacy(cards, editions, commons, version=stamp, built=built, keep=legacy_ids())
    pages = pages_of(cards)
    text = json.dumps(bundle, ensure_ascii=False, indent=1) + "\n"

    current = same_content(read_embedded(), bundle)
    published = same_content(read_json(PUBLISHED), bundle)
    legacy = same_content(read_json(LEGACY), old)
    paged = pages_current(pages)
    noted = version_current() and version_current(LEGACY, LEGACY_VERSION)
    if args.check:
        if current and published and legacy and paged and noted:
            print(f"{len(cards)} cards, {len(pages)} pages, {len(editions)} editions: every copy current")
            return 0
        print("stale:" + ("" if current else " lib/data/embedded_bank.dart")
              + ("" if published else " web/cards/v2/cards.json")
              + ("" if legacy else " web/cards/cards.json")
              + ("" if paged else " web/cards/pages/")
              + ("" if noted else " the version notes"))
        print("run python3 tool/cards/bundle.py")
        return 1

    if current and published and legacy and paged:
        for pub, note in ((PUBLISHED, VERSION), (LEGACY, LEGACY_VERSION)):
            if not version_current(pub, note):
                note.write_text(version_note(json.loads(pub.read_text(encoding="utf-8"))), encoding="utf-8")
                print(f"wrote {note.relative_to(ROOT)}")
        print(f"{len(cards)} cards, {len(pages)} pages, {len(editions)} editions: nothing to do")
        return 0
    check.EDITIONS.write_text(json.dumps(editions, indent=2) + "\n", encoding="utf-8")
    check.COMMONS.write_text(json.dumps(commons, indent=1) + "\n", encoding="utf-8")
    EMBEDDED.write_text(render_dart(text), encoding="utf-8")
    PUBLISHED.parent.mkdir(parents=True, exist_ok=True)
    PUBLISHED.write_text(text, encoding="utf-8")
    VERSION.write_text(version_note(bundle), encoding="utf-8")
    # The older builds' copy is rewritten only when what they get changes:
    # a new stamp alone would send every one of them the whole bank again.
    if not legacy:
        LEGACY.write_text(json.dumps(old, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        LEGACY_VERSION.write_text(version_note(old), encoding="utf-8")
    write_pages(pages)
    print(f"{len(cards)} cards, {len(pages)} pages, {len(editions)} editions, version {bundle['version']}")
    print(f"wrote {EMBEDDED.relative_to(ROOT)}, {PUBLISHED.relative_to(ROOT)}, {LEGACY.relative_to(ROOT)},"
          f" the version notes and {PAGES.relative_to(ROOT)}/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
