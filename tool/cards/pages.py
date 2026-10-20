"""The rules a free card's page has to keep, checked before the app sees it.

A free card's face is a web page made with the card kit (docs/cards/kit),
kept beside the card as `<id>.html` and inlined by bundle.py into the bank.
The app puts the kit, its libraries and its fonts inside the page and shows
it offline, behind a policy that shuts the network out
(lib/widgets/web/card_kit.dart). So the page may link the kit and nothing
else, may fetch nothing, has to be small enough to travel in the bank, and
has to carry what the app and the checker need from it: one card, the kit's
single-card mode, a way to play it through, the card's own question as its
question. docs/REMOTE.md, Free cards, has the whole road.

What this cannot check is whether the page looks right on a phone. That is
tool/cards/card_check.cjs, and then the eye.

    python3 tool/cards/pages.py tool/cards/bank/<topic>/<id>.html
"""
from __future__ import annotations

import html as htmllib
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
KIT = HERE.parent.parent / "docs" / "cards" / "kit"

# The kit this checker holds pages to; the app's own is kCardKit in
# lib/models/pill.dart, and a test keeps the two equal.
KIT_VERSION = 1

# The most a page may weigh. It travels in the bank, which every phone
# downloads whole, and in the build: a picture belongs drawn, not pasted.
MAX_BYTES = 200_000

LABEL_CHARS = (20, 400)

CDN = re.compile(r"^https?://(cdn\.jsdelivr\.net|unpkg\.com|cdnjs\.cloudflare\.com)/", re.I)
GOOGLE_FONTS = re.compile(r"^https?://fonts\.googleapis\.com/css2?\b", re.I)
# A blob the page made itself (Kit.url) may be fetched; nothing else may.
NETWORK = re.compile(r"\bfetch\s*\((?!\s*Kit\.url)|\b(XMLHttpRequest|WebSocket|EventSource|sendBeacon)\b")
ELSEWHERE = re.compile(r"<(iframe|form|object|embed|base|frame)\b", re.I)
LINK = re.compile(r"<link\b[^>]*>", re.I)
SCRIPT_SRC = re.compile(r"<script\b([^>]*\bsrc\s*=[^>]*)>", re.I)
MEDIA_SRC = re.compile(r"<(img|audio|video|source|track|image)\b[^>]*\b(?:src|href|xlink:href|poster)\s*=\s*[\"']([^\"']+)[\"']", re.I)
IMPORT_MAP = re.compile(r"<script\b[^>]*\btype\s*=\s*[\"']importmap[\"'][^>]*>([\s\S]*?)</script\s*>", re.I)
IMPORT_FROM = re.compile(r"""\b(?:import|from)\s*\(?\s*["']([^"']+)["']""")
KIT_URL = re.compile(r"""Kit\.url\(\s*['"]([^'"]+)['"]\s*\)""")
CSS_URL = re.compile(r"""url\(\s*(['"]?)([^'")]+)\1\s*\)""")
QUESTION = re.compile(r"<(h[1-6]|p|div)\b[^>]*\bclass\s*=\s*[\"'][^\"']*\bq\b[^\"']*[\"'][^>]*>([\s\S]*?)</\1>", re.I)
CARD = re.compile(r"<article\b[^>]*\bclass\s*=\s*[\"'][^\"']*\bcard\b[^\"']*[\"'][^>]*>", re.I)


def _attr(tag: str, name: str) -> str | None:
    m = re.search(rf"\b{name}\s*=\s*(?:\"([^\"]*)\"|'([^']*)'|([^\s>]+))", tag, re.I)
    return None if m is None else (m.group(1) or m.group(2) or m.group(3) or "")


def kit_files(root: Path = KIT) -> set[str]:
    """Every file the app carries of the kit, by its path inside the kit."""
    keep = {"astute-card.css", "astute-card.js", "astute-bridge.js", "fonts.css"}
    out = {p for p in keep if (root / p).exists()}
    for sub in ("fonts", "vendor", "vendor/gsap-plugins"):
        d = root / sub
        if d.is_dir():
            out |= {f"{sub}/{f.name}" for f in d.iterdir() if f.is_file()}
    return out


def resolve(ref: str, files: set[str]) -> str | None:
    """The kit file a link stands for, as lib/widgets/web/card_kit.dart reads
    it (kitPathOf), or None when the kit has nothing by that name."""
    bare = re.split(r"[?#]", ref.strip())[0]
    if GOOGLE_FONTS.match(bare):
        return "fonts.css"
    if CDN.match(bare):
        name = bare.rsplit("/", 1)[-1]
        return next((p for p in sorted(files) if p.startswith("vendor/") and p.rsplit("/", 1)[-1] == name), None)
    if ":" in bare or bare.startswith("//") or not bare:
        return None
    at = bare.rfind("kit/")
    inner = bare[at + 4:] if at >= 0 else re.sub(r"^(\./|\.\./)+", "", bare)
    return inner if inner in files else None


def text_of(markup: str) -> str:
    """What a piece of markup says, as a reader reads it."""
    plain = re.sub(r"<[^>]+>", "", markup)
    return re.sub(r"\s+", " ", htmllib.unescape(plain)).strip()


def check_page(card: dict, page: str | None, *, files: set[str] | None = None) -> list[str]:
    """Everything wrong with a free card's page, as short sentences."""
    web = card.get("web")
    if not isinstance(web, dict):
        return ["web: not an object"]
    if page is None:
        return [f"a free card keeps its page beside it: {card['id']}.html"]
    files = kit_files() if files is None else files
    p: list[str] = []

    kit = web.get("kit")
    if not isinstance(kit, int) or kit < 1:
        p.append("web.kit is the version of the kit the page is made with")
    elif kit > KIT_VERSION:
        p.append(f"web.kit is {kit}, but the kit is at {KIT_VERSION}: no build could show it")
    if "html" in web:
        p.append("web.html is the bundle's: the page lives beside the card, and bundle.py puts it in")
    label = web.get("label", "")
    if not isinstance(label, str) or not LABEL_CHARS[0] <= len(label.strip()) <= LABEL_CHARS[1]:
        p.append(f"web.label says what the face shows and asks, for a reader who cannot see it: {LABEL_CHARS[0]} to {LABEL_CHARS[1]} characters")
    if web.get("touch", "taps") not in ("taps", "drags"):
        p.append("web.touch is taps or drags")

    size = len(page.encode("utf-8"))
    if size > MAX_BYTES:
        p.append(f"the page is {size // 1000} KB; at most {MAX_BYTES // 1000}: it travels in the bank every phone downloads")
    if "'''" in page:
        p.append("the page has three quotes in a row, which the embedded bank (a Dart raw string) cannot hold")

    # One card, in the kit's single-card mode, played through for the checker.
    cards = CARD.findall(page)
    if len(cards) != 1:
        p.append(f"a free card's page holds one <article class=\"card\">, not {len(cards)}")
    elif (topic := _attr(cards[0], "data-topic")) not in (None, card["topic"]):
        p.append(f"the page is dressed as {topic}, the card is {card['topic']}")
    if "Kit.single()" not in page:
        p.append("the page calls Kit.single(): the kit's mode for one card in the app")
    if not re.search(r"Kit\.play\.\w+\s*=", page):
        p.append("the page registers Kit.play.card, so the checker can photograph its end")

    # Its question is the card's: the app draws it on the poster, before the
    # page is up, and everything that is not the page reads the card's.
    m = QUESTION.search(page)
    if m and text_of(m.group(2)) != re.sub(r"\s+", " ", card["question"]).strip():
        p.append(f"the page asks {text_of(m.group(2))!r}; the card asks {card['question']!r}: the same words, so the poster and the page agree")

    # What it answers.
    kind = card.get("kind")
    answers = "Kit.answer(" in page
    if kind in ("page", "pickOne", "number", "estimate", "debate") and not answers:
        p.append(f"a {kind} card answers through Kit.answer, so the app can record it")
    if kind == "read" and answers:
        p.append("a card that only tells records nothing: Kit.answer does nothing on it")
    if web.get("touch") == "drags" and not re.search(r"data-drag|touch-action\s*:\s*none", page):
        p.append("a card that takes drags marks what it holds: data-drag, or touch-action: none")

    # Nothing from anywhere but the kit.
    for tag in LINK.findall(page):
        rel = (_attr(tag, "rel") or "").lower().split()
        href = _attr(tag, "href") or ""
        if "stylesheet" in rel:
            if resolve(href, files) is None:
                p.append(f"links {href!r}, which is not in the kit: link kit/... or a kit library's CDN copy")
        elif "preconnect" not in rel and "dns-prefetch" not in rel:
            p.append(f"a <link rel={' '.join(rel)!r}> the app drops: only stylesheets are linked")
    for attrs in SCRIPT_SRC.findall(page):
        src = _attr(attrs, "src") or ""
        if resolve(src, files) is None:
            p.append(f"loads the script {src!r}, which is not in the kit")
    for m in IMPORT_MAP.finditer(page):
        try:
            imports = json.loads(m.group(1)).get("imports", {})
        except (json.JSONDecodeError, AttributeError):
            p.append("an import map that does not read as JSON")
            continue
        for ref in imports.values():
            if not isinstance(ref, str) or resolve(ref, files) is None:
                p.append(f"the import map points at {ref!r}, which is not in the kit")
    for ref in IMPORT_FROM.findall(page):
        if re.match(r"^(https?:)?//", ref):
            p.append(f"imports {ref!r} from the network: map it to a kit module in an import map")
    for ref in KIT_URL.findall(page):
        if resolve(ref, files) is None:
            p.append(f"Kit.url names {ref!r}, which is not in the kit")
    for _, ref in CSS_URL.findall(page):
        if ref.startswith(("data:", "#")):
            continue
        if resolve(ref, files) is None:
            p.append(f"a stylesheet points at {ref!r}: a picture goes in as data, a font is the kit's")
    for _, ref in MEDIA_SRC.findall(page):
        if not ref.startswith(("data:", "#")):
            p.append(f"shows {ref[:60]!r} from outside the page: put it in as data")
    if NETWORK.search(page):
        p.append(f"asks the network ({NETWORK.search(page).group(0).strip()}): a card has everything it needs inside it")
    if ELSEWHERE.search(page):
        p.append(f"a <{ELSEWHERE.search(page).group(1).lower()}> loads or sends something elsewhere: not in a card")
    return p


def main(argv: list[str]) -> int:
    bad = 0
    for name in argv:
        path = Path(name)
        card = json.loads(path.with_suffix(".json").read_text(encoding="utf-8"))
        problems = check_page(card, path.read_text(encoding="utf-8"))
        for problem in problems:
            print(f"{path}: {problem}")
        bad += bool(problems)
    print("all clear" if not bad else f"{bad} of {len(argv)} with problems")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
